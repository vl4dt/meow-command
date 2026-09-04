class_name ShopScreen
extends CanvasLayer
## Shop: themes (free to switch), cat skins (biscuit currency), trophy shelf.
## Skins are drop-in art (assets/sprites/cat_<skin>.png, see ART_SPECS.md) —
## without the file the cat stays classic, which is fine and cute.

var _game: Node = null
var _wallet: Label = null
var _theme_btns: Dictionary = {}
var _skin_btns: Dictionary = {}
var _trophy_labels: Array = []

const SKINS := {
	"default": {"name": "CLASSIC", "cost": 0},
	"mochi": {"name": "MOCHI", "cost": 100},
	"miso": {"name": "MISO", "cost": 250},
	"peppermint": {"name": "PEPPERMINT", "cost": 500},
}
const THEME_NAMES := {
	"default": "CLASSIC",
	"sakura": "SAKURA",
	"midnight": "MIDNIGHT",
}


func setup(game: Node) -> void:
	_game = game
	layer = 13
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	refresh()
	visible = false


func show_screen() -> void:
	refresh()
	visible = true


func hide_screen() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_game._hide_shop()


func refresh() -> void:
	if _wallet != null:
		_wallet.text = "BISCUITS %d" % Meta.biscuits
	for id in _theme_btns:
		var b: Button = _theme_btns[id]
		b.text = THEME_NAMES[id] + ("  ●" if Meta.theme == id else "")
	for id in _skin_btns:
		var b: Button = _skin_btns[id]
		var cost: int = int(SKINS[id]["cost"])
		if Meta.skin == id:
			b.text = str(SKINS[id]["name"]) + "  ●"
		elif Meta.has("skin_" + id):
			b.text = str(SKINS[id]["name"]) + "  ✓"
		else:
			b.text = str(SKINS[id]["name"]) + "  %d" % cost
	for e in _trophy_labels:
		var l: Label = e["label"]
		var unlocked := Meta.has_achievement(str(e["id"]))
		l.text = ("★ " if unlocked else "☆ ") + str(Meta.ACHIEVEMENTS.get(str(e["id"]), e["id"]))
		l.add_theme_color_override("font_color",
			Palette.UI_ACCENT if unlocked else Color(Palette.UI_TEXT, 0.45))


# ---------------------------------------------------------------- actions

func _pick_theme(id: String) -> void:
	Meta.theme = id
	Meta.save_all()
	Palette.apply_theme(id)
	_game.sfx.play("biscuit")
	refresh()


func _buy_skin(id: String) -> void:
	var cost: int = int(SKINS[id]["cost"])
	if Meta.has("skin_" + id):
		Meta.skin = id
		Meta.save_all()
		_game.sfx.play("biscuit")
		refresh()
		return
	if Meta.biscuits < cost:
		_game.sfx.play("city_hit")
		return
	Meta.biscuits -= cost
	Meta.owned.append("skin_" + id)
	Meta.skin = id
	Meta.save_all()
	_game.sfx.play("unlock")
	_game.fx.confetti()
	if _all_skins_owned():
		_game._check_achievement("collector")
	refresh()


func _all_skins_owned() -> bool:
	for id in SKINS:
		if not Meta.has("skin_" + id):
			return false
	return true


# ------------------------------------------------------------------- build

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.16, 0.1, 0.18, 0.65)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	add_child(dim)

	var title := _make_label(0, 34, 48, Palette.UI_TEXT)
	title.text = "SHOP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(1280, 60)
	add_child(title)

	_wallet = _make_label(0, 92, 24, Palette.UI_ACCENT)
	_wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wallet.size = Vector2(1280, 32)
	add_child(_wallet)

	# Themes (free to switch — visual customization)
	var th := _make_label(140, 144, 22, Palette.UI_ACCENT)
	th.text = "THEMES — FREE"
	add_child(th)
	var txs := [140.0, 480.0, 820.0]
	var tids := ["default", "sakura", "midnight"]
	for i in tids.size():
		var id: String = tids[i]
		var b := _make_button("", Vector2(txs[i], 182), _make_theme_cb(id))
		b.size = Vector2(280, 56)
		_theme_btns[id] = b

	# Cat skins (biscuit currency)
	var sh := _make_label(140, 268, 22, Palette.UI_ACCENT)
	sh.text = "CAT SKINS"
	add_child(sh)
	var sxs := [140.0, 390.0, 640.0, 890.0]
	var sids := ["default", "mochi", "miso", "peppermint"]
	for i in sids.size():
		var id: String = sids[i]
		var b := _make_button("", Vector2(sxs[i], 306), _make_skin_cb(id))
		b.size = Vector2(230, 56)
		_skin_btns[id] = b

	# Trophy shelf
	var ah := _make_label(140, 394, 22, Palette.UI_ACCENT)
	ah.text = "TROPHIES"
	add_child(ah)
	var col := 0
	var y := 432.0
	for id in Meta.ACHIEVEMENTS:
		var l := _make_label(0.0, 0.0, 17, Palette.UI_TEXT)
		l.size = Vector2(520, 26)
		l.position = Vector2(140.0 + float(col) * 520.0, y)
		add_child(l)
		_trophy_labels.append({"id": id, "label": l})
		col += 1
		if col == 2:
			col = 0
			y += 36.0

	_make_button("BACK", Vector2(1280.0 / 2.0 - 130.0, 648), func(): _game._hide_shop())


func _make_theme_cb(id: String) -> Callable:
	return func(): _pick_theme(id)


func _make_skin_cb(id: String) -> Callable:
	return func(): _buy_skin(id)


func _make_button(text: String, pos: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(260, 64)
	b.add_theme_font_size_override("font_size", 22)
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


func _make_label(x: float, y: float, size: int, color: Color) -> Label:
	var l := Label.new()
	l.position = Vector2(x, y)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
