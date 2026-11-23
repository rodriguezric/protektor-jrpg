class_name StoryScenes
extends RefCounted
## Small staged moments in the field, each played once when the story is
## ready for it (Game.story.scenes_seen):
##   Commons (one per interval, when you come back from a deployment):
##     nell_birthday  - a ration-candle birthday on the couch (2nd interval on)
##     pala_files     - Pala at the archive console as the maintenance unit
##                      rolls her way (Pala relationship 1+)
##     hiro_alone     - Hiro at the sim pod, blocking things that aren't there
##                      (Hiro relationship 2+)
##     transfer       - the Instructor comes for Kit (4+ deployments)
##     forgot_name    - a medic asks Sefa her name (after a loss, or 5+)
##   Rooms:
##     midas_bread    - Midas pocketing bread in the mess hall (alive, 1+)
##     argument       - Hiro and Pala on the rooftop (both relationship 2+)
##     pala_note      - Pala's note for Midas at the memorial (he's gone)
##   The parade:
##     barrier        - your mother pushes to the barrier (always)

var s: Story


func _init(p_s: Story) -> void:
	s = p_s


static func seen(id: String) -> bool:
	return (Game.story.get("scenes_seen", {}) as Dictionary).has(id)


static func mark(id: String) -> void:
	var d: Dictionary = Game.story.get("scenes_seen", {})
	d[id] = true
	Game.story.scenes_seen = d


func _pala_here() -> bool:
	return not bool(Game.story.pala_unavailable) and not bool(Game.story.get("pala_escape_chosen", false))


# ---------------------------------------------------------------- commons ---

func commons_scene() -> void:
	## Plays the first Commons moment that's ready and unseen (at most one).
	var n := Game.completed_count()
	var order := [
		["transfer", n >= 4 and s.a("rec3") != null],
		["forgot_name", (str(Game.story.get("last_result", "")) == "lose" or n >= 5) and s.a("rec2") != null],
		["hiro_alone", Game.relationship("hiro") >= 2],
		["pala_files", Game.relationship("pala") >= 1 and _pala_here() and s.a("pala") != null],
		["nell_birthday", int(Game.story.get("interval_count", 0)) >= 2 and s.a("rec0") != null and s.a("rec1") != null],
	]
	for o in order:
		if o[1] and not seen(o[0]):
			mark(o[0])
			s.w.busy = true
			await call("_" + o[0])
			await s.pan_back(0.5)
			s.w.busy = false
			return


func _nell_birthday() -> void:
	await s.pan(Vector2i(5, 7), 0.8)
	# Nell and Dov come over to the couch
	s.walk_bg("rec0", [Vector2i(5, 6)], 60.0)
	await s.walk("rec1", [Vector2i(4, 7)], 60.0)
	await s.walk("rec0", [Vector2i(5, 6)], 60.0)
	s.face("rec0", 0)
	s.face("rec1", 2)
	var candle := Sprite2D.new()
	candle.texture = Art.prop("candles", 0)
	candle.scale = Vector2(0.5, 0.5)
	candle.position = s.w.tile_center(Vector2i(5, 7)) + Vector2(4, 0)
	candle.z_index = 5
	s.w.add_child(candle)
	await s.say("", "Someone has stuck a ration-candle into a slice of Nutri-Loaf and hidden it behind the couch.")
	await s.say("dov", "Happy birthday, Nell. Don't tell anyone. Birthdays aren't on the schedule.", "smile")
	await s.say("nell", "I'm twelve. I counted.", "smile")
	for k in 3:
		s.emote("rec1", "note", 0.6)
		Sfx.play("blip", [1.0, 1.12, 1.26][k], -14.0)
		await s.wait(0.5)
	var c := await s.ask("Dov waves you over.", ["Sing along", "Keep watch"])
	if c == 0:
		await s.walk("player", [Vector2i(6, 7)], 50.0)
		s.emote("player", "note", 0.8)
		await s.say("", "You sing it very quietly. All three of you are bad at it.")
	else:
		s.w.player.face(0)
		await s.say("", "You stand where you can see the door. Nobody comes.")
	Sfx.play("whoosh", 1.6, -12.0)
	candle.queue_free()
	s.emote("rec0", "heart", 1.4)
	await s.say("nell", "Twelve. Okay. Okay.", "smile")


func _pala_files() -> void:
	var pala := s.a("pala")
	await s.pan(Vector2i(22, 4), 0.7)
	s.face("pala", 1)
	await s.say("", "Pala is at the archive console, her badge pressed to the reader, copying something line by line.")
	var bot := s.a("bot")
	if bot:
		await bot.walk_to([s.w.tile_center(Vector2i(17, 5))], 50.0)
	s.emote("pala", "!", 0.8)
	await s.say("", "The maintenance unit turns, and starts polishing its way toward her.")
	var c := await s.ask("What do you do?", ["Distract the unit", "Stay out of it"])
	if c == 0:
		await s.walk("player", [Vector2i(16, 6)], 70.0)
		if bot:
			bot.face_toward(s.w.player.position)
			bot.emote("?", 1.0)
		Sfx.play("beep", 1.4, -8.0)
		await s.say("", "You crouch and admire the floor it just polished. The unit stops to consider your admiration.")
		s.emote("pala", "heart", 1.0)
		await s.say("pala", "Thanks. I owe you a constellation.", "smile")
	else:
		if bot:
			await bot.walk_to([s.w.tile_center(Vector2i(21, 5))], 20.0)
		await s.say("", "The unit polishes right past her heels. Pala doesn't breathe until it's gone.")
		await s.say("pala", "...That was close. Don't tell anyone you saw me.", "anxious")
	if pala:
		pala.face(0)


func _hiro_alone() -> void:
	await s.w.set_tint(Color(0.6, 0.66, 0.9), 0.6)
	await s.pan(Vector2i(5, 3), 0.8)
	s.face("hiro", 1)
	await s.say("", "Hiro stands at the window with his eyes shut, one hand sweeping the air in arcs, blocking things that aren't there.")
	for k in 4:
		s.emote("hiro", "sync", 0.5)
		s.a("hiro").hop(1.5, 0.15)
		Sfx.play("block", 1.3 + k * 0.05, -16.0)
		await s.wait(0.6)
	var c := await s.ask("Say something?", ["Hiro?", "(Leave him be)"])
	if c == 0:
		await s.say("you", "Hiro?")
		await s.say("hiro", "Thirty-one. Thirty-two. ...You made me lose count.", "flat")
		await s.say("", "He doesn't turn around.")
	else:
		await s.say("", "You leave him be. The arcs go on behind you, perfectly even.")
	await s.w.set_tint(Color(0.82, 0.88, 1.0), 0.6)


func _transfer() -> void:
	await s.pan(Vector2i(11, 11), 0.7)
	Sfx.play("heavy_door", 1.0, -6.0)
	var kit := s.a("rec3")
	s.walk_bg("rec3", [Vector2i(13, 10)], 50.0)
	var ins := await s.enter({"id": "scene_instructor", "who": "instructor", "dir": 1}, Vector2i(11, 13), [Vector2i(11, 11)], 40.0)
	await s.walk("rec3", [Vector2i(13, 10)], 50.0)
	kit.face(3)
	ins.face_toward(kit.position)
	await s.say("instructor", "Recruit Kit. Your transfer has been approved.")
	kit.emote("!", 0.8)
	await s.say("kit", "Transfer? But I'm eleventh on the board, I'm nearly...", "worried")
	await s.say("instructor", "Congratulations. Come with me.")
	for id in ["rec0", "rec1", "rec2"]:
		s.face(id, 1)
	await kit.walk_to([s.w.tile_center(Vector2i(12, 11)), s.w.tile_center(Vector2i(12, 12))], 34.0)
	kit.face(1)
	await s.wait(0.5)
	kit.face(0)
	await s.say("", "At the door Kit looks back. Nobody is looking at Kit.")
	s.leave("scene_instructor", [Vector2i(11, 13)], 40.0)
	await s.leave("rec3", [Vector2i(12, 13)], 34.0)
	Sfx.play("heavy_door", 0.9, -6.0)
	Game.story.kit_transferred = true
	await s.say("", "Nobody watches the door close. Everybody hears it.")


func _forgot_name() -> void:
	await s.pan(Vector2i(19, 9), 0.7)
	s.face("rec2", 2)
	await s.enter({"id": "scene_medic", "who": "medic", "dir": 3}, Vector2i(11, 13), [Vector2i(12, 12), Vector2i(20, 12), Vector2i(20, 9)], 46.0)
	await s.say("", "A medic crouches beside Sefa with a clipboard.")
	await s.say("medic", "Can you tell me your name?")
	await s.wait(0.8)
	await s.say("sefa", "...Pilot.", "flat")
	await s.say("medic", "Your name, sweetheart.")
	s.emote("rec2", "...", 1.0)
	await s.wait(1.0)
	await s.say("sefa", "Pilot Sefa. Sefa. It's Sefa. Sorry. It's Sefa.", "worried")
	Sfx.play("paper", 1.2, -10.0)
	await s.say("", "The medic writes something down and doesn't say what.")
	await s.leave("scene_medic", [Vector2i(20, 12), Vector2i(12, 12), Vector2i(11, 13)], 46.0)


# ------------------------------------------------------------------ rooms ---

func room_cast(id: String) -> Array:
	## People already in a room when a scene is about to play there; added to
	## the map before it fades in (StoryWing), so nobody pops in.
	match room_key(id):
		"midas_bread":
			return [{"id": "scene_midas", "who": "midas", "tile": Vector2i(18, 6), "dir": 1}]
		"argument":
			return [{"id": "scene_hiro", "who": "hiro", "tile": Vector2i(9, 4), "dir": 2},
				{"id": "scene_pala", "who": "pala", "tile": Vector2i(11, 4), "dir": 3, "mood": "angry"}]
		"pala_note":
			return [{"id": "scene_pala", "who": "pala", "tile": Vector2i(4, 2), "dir": 1}]
	return []


func room_key(id: String) -> String:
	var key := ""
	match id:
		"mess":
			if not Game.midas_dead() and Game.completed_count() >= 1:
				key = "midas_bread"
		"rooftop":
			if Game.relationship("hiro") >= 2 and Game.relationship("pala") >= 2 and _pala_here():
				key = "argument"
		"memorial":
			if Game.midas_dead() and _pala_here():
				key = "pala_note"
	if key == "" or seen(key):
		return ""
	return key


func room_scene(id: String) -> void:
	var key := room_key(id)
	if key == "" or s.a(room_cast(id)[0].id if not room_cast(id).is_empty() else "") == null:
		return
	mark(key)
	s.w.busy = true
	await call("_" + key)
	await s.pan_back(0.4)
	s.w.busy = false


func _midas_bread() -> void:
	var mid := s.a("scene_midas")
	await s.pan(Vector2i(17, 6), 0.6)
	await s.say("", "Midas is at the far table, sliding a bread roll into his jacket, very slowly, as if slowness made it invisible.")
	mid.face_toward(s.w.player.position)
	mid.emote("!", 0.8)
	await s.say("midas", "It's for later. In case. Mom always kept bread for later.", "uneasy")
	await s.say("midas", "...You can have half. Later.", "smile")
	mid.emote("heart", 1.2)
	await s.wait(0.6)
	await s.leave("scene_midas", [Vector2i(13, 6)] + Building.room_out("mess"), 40.0)


func _argument() -> void:
	var hiro := s.a("scene_hiro")
	var pala := s.a("scene_pala")
	await s.pan(Vector2i(10, 4), 0.6)
	await s.say("", "Voices, before you're even through the door.")
	pala.set_mood("angry")
	await s.say("pala", "Look at your numbers, Hiro! Look at them!", "angry")
	await s.say("hiro", "I'm not a number. I'm the fastest thing in this building.", "flat")
	await s.say("pala", "That's what scares me.", "sad")
	hiro.face_toward(s.w.player.position)
	await s.wait(0.4)
	s.leave("scene_hiro", Building.room_out("rooftop"), 50.0)
	await s.say("", "He walks past you without looking.")
	pala.face_toward(s.w.player.position)
	await s.say("pala", "...He used to laugh at everything. Do you remember? He used to laugh.", "sad")
	await s.leave("scene_pala", Building.room_out("rooftop"), 40.0)


func _pala_note() -> void:
	var pala := s.a("scene_pala")
	await s.pan(Vector2i(5, 3), 0.6)
	await s.say("", "Pala is at the wall of names, tucking a folded paper into the gap beside MIDAS.")
	pala.face_toward(s.w.player.position)
	await s.say("pala", "His mom's tomato recipe. He told it to me once, start to finish, like a prayer.", "sad")
	await s.say("pala", "Somebody should have it written down. Somebody here.", "sad")
	pala.emote("...", 1.2)
	await s.wait(0.6)
	await s.leave("scene_pala", Building.room_out("memorial"), 40.0)


# ----------------------------------------------------------------- parade ---

func barrier() -> void:
	## At the parade: your mother pushes to the barrier, and a guard steps in.
	if seen("barrier"):
		return
	mark("barrier")
	await s.pan(Vector2i(5, 12), 0.8)
	await s.walk("mother", [Vector2i(5, 12)], 60.0)
	s.a("mother").hop(3.0)
	s.emote("mother", "heart", 1.0)
	await s.say("", "Your mother pushes through to the barrier and waves both arms, like you might miss her.")
	var guard := await s.enter({"id": "scene_guard", "who": "officer", "dir": 0}, Vector2i(0, 11), [Vector2i(6, 11)], 60.0)
	guard.face(0)
	await s.say("officer", "Ma'am. Behind the line, please.")
	await s.walk("mother", [Vector2i(4, 13)], 40.0)
	s.face("mother", 1)
	s.face_to("father", "mother")
	await s.say("", "She steps back. Your father takes her hand without looking at it.")
	await s.leave("scene_guard", [Vector2i(0, 11)], 60.0)
	await s.pan_back(0.6)
