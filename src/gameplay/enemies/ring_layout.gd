class_name RingLayout
extends RefCounted
## Pure helper: where an enemy waits around the player. In a side-scroller the
## "ring" is two columns (left and right of the player) fanned out over the
## depth lane, so waiting enemies do not stack on the same spot.
##
## Story: production/epics/ragnarok-brawler/story-003-enemies-horde-ai.md

## Depth offsets (in units of `depth_spread`) cycled by tier: centre, up, down.
const DEPTH_PATTERN: Array[int] = [0, -1, 1]


## Slot position for an enemy.
## `side`: -1 = left of the player, +1 = right. `tier`: 0 = innermost slot on
## that side, each further tier is `step_x` farther out and uses the next depth
## offset. `bounds` (zero size = unbounded): if the slot would fall outside the
## level horizontally it is mirrored to the other side, then clamped.
##
## KNOWN LIMITATION (godot-gdscript-specialist review, Story 003): if `distance`
## (range_x + tier*step_x) exceeds the room available on BOTH sides of `center`
## - a narrow arena, or a tier stacked deep enough by a large roster - the
## mirrored x is ALSO out of bounds, and the final clamp() silently collapses
## every such slot to the same bounds edge: multiple enemies stack with no
## error. Not reachable with this story's shipped data (max distance ~480px vs
## a 2800px level). The depth-offset bump below reduces the visual collapse
## (slots still separate vertically) but does not fully solve it; a future
## narrower arena (e.g. a boss room) or a larger roster should re-check this
## before reusing ring placement as-is.
static func compute(center: Vector2, side: int, tier: int, range_x: float, step_x: float, depth_spread: float, bounds: Rect2) -> Vector2:
	var distance: float = range_x + float(tier) * step_x
	var depth: float = float(DEPTH_PATTERN[tier % DEPTH_PATTERN.size()]) * depth_spread
	var x: float = center.x + float(side) * distance
	var mirrored: bool = false
	if bounds.size != Vector2.ZERO and (x < bounds.position.x or x > bounds.end.x):
		x = center.x - float(side) * distance
		mirrored = true
	if mirrored and bounds.size != Vector2.ZERO and (x < bounds.position.x or x > bounds.end.x):
		# Both sides overflow (see KNOWN LIMITATION above) - spread remaining
		# slots along depth instead of letting them all collapse to one point.
		depth += float(tier) * depth_spread
	var slot: Vector2 = Vector2(x, center.y + depth)
	if bounds.size != Vector2.ZERO:
		slot = slot.clamp(bounds.position, bounds.end)
	return slot
