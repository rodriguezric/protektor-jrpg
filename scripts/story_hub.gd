class_name StoryHub
extends RefCounted
## Chapter 2's loop: after every deployment you walk the Pilot Commons and choose
## who to spend the interval with (scene_2_5), then report to the deployment
## terminal (scene_2_6). Relationships, unlocks, Midas and the endings follow
## Protektor's MissionProgress rules exactly.

var s: Story
var used := false
var last_res := {}


func _init(p_s: Story) -> void:
	s = p_s


func enter(res: Dictionary) -> void:
	var m = s.m
	last_res = res
	var resumed := res.is_empty() and int(Game.story.get("interval_count", 0)) > 0
	if resumed:
		used = bool(Game.story.get("interval_used", false))
	else:
		used = false
		Game.story.interval_used = false
		Game.story.interval_count = int(Game.story.get("interval_count", 0)) + 1
	s.save_at("hub")
	if Game.has_failure_ending() or Game.all_levels_done():
		m.load_map(_map(), Vector2i(12, 12), 1)
		await m.fade_in(0.6)
		await s.endings.play(Game.automatic_ending_type())
		return
	m.load_map(_map(), Vector2i(12, 12), 1)
	s.w.busy = true
	await m.fade_in(0.8)
	s.w.show_area_name()
	var r := str(res.get("result", ""))
	if r == "lose" or r == "retreat":
		await s.say("system", ["Deployment failed. Recovery protocol complete.", "Failed deployments are recorded. Readiness is not optional."])
		if Game.use_medicine():
			s.w.player.emote("sync")
			await s.say("", "You take a Neural Stabilizer. The cold settles. The failure is cleared from your record.")
	elif r == "win" and int(res.get("credits", 0)) > 0 and int(Game.story.interval_count) <= 2:
		await s.say("system", "Deployment credits issued. Engineering will accept them at the terminal by the lockers.")
	if int(Game.story.interval_count) == 1:
		await s.say("", ["They don't send you back to the dorms right away.", "There's time.", "Not much. But enough."])
	if Game.midas_dead() and not bool(Game.story.midas_death_announced):
		await _midas_announcement()
	if used:
		await s.say("system", "Report to the deployment terminal.")
		s.w.show_marker(Vector2i(14, 9))
	else:
		await s.say("system", "Post-mission interval available. One interaction recommended.")
	s.w.busy = false


func _map() -> Dictionary:
	var mp := Maps.commons()
	var npcs := []
	var hr := Game.relationship("hiro")
	if hr >= 2:
		npcs.append({"who": "hiro", "tile": Vector2i(3, 4), "dir": 1, "no_turn": hr >= 3, "turn_back": true})
	else:
		npcs.append({"who": "hiro", "tile": Vector2i(5, 3), "dir": 3, "mood": "smile" if hr == 0 else ""})
	if not bool(Game.story.pala_unavailable) and not bool(Game.story.pala_escape_chosen):
		npcs.append({"who": "pala", "tile": Vector2i(22, 4), "dir": 1})
	if not Game.midas_dead():
		npcs.append({"who": "midas", "tile": Vector2i(13, 2), "dir": 1, "mood": "sad"})
	else:
		mp.props.append(Maps.p("memorial", 13, 2, {"event": {"id": "memorial"}, "light": Pal.LEMON, "lr": 12, "light_off": Vector2(0, -6), "pulse": 7.0}))
	var extra_n := clampi(5 - Game.completed_count() / 3, 1, 5)
	var spots := [Vector2i(16, 6), Vector2i(8, 10), Vector2i(19, 9), Vector2i(3, 9), Vector2i(24, 11)]
	for i in extra_n:
		npcs.append({"id": "rec%d" % i, "spec": Data.EXTRAS[(i * 3 + 1) % Data.EXTRAS.size()], "tile": spots[i], "dir": i % 4, "wander": i % 2 == 0, "range": 2.0})
	npcs.append({"id": "bot", "bot": true, "tile": Vector2i(15, 7), "dir": 0, "wander": true, "range": 4.0})
	mp.npcs = npcs
	# The roster: names get struck as pilots "transfer".
	for p in mp.props:
		if p.get("id", "") == "board":
			p.v = mini(12, Game.completed_count() / 2 + (2 if Game.midas_dead() else 0))
	return mp


# --------------------------------------------------------------- talking ---

func talk(n: Actor) -> void:
	var id: String = n.info.get("who", n.info.get("id", ""))
	match id:
		"hiro":
			if used:
				await s.say("hiro", "..." if Game.relationship("hiro") >= 3 else "Not now. I'm running the next deployment in my head.", "")
				return
			await _hiro()
			await _close("hiro")
		"pala":
			if used:
				await s.say("pala", "Later. The archive logs are being watched right now.", "anxious")
				return
			await _pala()
			await _close("pala")
		"midas":
			if used:
				await s.say("midas", "I'm okay. Go. They'll call us soon.", "uneasy")
				return
			await _midas()
			await _close("midas")
		"bot":
			Sfx.play("beep", 1.4, -8.0)
			n.emote("...")
			await s.say("", "A maintenance unit polishes the same panel of floor. It has been polishing it since you arrived.")
		_:
			var lines := [
				["Did you see the leaderboard? Nobody's beaten Hiro's turn speed.", "I sleep better after a deployment. Is that weird?"],
				["My roommate transferred. That's what they said. Transferred.", "The food's better than at home. That's something."],
				["You're from the same intake as Midas, right? He's nice.", "Don't sit in the sim pods too long. You get... sticky."],
				["I counted. There are fewer of us at dinner every week.", "They say we're the best intake in years."],
				["I don't remember my sister's voice anymore. I mean, I do. I just can't hear it.", "Synchronization's at forty for me. Is that good?"],
			]
			var idx := int(str(n.info.get("id", "rec0")).trim_prefix("rec")) % lines.size()
			var ln: Array = lines[idx]
			await s.say("", "\"%s\"" % ln[Game.completed_count() % ln.size()])


func _close(choice: String) -> void:
	if Game.story.get("story_ending_requested", false):
		await s.endings.play(Game.ending_type())
		return
	used = true
	Game.story.interval_used = true
	Game.save()
	await s.say("", ["The interval ends.", "Whatever you chose, it stays with you."])
	Sfx.music("low_mechanical_ambient", 1.5)
	Sfx.play("chime", 1.0, -6.0)
	await s.say("system", "Report to the deployment terminal.")
	s.w.show_marker(Vector2i(14, 9))


func _record(choice: String, response: String) -> void:
	Game.record_conversation(choice, response)


# ------------------------------------------------------------------ Hiro ---

func _hiro() -> void:
	Sfx.music("hiro_theme", 1.0)
	var r := Game.relationship("hiro")
	var resp := ""
	var act := s.a("hiro")
	if r == 0:
		act.hop()
		await s.say("hiro", ["You felt it, right? The flow. That turn near the end was perfect.", "I didn't even think. I was already facing it. Tell me that wasn't incredible."], "still_smiling")
		var c := await s.ask("How do you answer?", ["Race me.", "Slow down."])
		if c == 0:
			resp = "compete"
			act.emote("note")
			await s.say("hiro", "You're on. Next deployment, first one to clear their side wins.", "still_smiling")
		else:
			resp = "caution"
			await s.say("hiro", "Slow is what instructors say when they can't keep up. I'm kidding. Mostly.", "smile")
		await s.say("hiro", ["The Protektor catches every impulse before I even know I had it.", "Next time, I'm going faster. Cleaner. Try not to blink."], "smile")
	elif r == 1:
		await s.say("hiro", ["When they disconnect me now, the room feels late. Like everything needs permission to move.", "The instructors call it synchronization. When I'm linked, nothing in me hesitates."], "")
		if not Game.is_planet_unlocked("umbra_vacua"):
			await s.say("hiro", "I found a sealed deployment vector while I was linked. Umbra Vacua. Command doesn't think we're ready for it.", "")
			var u := await s.ask("Ask Hiro to open the route?", ["Send me the coordinates.", "Leave it sealed."])
			if u == 0:
				Game.unlock_planet("umbra_vacua")
				Sfx.play("chime", 0.8, -4.0)
				act.emote("sync")
				await s.say("hiro", "Done. Umbra Vacua is on your mission map now. Try to keep up.", "smile")
			else:
				await s.say("hiro", "Your loss. The route will still be there when you stop hesitating.", "flat")
		var c := await s.ask("What do you tell him?", ["I feel it.", "That worries me."])
		if c == 0:
			resp = "share_rush"
			await s.say("hiro", "Then you know. Out there, we're the fastest thought we've ever had.", "smile")
		else:
			resp = "warn_addiction"
			await s.say("hiro", "You sound like Pala. Worry is just hesitation wearing a serious face.", "flat")
		await s.say("hiro", ["I catch myself counting the hours until they call us again.", "Waiting used to make me bored. Now it feels like being held underwater."], "")
	elif r == 2:
		await s.say("hiro", ["I stopped dreaming about anything else. Now I only dream about the next deployment.", "Sleep, food, jokes... they all feel like things designed to fill the time between missions."], "flat")
		var c := await s.ask("How do you respond?", ["You've changed.", "Take a break."])
		if c == 0:
			resp = "notice_change"
			await s.say("hiro", "I've improved. People call improvement a change when it makes them uncomfortable.", "flat")
		else:
			resp = "suggest_rest"
			await s.say("hiro", "Rest dulls the connection. I won't waste readiness pretending to recover.", "flat")
		await s.say("", "He says it without a grin. His eyes remain fixed somewhere beyond the wall.")
		await s.say("hiro", "That should scare me, probably. It doesn't.", "flat")
	else:
		act.face(1)
		await s.say("hiro", ["They increased my synchronization limit. I don't feel the release anymore when they disconnect me.", "The targeting geometry stays with me. My body is the part that disconnects."], "hollow")
		var c := await s.ask("What do you say?", ["Come back, Hiro.", "Teach me."])
		if c == 0:
			resp = "call_back"
			await s.say("hiro", "Back to what? Noise? Delay? Hiro is here. He is simply no longer divided.", "hollow")
		else:
			resp = "follow_power"
			await s.say("hiro", "Stop correcting the first impulse. The Protektor is faster than the name you give it.", "hollow")
		await s.say("", "His face does not change. The bright impatience you remember has emptied from his eyes.")
		await s.say("hiro", "You look worried. Concern is wasted processing. Soon you won't feel it either.", "hollow")
	_record("hiro", resp)
	act.set_spec(Game.cast("hiro"))


# ------------------------------------------------------------------ Pala ---

func _pala() -> void:
	Sfx.music("pala_conversation", 1.0)
	var r := Game.relationship("pala")
	var resp := ""
	var act := s.a("pala")
	if Game.midas_dead() and r >= 1 and not Game.is_planet_unlocked("mechanon_ascens"):
		await s.say("pala", ["I found the deployment record they buried after Midas died.", "He was protecting Mechanon Ascens. Command erased the planet from our maps, but I restored his coordinates."], "sad")
		Game.unlock_planet("mechanon_ascens")
		Sfx.play("chime", 0.7, -4.0)
		await s.say("pala", "Mechanon Ascens is accessible now. We won't let what he protected disappear with him.", "")
	if r == 0:
		await s.say("pala", ["It takes a minute to come back. From being everywhere.", "Everyone pretends the silence afterward is peaceful. I think they're afraid to admit how empty it feels."], "anxious")
		var c := await s.ask("How did the silence feel to you?", ["Like relief.", "Something was missing."])
		if c == 0:
			resp = "relief"
			await s.say("pala", "Relief isn't wrong. Just notice if it becomes the only place you feel safe.", "")
		else:
			resp = "missing"
			await s.say("pala", "Me too. For a few seconds, I couldn't remember what my own thoughts sounded like.", "sad")
		await s.say("pala", ["The badge wants us to call that feeling progress.", "Keep listening for the noise inside you. It may be the part they can't control."], "smile")
	elif r == 1:
		await s.say("pala", ["I found gaps in the recovery logs. Pilots disappear from the schedule, but nobody records where they went.", "There are names one day and empty identification numbers the next."], "anxious")
		var c := await s.ask("How do you answer her?", ["Show me.", "Too dangerous."])
		if c == 0:
			resp = "trust"
			act.emote("heart")
			await s.say("pala", "I hoped you'd say that. I don't want to carry this alone.", "smile")
		else:
			resp = "caution"
			await s.say("pala", "It is. But pretending we didn't see it feels more dangerous.", "sad")
		await s.say("pala", ["Every missing pilot crossed the same synchronization range.", "I copied the records before the system could notice. Next time, I'll show you the pattern."], "")
	elif r == 2:
		await s.say("pala", ["The missing pilots didn't transfer. Their medical files end at the same synchronization threshold.", "Helion knows what happens after that point. They're hiding it from us."], "angry")
		var c := await s.ask("What should you do with the evidence?", ["Find a way out.", "Confront them."])
		if c == 0:
			resp = "escape"
			await s.say("pala", "I've been mapping one. I needed to know you might actually come with me.", "smile")
		else:
			resp = "confront"
			await s.say("pala", "They control every door and every message. Evidence won't protect us here.", "sad")
		await s.say("pala", ["There is an unmonitored service route beneath the launch wing.", "Give me one more interval. I'll find out when the route is clear."], "")
	else:
		await s.say("pala", ["The service route is open tonight. A supply shuttle leaves before the next deployment.", "If we reach it, Helion won't be able to follow without admitting what they did.",
			"I'm leaving now. I want you beside me, but I need you to choose."], "")
		var c := await s.ask("Will you escape with Pala?", ["Leave together.", "Stay behind."])
		if c == 0:
			resp = "leave_with_pala"
			Game.story.pala_escape_chosen = true
			Game.story.story_ending_requested = true
			act.emote("heart")
			await s.say("pala", "Then stay close. Whatever waits outside, we'll face it as ourselves.", "smile")
		else:
			resp = "stay"
			Game.story.pala_unavailable = true
			Game.story.story_ending_requested = true
			await s.say("pala", "I understand. I won't ask again. Goodbye.", "sad")
		Sfx.stop_music(0.8)
	_record("pala", resp)


# ----------------------------------------------------------------- Midas ---

func _midas() -> void:
	Sfx.music("midas_theme", 1.0)
	var r := Game.relationship("midas")
	var resp := ""
	var act := s.a("midas")
	act.face_toward(s.w.player.position)
	if r == 0:
		await s.say("midas", ["I found something in the terminal rules. Once someone here vouches for you, they'll permit outgoing calls home.", "They don't advertise it. The request only needs another pilot's authorization."], "uneasy")
		var c := await s.ask("How do you respond?", ["Why help me?", "Thank you."])
		if c == 0:
			resp = "why_help"
			await s.say("midas", "Because everyone should hear a familiar voice after being out there.", "smile")
		else:
			resp = "thanks"
			await s.say("midas", "Don't thank me yet. Just promise you'll use it.", "smile")
		await s.say("midas", ["I'll put my name on your request before the interval ends.", "Talk to your family while you still can. Home feels farther away after every mission."], "sad")
		Sfx.play("beep", 1.1, -6.0)
		s.w.prop_sprite("comm").modulate = Color(1.4, 1.6, 1.4)
	else:
		await s.say("midas", ["I miss home so much it hurts. I keep seeing my mother's kitchen every time I close my eyes.", "Do you want to hear a kind of funny memory about my mother?"], "sad")
		var c := await s.ask("Do you want to hear it?", ["Tell me.", "Not now."])
		if c == 0:
			resp = "hear_memory"
			var cin := Cinema.open(Color(0, 0, 0, 0))
			cin.modulate.a = 0.0
			cin.show_tex(Art.cine("kitchen"), 0.0)
			cin.effect = "embers"
			cin.effect_k = 0.4
			cin.create_tween().tween_property(cin, "modulate:a", 1.0, 1.2)
			await s.say("midas", ["My birthday had already passed. I thought that was it for another year.",
				"Then Mom came in the next morning holding a toy. She said she'd just discovered one she forgot to give me.",
				"The morning after that, she discovered another one. Then another the day after that.",
				"Eventually I figured out she had several toys hidden away. I asked her why she wouldn't just give me the rest.",
				"I remember her leaning against the kitchen doorway, trying not to smile. Her hair was still tied up from work, and she had flour on one cheek.",
				"She just shrugged and said, 'Birthdays end too quickly. I thought yours could have a few more mornings.'"], "smile")
			await s.say("midas", "I-I think maybe she knew that someday I would need to remember how much she-", "cry", {"auto": true, "auto_delay": 0.05})
			Sfx.play("static", 1.0, -4.0)
			Sfx.stop_music(0.0)
			cin.queue_free()
			s.m.flash(Pal.WHITE, 0.1, 0.5)
			await s.say("system", "Interaction window closed.")
			act.set_mood("cry")
		else:
			resp = "decline_memory"
			await s.say("midas", ["I understand. Sometimes hearing about someone else's home just makes your own feel farther away.",
				"I miss the little things most. Her humming, the chipped blue cup, the warm spot beside the stove.",
				"I don't want to be brave anymore. I just want to be there with her."], "sad")
	_record("midas", resp)


func _midas_announcement() -> void:
	Sfx.stop_music(0.0)
	await s.w.set_tint(Color(0.55, 0.6, 0.75), 0.8)
	await s.pan(Vector2i(13, 3), 0.8)
	await s.say("system", "We have some unfortunate news.")
	Sfx.music("midas_death", 1.0)
	await s.say("system", ["Pilot Midas has passed away.", "A medical review identified an undisclosed health issue.", "The condition was not present in the records available to his deployment team."])
	for i in 5:
		var act := s.a("rec%d" % i)
		if act:
			act.face(1)
			act.set_mood("sad")
	var c := await s.ask("What do you feel?", ["They're lying.", "This isn't real.", "I feel nothing."])
	match c:
		0:
			Game.story.midas_death_response = "anger"
			await s.say("you", "That's a lie. He was scared, and you kept sending him out.", "angry")
			await s.say("system", "The medical finding is final. Further speculation is discouraged.")
		1:
			Game.story.midas_death_response = "grief"
			await s.say("you", "No. I just talked to him. He wanted to go home.", "cry")
			await s.say("", "The system allows your words to disappear into the room.")
		_:
			Game.story.midas_death_response = "numb"
			await s.say("you", "I don't feel anything.", "flat")
			await s.say("", "That frightens you more than the announcement.")
	await s.say("system", ["His death was not related to his use of the Protektor.", "His family will be rewarded for his hard work and service."])
	Game.story.midas_death_announced = true
	Game.save()
	await s.pan_back(0.6)
	await s.w.set_tint(Maps.commons().tint, 1.0)
	Sfx.music("low_mechanical_ambient", 1.5)


# ------------------------------------------------------------------ home ---

func _home() -> void:
	Sfx.music("letter_discussion", 1.0)
	var h := Game.home_contacts()
	var resp := ""
	Sfx.play("beep", 1.0, -4.0)
	await s.say("system", "Outgoing message permitted.")
	Sfx.play("static", 1.0, -10.0)
	if h == 0:
		await s.say("parent", "Hello? We were told this channel might open, but they wouldn't tell us when.")
		await s.say("you", "It's me. I don't have long.")
		await s.say("parent", "We read every Academy letter twice. None of them sounded like you.")
		var c := await s.ask("What do you tell them?", ["I'm scared.", "Training is going well."])
		if c == 0:
			resp = "admit_fear"
			await s.say("you", "I'm scared. They send us out and act like being afraid means we aren't ready.", "sad")
			await s.say("parent", "Being afraid means you understand that you matter. Don't let them train that out of you.")
		else:
			resp = "reassure_home"
			await s.say("you", "Training is going well. I'm getting better every time.", "smile")
			await s.say("parent", "You never used to measure yourself that way. You don't have to protect us from the truth.")
		await s.say("parent", "Whatever they call you there, you are still our child. Call again. Please.")
	elif h == 1:
		await s.say("parent", "There you are. We've been waiting by the receiver every night.")
		await s.say("you", "I miss you. I don't know how long they let these calls last.", "sad")
		await s.say("parent", "Then don't waste it pretending you're fine. Tell us something real.")
		var c := await s.ask("What do you miss most?", ["The kitchen at night.", "Ordinary mornings."])
		if c == 0:
			resp = "miss_kitchen"
			await s.say("you", "The kitchen at night. The light over the stove and everyone talking when we should have been asleep.")
			await s.say("parent", "We leave that light on now. It makes the house feel like it's keeping your place.")
		else:
			resp = "miss_mornings"
			await s.say("you", "Ordinary mornings. Being late. Complaining about breakfast. Things that didn't matter until they were gone.")
			await s.say("parent", "They mattered because they were yours. There will be more of them when you come home.")
		await s.say("", "For a moment, the machinery around you sounds almost like the house settling after dark.")
	elif h == 2:
		await s.say("parent", "Your voice sounds different. Slower. Like you're choosing each feeling before you say it.")
		await s.say("you", "The missions make everything quiet afterward.", "flat")
		var c := await s.ask("How much do you explain?", ["Tell them about the Protektor.", "Don't frighten them."])
		if c == 0:
			resp = "explain_protektor"
			await s.say("you", "It knows what I'm going to do before I do. Sometimes I can't tell which thoughts started inside me.")
			await s.say("parent", "Then hold on to the thoughts it can't use. Your memories. Your name. The people who knew you before it did.")
		else:
			resp = "hide_protektor"
			await s.say("you", "It's only exhaustion. Everyone feels strange after a deployment.")
			await s.say("parent", "You pause before every answer now. Whatever is happening, you don't have to carry it alone.")
		await s.say("parent", "Listen to me. Whatever they promised us, you matter more than their program.")
	else:
		await s.say("parent", ["We found someone who can get us beyond Helion space. We can still bring you home.", "A maintenance transport crosses the Academy perimeter tonight. Say the word and we'll be waiting at the other end."])
		var c := await s.ask("Will you go home?", ["Come get me.", "I can't leave yet."])
		if c == 0:
			resp = "escape_home"
			Game.story.story_ending_requested = true
			await s.say("you", "Come get me. I want to go home.", "cry")
			await s.say("parent", "We're already on our way. Whatever they made you become, you won't face what comes next alone.")
			Sfx.stop_music(0.8)
		else:
			resp = "delay_escape"
			Game.story.home_unavailable = true
			await s.say("you", "I can't leave yet. There are people here I can't abandon.")
			await s.say("parent", ["Then help them if you can. But don't mistake surviving this place for owing it your life.", "The route won't stay open forever. Neither will we."])
	_record("home", resp)


# ---------------------------------------------------------------- examine --

func examine(ev: Dictionary) -> void:
	match ev.get("id", ""):
		"terminal":
			await _terminal()
		"comm":
			if used:
				await s.say("", "The comm booth's screen reads: LINE CLOSED UNTIL NEXT INTERVAL.")
			elif Game.relationship("midas") <= 0:
				await s.say("system", "Outgoing calls require another pilot's authorization.")
			elif bool(Game.story.home_unavailable):
				await s.say("", "The booth hums. The number for home returns nothing but a flat tone.")
			else:
				var c := await s.ask("Contact home?", ["Call home", "Not now"])
				if c == 0:
					await _home()
					await _close("home")
		"board":
			var n := mini(12, Game.completed_count() / 2 + (2 if Game.midas_dead() else 0))
			if n == 0:
				await s.say("", "PILOT ROSTER. Every name in this intake, in neat rows. Yours is near the middle.")
			else:
				await s.say("", ["PILOT ROSTER. %d of the names have a thin red line through them." % n, "Beside each line, one word: TRANSFERRED."])
				if Game.midas_dead():
					await s.say("", "Midas's name is one of them. The line through it is very straight.")
		"memorial":
			await s.say("", ["Someone left Midas's jacket folded on the floor by the window, with a paper cup and a ration-candle.", "Nobody admits to it."])
		"simpod":
			if Game.relationship("hiro") >= 2:
				await s.say("", "The sim pod is still warm. Hiro's handprint is on the glass, at the exact same height, again and again.")
			else:
				await s.say("", "TRAINING MODULES. Optional. Someone has underlined OPTIONAL twice.")
			var c := await s.ask("Run a training module? Clears pay a few credits.", ["Train", "Not now"], "system")
			if c == 0:
				await s.m.training()
		"workshop":
			await s.m.workshop()
		"vending":
			Sfx.play("beep", 1.3, -8.0)
			await s.say("", "NUTRITION PASTE, flavor: BLUE. The machine thanks you for your service.")
		"archive":
			await s.say("", "The archive console asks for clearance you don't have. Pala's fingerprints are all over the glass.")
		"locker":
			await s.say("", "Your locker. A drawing is taped inside the door. You don't remember putting it there, but it is yours.")
		"plant":
			await s.say("", "A plastic plant. Perfect. Dusty. Someone has been watering it anyway.")
		"spacewindow":
			if Game.midas_dead():
				await s.say("", "Stars. The window where Midas used to stand. It looks out at nothing in particular.")
			else:
				await s.say("", "Stars, slow and enormous. Somewhere out there, worlds are waiting to be defended.")
		"dorm":
			await s.say("", "The dormitory. Lights-out has not been called.")
		"exitdoor":
			await s.say("", "The door to the briefing halls. It only opens from the other side.")


func _terminal() -> void:
	var m = s.m
	if not used:
		var c := await s.ask("Deploy now? An interaction is still recommended.", ["Not yet", "Deploy"], "system")
		if c != 1:
			return
	s.w.hide_marker()
	var first := not bool(Game.story.get("terminal_seen", false))
	if first:
		await s.say("", ["The Academy doesn't announce the change.", "It just... happens."])
		Sfx.play("beep", 1.0, -4.0)
		await s.say("", ["A screen activates as you approach.", "It recognizes your badge immediately."])
		await s.say("system", ["Pilot recognized. Mission access granted.", "Active defense requests available. Select assignment.", "Unaddressed requests will be reassigned. Delays may increase risk."])
		await s.say("hiro", "High-density debris field. That'd be intense.", "still_smiling")
		if not bool(Game.story.pala_unavailable):
			await s.say("pala", "Some of them are blinking. That means we don't have all the information.", "anxious")
		if not Game.midas_dead():
			await s.say("midas", "I wish they told us how many people live on each one.", "uneasy")
		await s.say("", "The system does not respond.")
		Game.story.terminal_seen = true
	var pick: String = await m.starmap(false, first)
	if pick == "":
		Sfx.music("low_mechanical_ambient", 1.0)
		return
	var res: Dictionary = await deploy(pick)
	await enter(res)


func deploy(level_id: String) -> Dictionary:
	var m = s.m
	var c := Cinema.open()
	await m.fade_in(0.2)
	Sfx.play("badge", 1.0, -2.0)
	var lines := ["Your badge pulses. You touch it before anyone tells you to.", "The badge is warm before you even reach for it.", "Contact. Release. The room is gone.",
		"You don't hear the countdown anymore. You never needed it.", "Somewhere, a body stays behind in a chair."]
	await s.say("", lines[int(Game.story.get("deployments", 0)) % lines.size()])
	Sfx.play("gasp", 1.0, -6.0)
	c.effect = "warp"
	c.effect_k = 1.2
	c.set_vignette(0.6, 0.5)
	Sfx.play("warp", 1.1, -6.0)
	await s.wait(0.9)
	if m.world:
		m.world.visible = false
	return await m.start_mission(level_id, false, true, c)
