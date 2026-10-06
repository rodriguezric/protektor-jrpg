class_name Mission
extends Control
## Reflex combat. Loads one of Protektor's mission JSONs and runs it exactly like
## MissionDriver did (timeline events, spawner geometry, shield/cannon rules,
## triggers), in the original 480x480 logical arena. Everything you see is new:
## a pixel planet in a 176px window, side panels, and a lot of juice.

const L := 480.0
const K := 176.0 / 480.0
const CENTER := Vector2(240, 240)
const ARENA := Rect2(72, 2, 176, 176)
const PLAYER_CORE := 16.0
const SHIELD_T := 7.0
const PLAYER_RADIUS := 19.5
const BLOCK_RADIUS := 23.0
const CANNON_LEN := 18.0
const MAX_BULLETS := 3
## Weapons: shots in flight, speed, hit radius, damage, cooldown multiplier.
const WEAPON_STATS := {
	"basic": {"max": 3, "speed": 560.0, "r": 5.0, "dmg": 1.0, "cd": 1.0},
	"wave": {"max": 3, "speed": 470.0, "r": 14.0, "dmg": 1.0, "cd": 1.15},
	"beam": {"max": 3, "speed": 820.0, "r": 4.0, "dmg": 3.0, "cd": 1.35},
	"auto": {"max": 5, "speed": 600.0, "r": 5.0, "dmg": 1.0, "cd": 0.6},
}
const EXT_SHIELD_REACH := 14.0
const MISSILE_INTERVAL := 2.6
const MISSILE_SPEED := 300.0
const MISSILE_TURN := 6.0
const MISSILE_LIFE := 3.0
const BULLET_SPEED := 560.0
const BULLET_R := 5.0
const BULLET_DMG := 1.0
const MAX_HP := 5.0
const HITSTUN_SEC := 0.18
const HITSTUN_SCALE := 0.28
const SPAWN_MARGIN := 42.0
const FAST_INSET := 68.0
const ASSIST_CONE := 0.42

var level_id := ""
var arcade := false
var play_intro := true
var data := {}
var header := {}
var planet_key := "green_planet"
var planet_type := "terra_virex"
var level_index := 1
var timeline: Array = []
var triggers: Array = []
var t_index := 0
var level_t := 0.0
var last_spawn_t := 1.0
var running := false
var alive := true
var finished := false
var paused := false
var hp := MAX_HP
var red_hp := 0.0
var training := false
var lo := {}
var wstat := {}
var fire_cd_base := 0.14
var block_reach := PLAYER_RADIUS
var shot_block_r := BLOCK_RADIUS
var missiles: Array = []
var _missile_t := 1.5
var _fire_buffer := 0.0
var red_cells: Array = []
var credits_earned := 0
var facing := Vector2.UP
var speed_scale := 1.0
var _hitstun_until := 0.0
var freeze := 0.0
var threats: Array = []
var shots: Array = []
var bolts: Array = []
var fired_triggers := {}
var score := 0
var shown_score := 0.0
var defeated_n := 0
var blocks := 0
var streak := 0
var best_streak := 0
var hits_taken := 0
var _aim_mode := "key"
var _fire_cd := 0.0
var _result := {}
var _done_sig := false
var _shake_t := 0.0
var _shake_amt := 0.0
var _mood := ""
var _mood_t := 0.0
var _heart_t := 0.0
var _chatter_t := 18.0
var _skip := false
var _sync0 := 0
var _victory_msg := ""
var cannon_k := 0.0
var shield_k := 0.0
var _recoil := 0.0
var _shield_pulse := 0.0
var _planet_frame := 0.0

# nodes
var arena: Control
var space: TextureRect
var stars: StarLayer
var danger: ColorRect
var vignette: ColorRect
var threat_root: Node2D
var shot_layer: ShotLayer
var core: PlayerCore
var fx: Fx
var hud_fx: Fx
var popups: Node2D
var overlay: Control
var frame_box: NinePatchRect
var left_panel: Control
var right_panel: Control
var portrait: TextureRect
var comms_name: Label
var comms_text: Label
var score_label: Label
var streak_label: Label
var cells: Array = []
var sync_label: Label
var sync_bar: ColorRect
var prog_bar: ColorRect
var _comms_queue: Array = []
var _comms_busy := false

signal mission_done


func setup(p_level: String, p_arcade: bool, p_intro: bool, p_data: Dictionary = {}, p_training: bool = false) -> void:
	level_id = p_level
	arcade = p_arcade
	play_intro = p_intro and not p_training
	training = p_training
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	lo = Game.loadout()
	wstat = WEAPON_STATS.get(lo.weapon, WEAPON_STATS.basic)
	fire_cd_base = Data.FIRE_COOLDOWN[clampi(int(lo.cooldown), 0, 3)] * float(wstat.cd)
	red_hp = float(lo.armor)
	if lo.ext_shield:
		block_reach = PLAYER_RADIUS + EXT_SHIELD_REACH
		shot_block_r = BLOCK_RADIUS + EXT_SHIELD_REACH
	data = p_data
	_load()
	_build()
	if play_intro:
		_intro_prep()


# ------------------------------------------------------------------ load ---

func _load() -> void:
	if data.is_empty():
		var f := FileAccess.open("res://data/missions/%s.json" % level_id, FileAccess.READ)
		data = JSON.parse_string(f.get_as_text()) if f else {}
	header = data.get("header", {})
	planet_type = str(data.get("planet_type", level_id.split("_level_")[0]))
	level_index = int(data.get("level_index", 1))
	planet_key = str(header.get("planet_texture", Data.PLANET_INFO.get(planet_type, {}).get("tex", "green_planet")))
	for e in data.get("events", []):
		if typeof(e) != TYPE_DICTIONARY:
			continue
		if e.has("trigger"):
			triggers.append(e)
		else:
			timeline.append(e)
	timeline.sort_custom(func(a, b): return float(a.get("time", 0.0)) < float(b.get("time", 0.0)))
	for e in timeline:
		if str(e.get("type", "")) == "spawn_enemy":
			last_spawn_t = maxf(last_spawn_t, float(e.get("time", 0.0)))


static func enemy_configs() -> Dictionary:
	if Engine.has_meta("pk_enemies"):
		return Engine.get_meta("pk_enemies")
	var f := FileAccess.open("res://data/enemies.json", FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text()) if f else {}
	Engine.set_meta("pk_enemies", d)
	return d


# ----------------------------------------------------------------- build ---

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Pal.INK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# arena
	arena = Control.new()
	arena.position = ARENA.position
	arena.size = ARENA.size
	arena.clip_contents = true
	add_child(arena)
	space = TextureRect.new()
	space.texture = Art.space(176, 176, planet_key)
	arena.add_child(space)
	stars = StarLayer.new()
	stars.m = self
	arena.add_child(stars)
	danger = ColorRect.new()
	danger.size = ARENA.size
	danger.color = Color(Pal.BLOOD, 0.0)
	arena.add_child(danger)
	threat_root = Node2D.new()
	arena.add_child(threat_root)
	shot_layer = ShotLayer.new()
	shot_layer.m = self
	arena.add_child(shot_layer)
	core = PlayerCore.new()
	core.m = self
	core.position = (CENTER * K).round()
	arena.add_child(core)
	fx = Fx.new()
	arena.add_child(fx)
	popups = Node2D.new()
	arena.add_child(popups)
	vignette = ColorRect.new()
	vignette.size = ARENA.size
	vignette.color = Color(Pal.BLOOD, 0.0)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arena.add_child(vignette)
	overlay = Control.new()
	overlay.size = ARENA.size
	arena.add_child(overlay)
	frame_box = Art.make_box("sys_box")
	frame_box.draw_center = false
	frame_box.position = ARENA.position - Vector2(2, 2)
	frame_box.size = ARENA.size + Vector2(4, 4)
	add_child(frame_box)
	_build_left()
	_build_right()
	hud_fx = Fx.new()
	add_child(hud_fx)


func _build_left() -> void:
	left_panel = Control.new()
	add_child(left_panel)
	var pbox := Art.make_box("bar_box")
	pbox.position = Vector2(0, 2)
	pbox.size = Vector2(70, 70)
	left_panel.add_child(pbox)
	portrait = TextureRect.new()
	portrait.position = Vector2(11, 11)
	pbox.add_child(portrait)
	var nm := Art.label(Game.player_name if not arcade else "PILOT", Pal.SYNC)
	nm.position = Vector2(4, 72)
	left_panel.add_child(nm)
	var cbox := Art.make_box("sys_box")
	cbox.position = Vector2(2, 84)
	cbox.size = Vector2(68, 92)
	left_panel.add_child(cbox)
	var hd := Art.label("COMMS", Pal.TEXT_DIM)
	hd.position = Vector2(5, 3)
	cbox.add_child(hd)
	comms_name = Art.label("", Pal.SYNC)
	comms_name.position = Vector2(5, 15)
	cbox.add_child(comms_name)
	comms_text = Label.new()
	comms_text.position = Vector2(5, 26)
	comms_text.size = Vector2(60, 62)
	comms_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	comms_text.add_theme_color_override("font_color", Pal.TEXT)
	cbox.add_child(comms_text)
	_set_mood("closed")


func _build_right() -> void:
	right_panel = Control.new()
	right_panel.position = Vector2(250, 0)
	add_child(right_panel)
	var info: Dictionary = Data.PLANET_INFO.get(planet_type, {})
	var pb := Art.make_box("bar_box")
	pb.position = Vector2(0, 3)
	pb.size = Vector2(68, 34)
	right_panel.add_child(pb)
	var ps := TextureRect.new()
	ps.texture = Art.planet(planet_key, 14, 0)
	ps.position = Vector2(3, 7)
	ps.set_meta("spin", true)
	pb.add_child(ps)
	var nm := Label.new()
	nm.text = "\n".join(str(header.get("planet_name", info.get("name", planet_type))).to_upper().split(" "))
	nm.position = Vector2(20, 1)
	nm.add_theme_constant_override("line_spacing", -2)
	nm.add_theme_color_override("font_color", Pal.TEXT)
	pb.add_child(nm)
	var lv := Art.label("LEVEL %02d" % level_index, Pal.SYNC)
	lv.position = Vector2(4, 22)
	pb.add_child(lv)
	var ib := Art.make_box("box")
	ib.position = Vector2(0, 40)
	ib.size = Vector2(68, 30)
	right_panel.add_child(ib)
	var il := Art.label("INTEGRITY", Pal.TEXT_DIM)
	il.position = Vector2(5, 3)
	ib.add_child(il)
	for i in int(MAX_HP):
		var c := TextureRect.new()
		c.texture = Art.ui("cell_on")
		c.position = Vector2(5 + i * 12, 15)
		ib.add_child(c)
		cells.append(c)
	# Red integrity sits on top of the normal cells and is spent first.
	for i in int(red_hp):
		var c := TextureRect.new()
		c.texture = Art.ui("cell_red")
		c.position = Vector2(5 + i * 12, 15)
		ib.add_child(c)
		red_cells.append(c)
	var sb := Art.make_box("box")
	sb.position = Vector2(0, 73)
	sb.size = Vector2(68, 44)
	right_panel.add_child(sb)
	var sl := Art.label("SCORE", Pal.TEXT_DIM)
	sl.position = Vector2(5, 3)
	sb.add_child(sl)
	score_label = Art.label("0", Pal.LEMON)
	score_label.position = Vector2(5, 14)
	sb.add_child(score_label)
	streak_label = Art.label("", Pal.SYNC)
	streak_label.position = Vector2(5, 27)
	sb.add_child(streak_label)
	var yb := Art.make_box("sys_box")
	yb.position = Vector2(0, 120)
	yb.size = Vector2(68, 56)
	right_panel.add_child(yb)
	var yl := Art.label("SYNC", Pal.TEXT_DIM)
	yl.position = Vector2(5, 3)
	yb.add_child(yl)
	sync_label = Art.label("", Pal.SYNC)
	sync_label.position = Vector2(34, 3)
	yb.add_child(sync_label)
	var sbb := ColorRect.new()
	sbb.color = Pal.INK
	sbb.position = Vector2(5, 15)
	sbb.size = Vector2(58, 5)
	yb.add_child(sbb)
	sync_bar = ColorRect.new()
	sync_bar.color = Pal.SYNC
	sync_bar.position = Vector2(6, 16)
	sync_bar.size = Vector2(0, 3)
	yb.add_child(sync_bar)
	var wl := Art.label("THREAT WAVES", Pal.TEXT_DIM)
	wl.position = Vector2(5, 25)
	yb.add_child(wl)
	var pbb := ColorRect.new()
	pbb.color = Pal.INK
	pbb.position = Vector2(5, 37)
	pbb.size = Vector2(58, 5)
	yb.add_child(pbb)
	prog_bar = ColorRect.new()
	prog_bar.color = Pal.BLOOD.lerp(Pal.ORANGE, 0.4)
	prog_bar.position = Vector2(6, 38)
	prog_bar.size = Vector2(0, 3)
	yb.add_child(prog_bar)
	var hint := Art.label("Esc pause", Pal.TEXT_DIM)
	hint.position = Vector2(5, 44)
	yb.add_child(hint)
	_sync0 = Game.sync_percent()
	_update_sync()


# ------------------------------------------------------------------- run ---

func run() -> Dictionary:
	var music_path := str(header.get("music", {}).get("file_path", ""))
	if play_intro:
		await _intro()
	else:
		shield_k = 1.0
		cannon_k = 1.0
		if training:
			await _sim_banner()
	if music_path != "":
		Sfx.music(music_path.get_file().get_basename(), 0.6)
	running = true
	_set_mood("")
	if not _done_sig:
		await mission_done
	return _result


## Intro pacing, from Protektor's MissionDriver.
const INTRO_BLACK_HOLD_SEC := 0.08
const INTRO_STAR_WARP_SEC := 3.0
const INTRO_WARP_TO_PLANET_SEC := 4.0
const INTRO_NAME_FLASH_IN_SEC := 0.05
const INTRO_NAME_FLASH_OUT_SEC := 0.15
const INTRO_NAME_FADE_IN_SEC := 0.51
const INTRO_NAME_HOLD_SEC := 2.0
const INTRO_NAME_FADE_OUT_SEC := 1.0
const INTRO_PLANET_ZOOM_OUT_SEC := 2.4
const INTRO_COMPONENT_BUILD_SEC := 1.15
const INTRO_HUD_FADE_SEC := 1.2
const INTRO_PLANET_START_SCALE := 0.16
const INTRO_PLANET_SCREEN_FILL := 0.70
const INTRO_ZOOM_LOOP_FADE_OUT_SEC := 12.0

var _zoom_loop: AudioStreamPlayer
var _intro_black: ColorRect


func _intro_prep() -> void:
	## Applied in setup, before the first frame is drawn, so the finished arena
	## never shows through before the warp.
	core.modulate.a = 0.0
	core.planet_scale = INTRO_PLANET_START_SCALE
	left_panel.modulate.a = 0.0
	right_panel.modulate.a = 0.0
	frame_box.modulate.a = 0.0
	stars.warp = 0.0
	_intro_black = ColorRect.new()
	_intro_black.size = ARENA.size
	_intro_black.color = Color(0, 0, 0, 1)
	overlay.add_child(_intro_black)
	# The zoom loop starts the moment the mission loads, like the original.
	_zoom_loop = AudioStreamPlayer.new()
	var stream = load("res://music/zooming_loop2.mp3")
	if stream:
		stream = stream.duplicate()
		stream.loop = true
		_zoom_loop.stream = stream
		_zoom_loop.volume_db = 0.0 if not Sfx.muted_music else -80.0
		add_child(_zoom_loop)
		_zoom_loop.play()


func _watch_skip() -> void:
	## Z fast-forwards the intro.
	while _intro_running:
		if Input.is_action_just_pressed("accept"):
			_skip = true
			Engine.time_scale = 6.0
		await get_tree().process_frame
	Engine.time_scale = 1.0


var _intro_running := false


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _intro() -> void:
	_intro_running = true
	_watch_skip()
	Sfx.stop_music(0.8)
	var max_scale := ARENA.size.x * INTRO_PLANET_SCREEN_FILL / 16.0
	await get_tree().create_timer(INTRO_BLACK_HOLD_SEC).timeout
	# 1. Star warp: the streaks accelerate while the black lifts (the zoom
	# loop is the only sound here).
	var t1 := create_tween().set_parallel(true)
	t1.tween_property(stars, "warp", 0.68, INTRO_STAR_WARP_SEC).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t1.tween_property(_intro_black, "color:a", 0.0, INTRO_STAR_WARP_SEC * 0.68)
	t1.tween_property(space, "modulate", Color(0.55, 0.55, 0.65), INTRO_STAR_WARP_SEC)
	await t1.finished
	# 2. Warp to the planet: it rushes up out of the tunnel to fill the view.
	var t2 := create_tween().set_parallel(true)
	t2.tween_property(stars, "warp", 1.0, INTRO_WARP_TO_PLANET_SEC).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t2.tween_property(core, "planet_scale", max_scale, INTRO_WARP_TO_PLANET_SEC).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t2.tween_property(core, "modulate:a", 1.0, INTRO_WARP_TO_PLANET_SEC * 0.78).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await t2.finished
	stars.warp = 0.0
	space.modulate = Color.WHITE
	# 3. The planet's name, after a white flash; the zoom loop begins its long fade.
	if _zoom_loop and _zoom_loop.playing:
		var zf := _zoom_loop.create_tween()
		zf.tween_property(_zoom_loop, "volume_db", -60.0, INTRO_ZOOM_LOOP_FADE_OUT_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		zf.tween_callback(_zoom_loop.stop)
	var flash := ColorRect.new()
	flash.size = ARENA.size
	flash.color = Color(1, 1, 1, 0)
	overlay.add_child(flash)
	var tf := create_tween()
	tf.tween_property(flash, "color:a", 1.0, INTRO_NAME_FLASH_IN_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tf.tween_property(flash, "color:a", 0.0, INTRO_NAME_FLASH_OUT_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tf.finished
	flash.queue_free()
	var name_l := Art.shadow_label(str(header.get("planet_name", planet_type)).to_upper(), Pal.TEXT, 2)
	overlay.add_child(name_l)
	name_l.position = Vector2(88 - Art.text_width(name_l.text, 2) / 2.0, 14)
	name_l.modulate.a = 0.0
	var sub := Art.shadow_label("DEFENSE LEVEL %02d" % level_index, Pal.SYNC)
	overlay.add_child(sub)
	sub.position = Vector2(88 - Art.text_width(sub.text) / 2.0, 36)
	sub.modulate.a = 0.0
	var t3 := create_tween().set_parallel(true)
	t3.tween_property(name_l, "modulate:a", 1.0, INTRO_NAME_FADE_IN_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t3.tween_property(sub, "modulate:a", 1.0, INTRO_NAME_FADE_IN_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await t3.finished
	await get_tree().create_timer(INTRO_NAME_HOLD_SEC).timeout
	var t4 := create_tween().set_parallel(true)
	t4.tween_property(name_l, "modulate:a", 0.0, INTRO_NAME_FADE_OUT_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t4.tween_property(sub, "modulate:a", 0.0, INTRO_NAME_FADE_OUT_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await t4.finished
	name_l.queue_free()
	sub.queue_free()
	# 4. Pull back out to defense distance.
	var t5 := create_tween()
	t5.tween_property(core, "planet_scale", 1.0, INTRO_PLANET_ZOOM_OUT_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await t5.finished
	# 5. The Protektor forms: the shield grows in, then the cannon extends.
	var shield_up := AudioStreamPlayer.new()
	shield_up.stream = load("res://sfx/shield_up.wav")
	add_child(shield_up)
	shield_up.play()
	var t6 := create_tween()
	t6.tween_method(func(p: float) -> void:
		shield_k = clampf(p * 1.2, 0.0, 1.0)
		cannon_k = clampf((p - 0.3) / 0.7, 0.0, 1.0), 0.0, 1.0, INTRO_COMPONENT_BUILD_SEC).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await t6.finished
	shield_up.stop()
	shield_up.queue_free()
	shield_k = 1.0
	cannon_k = 1.0
	fx.ring(core.position, 4, 30, 0.5, Pal.SYNC, 1.0, 1.0)
	# 6. The HUD columns fade in, then the level begins.
	_comms("SYSTEM", "Planetary defense active. Orientation control enabled.", 40.0, 1.6)
	var t7 := create_tween().set_parallel(true)
	t7.tween_property(left_panel, "modulate:a", 1.0, INTRO_HUD_FADE_SEC)
	t7.tween_property(right_panel, "modulate:a", 1.0, INTRO_HUD_FADE_SEC)
	t7.tween_property(frame_box, "modulate:a", 1.0, INTRO_HUD_FADE_SEC)
	await t7.finished
	_intro_black.queue_free()
	_intro_running = false
	Engine.time_scale = 1.0


func _sim_banner() -> void:
	var t := Art.shadow_label("SIMULATION", Pal.SYNC, 2)
	t.position = Vector2(88 - Art.text_width(t.text, 2) / 2.0, 60)
	overlay.add_child(t)
	var sub_l := Art.shadow_label(str(header.get("planet_name", "")), Pal.TEXT)
	sub_l.position = Vector2(88 - Art.text_width(sub_l.text) / 2.0, 84)
	overlay.add_child(sub_l)
	Sfx.play("beep", 0.8, -6.0)
	await get_tree().create_timer(1.4).timeout
	var tw := create_tween().set_parallel(true)
	tw.tween_property(t, "modulate:a", 0.0, 0.4)
	tw.tween_property(sub_l, "modulate:a", 0.0, 0.4)
	await tw.finished
	t.queue_free()
	sub_l.queue_free()


func _arena_flash(c: Color, t: float) -> void:
	var r := ColorRect.new()
	r.size = ARENA.size
	r.color = Color(c, 0.9)
	overlay.add_child(r)
	var tw := create_tween()
	tw.tween_property(r, "color:a", 0.0, t)
	tw.tween_callback(r.queue_free)
	await tw.finished


# ------------------------------------------------------------------ loop ---

func _process(delta: float) -> void:
	_planet_frame += delta * 5.0
	_update_shake(delta)
	_update_hud(delta)
	if paused:
		return
	if running and alive and not finished and Input.is_action_just_pressed("cancel"):
		_pause_menu()
		return
	if alive and not finished:
		_handle_aim()
	if freeze > 0.0:
		freeze -= delta
		return
	_recoil = maxf(0.0, _recoil - delta * 40.0)
	_shield_pulse = maxf(0.0, _shield_pulse - delta * 4.0)
	if speed_scale < 1.0 and Time.get_ticks_msec() / 1000.0 >= _hitstun_until and alive:
		speed_scale = 1.0
	if not running:
		return
	_handle_fire(delta)
	level_t += delta
	while t_index < timeline.size() and float(timeline[t_index].get("time", 0.0)) <= level_t:
		var e: Dictionary = timeline[t_index]
		t_index += 1
		_run_event(e)
	for th in threats.duplicate():
		if is_instance_valid(th):
			th.tick(delta)
	_update_shots(delta)
	_update_bolts(delta)
	_update_missiles(delta)
	_chatter(delta)
	if hp <= 1.0 and alive:
		_heart_t -= delta
		if _heart_t <= 0.0:
			_heart_t = 0.9
			Sfx.play("heartbeat", 1.0, -6.0)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and (event as InputEventMouseMotion).relative.length() > 0.5:
		_aim_mode = "mouse"
	elif event is InputEventKey or event is InputEventJoypadButton:
		if event.is_action("up") or event.is_action("down") or event.is_action("left") or event.is_action("right"):
			_aim_mode = "key"
	elif event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.35:
		_aim_mode = "stick"
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_aim_mode = "mouse"
		_press_fire()


func _handle_aim() -> void:
	var v := Vector2.ZERO
	match _aim_mode:
		"mouse":
			var mp := get_viewport().get_mouse_position()
			v = mp - (ARENA.position + core.position)
		_:
			v = Input.get_vector("left", "right", "up", "down")
	if v.length() > 0.3:
		facing = v.normalized()


func _handle_fire(delta: float) -> void:
	_fire_cd -= delta
	_fire_buffer -= delta
	if Input.is_action_just_pressed("accept"):
		_press_fire()
	elif _fire_buffer > 0.0 and _fire_cd <= 0.0:
		_fire_buffer = 0.0
		_try_fire()
	var held := Input.is_action_pressed("accept") or (_aim_mode == "mouse" and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	if held and _fire_cd <= 0.0:
		_try_fire()


func _press_fire() -> void:
	## A press during the cooldown is remembered briefly, so taps never get eaten.
	if not _try_fire():
		_fire_buffer = 0.15


func _try_fire(_unused: bool = false) -> bool:
	## The cooldown (upgradeable) gates every shot; the weapon sets how many
	## can be in the air at once.
	if not running or not alive or finished or paused:
		return false
	if _fire_cd > 0.0:
		return false
	if bolts.size() >= int(wstat.max):
		return false
	_fire_cd = fire_cd_base
	var dirv := facing
	if _aim_mode != "mouse":
		dirv = _assist(facing)
	var tip := CENTER + facing * (PLAYER_CORE + CANNON_LEN)
	bolts.append({"lp": tip, "dir": dirv, "trail": [], "w": str(lo.weapon)})
	_recoil = 3.0
	fx.burst(core.position + facing * 15.0, 5, [Pal.LEMON, Pal.WHITE, Pal.SYNC], Vector2(20, 60), Vector2(0.06, 0.16), {"dir": facing.angle(), "spread": 0.5})
	match str(lo.weapon):
		"beam":
			Sfx.play("shoot", 0.7, -6.0)
			shake(1.0, 0.06)
		"wave":
			Sfx.play("shoot", 0.85, -8.0)
		_:
			Sfx.play("shoot", randf_range(0.95, 1.08), -9.0)
	return true


func _assist(f: Vector2) -> Vector2:
	## Keyboard aim snaps to 8 directions; nudge the shot toward the threat the
	## pilot is plainly facing (the shield still uses the real facing).
	var best := f
	var best_a := ASSIST_CONE
	for th in threats:
		if not th.can_be_hit() or th.is_asteroid:
			continue
		var to: Vector2 = th.lp - CENTER
		var a := absf(f.angle_to(to))
		if a < best_a and to.length() < 330.0:
			best_a = a
			best = to.normalized()
	return best


# ---------------------------------------------------------------- events ---

func _run_event(e: Dictionary) -> void:
	match str(e.get("type", "")):
		"spawn_enemy":
			_spawn(e)
		"fx_background_color":
			_bg_color(e)
		"fx_async_message":
			_comms("SYSTEM", str(e.get("text", "")), float(e.get("type_speed_cps", 24.0)), float(e.get("hold_sec", 2.0)))
		"scene_handoff":
			_begin_victory()


func _bg_color(e: Dictionary) -> void:
	var name := str(e.get("color", "black")).to_lower()
	var target_a := 0.0
	if name == "danger_red":
		target_a = 0.3
		Sfx.play("tell", 0.8, -10.0)
		_warning()
	elif name == "alert_orange":
		target_a = 0.2
	var tw := create_tween()
	tw.tween_property(danger, "color:a", target_a, maxf(0.05, float(e.get("duration_sec", 0.2))))


func _warning() -> void:
	var w := Art.shadow_label("! WARNING !", Pal.BLOOD.lerp(Pal.WHITE, 0.2))
	overlay.add_child(w)
	w.position = Vector2(88 - Art.text_width(w.text) / 2.0, 8)
	var tw := w.create_tween()
	for i in 4:
		tw.tween_property(w, "modulate:a", 0.2, 0.12)
		tw.tween_property(w, "modulate:a", 1.0, 0.12)
	tw.tween_property(w, "modulate:a", 0.0, 0.2)
	tw.tween_callback(w.queue_free)


func _spawn(e: Dictionary) -> void:
	var th := Threat.new()
	th.m = self
	var kind := str(e.get("enemy_type", "")).strip_edges()
	var cfg: Dictionary = enemy_configs().get(kind, {})
	for k in cfg:
		if k == "color":
			var c: Array = cfg[k]
			th.color = Color(c[0], c[1], c[2], c[3])
		elif k in th:
			th.set(k, cfg[k])
	for k in ["move_speed", "sine_lateral_strength", "sine_wave_speed", "size", "max_hp"]:
		if e.has(k):
			th.set(k, float(e[k]))
	var side := str(e.get("spawn_side", "top")).strip_edges()
	th.spawn_side = side
	th.lp = _spawn_pos(e, side, kind)
	if bool(e.get("equalize_arrival_time", false)):
		var margin := _margin(kind)
		var ex := Rect2(Vector2.ZERO, Vector2(L, L)).grow(margin)
		var ref := minf(minf(CENTER.x - ex.position.x, ex.end.x - CENTER.x), minf(CENTER.y - ex.position.y, ex.end.y - CENTER.y))
		var dist := th.lp.distance_to(CENTER)
		if ref > 0.0 and dist > 0.0:
			th.move_speed = th.move_speed * dist / ref
	threat_root.add_child(th)
	threats.append(th)


func _margin(kind: String) -> float:
	if kind != "drone_fast":
		return SPAWN_MARGIN
	return -minf(FAST_INSET, maxf(8.0, L * 0.18))


func _spawn_pos(e: Dictionary, side: String, kind: String) -> Vector2:
	var margin := _margin(kind)
	var s := side.to_lower()
	if s == "degrees":
		var a := deg_to_rad(float(posmod(int(e.get("degrees", 0)), 360)) - 90.0)
		return _edge_point(Vector2(cos(a), sin(a)), margin)
	if s.begins_with("angle_"):
		var t := s.substr(6)
		if t.is_valid_float():
			var a := deg_to_rad(float(t))
			return _edge_point(Vector2(cos(a), sin(a)), margin)
		return CENTER
	var ranges := {
		"top": [-0.75, -0.25], "bottom": [0.25, 0.75], "left": [0.75, 1.25], "right": [-0.25, 0.25],
		"north": [-0.625, -0.375], "north_east": [-0.375, -0.125], "top_right": [-0.375, -0.125], "east": [-0.125, 0.125],
		"south_east": [0.125, 0.375], "bottom_right": [0.125, 0.375], "south": [0.375, 0.625], "south_west": [0.625, 0.875],
		"bottom_left": [0.625, 0.875], "west": [0.875, 1.125], "north_west": [1.125, 1.375], "top_left": [1.125, 1.375],
	}
	var r: Array = [-1.0, 1.0]
	if s == "random_left_right":
		r = [0.5, 1.0] if randf() < 0.5 else [-1.0, -0.5]
	elif s == "random_top_bottom" or s == "random_top_down":
		r = [-0.5, 0.0] if randf() < 0.5 else [0.0, 0.5]
	elif ranges.has(s):
		r = ranges[s]
	var ang := randf_range(r[0] * PI, r[1] * PI)
	return _edge_point(Vector2(cos(ang), sin(ang)), margin)


func _edge_point(dirv: Vector2, margin: float) -> Vector2:
	var ex := Rect2(Vector2.ZERO, Vector2(L, L)).grow(margin)
	var best := INF
	for t in [(ex.position.x - CENTER.x) / dirv.x if absf(dirv.x) > 0.0001 else INF, (ex.end.x - CENTER.x) / dirv.x if absf(dirv.x) > 0.0001 else INF,
			(ex.position.y - CENTER.y) / dirv.y if absf(dirv.y) > 0.0001 else INF, (ex.end.y - CENTER.y) / dirv.y if absf(dirv.y) > 0.0001 else INF]:
		if t <= 0.0 or t >= best:
			continue
		var p: Vector2 = CENTER + dirv * float(t)
		if p.x < ex.position.x - 0.01 or p.x > ex.end.x + 0.01 or p.y < ex.position.y - 0.01 or p.y > ex.end.y + 0.01:
			continue
		best = t
	return CENTER if best == INF else CENTER + dirv * best


# ----------------------------------------------------------------- shots ---

func spawn_enemy_shot(p: Vector2, dirv: Vector2, speed: float, dmg: float, r: float, kind: String) -> void:
	shots.append({"lp": p, "dir": dirv, "speed": speed, "dmg": dmg, "r": r, "kind": kind, "trail": []})
	var sp := (p * K).round()
	fx.burst(sp, 6, [Pal.LEMON if kind == "tank" else Pal.VOID, Pal.WHITE], Vector2(15, 40), Vector2(0.1, 0.25))
	Sfx.play("enemy_shoot", randf_range(0.9, 1.1), -10.0)


func _update_shots(delta: float) -> void:
	var sd := delta * speed_scale
	var area := Rect2(Vector2.ZERO, Vector2(L, L))
	for s in shots.duplicate():
		s.trail.push_front(s.lp)
		if s.trail.size() > 4:
			s.trail.pop_back()
		s.lp += s.dir * s.speed * sd
		var r: float = s.r
		if not area.grow(r).has_point(s.lp):
			shots.erase(s)
			continue
		var dist: float = s.lp.distance_to(CENTER)
		if dist > maxf(PLAYER_RADIUS, shot_block_r) + r or not alive:
			continue
		if dist <= shot_block_r + r and (s.lp - CENTER).dot(-facing) >= -r:
			shots.erase(s)
			_block_fx((s.lp * K).round(), true)
			continue
		if dist <= PLAYER_RADIUS + r:
			shots.erase(s)
			damage_player(s.dmg, null)


func _update_bolts(delta: float) -> void:
	var sd := delta * speed_scale
	var r: float = wstat.r
	var area := Rect2(Vector2.ZERO, Vector2(L, L)).grow(r)
	for b in bolts.duplicate():
		b.trail.push_front(b.lp)
		if b.trail.size() > 3:
			b.trail.pop_back()
		b.lp += b.dir * float(wstat.speed) * sd
		if not area.has_point(b.lp):
			bolts.erase(b)
			Achievements.shot_missed()
			continue
		for th in threats:
			if not th.can_be_hit():
				continue
			if th.lp.distance_to(b.lp) <= th.hit_radius() + r:
				bolts.erase(b)
				_bolt_hit(th, b)
				break


func _update_missiles(delta: float) -> void:
	## Auto Missile: launches on a timer and homes on the nearest thing it can
	## see, rocks included (which it can't break).
	if not lo.get("missile", false):
		return
	var sd := delta * speed_scale
	_missile_t -= sd
	if _missile_t <= 0.0 and not threats.is_empty():
		_missile_t = MISSILE_INTERVAL
		var a := facing.angle() + PI * (0.5 if randf() < 0.5 else -0.5)
		missiles.append({"lp": CENTER + Vector2.from_angle(a) * 20.0, "dir": Vector2.from_angle(a), "t": 0.0, "trail": []})
		Sfx.play("portal", 1.6, -12.0)
	for ms in missiles.duplicate():
		ms.t += sd
		var target = _nearest_threat(ms.lp)
		if target != null:
			var want: Vector2 = (target.lp - ms.lp).normalized()
			var ang: float = ms.dir.angle_to(want)
			ms.dir = ms.dir.rotated(clampf(ang, -MISSILE_TURN * sd, MISSILE_TURN * sd))
		ms.lp += ms.dir * MISSILE_SPEED * sd
		ms.trail.push_front(ms.lp)
		if ms.trail.size() > 6:
			ms.trail.pop_back()
		if int(ms.t * 30.0) % 2 == 0:
			fx.particle((ms.lp * K).round(), Vector2.ZERO, 0.35, Pal.STONE.lerp(Pal.WHITE, 0.3), {"size": 2.0, "size_end": 0.5})
		var hit = null
		for th in threats:
			if th.can_be_hit() and th.lp.distance_to(ms.lp) <= th.hit_radius() + 4.0:
				hit = th
				break
		if hit != null or ms.t > MISSILE_LIFE or not Rect2(Vector2.ZERO, Vector2(L, L)).grow(40).has_point(ms.lp):
			missiles.erase(ms)
			var p: Vector2 = (ms.lp * K).round()
			fx.burst(p, 10, [Pal.EMBER, Pal.LEMON, Pal.WHITE], Vector2(20, 70), Vector2(0.15, 0.35))
			fx.ring(p, 1, 8, 0.25, Pal.EMBER, 1.0, 1.0)
			Sfx.play("enemy_hit", 0.8, -10.0)
			if hit != null and not (hit.is_asteroid and hit.max_hp > 5.0):
				hit.apply_damage(1.0)


func _nearest_threat(from: Vector2):
	var best = null
	var bd := INF
	for th in threats:
		if not th.can_be_hit():
			continue
		var d: float = th.lp.distance_to(from)
		if d < bd:
			bd = d
			best = th
	return best


func _bolt_hit(th: Threat, b: Dictionary) -> void:
	Achievements.shot_hit()
	var p: Vector2 = (b.lp * K).round()
	if th.is_asteroid and th.max_hp > 5.0:
		fx.burst(p, 6, [Pal.STONE, Pal.WHITE, Pal.LEMON], Vector2(20, 60), Vector2(0.1, 0.25), {"dir": (-b.dir).angle(), "spread": 0.9})
		Sfx.play("block", 1.6, -16.0)
		th.apply_damage(float(wstat.dmg))
		return
	var died := th.apply_damage(float(wstat.dmg))
	fx.burst(p, 8, [Pal.LEMON, Pal.WHITE, Pal.EMBER], Vector2(20, 70), Vector2(0.1, 0.3), {"dir": (-b.dir).angle(), "spread": 1.1})
	if not died:
		Sfx.play("enemy_hit", randf_range(0.95, 1.1), -8.0)
		freeze = maxf(freeze, 0.025)


# --------------------------------------------------------- threat events ---

func on_tell(th: Threat, kind: String) -> void:
	Sfx.play("tell", 1.2 if kind == "charger" else 0.9, -11.0)
	var mark := Sprite2D.new()
	mark.texture = Art.ui("emote_!")
	mark.position = th.position + Vector2(0, -th.d * 0.5 - 8)
	popups.add_child(mark)
	mark.scale = Vector2(0.3, 0.3)
	var tw := mark.create_tween()
	tw.tween_property(mark, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.35)
	tw.tween_property(mark, "modulate:a", 0.0, 0.15)
	tw.tween_callback(mark.queue_free)
	if kind == "tank":
		fx.ring(th.position, 14, 3, th.tank_tell_sec, Pal.WHITE, 1.0, 1.0)


func on_block(th: Threat) -> void:
	_block_fx(th.position, false)


func _block_fx(p: Vector2, is_shot: bool) -> void:
	Achievements.blocked()
	_shield_pulse = 1.0
	fx.ring(p, 1, 9, 0.25, Pal.SYNC, 1.0, 1.0)
	fx.burst(p, 10, [Pal.SYNC, Pal.WHITE, Pal.TEAL], Vector2(25, 80), Vector2(0.12, 0.3), {"dir": (p - core.position).angle(), "spread": 1.0})
	Sfx.play("block", randf_range(0.95, 1.05), -6.0)
	freeze = maxf(freeze, 0.05)
	shake(1.5, 0.1)
	if is_shot:
		_popup(p + Vector2(0, -6), "BLOCK", Pal.SYNC)


func on_threat_died(th: Threat, was_blocked: bool) -> void:
	var p := th.position
	var col := th.color.lerp(Pal.EMBER, 0.4)
	if was_blocked:
		col = Pal.SYNC
	_shatter(th.pixel_image(), p, col)
	fx.circle(p, th.d * 0.6, 1, 0.14, Pal.WHITE)
	fx.ring(p, 2, th.d + 4, 0.3, col, 1.0, 1.0)
	var collided := not was_blocked and th.lp.distance_to(CENTER) <= PLAYER_RADIUS + th.hit_radius() + 1.0
	if not collided:
		_on_defeated(th.score_value(), was_blocked, p)
	Sfx.play("enemy_die", randf_range(0.9, 1.1), -6.0)
	freeze = maxf(freeze, 0.045)
	shake(2.0 if th.d > 14 else 1.0, 0.12)
	remove_threat(th, true)


func _shatter(img: Image, center: Vector2, tint: Color) -> void:
	## The sprite breaks into its own pixels and blows outward.
	if img == null:
		return
	var w := img.get_width()
	var h := img.get_height()
	var step := 1 if w * h < 300 else 2
	for y in range(0, h, step):
		for x in range(0, w, step):
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var off := Vector2(x - w / 2.0, y - h / 2.0)
			var v := off.normalized() * randf_range(20, 70) + Vector2(randf_range(-10, 10), randf_range(-10, 10))
			fx.particle(center + off, v, randf_range(0.25, 0.6), c, {"color2": Color(tint, 0.0), "drag": 0.9})


func _on_defeated(value: int, was_blocked: bool, p: Vector2) -> void:
	defeated_n += 1
	score += maxi(0, value)
	_popup(p + Vector2(0, -6), "+%d" % value, Pal.LEMON if not was_blocked else Pal.SYNC)
	if was_blocked:
		blocks += 1
		streak += 1
		best_streak = maxi(best_streak, streak)
		if streak >= 2:
			Sfx.play("combo", 1.0 + minf(streak, 10) * 0.05, -9.0)
			streak_label.text = "BLOCK x%d" % streak
			streak_label.scale = Vector2(1.4, 1.4)
			create_tween().tween_property(streak_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
		if streak >= 3:
			_set_mood("smile", 1.2)
	else:
		streak = 0
		streak_label.text = ""
	score_label.scale = Vector2(1.25, 1.25)
	create_tween().tween_property(score_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)


func _popup(p: Vector2, text: String, c: Color) -> void:
	var s := Sprite2D.new()
	s.texture = Art.number(text, c)
	s.position = p
	popups.add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "position:y", p.y - 10, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(s, "modulate:a", 0.0, 0.3).set_delay(0.3)
	tw.tween_callback(s.queue_free)


func remove_threat(th: Threat, _died: bool) -> void:
	if not threats.has(th):
		return
	threats.erase(th)
	th.queue_free()
	if threats.is_empty():
		_check_all_destroyed()


func _check_all_destroyed() -> void:
	for i in range(t_index, timeline.size()):
		if str(timeline[i].get("type", "")) == "spawn_enemy":
			return
	if not alive or finished:
		return
	var any := false
	for e in triggers:
		var tr = e.get("trigger", {})
		if typeof(tr) != TYPE_DICTIONARY or str(tr.get("type", "")) != "all_enemies_destroyed":
			continue
		var id := str(e.get("id", str(e.hash())))
		if fired_triggers.has(id) and not bool(tr.get("repeat", false)):
			continue
		fired_triggers[id] = true
		any = true
		match str(e.get("type", "")):
			"fx_async_message":
				_victory_msg = str(e.get("text", ""))
				_comms("SYSTEM", _victory_msg, float(e.get("type_speed_cps", 26.0)), float(e.get("hold_sec", 2.0)))
			"fx_background_color":
				_bg_color(e)
	if any or triggers.is_empty():
		_begin_victory()


# ---------------------------------------------------------------- player ---

func damage_player(amount: float, _src) -> bool:
	if not alive or finished or amount <= 0.0 or hp <= 0.0:
		return false
	hits_taken += 1
	Achievements.took_damage()
	streak = 0
	streak_label.text = ""
	if red_hp > 0.0:
		# red integrity takes the hit first
		red_hp = maxf(0.0, red_hp - amount)
		var ridx := int(red_hp)
		if ridx < red_cells.size():
			var rc: TextureRect = red_cells[ridx]
			rc.visible = false
			hud_fx.burst(right_panel.position + Vector2(5 + ridx * 12, 55) + Vector2(3, 4), 10, [Pal.BLOOD, Pal.WHITE, Pal.EMBER], Vector2(20, 60), Vector2(0.2, 0.5), {"up": 20.0, "acc": Vector2(0, 120)})
	else:
		hp = maxf(0.0, hp - amount)
		var idx := int(hp)
		if idx < cells.size():
			var c: TextureRect = cells[idx]
			c.texture = Art.ui("cell_off")
			hud_fx.burst(right_panel.position + Vector2(5 + idx * 12, 55) + Vector2(3, 4), 10, [Pal.SYNC, Pal.WHITE, Pal.TEAL], Vector2(20, 60), Vector2(0.2, 0.5), {"up": 20.0, "acc": Vector2(0, 120)})
	Sfx.play("hurt", 1.0, -3.0)
	core.hurt_t = 0.3
	shake(4.0, 0.25)
	var v := create_tween()
	vignette.color.a = 0.45
	v.tween_property(vignette, "color:a", 0.0, 0.35)
	fx.burst(core.position, 14, [Pal.BLOOD, Pal.EMBER, Pal.WHITE], Vector2(20, 70), Vector2(0.2, 0.45))
	_set_mood("shock", 0.6)
	if hp <= 0.0:
		_begin_death()
	else:
		_hitstun_until = Time.get_ticks_msec() / 1000.0 + HITSTUN_SEC
		speed_scale = HITSTUN_SCALE
	return true


func shake(a: float, t: float) -> void:
	_shake_amt = maxf(a, _shake_amt if _shake_t > 0.0 else 0.0)
	_shake_t = maxf(t, _shake_t)


func _update_shake(delta: float) -> void:
	var o := Vector2.ZERO
	if _shake_t > 0.0:
		_shake_t -= delta
		var a := int(ceilf(_shake_amt * minf(1.0, _shake_t * 5.0)))
		o = Vector2(randi_range(-a, a), randi_range(-a, a))
	arena.position = ARENA.position + o
	frame_box.position = ARENA.position - Vector2(2, 2) + o


func _set_mood(mood: String, t: float = 0.0) -> void:
	_mood = mood
	_mood_t = t
	var spec := Game.player_spec()
	if mood == "" and Game.sync_percent() >= 55:
		mood = "flat"
	portrait.texture = Art.portrait(spec, mood, false, false, 2)


# ------------------------------------------------------------------- hud ---

func _update_hud(delta: float) -> void:
	if _mood_t > 0.0:
		_mood_t -= delta
		if _mood_t <= 0.0:
			_set_mood("")
	if shown_score < score:
		shown_score = minf(score, shown_score + maxf(40.0, (score - shown_score) * 8.0) * delta)
		score_label.text = str(int(shown_score))
	if running:
		prog_bar.size.x = 56.0 * clampf(level_t / maxf(1.0, last_spawn_t), 0.0, 1.0)
		_update_sync()
	for c in right_panel.get_children():
		for g in c.get_children():
			if g.has_meta("spin"):
				g.texture = Art.planet(planet_key, 14, int(_planet_frame))


func _update_sync() -> void:
	var k := clampf(level_t / maxf(1.0, last_spawn_t), 0.0, 1.0)
	var v := _sync0 + k * 4.0
	sync_label.text = "%d%%" % int(v)
	sync_bar.size.x = 56.0 * clampf(v / 100.0, 0.0, 1.0)


func _comms(who: String, text: String, cps: float, hold: float) -> void:
	_comms_queue.append({"who": who, "text": text, "cps": cps, "hold": hold})
	if not _comms_busy:
		_comms_pump()


func _comms_pump() -> void:
	_comms_busy = true
	while not _comms_queue.is_empty():
		var msg: Dictionary = _comms_queue.pop_front()
		comms_name.text = msg.who
		comms_name.add_theme_color_override("font_color", Pal.SYNC if msg.who == "SYSTEM" else Pal.LEMON)
		comms_text.text = msg.text
		comms_text.visible_characters = 0
		var n := 0
		var t := 0.0
		while n < msg.text.length():
			await get_tree().process_frame
			if not is_inside_tree():
				return
			t += get_process_delta_time() * maxf(8.0, msg.cps) * 1.6
			var nn := mini(int(t), msg.text.length())
			if nn != n:
				n = nn
				if n % 3 == 0:
					Sfx.voice("system" if msg.who == "SYSTEM" else "boy", n)
				comms_text.visible_characters = n
		comms_text.visible_characters = -1
		var hold: float = msg.hold
		while hold > 0.0 and _comms_queue.is_empty():
			await get_tree().process_frame
			if not is_inside_tree():
				return
			hold -= get_process_delta_time()
	_comms_busy = false


func _chatter(delta: float) -> void:
	if arcade or training:
		return
	_chatter_t -= delta
	if _chatter_t > 0.0:
		return
	_chatter_t = randf_range(16.0, 26.0)
	var who := ["hiro"]
	if not bool(Game.story.pala_unavailable):
		who.append("pala")
	if not Game.midas_dead():
		who.append("midas")
	var w: String = who[randi() % who.size()]
	var lines: Array = Data.COMMS[w]
	if w == "hiro" and Game.relationship("hiro") >= 3:
		lines = ["Target. Target. Target.", "...", "Faster."]
	_comms(w.capitalize(), lines[randi() % lines.size()], 30.0, 2.0)


# ----------------------------------------------------------------- pause ---

func _pause_menu() -> void:
	paused = true
	Sfx.play("confirm")
	get_tree().paused = false
	var dim := ColorRect.new()
	dim.color = Color(Pal.INK, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var title := Art.shadow_label("PAUSED", Pal.SYNC, 2)
	title.position = Vector2(160 - Art.text_width("PAUSED", 2) / 2.0, 50)
	dim.add_child(title)
	var opts := ["Resume", "Retreat (counts as failed)" if not arcade else "Abort mission"]
	var m := Menu.make(dim, opts, Vector2(100, 84), Vector2(130, 27))
	var r := await m.ask()
	dim.queue_free()
	paused = false
	if r == 1:
		alive = false
		running = false
		_finish("retreat")


# ------------------------------------------------------- victory / death ---

func _begin_victory() -> void:
	if finished or not alive:
		return
	finished = true
	running = false
	await get_tree().create_timer(0.6).timeout
	shots.clear()
	bolts.clear()
	Sfx.music("mission_complete", 0.4, -6.0)
	Sfx.play("sync", 1.0, -4.0)
	fx.ring(core.position, 6, 120, 1.0, Pal.SYNC, 2.0, 1.0)
	fx.ring(core.position, 6, 90, 0.8, Pal.WHITE, 1.0, 1.0)
	_set_mood("smile" if Game.sync_percent() < 55 else "flat")
	var before := Game.sync_percent()
	var unlocks := []
	if training:
		credits_earned = int(data.get("reward", 0))
	else:
		unlocks = Game.mark_completed(planet_type, level_index, arcade)
		if not arcade:
			Game.story.last_mission = level_id
			Game.story.deployments = int(Game.story.get("deployments", 0)) + 1
			credits_earned = Data.mission_reward(planet_type, level_index)
	if credits_earned > 0:
		Game.add_credits(credits_earned)
	if not training:
		Achievements.mission_cleared(level_index, hits_taken)
	var after := Game.sync_percent()
	var banner := Art.shadow_label("SIMULATION CLEARED" if training else "THREATS NEUTRALIZED", Pal.SYNC)
	overlay.add_child(banner)
	banner.position = Vector2(-120, 18)
	var tw := create_tween()
	tw.tween_property(banner, "position:x", 88 - Art.text_width(banner.text) / 2.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.6).timeout
	var panel := Art.make_box("sys_box")
	panel.position = Vector2(26, 36)
	panel.size = Vector2(124, 119 if credits_earned > 0 else 108)
	panel.scale = Vector2(1, 0)
	panel.pivot_offset = panel.size / 2.0
	overlay.add_child(panel)
	await create_tween().tween_property(panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).finished
	var rows := [["SCORE", score], ["DESTROYED", defeated_n], ["BLOCKED", blocks], ["BEST STREAK", best_streak], ["INTEGRITY", "%d/%d" % [int(hp), int(MAX_HP)]]]
	if credits_earned > 0:
		rows.append(["CREDITS", credits_earned])
	var sy := 5 + rows.size() * 11
	for i in rows.size():
		var l := Art.label(rows[i][0], Pal.TEXT_DIM)
		l.position = Vector2(6, 5 + i * 11)
		panel.add_child(l)
		var v := Art.label("0", Pal.LEMON)
		v.position = Vector2(76, 5 + i * 11)
		panel.add_child(v)
		if rows[i][1] is int:
			var target: int = rows[i][1]
			var dur := 0.4 if target > 0 else 0.05
			var tt := create_tween()
			tt.tween_method(func(x: float) -> void:
				var nv := str(int(x))
				if v.text != nv:
					v.text = nv
					Sfx.play("tick", 1.0, -18.0), 0.0, float(target), dur)
			await tt.finished
		else:
			v.text = rows[i][1]
		Sfx.play("coin" if rows[i][0] == "CREDITS" else "score", 1.0 + i * 0.05, -10.0)
		if rows[i][0] == "CREDITS":
			v.add_theme_color_override("font_color", Pal.GLOW)
			v.text = "+" + v.text
		await get_tree().create_timer(0.08).timeout
	var sl := Art.label("SYNCHRONIZATION", Pal.SYNC)
	sl.position = Vector2(6, sy + 2)
	panel.add_child(sl)
	var bb := ColorRect.new()
	bb.color = Pal.INK
	bb.position = Vector2(6, sy + 14)
	bb.size = Vector2(112, 6)
	panel.add_child(bb)
	var fill := ColorRect.new()
	fill.color = Pal.SYNC
	fill.position = Vector2(7, sy + 15)
	fill.size = Vector2(110.0 * before / 100.0, 4)
	panel.add_child(fill)
	var pl := Art.label("%d%%" % before, Pal.TEXT)
	pl.position = Vector2(92, sy + 2)
	panel.add_child(pl)
	if training:
		sl.visible = false
		bb.visible = false
		fill.visible = false
		pl.visible = false
	await get_tree().create_timer(0.25).timeout
	if after != before and not arcade and not training:
		Sfx.play("sync", 1.2, -8.0)
		var ft := create_tween()
		ft.tween_property(fill, "size:x", 110.0 * after / 100.0, 0.8).set_trans(Tween.TRANS_SINE)
		ft.parallel().tween_method(func(x: float) -> void: pl.text = "%d%%" % int(x), float(before), float(after), 0.8)
		await ft.finished
		var up := Art.label("+%d" % (after - before), Pal.LEMON)
		up.position = Vector2(70, sy + 2)
		panel.add_child(up)
	var y := sy + 24
	for p in unlocks:
		var u := Art.label("NEW: " + str(Data.PLANET_INFO[p].name), Pal.GLOW)
		u.position = Vector2(6, y)
		panel.add_child(u)
		Sfx.play("chime", 1.0, -6.0)
		y += 10
	var press := Art.shadow_label("Press Z", Pal.TEXT)
	press.position = Vector2(88 - Art.text_width("Press Z") / 2.0, 160)
	overlay.add_child(press)
	while not Input.is_action_just_pressed("accept"):
		press.visible = fmod(Time.get_ticks_msec() / 1000.0, 1.0) < 0.65
		await get_tree().process_frame
	Sfx.play("confirm")
	_result = {"result": "win", "score": score, "defeated": defeated_n, "blocks": blocks, "best_streak": best_streak,
		"planet": planet_type, "level": level_index, "unlocks": unlocks, "hits": hits_taken, "credits": credits_earned}
	_done_sig = true
	mission_done.emit()


func _begin_death() -> void:
	if not alive:
		return
	alive = false
	running = false
	speed_scale = 0.0
	Sfx.play("shutdown", 1.0, -4.0)
	Sfx.music_volume(-60.0, 2.5)
	shake(3.0, 3.6)
	_set_mood("hollow")
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "shield_k", 0.0, 1.35)
	tw.tween_property(self, "cannon_k", 0.0, 1.35)
	await tw.finished
	Sfx.play("explode", 0.8, -2.0)
	fx.burst(core.position, 40, [Pal.SYNC, Pal.WHITE, Pal.BLOOD], Vector2(20, 100), Vector2(0.3, 0.9))
	await _arena_flash(Pal.WHITE, 0.24)
	# CRT shutdown: the window collapses to a line, then a dot.
	arena.pivot_offset = ARENA.size / 2.0
	var c1 := create_tween()
	c1.tween_property(arena, "scale", Vector2(1.0, 0.01), 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	c1.tween_property(arena, "scale", Vector2(0.0, 0.01), 0.22)
	await c1.finished
	Sfx.stop_music(0.2)
	var lost := Art.shadow_label("SIMULATION ENDED" if training else "SYNCHRONIZATION LOST", Pal.BLOOD.lerp(Pal.WHITE, 0.2))
	lost.position = Vector2(160 - Art.text_width(lost.text) / 2.0, 70)
	add_child(lost)
	var sub := Art.label("No credits awarded." if training else ("Deployment failed." if not arcade else "Mission failed."), Pal.TEXT_DIM)
	sub.position = Vector2(160 - Art.text_width(sub.text) / 2.0, 84)
	add_child(sub)
	await get_tree().create_timer(1.0).timeout
	var press := Art.shadow_label("Press Z", Pal.TEXT)
	press.position = Vector2(160 - Art.text_width("Press Z") / 2.0, 150)
	add_child(press)
	while not Input.is_action_just_pressed("accept"):
		press.visible = fmod(Time.get_ticks_msec() / 1000.0, 1.0) < 0.65
		await get_tree().process_frame
	_finish("lose")


func _finish(result: String) -> void:
	if result != "win" and not arcade and not training:
		Game.record_failure()
	_result = {"result": result, "score": score, "planet": planet_type, "level": level_index, "unlocks": []}
	_done_sig = true
	mission_done.emit()


# ============================================================ inner nodes ===

class StarLayer extends Node2D:
	var m
	var pts := []
	var warp := 0.0

	func _ready() -> void:
		for i in 70:
			pts.append({"p": Vector2(randf() * 176, randf() * 176), "z": randf_range(0.2, 1.0), "ph": randf() * TAU, "k": 0 if randf() < 0.8 else (1 if randf() < 0.8 else 2)})

	func _process(delta: float) -> void:
		var c := Vector2(88, 88)
		for s in pts:
			var v: Vector2 = s.p - c
			var spd: float = (3.0 + warp * 340.0) * s.z
			s.p += v.normalized() * spd * delta * (0.4 + v.length() / 88.0)
			if not Rect2(-8, -8, 192, 192).has_point(s.p):
				s.p = c + Vector2.from_angle(randf() * TAU) * randf_range(2, 30)
		queue_redraw()

	func _draw() -> void:
		var t := Time.get_ticks_msec() / 1000.0
		var sway: Vector2 = -m.facing * 1.5 if m.alive else Vector2.ZERO
		# faint tactical rings at the distances threats like to hold
		var c := Vector2(88, 88)
		for rr in [66.0, 36.0]:
			var n := int(rr * 1.6)
			for i in n:
				if i % 3 != 0:
					continue
				var a := i * TAU / n + t * (0.05 if rr > 50.0 else -0.08)
				draw_rect(Rect2((c + Vector2(cos(a), sin(a)) * rr).round(), Vector2.ONE), Color(Pal.TEAL, 0.28))
		for k in 4:
			var d := Vector2.from_angle(k * PI / 2.0)
			draw_line((c + d * 70).round(), (c + d * 76).round(), Color(Pal.TEAL, 0.35), 1.0)
		for s in pts:
			var p: Vector2 = (s.p + sway * s.z).round()
			var a: float = 0.4 + 0.6 * (0.5 + 0.5 * sin(t * 2.0 + s.ph))
			if warp > 0.0:
				var dirv: Vector2 = (s.p - Vector2(88, 88)).normalized()
				draw_line(p, p - dirv * (4.0 + warp * 20.0 * s.z), Color(Pal.SYNC.lerp(Pal.WHITE, s.z), 0.8), 1.0)
			elif s.k == 0:
				draw_rect(Rect2(p, Vector2.ONE), Color(Pal.WHITE, a * s.z))
			else:
				draw_texture(Art.star(s.k), p - Vector2(2, 2), Color(1, 1, 1, a))


class ShotLayer extends Node2D:
	var m

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var K: float = m.K
		for b in m.bolts:
			var p: Vector2 = (b.lp * K).round()
			match str(b.get("w", "basic")):
				"wave":
					# a wide crescent bowed forward
					var nrm := Vector2(-b.dir.y, b.dir.x)
					for k in range(-5, 6):
						var q: Vector2 = p + nrm * k - b.dir * (absf(k) * absf(k) * 0.09)
						var col := Pal.SYNC.lerp(Pal.WHITE, 0.5 if absi(k) < 2 else 0.0)
						draw_rect(Rect2(q.round(), Vector2.ONE), col)
						draw_rect(Rect2((q - b.dir).round(), Vector2.ONE), Color(Pal.SYNC, 0.45))
				"beam":
					var tail: Vector2 = p - b.dir * 9.0
					draw_line(tail, p, Color(Pal.VOID.lerp(Pal.WHITE, 0.3), 0.55), 3.0)
					draw_line(tail, p, Pal.WHITE, 1.0)
					draw_rect(Rect2(p - Vector2(1, 1), Vector2(3, 3)), Pal.WHITE)
				_:
					for i in b.trail.size():
						var q: Vector2 = (b.trail[i] * K).round()
						draw_line(q, p, Color(Pal.LEMON, 0.5 - i * 0.15), 3.0 - i)
					draw_rect(Rect2(p - Vector2(1, 1), Vector2(3, 3)), Pal.LEMON)
					draw_rect(Rect2(p, Vector2(1, 1)), Pal.WHITE)
		for ms in m.missiles:
			var p: Vector2 = (ms.lp * K).round()
			var back: Vector2 = -ms.dir
			draw_line(p, (p + back * 3.0).round(), Pal.STONE, 2.0)
			draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Pal.EMBER)
			var flame: Vector2 = (p + back * (4.0 + randf() * 2.0)).round()
			draw_rect(Rect2(flame, Vector2.ONE), Pal.LEMON)
		for s in m.shots:
			var p: Vector2 = (s.lp * K).round()
			var col: Color = Pal.EMBER if s.kind == "tank" else Pal.VOID
			for i in s.trail.size():
				var q: Vector2 = (s.trail[i] * K).round()
				draw_circle(q, maxf(0.5, s.r * K - i * 0.6), Color(col, 0.35 - i * 0.08))
			var r: float = maxf(1.5, s.r * K)
			var fl := 1.0 if int(Time.get_ticks_msec() / 60) % 2 == 0 else 0.0
			draw_circle(p, r + 1.0, Color(col, 0.5))
			draw_circle(p, r, col.lerp(Pal.WHITE, 0.3 * fl))
			draw_rect(Rect2(p - Vector2(0, 1), Vector2(1, 1)), Pal.WHITE)


class PlayerCore extends Node2D:
	## The planet, its shield crescent and the beam cannon, drawn pixel by pixel.
	var m
	var planet_scale := 1.0
	var hurt_t := 0.0
	var ring_cache := {}

	func _ring(r: int) -> Array:
		if not ring_cache.has(r):
			var pts := []
			var seen := {}
			for i in r * 12:
				var a := i * TAU / (r * 12)
				var p := Vector2(cos(a), sin(a)) * (r + 0.5)
				var q := Vector2i(roundi(p.x), roundi(p.y))
				if not seen.has(q):
					seen[q] = true
					pts.append([q, a])
			ring_cache[r] = pts
		return ring_cache[r]

	func _process(delta: float) -> void:
		hurt_t = maxf(0.0, hurt_t - delta)
		queue_redraw()

	func _draw() -> void:
		var tex: Texture2D = Art.planet(m.planet_key, 16, int(m._planet_frame))
		var sz := tex.get_size() * planet_scale
		if planet_scale > 1.5:
			# close up: draw a detailed render so the zoom isn't a blur of big pixels
			tex = Art.planet(m.planet_key, 128, 0)
			sz = tex.get_size() * (planet_scale * 16.0 / 128.0)
		var mod := Color(1, 0.45, 0.45) if hurt_t > 0.0 and int(hurt_t * 30) % 2 == 0 else Color.WHITE
		draw_texture_rect(tex, Rect2((-sz / 2.0).round(), sz), false, mod)
		if planet_scale > 1.05:
			return
		var back: float = (-m.facing).angle()
		var k: float = m.shield_k
		var pulse: float = m._shield_pulse
		if k > 0.0:
			var col := Pal.SYNC.lerp(Pal.WHITE, pulse)
			var rb: int = 11 + (5 if m.lo.get("ext_shield", false) else 0)
			for r in [rb + int(pulse * 2.0), rb + 1 + int(pulse * 2.0)]:
				for e in _ring(r):
					var da := absf(wrapf(e[1] - back, -PI, PI))
					if da > PI * 0.5 * k:
						continue
					var seg := int((e[1] - back + PI) / (PI / 5.0))
					var gap := absf(fmod(e[1] - back + PI + 100.0 * TAU, PI / 5.0) - PI / 10.0) > PI / 10.0 - 0.05
					if gap:
						continue
					var a := (0.95 if r == rb + int(pulse * 2.0) else 0.55) * (0.85 + 0.15 * sin(Time.get_ticks_msec() / 90.0 + seg))
					draw_rect(Rect2(Vector2(e[0]), Vector2.ONE), Color(col, a))
		var ck: float = m.cannon_k
		if ck > 0.0:
			var f: Vector2 = m.facing
			var n := Vector2(-f.y, f.x)
			var r0 := 8.0
			var r1: float = r0 + 7.0 * ck - m._recoil
			var steps := int(r1 - r0) + 1
			for i in steps:
				var p: Vector2 = f * (r0 + i)
				draw_rect(Rect2((p + n).round(), Vector2.ONE), Pal.STEEL)
				draw_rect(Rect2((p - n).round(), Vector2.ONE), Pal.SLATE)
				draw_rect(Rect2(p.round(), Vector2.ONE), Pal.SYNC.lerp(Pal.WHITE, 0.3))
			draw_rect(Rect2((f * r1).round() - Vector2(1, 1), Vector2(2, 2)), Pal.WHITE)
