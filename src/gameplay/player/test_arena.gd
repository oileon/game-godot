class_name TestArena
extends Node2D
## Test scene driver for Story 001: wires the player, dummies, hit effects,
## camera and HUD for a side-scrolling belt-scroller level (corrected from an
## earlier top-down pass - see the story's "Rework note", 2026-10-01).
## Test scaffolding only - Story 006 owns the real stage.
##
## Extra debug keys: H = deal a test hit to the player (exercises HP / hurt /
## death), R = reload the arena.
## Story: production/epics/ragnarok-brawler/story-001-swordsman-core-moveset.md

## Width of the level (px). Wider than one screen (1280) so the camera's
## horizontal scroll is demonstrable; also sizes the camera's X clamp.
@export var level_width: float = 2800.0
## Top of the depth lane (feet-position Y clamp) - a shallow band, not the
## old full-arena height. Up/down input moves within this lane only.
@export var lane_top: float = 430.0
## Bottom of the depth lane (feet-position Y clamp).
@export var lane_bottom: float = 570.0
## Camera2D.position_smoothing_speed - how quickly the view catches up to the
## player's X. Higher = snappier, lower = softer/laggier.
@export var camera_follow_speed: float = 5.0
## Attack used by the H debug key to hurt the player.
@export var test_player_hit: AttackData

@onready var _actors: Node2D = $Actors
@onready var _player: Swordsman = $Actors/Swordsman
@onready var _hud: TestArenaHud = $Hud
@onready var _camera: Camera2D = $Camera2D


func _ready() -> void:
	var lane: Rect2 = Rect2(0.0, lane_top, level_width, lane_bottom - lane_top)
	_player.movement_bounds = lane
	for child: Node in _actors.get_children():
		var dummy: TargetDummy = child as TargetDummy
		if dummy != null:
			dummy.movement_bounds = lane
	_player.hit_landed.connect(_on_player_hit_landed)
	_hud.bind(_player)
	_setup_camera()


func _physics_process(_delta: float) -> void:
	# Camera follows the player's X only - the depth lane is shallow enough
	# that panning on Y would just reveal empty space above/below it.
	_camera.global_position.x = _player.global_position.x


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
	var effect: HitEffectPlaceholder = HitEffectPlaceholder.new()
	effect.setup(hit.attack.hit_effect_radius, hit.attack.hit_effect_duration, hit.attack.hit_effect_color)
	effect.position = hit.hit_position + Vector2(0.0, -30.0)
	_actors.add_child(effect)


## Configures the Camera2D added in test_arena.tscn: clamped to the level's
## bounds, smoothed horizontal follow, fixed Y (no vertical scroll - the
## level's visual height matches the viewport, so nothing beyond the backdrop/
## floor is ever shown). Looked up via @onready $NodePath, not a NodePath-
## wired typed export - see the project's known NodePath-export landmine.
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
