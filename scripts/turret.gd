class_name Turret
extends Node2D
## A cute cat sitting in a cannon. Aims at the mouse and pops out star missiles.

const COOLDOWN := 0.32
const RADIUS := 20.0

var alive := true
var cooldown := 0.0
var aim_angle := -PI / 2.0


func update_aim(mouse: Vector2) -> void:
	if not alive:
		return
	aim_angle = (mouse - position).angle()


func try_fire(_target: Vector2) -> bool:
	if not alive or cooldown > 0.0:
		return false
	cooldown = COOLDOWN
	return true


func _process(delta: float) -> void:
	if cooldown > 0.0:
		cooldown = maxf(0.0, cooldown - delta)
		queue_redraw()


func _draw() -> void:
	if not alive:
		_draw_dead()
		return
	# Barrel (drawn first so the cat sits in front of it)
	draw_set_transform(Vector2(0, -14), aim_angle, Vector2.ONE)
	draw_rect(Rect2(4, -4.5, 26, 9), Palette.TURRET_BARREL)
	draw_circle(Vector2(30, 0), 5.5, Palette.TURRET_BARREL)
	draw_circle(Vector2(30, 0), 2.5, Color("white", 0.7))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Cannon base
	draw_circle(Vector2(0, -6), 18.0, Palette.TURRET_BELLY)
	# Cat ears
	var pts_l := PackedVector2Array([
		Vector2(-13, -22), Vector2(-10, -35), Vector2(-2, -26),
	])
	draw_colored_polygon(pts_l, Palette.TURRET_BODY)
	var pts_r := PackedVector2Array([
		Vector2(13, -22), Vector2(10, -35), Vector2(2, -26),
	])
	draw_colored_polygon(pts_r, Palette.TURRET_BODY)
	# Head
	draw_circle(Vector2(0, -16), 13.0, Palette.TURRET_BODY)
	# Eyes
	draw_circle(Vector2(-5, -18), 2.0, Palette.CAT_EYE)
	draw_circle(Vector2(5, -18), 2.0, Palette.CAT_EYE)
	draw_circle(Vector2(-4.4, -18.6), 0.7, Color("white"))
	draw_circle(Vector2(5.6, -18.6), 0.7, Color("white"))
	# Nose + little "w" mouth
	draw_circle(Vector2(0, -13.5), 1.3, Palette.CAT_CHEEK)
	draw_arc(Vector2(-2.5, -13), 2.2, 0.0, PI, 8, Palette.CAT_EYE, 1.4)
	draw_arc(Vector2(2.5, -13), 2.2, 0.0, PI, 8, Palette.CAT_EYE, 1.4)
	# Blush
	draw_circle(Vector2(-9, -14), 2.5, Color(Palette.CAT_CHEEK, 0.6))
	draw_circle(Vector2(9, -14), 2.5, Color(Palette.CAT_CHEEK, 0.6))


func _draw_dead() -> void:
	draw_circle(Vector2(0, -6), 18.0, Palette.TURRET_DEAD)
	draw_circle(Vector2(0, -16), 13.0, Palette.TURRET_DEAD)
	for s in [-5.0, 5.0]:
		var p := Vector2(s, -18)
		draw_line(p + Vector2(-2.5, -2.5), p + Vector2(2.5, 2.5), Palette.CAT_EYE, 1.8)
		draw_line(p + Vector2(-2.5, 2.5), p + Vector2(2.5, -2.5), Palette.CAT_EYE, 1.8)
