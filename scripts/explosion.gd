class_name Explosion
extends Node2D
## A soft pastel boom. Grows, holds, then shrinks — pops any rats inside.

const LIFE := 0.95
const GROW_TIME := 0.4
const HOLD_TIME := 0.25

var max_radius := 55.0
var age := 0.0
var done := false
var kills_rats := true


func _process(delta: float) -> void:
	age += delta
	if age >= LIFE:
		done = true
	queue_redraw()


func current_radius() -> float:
	if age <= 0.0:
		return 0.0
	if age < GROW_TIME:
		return max_radius * (age / GROW_TIME)
	if age < GROW_TIME + HOLD_TIME:
		return max_radius
	var t := (age - GROW_TIME - HOLD_TIME) / (LIFE - GROW_TIME - HOLD_TIME)
	return max_radius * (1.0 - t)


func _draw() -> void:
	var r := current_radius()
	if r < 1.0:
		return
	var fade := 1.0 - (age / LIFE) * 0.5
	# Optional hand-crafted explosion (center anchor, see ART_SPECS.md)
	var tex := Assets.tex("explosion")
	if tex != null:
		var s := (r * 2.4) / tex.get_width()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(s, s))
		draw_texture(tex, Vector2(-tex.get_width() / 2.0, -tex.get_height() / 2.0), Color(1.0, 1.0, 1.0, 0.85 * fade))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	draw_circle(Vector2.ZERO, r, Color(Palette.EXPLOSION_OUT, 0.3 * fade))
	draw_circle(Vector2.ZERO, r * 0.65, Color(Palette.EXPLOSION_IN, 0.35 * fade))
	var spin := age * 2.5
	for i in 8:
		var a := TAU * float(i) / 8.0 + spin
		var p := Vector2(cos(a), sin(a)) * r * 0.8
		draw_circle(p, 1.8, Color("white", 0.65 * fade))
	# Expanding ring pulse (juice)
	var ring_t := clampf(age / GROW_TIME, 0.0, 1.0)
	draw_arc(Vector2.ZERO, r * (0.9 + 0.25 * ring_t), 0.0, TAU, 40, Color(1.0, 1.0, 1.0, 0.4 * fade * (1.0 - ring_t * 0.5)), 2.0)
