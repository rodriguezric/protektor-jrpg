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
var endings: StoryEndings


func _ready() -> void:
	prologue = StoryPrologue.new(self)
	academy = StoryAcademy.new(self)
	hub = StoryHub.new(self)
	endings = StoryEndings.new(self)


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
		"home", "parade":
			return prologue
		"commons":
			return hub
		"launch_wing":
			return endings
	return academy


func talk(n: Actor) -> void:
	var o := _owner()
	if o and o.has_method("talk"):
		await o.talk(n)
	else:
		await say("", "...")


func examine(ev: Dictionary) -> void:
	var o := _owner()
	if o and o.has_method("examine"):
		await o.examine(ev)


func trigger(id: String) -> void:
	var o := _owner()
	if o and o.has_method("trigger"):
		await o.trigger(id)


func exit(e: Dictionary) -> void:
	var o := _owner()
	if o and o.has_method("exit"):
		await o.exit(e)


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
			var nm: String = {"system": "System", "system_far": "System (distant)", "system_close": "System (close)"}[who]
			return [nm, {"portrait": "system", "sys": true, "voice": "system", "side": "left"}]
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
	await m.dialog.say(lines, sp[0], opts)


func ask(question: String, options: Array, who: String = "", mood: String = "") -> int:
	var sp := speaker(who, mood)
	return await m.dialog.ask(question, options, sp[0], sp[1])


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
	await act.walk_to(pts, speed)


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
	await w.pan_to(p, t)


func pan_back(t: float = 0.6) -> void:
	await w.pan_back(t)


func wait(t: float) -> void:
	await m.get_tree().create_timer(t).timeout


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
