class_name ArtMission
## Planets, threats and space. Planets are lit spheres in four bands with a
## surface pattern sampled in 3D (so rotation frames wrap seamlessly). Drones are
## Greywater-style monsters: chubby lit bodies, an outline, and one big eye that
## always watches the planet.

const PLANET_FRAMES := 32


static func _n3(x: float, y: float, z: float, s: float, seed: float) -> float:
	return Pal.noise(x * s * 9.0 + z * s * 6.0 + seed, y * s * 9.0 - z * s * 4.0, seed * 0.7) * 0.65 \
		+ Pal.noise(z * s * 13.0 - x * s * 5.0, y * s * 13.0 + x * s * 3.0 + seed, seed + 3.0) * 0.35


static func planet(key: String, d: int, frame: int) -> PixBuf:
	var b := PixBuf.new(d + 4, d + 4)
	var r := d / 2.0
	var c0 := Vector2(b.w / 2.0, b.h / 2.0)
	var rot := float(frame) / PLANET_FRAMES * TAU
	var L := Vector3(-0.6, -0.55, 0.58).normalized()
	var atmo := _atmo(key)
	for py in b.h:
		for px in b.w:
			var dx := (px + 0.5 - c0.x) / r
			var dy := (py + 0.5 - c0.y) / r
			var dd := dx * dx + dy * dy
			if dd > 1.0:
				if dd < 1.0 + 3.2 / r and atmo.a > 0.0 and dx < 0.3 and dy < 0.3:
					b.pset(px, py, Color(atmo, 1.0))
				continue
			var nz := sqrt(1.0 - dd)
			var n := Vector3(dx, dy, nz)
			# rotate the surface around the vertical axis
			var sx := dx * cos(rot) + nz * sin(rot)
			var sz := -dx * sin(rot) + nz * cos(rot)
			var col := _surface(key, sx, dy, sz, frame)
			var l := n.dot(L)
			var c := Pal.band(col, l)
			if l < -0.55:
				c = Pal.deep(col).lerp(Pal.INK, 0.35)
			b.img.set_pixel(px, py, c)
	b.outline()
	return b


static func _atmo(key: String) -> Color:
	match key:
		"green_planet": return Pal.SKY.lerp(Pal.SYNC, 0.3)
		"cold_planet": return Pal.FROST
		"hot_planet": return Pal.EMBER.lerp(Pal.ROSE, 0.3)
		"tempestris_planet": return Pal.LILAC.lerp(Pal.SKY, 0.3)
		"viscera_nova_planet": return Pal.ROSE.lerp(Pal.PINK, 0.3)
		"umbra_vacua_planet": return Pal.VOID.lerp(Pal.PLUM, 0.5)
		"metal_planet": return Pal.SYNC.lerp(Pal.STEEL, 0.5)
	return Color(0, 0, 0, 0)


static func _surface(key: String, x: float, y: float, z: float, frame: int) -> Color:
	match key:
		"cold_planet":
			var n := _n3(x, y, z, 1.0, 5.0)
			var c := Pal.FROST if n > -0.1 else Pal.SKY.lerp(Pal.FROST, 0.4)
			if absf(_n3(x, y, z, 2.2, 9.0)) < 0.05:
				c = Pal.STEEL.lerp(Pal.BLUE, 0.4)
			if absf(y) > 0.75:
				c = Pal.WHITE
			return c
		"hot_planet":
			var n := _n3(x, y, z, 1.4, 2.0)
			var c := Pal.BARK.lerp(Pal.INK2, 0.4)
			if n > 0.3:
				c = Pal.WOOD.lerp(Pal.INK2, 0.3)
			var crack := absf(_n3(x, y, z, 1.8, 7.0))
			if crack < 0.06:
				c = Pal.EMBER
			elif crack < 0.11:
				c = Pal.ORANGE.lerp(Pal.RED, 0.4)
			return c
		"metal_planet":
			var lat := asin(clampf(y, -1.0, 1.0))
			var lon := atan2(x, z)
			var c := Pal.STEEL.lerp(Pal.SLATE, 0.3)
			if fmod(absf(lat) * 5.0, 1.0) < 0.12 or fmod(lon * 2.4 + 20.0, 1.0) < 0.1:
				c = Pal.SLATE.lerp(Pal.NAVY, 0.4)
			if Pal.hash2(int(lat * 12.0 + 30), int(lon * 9.0 + 40), 3) > 0.9:
				c = Pal.SYNC
			return c
		"tempestris_planet":
			var band_v := sin(y * 9.0 + _n3(x, y, z, 1.2, 4.0) * 2.5)
			var c := Pal.LILAC if band_v > 0.3 else (Pal.PURPLE if band_v > -0.4 else Pal.SKY.lerp(Pal.LILAC, 0.5))
			var eye := Vector3(x, y, z).distance_to(Vector3(0.5, 0.25, 0.83))
			if eye < 0.22:
				c = Pal.WHITE.lerp(Pal.LILAC, eye * 3.0)
			return c
		"viscera_nova_planet":
			var n := _n3(x, y, z, 1.6, 6.0)
			var c := Pal.ROSE.lerp(Pal.PINK, 0.4) if n > 0.0 else Pal.ROSE.lerp(Pal.PLUM, 0.3)
			var vein := absf(_n3(x, y, z, 2.4, 11.0 + sin(frame * 0.4) * 0.15))
			if vein < 0.045:
				c = Pal.BLOOD
			elif n > 0.55:
				c = Pal.PEACH.lerp(Pal.PINK, 0.4)
			return c
		"umbra_vacua_planet":
			var n := _n3(x, y, z, 1.0, 13.0)
			var c := Pal.INK2.lerp(Pal.PLUM, 0.3) if n > 0.0 else Pal.INK2.lerp(Pal.INK, 0.4)
			if absf(n) < 0.03:
				c = Pal.VOID.lerp(Pal.INK2, 0.5)
			return c
	# green_planet: Terra Virex
	var n := _n3(x, y, z, 1.1, 1.0)
	var c := Pal.BLUE.lerp(Pal.WATER, 0.35)
	if n > 0.12:
		c = Pal.SAGE if n < 0.4 else Pal.GRASS
		if n > 0.62:
			c = Pal.DIRT.lerp(Pal.SAGE, 0.3)
	elif n > 0.05:
		c = Pal.SKY.lerp(Pal.BLUE, 0.3)
	if absf(y) > 0.82:
		c = Pal.FROST
	var cloud := _n3(x + 0.3, y, z, 1.8, 20.0)
	if cloud > 0.48:
		c = Pal.WHITE.lerp(c, 0.25)
	return c


# ---------------------------------------------------------------- threats --

static func sprite_size(kind: String, logical_size: float) -> int:
	var d := int(round(logical_size * 0.37 * 1.45))
	if kind == "asteroid":
		d = int(round(logical_size * 0.37 * 1.5))
	return clampi(d, 8, 22)


static func drone(kind: String, d: int, look: int, frame: int) -> PixBuf:
	## look: 0..7 octant the eye points at (0 = right, 2 = down, ...).
	var pad := 4
	var b := PixBuf.new(d + pad * 2, d + pad * 2)
	var c := Vector2(b.w / 2.0, b.h / 2.0)
	var r := d / 2.0
	var dir := Vector2.from_angle(look * TAU / 8.0)
	var eye_r := maxf(1.8, r * 0.38)
	var f := float(frame % 2)
	match kind:
		"drone_fast":
			var body := Pal.SKY.lerp(Pal.FROST, 0.3)
			var tail := c - dir * r * 1.1
			var nrm := Vector2(-dir.y, dir.x)
			b.poly([c + dir * r * 0.9, c + nrm * r * 0.75, tail, c - nrm * r * 0.75], body)
			b.ball(c.x, c.y, r * 0.7, r * 0.7, body)
			eye_r = maxf(1.6, r * 0.32)
		"drone_tank":
			var body := Pal.SLATE.lerp(Pal.STEEL, 0.4)
			b.ball(c.x, c.y + 1, r, r * 0.9, Pal.shade(body))
			b.ball(c.x, c.y - 1, r * 0.92, r * 0.82, body)
			for k in 6:
				var a := k * TAU / 6.0 + 0.3
				b.rect(c.x + cos(a) * r * 0.78 - 1, c.y + sin(a) * r * 0.7 - 1, 2, 2, Pal.deep(body))
			b.rect(c.x - r * 0.9, c.y + r * 0.35, r * 1.8, 1.5, Pal.LEMON.lerp(Pal.INK2, 0.4))
			eye_r = maxf(2.0, r * 0.3)
		"charger_drone":
			var body := Pal.PEACH.lerp(Pal.ROSE, 0.35)
			var nrm := Vector2(-dir.y, dir.x)
			b.tri(c.x + nrm.x * r * 0.5, c.y + nrm.y * r * 0.5, c.x + dir.x * r * 1.05 + nrm.x * r * 0.8, c.y + dir.y * r * 1.05 + nrm.y * r * 0.8, c.x + dir.x * r * 0.3, c.y + dir.y * r * 0.3, Pal.CREAM)
			b.tri(c.x - nrm.x * r * 0.5, c.y - nrm.y * r * 0.5, c.x + dir.x * r * 1.05 - nrm.x * r * 0.8, c.y + dir.y * r * 1.05 - nrm.y * r * 0.8, c.x + dir.x * r * 0.3, c.y + dir.y * r * 0.3, Pal.CREAM)
			b.ball(c.x, c.y, r * 0.85, r * 0.85, body)
			for k in 3:
				var a := dir.angle() + PI + (k - 1) * 0.6
				b.tri(c.x + cos(a - 0.25) * r * 0.7, c.y + sin(a - 0.25) * r * 0.7, c.x + cos(a + 0.25) * r * 0.7, c.y + sin(a + 0.25) * r * 0.7, c.x + cos(a) * r * 1.25, c.y + sin(a) * r * 1.25, Pal.shade(body))
		"drone_shifter":
			var body := Pal.TEAL.lerp(Pal.MINT, 0.4)
			b.poly([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)], Pal.shade(body))
			b.ball(c.x, c.y, r * 0.72, r * 0.72, body)
			b.pset(int(c.x), int(c.y - r + 1), Pal.SYNC)
			b.pset(int(c.x), int(c.y + r - 2), Pal.SYNC)
		"drone_sine":
			var body := Pal.LILAC.lerp(Pal.PINK, 0.3)
			var back := -dir
			var nrm := Vector2(-dir.y, dir.x)
			for k in 3:
				var o := (k - 1) * r * 0.5
				var p0 := c + back * r * 0.4 + nrm * o
				var wig := sin(f * PI + k * 1.7) * r * 0.35
				var p1 := c + back * r * 1.3 + nrm * (o * 1.3 + wig)
				b.cap(p0.x, p0.y, p1.x, p1.y, 0.7, Pal.shade(body))
			b.ball(c.x, c.y, r * 0.85, r * 0.75, body)
			b.rect(c.x - r * 0.6, c.y + r * 0.2, r * 1.2, 1, Pal.hi(body))
		"circle_shooter_drone":
			var body := Pal.STEEL.lerp(Pal.FROST, 0.35)
			b.ball(c.x, c.y, r, r, body)
			b.ball(c.x, c.y, r * 0.62, r * 0.62, Pal.NAVY.lerp(Pal.INK, 0.2))
			for k in 8:
				var a := k * TAU / 8.0 + f * 0.4
				b.rect(c.x + cos(a) * r * 0.82 - 1, c.y + sin(a) * r * 0.82 - 1, 2, 2, Pal.SYNC if k % 2 == int(f) else Pal.deep(body))
			var tip := c + dir * r * 0.95
			b.cap(c.x, c.y, tip.x, tip.y, 1.3, Pal.SLATE)
			eye_r = maxf(1.8, r * 0.3)
		"spiral_drone":
			var body := Pal.SKY.lerp(Pal.FROST, 0.45)
			b.ball(c.x, c.y, r, r * 0.92, body)
			var a0 := f * 0.8
			for k in 26:
				var t := k / 26.0
				var a := a0 + t * TAU * 1.5
				var rr := r * (0.15 + t * 0.75)
				b.pset(int(c.x + cos(a) * rr), int(c.y + sin(a) * rr * 0.92), Pal.shade(body).lerp(Pal.BLUE, 0.3))
			eye_r = maxf(1.6, r * 0.26)
		_:
			# drone_basic: a round watcher with stubby fins
			var body := Pal.STONE.lerp(Pal.LILAC, 0.3)
			var nrm := Vector2(-dir.y, dir.x)
			for s in [-1.0, 1.0]:
				var fin: Vector2 = c + nrm * s * r * 0.95 - dir * r * 0.2
				b.ball(fin.x, fin.y, r * 0.35, r * 0.35, Pal.shade(body))
			b.ball(c.x, c.y, r * 0.88, r * 0.88, body)
			var ant := c - dir * r * 1.15
			b.line(int(c.x - dir.x * r * 0.7), int(c.y - dir.y * r * 0.7), int(ant.x), int(ant.y), Pal.INK2)
			b.pset(int(ant.x), int(ant.y), Pal.BLOOD if f == 0.0 else Pal.EMBER)
	# the eye
	var ec := c + dir * r * (0.22 if kind != "drone_fast" else 0.35)
	if kind == "drone_tank":
		b.rect(ec.x - eye_r, ec.y - 1, eye_r * 2, 3, Pal.INK)
		b.rect(ec.x - 1 + dir.x * eye_r * 0.5, ec.y - 1, 2, 2, Pal.BLOOD)
	else:
		b.circ(ec.x, ec.y, eye_r, Pal.WHITE)
		var pc := ec + dir * eye_r * 0.45
		var pr := maxf(0.9, eye_r * 0.55)
		var iris := Pal.BLOOD if kind == "charger_drone" else (Pal.VOID if kind == "drone_sine" else Pal.INK)
		b.circ(pc.x, pc.y, pr, iris)
		b.pset(int(pc.x), int(pc.y), Pal.INK)
		b.pset(int(ec.x - eye_r * 0.4), int(ec.y - eye_r * 0.5), Pal.WHITE)
	b.outline()
	return b


static func asteroid(d: int, v: int, frame: int) -> PixBuf:
	var b := PixBuf.new(d + 4, d + 4)
	var c := Vector2(b.w / 2.0, b.h / 2.0)
	var r := d / 2.0
	var pts := []
	for k in 9:
		var a := k * TAU / 9.0 + frame * TAU / 16.0
		var rr := r * (0.78 + Pal.hash2(k, v, 3) * 0.28)
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	var rock := Pal.STONE.lerp(Pal.WOOD, 0.35)
	b.poly(pts, rock)
	b.recolor(func(x: int, y: int, col: Color) -> Color:
		var nx := (x + 0.5 - c.x) / r
		var ny := (y + 0.5 - c.y) / r
		var l := -nx * 0.7 - ny * 0.7
		var o := Pal.band(rock, l * 1.2 + 0.2)
		if Pal.hash2(x + frame * 3, y, v) > 0.88:
			o = Pal.shade(o)
		return o)
	for k in 2:
		var a := frame * TAU / 16.0 + k * 2.4 + v
		var cp := c + Vector2(cos(a), sin(a)) * r * 0.35
		b.circ(cp.x, cp.y, maxf(1.0, r * 0.22), Pal.deep(rock))
	b.outline()
	return b


static func spawn_portal(d: int, frame: int) -> PixBuf:
	var b := PixBuf.new(d, d)
	var c := d / 2.0
	for k in 16:
		var a := k * TAU / 16.0 + frame * 0.5
		var rr := c - 1.0 - (k % 2)
		b.pset(int(c + cos(a) * rr), int(c + sin(a) * rr), Pal.SYNC if k % 2 == 0 else Pal.WHITE)
	b.circ(c, c, c * 0.35, Pal.SYNC.lerp(Pal.WHITE, 0.5))
	return b


# ----------------------------------------------------------------- space ---

const BAYER := [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


static func nebula_colors(key: String) -> Array:
	match key:
		"cold_planet": return [Color("0f1420"), Color("172338"), Color("23324a")]
		"hot_planet": return [Color("150c14"), Color("2a1220"), Color("41201e")]
		"metal_planet": return [Color("0e1218"), Color("161e2a"), Color("1f2a36")]
		"tempestris_planet": return [Color("120e1e"), Color("201734"), Color("2f2348")]
		"viscera_nova_planet": return [Color("150b13"), Color("2a1222"), Color("3d1a2c")]
		"umbra_vacua_planet": return [Color("0b0a10"), Color("110e18"), Color("181424")]
	return [Color("0e1119"), Color("131b2b"), Color("1b2a3a")]


static func space(w: int, h: int, key: String) -> PixBuf:
	var b := PixBuf.new(w, h)
	var cols := nebula_colors(key)
	for y in h:
		for x in w:
			var n := Pal.noise(x * 0.9, y * 0.9, 4.0 + key.length()) * 0.6 + Pal.noise(x * 2.3, y * 2.1, 9.0) * 0.4
			var t := clampf((n + 0.6) / 1.4, 0.0, 0.999) * (cols.size() - 1)
			var i := int(t)
			var f := t - i
			var c: Color = cols[i] if f * 16.0 <= BAYER[y % 4][x % 4] else cols[mini(i + 1, cols.size() - 1)]
			b.img.set_pixel(x, y, c)
	for i in int(w * h / 90):
		var x := int(Pal.hash2(i, 1, key.length()) * w)
		var y := int(Pal.hash2(i, 2, key.length()) * h)
		b.pset(x, y, Pal.WHITE.lerp(cols[0], 0.35 + Pal.hash2(i, 3) * 0.5))
	return b


static func star(kind: int) -> PixBuf:
	var b := PixBuf.new(5, 5)
	match kind:
		0:
			b.pset(2, 2, Pal.WHITE)
		1:
			b.pset(2, 2, Pal.WHITE)
			b.pset(1, 2, Pal.SKY)
			b.pset(3, 2, Pal.SKY)
			b.pset(2, 1, Pal.SKY)
			b.pset(2, 3, Pal.SKY)
		_:
			b.ascii(["..X..", "..X..", "XXWXX", "..X..", "..X.."], {"X": Pal.SYNC.lerp(Pal.WHITE, 0.4), "W": Pal.WHITE})
	return b
