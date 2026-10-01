class_name HitInfo
extends RefCounted
## Describes one landed hit, passed from a hitbox owner to the victim's Hurtbox.
##
## Implements: design/game-brief.md (impact feedback). Story 001.

## The attack that produced this hit.
var attack: AttackData
## The node that dealt the hit.
var source: Node2D
## Unit-ish direction the victim is pushed (knockback direction).
var direction: Vector2
## World position of the impact (used by presentation to place the hit effect).
var hit_position: Vector2


func _init(p_attack: AttackData, p_source: Node2D, p_direction: Vector2, p_hit_position: Vector2) -> void:
	attack = p_attack
	source = p_source
	direction = p_direction
	hit_position = p_hit_position
