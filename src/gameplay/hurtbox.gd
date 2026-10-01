class_name Hurtbox
extends Area2D
## Area that can receive hits. The owner connects to `hit_received` and decides
## what happens (damage, stun, death). The owner also toggles `invulnerable`
## (e.g. during dodge i-frames or after death).
##
## Implements: design/game-brief.md (attacks damage a target). Story 001.

## Emitted when a hit is accepted (not blocked by invulnerability).
signal hit_received(hit: HitInfo)

## While true, incoming hits are ignored.
var invulnerable: bool = false


## Attempts to deliver a hit. Returns true if the hit was accepted.
func receive_hit(hit: HitInfo) -> bool:
	if invulnerable:
		return false
	hit_received.emit(hit)
	return true
