class_name SlotScreen
extends Control
## Pick one of the three save slots. mode "load" only allows slots you can
## resume; mode "new" allows any, and the title asks before overwriting.
## run() returns the slot number, or 0 when cancelled.

const CHAPTERS := {"prologue": "Prologue: Home", "academy": "Chapter 1: The Academy", "briefing": "Chapter 2: First Deployment",
	"hub": "Chapter 2: The Commons", "done": "Story complete"}

var mode := "load"
var sel := 0
var t := 0.0
var cards: Array = []
var infos: Array = []
var cursor: TextureRect


func setup(p_mode: String) -> void:
	mode = p_mode
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = Art.space(320, 180, "green_planet")
	bg.modulate = Color(0.75, 0.75, 0.85)
	add_child(bg)
	var tb := Art.make_box("sys_box")
	tb.position = Vector2(6, 4)
	tb.size = Vector2(120, 16)
	add_child(tb)
	var tl := Art.label("NEW GAME - CHOOSE SLOT" if mode == "new" else "LOAD GAME", Pal.SYNC)
	tl.position = Vector2(5, 3)
	tb.add_child(tl)
	var help := Art.label("Z choose  X back", Pal.TEXT_DIM)
	help.position = Vector2(232, 7)
	add_child(help)
	for n in range(1, Game.SLOTS + 1):
		var info := Game.slot_info(n)
		infos.append(info)
		var card := _card(n, info)
		card.position = Vector2(14, 26 + (n - 1) * 50)
		add_child(card)
		cards.append(card)
		card.modulate.a = 0.0
		card.create_tween().tween_property(card, "modulate:a", 1.0, 0.2).set_delay(0.08 * n)
	cursor = TextureRect.new()
	cursor.texture = Art.ui("cursor")
	add_child(cursor)
	sel = maxi(0, Game.most_recent_slot() - 1) if mode == "load" else 0
	if mode == "load" and not _usable(sel):
		for i in Game.SLOTS:
			if _usable(i):
				sel = i
				break


func _usable(i: int) -> bool:
	if mode == "new":
		return true
	var info: Dictionary = infos[i]
	return not info.is_empty() and info.chapter != "done"


func _card(n: int, info: Dictionary) -> Control:
	var c := Control.new()
	c.size = Vector2(292, 46)
	var box := Art.make_box("box" if not info.is_empty() else "bar_box")
	box.size = c.size
	c.add_child(box)
	var num := Art.shadow_label("%d" % n, Pal.LEMON, 2)
	num.position = Vector2(8, 12)
	c.add_child(num)
	if info.is_empty():
		var e := Art.label("- Empty Slot -", Pal.TEXT_DIM)
		e.position = Vector2(146 - Art.text_width(e.text) / 2.0, 18)
		c.add_child(e)
		return c
	var spec: Dictionary = Data.LOOKS[clampi(int(info.look), 0, Data.LOOKS.size() - 1)].duplicate()
	spec.merge({"id": "slot%d" % n, "top": Pal.ROSE.lerp(Pal.SLATE, 0.35), "hood": true, "hoodc": Pal.ROSE.lerp(Pal.SLATE, 0.2),
		"jacket": Data.JACKET, "bottom": Pal.INK2, "badge": info.chapter != "prologue", "variant": "slot"})
	var pic := TextureRect.new()
	pic.texture = Art.portrait(spec, "", false, false, 2)
	pic.position = Vector2(28, -1)
	c.add_child(pic)
	var nm := Art.label(info.name, Pal.TEXT)
	nm.position = Vector2(80, 4)
	c.add_child(nm)
	var ch := Art.label(CHAPTERS.get(info.chapter, info.chapter), Pal.SYNC)
	ch.position = Vector2(80, 16)
	c.add_child(ch)
	var stats := "Missions %d   Credits %d" % [info.missions, info.credits]
	if info.stripped:
		stats += "   STRIPPED"
	var st := Art.label(stats, Pal.TEXT_DIM)
	st.position = Vector2(80, 28)
	c.add_child(st)
	if int(info.saved_at) > 0:
		var dt := Time.get_datetime_dict_from_unix_time(int(info.saved_at))
		var when := Art.label("%04d-%02d-%02d %02d:%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute], Pal.TEXT_DIM)
		when.position = Vector2(284 - Art.text_width(when.text), 4)
		c.add_child(when)
	if not _usable(n - 1):
		c.modulate = Color(0.6, 0.6, 0.7)
	return c


func _process(delta: float) -> void:
	t += delta
	for i in cards.size():
		var c: Control = cards[i]
		var target_x := 14.0 + (6.0 if i == sel else 0.0)
		c.position.x = lerpf(c.position.x, target_x, minf(1.0, delta * 14.0))
	var cc: Control = cards[sel]
	cursor.position = Vector2(cc.position.x - 9 - (1 if fmod(t, 0.5) < 0.25 else 0), cc.position.y + 19)


func run() -> int:
	await get_tree().process_frame
	while true:
		await get_tree().process_frame
		var old := sel
		if Input.is_action_just_pressed("down"):
			sel = (sel + 1) % Game.SLOTS
		elif Input.is_action_just_pressed("up"):
			sel = (sel - 1 + Game.SLOTS) % Game.SLOTS
		elif Input.is_action_just_pressed("cancel"):
			Sfx.play("cancel")
			return 0
		elif Input.is_action_just_pressed("accept"):
			if not _usable(sel):
				Sfx.play("miss")
				continue
			Sfx.play("confirm")
			var c: Control = cards[sel]
			c.pivot_offset = c.size / 2.0
			c.scale = Vector2(1.04, 1.04)
			create_tween().tween_property(c, "scale", Vector2.ONE, 0.15)
			return sel + 1
		if old != sel:
			Sfx.play("blip")
	return 0
