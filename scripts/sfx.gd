extends Node
## Effects are synthesized from tones and noise (Greywater's synth). Music is
## Protektor's original score, streamed and crossfaded between two players.

const RATE := 22050
const MUSIC_DB := -9.0

## Per-speaker typewriter voices: [wave, base pitch, volume db].
const VOICES := {
	"child": ["tri", 1.25, -13.0], "boy": ["sq", 1.18, -16.0], "boy2": ["sq", 1.02, -16.0], "girl": ["tri", 1.45, -13.0],
	"adult_flat": ["sq", 0.72, -17.0], "woman": ["tri", 1.05, -13.0], "man": ["sq", 0.8, -16.0], "system": ["sin", 0.55, -10.0],
	"announcer": ["sq", 0.9, -15.0], "narrator": ["sin", 1.0, -20.0],
}

var sounds := {}
var players: Array[AudioStreamPlayer] = []
var music_a: AudioStreamPlayer
var music_b: AudioStreamPlayer
var current_song := ""
var _music_tween: Tween
var _rng := RandomNumberGenerator.new()
var muted_music := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 14:
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		players.append(p)
	music_a = AudioStreamPlayer.new()
	music_b = AudioStreamPlayer.new()
	for m in [music_a, music_b]:
		m.volume_db = -60.0
		add_child(m)
	muted_music = OS.get_environment("PK_MUTE") != ""


func play(name: String, pitch: float = 1.0, vol_db: float = -6.0) -> void:
	if not sounds.has(name):
		sounds[name] = _wav(_make(name), false)
	var p: AudioStreamPlayer = players[0]
	for cand in players:
		if not cand.playing:
			p = cand
			break
	p.stream = sounds[name]
	p.pitch_scale = pitch
	p.volume_db = vol_db
	p.play()


func voice(kind: String, variance: int = 0) -> void:
	var v: Array = VOICES.get(kind, VOICES.narrator)
	var key := "v_" + str(v[0])
	if not sounds.has(key):
		sounds[key] = _wav(_tone(520, 520, 0.03, v[0], 0.3), false)
	var pitch: float = v[1] * (1.0 + (variance % 3) * 0.04)
	play_stream(sounds[key], pitch, v[2])


func play_stream(stream: AudioStream, pitch: float, vol_db: float) -> void:
	var p: AudioStreamPlayer = players[0]
	for cand in players:
		if not cand.playing:
			p = cand
			break
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = vol_db
	p.play()


# ------------------------------------------------------------------ music ---

func music(name: String, fade: float = 1.0, vol: float = MUSIC_DB) -> void:
	if name == current_song:
		return
	current_song = name
	if _music_tween:
		_music_tween.kill()
	var old := music_a if music_a.playing else (music_b if music_b.playing else null)
	var new_p := music_b if old == music_a else music_a
	if old:
		_music_tween = create_tween()
		_music_tween.tween_property(old, "volume_db", -60.0, fade)
		_music_tween.tween_callback(old.stop)
	if name == "" or muted_music:
		return
	var path := "res://music/%s.mp3" % name
	if not ResourceLoader.exists(path):
		path = "res://music/%s.wav" % name
	if not ResourceLoader.exists(path):
		path = "res://music/%s.ogg" % name
	if not ResourceLoader.exists(path):
		push_warning("missing music " + name)
		return
	var stream = load(path)
	if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
		stream.loop = name != "mission_complete"
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
	new_p.stream = stream
	new_p.volume_db = -40.0
	new_p.play()
	var t := create_tween()
	t.tween_property(new_p, "volume_db", vol, fade * 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func music_volume(db: float, t: float = 0.5) -> void:
	for m in [music_a, music_b]:
		if m.playing:
			create_tween().tween_property(m, "volume_db", db, t)


func stop_music(fade: float = 1.0) -> void:
	music("", fade)


# ------------------------------------------------------------- synthesis ---

func _make(name: String) -> PackedFloat32Array:
	match name:
		"blip":
			return _tone(880, 880, 0.035, "sq", 0.25)
		"confirm":
			return _cat([_tone(660, 660, 0.04, "sq", 0.25), _tone(990, 990, 0.07, "sq", 0.25)])
		"cancel":
			return _cat([_tone(520, 520, 0.04, "sq", 0.2), _tone(330, 330, 0.07, "sq", 0.2)])
		"miss":
			return _tone(500, 400, 0.1, "tri", 0.2)
		"shoot":
			return _mix([_tone(1500, 520, 0.09, "sq", 0.16), _noise(0.06, 0.18, 0.9)])
		"block":
			return _mix([_tone(980, 980, 0.16, "tri", 0.3), _tone(1470, 1460, 0.2, "tri", 0.18), _noise(0.07, 0.35, 0.95)])
		"hurt":
			return _mix([_noise(0.25, 0.6, 0.4), _tone(220, 50, 0.3, "sq", 0.3)])
		"enemy_hit":
			return _mix([_tone(700, 260, 0.07, "sq", 0.2), _noise(0.05, 0.3, 0.7)])
		"enemy_die":
			return _mix([_noise(0.3, 0.55, 0.3), _tone(320, 50, 0.3, "sin", 0.6)])
		"explode":
			return _mix([_noise(0.8, 0.75, 0.08), _tone(110, 28, 0.7, "sin", 0.8)])
		"tell":
			return _cat([_tone(1320, 1320, 0.05, "sq", 0.18), _tone(0, 0, 0.03, "sin", 0.0), _tone(1320, 1320, 0.05, "sq", 0.18)])
		"enemy_shoot":
			return _mix([_tone(400, 900, 0.12, "sq", 0.12), _noise(0.08, 0.2, 0.6)])
		"portal":
			return _tone(300, 1600, 0.18, "tri", 0.18)
		"warp":
			return _mix([_noise(1.6, 0.45, 0.25, true, true), _tone(90, 900, 1.6, "tri", 0.18, true)])
		"warp_hit":
			return _mix([_noise(0.6, 0.6, 0.6), _tone(1200, 80, 0.6, "sin", 0.5)])
		"assemble":
			return _cat([_tone(330, 330, 0.05, "sq", 0.15), _tone(440, 440, 0.05, "sq", 0.15), _tone(554, 554, 0.05, "sq", 0.15), _tone(659, 659, 0.05, "sq", 0.15)])
		"plate":
			return _mix([_tone(880, 660, 0.06, "sq", 0.15), _noise(0.04, 0.2, 0.9)])
		"sync":
			return _cat([_tone(523, 523, 0.07, "tri", 0.25), _tone(784, 784, 0.07, "tri", 0.25), _tone(1047, 1047, 0.07, "tri", 0.25), _tone(1568, 1568, 0.35, "tri", 0.22)])
		"syncdown":
			return _cat([_tone(1047, 1047, 0.08, "tri", 0.22), _tone(784, 784, 0.08, "tri", 0.22), _tone(523, 400, 0.4, "tri", 0.22)])
		"chime":
			return _mix([_tone(1320, 1320, 0.6, "sin", 0.2), _tone(1980, 1980, 0.5, "sin", 0.1)])
		"tick":
			return _tone(1800, 1800, 0.012, "sq", 0.12)
		"score":
			return _cat([_tone(988, 988, 0.04, "sq", 0.16), _tone(1319, 1319, 0.08, "sq", 0.16)])
		"combo":
			return _cat([_tone(784, 784, 0.04, "sq", 0.16), _tone(1175, 1175, 0.04, "sq", 0.16), _tone(1568, 1568, 0.09, "sq", 0.16)])
		"alarm":
			return _cat([_tone(880, 880, 0.18, "sq", 0.16), _tone(587, 587, 0.18, "sq", 0.16), _tone(880, 880, 0.18, "sq", 0.16), _tone(587, 587, 0.18, "sq", 0.16)])
		"knock":
			return _cat([_mix([_tone(140, 70, 0.08, "sin", 0.8), _noise(0.05, 0.4, 0.3)]), _tone(0, 0, 0.12, "sin", 0.0), _mix([_tone(140, 70, 0.08, "sin", 0.8), _noise(0.05, 0.4, 0.3)])])
		"paper":
			return _cat([_noise(0.08, 0.3, 0.95), _noise(0.05, 0.2, 0.9), _noise(0.1, 0.25, 0.95)])
		"door":
			return _noise(0.45, 0.35, 0.7, true, true)
		"heavy_door":
			return _mix([_noise(1.0, 0.5, 0.06), _tone(60, 45, 1.0, "sq", 0.18), _crackle(0.9, 0.15)])
		"step":
			return _mix([_tone(160, 90, 0.04, "sin", 0.4), _noise(0.03, 0.15, 0.5)])
		"gasp":
			return _noise(0.5, 0.4, 0.55, true, true)
		"beep":
			return _tone(1046, 1046, 0.07, "sq", 0.18)
		"badge":
			return _cat([_noise(0.12, 0.15, 0.6, false, true), _tone(1568, 1568, 0.2, "sin", 0.2)])
		"heartbeat":
			return _cat([_tone(70, 40, 0.1, "sin", 0.9), _tone(0, 0, 0.12, "sin", 0.0), _tone(65, 40, 0.12, "sin", 0.7)])
		"pop":
			return _tone(500, 1100, 0.07, "sq", 0.15)
		"whoosh":
			return _noise(0.3, 0.35, 0.2, true, true)
		"crowd":
			return _mix([_noise(1.2, 0.3, 0.3, false, true), _crackle(1.2, 0.2)])
		"shutdown":
			return _tone(900, 40, 1.1, "sq", 0.2)
		"thrust":
			return _mix([_noise(1.4, 0.5, 0.12, false, true), _tone(70, 110, 1.4, "sq", 0.12, true)])
		"static":
			return _noise(0.6, 0.25, 0.95)
	return _tone(440, 440, 0.05, "sq", 0.2)


func _osc(phase: float, wave: String, duty: float = 0.5) -> float:
	var f := fmod(phase, 1.0)
	match wave:
		"sq":
			return 1.0 if f < duty else -1.0
		"tri":
			return 4.0 * absf(f - 0.5) - 1.0
		"saw":
			return 2.0 * f - 1.0
	return sin(phase * TAU)


func _tone(f0: float, f1: float, dur: float, wave: String, vol: float, swell: bool = false, vibrato: bool = false) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / n
		var f := lerpf(f0, f1, t)
		if vibrato:
			f *= 1.0 + sin(i * 0.004) * 0.03
		ph += f / RATE
		var env := t if swell else minf(1.0, i / 60.0) * pow(1.0 - t, 1.4)
		out[i] = _osc(ph, wave) * vol * env
	return out


func _noise(dur: float, vol: float, bright: float, sweep: bool = false, swell: bool = false) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / n
		var k := bright * (0.2 + t * 1.6 if sweep else 1.0)
		lp += (_rng.randf_range(-1.0, 1.0) - lp) * clampf(k, 0.01, 1.0)
		var env := sin(t * PI) if swell else pow(1.0 - t, 2.0)
		out[i] = lp * vol * env
	return out


func _crackle(dur: float, vol: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var on := 0
	for i in n:
		if on <= 0 and _rng.randf() < 0.004:
			on = _rng.randi_range(40, 400)
		if on > 0:
			on -= 1
			out[i] = _rng.randf_range(-1.0, 1.0) * vol * (1.0 - float(i) / n)
	return out


func _cat(parts: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for p in parts:
		out.append_array(p)
	return out


func _mix(parts: Array) -> PackedFloat32Array:
	var n := 0
	for p in parts:
		n = maxi(n, p.size())
	var out := PackedFloat32Array()
	out.resize(n)
	for p in parts:
		for i in p.size():
			out[i] += p[i]
	return out


func _wav(s: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(s.size() * 2)
	for i in s.size():
		bytes.encode_s16(i * 2, int(clampf(tanh(s[i] * 1.2), -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = s.size()
	return w
