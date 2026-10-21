class_name StoryPrologue
extends RefCounted
## Chapter 0: the letter, the night before, the parade.
## (dialog/demo_intro_scene.dialog.json, Intro Scene Script Draft)

const EVENING := Color(0.85, 0.78, 0.82)

var s: Story
var evening := false
var letter_c: Cinema


func _init(p_s: Story) -> void:
	s = p_s


func start() -> void:
	s.save_at("prologue")
	var m = s.m
	# Establishing shot: the block at night through the kitchen window.
	var c := Cinema.open()
	c.animate_bg("city", 8, 3.0)
	var ship := c.sprite(Art.prop("shuttle", 0), Vector2(-60, 40))
	ship.modulate = Color(0.1, 0.1, 0.16)
	ship.scale = Vector2(0.5, 0.5)
	c.create_tween().tween_property(ship, "position:x", 380.0, 14.0)
	c.sprite(Art.cine("city_frame"), Vector2(160, 90))
	Sfx.music("letter_discussion", 2.0)
	await m.fade_in(1.4)
	await s.say("", ["Home is a narrow stack of rooms in Block 7: a kitchen and a living room below, bedrooms up a creaking staircase, and windows that make the whole block look cleaner than it is.",
		"Outside, transports drag shadows across the window while the shield grid pulses over the block in slow blue waves."])
	await m.fade_out(0.8)
	c.queue_free()
	var mp := Maps.home()
	mp.npcs = [
		{"id": "mother", "who": "mother", "tile": Vector2i(3, 7), "dir": 2},
		{"id": "father", "who": "father", "tile": Vector2i(6, 7), "dir": 3, "mood": ""},
	]
	m.load_map(mp, Vector2i(5, 9), 1)
	s.w.busy = true
	s.w.show_area_name()
	await m.fade_in(0.8)
	await s.say("", ["You know which stair creaks, where the heater stutters, where your mother keeps the good cups for visitors who never stay long.",
		"Tonight, even familiar things feel careful."])
	await s.say("", "Your parents stand in the kitchen. Your mother is holding a letter so tightly the fold has gone white.")
	s.w.prop_sprite("letter").visible = false
	Sfx.play("paper")
	await _letter_open()
	await s.say("mother", "\"We are pleased to inform you that your child has been selected for the Protektor Initiative.\"", "steady")
	await _letter_close()
	s.face_to("father", "mother")
	await s.say("father", "Selected.", "guarded")
	s.face("father", 3)
	await s.say("mother", "\"Participation ensures full nutritional support, medical coverage, and permanent housing allocation for immediate family.\"", "reading")
	await s.say("father", "They print the payment terms before the truth.", "skeptical")
	await s.say("mother", "\"Your child's contribution will directly ensure planetary survival.\"", "soft")
	s.face_to("mother", "player")
	s.face_to("father", "player")
	await s.say("you", "... Why are you reading it like that?")
	s.emote("mother", "sweat")
	await s.say("mother", "It is... an invitation.", "hesitant")
	await s.say("father", "A draft.", "flat")
	Sfx.play("paper", 0.8)
	s.a("mother").shake(0.3, 1.0)
	await s.say("mother", "\"Participation is voluntary.\"", "tired")
	await s.say("father", "Voluntary enough that the transit packet came in the same envelope.", "resigned")
	await s.pan(Vector2i(4, 3))
	var pk := s.w.prop_sprite("packet")
	var tw := pk.create_tween().set_loops(4)
	tw.tween_property(pk, "modulate", Color(1.6, 1.6, 1.4), 0.15)
	tw.tween_property(pk, "modulate", Color.WHITE, 0.15)
	await s.say("", "On the counter, beside the letter, a sealed travel packet is already stamped with your family name.")
	await s.pan_back()
	var r := await s.ask("What do you say?", ["Do I have to go?", "I can do it.", "(Stay silent)"])
	match r:
		0:
			Game.vars.letter_choice = "doubt"
			await s.say("you", "Do I have to go?", "worried")
			await s.say("father", "If they send a letter, they expect obedience. They only call it an answer.", "firm")
		1:
			Game.vars.letter_choice = "resolve"
			await s.say("you", "I can do it.")
			s.emote("mother", "heart")
			await s.say("mother", "We know you can. That is why they chose you.", "proud")
			await s.say("", "The words land too neatly, like something meant for a poster.")
		_:
			Game.vars.letter_choice = "silent"
			s.emote("player", "...")
			await s.say("", "You keep the question in.")
			await s.say("father", "Silence says you understand more than they hoped.", "stern")
	# Scene 0.2 -- parents talk
	s.face_to("mother", "father")
	await s.say("mother", "They say it is training first. An academy. As if a new word makes it gentler.", "")
	s.face_to("mother", "player")
	await s.say("you", "Will I come back?", "sad")
	await s.say("father", "Of course.", "reassuring")
	await s.say("mother", "Yes. Of course.", "insistent")
	await s.say("you", "When?")
	await s.say("father", "When they decide your part is done.", "measured")
	await s.say("mother", "After you protect us. After all of us can breathe easier.", "pleading")
	await s.say("", "No one said goodbye. That made it sound more like goodbye.")
	await m.fade_out(1.0)
	await _evening()


func _letter_open() -> void:
	letter_c = Cinema.open(Color(0, 0, 0, 0))
	letter_c.modulate.a = 0.0
	letter_c.show_tex(Art.cine("table"), 0.0)
	var l := letter_c.sprite(Art.cine("letter", 0), Vector2(160, 92), 1.0)
	l.set_meta("letter", true)
	await letter_c.create_tween().tween_property(letter_c, "modulate:a", 1.0, 0.5).finished


func _letter_close() -> void:
	if letter_c:
		await letter_c.close(0.5)
		letter_c = null


func _evening() -> void:
	var m = s.m
	evening = true
	Sfx.music("mellow_loop", 1.5)
	m.load_map(_house("home"), Vector2i(7, 8), 0)
	s.w.busy = true
	await m.fade_in(0.8)
	await s.say("", "Evening. Nobody mentions the letter again. It is still on the table.")
	await s.say("~", "I should go to bed. Tomorrow comes either way.")
	s.w.show_marker(Vector2i(21, 2))
	s.w.busy = false


func _house(id: String) -> Dictionary:
	## Either floor of home, set for the evening once it has come.
	var mp := Maps.home() if id == "home" else Maps.home_up()
	if evening:
		mp.tint = EVENING
		mp.music = "mellow_loop"
		if id == "home":
			mp.npcs = [
				{"id": "mother", "who": "mother", "tile": Vector2i(2, 3), "dir": 1},
				{"id": "father", "who": "father", "tile": Vector2i(18, 4), "dir": 1},
			]
	return mp


func exit(e: Dictionary) -> void:
	## The stairs between the floors.
	var to: String = e.get("to", "")
	if to != "home" and to != "home_up":
		return
	for i in 3:
		Sfx.play("step", 0.85 + i * 0.08, -16.0)
		await s.wait(0.09)
	await s.m.change_map(_house(to), e.tile, e.dir)
	if evening:
		s.w.show_marker(Vector2i(2, 2) if to == "home_up" else Vector2i(21, 2))


# ---------------------------------------------------------------- field ---

func talk(n: Actor) -> void:
	match n.info.get("id", ""):
		"mother":
			if s.w.def.id == "parade":
				return
			await s.say("mother", ["Did you eat? You should eat something.", "...I keep reading it. As if the words will change if I look long enough."], "tired")
		"father":
			if s.w.def.id == "parade":
				return
			await s.say("father", ["The shield's breathing slower tonight. They say that's normal.", "Get some sleep. I'll check the heater."], "flat")
		"hiro":
			await s.say("hiro", "Look at those things. Bet they hit harder than anything on this planet.", "still_smiling")
		"pala":
			await s.say("pala", "Their joints don't flex like armor. They flex like... something grown.", "anxious")
		"midas":
			await s.say("midas", "My mom's out there somewhere. I can't find her face.", "uneasy")
		"announcer":
			await s.say("announcer", "Recruits will hold formation until called!")
		_:
			var id: String = n.info.get("id", "")
			if id.begins_with("crowd"):
				var lines := ["We're so proud of you!", "Helion keeps us safe!", "Wave! Wave to us!", "My boy went up last spring. He writes every month."]
				await s.say("", "\"%s\"" % lines[id.hash() % lines.size()])
			elif id.begins_with("rec"):
				var lines2 := ["Don't step out of line. They're watching.", "My uniform's too big too.", "I heard you get your own Protektor.", "..."]
				await s.say("", "\"%s\"" % lines2[id.hash() % lines2.size()])
			else:
				await s.say("", "...")


func examine(ev: Dictionary) -> void:
	match ev.get("id", ""):
		"window":
			await s.say("", "The shield grid pulses over the block in slow blue waves. A transport slides across the stars and is gone.")
		"stove":
			await s.say("", "Something was cooking. Nobody finished it.")
		"fridge":
			await s.say("", "Magnets hold a ration schedule and a drawing you made years ago. A planet with a smile on it.")
		"heater":
			Sfx.play("knock", 0.6, -14.0)
			await s.say("", "The heater stutters, catches, stutters again. It has always done that.")
		"photo":
			await s.say("", "A family photo. Three faces squinting into the same bright afternoon.")
		"tv":
			await s.say("", ["The block screen loops tomorrow's parade rehearsal with the sound off.", "Every recruit on it is smiling. The camera never stays on one long enough to check."])
		"clock":
			await s.say("", "The wall clock runs four minutes fast. It has run four minutes fast your whole life, and nobody has ever fixed it.")
		"calendar":
			await s.say("", "The ration calendar. Tomorrow's square has been circled, and then the circle has been scribbled over.")
		"coats":
			await s.say("", "Your mother's coat, your father's work jacket, and the hook where yours hangs. It's empty. Your coat is already packed.")
		"radio":
			await s.say("", "The block radio, turned down low. A voice is reading the names of tomorrow's recruits, slowly enough to be a ceremony.")
		"couch":
			await s.say("", "The couch still has a dent where your father sits for the evening broadcast. Tonight he's standing.")
		"desk":
			await s.say("", ["Your desk. Drawings of planets with faces, a cup of worn-down pencils.", "Someone has squared the papers into a neat pile. It wasn't you."])
		"wardrobe":
			await s.say("", "Your wardrobe is half empty. The clothes that are left all suddenly feel too small.")
		"toy":
			await s.say("", "A plastic Protektor. You glued its arm back on years ago, and it has pointed slightly the wrong way ever since.")
		"bag":
			await s.say("", "A bag, packed and zipped, waiting by the door. You didn't pack it.")
		"parentsbed":
			await s.say("", "Your parents' bed, made tight at the corners. A book on your mother's side has the same page folded down as last week.")
		"dresser":
			await s.say("", "Your father's work badge: Block 7 Maintenance. The photo on it is younger than he is.")
		"tub":
			await s.say("", "The tub. The water runs warm for exactly four minutes, so everyone in this house showers fast.")
		"basin":
			await s.say("", ["Three toothbrushes in a cup. By tomorrow night there'll be two.", "In the mirror you try to look like someone a parade would be for."])
		"toilet":
			await s.say("", "The flush handle has to be held down for a count of three. You count without thinking.")
		"basket":
			await s.say("", "Laundry, folded. One of your shirts is on top, still warm. Somebody washed it so you'd have it tomorrow.")
		"drawings":
			await s.say("", "Your old drawings, taped along the hallway: a rocket, a dog you never had, the shield grid in blue crayon.")
		"table":
			await s.say("", ["The letter is still face down on the table. The Helion seal shows through the paper.", "You don't turn it over."])
		"packet":
			await s.say("", "A sealed travel packet, already stamped with your family name. It is heavier than it looks.")
		"sink":
			await s.say("", "The good cups for visitors. Two are out tonight.")
		"frontdoor":
			await s.say("", "The front door. Tomorrow you go through it in a uniform.")
		"bed":
			if not evening:
				return
			var r := await s.ask("Go to sleep?", ["Sleep", "Not yet"])
			if r == 0:
				s.w.hide_marker()
				await _night()


# ---------------------------------------------------------------- night ---

func _night() -> void:
	var m = s.m
	await m.fade_out(0.8)
	evening = false
	var pl := s.w.player
	pl.visible = false
	var sleeper := s.w.add_npc({"id": "sleeper", "spec": Game.player_spec("home"), "tile": Vector2i(2, 2), "dir": 0, "offset": Vector2(0, 6), "ghost": true})
	sleeper.z_index = 1
	var quilt := Sprite2D.new()
	quilt.texture = Art.prop("quilt")
	quilt.position = s.w.tile_center(Vector2i(2, 2)) + Vector2(0, 2)
	quilt.z_index = 2
	s.w.add_child(quilt)
	# your mother comes up the stairs and waits outside your door
	s.w.add_npc({"id": "mother", "who": "mother", "tile": Vector2i(4, 10), "dir": 1})
	s.w.tint.color = Maps.NIGHT
	s.w.cam_follow = false
	s.w.cam_focus = s.w.tile_center(Vector2i(5, 5))
	s.w.cam.position = s.w.cam_focus
	await m.fade_in(1.2)
	await s.say("", "You lie awake while the ceiling recycler hums above you and the packed silence from downstairs climbs the stairs and settles into your room.")
	match Game.vars.get("letter_choice", ""):
		"doubt":
			await s.say("", "You asked if you had to go. No one answered that part.")
		"resolve":
			await s.say("", "You said you could do it. In the dark, the words sound like they belong to someone older.")
		_:
			await s.say("", "You said nothing in the kitchen. The silence followed you here.")
	await s.say("~", ["Everyone keeps saying it's important.", "No one says it's safe."])
	Sfx.play("knock", 1.0, -2.0)
	sleeper.emote("!")
	await s.wait(0.5)
	await s.say("mother", "Can I come in?", "gentle")
	await s.say("you", "Yeah.")
	await s.walk("mother", [Vector2i(4, 5), Vector2i(3, 4), Vector2i(3, 3)], 34.0)
	s.face("mother", 3)
	await s.say("mother", "You don't have to be strong for us.", "gentle")
	var r := await s.ask("How do you respond?", ["I am scared.", "I'll be fine."])
	if r == 0:
		Game.vars.night_response = "fear"
		await s.say("you", "I am scared.", "sad")
		await s.say("mother", "Good. Fear means you know this is real. Do not let anyone train that out of you completely.", "soft")
	else:
		Game.vars.night_response = "mask"
		await s.say("you", "I'll be fine.", "smile")
		await s.say("mother", "You do not have to make me feel better. Not tonight.", "sad")
	if Game.vars.get("letter_choice", "") == "silent":
		await s.say("mother", "You went so quiet after the letter. I should have said more before they did.", "sad")
	await s.say("mother", "Whatever happens... remember who you are.", "soft")
	await s.say("you", "What if I forget?", "sad")
	s.emote("mother", "heart", 1.6)
	await s.say("mother", "Then we'll remind you.", "smile")
	await m.fade_out(1.6)
	Sfx.stop_music(1.0)
	await parade()


# ---------------------------------------------------------------- parade ---

func parade() -> void:
	var m = s.m
	m.load_map(Maps.parade(), Vector2i(23, 10), 3)
	s.w.busy = true
	Sfx.music("parade", 1.0)
	s.w.tint.color = Color(1.5, 1.5, 1.45)
	await m.fade_in(0.4)
	s.w.set_tint(Color(1.05, 1.02, 0.95), 1.6)
	s.w.show_area_name()
	await s.say("", ["They line you up with the others.", "New uniforms. Too clean. Too big. The fabric smells sealed, like it came from a machine and not a person."])
	await s.say("~", "Take your place in the line.")
	s.w.show_marker(Vector2i(17, 9))
	s.w.busy = false


func trigger(id: String) -> void:
	if id != "lineup":
		return
	var m = s.m
	s.w.hide_marker()
	await s.w.player.walk_to([s.w.tile_center(Vector2i(17, 9))], 50.0)
	s.w.player.face(1)
	await s.wait(0.3)
	Sfx.play("crowd", 1.0, -6.0)
	s.confetti(s.w.tile_center(Vector2i(14, 4)), 50)
	for i in 16:
		var c := s.a("crowd%d" % i)
		if c:
			c.hop(3.0, 0.3)
	await s.say("announcer", "Today, we honor the next generation of planetary defenders!", "")
	if Game.vars.get("night_response", "") == "mask":
		await s.say("", "You keep your face still. You practiced that before dawn.")
	else:
		await s.say("", "Your stomach is tight enough that even standing still feels like work.")
	await s.say("", "You notice the others.")
	await s.pan("hiro", 0.5)
	s.face("hiro", 3)
	s.emote("hiro", "note")
	await s.say("", "Hiro, grinning.")
	await s.pan("pala", 0.4)
	s.face("pala", 2)
	await s.say("", "Pala, watching the machines.")
	await s.pan("midas", 0.4)
	s.a("midas").shake(0.4, 1.0)
	s.emote("midas", "sweat")
	await s.say("", "Midas, gripping his uniform.")
	await s.pan_back(0.4)
	var r := await s.ask("Where do you focus?", ["Look for parents", "Watch Protektors", "Watch recruits"])
	match r:
		0:
			Game.vars.parade_focus = "parents"
			s.w.player.face(0)
			await s.pan(Vector2i(5, 12), 0.9)
			s.face("mother", 1)
			s.emote("mother", "heart", 0.8)
			await s.say("", "You search the crowd for your parents. The stadium glare flattens every face into the same pale blur.")
			await m.flash(Pal.WHITE, 0.8, 0.9)
			s.hide("mother")
			s.hide("father")
		1:
			Game.vars.parade_focus = "protektors"
			await s.pan(Vector2i(22, 5), 0.9)
			await s.say("", "Armored silhouettes stand above you on the raised rail. Their helmets never turn, but you still feel watched.")
		_:
			Game.vars.parade_focus = "recruits"
			await s.pan(Vector2i(9, 8), 0.9)
			await s.say("", "You watch the other recruits match their breathing to the march, each of them pretending not to look afraid.")
	await s.pan(Vector2i(25, 8), 0.8)
	Sfx.play("heavy_door", 1.0, -2.0)
	m.shake(2.0, 0.8)
	var sh := s.w.prop_sprite("shuttle")
	sh.texture = Art.prop("shuttle", 1)
	await s.say("", "A transport door opens.")
	match Game.vars.parade_focus:
		"parents":
			await s.say("", "You look one last time for your parents. The light is too bright, or they are already gone.")
		"protektors":
			await s.say("", "One Protektor raises a hand toward the transport. The gesture is efficient, almost mechanical.")
		_:
			await s.say("", "Midas swallows hard. Hiro keeps grinning. No one breaks rank.")
	if Game.vars.get("letter_choice", "") == "resolve":
		await s.say("", "You try to hold onto the brave thing you said in the kitchen. It feels smaller out here.")
	await s.pan_back(0.5)
	await s.say("announcer", "Welcome... to the Academy.")
	# Board, in line.
	var line := ["rec0", "rec1", "rec2", "hiro", "pala", "midas", "player", "rec3", "rec4"]
	var door := s.w.tile_center(Vector2i(25, 9)) + Vector2(-6, 0)
	for i in line.size():
		var aid: String = line[i]
		var act := s.a(aid)
		if act == null:
			continue
		var go := func() -> void:
			if await act.walk_to([Vector2(act.position.x, s.w.tile_center(Vector2i(0, 9)).y), door], 60.0):
				act.visible = false
			Sfx.play("step", 1.3, -16.0)
		go.call()
		await s.wait(0.25)
	await s.wait(2.4)
	s.w.player.visible = false
	sh.texture = Art.prop("shuttle", 0)
	Sfx.play("thrust", 1.0, -2.0)
	m.shake(3.0, 1.6)
	var fx := Fx.new()
	s.w.add_child(fx)
	fx.burst(sh.position + Vector2(0, -2), 40, [Pal.STONE, Pal.CREAM, Pal.WHITE], Vector2(20, 70), Vector2(0.5, 1.2), {"flat": true, "drag": 0.95})
	var lt := sh.create_tween()
	lt.tween_property(sh, "position:y", sh.position.y - 30, 0.8).set_trans(Tween.TRANS_SINE)
	lt.tween_property(sh, "position", sh.position + Vector2(240, -220), 1.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await s.wait(1.6)
	Sfx.stop_music(1.4)
	await m.fade_out(1.2)
	await s.academy.orientation()
