class_name TvScreen
extends Control
## Watching TV: the set fills the screen, its 144x80 picture at 2x under
## scanlines (the same tube as the Starbox). Up/Right and Down/Left flip the
## channel through a burst of static, X (B) switches it off. Each channel
## plays its show (TvShows) on a fresh TvStage and loops it with a station
## ident between runs. Channel 6 is only static... mostly.
##
## Touch: an arrow screen (the stick flips channels, B switches off).

const SW := 144
const SH := 80
const SCREEN := Rect2(16, 10, SW * 2, SH * 2)

var vp: SubViewport
var picture: TextureRect
var stage: TvStage
var noise: TextureRect
var osd: Label
var idx := 0
var _t := 0.0
var _osd_t := 0.0
var _static_t := 0.0
var _noise_tex: Array = []
var seen := {}


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var room := ColorRect.new()
	room.color = Color("120d0a")
	room.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(room)
	var set_ := TextureRect.new()
	set_.texture = ImageTexture.create_from_image(_cabinet().img)
	set_.position = Vector2(4, 2)
	add_child(set_)
	vp = SubViewport.new()
	vp.size = Vector2i(SW, SH)
	vp.disable_3d = true
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var bg := ColorRect.new()
	bg.color = Color("05040a")
	bg.size = Vector2(SW, SH)
	vp.add_child(bg)
	for k in 4:
		_noise_tex.append(_make_noise(k))
	noise = TextureRect.new()
	noise.size = Vector2(SW, SH)
	noise.z_index = 40
	noise.visible = false
	vp.add_child(noise)
	osd = Art.shadow_label("", Color("8aff8a"))
	osd.position = Vector2(SW - 34, 2)
	osd.z_index = 41
	vp.add_child(osd)
	picture = TextureRect.new()
	picture.texture = vp.get_texture()
	picture.position = SCREEN.position
	picture.size = SCREEN.size
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sh := Shader.new()
	sh.code = ConsoleScreen.CRT_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	picture.material = mat
	add_child(picture)


func _cabinet() -> PixBuf:
	## The family set: a wood-grain cabinet, dials on the bezel's lip.
	var b := PixBuf.new(312, 176)
	var wood := Color("5a3a24")
	b.rect(0, 2, 312, 172, Pal.INK)
	b.rect(2, 0, 308, 176, Pal.INK)
	b.rect(2, 2, 308, 172, wood)
	for y in range(4, 172, 5):
		b.rect(2, y, 308, 1, wood.lerp(Color("3a2414"), 0.35))
	b.rect(4, 4, 304, 2, wood.lerp(Pal.WHITE, 0.15))
	b.rect(10, 6, 292, 166, Color("1a1410"))
	b.rect(11, 7, 290, 164, Pal.INK)
	b.circ(292, 172, 2, Color("c9ccd8"))
	b.circ(282, 172, 2, Color("c9ccd8"))
	return b


func _make_noise(k: int) -> ImageTexture:
	var img := Image.create(SW, SH, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99 + k * 17
	for y in SH:
		var band := rng.randf() < 0.06
		for x in SW:
			var v := rng.randf_range(0.1, 0.85)
			if band:
				v = 0.95
			img.set_pixel(x, y, Color(v, v, v))
	return ImageTexture.create_from_image(img)


func _process(delta: float) -> void:
	_t += delta
	picture.material.set_shader_parameter("time", _t)
	if noise.visible:
		noise.texture = _noise_tex[int(_t * 24.0) % _noise_tex.size()]
	_osd_t -= delta
	osd.visible = _osd_t > 0.0


# ---------------------------------------------------------------- flow ---

func run(start_channel: int = 0) -> void:
	idx = clampi(start_channel, 0, TvShows.CHANNELS.size() - 1)
	await _power_on()
	_tune()
	await get_tree().process_frame
	while true:
		await get_tree().process_frame
		if not is_inside_tree():
			return
		if Input.is_action_just_pressed("up") or Input.is_action_just_pressed("right"):
			idx = (idx + 1) % TvShows.CHANNELS.size()
			_tune()
		elif Input.is_action_just_pressed("down") or Input.is_action_just_pressed("left"):
			idx = (idx - 1 + TvShows.CHANNELS.size()) % TvShows.CHANNELS.size()
			_tune()
		elif Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("pause"):
			break
	_drop_stage()
	noise.visible = false
	Sfx.play("shutdown", 2.0, -14.0)
	var tw := create_tween()
	tw.tween_property(picture, "scale", Vector2(1, 0.02), 0.14).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(picture, "modulate", Color(3, 3, 3), 0.14)
	tw.tween_property(picture, "scale", Vector2(0.0, 0.02), 0.1)
	await tw.finished
	await get_tree().create_timer(0.2).timeout


func _power_on() -> void:
	picture.pivot_offset = SCREEN.size / 2.0
	picture.scale = Vector2(1.0, 0.02)
	picture.modulate = Color(3, 3, 3)
	Sfx.play("static", 1.3, -16.0)
	var tw := create_tween()
	tw.tween_property(picture, "scale", Vector2(1, 1), 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(picture, "modulate", Color.WHITE, 0.4)
	await tw.finished


func channel_id() -> String:
	return TvShows.CHANNELS[idx].id


func _tune() -> void:
	## Flip: a burst of static and the channel number, then the show.
	_drop_stage()
	var ch: Dictionary = TvShows.CHANNELS[idx]
	osd.text = "CH %d" % ch.ch
	_osd_t = 1.6
	noise.visible = true
	Sfx.play("static", randf_range(0.9, 1.3), -14.0)
	seen[ch.id] = true
	stage = TvStage.new()
	stage.visible = false
	vp.add_child(stage)
	_run_channel(stage, ch.id)


func _drop_stage() -> void:
	if stage == null:
		return
	var old := stage
	stage = null
	old.cancelled = true
	old.visible = false
	# free it once its show has run out (a cancelled show returns at once)
	var free_later := func() -> void:
		for i in 30:
			if not is_instance_valid(old) or bool(old.get_meta("done", false)):
				break
			await get_tree().process_frame
		if is_instance_valid(old):
			old.queue_free()
	free_later.call()


func _run_channel(st: TvStage, id: String) -> void:
	await get_tree().create_timer(0.3).timeout
	if st.cancelled:
		st.set_meta("done", true)
		return
	if id == "static":
		# nothing on but snow; once in a long while, not quite nothing
		while not st.cancelled:
			await st.wait(randf_range(4.0, 7.0))
			if st.cancelled or randf() > 0.35:
				continue
			noise.visible = false
			st.visible = true
			st.backdrop("black")
			var l := Art.label("REMAIN CALM", Color("ff5a6e"))
			l.position = Vector2(SW / 2.0 - Art.text_width("REMAIN CALM") / 2.0, 36)
			st.add_child(l)
			Sfx.play("heartbeat", 0.8, -8.0)
			await st.wait(0.12)
			if is_instance_valid(l):
				l.queue_free()
			if not st.cancelled:
				st.visible = false
				noise.visible = true
		st.set_meta("done", true)
		return
	noise.visible = false
	st.visible = true
	while not st.cancelled:
		await TvShows.play(id, st)
		if st.cancelled:
			break
		# station ident, then the show again
		st.clear_set()
		st.caption_off()
		st.backdrop("testcard")
		await st.say("", "%s - back after this." % TvShows.CHANNELS[idx].name if TvShows.CHANNELS[idx].id == id else "", 1.4)
		st.caption_off()
	st.set_meta("done", true)
