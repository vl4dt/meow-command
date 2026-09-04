class_name Turret
extends Node2D
## A cute cat sitting in a cannon. Aims at the pointer and pops out star
## missiles. Has 3 hp — rats that land on it damage it.
##
## Optional drop-in sprites (see ART_SPECS.md):
##   cat_<skin>.png  — the whole turret (bottom-center anchor), skin from
##                     Meta.skin ("default" | "mochi" | "miso" | "peppermint")
##   turret_barrel.png — rotating barrel (left-center pivot)

const COOLDOWN := 0.32
const RADIUS := 20.0
const MAX_HP := 3

var alive := true
var hp := MAX_HP
var cooldown := 0.0
var aim_angle := -PI / 2.0
var recoil := 0.0  # 1 → 0 after firing
var blink := 0.0  # seconds of closed eyes
var happy := 0.0  # seconds of happy face (easter egg)
var flash := 0.0  # white hit-flash


func update_aim(mouse: Vector2) -> void:
	if not alive:
		return
	aim_angle = (mouse - position).angle()


func try_fire(_target: Vector2) -> bool:
	if not alive or cooldown > 0.0:
		return false
	cooldown = COOLDOWN
	recoil = 1.0
	return true


## One point of damage from a landed rat.
func take_hit() -> void:
	if not alive:
		return
	hp -= 1
	flash = 0.25
	if hp <= 0:
		alive = false


## Easter egg: the cat gets a happy face (game plays a meow).
func set_happy() -> void:
	if alive:
		happy = 1.4


func _process(delta: float) -> void:
	var changed := false
	if cooldown > 0.0:
		cooldown = maxf(0.0, cooldown - delta)
		changed = true
	if recoil > 0.0:
		recoil = maxf(0.0, recoil - delta * 6.0)
		changed = true
	if happy > 0.0:
		happy = maxf(0.0, happy - delta)
		changed = true
	if flash > 0.0:
		flash = maxf(0.0, flash - delta)
		changed = true
	if blink > 0.0:
		blink = maxf(0.0, blink - delta)
		changed = true
	elif randf() < delta * 0.15:
		blink = 0.12
		changed = true
	if changed:
		queue_redraw()


func _draw() -> void:
	if not alive:
		_draw_dead()
		return
	var tex := Assets.tex("cat_" + Meta.skin)
	if tex != null:
		_draw_with_texture(tex)
		return
	_draw_procedural()
	# Hit flash overlay
	if flash > 0.0:
		draw_circle(Vector2(0, -12), 22.0, Color(1.0, 1.0, 1.0, minf(1.0, flash * 4.0) * 0.6))
	# HP pips
	for i in MAX_HP:
		var p := Vector2(-10.0 + i * 10.0, -46.0)
		var filled := i < hp
		_draw_heart(p, 3.5, Palette.HEART if filled else Color(Palette.HEART, 0.25))


func _draw_with_texture(tex: Texture2D) -> void:
	# Barrel (rotating, left-center pivot)
	var barrel := Assets.tex("turret_barrel")
	var recoil_off := -recoil * 5.0
	if barrel != null:
		var s := 26.0 / barrel.get_width()
		draw_set_transform(Vector2(0, -14), aim_angle, Vector2(s, s))
		draw_texture(barrel, Vector2(4.0 + recoil_off / s, -barrel.get_height() / 2.0))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		_draw_barrel(recoil_off)
	# Cat + cannon base (bottom-center anchor), sized ~64×64
	var w := 64.0
	var h := 64.0
	var scale := Vector2(w / tex.get_width(), h / tex.get_height())
	draw_set_transform(Vector2.ZERO, 0.0, scale)
	var tint := Color(2.2, 2.2, 2.2) if flash > 0.0 else Color.WHITE
	draw_texture(tex, Vector2(-w / 2.0, -h), tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# HP pips
	for i in MAX_HP:
		var p := Vector2(-10.0 + i * 10.0, -70.0)
		var filled := i < hp
		_draw_heart(p, 3.5, Palette.HEART if filled else Color(Palette.HEART, 0.25))


func _draw_barrel(recoil_off: float) -> void:
	# Barrel (drawn first so the cat sits in front of it)
	draw_set_transform(Vector2(0, -14), aim_angle, Vector2.ONE)
	draw_rect(Rect2(4.0 + recoil_off, -4.5, 26.0, 9.0), Palette.TURRET_BARREL)
	draw_circle(Vector2(30.0 + recoil_off, 0.0), 5.5, Palette.TURRET_BARREL)
	draw_circle(Vector2(30.0 + recoil_off, 0.0), 2.5, Color("white", 0.7))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_procedural() -> void:
	_draw_barrel(-recoil * 5.0)
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
	# Eyes (blink → closed line; happy → ^ ^ arcs)
	if blink > 0.0:
		draw_line(Vector2(-7.5, -18), Vector2(-2.5, -18), Palette.CAT_EYE, 1.6)
		draw_line(Vector2(2.5, -18), Vector2(7.5, -18), Palette.CAT_EYE, 1.6)
	elif happy > 0.0:
		draw_arc(Vector2(-5, -17), 2.6, PI, TAU, 8, Palette.CAT_EYE, 1.6)
		draw_arc(Vector2(5, -17), 2.6, PI, TAU, 8, Palette.CAT_EYE, 1.6)
	else:
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
	# Happy hearts (easter egg)
	if happy > 0.0:
		var a := minf(1.0, happy)
		_draw_heart(Vector2(-8, -40 - sin(happy * 6.0) * 2.0), 3.0, Color(Palette.HEART, a))
		_draw_heart(Vector2(6, -44 - cos(happy * 5.0) * 2.0), 2.4, Color(Palette.HEART, a))


func _draw_dead() -> void:
	draw_circle(Vector2(0, -6), 18.0, Palette.TURRET_DEAD)
	draw_circle(Vector2(0, -16), 13.0, Palette.TURRET_DEAD)
	for s in [-5.0, 5.0]:
		var p := Vector2(s, -18)
		draw_line(p + Vector2(-2.5, -2.5), p + Vector2(2.5, 2.5), Palette.CAT_EYE, 1.8)
		draw_line(p + Vector2(-2.5, 2.5), p + Vector2(2.5, -2.5), Palette.CAT_EYE, 1.8)


func _draw_heart(c: Vector2, r: float, color: Color) -> void:
	draw_circle(c + Vector2(-r * 0.45, -r * 0.25), r * 0.62, color)
	draw_circle(c + Vector2(r * 0.45, -r * 0.25), r * 0.62, color)
	var pts := PackedVector2Array([
		c + Vector2(-r * 0.95, 0.0), c + Vector2(r * 0.95, 0.0),
		c + Vector2(0.0, r * 1.15),
	])
	draw_colored_polygon(pts, color)
