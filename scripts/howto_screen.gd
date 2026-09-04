class_name HowToScreen
extends CanvasLayer
## How-to-play screen: four short panels explaining the core loop.

var _game: Node = null


func setup(game: Node) -> void:
	_game = game
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


func show_screen() -> void:
	visible = true


func hide_screen() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_game._hide_howto()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.16, 0.1, 0.18, 0.6)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	add_child(dim)

	var title := Label.new()
	title.text = "HOW TO PLAY"
	title.position = Vector2(0, 48)
	title.size = Vector2(1280, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Palette.UI_TEXT)
	add_child(title)

	_panel(140, "TAP TO FIRE", "Tap anywhere — the nearest cat turret pops a star missile at that spot.")
	_panel(268, "CHAIN THE BOOMS", "Explosions pop nearby rats. Chain kills within 2.5s to stack COMBO points, up to ×5.")
	_panel(396, "KNOW YOUR FOES", "Big rats split when popped. Helmeted shells need 2 hits. Weavers dodge sideways. Every 5th wave: the RAT KING.")
	_panel(524, "PROTECT THE CITY", "Rats that land smash buildings AND turrets. Lose all of either, and it's game over. Biscuits = currency for the shop.")

	var b := _add_button("BACK", Vector2(1280.0 / 2.0 - 130.0, 648), func(): _game._hide_howto())
	b.add_theme_font_size_override("font_size", 28)


func _panel(y: float, head: String, body: String) -> void:
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.24, 0.17, 0.25, 0.92)
	sb.set_corner_radius_all(18)
	sb.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(140.0, y)
	panel.size = Vector2(1000, 104)
	add_child(panel)

	var h := Label.new()
	h.text = head
	h.position = Vector2(170.0, y + 12.0)
	h.size = Vector2(940, 30)
	h.add_theme_font_size_override("font_size", 24)
	h.add_theme_color_override("font_color", Palette.UI_ACCENT)
	add_child(h)

	var t := Label.new()
	t.text = body
	t.position = Vector2(170.0, y + 48.0)
	t.size = Vector2(940, 48)
	t.add_theme_font_size_override("font_size", 19)
	t.add_theme_color_override("font_color", Palette.UI_TEXT)
	add_child(t)


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
