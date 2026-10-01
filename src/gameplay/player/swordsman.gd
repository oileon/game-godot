class_name Swordsman
extends CharacterBody2D
## Swordsman-style player character: side-scrolling belt-scroller movement
## (X is the primary axis, Y is a narrow depth lane, a separate gravity-driven
## jump-height axis), basic/heavy attack, dodge, skill, HP and death. Logic
## only; all visuals live in SwordsmanPlaceholderVisual and react to this
## node's signals/getters.
##
## Implements: design/game-brief.md MVP features 1-2 (Swordsman class, basic +
## heavy + dodge + 1 skill) and the 2026-10-01 genre/perspective clarification
## (classic side-scrolling beat 'em up, not top-down).
## Story: production/epics/ragnarok-brawler/story-001-swordsman-core-moveset.md
## (rework pass, 2026-10-01 — corrected movement model; the combat/health
## logic below was already correct and is unchanged by this pass).
##
## State machine (explicit transition table in TRANSITIONS):
##   IDLE <-> MOVE
##   IDLE/MOVE -> AIRBORNE (jump) | BASIC_ATTACK | HEAVY_ATTACK | SKILL | DODGE
##   AIRBORNE -> BASIC_ATTACK | IDLE (landed) | HURT | DEAD
##   BASIC_ATTACK -> AIRBORNE (still falling when the attack ends) | IDLE
##   HEAVY_ATTACK/SKILL/DODGE -> IDLE (when finished)
##   any live state -> HURT (hit received) -> IDLE
##   any live state -> DEAD (HP 0), terminal
##
## Attacks run through phases STARTUP -> ACTIVE -> RECOVERY. The hitbox only
## connects during ACTIVE. Combo chaining / cancelling is NOT here (Story 002).
## Timings are physics-frame quantised (delta-driven, frame-rate independent).
##
## Jump height (see `jump_height`) is a presentation + airborne-flag axis only
## and never changes collision X/Y — only BASIC_ATTACK is reachable from
## AIRBORNE (scope: one airborne attack, no juggle/launcher system — that is
## Story 002/003 territory). Design choice: an airborne attack always runs its
## full STARTUP/ACTIVE/RECOVERY duration even if gravity brings the character
## back to the ground mid-attack; landing only zeroes the presentational jump
## height, it does not cut the attack short or change state early.

## Character states.
enum State { IDLE, MOVE, AIRBORNE, BASIC_ATTACK, HEAVY_ATTACK, DODGE, SKILL, HURT, DEAD }
## Phases of an attack.
enum AttackPhase { NONE, STARTUP, ACTIVE, RECOVERY }

## Emitted on every state change.
signal state_changed(previous: State, current: State)
## Emitted when an attack begins.
signal attack_started(attack: AttackData)
## Emitted when the current attack enters a new phase.
signal attack_phase_changed(phase: AttackPhase)
## Emitted when this character's attack connects with a hurtbox.
signal hit_landed(hurtbox: Hurtbox, hit: HitInfo)
## Emitted each frame the skill cooldown changes (remaining 0 = ready).
signal skill_cooldown_changed(remaining: float, total: float)
## Emitted once when the character dies.
signal died

## Allowed transitions. Anything not listed is rejected by _change_state().
const TRANSITIONS: Dictionary = {
	State.IDLE: [State.MOVE, State.AIRBORNE, State.BASIC_ATTACK, State.HEAVY_ATTACK, State.DODGE, State.SKILL, State.HURT, State.DEAD],
	State.MOVE: [State.IDLE, State.AIRBORNE, State.BASIC_ATTACK, State.HEAVY_ATTACK, State.DODGE, State.SKILL, State.HURT, State.DEAD],
	State.AIRBORNE: [State.IDLE, State.BASIC_ATTACK, State.HURT, State.DEAD],
	State.BASIC_ATTACK: [State.IDLE, State.AIRBORNE, State.HURT, State.DEAD],
	State.HEAVY_ATTACK: [State.IDLE, State.HURT, State.DEAD],
	State.SKILL: [State.IDLE, State.HURT, State.DEAD],
	State.DODGE: [State.IDLE, State.HURT, State.DEAD],
	State.HURT: [State.IDLE, State.AIRBORNE, State.HURT, State.DEAD],
	State.DEAD: [],
}

## Data-driven tunables (assets/data/swordsman_stats.tres).
@export var stats: SwordsmanStats
## World-space rectangle the character is clamped to: X = the level's left/
## right bounds, Y = the narrow depth lane (not a full-arena height). Zero
## size = unbounded. Set by the owning scene (e.g. TestArena).
@export var movement_bounds: Rect2 = Rect2()

## Current state.
var state: State = State.IDLE
## Horizontal facing: 1.0 right, -1.0 left.
var facing_x: float = 1.0
## Height-axis offset above the ground plane (px); 0 = grounded. Presentation
## + airborne-flag only - never affects collision X/Y. Read by the visual to
## draw the character raised; see is_grounded().
var jump_height: float = 0.0

var _state_time: float = 0.0
var _freeze_left: float = 0.0
var _dodge_cooldown_left: float = 0.0
var _skill_cooldown_left: float = 0.0
var _vertical_velocity: float = 0.0
var _current_attack: AttackData
var _attack_phase: AttackPhase = AttackPhase.NONE
var _hit_targets: Array[Hurtbox] = []
var _dodge_direction: Vector2 = Vector2.RIGHT
var _hurt_duration: float = 0.0
var _knockback: KnockbackMotion = KnockbackMotion.new()

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Area2D = $Hitbox
@onready var _hitbox_shape: CollisionShape2D = $Hitbox/HitboxShape


func _ready() -> void:
	assert(stats != null, "Swordsman requires a SwordsmanStats resource")
	_hitbox_shape.shape = RectangleShape2D.new()
	hitbox.monitoring = false
	health.setup(stats.max_hp)
	hurtbox.hit_received.connect(_on_hurtbox_hit_received)


func _physics_process(delta: float) -> void:
	if _freeze_left > 0.0:
		# Hit-stop: the whole character holds still.
		_freeze_left = maxf(_freeze_left - delta, 0.0)
		return
	_tick_cooldowns(delta)
	_process_height_axis(delta)
	match state:
		State.IDLE, State.MOVE:
			_process_locomotion()
		State.AIRBORNE:
			_process_airborne()
		State.BASIC_ATTACK, State.HEAVY_ATTACK, State.SKILL:
			_process_attack(delta)
		State.DODGE:
			_process_dodge(delta)
		State.HURT:
			_process_hurt(delta)
		State.DEAD:
			_process_dead(delta)


# --- Public API -------------------------------------------------------------

## Freezes the character for `duration` seconds (hit-stop). Longer freezes win.
func apply_hit_stop(duration: float) -> void:
	_freeze_left = maxf(_freeze_left, duration)


## The attack currently executing, or null.
func get_current_attack() -> AttackData:
	return _current_attack


## Current attack phase (NONE when not attacking).
func get_attack_phase() -> AttackPhase:
	return _attack_phase


## Seconds spent in the current state.
func get_state_time() -> float:
	return _state_time


## Seconds until the skill is ready (0 = ready).
func get_skill_cooldown_remaining() -> float:
	return _skill_cooldown_left


## True while the hurtbox ignores hits (dodge i-frames, death).
func is_invulnerable() -> bool:
	return hurtbox.invulnerable


## True when the height axis is at rest on the ground plane (not jumping/falling).
func is_grounded() -> bool:
	return jump_height <= 0.0 and _vertical_velocity <= 0.0


# --- State machine ----------------------------------------------------------

func _change_state(next: State) -> bool:
	if not (TRANSITIONS[state] as Array).has(next):
		return false
	var previous: State = state
	_exit_state(previous)
	state = next
	_state_time = 0.0
	_enter_state(next)
	state_changed.emit(previous, next)
	return true


func _enter_state(next: State) -> void:
	match next:
		State.BASIC_ATTACK:
			_begin_attack(stats.basic_attack)
		State.HEAVY_ATTACK:
			_begin_attack(stats.heavy_attack)
		State.SKILL:
			_skill_cooldown_left = stats.skill_cooldown
			_begin_attack(stats.skill_attack)
		State.DODGE:
			_begin_dodge()
		State.DEAD:
			hurtbox.invulnerable = true
			died.emit()
		_:
			pass


func _exit_state(previous: State) -> void:
	match previous:
		State.BASIC_ATTACK, State.HEAVY_ATTACK, State.SKILL:
			_end_attack()
		State.DODGE:
			hurtbox.invulnerable = false
			_dodge_cooldown_left = stats.dodge_cooldown
		_:
			pass


# --- Locomotion -------------------------------------------------------------

func _read_move_input() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")


func _process_locomotion() -> void:
	if Input.is_action_just_pressed(&"skill") and _skill_cooldown_left <= 0.0:
		if _change_state(State.SKILL):
			return
	if Input.is_action_just_pressed(&"dodge") and _dodge_cooldown_left <= 0.0:
		if _change_state(State.DODGE):
			return
	if Input.is_action_just_pressed(&"attack_heavy"):
		if _change_state(State.HEAVY_ATTACK):
			return
	if Input.is_action_just_pressed(&"attack_basic"):
		if _change_state(State.BASIC_ATTACK):
			return
	if Input.is_action_just_pressed(&"jump") and is_grounded():
		_vertical_velocity = stats.jump_velocity
		if _change_state(State.AIRBORNE):
			return

	var move_input: Vector2 = _read_move_input()
	if move_input != Vector2.ZERO:
		velocity = Vector2(move_input.x * stats.move_speed, move_input.y * stats.move_speed * stats.vertical_speed_ratio)
		if absf(move_input.x) > 0.01:
			facing_x = signf(move_input.x)
		if state != State.MOVE:
			_change_state(State.MOVE)
	else:
		velocity = Vector2.ZERO
		if state != State.IDLE:
			_change_state(State.IDLE)
	_move_and_clamp()


## While airborne: the same X/depth-lane locomotion as IDLE/MOVE (a belt-
## scroller lets you steer in mid-air), plus the one airborne attack and the
## landing check. The height axis itself is handled by _process_height_axis(),
## which runs every physics frame regardless of state.
func _process_airborne() -> void:
	if Input.is_action_just_pressed(&"attack_basic"):
		if _change_state(State.BASIC_ATTACK):
			return

	var move_input: Vector2 = _read_move_input()
	if move_input != Vector2.ZERO:
		velocity = Vector2(move_input.x * stats.move_speed, move_input.y * stats.move_speed * stats.vertical_speed_ratio)
		if absf(move_input.x) > 0.01:
			facing_x = signf(move_input.x)
	else:
		velocity = Vector2.ZERO
	_move_and_clamp()
	if is_grounded():
		_change_state(State.IDLE)


func _move_and_clamp() -> void:
	move_and_slide()
	if movement_bounds.size != Vector2.ZERO:
		global_position = global_position.clamp(movement_bounds.position, movement_bounds.end)


## Integrates the jump-height axis (gravity-driven). Runs every physics frame
## regardless of state so a jump started before a hit, attack or dodge still
## resolves (and lands) in the background. Presentation + is_grounded() only -
## never touches collision X/Y.
func _process_height_axis(delta: float) -> void:
	if jump_height <= 0.0 and _vertical_velocity <= 0.0:
		jump_height = 0.0
		_vertical_velocity = 0.0
		return
	_vertical_velocity -= stats.jump_gravity * delta
	jump_height = maxf(jump_height + _vertical_velocity * delta, 0.0)
	if jump_height <= 0.0:
		jump_height = 0.0
		_vertical_velocity = 0.0


# --- Attacks ----------------------------------------------------------------

func _begin_attack(attack: AttackData) -> void:
	_current_attack = attack
	_hit_targets.clear()
	velocity = Vector2.ZERO
	var shape: RectangleShape2D = _hitbox_shape.shape as RectangleShape2D
	shape.size = attack.hitbox_size
	hitbox.position = Vector2(attack.hitbox_offset.x * facing_x, attack.hitbox_offset.y)
	# Monitoring starts now so overlaps are already known when ACTIVE begins;
	# hits are only resolved during ACTIVE.
	hitbox.monitoring = true
	_attack_phase = AttackPhase.STARTUP
	attack_started.emit(attack)
	attack_phase_changed.emit(_attack_phase)


func _end_attack() -> void:
	hitbox.monitoring = false
	_attack_phase = AttackPhase.NONE
	_current_attack = null
	attack_phase_changed.emit(_attack_phase)


func _process_attack(delta: float) -> void:
	_state_time += delta
	var attack: AttackData = _current_attack
	if _state_time >= attack.get_total_duration():
		velocity = Vector2.ZERO
		_change_state(_landing_state())
		return

	var phase: AttackPhase = _phase_for_time(attack, _state_time)
	if phase != _attack_phase:
		_attack_phase = phase
		attack_phase_changed.emit(_attack_phase)

	if phase == AttackPhase.ACTIVE:
		velocity = Vector2(facing_x * attack.lunge_speed, 0.0)
		_move_and_clamp()
		_resolve_hits()
	else:
		velocity = Vector2.ZERO


func _phase_for_time(attack: AttackData, elapsed: float) -> AttackPhase:
	if elapsed < attack.startup:
		return AttackPhase.STARTUP
	if elapsed < attack.startup + attack.active:
		return AttackPhase.ACTIVE
	return AttackPhase.RECOVERY


## State to return to when an attack finishes: AIRBORNE if gravity hasn't
## brought the character back to the ground yet (and the current state's
## transition table allows it - today, only BASIC_ATTACK does), IDLE otherwise.
func _landing_state() -> State:
	if not is_grounded() and (TRANSITIONS[state] as Array).has(State.AIRBORNE):
		return State.AIRBORNE
	return State.IDLE


func _resolve_hits() -> void:
	for area: Area2D in hitbox.get_overlapping_areas():
		var target: Hurtbox = area as Hurtbox
		if target == null or _hit_targets.has(target):
			continue
		_hit_targets.append(target)
		var impact: Vector2 = hitbox.global_position.lerp(target.global_position, 0.5)
		var hit: HitInfo = HitInfo.new(_current_attack, self, Vector2(facing_x, 0.0), impact)
		if target.receive_hit(hit):
			apply_hit_stop(_current_attack.hit_stop_duration)
			hit_landed.emit(target, hit)


# --- Dodge ------------------------------------------------------------------

func _begin_dodge() -> void:
	var move_input: Vector2 = _read_move_input()
	_dodge_direction = move_input.normalized() if move_input != Vector2.ZERO else Vector2(facing_x, 0.0)


func _process_dodge(delta: float) -> void:
	_state_time += delta
	var iframes_end: float = stats.dodge_iframe_start + stats.dodge_iframe_duration
	hurtbox.invulnerable = _state_time >= stats.dodge_iframe_start and _state_time < iframes_end
	velocity = _dodge_direction * (stats.dodge_distance / stats.dodge_duration)
	_move_and_clamp()
	if _state_time >= stats.dodge_duration:
		velocity = Vector2.ZERO
		_change_state(State.IDLE)


# --- Damage / death ---------------------------------------------------------

func _on_hurtbox_hit_received(hit: HitInfo) -> void:
	if state == State.DEAD:
		return
	health.take_damage(hit.attack.damage)
	apply_hit_stop(hit.attack.hit_stop_duration)
	_knockback.start(hit.direction * hit.attack.knockback_speed, hit.attack.knockback_duration)
	_hurt_duration = hit.attack.hitstun_duration
	if health.is_dead():
		_change_state(State.DEAD)
	else:
		_change_state(State.HURT)


func _process_hurt(delta: float) -> void:
	_state_time += delta
	velocity = _knockback.step(delta)
	_move_and_clamp()
	if _state_time >= _hurt_duration:
		velocity = Vector2.ZERO
		_change_state(_landing_state())


func _process_dead(delta: float) -> void:
	_state_time += delta
	velocity = _knockback.step(delta)
	_move_and_clamp()


# --- Cooldowns --------------------------------------------------------------

func _tick_cooldowns(delta: float) -> void:
	_dodge_cooldown_left = maxf(_dodge_cooldown_left - delta, 0.0)
	if _skill_cooldown_left > 0.0:
		_skill_cooldown_left = maxf(_skill_cooldown_left - delta, 0.0)
		skill_cooldown_changed.emit(_skill_cooldown_left, stats.skill_cooldown)
