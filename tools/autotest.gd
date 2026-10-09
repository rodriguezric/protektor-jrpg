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


func _apply_loadout() -> void:
	var w := OS.get_environment("PK_WEAPON")
	if w != "":
		Game.story.weapons = ["basic", "wave", "beam", "auto"]
		Game.story.weapon = w
	if OS.get_environment("PK_UP") == "max":
		Game.story.upgrades = {"cooldown": 3, "armor": 3}
		Game.story.specials = ["missile", "ext_shield"]


# ------------------------------------------------------------- trailer ---

func caption(text: String, at: float, hold: float, y: float = 132.0) -> void:
	## Trailer caption in the game's pixel font, faded in and out.
	await wait(at)
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	var l := Art.shadow_label(text, Pal.TEXT, 2)
	l.position = Vector2(160 - Art.text_width(text, 2) / 2.0, y)
	l.modulate.a = 0.0
	layer.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.35)
	tw.tween_interval(hold)
	tw.tween_property(l, "modulate:a", 0.0, 0.35)
	tw.tween_callback(layer.queue_free)


func _trailer(seg: String) -> void:
	Game.testing = true
	Game.player_name = "Ari"
	auto_talk = false
	main.fade_rect.color.a = 0.0
	match seg:
		"city":
			var c := Cinema.open()
			c.animate_bg("city", 8, 3.0)
			var ship := c.sprite(Art.prop("shuttle", 0), Vector2(-40, 42))
			ship.modulate = Color(0.1, 0.1, 0.16)
			ship.scale = Vector2(0.5, 0.5)
			c.create_tween().tween_property(ship, "position:x", 200.0, 6.0)
			c.sprite(Art.cine("city_frame"), Vector2(160, 90))
			caption("PARTICIPATION IS VOLUNTARY.", 0.8, 3.4, 140)
			await wait(6.0)
		"home":
			var mp := Maps.home()
			mp.npcs = [{"id": "mother", "who": "mother", "tile": Vector2i(3, 7), "dir": 2, "mood": "sad"}, {"id": "father", "who": "father", "tile": Vector2i(6, 7), "dir": 3}]
			var w = main.load_map(mp, Vector2i(5, 9), 1)
			w.busy = true
			w.player.spec = Game.player_spec("home")
			w.player.refresh()
			w.cam_follow = false
			w.cam_focus = w.tile_center(Vector2i(6, 5))
			w.cam.position = w.cam_focus
			await wait(1.6)
			var c := Cinema.open(Color(0, 0, 0, 0))
			c.modulate.a = 0.0
			c.show_tex(Art.cine("table"), 0.0)
			c.sprite(Art.cine("letter", 0), Vector2(160, 92), 1.0)
			c.create_tween().tween_property(c, "modulate:a", 1.0, 0.5)
			caption("YOUR CHILD HAS BEEN SELECTED.", 1.8, 2.2, 150)
			await wait(4.6)
		"parade":
			var w = main.load_map(Maps.parade(), Vector2i(17, 9), 1)
			w.busy = true
			w.cam_follow = false
			w.cam_focus = w.tile_center(Vector2i(8, 7))
			w.cam.position = w.cam_focus
			w.tint.color = Color(1.05, 1.02, 0.95)
			w.pan_to(w.tile_center(Vector2i(21, 7)), 5.0)
			main.story.confetti(w.tile_center(Vector2i(14, 4)), 60)
			for i in 16:
				var cr = w.actor("crowd%d" % i)
				if cr:
					cr.hop(3.0, 0.35)
			caption("THE COLONIES NEED PROTEKTORS.", 0.6, 3.2, 150)
			await wait(1.8)
			main.story.confetti(w.tile_center(Vector2i(18, 5)), 50)
			await wait(3.4)
		"badge":
			var w = main.load_map(Maps.hall(), Vector2i(5, 9), 1)
			w.busy = true
			w.player.set_pose("sit")
			w.cam_follow = false
			w.cam_focus = w.tile_center(Vector2i(9, 7))
			w.cam.position = w.cam_focus
			await wait(1.6)
			var c := Cinema.open()
			c.show_tex(Art.cine("badge_bg"), 0.0)
			var bs := c.sprite(Art.cine("badge", 0), Vector2(160, 104), 1.0)
			var nm := Art.shadow_label(OS.get_environment("PK_NAME") if OS.get_environment("PK_NAME") != "" else "ARI", Pal.FROST)
			nm.position = Vector2(-Art.text_width(nm.text) / 2.0, 8)
			bs.add_child(nm)
			caption("ONE TOUCH.", 0.4, 1.0, 30)
			await wait(1.7)
			bs.texture = Art.cine("badge", 1)
			await main.flash(Pal.SYNC, 0.25, 0.9)
			nm.queue_free()
			c.clear_sprites()
			c.show_tex(null, 0.0)
			c.effect = "warp"
			c.effect_k = 1.0
			c.set_vignette(0.8, 0.0)
			caption("EVERYTHING RUSHES FORWARD.", 0.2, 1.6, 82)
			await wait(2.4)
		"intro":
			main.start_mission("terra_virex_level_02", false, true)
			await wait(16.5)
		"play":
			bot = true
			OS.set_environment("PK_GOD", "1")
			var lv := OS.get_environment("PK_LEVEL")
			Game.story.weapons = ["basic", "wave", "beam", "auto"]
			Game.story.weapon = OS.get_environment("PK_WEAPON") if OS.get_environment("PK_WEAPON") != "" else "basic"
			if OS.get_environment("PK_UP") == "max":
				Game.story.upgrades = {"cooldown": 3, "armor": 3}
				Game.story.specials = ["missile", "ext_shield"]
			main.start_mission(lv, false, false)
			var cap := OS.get_environment("PK_CAP")
			if cap != "":
				caption(cap, float(OS.get_environment("PK_CAP_AT")), 2.6, 150)
			await wait(float(OS.get_environment("PK_LEN")) if OS.get_environment("PK_LEN") != "" else 14.0)
		"hub":
			Game.chapter = "hub"
			Game.mark_completed("terra_virex", 1)
			var w = main.load_map(main.story.hub._map(), Vector2i(8, 6), 2)
			w.busy = true
			var hiro: Actor = w.actor("hiro")
			w.player.walk_to([w.tile_center(Vector2i(6, 4)) + Vector2(4, 0)], 50.0)
			await wait(1.3)
			hiro.hop()
			hiro.emote("note")
			main.story.say("hiro", "You felt it, right? The flow. That turn near the end was perfect.", "still_smiling")
			caption("BETWEEN DEPLOYMENTS,", 0.6, 1.4, 6)
			caption("CHOOSE WHO YOU BECOME.", 2.4, 1.6, 6)
			await wait(5.0)
		"starmap":
			for p in Data.PLANETS:
				Game._unlock(p)
			var sm := StarMap.new()
			main.cine_layer.add_child(sm)
			sm.setup(false, true)
			sm.run()
			caption("SEVEN WORLDS TO DEFEND.", 2.4, 1.6, 104)
			await wait(4.6)
		"ending":
			var c := Cinema.open()
			c.show_tex(Art.cine("ascend"), 0.0)
			c.effect = "stars"
			c.effect_k = 0.6
			var mech := c.sprite(Art.prop("mech", 0), Vector2(160, 150))
			mech.modulate = Color(0.85, 1.0, 1.1)
			c.create_tween().tween_property(mech, "position:y", 96.0, 4.0).set_trans(Tween.TRANS_SINE)
			caption("FIVE ENDINGS.", 0.6, 1.6, 20)
			caption("HOW MUCH OF YOU REMAINS?", 2.4, 1.6, 20)
			await wait(4.6)
		"title":
			main.title()
			await wait(7.0)
	get_tree().quit()


func _has_training() -> bool:
	for c in main.cine_layer.get_children():
		if c is Training:
			return true
	return false


func _has_starmap() -> bool:
	for c in main.cine_layer.get_children():
		if c is StarMap:
			return true
	return false


# ---------------------------------------------------------------- touch ---

func _finger(i: int, pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = i
	e.position = pos
	e.pressed = pressed
	Input.parse_input_event(e)


func _drag_to(i: int, pos: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = i
	e.position = pos
	Input.parse_input_event(e)


func _touch_tap(pos: Vector2, after: float = 0.3) -> void:
	_finger(9, pos, true)
	await wait(0.08)
	_finger(9, pos, false)
	await wait(after)


func window_shot(name: String) -> void:
	## The whole window, touch controls included.
	await RenderingServer.frame_post_draw
	get_tree().root.get_texture().get_image().save_png("%s/%s.png" % [out, name])


func _control(id: String) -> Vector2:
	for c in Game.shell.touch.controls:
		if c.id == id:
			return (c.rect as Rect2).get_center()
	return Vector2.ZERO


func _touch_test() -> void:
	## Real touch events: walk with the stick, pause from MENU, then in a
	## deployment aim with the stick, fire by tapping, and pause.
	Game.testing = true
	auto_talk = false
	main.fade_rect.color.a = 0.0
	var sh: Shell = Game.shell
	var tc: TouchControls = sh.touch
	var win: Vector2 = get_tree().root.get_visible_rect().size
	Game.chapter = "hub"
	main.load_map(main.story.hub._map(), Vector2i(8, 6), 2)
	var w = main.world
	await wait(0.6)
	await _touch_tap(sh.game_rect.get_center(), 0.5)   # first touch wakes the controls
	print("[touch] active=%s layout=%s slot=%s in_bars=%s game_rect=%s" % [tc.active, tc.layout, tc.slot_mode, tc.in_bars, sh.game_rect])
	# the floating stick: touch the left side, push right, then far right to run
	var start := Vector2(win.x * 0.2, win.y * 0.7)
	var p0: Vector2 = w.player.position
	_finger(1, start, true)
	await wait(0.1)
	_drag_to(1, start + Vector2(tc.joy_radius * 0.5, 0))
	await wait(0.6)
	var walked: float = w.player.position.x - p0.x
	var at_touch := tc.joy_origin.distance_to(start) < 2.0
	var run0: Vector2 = w.player.position
	_drag_to(1, start + Vector2(tc.joy_radius * 1.4, 0))
	await wait(0.4)
	await window_shot("touch_field")
	print("[touch] stick at touch=%s walked_right=%.1f (0.6s) running=%s ran=%.1f (0.4s)" % [at_touch, walked, tc.running, w.player.position.x - run0.x])
	_finger(1, start, false)
	await wait(0.3)
	# MENU opens the pilot status; B closes it
	await _touch_tap(_control("menu"), 0.8)
	var open := false
	for c in main.ui.get_children():
		if c is PilotStatus:
			open = true
	await window_shot("touch_menu")
	print("[touch] menu opened pilot status=%s slot now=%s" % [open, tc.slot_mode])
	await _touch_tap(_control("b"), 0.8)
	# a deployment
	w.busy = true
	main.start_mission("terra_virex_level_01", false, false)
	await wait(1.6)
	var m: Mission = tc._mission()
	print("[touch] mission layout=%s slot=%s controls=%s" % [tc.layout, tc.slot_mode, tc.controls.map(func(x): return x.id)])
	# aim up-left with the stick
	_finger(1, start, true)
	await wait(0.1)
	_drag_to(1, start + Vector2(-1, -1).normalized() * tc.joy_radius * 0.9)
	await wait(0.3)
	print("[touch] facing=%s (want about (-0.71, -0.71)) aim=%s" % [m.facing, Game.touch_aim])
	# a second finger on the right fires; holding keeps firing
	var shots_before := 0
	var fired := {"n": 0}
	var fire_pos := Vector2(win.x * 0.7, win.y * 0.5)
	_finger(2, fire_pos, true)
	for i in 30:
		await get_tree().process_frame
		fired.n = maxi(fired.n, m.bolts.size())
	await window_shot("touch_mission")
	_finger(2, fire_pos, false)
	print("[touch] bolts in the air while holding fire: %d (before %d)" % [fired.n, shots_before])
	# letting go of the stick keeps the facing
	_finger(1, start, false)
	await wait(0.2)
	print("[touch] facing kept after release=%s" % [m.facing.distance_to(Vector2(-1, -1).normalized()) < 0.05])
	# a single tap fires once (after the last volley has cleared: three in
	# the air is the weapon's limit)
	for i in 240:
		if m.bolts.is_empty():
			break
		await get_tree().process_frame
	await wait(0.2)
	var b0: int = m.bolts.size()
	_finger(3, fire_pos, true)
	await get_tree().process_frame
	await get_tree().process_frame
	var b1: int = m.bolts.size()
	_finger(3, fire_pos, false)
	print("[touch] tap fired=%s" % [b1 > b0])
	# the top-right button pauses; tap Resume twice (select, confirm)
	await wait(0.3)
	await _touch_tap(_control("menu"), 0.6)
	print("[touch] paused=%s slot=%s" % [m.paused, tc.slot_mode])
	await window_shot("touch_pause")
	var rows := get_tree().get_nodes_in_group("tap_targets")
	if not rows.is_empty():
		var menu: Menu = rows[0]
		var row := sh.to_window(menu.get_global_rect().position + menu._slot(0) + Vector2(10, 4))
		await _touch_tap(row, 0.5)
	print("[touch] resumed=%s" % [not m.paused])
	# desktop still works through the shell: a key hides the touch controls,
	# the mouse aims where it points and a click fires
	var k := InputEventKey.new()
	k.keycode = KEY_RIGHT
	k.physical_keycode = KEY_RIGHT
	k.pressed = true
	Input.parse_input_event(k)
	await get_tree().process_frame
	k = k.duplicate()
	k.pressed = false
	Input.parse_input_event(k)
	await wait(0.3)
	print("[touch] key hid touch controls=%s aim_mode=%s" % [not tc.active, m._aim_mode])
	var target := sh.to_window(Mission.ARENA.position + m.core.position + Vector2(40, 0))
	for i in 3:
		var mm := InputEventMouseMotion.new()
		mm.position = target + Vector2(i, 0)
		mm.relative = Vector2(4, 0)
		Input.parse_input_event(mm)
		await get_tree().process_frame
	await wait(0.1)
	print("[touch] mouse aim facing=%s (want about (1, 0)) aim_mode=%s" % [m.facing, m._aim_mode])
	for i in 240:
		if m.bolts.is_empty():
			break
		await get_tree().process_frame
	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.position = target
	mb.pressed = true
	Input.parse_input_event(mb)
	await get_tree().process_frame
	await get_tree().process_frame
	print("[touch] mouse click fired=%s" % [m.bolts.size() > 0])
	mb = mb.duplicate()
	mb.pressed = false
	Input.parse_input_event(mb)
	get_tree().quit()


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
	if scenario == "trailer":
		await _trailer(OS.get_environment("PK_SEG"))
		return
	if scenario == "splash":
		# the studio card at 0.5 s steps, then the title fading in after it
		auto_talk = false
		var t0 := Time.get_ticks_msec()
		var done := {"v": false}
		var go := func() -> void:
			await main.company_splash()
			done.v = true
		go.call()
		for i in 12:
			await wait(0.5)
			await shot("splash_%02d" % i)
		print("[splash] finished on its own=%s after %.1fs, screen black=%s" % [done.v, (Time.get_ticks_msec() - t0) / 1000.0, main.fade_rect.color.a > 0.99])
		main.title()
		await wait(1.5)
		await shot("splash_then_title")
		# skipping: press Z partway through; it must end the same way
		main.cine_layer.get_child(main.cine_layer.get_child_count() - 1).queue_free()
		done.v = false
		var t1 := Time.get_ticks_msec()
		go.call()
		await wait(1.0)
		await tap("accept", 0.1)
		for i in 60:
			if done.v:
				break
			await wait(0.05)
		print("[splash] skipped=%s in %.1fs, screen black=%s, splash freed=%s" % [done.v, (Time.get_ticks_msec() - t1) / 1000.0, main.fade_rect.color.a > 0.99,
			main.cine_layer.get_children().filter(func(c): return c is CompanySplash and not c.is_queued_for_deletion()).is_empty()])
		get_tree().quit()
		return
	if scenario == "touch":
		await _touch_test()
		return
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
			Game.testing = true
			_apply_loadout()
			if lv.begins_with("training_"):
				var bits := lv.split("_")
				var td := Training.build(bits[1], int(bits[2]) - 1)
				main.start_mission(td.level_id, false, false, null, td, true)
			else:
				main.start_mission(lv, false, OS.get_environment("PK_INTRO") != "off")
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
			print("rel pala=", Game.relationship("pala"), " completed=", Game.completed_count(), " interval=", Game.story.interval_count, " credits=", Game.credits())
			get_tree().quit()
		"introcheck":
			Game.player_name = "Ari"
			Game.chapter = "hub"
			if OS.get_environment("PK_DEPLOY") != "":
				main.load_map(Maps.commons(), Vector2i(12, 12), 1)
				main.story.hub.deploy("terra_virex_level_01")
			else:
				main.start_mission("terra_virex_level_01", false, true)
			var n := int(OS.get_environment("PK_N")) if OS.get_environment("PK_N") != "" else 45
			var step := float(OS.get_environment("PK_STEP")) if OS.get_environment("PK_STEP") != "" else 0.1
			for i in n:
				await get_tree().create_timer(step).timeout
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
		"opening":
			auto_talk = false
			Game.new_game()
			main.story.begin("prologue")
			for i in 5:
				await wait(1.6)
				await shot("open_%d" % i)
			get_tree().quit()
		"warpcine":
			auto_talk = false
			var c := Cinema.open()
			c.effect = "warp"
			c.effect_k = 1.0
			c.set_vignette(0.75, 0.0)
			for i in 4:
				await wait(0.5)
				await shot("warpcine_%d" % i)
			get_tree().quit()
		"screens":
			auto_talk = false
			Game.testing = true
			Game.story.credits = 420
			Game.mark_completed("terra_virex", 3)
			Game.mark_completed("glacien_ix", 1)
			Game.story.training = {"block": 2, "shoot": 1, "combo": 0}
			main.load_map(Maps.commons(), Vector2i(6, 12), 1)
			main.workshop()
			await wait(1.2)
			await shot("workshop")
			await tap("down", 0.2)
			await tap("down", 0.2)
			await tap("accept", 1.0)
			await shot("workshop_bought")
			for i in 9:
				await tap("down", 0.15)
			await shot("workshop_weapons")
			await tap("cancel", 1.2)
			main.training()
			await wait(1.5)
			await shot("training")
			await tap("right", 0.3)
			await tap("accept", 0.5)
			await shot("training_tiers")
			print("credits now ", Game.credits(), " upgrades ", Game.story.upgrades)
			get_tree().quit()
		"weaponshot":
			auto_talk = false
			Game.testing = true
			var img := Image.create_empty(4 * 90, 90, false, Image.FORMAT_RGBA8)
			var col := 0
			for w in ["basic", "wave", "beam", "auto"]:
				Game.story.weapons = ["basic", "wave", "beam", "auto"]
				Game.story.weapon = w
				var td := Training.build("block", 0)
				main.start_mission(td.level_id, false, false, null, td, true)
				await wait(2.4)
				var m: Mission = main.mission_layer.get_child(main.mission_layer.get_child_count() - 1)
				m._aim_mode = "key"
				m.facing = Vector2(1, -1).normalized()
				for k in 3:
					m._fire_cd = 0.0
					m._try_fire()
					await wait(0.04)
				await RenderingServer.frame_post_draw
				var full := get_viewport().get_texture().get_image()
				full.convert(Image.FORMAT_RGBA8)
				img.blit_rect(full, Rect2i(150, 10, 90, 90), Vector2i(col * 90, 0))
				print(w, " in flight: ", m.bolts.size())
				col += 1
				m.queue_free()
				await wait(0.3)
			img.resize(img.get_width() * 3, img.get_height() * 3, Image.INTERPOLATE_NEAREST)
			img.save_png(out + "/weapons.png")
			get_tree().quit()
		"trainlap":
			Game.testing = true
			Game.story.credits = 0
			main.load_map(Maps.commons(), Vector2i(6, 12), 1)
			main.training()
			await wait(1.5)
			auto_talk = false
			await tap("accept", 0.6)
			await tap("accept", 0.6)
			bot = true
			for i in 60:
				await wait(1.0)
				if _has_training():
					break
			print("after drill: credits=", Game.credits(), " training=", Game.story.training)
			get_tree().quit()
		"achscreen":
			auto_talk = false
			Game.testing = true
			var now := int(Time.get_unix_time_from_system())
			for id in ["aim_10", "aim_25", "block_10", "flawless_1", "unlock_glacien_ix", "clear_terra_virex", "ending_partial_pala", "ending_ascended", "all_training"]:
				Game.achieved[id] = now
			Game.achv_stats = {"best_shot_streak": 37, "best_block_chain": 18, "flawless_count": 3}
			var scr := AchievementsScreen.new()
			main.cine_layer.add_child(scr)
			scr.run()
			await wait(1.0)
			await shot("ach_all")
			await tap("right", 0.3)
			await tap("right", 0.3)
			await tap("down", 0.5)
			await shot("ach_scrolled")
			await tap("down", 0.3)
			await tap("down", 0.6)
			await shot("ach_down")
			for k in 6:
				await tap("up", 0.15)
			await tap("right", 0.2)
			await tap("right", 0.6)
			await shot("ach_tab")
			main.toast_achievement(Achievements.find("clear_glacien_ix"))
			await wait(0.8)
			await shot("ach_toast")
			get_tree().quit()
		"achplay":
			# real play with achievements live (PK_ACH points at a scratch file)
			Game.testing = false
			Game.player_name = "Ari"
			Game.chapter = "hub"
			bot = true
			auto_talk = false
			main.start_mission("terra_virex_level_01", false, false)
			for i in 110:
				await wait(1.0)
				if main.mission_layer.get_child_count() == 0:
					break
			print("achieved: ", Game.achieved.keys(), " stats: ", Game.achv_stats)
			get_tree().quit()
		"slots":
			auto_talk = false
			print("after migration: slot1=", Game.slot_info(1), " profile unlocked=", Game.profile.unlocked, " upgrades=", Game.profile.upgrades, " weapons=", Game.profile.weapons)
			main.title()
			await wait(5.0)
			await tap("down", 0.4)
			await shot("slots_title")
			await tap("accept", 1.2)
			await shot("slots_new")
			await tap("down", 0.3)
			await tap("accept", 1.5)
			await shot("slots_keep")
			await tap("accept", 0.3)
			await tap("accept", 1.5)
			for k in 4:
				await tap("down", 0.1)
			await tap("right", 0.1)
			await tap("right", 0.1)
			await tap("accept", 2.0)
			auto_talk = true
			await wait(4.0)
			print("slot2 after new game=", Game.slot_info(2), " active slot=", Game.slot, " loadout=", Game.loadout())
			auto_talk = false
			main.dialog.close()
			for c in main.cine_layer.get_children():
				c.queue_free()
			if main.world:
				main.world.queue_free()
				main.world = null
			var s2 := SlotScreen.new()
			s2.setup("load")
			main.cine_layer.add_child(s2)
			main.fade_rect.color.a = 0.0
			await wait(1.0)
			await shot("slots_load")
			get_tree().quit()
		"slotlogic":
			auto_talk = true
			Game.player_name = "Kai"
			Game.start_new_game(2, false)
			main.story.begin("prologue")
			await wait(2.0)
			print("A slot2=", Game.slot_info(2))
			# buy an upgrade in slot 2: it should carry over to every slot
			Game.story.specials.append("missile")
			Game.save()
			Game.start_new_game(3, true)
			Game.player_name = "Rin"
			Game.save()
			print("B stripped slot3 loadout=", Game.loadout(), " info=", Game.slot_info(3))
			Game.load_slot(1)
			print("C slot1 chapter=", Game.chapter, " name=", Game.player_name, " credits=", Game.credits(), " loadout=", Game.loadout())
			Game.load_profile()
			print("D profile specials=", Game.profile.specials, " unlocked=", Game.profile.unlocked, " most recent=", Game.most_recent_slot())
			get_tree().quit()
		"menutext":
			Game.testing = true
			auto_talk = false
			main.load_map(Maps.commons(), Vector2i(12, 8), 1)
			await wait(0.5)
			await tap("cancel", 0.6)
			await tap("down", 0.2)
			await tap("down", 0.2)
			await tap("accept", 1.5)
			await shot("menutext")
			get_tree().quit()
		"victory":
			# Results panel straight after a clear; PK_LEVEL picks the level so
			# unlocks can be included (level 3 of a world unlocks the next).
			Game.testing = true
			var lv := OS.get_environment("PK_LEVEL") if OS.get_environment("PK_LEVEL") != "" else "terra_virex_level_01"
			main.start_mission(lv, false, false)
			await wait(1.5)
			var m: Mission = main.mission_layer.get_child(main.mission_layer.get_child_count() - 1)
			m.score = 1234
			m._begin_victory()
			for i in 4:
				await wait(1.5)
				await shot("victory_%d" % i)
			get_tree().quit()
		"comms":
			# A long transmission in the comms pane, shot as it types and scrolls.
			Game.testing = true
			main.start_mission("terra_virex_level_01", false, false)
			await wait(1.0)
			var m: Mission = main.mission_layer.get_child(main.mission_layer.get_child_count() - 1)
			m._comms_queue.clear()
			m._comms("SYSTEM", "Multiple hostile signatures converging on the northern hemisphere. Shield harmonics unstable. Recalibrating the defensive lattice now, stand by for further instructions, pilot.", 30.0, 3.0)
			for i in 6:
				await wait(1.2)
				await shot("comms_%d" % i)
			get_tree().quit()
		"blink":
			# Idle actors blink on their own; so does the pilot status portrait.
			Game.testing = true
			main.load_map(Maps.hall(), Vector2i(5, 9), 0)
			var w = main.world
			w.busy = true
			var seen := {}
			var shot_taken := false
			for i in 360:
				await get_tree().process_frame
				if w.player.blinking:
					seen["player"] = int(seen.get("player", 0)) + 1
					if not shot_taken:
						shot_taken = true
						await shot("blink_field")
			print("player blink frames: ", seen)
			var ps := PilotStatus.new()
			main.ui.add_child(ps)
			var shut := 0
			for i in 360:
				await get_tree().process_frame
				if ps.blink_t <= 0.0:
					shut += 1
					if shut == 2:
						await shot("blink_menu")
			print("menu blink frames: ", shut)
			get_tree().quit()
		"choices":
			# Every ask() in the scripts: does the question fit one 3-line page,
			# and does the choice menu stay on screen, clear of the portrait?
			Game.testing = true
			var re := RegEx.new()
			re.compile("(?s)ask\\(\\s*\"([^\"]*)\"(?:\\s*%\\s*\\[[^\\]]*\\])?\\s*,\\s*\\[([^\\]]*)\\]\\s*(?:,\\s*\"([^\"]*)\")?")
			var opt_re := RegEx.new()
			opt_re.compile("\"([^\"]*)\"")
			var d: DialogBox = main.dialog
			auto_talk = false
			main.fade_rect.color.a = 0.0
			main.load_map(Maps.hall(), Vector2i(5, 9), 0)
			main.world.busy = true
			var worst := []
			var problems := 0
			for f in ["main", "pilot_status", "story_prologue", "story_academy", "story_hub"]:
				var src := FileAccess.get_file_as_string("res://scripts/%s.gd" % f)
				for mt in re.search_all(src):
					var q := mt.get_string(1).replace("%d", "3").replace("%s", "WWWWWWWW")
					var opts: Array = []
					for om in opt_re.search_all(mt.get_string(2)):
						opts.append(om.get_string(1))
					var who := mt.get_string(3)
					var pages := d.paginate(q)
					var w := 0
					for o in opts:
						w = maxi(w, Art.text_width(o))
					var h := opts.size() * 10 + 7
					var r := Rect2(312 - w - 22, 124 - h, w + 20, h)
					var portrait := who == "system"
					var issues := []
					if pages.size() > 1:
						issues.append("question needs %d pages" % pages.size())
					if r.position.x < 4 or r.position.y < 4:
						issues.append("menu off screen")
					if portrait and r.intersects(Rect2(8, 40, 78, 78)):
						issues.append("menu overlaps portrait")
					problems += issues.size()
					print("%-14s q_lines=%d menu=%s %s | %s" % [f, d.paginate(q)[0].count("\n") + 1, r, "OK" if issues.is_empty() else str(issues), q])
					worst.append({"q": q, "opts": opts, "who": who, "w": w * 100 + opts.size()})
			print("choice problems: ", problems)
			# show the widest and the tallest menus on screen
			worst.sort_custom(func(a, b): return a.w > b.w)
			# plus the longest question
			var longest: Dictionary = worst[0]
			for c in worst:
				if Art.text_width(c.q) > Art.text_width(longest.q):
					longest = c
			worst.insert(1, longest)
			for i in 2:
				var c: Dictionary = worst[i]
				var sp: Array = main.story.speaker(c.who)
				d.ask(c.q, c.opts, sp[0], sp[1])
				await wait(2.5)
				await shot("choices_%d" % i)
				tap("accept")
				await wait(0.4)
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
				if i % 12 == 6:
					await shot("walk_%d" % i)
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
