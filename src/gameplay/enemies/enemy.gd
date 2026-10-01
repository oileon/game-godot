class_name Enemy
extends CharacterBody2D
## Shared brawler-horde enemy. One class, per-type behaviour from EnemyStats
## data. Logic only; the look lives in EnemyPlaceholderVisual, which reads the
## getters/signals below.
##
## Implements: design/game-brief.md MVP feature 4 + core loop (control a horde).
## Story: production/epics/ragnarok-brawler/story-003-enemies-horde-ai.md
##
## State machine (explicit table in TRANSITIONS; _change_state() is the ONLY
## writer of `state`):
##   IDLE      not yet alerted / no live target. -> APPROACH when alerted or the
##             player comes within aggro_range.
##   APPROACH  walks to its ring slot (no token) or charges in to attack range
##             (holding an attack token).
##   WAIT_RING holds/maintains its ring slot, faces the player, backs away if the
##             player gets inside retreat_distance (ranged). When its attack timer
##             has run out it asks the token pool; a granted token -> APPROACH.
##   ATTACK    STARTUP (telegraph) -> ACTIVE (hit / projectile) -> RECOVERY, driven
##             by AttackData. The token is released when RECOVERY begins.
##   HURT      flinch + knockback + stun (scaled by EnemyStats), self hit-stop.
##   DEAD      terminal; no collision, hurtbox off, fades and frees itself.
##   IDLE      -> APPROACH | HURT | DEAD
##   APPROACH  -> WAIT_RING | ATTACK | IDLE | HURT | DEAD
##   WAIT_RING -> APPROACH | IDLE | HURT | DEAD
##   ATTACK    -> WAIT_RING | IDLE | HURT | DEAD
##   HURT      -> WAIT_RING | IDLE | HURT | DEAD
##
## Collision table (physics layers): 1 = player body, 2 = player Hurtbox,
## 4 = enemy/dummy Hurtbox, 8 = solid bodies (enemies, dummies).
##   Enemy body:   layer 8, mask 1|8 (= 9) - blocks and is blocked by the player
##                 and other enemies. Removed (layer/mask 0) on death.
##   Enemy Hurtbox: layer 4, mask 0 (detected by the player's Hitbox, mask 4).
##   Enemy Hitbox:  layer 0, mask 2 (detects the player's Hurtbox).
## All timers are delta-driven inside _physics_process.

## Enemy states.
enum State { IDLE, APPROACH, WAIT_RING, ATTACK, HURT, DEAD }
## Phases of an attack.
enum AttackPhase { NONE, STARTUP, ACTIVE, RECOVERY }

## Emitted on every state change.
signal state_changed(previous: State, current: State)
## Emitted when an attack begins (the telegraph starts).
signal attack_started(attack: AttackData)
## Emitted when the attack enters a new phase.
signal attack_phase_changed(phase: AttackPhase)
## Emitted when a hit is accepted (presentation flash).
signal hit_taken(hit: HitInfo)
## Emitted when this enemy's melee attack connects with the player's hurtbox.
signal hit_landed(hurtbox: Hurtbox, hit: HitInfo)
## Emitted when this enemy fires a projectile.
signal projectile_fired(projectile: EnemyProjectile)
## Emitted exactly once on death.
signal died(enemy: Enemy)

## Allowed transitions. Anything else is rejected by _change_state().
const TRANSITIONS: Dictionary = {
	State.IDLE: [State.APPROACH, State.HURT, State.DEAD],
	State.APPROACH: [State.WAIT_RING, State.ATTACK, State.IDLE, State.HURT, State.DEAD],
	State.WAIT_RING: [State.APPROACH, State.IDLE, State.HURT, State.DEAD],
	State.ATTACK: [State.WAIT_RING, State.IDLE, State.HURT, State.DEAD],
	State.HURT: [State.WAIT_RING, State.IDLE, State.HURT, State.DEAD],
	State.DEAD: [],
}

## Data-driven tunables (assets/data/enemies/*.tres).
@export var stats: EnemyStats
## World rectangle the enemy is clamped to (X = level, Y = depth lane). Zero
## size = unbounded. Set by the owner (EncounterGroup / arena).
@export var movement_bounds: Rect2 = Rect2()
## Log every state transition with print() (AI debugging).
@export var debug_log_transitions: bool = false

## Current state.
var state: State = State.IDLE
## Horizontal facing: 1.0 right, -1.0 left.
var facing_x: float = -1.0
## The player this enemy fights. Injected via configure().
var target: Swordsman

var _alerted: bool = false
var _state_time: float = 0.0
var _freeze_left: float = 0.0
var _attack_timer: float = 0.0
var _has_token: bool = false
var _token_time: float = 0.0
var _current_attack: AttackData
var _attack_phase: AttackPhase = AttackPhase.NONE
var _hit_targets: Array[Hurtbox] = []
var _projectile_fired: bool = false
var _hurt_duration: float = 0.0
var _knockback: KnockbackMotion = KnockbackMotion.new()
var _tokens: AttackTokenPool
var _ring_provider: Callable
var _rng: RandomNumberGenerator

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Area2D = $Hitbox
@onready var _hitbox_shape: CollisionShape2D = $Hitbox/HitboxShape


## Injects the enemy's collaborators (dependency injection, no singletons). Call
## before adding to the tree. `tokens` null = attacks freely (standalone enemy).
## `ring_provider` is a Callable(enemy: Enemy) -> Vector2 giving the ring slot;
## invalid = hold the current position. `rng` null = fixed-seed RNG.
func configure(p_target: Swordsman, p_bounds: Rect2, p_tokens: AttackTokenPool, p_ring_provider: Callable, p_rng: RandomNumberGenerator) -> void:
	target = p_target
	movement_bounds = p_bounds
	_tokens = p_tokens
	_ring_provider = p_ring_provider
	_rng = p_rng


func _ready() -> void:
	assert(stats != null and stats.attack != null, "Enemy requires an EnemyStats resource with an attack")
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.seed = 1
	_hitbox_shape.shape = RectangleShape2D.new()
	hitbox.monitoring = false
	health.setup(stats.max_hp)
	hurtbox.hit_received.connect(_on_hurtbox_hit_received)
	_attack_timer = _roll(stats.initial_attack_delay_min, stats.initial_attack_delay_max)


func _physics_process(delta: float) -> void:
	if _freeze_left > 0.0:
		# Hit-stop: the enemy holds still.
		_freeze_left = maxf(_freeze_left - delta, 0.0)
		return
	match state:
		State.IDLE:
			_process_idle()
		State.APPROACH:
			_process_approach(delta)
		State.WAIT_RING:
			_process_wait_ring(delta)
		State.ATTACK:
			_process_attack(delta)
		State.HURT:
			_process_hurt(delta)
		State.DEAD:
			_process_dead(delta)


# --- Public API -------------------------------------------------------------

## Wakes the enemy so it starts approaching the player.
func alert() -> void:
	_alerted = true


## Freezes the enemy for `duration` seconds (hit-stop). Longer freezes win.
func apply_hit_stop(duration: float) -> void:
	_freeze_left = maxf(_freeze_left, duration)


## True once the enemy is dead.
func is_dead() -> bool:
	return state == State.DEAD


## True while this enemy holds an attack token.
func has_attack_token() -> bool:
	return _has_token


## Current attack phase (NONE when not attacking).
func get_attack_phase() -> AttackPhase:
	return _attack_phase


## The attack being executed, or null.
func get_current_attack() -> AttackData:
	return _current_attack


## Seconds spent in the current state.
func get_state_time() -> float:
	return _state_time


## 0..1 progress through the attack's STARTUP (the telegraph); 0 outside it.
func get_telegraph_progress() -> float:
	if state != State.ATTACK or _attack_phase != AttackPhase.STARTUP or _current_attack.startup <= 0.0:
		return 0.0
	return clampf(_state_time / _current_attack.startup, 0.0, 1.0)


## 1 while the corpse lingers, then fades to 0 (1 for living enemies).
func get_corpse_alpha() -> float:
	if state != State.DEAD:
		return 1.0
	var fade_time: float = _state_time - stats.corpse_linger
	if fade_time <= 0.0:
		return 1.0
	return clampf(1.0 - fade_time / maxf(stats.corpse_fade, 0.001), 0.0, 1.0)


# --- State machine ----------------------------------------------------------

func _change_state(next: State) -> bool:
	if not (TRANSITIONS[state] as Array).has(next):
		return false
	var previous: State = state
	_exit_state(previous)
	state = next
	_state_time = 0.0
	_enter_state(next)
	if debug_log_transitions:
		print("[Enemy %s #%d] %s -> %s" % [stats.display_name, get_instance_id(), State.keys()[previous], State.keys()[next]])
	state_changed.emit(previous, next)
	return true


func _enter_state(next: State) -> void:
	match next:
		State.ATTACK:
			_begin_attack()
		State.HURT:
			_release_token()
		State.DEAD:
			_release_token()
			if _tokens != null:
				_tokens.withdraw(get_instance_id())
			hurtbox.invulnerable = true
			hurtbox.set_deferred(&"monitorable", false)
			hitbox.set_deferred(&"monitoring", false)
			# Dead bodies must not block movement or attacks.
			set_deferred(&"collision_layer", 0)
			set_deferred(&"collision_mask", 0)
			velocity = Vector2.ZERO
			died.emit(self)
		_:
			pass


func _exit_state(previous: State) -> void:
	match previous:
		State.ATTACK:
			_end_attack()
		State.WAIT_RING:
			# Leaving the ring without a token: stop waiting in the queue.
			if not _has_token and _tokens != null:
				_tokens.withdraw(get_instance_id())
		_:
			pass


# --- Idle / approach / ring --------------------------------------------------

func _process_idle() -> void:
	velocity = Vector2.ZERO
	if not _target_alive():
		return
	if _alerted or _distance_to_target() <= stats.aggro_range:
		_alerted = true
		_change_state(State.APPROACH)


func _process_approach(delta: float) -> void:
	if not _target_alive():
		_release_token()
		_change_state(State.IDLE)
		return
	_tick_attack_timer(delta)
	_face_target()
	if _has_token:
		_token_time += delta
		if _token_time > stats.token_hold_timeout:
			# Could not get into range in time (blocked?): give the turn back.
			_release_token()
			_attack_timer = _roll(stats.attack_cooldown_min, stats.attack_cooldown_max)
			return
		if _in_attack_range():
			_change_state(State.ATTACK)
			return
		_steer_to(_attack_stand_position(), stats.move_speed)
		return
	var slot: Vector2 = _get_ring_position()
	if global_position.distance_to(slot) <= stats.arrive_tolerance:
		_change_state(State.WAIT_RING)
		return
	_steer_to(slot, stats.move_speed)


func _process_wait_ring(delta: float) -> void:
	if not _target_alive():
		_change_state(State.IDLE)
		return
	_tick_attack_timer(delta)
	_face_target()
	var slot: Vector2 = _get_ring_position()
	if global_position.distance_to(slot) > stats.ring_leash:
		_change_state(State.APPROACH)
		return
	var dx: float = global_position.x - target.global_position.x
	if stats.retreat_distance > 0.0 and absf(dx) < stats.retreat_distance:
		# Keep-distance: back away along X, keep drifting toward the slot's lane.
		var away: float = signf(dx) if dx != 0.0 else -facing_x
		var retreat_speed: float = stats.move_speed * stats.retreat_speed_scale
		velocity = Vector2(away * retreat_speed, clampf((slot.y - global_position.y) / _physics_dt(), -_vertical_speed(), _vertical_speed()))
		_move_and_clamp()
	elif global_position.distance_to(slot) > stats.arrive_tolerance * stats.retreat_settle_fraction:
		_steer_to(slot, stats.move_speed)
	else:
		velocity = Vector2.ZERO
	if _attack_timer > 0.0:
		return
	var granted: bool = _tokens == null or _tokens.request(get_instance_id())
	if granted:
		_has_token = true
		_token_time = 0.0
		_change_state(State.APPROACH)


func _tick_attack_timer(delta: float) -> void:
	_attack_timer = maxf(_attack_timer - delta, 0.0)


func _get_ring_position() -> Vector2:
	if _ring_provider.is_valid():
		return _ring_provider.call(self) as Vector2
	return global_position


## Where a token holder walks to: its current side of the player at
## attack_stand_distance, on the player's depth line.
func _attack_stand_position() -> Vector2:
	var side: float = signf(global_position.x - target.global_position.x)
	if side == 0.0:
		side = -facing_x
	return Vector2(target.global_position.x + side * stats.attack_stand_distance, target.global_position.y)


func _in_attack_range() -> bool:
	var offset: Vector2 = target.global_position - global_position
	return absf(offset.x) <= stats.attack_range and absf(offset.y) <= stats.depth_tolerance


## Moves toward `point` with per-axis speed caps (no overshoot).
func _steer_to(point: Vector2, speed: float) -> void:
	var to_point: Vector2 = point - global_position
	var dt: float = _physics_dt()
	velocity = Vector2(clampf(to_point.x / dt, -speed, speed), clampf(to_point.y / dt, -_vertical_speed(), _vertical_speed()))
	_move_and_clamp()


func _vertical_speed() -> float:
	return stats.move_speed * stats.vertical_speed_ratio


func _physics_dt() -> float:
	return 1.0 / float(Engine.physics_ticks_per_second)


func _move_and_clamp() -> void:
	move_and_slide()
	if movement_bounds.size != Vector2.ZERO:
		global_position = global_position.clamp(movement_bounds.position, movement_bounds.end)


func _face_target() -> void:
	if target == null:
		return
	var dx: float = target.global_position.x - global_position.x
	if absf(dx) > stats.facing_deadzone:
		facing_x = signf(dx)


func _target_alive() -> bool:
	return target != null and is_instance_valid(target) and not target.health.is_dead()


func _distance_to_target() -> float:
	return global_position.distance_to(target.global_position)


func _roll(min_value: float, max_value: float) -> float:
	return _rng.randf_range(minf(min_value, max_value), maxf(min_value, max_value))


func _release_token() -> void:
	_has_token = false
	_token_time = 0.0
	if _tokens != null:
		_tokens.release(get_instance_id())


# --- Attack ----------------------------------------------------------------

func _begin_attack() -> void:
	_current_attack = stats.attack
	_hit_targets.clear()
	_projectile_fired = false
	velocity = Vector2.ZERO
	if not stats.is_ranged():
		var shape: RectangleShape2D = _hitbox_shape.shape as RectangleShape2D
		shape.size = _current_attack.hitbox_size
		hitbox.position = Vector2(_current_attack.hitbox_offset.x * facing_x, _current_attack.hitbox_offset.y)
		# Monitoring starts now so overlaps are known when ACTIVE begins; hits
		# are only resolved during ACTIVE.
		hitbox.monitoring = true
	_attack_phase = AttackPhase.STARTUP
	attack_started.emit(_current_attack)
	attack_phase_changed.emit(_attack_phase)


func _end_attack() -> void:
	hitbox.set_deferred(&"monitoring", false)
	_attack_phase = AttackPhase.NONE
	_current_attack = null
	_release_token()
	attack_phase_changed.emit(_attack_phase)


func _process_attack(delta: float) -> void:
	_state_time += delta
	var attack: AttackData = _current_attack
	if _state_time >= attack.get_total_duration():
		velocity = Vector2.ZERO
		_attack_timer = _roll(stats.attack_cooldown_min, stats.attack_cooldown_max)
		_change_state(State.WAIT_RING if _target_alive() else State.IDLE)
		return
	var phase: AttackPhase = _phase_for_time(attack, _state_time)
	if phase != _attack_phase:
		_attack_phase = phase
		if phase == AttackPhase.RECOVERY:
			# The turn is over: free the token so the next attacker can start.
			_release_token()
		attack_phase_changed.emit(_attack_phase)
	if phase == AttackPhase.ACTIVE:
		velocity = Vector2(facing_x * attack.lunge_speed, 0.0)
		if attack.lunge_speed != 0.0:
			_move_and_clamp()
		if stats.is_ranged():
			_fire_projectile()
		else:
			_resolve_hits()
	else:
		velocity = Vector2.ZERO


func _phase_for_time(attack: AttackData, elapsed: float) -> AttackPhase:
	if elapsed < attack.startup:
		return AttackPhase.STARTUP
	if elapsed < attack.startup + attack.active:
		return AttackPhase.ACTIVE
	return AttackPhase.RECOVERY


func _resolve_hits() -> void:
	for area: Area2D in hitbox.get_overlapping_areas():
		var victim: Hurtbox = area as Hurtbox
		if victim == null or _hit_targets.has(victim):
			continue
		_hit_targets.append(victim)
		var impact: Vector2 = hitbox.global_position.lerp(victim.global_position, 0.5)
		var hit: HitInfo = HitInfo.new(_current_attack, self, Vector2(facing_x, 0.0), impact)
		if victim.receive_hit(hit):
			hit_landed.emit(victim, hit)


func _fire_projectile() -> void:
	if _projectile_fired:
		return
	_projectile_fired = true
	var data: ProjectileData = stats.projectile
	var shot: EnemyProjectile = EnemyProjectile.new()
	shot.setup(data, facing_x, movement_bounds)
	get_parent().add_child(shot)
	shot.global_position = global_position + Vector2(data.spawn_offset.x * facing_x, 0.0)
	projectile_fired.emit(shot)


# --- Damage / death ---------------------------------------------------------

func _on_hurtbox_hit_received(hit: HitInfo) -> void:
	if state == State.DEAD:
		return
	_alerted = true
	health.take_damage(hit.attack.damage)
	apply_hit_stop(hit.attack.hit_stop_duration)
	hit_taken.emit(hit)
	var armored: bool = state == State.ATTACK and stats.armor_during_attack and not health.is_dead()
	if not armored:
		_knockback.start(hit.direction * hit.attack.knockback_speed * stats.knockback_scale, hit.attack.knockback_duration)
	_attack_timer = maxf(_attack_timer, stats.post_hurt_attack_delay)
	if health.is_dead():
		_change_state(State.DEAD)
	elif not armored:
		_hurt_duration = hit.attack.hitstun_duration * stats.hitstun_scale
		_change_state(State.HURT)


func _process_hurt(delta: float) -> void:
	_state_time += delta
	velocity = _knockback.step(delta)
	_move_and_clamp()
	if _state_time >= _hurt_duration:
		velocity = Vector2.ZERO
		_change_state(State.WAIT_RING if _target_alive() else State.IDLE)


func _process_dead(delta: float) -> void:
	_state_time += delta
	velocity = _knockback.step(delta)
	if velocity != Vector2.ZERO:
		global_position += velocity * delta
		if movement_bounds.size != Vector2.ZERO:
			global_position = global_position.clamp(movement_bounds.position, movement_bounds.end)
	if _state_time >= stats.corpse_linger + stats.corpse_fade:
		queue_free()
