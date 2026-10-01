class_name AttackData
extends Resource
## Data for a single attack (basic, heavy, skill, or a test hit).
##
## Implements: design/game-brief.md MVP feature 2 (basic + heavy + skill).
## Story: production/epics/ragnarok-brawler/story-001-swordsman-core-moveset.md
##
## Every tunable of an attack lives here, saved as a .tres under assets/data/attacks/.
## Hitbox offset is authored for a character facing RIGHT; it is mirrored by facing.

## Identifier used for debugging and presentation lookups.
@export var move_name: StringName = &""

@export_group("Timing (seconds)")
## Wind-up before the hitbox can connect.
@export var startup: float = 0.1
## Window during which the hitbox can connect.
@export var active: float = 0.08
## Cool-down after the active window before the actor is free again.
@export var recovery: float = 0.2

@export_group("Cancelling")
## Seconds into the attack from which a dodge/skill press cancels it (cutting the
## remaining recovery). The window stays open until the attack ends. Negative =
## this attack cannot be cancelled. (Story 002)
@export var cancel_window_start: float = -1.0

@export_group("Damage")
## HP removed from the target on hit.
@export var damage: int = 10

@export_group("Hitbox (pixels, authored facing right)")
## Size of the rectangular hitbox.
@export var hitbox_size: Vector2 = Vector2(56.0, 40.0)
## Centre of the hitbox relative to the attacker's feet.
@export var hitbox_offset: Vector2 = Vector2(40.0, -24.0)
## Forward speed applied to the attacker during the active window (px/s).
@export var lunge_speed: float = 0.0

@export_group("Impact feedback")
## Initial knockback speed applied to the target (px/s); decays linearly.
@export var knockback_speed: float = 160.0
## Time over which the knockback decays to zero (seconds).
@export var knockback_duration: float = 0.12
## Time the target is stunned (HURT) after being hit (seconds).
@export var hitstun_duration: float = 0.25
## Freeze applied to both attacker and target on hit (seconds).
@export var hit_stop_duration: float = 0.06
## Radius of the placeholder hit burst (pixels).
@export var hit_effect_radius: float = 28.0
## Lifetime of the placeholder hit burst (seconds).
@export var hit_effect_duration: float = 0.18
## Colour of the placeholder hit burst.
@export var hit_effect_color: Color = Color(1.0, 0.9, 0.3, 1.0)


## Total duration of the attack: startup + active + recovery (seconds).
func get_total_duration() -> float:
	return startup + active + recovery
