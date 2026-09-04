extends Node
## Cute procedural sound effects + 3-tier music, all generated in code
## (no audio assets needed). 16-bit mono WAVs rendered at startup.
##
## - 6-voice SFX pool so chain-pops don't chop each other.
## - Music tiers (calm/upbeat/intense) escalate with the waves.
## - unlock() must be called from the first user gesture (Android audio).
## - Drop-in: res://assets/audio/<name>.ogg replaces any synthesized stream
##   (launch, pop, explosion, city_hit, wave, game_over, combo_up, powerup,
##   biscuit, boss, unlock, meow, music_calm, music_upbeat, music_intense).
##   See ART_SPECS.md §6.

const RATE := 22050
const VOICES := 6
const MUSIC_DB := -20.0
const SFX_DB := -6.0

var _players: Array[AudioStreamPlayer] = []
var _voice := 0
var _music: AudioStreamPlayer
var _streams: Dictionary = {}
var _unlocked := false
var _sound_on := true
var _tier: String = "calm"


func _ready() -> void:
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.volume_db = SFX_DB
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = MUSIC_DB
	_music.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music)
	_build_streams()


func _exit_tree() -> void:
	# Release stream references before the audio server shuts down
	# (prevents AudioStreamWAV/PlaybackWAV leak warnings at exit).
	_music.stop()
	for p in _players:
		p.stop()
	_music.stream = null
	for p in _players:
		p.stream = null
	_streams.clear()


## Android audio unlock — call from the first user gesture (any tap/button).
func unlock() -> void:
	if _unlocked:
		return
	_unlocked = true
	if _sound_on:
		_play_music()


## Master sound toggle (settings / title screen).
func set_sound(on: bool) -> void:
	_sound_on = on
	if on:
		if _unlocked:
			_play_music()
	else:
		_music.stop()


## Play an SFX by name on the next free voice.
func play(name: String) -> void:
	if not _sound_on or _players.is_empty():
		return
	var s := _stream(name)
	if s == null:
		return
	var p: AudioStreamPlayer = _players[_voice]
	_voice = (_voice + 1) % VOICES
	p.stream = s
	p.play()


## Switch the music tier (calm / upbeat / intense).
func switch_tier(tier: String) -> void:
	if tier == _tier:
		return
	_tier = tier
	_play_music()


func _play_music() -> void:
	if not _unlocked or not _sound_on:
		return
	var s := _stream("music_" + _tier)
	if s == null:
		return
	_music.stream = s
	_music.play(true)


func _stream(name: String) -> AudioStream:
	var a := Assets.audio(name)
	if a != null:
		return a
	var s = _streams.get(name)
	return s if s != null else null


func _build_streams() -> void:
	_streams["launch"] = _tone_stream([[880.0, 0.16, 0.5, 220.0]])
	_streams["pop"] = _tone_stream([[520.0, 0.09, 0.45, 980.0]])
	_streams["explosion"] = _noise_stream(0.35, 0.55)
	_streams["city_hit"] = _tone_stream([[150.0, 0.28, 0.6, 55.0]])
	_streams["wave"] = _tone_stream([
		[523.25, 0.12, 0.4],
		[659.25, 0.12, 0.4],
		[783.99, 0.22, 0.4],
	])
	_streams["game_over"] = _tone_stream([
		[392.0, 0.2, 0.45],
		[329.63, 0.2, 0.45],
		[261.63, 0.4, 0.45],
	])
	_streams["combo_up"] = _tone_stream([
		[659.25, 0.08, 0.4],
		[880.0, 0.14, 0.45],
	])
	_streams["powerup"] = _tone_stream([
		[440.0, 0.08, 0.4],
		[554.37, 0.08, 0.4],
		[659.25, 0.16, 0.45],
	])
	_streams["biscuit"] = _tone_stream([
		[783.99, 0.07, 0.4],
		[1174.66, 0.1, 0.4],
	])
	_streams["boss"] = _tone_stream([
		[110.0, 0.25, 0.6, 55.0],
		[82.41, 0.5, 0.55, 41.2],
	])
	_streams["unlock"] = _tone_stream([
		[523.25, 0.1, 0.4],
		[659.25, 0.1, 0.4],
		[783.99, 0.1, 0.4],
		[1046.5, 0.22, 0.45],
	])
	_streams["meow"] = _tone_stream([
		[300.0, 0.22, 0.4, 560.0],
		[520.0, 0.16, 0.35, 240.0],
	])
	_streams["music_calm"] = _music_stream(_melody_calm(), 0.16)
	_streams["music_upbeat"] = _music_stream(_melody_upbeat(), 0.18)
	_streams["music_intense"] = _music_stream(_melody_intense(), 0.2)


# ------------------------------------------------------ melody definitions
# [freq_hz, dur_s] pairs; 0 = rest. All loops are ~8s.

func _melody_calm() -> Array:
	return [
		[523.25, 0.24], [0.0, 0.12], [659.25, 0.24], [783.99, 0.24],
		[0.0, 0.12], [880.0, 0.24], [783.99, 0.24], [659.25, 0.24],
		[587.33, 0.24], [0.0, 0.12], [523.25, 0.24], [659.25, 0.24],
		[783.99, 0.24], [880.0, 0.24], [1046.5, 0.48], [0.0, 0.24],
	]


func _melody_upbeat() -> Array:
	return [
		[659.25, 0.14], [783.99, 0.14], [880.0, 0.14], [783.99, 0.14],
		[659.25, 0.14], [587.33, 0.14], [659.25, 0.28], [0.0, 0.1],
		[783.99, 0.14], [880.0, 0.14], [1046.5, 0.14], [880.0, 0.14],
		[783.99, 0.14], [659.25, 0.14], [783.99, 0.28], [0.0, 0.1],
		[880.0, 0.14], [1046.5, 0.14], [1174.66, 0.28], [0.0, 0.14],
		[1046.5, 0.14], [880.0, 0.14], [783.99, 0.14], [659.25, 0.42],
	]


func _melody_intense() -> Array:
	return [
		[440.0, 0.1], [523.25, 0.1], [440.0, 0.1], [587.33, 0.1],
		[659.25, 0.2], [587.33, 0.1], [523.25, 0.1], [440.0, 0.1],
		[415.3, 0.1], [523.25, 0.1], [415.3, 0.1], [554.37, 0.1],
		[622.25, 0.2], [554.37, 0.1], [493.88, 0.1], [415.3, 0.1],
		[349.23, 0.1], [440.0, 0.1], [349.23, 0.1], [493.88, 0.1],
		[554.37, 0.1], [622.25, 0.1], [659.25, 0.3], [0.0, 0.1],
	]


# ------------------------------------------------------ synthesis helpers

## notes: array of [freq_hz, dur_s, vol, slide_to_hz?]
func _tone_stream(notes: Array) -> AudioStreamWAV:
	var out := PackedByteArray()
	var phase := 0.0
	for note in notes:
		var freq: float = note[0]
		var dur: float = note[1]
		var vol: float = note[2]
		var slide: float = note[3] if note.size() > 3 else -1.0
		var n := int(dur * RATE)
		for i in n:
			var f: float = freq if slide <= 0.0 else lerpf(freq, slide, float(i) / float(n))
			phase = fmod(phase + f / float(RATE), 1.0)
			var s := sin(TAU * phase) * vol * _envelope(i, n) * 0.55
			_append_sample(out, s)
	return _finalize(out)


func _envelope(i: int, n: int) -> float:
	var attack := maxf(1.0, float(RATE) * 0.004)
	var release := float(RATE) * 0.06
	var env := minf(float(i) / attack, 1.0)
	env = minf(env, maxf(0.0, float(n - i) / release))
	return env


func _append_sample(out: PackedByteArray, s: float) -> void:
	var v := int(clampf(s, -1.0, 1.0) * 32767.0)
	out.append(v & 0xFF)
	out.append((v >> 8) & 0xFF)


func _finalize(out: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = out
	return stream


func _noise_stream(dur: float, vol: float) -> AudioStreamWAV:
	var out := PackedByteArray()
	var n := int(dur * RATE)
	var seedv := 987654321
	for i in n:
		seedv = (seedv * 1103515245 + 12345) & 0x7FFFFFFF
		var white := float(seedv) / float(0x7FFFFFFF) * 2.0 - 1.0
		var env := 1.0 - float(i) / float(n)
		_append_sample(out, white * vol * env * env * 0.7)
	return _finalize(out)


func _music_stream(melody: Array, vol: float) -> AudioStreamWAV:
	var out := PackedByteArray()
	var phase := 0.0
	for note in melody:
		var freq: float = note[0]
		var dur: float = note[1]
		var n := int(dur * RATE)
		for i in n:
			var s := 0.0
			if freq > 0.0:
				phase = fmod(phase + freq / float(RATE), 1.0)
				s = sin(TAU * phase) * vol * _envelope(i, n)
			_append_sample(out, s)
	var stream := _finalize(out)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = out.size() / 2
	return stream
