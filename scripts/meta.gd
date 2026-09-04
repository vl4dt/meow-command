class_name Meta
extends RefCounted
## Persisted meta state — user://meta.save (plain JSON, readable by humans).
## Holds the wallet, unlocks, theme/skin selection, achievements, lifetime
## stats, and the daily-challenge record. The game reads it once at boot and
## writes it on game over / purchase / settings change.


const PATH := "user://meta.save"

static var best: int = 0
static var biscuits: int = 0
static var owned: Array = ["theme_default", "skin_default"]
static var theme: String = "default"
static var skin: String = "default"
static var sound_on: bool = true
static var achievements: Array = []
static var stats: Dictionary = {
	"runs": 0, "kills": 0, "best_wave": 0, "best_combo": 0,
	"biscuits_earned": 0, "bosses": 0,
}
static var daily: Dictionary = {"date": 0, "score": 0}

## Trophy shelf: id -> "Name — description".
const ACHIEVEMENTS := {
	"first_kill": "First Pounce — pop your first rat",
	"combo5": "Chain Reaction — reach a ×2 combo",
	"combo13": "Cat-nado — reach a ×4 combo",
	"king_slayer": "Rat King Slayer — defeat the Rat King",
	"wave5": "Survivor — reach wave 5",
	"wave10": "Veteran — reach wave 10",
	"kills50": "Sharpshooter — pop 50 rats in one run",
	"score1000": "Century Club — score 1000 in one run",
	"biscuits100": "Biscuit Baker — earn 100 biscuits total",
	"collector": "Collector — own every cat skin",
}


static func load_all() -> void:
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return
	best = int(data.get("best", 0))
	biscuits = int(data.get("biscuits", 0))
	if data.has("owned") and data["owned"] is Array:
		owned = data["owned"]
	theme = str(data.get("theme", "default"))
	skin = str(data.get("skin", "default"))
	sound_on = bool(data.get("sound_on", true))
	if data.has("achievements") and data["achievements"] is Array:
		achievements = data["achievements"]
	if data.has("stats") and data["stats"] is Dictionary:
		stats = data["stats"]
	if data.has("daily") and data["daily"] is Dictionary:
		daily = data["daily"]


static func save_all() -> void:
	var data := {
		"best": best,
		"biscuits": biscuits,
		"owned": owned,
		"theme": theme,
		"skin": skin,
		"sound_on": sound_on,
		"achievements": achievements,
		"stats": stats,
		"daily": daily,
	}
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))
		f.close()


## True when `id` (e.g. "theme_sakura") is owned or the default freebie.
static func has(id: String) -> bool:
	return owned.has(id)


static func has_achievement(id: String) -> bool:
	return achievements.has(id)


## Today's seed (yyyymmdd) for the daily challenge.
static func daily_seed() -> int:
	var d := Time.get_date_dict_from_system()
	return int(d["year"]) * 10000 + int(d["month"]) * 100 + int(d["day"])
