class_name City
extends Node2D
## A cluster of cute cat houses. Hearts above the roof show remaining health.

signal building_destroyed(pos: Vector2)

const BUILDING_W := 44.0
const BUILDING_GAP := 10.0
const BUILDING_HP := 3

var buildings: Array = []  # {pos, w, h, hp, max_hp, color}
var shielded := false  # City Shield power-up: immune + dome drawn


func setup(x: float, ground_y: float, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in 3:
		var h := rng.randf_range(56.0, 92.0)
		var pos := Vector2(x + (i - 1) * (BUILDING_W + BUILDING_GAP), ground_y)
		buildings.append({
			"pos": pos,
			"w": BUILDING_W,
			"h": h,
			"hp": BUILDING_HP,
			"max_hp": BUILDING_HP,
			"color": Palette.BUILDING_COLORS[(seed + i) % Palette.BUILDING_COLORS.size()],
		})


func alive_count() -> int:
	var n := 0
	for b in buildings:
		if b["hp"] > 0:
			n += 1
	return n


func target_points() -> Array[Vector2]:
	var pts: Array[Vector2] = []
	for b in buildings:
		if b["hp"] > 0:
			pts.append(b["pos"] + Vector2(0, -b["h"] * 0.5))
	return pts


## Damages the NEAREST living building within radius. Returns true if a
## building took the hit (false when shielded or nothing is in range).
func damage_nearest(point: Vector2, radius: float) -> bool:
	if shielded:
		return false
	var best_i := -1
	var best_d := INF
	for i in buildings.size():
		var b: Dictionary = buildings[i]
		if b["hp"] <= 0:
			continue
		var center: Vector2 = b["pos"] + Vector2(0, -b["h"] * 0.5)
		var d := (center - point).length()
		if d < radius + b["w"] * 0.5 and d < best_d:
			best_d = d
			best_i = i
	if best_i < 0:
		return false
	var b: Dictionary = buildings[best_i]
	b["hp"] -= 1
	queue_redraw()
	if b["hp"] <= 0:
		building_destroyed.emit(b["pos"])
	return true


func _draw() -> void:
	for b in buildings:
		_draw_building(b)
	if shielded:
		_draw_shield_dome()


## City Shield power-up: a soft green dome over the whole cluster.
func _draw_shield_dome() -> void:
	var cx := 0.0
	var min_y := 0.0
	for b in buildings:
		var pos: Vector2 = b["pos"]
		cx += pos.x
		min_y = minf(min_y, pos.y - b["h"] - 20.0)
	cx /= float(maxi(1, buildings.size()))
	var r := 110.0
	var pulse := 0.5 + 0.1 * sin(Time.get_ticks_msec() * 0.004)
	draw_arc(Vector2(cx, 0.0), r, PI, TAU, 32, Color(0.56, 0.84, 0.58, pulse), 3.0)
	draw_circle(Vector2(cx, 0.0), r, Color(0.56, 0.84, 0.58, 0.1))


func _draw_building(b: Dictionary) -> void:
	var pos: Vector2 = b["pos"]
	var w: float = b["w"]
	var h: float = b["h"]
	var color: Color = b["color"]
	if b["hp"] <= 0:
		_draw_rubble(pos, w)
		return
	# Optional hand-crafted building (bottom-center anchor, see ART_SPECS.md)
	var tex := Assets.tex("building")
	if tex != null:
		var scale := Vector2(w / tex.get_width(), h / tex.get_height())
		draw_set_transform(Vector2.ZERO, 0.0, scale)
		draw_texture(tex, Vector2((pos.x - w / 2.0) / scale.x, (pos.y - h) / scale.y))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# Health hearts (keep the procedural UI on top of any art)
		var hp: int = b["hp"]
		for i in hp:
			var hx := pos.x - (hp - 1) * 7.0 + i * 14.0
			_draw_heart(Vector2(hx, pos.y - h - 34.0), 4.0, Palette.HEART)
		return
	# Body
	draw_rect(Rect2(pos.x - w / 2.0, pos.y - h, w, h), color)
	# Roof band
	var top_y := pos.y - h - 8.0
	draw_rect(Rect2(pos.x - w / 2.0 - 3.0, top_y, w + 6.0, 10.0), Palette.BUILDING_ROOF)
	# Cat ears on the roof
	_draw_ear(pos + Vector2(-w * 0.5, top_y), w * 0.42, 16.0, color, true)
	_draw_ear(pos + Vector2(w * 0.5, top_y), w * 0.42, 16.0, color, false)
	# Round window
	var wc := pos + Vector2(0, -h * 0.6)
	draw_circle(wc, w * 0.24, Palette.WINDOW)
	draw_arc(wc, w * 0.24, 0.0, TAU, 24, Palette.WINDOW_FRAME, 2.0)
	# Door with a paw knob
	draw_rect(Rect2(pos.x - 8.0, pos.y - 20.0, 16.0, 20.0), Palette.DOOR)
	draw_circle(pos + Vector2(4, -10), 1.5, Palette.WINDOW)
	# Health hearts
	var hp: int = b["hp"]
	for i in hp:
		var hx := pos.x - (hp - 1) * 7.0 + i * 14.0
		_draw_heart(Vector2(hx, pos.y - h - 34.0), 4.0, Palette.HEART)


func _draw_ear(base: Vector2, ew: float, eh: float, color: Color, left: bool) -> void:
	var dir := -1.0 if left else 1.0
	var pts := PackedVector2Array([
		base,
		base + Vector2(dir * ew * 0.2, -eh),
		base + Vector2(dir * ew, 0.0),
	])
	draw_colored_polygon(pts, color)
	var inner := PackedVector2Array([
		base + Vector2(dir * ew * 0.15, -eh * 0.55),
		base + Vector2(dir * ew * 0.28, -eh * 0.85),
		base + Vector2(dir * ew * 0.55, -eh * 0.1),
	])
	draw_colored_polygon(inner, Palette.CAT_CHEEK)


func _draw_heart(c: Vector2, s: float, color: Color) -> void:
	draw_circle(c + Vector2(-s * 0.45, -s * 0.25), s * 0.5, color)
	draw_circle(c + Vector2(s * 0.45, -s * 0.25), s * 0.5, color)
	var tri := PackedVector2Array([
		c + Vector2(-s * 0.9, -s * 0.05),
		c + Vector2(s * 0.9, -s * 0.05),
		c + Vector2(0.0, s * 1.05),
	])
	draw_colored_polygon(tri, color)


func _draw_rubble(pos: Vector2, w: float) -> void:
	var tex := Assets.tex("rubble")
	if tex != null:
		var s := 1.6 * w / tex.get_width()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(s, s))
		draw_texture(tex, Vector2(pos.x / s - tex.get_width() / 2.0, pos.y / s - tex.get_height()))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	draw_circle(pos + Vector2(-w * 0.28, -5.0), 5.0, Palette.RUBBLE)
	draw_circle(pos + Vector2(0.0, -7.0), 6.5, Color(Palette.RUBBLE, 0.85))
	draw_circle(pos + Vector2(w * 0.26, -4.0), 4.0, Color(Palette.RUBBLE, 0.9))
