class_name TargetDummy
extends StaticBody2D
## Test target with HP: takes damage, is knocked back, stuns, dies, respawns.
## NOT an enemy (no AI) - real enemies are Story 003.
##
## Root is a StaticBody2D (not a plain Node2D) so the dummy has a real solid
## footprint the player collides with - the project's own first side-scrolling
## pass shipped target dummies with only an Area2D hurtbox, and Areas never
## physically block CharacterBody2D.move_and_slide(); the player walked
## straight through them. Fixed by adding a SolidCollision shape on this body
## (collision_layer = 8, a new bit distinct from the existing hurtbox/hitbox
## layers 1/2/4) and setting Swordsman's collision_mask to include it. `extends
## StaticBody2D` is a strict superset of `Node2D` (PhysicsBody2D ->
## CollisionObject2D -> Node2D), so the direct `global_position` writes below
## (knockback, respawn) are unaffected.
##
## Story: production/epics/ragnarok-brawler/story-001-swordsman-core-moveset.md
##
## States: IDLE -> HURT -> IDLE, any live state -> DEAD -> (respawn) IDLE.

## Dummy states.
enum State { IDLE, HURT, DEAD }

## Emitted when a hit is applied (for presentation, e.g. flash).
signal hit_taken(hit: HitInfo)
## Emitted on death.
signal died
## Emitted after respawning.
signal respawned

## Data-driven tunables.
@export var stats: TargetDummyStats
## World-space rectangle the dummy is clamped to. Zero size = unbounded.
@export var movement_bounds: Rect2 = Rect2()

## Current state.
var state: State = State.IDLE

var _state_time: float = 0.0
var _freeze_left: float = 0.0
var _hurt_duration: float = 0.0
var _knockback: KnockbackMotion = KnockbackMotion.new()
var _spawn_position: Vector2

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox


func _ready() -> void:
	assert(stats != null, "TargetDummy requires a TargetDummyStats resource")
	_spawn_position = global_position
	health.setup(stats.max_hp)
	hurtbox.hit_received.connect(_on_hurtbox_hit_received)


func _physics_process(delta: float) -> void:
	if _freeze_left > 0.0:
		_freeze_left = maxf(_freeze_left - delta, 0.0)
		return
	match state:
		State.HURT:
			_state_time += delta
			_apply_knockback(delta)
			if _state_time >= _hurt_duration:
				_set_state(State.IDLE)
		State.DEAD:
			_state_time += delta
			_apply_knockback(delta)
			if stats.respawn_delay > 0.0 and _state_time >= stats.respawn_delay:
				_respawn()
		_:
			pass


## Freezes the dummy for `duration` seconds (hit-stop).
func apply_hit_stop(duration: float) -> void:
	_freeze_left = maxf(_freeze_left, duration)


## Seconds spent in the current state.
func get_state_time() -> float:
	return _state_time


func _set_state(next: State) -> void:
	state = next
	_state_time = 0.0


func _apply_knockback(delta: float) -> void:
	global_position += _knockback.step(delta) * delta
	if movement_bounds.size != Vector2.ZERO:
		global_position = global_position.clamp(movement_bounds.position, movement_bounds.end)


func _on_hurtbox_hit_received(hit: HitInfo) -> void:
	if state == State.DEAD:
		return
	health.take_damage(hit.attack.damage)
	apply_hit_stop(hit.attack.hit_stop_duration)
	_knockback.start(hit.direction * hit.attack.knockback_speed * stats.knockback_scale, hit.attack.knockback_duration)
	_hurt_duration = hit.attack.hitstun_duration
	hit_taken.emit(hit)
	if health.is_dead():
		hurtbox.invulnerable = true
		_set_state(State.DEAD)
		died.emit()
	else:
		_set_state(State.HURT)


func _respawn() -> void:
	global_position = _spawn_position
	_knockback.cancel()
	health.setup(stats.max_hp)
	hurtbox.invulnerable = false
	_set_state(State.IDLE)
	respawned.emit()
