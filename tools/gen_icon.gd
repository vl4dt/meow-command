extends SceneTree
## Generates the 1024×1024 store icon at res://assets/store/icon.png.
## Pure Image math (no rendering context) — headless-safe.
## Run: godot --headless --path . -s res://tools/gen_icon.gd

const SIZE := 1024
const OUT := "res://assets/store/icon.png"
const CORNER := 190.0

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var img := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	_background(img)
	# Ears (behind the head)
	_fill_tri(img, Vector2(250.0, 440.0), Vector2(330.0, 150.0), Vector2(510.0, 340.0), Color("#f7c873"))
	_fill_tri(img, Vector2(774.0, 440.0), Vector2(694.0, 150.0), Vector2(514.0, 340.0), Color("#f7c873"))
	_fill_tri(img, Vector2(300.0, 400.0), Vector2(348.0, 235.0), Vector2(462.0, 352.0), Color("#ff9eb5"))
	_fill_tri(img, Vector2(724.0, 400.0), Vector2(676.0, 235.0), Vector2(562.0, 352.0), Color("#ff9eb5"))
	# Head
	_fill_circle(img, 512.0, 590.0, 310.0, Color("#f7c873"))
	# Muzzle patch
	_fill_circle(img, 512.0, 690.0, 100.0, Color("#ffe3b3"))
	# Eyes
	_fill_circle(img, 392.0, 560.0, 44.0, Color("#3a2e2a"))
	_fill_circle(img, 632.0, 560.0, 44.0, Color("#3a2e2a"))
	_fill_circle(img, 406.0, 546.0, 15.0, Color("white"))
	_fill_circle(img, 646.0, 546.0, 15.0, Color("white"))
	# Cheeks
	_fill_circle(img, 296.0, 664.0, 54.0, Color("#ff9eb5", 0.55))
	_fill_circle(img, 728.0, 664.0, 54.0, Color("#ff9eb5", 0.55))
	# Nose + mouth
	_fill_circle(img, 512.0, 648.0, 27.0, Color("#ff6f91"))
	_arc(img, Vector2(512.0, 660.0), 46.0, deg_to_rad(100.0), deg_to_rad(170.0), 8.0, Color("#5b4a5e"))
	_arc(img, Vector2(512.0, 660.0), 46.0, deg_to_rad(20.0), deg_to_rad(80.0), 8.0, Color("#5b4a5e"))
	# Whiskers
	var ink := Color("#5b4a5e", 0.6)
	_line(img, Vector2(398.0, 636.0), Vector2(248.0, 606.0), 9.0, ink)
	_line(img, Vector2(392.0, 672.0), Vector2(238.0, 672.0), 9.0, ink)
	_line(img, Vector2(398.0, 708.0), Vector2(248.0, 738.0), 9.0, ink)
	_line(img, Vector2(626.0, 636.0), Vector2(776.0, 606.0), 9.0, ink)
	_line(img, Vector2(632.0, 672.0), Vector2(786.0, 672.0), 9.0, ink)
	_line(img, Vector2(626.0, 708.0), Vector2(776.0, 738.0), 9.0, ink)

	if not DirAccess.dir_exists_absolute("res://assets/store"):
		DirAccess.make_dir_recursive_absolute("res://assets/store")
	img.save_png(OUT)
	print("ICON RESULT: PASS (", OUT, " ", img.get_width(), "x", img.get_height(), ")")
	quit(0)


# ----------------------------------------------------------------- painting

func _background(img: Image) -> void:
	var top := Color("#ffd9e8")
	var bottom := Color("#fff3d6")
	var inv := 1.0 / float(SIZE)
	for y in range(SIZE):
		var c: Color = top.lerp(bottom, float(y) * inv)
		for x in range(SIZE):
			var a: float = _rounded_alpha(float(x) + 0.5, float(y) + 0.5)
			if a <= 0.0:
				continue
			img.set_pixel(x, y, Color(c, a))


func _rounded_alpha(px: float, py: float) -> float:
	var x := minf(px, float(SIZE) - px)
	var y := minf(py, float(SIZE) - py)
	if x >= CORNER or y >= CORNER:
		return 1.0
	var dx: float = CORNER - x
	var dy: float = CORNER - y
	var d: float = sqrt(dx * dx + dy * dy)
	if d <= CORNER:
		return 1.0
	return clampf(CORNER - d + 1.0, 0.0, 1.0)


func _fill_circle(img: Image, cx: float, cy: float, r: float, color: Color) -> void:
	var minx := int(floor(cx - r))
	var maxx := int(ceil(cx + r))
	var miny := int(floor(cy - r))
	var maxy := int(ceil(cy + r))
	for y in range(miny, maxy + 1):
		if y < 0 or y >= SIZE:
			continue
		for x in range(minx, maxx + 1):
			if x < 0 or x >= SIZE:
				continue
			var dx: float = float(x) + 0.5 - cx
			var dy: float = float(y) + 0.5 - cy
			if dx * dx + dy * dy <= r * r:
				img.set_pixel(x, y, color)


func _fill_tri(img: Image, a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
	var area := _tri_area(a, b, c)
	if area < 0.5:
		return
	var minx := int(floor(minf(a.x, minf(b.x, c.x))))
	var maxx := int(ceil(maxf(a.x, maxf(b.x, c.x))))
	var miny := int(floor(minf(a.y, minf(b.y, c.y))))
	var maxy := int(ceil(maxf(a.y, maxf(b.y, c.y))))
	for y in range(miny, maxy + 1):
		if y < 0 or y >= SIZE:
			continue
		for x in range(minx, maxx + 1):
			if x < 0 or x >= SIZE:
				continue
			var p := Vector2(float(x) + 0.5, float(y) + 0.5)
			if _tri_area(a, b, p) + _tri_area(b, c, p) + _tri_area(c, a, p) <= area + 0.5:
				img.set_pixel(x, y, color)


func _tri_area(a: Vector2, b: Vector2, c: Vector2) -> float:
	return absf((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y)) * 0.5


func _line(img: Image, a: Vector2, b: Vector2, thickness: float, color: Color) -> void:
	var minx := int(floor(minf(a.x, b.x) - thickness))
	var maxx := int(ceil(maxf(a.x, b.x) + thickness))
	var miny := int(floor(minf(a.y, b.y) - thickness))
	var maxy := int(ceil(maxf(a.y, b.y) + thickness))
	for y in range(miny, maxy + 1):
		if y < 0 or y >= SIZE:
			continue
		for x in range(minx, maxx + 1):
			if x < 0 or x >= SIZE:
				continue
			var p := Vector2(float(x) + 0.5, float(y) + 0.5)
			if _seg_dist(p, a, b) <= thickness:
				img.set_pixel(x, y, color)


func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := (p - a).dot(ab) / ab.length_squared()
	t = clampf(t, 0.0, 1.0)
	return (a + ab * t - p).length()


func _arc(img: Image, center: Vector2, radius: float, a0: float, a1: float, thickness: float, color: Color) -> void:
	var steps := 48
	for i in range(steps + 1):
		var a: float = a0 + (a1 - a0) * float(i) / float(steps)
		var p := center + Vector2(cos(a), sin(a)) * radius
		_fill_circle(img, p.x, p.y, thickness, color)
