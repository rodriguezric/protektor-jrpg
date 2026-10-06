class_name Training
extends Control
## The sim pods: a module select laid out like the star map. Three disciplines
## (blocking, shooting, both), three tiers each, unlocked in order. Every drill
## is built as ordinary mission data, so it plays exactly like a deployment.
## run() returns {"module": id, "tier": 0..2} or {} when you step away.

const ROMAN := ["I", "II", "III"]

var sel := 0
var t := 0.0
var drawer: Node2D
var info_name: Label
var info_desc: Label
var info_tiers: Label
var credits_l: Label


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = Art.space(320, 180, "metal_planet")
	add_child(bg)
	drawer = Node2D.new()
	drawer.draw.connect(_draw_map)
	add_child(drawer)
	var tb := Art.make_box("sys_box")
	tb.position = Vector2(6, 4)
	tb.size = Vector2(120, 16)
	add_child(tb)
	var tl := Art.label("TRAINING MODULES", Pal.SYNC)
	tl.position = Vector2(5, 3)
	tb.add_child(tl)
	var cb := Art.make_box("bar_box")
	cb.position = Vector2(238, 4)
	cb.size = Vector2(76, 16)
	add_child(cb)
	var ci := TextureRect.new()
	ci.texture = Art.ui("credit")
	ci.position = Vector2(3, 3)
	cb.add_child(ci)
	credits_l = Art.label("", Pal.LEMON)
	credits_l.position = Vector2(15, 3)
	cb.add_child(credits_l)
	var ib := Art.make_box("box")
	ib.position = Vector2(6, 120)
	ib.size = Vector2(308, 56)
	add_child(ib)
	info_name = Art.label("", Pal.TEXT)
	info_name.position = Vector2(6, 3)
	ib.add_child(info_name)
	info_desc = Label.new()
	info_desc.position = Vector2(6, 15)
	info_desc.size = Vector2(296, 22)
	info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_desc.add_theme_color_override("font_color", Pal.TEXT_DIM)
	ib.add_child(info_desc)
	info_tiers = Art.label("", Pal.SYNC)
	info_tiers.position = Vector2(6, 40)
	ib.add_child(info_tiers)
	var help := Art.label("Z select  X back", Pal.TEXT_DIM)
	help.position = Vector2(140, 6)
	add_child(help)
	_update_info()


func _process(delta: float) -> void:
	t += delta
	credits_l.text = str(Game.credits())
	drawer.queue_redraw()


func _draw_map() -> void:
	for i in Data.TRAINING_MODULES.size():
		var id: String = Data.TRAINING_MODULES[i]
		var m: Dictionary = Data.TRAINING[id]
		var pos: Vector2 = m.pos + Vector2(0, sin(t * 1.5 + i) * 1.5)
		var d := 30 if i == sel else 24
		# hologram: the planet in sync-light, with scanlines
		var tex := Art.planet(m.tex, d, int(t * 4.0 + i * 5))
		var sz := tex.get_size()
		drawer.draw_texture_rect(tex, Rect2((pos - sz / 2.0).round(), sz), false, Color(0.55, 1.0, 1.05, 0.85))
		for y in range(int(pos.y - sz.y / 2.0), int(pos.y + sz.y / 2.0), 2):
			drawer.draw_line(Vector2(pos.x - sz.x / 2.0, y), Vector2(pos.x + sz.x / 2.0, y), Color(Pal.INK, 0.25), 1.0)
		# projector base
		for k in 14:
			var a := k * TAU / 14.0 + t
			drawer.draw_rect(Rect2((pos + Vector2(cos(a) * 16, 22 + sin(a) * 3)).round(), Vector2.ONE), Color(Pal.SYNC, 0.6))
		var lbl: String = m.short
		drawer.draw_string(Art.font, (pos + Vector2(-Art.text_width(lbl) / 2.0, 36)).round(), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, PixFont.SIZE, Pal.TEXT if i == sel else Pal.TEXT_DIM)
		# tier pips: cleared / open / locked
		var done := Game.training_level(id)
		for k in 3:
			var pp := pos + Vector2(-13 + k * 10, 41)
			var col := Pal.SYNC if k < done else (Pal.STEEL if k <= done else Pal.INK2)
			drawer.draw_rect(Rect2(pp, Vector2(6, 4)), col)
		if i == sel:
			var r := d * 0.5 + 6 + sin(t * 6.0)
			for s in 24:
				var a := s * TAU / 24.0 + t * 1.5
				if s % 3 != 2:
					drawer.draw_rect(Rect2((pos + Vector2(cos(a), sin(a)) * r).round(), Vector2(2, 2)), Pal.SYNC if s % 3 == 0 else Pal.WHITE)


func _update_info() -> void:
	var id: String = Data.TRAINING_MODULES[sel]
	var m: Dictionary = Data.TRAINING[id]
	info_name.text = "%s  -  %s" % [m.short, m.name.to_upper()]
	info_desc.text = m.desc
	var done := Game.training_level(id)
	var parts := []
	for k in 3:
		var tag := "cleared" if k < done else ("%dc" % m.rewards[k] if k <= done else "locked")
		parts.append("[%s %s]" % [ROMAN[k], tag])
	info_tiers.text = "  ".join(parts)


func run() -> Dictionary:
	await get_tree().process_frame
	while true:
		await get_tree().process_frame
		var old := sel
		if Input.is_action_just_pressed("right") or Input.is_action_just_pressed("down"):
			sel = (sel + 1) % Data.TRAINING_MODULES.size()
		elif Input.is_action_just_pressed("left") or Input.is_action_just_pressed("up"):
			sel = (sel - 1 + Data.TRAINING_MODULES.size()) % Data.TRAINING_MODULES.size()
		elif Input.is_action_just_pressed("cancel"):
			Sfx.play("cancel")
			return {}
		elif Input.is_action_just_pressed("accept"):
			Sfx.play("confirm")
			var tier := await _pick_tier()
			if tier >= 0:
				return {"module": Data.TRAINING_MODULES[sel], "tier": tier}
		if old != sel:
			Sfx.play("blip")
			_update_info()
	return {}


func _pick_tier() -> int:
	var id: String = Data.TRAINING_MODULES[sel]
	var m: Dictionary = Data.TRAINING[id]
	var done := Game.training_level(id)
	var opts := []
	for k in 3:
		var right := "locked"
		if k < done:
			right = "%dc" % m.rewards[k]
		elif k == done:
			right = "%dc x2" % m.rewards[k]
		opts.append({"text": "Tier " + ROMAN[k], "enabled": k <= done, "right": right})
	var menu := Menu.make(self, opts, Vector2(118, 68), Vector2(96, 37))
	menu.index = mini(done, 2)
	menu.set_entries(opts)
	var r := await menu.ask()
	menu.queue_free()
	return r


# --------------------------------------------------------------- drills ---

static func reward(module: String, tier: int) -> int:
	## First clear of a tier pays double.
	var base: int = Data.TRAINING[module].rewards[tier]
	return base * 2 if Game.training_level(module) <= tier else base


static func build(module: String, tier: int) -> Dictionary:
	## A drill as Protektor mission data: timed spawn_enemy events plus the
	## usual all_enemies_destroyed completion trigger.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(module) + tier * 101
	var counts := {"block": [10, 16, 22], "shoot": [8, 12, 16], "combo": [12, 18, 24]}
	var gaps := {"block": [2.2, 1.5, 1.05], "shoot": [2.6, 1.9, 1.4], "combo": [2.0, 1.5, 1.1]}
	var pools := {
		"block": [["asteroid_slow"], ["asteroid"], ["asteroid", "asteroid"]],
		"shoot": [["drone_basic"], ["drone_basic", "drone_sine"], ["drone_basic", "drone_sine", "drone_fast", "drone_shifter"]],
		"combo": [["asteroid_slow", "drone_basic"], ["asteroid", "drone_basic", "charger_drone", "drone_sine"],
			["asteroid", "drone_basic", "charger_drone", "drone_tank", "drone_fast", "circle_shooter_drone"]],
	}
	var events := [{"id": "sim_start", "type": "fx_async_message", "time": 0.3, "text": "Simulation start.", "type_speed_cps": 30, "hold_sec": 1.2}]
	var t := 2.0
	var n: int = counts[module][tier]
	for i in n:
		var pool: Array = pools[module][tier]
		var kind: String = pool[i % pool.size()] if module == "combo" else pool[rng.randi() % pool.size()]
		var deg := (i * 45) % 360 if tier == 0 else (rng.randi_range(0, 7) * 45 if tier == 1 else rng.randi_range(0, 359))
		var e := {"id": "sim_%d" % i, "type": "spawn_enemy", "time": t, "enemy_type": kind, "spawn_side": "degrees", "degrees": deg}
		if module == "block" and tier == 2 and i % 5 == 4:
			e["move_speed"] = 360
		events.append(e)
		# the last tier of blocking and combined throws pairs from opposite sides
		if tier == 2 and module != "shoot" and i % 4 == 3:
			var twin := e.duplicate()
			twin.id = "sim_%d_b" % i
			twin.degrees = (deg + 180) % 360
			twin.enemy_type = "asteroid"
			events.append(twin)
		t += float(gaps[module][tier]) * rng.randf_range(0.85, 1.15)
	events.append({"id": "sim_done", "type": "fx_async_message", "trigger": {"type": "all_enemies_destroyed", "repeat": false, "params": {}},
		"text": "Simulation complete.", "type_speed_cps": 30, "hold_sec": 1.5})
	var m: Dictionary = Data.TRAINING[module]
	return {"format_version": 1, "level_id": "training_%s_%d" % [module, tier + 1], "planet_type": "training", "level_index": tier + 1,
		"header": {"planet_name": "%s %s" % [m.short, ROMAN[tier]], "planet_texture": m.tex, "music": {"file_path": "res://music/academy_battle.mp3"}},
		"events": events, "reward": reward(module, tier)}
