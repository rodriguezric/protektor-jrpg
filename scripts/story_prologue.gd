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
			# the front door opens onto the street for the evening
			mp.exits = mp.exits.duplicate()
			mp.exits.append({"rect": Rect2i(15, 2, 2, 1), "to": "block7", "tile": Vector2i(9, 3), "dir": 0})
	return mp


func exit(e: Dictionary) -> void:
	## The stairs between the floors, and the front door to the street.
	var to: String = e.get("to", "")
	if to == "block7" or (to == "home" and s.w.def.id == "block7"):
		# the front door opens and latches like every other door (World doors)
		await s.wait(0.15)
		if to == "block7":
			await s.m.change_map(Maps.block7("evening"), e.tile, e.dir)
			if not bool(Game.story.get("block7_seen", false)):
				Game.story.block7_seen = true
				s.w.busy = true
				s.w.show_area_name()
				await s.say("", ["Block 7 is out on its steps tonight, the way it only is in summer, or after bad news.", "Everyone pretends not to look at your door."])
				s.w.busy = false
		else:
			await s.m.change_map(_house("home"), e.tile, e.dir)
			s.w.show_marker(Vector2i(21, 2))
		return
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
		"mother", "father":
			var place := "parade" if s.w.def.id == "parade" else "home"
			n.face_toward(s.w.player.position)
			await NpcTalk.say(s, "%s.%s" % [place, n.info.get("id", "")])
		"hiro", "pala", "midas", "announcer":
			await NpcTalk.say(s, "parade." + str(n.info.get("id", "")))
		"okafor", "hale", "benno", "tomas", "juno", "pip", "wren":
			await _neighbour(n.info.get("id", ""))
		_:
			var id: String = n.info.get("id", "")
			if id.begins_with("crowd"):
				await NpcTalk.say(s, "parade.crowd", id)
			elif id.begins_with("rec"):
				await NpcTalk.say(s, "parade.rec", id)
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
			await _tv()
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
		"starbox":
			await _starbox()
		"kiosk":
			await s.say("", ["Ration chits, tea tins, spare bulbs. A hand-lettered card in the window:", "RECRUIT FAMILIES - ONE EXTRA CHIT THIS WEEK. CONGRATULATIONS."])
		"noticeboard":
			await s.say("", ["A Helion poster: a chrome robot striding over a green planet. STEEL THAT NEVER SLEEPS.", "Under it, older notices. A lost cat (FOUND, in pen). Ration hours. A choir that meets on fifth-days."])
			Propaganda.find("poster")
		"swings":
			await s.say("", "Your initials are still scratched into the left swing. Juno's are next to them, bigger.")
		"slide":
			await s.say("", "The slide you were afraid of until you were seven. It looks small now.")
		"cat":
			await s.say("", "The block cat. It belongs to nobody, which means it belongs to everybody. It ignores you, as a kindness.")
		"bin":
			await s.say("", ["Someone threw away a recruitment flyer. Someone else fished it out again and smoothed it flat.", "COULD YOUR CHILD BE CHOSEN? Full nutrition. Permanent housing. A hero in the family."])
			Propaganda.find("flyer")
		"homedoor":
			await s.say("", "Your door. The paint is chipped where your father's toolbox always catches it.")
		"okafordoor":
			await s.say("", "Mrs. Okafor's door, and a wind chime made of old spoons.")
		"nwindow":
			await s.say("", "Behind a curtain, a family eats dinner around a radio. Someone laughs, then remembers what tomorrow is.")
		"parade_mech":
			await s.say("", ["A Protektor on display, taller than the plaza lamps.", "Up close, the seams are glued. There's a hatch on its back, and nothing behind it."])
			Propaganda.find("parade_mech")
		"dark_window":
			await s.say("", "The Delacroix window. Dark for twelve years.")
		"desk":
			await s.say("", ["Your desk. Drawings of planets with faces, a cup of worn-down pencils.", "Someone has squared the papers into a neat pile. It wasn't you."])
		"wardrobe":
			await s.say("", "Your wardrobe is half empty. The clothes that are left all suddenly feel too small.")
		"toy":
			await s.say("", "A plastic Protektor. You glued its arm back on years ago, and it has pointed slightly the wrong way ever since.")
			Propaganda.find("toy")
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

## What your parents say about what you just watched (evening, at home).
const TV_REACTIONS := {
	"news": ["father", "Forty percent. They say it like it's a harvest.", ""],
	"cartoon": ["mother", "You used to stand on the couch for that one and punch the air.", "smile"],
	"kitchen": ["mother", "Three ways. I've made that loaf four ways for years. Nobody noticed.", "smile"],
	"weather": ["father", "They never forecast the weather here. Only out there.", ""],
	"serial": ["mother", "Don't tell me what happens. I'm two episodes behind.", "smile"],
	"static": ["father", "That channel's been dead since before you were born. Turn it off, would you?", "sad"],
}


func _tv() -> void:
	## The block screen. Flip through what's on; your parents have opinions.
	if not bool(Game.story.get("tv_seen", false)):
		Game.story.tv_seen = true
		await s.say("", ["The block screen loops tomorrow's parade rehearsal with the sound off.", "Every recruit on it is smiling. The camera never stays on one long enough to check."])
	if await s.ask("Change the channel?", ["Watch", "Leave it"]) != 0:
		return
	var res: Dictionary = await s.m.tv(int(Game.story.get("tv_channel", 0)))
	Game.story.tv_channel = int(res.get("index", 0))
	var last: String = res.get("last", "")
	if evening and TV_REACTIONS.has(last) and s.a(TV_REACTIONS[last][0]) != null:
		var r: Array = TV_REACTIONS[last]
		s.a(r[0]).face_toward(s.w.player.position)
		await s.say(r[0], r[1], r[2])


# --------------------------------------------------------------- Block 7 ---

## What each neighbour says, in order, each time you come back to them
## (the last line repeats).
const BLOCK7_TALK := {
	"okafor": [["okafor", ["Ah. Block 7's chosen one.", "Twelve years ago they took the Delacroix boy. Same letter. Same smile printed on the envelope."], "sad"],
		["okafor", "He waved from the transport. Everyone said how proud he looked. I only remember how small.", "sad"],
		["okafor", "Come back and tell me if they still smile on the envelopes.", ""]],
	"hale": [["hale", ["My Lise went up six years ago.", "They send a form letter every spring. Same words. Same signature. 'Your daughter's contribution is valued.'"], "sad"],
		["hale", "I keep the letters in a shoebox. I tell myself one spring the handwriting will change.", ""],
		["hale", "If you see her up there... no. Never mind. Get some sleep, kid.", "sad"]],
	"benno": [["benno", "Extra ration chit, for the family of a recruit. Congratulations? I never know what to say.", ""],
		["benno", "Your mother came by for the good tea today. First time in a year. I gave her the tin for free.", "smile"],
		["benno", "Kiosk closes at eight. Same as always. The world could end and the kiosk would close at eight.", ""]],
	"tomas": [["tomas", "They didn't pick me. I keep checking whether I'm relieved or jealous. It changes every minute.", "sad"],
		["tomas", "Bet you get a real Protektor. Bet it's enormous.", "smile"],
		["tomas", "...Don't forget us, okay? That's all.", "sad"]],
	"juno": [["juno", "Wear it. Even if they make you take everything else off.", ""],
		["juno", "I'm going to watch the news every night. If they show your face I'll wave at the screen like an idiot.", "smile"],
		["juno", "Go home. Before I say something embarrassing.", "sad"]],
	"pip": [["pip", "When I'm big they'll pick me too. I've been practising my robot voice. BEEP. BOOP.", "smile"],
		["pip", "Robots don't get scared. That's why they're robots.", ""]],
	"wren": [["wren", "I'm always the slime. Pip says slimes don't get letters.", ""],
		["wren", "My mama says the robots are lucky. I don't think robots can be lucky.", "sad"]],
}


func _neighbour(id: String) -> void:
	if (id == "tomas" or id == "juno") and not bool(Game.story.get("bracelet", false)):
		await _friends_gift()
		return
	if (id == "pip" or id == "wren") and not bool(Game.story.get("kids_seen", false)):
		await _kids_game()
		return
	var seen: Dictionary = Game.story.get("block7_talks", {})
	var n := int(seen.get(id, 0))
	var lines: Array = BLOCK7_TALK[id]
	var line: Array = lines[mini(n, lines.size() - 1)]
	s.face_to(id, "player")
	if id == "okafor" and n == 0:
		await s.say(line[0], line[1], line[2])
		await s.pan(Vector2i(28, 2), 0.7)
		await s.say("okafor", "That was their window. Nobody has lived there since the family moved to the good housing.", "sad")
		await s.pan_back(0.5)
	else:
		await s.say(line[0], line[1], line[2])
	seen[id] = n + 1
	Game.story.block7_talks = seen


func _friends_gift() -> void:
	## Tomas and Juno come over from the bench with something behind Juno's back.
	Game.story.bracelet = true
	var p := s.w.player.position
	# they come up beside you, a step apart (not close enough to box you in)
	s.walk_bg("juno", [p + Vector2(16, 0)], 40.0)
	await s.walk("tomas", [p + Vector2(-16, 0)], 40.0)
	await s.wait(0.2)
	s.face_to("juno", "player")
	s.face_to("tomas", "player")
	s.w.player.face(0)
	await s.say("juno", "We wanted to come to the parade. They only let families on the plaza.", "sad")
	await s.say("tomas", "So we made you something. Well. Juno made it. I held the string.", "smile")
	s.a("juno").hop(3.0)
	s.emote("juno", "heart", 1.4)
	Sfx.play("chime", 1.2, -8.0)
	await s.say("", "A bracelet braided from blue parade ribbon. Three knots: one for each of them, one for the block.")
	var r := await s.ask("What do you say?", ["Thank you.", "I'll come back."])
	if r == 0:
		await s.say("you", "Thank you.", "smile")
		await s.say("juno", "Don't. If you thank me I'll cry, and Tomas will tell everyone.", "smile")
	else:
		await s.say("you", "I'll come back.")
		s.emote("tomas", "...")
		await s.say("tomas", "Everybody says that.", "sad")
		await s.say("juno", "So be the one who does.", "")
	await s.say("tomas", "They didn't pick me. I keep checking whether I'm relieved or jealous. It changes every minute.", "sad")


func _kids_game() -> void:
	## Pip and Wren, in the park: Robo-Protektor versus the Slime Lord.
	if bool(Game.story.get("kids_seen", false)):
		return
	Game.story.kids_seen = true
	s.w.busy = true
	await s.pan(Vector2i(22, 10), 0.6)
	s.face("pip", 2)
	s.face("wren", 3)
	s.a("pip").hop(4.0)
	await s.say("pip", "I'm ROBO-PROTEKTOR! Steel that never sleeps!", "smile")
	s.a("wren").shake(0.4, 1.0)
	await s.say("wren", "GLORP! I'm the Slime Lord! Your planet is MINE!", "angry")
	await s.walk("pip", [Vector2i(22, 11)], 70.0)
	Sfx.play("knock", 0.8, -4.0)
	s.m.shake(1.5, 0.3)
	s.emote("pip", "!", 0.8)
	s.a("wren").set_pose("lie")
	await s.say("pip", "KA-POW!", "smile")
	await s.say("wren", "Ughhh. I am... defeated...", "closed")
	await s.wait(0.4)
	s.a("wren").set_pose("walk")
	s.a("wren").set_mood("smile")
	# then Pip spots you
	s.a("pip").face_toward(s.w.player.position)
	s.emote("pip", "!", 1.0)
	await s.wait(0.4)
	await s.pan_back(0.5)
	var p := s.w.player.position
	await s.walk("pip", [p + Vector2(12, 4)], 80.0)
	s.face_to("pip", "player")
	s.w.player.face_toward(s.a("pip").position)
	await s.say("pip", "You got the letter! Are you gonna be a ROBOT now?!", "smile")
	var r := await s.ask("What do you tell Pip?", ["Something like that.", "I don't know."])
	if r == 0:
		await s.say("pip", "WHOA. Can I have your Starbox if you don't come back?", "smile")
		await s.say("wren", "PIP!", "angry")
	else:
		await s.say("pip", "You don't KNOW? It's the best thing that can happen to a person! It says so on the poster!", "")
	await s.say("", "Pip's costume is a ration box with two eyeholes and a pipe-cleaner antenna, made from the pattern Helion printed on the kids' page.")
	Propaganda.find("costume")
	s.w.busy = false


func _departure() -> void:
	## Dawn. The whole block lines the sidewalk to see you off, and you walk
	## the length of it with your parents a step behind.
	var m = s.m
	m.load_map(Maps.block7("dawn"), Vector2i(9, 3), 0)
	s.w.busy = true
	s.w.add_npc({"id": "mother", "who": "mother", "tile": Vector2i(8, 2), "dir": 0})
	s.w.add_npc({"id": "father", "who": "father", "tile": Vector2i(10, 2), "dir": 0})
	Sfx.music("mellow_loop", 1.0)
	await m.fade_in(1.0)
	await s.say("", ["Morning comes grey and gold. The whole block has come out onto the sidewalk, which it never does.", "Your parents walk a step behind you, as if you already belong to somewhere else."])
	var stops := [
		[14, "hale", "Keep your head down. Write, if they let you.", "sad"],
		[17, "benno", "For the road. Don't tell your mother it was free.", "smile"],
		[19, "tomas", "Don't forget us!", "sad"],
		[20, "juno", "Wear it!" if bool(Game.story.get("bracelet", false)) else "Bye! BYE!", "smile"],
		[22, "pip", "BEEP BOOP! Good luck, robot!", "smile"],
		[24, "okafor", "Come back and tell me if they still smile.", ""],
	]
	for st in stops:
		var x: int = st[0]
		s.walk_bg("mother", [Vector2i(x - 2, 4)], 40.0)
		s.walk_bg("father", [Vector2i(x - 1, 4)], 40.0)
		await s.w.player.walk_to([s.w.tile_center(Vector2i(x, 4))], 40.0)
		s.w.player.face(1)
		s.face_to(st[1], "player")
		if st[1] == "pip":
			s.a("pip").hop(4.0)
			s.a("wren").hop(3.0)
		elif st[1] == "benno":
			s.emote("benno", "note", 1.0)
		elif st[1] == "juno":
			s.a("juno").hop(3.0)
		await s.say(st[1], st[2], st[3])
	s.emote("okafor", "heart", 1.2)
	await s.say("", "At the end of the block, a transport waits with its door open and its engine idling.")
	await m.fade_out(1.2)


func _starbox() -> void:
	## Your Starbox. One more game before tomorrow.
	if not bool(Game.story.get("starbox_seen", false)):
		Game.story.starbox_seen = true
		await s.say("", ["Your Starbox. The A button is worn smooth, and the PROTEKTOR cartridge label has peeled down to a robot's grin.",
			"Every kid on the block had one. Helion made sure of it."])
		Propaganda.find("cartridge")
	if await s.ask("Play the Starbox?", ["Play", "Not now"]) != 0:
		return
	await s.m.console()
	if not bool(Game.story.get("starbox_played", false)):
		Game.story.starbox_played = true
		await s.say("", "Tomorrow the robot on the cartridge is supposed to be you.")


func _night() -> void:
	var m = s.m
	await m.fade_out(0.8)
	evening = false
	var pl := s.w.player
	pl.visible = false
	var sleeper := s.w.add_npc({"id": "sleeper", "spec": Game.player_spec("home"), "tile": Vector2i(1, 2), "dir": 0, "offset": Vector2(8, 6), "ghost": true})
	sleeper.z_index = 1
	var quilt := Sprite2D.new()
	quilt.texture = Art.prop("quilt")
	quilt.position = s.w.tile_center(Vector2i(1, 2)) + Vector2(8, 2)
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
	await _departure()
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
	await s.scenes.barrier()
	await s.say("~", "Take your place in the line.")
	s.w.show_marker(Vector2i(17, 9))
	s.w.busy = false


func trigger(id: String) -> void:
	if id == "kids_game":
		await _kids_game()
		return
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
	# the transport's hatch opens: seals hiss, the door slides up, the ramp
	# drops to the ground with a thud
	var sh := s.w.prop_sprite("shuttle")
	var hatch_at: Vector2 = sh.position + Vector2(-10, -26)
	var puff := Fx.new()
	s.w.add_child(puff)
	Sfx.play("door", 0.7, -6.0)
	puff.burst(hatch_at, 14, [Pal.WHITE, Pal.FROST, Pal.STONE], Vector2(10, 30), Vector2(0.4, 0.9), {"drag": 0.9})
	await s.wait(0.5)
	sh.texture = Art.prop("shuttle", 2)
	Sfx.play("heavy_door", 1.0, -2.0)
	await s.wait(0.35)
	sh.texture = Art.prop("shuttle", 1)
	m.shake(2.0, 0.5)
	puff.burst(sh.position + Vector2(-10, -4), 18, [Pal.STONE, Pal.CREAM], Vector2(20, 50), Vector2(0.4, 0.8), {"flat": true, "drag": 0.93})
	await s.wait(0.9)
	match Game.vars.parade_focus:
		"parents":
			await s.say("", "You look one last time for your parents. The light is too bright, or they are already gone.")
		"protektors":
			# the nearer Protektor lifts its arm toward the transport, in two
			# exact movements, and holds it there
			var mech := s.w.prop_sprite("mech2")
			await s.pan(Vector2i(24, 7), 0.5)
			for pose_base in [2, 4]:
				Sfx.play("plate", 0.6, -8.0)
				mech.set_meta("base", pose_base)
				mech.texture = Art.prop("mech", pose_base)
				await s.wait(0.45)
			await s.wait(0.5)
			await s.say("", "The gesture is efficient, almost mechanical.")
			await s.pan(Vector2i(25, 8), 0.4)
		_:
			await s.say("", "Midas swallows hard. Hiro keeps grinning. No one breaks rank.")
	if Game.vars.get("letter_choice", "") == "resolve":
		await s.say("", "You try to hold onto the brave thing you said in the kitchen. It feels smaller out here.")
	await s.pan_back(0.5)
	await s.say("announcer", "Welcome... to the Academy.")
	# Board, in line: nearest the transport first, everyone keeping their
	# place, down off the carpet, along the front of the transport to the
	# foot of the ramp, up it and in through the hatch.
	var line := ["rec4", "rec3", "player", "midas", "pala", "hiro", "rec2", "rec1", "rec0"]
	var hatch := sh.position + Vector2(-10, 0)
	var boarded := {"n": 0}
	var walkers := 0
	for aid in line:
		var act := s.a(aid)
		if act == null:
			continue
		walkers += 1
		act.z_index = 1
		var go := func() -> void:
			var ok := await act.walk_to([Vector2(372, act.position.y), Vector2(376, hatch.y - 6), Vector2(hatch.x, hatch.y - 4),
				Vector2(hatch.x, hatch.y - 18)], 60.0)
			if ok and is_instance_valid(act):
				Sfx.play("step", 1.3, -16.0)
				var tw := act.create_tween()
				tw.tween_property(act, "position:y", hatch.y - 24, 0.3)
				tw.parallel().tween_property(act, "modulate:a", 0.0, 0.3)
				await tw.finished
				if is_instance_valid(act):
					act.visible = false
					act.modulate.a = 1.0
					act.z_index = 0
			boarded.n += 1
		go.call()
		await s.wait(0.05)
	while boarded.n < walkers:
		await s.wait(0.1)
	await s.wait(0.4)
	# the hatch closes: door slides down, ramp folds up
	Sfx.play("heavy_door", 1.1, -4.0)
	sh.texture = Art.prop("shuttle", 2)
	await s.wait(0.35)
	sh.texture = Art.prop("shuttle", 0)
	m.shake(1.0, 0.3)
	await s.wait(0.7)
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
