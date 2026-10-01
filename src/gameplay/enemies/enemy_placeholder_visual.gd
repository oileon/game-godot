class_name EnemyPlaceholderVisual
extends Node2D
## PLACEHOLDER presentation for an Enemy, drawn in code (distinct silhouette and
## colour per type from EnemyStats). Replaced by PixelLab sprites later. Reads
## the Enemy's getters/signals only - no logic.
##
## Shows: shadow, body, facing mark, type label, HP bar, a growing red
## telegraph marker during attack STARTUP, a hit flash and the death fade.
## Story: production/epics/ragnarok-brawler/story-003-enemies-horde-ai.md

## The enemy presented. Not NodePath-wired in the scene (typed-node export
## landmine); resolved from the parent in _ready().
var enemy: Enemy
## Duration of the white hit flash (presentation only).
@export var flash_duration: float = 0.1

const COLOR_SHADOW: Color = Color(0.0, 0.0, 0.0, 0.35)
const COLOR_BAR_BACK: Color = Color(0.1, 0.1, 0.1, 0.8)
const COLOR_BAR_FILL: Color = Color(0.85, 0.2, 0.2)
const COLOR_TELEGRAPH: Color = Color(1.0, 0.15, 0.1)
const COLOR_TOKEN: Color = Color(1.0, 0.85, 0.2)

var _flash_left: float = 0.0


func _ready() -> void:
	enemy = get_parent() as Enemy
	if enemy != null:
		enemy.hit_taken.connect(_on_hit_taken)


func _process(delta: float) -> void:
	if enemy == null:
		return
	_flash_left = maxf(_flash_left - delta, 0.0)
	var base: Color = Color.WHITE
	base.a = enemy.get_corpse_alpha()
	modulate = base.lerp(Color(3.0, 3.0, 3.0, base.a), _flash_left / maxf(flash_duration, 0.001))
	queue_redraw()


func _on_hit_taken(_hit: HitInfo) -> void:
	_flash_left = flash_duration


func _draw() -> void:
	if enemy == null or enemy.stats == null:
		return
	var stats: EnemyStats = enemy.stats
	var size: Vector2 = stats.body_size
	var shadow: PackedVector2Array = PackedVector2Array()
	for i: int in 16:
		var angle: float = TAU * float(i) / 16.0
		shadow.append(Vector2(cos(angle) * size.x * 0.6, sin(angle) * 6.0))
	draw_colored_polygon(shadow, COLOR_SHADOW)

	var dead: bool = enemy.is_dead()
	var color: Color = stats.body_color
	if dead:
		color = color.darkened(0.5)
	_draw_body(stats.silhouette, size, color, dead)
	if dead:
		return

	var face: float = enemy.facing_x
	draw_circle(Vector2(face * size.x * 0.22, -size.y * 0.7), maxf(size.x * 0.07, 2.0), Color.WHITE)
	if enemy.has_attack_token():
		draw_circle(Vector2(0.0, -size.y - 22.0), 3.0, COLOR_TOKEN)
	var progress: float = enemy.get_telegraph_progress()
	if enemy.get_attack_phase() == Enemy.AttackPhase.STARTUP:
		var pulse: float = 0.5 + 0.5 * sin(enemy.get_state_time() * 40.0)
		var tele: Color = COLOR_TELEGRAPH
		tele.a = 0.35 + 0.5 * pulse
		var mark_y: float = -size.y - 34.0
		draw_rect(Rect2(-4.0, mark_y - 10.0 - 10.0 * progress, 8.0, 12.0 + 10.0 * progress), tele)
		draw_circle(Vector2(0.0, mark_y + 8.0), 4.0, tele)
		_draw_attack_zone(enemy.get_current_attack(), face, tele)
	elif enemy.get_attack_phase() == Enemy.AttackPhase.ACTIVE:
		_draw_attack_zone(enemy.get_current_attack(), face, Color(1.0, 1.0, 1.0, 0.6))

	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(-size.x * 0.5, -size.y - 34.0 + (0.0 if progress == 0.0 and enemy.get_attack_phase() != Enemy.AttackPhase.STARTUP else -22.0)), "PLACEHOLDER %s" % stats.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(1.0, 1.0, 1.0, 0.8))
	var ratio: float = float(enemy.health.current_health) / float(maxi(enemy.health.max_health, 1))
	var bar_w: float = maxf(size.x, 36.0)
	draw_rect(Rect2(-bar_w * 0.5, -size.y - 14.0, bar_w, 5.0), COLOR_BAR_BACK)
	draw_rect(Rect2(-bar_w * 0.5, -size.y - 14.0, bar_w * ratio, 5.0), COLOR_BAR_FILL)


func _draw_body(silhouette: EnemyStats.Silhouette, size: Vector2, color: Color, dead: bool) -> void:
	if dead:
		draw_rect(Rect2(-size.x * 0.5, -size.y * 0.25, size.x, size.y * 0.25), color)
		return
	match silhouette:
		EnemyStats.Silhouette.SPIKY_TRIANGLE:
			draw_colored_polygon(PackedVector2Array([
				Vector2(-size.x * 0.5, 0.0), Vector2(-size.x * 0.25, -size.y * 0.6), Vector2(-size.x * 0.35, -size.y),
				Vector2(0.0, -size.y * 0.75), Vector2(size.x * 0.35, -size.y), Vector2(size.x * 0.25, -size.y * 0.6),
				Vector2(size.x * 0.5, 0.0)]), color)
		EnemyStats.Silhouette.HEAVY_BOX:
			draw_rect(Rect2(-size.x * 0.5, -size.y * 0.8, size.x, size.y * 0.8), color)
			draw_rect(Rect2(-size.x * 0.3, -size.y, size.x * 0.6, size.y * 0.25), color.lightened(0.15))
			draw_rect(Rect2(-size.x * 0.5, -size.y * 0.8, size.x, size.y * 0.1), color.darkened(0.3))
		EnemyStats.Silhouette.TALL_DIAMOND:
			draw_colored_polygon(PackedVector2Array([
				Vector2(0.0, 0.0), Vector2(size.x * 0.5, -size.y * 0.45), Vector2(0.0, -size.y), Vector2(-size.x * 0.5, -size.y * 0.45)]), color)
			draw_line(Vector2(enemy.facing_x * size.x * 0.5, -size.y * 0.7), Vector2(enemy.facing_x * size.x * 0.5, -size.y * 0.2), color.lightened(0.4), 3.0)


## Outlines the melee hitbox zone (telegraph) for the attack about to land.
func _draw_attack_zone(attack: AttackData, face: float, color: Color) -> void:
	if attack == null or enemy.stats.is_ranged():
		return
	var centre: Vector2 = Vector2(attack.hitbox_offset.x * face, attack.hitbox_offset.y)
	draw_rect(Rect2(centre - attack.hitbox_size * 0.5, attack.hitbox_size), Color(color.r, color.g, color.b, color.a * 0.35), true)
	draw_rect(Rect2(centre - attack.hitbox_size * 0.5, attack.hitbox_size), color, false, 2.0)
