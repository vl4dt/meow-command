class_name BiscuitDrop
extends Node2D
## A tasty biscuit that falls slowly and wobbles. Tap to collect
## (+25 points, +2 biscuits). Expires after a few seconds (blinks when
## about to vanish). Optional drop-in: assets/sprites/biscuit.png.

const FALL_SPEED := 55.0
const LIFE := 7.0
const REST_Y := 640.0

var life: float = LIFE
var t: float = 0.0
var done := false
var base_x := 0.0


func setup(pos: Vector2) -> void:
	position = pos
	base_x = pos.x


func _process(delta: float) -> void:
	t += delta
	life -= delta
	if life <= 0.0:
		done = true
		return
	position.y += FALL_SPEED * delta
	position.x = base_x + sin(t * 3.0) * 14.0
	if position.y > REST_Y:
		position.y = REST_Y
		life = minf(life, 1.2)  # start expiring once it lands
	queue_redraw()


func _draw() -> void:
	var a := 1.0
	if life < 1.5:
		a = maxf(0.0, life / 1.5)
		if fmod(t * 6.0, 1.0) > 0.5:
			a *= 0.35
	var tex := Assets.tex("biscuit")
	if tex != null:
		draw_texture(tex, Vector2(-tex.get_width() / 2.0, -tex.get_height() / 2.0), Color(1.0, 1.0, 1.0, a))
		return
	# Procedural biscuit: golden circle, darker rim, little paw print.
	draw_circle(Vector2.ZERO, 13.0, Color(0.76, 0.56, 0.3, a))
	draw_circle(Vector2.ZERO, 11.5, Color(0.95, 0.78, 0.45, a))
	var pad := Color(0.76, 0.56, 0.3, a)
	draw_circle(Vector2(0.0, 2.5), 3.6, pad)
	draw_circle(Vector2(-4.6, -3.0), 2.2, pad)
	draw_circle(Vector2(0.0, -5.0), 2.2, pad)
	draw_circle(Vector2(4.6, -3.0), 2.2, pad)
