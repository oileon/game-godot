class_name BossStats
extends EnemyStats
## Tunables for a boss on top of EnemyStats. HP, move speed, awareness/
## positioning, hit-reaction (hitstun_scale/knockback_scale/armor_during_attack)
## etc. are all inherited for free - a boss is still "one shared Enemy-family
## class driven entirely by data," it just has more than one attack to choose
## between (see `attack_patterns` below) instead of the single `attack` field
## common enemies use.
##
## Implements: design/game-brief.md MVP feature 5 (1 mini boss).
## Story: production/epics/ragnarok-brawler/story-004-mini-boss.md

@export_group("Boss attack patterns")
## 2-4 attacks MiniBoss._choose_pattern() picks between at the start of every
## ATTACK (never repeats the immediately-previous one - see the doc comment
## on MiniBoss). Author at least one fast/short-range pattern and one slow/
## wide-or-long-range pattern so the choices read as different threats to
## dodge, not just different damage numbers.
##
## The inherited `attack` field (from EnemyStats) is NOT used by MiniBoss for
## attack selection - it only exists to satisfy Enemy._ready()'s
## `stats.attack != null` assert. Set it to one of the entries below (any one)
## as a harmless default; MiniBoss._begin_attack() always overrides the actual
## per-swing choice from `attack_patterns`.
@export var attack_patterns: Array[AttackData] = []
## Relative weight per entry in `attack_patterns` (same size/order). Missing or
## empty = uniform (1.0 each). Only matters with 3+ patterns - with exactly 2
## patterns, "never repeat the previous one" alone already forces strict
## alternation regardless of these weights.
@export var pattern_weights: Array[float] = []

@export_group("Boss placeholder look")
## Any attack pattern whose `startup` is at least this long gets the extra
## wide ground telegraph zone drawn by BossPlaceholderVisual, so a slow/heavy
## pattern reads as visibly different from a fast one (not just a differently
## sized rectangle on the same marker).
@export var heavy_telegraph_startup: float = 0.5
