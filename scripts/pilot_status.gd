class_name PilotStatus
extends Control
## The field menu: Pilot Status HUD from the design doc (synchronization,
## emotional stability, physical condition, neural fatigue) plus your bonds.
## The readout glitches more the further you are synchronized.

var bars := []
var labels := []
var t := 0.0
var glitch := 0.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(Pal.INK, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var sync := Game.sync_percent()
	glitch = clampf((sync - 45) / 50.0, 0.0, 1.0)
	var box := Art.make_box("sys_box")
	box.position = Vector2(80, 6)
	box.size = Vector2(234, 168)
	add_child(box)
	var pic := TextureRect.new()
	pic.texture = Art.portrait(Game.player_spec(), "flat" if sync >= 55 else "")
	pic.position = Vector2(6, 6)
	box.add_child(pic)
	var nm := Art.label(Game.player_name, Pal.TEXT)
	nm.position = Vector2(60, 6)
	box.add_child(nm)
	var st := Art.label("Stage: " + Game.stage_name(), Pal.SYNC)
	st.position = Vector2(60, 17)
	box.add_child(st)
	labels.append(st)
	var ms := Art.label("Missions %d   Failed %d" % [Game.completed_count(), int(Game.story.missions_failed)], Pal.TEXT_DIM)
	ms.position = Vector2(60, 28)
	box.add_child(ms)
	var stats := [
		["SYNCHRONIZATION", sync, Pal.SYNC],
		["EMOTIONAL STABILITY", clampi(100 - sync + Game.relationship("pala") * 6 + Game.home_contacts() * 6 + Game.relationship("midas") * 5, 4, 100), Pal.GLOW],
		["PHYSICAL CONDITION", clampi(96 - Game.completed_count() * 3 - int(Game.story.missions_failed) * 6, 8, 100), Pal.LEMON],
		["NEURAL FATIGUE", clampi(10 + Game.completed_count() * 4 + Game.relationship("hiro") * 5, 0, 100), Pal.BLOOD],
	]
	for i in stats.size():
		var y := 58 + i * 15
		var l := Art.label(stats[i][0], Pal.TEXT_DIM)
		l.position = Vector2(8, y)
		box.add_child(l)
		labels.append(l)
		var bb := ColorRect.new()
		bb.color = Pal.INK
		bb.position = Vector2(110, y + 2)
		bb.size = Vector2(90, 6)
		box.add_child(bb)
		var f := ColorRect.new()
		f.color = stats[i][2]
		f.position = Vector2(111, y + 3)
		f.size = Vector2(0, 4)
		box.add_child(f)
		create_tween().tween_property(f, "size:x", 88.0 * stats[i][1] / 100.0, 0.5).set_delay(0.08 * i).set_trans(Tween.TRANS_SINE)
		var v := Art.label("%d%%" % stats[i][1], Pal.TEXT)
		v.position = Vector2(204, y)
		box.add_child(v)
		bars.append(f)
	var bonds := Art.label("BONDS", Pal.TEXT_DIM)
	bonds.position = Vector2(8, 122)
	box.add_child(bonds)
	var who := [["Hiro", "hiro"], ["Pala", "pala"], ["Midas", "midas"], ["Home", "home"]]
	for i in who.size():
		var x := 8 + i * 56
		var l := Art.label(who[i][0], Pal.TEXT)
		l.position = Vector2(x, 134)
		box.add_child(l)
		var n := Game.home_contacts() if who[i][1] == "home" else Game.relationship(who[i][1])
		var gone: bool = (who[i][1] == "midas" and Game.midas_dead()) or (who[i][1] == "pala" and bool(Game.story.pala_unavailable))
		if gone:
			l.add_theme_color_override("font_color", Pal.TEXT_DIM)
		for h in 3:
			var hr := TextureRect.new()
			hr.texture = Art.ui("heart" if h < n and not gone else "heart_off")
			hr.position = Vector2(x + h * 9, 145)
			box.add_child(hr)


func _process(delta: float) -> void:
	t += delta
	if glitch > 0.0:
		for l in labels:
			l.position.x = (8 if l.position.x < 40 else 60) + (randi_range(-1, 1) if randf() < glitch * 0.15 else 0)
			l.modulate.a = 0.4 if randf() < glitch * 0.05 else 1.0


func run() -> String:
	var m := Menu.make(self, ["Close", "Controls", "Title"], Vector2(6, 6), Vector2(70, 37))
	while true:
		var r := await m.ask()
		if r == 1:
			await Game.main.dialog.say(["Arrows/WASD walk. Shift runs. Z talks, examines and confirms. X opens this menu.",
				"In a deployment, turn with the arrows, WASD, the mouse or a stick. Z, Space or left-click fires the beam from your FRONT.",
				"Your BACK raises the shield. Turn away from asteroids and enemy fire to block them. Drones must be shot.",
				"Esc pauses a deployment."], "", {"sys": true, "voice": "system"})
			continue
		if r == 2:
			var c: int = await Game.main.dialog.ask("Return to the title screen? Progress is saved at each interval.", ["Stay", "Return to title"], "", {"sys": true})
			if c == 1:
				return "title"
			continue
		break
	Sfx.play("cancel")
	return ""
