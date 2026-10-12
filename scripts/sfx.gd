extends Node
## Procedurally synthesised sound effects and background music. No audio files ship with the game.

const RATE := 22050
const POOL_SIZE := 10

var _streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, "Master")
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)

	_streams.pop = _wav(_synth_pop())
	_streams.bump = _wav(_synth_bump())
	_streams.drop = _wav(_synth_sweep(700.0, 180.0, 0.22))
	_streams.click = _wav(_synth_sweep(1400.0, 900.0, 0.035))
	_streams.tick = _wav(_synth_sweep(1800.0, 1800.0, 0.05))
	_streams.win = _wav(_synth_jingle([0, 4, 7, 12, 16], 0.11, 0.5))
	_streams.lose = _wav(_synth_jingle([7, 4, 0, -5], 0.16, 0.45))
	_streams.go = _wav(_synth_jingle([0, 7, 12], 0.07, 0.35))


func set_volumes(master: float, music: float, sfx: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(music, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(sfx, 0.0001)))


func play(name: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var p := _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = _streams[name]
	p.pitch_scale = clampf(pitch, 0.25, 4.0)
	p.volume_db = volume_db
	p.play()


## Starts a looping tune in the given key (semitones above C). Same key keeps playing.
func play_music(root: int) -> void:
	var key := "music_%d" % root
	if not _streams.has(key):
		_streams[key] = _wav(_synth_music(root), true)
	if _music.stream == _streams[key] and _music.playing:
		return
	_music.stream = _streams[key]
	_music.play()


# ---------------------------------------------------------------- synthesis

func _wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
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


func _synth_pop() -> PackedFloat32Array:
	var n := int(RATE * 0.09)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := lerpf(420.0, 1100.0, minf(t / 0.05, 1.0))
		phase += TAU * f / RATE
		out[i] = sin(phase) * exp(-t * 38.0) * 0.6
	return out


func _synth_bump() -> PackedFloat32Array:
	var n := int(RATE * 0.2)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in n:
		var t := float(i) / RATE
		phase += TAU * lerpf(140.0, 55.0, t / 0.2) / RATE
		out[i] = (sin(phase) * 0.8 + rng.randf_range(-0.3, 0.3) * exp(-t * 60.0)) * exp(-t * 18.0)
	return out


func _synth_sweep(f0: float, f1: float, length: float) -> PackedFloat32Array:
	var n := int(RATE * length)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		phase += TAU * lerpf(f0, f1, t / length) / RATE
		out[i] = sin(phase) * (1.0 - t / length) * 0.45
	return out


func _synth_jingle(semitones: Array, step: float, vol: float) -> PackedFloat32Array:
	var note_len := int(RATE * step)
	var n := note_len * (semitones.size() + 3)
	var out := PackedFloat32Array()
	out.resize(n)
	for k in semitones.size():
		var f := 523.25 * pow(2.0, semitones[k] / 12.0)
		var start := k * note_len
		var dur := note_len * (4 if k == semitones.size() - 1 else 2)
		for j in dur:
			if start + j >= n:
				break
			var t := float(j) / RATE
			var s := sin(TAU * f * t) * 0.7 + sin(TAU * f * 2.0 * t) * 0.2
			out[start + j] += s * exp(-t * 6.0) * vol
	return out


## Four-bar I–vi–IV–V loop: soft triangle bass, plucky square-ish arpeggio, light hi-hat.
func _synth_music(root: int) -> PackedFloat32Array:
	var bpm := 116.0
	var beat := 60.0 / bpm
	var bars := 4
	var n := int(RATE * beat * 4 * bars)
	var out := PackedFloat32Array()
	out.resize(n)
	var chords := [[0, 4, 7], [9, 12, 16], [5, 9, 12], [7, 11, 14]]
	var base := 130.81 * pow(2.0, root / 12.0)  # C3 shifted
	var step_len := int(RATE * beat / 2.0)  # eighth notes
	var arp_order := [0, 1, 2, 1, 0, 2, 1, 2]
	var rng := RandomNumberGenerator.new()
	rng.seed = 99 + root
	for bar in bars:
		var chord: Array = chords[bar]
		for step in 8:
			var start := (bar * 8 + step) * step_len
			# arpeggio, two octaves up
			var f := base * 4.0 * pow(2.0, chord[arp_order[step]] / 12.0)
			# bass on beats
			var fb := base * 0.5 * pow(2.0, chord[0] / 12.0)
			for j in step_len:
				var i := start + j
				if i >= n:
					break
				var t := float(j) / RATE
				var arp := (sin(TAU * f * t) + 0.25 * sin(TAU * f * 3.0 * t)) * exp(-t * 9.0) * 0.12
				var tb := float(i) / RATE
				var tri := 2.0 * absf(2.0 * fposmod(fb * tb, 1.0) - 1.0) - 1.0
				var bass := tri * 0.16 * (1.0 - 0.5 * float(j) / step_len)
				var hat := 0.0
				if step % 2 == 1 and j < 600:
					hat = rng.randf_range(-1.0, 1.0) * 0.04 * (1.0 - j / 600.0)
				out[i] += arp + bass + hat
	# soften loop seam
	for i in 200:
		out[i] *= float(i) / 200.0
		out[n - 1 - i] *= float(i) / 200.0
	return out
