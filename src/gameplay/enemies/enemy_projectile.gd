class_name EnemyProjectile
extends Area2D
## Straight-flying projectile fired by ranged enemies. Hits the player's
## Hurtbox once through receive_hit() with a HitInfo, then frees itself. It also
## frees itself on expiry or when it leaves the level. A hit rejected by
## invulnerability (dodge i-frames) lets the projectile fly on.
##
## Node origin sits on the ground plane (so y-sorting is sane); the collision
## shape and the PLACEHOLDER drawing are raised by the data's spawn height.
## Collision: layer 0, mask 2 (the player's Hurtbox layer).
##
## Story: production/epics/ragnarok-brawler/story-003-enemies-horde-ai.md

## Emitted when the projectile connects with a hurtbox.
signal hit_landed(hurtbox: Hurtbox, hit: HitInfo)

var _data: ProjectileData
var _direction_x: float = 1.0
var _bounds: Rect2 = Rect2()
var _age: float = 0.0
var _spent: bool = false


## Configures the projectile. Call before adding to the tree. `bounds` is the
## level rectangle (zero size = never discarded for leaving the level).
func setup(data: ProjectileData, direction_x: float, bounds: Rect2) -> void:
	_data = data
	_direction_x = signf(direction_x) if direction_x != 0.0 else 1.0
	_bounds = bounds


func _ready() -> void:
	assert(_data != null and _data.attack != null, "EnemyProjectile requires ProjectileData with an AttackData")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = _data.radius
	shape_node.shape = circle
	shape_node.position = Vector2(0.0, _data.spawn_offset.y)
	add_child(shape_node)
	var visual: _PlaceholderVisual = _PlaceholderVisual.new()
	visual.radius = _data.radius
	visual.color = _data.color
	visual.position = Vector2(0.0, _data.spawn_offset.y)
	add_child(visual)


func _physics_process(delta: float) -> void:
	if _spent:
		return
	_age += delta
	global_position.x += _direction_x * _data.speed * delta
	if _age >= _data.lifetime or _is_out_of_bounds():
		_spent = true
		queue_free()
		return
	for area: Area2D in get_overlapping_areas():
		var target: Hurtbox = area as Hurtbox
		if target == null:
			continue
		var hit: HitInfo = HitInfo.new(_data.attack, self, Vector2(_direction_x, 0.0), global_position + Vector2(0.0, _data.spawn_offset.y))
		if target.receive_hit(hit):
			_spent = true
			hit_landed.emit(target, hit)
			queue_free()
			return


func _is_out_of_bounds() -> bool:
	if _bounds.size == Vector2.ZERO:
		return false
	return global_position.x < _bounds.position.x - _data.out_of_bounds_margin or global_position.x > _bounds.end.x + _data.out_of_bounds_margin


## PLACEHOLDER drawing (glowing orb). Presentation only.
class _PlaceholderVisual extends Node2D:
	var radius: float = 9.0
	var color: Color = Color.WHITE

	func _draw() -> void:
		draw_circle(Vector2.ZERO, radius * 1.4, Color(color.r, color.g, color.b, 0.3))
		draw_circle(Vector2.ZERO, radius, color)
		draw_circle(Vector2.ZERO, radius * 0.45, Color(1.0, 1.0, 1.0, 0.9))
