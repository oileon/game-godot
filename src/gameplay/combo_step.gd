class_name ComboStep
extends Resource
## One link of the basic-attack chain: the attack it performs plus the window in
## which a follow-up press continues the combo.
##
## Implements: design/game-brief.md MVP feature 3 (combo system).
## Story: production/epics/ragnarok-brawler/story-002-combo-chain-cancelling.md

## The attack performed by this step.
@export var attack: AttackData
## Seconds into this step (since it began) at which a follow-up press starts to
## continue the chain. A press made earlier is buffered until this moment.
@export var chain_window_start: float = 0.15
## Seconds into this step after which a follow-up press no longer continues the
## chain (it is then treated as the start of a fresh combo).
@export var chain_window_end: float = 0.35
