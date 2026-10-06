class_name Threat
extends Node2D
## One enemy. Behaviour is a straight port of Protektor's EnemySquare and runs in
## the original 480x480 logical space (lp); the node is only its pixel-art face.

signal defeated(score_value: int, was_blocked: bool)

const SHIELD_THRESHOLD := 0.50
const FAST_SPAWN_PORTAL_SEC := 0.55
const CARDINAL_SIDES := ["north", "east", "south", "west"]
const OCTANT_SIDES := ["north", "north_east", "east", "south_east", "south", "south_west", "west", "north_west"]

const FLASH_SHADER := """
shader_type canvas_item;
uniform float flash = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	COLOR = vec4(mix(c.rgb * COLOR.rgb, flash_color.rgb, flash), c.a * COLOR.a);
}
"""
static var _shader: Shader

# --- config (same names as the original enemies.json / EnemySquare) -----
var move_speed := 100.0
var size := 22.0
var color := Color(0.95, 0.36, 0.36, 1.0)
var max_hp := 3.0
var hit_stun_sec := 0.16
var is_asteroid := false
var blockable_by_shield := false
var contact_damage := 1.0
var drone_type := "drone_basic"
var behavior_type := ""
var spawn_side := ""
var shifter_trigger_distance := 180.0
var shifter_turn_speed := 4.6
var sine_lateral_strength := 0.5
var sine_wave_speed := 5.2
var circle_shooter_hover_distance := 185.0
var circle_shooter_hold_sec := 1.2
var circle_shooter_post_shot_wait_sec := 0.75
var circle_shooter_turn_speed := 4.2
var circle_shooter_shoot_chance := 0.65
var circle_shooter_projectile_speed := 300.0
var circle_shooter_projectile_damage := 1.0
var circle_shooter_projectile_radius := 7.0
var spiral_turn_speed := 2.8
var spiral_turn_direction := 0
var spiral_trail_intensity := 1.0
var charger_approach_speed := 60.0
var charger_stop_distance := 180.0
var charger_hold_sec := 0.55
var charger_tell_sec := 0.6
var charger_flash_hz := 10.0
var charger_shake_amplitude := 4.0
var tank_move_interval_sec := 1.9
var tank_tell_sec := 0.7
var tank_flash_hz := 10.0
var tank_projectile_speed := 285.0
var tank_projectile_damage := 1.0
var tank_projectile_radius := 8.0

# --- runtime --------------------------------------------------------------
var m  # Mission
var lp := Vector2.ZERO
var hp := 0.0
var _hit_stun_left := 0.0
var _flash_t := 0.0
var dying := false
var _move_dir := Vector2.ZERO
var _spawn_intro := 0.0
var _shifter_init := false
var _shifter_shifted := false
var _shifter_phase := "approach"
var _shifter_target_angle := 0.0
var _shifter_turn_dir := 1
var _shifter_side := ""
var _sine_t := 0.0
var _sine_sign := 1.0
var _sine_init := false
var _spiral_init := false
var _spiral_sign := 1
var _charger_init := false
var _charger_state := "approach"
var _charger_left := 0.0
var _tank_init := false
var _tank_state := "approach"
var _tank_left := 0.0
var _cs_init := false
var _cs_state := "entry"
var _cs_side := ""
var _cs_target_side := ""
var _cs_target_angle := 0.0
var _cs_turn_dir := 1
var _cs_left := 0.0

# --- visuals ---------------------------------------------------------------
var spr: Sprite2D
var mat: ShaderMaterial
var d := 12
var vis_kind := "drone_basic"
var _anim := 0.0
var _rock_v := 0
var _rock_spin := 0.0
var _trail_t := 0.0
var _jitter := Vector2.ZERO


func _ready() -> void:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = FLASH_SHADER
	hp = max_hp
	vis_kind = "asteroid" if is_asteroid else drone_type
	if behavior_type == "spiral":
		vis_kind = "spiral_drone"
	d = ArtMission.sprite_size("asteroid" if is_asteroid else vis_kind, size)
	spr = Sprite2D.new()
	mat = ShaderMaterial.new()
	mat.shader = _shader
	spr.material = mat
	add_child(spr)
	_rock_v = randi() % 5
	_rock_spin = randf_range(-9.0, 9.0)
	_anim = randf() * 10.0
	if not is_asteroid and drone_type == "drone_fast":
		_spawn_intro = FAST_SPAWN_PORTAL_SEC
		Sfx.play("portal", randf_range(0.9, 1.15), -14.0)
	elif not is_asteroid:
		scale = Vector2(0.2, 0.2)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_refresh_sprite()
	sync_pos()


func sync_pos() -> void:
	position = (lp * m.K).round() + _jitter


func target() -> Vector2:
	return m.CENTER


# ------------------------------------------------------------------ tick ---

func tick(delta: float) -> void:
	if dying:
		return
	var sd: float = delta * m.speed_scale
	_anim += sd
	if _spawn_intro > 0.0:
		_spawn_intro = maxf(0.0, _spawn_intro - sd)
		if _spawn_intro <= 0.0:
			m.fx.ring(position, 2, 9, 0.25, Pal.SYNC, 1.0, 1.0)
		_refresh_sprite()
		sync_pos()
		return
	if _hit_stun_left > 0.0:
		_hit_stun_left = maxf(0.0, _hit_stun_left - sd)
	if _flash_t > 0.0:
		_flash_t = maxf(0.0, _flash_t - sd)
	if _hit_stun_left <= 0.0 and m.alive:
		_update_movement(sd)
		_handle_target_contact()
		if dying:
			return
	_visual_tick(sd)
	var area := Rect2(Vector2.ZERO, Vector2(m.L, m.L)).grow(120.0)
	if not area.has_point(lp):
		m.remove_threat(self, false)


func _update_movement(delta: float) -> void:
	match behavior_type:
		"shifter":
			_update_shifter(delta)
		"charger":
			_update_charger(delta)
		"circle_shooter":
			_update_circle_shooter(delta)
		"sine":
			_update_sine(delta)
		"spiral":
			_update_spiral(delta)
		_:
			if not is_asteroid and drone_type == "drone_tank":
				_update_tank(delta)
			else:
				_update_direct(delta)


func _update_direct(delta: float) -> void:
	var to_t := target() - lp
	if to_t.length() > 1.0:
		_move_dir = to_t.normalized()
		lp += _move_dir * move_speed * delta
	else:
		_move_dir = Vector2.ZERO


func _update_shifter(delta: float) -> void:
	if not _shifter_init:
		_shifter_init = true
		_shifter_side = _resolve_side(CARDINAL_SIDES)
	if _shifter_phase == "shift":
		var off := lp - target()
		var radius := maxf(1.0, off.length())
		var cur := off.angle()
		var remaining := wrapf(_shifter_target_angle - cur, -PI, PI)
		var step := shifter_turn_speed * delta * _shifter_turn_dir
		var prev := lp
		if absf(remaining) <= absf(step):
			cur = _shifter_target_angle
			_shifter_phase = "final_approach"
			_shifter_shifted = true
		else:
			cur += step
		lp = target() + Vector2.RIGHT.rotated(cur) * radius
		_move_dir = (lp - prev).normalized()
		return
	var to_t := target() - lp
	var dist := to_t.length()
	if not _shifter_shifted and dist <= shifter_trigger_distance:
		_shifter_phase = "shift"
		var idx := CARDINAL_SIDES.find(_shifter_side)
		var next := str(CARDINAL_SIDES[posmod(idx + (-1 if randf() < 0.5 else 1), 4)]) if idx != -1 else "east"
		var cw := str(CARDINAL_SIDES[posmod(idx + 1, 4)]) if idx != -1 else next
		_shifter_turn_dir = 1 if cw == next else -1
		_shifter_target_angle = _cardinal_angle(next)
		_shifter_side = next
		_move_dir = Vector2.ZERO
		return
	if dist <= 1.0:
		_move_dir = Vector2.ZERO
		return
	_move_dir = to_t.normalized()
	lp += _move_dir * move_speed * delta


func _update_charger(delta: float) -> void:
	if not _charger_init:
		_charger_init = true
		_charger_state = "approach"
	if _charger_state == "hold":
		_move_dir = Vector2.ZERO
		_charger_left = maxf(0.0, _charger_left - delta)
		if _charger_left <= 0.0:
			_charger_state = "tell"
			_charger_left = charger_tell_sec
			m.on_tell(self, "charger")
		return
	if _charger_state == "tell":
		_move_dir = Vector2.ZERO
		_charger_left = maxf(0.0, _charger_left - delta)
		if _charger_left <= 0.0:
			_charger_state = "charge"
			Sfx.play("whoosh", 1.4, -10.0)
		return
	var to_t := target() - lp
	var dist := to_t.length()
	if dist <= 1.0:
		_move_dir = Vector2.ZERO
		return
	if _charger_state == "approach" and dist <= charger_stop_distance:
		_charger_state = "hold"
		_charger_left = charger_hold_sec
		_move_dir = Vector2.ZERO
		return
	_move_dir = to_t.normalized()
	lp += _move_dir * (move_speed if _charger_state == "charge" else charger_approach_speed) * delta


func _update_tank(delta: float) -> void:
	if not _tank_init:
		_tank_init = true
		_tank_state = "approach"
		_tank_left = tank_move_interval_sec
	if _tank_state == "tell":
		_move_dir = Vector2.ZERO
		_tank_left = maxf(0.0, _tank_left - delta)
		if _tank_left <= 0.0:
			_fire(tank_projectile_speed, tank_projectile_damage, tank_projectile_radius, "tank")
			_tank_state = "approach"
			_tank_left = tank_move_interval_sec
		return
	_tank_left = maxf(0.0, _tank_left - delta)
	if _tank_left <= 0.0:
		_tank_state = "tell"
		_tank_left = tank_tell_sec
		_move_dir = Vector2.ZERO
		m.on_tell(self, "tank")
		return
	_update_direct(delta)


func _update_sine(delta: float) -> void:
	if not _sine_init:
		_sine_init = true
		_sine_t = randf_range(0.0, TAU)
		_sine_sign = -1.0 if randf() < 0.5 else 1.0
	var to_t := target() - lp
	if to_t.length() <= 1.0:
		_move_dir = Vector2.ZERO
		return
	var fwd := to_t.normalized()
	var lat := Vector2(-fwd.y, fwd.x) * _sine_sign
	_move_dir = (fwd + lat * sin(_sine_t) * sine_lateral_strength).normalized()
	lp += _move_dir * move_speed * delta
	_sine_t += delta * sine_wave_speed


func _update_spiral(delta: float) -> void:
	if not _spiral_init:
		_spiral_init = true
		if spiral_turn_direction == 1 or spiral_turn_direction == -1:
			_spiral_sign = spiral_turn_direction
		else:
			_spiral_sign = -1 if randf() < 0.5 else 1
	var off := lp - target()
	var radius := off.length()
	if radius <= 1.0:
		_move_dir = Vector2.ZERO
		return
	var ang := off.angle() + delta * spiral_turn_speed * _spiral_sign
	var nr := maxf(0.0, radius - move_speed * delta)
	var prev := lp
	lp = target() + Vector2.RIGHT.rotated(ang) * nr
	_move_dir = (lp - prev).normalized()


func _update_circle_shooter(delta: float) -> void:
	if not _cs_init:
		_cs_init = true
		_cs_state = "entry"
		_cs_side = _resolve_side(OCTANT_SIDES)
		_cs_target_side = _cs_side
		_cs_target_angle = _octant_angle(_cs_side)
		_cs_left = circle_shooter_hold_sec
	match _cs_state:
		"entry":
			var slot := _cs_slot(_cs_side)
			var to_s := slot - lp
			if to_s.length() <= maxf(6.0, move_speed * delta):
				lp = slot
				_move_dir = Vector2.ZERO
				_cs_state = "hold"
				_cs_left = circle_shooter_hold_sec
			else:
				_move_dir = to_s.normalized()
				lp += _move_dir * move_speed * delta
		"shift":
			var off := lp - target()
			var cur := off.angle()
			var remaining := wrapf(_cs_target_angle - cur, -PI, PI)
			var step := circle_shooter_turn_speed * delta * _cs_turn_dir
			var prev := lp
			if absf(remaining) <= absf(step):
				cur = _cs_target_angle
				_cs_side = _cs_target_side
				_cs_state = "hold"
				_cs_left = circle_shooter_hold_sec
			else:
				cur += step
			lp = target() + Vector2.RIGHT.rotated(cur) * maxf(1.0, circle_shooter_hover_distance)
			_move_dir = (lp - prev).normalized()
		"post_shot":
			_move_dir = Vector2.ZERO
			_cs_left = maxf(0.0, _cs_left - delta)
			if _cs_left <= 0.0:
				_cs_start_shift()
		_:
			lp = _cs_slot(_cs_side)
			_move_dir = Vector2.ZERO
			_cs_left = maxf(0.0, _cs_left - delta)
			if _cs_left <= 0.0:
				if randf() <= clampf(circle_shooter_shoot_chance, 0.0, 1.0):
					_fire(circle_shooter_projectile_speed, circle_shooter_projectile_damage, circle_shooter_projectile_radius, "circle")
					_cs_state = "post_shot"
					_cs_left = circle_shooter_post_shot_wait_sec
				else:
					_cs_start_shift()


func _cs_start_shift() -> void:
	_cs_state = "shift"
	var opts := []
	for s in OCTANT_SIDES:
		if s != _cs_side:
			opts.append(s)
	_cs_target_side = str(opts[randi() % opts.size()])
	var fi := OCTANT_SIDES.find(_cs_side)
	var ti := OCTANT_SIDES.find(_cs_target_side)
	_cs_turn_dir = 1 if posmod(ti - fi, 8) <= posmod(fi - ti, 8) else -1
	_cs_target_angle = _octant_angle(_cs_target_side)


func _cs_slot(side: String) -> Vector2:
	return target() + Vector2.RIGHT.rotated(_octant_angle(side)) * maxf(1.0, circle_shooter_hover_distance)


func _resolve_side(sides: Array) -> String:
	var key := spawn_side.strip_edges().to_lower()
	var alias := {"top": "north", "bottom": "south", "left": "west", "right": "east", "top_left": "north_west", "top_right": "north_east", "bottom_left": "south_west", "bottom_right": "south_east"}
	if sides.size() == 8 and alias.has(key):
		key = alias[key]
	if sides.has(key):
		return key
	var off := lp - target()
	if off.length() <= 0.001:
		return "north"
	var best := "north"
	var best_d := INF
	for s in sides:
		var a := _cardinal_angle(s) if sides.size() == 4 else _octant_angle(s)
		var dd := absf(wrapf(off.angle() - a, -PI, PI))
		if dd < best_d:
			best_d = dd
			best = s
	return best


static func _cardinal_angle(s: String) -> float:
	match s:
		"east": return 0.0
		"south": return PI * 0.5
		"west": return PI
	return -PI * 0.5


static func _octant_angle(s: String) -> float:
	match s:
		"east": return 0.0
		"south_east": return PI * 0.25
		"south": return PI * 0.5
		"south_west": return PI * 0.75
		"west": return PI
		"north_west": return -PI * 0.75
		"north": return -PI * 0.5
	return -PI * 0.25


func _fire(speed: float, dmg: float, radius: float, kind: String) -> void:
	var dirv := (target() - lp).normalized()
	if dirv.length_squared() <= 0.0001:
		dirv = Vector2.DOWN
	m.spawn_enemy_shot(lp, dirv, speed, dmg, radius, kind)


# --------------------------------------------------------------- contact ---

func can_be_hit() -> bool:
	return not dying


func hit_radius() -> float:
	return size * 0.55


func can_be_blocked() -> bool:
	return blockable_by_shield or is_asteroid


func _handle_target_contact() -> void:
	var contact: float = m.PLAYER_RADIUS + hit_radius()
	if lp.distance_to(target()) > contact:
		return
	if _is_blocked():
		m.on_block(self)
		die(true)
		return
	var did_damage: bool = m.damage_player(contact_damage, self)
	if did_damage or can_be_blocked():
		die(false)


func _is_blocked() -> bool:
	if not can_be_blocked():
		return false
	var off := lp - target()
	if off.length_squared() <= 0.0001:
		return false
	return off.normalized().dot(-m.facing) >= SHIELD_THRESHOLD


func apply_damage(amount: float) -> bool:
	if not can_be_hit() or amount <= 0.0:
		return false
	hp -= amount
	_hit_stun_left = maxf(_hit_stun_left, hit_stun_sec)
	_flash_t = 0.17
	if hp <= 0.0:
		die(false)
		return true
	return false


func score_value() -> int:
	# Asteroids carry 99 hp only so the beam can't break them; score them like 1.
	if is_asteroid and max_hp > 5.0:
		return 100
	return int(round(max_hp * 100.0))


func die(was_blocked: bool) -> void:
	if dying:
		return
	dying = true
	defeated.emit(score_value(), was_blocked)
	m.on_threat_died(self, was_blocked)


# ---------------------------------------------------------------- visuals --

func _look() -> int:
	var v := target() - lp
	if not is_asteroid and drone_type == "drone_fast" and _move_dir.length() > 0.1:
		v = _move_dir
	return posmod(int(round(v.angle() / (TAU / 8.0))), 8)


func _refresh_sprite() -> void:
	if _spawn_intro > 0.0:
		spr.texture = Art.portal(d + 8, int(_anim * 20.0) % 8)
		var k := 1.0 - _spawn_intro / FAST_SPAWN_PORTAL_SEC
		spr.scale = Vector2.ONE * lerpf(1.5, 0.9, k)
		spr.modulate.a = 0.6 + 0.4 * (1.0 if int(_anim * 18.0) % 2 == 0 else 0.0)
		return
	spr.scale = Vector2.ONE
	spr.modulate.a = 1.0
	if is_asteroid:
		spr.texture = Art.asteroid(d, _rock_v, posmod(int(_anim * _rock_spin), 16))
	else:
		spr.texture = Art.drone(vis_kind, d, _look(), int(_anim * 5.0) % 2)


func _visual_tick(delta: float) -> void:
	_refresh_sprite()
	var flash := 0.0
	var fcol := Pal.WHITE
	_jitter = Vector2.ZERO
	var t := Time.get_ticks_msec() / 1000.0
	if behavior_type == "charger":
		if _charger_state == "hold":
			spr.modulate = Color(0.75, 0.75, 0.8)
		elif _charger_state == "tell":
			var k := 1.0 - _charger_left / maxf(charger_tell_sec, 0.001)
			flash = lerpf(0.35, 1.0, k) * (sin(t * TAU * charger_flash_hz) * 0.5 + 0.5)
			fcol = Pal.BLOOD
			_jitter = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * (charger_shake_amplitude / 4.0)
		else:
			spr.modulate = Color.WHITE
	if not is_asteroid and drone_type == "drone_tank" and behavior_type == "" and _tank_state == "tell":
		var k := 1.0 - _tank_left / maxf(tank_tell_sec, 0.001)
		flash = lerpf(0.35, 1.0, k) * (sin(t * TAU * tank_flash_hz) * 0.5 + 0.5)
		fcol = Pal.WHITE
	if _flash_t > 0.0:
		flash = 1.0
		fcol = Pal.WHITE
		_jitter += Vector2(randf_range(-1, 1), randf_range(-1, 1))
	mat.set_shader_parameter("flash", flash)
	mat.set_shader_parameter("flash_color", fcol)
	sync_pos()
	# trails
	_trail_t -= delta
	if _trail_t <= 0.0:
		if is_asteroid:
			_trail_t = 0.03
			var back := -(target() - lp).normalized()
			var cols := [Pal.EMBER, Pal.ROSE.lerp(Pal.VOID, 0.3), Pal.SYNC]
			m.fx.particle(position + back * d * 0.35 + Vector2(randf_range(-1, 1), randf_range(-1, 1)), back * randf_range(8, 20), randf_range(0.18, 0.35), cols[randi() % 3], {"size": 2.0, "size_end": 0.5})
		elif behavior_type == "spiral":
			_trail_t = 0.06
			m.fx.particle(position, Vector2.ZERO, 0.4 * spiral_trail_intensity, Pal.SYNC.lerp(Pal.SKY, 0.5), {"color2": Color(Pal.SKY, 0.0)})
		elif behavior_type == "charger" and _charger_state == "charge":
			_trail_t = 0.02
			m.fx.particle(position, Vector2.ZERO, 0.2, Pal.BLOOD, {"size": 3.0, "size_end": 1.0})
		elif drone_type == "drone_fast":
			_trail_t = 0.04
			m.fx.particle(position - _move_dir * d * 0.4, Vector2.ZERO, 0.2, Pal.SYNC.lerp(Pal.SKY, 0.4), {"size": 2.0, "size_end": 0.5})
		else:
			_trail_t = 0.2


func pixel_image() -> Image:
	return spr.texture.get_image() if spr.texture else null
