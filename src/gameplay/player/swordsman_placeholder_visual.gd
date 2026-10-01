class_name SwordsmanPlaceholderVisual
extends Node2D
## PLACEHOLDER presentation for the Swordsman, drawn in code with simple shapes.
## Replace this node with a PixelLab AnimatedSprite2D later; it only reads the
## Swordsman's public getters, so no logic changes when swapped.
##
## Story: production/epics/ragnarok-brawler/story-001-swordsman-core-moveset.md

## The logic node this visual presents. Exported for inspector visibility, but
## NOT relied on to auto-resolve from the scene's `NodePath("..")` value — a
## typed-Node @export assigned via NodePath did not resolve on instantiate
## (observed on 4.7.2: stayed null, verified with a headless diagnostic), so
## `_ready()` below falls back to the parent, which is always correct for
## this node's place in the scene.
@export var actor: Swordsman


func _ready() -> void:
	if actor == null:
		actor = get_parent() as Swordsman

# PLACEHOLDER palette (original, not derived from any Ragnarok asset).
const COLOR_SHADOW: Color = Color(0.0, 0.0, 0.0, 0.35)
const COLOR_BODY: Color = Color(0.25, 0.45, 0.85)
const COLOR_LEGS: Color = Color(0.2, 0.2, 0.3)
const COLOR_HEAD: Color = Color(0.95, 0.8, 0.65)
const COLOR_HAIR: Color = Color(0.45, 0.25, 0.1)
const COLOR_SWORD: Color = Color(0.85, 0.9, 0.95)
const COLOR_HITBOX_DEBUG: Color = Color(1.0, 0.2, 0.2, 0.35)
const COLOR_HURT_TINT: Color = Color(1.0, 0.45, 0.45)
const COLOR_IFRAME_TINT: Color = Color(0.5, 0.9, 1.0, 0.55)
const SWORD_LENGTH: float = 34.0
const HAND_POSITION: Vector2 = Vector2(10.0, -26.0)


func _process(_delta: float) -> void:
	if actor == null:
		return
	scale.x = actor.facing_x
	if actor.state == Swordsman.State.HURT:
		modulate = COLOR_HURT_TINT
	elif actor.is_invulnerable() and actor.state != Swordsman.State.DEAD:
		modulate = COLOR_IFRAME_TINT
	else:
		modulate = Color.WHITE
	queue_redraw()


func _draw() -> void:
	if actor == null:
		return
	# Shadow stays on the ground plane - only the body/sword draws rise with
	# jump_height, so a jump reads clearly even with placeholder art.
	_draw_shadow()
	var jump_offset: Vector2 = Vector2(0.0, -actor.jump_height)
	draw_set_transform(jump_offset)
	if actor.state == Swordsman.State.DEAD:
		# PLACEHOLDER fallen body.
		draw_rect(Rect2(-22.0, -14.0, 44.0, 14.0), COLOR_BODY.darkened(0.5))
		draw_circle(Vector2(-26.0, -8.0), 9.0, COLOR_HEAD.darkened(0.5))
		draw_set_transform(Vector2.ZERO)
		return
	draw_rect(Rect2(-9.0, -14.0, 7.0, 14.0), COLOR_LEGS)
	draw_rect(Rect2(2.0, -14.0, 7.0, 14.0), COLOR_LEGS)
	draw_rect(Rect2(-12.0, -38.0, 24.0, 26.0), COLOR_BODY)
	draw_circle(Vector2(0.0, -48.0), 10.0, COLOR_HEAD)
	draw_rect(Rect2(-10.0, -60.0, 20.0, 8.0), COLOR_HAIR)
	_draw_attack_overlay()
	_draw_sword()
	draw_set_transform(Vector2.ZERO)


func _draw_shadow() -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in 16:
		var angle: float = TAU * float(i) / 16.0
		points.append(Vector2(cos(angle) * 18.0, sin(angle) * 6.0))
	draw_colored_polygon(points, COLOR_SHADOW)


func _sword_angle() -> float:
	var attack: AttackData = actor.get_current_attack()
	var rest_angle: float = deg_to_rad(40.0)
	if attack == null:
		return rest_angle
	var t: float = actor.get_state_time()
	var raised: float = deg_to_rad(-140.0)
	var swept: float = deg_to_rad(60.0)
	match actor.get_attack_phase():
		Swordsman.AttackPhase.STARTUP:
			return lerpf(rest_angle, raised, clampf(t / maxf(attack.startup, 0.001), 0.0, 1.0))
		Swordsman.AttackPhase.ACTIVE:
			return lerpf(raised, swept, clampf((t - attack.startup) / maxf(attack.active, 0.001), 0.0, 1.0))
		Swordsman.AttackPhase.RECOVERY:
			var rec_t: float = (t - attack.startup - attack.active) / maxf(attack.recovery, 0.001)
			return lerpf(swept, rest_angle, clampf(rec_t, 0.0, 1.0))
		_:
			return rest_angle


func _draw_sword() -> void:
	var tip: Vector2 = HAND_POSITION + Vector2.from_angle(_sword_angle()) * SWORD_LENGTH
	draw_line(HAND_POSITION, tip, COLOR_SWORD, 4.0)
	draw_circle(HAND_POSITION, 3.0, COLOR_HEAD)


func _draw_attack_overlay() -> void:
	var attack: AttackData = actor.get_current_attack()
	if attack == null:
		return
	if actor.get_attack_phase() == Swordsman.AttackPhase.ACTIVE:
		# Debug view of the live hitbox (PLACEHOLDER aid for tuning/screenshots).
		var rect: Rect2 = Rect2(attack.hitbox_offset - attack.hitbox_size * 0.5, attack.hitbox_size)
		draw_rect(rect, COLOR_HITBOX_DEBUG)
	elif actor.get_attack_phase() == Swordsman.AttackPhase.STARTUP:
		# Telegraph: thin outline of where the hitbox will be.
		var rect_t: Rect2 = Rect2(attack.hitbox_offset - attack.hitbox_size * 0.5, attack.hitbox_size)
		draw_rect(rect_t, Color(1.0, 1.0, 1.0, 0.25), false, 1.0)
