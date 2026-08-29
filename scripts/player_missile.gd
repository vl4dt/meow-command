class_name PlayerMissile
extends Node2D
## A little star missile fired by the cat turrets.

const RADIUS := 6.0
const SPEED := 700.0

var velocity := Vector2.ZERO
var target := Vector2.ZERO
var exploded := false  # reached its endpoint (or hit a rat)
var boomed := false  # an explosion was already spawned for it


func launch(from: Vector2, aim: Vector2) -> void:
	position = from
	target = aim
	velocity = (aim - from).normalized() * SPEED


func _process(delta: float) -> void:
	if exploded:
		return
	var step := velocity * delta
	if (position - target).length() <= step.length():
		position = target
		exploded = true
	else:
		position += step
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 7.0, Color(Palette.PLAYER_MISSILE, 0.3))
	draw_circle(Vector2.ZERO, 4.0, Palette.PLAYER_MISSILE)
	draw_circle(Vector2.ZERO, 1.6, Color("white"))
