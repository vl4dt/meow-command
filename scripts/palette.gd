class_name Palette
extends RefCounted
## Shared palette for the whole game — one place to retheme.
## Colors are static vars so a theme can re-tint them at runtime;
## THEMES holds the full color sets and apply_theme(name) activates one.
## Every theme defines every key (rats keep their invader colors).

# --- Sky & world ---
static var SKY_TOP := Color("#ffd9e8")
static var SKY_MID := Color("#cfe4ff")
static var SKY_BOTTOM := Color("#fff3d6")
static var SUN := Color("#ffdf8a")
static var SUN_FACE := Color("#e8a94e")
static var CLOUD := Color("white", 0.9)
static var HILL_FAR := Color("#cdeecb")
static var HILL_NEAR := Color("#b2e3ae")
static var GROUND := Color("#9fd99a")
static var GROUND_EDGE := Color("#7cc477")

# --- Cat city ---
static var BUILDING_COLORS: Array = [
	Color("#f7a8c4"),
	Color("#9fc3f7"),
	Color("#c3a8f7"),
	Color("#f7cf9f"),
	Color("#9fe8cf"),
]
static var BUILDING_ROOF := Color("#5b4a5e")
static var WINDOW := Color("#fff8e1")
static var WINDOW_FRAME := Color("#8a6f84")
static var DOOR := Color("#8a6f84")
static var HEART := Color("#ff6f91")
static var RUBBLE := Color("#b9a8a0")

# --- Turrets ---
static var TURRET_BODY := Color("#f7c873")
static var TURRET_BELLY := Color("#ffe3b3")
static var TURRET_BARREL := Color("#7a6a5f")
static var CAT_EYE := Color("#3a2e2a")
static var CAT_CHEEK := Color("#ff9eb5")
static var TURRET_DEAD := Color("#b8b0ad")

# --- Rats (the invaders) ---
static var RAT_BODY := Color("#d9a066")
static var RAT_SPLITTER := Color("#c96a4a")
static var RAT_EAR := Color("#a9744f")
static var RAT_MUZZLE := Color("#f3d3b3")
static var RAT_EYE := Color("#3a2e2a")
static var RAT_NOSE := Color("#4a3728")
static var RAT_TONGUE := Color("#ff8fa3")
static var RAT_TRAIL := Color("#ffc98a")

# --- Player & FX ---
static var PLAYER_MISSILE := Color("#6fd3ff")
static var EXPLOSION_OUT := Color("#ffb3c7")
static var EXPLOSION_IN := Color("#fff1f5")

# --- UI ---
static var UI_TEXT := Color("#5b4a5e")
static var UI_ACCENT := Color("#ff7aa2")
static var OVERLAY_DIM := Color("#3a2e4a", 0.55)


## Full color sets. "default" mirrors the static vars above.
const THEMES := {
	"default": {
		"SKY_TOP": Color("#ffd9e8"), "SKY_MID": Color("#cfe4ff"), "SKY_BOTTOM": Color("#fff3d6"),
		"SUN": Color("#ffdf8a"), "SUN_FACE": Color("#e8a94e"), "CLOUD": Color("white", 0.9),
		"HILL_FAR": Color("#cdeecb"), "HILL_NEAR": Color("#b2e3ae"),
		"GROUND": Color("#9fd99a"), "GROUND_EDGE": Color("#7cc477"),
		"BUILDING_COLORS": [Color("#f7a8c4"), Color("#9fc3f7"), Color("#c3a8f7"), Color("#f7cf9f"), Color("#9fe8cf")],
		"BUILDING_ROOF": Color("#5b4a5e"), "WINDOW": Color("#fff8e1"), "WINDOW_FRAME": Color("#8a6f84"),
		"DOOR": Color("#8a6f84"), "HEART": Color("#ff6f91"), "RUBBLE": Color("#b9a8a0"),
		"TURRET_BODY": Color("#f7c873"), "TURRET_BELLY": Color("#ffe3b3"), "TURRET_BARREL": Color("#7a6a5f"),
		"CAT_EYE": Color("#3a2e2a"), "CAT_CHEEK": Color("#ff9eb5"), "TURRET_DEAD": Color("#b8b0ad"),
		"RAT_BODY": Color("#d9a066"), "RAT_SPLITTER": Color("#c96a4a"), "RAT_EAR": Color("#a9744f"),
		"RAT_MUZZLE": Color("#f3d3b3"), "RAT_EYE": Color("#3a2e2a"), "RAT_NOSE": Color("#4a3728"),
		"RAT_TONGUE": Color("#ff8fa3"), "RAT_TRAIL": Color("#ffc98a"),
		"PLAYER_MISSILE": Color("#6fd3ff"), "EXPLOSION_OUT": Color("#ffb3c7"), "EXPLOSION_IN": Color("#fff1f5"),
		"UI_TEXT": Color("#5b4a5e"), "UI_ACCENT": Color("#ff7aa2"), "OVERLAY_DIM": Color("#3a2e4a", 0.55),
	},
	"sakura": {
		"SKY_TOP": Color("#ffe0f0"), "SKY_MID": Color("#ffd0e8"), "SKY_BOTTOM": Color("#fff0f6"),
		"SUN": Color("#ffc2d8"), "SUN_FACE": Color("#e87ba4"), "CLOUD": Color("white", 0.9),
		"HILL_FAR": Color("#e9c9e2"), "HILL_NEAR": Color("#d9a9cd"),
		"GROUND": Color("#c9a1c1"), "GROUND_EDGE": Color("#b181a9"),
		"BUILDING_COLORS": [Color("#ffb4d2"), Color("#a9d8ff"), Color("#d4b4ff"), Color("#ffd5a9"), Color("#a9e8d1")],
		"BUILDING_ROOF": Color("#6a4a60"), "WINDOW": Color("#fff6fb"), "WINDOW_FRAME": Color("#9a7a8c"),
		"DOOR": Color("#9a7a8c"), "HEART": Color("#ff5f90"), "RUBBLE": Color("#c1a9b1"),
		"TURRET_BODY": Color("#f7c873"), "TURRET_BELLY": Color("#ffe3b3"), "TURRET_BARREL": Color("#7a6a5f"),
		"CAT_EYE": Color("#3a2e2a"), "CAT_CHEEK": Color("#ff8fb1"), "TURRET_DEAD": Color("#c1b1b9"),
		"RAT_BODY": Color("#d9a066"), "RAT_SPLITTER": Color("#c96a4a"), "RAT_EAR": Color("#a9744f"),
		"RAT_MUZZLE": Color("#f3d3b3"), "RAT_EYE": Color("#3a2e2a"), "RAT_NOSE": Color("#4a3728"),
		"RAT_TONGUE": Color("#ff8fa3"), "RAT_TRAIL": Color("#ffc98a"),
		"PLAYER_MISSILE": Color("#9fd8ff"), "EXPLOSION_OUT": Color("#ff9fc1"), "EXPLOSION_IN": Color("#fff0f8"),
		"UI_TEXT": Color("#5e4a60"), "UI_ACCENT": Color("#ff5fa0"), "OVERLAY_DIM": Color("#4a2e4a", 0.55),
	},
	"midnight": {
		"SKY_TOP": Color("#191f38"), "SKY_MID": Color("#272d52"), "SKY_BOTTOM": Color("#383e68"),
		"SUN": Color("#e9e9ff"), "SUN_FACE": Color("#b9b9e2"), "CLOUD": Color("white", 0.22),
		"HILL_FAR": Color("#2e4a4c"), "HILL_NEAR": Color("#254042"),
		"GROUND": Color("#2b4b3b"), "GROUND_EDGE": Color("#1f3a2e"),
		"BUILDING_COLORS": [Color("#7a8fd6"), Color("#8fd6cb"), Color("#b48fd6"), Color("#d6b490"), Color("#8fd6a9")],
		"BUILDING_ROOF": Color("#14172e"), "WINDOW": Color("#ffe89f"), "WINDOW_FRAME": Color("#272d52"),
		"DOOR": Color("#272d52"), "HEART": Color("#ff6f91"), "RUBBLE": Color("#5b607c"),
		"TURRET_BODY": Color("#e9b960"), "TURRET_BELLY": Color("#ffd9a0"), "TURRET_BARREL": Color("#5b607c"),
		"CAT_EYE": Color("#f0f0ff"), "CAT_CHEEK": Color("#ff8fb1"), "TURRET_DEAD": Color("#4b506c"),
		"RAT_BODY": Color("#d9a066"), "RAT_SPLITTER": Color("#c96a4a"), "RAT_EAR": Color("#a9744f"),
		"RAT_MUZZLE": Color("#f3d3b3"), "RAT_EYE": Color("#ffd24a"), "RAT_NOSE": Color("#4a3728"),
		"RAT_TONGUE": Color("#ff8fa3"), "RAT_TRAIL": Color("#ffc98a"),
		"PLAYER_MISSILE": Color("#8fd8ff"), "EXPLOSION_OUT": Color("#b48fd6"), "EXPLOSION_IN": Color("#f0e9ff"),
		"UI_TEXT": Color("#ece4f4"), "UI_ACCENT": Color("#c990ff"), "OVERLAY_DIM": Color("#0a0a1c", 0.65),
	},
}


## Activate a theme by name ("default" | "sakura" | "midnight").
static func apply_theme(name: String) -> void:
	var t: Dictionary = THEMES.get(name, THEMES["default"])
	SKY_TOP = t["SKY_TOP"]
	SKY_MID = t["SKY_MID"]
	SKY_BOTTOM = t["SKY_BOTTOM"]
	SUN = t["SUN"]
	SUN_FACE = t["SUN_FACE"]
	CLOUD = t["CLOUD"]
	HILL_FAR = t["HILL_FAR"]
	HILL_NEAR = t["HILL_NEAR"]
	GROUND = t["GROUND"]
	GROUND_EDGE = t["GROUND_EDGE"]
	BUILDING_COLORS = t["BUILDING_COLORS"]
	BUILDING_ROOF = t["BUILDING_ROOF"]
	WINDOW = t["WINDOW"]
	WINDOW_FRAME = t["WINDOW_FRAME"]
	DOOR = t["DOOR"]
	HEART = t["HEART"]
	RUBBLE = t["RUBBLE"]
	TURRET_BODY = t["TURRET_BODY"]
	TURRET_BELLY = t["TURRET_BELLY"]
	TURRET_BARREL = t["TURRET_BARREL"]
	CAT_EYE = t["CAT_EYE"]
	CAT_CHEEK = t["CAT_CHEEK"]
	TURRET_DEAD = t["TURRET_DEAD"]
	RAT_BODY = t["RAT_BODY"]
	RAT_SPLITTER = t["RAT_SPLITTER"]
	RAT_EAR = t["RAT_EAR"]
	RAT_MUZZLE = t["RAT_MUZZLE"]
	RAT_EYE = t["RAT_EYE"]
	RAT_NOSE = t["RAT_NOSE"]
	RAT_TONGUE = t["RAT_TONGUE"]
	RAT_TRAIL = t["RAT_TRAIL"]
	PLAYER_MISSILE = t["PLAYER_MISSILE"]
	EXPLOSION_OUT = t["EXPLOSION_OUT"]
	EXPLOSION_IN = t["EXPLOSION_IN"]
	UI_TEXT = t["UI_TEXT"]
	UI_ACCENT = t["UI_ACCENT"]
	OVERLAY_DIM = t["OVERLAY_DIM"]
