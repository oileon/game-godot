class_name EncounterGroup
extends Node2D
## Spawns a group of enemies from EncounterData, owns the attack-token pool and
## the ring layout, and reports when the group is cleared. Drop it into a scene
## (as a child of the y-sorted actor layer) - it is NOT an autoload.
##
## Enemies are added as siblings of this node (so they y-sort with the player);
## the group only tracks them. Death accounting is by count, independent of the
## enemy nodes (which fade and free themselves after their corpse delay).
##
## Call start() after the scene is ready (e.g. `start.call_deferred(player)`) -
## adding children from the parent's _ready() is rejected by Godot.
##
## Implements: design/game-brief.md core loop; Story 003 AC2/AC4/AC6.
## Story: production/epics/ragnarok-brawler/story-003-enemies-horde-ai.md

## Emitted for each enemy right after it is added to the scene.
signal enemy_spawned(enemy: Enemy)
## Emitted once per enemy death.
signal enemy_died(enemy: Enemy)
## Emitted exactly once, when every enemy this group spawned is dead.
signal group_cleared

## The group's spawn list and coordination rules.
@export var encounter: EncounterData
## Base enemy scene instantiated for every spawn (src/gameplay/enemies/enemy.tscn).
@export var enemy_scene: PackedScene
## World rectangle handed to every enemy as its movement clamp. Zero = unbounded.
@export var movement_bounds: Rect2 = Rect2()

var _pool: AttackTokenPool
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _player: Swordsman
var _started: bool = false
var _cleared: bool = false
var _spawned_count: int = 0
var _dead_count: int = 0
## Live enemies in spawn order (dead ones are removed on death).
var _alive: Array[Enemy] = []
## instance id -> ring side (-1/+1), fixed at start from the spawn position.
var _sides: Dictionary = {}
## instance id -> ring tier on its side (recomputed when someone dies).
var _tiers: Dictionary = {}
var _pending_alerts: Array[Enemy] = []
var _pending_delays: Array[float] = []


## Spawns the group and begins the fight: enemies aggro `player`. Does nothing
## if already started. An encounter with no spawns is cleared immediately.
func start(player: Swordsman) -> void:
	if _started:
		return
	assert(encounter != null and enemy_scene != null, "EncounterGroup requires `encounter` and `enemy_scene`")
	_started = true
	_player = player
	_pool = AttackTokenPool.new(encounter.max_attackers)
	_rng.seed = encounter.rng_seed
	var parent: Node = get_parent()
	for spawn: EnemySpawn in encounter.spawns:
		var enemy: Enemy = enemy_scene.instantiate() as Enemy
		enemy.stats = spawn.stats
		enemy.configure(player, movement_bounds, _pool, get_ring_position, _rng)
		var position_in_world: Vector2 = global_position + spawn.offset
		if movement_bounds.size != Vector2.ZERO:
			position_in_world = position_in_world.clamp(movement_bounds.position, movement_bounds.end)
		enemy.position = position_in_world
		_sides[enemy.get_instance_id()] = 1 if position_in_world.x >= player.global_position.x else -1
		enemy.died.connect(_on_enemy_died)
		parent.add_child(enemy)
		enemy.global_position = position_in_world
		_alive.append(enemy)
		_spawned_count += 1
		if spawn.alert_delay <= 0.0:
			enemy.alert()
		else:
			_pending_alerts.append(enemy)
			_pending_delays.append(spawn.alert_delay)
		enemy_spawned.emit(enemy)
	_reassign_tiers()
	_check_cleared()


func _physics_process(delta: float) -> void:
	for i: int in range(_pending_alerts.size() - 1, -1, -1):
		_pending_delays[i] -= delta
		if _pending_delays[i] <= 0.0:
			var enemy: Enemy = _pending_alerts[i]
			if is_instance_valid(enemy):
				enemy.alert()
			_pending_alerts.remove_at(i)
			_pending_delays.remove_at(i)


## Ring slot for `enemy` around the player (used as the enemies' ring provider).
func get_ring_position(enemy: Enemy) -> Vector2:
	var id: int = enemy.get_instance_id()
	return RingLayout.compute(
			_player.global_position,
			int(_sides.get(id, 1)),
			int(_tiers.get(id, 0)),
			enemy.stats.preferred_range,
			encounter.ring_step_x,
			encounter.ring_depth_spread,
			movement_bounds)


## Number of enemies spawned so far.
func get_spawned_count() -> int:
	return _spawned_count


## Number of enemies still alive.
func get_alive_count() -> int:
	return _spawned_count - _dead_count


## True once group_cleared has been emitted.
func is_cleared() -> bool:
	return _cleared


## Live enemies (spawn order). Do not hold the array across frames.
func get_alive_enemies() -> Array[Enemy]:
	return _alive.duplicate()


## Display names of the enemies currently holding an attack token (HUD/debug).
func get_token_holder_names() -> PackedStringArray:
	var names: PackedStringArray = PackedStringArray()
	if _pool == null:
		return names
	for enemy: Enemy in _alive:
		if _pool.holds(enemy.get_instance_id()):
			names.append(String(enemy.stats.display_name))
	return names


func _on_enemy_died(enemy: Enemy) -> void:
	_dead_count += 1
	_alive.erase(enemy)
	_sides.erase(enemy.get_instance_id())
	_tiers.erase(enemy.get_instance_id())
	var pending_index: int = _pending_alerts.find(enemy)
	if pending_index >= 0:
		_pending_alerts.remove_at(pending_index)
		_pending_delays.remove_at(pending_index)
	_pool.withdraw(enemy.get_instance_id())
	enemy_died.emit(enemy)
	_reassign_tiers()
	_check_cleared()


## Tier = how many earlier-spawned live enemies share this enemy's side.
func _reassign_tiers() -> void:
	var count_per_side: Dictionary = {-1: 0, 1: 0}
	for enemy: Enemy in _alive:
		var id: int = enemy.get_instance_id()
		var side: int = _sides[id]
		_tiers[id] = count_per_side[side]
		count_per_side[side] += 1


func _check_cleared() -> void:
	if _cleared or not _started or _dead_count < _spawned_count:
		return
	_cleared = true
	group_cleared.emit()
