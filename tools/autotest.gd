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
		Game.story.upgrades = {"cooldown": 3, "armor": 3, "missile": 3}
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
				Game.story.upgrades = {"cooldown": 3, "armor": 3, "missile": 3}
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
	# no A button: a quick tap on the stick (never pushed) presses OK, and the
	# stick is only drawn while held
	var saw := {"accept": false}
	var watch := func() -> void:
		if Input.is_action_pressed("accept"):
			saw.accept = true
	get_tree().process_frame.connect(watch)
	await _touch_tap(start, 0.2)
	get_tree().process_frame.disconnect(watch)
	print("[touch] no A=%s stick tap accepted=%s stick hidden=%s" % [tc.controls.all(func(x): return x.id != "a"), saw.accept, tc.joy_finger < 0])
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


const ROWS_N := 4


func _touch_screens() -> void:
	## The title shows no stick or buttons; the star map is played by tapping
	## worlds (stick hidden, B kept for back).
	Game.testing = true
	auto_talk = false
	var sh: Shell = Game.shell
	var tc: TouchControls = sh.touch
	main.title()
	await wait(0.8)
	await _touch_tap(sh.to_window(Vector2(250, 20)), 0.2)   # wake the controls
	await wait(3.0)
	await window_shot("touch_title")
	var shown := tc.controls.filter(func(c): return tc._shown(c) and (not tc.hidden_ids.has(c.id)) and (not tc.slot_alpha.has(c.id) or tc.slot_mode == c.id))
	print("[screens] title: active=%s slot='%s' hidden=%s stick blocked=%s visible controls=%s" % [tc.active, tc.slot_mode, tc.hidden_ids, tc.joy_blocked, shown.map(func(c): return c.id)])
	# the star map, every world open
	for c in main.cine_layer.get_children():
		c.queue_free()
	main.fade_rect.color.a = 0.0
	Game.load_meta_only()
	for p in Data.PLANETS:
		Game._unlock(p)
	var res := {"pick": "?"}
	var go := func() -> void:
		res.pick = await main.starmap(true, false)
	go.call()
	await wait(1.5)
	var sm: StarMap
	for c in main.cine_layer.get_children():
		if c is StarMap:
			sm = c
	await window_shot("touch_starmap")
	print("[screens] starmap: slot='%s' hidden=%s stick blocked=%s" % [tc.slot_mode, tc.hidden_ids, tc.joy_blocked])
	var before := sm.sel
	var target := (before + 2) % sm.visible_planets.size()
	var tp: Vector2 = sh.to_window(sm._planet_pos(target))
	await _touch_tap(tp, 0.3)
	print("[screens] tap a world: selected %s -> %s (want %s, %s)" % [before, sm.sel, target, sm.visible_planets[sm.sel]])
	await _touch_tap(sh.to_window(Vector2(300, 100)), 0.3)   # empty space: nothing
	print("[screens] tap empty space: still %s, level menu open=%s" % [sm.sel, not get_tree().get_nodes_in_group("tap_targets").filter(func(n): return n is Menu).is_empty()])
	await _touch_tap(sh.to_window(sm._planet_pos(sm.sel)), 0.5)   # again: choose it
	var menus := get_tree().get_nodes_in_group("tap_targets").filter(func(n): return n is Menu)
	print("[screens] tap it again: level menu open=%s slot='%s'" % [not menus.is_empty(), tc.slot_mode])
	await window_shot("touch_starmap_levels")
	if not menus.is_empty():
		var m: Menu = menus[0]
		var row := sh.to_window(m.get_global_rect().position + m._slot(0) + Vector2(12, 4))
		await _touch_tap(row, 0.3)
		await _touch_tap(row, 2.0)
	print("[screens] deployed to: %s" % res.pick)
	# training: tap a module, tap it again, tap a tier (no stick, B for back)
	for c in main.cine_layer.get_children():
		c.queue_free()
	main.fade_rect.color.a = 0.0
	var tr := Training.new()
	main.cine_layer.add_child(tr)
	var tres := {"pick": null}
	var go_tr := func() -> void:
		tres.pick = await tr.run()
	go_tr.call()
	await wait(0.6)
	await window_shot("touch_training")
	print("[screens] training: slot='%s' hidden=%s stick blocked=%s" % [tc.slot_mode, tc.hidden_ids, tc.joy_blocked])
	var tb := tr.sel
	var tt := (tb + 1) % Data.TRAINING_MODULES.size()
	await _touch_tap(sh.to_window(tr._module_pos(tt)), 0.3)
	print("[screens] tap a module: selected %s -> %s (want %s)" % [tb, tr.sel, tt])
	await _touch_tap(sh.to_window(Vector2(300, 100)), 0.3)   # empty space: nothing
	print("[screens] tap empty space: still %s" % tr.sel)
	await _touch_tap(sh.to_window(tr._module_pos(tr.sel)), 0.5)
	var tmenus := get_tree().get_nodes_in_group("tap_targets").filter(func(n): return n is Menu)
	print("[screens] tap it again: tier menu open=%s slot='%s'" % [not tmenus.is_empty(), tc.slot_mode])
	await window_shot("touch_training_tiers")
	if not tmenus.is_empty():
		var tm: Menu = tmenus[0]
		var trow := sh.to_window(tm.get_global_rect().position + tm._slot(0) + Vector2(12, 4))
		await _touch_tap(trow, 0.3)
		await _touch_tap(trow, 0.5)
	print("[screens] training pick: %s (want module %s tier 0)" % [tres.pick, Data.TRAINING_MODULES[tt]])
	tr.queue_free()
	# save slots: tap a slot, tap it again; B backs out
	var ss := SlotScreen.new()
	ss.setup("new")
	main.cine_layer.add_child(ss)
	var sres := {"n": -1}
	var go_ss := func() -> void:
		sres.n = await ss.run()
	go_ss.call()
	await wait(0.6)
	await window_shot("touch_slots")
	print("[screens] slots: slot='%s' hidden=%s stick blocked=%s" % [tc.slot_mode, tc.hidden_ids, tc.joy_blocked])
	await _touch_tap(sh.to_window((ss.cards[2] as Control).get_global_rect().get_center()), 0.3)
	print("[screens] tap slot 3: sel=%s (want 2) chosen=%s" % [ss.sel, sres.n])
	await _touch_tap(sh.to_window((ss.cards[2] as Control).get_global_rect().get_center()), 0.3)
	print("[screens] tap it again: chosen=%s (want 3) still tappable=%s" % [sres.n, ss.is_in_group("tap_targets")])
	sres.n = -1
	go_ss.call()
	await wait(0.3)
	await _touch_tap(_control("b"), 0.3)
	print("[screens] B on slots: chosen=%s (want 0)" % sres.n)
	ss.queue_free()
	# name entry: letters type on one tap, B erases, Look changes, End accepts
	Game.player_name = ""
	var ne := NameEntry.new()
	main.cine_layer.add_child(ne)
	var nres := {"done": false}
	var go_ne := func() -> void:
		await ne.run()
		nres.done = true
	go_ne.call()
	await wait(0.6)
	print("[screens] name entry: slot='%s' hidden=%s stick blocked=%s" % [tc.slot_mode, tc.hidden_ids, tc.joy_blocked])
	for k in [[0, 0], [2, 1], [2, 2]]:   # A, b, c
		await _touch_tap(sh.to_window((ne.grid[k[0]][k[1]] as Label).global_position + Vector2(2, 3)), 0.2)
	print("[screens] typed: '%s' (want 'Abc')" % ne.name_text)
	await _touch_tap(_control("b"), 0.3)
	print("[screens] B erased: '%s' (want 'Ab')" % ne.name_text)
	var look0 := Game.look
	var look_l: Label = ne.grid[ROWS_N][0]
	await _touch_tap(sh.to_window(look_l.global_position + Vector2(Art.text_width(look_l.text) - 2, 3)), 0.2)
	print("[screens] tap Look >: look %s -> %s" % [look0, Game.look])
	await window_shot("touch_name")
	var end_l: Label = ne.grid[ROWS_N][2]
	await _touch_tap(sh.to_window(end_l.global_position + Vector2(4, 3)), 0.3)
	print("[screens] tap End: done=%s name='%s'" % [nres.done, Game.player_name])
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
			# confirm the result screen, win or lose (a defeat used to stall here)
			if (m.finished or not m.alive) and Engine.get_process_frames() % 20 == 0:
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
		if best.rock:
			# block toward the middle of everything blockable that's close,
			# weighted to the nearest (a wall of rocks, not just one of them)
			var sum := Vector2.ZERO
			for s in m.shots:
				var d: float = s.lp.distance_to(m.CENTER)
				if d < 170.0:
					sum += (s.lp - m.CENTER).normalized() / maxf(20.0, d)
			for th in m.threats:
				if th.is_asteroid:
					var d: float = th.lp.distance_to(m.CENTER)
					if d < 170.0:
						sum += (th.lp - m.CENTER).normalized() / maxf(20.0, d)
			if sum.length() > 0.0001:
				to = sum.normalized()
		# "key" aim with no keys held leaves facing alone ("mouse" aim would
		# snap it back to the cursor every frame and undo the block)
		m._aim_mode = "key"
		m.facing = -to if best.rock else to
		if not best.rock:
			m._try_fire(true)


# ---------------------------------------------------------- levelcheck ---

func _levelcheck() -> void:
	## Plays levels with the standard kit (no upgrades, basic shot) using the
	## bot and prints one result line per level. PK_LEVEL=<id>|<substring>|all
	## (default all); PK_SPEED=<n> runs the game n times faster (times are
	## still reported in game seconds); PK_LIMIT=<s> gives up on a level after
	## s game seconds (default 300). Pair with tools/level_report.py, which
	## checks the timelines without playing them.
	Game.testing = true
	Game.player_name = "Ari"
	Game.chapter = "hub"
	auto_talk = false
	Game.story.upgrades = {"cooldown": 0, "armor": 0, "missile": 0}
	Game.story.specials = []
	Game.story.weapons = ["basic"]
	Game.story.weapon = "basic"
	Game.story.stripped = false
	var want := OS.get_environment("PK_LEVEL")
	var ids := []
	for f in DirAccess.get_files_at("res://data/missions"):
		var id := f.get_basename()
		if f.ends_with(".json") and (want == "" or want == "all" or id == want or id.contains(want)):
			ids.append(id)
	ids.sort()
	var speed := maxf(1.0, float(OS.get_environment("PK_SPEED"))) if OS.get_environment("PK_SPEED") != "" else 1.0
	var limit := float(OS.get_environment("PK_LIMIT")) if OS.get_environment("PK_LIMIT") != "" else 300.0
	var rows := []
	main.fade_rect.color.a = 0.0
	for id in ids:
		bot = true
		Engine.time_scale = speed
		main.start_mission(id, false, false)
		var m: Mission = null
		while m == null:
			await get_tree().process_frame
			var n: int = main.mission_layer.get_child_count()
			if n > 0:
				m = main.mission_layer.get_child(n - 1)
		while not m.running:
			await get_tree().process_frame
		var t0 := Time.get_ticks_msec()
		var game_t := 0.0
		var outcome := ""
		var seen_hits := 0
		var verbose := OS.get_environment("PK_VERBOSE") != ""
		while outcome == "":
			await get_tree().process_frame
			game_t += get_process_delta_time()
			if verbose and m.hits_taken > seen_hits:
				# what was closest to the planet when it was hit, and where the bot faced
				seen_hits = m.hits_taken
				var near := []
				for th in m.threats:
					near.append([th.lp.distance_to(m.CENTER), "%s@%d" % [th.drone_type if not th.is_asteroid else "rock", int(rad_to_deg((th.lp - m.CENTER).angle()) + 450) % 360]])
				for sh in m.shots:
					near.append([sh.lp.distance_to(m.CENTER), "shot@%d" % (int(rad_to_deg((sh.lp - m.CENTER).angle()) + 450) % 360)])
				near.sort_custom(func(a, b): return a[0] < b[0])
				print("[levelcheck]   hit %d at %.1fs (level_t %.1f) facing %d, nearest: %s" % [seen_hits, game_t, m.level_t,
					int(rad_to_deg(m.facing.angle()) + 450) % 360, ", ".join(near.slice(0, 3).map(func(x): return "%s d%d" % [x[1], int(x[0])]))])
			if m.finished:
				outcome = "WIN"
			elif not m.alive:
				outcome = "LOSE"
			elif game_t > limit:
				outcome = "TIMEOUT"
		var line := "[levelcheck] %-26s %-7s %6.1fs  hits %2d  hp %d/%d  real %.0fs" % [id, outcome, game_t,
			m.hits_taken, int(m.hp), int(m.MAX_HP), (Time.get_ticks_msec() - t0) / 1000.0]
		print(line)
		rows.append(line)
		if outcome == "TIMEOUT":
			m.alive = false
			m.running = false
			m._finish("retreat")
		# the bot confirms the result screen; wait for the mission to go
		while is_instance_valid(m) and not m.is_queued_for_deletion():
			await get_tree().process_frame
		Engine.time_scale = 1.0
		await wait(0.5)
	bot = false
	print("[levelcheck] ---- summary (standard kit, speed x%.0f) ----" % speed)
	for r in rows:
		print(r)


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
	if scenario == "touch_screens":
		await _touch_screens()
		return
	if scenario == "touch":
		await _touch_test()
		return
	match scenario:
		"levelcheck":
			await _levelcheck()
			get_tree().quit()
		"title":
			main.title()
			await wait(2.5)
			await shot("title")
			await wait(3.5)
			await shot("title_menu")
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
		"codec":
			# pilot codec calls: the portrait panel blinks to the pilot's face
			# for their messages and back to the protagonist afterwards
			bot = true
			auto_talk = false
			Game.player_name = "Ari"
			Game.chapter = "hub"
			Game.testing = true
			main.start_mission("terra_virex_level_01", false, false)
			await wait(1.5)
			var m: Node = main.mission_layer.get_child(main.mission_layer.get_child_count() - 1)
			m._chatter_t = 999.0
			await shot("codec_00_player")
			m.pilot_call("hiro", "Ari, rocks inbound on your left. Turn!", "smile")
			m.pilot_call("hiro", "Clean. Again.", "")
			for i in 16:
				await wait(0.08 if i < 6 else 0.4)
				await shot("codec_hiro_%02d" % i)
			m._comms("SYSTEM", "Sector clear. Hold position.", 30.0, 1.0)
			m.pilot_call("pala", "Steady. Breathe. Count it out.", "sad")
			m._set_mood("shock", 0.4)   # a hit mid-call must not cover Pala
			for i in 18:
				await wait(0.35)
				await shot("codec_pala_%02d" % i)
			print("[codec] pilot_on='%s' busy=%s" % [m._pilot_on, m._comms_busy])
			Game.story.midas_dead = true
			m.pilot_call("midas", "This should never show.")
			await wait(0.3)
			print("[codec] after dead midas call: pilot_on='%s' queue=%d" % [m._pilot_on, m._comms_queue.size()])
			get_tree().quit()
		"pilotcomms":
			# every story level's scripted pilot calls under three story states
			Game.new_game()
			var M = load("res://scripts/mission.gd")
			var states := [["fresh", {"hiro": 0, "pala": 0, "midas": 0}, false, false],
				["close", {"hiro": 3, "pala": 2, "midas": 1}, false, false],
				["midas_dead+pala_gone", {"hiro": 1, "pala": 1, "midas": 2}, true, true]]
			for st in states:
				Game.story.relationships = st[1].duplicate()
				Game.story.midas_dead = st[2]
				Game.story.pala_unavailable = st[3]
				print("[pilotcomms] ---- %s ----" % st[0])
				var data: Dictionary = M.pilot_comms_data()
				for planet in Data.PLANETS:
					for lv in ["1", "2", "3"]:
						var said := []
						for c in data[planet][lv]:
							var l: Dictionary = M.pilot_line(c)
							said.append("-" if l.is_empty() else "%s/%d: %s" % [l.pilot, l.tier, l.text])
						print("[pilotcomms] %s_%s  %s" % [planet, lv, "  |  ".join(said)])
			get_tree().quit()
		"breakdown":
			# Midas' death on the codec: the first story mission after his memory
			# talk (relationship 2) freezes play, cuts him off and marks him dead
			bot = true
			auto_talk = false
			Game.player_name = "Ari"
			Game.chapter = "hub"
			Game.testing = true
			Game.story.relationships = {"hiro": 1, "pala": 1, "midas": 2}
			Game.story.midas_dead = false
			Game.story.midas_breakdown_seen = false
			main.start_mission("glacien_ix_level_01", false, false)
			await wait(0.5)
			var m: Node = main.mission_layer.get_child(main.mission_layer.get_child_count() - 1)
			print("[breakdown] armed at %.1f, midas calls left: %d" % [m._breakdown_at, m._pilot_script.filter(func(l): return l.pilot == "midas").size()])
			# the clock runs naturally up to the call (skipping ahead floods spawns)
			var hp0: float = m.hp
			var k := 0
			while not m._cutin and k < 450:
				await wait(0.1)
				k += 1
			hp0 = m.hp
			var lt: float = m.level_t
			var pos := []
			for th in m.threats:
				pos.append(th.position)
			for i in 40:
				await wait(0.45)
				await shot("breakdown_%02d" % i)
				if i == 12:
					var still := true
					for j in mini(pos.size(), m.threats.size()):
						if is_instance_valid(m.threats[j]) and m.threats[j].position != pos[j]:
							still = false
					print("[breakdown] mid-call: cutin=%s clock frozen=%s threats still=%s pilot_on=%s" % [m._cutin, is_equal_approx(lt, m.level_t), still, m._pilot_on])
			print("[breakdown] after: cutin=%s hp at call %s, now %s midas_dead=%s pilot_on='%s'" % [m._cutin, hp0, m.hp, Game.midas_dead(), m._pilot_on])
			m._arm_breakdown()
			print("[breakdown] re-arm once dead: %.1f (want -1)" % m._breakdown_at)
			Game.story.midas_dead = false
			Game.story.relationships.midas = 1
			m._arm_breakdown()
			print("[breakdown] arm at relationship 1: %.1f (want -1), dead()=%s (want false)" % [m._breakdown_at, Game.midas_dead()])
			Game.story.relationships.midas = 2
			m._arm_breakdown()
			m._finish("retreat")
			print("[breakdown] retreat before the call: midas_dead=%s (want true)" % Game.midas_dead())
			get_tree().quit()
		"console":
			# the Starbox: the bedroom prop, boot, shelf, a game (PK_GAME, or the
			# empty-slot path), pause, game over and the high-score table
			auto_talk = false
			Game.new_game()
			Game.player_name = "Ari"
			var pr: StoryPrologue = main.story.prologue
			pr.evening = true
			main.fade_rect.color.a = 0.0
			var w = main.load_map(pr._house("home_up"), Vector2i(3, 4), 0)
			await wait(0.8)
			await shot("console_room")
			var gid := OS.get_environment("PK_GAME")
			if OS.get_environment("PK_TOUCH") != "":
				Game.shell.touch._set_active(true)
			var c := ConsoleScreen.new()
			main.ui.add_child(c)
			c.run()
			await wait(0.4)
			await shot("console_boot")
			await wait(2.8)
			await shot("console_shelf")
			var idx := 0
			for i in ConsoleScreen.GAMES.size():
				if ConsoleScreen.GAMES[i].id == gid:
					idx = i
			for i in idx:
				await tap("down", 0.2)
			await shot("console_shelf_sel")
			await tap("accept", 0.3)
			if gid == "":
				await shot("console_nocart")
				await wait(1.6)
			else:
				bot = false
				var secs := float(OS.get_environment("PK_SECS")) if OS.get_environment("PK_SECS") != "" else 12.0
				var n := int(secs / 0.5)
				for i in n:
					await wait(0.5)
					if c.game and is_instance_valid(c.game) and "auto" in c.game and OS.get_environment("PK_HUMAN") == "":
						c.game.auto = true
					if i == 0 and OS.get_environment("PK_WAVE") != "" and "wave" in c.game:
						c.game.wave = int(OS.get_environment("PK_WAVE"))
					if OS.get_environment("PK_TOUCH") != "" and i == 4:
						await window_shot("console_touch")
						c.game.auto = false
						var f0: float = c.game.facing if "facing" in c.game else 0.0
						var win := get_viewport().get_visible_rect().size
						var p0 := Vector2(win.x * 0.2, win.y * 0.6)
						_finger(0, p0, true)
						await wait(0.1)
						_drag_to(0, p0 + Vector2(120, 0))
						await wait(0.6)
						print("[console] touch stick: facing %.2f -> %.2f (want toward 0)" % [f0, c.game.facing if "facing" in c.game else 0.0])
						_finger(0, p0 + Vector2(120, 0), false)
						var n0: int = c.game.shots.size() if "shots" in c.game else 0
						_finger(1, _control("pa"), true)
						await get_tree().process_frame
						await get_tree().process_frame
						print("[console] touch A: shots %d -> %d" % [n0, c.game.shots.size() if "shots" in c.game else 0])
						_finger(1, _control("pa"), false)
					if i % 2 == 0:
						await shot("console_play_%02d" % i)
					if c.state != "playing":
						break
				if c.state == "playing":
					await tap("pause", 0.4)
					await shot("console_paused")
					await tap("cancel", 0.8)
				await wait(0.8)
				await shot("console_over")
				print("[console] %s score=%d table=%s stats=%s" % [gid, c.game.score if c.game else -1, ConsoleScreen.scores(gid), Game.achv_stats])
				await tap("cancel", 0.6)
			await tap("cancel", 1.0)
			await shot("console_off")
			print("[console] state=%s inside=%s ach=%s" % [c.state, c.is_inside_tree(), Game.achieved.keys()])
			get_tree().quit()
		"tv":
			# the home TV: tune PK_CH (default 1) and screenshot its show for
			# PK_SECS, then flip through every channel once and switch off
			auto_talk = false
			Game.new_game()
			Game.player_name = "Ari"
			var pr: StoryPrologue = main.story.prologue
			pr.evening = true
			main.fade_rect.color.a = 0.0
			main.load_map(pr._house("home"), Vector2i(11, 3), 1)
			await wait(0.6)
			if OS.get_environment("PK_EP") != "":
				Game.profile.tv_serial_ep = int(OS.get_environment("PK_EP")) - 1
			var t := TvScreen.new()
			main.ui.add_child(t)
			var ch := int(OS.get_environment("PK_CH")) if OS.get_environment("PK_CH") != "" else 1
			t.run(ch - 1)
			var secs := float(OS.get_environment("PK_SECS")) if OS.get_environment("PK_SECS") != "" else 20.0
			var every := float(OS.get_environment("PK_EVERY")) if OS.get_environment("PK_EVERY") != "" else 1.0
			var n := int(secs / every)
			for i in n:
				await wait(every)
				await shot("tv_%d_%03d" % [ch, i])
			if OS.get_environment("PK_FLIP") != "":
				for k in TvShows.CHANNELS.size():
					await tap("up", 1.5)
					await shot("tv_flip_%d" % k)
			await tap("cancel", 0.8)
			print("[tv] seen=%s left on=%s serial_ep=%s ach=%s" % [t.seen.keys(), t.channel_id(), Game.profile.get("tv_serial_ep", 0), Game.achieved.keys()])
			get_tree().quit()
		"block7":
			# the street outside home: arrival, a look round, the kids' game,
			# the friends' gift, Mrs. Okafor, and the dawn send-off
			Game.new_game()
			Game.player_name = "Ari"
			var pr: StoryPrologue = main.story.prologue
			pr.evening = true
			main.fade_rect.color.a = 0.0
			main.load_map(pr._house("home"), Vector2i(15, 3), 1)
			await wait(0.5)
			var snap := {"on": true, "k": 0}
			var snapper := func() -> void:
				while snap.on:
					await wait(0.9)
					await shot("b7_%03d" % snap.k)
					snap.k += 1
			snapper.call()
			await main.story.exit({"to": "block7", "tile": Vector2i(9, 3), "dir": 0})
			var w = main.world
			for t in [Vector2i(4, 4), Vector2i(15, 4), Vector2i(25, 4), Vector2i(6, 10), Vector2i(14, 10)]:
				w.player.position = w.tile_center(t)
				await wait(1.0)
			await main.story.trigger("kids_game")
			w.player.position = w.tile_center(Vector2i(8, 10))
			await wait(0.6)
			await main.story.talk(w.actor("tomas"))
			await main.story.talk(w.actor("juno"))
			w.player.position = w.tile_center(Vector2i(24, 4))
			await wait(0.5)
			await main.story.talk(w.actor("okafor"))
			await main.story.talk(w.actor("hale"))
			await main.story.examine({"id": "noticeboard"})
			print("[block7] bracelet=%s kids=%s talks=%s" % [Game.story.get("bracelet"), Game.story.get("kids_seen"), Game.story.get("block7_talks")])
			await pr._departure()
			snap.on = false
			print("[block7] departure done, map=%s" % main.world.def.id)
			get_tree().quit()
		"wing":
			# the pilot wing: the corridor, then every room (all unlocked), its
			# first-visit scene and a couple of its things. PK_DEAD=1 kills Midas.
			Game.new_game()
			Game.player_name = "Ari"
			Game.chapter = "hub"
			for p in ["terra_virex", "glacien_ix"]:
				Game.story.completed_levels[p] = 3
			Game.story.relationships = {"hiro": 1, "pala": 1, "midas": 1}
			if OS.get_environment("PK_DEAD") != "":
				Game.story.midas_dead = true
				Game.story.midas_death_announced = true
			main.fade_rect.color.a = 0.0
			main.load_map(main.story.hub._map(), Vector2i(22, 2), 1)
			await wait(0.5)
			var snap := {"on": true, "k": 0}
			var snapper := func() -> void:
				while snap.on:
					await wait(0.8)
					await shot("wing_%03d" % snap.k)
					snap.k += 1
			snapper.call()
			await main.story.examine({"id": "wing"})
			await wait(0.6)
			var only := OS.get_environment("PK_ROOM")
			for id in Maps.WING_ROOMS:
				if only != "" and id != only:
					continue
				await main.story.examine({"id": "room:" + id})
				await wait(1.0)
				var w = main.world
				for ev in w.def.get("events", []).slice(0, 1):
					if not ["rec_tv"].has(ev.id):
						await main.story.examine(ev)
				for pr in w.def.props:
					if pr.has("event") and not ["rec_tv", "rec_starbox", "simpod", "lore"].has(pr.event.id):
						await main.story.examine(pr.event)
						break
				print("[wing] %s ok (map %s)" % [id, w.def.id])
				await main.story.exit({"to": "wing"})
				await wait(0.4)
			await main.story.exit({"to": "commons", "tile": Vector2i(22, 2), "dir": 0})
			snap.on = false
			print("[wing] back in %s; flags stargazed=%s tomato=%s" % [main.world.def.id, Game.story.get("stargazed"), Game.story.get("midas_tomato")])
			get_tree().quit()
		"hubgame":
			# a Pilot Wing game (PK_HG = pingpong / cards / drill) played by a bot
			auto_talk = false
			Game.player_name = "Ari"
			var g := HubGame.new()
			g.auto = OS.get_environment("PK_HUMAN") == ""
			main.ui.add_child(g)
			var snap := {"on": true, "k": 0}
			var snapper := func() -> void:
				while snap.on:
					await wait(0.5)
					await shot("hg_%03d" % snap.k)
					snap.k += 1
			snapper.call()
			var stop := func() -> void:
				await wait(float(OS.get_environment("PK_SECS")) if OS.get_environment("PK_SECS") != "" else 20.0)
				g.auto = false
			stop.call()
			var res: Dictionary = await g.run(OS.get_environment("PK_HG"), Data.EXTRAS[2])
			snap.on = false
			print("[hubgame] %s -> %s ach=%s" % [OS.get_environment("PK_HG"), res, Game.achieved.keys()])
			get_tree().quit()
		"propaganda":
			# the FILES page, the archive's brief reveal, and the rec room TV's
			# special bulletin with its reveal
			Game.new_game()
			Game.player_name = "Ari"
			Game.chapter = "hub"
			for p in ["terra_virex", "glacien_ix"]:
				Game.story.completed_levels[p] = 3
			Game.story.last_mission = "glacien_ix_level_03"
			main.fade_rect.color.a = 0.0
			for id in ["poster", "toy", "news", "cartridge"]:
				Propaganda.find(id)
			await wait(0.5)
			var f := PropagandaScreen.new()
			main.ui.add_child(f)
			f.run()
			await wait(0.5)
			await tap("down", 0.2)
			await shot("prop_files")
			await tap("down", 0.2)
			await tap("down", 0.2)
			await tap("down", 0.2)
			await tap("down", 0.4)
			await shot("prop_files_unfound")
			await tap("cancel", 0.5)
			f.queue_free()
			var snap := {"on": true, "k": 0}
			var snapper := func() -> void:
				while snap.on:
					await wait(0.6)
					await shot("prop_%03d" % snap.k)
					snap.k += 1
			snapper.call()
			main.load_map(Maps.wing_room("archive"), Vector2i(7, 7), 1)
			Game.story.room_archive_seen = true
			await wait(0.5)
			await main.story.wing._brief_reveal()
			main.load_map(Maps.wing_room("rec"), Vector2i(7, 7), 1)
			await wait(0.5)
			var closer := func() -> void:
				await wait(26.0)
				await tap("cancel", 0.3)
			closer.call()
			await main.story.examine({"id": "rec_tv"})
			snap.on = false
			print("[propaganda] found=%d/%d %s footage_seen=%s ach=%s" % [Propaganda.count(), Propaganda.ORDER.size(), Propaganda.found_all().keys(), Game.story.get("footage_seen"), Game.achieved.keys()])
			get_tree().quit()
		"tomato":
			# the rooftop planter across visits once Midas is gone
			Game.new_game()
			Game.chapter = "hub"
			for p in ["terra_virex", "glacien_ix"]:
				Game.story.completed_levels[p] = 3
			Game.story.midas_dead = true
			main.fade_rect.color.a = 0.0
			for step in ["first", "again", "watered"]:
				if step == "watered":
					Game.story.watered_tomato = true
				main.load_map(Maps.wing_room("rooftop"), Vector2i(7, 7), 1)
				Game.story.room_rooftop_seen = true
				await wait(0.6)
				var tom: Sprite2D = main.world.prop_sprite("tomato")
				print("[tomato] %s: planter is %s" % [step, "v2 wilted" if tom.texture == Art.prop("planter", 2) else ("v0 green" if tom.texture == Art.prop("planter", 0) else "v1 tomatoes")])
				await shot("tomato_" + step)
			get_tree().quit()
		"ascend":
			# beat the very last story level and come back to the Commons: the
			# ascension ending should play (PK_SKIP leaves one planet short)
			Game.new_game()
			Game.player_name = "Ari"
			Game.chapter = "hub"
			Game.testing = true
			for pl in Data.PLANETS:
				Game.unlock_planet(pl)
				Game.story.completed_levels[pl] = 3
			var last := OS.get_environment("PK_SKIP") if OS.get_environment("PK_SKIP") != "" else "mechanon_ascens"
			Game.story.completed_levels[last] = 2
			Game.story.interval_count = 9
			print("[ascend] before: all_levels_done=%s" % Game.all_levels_done())
			if OS.get_environment("PK_SKIP") == "":
				Game.mark_completed(last, 3)
			print("[ascend] after last level: all_levels_done=%s automatic=%s" % [Game.all_levels_done(), Game.automatic_ending_type()])
			main.fade_rect.color.a = 0.0
			main.story.hub.enter({"result": "win", "credits": 0})
			for i in 30:
				await wait(1.0)
				if i % 3 == 0:
					await shot("ascend_%02d" % i)
			print("[ascend] ending played: %s (endings so far %s)" % [main.story.endings.kind, Game.history.map(func(h): return h.ending)])
			get_tree().quit()
		"doorwalk":
			# every door and exit, walked through like a player would (keys
			# held, fast and back to back), checking walking mode comes back
			# each time; then a lock with nothing behind it must lift itself
			auto_talk = true
			Game.new_game()
			Game.player_name = "Ari"
			for pl in ["terra_virex", "glacien_ix"]:
				Game.story.completed_levels[pl] = 3
			var pr: StoryPrologue = main.story.prologue
			pr.evening = true
			Game.story.block7_seen = true
			Game.story.wing_seen = true
			main.fade_rect.color.a = 0.0
			var fails := []
			var checks := {"n": 0, "log": []}
			var settle := func() -> bool:
				for k in 250:
					await wait(0.1)
					var cw = main.world
					if cw and is_instance_valid(cw) and not cw.busy and not main.dialog.visible and main.fade_rect.color.a < 0.05:
						return true
				return false
			var can_move := func() -> bool:
				# walking mode is on and at least one direction is open
				var cw = main.world
				if cw.busy or cw.paused or main.dialog.visible:
					return false
				for v in [Vector2(0, -3), Vector2(-3, 0), Vector2(3, 0), Vector2(0, 3)]:
					if not cw.blocked(cw.player.position + v, cw.player):
						return true
				return false
			var step := func(label: String, tile: Vector2i, dir: String, mode: String) -> void:
				var cw = main.world
				cw.player.position = cw.tile_center(tile)
				await wait(0.1)
				if mode == "walk":
					await hold(dir, 0.6)
				else:
					cw.player.face({"up": 1, "down": 0, "left": 3, "right": 2}[dir])
					await tap("accept", 0.2)
				var ok: bool = await settle.call()
				var mv: bool = ok and await can_move.call()
				checks.n += 1
				checks.log.append("%s -> %s" % [label, main.world.def.id])
				print("[doorwalk] %s -> %s settled=%s moved=%s" % [label, main.world.def.id, ok, mv])
				if not ok or not mv:
					fails.append("%s (map %s, settled=%s moved=%s)" % [label, main.world.def.id, ok, mv])
			for rep in int(OS.get_environment("PK_REPS")) if OS.get_environment("PK_REPS") != "" else 3:
				main.load_map(pr._house("home"), Vector2i(20, 4), 1)
				await wait(0.4)
				await step.call("home stairs up", Vector2i(21, 3), "up", "walk")
				await step.call("home_up stairs down", Vector2i(20, 10), "down", "walk")
				await step.call("front door out", Vector2i(15, 3), "up", "walk")
				await step.call("Block 7 door home", Vector2i(9, 3), "up", "walk")
				Game.chapter = "hub"
				main.load_map(main.story.hub._map(), Vector2i(22, 3), 1)
				await wait(0.4)
				await step.call("Commons door to the wing", Vector2i(22, 2), "up", "examine")
				for id in Maps.WING_ROOMS:
					if not StoryWing.unlocked(id):
						continue
					await step.call("wing door " + id, Vector2i(Maps.WING_DOOR_X[id], 2), "up", "examine")
					await step.call("leave " + id, Vector2i(7, 7), "down", "walk")
				await step.call("wing back to the Commons", Vector2i(14, 4), "down", "walk")
				Game.chapter = "prologue"
			print("[doorwalk] path: %s" % ", ".join(checks.log.slice(0, 14)))
			print("[doorwalk] %d door checks, %d stuck: %s" % [checks.n, fails.size(), fails])
			# a lock nobody will lift
			main.world.busy = true
			var t0 := Time.get_ticks_msec()
			while main.world.busy and Time.get_ticks_msec() - t0 < 9000:
				await wait(0.2)
			print("[doorwalk] stale lock lifted=%s after %.1fs" % [not main.world.busy, (Time.get_ticks_msec() - t0) / 1000.0])
			get_tree().quit()
		"stuckcheck":
			# can the player always move after a field cutscene? and does a
			# map-changing interaction keep control locked until it's done?
			Game.new_game()
			Game.player_name = "Ari"
			var pr: StoryPrologue = main.story.prologue
			pr.evening = true
			main.fade_rect.color.a = 0.0
			main.load_map(Maps.block7("evening"), Vector2i(8, 10), 1)
			await wait(0.5)
			var w = main.world
			await main.story.talk(w.actor("tomas"))
			await wait(0.3)
			var moves := []
			for d in ["left", "right", "up", "down"]:
				var before: Vector2 = w.player.position
				await hold(d, 0.35)
				moves.append("%s %.0f" % [d, w.player.position.distance_to(before)])
			print("[stuck] after the bracelet scene: busy=%s moves=%s" % [w.busy, moves])
			await shot("stuck_bracelet")
			# someone parked right on top of you
			var pip = w.actor("pip")
			pip.position = w.player.position + Vector2(3, 0)
			var b2: Vector2 = w.player.position
			await hold("left", 0.35)
			print("[stuck] overlapped by Pip: stepped away %.0f px (want > 0)" % w.player.position.distance_to(b2))
			# a map-changing interaction: entering a Pilot Wing room
			Game.chapter = "hub"
			main.load_map(Maps.wing(), Vector2i(2, 2), 1)
			await wait(0.4)
			var unlocked_mid := []
			var watch := {"on": true}
			var watcher := func() -> void:
				while watch.on:
					await get_tree().process_frame
					var cw = main.world
					if cw and is_instance_valid(cw) and cw.def.id == "room_rec" and not cw.busy:
						unlocked_mid.append(Engine.get_process_frames())
			watcher.call()
			main.world.run(main.story.examine.bind({"id": "room:rec"}))
			await wait(0.1)
			while main.world.busy or main.world.def.id != "room_rec":
				await wait(0.1)
			watch.on = false
			print("[stuck] room entry: frames unlocked during the scene=%d, unlocked at the end=%s on %s" % [maxi(0, unlocked_mid.size() - 2), not main.world.busy, main.world.def.id])
			get_tree().quit()
		"commonstalk":
			# the Commons' named recruits and the bot, talked to in the field
			auto_talk = false
			Game.new_game()
			Game.player_name = "Ari"
			Game.chapter = "hub"
			main.fade_rect.color.a = 0.0
			main.load_map(main.story.hub._map(), Vector2i(12, 8), 1)
			await wait(0.5)
			var w = main.world
			var k := 0
			for id in ["rec0", "rec1", "rec2", "rec3", "rec4", "bot"]:
				var act = w.actor(id)
				if act == null:
					continue
				var go := func() -> void:
					await main.story.talk(act)
				go.call()
				await wait(1.6)
				await shot("ct_%d" % k)
				k += 1
				for j in 4:
					await tap("accept", 0.3)
			get_tree().quit()
		"scenes":
			# every staged field moment (StoryScenes), each under the story state
			# that unlocks it; PK_SCENE runs just one
			var all := {"nell_birthday": ["commons", {"interval_count": 2}, {}, 1],
				"pala_files": ["commons", {}, {"pala": 1}, 1],
				"hiro_alone": ["commons", {}, {"hiro": 2}, 1],
				"transfer": ["commons", {}, {}, 4],
				"forgot_name": ["commons", {"last_result": "lose"}, {}, 1],
				"midas_bread": ["mess", {}, {}, 1],
				"argument": ["rooftop", {}, {"hiro": 2, "pala": 2}, 5],
				"pala_note": ["memorial", {"midas_dead": true, "midas_death_announced": true}, {"midas": 2}, 4],
				"barrier": ["parade", {}, {}, 0]}
			var only := OS.get_environment("PK_SCENE")
			var snap := {"on": true, "k": 0, "tag": ""}
			var snapper := func() -> void:
				while snap.on:
					await wait(0.7)
					await shot("sc_%s_%03d" % [snap.tag, snap.k])
					snap.k += 1
			snapper.call()
			for id in all:
				if only != "" and id != only:
					continue
				var spec: Array = all[id]
				Game.new_game()
				Game.player_name = "Ari"
				Game.chapter = "hub" if spec[0] != "parade" else "prologue"
				for k in spec[1]:
					Game.story[k] = spec[1][k]
				var rel := {"hiro": 0, "pala": 0, "midas": 0}
				rel.merge(spec[2], true)
				Game.story.relationships = rel
				var lv := 0
				for pl in Data.PLANETS:
					if lv >= spec[3]:
						break
					Game.story.completed_levels[pl] = mini(3, spec[3] - lv)
					lv += mini(3, spec[3] - lv)
				for other in all:
					if other != id:
						StoryScenes.mark(other)
				snap.tag = id
				snap.k = 0
				main.fade_rect.color.a = 0.0
				match spec[0]:
					"commons":
						main.load_map(main.story.hub._map(), Vector2i(12, 12), 1)
						await wait(0.4)
						await main.story.scenes.commons_scene()
					"parade":
						main.load_map(Maps.parade(), Vector2i(23, 10), 3)
						await wait(0.4)
						await main.story.scenes.barrier()
					_:
						var rm := Maps.wing_room(spec[0])
						rm.npcs = rm.npcs.duplicate()
						rm.npcs.append_array(main.story.scenes.room_cast(spec[0]))
						main.load_map(rm, Vector2i(7, 7), 1)
						await wait(0.4)
						await main.story.scenes.room_scene(spec[0])
				print("[scenes] %s played=%s" % [id, StoryScenes.seen(id)])
				await wait(0.8)
			snap.on = false
			get_tree().quit()
		"npctalk":
			# every talkable person, three talks each, under three story states
			Game.new_game()
			Game.player_name = "Ari"
			var states := [["fresh", {}, 0],
				["middle", {"block7_seen": true, "bracelet": true, "last_result": "win"}, 4],
				["late", {"midas_dead": true, "last_result": "lose"}, 7]]
			for st in states:
				Game.new_game()
				for k in st[1]:
					Game.story[k] = st[1][k]
				var lv := 0
				for p in Data.PLANETS:
					if lv >= st[2]:
						break
					Game.story.completed_levels[p] = mini(3, st[2] - lv)
					lv += mini(3, st[2] - lv)
				Game.vars.letter_choice = "resolve" if st[0] == "middle" else "silent"
				print("[npctalk] ---- %s (done=%d) ----" % [st[0], Game.completed_count()])
				for key in NpcTalk.data():
					var said := []
					var inst := "crowd3" if key.ends_with(".crowd") else ("rec1" if key.ends_with(".rec") else "")
					for i in 3:
						var l := NpcTalk.line(key, inst)
						said.append("-" if l.is_empty() else l[1])
					var rep: bool = said[0] == said[1] or said[1] == said[2]
					print("[npctalk] %s%s  %s" % [key, "  REPEAT!" if rep else "", "  |  ".join(said)])
			get_tree().quit()
		"house":
			# both floors of home: walk into your room through its door, then
			# take the stairs down and back up
			Game.new_game()
			Game.player_name = "Ari"
			auto_talk = false
			var pr: StoryPrologue = main.story.prologue
			pr.evening = true
			main.fade_rect.color.a = 0.0
			var w = main.load_map(pr._house("home"), Vector2i(16, 5), 0)
			w.cam_follow = true
			await wait(0.8)
			await shot("house_ground")
			w.player.position = w.tile_center(Vector2i(6, 5))
			await wait(0.4)
			await shot("house_kitchen")
			w.player.position = w.tile_center(Vector2i(21, 4))
			await hold("up", 0.7)
			await wait(1.2)
			w = main.world
			print("[house] after stairs up: map=%s at %s" % [w.def.id, Vector2i(w.player.position / 16.0)])
			await shot("house_up")
			w.player.position = w.tile_center(Vector2i(4, 9)) + Vector2(4, 0)   # a little off centre
			var door: Dictionary = w.doors[0]
			print("[house] door shut before=%s" % [not door.open])
			await hold("up", 0.35)
			await wait(0.1)
			print("[house] door open in the doorway=%s at %s" % [door.open, w.player.position])
			await shot("house_door")
			await hold("up", 0.8)
			print("[house] walked into the bedroom: tile=%s (want y<=5)" % [Vector2i(w.player.position / 16.0)])
			await shot("house_bedroom")
			await wait(0.6)
			print("[house] door shut again=%s" % [not door.open])
			w.player.position = w.tile_center(Vector2i(20, 9))
			await hold("down", 0.9)
			await wait(1.2)
			print("[house] after stairs down: map=%s at %s" % [main.world.def.id, Vector2i(main.world.player.position / 16.0)])
			await shot("house_back_down")
			w = main.world
			w.player.position = w.tile_center(Vector2i(21, 4))
			await hold("up", 0.7)
			await wait(1.2)
			w = main.world
			w.player.position = w.tile_center(Vector2i(2, 4))
			w.player.face(1)
			await tap("accept", 0.4)
			await wait(0.2)
			print("[house] back up, bed asks to sleep=%s" % main.dialog.visible)
			await shot("house_bed")
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
					# up the stairs
					w.player.position = w.tile_center(Vector2i(21, 4))
					await hold("up", 0.7)
				elif w and w.marker and w.marker.visible and not w.busy and w.def.id == "home_up":
					w.player.position = w.tile_center(Vector2i(2, 4))
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
		"brows":
			# the cast's faces in every mood: portraits (zoom 3) and field
			# sprites front and side, saved as one sheet (PK_OUT/brows.png)
			Game.player_name = "Ari"
			var specs := [Game.player_spec("academy"), Game.cast("hiro"), Game.cast("pala"), Game.cast("midas"),
				Game.cast("mother"), Game.cast("father"), Game.cast("instructor"), Game.cast("okafor")]
			var moods := ["", "smile", "sad", "cry", "angry", "shock", "terrified", "hollow", "closed"]
			var cw := 72
			var ch := 72 + 40
			var img := Image.create(cw * moods.size(), ch * specs.size(), false, Image.FORMAT_RGBA8)
			img.fill(Color("1a1626"))
			for r in specs.size():
				for c in moods.size():
					var pt: Image = Art.portrait(specs[r], moods[c], false, false, 3).get_image()
					img.blend_rect(pt, Rect2i(Vector2i.ZERO, pt.get_size()), Vector2i(c * cw + 0, r * ch))
					for k in 2:
						var sp: Image = Art.person(specs[r], [0, 2][k], 0, moods[c], "walk").get_image()
						sp.resize(sp.get_width() * 1, sp.get_height() * 1, Image.INTERPOLATE_NEAREST)
						img.blend_rect(sp, Rect2i(Vector2i.ZERO, sp.get_size()), Vector2i(c * cw + 4 + k * 34, r * ch + 74))
			img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
			img.save_png(out + "/brows.png")
			print("[brows] saved %dx%d" % [img.get_width(), img.get_height()])
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
		"beamcheck":
			# Beam Shot: pierces a line of tanks at once and can be swept onto a target
			auto_talk = false
			Game.story.weapons = ["basic", "beam"]
			Game.story.weapon = "beam"
			main.start_mission("terra_virex_level_01", true, false)
			await wait(1.0)
			var m: Mission = main.mission_layer.get_child(0)
			m.timeline = []
			m._aim_mode = "key"
			var line := []
			for d in [70.0, 120.0, 170.0]:
				m._spawn({"enemy_type": "drone_tank", "spawn_side": "north"})
				var th: Threat = m.threats[m.threats.size() - 1]
				th.lp = Mission.CENTER + Vector2(0, -d)
				th.move_speed = 0.0
				line.append(th)
			m._spawn({"enemy_type": "drone_tank", "spawn_side": "east"})
			var side: Threat = m.threats[m.threats.size() - 1]
			side.lp = Mission.CENTER + Vector2(140, 0)
			side.move_speed = 0.0
			for th in m.threats:
				print("before hp ", th.hp)
			m.facing = Vector2.UP
			m._fire_cd = 0.0
			m._try_fire()
			await wait(0.08)
			await shot("beam_fire")
			# sweep the beam toward the side target while it is still active
			for i in 8:
				m.facing = Vector2.UP.rotated(PI / 2.0 * (i + 1) / 8.0)
				await get_tree().process_frame
			await shot("beam_sweep")
			print("beam active after sweep: ", not m.beam.is_empty())
			for th in line:
				print("line hp ", th.hp if is_instance_valid(th) else -1.0)
			print("side hp ", side.hp if is_instance_valid(side) else -1.0)
			await wait(0.4)
			print("beam ended: ", m.beam.is_empty(), " can refire right away: ", m._try_fire())
			await wait(1.0)
			print("refire after cooldown: ", m._try_fire())
			get_tree().quit()
		"missilecheck":
			# Auto Missile levels 1-3: bought in the Workshop, one missile per level per volley
			auto_talk = false
			Game.testing = true
			Game.story.credits = 5000
			Game.mark_completed("terra_virex", 5)
			main.load_map(Maps.commons(), Vector2i(6, 12), 1)
			main.workshop()
			await wait(1.2)
			var ws: Workshop = null
			for c in main.ui.get_children():
				if c is Workshop:
					ws = c
			print("start: missile level ", Game.missile_level(), " credits ", Game.credits(), " upgrades ", Game.story.upgrades, " specials ", Game.story.specials)
			for k in 4:
				for i in ws.rows.size():
					if ws.rows[i].get("id", "") == "missile":
						ws.menu.index = i
						ws._describe(i)
				await wait(0.3)
				if k == 1:
					await shot("ws_missile")
				print("row: ", ws.rows[ws.menu.index].text, " ", ws.rows[ws.menu.index].right, " stat: ", ws.d_stat.text)
				await tap("accept", 0.8)
			print("missile level ", Game.missile_level(), " specials ", Game.story.specials, " credits ", Game.credits())
			await tap("cancel", 1.2)
			for lvl in [1, 2, 3]:
				Game.story.upgrades.missile = lvl
				main.start_mission("terra_virex_level_01", true, false)
				await wait(1.0)
				var m: Mission = main.mission_layer.get_child(main.mission_layer.get_child_count() - 1)
				m.timeline = []
				for d in [0.0, 90.0, 180.0, 270.0]:
					m._spawn({"enemy_type": "drone_tank", "spawn_side": "north"})
					var th: Threat = m.threats[m.threats.size() - 1]
					th.lp = Mission.CENTER + Vector2.from_angle(deg_to_rad(d)) * (120.0 + d * 0.2)
					th.move_speed = 0.0
				m._missile_t = 0.0
				for i in 3:
					await get_tree().process_frame
				var tg := {}
				for ms in m.missiles:
					if ms.target != null:
						tg[ms.target.get_instance_id()] = true
				if lvl == 3:
					await wait(0.15)
					await shot("missile_volley")
				print("level ", lvl, " loadout ", m.lo.missile, " missiles ", m.missiles.size(), " distinct targets ", tg.size())
				m.queue_free()
				await wait(0.3)
			get_tree().quit()
		"eyesroll":
			# badge contact: gasp, eyes roll up, then the sync flash
			auto_talk = false
			var c := Cinema.open()
			c.show_tex(Art.cine("badge_bg"), 0.0)
			var bs := c.sprite(Art.cine("badge", 1), Vector2(160, 104), 1.0)
			var nm := Art.shadow_label("ARI", Pal.FROST)
			nm.position = Vector2(-Art.text_width(nm.text) / 2.0, 8)
			bs.add_child(nm)
			await wait(0.5)
			Sfx.play("gasp", 1.0, -2.0)
			print("gasp stream: ", Sfx.sounds["gasp"].get_class(), " length ", Sfx.sounds["gasp"].get_length())
			var done := [false]
			var roll := func() -> void:
				await c.eyes_roll(1.2)
				done[0] = true
			roll.call()
			for i in 4:
				await wait(0.28)
				await shot("eyes_%d" % i)
			while not done[0]:
				await get_tree().process_frame
			print("eyes_roll returned: ", done[0])
			var to_warp := func() -> void:
				c.clear_sprites()
				c.show_tex(null, 0.0)
				c.effect = "warp"
				c.effect_k = 1.0
				c.set_vignette(0.75, 0.0)
			var faded := [false]
			var cross := func() -> void:
				await c.eyes_fade(to_warp, 0.6, 0.4, 2.0)
				faded[0] = true
			cross.call()
			for i in 6:
				await wait(0.5)
				await shot("eyes_after_%d" % i)
			await wait(0.2)
			print("fade returned: ", faded[0])
			get_tree().quit()
		"firecheck":
			auto_talk = false
			var fw := OS.get_environment("PK_WEAPON")
			if fw != "":
				Game.story.weapons = ["basic", fw]
				Game.story.weapon = fw
			main.start_mission("terra_virex_level_01", true, false)
			await wait(1.0)
			var m: Mission = main.mission_layer.get_child(0)
			var mx := 0
			var shots := 0
			# hold fire
			_send("accept", true)
			for i in 90:
				var before := m.bolts.size()
				await get_tree().process_frame
				shots += maxi(0, m.bolts.size() - before)
				mx = maxi(mx, m.bolts.size())
			_send("accept", false)
			print("weapon ", m.lo.weapon, " held fire, shots: ", shots, " max in flight: ", mx)
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
			if not Game.story.specials.has("missile"):
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
