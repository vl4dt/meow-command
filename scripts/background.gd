extends Node2D
## Paints the pastel sky, sleepy sun, drifting clouds, and the meadow.

const SCREEN := Vector2(1280, 720)
const GROUND_Y := 664.0

var _sky_tex: GradientTexture2D
var _clouds: Array = []
var sun_blink_t := 0.0  # easter egg: the sun blinks when tapped


## Easter egg — called by game.gd when the sun is tapped.
func sun_blink() -> void:
	sun_blink_t = 1.0


func _ready() -> void:
	_sky_tex = _make_sky()
	var rng := RandomNumberGenerator.new()
	for i in 5:
		_clouds.append({
			"pos": Vector2(rng.randf_range(-200.0, 1400.0), rng.randf_range(50.0, 260.0)),
			"scale": rng.randf_range(0.7, 1.5),
			"speed": rng.randf_range(4.0, 12.0),
		})


func _process(delta: float) -> void:
	if sun_blink_t > 0.0:
		sun_blink_t = maxf(0.0, sun_blink_t - delta * 2.0)
	for c in _clouds:
		var p: Vector2 = c["pos"]
		p.x += c["speed"] * delta
		if p.x > SCREEN.x + 160.0:
			p.x = -160.0
		c["pos"] = p
	queue_redraw()


func _make_sky() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Palette.SKY_TOP)
	g.set_color(1, Palette.SKY_BOTTOM)
	g.add_point(0.55, Palette.SKY_MID)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0.0, 0.0)
	tex.fill_to = Vector2(0.0, 1.0)
	tex.width = 4
	tex.height = int(SCREEN.y)
	return tex


func _draw() -> void:
	# Optional hand-crafted full background (1280×720, no clouds — see
	# ART_SPECS.md). Code-drawn clouds float on top of it.
	var bg := Assets.tex("background")
	if bg != null:
		draw_texture_rect(bg, Rect2(Vector2.ZERO, SCREEN), true)
		for c in _clouds:
			_draw_cloud(c["pos"], c["scale"])
		return
	draw_texture_rect(_sky_tex, Rect2(Vector2.ZERO, SCREEN), true)
	# Sleepy sun with a face (blinks when tapped)
	var sun := Vector2(1120.0, 120.0)
	draw_circle(sun, 52.0, Color(Palette.SUN, 0.35))
	draw_circle(sun, 40.0, Palette.SUN)
	if sun_blink_t > 0.0:
		draw_arc(sun + Vector2(-13, -6), 4.5, 0.0, TAU, 12, Palette.SUN_FACE, 2.5)
		draw_arc(sun + Vector2(13, -6), 4.5, 0.0, TAU, 12, Palette.SUN_FACE, 2.5)
	else:
		draw_circle(sun + Vector2(-13, -6), 3.5, Palette.SUN_FACE)
		draw_circle(sun + Vector2(13, -6), 3.5, Palette.SUN_FACE)
	draw_arc(sun + Vector2(0, 4), 14.0, 0.4, TAU - 0.4, 24, Palette.SUN_FACE, 3.0)
	# Rolling hills (bottom halves hidden by the ground band)
	_draw_hill(Vector2(300, GROUND_Y + 30), 460.0, 150.0, Palette.HILL_FAR)
	_draw_hill(Vector2(920, GROUND_Y + 40), 560.0, 190.0, Palette.HILL_NEAR)
	# Meadow
	draw_rect(Rect2(0, GROUND_Y, SCREEN.x, SCREEN.y - GROUND_Y), Palette.GROUND)
	draw_rect(Rect2(0, GROUND_Y, SCREEN.x, 6), Palette.GROUND_EDGE)
	# A few flowers
	for i in 7:
		var fx := 90.0 + i * 170.0
		draw_circle(Vector2(fx, GROUND_Y + 22), 3.0, Color("white", 0.9))
		draw_circle(Vector2(fx, GROUND_Y + 22), 1.4, Palette.SUN)
	# Clouds float on top
	for c in _clouds:
		_draw_cloud(c["pos"], c["scale"])


func _draw_hill(center: Vector2, w: float, h: float, color: Color) -> void:
	draw_set_transform(center, 0.0, Vector2(w / 2.0, h / 2.0))
	draw_circle(Vector2.ZERO, 1.0, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_cloud(p: Vector2, s: float) -> void:
	draw_set_transform(p, 0.0, Vector2(s, s))
	draw_circle(Vector2(-26, 4), 16.0, Palette.CLOUD)
	draw_circle(Vector2(0, -6), 22.0, Palette.CLOUD)
	draw_circle(Vector2(26, 4), 17.0, Palette.CLOUD)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
