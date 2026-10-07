class_name StoryAcademy
extends RefCounted
## Chapter 1 and the first deployment: orientation, the badge, the pairing pods,
## the briefing, the waiting room, Terra Virex, and the aftermath.
## (scene_1_1 .. scene_2_4)

var s: Story
var phase := ""


func _init(p_s: Story) -> void:
	s = p_s


# ---------------------------------------------------- 1.1 orientation hall --

func orientation() -> void:
	var m = s.m
	s.save_at("academy")
	var c := Cinema.open()
	c.show_tex(Art.cine("academy_ext"), 0.0)
	c.effect = "stars"
	c.effect_k = 0.3
	Sfx.music("low_mechanical_ambient", 1.5)
	await m.fade_in(1.0)
	await s.say("", "The Academy doesn't look like a school.")
	await m.fade_out(0.6)
	c.queue_free()
	var mp := Maps.hall()
	m.load_map(mp, Vector2i(5, 9), 1)
	var pl := s.w.player
	pl.set_pose("sit")
	s.w.busy = true
	s.place("instructor", Vector2i(10, 12), 1)
	s.w.cam_follow = false
	s.w.cam_focus = s.w.tile_center(Vector2i(9, 7))
	s.w.cam.position = s.w.cam_focus
	await m.fade_in(0.8)
	s.w.show_area_name()
	await s.say("", ["No windows. No decorations. Just clean lines and soft lights that never flicker.", "They seat you in rows."])
	for i in 6:
		Sfx.play("step", 0.8 + randf() * 0.2, -10.0)
		await s.wait(0.18)
	await s.say("~", "It smells like metal... and something burnt.")
	Sfx.play("door", 1.0, -4.0)
	await s.walk("instructor", [Vector2i(10, 4), Vector2i(10, 3)], 40.0)
	s.a("instructor").position.x -= 8
	s.face("instructor", 0)
	await s.say("instructor", ["Welcome, recruits.", "You have been chosen because you possess something rare. Adaptability.",
		"Most minds resist neural integration. Yours don't.", "This is not a burden. This is a gift."], "neutral")
	s.emote("rec3", "!")
	s.emote("rec7", "?")
	await s.say("", "Some recruits straighten up. Some look confused. Someone near you exhales slowly.")
	await s.say("instructor", "The Protektor is a planetary defense system. It responds faster than any adult pilot because it thinks with you.")
	await s.say("~", "That doesn't sound like a machine.")
	var r := await s.ask("What do you do?", ["What happens if something goes wrong?", "How long is training?", "(Say nothing)"])
	match r:
		0:
			Game.vars.orientation_question = "failure"
			await s.say("you", "What happens if something goes wrong?", "worried")
			await s.say("instructor", ["Then we correct it. Quickly. Nothing about this program assumes failure.", "If you are worried, use that energy to focus."])
		1:
			Game.vars.orientation_question = "training"
			await s.say("you", "How long is training?")
			await s.say("instructor", ["Until you interface with confidence.", "Some recruits finish in weeks. Some need months. Time follows discipline."])
		_:
			Game.vars.orientation_question = "silent"
			await s.say("", "You keep your question to yourself. The Instructor scans the rows anyway.")
	await s.say("instructor", ["You will hear rumors. Ignore them.", "You will feel sensations during synchronization. This is normal. Excitement. Clarity. Focus."])
	await s.say("~", "They didn't say fear.")
	await s.say("", "You glance sideways.")
	s.face("hiro", 2)
	s.emote("hiro", "note")
	await s.say("", "Hiro, still smiling.")
	await s.say("hiro", "Bet this beats school.", "still_smiling")
	s.face("hiro", 1)
	s.mood("pala", "sad")
	await s.say("", "Pala, watching the floor panels.")
	await s.say("pala", "They skipped page three.", "anxious")
	s.a("midas").shake(0.4, 1.0)
	await s.say("", "Midas, gripping his sleeves.")
	await s.say("midas", "My mom said this would be safe...", "uneasy")
	await s.say("instructor", ["You will be assigned dormitories. You will be assigned training modules.", "Participation is optional. Completion is... encouraged."])
	await s.say("~", "That sounded different.")
	Sfx.music("low_sync_hum", 1.5)
	await s.w.set_tint(Maps.COLD, 1.0)
	await s.say("", "The room empties in neat lines.")
	for i in 13:
		var act := s.a("rec%d" % i)
		if act:
			act.set_pose("walk")
			var go := func() -> void:
				if await act.walk_to([Vector2(act.position.x, s.w.tile_center(Vector2i(0, 12)).y), s.w.tile_center(Vector2i(10, 12)), s.w.tile_center(Vector2i(10, 13))], 50.0):
					act.visible = false
			go.call()
			await s.wait(0.12)
	m.shake(1.0, 1.2)
	Sfx.play("heavy_door", 0.6, -10.0)
	await s.say("", "Somewhere beneath the floor... something is waiting.")
	await m.fade_out(1.0)
	await badge()


# ---------------------------------------------------------- 1.2 the badge --

func badge() -> void:
	var m = s.m
	var line := [Vector2i(3, 6), Vector2i(4, 6), Vector2i(5, 6), Vector2i(6, 6), Vector2i(7, 6), Vector2i(8, 6), Vector2i(9, 6), Vector2i(11, 6), Vector2i(12, 6), Vector2i(13, 6), Vector2i(14, 6), Vector2i(15, 6), Vector2i(16, 6)]
	var who := ["rec0", "rec1", "hiro", "rec2", "pala", "player", "midas", "rec3", "rec4", "rec5", "rec6", "rec7", "rec8"]
	for i in who.size():
		var act := s.a(who[i])
		if act:
			act.stop_walk()
			act.visible = true
			act.set_pose("walk")
			act.position = s.w.tile_center(line[i])
			act.face(1)
	s.w.player.set_pose("walk")
	var off := s.w.add_npc({"id": "officer", "who": "officer", "tile": Vector2i(2, 5), "dir": 2})
	var tray := Sprite2D.new()
	tray.texture = Art.prop("tray")
	tray.position = Vector2(0, -12)
	tray.z_index = 1
	off.add_child(tray)
	s.place("instructor", Vector2i(10, 3), 0)
	s.a("instructor").position.x -= 8
	s.w.cam_focus = s.w.tile_center(Vector2i(9, 5))
	s.w.cam.position = s.w.cam_focus
	s.w.tint.color = Color(0.86, 0.92, 1.0)
	await m.fade_in(0.8)
	await s.say("", ["They don't call it a test.", "They call it distribution."])
	Sfx.play("plate", 0.6, -6.0)
	await s.say("", ["An officer walks down the line.", "On the tray, small metallic badges. Flat. Unassuming. Cold."])
	walk_officer(off)
	await s.say("instructor", ["This badge is your interface.", "Touching it establishes contact with your assigned Protektor.", "You will not remove it once issued."])
	while is_instance_valid(off) and off.position.x < s.w.tile_center(Vector2i(8, 5)).x - 1:
		await s.wait(0.1)
	Sfx.play("badge", 1.0, -4.0)
	# Close-up: your name, etched into the metal.
	var c := Cinema.open()
	c.modulate.a = 0.0
	c.show_tex(Art.cine("badge_bg"), 0.0)
	var bs := c.sprite(Art.cine("badge", 0), Vector2(160, 104), 1.0)
	# the etched name rides on the badge's nameplate
	var nm := Art.shadow_label(Game.player_name.to_upper(), Pal.FROST)
	nm.position = Vector2(-Art.text_width(nm.text) / 2.0, 8)
	bs.add_child(nm)
	await c.create_tween().tween_property(c, "modulate:a", 1.0, 0.4).finished
	await s.say("", ["The badge stops in front of you.", "Your name is etched into the surface."])
	await s.say("instructor", ["When instructed, place your thumb on the badge.", "Maintain contact."])
	Sfx.stop_music(0.3)
	await s.wait(0.6)
	await s.say("instructor", "Now.")
	Sfx.play("gasp", 1.0, -2.0)
	bs.texture = Art.cine("badge", 1)
	Sfx.play("sync", 0.8, -4.0)
	await m.flash(Pal.SYNC, 0.3, 0.9)
	nm.queue_free()
	Sfx.music("claustrophobia_1", 0.4)
	c.clear_sprites()
	c.show_tex(null, 0.0)
	c.effect = "warp"
	c.effect_k = 1.0
	c.set_vignette(0.75, 0.0)
	Sfx.play("warp", 1.0, -2.0)
	m.shake(2.0, 2.0)
	await s.say("", ["The instant your skin touches the badge, everything rushes forward.", "Light stretches. Colors tear past you. Blue. Gold. White."])
	await s.say("you", "I can't breathe-", "shock")
	c.effect = "stars"
	c.effect_k = 0.2
	c.set_vignette(1.2, 1.5)
	await s.say("", "No body. No room. Just distance.")
	await s.say("system_far", ["Synchronization detected.", "Neural acceptance confirmed."])
	await s.say("", "The panic dissolves. Everything feels aligned.")
	var r := await s.ask("What hits you first?", ["This feels incredible.", "This shouldn't be this easy.", "I don't feel anything at all."])
	Game.vars.badge_reaction = ["wonder", "doubt", "numb"][r]
	await s.say("~", ["This feels incredible.", "This shouldn't be this easy.", "I don't feel anything at all."][r])
	Sfx.play("warp_hit", 1.0, -2.0)
	await m.flash(Pal.WHITE, 0.4, 1.0)
	c.queue_free()
	Sfx.music("low_sync_hum", 0.6)
	s.w.player.set_spec(Game.player_spec("academy"))
	for id in ["hiro", "pala", "midas"]:
		s.a(id).set_spec(Game.cast(id))
	s.w.player.emote("sync", 1.4)
	off.visible = false
	await s.say("instructor", ["Synchronization complete.", "Do not remove the badge."])
	await s.say("", ["The badge is warm now.", "Almost pulsing."])
	s.face("hiro", 2)
	s.emote("hiro", "!")
	await s.say("hiro", "That was wild.", "still_smiling")
	s.face("pala", 3)
	await s.say("pala", "It skipped the safety ramp...", "anxious")
	s.face("midas", 3)
	s.mood("midas", "shock")
	await s.say("midas", "I thought I was gone.", "uneasy")
	await s.say("", "They move you along. No explanations. No questions.")
	await s.say("~", "Why does it already feel permanent?")
	Sfx.stop_music(1.0)
	await m.fade_out(1.0)
	await pods()


func walk_officer(off) -> void:
	for x in range(3, 17):
		if x == 10:
			continue
		if not is_instance_valid(off) or not off.visible:
			return
		await off.walk_to([s.w.tile_center(Vector2i(x, 5))], 26.0)
		if not is_instance_valid(off):
			return
		off.face(0)
		Sfx.play("tick", 1.0, -16.0)
		if x == 8:
			await s.wait(6.0)
		await s.wait(0.25)


# ---------------------------------------------------- 1.3 pairing pods ----

func pods() -> void:
	var m = s.m
	phase = "pods"
	m.load_map(Maps.corridor(), Vector2i(2, 4), 2)
	s.w.busy = true
	Sfx.music("low_sync_hum", 1.0)
	await m.fade_in(0.6)
	s.w.show_area_name()
	await s.say("", "The line of recruits splits again, funneled toward narrow lifts sunk beneath the badge hall.")
	var doors := [Vector2i(5, 2), Vector2i(11, 2), Vector2i(11, 2), Vector2i(17, 2)]
	for i in 4:
		var act := s.a("rec%d" % i)
		var d: Vector2i = doors[i]
		var go := func() -> void:
			if await act.walk_to([s.w.tile_center(Vector2i(d.x, act.home_tile.y)), s.w.tile_center(d), s.w.tile_center(d) + Vector2(0, -12)], 40.0):
				Sfx.play("door", 1.2, -12.0)
				act.visible = false
		go.call()
	for i in 5:
		Sfx.play("step", 0.9, -12.0)
		await s.wait(0.25)
	await s.say("", "Every footstep echoes. Every badge pulses in the same slow rhythm.")
	await s.say("instructor", ["You will enter the pairing pods in groups of four.", "Follow the badge prompt. Do not remove it. Do not delay."])
	s.w.show_marker(Vector2i(26, 3))
	s.w.busy = false


func trigger(id: String) -> void:
	if id == "pod":
		await _pod()


func _pod() -> void:
	var m = s.m
	s.w.hide_marker()
	await s.w.player.walk_to([s.w.tile_center(Vector2i(26, 3)) + Vector2(0, 4)], 40.0)
	s.w.player.face(0)
	Sfx.play("door", 0.8, -4.0)
	await s.say("", ["The pod is a circle carved out of light. No chair. Just an outline on the floor.", "You step in. The badge thrums against your skin."])
	Sfx.play("gasp", 1.0, -2.0)
	var c := Cinema.open(Color(0, 0, 0, 0))
	c.set_vignette(1.3, 0.0)
	await c.set_vignette(0.35, 0.6)
	c.back.color = Pal.INK
	c.set_vignette(1.3, 0.0)
	Sfx.music("claustrophobia_1", 0.5)
	c.effect = "pulse"
	await s.say("system_close", "Neural interface detected. Protektor link pending.")
	await s.say("", "The voice vibrates inside your chest instead of your ears.")
	var r := await s.ask("How do you answer the presence?", ["Reach toward it.", "Ask who it is.", "Hold your breath and wait."])
	match r:
		0:
			Game.vars.link_reaction = "curious"
			await s.say("you", "I'm here. Can you hear me?")
			await s.say("system_close", "Signal received. Alignment accelerating.")
		1:
			Game.vars.link_reaction = "question"
			await s.say("you", "Who are you supposed to be?")
			await s.say("system_close", "Designation: Protektor shell Delta-13. Purpose: defend.")
		_:
			Game.vars.link_reaction = "guarded"
			await s.say("", "You lock your jaw and say nothing. The badge hum rises anyway.")
			await s.say("system_close", "Lack of response noted. Proceeding.")
	Sfx.music("low_sync_hum", 0.6)
	await s.say("system_close", "Link confirmed. Shared channel stabilized.")
	c.effect = ""
	c.show_bg("horizon", 0, 0.8)
	await s.say("", "Images flash through your head: mountains wrapped in shield light, orbiting debris frozen mid-air.")
	await c.close(0.6)
	s.face("hiro", 3)
	s.emote("hiro", "heart")
	await s.say("hiro", "Mine said hi back!", "still_smiling")
	s.emote("pala", "!")
	await s.say("pala", "It shouldn't be talking this soon...", "anxious")
	await s.say("midas", "Just breathe. It's part of the test.", "uneasy")
	await s.say("system_close", "Candidate, remain ready. Deployment briefing follows.")
	await s.say("", "The badge cools, but the presence stays. You sense expectation, like holding your breath forever.")
	Sfx.stop_music(1.0)
	await m.fade_out(1.0)
	await briefing()


# ---------------------------------------------------------- 2.1 briefing --

func briefing() -> void:
	var m = s.m
	s.save_at("briefing")
	m.load_map(Maps.briefing(), Vector2i(5, 10), 1)
	s.w.player.set_pose("sit")
	s.w.busy = true
	s.w.prop_sprite("holo_planet").visible = false
	s.w.cam_follow = false
	s.w.cam_focus = s.w.tile_center(Vector2i(9, 6))
	s.w.cam.position = s.w.cam_focus
	Sfx.music("low_mechanical_ambient", 1.0)
	await m.fade_in(0.8)
	s.w.show_area_name()
	await s.say("", ["The briefing hall is larger than the classrooms.", "And emptier. Rows of seats face a single curved screen."])
	await s.say("~", "Why does it feel like we're early...")
	await s.say("", "Recruits sit where they're told. The spacing is intentional.")
	await s.say("hiro", "Guess this is it. The real stuff.", "still_smiling")
	Sfx.play("beep", 0.8, -4.0)
	var hp := s.w.prop_sprite("holo_planet")
	hp.visible = true
	hp.scale = Vector2(0.1, 0.1)
	await hp.create_tween().tween_property(hp, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).finished
	var marks: Array = []
	for k in 4:
		var mk := Sprite2D.new()
		mk.texture = Art.ui("emote_!")
		var a := k * TAU / 4.0 + 0.6
		mk.position = hp.position + Vector2(cos(a), sin(a)) * 22
		mk.z_index = 6
		s.w.add_child(mk)
		marks.append(mk)
		var tw := mk.create_tween().set_loops()
		tw.tween_property(mk, "modulate:a", 0.2, 0.3)
		tw.tween_property(mk, "modulate:a", 1.0, 0.3)
	await s.say("", "A planet appears on the display. Blue. Familiar. Threat markers blink at the edges.")
	await s.say("instructor", ["This is Terra Virex. Baseline colony world.", "You have completed orientation. You are now eligible for deployment.",
		"This is not combat. This is defense.", "Each mission consists of multiple threat waves. Your Protektor remains stationary."])
	await s.say("pala", "How long does a deployment last?", "anxious")
	await s.say("instructor", "Until the threat is neutralized.")
	await s.say("midas", "Is anyone down there hurt?", "uneasy")
	await s.say("instructor", "Civilian casualties are statistically minimal.")
	var r := await s.ask("What do you ask?", ["What happens if we fail?", "How often do missions occur?", "(Stay silent)"])
	match r:
		0:
			Game.vars.briefing_question = "fail"
			await s.say("you", "What happens if we fail?", "worried")
			await s.say("instructor", "Your first mission will be supervised. Performance will be monitored.")
		1:
			Game.vars.briefing_question = "frequency"
			await s.say("you", "How often do missions occur?")
			await s.say("instructor", "As often as needed. Readiness is not optional.")
		_:
			Game.vars.briefing_question = "silent"
			await s.say("", "You keep the question to yourself and watch the threat markers orbit the colony.")
	await s.say("instructor", "Prepare for deployment.")
	s.w.player.emote("sync")
	await s.say("", "Your badge warms, like it's already listening.")
	await s.say("~", "They didn't say if. They said when.")
	for mk in marks:
		mk.queue_free()
	await m.fade_out(0.8)
	await waiting()


# --------------------------------------------------------- 2.2 the wait ---

func waiting() -> void:
	var m = s.m
	m.load_map(Maps.waiting(), Vector2i(5, 5), 1)
	s.w.busy = true
	Sfx.music("low_mechanical_ambient", 1.0)
	await m.fade_in(0.8)
	s.w.show_area_name()
	await s.say("", ["They don't take you straight to deployment.", "They make you wait."])
	await s.say("", "The room is small. No windows. No screens. Just benches along the walls.")
	await s.say("~", "Like a doctor's office.")
	await s.say("", "Except no one tells you what they're checking for.")
	Sfx.music("low_sync_hum", 1.0)
	await s.say("", "Minutes pass. Or maybe seconds.")
	await s.say("~", "Time feels different.")
	s.w.player.emote("sync")
	await s.say("", "Your badge is warm again. Warmer than before.")
	var hiro := s.a("hiro")
	var pace := func() -> void:
		for i in 3:
			if not is_instance_valid(hiro):
				return
			await hiro.walk_to([s.w.tile_center(Vector2i(7, 4)), s.w.tile_center(Vector2i(9, 4))], 30.0)
	pace.call()
	await s.say("hiro", "I hate this part. Waiting. I'd rather just start.", "")
	s.mood("pala", "closed")
	await s.say("pala", ["Waiting makes things louder. Inside your head.", "Try counting your breaths."], "smile")
	s.a("midas").shake(0.3, 1.0)
	await s.say("midas", ["Do you think they tell families before or after?", "Never mind."], "uneasy")
	Sfx.play("chime", 0.8, -6.0)
	await s.say("system", "Deployment window approaching. Stand by.")
	Sfx.play("heartbeat", 0.9, -4.0)
	await s.say("", "Your heart rate slows. You didn't tell it to.")
	await s.say("~", "Why am I not panicking?")
	var r := await s.ask("What do you do while you wait?", ["Close your eyes", "Watch the door", "Focus on the badge"])
	match r:
		0:
			Game.vars.pre_mission_focus = "eyes_closed"
			s.w.player.set_mood("closed")
			await s.say("", "You close your eyes and count breaths until the numbers stop meaning anything.")
			s.w.player.set_mood("")
		1:
			Game.vars.pre_mission_focus = "door"
			s.w.player.face(1)
			await s.say("", "You keep your eyes on the sealed door and wait for it to prove this is still a normal room.")
		_:
			Game.vars.pre_mission_focus = "badge"
			s.w.player.emote("sync")
			await s.say("", "You stare at the badge until the metal seems to pulse in time with something that isn't your heart.")
	Sfx.play("heavy_door", 1.0, -2.0)
	m.shake(1.5, 0.5)
	s.place("instructor", Vector2i(5, 2), 0)
	s.w.add_npc({"id": "instructor", "who": "instructor", "tile": Vector2i(5, 2), "dir": 0})
	await s.say("instructor", "Deployment in ten seconds.")
	await s.say("", "No countdown. No one says good luck.")
	s.face("hiro", 0)
	await s.say("hiro", "Here we go.", "still_smiling")
	await s.say("pala", "Remember to breathe.", "anxious")
	await s.say("midas", "I hope she's not watching the sky right now.", "uneasy")
	await s.say("~", ["I don't feel scared.", "I think that scares me."])
	Sfx.stop_music(1.0)
	await m.fade_out(0.8)
	await deploy_first()


# -------------------------------------------- 2.3 first mission: Terra Virex --

func deploy_first() -> void:
	var m = s.m
	var c := Cinema.open()
	await m.fade_in(0.3)
	await s.say("", ["There is no countdown.", "No one tells you to get ready."])
	Sfx.play("badge", 1.0, -2.0)
	await s.say("", "Your badge pulses once. Sharp. Insistent.")
	await s.say("~", "Now.")
	Sfx.play("gasp", 1.0, -2.0)
	await m.flash(Pal.WHITE, 0.3, 1.0)
	c.set_vignette(1.2, 0.0)
	c.set_vignette(0.5, 1.2)
	c.effect = "warp"
	c.effect_k = 0.7
	Sfx.play("warp", 0.9, -4.0)
	await s.say("", ["The moment your skin makes contact, you lose your breath.", "Your vision collapses inward. Dark at the edges. Light rushing forward.",
		"Your eyes roll back. Not in pain. In surrender."])
	c.effect_k = 1.4
	await s.say("", ["Stars stretch.", "Colors tear past you. Blue. Gold. White."])
	c.effect = ""
	c.particles.clear()
	c.set_vignette(1.3, 0.3)
	Sfx.play("warp_hit", 0.7, -6.0)
	var big := c.sprite(Art.planet("green_planet", 150, 0), Vector2(160, 100))
	await s.say("", ["Everything stops.", "A planet fills your vision.", "Terra Virex. Whole. Fragile."])
	await s.say("~", "I am it.")
	if m.world:
		m.world.visible = false
	var res: Dictionary = await m.start_mission("terra_virex_level_01", false, true, c)
	await aftermath(res)


# ------------------------------------------------------- 2.4 the aftermath --

func aftermath(res: Dictionary) -> void:
	var m = s.m
	var won: bool = res.get("result", "") == "win"
	m.load_map(Maps.recovery(), Vector2i(7, 5), 0)
	s.w.busy = true
	Sfx.music("low_sync_hum", 1.0)
	s.w.tint.color = Color(1.6, 1.6, 1.6)
	await m.fade_in(0.8)
	await s.w.set_tint(Color(1.0, 1.0, 1.02), 1.0)
	await s.say("", ["The stars don't fade out.", "They simply stop being there."])
	Sfx.play("gasp", 1.2, -4.0)
	s.w.player.emote("!")
	await s.say("", "Your breath comes back all at once.")
	await s.say("you", "(gasp)", "shock")
	await s.say("", ["Gravity returns. Your feet are on the floor again.", "You're standing in a different room. Smaller than the briefing hall. Brighter than the dormitory."])
	await s.say("~", "I didn't walk.")
	await s.say("", "Your badge is cool now. Cold, actually.")
	await s.say("~", "That's new.")
	await s.say("", "For a moment, you miss the warmth.")
	await s.say("~", "Why would I miss that?")
	if won:
		await s.say("system", "Mission complete. Threats neutralized. Planetary integrity maintained. Synchronization increased.")
	else:
		await s.say("system", "Deployment terminated. Planetary integrity compromised. Recovery initiated. Synchronization increased.")
	var hiro := s.a("hiro")
	var pacing := [true]
	var pace := func() -> void:
		while pacing[0] and is_instance_valid(hiro):
			await hiro.walk_to([s.w.tile_center(Vector2i(5, 6)), s.w.tile_center(Vector2i(2, 6))], 34.0)
	pace.call()
	await s.say("", "Hiro is pacing.")
	await s.say("hiro", ["Did you feel that turn near the end?", "I barely had to think."], "still_smiling")
	await s.say("", "Pala is sitting, eyes closed.")
	await s.say("pala", ["My hands are still shaking.", "I don't remember moving them."], "closed")
	await s.say("", "Midas leans against the wall.")
	await s.say("midas", ["I kept thinking about the people down there.", "Even when the rocks stopped coming."], "uneasy")
	pacing[0] = false
	Sfx.play("door", 1.0, -6.0)
	s.w.add_npc({"id": "instructor", "who": "instructor", "tile": Vector2i(7, 7), "dir": 1})
	await s.say("instructor", ["Good work.", "Recovery time will be brief. Your next assignment will be scheduled shortly."])
	s.w.player.position = s.w.tile_center(Vector2i(7, 5)) + Vector2(8, 0)
	Sfx.play("beep", 1.2, -6.0)
	await s.say("", "Lights scan across you.")
	await s.say("instructor", ["Synchronization increase is within acceptable parameters.", "Side effects are normal."])
	await s.say("~", "Side effects.")
	await s.say("", "When you close your eyes, you can still feel the planet.")
	await s.say("~", "I know where it is.")
	var r := await s.ask("What stays with you?", ["That felt right.", "I didn't like how easy it was.", "I wish it hadn't ended."])
	Game.vars.aftermath_response = ["right", "easy", "ended"][r]
	await s.say("you", ["That felt right.", "I didn't like how easy it was.", "I wish it hadn't ended."][r])
	await s.say("", "You're guided back into the hall. No applause. Just the sense that something has shifted.")
	await s.say("~", "It wasn't combat. It was practice.")
	await m.fade_out(0.8)
	await s.hub.enter(res)


# ------------------------------------------------------------- field ------

func talk(n: Actor) -> void:
	var id: String = n.info.get("id", "")
	match id:
		"instructor":
			await s.say("instructor", "Proceed to your pod, recruit. Do not delay.")
		"hiro":
			await s.say("hiro", "Hurry up! I want to know what mine sounds like.", "still_smiling")
		"pala":
			await s.say("pala", "Group of four. Four pods. And no one asked us which one we wanted.", "anxious")
		"midas":
			await s.say("midas", "If I close my eyes, it's almost like the lift at home.", "uneasy")
		_:
			await s.say("", "\"Keep moving. They're timing us.\"")


func examine(ev: Dictionary) -> void:
	await s.say("", "Nothing here explains itself.")
