extends Node2D
## Meow Command — defend the cute cat city from the dog missile attack!
## Click to fire. Nearest live turret pops a star missile at your cursor.

enum State { PLAYING, WAVE_BREAK, GAME_OVER }

const SCREEN := Vector2(1280, 720)
const GROUND_Y := 664.0
const CITY_XS := [300.0, 640.0, 980.0]
const TURRET_XS := [150.0, 470.0, 810.0, 1130.0]
const TURRET_Y := 652.0
const DOG_SPAWN_Y := -30.0
const EXPLOSION_RADIUS := 55.0

const SfxScript = preload("res://scripts/sfx.gd")

var state: int = State.PLAYING
var score := 0
var best := 0
var wave := 1
var dogs_to_spawn := 0
var spawn_timer := 0.0
var wave_break_timer := 0.0

var sfx: Node
var world: Node2D
var cities: Array = []
var turrets: Array = []
var dogs: Array = []
var missiles: Array = []
var explosions: Array = []

var score_label: Label
var wave_label: Label
var best_label: Label
var banner_label: Label
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

	# Game-over overlay
	gameover_layer = CanvasLayer.new()
	gameover_layer.name = "GameOver"
	gameover_layer.layer = 10
	add_child(gameover_layer)
	var dim := ColorRect.new()
	dim.color = Palette.OVERLAY_DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	gameover_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	gameover_layer.add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(box)
	var title := _make_label(0, 0, 64, Palette.UI_TEXT)
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	final_label = _make_label(0, 0, 30, Palette.UI_TEXT)
	final_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(final_label)
	var hint := _make_label(0, 0, 24, Palette.UI_ACCENT)
	hint.text = "click to try again"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	gameover_layer.visible = false


func _make_label(x: float, y: float, size: int, color: Color) -> Label:
	var l := Label.new()
	l.position = Vector2(x, y)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color("white", 0.85))
	l.add_theme_constant_override("outline_size", 5)
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


func _show_banner(text: String, duration: float = 2.4) -> void:
	banner_label.text = text
	banner_label.position.x = SCREEN.x / 2.0 - banner_label.get_minimum_size().x / 2.0
	banner_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(banner_label, "modulate:a", 0.0, 1.2).set_delay(maxf(0.2, duration - 1.2))


func _score_popup(pos: Vector2, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Palette.UI_ACCENT)
	l.add_theme_color_override("font_outline_color", Color("white", 0.9))
	l.add_theme_constant_override("outline_size", 4)
	world.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", pos.y - 42.0, 0.7)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.7)
	tw.tween_callback(l.queue_free)


# ----------------------------------------------------------------- waves

func _start_wave(n: int) -> void:
	wave = n
	dogs_to_spawn = mini(4 + n * 2, 26)
	spawn_timer = 1.2
	state = State.PLAYING
	_show_banner("WAVE %d — the dogs are coming!" % n)
	sfx.play("wave")
	_update_hud()


func _spawn_dog() -> void:
	var from := Vector2(randf_range(60.0, SCREEN.x - 60.0), DOG_SPAWN_Y)
	var target := _pick_target()
	var speed := minf(randf_range(42.0, 60.0) + wave * 7.0, 190.0)
	var dog := DogMissile.new()
	dog.name = "Dog%d" % dogs.size()
	world.add_child(dog)
	dog.launch(from, target, speed)
	dogs.append(dog)


func _pick_target() -> Vector2:
	var options: Array = []
	for c in cities:
		options.append_array(c.target_points())
	# Sometimes the dogs go straight for a turret
	if randf() < 0.25:
		var alive_turrets: Array = []
		for t in turrets:
			if t.alive:
				alive_turrets.append(t.position + Vector2(0, -16))
		if not alive_turrets.is_empty():
			return alive_turrets[randi() % alive_turrets.size()]
	if options.is_empty():
		return Vector2(SCREEN.x / 2.0, GROUND_Y)
	return options[randi() % options.size()]


func _end_wave() -> void:
	# Defensive: if the city is gone, the game is over — no bonus, no next wave.
	if _alive_buildings() == 0:
		_game_over()
		return
	var bonus := 100 * wave + 25 * _alive_buildings()
	_score(bonus)
	_score_popup(Vector2(SCREEN.x / 2.0, 320.0), "+%d" % bonus)
	state = State.WAVE_BREAK
	wave_break_timer = 2.6
	_show_banner("WAVE %d CLEARED!" % wave)
	sfx.play("wave")


# ------------------------------------------------------------------ loop

func _process(delta: float) -> void:
	var mouse := get_viewport().get_mouse_position()
	for t in turrets:
		t.update_aim(mouse)

	match state:
		State.PLAYING:
			_update_playing(delta)
		State.WAVE_BREAK:
			wave_break_timer -= delta
			if wave_break_timer <= 0.0:
				_start_wave(wave + 1)

	_cleanup()


func _update_playing(delta: float) -> void:
	# Spawn the dog swarm
	if dogs_to_spawn > 0:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			_spawn_dog()
			dogs_to_spawn -= 1
			spawn_timer = maxf(0.22, 0.95 - wave * 0.05) * randf_range(0.7, 1.3)

	# Missiles that clip a dog explode early
	for m in missiles:
		if m.exploded:
			continue
		for d in dogs.duplicate():
			if d.landed or d.dead:
				continue
			if (m.position - d.position).length() < PlayerMissile.RADIUS + DogMissile.RADIUS:
				m.position = d.position
				m.exploded = true
				m.boomed = true
				_spawn_explosion(m.position, EXPLOSION_RADIUS, true)
				_kill_dog(d)
				sfx.play("pop")
				break

	# Growing explosions pop any dogs inside them
	for e in explosions:
		if e.done or not e.kills_dogs:
			continue
		var r: float = e.current_radius()
		if r < 4.0:
			continue
		for d in dogs.duplicate():
			if d.landed or d.dead:
				continue
			if (e.position - d.position).length() < r + DogMissile.RADIUS:
				_kill_dog(d)
				sfx.play("pop")

	# Wave complete when the sky is clear
	if dogs_to_spawn == 0 and dogs.is_empty() and missiles.is_empty():
		_end_wave()


func _cleanup() -> void:
	var i := dogs.size() - 1
	while i >= 0:
		var d: DogMissile = dogs[i]
		if not is_instance_valid(d):
			dogs.remove_at(i)
		elif d.dead:
			dogs.remove_at(i)
			d.queue_free()
		elif d.landed:
			_dog_landed(d)
			dogs.remove_at(i)
			d.queue_free()
		i -= 1

	var j := missiles.size() - 1
	while j >= 0:
		var m: PlayerMissile = missiles[j]
		if not is_instance_valid(m):
			missiles.remove_at(j)
		elif m.exploded:
			missiles.remove_at(j)
			if not m.boomed:
				_spawn_explosion(m.position, EXPLOSION_RADIUS, true)
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
		if state == State.GAME_OVER:
			_restart()
		elif state == State.PLAYING:
			_fire_at(event.position)


func _fire_at(pos: Vector2) -> void:
	var chosen: Turret = null
	var best_d := INF
	for t in turrets:
		if not t.alive:
			continue
		var d := absf(t.position.x - pos.x)
		if d < best_d:
			best_d = d
			chosen = t
	if chosen == null:
		return
	if chosen.try_fire(pos):
		var m := PlayerMissile.new()
		m.name = "Missile%d" % missiles.size()
		world.add_child(m)
		m.launch(chosen.position + Vector2(0, -30), pos)
		missiles.append(m)
		sfx.play("launch")


# ------------------------------------------------------------- events

func _kill_dog(d: DogMissile) -> void:
	if not dogs.has(d):
		return
	d.dead = true
	dogs.erase(d)
	d.queue_free()
	_score(10)
	_score_popup(d.position + Vector2(0, -20.0), "+10")
	_spawn_explosion(d.position, 24.0, false)


func _dog_landed(d: DogMissile) -> void:
	var p: Vector2 = d.position
	_spawn_explosion(p, 26.0, false)
	sfx.play("city_hit")
	var hit := false
	for c in cities:
		if c.damage_nearest(p, 40.0):
			hit = true
			break
	if not hit:
		for t in turrets:
			if t.alive and (t.position - p).length() < 40.0:
				t.alive = false
				t.queue_redraw()
				hit = true
				break
	_check_game_over()


func _spawn_explosion(pos: Vector2, radius: float, kills: bool) -> void:
	var e := Explosion.new()
	e.name = "Boom%d" % explosions.size()
	e.position = pos
	e.max_radius = radius
	e.kills_dogs = kills
	world.add_child(e)
	explosions.append(e)


func _check_game_over() -> void:
	if state != State.PLAYING and state != State.WAVE_BREAK:
		return
	var alive_buildings := 0
	for c in cities:
		alive_buildings += c.alive_count()
	var alive_turrets := 0
	for t in turrets:
		if t.alive:
			alive_turrets += 1
	if alive_buildings == 0 or alive_turrets == 0:
		_game_over()


func _game_over() -> void:
	state = State.GAME_OVER
	if score > best:
		best = score
		_save_best()
	_update_hud()
	final_label.text = "final score %d — the dogs got the last biscuit" % score
	gameover_layer.visible = true
	sfx.play("game_over")


func _restart() -> void:
	if world:
		world.queue_free()
		world = null
	cities.clear()
	turrets.clear()
	dogs.clear()
	missiles.clear()
	explosions.clear()
	score = 0
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
	if FileAccess.file_exists("user://best_score.save"):
		var f := FileAccess.open("user://best_score.save", FileAccess.READ)
		if f:
			best = f.get_32()


func _save_best() -> void:
	var f := FileAccess.open("user://best_score.save", FileAccess.WRITE)
	if f:
		f.store_32(best)
