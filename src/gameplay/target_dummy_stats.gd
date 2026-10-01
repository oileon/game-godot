class_name TargetDummyStats
extends Resource
## Tunables for a TargetDummy (test target; NOT a real enemy, see Story 003).
##
## Story: production/epics/ragnarok-brawler/story-001-swordsman-core-moveset.md

## Starting and maximum HP.
@export var max_hp: int = 100
## Multiplier on incoming knockback (1 = full, 0 = immovable).
@export_range(0.0, 2.0, 0.05) var knockback_scale: float = 1.0
## Seconds after death before the dummy respawns at full HP (<= 0 = never).
@export var respawn_delay: float = 2.5
