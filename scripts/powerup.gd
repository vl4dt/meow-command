class_name PowerUpDrop
extends Node2D
## A glowing power-up that falls slowly. Tap to activate (one at a time):
##   double — double shot for 8s (two missiles per tap)
##   wide   — wide boom for 8s (explosion radius ×1.5)
##   slow   — slow-mo for 6s (rats fall 45% slower)
##   shield — city shield for 8s (buildings + turrets immune, dome drawn)
## Optional drop-in: assets/sprites/powerup_<type>.png.

const FALL_SPEED := 45.0
const LIFE := 8.0
const REST_Y := 640.0

const COLORS := {
	"double": "6ec6ff",
	"wide": "ffd166",
	"slow": "b39ddb",
	"shield": "8fd694",
}

var ptype: String = "double"
var life: float = LIFE
var t: float = 0.0
var done := false
var base_x := 0.0


func setup(pos: Vector2, type: String) -> void:
	position = pos
	base_x = pos.x
	ptype = type


func _process(delta: float) -> void:
	t += delta
	life -= delta
	if life <= 0.0:
		done = true
		return
	position.y += FALL_SPEED * delta
	position.x = base_x + sin(t * 2.4) * 18.0
	if position.y > REST_Y:
		position.y = REST_Y
		life = minf(life, 1.5)
	queue_redraw()


func _draw() -> void:
	var a := 1.0
	if life < 1.5:
		a = maxf(0.0, life / 1.5)
		if fmod(t * 6.0, 1.0) > 0.5:
			a *= 0.35
	var tex := Assets.tex("powerup_" + ptype)
	if tex != null:
		draw_texture(tex, Vector2(-tex.get_width() / 2.0, -tex.get_height() / 2.0), Color(1.0, 1.0, 1.0, a))
		return
	var c := Color(COLORS.get(ptype, "ffffff"))
	# Sparkle halo (pulses)
	var pulse := 1.0 + 0.12 * sin(t * 5.0)
	draw_circle(Vector2.ZERO, 20.0 * pulse, Color(c, 0.18 * a))
	draw_circle(Vector2.ZERO, 15.0, Color(c, 0.9 * a))
	draw_circle(Vector2.ZERO, 15.0, Color(1.0, 1.0, 1.0, 0.5 * a))
	# Icon
	var ic := Color(0.2, 0.16, 0.22, a)
	match ptype:
		"double":
			draw_circle(Vector2(-4.5, 0.0), 5.0, ic)
			draw_circle(Vector2(4.5, 0.0), 5.0, ic)
		"wide":
			_draw_star(Vector2.ZERO, 9.0, t * 0.8, ic)
		"slow":
			draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 24, ic, 2.5)
			draw_line(Vector2(0.0, 0.0), Vector2(0.0, -5.0), ic, 2.0)
			draw_line(Vector2(0.0, 0.0), Vector2(3.5, 2.0), ic, 2.0)
		"shield":
			var pts := PackedVector2Array([
				Vector2(-7.0, -5.0), Vector2(7.0, -5.0), Vector2(7.0, 2.0),
				Vector2(0.0, 8.0), Vector2(-7.0, 2.0),
			])
			draw_colored_polygon(pts, ic)
		_:
			draw_circle(Vector2.ZERO, 6.0, ic)


func _draw_star(c: Vector2, r: float, rot: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var ang := rot + TAU * i / 10.0
		var rad := r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(ang), sin(ang)) * rad)
	draw_colored_polygon(pts, color)
