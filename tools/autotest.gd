extends Node
## Debug autopilot (PK_TEST=<scenario>, PK_OUT=<dir>): drives the game and saves
## screenshots. A tiny bot plays missions: shield toward rocks and shots, gun
## toward everything else.

var out := ""
var main: Node
var auto_talk := true
var bot := false
var shots_taken := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	out = OS.get_environment("PK_OUT")
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 60
	main = Game.main
	_run.call_deferred(OS.get_environment("PK_TEST"))


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("shot ", name, " fps=", Engine.get_frames_per_second())


func wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _send(action: String, pressed: bool) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = pressed
	Input.parse_input_event(e)


func tap(action: String, t: float = 0.2) -> void:
	_send(action, true)
	await get_tree().process_frame
	await get_tree().process_frame
	_send(action, false)
	await wait(t)


func hold(action: String, t: float) -> void:
	_send(action, true)
	await wait(t)
	_send(action, false)


func _has_starmap() -> bool:
	for c in main.cine_layer.get_children():
		if c is StarMap:
			return true
	return false


func _process(_d: float) -> void:
	if auto_talk and main.dialog.visible and Engine.get_process_frames() % 9 == 0:
		_send("accept", true)
		_send.call_deferred("accept", false)
	if bot:
		_bot()


func _bot() -> void:
	for c in main.mission_layer.get_children():
		if not (c is Mission):
			continue
		var m: Mission = c
		if OS.get_environment("PK_GOD") != "" and m.alive:
			m.hp = 5.0
		if not m.running:
			if m.finished and Engine.get_process_frames() % 20 == 0:
				_send("accept", true)
				_send.call_deferred("accept", false)
			return
		var best = null
		var best_d := INF
		for s in m.shots:
			var d: float = s.lp.distance_to(m.CENTER)
			if d < 120.0 and d < best_d:
				best_d = d
				best = {"lp": s.lp, "rock": true}
		for th in m.threats:
			if not th.can_be_hit():
				continue
			var d: float = th.lp.distance_to(m.CENTER) * (0.6 if th.is_asteroid else 1.0)
			if d < best_d:
				best_d = d
				best = {"lp": th.lp, "rock": th.is_asteroid}
		if best == null:
			return
		var to: Vector2 = (best.lp - m.CENTER).normalized()
		m.facing = -to if best.rock else to
		if not best.rock:
			m._aim_mode = "mouse"
			m._try_fire(true)


func _run(scenario: String) -> void:
	print("autotest ", scenario, " -> ", out)
	match scenario:
		"title":
			main.title()
			await wait(2.5)
			await shot("title")
			await tap("accept", 1.4)
			await tap("right", 0.3)
			await tap("right", 0.3)
			await tap("accept", 0.3)
			await shot("name_entry")
			get_tree().quit()
		"mission":
			var lv := OS.get_environment("PK_LEVEL")
			if lv == "":
				lv = "terra_virex_level_02"
			bot = true
			auto_talk = false
			Game.player_name = "Ari"
			Game.chapter = "hub"
			main.start_mission(lv, false, true)
			var n := int(OS.get_environment("PK_N")) if OS.get_environment("PK_N") != "" else 14
			for i in n:
				await wait(1.6 if i < 4 else 3.0)
				await shot("mission_%02d" % i)
			get_tree().quit()
		"prologue":
			Game.new_game()
			Game.player_name = "Ari"
			main.story.begin("prologue")
			for i in 40:
				await wait(1.5)
				await shot("prologue_%02d" % i)
				var w = main.world
				if w and w.marker and w.marker.visible and not w.busy and w.def.id == "home":
					w.player.position = w.tile_center(Vector2i(19, 4))
					w.player.face(1)
					await tap("accept", 0.5)
				elif w and w.marker and w.marker.visible and not w.busy and w.def.id == "parade":
					w.player.position = w.tile_center(Vector2i(18, 9))
					await hold("left", 0.4)
			get_tree().quit()
		"academy":
			Game.new_game()
			Game.player_name = "Ari"
			Game.chapter = "academy"
			main.story.begin("academy")
			for i in 60:
				await wait(1.5)
				await shot("academy_%02d" % i)
				var w = main.world
				if w and w.marker and w.marker.visible and w.def.id == "corridor" and not w.busy:
					w.player.position = w.tile_center(Vector2i(25, 3))
					await hold("right", 0.6)
				if main.mission_layer.get_child_count() > 0:
					bot = true
			get_tree().quit()
		"hub":
			Game.new_game()
			Game.player_name = "Ari"
			Game.chapter = "hub"
			Game.mark_completed("terra_virex", 1)
			var mode := OS.get_environment("PK_HUB")
			if mode == "late":
				Game.story.relationships = {"hiro": 3, "pala": 2, "midas": 2}
				Game.story.midas_dead = true
				Game.story.home_contacts = 1
				Game.mark_completed("terra_virex", 3)
				Game.mark_completed("glacien_ix", 2)
			main.story.begin("hub")
			await wait(4.0)
			await shot("hub_0")
			await wait(4.0)
			await shot("hub_1")
			var w = main.world
			var hiro: Actor = w.actor("hiro")
			w.player.position = hiro.position + Vector2(0, 14)
			w.player.face(1)
			await wait(0.3)
			await tap("accept", 0.8)
			await shot("hub_hiro")
			await wait(6.0)
			await shot("hub_2")
			await tap("cancel", 0.6)
			auto_talk = false
			await shot("hub_menu")
			await tap("accept", 0.5)
			auto_talk = true
			w.player.position = w.tile_center(Vector2i(14, 11))
			w.player.face(1)
			await wait(0.5)
			await tap("accept", 1.0)
			await wait(3.0)
			await shot("starmap")
			get_tree().quit()
		"ending":
			Game.new_game()
			Game.player_name = "Ari"
			main.load_map(Maps.commons(), Vector2i(12, 12), 1)
			main.story.endings.play(OS.get_environment("PK_END"))
			for i in 16:
				await wait(1.5)
				await shot("ending_%02d" % i)
				var w = main.world
				if w and w.def.id == "launch_wing" and w.marker and w.marker.visible:
					w.player.position = w.tile_center(Vector2i(22, 3))
					await hold("right", 0.6)
			get_tree().quit()
		"loop":
			Game.new_game()
			Game.player_name = "Ari"
			Game.chapter = "hub"
			Game.mark_completed("terra_virex", 1)
			main.story.begin("hub")
			await wait(5.0)
			var w = main.world
			var pala: Actor = w.actor("pala")
			w.player.position = pala.position + Vector2(0, 14)
			w.player.face(1)
			await wait(0.3)
			await tap("accept", 0.5)
			await wait(14.0)
			await shot("loop_after_pala")
			w.player.position = w.tile_center(Vector2i(14, 11))
			w.player.face(1)
			await wait(0.3)
			await tap("accept", 0.5)
			while not _has_starmap():
				await wait(0.3)
			await wait(4.0)
			await shot("loop_starmap")
			auto_talk = false
			await tap("accept", 0.8)
			await tap("accept", 0.6)
			bot = true
			auto_talk = true
			for i in 50:
				await wait(2.0)
				if i % 5 == 0:
					await shot("loop_%02d" % i)
				if main.world and main.world.visible and main.mission_layer.get_child_count() == 0 and i > 10:
					break
			await wait(4.0)
			await shot("loop_back")
			print("rel pala=", Game.relationship("pala"), " completed=", Game.completed_count(), " interval=", Game.story.interval_count)
			get_tree().quit()
		"introcheck":
			Game.player_name = "Ari"
			Game.chapter = "hub"
			if OS.get_environment("PK_DEPLOY") != "":
				main.load_map(Maps.commons(), Vector2i(12, 12), 1)
				main.story.hub.deploy("terra_virex_level_01")
			else:
				main.start_mission("terra_virex_level_01", false, true)
			for i in 45:
				await get_tree().create_timer(0.1).timeout
				await shot("intro_%02d" % i)
			get_tree().quit()
		"portraits":
			auto_talk = false
			Game.chapter = "hub"
			Game.player_name = "Ari"
			main.load_map(Maps.commons(), Vector2i(12, 8), 1)
			for who in ["hiro", "you", "instructor", "pala"]:
				main.story.say(who, "Checking how this portrait sits in the dialog box.", "")
				await wait(1.6)
				await shot("pt_" + who)
				await tap("accept", 0.4)
			get_tree().quit()
		"facecheck":
			auto_talk = false
			Game.chapter = "hub"
			main.load_map(Maps.commons(), Vector2i(12, 8), 1)
			main.story.say("pala", "This is a long line of dialog so that the typewriter keeps running for a good few seconds while we watch her mouth move and wait for a blink to happen.", "")
			var states := []
			for i in 160:
				await get_tree().process_frame
				await get_tree().process_frame
				await get_tree().process_frame
				states.append("%s talking=%s" % [main.dialog._face_state, main.dialog._talking])
			var c := {}
			for st in states:
				c[st] = c.get(st, 0) + 1
			print("face states: ", c)
			get_tree().quit()
		"looks":
			var img := Image.create_empty(4 * 76, 2 * 76, false, Image.FORMAT_RGBA8)
			img.fill(Color("1a1622"))
			for i in Data.LOOKS.size():
				Game.look = i
				for j in 2:
					var sp := Game.player_spec("home" if j == 0 else "academy")
					var im := ArtPortraits.from_sprite(sp, "").img
					img.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(i * 76 + 2, j * 76 + 2))
			img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
			img.save_png(out + "/looks.png")
			get_tree().quit()
		"planetcheck":
			var img := Image.create_empty(4 * 92, 92, false, Image.FORMAT_RGBA8)
			img.fill(Color("0e1119"))
			for f in 4:
				var im := ArtMission.planet("green_planet", 84, f * 8).img
				img.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(f * 92 + 2, 2))
			img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
			img.save_png(out + "/planet.png")
			get_tree().quit()
		"titlefade":
			main.title()
			for i in 6:
				await wait(0.5)
				await shot("tf_%d" % i)
			get_tree().quit()
		"endtitle":
			Game.new_game()
			Game.player_name = "Ari"
			main.load_map(Maps.commons(), Vector2i(12, 12), 1)
			main.story.endings.play(OS.get_environment("PK_END"))
			var got := false
			for i in 120:
				await wait(1.0)
				var w = main.world
				if w and w.def.id == "launch_wing" and w.marker and w.marker.visible and not w.busy:
					w.player.position = w.tile_center(Vector2i(22, 3))
					await hold("right", 0.6)
				for c in main.cine_layer.get_children():
					if c is TitleScreen:
						got = true
				if got:
					break
				if not main.dialog.visible:
					await tap("accept", 0.2)
			await wait(1.0)
			await shot("endtitle")
			print("returned to title: ", got)
			get_tree().quit()
		"endflow":
			Game.new_game()
			Game.player_name = "Ari"
			Game.chapter = "hub"
			Game.mark_completed("terra_virex", 1)
			Game.story.relationships.pala = 3
			main.story.begin("hub")
			await wait(5.0)
			var w0 = main.world
			var pala: Actor = w0.actor("pala")
			w0.player.position = pala.position + Vector2(0, 14)
			w0.player.face(1)
			await wait(0.3)
			await tap("accept", 0.5)
			var got := false
			for i in 150:
				await wait(1.0)
				var w = main.world
				if is_instance_valid(w) and w.def.id == "launch_wing" and w.marker and w.marker.visible and not w.busy:
					w.player.position = w.tile_center(Vector2i(22, 3))
					await hold("right", 0.6)
				for c in main.cine_layer.get_children():
					if c is TitleScreen:
						got = true
				if got:
					break
				if not main.dialog.visible:
					await tap("accept", 0.2)
			await wait(1.5)
			await shot("endflow")
			print("returned to title: ", got, " chapter=", Game.chapter)
			get_tree().quit()
		"firecheck":
			auto_talk = false
			main.start_mission("terra_virex_level_01", true, false)
			await wait(1.0)
			var m: Mission = main.mission_layer.get_child(0)
			var mx := 0
			# hold fire
			_send("accept", true)
			for i in 90:
				await get_tree().process_frame
				mx = maxi(mx, m.bolts.size())
			_send("accept", false)
			print("held fire, max in flight: ", mx)
			await wait(1.0)
			mx = 0
			# mash fire as fast as possible (a press every 2 frames)
			for i in 30:
				_send("accept", true)
				await get_tree().process_frame
				_send("accept", false)
				await get_tree().process_frame
				mx = maxi(mx, m.bolts.size())
			print("mashed fire, max in flight: ", mx)
			get_tree().quit()
		"walkcheck":
			main.load_map(Maps.hall(), Vector2i(5, 9), 1)
			var w = main.world
			w.busy = true
			var act: Actor = w.actor("instructor")
			var frames := {}
			act.walk_to([w.tile_center(Vector2i(10, 12))], 40.0)
			var pf := {}
			w.player.walk_to([w.tile_center(Vector2i(1, 9))], 40.0)
			for i in 60:
				await get_tree().process_frame
				frames[act.frame] = true
				pf[w.player.frame] = true
			print("npc frames seen: ", frames.keys(), " player frames seen: ", pf.keys())
			get_tree().quit()
		"escape":
			var e := Escape.new()
			main.cine_layer.add_child(e)
			e.run()
			for i in 6:
				await wait(2.0)
				await shot("escape_%d" % i)
			get_tree().quit()
