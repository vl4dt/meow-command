extends Node
## Cute procedural sound effects + a soft music loop, all generated in code
## (no audio assets needed). 16-bit mono WAVs rendered at startup.

const RATE := 22050

var _player: AudioStreamPlayer
var _music: AudioStreamPlayer
var _streams: Dictionary = {}


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.volume_db = -6.0
	add_child(_player)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -20.0
	add_child(_music)
	_build_streams()
	start_music()


func _exit_tree() -> void:
	# Release stream references before the audio server shuts down
	# (prevents AudioStreamWAV/PlaybackWAV leak warnings at exit).
	_music.stop()
	_player.stop()
	_music.stream = null
	_player.stream = null
	_streams.clear()


func start_music() -> void:
	var s: AudioStreamWAV = _streams.get("music")
	if s:
		_music.stream = s
		_music.play(true)


func play(name: String) -> void:
	var s: AudioStreamWAV = _streams.get(name)
	if s:
		_player.stream = s
		_player.play()


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
	_streams["music"] = _music_stream()


# notes: array of [freq_hz, dur_s, vol, slide_to_hz?]
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


func _music_stream() -> AudioStreamWAV:
	# A sleepy pentatonic lullaby loop: [freq, dur] pairs (0 = rest).
	var melody: Array = [
		[523.25, 0.24], [0.0, 0.12], [659.25, 0.24], [783.99, 0.24],
		[0.0, 0.12], [880.0, 0.24], [783.99, 0.24], [659.25, 0.24],
		[587.33, 0.24], [0.0, 0.12], [523.25, 0.24], [659.25, 0.24],
		[783.99, 0.24], [880.0, 0.24], [1046.5, 0.48], [0.0, 0.24],
	]
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
				s = sin(TAU * phase) * 0.16 * _envelope(i, n)
			_append_sample(out, s)
	var stream := _finalize(out)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = out.size() / 2
	return stream
