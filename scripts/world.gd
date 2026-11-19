class_name World
extends Node2D
## The field: generated ground, y-sorted props and characters, tile collision,
## talking, examining, step triggers and exits. Story scripts drive cutscenes
## through the helpers at the bottom (actor lookup, camera pans, tint).

const TILE := 16
const SPEED := 64.0

var def: Dictionary
var rows: Array
var tw := 0
var th := 0
var solid := {}
var events := {}
var ents: Node2D
var decals: Node2D
var lights: Node2D
var player: Actor
var npcs: Array = []
var by_id := {}
var props := {}
var cam: Camera2D
var busy := false
var _event_end_frame := -10
var paused := false
var animated: Array = []
var hud: CanvasLayer
var tint: CanvasModulate
var handler: Object
var cam_follow := true
var cam_focus := Vector2.ZERO
var marker: Sprite2D
var fired := {}
var step_t := 0.0
var cam_bias := 0.0
## Doors that swing open while someone stands in or beside them:
## {sprite, kind, pos (bottom centre), open}.
var doors: Array = []


func setup(map_def: Dictionary, tile: Vector2i, facing: int, p_handler: Object) -> void:
	def = map_def
	handler = p_handler
	rows = def.rows
	tw = (rows[0] as String).length()
	th = rows.size()
	tint = CanvasModulate.new()
	tint.color = def.get("tint", Color.WHITE)
	add_child(tint)
	var ground := Sprite2D.new()
	ground.centered = false
	ground.texture = Art.ground(def.id, rows, def.get("theme", "academy"))
	add_child(ground)
	decals = Node2D.new()
	add_child(decals)
	ents = Node2D.new()
	ents.y_sort_enabled = true
	add_child(ents)
	lights = Node2D.new()
	add_child(lights)
	_build_tiles()
	_build_props()
	_build_npcs()
	player = Actor.new(Game.player_spec(def.get("outfit", "")))
	player.position = tile_center(tile)
	player.face(facing)
	player.visible = not def.get("no_player", false)
	ents.add_child(player)
	cam = Camera2D.new()
	add_child(cam)
	cam.position = _clamp_cam(player.position)
	cam.make_current()
	hud = CanvasLayer.new()
	hud.layer = 3
	add_child(hud)
	if def.has("music"):
		Sfx.music(def.music)


func _clamp_cam(p: Vector2) -> Vector2:
	var mw := tw * TILE
	var mh := th * TILE
	var x := mw / 2.0 if mw <= 320 else clampf(p.x, 160.0, mw - 160.0)
	var y := mh / 2.0 + cam_bias * 0.5 if mh <= 180 else clampf(p.y, 90.0, mh - 90.0 + cam_bias)
	return Vector2(x, y)


func tile_center(t: Vector2i) -> Vector2:
	return Vector2(t.x * TILE + 8, t.y * TILE + 12)


func tile_pos(x: float, y: float) -> Vector2:
	return Vector2(x * TILE + 8, y * TILE + 12)


func _place(tex: Texture2D, pos: Vector2, parent: Node = null) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.offset = -Vector2(tex.get_width() * 0.5, tex.get_height()).floor()
	s.position = pos
	(parent if parent else ents).add_child(s)
	return s


func _shadow(pos: Vector2, w: int, h: int) -> void:
	var s := Sprite2D.new()
	s.texture = Art.shadow(w, h)
	s.modulate = Color(1, 1, 1, 0.25)
	s.position = pos
	decals.add_child(s)


func add_light(pos: Vector2, r: int, c: Color, pulse: float = 0.0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = Art.light(r, c)
	s.position = pos
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	s.material = m
	lights.add_child(s)
	if pulse > 0.0:
		s.set_meta("pulse", pulse)
		s.set_meta("phase", randf() * TAU)
		animated.append(s)
	return s


func _build_tiles() -> void:
	for y in th:
		for x in tw:
			var ch: String = (rows[y] as String)[x]
			if ArtTiles.is_solid(ch):
				solid[Vector2i(x, y)] = true


func _build_props() -> void:
	for p in def.get("props", []):
		var t: Vector2i = p.tile
		var pos: Vector2 = Vector2(t.x * TILE + 8, (t.y + 1) * TILE) + p.get("offset", Vector2.ZERO)
		var tex := Art.prop(p.kind, p.get("v", 0))
		var s: Sprite2D
		if p.get("decal", false):
			s = _place(tex, pos, decals)
		else:
			s = _place(tex, pos)
			if p.get("shadow", true) and tex.get_width() > 12 and p.get("wall", false) == false:
				_shadow(pos + Vector2(0, -1), int(tex.get_width() * 0.8), 5)
		if p.has("lift"):
			s.offset.y -= p.lift
		if p.has("id"):
			props[p.id] = s
		if p.get("door", false):
			doors.append({"sprite": s, "kind": p.kind, "pos": pos, "open": false})
		if p.has("anim"):
			s.set_meta("kind", p.kind)
			s.set_meta("frames", p.anim)
			s.set_meta("fps", p.get("fps", 3.0))
			animated.append(s)
		if p.has("light"):
			var lp: Vector2 = pos + p.get("light_off", Vector2(0, -tex.get_height() * 0.6))
			add_light(lp, p.get("lr", 18), p.light, p.get("pulse", 0.0))
		var area: Rect2i = p.get("area", Rect2i(t.x, t.y, 1, 1) if not p.get("decal", false) and not p.get("wall", false) else Rect2i())
		for yy in range(area.position.y, area.end.y):
			for xx in range(area.position.x, area.end.x):
				solid[Vector2i(xx, yy)] = true
				if p.has("event"):
					events[Vector2i(xx, yy)] = p.event
		if p.has("event") and area.size == Vector2i.ZERO:
			events[t] = p.event
		if p.kind == "holo":
			_holo_planet(pos + Vector2(0, -28), p.get("planet", "green_planet"), p.get("id", "holo") + "_planet")
	for e in def.get("events", []):
		events[e.tile] = e


func _holo_planet(pos: Vector2, key: String, id: String) -> void:
	var s := Sprite2D.new()
	s.texture = Art.planet(key, 28, 0)
	s.position = pos
	s.modulate = Color(Pal.SYNC.lerp(Pal.WHITE, 0.3), 0.75)
	s.set_meta("holo", key)
	s.z_index = 5
	add_child(s)
	animated.append(s)
	props[id] = s
	add_light(pos, 26, Pal.SYNC.lerp(Pal.TEAL, 0.5), 2.0)


func _build_npcs() -> void:
	for n in def.get("npcs", []):
		add_npc(n)


func add_npc(n: Dictionary) -> Actor:
	var a: Actor
	if n.get("bot", false):
		a = Actor.new({})
		a.bot = true
		a.refresh()
	else:
		var spec: Dictionary = n.spec if n.has("spec") else Game.cast(n.who)
		a = Actor.new(spec)
	a.info = n
	a.home_tile = n.tile
	a.position = tile_center(n.tile) + n.get("offset", Vector2.ZERO)
	a.face(n.get("dir", 0))
	if n.has("mood"):
		a.mood = n.mood
	if n.has("pose"):
		a.pose = n.pose
	a.refresh()
	ents.add_child(a)
	npcs.append(a)
	if n.has("id"):
		by_id[n.id] = a
	elif n.has("who"):
		by_id[n.who] = a
	return a


func remove_npc(id: String) -> void:
	if by_id.has(id):
		var a: Actor = by_id[id]
		npcs.erase(a)
		by_id.erase(id)
		a.queue_free()


func view_rect() -> Rect2:
	## What the camera shows right now (pans included), in world space.
	var size := get_viewport_rect().size / (cam.zoom if cam else Vector2.ONE)
	var c := cam.get_screen_center_position() if cam else Vector2.ZERO
	return Rect2(c - size / 2.0, size)


func char_at(t: Vector2i) -> String:
	if t.y < 0 or t.y >= rows.size() or t.x < 0 or t.x >= (rows[t.y] as String).length():
		return " "
	return (rows[t.y] as String)[t.x]


func door_sill(t: Vector2i) -> Variant:
	## For a door in a wall face (a D with floor below it), the point at the
	## centre of its opening on the sill, where someone stepping out stands;
	## null for anything else.
	if char_at(t) != "D":
		return null
	var below := t
	while char_at(below) == "D":
		below.y += 1
	if ArtTiles.is_wall(char_at(below)) or char_at(below) == " ":
		return null
	var x0 := t.x
	while char_at(Vector2i(x0 - 1, t.y)) == "D":
		x0 -= 1
	var x1 := t.x
	while char_at(Vector2i(x1 + 1, t.y)) == "D":
		x1 += 1
	return Vector2((x0 + x1 + 1) * TILE / 2.0, below.y * TILE - 1)


func offstage(t: Vector2i) -> Vector2:
	## A point beyond the view edge nearest tile t, far enough out that a
	## standing sprite there is entirely out of sight.
	var v := view_rect()
	var p := tile_center(t)
	var d := {"left": p.x - v.position.x, "right": v.end.x - p.x, "top": p.y - v.position.y, "bottom": v.end.y - p.y}
	var best := "left"
	for k in d:
		if d[k] < d[best]:
			best = k
	match best:
		"left":
			return Vector2(v.position.x - 16, clampf(p.y, v.position.y + 40, v.end.y))
		"right":
			return Vector2(v.end.x + 16, clampf(p.y, v.position.y + 40, v.end.y))
		"top":
			return Vector2(clampf(p.x, v.position.x, v.end.x), v.position.y - 4)
	return Vector2(clampf(p.x, v.position.x, v.end.x), v.end.y + 36)


func show_area_name(text: String = "") -> void:
	if text == "":
		text = def.get("name", "")
	if text == "":
		return
	var b := Art.make_box("bar_box")
	var l := Label.new()
	l.text = text
	l.position = Vector2(6, 3)
	b.add_child(l)
	b.size = Vector2(Art.text_width(text) + 14, 15)
	b.position = Vector2(-b.size.x, 6)
	hud.add_child(b)
	var tw_ := b.create_tween()
	tw_.tween_property(b, "position:x", 6.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_.tween_interval(2.0)
	tw_.tween_property(b, "position:x", -b.size.x - 4, 0.3)
	tw_.tween_callback(b.queue_free)


# ---------------------------------------------------------------- update ---

func _process(delta: float) -> void:
	_animate(delta)
	_update_npcs(delta)
	var want := 34.0 if Game.main.dialog.visible else 0.0
	cam_bias = move_toward(cam_bias, want, delta * 120.0)
	var target := _clamp_cam((player.position if cam_follow else cam_focus) + Vector2(0, cam_bias))
	cam.position = cam.position.lerp(target, minf(1.0, delta * 8.0)) if not cam_follow else target
	cam.position = cam.position.round()
	_safety_net(delta)
	if not busy and not paused and player.visible and not player.scripted and not Game.main.dialog.visible:
		# only in walking mode: cutscenes seat people on benches on purpose
		_unstick_player()
	if busy or paused or Game.main.dialog.visible or not player.visible:
		if not player.scripted:
			player.moving = false
		return
	var v := Input.get_vector("left", "right", "up", "down")
	if v.length() > 0.2:
		var d: int
		if absf(v.x) > absf(v.y):
			d = 2 if v.x > 0 else 3
		else:
			d = 0 if v.y > 0 else 1
		player.face(d)
		var spd := SPEED * (1.6 if Input.is_action_pressed("run") else 1.0)
		var step := v.normalized() * spd * delta
		var before := player.position
		_try_move(Vector2(step.x, 0))
		_try_move(Vector2(0, step.y))
		var moved := player.position.distance_to(before)
		player.moving = moved > 0.01
		if moved > 0.01:
			step_t += moved
			if step_t > 18.0:
				step_t = 0.0
				Sfx.play("step", randf_range(0.9, 1.1), -22.0)
				if Input.is_action_pressed("run"):
					_dust(player.position)
			_after_step()
	else:
		player.moving = false
	if busy or Engine.get_process_frames() - _event_end_frame <= 1:
		return
	if Input.is_action_just_pressed("accept"):
		_interact()
	elif Input.is_action_just_pressed("cancel"):
		run(Game.main.field_menu)


var _stuck_t := 0.0


func _safety_net(delta: float) -> void:
	## Walking mode can never be lost: if the field has been locked for a
	## moment with nothing going on (no interaction running, no story beat
	## for several seconds, no dialog, fade, menu or cutscene picture up),
	## hand control back.
	var m: Node = Game.main
	# quiet for 4 s with no interaction running, or for 10 s even with one
	# (an interaction that has hung will never finish on its own)
	var quiet := Time.get_ticks_msec() - int(handler.get("last_activity")) if handler != null else 0
	var idle: bool = busy and not paused and is_visible_in_tree() and player.visible and not m.dialog.visible \
		and m.fade_rect.color.a < 0.05 and handler != null \
		and ((int(handler.get("active")) == 0 and quiet > 4000) or quiet > 10000)
	if idle:
		# someone still walking a scripted path is a cutscene in progress
		if player.scripted and player.moving:
			idle = false
		for n: Actor in npcs:
			if n.scripted and n.moving:
				idle = false
		for c in m.cine_layer.get_children():
			if c is CanvasItem and c.visible:
				idle = false
		for c in m.ui.get_children():
			if c is Control and c.visible and c != m.dialog and not (c is ColorRect) and c.get_script() != null and not c.has_meta("toast"):
				idle = false
	_stuck_t = _stuck_t + delta if idle else 0.0
	if _stuck_t > 1.0:
		_stuck_t = 0.0
		busy = false
		push_warning("field was locked with nothing running on %s; control restored" % def.get("id", "?"))


func _try_move(d: Vector2) -> void:
	var p := player.position + d
	if not blocked(p, player):
		player.position = p
	elif d.x == 0.0 and d.y != 0.0:
		# walking up or down into a narrow gap (a doorway, a stair) slightly
		# off centre: slide toward the gap instead of sticking on its frame
		var cx := floorf(player.position.x / TILE) * TILE + TILE / 2.0
		for c in [cx, cx - TILE, cx + TILE]:
			var off: float = c - player.position.x
			if absf(off) > 7.0 or absf(off) < 0.01:
				continue
			if not blocked(Vector2(c, p.y), player):
				var nudge := Vector2(signf(off) * minf(absf(off), absf(d.y)), 0)
				if not blocked(player.position + nudge, player):
					player.position += nudge
				return


func blocked_by_map(p: Vector2) -> bool:
	## The walls and props alone (no people).
	for c in [Vector2(-5, -5), Vector2(5, -5), Vector2(-5, -1), Vector2(5, -1)]:
		var q: Vector2 = p + c
		var t := Vector2i(floori(q.x / TILE), floori(q.y / TILE))
		if t.x < 0 or t.y < 0 or t.x >= tw or t.y >= th or solid.has(t):
			return true
	return false


func _unstick_player() -> void:
	## If the player stands inside a wall or a prop (a bad arrival tile, a
	## scripted walk that ended in furniture), move them to the nearest tile
	## they can actually walk on.
	if player == null or not blocked_by_map(player.position):
		return
	var here := Vector2i(floori(player.position.x / TILE), floori((player.position.y - 3) / TILE))
	for r in range(1, maxi(tw, th)):
		var best := Vector2i(-1, -1)
		var bd := 1e9
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var t := here + Vector2i(dx, dy)
				if t.x < 0 or t.y < 0 or t.x >= tw or t.y >= th:
					continue
				var c := tile_center(t)
				if blocked_by_map(c) or ArtTiles.is_wall(char_at(t)) or char_at(t) == " ":
					continue
				var d := c.distance_to(player.position)
				if d < bd:
					bd = d
					best = t
		if best.x >= 0:
			push_warning("player was inside something solid at %s on %s; moved to %s" % [here, def.get("id", "?"), best])
			player.position = tile_center(best)
			return


func blocked(p: Vector2, who: Node2D) -> bool:
	for c in [Vector2(-5, -5), Vector2(5, -5), Vector2(-5, -1), Vector2(5, -1)]:
		var q: Vector2 = p + c
		var t := Vector2i(floori(q.x / TILE), floori(q.y / TILE))
		if t.x < 0 or t.y < 0 or t.x >= tw or t.y >= th or solid.has(t):
			return true
	for n: Actor in npcs:
		if n == who or not n.visible or n.info.get("ghost", false):
			continue
		if absf(n.position.x - p.x) < 11 and absf(n.position.y - p.y) < 7:
			# already overlapping (a cutscene parked someone on top of you):
			# any step that doesn't go deeper in is allowed, so you can't be pinned
			var cur: Vector2 = who.position
			if absf(n.position.x - cur.x) < 11 and absf(n.position.y - cur.y) < 7 \
					and p.distance_to(n.position) >= cur.distance_to(n.position):
				continue
			return true
	if who != player and absf(player.position.x - p.x) < 11 and absf(player.position.y - p.y) < 7:
		return true
	return false


func _after_step() -> void:
	var t := Vector2i(floori(player.position.x / TILE), floori((player.position.y - 3) / TILE))
	for e in def.get("exits", []):
		if (e.rect as Rect2i).has_point(t):
			run(handler.exit.bind(e))
			return
	for tr in def.get("triggers", []):
		if (tr.rect as Rect2i).has_point(t) and not fired.has(tr.id):
			if tr.get("once", true):
				fired[tr.id] = true
			run(handler.trigger.bind(tr.id))
			return


func _dust(p: Vector2) -> void:
	for i in 3:
		var d := Sprite2D.new()
		d.texture = Art.shadow(4, 3)
		d.modulate = Color(Pal.CREAM, 0.5)
		d.position = p + Vector2(randf_range(-4, 4), -1)
		decals.add_child(d)
		var tw := d.create_tween().set_parallel(true)
		tw.tween_property(d, "position", d.position + Vector2(randf_range(-6, 6), -4), 0.35)
		tw.tween_property(d, "modulate:a", 0.0, 0.35)
		tw.chain().tween_callback(d.queue_free)


func run(co: Callable) -> void:
	## Runs an async event with player control locked until it finishes.
	if busy:
		return
	busy = true
	if not player.scripted:
		player.moving = false
	await co.call()
	if is_instance_valid(self):
		busy = false
		_event_end_frame = Engine.get_process_frames()


func _update_npcs(delta: float) -> void:
	for n: Actor in npcs:
		if n.scripted:
			continue
		if not n.info.get("wander", false) or busy or paused:
			if n.walk_target == null:
				n.moving = false
			continue
		if n.walk_target == null:
			n.moving = false
			n.wander_t -= delta
			if n.wander_t <= 0:
				n.wander_t = randf_range(1.5, 4.0)
				var d := randi() % 4
				var target: Vector2 = n.position + Actor.DIRS[d] * TILE
				var home := tile_center(n.home_tile)
				if target.distance_to(home) <= TILE * n.info.get("range", 2.5) and not blocked(target, n):
					n.face(d)
					n.walk_target = target
		else:
			var tgt: Vector2 = n.walk_target
			var step := (tgt - n.position).limit_length(28.0 * delta)
			if blocked(n.position + step, n):
				n.walk_target = null
				continue
			n.position += step
			n.moving = true
			if n.position.distance_to(tgt) < 0.5:
				n.position = tgt
				n.walk_target = null


func _update_doors() -> void:
	for d in doors:
		var near := false
		for a: Actor in [player] + npcs:
			if not a.visible or a.info.get("ghost", false):
				continue
			var v: Vector2 = a.position - d.pos
			if absf(v.x) < 12.0 and v.y > -44.0 and v.y < 6.0:
				near = true
				break
		if near != d.open:
			d.open = near
			(d.sprite as Sprite2D).texture = Art.prop(d.kind, 1 if near else 0)
			Sfx.play("latch", 1.0 if near else 0.88, -8.0)


func _animate(_delta: float) -> void:
	_update_doors()
	var t := Time.get_ticks_msec() / 1000.0
	for s in animated:
		if not is_instance_valid(s):
			continue
		if s.has_meta("pulse"):
			s.modulate.a = 0.75 + 0.25 * sin(t * s.get_meta("pulse") + s.get_meta("phase"))
		elif s.has_meta("holo"):
			s.texture = Art.planet(s.get_meta("holo"), 28, int(t * 6.0))
			s.modulate.a = 0.62 + (0.2 if fmod(t * 7.3, 1.0) > 0.12 else -0.25)
			s.position.y += sin(t * 2.0) * 0.02
		elif s.has_meta("frames"):
			s.texture = Art.prop(s.get_meta("kind"), int(t * s.get_meta("fps")) % int(s.get_meta("frames")))
	if marker:
		marker.position.y = marker.get_meta("y") + (1.0 if fmod(t, 0.6) < 0.3 else -1.0)


# ------------------------------------------------------------- interact ----

func _interact() -> void:
	var front: Vector2 = player.position + Actor.DIRS[player.dir] * 12 + Vector2(0, -3)
	for n: Actor in npcs:
		if n.visible and n.position.distance_to(front + Vector2(0, 3)) < 13:
			run(_talk.bind(n))
			return
	var t := Vector2i(floori(front.x / TILE), floori(front.y / TILE))
	if events.has(t):
		run(handler.examine.bind(events[t]))


func _talk(n: Actor) -> void:
	n.walk_target = null
	n.moving = false
	var was := n.dir
	if not n.info.get("no_turn", false) and n.pose == "walk":
		n.face_toward(player.position)
	await handler.talk(n)
	if is_instance_valid(n) and n.info.get("turn_back", true) and n.info.get("wander", false) == false:
		n.face(was)


# --------------------------------------------------------------- helpers ---

func actor(id: String) -> Actor:
	if id == "player":
		return player
	return by_id.get(id, null)


func pan_to(p: Vector2, t: float = 0.8) -> void:
	cam_follow = false
	var from := cam.position
	cam_focus = p
	var tw_ := create_tween()
	tw_.tween_method(func(v: Vector2) -> void: cam_focus = v, from, p, t).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw_.finished


func pan_back(t: float = 0.6) -> void:
	await pan_to(player.position, t)
	cam_follow = true


func set_tint(c: Color, t: float = 0.6) -> void:
	var tw_ := create_tween()
	tw_.tween_property(tint, "color", c, t)
	await tw_.finished


func show_marker(tile: Vector2i) -> void:
	if marker == null:
		marker = Sprite2D.new()
		marker.texture = Art.ui("marker")
		marker.z_index = 30
		add_child(marker)
	marker.position = tile_center(tile) + Vector2(0, -22)
	marker.set_meta("y", marker.position.y)
	marker.visible = true


func hide_marker() -> void:
	if marker:
		marker.visible = false


func prop_sprite(id: String) -> Sprite2D:
	return props.get(id, null)
