class_name HealthComponent
extends Node
## Tracks HP for an actor. Pure logic, no presentation.
##
## Implements: design/game-brief.md (character has HP and a death state). Story 001.

## Emitted whenever current HP changes.
signal health_changed(current: int, maximum: int)
## Emitted once when HP reaches 0.
signal died

## Maximum HP (set via setup()).
var max_health: int = 1
## Current HP.
var current_health: int = 1


## Initialises max and current HP (full health).
func setup(p_max_health: int) -> void:
	max_health = maxi(p_max_health, 1)
	current_health = max_health
	health_changed.emit(current_health, max_health)


## Removes HP (clamped at 0). Returns the HP actually removed. Emits `died` on reaching 0.
func take_damage(amount: int) -> int:
	if is_dead() or amount <= 0:
		return 0
	var before: int = current_health
	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		died.emit()
	return before - current_health


## True when HP is 0.
func is_dead() -> bool:
	return current_health <= 0
