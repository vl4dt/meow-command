extends Node2D
## Meow Command — defend the cute cat city from the rat swarm attack!
## Click to fire. Nearest live turret pops a star missile at your cursor.

enum State { PLAYING, WAVE_BREAK, GAME_OVER }

const SCREEN := Vector2(1280, 720)
const GROUND_Y := 664.0
const CITY_XS := [300.0, 640.0, 980.0]
const TURRET_XS := [150.0, 470.0, 810.0, 1130.0]
const TURRET_Y := 652.0
const RAT_SPAWN_Y := -30.0
const EXPLOSION_RADIUS := 55.0
const MAX_RATS := 40  # hard cap on live rats (splitter children can briefly exceed)

# Combo (rolling window): kills within COMBO_WINDOW of each other chain a
# multiplier on per-rat points. Wave-clear bonuses stay flat.
const COMBO_WINDOW := 2.5
const COMBO_CAP := 5.0

const SfxScript = preload("res://scripts/sfx.gd")

var state: int = State.PLAYING
var score := 0
var best := 0
var wave := 1
var rats_to_spawn := 0
var spawn_timer := 0.0
var wave_break_timer := 0.0
var splitters_this_wave := 0

# Combo state
var combo := 0
var combo_timer := 0.0

var sfx: Node
var world: Node2D
var cities: Array = []
var turrets: Array = []
var rats: Array = []
var missiles: Array = []
var explosions: Array = []

var score_label: Label
var wave_label: Label
var best_label: Label
var banner_label: Label
var combo_label: Label
var combo_bar: ColorRect
var gameover_layer: CanvasLayer
var final_label: Label


func _ready() -> void:
	randomize()
	_load_best()
	sfx = SfxScript.new()
	sfx.name = "SFX"
	add_child(sfx)
	_build_world()
	_build_hud()
	_start_wave(1)


# ---------------------------------------------------------------- world

func _build_world() -> void:
	world = Node2D.new()
	world.name = "World"
	add_child(world)

	var bg: Node2D = load("res://scripts/background.gd").new()
	bg.name = "Background"
	world.add_child(bg)

	for i in CITY_XS.size():
		var city := City.new()
		city.name = "City%d" % i
		city.setup(CITY_XS[i], GROUND_Y, 100 + i * 7)
		cities.append(city)
		world.add_child(city)

	for i in TURRET_XS.size():
		var t := Turret.new()
		t.name = "Turret%d" % i
		t.position = Vector2(TURRET_XS[i], TURRET_Y)
		turrets.append(t)
		world.add_child(t)


# ------------------------------------------------------------------ hud

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)

	score_label = _make_label(26, 14, 26, Palette.UI_TEXT)
	hud.add_child(score_label)

	wave_label = _make_label(0, 14, 26, Palette.UI_TEXT)
	hud.add_child(wave_label)

	best_label = _make_label(0, 14, 26, Palette.UI_TEXT)
	hud.add_child(best_label)

	banner_label = _make_label(0, 190, 44, Palette.UI_ACCENT)
	banner_label.modulate.a = 0.0
	hud.add_child(banner_label)

	# Combo readout (top-center, below the wave label) with a draining bar.
	combo_label = _make_label(0, 48, 24, Palette.UI_ACCENT)
	combo_label.visible = false
	hud.add_child(combo_label)
	combo_bar = ColorRect.new()
	combo_bar.color = Palette.UI_ACCENT
	combo_bar.position = Vector2(SCREEN.x / 2.0 - 60.0, 76.0)
	combo_bar.size = Vector2(120.0, 4.0)
	combo_bar.visible = false
	hud.add_child(combo_bar)

	# Game-over overlay
	gameover_layer = CanvasLayer.new()
	gameover_layer.name = "GameOver"
	gameover_layer.layer = 20
	gameover_layer.visible = false
	add_child(gameover_layer)

	var dim := ColorRect.new()
	dim.color = Palette.OVERLAY_DIM
	dim.position = Vector2.ZERO
	dim.size = SCREEN
	gameover_layer.add_child(dim)

	final_label = _make_label(0, 250, 40, Palette.UI_TEXT)
	gameover_layer.add_child(final_label)

	var again := Button.new()
	again.text = "PLAY AGAIN"
	again.position = Vector2(SCREEN.x / 2.0 - 110.0, 380.0)
	again.size = Vector2(220, 64)
	again.pressed.connect(_restart)
	gameover_layer.add_child(again)


func _make_label(x: float, y: float, size: int, color: Color) -> Label:
	var l := Label.new()
	l.position = Vector2(x, y)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color("white", 0.6))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l


func _update_hud() -> void:
	if score_label == null:
		return
	score_label.text = "SCORE %d" % score
	wave_label.text = "WAVE %d" % wave
	best_label.text = "BEST %d" % best
	score_label.position.x = 26.0
	wave_label.position.x = SCREEN.x / 2.0 - wave_label.get_minimum_size().x / 2.0
	best_label.position.x = SCREEN.x - 26.0 - best_label.get_minimum_size().x


func _update_combo_hud() -> void:
	if combo_label == null:
		return
	if combo >= 2:
		combo_label.visible = true
		combo_label.text = "COMBO %s" % _fmt_mult(_combo_multiplier())
		combo_label.position.x = SCREEN.x / 2.0 - combo_label.get_minimum_size().x / 2.0
		combo_bar.visible = true
		combo_bar.size.x = 120.0 * clampf(combo_timer / COMBO_WINDOW, 0.0, 1.0)
	else:
		combo_label.visible = false
		combo_bar.visible = false


func _show_banner(text: String) -> void:
	if banner_label == null:
		return
	banner_label.text = text
	banner_label.position.x = SCREEN.x / 2.0 - banner_label.get_minimum_size().x / 2.0
	banner_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(banner_label, "modulate:a", 1.0, 0.9)
	tw.tween_property(banner_label, "modulate:a", 0.0, 0.7)


func _score_popup(pos: Vector2, text: String) -> void:
	var l := _make_label(0, 0, 22, Palette.UI_ACCENT)
	l.text = text
	l.position = pos - l.get_minimum_size() / 2.0
	world.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", l.position.y - 46.0, 0.7)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.7)
	tw.tween_callback(l.queue_free)


# ----------------------------------------------------------------- waves

func _start_wave(n: int) -> void:
	wave = n
	rats_to_spawn = mini(4 + n * 2, 26)
	splitters_this_wave = 0
	spawn_timer = 1.2
	state = State.PLAYING
	_show_banner("WAVE %d — the rats are coming!" % n)
	sfx.play("wave")
	_update_hud()


func _spawn_rat() -> void:
	var from := Vector2(randf_range(60.0, SCREEN.x - 60.0), RAT_SPAWN_Y)
	var target := _pick_target()
	var speed := minf(randf_range(42.0, 60.0) + wave * 7.0, 190.0)
	var rat := RatMissile.new()
	# Splitter rats (wave 3+): bigger, +25, split into 2 fast children on kill.
	if wave >= 3 and splitters_this_wave < 3 and randf() < 0.12:
		rat.kind = RatMissile.Kind.SPLITTER
		splitters_this_wave += 1
	rat.name = "Rat%d" % rats.size()
	world.add_child(rat)
	rat.launch(from, target, speed)
	rats.append(rat)


## A killed splitter splits into 2 small, fast, non-splitting children that
## scatter toward random targets. Brief spawn-grace so the split reads clearly.
func _spawn_splitter_children(at: Vector2) -> void:
	for i in 2:
		var child := RatMissile.new()
		child.kind = RatMissile.Kind.CHILD
		child.name = "Rat%d" % rats.size()
		world.add_child(child)
		var t := _pick_target()
		var speed := minf(randf_range(55.0, 75.0) + wave * 7.0, 230.0)
		var offset := Vector2(randf_range(-14.0, 14.0), randf_range(-6.0, 6.0))
		child.launch(at + offset, t, speed)
		child.spawn_grace = 1.0
		rats.append(child)


func _pick_target() -> Vector2:
	var points: Array = []
	for c in cities:
		points.append_array(c.target_points())
	for t in turrets:
		points.append(t.position)
	if points.is_empty():
		return Vector2(SCREEN.x / 2.0, GROUND_Y)
	# Sometimes the rats go straight for the turrets to keep pressure on.
	if randf() < 0.35:
		for t in turrets:
			if t.alive and randf() < 0.5:
				return t.position
	return points[randi() % points.size()]


func _end_wave() -> void:
	state = State.WAVE_BREAK
	wave_break_timer = 2.6
	var bonus := 25 + wave * 10
	_score(bonus)
	_show_banner("WAVE CLEARED  + %d" % bonus)
	sfx.play("wave")


# ------------------------------------------------------------------ loop

func _process(delta: float) -> void:
	var mouse := get_viewport().get_mouse_position()
	for t in turrets:
		t.update_aim(mouse)
	# Combo decay (runs in every state so it expires during wave breaks too)
	if combo > 0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0
	match state:
		State.PLAYING:
			_update_playing(delta)
		State.WAVE_BREAK:
			wave_break_timer -= delta
			if wave_break_timer <= 0.0:
				_start_wave(wave + 1)
	_cleanup()
	_update_combo_hud()


func _update_playing(delta: float) -> void:
	# Spawn the rat swarm (capped so splitter children can't run away)
	if rats_to_spawn > 0 and rats.size() < MAX_RATS:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			_spawn_rat()
			rats_to_spawn -= 1
			spawn_timer = maxf(0.22, 0.95 - wave * 0.05) * randf_range(0.7, 1.3)

	# Missiles that clip a rat explode early
	for m in missiles:
		if m.exploded:
			continue
		for d in rats.duplicate():
			if d.landed or d.dead or d.spawn_grace > 0.0:
				continue
			if (m.position - d.position).length() < PlayerMissile.RADIUS + d.get_radius():
				m.position = d.position
				m.exploded = true
				m.boomed = true
				_spawn_explosion(m.position, EXPLOSION_RADIUS, true)
				_kill_rat(d)
				sfx.play("pop")
				break

	# Growing explosions pop any rats inside them
	for e in explosions:
		if e.done or not e.kills_rats:
			continue
		var r: float = e.current_radius()
		if r < 4.0:
			continue
		for d in rats.duplicate():
			if d.landed or d.dead or d.spawn_grace > 0.0:
				continue
			if (e.position - d.position).length() < r + d.get_radius():
				_kill_rat(d)
				sfx.play("pop")

	# Wave complete when the sky is clear
	if rats_to_spawn == 0 and rats.is_empty() and missiles.is_empty():
		_end_wave()


func _cleanup() -> void:
	var i := rats.size() - 1
	while i >= 0:
		var d: RatMissile = rats[i]
		if not is_instance_valid(d):
			rats.remove_at(i)
		elif d.dead:
			rats.remove_at(i)
			d.queue_free()
		elif d.landed:
			_rat_landed(d)
			rats.remove_at(i)
			d.queue_free()
		i -= 1

	var j := missiles.size() - 1
	while j >= 0:
		var m: PlayerMissile = missiles[j]
		if not is_instance_valid(m):
			missiles.remove_at(j)
		elif m.exploded:
			# An endpoint hit that never clipped a rat still pops a boom.
			if not m.boomed:
				_spawn_explosion(m.position, EXPLOSION_RADIUS, true)
				sfx.play("explosion")
			missiles.remove_at(j)
			m.queue_free()
		j -= 1

	var k := explosions.size() - 1
	while k >= 0:
		var e: Explosion = explosions[k]
		if not is_instance_valid(e):
			explosions.remove_at(k)
		elif e.done:
			explosions.remove_at(k)
			e.queue_free()
		k -= 1


# ------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if state == State.PLAYING:
			_fire_at(event.position)
	elif event.is_action_pressed("ui_cancel"):
		if state != State.GAME_OVER:
			get_tree().quit()


func _fire_at(pos: Vector2) -> void:
	var best_turret: Turret = null
	var best_d := INF
	for t in turrets:
		if not t.alive:
			continue
		var d: float = t.position.distance_to(pos)
		if d < best_d:
			best_d = d
			best_turret = t
	if best_turret == null:
		return
	# Gate on cooldown first; try_fire() arms the turret if it can fire.
	if not best_turret.try_fire(pos):
		return
	var m := PlayerMissile.new()
	m.name = "Shot%d" % missiles.size()
	world.add_child(m)
	m.launch(best_turret.position, pos)
	missiles.append(m)
	sfx.play("launch")


# ------------------------------------------------------------- events

func _kill_rat(d: RatMissile) -> void:
	if not rats.has(d):
		return
	d.dead = true
	rats.erase(d)
	d.queue_free()
	# Combo: this kill extends the chain and sets the multiplier for scoring.
	combo += 1
	combo_timer = COMBO_WINDOW
	var pts := _rat_points(d)
	_score(pts)
	_score_popup(d.position + Vector2(0, -20.0), "+%d" % pts)
	_spawn_explosion(d.position, 24.0, false)
	if d.kind == RatMissile.Kind.SPLITTER:
		_spawn_splitter_children(d.position)


## Base points per kind, scaled by the current combo multiplier.
func _rat_points(d: RatMissile) -> int:
	var base := 10
	match d.kind:
		RatMissile.Kind.SPLITTER:
			base = 25
		RatMissile.Kind.CHILD:
			base = 15
	return int(roundf(base * _combo_multiplier()))


func _combo_multiplier() -> float:
	if combo <= 1:
		return 1.0
	return minf(1.0 + 0.25 * (combo - 1), COMBO_CAP)


func _fmt_mult(m: float) -> String:
	if absf(m - roundf(m)) < 0.001:
		return "×%d" % int(roundf(m))
	return "×%.2f" % m


func _rat_landed(d: RatMissile) -> void:
	# Damage the nearest building (or a turret's city) and rattle it.
	for c in cities:
		if c.damage_nearest(d.position):
			_spawn_explosion(d.position, 18.0, false)
			sfx.play("city_hit")
			return
	_spawn_explosion(d.position, 18.0, false)
	sfx.play("city_hit")
	_check_game_over()


func _spawn_explosion(pos: Vector2, radius: float, kills: bool) -> void:
	var e := Explosion.new()
	e.name = "Boom%d" % explosions.size()
	e.position = pos
	e.max_radius = radius
	e.kills_rats = kills
	world.add_child(e)
	explosions.append(e)


func _check_game_over() -> void:
	var alive := _alive_buildings()
	if alive > 0:
		return
	_game_over()


func _game_over() -> void:
	state = State.GAME_OVER
	if score > best:
		best = score
		_save_best()
	_update_hud()
	final_label.text = "final score %d — the rats got the last biscuit" % score
	gameover_layer.visible = true
	sfx.play("game_over")


func _restart() -> void:
	if world:
		world.queue_free()
		world = null
	cities.clear()
	turrets.clear()
	rats.clear()
	missiles.clear()
	explosions.clear()
	score = 0
	combo = 0
	combo_timer = 0.0
	splitters_this_wave = 0
	state = State.PLAYING
	gameover_layer.visible = false
	_build_world()
	_start_wave(1)


# ------------------------------------------------------------- helpers

func _alive_buildings() -> int:
	var n := 0
	for c in cities:
		n += c.alive_count()
	return n


func _score(points: int) -> void:
	score += points
	if score > best:
		best = score
	_update_hud()


func _load_best() -> void:
	var f := FileAccess.open("user://best_score.save", FileAccess.READ)
	if f != null:
		best = f.get_32()
		f.close()


func _save_best() -> void:
	var f := FileAccess.open("user://best_score.save", FileAccess.WRITE)
	if f != null:
		f.store_32(best)
		f.close()
