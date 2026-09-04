class_name RatMissile
extends Node2D
## A cute rat tumbling down from the sky toward the cat city.
## Kinds:
##   NORMAL   — standard rat, +10.
##   SPLITTER — bigger, +25; when killed it splits into 2 fast CHILD rats.
##   CHILD    — small, fast, +15, non-splitting; brief spawn-grace.
##   WEAVE    — +20; sways side to side (sine path).
##   SHELL    — +30; armored, takes 2 hits (flashes on the first).
##   KING     — boss, +100; 5 hp; on death splits into 4 children.
## Classic ground-splits: from wave 8, any rat that reaches 65% of its path
## bursts into 2 children without scoring (flagged ground_split).
##
## Optional drop-in sprites: assets/sprites/rat_<kind>.png (see ART_SPECS.md).

enum Kind { NORMAL, SPLITTER, CHILD, WEAVE, SHELL, KING }

const RADIUS := 14.0
const SPLITTER_RADIUS := 22.0
const CHILD_RADIUS := 10.0
const WEAVE_RADIUS := 14.0
const SHELL_RADIUS := 15.0
const KING_RADIUS := 38.0

var kind: int = Kind.NORMAL
var hp := 1
var landed := false
var dead := false  # killed by a player explosion
var spawn_grace := 0.0  # seconds of kill-invulnerability (splitter children)
var flash := 0.0  # white hit-flash (armored rats taking a non-lethal hit)
var ground_split := false  # died by reaching 65% of the path (no score)
var trail: Array[Vector2] = []

# Path state (straight line + optional perpendicular weave).
var from := Vector2.ZERO
var dir := Vector2.DOWN
var dist := 0.0
var speed := 60.0
var path_len := 600.0
var target := Vector2.ZERO
var weave_amp := 0.0
var splits_at_ground := false
var split_done := false


## Collision radius depends on the kind.
func get_radius() -> float:
	match kind:
		Kind.SPLITTER:
			return SPLITTER_RADIUS
		Kind.CHILD:
			return CHILD_RADIUS
		Kind.WEAVE:
			return WEAVE_RADIUS
		Kind.SHELL:
			return SHELL_RADIUS
		Kind.KING:
			return KING_RADIUS
		_:
			return RADIUS


## Visual scale so one drawing routine serves all kinds.
func _scale() -> float:
	match kind:
		Kind.SPLITTER:
			return 1.6
		Kind.CHILD:
			return 0.7
		Kind.SHELL:
			return 1.05
		Kind.KING:
			return 2.6
		_:
			return 1.0


func _tex_name() -> String:
	match kind:
		Kind.SPLITTER:
			return "rat_splitter"
		Kind.CHILD:
			return "rat_child"
		Kind.WEAVE:
			return "rat_weave"
		Kind.SHELL:
			return "rat_shell"
		Kind.KING:
			return "rat_king"
		_:
			return "rat_normal"


func _body_color() -> Color:
	if kind == Kind.SPLITTER:
		return Palette.RAT_SPLITTER
	if kind == Kind.KING:
		return Palette.RAT_SPLITTER
	return Palette.RAT_BODY


## Configure and place the rat. Called before adding to the tree.
func setup(k: int, from_pos: Vector2, aim: Vector2, spd: float, splits: bool) -> void:
	kind = k
	from = from_pos
	target = aim
	dir = (aim - from).normalized()
	path_len = (aim - from).length()
	speed = spd
	splits_at_ground = splits
	position = from
	match kind:
		Kind.SPLITTER:
			hp = 1
		Kind.CHILD:
			hp = 1
			spawn_grace = 1.0
		Kind.WEAVE:
			hp = 1
			weave_amp = 42.0
		Kind.SHELL:
			hp = 2
		Kind.KING:
			hp = 5
		_:
			hp = 1


## One point of damage. Grace periods ignore hits (split reads clearly).
func take_hit() -> void:
	if dead or landed:
		return
	if spawn_grace > 0.0:
		return
	hp -= 1
	if hp <= 0:
		dead = true
	else:
		flash = 0.18


func _process(delta: float) -> void:
	if spawn_grace > 0.0:
		spawn_grace = maxf(0.0, spawn_grace - delta)
	if flash > 0.0:
		flash = maxf(0.0, flash - delta)
	if landed or dead:
		return
	dist += speed * delta
	if dist >= path_len:
		dist = path_len
		position = target
		landed = true
		return
	var base := from + dir * dist
	if weave_amp > 0.0:
		var perp := dir.rotated(PI / 2.0)
		base += perp * sin(dist * 0.02) * weave_amp
	position = base
	# Classic ground-split: burst into 2 children at 65% of the path.
	if splits_at_ground and not split_done and dist >= path_len * 0.65:
		split_done = true
		ground_split = true
		dead = true
		return
	trail.append(position)
	if trail.size() > 18:
		trail.pop_front()
	queue_redraw()


func _draw() -> void:
	# Soft dotted trail (drawn unscaled, in the original coordinate style).
	for i in trail.size():
		var t := float(i) / float(maxi(1, trail.size() - 1))
		draw_circle(trail[i], 1.5 + 3.5 * t, Color(Palette.RAT_TRAIL, 0.12 + 0.4 * t))
	var s := _scale()
	var body := _body_color()
	var tex := Assets.tex(_tex_name())
	if tex != null:
		var w := get_radius() * 2.2
		var scale := Vector2(w / tex.get_width(), w / tex.get_height())
		draw_set_transform(Vector2.ZERO, 0.0, scale)
		var tint := Color(2.2, 2.2, 2.2) if flash > 0.0 else Color.WHITE
		draw_texture(tex, Vector2(-w / 2.0, -w / 2.0), tint)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
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
	# Kind decorations
	if kind == Kind.WEAVE:
		# A little bow on the head
		var bow := Color(0.55, 0.78, 0.99)
		draw_circle(Vector2(-4.0, -14.0), 2.6, bow)
		draw_circle(Vector2(4.0, -14.0), 2.6, bow)
		draw_circle(Vector2(0.0, -14.0), 1.6, Color(0.35, 0.6, 0.95))
	elif kind == Kind.SHELL:
		# A helmet over the head
		var helm := Color(0.55, 0.6, 0.68)
		var pts := PackedVector2Array()
		for i in 12:
			var a := PI + TAU * i / 12.0
			pts.append(Vector2(0, -4) + Vector2(cos(a), sin(a)) * 12.5)
		draw_colored_polygon(pts, helm)
		draw_rect(Rect2(-12.5, -5.0, 25.0, 2.5), Color(0.4, 0.45, 0.55))
	elif kind == Kind.KING:
		# A golden crown
		var gold := Color(0.98, 0.8, 0.3)
		var pts := PackedVector2Array([
			Vector2(-10.0, -11.0), Vector2(-6.0, -20.0), Vector2(-2.5, -13.0),
			Vector2(0.0, -22.0), Vector2(2.5, -13.0), Vector2(6.0, -20.0),
			Vector2(10.0, -11.0),
		])
		draw_colored_polygon(pts, gold)
		draw_circle(Vector2(0.0, -22.0), 1.6, Color(1.0, 0.9, 0.5))
		draw_circle(Vector2(-6.0, -20.0), 1.4, Color(1.0, 0.9, 0.5))
		draw_circle(Vector2(6.0, -20.0), 1.4, Color(1.0, 0.9, 0.5))
	# Hit flash (armored rat, non-lethal hit)
	if flash > 0.0:
		draw_circle(Vector2(0, 2), 16.0, Color(1.0, 1.0, 1.0, minf(1.0, flash * 4.0) * 0.7))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
