class_name FXLayer
extends Node2D
## Lightweight procedural particle layer: puffs, stars, sparks, confetti.
## One CanvasItem, pooled particles — cheap on mobile. Optional drop-in
## textures: res://assets/sprites/fx_puff.png, fx_star.png, fx_spark.png
## (see ART_SPECS.md §5).

const MAX_P := 240
const CONFETTI_COLORS := [
	"ff7ba9", "ffd166", "6ec6ff", "b39ddb", "8fd694",
]

var _ps: Array = []


## Burst of particles at a point. kind: puff | star | spark.
func burst(pos: Vector2, kind: String, scale: float = 1.0) -> void:
	var n := int(5 + scale * 0.25)
	for i in n:
		_add(pos, kind, scale)


## A shower of confetti from the top of the screen (wave clear / NEW BEST).
func confetti() -> void:
	for i in 42:
		_ps.append({
			"pos": Vector2(randf() * 1280.0, -20.0 - randf() * 80.0),
			"vel": Vector2(randf_range(-30.0, 30.0), randf_range(60.0, 170.0)),
			"life": randf_range(1.4, 2.4), "max_life": 2.4,
			"kind": "confetti",
			"size": randf_range(4.0, 7.0),
			"angle": randf() * TAU,
			"spin": randf_range(-8.0, 8.0),
			"ci": i % CONFETTI_COLORS.size(),
		})
	if _ps.size() > MAX_P:
		_ps.resize(MAX_P)


func _add(pos: Vector2, kind: String, scale: float) -> void:
	if _ps.size() >= MAX_P:
		_ps.pop_front()
	var a := randf() * TAU
	var spd := randf_range(24.0, 95.0) * scale
	var life := randf_range(0.35, 0.8)
	_ps.append({
		"pos": pos + Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0)),
		"vel": Vector2(cos(a), sin(a)) * spd,
		"life": life, "max_life": life,
		"kind": kind,
		"size": randf_range(3.0, 7.0) * scale,
		"angle": randf() * TAU,
		"spin": randf_range(-6.0, 6.0),
	})


func _process(delta: float) -> void:
	if _ps.is_empty():
		return
	var alive: Array = []
	for p in _ps:
		p["life"] -= delta
		if p["life"] <= 0.0:
			continue
		p["pos"] += p["vel"] * delta
		if p["kind"] == "confetti":
			p["vel"].y += 50.0 * delta
			p["vel"].x += sin(p["pos"].y * 0.05) * 40.0 * delta
		else:
			p["vel"] *= (1.0 - 2.5 * delta)
			p["vel"].y += 150.0 * delta
		p["angle"] += p["spin"] * delta
		alive.append(p)
	_ps = alive
	queue_redraw()


func _draw() -> void:
	for p in _ps:
		var t: float = float(p["life"]) / float(p["max_life"])
		match p["kind"]:
			"puff":
				var tex := Assets.tex("fx_puff")
				if tex != null:
					var s: float = float(p["size"]) * 3.0
					draw_set_transform(p["pos"], p["angle"], Vector2.ONE)
					draw_texture(tex, Vector2(-s / 2.0, -s / 2.0), Color(1.0, 1.0, 1.0, 0.55 * t))
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				else:
					draw_circle(p["pos"], p["size"] * (1.6 - t * 0.6), Color(0.82, 0.73, 0.66, 0.5 * t))
			"star":
				var tex2 := Assets.tex("fx_star")
				if tex2 != null:
					var s2: float = float(p["size"]) * 2.6
					draw_set_transform(p["pos"], p["angle"], Vector2.ONE)
					draw_texture(tex2, Vector2(-s2 / 2.0, -s2 / 2.0), Color(1.0, 1.0, 1.0, 0.9 * t))
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				else:
					_draw_star(p["pos"], p["size"] * (0.5 + t), p["angle"], Color(1.0, 0.82, 0.4, 0.9 * t))
			"spark":
				draw_circle(p["pos"], p["size"] * 0.5, Color(1.0, 1.0, 1.0, 0.8 * t))
			"confetti":
				var c: Color = Color(CONFETTI_COLORS[p["ci"]])
				draw_set_transform(p["pos"], p["angle"], Vector2.ONE)
				draw_rect(Rect2(-p["size"] / 2.0, -p["size"] / 4.0, p["size"], p["size"] / 2.0), Color(c, 0.9 * t))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			_:
				draw_circle(p["pos"], p["size"] * 0.5, Color(1.0, 1.0, 1.0, 0.5 * t))


func _draw_star(c: Vector2, r: float, rot: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var a := rot + TAU * i / 8.0
		var rad := r if i % 2 == 0 else r * 0.4
		pts.append(c + Vector2(cos(a), sin(a)) * rad)
	draw_colored_polygon(pts, color)
