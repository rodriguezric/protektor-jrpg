class_name Boss
extends Threat
## A boss or mini-boss: a big, many-hit Threat that holds its ground out in
## the arena and attacks on timers, defined in data/bosses.json. Being a
## Threat, the player's bolts, beam and missiles hit it, and the mission's
## clear check (and wait_until_clear) waits for it.
##
## A definition:
##   name, mini, hp, size (logical), dist (from the planet), color [r,g,b],
##   art {shape, nodes, spikes}, score,
##   phases: [{until (hp fraction this phase lasts down to), move, open,
##             attacks: [{type, every, first, ...}]}]
## move:  {type: hold | orbit (speed_deg) | hop (every, step_deg) |
##         mirror (delay, offset_deg) | lunge (every, depth, speed)}
## open:  "always" | {type: cycle, open, closed} | {type: after_attack, sec}
##        | {type: after_block, sec}   (when shut, hits only spark off it)
## attacks:
##   volley      n shots from the boss at the planet (gap, speed)
##   arc_burst   count shots from the arena edge, centred on the boss's
##               angle + offset_deg, spread over width_deg, all at once
##   spin_stream one shot every gap from an edge angle that turns at
##               deg_per_sec, for duration
##   adds        spawn enemy_type at the boss's angle + each of degrees[]
##   on_rotate   a shot from the boss each time the player turns (cooldown)
## Every attack can carry tell (seconds of warning flash before it fires).

signal phase_changed(index: int)

var boss_id := ""
var def := {}
var is_mini := false
var title := ""
var phases: Array = []
var phase := -1
var angle := 0.0
var dist := 170.0
var home_dist := 170.0
var open := true
var _open_t := 0.0
var _cycle_t := 0.0
var _timers: Array = []
var _hist: Array = []
var _last_facing := Vector2.UP
var _rotate_cd := 0.0
var _enter_t := 0.0
var _invuln_t := 0.0
var _tell_t := 0.0
var _hop_t := 0.0
var _lunge_t := 0.0
var _lunging := 0.0
var _streams: Array = []
var _shut_spark_t := 0.0
const ENTER_SEC := 1.6


static func defs() -> Dictionary:
	if Engine.has_meta("pk_bosses"):
		return Engine.get_meta("pk_bosses")
	var f := FileAccess.open("res://data/bosses.json", FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text()) if f else {}
	Engine.set_meta("pk_bosses", d if d is Dictionary else {})
	return Engine.get_meta("pk_bosses")


func setup_boss(id: String, deg: float) -> void:
	boss_id = id
	def = defs().get(id, {})
	is_mini = bool(def.get("mini", false))
	title = str(def.get("name", id.replace("_", " ").to_upper()))
	max_hp = float(def.get("hp", 40.0))
	size = float(def.get("size", 90.0 if not is_mini else 60.0))
	home_dist = float(def.get("dist", 165.0))
	dist = home_dist + 220.0
	var c: Array = def.get("color", [0.8, 0.4, 0.5])
	color = Color(c[0], c[1], c[2])
	phases = def.get("phases", [{}])
	hit_stun_sec = 0.0
	contact_damage = float(def.get("contact_damage", 1.0))
	drone_type = "boss"
	angle = deg_to_rad(deg - 90.0)
	lp = m.CENTER + Vector2.from_angle(angle) * dist
	_enter_t = ENTER_SEC


func _ready() -> void:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = FLASH_SHADER
	hp = max_hp
	d = int(round(size * m.K))
	spr = Sprite2D.new()
	mat = ShaderMaterial.new()
	mat.shader = _shader
	spr.material = mat
	add_child(spr)
	_anim = randf() * 10.0
	_refresh_sprite()
	sync_pos()
	_set_phase(0)


# ------------------------------------------------------------------ tick ---

func tick(delta: float) -> void:
	if dying:
		return
	var sd: float = delta * m.speed_scale
	_anim += sd
	if _flash_t > 0.0:
		_flash_t = maxf(0.0, _flash_t - sd)
	if _enter_t > 0.0:
		# glide in from beyond the edge
		_enter_t = maxf(0.0, _enter_t - sd)
		var k := 1.0 - _enter_t / ENTER_SEC
		dist = lerpf(home_dist + 220.0, home_dist, 1.0 - pow(1.0 - k, 3.0))
		lp = m.CENTER + Vector2.from_angle(angle) * dist
		_visual_tick(sd)
		return
	_invuln_t = maxf(0.0, _invuln_t - sd)
	_tell_t = maxf(0.0, _tell_t - sd)
	_shut_spark_t = maxf(0.0, _shut_spark_t - sd)
	var ph: Dictionary = phases[phase] if phase >= 0 and phase < phases.size() else {}
	_move(ph.get("move", {}), sd)
	_update_open(ph.get("open", "always"), sd)
	_attacks(ph.get("attacks", []), sd)
	_update_streams(sd)
	_check_rotate(ph.get("attacks", []), sd)
	lp = m.CENTER + Vector2.from_angle(angle) * dist
	if _lunging > 0.0 and m.alive:
		_handle_target_contact()
	_visual_tick(sd)


func _move(mv: Dictionary, sd: float) -> void:
	match str(mv.get("type", "hold")):
		"orbit":
			angle += deg_to_rad(float(mv.get("speed_deg", 20.0))) * sd
		"hop":
			_hop_t -= sd
			if _hop_t <= 0.0:
				_hop_t = float(mv.get("every", 4.0))
				var step := deg_to_rad(float(mv.get("step_deg", 90.0)))
				_glide_to(angle + step * (1.0 if randf() < 0.5 else -1.0))
		"mirror":
			# follows where the player faced `delay` seconds ago
			_hist.push_back([m.level_t, m.facing.angle()])
			var delay := float(mv.get("delay", 0.6))
			while _hist.size() > 1 and float(_hist[1][0]) <= m.level_t - delay:
				_hist.pop_front()
			var want: float = float(_hist[0][1]) + deg_to_rad(float(mv.get("offset_deg", 0.0)))
			angle = lerp_angle(angle, want, clampf(sd * 6.0, 0.0, 1.0))
		"lunge":
			_lunge_t -= sd
			if _lunge_t <= 0.0 and _lunging <= 0.0:
				_lunge_t = float(mv.get("every", 5.0))
				_lunging = 1.0
				_tell(0.6)
		_:
			pass
	if _lunging > 0.0:
		var spd := float(mv.get("speed", 1.2))
		_lunging = maxf(0.0, _lunging - sd * spd * 0.5)
		# out to the planet's edge and back, shaped like a bump
		var k := sin((1.0 - _lunging) * PI)
		dist = lerpf(home_dist, float(mv.get("depth", m.PLAYER_RADIUS + hit_radius() - 2.0)), k)
	elif _enter_t <= 0.0:
		dist = move_toward(dist, home_dist, sd * 200.0)


func _glide_to(a: float) -> void:
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: angle = v, angle, a, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _update_open(o, sd: float) -> void:
	if o is String:
		open = o != "closed"
		return
	var od: Dictionary = o
	match str(od.get("type", "always")):
		"cycle":
			_cycle_t += sd
			var a := float(od.get("open", 3.0))
			var b := float(od.get("closed", 3.0))
			open = fmod(_cycle_t, a + b) < a
		"after_attack", "after_block":
			_open_t = maxf(0.0, _open_t - sd)
			open = _open_t > 0.0
		_:
			open = true


func _attacks(list: Array, sd: float) -> void:
	for i in list.size():
		var a: Dictionary = list[i]
		if str(a.get("type", "")) == "on_rotate":
			continue
		_timers[i] = float(_timers[i]) - sd
		if float(_timers[i]) > 0.0:
			continue
		_timers[i] = float(a.get("every", 3.0))
		var tell := float(a.get("tell", 0.0))
		if tell > 0.0:
			_tell(tell)
			get_tree().create_timer(tell / maxf(0.05, m.speed_scale), false).timeout.connect(_fire_attack.bind(a))
		else:
			_fire_attack(a)


func _check_rotate(list: Array, sd: float) -> void:
	_rotate_cd = maxf(0.0, _rotate_cd - sd)
	var turned: float = m.facing.angle_to(_last_facing)
	_last_facing = m.facing
	if absf(turned) < 0.5:
		return
	for a in list:
		if str(a.get("type", "")) == "on_rotate" and _rotate_cd <= 0.0:
			_rotate_cd = float(a.get("cooldown", 0.8))
			_fire_attack(a)


func _fire_attack(a: Dictionary) -> void:
	if dying or not is_inside_tree() or not m.alive or m.finished:
		return
	var spd := float(a.get("speed", 220.0))
	var r := float(a.get("radius", 8.0))
	var dmg := float(a.get("damage", 1.0))
	match str(a.get("type", "")):
		"volley", "on_rotate":
			var n := int(a.get("n", 1))
			var gap := float(a.get("gap", 0.18))
			for k in n:
				if k == 0:
					_shoot_from(lp, spd, r, dmg)
				else:
					get_tree().create_timer(gap * k / maxf(0.05, m.speed_scale), false).timeout.connect(func() -> void:
						if not dying and is_inside_tree() and m.alive and not m.finished:
							_shoot_from(lp, spd, r, dmg))
		"arc_burst":
			var count := int(a.get("count", 5))
			var width := deg_to_rad(float(a.get("width_deg", 120.0)))
			var mid := angle + deg_to_rad(float(a.get("offset_deg", 180.0)))
			for k in count:
				var t := 0.5 if count == 1 else float(k) / float(count - 1)
				var ang := mid - width / 2.0 + width * t
				_shoot_from(m._edge_point(Vector2.from_angle(ang), -10.0), spd, r, dmg)
		"spin_stream":
			_streams.append({"a": angle + deg_to_rad(float(a.get("offset_deg", 180.0))), "turn": deg_to_rad(float(a.get("deg_per_sec", 90.0))),
				"left": float(a.get("duration", 3.0)), "gap": float(a.get("gap", 0.3)), "t": 0.0, "spd": spd, "r": r, "dmg": dmg})
		"adds":
			for dg in a.get("degrees", [0]):
				var deg := rad_to_deg(angle) + 90.0 + float(dg)
				m._spawn({"enemy_type": str(a.get("enemy_type", "drone_basic")), "spawn_side": "degrees", "degrees": posmod(int(round(deg)), 360)})
	var o = (phases[phase] if phase >= 0 and phase < phases.size() else {}).get("open", "always")
	if o is Dictionary and str(o.get("type", "")) == "after_attack":
		_open_t = float(o.get("sec", 2.5))


func _update_streams(sd: float) -> void:
	for s in _streams.duplicate():
		s.left -= sd
		s.t -= sd
		s.a += s.turn * sd
		if s.t <= 0.0:
			s.t = s.gap
			_shoot_from(m._edge_point(Vector2.from_angle(s.a), -10.0), s.spd, s.r, s.dmg)
		if s.left <= 0.0:
			_streams.erase(s)


func _shoot_from(p: Vector2, spd: float, r: float, dmg: float) -> void:
	var dirv: Vector2 = (m.CENTER - p).normalized()
	m.spawn_enemy_shot(p, dirv, spd, dmg, r, "boss")


func _tell(t: float) -> void:
	_tell_t = maxf(_tell_t, t)
	m.on_tell(self, "boss")


func on_shot_blocked() -> void:
	## The mission tells the boss when the player blocks one of its shots.
	var o = (phases[phase] if phase >= 0 and phase < phases.size() else {}).get("open", "always")
	if o is Dictionary and str(o.get("type", "")) == "after_block":
		_open_t = float(o.get("sec", 3.0))


# ---------------------------------------------------------------- phases ---

func _set_phase(i: int) -> void:
	phase = clampi(i, 0, phases.size() - 1)
	var list: Array = phases[phase].get("attacks", [])
	_timers = []
	for a in list:
		_timers.append(float(a.get("first", a.get("every", 3.0))))
	_streams.clear()
	_open_t = 0.0
	_cycle_t = 0.0
	_hop_t = 1.5
	_lunge_t = 2.0
	if i > 0:
		_invuln_t = 1.2
		_flash_t = 0.4
	phase_changed.emit(phase)


func _phase_for_hp() -> int:
	var frac := hp / maxf(1.0, max_hp)
	for i in phases.size():
		if frac > float(phases[i].get("until", 0.0)):
			return i
	return phases.size() - 1


# --------------------------------------------------------------- contact ---

func can_be_hit() -> bool:
	return not dying and _enter_t <= 0.0


func can_take_damage() -> bool:
	return can_be_hit() and open and _invuln_t <= 0.0


func hit_radius() -> float:
	return size * 0.42


func can_be_blocked() -> bool:
	return false


func _handle_target_contact() -> void:
	if lp.distance_to(m.CENTER) <= m.PLAYER_RADIUS + hit_radius():
		m.damage_player(contact_damage, self)
		_lunging = minf(_lunging, 0.5)


func apply_damage(amount: float) -> bool:
	if not can_be_hit() or amount <= 0.0:
		return false
	if not can_take_damage():
		if _shut_spark_t <= 0.0:
			_shut_spark_t = 0.12
			m.on_boss_deflect(self)
		return false
	hp -= amount
	_flash_t = 0.12
	if hp <= 0.0:
		hp = 0.0
		die(false)
		return true
	var want := _phase_for_hp()
	if want != phase:
		_set_phase(want)
	return false


func score_value() -> int:
	return int(def.get("score", int(max_hp) * 100))


func die(was_blocked: bool) -> void:
	if dying:
		return
	dying = true
	defeated.emit(score_value(), was_blocked)
	m.on_boss_died(self)


# ---------------------------------------------------------------- visuals --

func _refresh_sprite() -> void:
	var frame := int(_anim * 6.0) % 4
	var look := posmod(int(round((m.CENTER - lp).angle() / (TAU / 8.0))), 8)
	spr.texture = Art.boss(boss_id, def.get("art", {}), color, d, look, frame, open)
	spr.scale = Vector2.ONE
	spr.modulate.a = 1.0


func _visual_tick(delta: float) -> void:
	_refresh_sprite()
	var flash := 0.0
	var fcol := Pal.WHITE
	_jitter = Vector2.ZERO
	var t := Time.get_ticks_msec() / 1000.0
	if _tell_t > 0.0:
		flash = 0.35 + 0.65 * (sin(t * TAU * 8.0) * 0.5 + 0.5)
		fcol = Pal.BLOOD
		_jitter = Vector2(randf_range(-1, 1), randf_range(-1, 1))
	if _invuln_t > 0.0:
		flash = maxf(flash, 0.6 if int(t * 16.0) % 2 == 0 else 0.0)
	if _flash_t > 0.0:
		flash = 1.0
		fcol = Pal.WHITE
		_jitter += Vector2(randf_range(-1, 1), randf_range(-1, 1))
	if _enter_t > 0.0:
		spr.modulate.a = 1.0 - _enter_t / ENTER_SEC * 0.6
	mat.set_shader_parameter("flash", flash)
	mat.set_shader_parameter("flash_color", fcol)
	sync_pos()
	_trail_t -= delta
	if _trail_t <= 0.0:
		_trail_t = 0.08
		var a := randf() * TAU
		m.fx.particle(position + Vector2.from_angle(a) * d * 0.45, Vector2.from_angle(a) * 6.0, 0.4, color.lerp(Pal.WHITE, 0.3), {"size": 2.0, "size_end": 0.5})
