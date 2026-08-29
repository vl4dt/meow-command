class_name RatMissile
extends Node2D
## A cute rat tumbling down from the sky toward the cat city.
## Kinds:
##   NORMAL   — standard rat, +10.
##   SPLITTER — bigger, +25; when killed it splits into 2 fast CHILD rats.
##   CHILD    — small, fast, +15, non-splitting; brief spawn-grace so the
##              split reads clearly and isn't instantly re-killed.

enum Kind { NORMAL, SPLITTER, CHILD }

const RADIUS := 14.0
const SPLITTER_RADIUS := 22.0
const CHILD_RADIUS := 10.0

var kind: int = Kind.NORMAL
var velocity := Vector2.ZERO
var target := Vector2.ZERO
var landed := false
var dead := false  # killed by a player explosion
var spawn_grace := 0.0  # seconds of kill-invulnerability (splitter children)
var trail: Array[Vector2] = []


## Collision radius depends on the kind (splitter is bigger, child smaller).
func get_radius() -> float:
	match kind:
		Kind.SPLITTER:
			return SPLITTER_RADIUS
		Kind.CHILD:
			return CHILD_RADIUS
		_:
			return RADIUS


## Visual scale so one drawing routine serves all three kinds.
func _scale() -> float:
	match kind:
		Kind.SPLITTER:
			return 1.6
		Kind.CHILD:
			return 0.7
		_:
			return 1.0


func _body_color() -> Color:
	if kind == Kind.SPLITTER:
		return Palette.RAT_SPLITTER
	return Palette.RAT_BODY


func launch(from: Vector2, aim: Vector2, speed: float) -> void:
	position = from
	target = aim
	velocity = (aim - from).normalized() * speed


func _process(delta: float) -> void:
	if spawn_grace > 0.0:
		spawn_grace = maxf(0.0, spawn_grace - delta)
	if landed or dead:
		return
	var step := velocity * delta
	if (position - target).length() <= step.length():
		position = target
		landed = true
	else:
		position += step
	trail.append(position)
	if trail.size() > 18:
		trail.pop_front()
	queue_redraw()


func _draw() -> void:
	# Soft dotted trail (drawn unscaled, in the original coordinate style).
	for i in trail.size():
		var t := float(i) / float(maxi(1, trail.size() - 1))
		draw_circle(trail[i], 1.5 + 3.5 * t, Color(Palette.RAT_TRAIL, 0.12 + 0.4 * t))
	# Body (scaled per kind).
	var s := _scale()
	var body := _body_color()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(s, s))
	var time := Time.get_ticks_msec() * 0.001
	var wag := sin(time * 9.0 + position.x * 0.05)
	# Wagging tail
	draw_circle(Vector2(-9, 10 + wag * 2.0), 4.0, Palette.RAT_EAR)
	# Body
	draw_circle(Vector2(0, 9), 8.5, body)
	# Head
	draw_circle(Vector2(0, -3), 11.0, body)
	# Ears
	draw_circle(Vector2(-10.5, -9), 5.5, Palette.RAT_EAR)
	draw_circle(Vector2(10.5, -9), 5.5, Palette.RAT_EAR)
	# Muzzle
	draw_circle(Vector2(0, 1), 6.0, Palette.RAT_MUZZLE)
	# Eyes + shine
	draw_circle(Vector2(-4.5, -7), 1.9, Palette.RAT_EYE)
	draw_circle(Vector2(4.5, -7), 1.9, Palette.RAT_EYE)
	draw_circle(Vector2(-3.9, -7.7), 0.7, Color("white"))
	draw_circle(Vector2(5.1, -7.7), 0.7, Color("white"))
	# Nose
	draw_circle(Vector2(0, -1.5), 1.7, Palette.RAT_NOSE)
	# Happy tongue
	draw_circle(Vector2(0, 3.5 + wag), 2.3, Palette.RAT_TONGUE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
