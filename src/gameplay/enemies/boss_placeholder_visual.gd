class_name BossPlaceholderVisual
extends EnemyPlaceholderVisual
## PLACEHOLDER presentation for MiniBoss. Reuses EnemyPlaceholderVisual's body/
## HP-bar/flash/attack-zone drawing UNCHANGED (enemy_placeholder_visual.gd is
## not modified) - the boss's bigger body_size and distinct body_color
## (mini_boss.tres) already make it read as "bigger and more threatening"
## than a common enemy. This subclass adds two boss-only touches:
##
##  - a pair of "horn" marks above the head, so the silhouette reads as a
##    boss even though it reuses the HEAVY_BOX shape family (no new
##    EnemyStats.Silhouette enum value was added - that would require
##    touching the already-reviewed enemy_stats.gd AND
##    enemy_placeholder_visual.gd's _draw_body() match; a visual flourish
##    drawn purely in this subclass avoids both).
##  - a wide ground warning zone + growing ring during STARTUP, for any
##    attack pattern whose `startup` is >= BossStats.heavy_telegraph_startup,
##    so the slow/heavy pattern is visibly distinguishable from the fast one
##    (not just a differently-sized rectangle on the same marker the base
##    class already draws via `_draw_attack_zone()`).
##
## Story: production/epics/ragnarok-brawler/story-004-mini-boss.md

const COLOR_HORN: Color = Color(0.05, 0.02, 0.02, 1.0)
const COLOR_HEAVY_ZONE: Color = Color(1.0, 0.05, 0.6, 1.0)


func _draw() -> void:
	super._draw()
	if enemy == null or enemy.stats == null or enemy.is_dead():
		return
	_draw_horns(enemy.stats.body_size)
	_draw_heavy_telegraph()


## Two small triangular "horns" above the head so the boss silhouette reads
## as distinct from a common enemy using the same body shape family.
func _draw_horns(size: Vector2) -> void:
	var top: float = -size.y
	draw_colored_polygon(PackedVector2Array([
		Vector2(-size.x * 0.3, top), Vector2(-size.x * 0.45, top - size.y * 0.22), Vector2(-size.x * 0.12, top)]), COLOR_HORN)
	draw_colored_polygon(PackedVector2Array([
		Vector2(size.x * 0.3, top), Vector2(size.x * 0.45, top - size.y * 0.22), Vector2(size.x * 0.12, top)]), COLOR_HORN)


## Wide ground strip + growing ring under the attack's reach, drawn only
## during STARTUP and only for patterns at/above heavy_telegraph_startup -
## makes the slow/heavy pattern's telegraph visibly wider and more alarming
## than the fast pattern's, in addition to the base class's hitbox outline.
func _draw_heavy_telegraph() -> void:
	var boss_stats: BossStats = enemy.stats as BossStats
	if boss_stats == null or enemy.get_attack_phase() != Enemy.AttackPhase.STARTUP:
		return
	var attack: AttackData = enemy.get_current_attack()
	if attack == null or attack.startup < boss_stats.heavy_telegraph_startup:
		return
	var progress: float = enemy.get_telegraph_progress()
	var face: float = enemy.facing_x
	var reach: float = attack.hitbox_offset.x + attack.hitbox_size.x * 0.5
	var zone_color: Color = COLOR_HEAVY_ZONE
	zone_color.a = 0.12 + 0.18 * progress
	var zone: Rect2 = Rect2(Vector2(0.0, -6.0), Vector2(face * reach, 12.0)).abs()
	draw_rect(zone, zone_color)
	var ring_color: Color = COLOR_HEAVY_ZONE
	ring_color.a = 0.4 + 0.5 * progress
	draw_arc(Vector2(face * reach, 0.0), 10.0 + 14.0 * progress, 0.0, TAU, 20, ring_color, 3.0, true)
