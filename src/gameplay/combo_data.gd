class_name ComboData
extends Resource
## Data-driven combo rules for a character. Saved under assets/data/combo/.
##
## Implements: design/game-brief.md MVP feature 3 (combo system with animation
## cancelling). Per-attack cancel windows live on AttackData.cancel_window_start.
## Story: production/epics/ragnarok-brawler/story-002-combo-chain-cancelling.md

## Ordered basic-attack chain (step 0 is the opener). The last step can only be
## continued by the heavy finisher; after it the chain ends.
@export var steps: Array[ComboStep] = []
## Attack performed when heavy is pressed inside a step's chain window. It ends
## the combo (the chain resets afterwards). Null disables the heavy branch.
@export var heavy_finisher: AttackData
## Seconds with no continuing input (no attack started, no hit connected)
## before the combo counter resets.
@export var combo_timeout: float = 0.8
## Seconds a press is remembered before it expires if it could not be used yet.
@export var input_buffer_duration: float = 0.2
