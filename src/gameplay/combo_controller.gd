class_name ComboController
extends RefCounted
## Pure-logic combo brain: input buffer, chain window, heavy branch, cancel
## windows and the combo counter. No Node, scene, rendering or Input access -
## the owner (Swordsman) feeds presses and elapsed time and acts on the result,
## so this can be driven by plain method calls in a unit test.
##
## Implements: design/game-brief.md MVP feature 3 (combo system with animation
## cancelling).
## Story: production/epics/ragnarok-brawler/story-002-combo-chain-cancelling.md
##
## Rules:
##  - Buffer: press() remembers a press (one entry per button, newest press of
##    a button replaces the older one). tick() ages entries; an entry older than
##    ComboData.input_buffer_duration expires. Entries are consumed only when
##    they become actionable, oldest first, so a press that arrives early (during
##    startup, or during hit-stop) fires the moment its window opens.
##  - Chain: BASIC inside the current step's chain window -> next step (if any).
##  - Heavy branch: HEAVY inside a chain window -> heavy finisher, combo ends.
##  - Cancel: DODGE / SKILL once the current attack's cancel window has opened
##    (AttackData.cancel_window_start >= 0, ground attacks only) and the move is
##    off cooldown. If the move IS on cooldown the press is NOT consumed: it stays
##    buffered and expires after the buffer duration (or fires if the cooldown
##    ends in time).
##  - Counter: +1 per hit that connects (register_hit). Resets on timeout
##    (no attack started / hit connected for combo_timeout seconds) or reset().

## Emitted when the combo counter changes (0 = reset).
signal count_changed(count: int)

## Buttons the controller understands.
enum PressKind { BASIC, HEAVY, DODGE, SKILL }
## What the owner should do after poll().
enum Action { NONE, CHAIN, HEAVY_FINISHER, CANCEL_DODGE, CANCEL_SKILL }

## Step index meaning "not a chain step" (heavy, skill, airborne attack).
const NO_STEP: int = -1


class BufferedPress:
	var button: int
	var age: float = 0.0

	func _init(p_button: int) -> void:
		button = p_button


var _data: ComboData
var _buffer: Array[BufferedPress] = []
var _count: int = 0
var _since_activity: float = 0.0
var _attack: AttackData
var _step: int = NO_STEP
var _ground: bool = true


## Creates a controller driven by `data`.
func _init(data: ComboData) -> void:
	_data = data


## Remembers a press of `button` (call from input events, even during hit-stop).
func press(button: PressKind) -> void:
	consume(button)
	_buffer.append(BufferedPress.new(button))


## True if an unexpired press of `button` is buffered.
func has_buffered(button: PressKind) -> bool:
	for entry: BufferedPress in _buffer:
		if entry.button == button:
			return true
	return false


## Removes a buffered press of `button`. Returns true if one was present.
func consume(button: PressKind) -> bool:
	for i: int in _buffer.size():
		if _buffer[i].button == button:
			_buffer.remove_at(i)
			return true
	return false


## Ages the buffer and the combo timeout. Call once per unfrozen physics frame
## (hit-stop does not age the buffer, so a freeze never eats a press).
func tick(delta: float) -> void:
	for i: int in range(_buffer.size() - 1, -1, -1):
		_buffer[i].age += delta
		if _buffer[i].age > _data.input_buffer_duration:
			_buffer.remove_at(i)
	_since_activity += delta
	if _count > 0 and _since_activity >= _data.combo_timeout:
		_set_count(0)


## Tells the controller an attack began. `step` is the chain index or NO_STEP;
## `grounded` false (airborne attack) disables chaining and cancelling.
func notify_attack_started(attack: AttackData, step: int, grounded: bool) -> void:
	_attack = attack
	_step = step if grounded else NO_STEP
	_ground = grounded
	_since_activity = 0.0


## Tells the controller the current attack ended (finished, chained or cancelled).
func notify_attack_ended() -> void:
	_attack = null
	_step = NO_STEP


## Counts one connected hit and restarts the combo timeout.
func register_hit() -> void:
	_since_activity = 0.0
	_set_count(_count + 1)


## Clears the counter and buffer (player hit or died).
func reset() -> void:
	_buffer.clear()
	_set_count(0)


## Current combo counter.
func get_count() -> int:
	return _count


## Chain index of the running attack, or NO_STEP.
func get_current_step() -> int:
	return _step


## Attack for chain step `index`.
func get_step_attack(index: int) -> AttackData:
	return _data.steps[index].attack


## Attack the CHAIN action leads to (valid right after poll() returned CHAIN).
func get_chain_attack() -> AttackData:
	return _data.steps[_step + 1].attack


## Step index the CHAIN action leads to.
func get_chain_step() -> int:
	return _step + 1


## The heavy finisher attack (may be null).
func get_finisher_attack() -> AttackData:
	return _data.heavy_finisher


## Looks for a buffered press that is actionable `elapsed` seconds into the
## running attack. A returned action's press is consumed. `can_dodge` /
## `can_skill` are the owner's cooldown checks.
func poll(elapsed: float, can_dodge: bool, can_skill: bool) -> Action:
	if _attack == null:
		return Action.NONE
	for entry: BufferedPress in _buffer:
		var action: Action = _action_for(entry.button as PressKind, elapsed, can_dodge, can_skill)
		if action != Action.NONE:
			_buffer.erase(entry)
			return action
	return Action.NONE


func _action_for(button: PressKind, elapsed: float, can_dodge: bool, can_skill: bool) -> Action:
	match button:
		PressKind.BASIC:
			if _step != NO_STEP and _step + 1 < _data.steps.size() and _in_chain_window(elapsed):
				return Action.CHAIN
		PressKind.HEAVY:
			if _step != NO_STEP and _data.heavy_finisher != null and _in_chain_window(elapsed):
				return Action.HEAVY_FINISHER
		PressKind.DODGE:
			if can_dodge and _in_cancel_window(elapsed):
				return Action.CANCEL_DODGE
		PressKind.SKILL:
			if can_skill and _in_cancel_window(elapsed):
				return Action.CANCEL_SKILL
	return Action.NONE


func _in_chain_window(elapsed: float) -> bool:
	var step: ComboStep = _data.steps[_step]
	return elapsed >= step.chain_window_start and elapsed <= step.chain_window_end


func _in_cancel_window(elapsed: float) -> bool:
	return _ground and _attack.cancel_window_start >= 0.0 and elapsed >= _attack.cancel_window_start


func _set_count(value: int) -> void:
	if value == _count:
		return
	_count = value
	count_changed.emit(_count)
