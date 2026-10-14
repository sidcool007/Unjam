extends Node
## Autoload "Audio": 100% procedural (synthesised) original sound effects and
## a short ambient loop, so no third-party audio assets or licences exist.
## Everything is optional: if a stream fails to build, play() is a no-op.

const RATE := 22050
const SFX_NAMES := ["tap", "select", "move", "invalid", "clear", "win", "fail", "coin", "undo"]

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _next := 0
var sound_on := true
var music_on := true


func _ready() -> void:
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -16.0
	add_child(_music)
	_build_sfx()
	var prog = get_node_or_null("/root/Progress")
	if prog:
		prog.settings_changed.connect(_sync_settings)
		_sync_settings()


func _sync_settings() -> void:
	var prog = get_node_or_null("/root/Progress")
	if prog == null:
		return
	sound_on = bool(prog.settings["sound"])
	music_on = bool(prog.settings["music"])
	if music_on:
		start_music()
	else:
		_music.stop()


func play(name: String, pitch: float = 1.0) -> void:
	if not sound_on or not _streams.has(name) or _players.is_empty():
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[name]
	p.pitch_scale = pitch
	p.volume_db = -6.0
	p.play()


func start_music() -> void:
	if not music_on or _music == null:
		return
	if _music.stream == null:
		_music.stream = _build_music()
	if not _music.playing and _music.stream != null:
		_music.play()


# ------------------------------------------------------------ synthesis

func _wav(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, clampi(int(samples[i] * 32000.0), -32768, 32767))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w


## notes: Array of [freq_hz_start, freq_hz_end, seconds, volume]
func _seq(notes: Array, wave: String = "sine") -> AudioStreamWAV:
	var out := PackedFloat32Array()
	for n in notes:
		var count := int(n[2] * RATE)
		var phase := 0.0
		for i in count:
			var t := float(i) / float(count)
			var f: float = lerpf(n[0], n[1], t)
			phase += TAU * f / RATE
			var s := sin(phase)
			if wave == "soft":
				s = 0.7 * sin(phase) + 0.2 * sin(2.0 * phase) + 0.1 * sin(3.0 * phase)
			var env := minf(t / 0.06, 1.0) * pow(1.0 - t, 1.6)
			out.append(s * env * float(n[3]))
	return _wav(out)


func _build_sfx() -> void:
	_streams["tap"] = _seq([[660.0, 560.0, 0.05, 0.35]])
	_streams["select"] = _seq([[520.0, 780.0, 0.09, 0.4]], "soft")
	_streams["move"] = _seq([[400.0, 300.0, 0.10, 0.4], [300.0, 260.0, 0.06, 0.25]], "soft")
	_streams["invalid"] = _seq([[200.0, 150.0, 0.14, 0.4]], "soft")
	_streams["undo"] = _seq([[500.0, 330.0, 0.11, 0.35]], "soft")
	_streams["clear"] = _seq([[523.0, 523.0, 0.08, 0.4], [659.0, 659.0, 0.08, 0.4], [784.0, 784.0, 0.16, 0.45]], "soft")
	_streams["coin"] = _seq([[988.0, 988.0, 0.06, 0.35], [1319.0, 1319.0, 0.14, 0.35]])
	_streams["win"] = _seq([[523.0, 523.0, 0.12, 0.45], [659.0, 659.0, 0.12, 0.45], [784.0, 784.0, 0.12, 0.45], [1047.0, 1047.0, 0.35, 0.5]], "soft")
	_streams["fail"] = _seq([[330.0, 330.0, 0.16, 0.4], [262.0, 262.0, 0.16, 0.4], [196.0, 180.0, 0.3, 0.4]], "soft")


func _build_music() -> AudioStreamWAV:
	# 8-second calm loop: Am - F - C - G arpeggio, gentle pad.
	var chords := [[220.0, 261.6, 329.6], [174.6, 220.0, 261.6], [261.6, 329.6, 392.0], [196.0, 246.9, 293.7]]
	var out := PackedFloat32Array()
	var note_len := int(0.25 * RATE)
	for chord in chords:
		for step in 8:
			var f: float = chord[[0, 1, 2, 1, 0, 1, 2, 1][step]] * (2.0 if step % 4 == 2 else 1.0)
			var ph := 0.0
			for i in note_len:
				var t := float(i) / note_len
				ph += TAU * f / RATE
				out.append(sin(ph) * minf(t / 0.1, 1.0) * pow(1.0 - t, 1.2) * 0.35)
	return _wav(out, true)
