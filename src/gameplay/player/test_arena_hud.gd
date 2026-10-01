class_name TestArenaHud
extends CanvasLayer
## Test-only HUD (PLACEHOLDER): controls help, player HP bar, skill cooldown bar,
## state readout and FPS. Reads the Swordsman via signals/getters only.
## Story: production/epics/ragnarok-brawler/story-001-swordsman-core-moveset.md

var _player: Swordsman
var _help_label: Label
var _state_label: Label
var _hp_bar: ProgressBar
var _hp_label: Label
var _skill_bar: ProgressBar
var _skill_label: Label


func _ready() -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.name = "PlaceholderHudBox"
	box.position = Vector2(12.0, 8.0)
	add_child(box)

	_help_label = Label.new()
	_help_label.text = "PLACEHOLDER HUD | Move: WASD/Arrows | Basic: J/LMB | Heavy: K/RMB | Dodge: Space | Jump: I | Skill: L | H: hurt self | R: reset"
	box.add_child(_help_label)

	_hp_label = Label.new()
	box.add_child(_hp_label)
	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(260.0, 16.0)
	_hp_bar.show_percentage = false
	box.add_child(_hp_bar)

	_skill_label = Label.new()
	box.add_child(_skill_label)
	_skill_bar = ProgressBar.new()
	_skill_bar.custom_minimum_size = Vector2(260.0, 12.0)
	_skill_bar.show_percentage = false
	box.add_child(_skill_bar)

	_state_label = Label.new()
	box.add_child(_state_label)


## Connects the HUD to the player. Call once after the player is ready.
func bind(player: Swordsman) -> void:
	_player = player
	player.health.health_changed.connect(_on_health_changed)
	player.skill_cooldown_changed.connect(_on_skill_cooldown_changed)
	_on_health_changed(player.health.current_health, player.health.max_health)
	_on_skill_cooldown_changed(0.0, player.stats.skill_cooldown)


func _process(_delta: float) -> void:
	if _player == null:
		return
	var phase_name: String = Swordsman.AttackPhase.keys()[_player.get_attack_phase()]
	var state_name: String = Swordsman.State.keys()[_player.state]
	_state_label.text = "State: %s  Phase: %s  FPS: %d" % [state_name, phase_name, Engine.get_frames_per_second()]


func _on_health_changed(current: int, maximum: int) -> void:
	_hp_bar.max_value = maximum
	_hp_bar.value = current
	_hp_label.text = "HP %d / %d" % [current, maximum]


func _on_skill_cooldown_changed(remaining: float, total: float) -> void:
	_skill_bar.max_value = total
	_skill_bar.value = total - remaining
	if remaining <= 0.0:
		_skill_label.text = "Skill [L]: READY"
	else:
		_skill_label.text = "Skill [L]: cooldown %.1fs" % remaining
