class_name TitleScreen
extends CanvasLayer
## Title screen: logo, PLAY / DAILY / HOW TO, sound toggle, best + wallet.
## Shown when the game state is TITLE; the world idles behind a dim.

var _game: Node = null
var _sound_btn: Button = null
var _best_label: Label = null
var _bisc_label: Label = null


func setup(game: Node) -> void:
	_game = game
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func hide_screen() -> void:
	visible = false


func refresh_wallet() -> void:
	if _best_label != null:
		_best_label.text = "BEST %d" % _game.best
	if _bisc_label != null:
		_bisc_label.text = "BISCUITS %d" % Meta.biscuits


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.16, 0.1, 0.18, 0.45)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	add_child(dim)

	# Logo: hand-crafted assets/sprites/logo.png (1024×512) or text.
	var logo := Assets.tex("logo")
	if logo != null:
		var img := TextureRect.new()
		img.texture = logo
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.custom_minimum_size = Vector2(640, 320)
		img.position = Vector2(1280.0 / 2.0 - 320.0, 40.0)
		add_child(img)
	else:
		var title := Label.new()
		title.text = "MEOW COMMAND"
		title.position = Vector2(0, 70)
		title.size = Vector2(1280, 100)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 72)
		title.add_theme_color_override("font_color", Palette.UI_TEXT)
		title.add_theme_color_override("font_shadow_color", Color(0.36, 0.29, 0.37, 0.9))
		title.add_theme_constant_override("shadow_offset_x", 3)
		title.add_theme_constant_override("shadow_offset_y", 3)
		add_child(title)
		var sub := Label.new()
		sub.text = "defend kitty city from the rat swarm"
		sub.position = Vector2(0, 178)
		sub.size = Vector2(1280, 34)
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.add_theme_font_size_override("font_size", 24)
		sub.add_theme_color_override("font_color", Palette.UI_TEXT)
		add_child(sub)

	var cx := 1280.0 / 2.0 - 130.0
	_add_button("PLAY", Vector2(cx, 300), func(): _game._begin_run(false))
	_add_button("DAILY", Vector2(cx, 376), func(): _game._begin_run(true))
	_add_button("HOW TO", Vector2(cx, 452), func(): _game._show_howto())
	_sound_btn = _add_button("", Vector2(cx, 528), _toggle_sound)
	_update_sound_btn()

	_best_label = _make_label(26, 660, 22, Palette.UI_TEXT)
	_best_label.text = "BEST %d" % _game.best
	add_child(_best_label)
	_bisc_label = _make_label(1280.0 - 26.0, 660, 22, Palette.UI_TEXT)
	_bisc_label.text = "BISCUITS %d" % Meta.biscuits
	_bisc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_bisc_label.size = Vector2(400, 30)
	add_child(_bisc_label)
	var ver := _make_label(1280.0 - 26.0, 688, 14, Palette.UI_TEXT)
	ver.text = "v1.0 · a cat defense game"
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ver.size = Vector2(400, 22)
	add_child(ver)


func _toggle_sound() -> void:
	_game._toggle_sound()
	_update_sound_btn()


func _update_sound_btn() -> void:
	if _sound_btn != null:
		_sound_btn.text = "SOUND: ON" if _game.sound_on else "SOUND: OFF"


func _add_button(text: String, pos: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(260, 64)
	b.add_theme_font_size_override("font_size", 28)
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
	add_child(b)
	return b


func _make_label(x: float, y: float, size: int, color: Color) -> Label:
	var l := Label.new()
	l.position = Vector2(x, y)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
