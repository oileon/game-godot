class_name EnemySpawn
extends Resource
## One entry of an encounter: which enemy type, where, and when it is alerted.
##
## Story: production/epics/ragnarok-brawler/story-003-enemies-horde-ai.md

## Enemy type data.
@export var stats: EnemyStats
## Spawn position relative to the EncounterGroup's origin (px).
@export var offset: Vector2 = Vector2.ZERO
## Seconds after EncounterGroup.start() before this enemy is alerted (0 = at once).
@export var alert_delay: float = 0.0
