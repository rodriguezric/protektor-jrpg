class_name TvStage
extends Node2D
## A little set for a TV show, drawn inside the TV's 144x80 picture: a
## backdrop, field actors (the same Actor sprites the story uses), props,
## typed captions along the bottom, zooms, flashes and music stings.
##
## Shows are written as plain async functions against this API. Flipping
## the channel cancels the stage: every call then returns at once without
## touching anything, so a cancelled show runs out in a frame and the TV can
## free the stage safely afterwards (see TvScreen).

const W := 144
const H := 80

var cancelled := false
var set_root: Node2D
var bg_sprite: Sprite2D
var actors := {}
var props := {}
var cap_box: ColorRect
var cap_name: Label
var cap_text: Label
var overlay: ColorRect
var ticker: Label
var _ticker_on := false


func _init() -> void:
	set_root = Node2D.new()
	add_child(set_root)
	bg_sprite = Sprite2D.new()
	bg_sprite.centered = false
	set_root.add_child(bg_sprite)
	overlay = ColorRect.new()
	overlay.size = Vector2(W, H)
	overlay.color = Color(1, 1, 1, 0)
	overlay.z_index = 30
	add_child(overlay)
	# captions: one line along the bottom, the speaker's name in their colour
	cap_box = ColorRect.new()
	cap_box.position = Vector2(0, H - 10)
	cap_box.size = Vector2(W, 10)
	cap_box.color = Color(0, 0, 0, 0.78)
	cap_box.z_index = 20
	cap_box.visible = false
	add_child(cap_box)
	cap_name = Art.label("", Color("ffd36b"))
	cap_name.position = Vector2(2, 0)
	cap_box.add_child(cap_name)
	cap_text = Art.label("", Pal.WHITE)
	cap_text.position = Vector2(2, 0)
	cap_box.add_child(cap_text)
	# the news ticker runs along the top
	var tb := ColorRect.new()
	tb.size = Vector2(W, 9)
	tb.color = Color(0.6, 0.05, 0.1, 0.85)
	tb.z_index = 21
	tb.visible = false
	tb.name = "ticker_bar"
	add_child(tb)
	ticker = Art.label("", Pal.WHITE)
	ticker.z_index = 22
	ticker.visible = false
	add_child(ticker)


func _process(delta: float) -> void:
	if _ticker_on:
		ticker.position.x -= 22.0 * delta
		if ticker.position.x < -Art.text_width(ticker.text):
			ticker.position.x = W


# ------------------------------------------------------------- staging ---

func wait(t: float) -> void:
	var left := t
	while left > 0.0 and not cancelled:
		await get_tree().process_frame
		if not is_inside_tree():
			return
		left -= get_process_delta_time()


func backdrop(kind: String) -> void:
	if cancelled:
		return
	bg_sprite.texture = ImageTexture.create_from_image(TvSets.draw(kind).img)


func actor(id: String, spec: Dictionary, pos: Vector2, dir: int = 0, mood: String = "") -> Actor:
	if cancelled:
		return null
	var a := Actor.new(spec)
	a.position = pos
	a.scripted = true
	a.face(dir)
	a.set_mood(mood)
	set_root.add_child(a)
	actors[id] = a
	return a


func a(id: String) -> Actor:
	return actors.get(id)


func prop(id: String, kind: String, pos: Vector2, v: int = 0, scale_k: float = 1.0) -> Sprite2D:
	if cancelled:
		return null
	var s := Sprite2D.new()
	s.texture = Art.prop(kind, v)
	s.centered = false
	s.offset = Vector2(-s.texture.get_width() / 2.0, -s.texture.get_height())
	s.position = pos
	s.scale = Vector2(scale_k, scale_k)
	set_root.add_child(s)
	props[id] = s
	return s


func sprite(id: String, tex: Texture2D, pos: Vector2, scale_k: float = 1.0) -> Sprite2D:
	if cancelled:
		return null
	var s := Sprite2D.new()
	s.texture = tex
	s.position = pos
	s.scale = Vector2(scale_k, scale_k)
	set_root.add_child(s)
	props[id] = s
	return s


func remove(id: String) -> void:
	if cancelled:
		return
	for d in [actors, props]:
		if d.has(id):
			d[id].queue_free()
			d.erase(id)


func clear_set() -> void:
	if cancelled:
		return
	for d in [actors, props]:
		for k in d:
			d[k].queue_free()
		d.clear()
	set_root.scale = Vector2.ONE
	set_root.position = Vector2.ZERO


func walk(id: String, to: Vector2, speed: float = 30.0) -> void:
	if cancelled or not actors.has(id):
		return
	var act: Actor = actors[id]
	act.face_toward(to)
	await act.walk_to([to], speed)


func move(id: String, to: Vector2, t: float, trans: int = Tween.TRANS_SINE) -> void:
	## Glide a prop or actor (no walk cycle): flying robots, sliding cards.
	if cancelled:
		return
	var n: Node2D = actors.get(id, props.get(id))
	if n == null:
		return
	var tw := create_tween()
	tw.tween_property(n, "position", to, t).set_trans(trans).set_ease(Tween.EASE_IN_OUT)
	await wait(t)


func face(id: String, d: int) -> void:
	if not cancelled and actors.has(id):
		actors[id].face(d)


func mood(id: String, m: String) -> void:
	if not cancelled and actors.has(id):
		actors[id].set_mood(m)


func pose(id: String, p: String) -> void:
	if not cancelled and actors.has(id):
		actors[id].set_pose(p)


func emote(id: String, kind: String, hold: float = 1.0) -> void:
	if not cancelled and actors.has(id):
		actors[id].emote(kind, hold)


func hop(id: String, h: float = 3.0) -> void:
	if not cancelled and actors.has(id):
		actors[id].hop(h)


func shake_actor(id: String, t: float = 0.3) -> void:
	if not cancelled and actors.has(id):
		actors[id].shake(t, 1.0)


func zoom(k: float, focus: Vector2, t: float = 0.3) -> void:
	## The camera pushes in on focus (k > 1) or pulls back (k = 1).
	if cancelled:
		return
	var target_pos := Vector2(W / 2.0, H / 2.0 - 6.0) - focus * k if k != 1.0 else Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(set_root, "scale", Vector2(k, k), t).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(set_root, "position", target_pos, t).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await wait(t)


func flash(c: Color = Color.WHITE, t: float = 0.25) -> void:
	if cancelled:
		return
	overlay.color = Color(c, 0.9)
	create_tween().tween_property(overlay, "color:a", 0.0, t)


func fade(to_black: bool, t: float = 0.4) -> void:
	if cancelled:
		return
	overlay.color = Color(0, 0, 0, 0.0 if to_black else 1.0)
	create_tween().tween_property(overlay, "color:a", 1.0 if to_black else 0.0, t)
	await wait(t)


func shake(t: float = 0.3, amp: float = 2.0) -> void:
	if cancelled:
		return
	var left := t
	while left > 0.0 and not cancelled:
		set_root.position += Vector2(randf_range(-amp, amp), randf_range(-amp, amp))
		await get_tree().process_frame
		if not is_inside_tree():
			return
		set_root.position -= Vector2.ZERO
		left -= get_process_delta_time()
	if not cancelled:
		set_root.position = set_root.position.round()


func say(who: String, text: String, hold: float = 1.4, col: Color = Color("ffd36b")) -> void:
	## A caption along the bottom: the speaker's name, then the line typed
	## out; a line too long for the band plays as several in a row.
	if cancelled:
		return
	cap_box.visible = true
	var tag := (who + ":") if who != "" else ""
	cap_name.text = tag
	cap_name.add_theme_color_override("font_color", col)
	var x0 := 2 + (Art.text_width(tag) + 3 if tag != "" else 0)
	cap_text.position.x = x0
	var chunks := _wrap(text, W - x0 - 2)
	for ci in chunks.size():
		var full: String = chunks[ci]
		var n := 0.0
		while n < full.length() and not cancelled:
			await get_tree().process_frame
			if not is_inside_tree():
				return
			n += get_process_delta_time() * 30.0
			cap_text.text = full.substr(0, int(n))
			if int(n) % 3 == 0:
				Sfx.voice("system" if who == "" else "boy", int(n))
		if cancelled:
			return
		cap_text.text = full
		await wait((hold if ci == chunks.size() - 1 else 0.5) + full.length() * 0.02)


func caption_off() -> void:
	if not cancelled:
		cap_box.visible = false


func title(big: String, small: String, col: Color, hold: float = 1.6) -> void:
	## A title card: the show's name over its own colour.
	if cancelled:
		return
	var card := ColorRect.new()
	card.size = Vector2(W, H)
	card.color = col.darkened(0.6)
	card.z_index = 25
	add_child(card)
	var l := Art.label(big, col.lerp(Color.WHITE, 0.4))
	l.add_theme_font_size_override("font_size", PixFont.SIZE * (2 if Art.text_width(big, 2) <= W - 8 else 1))
	var k := 2 if Art.text_width(big, 2) <= W - 8 else 1
	l.position = Vector2(floorf(W / 2.0 - Art.text_width(big, k) / 2.0), 22)
	card.add_child(l)
	var s := Art.label(small, Pal.WHITE)
	s.position = Vector2(floorf(W / 2.0 - Art.text_width(small) / 2.0), 30 + 9 * k)
	card.add_child(s)
	l.position.y -= 30
	create_tween().tween_property(l, "position:y", l.position.y + 30, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	sting("title")
	await wait(hold)
	card.queue_free()


func big_text(text: String, col: Color, hold: float = 0.8) -> void:
	## Comic-book lettering over the picture (KA-POW!).
	if cancelled:
		return
	var l := Art.shadow_label(text, col, 2)
	l.position = Vector2(floorf(W / 2.0 - Art.text_width(text, 2) / 2.0), 18)
	l.z_index = 24
	l.pivot_offset = Vector2(Art.text_width(text, 2) / 2.0, 8)
	l.scale = Vector2(0.3, 0.3)
	add_child(l)
	create_tween().tween_property(l, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await wait(hold)
	if is_instance_valid(l):
		l.queue_free()


func freeze_frame(text: String) -> void:
	## The serial's last shot: everything stops, the colour drains to sepia
	## and the words slam in.
	if cancelled:
		return
	set_root.process_mode = Node.PROCESS_MODE_DISABLED
	var tw := create_tween()
	tw.tween_property(set_root, "modulate", Color(1.15, 0.95, 0.7), 0.15)
	flash(Color.WHITE, 0.2)
	sting("drama")
	await big_text(text, Color("ffd36b"), 2.4)
	set_root.process_mode = Node.PROCESS_MODE_INHERIT
	set_root.modulate = Color.WHITE


func ticker_text(text: String) -> void:
	if cancelled:
		return
	ticker.text = text
	ticker.position = Vector2(W, 0)
	ticker.visible = true
	get_node("ticker_bar").visible = true
	_ticker_on = true


func ticker_off() -> void:
	if not cancelled:
		ticker.visible = false
		get_node("ticker_bar").visible = false
		_ticker_on = false


func sting(kind: String) -> void:
	## Little musical punctuation in blips: a title fanfare, the dramatic
	## DUN-DUN-DUNNN, a happy jingle, a laugh track.
	if cancelled:
		return
	match kind:
		"title":
			_notes([1.0, 1.26, 1.5, 2.0], 0.09, -10.0)
		"drama":
			_notes([0.75, 0.71, 0.5], 0.28, -6.0)
		"happy":
			_notes([1.5, 1.68, 2.0], 0.07, -12.0)
		"sad":
			_notes([1.0, 0.94, 0.84, 0.75], 0.22, -12.0)
		"laugh":
			Sfx.play("crowd", 1.4, -10.0)
		"cheer":
			Sfx.play("crowd", 1.0, -8.0)


func _notes(pitches: Array, gap: float, db: float) -> void:
	for p in pitches:
		if cancelled or not is_inside_tree():
			return
		Sfx.play("blip", p, db)
		await get_tree().create_timer(gap).timeout


func _wrap(text: String, width: float = W - 4) -> PackedStringArray:
	var out := PackedStringArray()
	var cur := ""
	for word in text.split(" ", false):
		var trial := word if cur == "" else cur + " " + word
		if Art.text_width(trial) <= width:
			cur = trial
		else:
			if cur != "":
				out.append(cur)
			cur = word
	if cur != "":
		out.append(cur)
	return out
