extends Node2D
## Meow Command — defend the cute cat city from the rat swarm attack!
## Tap to fire: the nearest live cat turret pops a star missile at that spot.
##
## States: TITLE → PLAYING ⇄ WAVE_BREAK → GAME_OVER; PAUSED from PLAYING.
## Touch is handled via emulated mouse events (project.godot sets
## emulate_mouse_from_touch=true), so one input path covers mouse + touch.

enum State { TITLE, PLAYING, WAVE_BREAK, PAUSED, GAME_OVER }

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

# Economy
const BISCUIT_DROP_CHANCE := 0.12
const POWERUP_DROP_CHANCE := 0.05
const POWER_DUR := {"double": 8.0, "wide": 8.0, "slow": 6.0, "shield": 8.0}
const POWER_NAMES := {"double": "DOUBLE SHOT", "wide": "WIDE BOOM", "slow": "SLOW-MO", "shield": "CITY SHIELD"}

const FLAVOR := [
	"the rats are coming!",
	"they smell the biscuits…",
	"extra wiggly tails today",
	"the rats brought friends",
	"rat rain intensifies",
	"the swarm is getting bold",
	"hold the line, kitties",
	"the rats are plotting",
]

const SfxScript = preload("res://scripts/sfx.gd")

var state: int = State.TITLE
var paused_from: int = State.PLAYING
var daily := false
var score := 0
var best := 0
var prev_best := 0
var wave := 1
var rats_to_spawn := 0
var spawn_timer := 0.0
var wave_break_timer := 0.0
var splitters_this_wave := 0

# Combo state
var combo := 0
var combo_timer := 0.0
var combo_milestone := 0  # highest milestone level celebrated this chain

# Run stats
var kills_run := 0
var best_combo_run := 0
var biscuit_run := 0

# Active power-up
var power: String = ""
var power_timer := 0.0

# Juice
var clutch_until := 0  # real-time ms until slow-mo restores
var shake := 0.0

# Settings
var sound_on := true

var sfx: Node
var world: Node2D
var bg: Node2D
var fx: Node2D
var cities: Array = []
var turrets: Array = []
var rats: Array = []
var missiles: Array = []
var explosions: Array = []
var bisc_drops: Array = []
var power_drops: Array = []

var title_screen: Node
var pause_screen: Node
var howto_screen: Node

var hud_layer: CanvasLayer
var score_label: Label
var wave_label: Label
var best_label: Label
var bisc_label: Label
var daily_label: Label
var banner_label: Label
var combo_label: Label
var combo_bar: ColorRect
var power_label: Label
var power_bar: ColorRect

var gameover_layer: CanvasLayer
var final_label: Label
var stats_label: Label
var newbest_label: Label
var copy_btn: Button


func _ready() -> void:
	randomize()
	Meta.load_all()
	best = Meta.best
	sound_on = Meta.sound_on
	sfx = SfxScript.new()
	sfx.name = "SFX"
	add_child(sfx)
	sfx.set_sound(sound_on)
	_build_world()
	_build_hud()
	_build_screens()
	_build_gameover()
	state = State.TITLE
	_update_hud()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if state == State.PLAYING or state == State.WAVE_BREAK:
			_pause()


# ---------------------------------------------------------------- world

func _build_world() -> void:
	world = Node2D.new()
	world.name = "World"
	add_child(world)

	bg = load("res://scripts/background.gd").new()
	bg.name = "Background"
	world.add_child(bg)

	for i in CITY_XS.size():
		var city := City.new()
		city.name = "City%d" % i
		city.setup(CITY_XS[i], GROUND_Y, 100 + i * 7)
		city.building_destroyed.connect(_on_building_destroyed)
		cities.append(city)
		world.add_child(city)

	for i in TURRET_XS.size():
		var t := Turret.new()
		t.name = "Turret%d" % i
		t.position = Vector2(TURRET_XS[i], TURRET_Y)
		turrets.append(t)
		world.add_child(t)

	fx = FXLayer.new()
	fx.name = "FX"
	world.add_child(fx)


func _on_building_destroyed(pos: Vector2) -> void:
	fx.burst(pos + Vector2(0, -20.0), "puff", 1.6)
	_shake(6.0)


## Fresh defenses (restart / back to title).
func _reset_defenses() -> void:
	for c in cities:
		c.queue_free()
	for t in turrets:
		t.queue_free()
	cities.clear()
	turrets.clear()
	for i in CITY_XS.size():
		var city := City.new()
		city.name = "City%d" % i
		city.setup(CITY_XS[i], GROUND_Y, 100 + i * 7)
		city.building_destroyed.connect(_on_building_destroyed)
		cities.append(city)
		world.add_child(city)
	for i in TURRET_XS.size():
		var t := Turret.new()
		t.name = "Turret%d" % i
		t.position = Vector2(TURRET_XS[i], TURRET_Y)
		turrets.append(t)
		world.add_child(t)


func _clear_entities() -> void:
	for r in rats:
		r.queue_free()
	for m in missiles:
		m.queue_free()
	for e in explosions:
		e.queue_free()
	for b in bisc_drops:
		b.queue_free()
	for p in power_drops:
		p.queue_free()
	rats.clear()
	missiles.clear()
	explosions.clear()
	bisc_drops.clear()
	power_drops.clear()


# ------------------------------------------------------------------ hud

func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "HUD"
	add_child(hud_layer)

	score_label = _make_label(26, 14, 26, Palette.UI_TEXT)
	hud_layer.add_child(score_label)

	wave_label = _make_label(26, 50, 20, Palette.UI_TEXT)
	hud_layer.add_child(wave_label)

	best_label = _make_label(0, 14, 26, Palette.UI_TEXT)
	hud_layer.add_child(best_label)

	bisc_label = _make_label(0, 50, 20, Palette.UI_TEXT)
	hud_layer.add_child(bisc_label)

	daily_label = _make_label(0, 14, 22, Palette.UI_ACCENT)
	daily_label.text = "DAILY"
	daily_label.visible = false
	hud_layer.add_child(daily_label)

	banner_label = _make_label(0, 190, 44, Palette.UI_ACCENT)
	banner_label.modulate.a = 0.0
	hud_layer.add_child(banner_label)

	# Combo readout (top-center) with a draining bar.
	combo_label = _make_label(0, 48, 24, Palette.UI_ACCENT)
	combo_label.visible = false
	hud_layer.add_child(combo_label)
	combo_bar = ColorRect.new()
	combo_bar.color = Palette.UI_ACCENT
	combo_bar.position = Vector2(SCREEN.x / 2.0 - 60.0, 76.0)
	combo_bar.size = Vector2(120.0, 4.0)
	combo_bar.visible = false
	hud_layer.add_child(combo_bar)

	# Active power-up readout (below the combo bar).
	power_label = _make_label(0, 104, 20, Palette.UI_ACCENT)
	power_label.visible = false
	hud_layer.add_child(power_label)
	power_bar = ColorRect.new()
	power_bar.color = Palette.UI_ACCENT
	power_bar.position = Vector2(SCREEN.x / 2.0 - 60.0, 130.0)
	power_bar.size = Vector2(120.0, 4.0)
	power_bar.visible = false
	hud_layer.add_child(power_bar)


func _build_screens() -> void:
	title_screen = TitleScreen.new()
	add_child(title_screen)
	title_screen.setup(self)

	pause_screen = PauseScreen.new()
	add_child(pause_screen)
	pause_screen.setup(self)

	howto_screen = HowToScreen.new()
	add_child(howto_screen)
	howto_screen.setup(self)


func _build_gameover() -> void:
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

	var title := _make_label(0, 130, 56, Palette.UI_TEXT)
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(SCREEN.x, 80)
	gameover_layer.add_child(title)

	final_label = _make_label(0, 230, 44, Palette.UI_ACCENT)
	final_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	final_label.size = Vector2(SCREEN.x, 60)
	gameover_layer.add_child(final_label)

	stats_label = _make_label(0, 310, 20, Palette.UI_TEXT)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.size = Vector2(SCREEN.x, 30)
	gameover_layer.add_child(stats_label)

	newbest_label = _make_label(0, 0, 36, Palette.UI_ACCENT)
	newbest_label.text = "NEW BEST!"
	newbest_label.visible = false
	newbest_label.position = Vector2(880.0, 180.0)
	newbest_label.rotation = -0.18
	gameover_layer.add_child(newbest_label)

	_make_button("PLAY AGAIN", Vector2(540.0, 430.0), func(): _restart_run(), gameover_layer)
	copy_btn = _make_button("COPY SCORE", Vector2(540.0, 510.0), _copy_score, gameover_layer)
	_make_button("MENU", Vector2(540.0, 590.0), func(): _to_title(), gameover_layer)


func _make_label(x: float, y: float, size: int, color: Color) -> Label:
	var l := Label.new()
	l.position = Vector2(x, y)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color("white", 0.6))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l


func _make_button(text: String, pos: Vector2, cb: Callable, parent: Node) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(260, 64)
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_color_override("font_color", Palette.UI_TEXT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.UI_ACCENT
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(10)
	b.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.bg_color = (Palette.UI_ACCENT as Color).lightened(0.18)
	b.add_theme_stylebox_override("hover", sbh)
	var sbd := sb.duplicate() as StyleBoxFlat
	sbd.bg_color = (Palette.UI_ACCENT as Color).darkened(0.18)
	b.add_theme_stylebox_override("pressed", sbd)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _update_hud() -> void:
	if score_label == null:
		return
	score_label.text = "SCORE %d" % score
	wave_label.text = "WAVE %d · RATS %d" % [wave, rats_to_spawn + rats.size()]
	best_label.text = "BEST %d" % best
	bisc_label.text = "BISCUITS %d" % Meta.biscuits
	daily_label.visible = daily
	score_label.position.x = 26.0
	wave_label.position.x = 26.0
	best_label.position.x = SCREEN.x - 26.0 - best_label.get_minimum_size().x
	bisc_label.position.x = SCREEN.x - 26.0 - bisc_label.get_minimum_size().x
	daily_label.position.x = SCREEN.x / 2.0 - daily_label.get_minimum_size().x / 2.0
	# Combo
	if combo >= 2:
		combo_label.visible = true
		combo_label.text = "COMBO %s" % _fmt_mult(_combo_multiplier())
		combo_label.position.x = SCREEN.x / 2.0 - combo_label.get_minimum_size().x / 2.0
		combo_bar.visible = true
		combo_bar.size.x = 120.0 * clampf(combo_timer / COMBO_WINDOW, 0.0, 1.0)
	else:
		combo_label.visible = false
		combo_bar.visible = false
	# Power-up
	if power != "":
		power_label.visible = true
		power_label.text = "%s %ds" % [POWER_NAMES.get(power, power.to_upper()), int(ceilf(power_timer))]
		power_label.position.x = SCREEN.x / 2.0 - power_label.get_minimum_size().x / 2.0
		power_bar.visible = true
		power_bar.size.x = 120.0 * clampf(power_timer / float(POWER_DUR.get(power, 8.0)), 0.0, 1.0)
	else:
		power_label.visible = false
		power_bar.visible = false


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


# ------------------------------------------------------------- state flow

func _begin_run(is_daily: bool) -> void:
	daily = is_daily
	if daily:
		seed(Meta.daily_seed())
	sfx.unlock()
	Engine.time_scale = 1.0
	clutch_until = 0
	shake = 0.0
	score = 0
	wave = 1
	combo = 0
	combo_timer = 0.0
	combo_milestone = 0
	kills_run = 0
	best_combo_run = 0
	biscuit_run = 0
	power = ""
	power_timer = 0.0
	prev_best = best
	_clear_entities()
	_reset_defenses()
	state = State.PLAYING
	title_screen.visible = false
	pause_screen.visible = false
	howto_screen.visible = false
	gameover_layer.visible = false
	_start_wave(1)
	_update_hud()


func _restart_run() -> void:
	get_tree().paused = false
	_begin_run(daily)


## Backwards-compatible alias (used by tools/gameplay_test.gd).
func _restart() -> void:
	_restart_run()


func _to_title() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	clutch_until = 0
	shake = 0.0
	power = ""
	power_timer = 0.0
	_clear_entities()
	_reset_defenses()
	state = State.TITLE
	gameover_layer.visible = false
	pause_screen.visible = false
	howto_screen.visible = false
	title_screen.visible = true
	title_screen.refresh_wallet()
	_update_hud()


func _pause() -> void:
	if state == State.PAUSED:
		return
	paused_from = state
	state = State.PAUSED
	get_tree().paused = true
	pause_screen.show_pause()


func _resume() -> void:
	if state != State.PAUSED:
		return
	state = paused_from
	get_tree().paused = false
	pause_screen.hide_screen()


func _show_howto() -> void:
	howto_screen.show_screen()


func _hide_howto() -> void:
	howto_screen.hide_screen()


func _toggle_sound() -> void:
	sound_on = not sound_on
	Meta.sound_on = sound_on
	Meta.save_all()
	sfx.set_sound(sound_on)


func _handle_escape() -> void:
	match state:
		State.TITLE:
			get_tree().quit()
		State.PLAYING, State.WAVE_BREAK:
			_pause()
		State.PAUSED:
			_resume()
		State.GAME_OVER:
			_to_title()


func _copy_score() -> void:
	var txt := "Meow Command — %d pts (wave %d, best combo ×%d)" % [score, wave, best_combo_run]
	DisplayServer.clipboard_set(txt)
	if copy_btn != null:
		copy_btn.text = "COPIED!"
		var tw := create_tween()
		tw.tween_interval(1.2)
		tw.tween_callback(func():
			if copy_btn != null:
				copy_btn.text = "COPY SCORE")


# ----------------------------------------------------------------- waves

func _start_wave(n: int) -> void:
	wave = n
	rats_to_spawn = _wave_rats(n)
	splitters_this_wave = 0
	spawn_timer = 1.0
	state = State.PLAYING
	if n % 5 == 0:
		_show_banner("WAVE %d — THE RAT KING APPROACHES!" % n)
		sfx.play("boss")
		_spawn_king()
	else:
		_show_banner("WAVE %d — %s" % [n, FLAVOR[(n - 1) % FLAVOR.size()]])
		sfx.play("wave")
	sfx.switch_tier(_tier_for(n))
	_update_hud()


func _wave_rats(n: int) -> int:
	return mini(4 + n * 2, 26 + maxi(0, n - 11))


func _tier_for(n: int) -> String:
	if n < 8:
		return "calm"
	if n < 16:
		return "upbeat"
	return "intense"


func _spawn_rat() -> void:
	if rats.size() >= MAX_RATS:
		return
	var kind := RatMissile.Kind.NORMAL
	var roll := randf()
	var splitters_left := _splitters_cap() - splitters_this_wave
	if wave >= 6 and roll < 0.10:
		kind = RatMissile.Kind.SHELL
	elif wave >= 4 and roll < 0.24:
		kind = RatMissile.Kind.WEAVE
	elif wave >= 3 and splitters_left > 0 and roll < 0.36:
		kind = RatMissile.Kind.SPLITTER
	if kind == RatMissile.Kind.SPLITTER:
		splitters_this_wave += 1
	var from := Vector2(randf_range(60.0, SCREEN.x - 60.0), RAT_SPAWN_Y)
	var target := _pick_target()
	var rat := RatMissile.new()
	rat.name = "Rat%d" % rats.size()
	rat.setup(kind, from, target, _rat_speed(), wave >= 8)
	world.add_child(rat)
	rats.append(rat)


func _rat_speed() -> float:
	var base := randf_range(42.0, 60.0) + wave * 7.0
	var cap := 190.0 + maxf(0.0, float(wave - 15)) * 4.0
	var v := minf(base, cap)
	if power == "slow":
		v *= 0.55
	return v


func _splitters_cap() -> int:
	return mini(3 + (wave - 3) / 5, 6)


func _spawn_king() -> void:
	var from := Vector2(randf_range(SCREEN.x * 0.3, SCREEN.x * 0.7), RAT_SPAWN_Y)
	var king := RatMissile.new()
	king.name = "King%d" % rats.size()
	king.setup(RatMissile.Kind.KING, from, _pick_target(), 62.0, false)
	world.add_child(king)
	rats.append(king)


## A killed splitter/king bursts into small, fast, non-splitting children.
func _spawn_children(at: Vector2, aim: Vector2, n: int) -> void:
	for i in n:
		if rats.size() >= MAX_RATS:
			return
		var t := aim
		if n > 1:
			t = Vector2(clampf(aim.x + randf_range(-180.0, 180.0), 60.0, SCREEN.x - 60.0), aim.y)
		var child := RatMissile.new()
		child.name = "Rat%d" % rats.size()
		child.setup(RatMissile.Kind.CHILD,
			at + Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0)),
			t, maxf(130.0, 150.0 + wave * 2.0), false)
		world.add_child(child)
		rats.append(child)


func _pick_target() -> Vector2:
	var points: Array = []
	for c in cities:
		points.append_array(c.target_points())
	for t in turrets:
		if t.alive:
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
	if state != State.PLAYING:
		return
	state = State.WAVE_BREAK
	wave_break_timer = 2.6
	var bonus := 25 + wave * 10
	_score(bonus)
	biscuit_run += wave
	_show_banner("WAVE %d CLEARED  + %d" % [wave, bonus])
	sfx.play("wave")
	fx.confetti()


# -------------------------------------------------------------------- loop

func _process(delta: float) -> void:
	# Real-time slow-mo restore (Engine.time_scale pauses game time, not this).
	if clutch_until > 0:
		if Time.get_ticks_msec() < clutch_until:
			Engine.time_scale = 0.35
		else:
			clutch_until = 0
			Engine.time_scale = 1.0
	# Screen shake decay
	if shake > 0.01:
		shake = maxf(0.0, shake - delta * 34.0)
		world.position = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	else:
		world.position = Vector2.ZERO
	# Combo decay (runs in every state so it expires during wave breaks too)
	if combo > 0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0
			combo_milestone = 0
	# Power-up timer
	if power != "":
		power_timer -= delta
		if power_timer <= 0.0:
			power = ""
			power_timer = 0.0
			for c in cities:
				c.shielded = false
	# Turret aim (follows the pointer in every state — cute on the title too)
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
	_update_hud()
	_cleanup()


func _update_playing(delta: float) -> void:
	# Spawn the rat swarm (capped so splitter children can't run away)
	if rats_to_spawn > 0 and rats.size() < MAX_RATS:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			_spawn_rat()
			rats_to_spawn -= 1
			spawn_timer = maxf(0.12, 0.95 - wave * 0.05) * randf_range(0.7, 1.3)
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
				_spawn_explosion(m.position, _boom_radius(), true)
				d.take_hit()
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
				d.take_hit()
	# Wave complete when the sky is clear
	if rats_to_spawn == 0 and rats.is_empty() and missiles.is_empty():
		_end_wave()


func _boom_radius() -> float:
	var r := EXPLOSION_RADIUS
	if power == "wide":
		r *= 1.5
	return r


func _cleanup() -> void:
	var i := rats.size() - 1
	while i >= 0:
		var d: RatMissile = rats[i]
		if not is_instance_valid(d):
			rats.remove_at(i)
		elif d.dead:
			_kill_rat(d)
		elif d.landed:
			_rat_landed(d)
		i -= 1

	var j := missiles.size() - 1
	while j >= 0:
		var m: PlayerMissile = missiles[j]
		if not is_instance_valid(m):
			missiles.remove_at(j)
		elif m.exploded:
			# An endpoint hit that never clipped a rat still pops a boom.
			if not m.boomed:
				_spawn_explosion(m.position, _boom_radius(), true)
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

	var b := bisc_drops.size() - 1
	while b >= 0:
		var bd: BiscuitDrop = bisc_drops[b]
		if not is_instance_valid(bd):
			bisc_drops.remove_at(b)
		elif bd.done:
			bisc_drops.remove_at(b)
			bd.queue_free()
		b -= 1

	var p := power_drops.size() - 1
	while p >= 0:
		var pd: PowerUpDrop = power_drops[p]
		if not is_instance_valid(pd):
			power_drops.remove_at(p)
		elif pd.done:
			power_drops.remove_at(p)
			pd.queue_free()
		p -= 1


# ------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	# Touches arrive as emulated mouse events (emulate_mouse_from_touch=true),
	# so the mouse path covers both desktop and mobile.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)
	elif event.is_action_pressed("ui_cancel"):
		_handle_escape()


func _handle_tap(pos: Vector2) -> void:
	sfx.unlock()
	if state != State.PLAYING:
		return
	_try_collect(pos)
	_easter_eggs(pos)
	_fire_at(pos)


func _easter_eggs(pos: Vector2) -> void:
	if bg != null and (pos - Vector2(1120.0, 120.0)).length() < 60.0:
		bg.sun_blink()
		sfx.play("meow")
		return
	for t in turrets:
		if t.alive and (t.position - pos).length() < 40.0:
			t.set_happy()
			sfx.play("meow")
			return


func _fire_at(pos: Vector2) -> void:
	if state != State.PLAYING:
		return
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
	if not best_turret.try_fire(pos):
		return
	var from := best_turret.position
	if power == "double":
		var v := pos - from
		_spawn_missile(from, from + v.rotated(-0.08))
		_spawn_missile(from, from + v.rotated(0.08))
	else:
		_spawn_missile(from, pos)
	sfx.play("launch")
	_vibrate(8)


func _spawn_missile(from: Vector2, aim: Vector2) -> void:
	var m := PlayerMissile.new()
	m.name = "Shot%d" % missiles.size()
	world.add_child(m)
	m.launch(from, aim)
	missiles.append(m)


# ------------------------------------------------------------- events

func _kill_rat(d: RatMissile) -> void:
	if not rats.has(d):
		return
	rats.erase(d)
	d.queue_free()
	if d.ground_split:
		# Classic ground split: no score, just two more rats.
		fx.burst(d.position, "puff", 1.2)
		_spawn_children(d.position, d.target, 2)
		return
	# Combo: this kill extends the chain and sets the multiplier for scoring.
	combo += 1
	combo_timer = COMBO_WINDOW
	best_combo_run = maxi(best_combo_run, combo)
	var pts := _rat_points(d)
	_score(pts)
	_score_popup(d.position + Vector2(0, -20.0), "+%d" % pts)
	fx.burst(d.position, "puff", d.get_radius() * 0.5)
	sfx.play("pop")
	_vibrate(12)
	if d.kind == RatMissile.Kind.SPLITTER:
		_spawn_children(d.position, d.target, 2)
	elif d.kind == RatMissile.Kind.KING:
		Meta.stats["bosses"] = int(Meta.stats.get("bosses", 0)) + 1
		_spawn_explosion(d.position, 90.0, true)
		_spawn_children(d.position, d.target, 4)
		_shake(14.0)
		sfx.play("boss")
		fx.burst(d.position, "star", 2.5)
	# Drops
	var r := randf()
	if r < BISCUIT_DROP_CHANCE:
		_drop_biscuit(d.position)
	elif r < BISCUIT_DROP_CHANCE + POWERUP_DROP_CHANCE:
		_drop_powerup(d.position)
	kills_run += 1
	_combo_milestone_check()
	# Clutch: the last rat of the wave slows the world for a beat.
	if rats.is_empty() and rats_to_spawn == 0 and state == State.PLAYING:
		clutch_until = Time.get_ticks_msec() + 450
		Engine.time_scale = 0.35


## Base points per kind, scaled by the current combo multiplier.
func _rat_points(d: RatMissile) -> int:
	var base := 10
	match d.kind:
		RatMissile.Kind.SPLITTER:
			base = 25
		RatMissile.Kind.CHILD:
			base = 15
		RatMissile.Kind.WEAVE:
			base = 20
		RatMissile.Kind.SHELL:
			base = 30
		RatMissile.Kind.KING:
			base = 100
	return int(roundf(base * _combo_multiplier()))


func _combo_multiplier() -> float:
	if combo <= 1:
		return 1.0
	return minf(1.0 + 0.25 * (combo - 1), COMBO_CAP)


func _combo_milestone_check() -> void:
	var lvl := 0
	if combo >= 17:
		lvl = 4
	elif combo >= 13:
		lvl = 3
	elif combo >= 9:
		lvl = 2
	elif combo >= 5:
		lvl = 1
	if lvl > combo_milestone:
		combo_milestone = lvl
		_show_banner("COMBO ×%d!" % (lvl + 1))
		sfx.play("combo_up")
		_vibrate(20)


func _fmt_mult(m: float) -> String:
	if absf(m - roundf(m)) < 0.001:
		return "×%d" % int(roundf(m))
	return "×%.2f" % m


func _rat_landed(d: RatMissile) -> void:
	if not rats.has(d):
		return
	rats.erase(d)
	d.queue_free()
	_spawn_explosion(d.position, 40.0, false)
	sfx.play("explosion")
	# Damage the nearest defense: a building, else a turret in range.
	var hit := false
	for c in cities:
		if c.damage_nearest(d.position, 40.0):
			hit = true
			break
	if not hit:
		var best_t: Turret = null
		var best_d := INF
		for t in turrets:
			if not t.alive:
				continue
			var dd: float = t.position.distance_to(d.position)
			if dd < 60.0 and dd < best_d:
				best_d = dd
				best_t = t
		if best_t != null:
			best_t.take_hit()
			hit = true
	if hit:
		sfx.play("city_hit")
		_shake(8.0)
		_check_game_over()


func _spawn_explosion(pos: Vector2, radius: float, kills: bool) -> void:
	var e := Explosion.new()
	e.name = "Boom%d" % explosions.size()
	e.position = pos
	e.max_radius = radius
	e.kills_rats = kills
	world.add_child(e)
	explosions.append(e)


func _drop_biscuit(pos: Vector2) -> void:
	var b := BiscuitDrop.new()
	b.setup(pos)
	bisc_drops.append(b)
	world.add_child(b)


func _drop_powerup(pos: Vector2) -> void:
	var types := ["double", "wide", "slow", "shield"]
	var p := PowerUpDrop.new()
	p.setup(pos, types[randi() % types.size()])
	power_drops.append(p)
	world.add_child(p)


func _try_collect(pos: Vector2) -> bool:
	for b in bisc_drops:
		if is_instance_valid(b) and (b.position - pos).length() < 40.0:
			b.done = true
			b.queue_free()
			bisc_drops.erase(b)
			_score(25)
			_score_popup(pos + Vector2(0, -24.0), "+25")
			biscuit_run += 2
			Meta.biscuits += 2
			sfx.play("biscuit")
			fx.burst(pos, "spark", 1.0)
			_vibrate(10)
			return true
	for p in power_drops:
		if is_instance_valid(p) and (p.position - pos).length() < 40.0:
			p.done = true
			p.queue_free()
			power_drops.erase(p)
			_apply_power(p.ptype)
			return true
	return false


func _apply_power(type: String) -> void:
	power = type
	power_timer = float(POWER_DUR.get(type, 8.0))
	sfx.play("powerup")
	_show_banner("POWER-UP: %s" % POWER_NAMES.get(type, type.to_upper()))
	_vibrate(25)
	for c in cities:
		c.shielded = (type == "shield")


# ------------------------------------------------------------- game over

func _check_game_over() -> void:
	if state == State.GAME_OVER:
		return
	if _alive_buildings() == 0 or _alive_turrets() == 0:
		_game_over()


func _game_over() -> void:
	state = State.GAME_OVER
	Engine.time_scale = 1.0
	clutch_until = 0
	sfx.play("game_over")
	# Persist meta state
	Meta.stats["runs"] = int(Meta.stats.get("runs", 0)) + 1
	Meta.stats["kills"] = int(Meta.stats.get("kills", 0)) + kills_run
	Meta.stats["best_wave"] = maxi(int(Meta.stats.get("best_wave", 0)), wave)
	Meta.stats["best_combo"] = maxi(int(Meta.stats.get("best_combo", 0)), best_combo_run)
	Meta.stats["biscuits_earned"] = int(Meta.stats.get("biscuits_earned", 0)) + biscuit_run
	Meta.biscuits += biscuit_run
	if daily:
		var ds := Meta.daily_seed()
		if int(Meta.daily.get("date", 0)) != ds:
			Meta.daily = {"date": ds, "score": 0}
		if score > int(Meta.daily.get("score", 0)):
			Meta.daily["score"] = score
	var new_best := score > prev_best and score > 0
	if new_best:
		best = score
		Meta.best = best
	Meta.save_all()
	_update_hud()
	final_label.text = "final score %d — the rats got the last biscuit" % score
	stats_label.text = "wave %d   ·   %d rats popped   ·   best combo ×%d   ·   +%d biscuits" % [wave, kills_run, best_combo_run, biscuit_run]
	newbest_label.visible = new_best
	if new_best:
		fx.confetti()
		sfx.play("unlock")
	gameover_layer.visible = true
	if copy_btn != null:
		copy_btn.text = "COPY SCORE"


# ------------------------------------------------------------- helpers

func _alive_buildings() -> int:
	var n := 0
	for c in cities:
		n += c.alive_count()
	return n


func _alive_turrets() -> int:
	var n := 0
	for t in turrets:
		if t.alive:
			n += 1
	return n


func _score(points: int) -> void:
	score += points
	if score > best:
		best = score
	_update_hud()


func _shake(amount: float) -> void:
	shake = maxf(shake, amount)


func _vibrate(ms: int) -> void:
	# Godot 4 has no static Input.vibrate(); call dynamically so this compiles
	# everywhere and only fires where the platform provides haptics.
	if DisplayServer.get_name() != "Android":
		return
	if Input.has_method("vibrate"):
		Input.call("vibrate", ms)
