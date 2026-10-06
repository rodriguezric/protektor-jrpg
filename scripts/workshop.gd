class_name Workshop
extends Control
## The engineering terminal in the Commons: spend credits on the Protektor.
## Basic upgrades (cooldown, red integrity, stabilizers) are priced for
## training; specials and weapons need mission money and mission experience.
## Weapons are unlocked once and then equipped one at a time.

var rows: Array = []
var menu: Menu
var credits_l: Label
var shown_credits := 0.0
var d_name: Label
var d_desc: Label
var d_stat: Label
var preview: Node2D
var fx: Fx
var t := 0.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("14111c")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var grid := Node2D.new()
	grid.draw.connect(func() -> void:
		for x in range(0, 320, 16):
			grid.draw_line(Vector2(x, 0), Vector2(x, 180), Color(Pal.HONEY, 0.06), 1.0)
		for y in range(0, 180, 16):
			grid.draw_line(Vector2(0, y), Vector2(320, y), Color(Pal.HONEY, 0.06), 1.0))
	add_child(grid)
	var tb := Art.make_box("bar_box")
	tb.position = Vector2(6, 4)
	tb.size = Vector2(150, 16)
	add_child(tb)
	var tl := Art.label("PROTEKTOR ENGINEERING", Pal.LEMON)
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
	shown_credits = Game.credits()
	var db := Art.make_box("box")
	db.position = Vector2(196, 24)
	db.size = Vector2(118, 152)
	add_child(db)
	preview = Node2D.new()
	preview.position = Vector2(59, 30)
	preview.draw.connect(_draw_preview)
	db.add_child(preview)
	d_name = Art.label("", Pal.TEXT)
	d_name.position = Vector2(6, 54)
	db.add_child(d_name)
	d_desc = Label.new()
	d_desc.position = Vector2(6, 66)
	d_desc.size = Vector2(106, 50)
	d_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d_desc.add_theme_color_override("font_color", Pal.TEXT_DIM)
	db.add_child(d_desc)
	d_stat = Label.new()
	d_stat.position = Vector2(6, 128)
	d_stat.size = Vector2(106, 22)
	d_stat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d_stat.add_theme_color_override("font_color", Pal.SYNC)
	db.add_child(d_stat)
	fx = Fx.new()
	add_child(fx)


func _process(delta: float) -> void:
	t += delta
	var c := float(Game.credits())
	if absf(shown_credits - c) > 0.5:
		shown_credits = move_toward(shown_credits, c, maxf(30.0, absf(c - shown_credits) * 6.0) * delta)
	else:
		shown_credits = c
	credits_l.text = str(int(shown_credits))
	preview.queue_redraw()


# ----------------------------------------------------------------- rows ---

func _build_rows() -> Array:
	var out := []
	var missions := Game.completed_count()
	out.append({"kind": "header", "text": "-- PROTEKTOR --"})
	for id in ["cooldown", "armor"]:
		var u: Dictionary = Data.UPGRADES[id]
		var lv := Game.upgrade_level(id)
		var maxed: bool = lv >= int(u.max)
		out.append({"kind": "upgrade", "id": id, "text": "%s %d/%d" % [u.name, lv, u.max],
			"right": "MAX" if maxed else "%dc" % u.costs[lv], "cost": 0 if maxed else int(u.costs[lv]), "done": maxed})
	var med: Dictionary = Data.UPGRADES.medicine
	out.append({"kind": "medicine", "id": "medicine", "text": "%s x%d" % [med.name, int(Game.story.get("medicine", 0))], "right": "%dc" % med.cost, "cost": int(med.cost)})
	if int(Game.story.get("medicine", 0)) > 0 and int(Game.story.missions_failed) > 0:
		out.append({"kind": "use_med", "id": "medicine", "text": "  Take a stabilizer now", "right": "", "cost": 0})
	out.append({"kind": "header", "text": "-- SPECIALS --"})
	for id in ["ext_shield", "missile"]:
		var sp: Dictionary = Data.SPECIALS[id]
		var owned := Game.has_special(id)
		var locked: bool = missions < int(sp.missions)
		out.append({"kind": "special", "id": id, "text": sp.name, "cost": int(sp.cost), "locked": locked, "done": owned,
			"right": "OWNED" if owned else ("%d missions" % sp.missions if locked else "%dc" % sp.cost)})
	out.append({"kind": "header", "text": "-- WEAPON --"})
	for id in ["basic", "wave", "beam", "auto"]:
		var w: Dictionary = Data.WEAPONS[id]
		var owned := Game.has_weapon(id)
		var locked: bool = missions < int(w.missions)
		var right := ""
		if Game.equipped_weapon() == id:
			right = "EQUIPPED"
		elif owned:
			right = "equip"
		elif locked:
			right = "%d missions" % w.missions
		else:
			right = "%dc" % w.cost
		out.append({"kind": "weapon", "id": id, "text": w.name, "cost": int(w.cost), "locked": locked and not owned, "owned": owned, "right": right})
	out.append({"kind": "leave", "text": "Leave", "right": ""})
	return out


func _entries() -> Array:
	var e := []
	for r in rows:
		var enabled := true
		if r.kind == "header":
			enabled = false
		elif r.get("locked", false) or (r.get("done", false) and r.kind != "weapon"):
			enabled = false
		elif r.get("cost", 0) > Game.credits() and not r.get("owned", false) and r.kind != "use_med":
			enabled = false
		e.append({"text": r.text, "right": r.get("right", ""), "enabled": enabled})
	return e


func _describe(i: int) -> void:
	var r: Dictionary = rows[i]
	var name := ""
	var desc := ""
	var stat := ""
	match r.kind:
		"upgrade":
			var u: Dictionary = Data.UPGRADES[r.id]
			name = u.name
			desc = u.desc
			if r.id == "cooldown":
				var lv := Game.upgrade_level("cooldown")
				stat = "Cooldown %.2fs" % Data.FIRE_COOLDOWN[lv] + ("" if lv >= 3 else " -> %.2fs" % Data.FIRE_COOLDOWN[lv + 1])
			else:
				stat = "Red cells %d" % Game.upgrade_level("armor") + ("" if Game.upgrade_level("armor") >= 3 else " -> %d" % (Game.upgrade_level("armor") + 1))
		"medicine", "use_med":
			name = Data.UPGRADES.medicine.name
			desc = Data.UPGRADES.medicine.desc
			stat = "Failed deployments: %d/3" % int(Game.story.missions_failed)
		"special":
			name = Data.SPECIALS[r.id].name
			desc = Data.SPECIALS[r.id].desc
			stat = "Needs %d missions (you have %d)" % [Data.SPECIALS[r.id].missions, Game.completed_count()] if r.locked else ""
		"weapon":
			name = Data.WEAPONS[r.id].name
			desc = Data.WEAPONS[r.id].desc
			var st: Dictionary = Mission.WEAPON_STATS[r.id]
			stat = "Damage %d  Max %d in flight" % [int(st.dmg), int(st.max)]
			if r.locked:
				stat = "Needs %d missions (you have %d)" % [Data.WEAPONS[r.id].missions, Game.completed_count()]
		"leave":
			name = "Leave"
			desc = "Step away from the terminal."
	d_name.text = name
	d_desc.text = desc
	d_stat.text = stat
	preview.set_meta("row", r)


func _draw_preview() -> void:
	## A little Protektor diagram: planet, shield, and what's selected.
	var r: Dictionary = preview.get_meta("row", {})
	var tex := Art.planet("green_planet", 16, int(t * 5.0))
	preview.draw_texture(tex, Vector2(-10, -10))
	var ext: bool = Game.has_special("ext_shield") or r.get("id", "") == "ext_shield"
	var rr := 16.0 if ext else 11.0
	for k in 24:
		var a := PI * 0.5 + k * PI / 23.0
		preview.draw_rect(Rect2((Vector2(cos(a), sin(a)) * rr).round(), Vector2.ONE), Color(Pal.SYNC, 0.8))
	var w: String = r.get("id", Game.equipped_weapon()) if r.get("kind", "") == "weapon" else Game.equipped_weapon()
	var phase := fmod(t * 1.2, 1.0)
	var y := -14.0 - phase * 14.0
	match w:
		"wave":
			for k in range(-5, 6):
				preview.draw_rect(Rect2(Vector2(k, y + k * k * 0.09).round(), Vector2.ONE), Pal.SYNC)
		"beam":
			preview.draw_line(Vector2(0, y), Vector2(0, y + 9), Pal.WHITE, 1.0)
		"auto":
			for k in 4:
				preview.draw_rect(Rect2(Vector2(-1, y + k * 5), Vector2(2, 2)), Pal.LEMON)
		_:
			preview.draw_rect(Rect2(Vector2(-1, y), Vector2(3, 3)), Pal.LEMON)
	if Game.has_special("missile") or r.get("id", "") == "missile":
		var a2 := t * 2.0
		preview.draw_rect(Rect2((Vector2(cos(a2), sin(a2)) * 22.0).round(), Vector2(2, 2)), Pal.EMBER)


# ------------------------------------------------------------------ run ---

func run() -> void:
	Sfx.play("beep", 0.9, -6.0)
	if bool(Game.story.get("stripped", false)):
		var note := Art.label("STRIPPED PLAYTHROUGH: upgrades stay offline in deployments.", Pal.BLOOD.lerp(Pal.WHITE, 0.3))
		note.position = Vector2(6, 168)
		add_child(note)
	rows = _build_rows()
	menu = Menu.make(self, _entries(), Vector2(6, 24), Vector2(186, rows.size() * 10 + 7))
	menu.moved.connect(_describe)
	menu.index = 1
	menu.set_entries(_entries())
	while true:
		var i := await menu.ask()
		if i < 0 or rows[i].kind == "leave":
			break
		await _act(rows[i], i)
		rows = _build_rows()
		var keep := menu.index
		menu.size.y = rows.size() * 10 + 7
		menu.set_entries(_entries())
		menu.index = clampi(keep, 0, rows.size() - 1)
		_describe(menu.index)
	Sfx.play("cancel")


func _act(r: Dictionary, i: int) -> void:
	var where := menu.position + Vector2(menu.size.x - 20, 8 + i * 10)
	match r.kind:
		"upgrade":
			if Game.spend(r.cost):
				Game.story.upgrades[r.id] = Game.upgrade_level(r.id) + 1
				Game.save()
				_bought(where, "UPGRADED")
		"medicine":
			if Game.spend(r.cost):
				Game.story.medicine = int(Game.story.get("medicine", 0)) + 1
				Game.save()
				_bought(where, "+1")
		"use_med":
			if Game.use_medicine():
				Sfx.play("sync", 1.3, -6.0)
				_burst(where, Pal.GLOW)
				_popup(where, "CLEARED", Pal.GLOW)
		"special":
			if Game.spend(r.cost):
				Game.story.specials.append(r.id)
				Game.save()
				_bought(where, "INSTALLED")
		"weapon":
			if r.owned:
				Game.set_weapon(r.id)
				Sfx.play("plate", 1.2, -6.0)
				_burst(where, Pal.SYNC)
			elif Game.spend(r.cost):
				Game.story.weapons.append(r.id)
				Game.set_weapon(r.id)
				_bought(where, "EQUIPPED")


func _bought(p: Vector2, text: String) -> void:
	Game.story.bought = true
	Game.save()
	Achievements.check()
	Sfx.play("buy", 1.0, -4.0)
	_burst(p, Pal.LEMON)
	_popup(p, text, Pal.LEMON)
	credits_l.scale = Vector2(1.3, 1.3)
	create_tween().tween_property(credits_l, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)


func _burst(p: Vector2, c: Color) -> void:
	fx.burst(p, 16, [c, Pal.WHITE, Pal.HONEY], Vector2(30, 90), Vector2(0.2, 0.5), {"up": 30.0, "acc": Vector2(0, 100)})
	fx.ring(p, 2, 14, 0.3, c, 1.0, 1.0)


func _popup(p: Vector2, text: String, c: Color) -> void:
	var l := Art.shadow_label(text, c)
	l.position = p + Vector2(-Art.text_width(text), -6)
	add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 12, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.4).set_delay(0.3)
	tw.tween_callback(l.queue_free)
