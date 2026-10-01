class_name KnockbackMotion
extends RefCounted
## Linearly decaying knockback velocity. Call step() once per physics frame
## and move the owner by the returned velocity.
##
## Implements: design/game-brief.md (knockback impact feedback). Story 001.

var _velocity: Vector2 = Vector2.ZERO
var _duration: float = 0.0
var _elapsed: float = 0.0


## Starts (or restarts) a knockback. A duration <= 0 means no knockback.
func start(velocity: Vector2, duration: float) -> void:
	_velocity = velocity
	_duration = duration
	_elapsed = 0.0


## Advances by `delta` and returns the knockback velocity for this frame (px/s).
func step(delta: float) -> Vector2:
	if not is_active():
		return Vector2.ZERO
	_elapsed += delta
	var remaining: float = clampf(1.0 - _elapsed / _duration, 0.0, 1.0)
	return _velocity * remaining


## True while the knockback has not finished.
func is_active() -> bool:
	return _duration > 0.0 and _elapsed < _duration


## Stops any knockback immediately.
func cancel() -> void:
	_duration = 0.0
	_elapsed = 0.0
