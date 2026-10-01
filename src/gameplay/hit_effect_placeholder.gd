class_name HitEffectPlaceholder
extends Node2D
## PLACEHOLDER hit burst: expanding ring plus radiating spikes, then frees itself.
## Replace with real VFX later; spawners only call setup().
## Story: production/epics/ragnarok-brawler/story-001-swordsman-core-moveset.md

const SPIKE_COUNT: int = 8

var _radius: float = 28.0
var _lifetime: float = 0.18
var _color: Color = Color.WHITE
var _elapsed: float = 0.0


## Configures the burst. Call before adding to the tree.
func setup(radius: float, lifetime: float, color: Color) -> void:
	_radius = radius
	_lifetime = maxf(lifetime, 0.01)
	_color = color
	z_index = 10


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _lifetime:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress: float = clampf(_elapsed / _lifetime, 0.0, 1.0)
	var color: Color = Color(_color.r, _color.g, _color.b, 1.0 - progress)
	var ring_radius: float = _radius * (0.3 + 0.7 * progress)
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 24, color, 3.0)
	for i: int in SPIKE_COUNT:
		var dir: Vector2 = Vector2.from_angle(TAU * float(i) / float(SPIKE_COUNT))
		draw_line(dir * ring_radius * 0.5, dir * ring_radius * 1.3, color, 2.0)
