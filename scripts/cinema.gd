class_name Cinema
extends Control
## Full-screen story vignettes over the field. Backdrops crossfade, sprites bob,
## and a few procedural effects (the sync rush, a closing vignette, drifting
## stars) play underneath the dialog box.

const VIGNETTE_SHADER := """
shader_type canvas_item;
uniform float radius = 1.2;
uniform vec4 tint : source_color = vec4(0.086, 0.075, 0.122, 1.0);
void fragment() {
	vec2 p = floor(FRAGCOORD.xy);
	vec2 c = vec2(160.0, 90.0);
	vec2 d = (p - c) / vec2(160.0, 130.0);
	float r = length(d);
	float edge = step(radius, r);
	float dither = step(radius - 0.06, r) * step(0.5, fract((p.x + p.y) / 4.0));
	COLOR = vec4(tint.rgb, max(edge, dither));
}
"""

var bg: TextureRect
var back: ColorRect
var actors: Node2D
var drawer: Node2D
var vig: ColorRect
var t := 0.0
var effect := ""
var effect_k := 0.0
var particles: Array = []
var anim_bg := ""
var anim_frames := 0
var anim_fps := 0.0
## Warp field for the "warp" effect: lights stream out from the centre in every
## direction, like the stars when a mission begins. effect_k is the warp speed.
var stars: Array = []


static func open(color: Color = Pal.INK) -> Cinema:
	var c := Cinema.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.back = ColorRect.new()
	c.back.color = color
	c.back.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(c.back)
	c.bg = TextureRect.new()
	c.add_child(c.bg)
	c.drawer = Node2D.new()
	c.add_child(c.drawer)
	c.actors = Node2D.new()
	c.add_child(c.actors)
	c.drawer.draw.connect(c._draw_fx)
	c.vig = ColorRect.new()
	c.vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = VIGNETTE_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("radius", 1.2)
	c.vig.material = mat
	c.add_child(c.vig)
	Game.main.cine_layer.add_child(c)
	return c


func set_vignette(r: float, t_: float = 0.0) -> void:
	var mat := vig.material as ShaderMaterial
	if t_ <= 0.0:
		mat.set_shader_parameter("radius", r)
		return
	var cur = mat.get_shader_parameter("radius")
	var from: float = cur if cur != null else 1.2
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("radius", v), from, r, t_).set_trans(Tween.TRANS_SINE)
	await tw.finished


func show_bg(name: String, frame: int = 0, fade: float = 0.5) -> void:
	var tex := Art.cine(name, frame)
	if fade <= 0.0 or bg.texture == null:
		bg.texture = tex
		bg.modulate.a = 1.0
		if fade > 0.0:
			bg.modulate.a = 0.0
			await create_tween().tween_property(bg, "modulate:a", 1.0, fade).finished
		return
	var nb := TextureRect.new()
	nb.texture = tex
	nb.modulate.a = 0.0
	add_child(nb)
	move_child(nb, bg.get_index() + 1)
	await create_tween().tween_property(nb, "modulate:a", 1.0, fade).finished
	bg.queue_free()
	bg = nb


func show_tex(tex: Texture2D, fade: float = 0.5) -> void:
	bg.texture = tex
	bg.modulate.a = 0.0
	await create_tween().tween_property(bg, "modulate:a", 1.0, fade).finished


func animate_bg(name: String, frames: int, fps: float) -> void:
	anim_bg = name
	anim_frames = frames
	anim_fps = fps


func hide_bg(fade: float = 0.5) -> void:
	anim_bg = ""
	await create_tween().tween_property(bg, "modulate:a", 0.0, fade).finished


func sprite(tex: Texture2D, pos: Vector2, bob: float = 0.0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.position = pos
	if bob > 0.0:
		s.set_meta("bob", bob)
		s.set_meta("y", pos.y)
		s.set_meta("ph", randf() * TAU)
	actors.add_child(s)
	return s


func person(spec: Dictionary, pos: Vector2, dir: int = 0, mood: String = "", pose: String = "walk") -> Sprite2D:
	var s := sprite(Art.person(spec, [0, 1, 2, 2][dir], 0, mood, pose), pos)
	s.flip_h = dir == 3
	s.offset = Vector2(0, -15)
	return s


func clear_sprites() -> void:
	for c in actors.get_children():
		c.queue_free()


func fade_node(n: CanvasItem, a: float, t_: float) -> void:
	await create_tween().tween_property(n, "modulate:a", a, t_).finished


func close(fade: float = 0.5) -> void:
	await create_tween().tween_property(self, "modulate:a", 0.0, fade).finished
	queue_free()


func _process(delta: float) -> void:
	t += delta
	if anim_bg != "":
		bg.texture = Art.cine(anim_bg, int(t * anim_fps) % anim_frames)
	for s in actors.get_children():
		if s.has_meta("bob"):
			s.position.y = s.get_meta("y") + round(sin(t * 1.6 + s.get_meta("ph")) * s.get_meta("bob"))
	for i in range(particles.size() - 1, -1, -1):
		var p: Dictionary = particles[i]
		p.t += delta
		p.pos += p.vel * delta
		if p.t > p.life:
			particles.remove_at(i)
	if effect == "warp":
		_update_warp(delta)
	elif effect == "stars" or effect == "embers":
		_spawn_particles(delta)
	drawer.queue_redraw()


func _update_warp(delta: float) -> void:
	var c := Vector2(160, 90)
	if stars.is_empty():
		for i in 140:
			stars.append(_new_star(c, true))
	for st in stars:
		var v: Vector2 = st.p - c
		var spd: float = (6.0 + effect_k * 300.0) * st.z * (0.35 + v.length() / 90.0)
		st.p += v.normalized() * spd * delta
		if not Rect2(-20, -20, 360, 220).has_point(st.p):
			var fresh: Dictionary = _new_star(c, false)
			st.p = fresh.p
			st.z = fresh.z
			st.c = fresh.c


func _new_star(c: Vector2, anywhere: bool) -> Dictionary:
	var cols := [Pal.SYNC.lerp(Pal.BLUE, 0.3), Pal.SYNC, Pal.LEMON, Pal.WHITE, Pal.WHITE]
	var a := randf() * TAU
	var r := randf_range(4.0, 170.0) if anywhere else randf_range(2.0, 24.0)
	return {"p": c + Vector2(cos(a), sin(a)) * r, "z": randf_range(0.25, 1.0), "c": cols[randi() % cols.size()]}


func _spawn_particles(delta: float) -> void:
	var n := int(effect_k * 60.0 * delta * 10.0) + (1 if randf() < effect_k else 0)
	for i in n:
		match effect:
			"warp":
				var a := randf() * TAU
				var cols := [Pal.SYNC.lerp(Pal.BLUE, 0.3), Pal.LEMON, Pal.WHITE]
				particles.append({"pos": Vector2(160, 90) + Vector2.from_angle(a) * randf_range(4, 30), "vel": Vector2.from_angle(a) * randf_range(120, 420) * effect_k,
					"t": 0.0, "life": 1.2, "c": cols[randi() % 3], "streak": true})
			"stars":
				particles.append({"pos": Vector2(randf() * 320, randf() * 180), "vel": Vector2(-6, 0) * effect_k, "t": 0.0, "life": 3.0, "c": Pal.WHITE, "streak": false})
			"embers":
				particles.append({"pos": Vector2(randf() * 320, 182), "vel": Vector2(randf_range(-6, 6), -randf_range(10, 30)), "t": 0.0, "life": 5.0, "c": Pal.SYNC if randf() < 0.5 else Pal.WHITE, "streak": false})


func _draw_fx() -> void:
	if effect == "warp":
		var c := Vector2(160, 90)
		for st in stars:
			var p: Vector2 = st.p
			var dirv: Vector2 = (p - c).normalized()
			var dist := (p - c).length()
			var length: float = (1.0 + effect_k * 22.0 * st.z) * clampf(dist / 60.0, 0.2, 1.6)
			var col: Color = st.c
			col.a = clampf(0.25 + st.z * 0.75, 0.0, 1.0) * clampf(dist / 20.0, 0.0, 1.0)
			var n := maxi(1, int(length))
			for k in n:
				var q := (p - dirv * k).round()
				var fade := 1.0 - float(k) / n
				drawer.draw_rect(Rect2(q, Vector2.ONE), Color(col, col.a * fade))
	for p in particles:
		var k: float = p.t / p.life
		var c: Color = p.c
		c.a = 1.0 - k
		if p.streak:
			var v: Vector2 = p.vel
			drawer.draw_line(p.pos.round(), (p.pos - v * 0.05).round(), c, 1.0)
		else:
			drawer.draw_rect(Rect2(p.pos.round(), Vector2.ONE), Color(c, sin(k * PI)))
	if effect == "tunnel":
		for i in 6:
			var r := fmod(t * 60.0 * effect_k + i * 30.0, 180.0)
			var col: Color = [Pal.SYNC, Pal.LEMON, Pal.WHITE][i % 3]
			for s in 48:
				var a := s * TAU / 48.0 + i
				if s % 2 == 0:
					drawer.draw_rect(Rect2((Vector2(160, 90) + Vector2(cos(a), sin(a) * 0.6) * r).round(), Vector2(2, 1)), Color(col, r / 180.0))
	if effect == "pulse":
		var r := fmod(t * 40.0, 120.0)
		for s in 64:
			var a := s * TAU / 64.0
			drawer.draw_rect(Rect2((Vector2(160, 90) + Vector2(cos(a), sin(a)) * r).round(), Vector2.ONE), Color(Pal.SYNC, 1.0 - r / 120.0))
