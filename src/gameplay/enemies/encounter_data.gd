class_name EncounterData
extends Resource
## Data describing one enemy group: who spawns where, and the coordination
## rules (attack tokens, ring layout, RNG seed). A stage defines encounters as
## these resources.
##
## Story: production/epics/ragnarok-brawler/story-003-enemies-horde-ai.md

## Enemies to spawn.
@export var spawns: Array[EnemySpawn] = []
## Max enemies allowed in an attack (token held through STARTUP/ACTIVE) at once.
@export var max_attackers: int = 2
## Extra horizontal distance per ring tier on the same side of the player (px).
@export var ring_step_x: float = 70.0
## Depth-lane offset between ring tiers (px).
@export var ring_depth_spread: float = 40.0
## Seed of the group's RNG (attack-delay jitter) - same seed, same behaviour.
@export var rng_seed: int = 1337
