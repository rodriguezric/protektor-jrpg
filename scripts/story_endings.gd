class_name StoryEndings
extends RefCounted
## The five endings (endings/*.ending.json), staged as walking scenes, an escape
## run, and painted vignettes.

var s: Story
var kind := ""


func _init(p_s: Story) -> void:
	s = p_s


func play(type: String) -> void:
	kind = type
	Game.complete_story(type)
	match type:
		"partial_pala", "partial_parents":
			await _escape_walk()
		"full_synchronization":
			await _full_sync()
		"full_synchronization_parents":
			await _full_sync_parents()
		"ascended":
			await _ascended()
		_:
			await _full_sync()


# ----------------------------------------------------------- escape route --

func _escape_walk() -> void:
	var m = s.m
	await m.fade_out(0.8)
	Sfx.stop_music(0.5)
	var mp := Maps.launch_wing()
	if kind == "partial_pala":
		mp.npcs = [{"id": "pala", "who": "pala", "tile": Vector2i(3, 4), "dir": 2, "ghost": true}]
	m.load_map(mp, Vector2i(2, 3), 2)
	s.w.busy = true
	Sfx.music("claustrophobia_1", 1.0)
	await m.fade_in(0.8)
	if kind == "partial_pala":
		await s.say("", "You and Pala slip beneath the launch wing before the alarms can name you.")
		await s.say("pala", "Stay low. Follow the cold air. The shuttle's at the end.", "anxious")
	else:
		await s.say("", "The maintenance transport is a rumour with a door. Your parents' voice said the end of the service route.")
	s.w.show_marker(Vector2i(23, 3))
	s.w.busy = false
	if kind == "partial_pala":
		_follow()
	_alarms()


func _follow() -> void:
	var pala := s.a("pala")
	pala.scripted = true
	var trail: Array = []
	while is_instance_valid(pala) and is_instance_valid(s.w) and s.w.def.id == "launch_wing":
		trail.append(s.w.player.position)
		if trail.size() > 22:
			var p: Vector2 = trail.pop_front()
			if pala.position.distance_to(p) > 0.5:
				pala.face_toward(p)
				pala.moving = true
				pala.position = pala.position.move_toward(p, 2.0)
			else:
				pala.moving = false
		await s.m.get_tree().process_frame


func _alarms() -> void:
	await s.wait(4.0)
	while is_instance_valid(s.w) and s.w.def.id == "launch_wing":
		Sfx.play("alarm", 1.0, -14.0)
		s.w.tint.color = Color(0.7, 0.35, 0.45)
		await s.wait(0.4)
		if not is_instance_valid(s.w):
			return
		s.w.tint.color = Color(0.45, 0.42, 0.6)
		await s.wait(1.4)


func trigger(id: String) -> void:
	if id != "shuttle":
		return
	var m = s.m
	s.w.hide_marker()
	Sfx.play("heavy_door", 1.2, -4.0)
	if kind == "partial_pala":
		await s.say("pala", "Go! Go!", "anxious")
	await m.fade_out(0.5)
	var esc := Escape.new()
	m.cine_layer.add_child(esc)
	await m.fade_in(0.4)
	await esc.run()
	await m.fade_out(0.8)
	esc.queue_free()
	if m.world:
		m.world.queue_free()
		m.world = null
	if kind == "partial_pala":
		await _vignette_remote(["pala"], ["A supply shuttle carries you beyond Helion space.", "Far from the Academy, quiet no longer feels like an order.",
			"You do not know whether the life ahead will be safe. Only that it will be yours."], "pala_conversation")
	else:
		await _vignette_remote(["mother", "father"], ["Your parents are waiting beyond the Academy perimeter.", "A supply shuttle carries the three of you beyond Helion space.",
			"For the first time in years, their voices are beside you instead of coming through a monitored channel.",
			"Survival begins somewhere beyond the Academy's reach. Whatever comes next, you face it together."], "good_ending")


func _vignette_remote(people: Array, pages: Array, music: String) -> void:
	var m = s.m
	var c := Cinema.open()
	Sfx.music(music, 2.0)
	c.animate_bg("remote", 2, 1.2)
	c.effect = "embers"
	c.effect_k = 0.25
	var x := 150.0
	var me := c.person(Game.player_spec(), Vector2(x, 154), 2, "smile")
	for i in people.size():
		var who: String = people[i]
		var sp := c.person(Game.cast(who), Vector2(x - 20 - i * 18, 154), 2, "smile")
		sp.set_meta("bob", 0.6)
		sp.set_meta("y", sp.position.y)
		sp.set_meta("ph", i * 1.3)
	await m.fade_in(1.4)
	for p in pages:
		await s.say("", p)
	await _end_card(c)


# ------------------------------------------------------------ full sync ----

func _full_sync() -> void:
	var m = s.m
	await m.fade_out(1.0)
	if m.world:
		m.world.queue_free()
		m.world = null
	var c := Cinema.open()
	Sfx.music("low_sync_hum", 2.0)
	c.animate_bg("chamber", 5, 3.0)
	var kid := c.person(Game.player_spec(), Vector2(160, 128), 0, "hollow")
	kid.modulate = Color(0.7, 1.0, 1.05, 0.9)
	var pct := Art.shadow_label("SYNCHRONIZATION 0%", Pal.SYNC)
	pct.position = Vector2(110, 20)
	c.add_child(pct)
	await m.fade_in(1.6)
	var tw := c.create_tween()
	tw.tween_method(func(v: float) -> void: pct.text = "SYNCHRONIZATION %d%%" % int(v), float(Game.sync_percent()), 100.0, 4.0)
	await s.say("", "Synchronization reaches one hundred percent.")
	await tw.finished
	Sfx.play("sync", 0.8, -4.0)
	await s.say("", "The last boundary between your thought and the Protektor disappears.")
	var ct := c.create_tween()
	ct.tween_property(kid, "modulate:a", 0.0, 2.5)
	await s.say("", "Helion records a successful pilot cycle. Every protected world remains secure.")
	pct.text = "SYNCHRONIZATION --"
	var spec: Dictionary = Data.EXTRAS[Game.rng.randi() % Data.EXTRAS.size()].duplicate()
	spec.id = "next_child"
	spec.erase("badge")
	var nxt := c.person(spec, Vector2(-10, 160), 2)
	c.create_tween().tween_property(nxt, "position:x", 120.0, 3.0)
	await s.say("", "By morning, the chamber is quiet. The Protektor is ready for a new child.")
	await _end_card(c)


func _full_sync_parents() -> void:
	var m = s.m
	await m.fade_out(1.0)
	if m.world:
		m.world.queue_free()
		m.world = null
	var c := Cinema.open()
	await m.fade_in(1.2)
	Sfx.stop_music(1.0)
	await s.say("", ["As far as I can remember, I have always had good direction. My teachers often talked of values and how they make a person.",
		"I took to this idea well. It's hard to recall my time as a student, despite what I believe I retained from those years.",
		"The fogginess of that time is not a burden."])
	Sfx.music("midas_death", 2.5)
	await c.show_bg("cradle", 0, 3.0)
	var kid := c.person(Game.player_spec(), Vector2(160, 112), 0, "hollow", "walk")
	kid.rotation = -PI / 2
	var mom := c.person(Game.cast("mother"), Vector2(124, 140), 2, "cry")
	var dad := c.person(Game.cast("father"), Vector2(198, 140), 3, "sad")
	await s.say("", ["I have been on many missions. My role as a pilot is appreciated and a difficult one I am told.",
		"Family members have sent letters, but I do not recall their faces. They often tell me how proud they are that I've made it this far.",
		"It is said that you should miss your family when you are on missions, but this I cannot understand.",
		"Piloting such a large device requires my full attention. Coordinating my thoughts and intuition, I can see the patterns of my targets.",
		"This ensures that the planet I protect is safe. It is documented that a lot of time passes on each of my missions, but their passing feels fleeting to me.",
		"I am told this is my last mission and that I will be reunited with my family, that they anticipate seeing me. I believe this is a good thing.",
		"Perhaps they can show me what I looked like when I was young. All I know is space and the intricacies of its movement. People are a mystery to me.",
		"This last mission felt long even for me. I can no longer control the system.",
		"People are approaching me. I can hear them but can't say a word. My limbs are motionless."])
	mom.position.x += 6
	dad.texture = Art.person(Game.cast("father"), 2, 0, "cry")
	dad.flip_h = true
	await s.say("", "What is that leaking from their eyes? Are they defective?")
	await _end_card(c)


func _ascended() -> void:
	var m = s.m
	await m.fade_out(1.0)
	if m.world:
		m.world.queue_free()
		m.world = null
	var c := Cinema.open()
	Sfx.music("hiro_theme", 2.0)
	await c.show_bg("ascend", 0, 0.0)
	c.effect = "stars"
	c.effect_k = 0.6
	var mech := c.sprite(Art.prop("mech", 0), Vector2(160, 150))
	mech.modulate = Color(0.85, 1.0, 1.1)
	await m.fade_in(2.0)
	await s.say("", ["The last threat falls beyond the horizon. The world beneath you is safe.", "You wait for the sensation of returning to your body. Nothing returns."])
	c.create_tween().tween_property(mech, "position:y", 70.0, 8.0).set_trans(Tween.TRANS_SINE)
	await s.say("", ["There is no cockpit now. No hands. No boundary between your thoughts and the Protektor.",
		"You feel every storm crossing the planet, every signal rising from its cities, every orbit opening above you."])
	c.create_tween().tween_property(mech, "scale", Vector2(0.3, 0.3), 5.0)
	c.effect = "warp"
	c.effect_k = 0.25
	await s.say("", "The Academy can no longer contain what you have become. For the first time, the stars do not look distant.")
	await _end_card(c)


# ------------------------------------------------------------- the end ----

func _end_card(c: Cinema) -> void:
	var m = s.m
	var names := {"partial_pala": "Partial Synchronization - With Pala", "partial_parents": "Partial Synchronization - With Parents",
		"full_synchronization": "Full Synchronization", "full_synchronization_parents": "Full Synchronization - With Parents", "ascended": "Ascended"}
	var dim := ColorRect.new()
	dim.color = Color(Pal.INK, 0.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(dim)
	await c.create_tween().tween_property(dim, "color:a", 0.75, 1.6).finished
	var t := Art.shadow_label("THE END", Pal.TEXT, 3)
	t.position = Vector2(160 - Art.text_width("THE END", 3) / 2.0, 60)
	t.modulate.a = 0.0
	c.add_child(t)
	var sub := Art.shadow_label(names.get(kind, kind), Pal.SYNC)
	sub.position = Vector2(160 - Art.text_width(sub.text) / 2.0, 98)
	sub.modulate.a = 0.0
	c.add_child(sub)
	c.create_tween().tween_property(t, "modulate:a", 1.0, 1.5)
	await c.create_tween().tween_property(sub, "modulate:a", 1.0, 1.5).set_delay(0.8).finished
	var seen := Art.label("Endings seen: %d" % _endings_seen(), Pal.TEXT_DIM)
	seen.position = Vector2(160 - Art.text_width(seen.text) / 2.0, 112)
	c.add_child(seen)
	var press := Art.shadow_label("Press Z", Pal.TEXT)
	press.position = Vector2(160 - Art.text_width("Press Z") / 2.0, 150)
	c.add_child(press)
	while not Input.is_action_just_pressed("accept"):
		press.visible = fmod(Time.get_ticks_msec() / 1000.0, 1.0) < 0.65
		await m.get_tree().process_frame
	Sfx.play("confirm")
	Sfx.stop_music(2.0)
	await m.fade_out(1.5)
	c.queue_free()
	m.title()


func _endings_seen() -> int:
	var kinds := {}
	for h in Game.history:
		kinds[h.get("ending", "")] = true
	return kinds.size()


func talk(_n: Actor) -> void:
	await s.say("pala", "Not now. Keep moving.", "anxious")


func examine(_ev: Dictionary) -> void:
	await s.say("", "Crates. Cold air. The hum of engines somewhere ahead.")
