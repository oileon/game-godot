class_name EnemyStats
extends Resource
## All tunables for one enemy type. One shared Enemy class is driven entirely by
## this data (saved as .tres under assets/data/enemies/); behaviour differences
## between the rusher, brute and ranged types come from these values.
##
## Ranged behaviour is derived from data: an enemy with a `projectile` fires it
## instead of using a melee hitbox, and `retreat_distance` > 0 makes it back
## away from the player.
##
## Implements: design/game-brief.md MVP feature 4 (3-5 common enemy types).
## Story: production/epics/ragnarok-brawler/story-003-enemies-horde-ai.md

## Silhouette of the PLACEHOLDER code-drawn body (replaced by sprites later).
enum Silhouette { SPIKY_TRIANGLE, HEAVY_BOX, TALL_DIAMOND }

## Display name (HUD / debug / placeholder label).
@export var display_name: StringName = &"enemy"

@export_group("Body")
## Starting and maximum HP.
@export var max_hp: int = 40
## Horizontal move speed (px/s).
@export var move_speed: float = 120.0
## Depth-lane speed as a fraction of move_speed.
@export_range(0.0, 1.5, 0.05) var vertical_speed_ratio: float = 0.7

@export_group("Awareness and positioning (pixels)")
## Distance at which an idle enemy notices the player on its own (EncounterGroup
## can also alert enemies explicitly).
@export var aggro_range: float = 700.0
## Horizontal distance from the player at which this enemy holds its ring slot.
@export var preferred_range: float = 130.0
## Max horizontal distance from which an attack may start.
@export var attack_range: float = 70.0
## Horizontal distance from the player this enemy walks to when it holds an
## attack token (should be <= attack_range).
@export var attack_stand_distance: float = 55.0
## Max depth-lane (Y) misalignment allowed when starting an attack.
@export var depth_tolerance: float = 14.0
## Distance to the ring slot at which the enemy counts as arrived.
@export var arrive_tolerance: float = 10.0
## While retreating, stop drifting toward the slot once this close to it
## (fraction of arrive_tolerance) - tighter than normal arrival so a retreating
## enemy does not oscillate between "drift toward slot" and "back away".
@export_range(0.1, 1.0, 0.05) var retreat_settle_fraction: float = 0.5
## If a waiting enemy drifts further than this from its slot it goes back to
## APPROACH (the player moved a long way).
@export var ring_leash: float = 160.0
## While waiting, if the player is closer than this (X) the enemy backs away.
## 0 = never retreats (melee types).
@export var retreat_distance: float = 0.0
## Retreat speed as a fraction of move_speed.
@export_range(0.0, 3.0, 0.05) var retreat_speed_scale: float = 1.0
## Horizontal distance from the player's facing line at which facing direction
## actually flips (deadzone, px) - prevents facing from flickering when the
## player is almost directly overhead/below.
@export var facing_deadzone: float = 4.0

@export_group("Attack")
## Timing, damage, hitbox and impact of the enemy's attack. For a projectile
## enemy only the timing is used (the shot spawns when ACTIVE begins); damage
## and impact come from projectile.attack.
@export var attack: AttackData
## Projectile fired at the start of ACTIVE (null = melee enemy).
@export var projectile: ProjectileData
## Seconds an attack-token holder may take to reach attack range before the
## token is taken back.
@export var token_hold_timeout: float = 3.0

@export_group("Attack pacing (seconds)")
## Bounds of the randomised delay before the first attack request after alert.
@export var initial_attack_delay_min: float = 0.4
@export var initial_attack_delay_max: float = 1.4
## Bounds of the randomised cool-down after an attack finishes.
@export var attack_cooldown_min: float = 1.2
@export var attack_cooldown_max: float = 2.2
## Minimum delay before this enemy may request a token again after being hit.
@export var post_hurt_attack_delay: float = 0.5

@export_group("Hit reaction")
## Multiplier on the incoming attack's hitstun (1 = full; low = hard to stagger).
@export_range(0.0, 2.0, 0.05) var hitstun_scale: float = 1.0
## Multiplier on incoming knockback (1 = full, 0 = immovable).
@export_range(0.0, 2.0, 0.05) var knockback_scale: float = 1.0
## If true, hits received during ATTACK deal damage but do not flinch or push
## the enemy (a "heavy" telegraphed attack cannot be cancelled by spamming).
@export var armor_during_attack: bool = false
## Seconds a corpse stays fully visible before it starts fading.
@export var corpse_linger: float = 0.8
## Seconds the corpse takes to fade out before it is removed.
@export var corpse_fade: float = 0.5

@export_group("Placeholder look")
## Body colour of the PLACEHOLDER visual.
@export var body_color: Color = Color(0.85, 0.35, 0.15)
## Width/height of the PLACEHOLDER body (px).
@export var body_size: Vector2 = Vector2(34.0, 44.0)
## Shape of the PLACEHOLDER body.
@export var silhouette: Silhouette = Silhouette.SPIKY_TRIANGLE


## True when this enemy fires a projectile instead of swinging a melee hitbox.
func is_ranged() -> bool:
	return projectile != null
