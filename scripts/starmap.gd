class_name StarMap
extends Control
## Scene 2.6: the deployment terminal's star map. Points of light bloom into
## worlds; pick one, pick a level, deploy. Returns a level id or "".

var arcade := false
var first_time := false
var visible_planets: Array = []
var sel := 0
var nodes := {}
var t := 0.0
var bloom := {}
var line_k := 0.0
var info_name: Label
var info_blurb: Label
var info_levels: Label
var info_tag: Label
var title_l: Label
var cursor_ring := 0.0
var drawer: Node2D
var _ready_input := false


func setup(p_arcade: bool, p_first: bool) -> void:
	arcade = p_arcade
	first_time = p_first
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = Art.space(320, 180, "umbra_vacua_planet")
	add_child(bg)
	drawer = Node2D.new()
	drawer.draw.connect(_draw_map)
	add_child(drawer)
	for p in Data.PLANETS:
		var known := Game.seen.has(p) if arcade else Game.is_planet_unlocked(p)
		if not known and (p == "umbra_vacua" or p == "mechanon_ascens"):
			continue
		visible_planets.append(p)
		bloom[p] = 0.0 if first_time else 1.0
	var tb := Art.make_box("sys_box")
	tb.position = Vector2(6, 4)
	tb.size = Vector2(150, 16)
	add_child(tb)
	title_l = Art.label("FREE MISSIONS" if arcade else "ACTIVE DEFENSE REQUESTS", Pal.SYNC)
	title_l.position = Vector2(5, 3)
	tb.add_child(title_l)
	var ib := Art.make_box("box")
	ib.position = Vector2(6, 132)
	ib.size = Vector2(308, 44)
	add_child(ib)
	info_name = Art.label("", Pal.TEXT)
	info_name.position = Vector2(6, 3)
	ib.add_child(info_name)
	info_tag = Art.label("", Pal.BLOOD)
	info_tag.position = Vector2(200, 3)
	ib.add_child(info_tag)
	info_blurb = Art.label("", Pal.TEXT_DIM)
	info_blurb.position = Vector2(6, 15)
	ib.add_child(info_blurb)
	info_levels = Art.label("", Pal.SYNC)
	info_levels.position = Vector2(6, 27)
	ib.add_child(info_levels)
	var help := Art.label("Arrows choose   Z select   X back", Pal.TEXT_DIM)
	help.position = Vector2(170, 6)
	add_child(help)
	for i in visible_planets.size():
		if _unlocked(visible_planets[i]):
			sel = i
			if visible_planets[i] == Game.story.get("last_planet", ""):
				break
	_update_info()


func _unlocked(p: String) -> bool:
	return Game.seen.has(p) if arcade else Game.is_planet_unlocked(p)


func _process(delta: float) -> void:
	t += delta
	cursor_ring += delta
	drawer.queue_redraw()


func _draw_map() -> void:
	# constellation lines
	for i in range(visible_planets.size() - 1):
		var a: Vector2 = Data.PLANET_INFO[visible_planets[i]].pos
		var b: Vector2 = Data.PLANET_INFO[visible_planets[i + 1]].pos
		var k := minf(bloom[visible_planets[i]], bloom[visible_planets[i + 1]])
		if k <= 0.0:
			continue
		var n := int(a.distance_to(b) / 4.0)
		for j in int(n * k):
			if (j + int(t * 8.0)) % 3 == 0:
				continue
			var p := a.lerp(b, float(j) / n).round()
			drawer.draw_rect(Rect2(p, Vector2.ONE), Color(Pal.TEAL, 0.7))
	for i in visible_planets.size():
		var p: String = visible_planets[i]
		var k: float = bloom[p]
		if k <= 0.0:
			continue
		var pos: Vector2 = Data.PLANET_INFO[p].pos + Vector2(0, sin(t * 1.5 + i) * 1.5)
		var unlocked := _unlocked(p)
		var key: String = Data.PLANET_INFO[p].tex
		var d := 24 if i == sel else 18
		var tex := Art.planet(key, d, int(t * 4.0 + i * 3))
		var mod := Color.WHITE if unlocked else Color(0.25, 0.25, 0.35)
		var sz := tex.get_size() * minf(1.0, k * 1.3)
		drawer.draw_texture_rect(tex, Rect2((pos - sz / 2.0).round(), sz), false, mod)
		if not unlocked:
			drawer.draw_texture(Art.ui("lock"), (pos - Vector2(4, 4)).round())
			continue
		# threat markers blink around worlds that still need defending
		var done := (int(Game.arcade.get(p, 0)) if arcade else Game.highest(p))
		if done < 3:
			for m in 3:
				var a := t * 0.8 + m * TAU / 3.0 + i
				var mp := pos + Vector2(cos(a), sin(a)) * (d * 0.5 + 5)
				if fmod(t * 3.0 + m, 1.0) < 0.6:
					drawer.draw_rect(Rect2(mp.round(), Vector2(2, 2)), Pal.BLOOD)
		if i == sel:
			var r := d * 0.5 + 5 + sin(t * 6.0)
			for s in 24:
				var a := s * TAU / 24.0 + cursor_ring * 1.5
				if s % 3 != 2:
					drawer.draw_rect(Rect2((pos + Vector2(cos(a), sin(a)) * r).round() - Vector2.ONE * 0.5, Vector2(2, 2)), Pal.SYNC if s % 3 == 0 else Pal.WHITE)
			drawer.draw_texture(Art.ui("cursor"), (pos + Vector2(-r - 10, -4)).round())


func _update_info() -> void:
	if visible_planets.is_empty():
		return
	var p: String = visible_planets[sel]
	var info: Dictionary = Data.PLANET_INFO[p]
	if not _unlocked(p):
		info_name.text = "UNKNOWN SIGNAL"
		info_blurb.text = "Access not granted."
		info_levels.text = ""
		info_tag.text = ""
		return
	info_name.text = info.name.to_upper()
	info_blurb.text = info.blurb
	var done := (int(Game.arcade.get(p, 0)) if arcade else Game.highest(p))
	var parts := []
	for l in 3:
		parts.append(("[%02d done]" if done > l else ("[%02d]" if Game.is_level_unlocked(p, l + 1, arcade) else "[%02d locked]")) % (l + 1))
	info_levels.text = "  ".join(parts)
	var tags := ["DEFENSE REQUESTED", "URGENT", "UNSTABLE"]
	info_tag.text = "" if done >= 3 else tags[(p.length() + done) % 3]


func run() -> String:
	if first_time:
		Sfx.play("beep")
		for p in visible_planets:
			bloom[p] = 0.01
			var bt := create_tween()
			bt.tween_method(func(v: float) -> void: bloom[p] = v, 0.01, 1.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			Sfx.play("chime", 0.8 + visible_planets.find(p) * 0.08, -10.0)
			await get_tree().create_timer(0.35).timeout
	Sfx.music("level_select", 1.0)
	await get_tree().process_frame
	while true:
		await get_tree().process_frame
		var old := sel
		if Input.is_action_just_pressed("right") or Input.is_action_just_pressed("down"):
			sel = (sel + 1) % visible_planets.size()
		elif Input.is_action_just_pressed("left") or Input.is_action_just_pressed("up"):
			sel = (sel - 1 + visible_planets.size()) % visible_planets.size()
		elif Input.is_action_just_pressed("cancel"):
			Sfx.play("cancel")
			return ""
		elif Input.is_action_just_pressed("accept"):
			var p: String = visible_planets[sel]
			if not _unlocked(p):
				Sfx.play("miss")
				continue
			Sfx.play("confirm")
			var lv := await _pick_level(p)
			if lv > 0:
				Game.story["last_planet"] = p
				await _deploy_fx(p)
				return "%s_level_%02d" % [p, lv]
		if old != sel:
			Sfx.play("blip")
			_update_info()
	return ""


func _pick_level(p: String) -> int:
	var opts := []
	var done := (int(Game.arcade.get(p, 0)) if arcade else Game.highest(p))
	for l in 3:
		var open := Game.is_level_unlocked(p, l + 1, arcade)
		var label := "Level %02d" % (l + 1)
		if l == 2:
			label += " - " + str(Data.PLANET_INFO[p].boss)
		opts.append({"text": label, "enabled": open, "right": "done" if done > l else ("" if open else "locked")})
	var m := Menu.make(self, opts, Vector2(150, 70), Vector2(158, 37))
	var best := 0
	for l in 3:
		if Game.is_level_unlocked(p, l + 1, arcade):
			best = l
	m.index = mini(best, done)
	m.set_entries(opts)
	var r := await m.ask()
	m.queue_free()
	return r + 1 if r >= 0 else 0


func _deploy_fx(p: String) -> void:
	Sfx.play("warp", 1.4, -8.0)
	var pos: Vector2 = Data.PLANET_INFO[p].pos
	var tw := create_tween()
	tw.tween_property(drawer, "scale", Vector2(3, 3), 0.6).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(drawer, "position", -pos * 2.0, 0.6).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await tw.finished
