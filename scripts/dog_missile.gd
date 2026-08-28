class_name DogMissile
extends Node2D
## A cute dog tumbling down from the sky toward the cat city.

const RADIUS := 14.0

var velocity := Vector2.ZERO
var target := Vector2.ZERO
var landed := false
var dead := false  # killed by a player explosion
var trail: Array[Vector2] = []


func launch(from: Vector2, aim: Vector2, speed: float) -> void:
	position = from
	target = aim
	velocity = (aim - from).normalized() * speed


func _process(delta: float) -> void:
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
	# Soft dotted trail
	for i in trail.size():
		var t := float(i) / float(maxi(1, trail.size() - 1))
		draw_circle(trail[i], 1.5 + 3.5 * t, Color(Palette.DOG_TRAIL, 0.12 + 0.4 * t))
	var t := Time.get_ticks_msec() * 0.001
	var wag := sin(t * 9.0 + position.x * 0.05)
	# Wagging tail
	draw_circle(Vector2(-9, 10 + wag * 2.0), 4.0, Palette.DOG_EAR)
	# Body
	draw_circle(Vector2(0, 9), 8.5, Palette.DOG_BODY)
	# Head
	draw_circle(Vector2(0, -3), 11.0, Palette.DOG_BODY)
	# Floppy ears
	draw_circle(Vector2(-10.5, -9), 5.5, Palette.DOG_EAR)
	draw_circle(Vector2(10.5, -9), 5.5, Palette.DOG_EAR)
	# Muzzle
	draw_circle(Vector2(0, 1), 6.0, Palette.DOG_MUZZLE)
	# Eyes + shine
	draw_circle(Vector2(-4.5, -7), 1.9, Palette.DOG_EYE)
	draw_circle(Vector2(4.5, -7), 1.9, Palette.DOG_EYE)
	draw_circle(Vector2(-3.9, -7.7), 0.7, Color("white"))
	draw_circle(Vector2(5.1, -7.7), 0.7, Color("white"))
	# Nose
	draw_circle(Vector2(0, -1.5), 1.7, Palette.DOG_NOSE)
	# Happy tongue
	draw_circle(Vector2(0, 3.5 + wag), 2.3, Palette.DOG_TONGUE)
