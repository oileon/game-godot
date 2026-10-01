class_name SwordsmanStats
extends Resource
## All tunables for the Swordsman. Saved as assets/data/swordsman_stats.tres.
##
## Implements: design/game-brief.md MVP features 1-2.
## Story: production/epics/ragnarok-brawler/story-001-swordsman-core-moveset.md

@export_group("Health")
## Starting and maximum HP.
@export var max_hp: int = 200

@export_group("Locomotion")
## Horizontal move speed (px/s).
@export var move_speed: float = 220.0
## Multiplier on vertical speed (belt-scroller depth feels slower).
@export_range(0.1, 1.5, 0.05) var vertical_speed_ratio: float = 0.7

@export_group("Jump")
## Initial upward velocity applied to the jump-height axis (px/s).
@export var jump_velocity: float = 480.0
## Downward acceleration applied to the jump-height axis (px/s^2).
@export var jump_gravity: float = 1500.0

@export_group("Dodge")
## Distance covered by a dodge (px).
@export var dodge_distance: float = 110.0
## Total dodge duration (seconds).
@export var dodge_duration: float = 0.22
## Time into the dodge when invulnerability starts (seconds).
@export var dodge_iframe_start: float = 0.02
## Length of the invulnerability window (seconds).
@export var dodge_iframe_duration: float = 0.16
## Time after a dodge before another can start (seconds).
@export var dodge_cooldown: float = 0.4

@export_group("Skill")
## Cooldown of the special skill (seconds).
@export var skill_cooldown: float = 4.0

@export_group("Attacks")
## Fast light attack.
@export var basic_attack: AttackData
## Slow, strong attack.
@export var heavy_attack: AttackData
## Special skill (cooldown-gated).
@export var skill_attack: AttackData

@export_group("Combo")
## Chain / heavy-branch / buffer / timeout rules (Story 002).
@export var combo: ComboData
