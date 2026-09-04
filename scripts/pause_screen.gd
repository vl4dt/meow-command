class_name PauseScreen
extends CanvasLayer
## Pause menu: RESUME / RESTART / QUIT + sound toggle.
## The tree is paused while this is up, so this layer runs with
## PROCESS_MODE_ALWAYS and also catches ESC (ui_cancel) to resume.

var _game: Node = null
var _sound_btn: Button = null


func setup(game: Node) -> void:
	_game = game
	layer = 11
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


func show_pause() -> void:
	visible = true
	_update_sound_btn()


func hide_screen() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_game._resume()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.16, 0.1, 0.18, 0.55)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	add_child(dim)

	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.24, 0.17, 0.25, 0.96)
	sb.set_corner_radius_all(24)
	sb.set_content_margin_all(30)
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(1280.0 / 2.0 - 240.0, 130.0)
	panel.size = Vector2(480, 460)
	add_child(panel)

	var title := Label.new()
	title.text = "PAUSED"
	title.position = Vector2(1280.0 / 2.0 - 240.0, 150.0)
	title.size = Vector2(480, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Palette.UI_TEXT)
	add_child(title)

	var info := Label.new()
	info.position = Vector2(1280.0 / 2.0 - 240.0, 214.0)
	info.size = Vector2(480, 30)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 20)
	info.add_theme_color_override("font_color", Palette.UI_TEXT)
	info.name = "PauseInfo"
	add_child(info)

	var cx := 1280.0 / 2.0 - 130.0
	_add_button("RESUME", Vector2(cx, 270), func(): _game._resume())
	_add_button("RESTART", Vector2(cx, 346), func(): _game._restart_run())
	_add_button("QUIT TO TITLE", Vector2(cx, 422), func(): _game._to_title())
	_sound_btn = _add_button("", Vector2(cx, 498), _toggle_sound)
	_update_sound_btn()


func _toggle_sound() -> void:
	_game._toggle_sound()
	_update_sound_btn()


func _update_sound_btn() -> void:
	if _sound_btn != null:
		_sound_btn.text = "SOUND: ON" if _game.sound_on else "SOUND: OFF"
	var info := get_node_or_null("PauseInfo")
	if info is Label and _game != null:
		info.text = "score %d · wave %d" % [_game.score, _game.wave]


func _add_button(text: String, pos: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(260, 60)
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_color_override("font_color", Palette.UI_TEXT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.UI_ACCENT
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(10)
	b.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.bg_color = (Palette.UI_ACCENT as Color).lightened(0.18)
	b.add_theme_stylebox_override("hover", sbh)
	var sbd := sb.duplicate() as StyleBoxFlat
	sbd.bg_color = (Palette.UI_ACCENT as Color).darkened(0.18)
	b.add_theme_stylebox_override("pressed", sbd)
	b.pressed.connect(cb)
	add_child(b)
	return b
