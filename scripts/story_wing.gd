class_name StoryWing
extends RefCounted
## The rest of the hub building (Building): walking between the Commons,
## Operations, the Main Concourse, the Engineering Bay, the dormitories and
## the two decks of rooms, and everything you can look at on the way.
## Visiting, reading and playing here never use up the interval's one
## conversation.
##
## Rooms: rec room (TV, Starbox, ping-pong, cards), mess hall, archive (lore
## terminals), training gym, observation deck (stargazing with Pala), memorial
## hall (it grows), rooftop garden (Midas' tomatoes). Dorms: your room (your
## locker), Hiro's, Pala's and Midas' rooms, the washroom.

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

func build(id: String) -> Dictionary:
	## A building map with its people in it.
	if id == "commons":
		return s.hub._map()
	var mp := Building.map(id)
	mp.npcs = mp.npcs.duplicate()
	if id.begins_with("room_") or id.begins_with("dorm_"):
		# whoever a scene needs is already in the room when it fades in
		mp.npcs.append_array(s.scenes.room_cast(scene_key(id)))
		if id == "room_rooftop" and not bool(Game.story.get("room_rooftop_seen", false)) and not Game.midas_dead():
			mp.npcs.append({"id": "midas", "who": "midas", "tile": Vector2i(5, 6), "dir": 3, "pose": "sit"})
	# after the interval's conversation, the pilots are wherever they go
	var here := {}
	for n in mp.npcs:
		here[n.get("id", n.get("who", ""))] = true
	for who in ["hiro", "pala", "midas"]:
		var sp := away_spot(who)
		if sp.get("map", "") == id and not here.has("away_" + who):
			var n := {"id": "away_" + who, "who": who, "tile": sp.tile, "dir": sp.dir}
			for k in ["mood", "pose", "offset"]:
				if sp.has(k):
					n[k] = sp[k]
			mp.npcs.append(n)
	return mp


static func scene_key(id: String) -> String:
	## Room scenes are keyed by the bare room name, dorm scenes by map id.
	return id.trim_prefix("room_") if id.begins_with("room_") else id


func away_spot(who: String) -> Dictionary:
	## Where a pilot goes once the interval's one conversation is spent:
	## {map, tile, dir, mood?}, or {} if they're nowhere to be found. Before
	## that they're all in the Commons.
	if not s.hub.used:
		return {}
	match who:
		"hiro":
			if Game.relationship("hiro") >= 2:
				# alone in his room, in front of his turn times
				return {"map": "dorm_hiro", "tile": Vector2i(3, 2), "dir": 1, "mood": "flat"}
			return {"map": "room_gym", "tile": Vector2i(12, 3), "dir": 2}
		"pala":
			if not s.scenes._pala_here():
				return {}
			var r := Game.relationship("pala")
			if r == 0:
				# on the rec room floor, watching channel four
				return {"map": "room_rec", "tile": Vector2i(5, 5), "dir": 1}
			if r == 1 and StoryScenes.seen("pala_map") and unlocked("archive"):
				return {"map": "room_archive", "tile": Vector2i(6, 3), "dir": 1}
			return {"map": "dorm_pala", "tile": Vector2i(5, 3), "dir": 1}
		"midas":
			if Game.midas_dead():
				return {}
			if Game.relationship("midas") >= 2:
				return {"map": "dorm_midas", "tile": Vector2i(3, 4), "dir": 3, "mood": "sad"}
			return {"map": "dorm_midas", "tile": Vector2i(5, 3), "dir": 1}
	return {}


func go(to: String) -> void:
	## Through a door or down the stairs to another part of the building.
	var from := str(s.w.def.id)
	if to.begins_with("room_") and not unlocked(to.trim_prefix("room_")):
		Sfx.play("cancel", 0.8, -6.0)
		await s.say("", ["%s. The door is sealed." % Building.name_of(to).to_upper(), unlock_hint(to.trim_prefix("room_"))])
		return
	if to in ["dorm_hiro", "dorm_pala", "dorm_midas"] and not await _knock(to.trim_prefix("dorm_")):
		return
	var stairs := (from == "concourse" and to in ["rec_deck", "upper_deck"]) or (to == "concourse" and from in ["rec_deck", "upper_deck"])
	if stairs:
		Sfx.play("step", 0.8, -8.0)
	else:
		Sfx.play("door", 1.0 if Building.PARENT.get(to, "") == from else 0.9, -8.0)
	var mp := build(to)
	var arr := Building.arrival(to, from, mp)
	await s.m.change_map(mp, arr[0], arr[1])
	s.w.show_area_name()
	var seen := to + "_seen"
	if not bool(Game.story.get(seen, false)):
		Game.story[seen] = true
		await _first_visit(to)
	if to.begins_with("room_") or to.begins_with("dorm_"):
		await s.scenes.room_scene(scene_key(to))
	mark_route()


func mark_route() -> void:
	## Once the interval's conversation is spent, the marker shows the next
	## step back toward the deploy terminal in Operations.
	if not s.hub.used or s.w == null:
		return
	var t = s.w.def.get("route", null)
	if t is Vector2i:
		s.w.show_marker(t)


func exit(e: Dictionary) -> void:
	var to: String = e.get("to", "")
	if to != "":
		await go(to)


func _knock(who: String) -> bool:
	## Someone else's room: knock first.
	var nm := who.capitalize()
	var home: bool = away_spot(who).get("map", "") == "dorm_" + who
	if home:
		Sfx.play("knock", 1.0, -6.0)
		match who:
			"hiro":
				if s.scenes.room_key("dorm_hiro") != "":
					await s.say("", "You knock. No answer. Through the door, very faintly, someone is counting.")
					return await s.ask("Go in?", ["Go in", "Leave it"]) == 0
				await s.say("", "\"It's open,\" Hiro says, with no interest at all in who it is.")
			"pala":
				await s.say("", "The door opens a crack. One eye. Then it opens all the way.")
			"midas":
				await s.say("", "\"It's open!\" Midas calls. \"Unless you're inspection. Then it's not.\"")
		return true
	if who == "midas" and Game.midas_dead():
		await s.say("", ["The nameplate on this door has been unscrewed. Four little holes are left.", "The door isn't locked."])
		if s.scenes.room_key("dorm_midas") != "":
			await s.say("", "On the other side, someone is breathing very quietly.")
	else:
		Sfx.play("knock", 1.0, -6.0)
		await s.say("", "You knock on %s's door. Nobody answers. %s" % [nm, "They're probably in the Commons." if who != "pala" or not bool(Game.story.pala_unavailable) else "Nobody has answered for a while."])
	return await s.ask("Go in?", ["Peek inside", "Leave it"]) == 0


# ------------------------------------------------------------- first visits ---

func _first_visit(id: String) -> void:
	match id:
		"ops":
			await s.say("", ["Operations. The deploy terminal waits in the middle of the room, lit like an altar.", "The comm booth for calls home is in the corner. Nobody uses the benches."])
		"concourse":
			await s.say("", ["The main concourse. Everything else in the building comes off it.", "There's a directory on the wall, for when you forget where you are."])
		"engineering":
			await s.say("", "The Engineering Bay. It smells of solder. The big door at the back hums and doesn't open.")
		"dorms":
			await s.say("", ["The dormitories. A row of doors with nameplates, a laundry basket nobody empties.", "Lights-out has not been called."])
		"dorm_you":
			await s.say("", "Your room. It's the size of your bed and a half. Somebody has already made the bed the regulation way.")
		"rec_deck":
			await s.say("", "The lower deck: the rec room, the mess hall and the gym. You can hear a ping-pong ball from the stairs.")
		"upper_deck":
			await s.say("", ["The upper deck. Carpet up here, and long windows. People talk quieter without being told to.", "Some doors are sealed. The plaques say the seals lift 'with seniority.'"])
		"room_rec":
			await s.say("", "The rec room. Someone has stacked the cushions into a fort and someone else has knocked it over.")
		"room_mess":
			await s.say("", "The mess hall smells of warm metal and Nutri-Loaf.")
		"room_archive":
			await s.say("", "The archive: binders, terminals, and a quiet that sounds expensive.")
		"room_gym":
			await s.say("", "The training gym. The sim pods hum even when nobody is in them.")
		"room_observation":
			await _stargazing()
		"room_memorial":
			await s.say("", ["The memorial hall. Nobody calls it that out loud.", "There is a wall of names, and someone keeps the candles lit."])
		"room_rooftop":
			await _rooftop_scene()


func _stargazing() -> void:
	## The observation deck's first night. You and Pala go up to the glass side
	## by side; then the view turns to the sky, and the shapes she made up when
	## she first got here are drawn star by star as she talks you through them.
	s.w.busy = true
	await s.say("", "The whole wall is window. The stars here are close enough to be rude.")
	if bool(Game.story.pala_unavailable) or bool(Game.story.get("pala_escape_chosen", false)):
		await s.say("", "You stand at the glass for a while, alone. It is the quietest place in the Academy.")
		s.w.busy = false
		return
	var door := Building.room_door("observation")
	# you go up to the glass
	await s.walk("player", [Vector2i(door.x, 5), Vector2i(door.x, 2)], 40.0)
	s.w.player.face(1)
	await s.wait(0.5)
	# Pala comes in through the door behind you and stands right beside you
	await s.enter({"id": "pala", "who": "pala", "dir": 1}, Vector2i(door.x + 1, door.y),
		[Vector2i(door.x + 1, 5), Vector2i(door.x + 1, 2)], 40.0)
	s.face("pala", 3)
	s.w.player.face(2)
	await s.say("pala", "You found it. I come here when the dorm gets too loud. Or too quiet.", "smile")
	s.face("pala", 1)
	s.w.player.face(1)
	await s.wait(0.4)
	await s.say("pala", "When I first got here I made up my own constellations. Want to see?", "")
	await s.m.fade_out(0.6)
	var c := _sky_view()
	await s.m.fade_in(0.8)
	await s.wait(0.6)
	var sky: Node2D = c.get_meta("sky")
	for i in STAR_SHAPES.size():
		var shape: Dictionary = STAR_SHAPES[i]
		if i > 0:
			var pan := sky.create_tween()
			pan.tween_property(sky, "position:x", -160.0 * i, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			await pan.finished
		var group: Node2D = sky.get_node(shape.id)
		for step in shape.steps:
			if step.has("draw"):
				_strokes(group, step.draw)
			if step.has("do"):
				_star_trick(group, step.do)
			await s.say("pala", step.say, step.get("mood", "smile"))
		var name_l: Label = group.get_meta("label")
		name_l.create_tween().tween_property(name_l, "modulate:a", 1.0, 0.5)
		Sfx.play("blip", 1.9, -12.0)
		await s.say("pala", shape.name, "smile")
	await s.say("you", "They're good.", "smile")
	await s.say("pala", "They're terrible. That's why I like them. Nobody here can tell me they're wrong.", "smile")
	await s.m.fade_out(0.6)
	c.queue_free()
	await s.m.fade_in(0.6)
	s.face("pala", 3)
	s.w.player.face(2)
	s.emote("pala", "heart", 1.4)
	await s.say("pala", "Next time you have to make one up. Those are the rules.", "smile")
	Game.story.stargazed = true
	await s.leave("pala", Building.room_out("observation"), 40.0)
	s.w.busy = false


## Pala's constellations, centred 160 px apart across the sky. Points are
## relative to each shape's centre; every step is one line of hers, drawing
## the strokes she's describing while she says it.
const STAR_SHAPES := [
	{"id": "chair", "name": "The Kitchen Chair.", "label": "THE KITCHEN CHAIR", "pivot": Vector2(22, 38),
		"stars": [Vector2(-22, -36), Vector2(-22, -10), Vector2(-22, 10), Vector2(22, 10), Vector2(22, 38), Vector2(-22, 38)],
		"steps": [
			{"say": "Start with the bright one at the top and go straight down. That's the back.",
				"draw": [[Vector2(-22, -36), Vector2(-22, -10), Vector2(-22, 10)]]},
			{"say": "Across, that's the seat. Then two legs.",
				"draw": [[Vector2(-22, 10), Vector2(22, 10)], [Vector2(22, 10), Vector2(22, 38)], [Vector2(-22, 10), Vector2(-22, 38)]]},
			{"say": "It's the chair in our kitchen. One leg's shorter, so it rocks when you sit on it.", "do": "rock"},
		]},
	{"id": "cup", "name": "The Cup My Brother Broke.", "label": "THE CUP MY BROTHER BROKE",
		"stars": [Vector2(-20, -22), Vector2(20, -22), Vector2(13, 22), Vector2(-13, 22), Vector2(19, -14), Vector2(32, -4), Vector2(15, 10), Vector2(-36, 34)],
		"steps": [
			{"say": "This one's a cup. The rim goes across the top...", "draw": [[Vector2(-20, -22), Vector2(20, -22)]]},
			{"say": "...down to the bottom, and there's the handle.",
				"draw": [[Vector2(20, -22), Vector2(13, 22), Vector2(-13, 22), Vector2(-20, -22)], [Vector2(19, -14), Vector2(32, -4), Vector2(15, 10)]]},
			{"say": "See the little one off on its own? That's the bit that broke off.", "do": "chip"},
			{"say": "My brother broke it. He said the cup did it.", "mood": ""},
		]},
	{"id": "dog", "name": "And that one's just a dog. Every sky needs a dog.", "label": "JUST A DOG",
		"stars": [Vector2(-42, -12), Vector2(-30, -18), Vector2(-34, -30), Vector2(-22, -6), Vector2(18, -6), Vector2(30, -22), Vector2(-20, 24), Vector2(16, 24)],
		"steps": [
			{"say": "Last one. Nose, head, and an ear sticking up.",
				"draw": [[Vector2(-42, -12), Vector2(-30, -18), Vector2(-34, -30)]]},
			{"say": "Then along the back to the tail.",
				"draw": [[Vector2(-30, -18), Vector2(-22, -6), Vector2(18, -6), Vector2(30, -22)]]},
			{"say": "And legs. It's wagging. You can't tell, but it is.",
				"draw": [[Vector2(-22, -6), Vector2(-20, 24)], [Vector2(18, -6), Vector2(16, 24)]], "do": "wag"},
		]},
]
const SKY_Y := 48.0


func _sky_view() -> Cinema:
	## Full screen: the night sky through the deck's window, with the two of
	## you from behind, leaning on the sill. The sky is twice the screen wide
	## and pans; the frame and the two of you stay put.
	var c := Cinema.open(Color("0e1119"))
	var sky := Node2D.new()
	c.add_child(sky)
	c.move_child(sky, c.bg.get_index() + 1)
	c.set_meta("sky", sky)
	var bgt := TextureRect.new()
	bgt.texture = Art.space(640, 180, "stargazing")
	sky.add_child(bgt)
	# a scatter of real stars, some of them twinkling
	for i in 46:
		var st := Sprite2D.new()
		st.centered = false
		st.texture = Art.star(1 if Pal.hash2(i, 7) < 0.25 else 0)
		st.position = Vector2(int(Pal.hash2(i, 5) * 636), int(Pal.hash2(i, 6) * 112)) - Vector2(2, 2)
		st.modulate.a = 0.5 + Pal.hash2(i, 8) * 0.4
		sky.add_child(st)
		if i % 3 == 0:
			var tw := st.create_tween().set_loops()
			tw.tween_property(st, "modulate:a", 0.2, 0.8 + Pal.hash2(i, 9))
			tw.tween_property(st, "modulate:a", st.modulate.a, 0.8 + Pal.hash2(i, 10))
	# her stars are there from the start; she just joins them up
	for i in STAR_SHAPES.size():
		var shape: Dictionary = STAR_SHAPES[i]
		# the shape lives in g's "art" child; "tilt" turns every point of it
		# about "pivot" (the chair rocks on a foot), re-rounded to whole pixels
		var g := Node2D.new()
		g.name = shape.id
		g.position = Vector2(160 + 160 * i, SKY_Y)
		g.set_meta("pivot", shape.get("pivot", Vector2.ZERO))
		g.set_meta("tilt", 0.0)
		sky.add_child(g)
		var art := Node2D.new()
		art.name = "art"
		g.add_child(art)
		var lights := {}
		for p in shape.stars:
			var st := Sprite2D.new()
			st.centered = false
			st.texture = Art.star(1)
			st.position = (p as Vector2) - Vector2(2, 2)
			st.set_meta("p", p)
			art.add_child(st)
			lights[p] = st
		g.set_meta("lights", lights)
		var l := Art.label(shape.label, Pal.LEMON)
		l.size = Vector2(160, 12)
		l.position = Vector2(80 + 160 * i, 2)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.modulate.a = 0.0
		sky.add_child(l)
		g.set_meta("label", l)
	# the window frame: side posts, two mullions and the sill
	var frame := Node2D.new()
	c.add_child(frame)
	c.move_child(frame, sky.get_index() + 1)
	for x in [0, 102, 215, 316]:
		var post := ColorRect.new()
		post.color = Pal.INK2
		post.position = Vector2(x, 0)
		post.size = Vector2(4, 180)
		frame.add_child(post)
		var edge := ColorRect.new()
		edge.color = Pal.STEEL.darkened(0.3)
		edge.position = Vector2(x + (3 if x < 160 else 0), 0)
		edge.size = Vector2(1, 180)
		frame.add_child(edge)
	var sill := ColorRect.new()
	sill.color = Pal.INK2
	sill.position = Vector2(0, 112)
	sill.size = Vector2(320, 68)
	frame.add_child(sill)
	var lip := ColorRect.new()
	lip.color = Pal.STEEL.darkened(0.2)
	lip.position = Vector2(0, 112)
	lip.size = Vector2(320, 1)
	frame.add_child(lip)
	# the two of you, from behind, shoulder to shoulder
	var shade := Color(0.34, 0.36, 0.52)
	# standing just above where the dialog box sits, so they stay in view
	c.person(Game.player_spec(), Vector2(152, 127), 1).modulate = shade
	c.person(Data.CAST["pala"], Vector2(167, 127), 1).modulate = shade
	return c


func _strokes(group: Node2D, strokes: Array) -> void:
	## Draws Pala's lines one after another, each growing from star to star,
	## lighting the stars as it reaches them.
	for pts in strokes:
		if not is_instance_valid(group):
			return
		await _stroke(group, pts)


func _stroke(group: Node2D, pts: Array) -> void:
	## One of her lines, grown point to point. Drawn a pixel at a time: a 1 px
	## Line2D loses its slanted runs to pixel snapping.
	var lights: Dictionary = group.get_meta("lights")
	var line := Node2D.new()
	var drawn: Array = [pts[0]]
	line.set_meta("pts", drawn)
	line.set_meta("group", group)
	line.draw.connect(func() -> void: _draw_stroke(line))
	var art := group.get_node("art")
	art.add_child(line)
	art.move_child(line, 0)
	_light(lights, pts[0])
	for k in range(1, pts.size()):
		var a: Vector2 = pts[k - 1]
		var b: Vector2 = pts[k]
		drawn.append(a)
		var tw := line.create_tween()
		tw.tween_method(func(v: float) -> void:
			drawn[k] = a.lerp(b, v).round()
			line.queue_redraw(), 0.0, 1.0, a.distance_to(b) / 70.0)
		await tw.finished
		if not is_instance_valid(line):
			return
		Sfx.play("blip", 1.4 + k * 0.08, -16.0)
		_light(lights, b)


func _draw_stroke(line: Node2D) -> void:
	var pts: Array = line.get_meta("pts")
	var g: Node2D = line.get_meta("group")
	var col := Color(Pal.LEMON, 0.8)
	for k in range(1, pts.size()):
		var a := _tilted(g, pts[k - 1])
		var b := _tilted(g, pts[k])
		var n := int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
		for i in n + 1:
			line.draw_rect(Rect2(a.lerp(b, float(i) / maxf(n, 1)).round(), Vector2.ONE), col)


func _tilted(g: Node2D, p: Vector2) -> Vector2:
	var pv: Vector2 = g.get_meta("pivot")
	return ((p - pv).rotated(float(g.get_meta("tilt"))) + pv).round()


func _set_tilt(g: Node2D, a: float) -> void:
	g.set_meta("tilt", a)
	for ch in g.get_node("art").get_children():
		if ch.has_meta("pts"):
			ch.queue_redraw()
		elif ch.has_meta("p"):
			ch.position = _tilted(g, ch.get_meta("p")) - Vector2(2, 2)


func _light(lights: Dictionary, p: Vector2) -> void:
	var st: Sprite2D = lights.get(p)
	if st and is_instance_valid(st):
		st.texture = Art.star(2)


func _star_trick(group: Node2D, what: String) -> void:
	## The little bits of business: the chair rocks on its short leg, the
	## broken-off star blinks, the dog's tail wags.
	match what:
		"rock":
			var tw := group.create_tween().set_loops(3)
			tw.tween_method(func(v: float) -> void: _set_tilt(group, v), 0.0, 0.09, 0.3).set_trans(Tween.TRANS_SINE)
			tw.tween_method(func(v: float) -> void: _set_tilt(group, v), 0.09, 0.0, 0.3).set_trans(Tween.TRANS_SINE)
		"chip":
			var st: Sprite2D = (group.get_meta("lights") as Dictionary).get(Vector2(-36, 34))
			var tw := st.create_tween().set_loops(4)
			tw.tween_property(st, "modulate", Color(Pal.LEMON, 1.0), 0.2)
			tw.tween_property(st, "modulate", Color.WHITE, 0.3)
		"wag":
			await s.wait(1.0)
			var tail: Sprite2D = (group.get_meta("lights") as Dictionary).get(Vector2(30, -22))
			var line: Node2D = null
			for ch in group.get_node("art").get_children():
				if ch.has_meta("pts") and (ch.get_meta("pts") as Array).size() == 4:
					line = ch
			if line == null or tail == null:
				return
			var tw := group.create_tween().set_loops(5)
			for leg in [[Vector2(30, -22), Vector2(35, -15)], [Vector2(35, -15), Vector2(30, -22)]]:
				tw.tween_method(func(v: Vector2) -> void:
					(line.get_meta("pts") as Array)[3] = v.round()
					line.queue_redraw()
					tail.position = v.round() - Vector2(2, 2), leg[0], leg[1], 0.16)


func _rooftop_scene() -> void:
	s.w.busy = true
	await s.say("", "The rooftop garden. Real dirt in steel boxes, and over it a sky with nothing between you and it.")
	if not Game.midas_dead() and s.a("midas") != null:
		# Midas was already up here, kneeling by his planter
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
		"away_hiro":
			var hr := Game.relationship("hiro")
			if hr < 3:
				n.face_toward(s.w.player.position)
			var hl := ["Ten more. Then ten more. You want in? No? Your loss.",
				"When I'm not linked my hands don't know what to do with themselves. So: this.",
				"Shh. I'm counting.", "Deployment window opens in forty-one minutes."]
			await s.say("hiro", hl[clampi(hr, 0, 3)], ["still_smiling", "", "flat", "hollow"][clampi(hr, 0, 3)])
		"away_pala":
			n.face_toward(s.w.player.position)
			var pl := "Channel four. Don't tell anyone I watch it. Don't tell anyone it's good."
			match s.w.def.id:
				"room_archive":
					pl = "Sit. Act bored. The camera in the corner likes bored."
				"dorm_pala":
					pl = "Close the door behind you. ...Thanks." if Game.relationship("pala") < 3 else "Not tonight. Tonight I'm packing light."
			await s.say("pala", pl, "")
		"away_midas":
			n.face_toward(s.w.player.position)
			if Game.relationship("midas") >= 2:
				await s.say("midas", "I'm okay. I'm just going to lie here a minute. Maybe two.", "sad")
			else:
				await s.say("midas", "I'm writing to Mom. I've crossed out 'I'm fine' four times. It keeps getting less true.", "smile")
		"eater":
			await s.say("", "\"Don't look at me. I'm eating slowly so it lasts longer.\"")
		"deck_kid":
			var dk := ["You're going to the gym? Nobody goes to the gym. Hiro goes to the gym.",
				"The mess hall has pudding on deployment days. You can tell it's a deployment day because there's pudding.",
				"The stairs go up and down. That's it. That's the whole building. I've checked."]
			n.face_toward(s.w.player.position)
			await s.say("", "\"%s\"" % dk[Game.completed_count() % dk.size()])
		"pala", "midas":
			await s.say(id, "...", "")
		_:
			await s.say("", "...")


# ---------------------------------------------------------------- examine ---

func examine(ev: Dictionary) -> void:
	var id: String = ev.get("id", "")
	if id.begins_with("go:"):
		await go(id.trim_prefix("go:"))
		return
	if id.begins_with("room:"):
		await go("room_" + id.trim_prefix("room:"))
		return
	if await _building_examine(id):
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
			var bag: Sprite2D = s.w.prop_sprite("punchbag")
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


# ------------------------------------------------------ around the building ---

func _building_examine(id: String) -> bool:
	## Things in the halls, Operations, Engineering and the dorms. Returns
	## false for anything that isn't one of them.
	var hr := Game.relationship("hiro")
	var pr := Game.relationship("pala")
	var dead := Game.midas_dead()
	match id:
		# Commons and halls
		"directory":
			await s.say("", ["BUILDING DIRECTORY. This level: PILOT COMMONS, OPERATIONS, ENGINEERING BAY, DORMITORIES.",
				"LOWER DECK (stairs, west): REC ROOM, MESS HALL, TRAINING GYM.",
				"UPPER DECK (stairs, east): ARCHIVE, OBSERVATION DECK, MEMORIAL HALL, ROOF ACCESS.",
				"Someone has added, very small, by the Commons: 'you are here (unfortunately)'."])
		"games":
			await s.say("", "Board games with pieces missing, and a stack of Academy readers. Every reader ends with a robot saving a city.")
		"commons_table":
			await s.say("", "A table covered in ration-chit IOUs from a card game that has been going on for weeks.")
		"hallwindow":
			await s.say("", "The concourse window looks down into the launch yard. The cradles are covered with tarps. Nobody is out there.")
		"upperwindow":
			await s.say("", "From up here you can see the shield grid's glow over the horizon, like a city that's always just out of sight.")
		"deck_vending":
			Sfx.play("beep", 1.2, -8.0)
			await s.say("", "A vending machine that only sells PROTEKTOR CRUNCH bars. Six of the eight slots are empty.")
		"ladder":
			await s.say("", ["PING-PONG LADDER. Names on magnets, moved up and down all week.", "Half the magnets have been taken off. The gaps haven't been closed up."])
		# Operations
		"opswindow":
			await s.say("", "Through the glass: the launch cradles in a long row, each with a chair at its heart and cables down into the floor.")
		"ops_holo":
			await s.say("", "A hologram of the defense roster. The planets turn slowly. None of them shows a population.")
		"flightlog":
			await s.say("", ["DEPLOYMENT LOG. Your number, your planets, your times.", "There's a column for SYNC %. There isn't a column for anything else."])
		# Engineering
		"workshop":
			await s.m.workshop()
		"parts":
			await s.say("", "Shelves of parts in labelled bins: SHIELD COILS. THRUSTER CAPS. NEURAL LEADS (CHILD).")
		"diagnostics":
			await s.say("", ["DIAGNOSTICS. Every Protektor in the program, listed as a percentage.", "Yours is green. A few near the bottom are grey, with no number at all."])
		"eng_crate":
			await s.say("", "A crate stencilled RETURNED UNITS. It's sealed, and lighter than it looks.")
		"baydoor":
			Sfx.play("knock", 0.6, -10.0)
			await s.say("", ["LAUNCH CRADLES. AUTHORISED PERSONNEL ONLY.", "The door is warm to the touch. Behind it, something hums in a long, even row."])
		# Dormitories
		"rota":
			await s.say("", "LIGHTS-OUT 21:00. WAKE 05:30. Under it, in pencil, somebody has added NAPS: NEVER.")
		"laundry":
			await s.say("", "A laundry basket full of identical grey shirts. You can only tell which is yours by the name tape.")
		"dormwindow":
			await s.say("", "The dorm window looks across at the next wing over. In one of its windows, a kid is looking back at you.")
		"yourbed":
			if Game.completed_count() >= 5:
				await s.say("", "Your bunk. You haven't slept in it much lately. You don't seem to need to.")
			else:
				await s.say("", "Your bunk. The blanket is folded the regulation way. You don't remember learning the regulation way.")
		"yourdesk":
			if await _letter_at_desk():
				return true
			if Game.home_contacts() > 0:
				await s.say("", ["Your notes from the calls home, in your own handwriting: 'kitchen light', 'they leave it on',", "'call again'. That one's underlined."])
			else:
				await s.say("", "Academy stationery. You've started a letter home three times. Each one begins 'Training is going well.'")
		"locker":
			await s.say("", "Your locker. A drawing is taped inside the door. You don't remember putting it there, but it is yours.")
		"hirobed":
			if hr >= 3:
				await s.say("", "Hiro's bunk. It hasn't been slept in. The blanket is still perfect.")
			else:
				await s.say("", "Hiro's bunk, made so tight a coin would bounce. He bounced one, once, to prove it.")
		"hiroboard":
			if hr >= 2:
				await s.say("", "Turn times pinned in rows, each faster than the last. There used to be doodles in the margins. They've been torn off.")
			else:
				await s.say("", "Hiro's turn times, printed and pinned up in rows. In the margin, a doodle of two stick pilots racing. One has your hair.")
		"hirocrate":
			await s.say("", "Wrist tape, two left shoes, and the wrapper from a contraband sweet, folded into a tiny star.")
		"hirobag":
			Sfx.play("knock", 0.7, -4.0)
			await s.say("", "A punchbag hung from a ceiling hook. Room inspection has written it up four times.")
		"palabed":
			await s.say("", "Pala's bunk. There's a pen mark on the pillow, and a torch under it.")
		"palastars":
			if bool(Game.story.get("stargazed", false)):
				await s.say("", "Pala's star charts, in pencil. You know these: the Kitchen Chair, the Cup, and a dog.")
			else:
				await s.say("", "Star charts in pencil. None of the shapes match any constellation you know.")
		"paladesk":
			await s.say("", "A desk lamp angled at the floor, not the desk. Easier to read under the blanket that way.")
		"palashelf":
			if pr >= 2:
				await s.say("", "The shelf is empty. The binder labels are still stuck to it: RECOVERY. TRANSFERS. THRESHOLDS.")
			else:
				await s.say("", "Binders in Pala's handwriting: RECOVERY. TRANSFERS. THRESHOLDS. The last one is empty.")
		"midasbed":
			if dead:
				await s.say("", "The bunk has been stripped to the frame. Whatever was tucked into it is gone.")
			else:
				await s.say("", "Midas' bunk. A photo is tucked into the frame: a woman in a kitchen, laughing, out of focus.")
		"midasdesk":
			if dead and str(Game.story.get("midas_letter", "")) == "kept":
				await s.say("", ["The desk has been cleared, but not well. At the back of the drawer, under a bread roll in a napkin:", "a folded letter. MOM, on the front, in Midas' round handwriting. It was never posted."])
				if await s.ask("Take the letter?", ["Take it", "Leave it"]) == 0:
					Game.story.midas_letter = "held"
					Sfx.play("paper", 1.2, -8.0)
					await s.say("", "You put it in your jacket, next to your badge. The comm booth in Operations still has a post slot.")
			elif dead:
				await s.say("", "The desk has been cleared. Whoever cleared it missed a bread roll in a napkin at the back of the drawer. For later.")
			else:
				await s.say("", "A bread roll wrapped in a napkin, 'for later'. A tin rocket with the paint worn off its nose. A blue cup, not chipped yet.")
		"seedling":
			await s.say("", "A tomato seedling in a ration tin. A paper tag: MIDAS. A second, smaller one: PLEASE DON'T PICK YET.")
		"effects":
			await s.say("", ["A crate: PERSONAL EFFECTS - MIDAS - HOLD FOR TRANSFER.", "It doesn't say where to."])
		"mirror":
			var face := "Your face. It takes a second, every time now, to be sure it's yours." if Game.completed_count() >= 5 \
				else "Your face. Tired, but yours. The badge glows faintly through your collar."
			await s.say("", ["The tap runs at exactly the right temperature. It has never been any other temperature.", face])
		"showers":
			await s.say("", "Showers on a ninety-second timer. Someone has scratched a tally of how often they've run out mid-rinse.")
		_:
			return false
	return true


# ---------------------------------------------------------- Midas' letter ---
## Midas asks you to post a letter home (StoryScenes._midas_letter). Story
## key midas_letter: "held" (in your jacket), "kept" (in his drawer),
## "posted" (from the Operations booth while he was alive), "posted_late".

const MIDAS_LETTER := ["Mom. They feed us well. Three ways, all sliced.",
	"I'm saving bread for when I come home, so don't buy any. Don't throw out the blue cup even though it's chipped.",
	"I'm okay. I'm being brave. I don't want to be brave anymore. Love, M."]


func post_letter() -> bool:
	## At the comm booth's post slot. True if there was a letter to post.
	if str(Game.story.get("midas_letter", "")) != "held":
		return false
	Sfx.play("paper", 1.0, -6.0)
	if Game.midas_dead():
		Game.story.midas_letter = "posted_late"
		await s.say("", ["You feed Midas' letter into the post slot.", "It's the right address. It's the wrong week. You post it anyway."])
	else:
		Game.story.midas_letter = "posted"
		await s.say("", ["You feed Midas' letter into the post slot. MOM, in round letters, disappears into the wall.", "Your record is good. They won't read yours as hard."])
	return true


func _letter_at_desk() -> bool:
	## After Midas is gone, his letter (or the answer to it) waits on your desk.
	if not Game.midas_dead():
		return false
	match str(Game.story.get("midas_letter", "")):
		"held":
			await s.say("", "Midas' letter is on your desk where you left it. MOM, on the front. You never posted it.")
			if await s.ask("Read it?", ["Read it", "Don't"]) == 0:
				await s.say("", MIDAS_LETTER)
			await s.say("", "The comm booth in Operations still has a post slot.")
			return true
		"posted":
			if bool(Game.story.get("midas_reply_read", false)):
				await s.say("", "His mother's letter, folded back into its envelope. You keep it face down, so the name doesn't look at you.")
				return true
			Game.story.midas_reply_read = true
			Sfx.play("paper", 1.1, -6.0)
			await s.say("", ["A letter on your desk, forwarded from Records. Addressed to MIDAS, from his mother.",
				"The envelope has been opened and taped shut again. It came to you because yours was the only other name on his contact list."])
			await s.say("", ["My darling. Your letter came. I laughed at the bread.",
				"I put the blue cup on the windowsill, so it can see the sky where you are.",
				"You don't have to be brave for me. Come home and be ordinary. Love, Mom."])
			s.w.player.emote("...", 1.6)
			return true
		"posted_late":
			await s.say("", "Nothing has come back from the letter you posted for Midas. You didn't expect it to. You check anyway.")
			return true
	return false


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
