class_name Assets
extends RefCounted
## Drop-in asset loader. Hand-crafted art in res://assets/sprites/<name>.png
## and audio in res://assets/audio/<name>.ogg replace the procedural
## fallbacks automatically — no code changes needed. Missing files are fine;
## callers always get null and fall back to _draw() art.
##
## See ART_SPECS.md for the full contract (filenames, sizes, anchors).

static var _tex_cache: Dictionary = {}
static var _aud_cache: Dictionary = {}


static func _sprite_path(name: String) -> String:
	return "res://assets/sprites/" + name + ".png"


static func _audio_path(name: String) -> String:
	return "res://assets/audio/" + name + ".ogg"


## Cached Texture2D for a sprite name, or null when the file is absent.
static func tex(name: String) -> Texture2D:
	if _tex_cache.has(name):
		return _tex_cache[name]
	var path := _sprite_path(name)
	if not FileAccess.file_exists(path):
		_tex_cache[name] = null
		return null
	var t = load(path)
	_tex_cache[name] = t if t != null else null
	return _tex_cache[name]


## Cached AudioStream for an audio name, or null when the file is absent.
static func audio(name: String) -> AudioStream:
	if _aud_cache.has(name):
		return _aud_cache[name]
	var path := _audio_path(name)
	if not FileAccess.file_exists(path):
		_aud_cache[name] = null
		return null
	var s = load(path)
	_aud_cache[name] = s if s != null else null
	return _aud_cache[name]
