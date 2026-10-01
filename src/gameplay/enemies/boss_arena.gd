class_name BossArena
extends Node2D
## Test scene driver for Story 004: the Swordsman fights a single MiniBoss, no
## EncounterGroup/AttackTokenPool/RingLayout (those exist to stagger a HORDE
## and do not apply to a solo 1v1 boss fight). Same side-scrolling lane/camera
## wiring as EnemyArena (minimal wiring copied, not inherited or shared,
## since EnemyArena is Story 003 test scaffolding and is not modified here).
##
## The boss is instantiated and configure()'d in code (not placed directly in
## the scene tree) so configure() runs - per Enemy's documented contract -
## before the node is added to the tree, exactly like EncounterGroup.start()
## does for common enemies.
##
## Debug keys: H = hurt the player, R = reload. A label shows the boss's
## state and HP, and announces when it is defeated.
## Story: production/epics/ragnarok-brawler/story-004-mini-boss.md

## Width of the level (px).
@export var level_width: float = 1800.0
## Top of the depth lane (feet-position Y clamp).
@export var lane_top: float = 430.0
## Bottom of the depth lane (feet-position Y clamp).
@export var lane_bottom: float = 570.0
## Camera2D.position_smoothing_speed.
@export var camera_follow_speed: float = 5.0
## Attack used by the H debug key to hurt the player.
@export var test_player_hit: AttackData
## Boss type data (BossStats). Spawned via configure(), not placed in the scene.
@export var boss_stats: BossStats
## Base boss scene instantiated at _ready() (src/gameplay/enemies/mini_boss.tscn).
@export var boss_scene: PackedScene
## World position the boss spawns at (local to this node).
@export var boss_spawn_offset: Vector2 = Vector2(600.0, 0.0)
## Seed for the boss's injected RNG (pattern selection, attack-delay jitter).
@export var rng_seed: int = 4242

var _boss: MiniBoss
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _debug_label: Label
var _defeated_text: String = ""

@onready var _actors: Node2D = $Actors
@onready var _player: Swordsman = $Actors/Swordsman
@onready var _hud: TestArenaHud = $Hud
@onready var _camera: Camera2D = $Camera2D


func _ready() -> void:
	var lane: Rect2 = Rect2(0.0, lane_top, level_width, lane_bottom - lane_top)
	_player.movement_bounds = lane
	_player.hit_landed.connect(_on_player_hit_landed)
	_hud.bind(_player)
	_setup_camera()
	_setup_debug_label()
	# Spawning adds a child to a parent that is still setting up, so defer.
	_spawn_boss.call_deferred(lane)


func _physics_process(_delta: float) -> void:
	_camera.global_position.x = _player.global_position.x
	if _boss != null and is_instance_valid(_boss):
		_debug_label.text = "PLACEHOLDER BOSS DEBUG | %s | HP: %d / %d | State: %s%s" % [
			_boss.stats.display_name, _boss.health.current_health, _boss.health.max_health,
			Enemy.State.keys()[_boss.state], _defeated_text]
	else:
		_debug_label.text = "PLACEHOLDER BOSS DEBUG | %s" % _defeated_text


func _unhandled_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_H and test_player_hit != null:
		var hit: HitInfo = HitInfo.new(test_player_hit, self, Vector2(-_player.facing_x, 0.0), _player.global_position)
		_player.hurtbox.receive_hit(hit)
	elif key_event.keycode == KEY_R:
		get_tree().reload_current_scene()


func _spawn_boss(lane: Rect2) -> void:
	assert(boss_scene != null and boss_stats != null, "BossArena requires boss_scene and boss_stats")
	_rng.seed = rng_seed
	var boss: MiniBoss = boss_scene.instantiate() as MiniBoss
	boss.stats = boss_stats
	boss.configure(_player, lane, null, Callable(), _rng)
	var spawn_position: Vector2 = global_position + boss_spawn_offset
	if lane.size != Vector2.ZERO:
		spawn_position = spawn_position.clamp(lane.position, lane.end)
	boss.position = spawn_position
	boss.hit_landed.connect(_on_enemy_hit_landed)
	boss.boss_defeated.connect(_on_boss_defeated)
	_actors.add_child(boss)
	boss.global_position = spawn_position
	boss.alert()
	_boss = boss


func _on_player_hit_landed(_hurtbox: Hurtbox, hit: HitInfo) -> void:
	_spawn_hit_effect(hit)


func _on_enemy_hit_landed(_hurtbox: Hurtbox, hit: HitInfo) -> void:
	_spawn_hit_effect(hit)


## Story 006 should listen to MiniBoss.boss_defeated (or its inherited `died`,
## equally valid) on the boss it spawns for the real stage, to advance the
## stage. This test scene just reflects it in the debug label.
func _on_boss_defeated(_boss: MiniBoss) -> void:
	_defeated_text = " | BOSS DEFEATED"


func _spawn_hit_effect(hit: HitInfo) -> void:
	var effect: HitEffectPlaceholder = HitEffectPlaceholder.new()
	effect.setup(hit.attack.hit_effect_radius, hit.attack.hit_effect_duration, hit.attack.hit_effect_color)
	effect.position = hit.hit_position + Vector2(0.0, -30.0)
	_actors.add_child(effect)


func _setup_debug_label() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "BossDebugLayer"
	add_child(layer)
	_debug_label = Label.new()
	_debug_label.position = Vector2(12.0, 150.0)
	layer.add_child(_debug_label)


## Same camera setup as EnemyArena/TestArena: clamped to the level, smoothed X follow.
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
