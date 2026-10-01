class_name ProjectileData
extends Resource
## Tunables for a simple travelling projectile (ranged enemy shot).
##
## Story: production/epics/ragnarok-brawler/story-003-enemies-horde-ai.md

## Damage / knockback / hitstun / hit-stop delivered on hit (timing fields are
## unused for projectiles).
@export var attack: AttackData
## Travel speed (px/s).
@export var speed: float = 260.0
## Seconds before the projectile expires on its own.
@export var lifetime: float = 2.5
## Collision radius (px).
@export var radius: float = 9.0
## Spawn offset from the shooter's feet, authored facing right. X = forward,
## Y = height above the ground (negative is up).
@export var spawn_offset: Vector2 = Vector2(24.0, -34.0)
## Extra distance beyond the level bounds before the projectile is discarded.
@export var out_of_bounds_margin: float = 64.0
## Colour of the PLACEHOLDER projectile.
@export var color: Color = Color(0.5, 1.0, 0.4)
