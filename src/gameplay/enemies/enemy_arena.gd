class_name EnemyArena
extends Node2D
## Test scene driver for Story 003: the Swordsman fights a mixed EncounterGroup
## (2 rushers, 1 brute, 1 ranged) in the same side-scrolling lane/camera setup as
## TestArena (minimal wiring copied rather than inherited, because scene
## inheritance cannot drop TestArena's target dummies). Test scaffolding only -
## Story 006 owns the real stage.
##
## Debug keys: H = hurt the player, R = reload. A small label shows enemies
## alive, attack-token holders and the cleared state.
## Story: production/epics/ragnarok-brawler/story-003-enemies-horde-ai.md

## Width of the level (px).
@export var level_width: float = 2800.0
## Top of the depth lane (feet-position Y clamp).
@export var lane_top: float = 430.0
## Bottom of the depth lane (feet-position Y clamp).
@export var lane_bottom: float = 570.0
## Camera2D.position_smoothing_speed.
@export var camera_follow_speed: float = 5.0
## Attack used by the H debug key to hurt the player.
@export var test_player_hit: AttackData

var _debug_label: Label
var _cleared_text: String = ""

@onready var _actors: Node2D = $Actors
@onready var _player: Swordsman = $Actors/Swordsman
@onready var _group: EncounterGroup = $Actors/EncounterGroup
@onready var _hud: TestArenaHud = $Hud
@onready var _camera: Camera2D = $Camera2D


func _ready() -> void:
	var lane: Rect2 = Rect2(0.0, lane_top, level_width, lane_bottom - lane_top)
	_player.movement_bounds = lane
	_group.movement_bounds = lane
	_player.hit_landed.connect(_on_player_hit_landed)
	_hud.bind(_player)
	_setup_camera()
	_setup_debug_label()
	_group.enemy_spawned.connect(_on_enemy_spawned)
	_group.group_cleared.connect(_on_group_cleared)
	# Spawning adds children to a parent that is still setting up, so defer.
	_group.start.call_deferred(_player)


func _physics_process(_delta: float) -> void:
	_camera.global_position.x = _player.global_position.x
	var holders: PackedStringArray = _group.get_token_holder_names()
	_debug_label.text = "PLACEHOLDER ENEMY DEBUG | Enemies alive: %d / %d | Attack tokens: [%s] %s" % [
		_group.get_alive_count(), _group.get_spawned_count(), ", ".join(holders), _cleared_text]


func _unhandled_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_H and test_player_hit != null:
		var hit: HitInfo = HitInfo.new(test_player_hit, self, Vector2(-_player.facing_x, 0.0), _player.global_position)
		_player.hurtbox.receive_hit(hit)
	elif key_event.keycode == KEY_R:
		get_tree().reload_current_scene()


func _on_player_hit_landed(_hurtbox: Hurtbox, hit: HitInfo) -> void:
	_spawn_hit_effect(hit)


func _on_enemy_spawned(enemy: Enemy) -> void:
	enemy.hit_landed.connect(func(_hurtbox: Hurtbox, hit: HitInfo) -> void: _spawn_hit_effect(hit))
	enemy.projectile_fired.connect(_on_projectile_fired)


func _on_projectile_fired(projectile: EnemyProjectile) -> void:
	projectile.hit_landed.connect(func(_hurtbox: Hurtbox, hit: HitInfo) -> void: _spawn_hit_effect(hit))


func _on_group_cleared() -> void:
	_cleared_text = "| GROUP CLEARED"


func _spawn_hit_effect(hit: HitInfo) -> void:
	var effect: HitEffectPlaceholder = HitEffectPlaceholder.new()
	effect.setup(hit.attack.hit_effect_radius, hit.attack.hit_effect_duration, hit.attack.hit_effect_color)
	effect.position = hit.hit_position + Vector2(0.0, -30.0)
	_actors.add_child(effect)


func _setup_debug_label() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "EnemyDebugLayer"
	add_child(layer)
	_debug_label = Label.new()
	_debug_label.position = Vector2(12.0, 150.0)
	layer.add_child(_debug_label)


## Same camera setup as TestArena: clamped to the level, smoothed X follow.
func _setup_camera() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	_camera.limit_left = 0
	_camera.limit_right = int(level_width)
	_camera.limit_top = 0
	_camera.limit_bottom = int(viewport_size.y)
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = camera_follow_speed
	_camera.global_position = Vector2(_player.global_position.x, viewport_size.y * 0.5)
	_camera.reset_smoothing()
	_camera.make_current()
