class_name Fx
extends Node2D
## Battle effects layer. Everything is drawn with draw_* calls at 320x180, so
## particles, rings, bolts and slashes come out as crisp pixels automatically.

var parts: Array = []
var shapes: Array = []


func _process(delta: float) -> void:
	for i in range(parts.size() - 1, -1, -1):
		var p: Dictionary = parts[i]
		if p.delay > 0.0:
			p.delay -= delta
			continue
		p.t += delta
		if p.t >= p.life:
			parts.remove_at(i)
			continue
		if p.has("orbit"):
			p.ang += p.spin * delta
			p.rad = maxf(0.0, p.rad + p.dr * delta)
			p.oy += p.rise * delta
			p.pos = p.orbit + Vector2(cos(p.ang) * p.rad, sin(p.ang) * p.rad * 0.35 + p.oy)
		else:
			p.vel += p.acc * delta
			p.vel *= pow(p.drag, delta * 60.0)
			if p.wobble > 0.0:
				p.vel.x += sin(p.t * 9.0 + p.seed) * p.wobble * delta
			p.pos += p.vel * delta
	for i in range(shapes.size() - 1, -1, -1):
		var s: Dictionary = shapes[i]
		if s.get("delay", 0.0) > 0.0:
			s.delay -= delta
			continue
		s.t += delta
		if s.t >= s.life:
			shapes.remove_at(i)
	queue_redraw()


func _draw() -> void:
	for s in shapes:
		if s.get("delay", 0.0) > 0.0:
			continue
		var k: float = s.t / s.life
		match s.type:
			"ring":
				var r: float = lerpf(s.r0, s.r1, ease(k, 0.4))
				var c: Color = s.color
				c.a = 1.0 - k * k
				_ellipse(s.pos, r, r * s.squash, c, s.width)
			"slash":
				var a1: float = lerpf(s.a0, s.a1, minf(1.0, k * 2.5))
				var a0: float = lerpf(s.a0, s.a1, clampf(k * 2.5 - 0.7, 0.0, 1.0))
				if a1 != a0:
					var c: Color = s.color
					draw_arc(s.pos, s.radius, a0, a1, 18, Pal.WHITE, s.width + 1.0)
					draw_arc(s.pos, s.radius + s.width, a0, a1, 18, c, 1.0)
					draw_arc(s.pos, s.radius - s.width, a0, a1, 18, Color(c, 0.6), 1.0)
			"line":
				var grow := minf(1.0, k * 4.0)
				var a: Vector2 = s.from
				var b: Vector2 = s.from.lerp(s.to, grow)
				var w: float = s.width * (1.0 - maxf(0.0, k - 0.5) * 2.0)
				if w > 0.3:
					draw_line(a, b, s.color, w + 2.0)
					draw_line(a, b, Pal.WHITE, maxf(1.0, w))
			"bolt":
				if int(s.t * 30.0) != s.get("seed_t", -1):
					s.seed_t = int(s.t * 30.0)
					s.pts = _bolt_points(s.from, s.to)
				var c: Color = s.color
				c.a = 1.0 if k < 0.6 else (1.0 - k) * 2.5
				draw_polyline(s.pts, c, 3.0)
				draw_polyline(s.pts, Color(Pal.WHITE, c.a), 1.0)
			"beam":
				var open := sin(k * PI)
				var w: float = s.width * open
				if w >= 1.0:
					var top: float = s.top
					var r := Rect2(s.x - w / 2.0, top, w, s.bottom - top)
					draw_rect(r, Color(s.color, 0.85))
					draw_rect(Rect2(s.x - w / 4.0, top, w / 2.0, s.bottom - top), Color(Pal.WHITE, 0.95))
			"shard":
				var grow := ease(minf(1.0, k * 4.0), 0.3)
				var h: float = s.height * grow
				if k > 0.75:
					h *= 1.0 - (k - 0.75) * 4.0
				var b: Vector2 = s.pos
				var pts := PackedVector2Array([b + Vector2(-s.width, 0), b + Vector2(-1, -h * 0.75), b + Vector2(s.lean, -h), b + Vector2(1, -h * 0.7), b + Vector2(s.width, 0)])
				draw_colored_polygon(pts, s.color)
				draw_line(b + Vector2(-s.width + 1, -1), b + Vector2(s.lean, -h + 1), s.hi, 1.0)
			"circle":
				var r: float = lerpf(s.r0, s.r1, ease(k, 0.3))
				draw_circle(s.pos, r, Color(s.color, 1.0 - k))
			"rune":
				var c: Color = s.color
				c.a = sin(k * PI)
				var r: float = s.radius * minf(1.0, k * 4.0)
				_ellipse(s.pos, r, r * 0.35, c, 1.0)
				_ellipse(s.pos, r * 0.7, r * 0.7 * 0.35, c, 1.0)
				for j in 6:
					var a: float = s.t * 3.0 + j * TAU / 6.0
					var p: Vector2 = s.pos + Vector2(cos(a) * r * 0.85, sin(a) * r * 0.85 * 0.35)
					draw_rect(Rect2(p.round(), Vector2(2, 2)), Color(Pal.WHITE, c.a))
	for p in parts:
		if p.delay > 0.0:
			continue
		var k: float = p.t / p.life
		var c: Color = (p.color as Color).lerp(p.color2, k)
		var sz: float = lerpf(p.size, p.size_end, k)
		var pos: Vector2 = p.pos.round()
		match p.shape:
			0:
				var s := maxf(1.0, roundf(sz))
				draw_rect(Rect2(pos - Vector2(s, s) * 0.5, Vector2(s, s)).abs(), c)
			1:
				var s := maxi(1, int(sz))
				draw_rect(Rect2(pos + Vector2(-s, 0), Vector2(s * 2 + 1, 1)), c)
				draw_rect(Rect2(pos + Vector2(0, -s), Vector2(1, s * 2 + 1)), c)
			2:
				draw_circle(pos, maxf(0.5, sz), c)
			3:
				var a: float = p.t * 8.0 + p.seed
				var d := Vector2(cos(a), sin(a) * 0.5) * maxf(1.5, sz)
				draw_line(pos - d, pos + d, c, 2.0)


func _ellipse(c: Vector2, rx: float, ry: float, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	var n := clampi(int(rx * 1.5), 12, 48)
	for i in n + 1:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polyline(pts, col, w)


func _bolt_points(a: Vector2, b: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array([a])
	var n := 9
	for i in range(1, n):
		var t := float(i) / n
		var p := a.lerp(b, t)
		p.x += randf_range(-9.0, 9.0)
		pts.append(p)
	pts.append(b)
	return pts


# ------------------------------------------------------------- spawners ----

func particle(pos: Vector2, vel: Vector2, life: float, color: Color, opts: Dictionary = {}) -> Dictionary:
	var p := {
		"pos": pos, "vel": vel, "life": life, "t": 0.0, "color": color,
		"color2": opts.get("color2", Color(color, 0.0)), "acc": opts.get("acc", Vector2.ZERO),
		"drag": opts.get("drag", 1.0), "size": opts.get("size", 1.0), "size_end": opts.get("size_end", opts.get("size", 1.0)),
		"shape": opts.get("shape", 0), "delay": opts.get("delay", 0.0), "wobble": opts.get("wobble", 0.0), "seed": randf() * 10.0,
	}
	parts.append(p)
	return p


func burst(pos: Vector2, n: int, colors: Array, speed: Vector2, life: Vector2, opts: Dictionary = {}) -> void:
	## Radial burst; opts.up biases upward, opts.spread limits the angle cone.
	for i in n:
		var a := randf() * TAU
		if opts.has("dir"):
			a = (opts.dir as float) + randf_range(-1.0, 1.0) * opts.get("spread", 0.6)
		var v := Vector2.from_angle(a) * randf_range(speed.x, speed.y)
		if opts.get("flat", false):
			v.y *= 0.45
		v.y -= opts.get("up", 0.0)
		var o := opts.duplicate()
		o.delay = opts.get("delay", 0.0) + randf() * opts.get("stagger", 0.0)
		particle(pos + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * opts.get("jitter", 0.0), v, randf_range(life.x, life.y), colors[randi() % colors.size()], o)


func orbit(center: Vector2, n: int, colors: Array, radius: Vector2, spin: float, life: float, opts: Dictionary = {}) -> void:
	for i in n:
		var p := particle(center, Vector2.ZERO, life * randf_range(0.7, 1.0), colors[randi() % colors.size()], opts)
		p.orbit = center
		p.ang = randf() * TAU
		p.rad = randf_range(radius.x, radius.y)
		p.dr = opts.get("dr", 0.0)
		p.spin = spin * randf_range(0.8, 1.2)
		p.rise = opts.get("rise", 0.0) * randf_range(0.5, 1.0)
		p.oy = randf_range(-2.0, 2.0)
		p.delay = randf() * opts.get("stagger", 0.0)


func ring(pos: Vector2, r0: float, r1: float, life: float, color: Color, width: float = 1.0, squash: float = 0.4, delay: float = 0.0) -> void:
	shapes.append({"type": "ring", "pos": pos, "r0": r0, "r1": r1, "life": life, "t": 0.0, "color": color, "width": width, "squash": squash, "delay": delay})


func slash(pos: Vector2, radius: float, a0: float, a1: float, life: float, color: Color, width: float = 2.0) -> void:
	shapes.append({"type": "slash", "pos": pos, "radius": radius, "a0": a0, "a1": a1, "life": life, "t": 0.0, "color": color, "width": width})


func line(from: Vector2, to: Vector2, life: float, color: Color, width: float = 2.0) -> void:
	shapes.append({"type": "line", "from": from, "to": to, "life": life, "t": 0.0, "color": color, "width": width})


func bolt(from: Vector2, to: Vector2, life: float, color: Color) -> void:
	shapes.append({"type": "bolt", "from": from, "to": to, "life": life, "t": 0.0, "color": color, "pts": _bolt_points(from, to)})


func beam(x: float, top: float, bottom: float, width: float, life: float, color: Color) -> void:
	shapes.append({"type": "beam", "x": x, "top": top, "bottom": bottom, "width": width, "life": life, "t": 0.0, "color": color})


func shard(base: Vector2, height: float, width: float, life: float, color: Color, delay: float = 0.0) -> void:
	shapes.append({"type": "shard", "pos": base, "height": height, "width": width, "lean": randf_range(-3, 3), "life": life, "t": 0.0, "color": color, "hi": Pal.hi(color), "delay": delay})


func circle(pos: Vector2, r0: float, r1: float, life: float, color: Color) -> void:
	shapes.append({"type": "circle", "pos": pos, "r0": r0, "r1": r1, "life": life, "t": 0.0, "color": color})


func rune(pos: Vector2, radius: float, life: float, color: Color) -> void:
	shapes.append({"type": "rune", "pos": pos, "radius": radius, "life": life, "t": 0.0, "color": color})


func dissolve(img: Image, origin: Vector2, flip: bool = false) -> void:
	## Breaks a sprite into its own pixels, which drift up and fade.
	var w := img.get_width()
	var h := img.get_height()
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var px := (w - 1 - x) if flip else x
			var v := Vector2(randf_range(-14, 14), randf_range(-40, -8))
			particle(origin + Vector2(px, y), v, randf_range(0.5, 1.1), c, {
				"color2": Color(Pal.WHITE, 0.0), "delay": (h - y) / float(h) * 0.35 + randf() * 0.1, "drag": 0.97, "wobble": 30.0})
