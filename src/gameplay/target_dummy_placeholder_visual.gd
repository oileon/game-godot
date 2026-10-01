class_name TargetDummyPlaceholderVisual
extends Node2D
## PLACEHOLDER presentation for a TargetDummy (post + arms + HP bar), drawn in code.
## Story: production/epics/ragnarok-brawler/story-001-swordsman-core-moveset.md

## The logic node this visual presents. Exported for inspector visibility, but
## NOT relied on to auto-resolve from the scene's `NodePath("..")` value — see
## the matching note in swordsman_placeholder_visual.gd; `_ready()` below
## falls back to the parent.
@export var target: TargetDummy
## Duration of the white hit flash (presentation only).
@export var flash_duration: float = 0.1

const COLOR_POST: Color = Color(0.55, 0.38, 0.2)
const COLOR_STRAW: Color = Color(0.85, 0.75, 0.4)
const COLOR_SHADOW: Color = Color(0.0, 0.0, 0.0, 0.35)
const COLOR_BAR_BACK: Color = Color(0.1, 0.1, 0.1, 0.8)
const COLOR_BAR_FILL: Color = Color(0.85, 0.2, 0.2)

var _flash_left: float = 0.0


func _ready() -> void:
	if target == null:
		target = get_parent() as TargetDummy
	if target != null:
		target.hit_taken.connect(_on_hit_taken)


func _process(delta: float) -> void:
	if target == null:
		return
	_flash_left = maxf(_flash_left - delta, 0.0)
	var base: Color = Color.WHITE
	if target.state == TargetDummy.State.DEAD:
		base.a = 0.45
	modulate = base.lerp(Color(3.0, 3.0, 3.0, base.a), _flash_left / maxf(flash_duration, 0.001))
	queue_redraw()


func _on_hit_taken(_hit: HitInfo) -> void:
	_flash_left = flash_duration


func _draw() -> void:
	if target == null:
		return
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in 16:
		var angle: float = TAU * float(i) / 16.0
		points.append(Vector2(cos(angle) * 20.0, sin(angle) * 6.0))
	draw_colored_polygon(points, COLOR_SHADOW)
	if target.state == TargetDummy.State.DEAD:
		draw_rect(Rect2(-24.0, -12.0, 48.0, 12.0), COLOR_POST)
		return
	draw_rect(Rect2(-4.0, -52.0, 8.0, 52.0), COLOR_POST)
	draw_rect(Rect2(-22.0, -44.0, 44.0, 8.0), COLOR_STRAW)
	draw_circle(Vector2(0.0, -58.0), 10.0, COLOR_STRAW)
	var ratio: float = float(target.health.current_health) / float(maxi(target.health.max_health, 1))
	draw_rect(Rect2(-20.0, -82.0, 40.0, 5.0), COLOR_BAR_BACK)
	draw_rect(Rect2(-20.0, -82.0, 40.0 * ratio, 5.0), COLOR_BAR_FILL)
