extends ConsoleGame
## PROTEKTOR (Starbox cartridge): the toy version of the real thing. A cartoon
## robot guards a little planet: turn with the arrows / stick, the shield arc
## in front blocks rocks and bolts, Z fires along the same line at drones,
## X sets off an Overdrive that clears the screen (three charges, one more
## every 2000 points). Three hearts; endless waves that speed up.
##
## Score: drone 100, block 50 x chain multiplier (every 5 blocks in a row adds
## x1, up to x5), bolt block 25, Overdrive kills 50. Stats for achievements:
## survive (seconds), chain (best block chain), kills.

const C := Vector2(72, 44)
const PLANET_R := 6.0
const SHIELD_R := 12.0
const SHIELD_HALF := 0.9
const TURN := 7.0

## Test hook: the bot plays it (aims the shield at rocks, shoots drones).
var auto := false

var facing := -PI / 2
var lives := 3
var od := 1
var od_next := 2000
var chain := 0
var threats: Array = []
var shots: Array = []
var sparks: Array = []
var stars: Array = []
var spawn_t := 1.2
var cool := 0.0
var hurt_t := 0.0
var flash_t := 0.0
var robot_mood := "" # "", "happy", "hurt"
var robot_t := 0.0
var intro := 1.6
var dying := -1.0
var title_l: Array = []
var mult_l: Label


func begin() -> void:
	for i in 26:
		stars.append(Vector3(randf() * W, randf() * H, randf_range(2, 9)))
	for spec in [["PROTEKTOR", 2, Color("5fd3e0")], ["STEEL THAT NEVER SLEEPS", 46, Color("ffd36b")]]:
		var l := Art.label(spec[0], spec[2])
		l.position = Vector2(floorf(W / 2.0 - Art.text_width(spec[0]) / 2.0), spec[1])
		add_child(l)
		title_l.append(l)
	mult_l = Art.label("", Color("ffd36b"))
	mult_l.position = Vector2(46, 0)
	add_child(mult_l)
	Sfx.play("chime", 1.4, -8.0)


func hud_text() -> String:
	var mult := mini(5, 1 + chain / 5)
	if mult_l:
		mult_l.text = "x%d" % mult if mult > 1 and dying < 0.0 else ""
	return "" if intro > 0.0 else "%06d" % score


func step(delta: float) -> void:
	for s in stars.size():
		var st: Vector3 = stars[s]
		st.x -= st.z * delta
		if st.x < 0:
			st.x += W
		stars[s] = st
	if intro > 0.0:
		intro -= delta
		if intro <= 0.0:
			for l in title_l:
				l.queue_free()
			title_l.clear()
		return
	if dying >= 0.0:
		dying += delta
		_tick_sparks(delta)
		if dying > 1.6:
			stats["survive"] = int(t)
			end()
		return
	_turn(delta)
	cool -= delta
	hurt_t -= delta
	flash_t -= delta
	robot_t -= delta
	if robot_t <= 0.0:
		robot_mood = ""
	var fire := pressed("accept") or (held("accept") and cool <= -0.15)
	if auto:
		fire = _auto_fire()
	if fire and cool <= 0.0:
		cool = 0.16
		shots.append({"p": C + Vector2.from_angle(facing) * (PLANET_R + 2), "v": Vector2.from_angle(facing) * 120.0})
		blip(1.6, -16.0)
	if (pressed("cancel") or (auto and _auto_overdrive())) and od > 0:
		_overdrive()
	_spawn(delta)
	_tick_threats(delta)
	_tick_shots(delta)
	_tick_sparks(delta)
	stat_max("survive", int(t - 1.6))
	if score >= od_next:
		od_next += 2000
		if od < 3:
			od += 1
			Sfx.play("chime", 1.6, -12.0)


func _turn(delta: float) -> void:
	var v := stick()
	if auto:
		v = _auto_aim()
	if v.length() > 0.35:
		var want := v.angle()
		var d := wrapf(want - facing, -PI, PI)
		facing += clampf(d, -TURN * delta, TURN * delta)
		facing = wrapf(facing, -PI, PI)


func _spawn(delta: float) -> void:
	spawn_t -= delta
	if spawn_t > 0.0:
		return
	var k := minf(1.0, t / 150.0)
	spawn_t = lerpf(1.3, 0.42, k) * randf_range(0.8, 1.2)
	var ang := randf() * TAU
	var p := C + Vector2.from_angle(ang) * 92.0
	p.y = C.y + (p.y - C.y) * 0.62
	var kind := "rock" if randf() < 0.55 else "drone"
	var spd := lerpf(13.0, 30.0, k) * randf_range(0.85, 1.15)
	threats.append({"kind": kind, "p": p, "spd": spd, "hp": 1, "fire": randf_range(1.5, 3.0) if t > 30.0 and kind == "drone" else 99.0, "a": randf() * TAU})


func _tick_threats(delta: float) -> void:
	for th in threats.duplicate():
		var to: Vector2 = C - th.p
		var dist := to.length()
		var hold: bool = th.kind == "drone" and th.fire < 90.0 and dist < 34.0
		if not hold:
			th.p += to.normalized() * th.spd * delta
		th.a += delta * 3.0
		if th.kind == "drone" and th.fire < 90.0:
			th.fire -= delta
			if th.fire <= 0.0 and dist < 60.0:
				th.fire = randf_range(1.8, 3.0)
				threats.append({"kind": "bolt", "p": th.p, "spd": 34.0, "hp": 1, "fire": 99.0, "a": 0.0})
				blip(0.7, -18.0)
		dist = (C - th.p).length()
		if dist <= SHIELD_R + 1.5 and th.kind != "drone" and _in_shield(th.p):
			_block(th)
			continue
		if dist <= PLANET_R + 1.0:
			threats.erase(th)
			_hurt()


func _in_shield(p: Vector2) -> bool:
	return absf(wrapf((p - C).angle() - facing, -PI, PI)) <= SHIELD_HALF


func _block(th: Dictionary) -> void:
	threats.erase(th)
	chain += 1
	stat_max("chain", chain)
	var mult := mini(5, 1 + chain / 5)
	score += (25 if th.kind == "bolt" else 50) * mult
	_burst(th.p, Color("9fe8ff"), 5)
	blip(1.0 + mini(chain, 12) * 0.05, -12.0)


func _tick_shots(delta: float) -> void:
	for s in shots.duplicate():
		s.p += s.v * delta
		if not Rect2(-4, -4, W + 8, H + 8).has_point(s.p):
			shots.erase(s)
			continue
		for th in threats:
			if th.kind == "drone" and (th.p as Vector2).distance_to(s.p) < 4.5:
				threats.erase(th)
				shots.erase(s)
				score += 100
				stats["kills"] = int(stats.get("kills", 0)) + 1
				_burst(th.p, Color("ff7a6b"), 8)
				Sfx.play("explode", 1.6, -14.0)
				robot_mood = "happy"
				robot_t = 0.5
				break


func _overdrive() -> void:
	od -= 1
	flash_t = 0.35
	Sfx.play("explode", 0.8, -6.0)
	for th in threats:
		score += 50
		_burst(th.p, Color("ffd36b"), 6)
	threats.clear()


func _hurt() -> void:
	chain = 0
	lives -= 1
	hurt_t = 0.6
	flash_t = 0.15
	robot_mood = "hurt"
	robot_t = 0.8
	Sfx.play("hurt", 1.3, -6.0)
	if lives <= 0:
		dying = 0.0
		threats.clear()
		shots.clear()
		_burst(C, Color("ffd36b"), 30)
		Sfx.play("explode", 0.6, -2.0)


func _burst(p: Vector2, col: Color, n: int) -> void:
	for i in n:
		sparks.append({"p": p, "v": Vector2.from_angle(randf() * TAU) * randf_range(15, 45), "life": randf_range(0.25, 0.6), "c": col})


func _tick_sparks(delta: float) -> void:
	for s in sparks.duplicate():
		s.p += s.v * delta
		s.life -= delta
		if s.life <= 0.0:
			sparks.erase(s)


# ------------------------------------------------------------------ bot ---

func _nearest(kinds: Array) -> Dictionary:
	var best := {}
	var bd := 1e9
	for th in threats:
		if kinds.has(th.kind):
			var d := (th.p as Vector2).distance_to(C)
			if d < bd:
				bd = d
				best = th
	return best


func _auto_aim() -> Vector2:
	var r := _nearest(["rock", "bolt"])
	if not r.is_empty() and (r.p as Vector2).distance_to(C) < 30.0:
		return (r.p as Vector2) - C
	var d := _nearest(["drone"])
	if not d.is_empty():
		return (d.p as Vector2) - C
	return Vector2.ZERO


func _auto_fire() -> bool:
	var d := _nearest(["drone"])
	return not d.is_empty() and absf(wrapf(((d.p as Vector2) - C).angle() - facing, -PI, PI)) < 0.2


func _auto_overdrive() -> bool:
	return threats.size() >= 9


# ---------------------------------------------------------------- draw ---

func _draw() -> void:
	for st in stars:
		draw_rect(Rect2(int(st.x), int(st.y), 1, 1), Color(0.6, 0.65, 0.9, 0.3 + st.z * 0.05))
	if flash_t > 0.0:
		draw_rect(Rect2(0, 0, W, H), Color(1, 0.95, 0.7, flash_t * 1.5))
	if intro > 0.0:
		_draw_title()
		return
	# the planet with its little robot
	var shake := Vector2(randi_range(-1, 1), randi_range(-1, 1)) if hurt_t > 0.3 else Vector2.ZERO
	if dying < 0.0:
		draw_circle(C + shake, PLANET_R, Color("3b8f6a"))
		draw_circle(C + shake + Vector2(-2, -2), 2.5, Color("62c08a"))
		_draw_robot(C + shake + Vector2(0, -PLANET_R - 4), 1)
		# shield arc and gun line
		var col := Color("9fe8ff") if hurt_t <= 0.0 or fmod(hurt_t, 0.12) < 0.06 else Color(1, 1, 1, 0.3)
		draw_arc(C, SHIELD_R, facing - SHIELD_HALF, facing + SHIELD_HALF, 10, col, 2.0, false)
		var tip := C + Vector2.from_angle(facing) * (PLANET_R + 4)
		draw_line(C + Vector2.from_angle(facing) * PLANET_R, tip, Color("ffd36b"), 1.0)
	for th in threats:
		var p: Vector2 = (th.p as Vector2).floor()
		match th.kind:
			"rock":
				draw_rect(Rect2(p - Vector2(2, 2), Vector2(5, 4)), Color("8a8496"))
				draw_rect(Rect2(p - Vector2(1, 2), Vector2(2, 1)), Color("b9b3c4"))
			"drone":
				draw_rect(Rect2(p - Vector2(2, 1), Vector2(5, 3)), Color("e0564f"))
				draw_rect(Rect2(p - Vector2(3, 0), Vector2(1, 1)) if int(th.a) % 2 == 0 else Rect2(p + Vector2(3, 0), Vector2(1, 1)), Color("ffd36b"))
				draw_rect(Rect2(p + Vector2(0, 0), Vector2(1, 1)), Color.WHITE)
			"bolt":
				draw_rect(Rect2(p, Vector2(2, 2)), Color("ff9ae0"))
	for s in shots:
		draw_rect(Rect2((s.p as Vector2).floor(), Vector2(2, 1)), Color("ffd36b"))
	for s in sparks:
		draw_rect(Rect2((s.p as Vector2).floor(), Vector2(1, 1)), s.c)
	# hearts, overdrive pips and the robot's face, along the top
	for i in 3:
		_heart(Vector2(98 + i * 8, 2), i < lives)
	for i in od:
		draw_rect(Rect2(124 + i * 6, 3, 4, 4), Color("ffd36b"))
	_draw_robot(Vector2(89, 6), 1)


func _heart(p: Vector2, full: bool) -> void:
	var c := Color("ff5a6e") if full else Color(0.3, 0.25, 0.35)
	draw_rect(Rect2(p, Vector2(2, 2)), c)
	draw_rect(Rect2(p + Vector2(3, 0), Vector2(2, 2)), c)
	draw_rect(Rect2(p + Vector2(0, 1), Vector2(5, 2)), c)
	draw_rect(Rect2(p + Vector2(1, 3), Vector2(3, 1)), c)
	draw_rect(Rect2(p + Vector2(2, 4), Vector2(1, 1)), c)


func _draw_robot(at: Vector2, k: int) -> void:
	## The cartridge's hero: a square tin robot with an antenna. Its face
	## follows the action (happy on a kill, >< when the planet is hit).
	var o := at.floor() - Vector2(3, 3) * k
	var body := Color("c9ccd8")
	draw_rect(Rect2(o, Vector2(7, 6) * k), body)
	draw_rect(Rect2(o + Vector2(0, 5) * k, Vector2(7, 1) * k), Color("8f93a6"))
	draw_rect(Rect2(o + Vector2(3, -2) * k, Vector2(1, 2) * k), Color("8f93a6"))
	draw_rect(Rect2(o + Vector2(3, -3) * k, Vector2(1, 1) * k), Color("ff5a6e") if fmod(t, 0.6) < 0.3 else Color("ffd36b"))
	var eye := Color("1a1626")
	match robot_mood:
		"happy":
			draw_rect(Rect2(o + Vector2(1, 2) * k, Vector2(2, 1) * k), eye)
			draw_rect(Rect2(o + Vector2(4, 2) * k, Vector2(2, 1) * k), eye)
			draw_rect(Rect2(o + Vector2(2, 4) * k, Vector2(3, 1) * k), Color("ff5a6e"))
		"hurt":
			draw_rect(Rect2(o + Vector2(1, 1) * k, Vector2(1, 1) * k), eye)
			draw_rect(Rect2(o + Vector2(2, 2) * k, Vector2(1, 1) * k), eye)
			draw_rect(Rect2(o + Vector2(5, 1) * k, Vector2(1, 1) * k), eye)
			draw_rect(Rect2(o + Vector2(4, 2) * k, Vector2(1, 1) * k), eye)
			draw_rect(Rect2(o + Vector2(2, 4) * k, Vector2(3, 1) * k), eye)
		_:
			draw_rect(Rect2(o + Vector2(1, 1) * k, Vector2(2, 2) * k), eye)
			draw_rect(Rect2(o + Vector2(4, 1) * k, Vector2(2, 2) * k), eye)
			draw_rect(Rect2(o + Vector2(2, 4) * k, Vector2(3, 1) * k), eye)


func _draw_title() -> void:
	_draw_robot(Vector2(72, 30 + sin(t * 6.0) * 2.0), 3)
	draw_circle(Vector2(72, 66), 9, Color("3b8f6a"))
