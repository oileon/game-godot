class_name AttackTokenPool
extends RefCounted
## Pure-logic attack-token coordinator: at most `max_tokens` holders at a time.
## Fairness is a deterministic FIFO queue - an enemy that asks while all tokens
## are taken is queued, and a free token goes to the longest-waiting requester.
## An enemy that just attacked re-enters at the back, so the same enemy cannot
## keep winning. No randomness here (determinism); jitter lives in the enemies'
## injected RNG.
##
## Callers identify themselves with an int id (e.g. Object.get_instance_id()).
## A requester must keep calling request() every frame it still wants a token,
## and call withdraw() when it stops wanting one (hurt, dead, left the ring).
##
## Implements: design/game-brief.md core loop (control a horde) - Story 003 AC4
## "attackers are staggered so the player can read threats".

## Maximum simultaneous holders.
var max_tokens: int = 2

var _holders: Array[int] = []
var _queue: Array[int] = []


func _init(p_max_tokens: int = 2) -> void:
	max_tokens = maxi(p_max_tokens, 1)


## Asks for a token. Returns true if `id` holds one after the call (already held,
## or granted now). Otherwise `id` is queued and false is returned.
func request(id: int) -> bool:
	if _holders.has(id):
		return true
	if not _queue.has(id):
		_queue.append(id)
	var free_tokens: int = max_tokens - _holders.size()
	if free_tokens > 0 and _queue.find(id) < free_tokens:
		_queue.erase(id)
		_holders.append(id)
		return true
	return false


## Releases a held token (no effect if `id` holds none). Keeps queue position
## state untouched.
func release(id: int) -> void:
	_holders.erase(id)


## Releases any held token AND removes `id` from the wait queue.
func withdraw(id: int) -> void:
	_holders.erase(id)
	_queue.erase(id)


## True if `id` currently holds a token.
func holds(id: int) -> bool:
	return _holders.has(id)


## Number of tokens currently held.
func holder_count() -> int:
	return _holders.size()


## Number of requesters waiting for a token.
func waiting_count() -> int:
	return _queue.size()


## Copy of the current holder ids (oldest grant first).
func get_holders() -> Array[int]:
	return _holders.duplicate()
