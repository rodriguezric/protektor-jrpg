class_name Story
extends Node
## The story director. Chapters (prologue, academy, hub, endings) live in their
## own scripts and share these helpers. Story is also the World's event handler
## and routes talk / examine / trigger / exit to whichever chapter owns the map.
## Dialogue follows Protektor's authored scenes (dialog/*.json and the scene
## scripts); the staging, walking and animation are new.

var prologue: StoryPrologue
var academy: StoryAcademy
var hub: StoryHub
var wing: StoryWing
var scenes: StoryScenes
var endings: StoryEndings


func _ready() -> void:
	prologue = StoryPrologue.new(self)
	academy = StoryAcademy.new(self)
	hub = StoryHub.new(self)
	wing = StoryWing.new(self)
	scenes = StoryScenes.new(self)
	endings = StoryEndings.new(self)


## How many talk / examine / trigger / exit interactions are running, and
## when story code last did something (a line, a walk, a pan, a wait). The
## field uses these to tell a real cutscene from a lock nobody will lift.
var active := 0
var last_activity := 0


func touch() -> void:
	last_activity = Time.get_ticks_msec()


var m: Node:
	get:
		return Game.main

var w: World:
	get:
		return Game.main.world


func begin(chapter: String) -> void:
	match chapter:
		"prologue":
			await prologue.start()
		"academy":
			await academy.orientation()
		"briefing":
			await academy.briefing()
		"hub":
			await hub.enter({})
		_:
			m.title()


# ------------------------------------------------------- world handlers ----

func _owner() -> Object:
	if w == null:
		return null
	match w.def.id:
		"home", "home_up", "parade", "block7":
			return prologue
		"commons", "ops":
			# the pilots, the terminal and the comm booth
			return hub
		"launch_wing":
			return endings
	if Building.is_building(str(w.def.id)):
		# the rest of the building: halls, dorms, rooms
		return wing
	return academy


func talk(n: Actor) -> void:
	var start := w.get_instance_id() if w else 0
	active += 1
	touch()
	var o := _owner()
	if o and o.has_method("talk"):
		await o.talk(n)
	else:
		await say("", "...")
	active = maxi(0, active - 1)
	touch()
	_release_if_moved(start)


func examine(ev: Dictionary) -> void:
	var start := w.get_instance_id() if w else 0
	active += 1
	touch()
	var o := _owner()
	if o and o.has_method("examine"):
		await o.examine(ev)
	active = maxi(0, active - 1)
	touch()
	_release_if_moved(start)


func trigger(id: String) -> void:
	var start := w.get_instance_id() if w else 0
	active += 1
	touch()
	var o := _owner()
	if o and o.has_method("trigger"):
		await o.trigger(id)
	active = maxi(0, active - 1)
	touch()
	_release_if_moved(start)


func _release_if_moved(start: int) -> void:
	## An interaction that loaded a new map ends here: the world it started on
	## (which locked control) is gone and can't unlock, so hand control back
	## on the map we ended up on. (Main.load_map keeps the new map locked
	## while the interaction is still running.)
	var now := w
	if now != null and is_instance_valid(now) and now.get_instance_id() != start and now.is_inside_tree():
		now.busy = false


func hub_minigame(kind: String) -> void:
	## The Pilot Wing's little games (HubGame). A decent result pays a few
	## credits, once per interval per game.
	var opp: Dictionary = {}
	match kind:
		"pingpong":
			await say("", ["A ping-pong table. The net sags in the middle.", "A recruit spins a paddle at you. \"One game. Loser cleans the paddles.\""])
			opp = Data.EXTRAS[2]
		"cards":
			await say("", ["A deck of cards with three missing; someone has drawn the missing ones by hand.", "\"High-low,\" says the recruit shuffling it. \"For ration chits.\""])
			opp = Data.EXTRAS[1]
		"drill":
			await say("system", ["SYNC-REFLEX DRILL. Respond to the indicated vector.", "Your results will be shared with your instructors."])
	if await ask("Play?", ["Play", "Not now"]) != 0:
		return
	var res: Dictionary = await m.hub_game(kind, opp)
	var sc := int(res.get("score", 0))
	var good := false
	match kind:
		"pingpong":
			good = sc >= 8
			if sc < 4:
				await say("", "\"Paddles are in the cupboard,\" they say. Not unkindly.")
			elif sc < 12:
				await say("", "\"Not bad. Again tomorrow.\"")
			else:
				await say("", "They stare at the ball, then at you. \"Where did THAT come from?\"")
		"cards":
			good = sc >= 5
			await say("", "\"%s\"" % ("Beginner's luck runs out." if sc < 3 else ("You're counting. Are you counting?" if sc < 7 else "Okay, nobody plays with you anymore.")))
		"drill":
			good = sc > 0 and sc <= 380
			if sc <= 0:
				await say("system", "Drill incomplete. Incomplete drills are recorded.")
			elif sc <= 300:
				await say("system", "Response latency exceptional. Synchronization readiness: elevated. Well done, pilot.")
				await say("", "It's the first time the system has said 'well done.' It doesn't feel like praise.")
			else:
				await say("system", "Response latency acceptable. Hesitation detected.")
	var played: Dictionary = Game.story.get("hub_game_paid", {})
	if good and int(played.get(kind, -1)) != int(Game.story.get("interval_count", 0)):
		played[kind] = int(Game.story.get("interval_count", 0))
		Game.story.hub_game_paid = played
		Game.add_credits(5)
		Sfx.play("coin", 1.0, -6.0)
		await say("", "You come away 5 credits richer.")


func exit(e: Dictionary) -> void:
	var start := w.get_instance_id() if w else 0
	active += 1
	touch()
	var o := _owner()
	if o and o.has_method("exit"):
		await o.exit(e)
	active = maxi(0, active - 1)
	touch()
	_release_if_moved(start)


# --------------------------------------------------------------- speakers ---

const MOOD := {"still_smiling": "smile", "anxious": "worried", "uneasy": "sad", "proud": "smile", "soft": "smile", "gentle": "smile",
	"guarded": "flat", "skeptical": "flat", "flat": "flat", "hesitant": "worried", "tired": "sad", "resigned": "sad",
	"firm": "angry", "stern": "angry", "pleading": "sad", "insistent": "worried", "reassuring": "smile"}


func speaker(who: String, mood: String = "") -> Array:
	## Returns [display name, dialog opts].
	mood = MOOD.get(mood, mood)
	match who:
		"":
			return ["", {"voice": "narrator"}]
		"~":
			return ["", {"voice": "child", "color": Pal.SKY.lerp(Pal.TEXT, 0.45)}]
		"you":
			return [Game.player_name, {"portrait": Game.player_spec(), "mood": mood, "side": "right", "voice": "child"}]
		"system", "system_far", "system_close":
			# machine voices (the academy system, the Protektor through the
			# badge) speak with no portrait: just a name and the text
			var nm: String = {"system": "System", "system_far": "System (distant)", "system_close": "System (close)"}[who]
			return [nm, {"sys": true, "voice": "system", "side": "left"}]
		"parent":
			return ["Parent", {"portrait": "comm", "voice": "woman", "side": "left"}]
		"voice":
			return ["Voice (distant)", {"portrait": "comm", "voice": "woman", "side": "left"}]
	var spec := Game.cast(who)
	var side := "left"
	return [spec.get("name", who.capitalize()), {"portrait": spec, "mood": mood, "side": side, "voice": spec.get("voice", "adult_flat")}]


func say(who: String, text, mood: String = "", extra: Dictionary = {}) -> void:
	var sp := speaker(who, mood)
	var opts: Dictionary = sp[1]
	opts.merge(extra, true)
	var lines: Array = text if text is Array else [text]
	if who == "~":
		lines = lines.map(func(l): return "(" + str(l) + ")")
	var actor := _actor_for(who)
	if actor and mood != "" and who != "you":
		actor.set_mood(MOOD.get(mood, mood))
	touch()
	await m.dialog.say(lines, sp[0], opts)
	touch()


func ask(question: String, options: Array, who: String = "", mood: String = "") -> int:
	var sp := speaker(who, mood)
	touch()
	var r: int = await m.dialog.ask(question, options, sp[0], sp[1])
	touch()
	return r


func _actor_for(who: String) -> Actor:
	if w == null or not is_instance_valid(w):
		return null
	return w.by_id.get(who, null)


# ------------------------------------------------------------ choreography --

func a(id: String) -> Actor:
	return w.actor(id)


func walk(id: String, tiles: Array, speed: float = 48.0) -> void:
	var act := a(id)
	if act == null:
		return
	var pts := []
	for t in tiles:
		pts.append(w.tile_center(t) if t is Vector2i else t)
	if not pts.is_empty():
		make_way(act, pts[-1])
	touch()
	await act.walk_to(pts, speed)
	touch()


func make_way(walker: Actor, dest: Vector2) -> void:
	## Anyone standing where a scripted walk will end steps aside to the
	## nearest free tile, so the walker doesn't stop on top of them.
	var everyone: Array = w.npcs.duplicate()
	everyone.append(w.player)
	for n: Actor in everyone:
		if n == walker or n == null or not n.visible or n.info.get("ghost", false):
			continue
		# on the spot, or close enough above/below that the sprites overlap
		if absf(n.position.x - dest.x) >= 12 or absf(n.position.y - dest.y) >= 20:
			continue
		var spot := _free_spot(n, dest, walker)
		if spot == Vector2.INF:
			continue
		n.walk_target = null
		if n != w.player:
			n.home_tile = Vector2i(floori(spot.x / 16.0), floori(spot.y / 16.0))
		var go := func() -> void:
			await n.walk_to([spot], 60.0)
			n.face_toward(dest)
		go.call()


func _free_spot(n: Actor, dest: Vector2, walker: Actor) -> Vector2:
	var here := Vector2i(floori(n.position.x / 16.0), floori((n.position.y - 3.0) / 16.0))
	var best := Vector2.INF
	var bd := 1e9
	for r in range(1, 4):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var t := here + Vector2i(dx, dy)
				var c: Vector2 = w.tile_center(t)
				if w.blocked_by_map(c) or ArtTiles.is_wall(w.char_at(t)) or c.distance_to(dest) < 24.0:
					continue
				var taken := false
				var others: Array = w.npcs.duplicate()
				others.append(w.player)
				for o: Actor in others:
					if o != n and o.visible and o.position.distance_to(c) < 14.0:
						taken = true
						break
				if taken:
					continue
				# straight moves first, and not back into the walker's way
				var d := c.distance_to(n.position) + (6.0 if dx != 0 and dy != 0 else 0.0)
				if c.distance_to(walker.position) < dest.distance_to(walker.position):
					d += 10.0
				if d < bd:
					bd = d
					best = c
		if best != Vector2.INF:
			return best
	return best


func walk_bg(id: String, tiles: Array, speed: float = 48.0) -> void:
	walk(id, tiles, speed)


func face(id: String, d: int) -> void:
	var act := a(id)
	if act:
		act.face(d)


func face_to(id: String, other: String) -> void:
	var act := a(id)
	var o := a(other)
	if act and o:
		act.face_toward(o.position)


func emote(id: String, kind: String, hold: float = 1.0) -> void:
	var act := a(id)
	if act:
		act.emote(kind, hold)


func mood(id: String, md: String) -> void:
	var act := a(id)
	if act:
		act.set_mood(md)


func pan(target, t: float = 0.7) -> void:
	var p: Vector2
	if target is Vector2i:
		p = w.tile_center(target)
	elif target is String:
		p = a(target).position
	else:
		p = target
	touch()
	await w.pan_to(p, t)
	touch()


func pan_back(t: float = 0.6) -> void:
	await w.pan_back(t)


func wait(t: float) -> void:
	touch()
	await m.get_tree().create_timer(t).timeout
	touch()


# ------------------------------------------------------ entrances & exits ---
## Nobody pops into or out of view (house rule, jrpg_art_style entrances.md).
## enter(): from a door in a wall face they fade in inside the dark opening
## and step down; from any other tile they walk in from beyond the camera's
## view. leave(): the reverse, then they're removed (or just hidden, keep).

func _way_in(t: Vector2i) -> Variant:
	## The entrance someone uses at tile t: the one at t, or (when t is
	## inside the map and not an open edge) the nearest one, so nobody walks
	## through a wall or out into the void. Null = walk off the open edge.
	var e = w.entrance(t)
	if e == null and not w.open_edge(t):
		e = w.nearest_entrance(w.tile_center(t))
	return e


func enter(n: Dictionary, from: Vector2i, path: Array = [], speed: float = 48.0) -> Actor:
	## n: an npc dict ({id, who|spec, dir, mood, ...}); path: tiles or points
	## to walk to after arriving. Await it to wait until they're in place.
	## Through a door, doorway or stairs they fade in inside the opening and
	## step through it; from an open map edge they walk in from off screen.
	touch()
	var d := n.duplicate()
	d.tile = from
	var act := w.add_npc(d)
	act.scripted = true
	var ent = _way_in(from)
	var pts := []
	if ent != null:
		act.position = ent.pos
		act.face(0 if (ent.step as Vector2).y > 0 else 1)
		act.modulate.a = 0.0
		# doors open and latch by themselves as someone reaches them (World
		# doors); only stairs need a sound of their own
		if w.char_at(from) in ["S", "v"]:
			Sfx.play("step", 0.9, -12.0)
		var tw := act.create_tween()
		tw.tween_property(act, "modulate:a", 1.0, 0.35)
		await tw.finished
		pts.append((ent.pos as Vector2) + (ent.step as Vector2))
		if w.entrance(from) == null:
			pts.append(w.tile_center(from))
	else:
		act.position = w.offstage(from)
		pts.append(w.tile_center(from))
	for t in path:
		pts.append(w.tile_center(t) if t is Vector2i else t)
	_trace("enter", str(n.get("id", n.get("who", ""))), [act.position] + pts, ent == null)
	if is_instance_valid(act):
		await act.walk_to(pts, speed)
		if is_instance_valid(act) and n.has("dir"):
			act.face(int(n.dir))
	return act


func _trace(kind: String, who: String, pts: Array, via_edge: bool) -> void:
	## PK_TRACE=1 (autotests): audit a walk-on / walk-off. Every step must
	## stay on the map and off solid wall, except inside a door, doorway or
	## stairs, or on the final stretch off an open map edge.
	if OS.get_environment("PK_TRACE") == "":
		return
	var walls := 0
	var outside := 0
	var props := 0
	for i in range(1, pts.size()):
		var a: Vector2 = pts[i - 1]
		var b: Vector2 = pts[i]
		var n := maxi(1, int(a.distance_to(b) / 2.0))
		var last_leg := i == pts.size() - 1
		for k in n + 1:
			var p := a.lerp(b, float(k) / n)
			var t := Vector2i(floori(p.x / World.TILE), floori((p.y - 3.0) / World.TILE))
			var ch := w.char_at(t)
			if t.x < 0 or t.y < 0 or t.x >= w.tw or t.y >= w.th:
				if not (via_edge and ((kind == "leave" and last_leg) or (kind == "enter" and i == 1))):
					outside += 1
			elif ArtTiles.is_solid(ch) and not "DdvSU".contains(ch):
				if not (via_edge and ((kind == "leave" and last_leg) or (kind == "enter" and i == 1))):
					walls += 1
			elif w.solid.has(t) and not "DdvSU".contains(ch):
				props += 1
	var ok := walls == 0 and outside == 0
	print("[trace] %s %s %s on %s: %s%s" % ["ok " if ok else "BAD", kind, who, w.def.id,
		"clean" if ok else "walls=%d outside=%d" % [walls, outside], "" if props == 0 else " (crosses furniture x%d)" % props])


func leave(id: String, path: Array = [], speed: float = 48.0, keep: bool = false) -> void:
	## Walks someone out: along path, then out through the entrance at its
	## last tile (or the nearest one), fading out in the opening; walking on
	## past the view edge only at an open map edge. Then removes them (keep:
	## just hides them, for people who come back later).
	var act := a(id)
	if act == null:
		return
	act.set_meta("leaving", true)
	touch()
	var pts := []
	for t in path:
		pts.append(w.tile_center(t) if t is Vector2i else t)
	var last: Vector2i
	if not path.is_empty() and path[-1] is Vector2i:
		last = path[-1]
	elif not pts.is_empty():
		last = Vector2i(floori((pts[-1] as Vector2).x / World.TILE), floori((pts[-1] as Vector2).y / World.TILE))
	else:
		last = Vector2i(floori(act.position.x / World.TILE), floori(act.position.y / World.TILE))
	var ent = _way_in(last)
	if ent != null:
		if w.entrance(last) != null and not pts.is_empty():
			pts.pop_back()
		pts.append((ent.pos as Vector2) + (ent.step as Vector2))
		pts.append(ent.pos)
	else:
		pts.append(w.offstage(last))
	_trace("leave", id, [act.position] + pts, ent == null)
	await act.walk_to(pts, speed)
	if not is_instance_valid(act):
		return
	if ent != null:
		if w.char_at(last) in ["S", "v"]:
			Sfx.play("step", 0.9, -12.0)
		var tw := act.create_tween()
		tw.tween_property(act, "modulate:a", 0.0, 0.35)
		await tw.finished
		if not is_instance_valid(act):
			return
	if keep:
		act.visible = false
		act.modulate.a = 1.0
	else:
		w.remove_npc(str(act.info.get("id", act.info.get("who", id))))


func hide(id: String) -> void:
	var act := a(id)
	if act:
		act.visible = false


func place(id: String, tile: Vector2i, d: int = -1, pose: String = "") -> void:
	var act := a(id)
	if act == null:
		return
	act.position = w.tile_center(tile)
	act.visible = true
	if d >= 0:
		act.face(d)
	if pose != "":
		act.set_pose(pose)


func confetti(center: Vector2, n: int = 40) -> void:
	var fx := Fx.new()
	fx.z_index = 40
	w.add_child(fx)
	fx.burst(center, n, [Pal.LEMON, Pal.ROSE, Pal.SYNC, Pal.WHITE, Pal.GLOW], Vector2(30, 90), Vector2(1.0, 2.0),
		{"up": 60.0, "acc": Vector2(0, 50), "drag": 0.97, "shape": 3, "size": 2.0, "wobble": 30.0})
	m.get_tree().create_timer(2.5).timeout.connect(fx.queue_free)


func save_at(chapter: String) -> void:
	Game.chapter = chapter
	Game.save()
