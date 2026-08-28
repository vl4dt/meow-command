class_name Palette
extends RefCounted
## Shared pastel palette for the whole game — one place to retheme.

# --- Sky & world ---
const SKY_TOP := Color("#ffd9e8")
const SKY_MID := Color("#cfe4ff")
const SKY_BOTTOM := Color("#fff3d6")
const SUN := Color("#ffdf8a")
const SUN_FACE := Color("#e8a94e")
const CLOUD := Color("white", 0.9)
const HILL_FAR := Color("#cdeecb")
const HILL_NEAR := Color("#b2e3ae")
const GROUND := Color("#9fd99a")
const GROUND_EDGE := Color("#7cc477")

# --- Cat city ---
const BUILDING_COLORS: Array[Color] = [
	Color("#f7a8c4"),
	Color("#9fc3f7"),
	Color("#c3a8f7"),
	Color("#f7cf9f"),
	Color("#9fe8cf"),
]
const BUILDING_ROOF := Color("#5b4a5e")
const WINDOW := Color("#fff8e1")
const WINDOW_FRAME := Color("#8a6f84")
const DOOR := Color("#8a6f84")
const HEART := Color("#ff6f91")
const RUBBLE := Color("#b9a8a0")

# --- Turrets ---
const TURRET_BODY := Color("#f7c873")
const TURRET_BELLY := Color("#ffe3b3")
const TURRET_BARREL := Color("#7a6a5f")
const CAT_EYE := Color("#3a2e2a")
const CAT_CHEEK := Color("#ff9eb5")
const TURRET_DEAD := Color("#b8b0ad")

# --- Dogs ---
const DOG_BODY := Color("#d9a066")
const DOG_EAR := Color("#a9744f")
const DOG_MUZZLE := Color("#f3d3b3")
const DOG_EYE := Color("#3a2e2a")
const DOG_NOSE := Color("#4a3728")
const DOG_TONGUE := Color("#ff8fa3")
const DOG_TRAIL := Color("#ffc98a")

# --- Player & FX ---
const PLAYER_MISSILE := Color("#6fd3ff")
const EXPLOSION_OUT := Color("#ffb3c7")
const EXPLOSION_IN := Color("#fff1f5")

# --- UI ---
const UI_TEXT := Color("#5b4a5e")
const UI_ACCENT := Color("#ff7aa2")
const OVERLAY_DIM := Color("#3a2e4a", 0.55)
