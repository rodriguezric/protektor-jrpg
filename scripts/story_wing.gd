class_name StoryWing
extends RefCounted
## The Pilot Wing off the Commons: a corridor of rooms that open up as the
## intake gets older (Maps.wing / Maps.wing_room). Visiting, reading and
## playing here never use up the interval's one conversation.
##
## Rooms: rec room (TV, Starbox, ping-pong, cards), mess hall, archive (lore
## terminals), training gym, observation deck (stargazing with Pala), memorial
## hall (it grows), rooftop garden (Midas' tomatoes).

var s: Story


func _init(p_s: Story) -> void:
	s = p_s


static func unlocked(id: String) -> bool:
	var n := Game.completed_count()
	match id:
		"archive":
			return n >= 2
		"observation":
			return n >= 3
		"memorial":
			return n >= 4 or Game.midas_dead()
		"rooftop":
			return n >= 5
	return true


static func unlock_hint(id: String) -> String:
	match id:
		"archive":
			return "Opens after two deployments."
		"observation":
			return "Opens after three deployments."
		"memorial":
			return "Opens after four deployments."
		"rooftop":
			return "Opens after five deployments."
	return ""


# ----------------------------------------------------------------- moving ---

func enter_wing(from_room: String = "") -> void:
	var tile := Vector2i(14, 4)
	var dir := 1
	if from_room != "":
		tile = Vector2i(Maps.WING_DOOR_X[from_room], 2)
		dir = 0
	Sfx.play("door", 1.1, -8.0)
	await s.m.change_map(Maps.wing(), tile, dir)
	if not bool(Game.story.get("wing_seen", false)):
		Game.story.wing_seen = true
		s.w.busy = true
		s.w.show_area_name()
		await s.say("", ["The Pilot Wing. A corridor of doors, each with a little plaque.", "Some of them are sealed. The plaques say the seals lift 'with seniority.'"])
		s.w.busy = false


func _enter_room(id: String) -> void:
	if not unlocked(id):
		Sfx.play("cancel", 0.8, -6.0)
		await s.say("", ["%s. The door is sealed." % Maps.WING_NAMES[id].to_upper(), unlock_hint(id)])
		return
	Sfx.play("door", 1.0, -8.0)
	await s.m.change_map(Maps.wing_room(id), Vector2i(7, 7), 1)
	var rid := "room_" + id
	if not bool(Game.story.get(rid + "_seen", false)):
		Game.story[rid + "_seen"] = true
		s.w.show_area_name()
		await _first_visit(id)


func exit(e: Dictionary) -> void:
	var to: String = e.get("to", "")
	if to == "wing":
		await enter_wing(s.w.def.id.trim_prefix("room_"))
	elif to == "commons":
		Sfx.play("door", 0.9, -8.0)
		await s.m.change_map(s.hub._map(), e.tile, e.dir)
		if s.hub.used:
			s.w.show_marker(Vector2i(14, 9))


# ------------------------------------------------------------- first visits ---

func _first_visit(id: String) -> void:
	match id:
		"rec":
			await s.say("", "The rec room. Someone has stacked the cushions into a fort and someone else has knocked it over.")
		"mess":
			await s.say("", "The mess hall smells of warm metal and Nutri-Loaf.")
		"archive":
			await s.say("", "The archive: binders, terminals, and a quiet that sounds expensive.")
		"gym":
			await s.say("", "The training gym. The sim pods hum even when nobody is in them.")
		"observation":
			await _stargazing()
		"memorial":
			await s.say("", ["The memorial hall. Nobody calls it that out loud.", "There is a wall of names, and someone keeps the candles lit."])
		"rooftop":
			await _rooftop_scene()


func _stargazing() -> void:
	## The observation deck's first night: Pala, the stars, and the shapes she
	## made up for them when she first got here.
	s.w.busy = true
	await s.say("", "The whole wall is window. The stars here are close enough to be rude.")
	if bool(Game.story.pala_unavailable) or bool(Game.story.get("pala_escape_chosen", false)):
		await s.say("", "You stand at the glass for a while, alone. It is the quietest place in the Academy.")
		s.w.busy = false
		return
	var pala := s.w.add_npc({"id": "pala", "who": "pala", "tile": Vector2i(7, 8), "dir": 1})
	pala.visible = true
	s.w.player.face(0)
	await s.walk("pala", [Vector2i(7, 4), Vector2i(8, 3)], 40.0)
	s.face("pala", 1)
	await s.say("pala", "You found it. I come here when the dorm gets too loud. Or too quiet.", "smile")
	await s.say("pala", "When I first got here I made up my own constellations. Want to see?", "")
	# her shapes, drawn in light over the real stars
	var shapes := [
		["The Kitchen Chair.", [Vector2(40, 10), Vector2(52, 10), Vector2(52, 22), Vector2(40, 22), Vector2(40, 34), Vector2(52, 22)]],
		["The Cup My Brother Broke.", [Vector2(112, 12), Vector2(126, 12), Vector2(124, 26), Vector2(114, 26), Vector2(112, 12)]],
		["And that one's just a dog. Every sky needs a dog.", [Vector2(176, 18), Vector2(186, 14), Vector2(196, 18), Vector2(206, 16), Vector2(200, 26), Vector2(184, 26)]],
	]
	# drawn on a layer of their own that follows the camera, so the deck's
	# night tint doesn't dim them
	var sky := CanvasLayer.new()
	sky.layer = 2
	sky.follow_viewport_enabled = true
	s.w.add_child(sky)
	for sh in shapes:
		var line := Line2D.new()
		line.width = 1.0
		line.default_color = Color(Pal.LEMON, 0.9)
		line.antialiased = false
		sky.add_child(line)
		for pt in sh[1]:
			var dot := ColorRect.new()
			dot.color = Pal.WHITE
			dot.size = Vector2(2, 2)
			dot.position = pt - Vector2(1, 1)
			line.add_child(dot)
		for k in (sh[1] as Array).size():
			line.add_point(sh[1][k])
			Sfx.play("blip", 1.4 + k * 0.08, -16.0)
			await s.wait(0.18)
		await s.say("pala", sh[0], "smile")
		var tw := line.create_tween()
		tw.tween_property(line, "modulate:a", 0.0, 0.8)
		tw.tween_callback(line.queue_free)
	sky.queue_free()
	s.emote("pala", "heart", 1.4)
	await s.say("you", "They're good.", "smile")
	await s.say("pala", "They're terrible. That's why I like them. Nobody here can tell me they're wrong.", "smile")
	Game.story.stargazed = true
	await s.walk("pala", [Vector2i(7, 6), Vector2i(7, 8)], 40.0)
	pala.visible = false
	s.w.busy = false


func _rooftop_scene() -> void:
	s.w.busy = true
	await s.say("", "The rooftop garden. Real dirt in steel boxes, and over it a sky with nothing between you and it.")
	if not Game.midas_dead():
		var mid := s.w.add_npc({"id": "midas", "who": "midas", "tile": Vector2i(5, 6), "dir": 3})
		mid.set_pose("sit")
		await s.pan(Vector2i(4, 6), 0.6)
		s.emote("midas", "!", 0.8)
		await s.say("midas", "Oh. Hi. I didn't think anyone else came up here.", "smile")
		await s.say("midas", "Mom grew these on our windowsill. They never get this red up here. I think they're homesick too.", "sad")
		s.emote("midas", "heart", 1.2)
		await s.say("midas", "You can have one, if you want. Don't tell the mess hall.", "smile")
		Game.story.midas_tomato = true
		await s.pan_back(0.5)
	else:
		var tom: Sprite2D = s.w.prop_sprite("tomato")
		if tom:
			tom.texture = Art.prop("planter", 2)
		await s.pan(Vector2i(4, 6), 0.6)
		await s.say("", ["One planter has a paper tag in careful handwriting: MIDAS - TOMATOES - PLEASE DON'T PICK YET.", "Nobody has watered it."])
		await s.pan_back(0.5)
	s.w.busy = false


# ------------------------------------------------------------------- talk ---

func talk(n: Actor) -> void:
	var id: String = n.info.get("id", "")
	match id:
		"fan":
			# the rec room's Hearts of the Shield Grid superfan
			var ep := int(Game.profile.get("tv_serial_ep", 0))
			var lines := [
				"Do you watch HEARTS OF THE SHIELD GRID? Channel four. It's the only real thing on.",
				"Episode one! When he takes the sunglasses off! I screamed into a pillow.",
				"The SLAP. I felt that slap in my soul.",
				"AMNESIA. Classic. He'll remember. They always remember.",
				"An evil TWIN with a MUSTACHE. I knew it. I've known it since episode one.",
				"I OBJECT. I object to how good that episode was.",
				"'Or WAS it?' I haven't slept. Two pairs of sunglasses. TWO.",
			]
			await s.say("", "\"%s\"" % lines[mini(ep, lines.size() - 1)])
		"gossip0", "gossip1":
			var g := [
				["Is it true the top tier eats less? Like they forget to?", "I heard the Paragon was a pilot once. Before."],
				["Nutri-Loaf again. Three ways, all sliced.", "Somebody's sitting where Midas used to sit. Nobody told them." if Game.midas_dead() else "Midas saves his bread for later. Every time."],
			]
			var ln: Array = g[0 if id == "gossip0" else 1]
			await s.say("", "\"%s\"" % ln[Game.completed_count() % ln.size()])
		"pala", "midas":
			await s.say(id, "...", "")
		_:
			await s.say("", "...")


# ---------------------------------------------------------------- examine ---

func examine(ev: Dictionary) -> void:
	var id: String = ev.get("id", "")
	if id.begins_with("room:"):
		await _enter_room(id.trim_prefix("room:"))
		return
	match id:
		# rec room
		"rec_tv":
			var res: Dictionary = await s.m.tv(int(Game.story.get("tv_channel", 0)))
			Game.story.tv_channel = int(res.get("index", 0))
			if bool(Game.story.get("footage_pending", false)):
				Game.story.footage_pending = false
				await _footage_reveal()
		"rec_starbox":
			if not bool(Game.story.get("rec_starbox_seen", false)):
				Game.story.rec_starbox_seen = true
				await s.say("", "A Starbox, bolted to the shelf. Someone has scratched HIRO WAS HERE into the cartridge slot.")
			await s.m.console()
		"pingpong":
			await s.hub_minigame("pingpong")
		"cards":
			await s.hub_minigame("cards")
		# mess hall
		"tray":
			await s.say("", "Today: Nutri-Loaf. A card on the counter reads THREE WAYS. All three are sliced.")
		"cereal":
			await s.say("", ["PROTEKTOR CRUNCH. A cartoon robot flexes on the box.", "The prize inside is a pamphlet for your family: 'Could YOUR child be chosen?'"])
			Propaganda.find("cereal")
		"dispenser":
			Sfx.play("beep", 1.2, -8.0)
			await s.say("", "WATER (BLUE). WATER (CLEAR). The blue one tastes like the clear one, but bluer.")
		"quota":
			await s.say("", ["CALORIE ALLOWANCE BY SYNCHRONIZATION TIER. The higher the tier, the smaller the number.", "A footnote: 'Higher-tier pilots report reduced appetite.'"])
		# archive
		"lore":
			await _lore()
		"shelf":
			await s.say("", "Binders of deployment logs, all the same thickness. The spines are labelled by planet, not by pilot.")
		"cabinet":
			await s.say("", "A cabinet: MEDICAL / TRANSFER RECORDS. The lock is newer than the cabinet.")
		"pala_stack":
			if Game.relationship("pala") >= 1 and not bool(Game.story.pala_unavailable):
				await s.say("", ["A stack of printouts hidden behind the crate, in Pala's handwriting down every margin:", "'same threshold. same threshold. same.'"])
			else:
				await s.say("", "An empty crate, stencilled FRAGILE.")
		# gym
		"simpod":
			var c := await s.ask("Run a training module? Clears pay a few credits.", ["Train", "Not now"], "system")
			if c == 0:
				await s.m.training()
		"treadmill":
			await s.say("", "You run until your legs ache. The screen counts your steps and calls them DEPLOYMENT READINESS.")
		"punchbag":
			Sfx.play("knock", 0.7, -4.0)
			s.w.player.hop(2.0)
			var bag := _prop_at(Vector2i(12, 3))
			if bag:
				var tw := bag.create_tween()
				tw.tween_property(bag, "rotation", 0.12, 0.08)
				tw.tween_property(bag, "rotation", -0.08, 0.15)
				tw.tween_property(bag, "rotation", 0.0, 0.2)
			await s.say("", "The bag swings back. Someone wrote a name on it in marker, then scratched the name out.")
		"drill":
			await s.hub_minigame("drill")
		"times":
			await s.say("", ["FASTEST TURN TIMES, THIS INTAKE: 1. HIRO 0.12s. 2. HIRO 0.12s. 3. HIRO 0.13s. 4. HIRO 0.13s.", "Your name is ninth. Under it, in pen: 'not bad'."])
		# observation deck
		"deckwindow":
			await s.say("", "Out there, far off, a green dot: Terra Virex. Somewhere near it, the blue haze of the shield grid over home.")
		"telescope":
			await s.say("", "Through the telescope: a convoy of transports, nose to tail, heading out. Each one the size of a fingernail.")
		# memorial
		"names":
			await _names()
		"candles":
			if not bool(Game.story.get("candle_lit", false)):
				var c2 := await s.ask("Light a candle?", ["Light one", "Leave them"])
				if c2 == 0:
					Game.story.candle_lit = true
					Sfx.play("chime", 0.7, -8.0)
					await s.say("", "You light one. Nobody sees. That seems to be the point.")
					return
			await s.say("", "Ration candles in paper cups. The duty log says nobody keeps them lit. Somebody does.")
		"guestbook":
			var lines := ["A guestbook nobody was told about. 'Kit, I still have your cards.' 'Sol: the vending machine misses you.'"]
			if Game.midas_dead():
				lines.append("The newest page, in neat small letters: 'Midas. Your tomatoes are coming up. -P'")
			await s.say("", lines)
		# rooftop
		"planter":
			await s.say("", "Hydroponic greens. The only things in the Academy that grow without being told to.")
		"tomato":
			if Game.midas_dead():
				if not bool(Game.story.get("watered_tomato", false)):
					var c3 := await s.ask("Water Midas' tomatoes?", ["Water them", "Leave them"])
					if c3 == 0:
						Game.story.watered_tomato = true
						var tom: Sprite2D = s.w.prop_sprite("tomato")
						if tom:
							tom.texture = Art.prop("planter", 0)
						Sfx.play("pop", 0.8, -8.0)
						await s.say("", "You water them. They don't look any different. You decide to come back anyway.")
						return
				await s.say("", "MIDAS - TOMATOES - PLEASE DON'T PICK YET.")
			else:
				await s.say("", "Midas' tomatoes. Small, stubborn, nearly red.")
		"rooftop_sky":
			await s.say("", "Open sky, for once. Somewhere far below, the shield grid hums.")


# ---------------------------------------------------------------- reveals ---

func _brief_reveal() -> void:
	## The brief lands: every robot you grew up with flashes past, and then
	## what was always behind it.
	s.w.busy = true
	Sfx.stop_music(0.6)
	await s.wait(0.4)
	var c := Cinema.open(Color(0, 0, 0, 1))
	var cuts := [[Art.prop("noticeboard", 0), "STEEL THAT NEVER SLEEPS"], [Art.prop("mech", 0), "BRAVE MACHINES"],
		[Art.prop("toy", 0), "AGES 5 AND UP"], [Art.prop("starbox", 1), "DEFEND THE PLANET!"]]
	for cut in cuts:
		var sp := c.sprite(cut[0], Vector2(160, 84))
		sp.scale = Vector2(3, 3) if (cut[0] as Texture2D).get_height() < 40 else Vector2(1.6, 1.6)
		var l := Art.shadow_label(cut[1], Pal.LEMON, 2)
		l.position = Vector2(160 - Art.text_width(cut[1], 2) / 2.0, 140)
		c.add_child(l)
		Sfx.play("static", 1.4, -12.0)
		s.m.flash(Pal.WHITE, 0.15, 0.5)
		await s.wait(0.55)
		sp.queue_free()
		l.queue_free()
	await s.wait(0.6)
	await s.say("", ["There was never a robot.", "There was always a child in a chair, somewhere a camera never went."])
	await c.close(0.6)
	s.w.player.emote("...", 1.4)
	await s.say("~", ["Every poster. Every cartoon. Every toy.", "They were pictures of us, with the children painted out."])
	Sfx.music("low_mechanical_ambient", 1.5)
	s.w.busy = false


func _footage_reveal() -> void:
	## After the special bulletin: what you just saw on the rec room TV.
	s.w.busy = true
	await s.say("~", ["That was my turn. The way I swing the shield wide before a block.", "They painted a robot over me."])
	var fan := s.a("fan")
	if fan:
		fan.emote("note", 1.0)
		await s.say("", "\"Wasn't that robot AMAZING?\" says the recruit on the couch. \"I want to be just like it.\"")
	await s.say("~", "...You were. You are.")
	s.w.busy = false


func _prop_at(t: Vector2i) -> Sprite2D:
	var want := s.w.tile_center(t)
	for c in s.w.get_children():
		if c is Sprite2D and (c as Sprite2D).position.distance_to(want) < 10.0:
			return c
	return null


# ------------------------------------------------------------------- lore ---

## The archive terminals: [title, unlocked when, text lines].
static func lore_entries() -> Array:
	var n := Game.completed_count()
	var out := [
		["HELION DEFENSE: A HISTORY", true, ["Helion Defense was chartered after the First Breach, when three colony worlds went dark in a single cycle.",
			"Crewed fleets proved too slow. The Protektor Initiative replaced them within a decade."]],
		["THE PROTEKTOR INITIATIVE", true, ["Pilots are selected between the ages of ten and thirteen, when neural plasticity peaks.",
			"Public materials depict autonomous defense units. This is a deliberate simplification."]],
		["PLANETARY DEFENSE ROSTER", n >= 3, ["Seven worlds under active defense. Population figures: CLASSIFIED.",
			"A note in the margin of the printout: 'they never tell us how many people'."]],
		["PILOT RECORD: LISE HALE", n >= 4, ["Intake 31. Peak synchronization: 92%. Status: TRANSFERRED.",
			"Family correspondence: automated, annual. Template 4-B."]],
		["PILOT RECORD: A. DELACROIX", n >= 5, ["Intake 19. Peak synchronization: 96%. Status: TRANSFERRED.",
			"Family relocated to priority housing. Case closed."]],
		["MARKETING BRIEF 7-C", n >= 4, ["PUBLIC COMMUNICATIONS: THE PROTEKTOR INITIATIVE. Public-facing materials must depict autonomous units.",
			"Imagery of pilots, and of minors in particular, is prohibited. The public must never picture a child.",
			"Tested phrasing: 'brave machines'. 'Steel that never sleeps.' 'The Protektor never sleeps, so you can.'"]],
		["SYNCHRONIZATION THRESHOLDS", n >= 6 or Game.relationship("pala") >= 2, ["Above 85%, ego boundaries begin to degrade. Pilots report reduced appetite, flattened affect, and a sense of 'being everywhere'.",
			"Recommended action: continue deployment."]],
	]
	return out


func _lore() -> void:
	var entries := lore_entries()
	var opts := []
	for e in entries:
		opts.append(e[0] if e[1] else "[LOCKED]")
	opts.append("Log off")
	while true:
		var c := await s.ask("ARCHIVE TERMINAL", opts, "system")
		if c < 0 or c >= entries.size():
			return
		if not entries[c][1]:
			await s.say("system", "Clearance insufficient. Clearance increases with service.")
			continue
		var read: Dictionary = Game.story.get("lore_read", {})
		var first: bool = not read.has(entries[c][0])
		read[entries[c][0]] = true
		Game.story.lore_read = read
		await s.say("system", entries[c][2])
		if entries[c][0] == "THE PROTEKTOR INITIATIVE":
			Propaganda.find("initiative")
		elif entries[c][0] == "MARKETING BRIEF 7-C":
			Propaganda.find("brief")
			if first:
				await _brief_reveal()
				return


func _names() -> void:
	var n := mini(12, Game.completed_count() / 2 + (2 if Game.midas_dead() else 0))
	var lines := ["The wall of names, engraved small. LISE HALE is here. A. DELACROIX is here, near the top, the letters worn soft by fingers."]
	if n > 0:
		lines.append("%d names from your intake have been added. The engraving on them is very fresh." % n)
	if Game.midas_dead():
		lines.append("MIDAS. Someone has tucked a little tin rocket into the gap beside it.")
	await s.say("", lines)
