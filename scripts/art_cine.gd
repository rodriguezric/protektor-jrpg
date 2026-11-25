class_name ArtCine
## Full-screen story vignettes (320x180), painted with the same tools, palette
## and dithering as everything else. Moving parts are added by Cinema.

const W := 320
const H := 180
const BAYER := [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


static func make(name: String, frame: int) -> PixBuf:
	match name:
		"table": return table()
		"letter": return letter(frame)
		"city": return city(frame)
		"city_frame": return city_frame()
		"badge_bg": return badge_bg()
		"badge": return badge(frame)
		"horizon": return horizon()
		"chamber": return chamber(frame)
		"cradle": return cradle()
		"remote": return remote_world(frame)
		"kitchen": return kitchen()
		"ascend": return ascend()
		"academy_ext": return academy_ext()
		"transport_sky": return transport_sky()
		"studio": return studio()
	return PixBuf.new(W, H)


static func gradient(b: PixBuf, cols: Array, y0: int = 0, y1: int = H) -> void:
	for y in range(y0, y1):
		for x in W:
			var t := clampf(float(y - y0) / (y1 - y0), 0.0, 0.999) * (cols.size() - 1)
			var i := int(t)
			var f := t - i
			b.img.set_pixel(x, y, cols[i] if f * 16.0 <= BAYER[y % 4][x % 4] else cols[mini(i + 1, cols.size() - 1)])


static func stars(b: PixBuf, n: int, y1: int, seed: int) -> void:
	for i in n:
		var x := int(Pal.hash2(i, 1, seed) * W)
		var y := int(Pal.hash2(i, 2, seed) * y1)
		b.pset(x, y, Pal.WHITE.lerp(Pal.NAVY, Pal.hash2(i, 3, seed) * 0.7))


static func ridge(b: PixBuf, base: int, amp: float, freq: float, ph: float, c: Color, top_c: Color = Color(0, 0, 0, 0)) -> void:
	for x in W:
		var top := int(base - absf(sin(x * freq + ph)) * amp - sin(x * freq * 3.1 + ph) * amp * 0.25)
		for y in range(top, H):
			b.pset(x, y, c)
		if top_c.a > 0.0:
			b.pset(x, top, top_c)


# ----------------------------------------------------------------- scenes --

static func table() -> PixBuf:
	var b := PixBuf.new(W, H)
	var wood := Pal.WOOD.lerp(Pal.PEACH, 0.2)
	for y in H:
		for x in W:
			var row := y / 9
			var c := wood.lerp(Pal.BARK, Pal.hash2(row, (x + row * 37) / 70, 2) * 0.3)
			if y % 9 == 0 or (x + row * 37) % 70 == 0:
				c = Pal.shade(wood)
			elif sin(x * 0.08 + y * 0.9 + Pal.noise(x, y) * 3.0) > 0.92:
				c = c.lerp(Pal.BARK, 0.25)
			b.img.set_pixel(x, y, c)
	# warm lamp pool + vignette
	for y in H:
		for x in W:
			var d := Vector2((x - 160) / 170.0, (y - 80) / 110.0).length()
			if d > 0.75 and Pal.hash2(x, y) < (d - 0.75) * 2.5:
				b.img.set_pixel(x, y, b.img.get_pixel(x, y).lerp(Pal.INK, 0.5))
	b.ell(256, 140, 18, 9, Pal.shade(Pal.BLUE))
	b.ball(256, 136, 14, 7, Pal.BLUE.lerp(Pal.SKY, 0.3))
	b.ell(256, 134, 10, 4, Pal.BARK)
	return b


static func letter(frame: int) -> PixBuf:
	## The Helion letter. frame 1: crumpled.
	var b := PixBuf.new(160, 112)
	b.rect(4, 4, 152, 104, Pal.WHITE)
	b.rect(4, 4, 152, 2, Pal.hi(Pal.WHITE))
	b.rect(4, 50, 152, 1, Pal.CREAM)
	ArtProps._emblem(b, 74, 10, Pal.NAVY, Pal.SYNC.lerp(Pal.BLUE, 0.4))
	b.rect(56, 20, 48, 2, Pal.NAVY)
	for i in 9:
		var y := 28 + i * 8 + (4 if i > 2 else 0)
		var len := 120 - int(Pal.hash2(i, 4) * 40)
		for x in range(16, 16 + len):
			if Pal.hash2(x / 3, i, 7) > 0.18 and x % 23 != 0:
				b.pset(x, y, Pal.SLATE.lerp(Pal.WHITE, 0.25))
	b.rect(100, 96, 40, 1, Pal.SLATE)
	b.line(102, 94, 112, 91, Pal.NAVY)
	b.line(112, 91, 120, 95, Pal.NAVY)
	b.rect(18, 90, 22, 10, Pal.RED.lerp(Pal.ROSE, 0.3))
	b.ascii(["X.X.X", ".XXX.", "XXXXX"], {"X": Pal.hi(Pal.RED)}, 26, 92)
	if frame == 1:
		for k in 6:
			var x := 6 + k * 3
			b.line(x, 8 + k * 9, x + 10, 20 + k * 11, Pal.CREAM.lerp(Pal.STONE, 0.4))
			b.line(153 - k * 3, 12 + k * 10, 143 - k * 3, 26 + k * 9, Pal.CREAM.lerp(Pal.STONE, 0.4))
	b.outline()
	return b


static func city(frame: int) -> PixBuf:
	var b := PixBuf.new(W, H)
	gradient(b, [Color("0d0f1c"), Color("16203a"), Color("2a3050"), Color("3a3048")], 0, 130)
	stars(b, 60, 70, 3)
	# the shield grid breathing over the block
	for x in W:
		for y in 110:
			var wave := sin((x * 0.05 + y * 0.12) - frame * 0.5)
			if ((x + y * 2) % 23 == 0 or (x * 2 - y + 400) % 31 == 0) and wave > -0.2:
				b.pset(x, y, b.pget(x, y).lerp(Pal.SYNC, 0.25 + 0.25 * maxf(0.0, wave)))
	ridge(b, 120, 30, 0.05, 1.0, Color("1a1a2a"))
	for k in 22:
		var bx := k * 15 + int(Pal.hash2(k, 1) * 6)
		var bh := 30 + int(Pal.hash2(k, 2) * 60)
		var bw := 10 + int(Pal.hash2(k, 3) * 8)
		b.rect(bx, H - bh, bw, bh, Pal.INK2.lerp(Pal.INK, 0.4 + Pal.hash2(k, 4) * 0.3))
		for wy in range(H - bh + 4, H - 4, 5):
			for wx in range(bx + 2, bx + bw - 2, 3):
				if Pal.hash2(wx, wy, k) > 0.6:
					b.pset(wx, wy, Pal.LEMON.lerp(Pal.HONEY, Pal.hash2(wx, wy) * 0.6))
	return b


static func city_frame() -> PixBuf:
	## The window frame alone, layered over the view so things outside pass
	## behind it.
	var b := PixBuf.new(W, H)
	b.rect(0, 0, W, 10, Pal.WOOD)
	b.rect(0, H - 14, W, 14, Pal.WOOD)
	b.rect(0, 0, 10, H, Pal.WOOD)
	b.rect(W - 10, 0, 10, H, Pal.WOOD)
	b.rect(156, 0, 8, H, Pal.WOOD)
	b.rect(0, H - 14, W, 2, Pal.hi(Pal.WOOD))
	b.rect(10, 10, 146, 1, Pal.shade(Pal.WOOD))
	b.rect(164, 10, 146, 1, Pal.shade(Pal.WOOD))
	return b


static func studio() -> PixBuf:
	## The studio card's backdrop: deep ink with a faint navy breath in the
	## middle, falling to ink at the edges in grainy dither.
	var b := PixBuf.new(W, H)
	gradient(b, [Color("0d0f1c"), Color("141a2a"), Color("0d0f1c")])
	for y in H:
		for x in W:
			var d := Vector2((x - 160) / 180.0, (y - 90) / 110.0).length()
			if d > 0.55 and Pal.hash2(x, y, 11) < (d - 0.55) * 2.2:
				b.img.set_pixel(x, y, Pal.INK)
	return b


static func badge_bg() -> PixBuf:
	## The badge presented on its own: a dark field, a soft cone of light from
	## above and a pool of light on the surface where it hovers.
	var b := PixBuf.new(W, H)
	gradient(b, [Color("141a28"), Color("1a2234"), Color("202a40")])
	var c := Vector2(160, 100)
	for y in H:
		for x in W:
			var d := Vector2((x - c.x) / 120.0, (y - c.y) / 90.0).length()
			var cone := absf(x - c.x) < 24.0 + y * 0.35 and y < c.y
			var k := 0.0
			if d < 1.0:
				k = (1.0 - d) * 0.35
			if cone:
				k += 0.08
			if k > 0.0 and k * 16.0 > BAYER[y % 4][x % 4]:
				b.img.set_pixel(x, y, b.img.get_pixel(x, y).lerp(Pal.NAVY.lerp(Pal.SYNC, 0.25), 0.55))
	# a lit pool on the surface below, and the badge's shadow within it
	b.ell(160, 154, 64, 10, Color("28344c"))
	b.ell(160, 154, 46, 7, Color("2e3c56"))
	b.ell(160, 154, 26, 4, Color("1a2234"))
	return b


static func badge(frame: int) -> PixBuf:
	var b := PixBuf.new(72, 72)
	var glow := frame > 0
	b.ball(36, 36, 32, 32, Pal.STEEL)
	b.ball(36, 36, 27, 27, Pal.SLATE.lerp(Pal.STEEL, 0.5))
	for k in 24:
		var a := k * TAU / 24.0
		b.rect(36 + cos(a) * 30 - 1, 36 + sin(a) * 30 - 1, 2, 2, Pal.SYNC if glow and k % 2 == 0 else Pal.deep(Pal.STEEL))
	b.ascii(["..XXX..", ".X...X.", "X..S..X", "X.SSS.X", "X..S..X", ".X...X.", "..XXX.."], {"X": Pal.deep(Pal.STEEL), "S": Pal.SYNC if glow else Pal.SLATE}, 33, 14)
	# nameplate: wide enough for an eight-letter name, recessed into the metal
	b.rect(9, 44, 54, 11, Pal.deep(Pal.STEEL))
	b.rect(9, 54, 54, 1, Pal.hi(Pal.STEEL))
	if glow:
		b.circ(36, 36, 4, Pal.SYNC)
	b.outline()
	return b


static func horizon() -> PixBuf:
	var b := PixBuf.new(W, H)
	gradient(b, [Color("0b0d18"), Color("15203a"), Color("233a5a"), Color("3d5a78")], 0, 120)
	stars(b, 80, 80, 9)
	ridge(b, 125, 34, 0.035, 0.4, Pal.PLUM.lerp(Pal.NAVY, 0.4), Pal.LILAC)
	ridge(b, 140, 22, 0.06, 2.1, Pal.NAVY.lerp(Pal.INK, 0.3), Pal.SKY)
	ridge(b, 158, 10, 0.1, 0.7, Pal.INK2)
	# shield dome over the mountains
	for k in 360:
		var a := PI + k * PI / 360.0
		for r in [140, 141]:
			var p: Vector2 = Vector2(160, 170) + Vector2(cos(a), sin(a) * 0.75) * r
			if k % 9 < 6:
				b.pset(int(p.x), int(p.y), Pal.SYNC.lerp(Pal.WHITE, 0.2 if r == 140 else 0.0))
	for i in 20:
		var a := PI + 0.2 + i * 0.13
		var p := Vector2(160, 170) + Vector2(cos(a), sin(a) * 0.75) * (165 + Pal.hash2(i, 5) * 20)
		b.ball(p.x, p.y, 1.5 + Pal.hash2(i, 6) * 2.5, 1.5 + Pal.hash2(i, 6) * 2.0, Pal.STONE.lerp(Pal.WOOD, 0.3))
	return b


static func chamber(frame: int) -> PixBuf:
	## The synchronization chamber: one pod, cables, and too much light.
	var b := PixBuf.new(W, H)
	gradient(b, [Color("0d1220"), Color("152238"), Color("1e3048")])
	for x in range(0, W, 24):
		b.rect(x, 0, 2, H, Pal.NAVY.lerp(Pal.INK, 0.2))
	for k in 7:
		var x0 := 20 + k * 46
		for t in 40:
			var tt := t / 40.0
			b.pset(int(lerpf(x0, 160 + (k - 3) * 6, tt)), int(10 + sin(tt * PI) * 30 + tt * 60), Pal.TEAL.lerp(Pal.SYNC, 0.3 if (t + frame) % 5 == 0 else 0.0))
	b.ball(160, 112, 46, 54, Pal.STEEL)
	b.ball(160, 110, 36, 44, Pal.NAVY.lerp(Pal.INK, 0.3))
	b.ball(160, 110, 33, 41, Pal.SYNC.lerp(Pal.NAVY, 0.55))
	b.ell(160, 172, 70, 8, Pal.SLATE)
	b.outline()
	return b


static func cradle() -> PixBuf:
	var b := PixBuf.new(W, H)
	gradient(b, [Color("e3e7ea"), Color("c7cfd6"), Color("a9b3be")])
	for y in range(120, H):
		for x in W:
			var c := Pal.FROST if ((x / 16) + (y / 16)) % 2 == 0 else Pal.FROST.lerp(Pal.STEEL, 0.2)
			b.img.set_pixel(x, y, c)
	b.rect(0, 118, W, 3, Pal.STEEL)
	b.rect(96, 100, 128, 40, Pal.STEEL)
	b.rect(98, 96, 124, 12, Pal.WHITE)
	b.rect(98, 104, 124, 20, Pal.SKY.lerp(Pal.FROST, 0.5))
	b.rect(98, 104, 124, 2, Pal.hi(Pal.SKY))
	b.rect(104, 140, 6, 22, Pal.SLATE)
	b.rect(210, 140, 6, 22, Pal.SLATE)
	b.rect(240, 40, 30, 60, Pal.STEEL)
	b.rect(244, 46, 22, 16, Pal.PANEL2)
	for x in range(246, 264):
		b.pset(x, 54 + (2 if x % 6 == 0 else 0), Pal.GLOW)
	b.outline()
	return b


static func remote_world(frame: int) -> PixBuf:
	var b := PixBuf.new(W, H)
	gradient(b, [Color("1d1430"), Color("3a2448"), Color("6a3a50"), Color("a8664a")], 0, 130)
	stars(b, 50, 60, 21)
	b.ball(62, 38, 14, 14, Pal.CREAM.lerp(Pal.PEACH, 0.3))
	b.ball(92, 26, 6, 6, Pal.LILAC.lerp(Pal.WHITE, 0.3))
	ridge(b, 118, 20, 0.03, 1.4, Pal.PLUM.lerp(Pal.INK2, 0.3))
	ridge(b, 134, 10, 0.07, 0.2, Pal.SAGE.lerp(Pal.INK2, 0.5), Pal.SAGE)
	for y in range(140, H):
		for x in W:
			b.pset(x, y, Pal.GRASS.lerp(Pal.INK2, 0.35 + Pal.noise(x, y) * 0.1))
	# a small house with one lit window
	b.rect(214, 108, 44, 32, Pal.WOOD)
	b.poly([Vector2(208, 110), Vector2(264, 110), Vector2(236, 92)], Pal.ROSE.lerp(Pal.INK2, 0.4))
	b.rect(222, 118, 10, 9, Pal.LEMON if frame % 2 == 0 else Pal.LEMON.lerp(Pal.HONEY, 0.4))
	b.rect(240, 122, 9, 18, Pal.BARK)
	b.rect(214, 139, 44, 1, Pal.shade(Pal.WOOD))
	b.outline()
	return b


static func kitchen() -> PixBuf:
	## Midas's memory: his mother in the kitchen doorway, in the colour of old photos.
	var b := PixBuf.new(W, H)
	gradient(b, [Color("6b5440"), Color("8a6c50"), Color("a8865c")])
	b.rect(110, 20, 100, 150, Pal.BARK)
	b.rect(116, 26, 88, 144, Color("d8b880"))
	b.rect(116, 26, 88, 2, Pal.hi(Color("d8b880")))
	b.rect(30, 90, 70, 60, Pal.WOOD)
	b.rect(30, 88, 70, 4, Pal.CREAM)
	b.ell(60, 86, 8, 3, Pal.BLUE.lerp(Pal.SKY, 0.4))
	b.rect(56, 78, 8, 8, Pal.BLUE.lerp(Pal.SKY, 0.4))
	b.pset(57, 79, Pal.WHITE)
	b.rect(230, 70, 60, 80, Pal.STONE.lerp(Pal.HONEY, 0.4))
	b.rect(236, 80, 20, 14, Pal.EMBER.lerp(Pal.HONEY, 0.5))
	var cx := 160
	var skin := Pal.SKIN2
	b.ball(cx, 128, 22, 36, Pal.ROSE.lerp(Pal.HONEY, 0.4))
	b.rect(cx - 12, 114, 24, 30, Pal.CREAM)
	b.ball(cx, 72, 15, 16, skin)
	b.ball(cx, 62, 17, 11, Pal.BARK.lerp(Pal.INK2, 0.3))
	b.ball(cx + 6, 50, 6, 5, Pal.BARK.lerp(Pal.INK2, 0.3))
	b.rect(cx - 7, 72, 4, 2, Pal.INK2)
	b.rect(cx + 3, 72, 4, 2, Pal.INK2)
	b.line(cx - 3, 80, cx + 3, 80, Pal.ROSE)
	b.pset(cx - 4, 79, Pal.ROSE)
	b.pset(cx + 4, 79, Pal.ROSE)
	b.ball(cx - 8, 78, 3, 2, Pal.WHITE)
	b.outline()
	# sepia wash
	b.recolor(func(x: int, y: int, c: Color) -> Color:
		var l := c.get_luminance()
		return Color(l * 1.05 + 0.08, l * 0.9 + 0.04, l * 0.7, 1.0).lerp(c, 0.25))
	return b


static func ascend() -> PixBuf:
	var b := PixBuf.new(W, H)
	gradient(b, [Color("05060c"), Color("0c1020"), Color("161c34")])
	stars(b, 180, H, 33)
	for y in range(100, H):
		for x in W:
			var dx := (x - 160) / 260.0
			var dy := (y - 360) / 260.0
			if dx * dx + dy * dy < 1.0:
				var n := ArtMission._surface("green_planet", dx, dy, sqrt(maxf(0.0, 1.0 - dx * dx - dy * dy)), 0)
				var l := 1.0 - (y - 100) / 160.0
				b.pset(x, y, Pal.band(n, l - 0.2))
			elif dx * dx + dy * dy < 1.03:
				b.pset(x, y, Pal.SKY.lerp(Pal.SYNC, 0.5))
	return b


static func academy_ext() -> PixBuf:
	## The Academy at night: a stepped concrete block with a beacon tower,
	## floodlit walls and searchlights, the lit gate at the end of a long
	## plaza. Lit from the upper left, four bands per surface.
	var b := PixBuf.new(W, H)
	gradient(b, [Color("080a14"), Color("111a30"), Color("1c2c4a"), Color("2e4262")], 0, 122)
	stars(b, 110, 96, 41)
	# a transport crossing high up, nav light blinking
	b.rect(38, 28, 9, 2, Pal.INK2)
	b.rect(41, 27, 3, 1, Pal.INK2)
	b.pset(47, 28, Pal.BLOOD)
	# searchlights sweeping up from the roof
	_beam(b, Vector2(132, 46), Vector2(60, -10), 18.0, 0.4)
	_beam(b, Vector2(188, 46), Vector2(272, -6), 16.0, 0.34)
	# mountains: far (rim lit), near
	ridge(b, 112, 26, 0.03, 1.2, Pal.PLUM.lerp(Pal.NAVY, 0.5), Pal.LILAC.lerp(Pal.NAVY, 0.3))
	ridge(b, 124, 12, 0.07, 2.6, Pal.NAVY.lerp(Pal.INK, 0.45), Pal.SLATE.lerp(Pal.NAVY, 0.4))
	# the plaza
	for y in range(122, H):
		for x in W:
			var c := Pal.ASPHALT.lerp(Pal.INK, 0.35 + (H - y) / 140.0)
			if (x + y * 3) % 23 == 0 and Pal.hash2(x, y, 3) > 0.5:
				c = Pal.shade(c)
			b.pset(x, y, c)
	# light spilling from the gate down the plaza
	for y in range(131, H):
		var half := 12 + (y - 131) * 0.9
		for x in range(int(160 - half), int(160 + half)):
			var k := 0.55 - (y - 131) / 70.0 - absf(x - 160) / half * 0.35
			if k * 16.0 > BAYER[y % 4][x % 4]:
				b.pset(x, y, b.pget(x, y).lerp(Pal.SYNC.lerp(Pal.STEEL, 0.5), 0.35))
	# the long path to the gate, edged with lamps
	for y in range(132, H):
		var half := 6 + (y - 132) * 0.45
		for x in range(int(160 - half), int(160 + half)):
			if x == int(160 - half) or x == int(160 + half) - 1:
				b.pset(x, y, Pal.SLATE.lerp(Pal.INK, 0.2))
			elif (y - 132) % 6 == 0:
				b.pset(x, y, b.pget(x, y).lerp(Pal.INK, 0.25))
	for i in 4:
		for side in [-1, 1]:
			var ly := 140 + i * 9
			var lx := int(160 + side * (12 + (ly - 132) * 0.45 + 3 + i))
			b.rect(lx, ly - 6 - i, 1, 6 + i, Pal.SLATE)
			b.pset(lx, ly - 7 - i, Pal.LEMON)
			_glow(b, lx, ly - 7 - i, 3 + i / 2, Pal.LEMON, 0.35)
	# perimeter wall with floodlit pylons
	var wall := Pal.STEEL.lerp(Pal.NAVY, 0.55)
	b.rect(0, 120, W, 11, wall)
	b.rect(0, 120, W, 1, Pal.hi(wall))
	b.rect(0, 129, W, 2, Pal.deep(wall))
	for x in range(6, W, 26):
		if absi(x + 3 - 160) < 22:
			continue
		b.rect(x, 114, 6, 17, Pal.shade(wall))
		b.rect(x, 114, 1, 17, wall)
		b.rect(x, 114, 6, 1, Pal.hi(wall))
		b.rect(x + 1, 112, 4, 2, Pal.INK2)
		b.pset(x + 2, 112, Pal.LEMON)
		b.pset(x + 3, 112, Pal.LEMON)
		_glow(b, x + 3, 113, 5, Pal.LEMON, 0.25)
	# the building: two wings, the main block, the tower
	_block(b, Rect2i(54, 78, 68, 42), 9, 7)
	_block(b, Rect2i(198, 78, 68, 42), 9, 7)
	_block(b, Rect2i(114, 54, 92, 66), 8, 6)
	_block(b, Rect2i(122, 46, 76, 9), 0, 0)
	_block(b, Rect2i(146, 22, 28, 25), 7, 5)
	# setbacks: rooftop edges and vents
	for vx in [64, 92, 210, 240]:
		b.rect(vx, 74, 8, 4, Pal.SLATE.lerp(Pal.INK, 0.4))
		b.rect(vx, 74, 8, 1, Pal.SLATE)
	# antenna spire and beacon
	b.tri(154, 22, 166, 22, 160, 8, Pal.STEEL.lerp(Pal.NAVY, 0.3))
	b.line(160, 8, 160, 22, Pal.hi(Pal.STEEL))
	b.rect(159, 4, 2, 5, Pal.SLATE)
	_glow(b, 160, 4, 8, Pal.SYNC, 0.5)
	b.circ(160, 4, 2, Pal.SYNC)
	b.pset(160, 3, Pal.WHITE)
	# banners either side of the seal
	for bx in [130, 182]:
		b.rect(bx, 58, 8, 30, Pal.RED.lerp(Pal.ROSE, 0.35))
		b.rect(bx, 58, 1, 30, Pal.RED.lerp(Pal.WHITE, 0.15))
		b.rect(bx + 7, 58, 1, 30, Pal.deep(Pal.RED))
		b.rect(bx, 58, 8, 2, Pal.HONEY)
		b.tri(bx, 88, bx + 8, 88, bx + 4, 92, Pal.RED.lerp(Pal.ROSE, 0.35))
		b.rect(bx + 3, 66, 2, 2, Pal.HONEY)
	# the seal over the gate
	b.circ(160, 72, 8, Pal.NAVY.lerp(Pal.INK, 0.3))
	ArtProps._emblem(b, 157, 69, Pal.HONEY, Pal.SYNC)
	_glow(b, 160, 72, 12, Pal.SYNC, 0.15)
	# the gate: a tall lit arch, steps down to the plaza
	b.rect(148, 96, 24, 24, Pal.deep(Pal.STEEL))
	b.rect(150, 98, 20, 22, Pal.SYNC.lerp(Pal.NAVY, 0.45))
	b.rect(150, 98, 20, 6, Pal.SYNC.lerp(Pal.WHITE, 0.1).lerp(Pal.NAVY, 0.25))
	b.rect(159, 98, 2, 22, Pal.NAVY.lerp(Pal.INK, 0.3))
	b.rect(146, 94, 28, 2, Pal.hi(Pal.STEEL))
	for k in 4:
		b.rect(146 - k * 2, 120 + k * 3, 28 + k * 4, 3, Pal.STEEL.lerp(Pal.NAVY, 0.3 + k * 0.1))
		b.rect(146 - k * 2, 120 + k * 3, 28 + k * 4, 1, Pal.hi(Pal.STEEL.lerp(Pal.NAVY, 0.3 + k * 0.1)))
	# low mist along the foot of the wall
	for y in range(124, 136):
		for x in W:
			var k := 0.3 - absf(y - 129) / 20.0 + sin(x * 0.05 + y) * 0.08
			if k * 16.0 > BAYER[y % 4][x % 4]:
				b.pset(x, y, b.pget(x, y).lerp(Pal.SKY, 0.3))
	return b


static func _block(b: PixBuf, r: Rect2i, row_h: int, col_w: int) -> void:
	## One concrete mass of the Academy: lit top edge and left face, a
	## shaded right return, ribs, and rows of mostly dark windows.
	var base := Pal.STEEL.lerp(Pal.NAVY, 0.45)
	b.rect(r.position.x, r.position.y, r.size.x, r.size.y, base)
	b.rect(r.position.x, r.position.y, r.size.x, 1, Pal.hi(base))
	b.rect(r.position.x, r.position.y + 1, 1, r.size.y - 1, base.lerp(Pal.hi(base), 0.5))
	b.rect(r.end.x - 4, r.position.y + 1, 4, r.size.y - 1, Pal.shade(base))
	b.rect(r.end.x - 1, r.position.y + 1, 1, r.size.y - 1, Pal.deep(base))
	b.rect(r.position.x, r.end.y - 2, r.size.x, 2, Pal.shade(base))
	if row_h == 0:
		return
	for x in range(r.position.x + col_w, r.end.x - 4, col_w * 2):
		b.rect(x, r.position.y + 3, 1, r.size.y - 5, Pal.shade(base))
	for y in range(r.position.y + 4, r.end.y - 5, row_h):
		b.rect(r.position.x + 2, y + 3, r.size.x - 6, 1, Pal.shade(base).lerp(base, 0.4))
		for x in range(r.position.x + 3, r.end.x - 7, col_w):
			var h := Pal.hash2(x, y, 77)
			var c := Pal.NAVY.lerp(Pal.INK, 0.45)
			if h > 0.93:
				c = Pal.LEMON.lerp(Pal.HONEY, 0.4)
			elif h > 0.68:
				c = Pal.SYNC.lerp(Pal.NAVY, 0.25 + Pal.hash2(x, y, 78) * 0.35)
			b.rect(x, y, col_w - 3, 2, c)
			b.pset(x, y + 2, Pal.shade(base))


static func _glow(b: PixBuf, cx: int, cy: int, r: int, c: Color, k: float) -> void:
	## A dithered halo, densest at the centre.
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			var d := Vector2(x - cx, y - cy).length() / r
			if d < 1.0 and (1.0 - d) * k * 16.0 > BAYER[posmod(y, 4)][posmod(x, 4)]:
				b.pset(x, y, b.pget(x, y).lerp(c, 0.45))


static func _beam(b: PixBuf, from: Vector2, to: Vector2, width: float, k: float) -> void:
	## A searchlight: a dithered cone widening away from the lamp.
	var dir := (to - from)
	var n := dir.length()
	var u := dir / n
	var side := Vector2(-u.y, u.x)
	for y in H:
		for x in W:
			var v := Vector2(x, y) - from
			var t := v.dot(u) / n
			if t < 0.0 or t > 1.0:
				continue
			var off := absf(v.dot(side))
			var half := 1.0 + width * t
			if off < half and (1.0 - off / half) * (1.0 - t * 0.7) * k * 16.0 > BAYER[y % 4][x % 4]:
				b.pset(x, y, b.pget(x, y).lerp(Pal.SKY.lerp(Pal.WHITE, 0.3), 0.3))


static func transport_sky() -> PixBuf:
	var b := PixBuf.new(W, H)
	gradient(b, [Color("8aa0b8"), Color("b8c6d0"), Color("e0e2dc")], 0, H)
	for k in 5:
		var cy := 30 + k * 26
		for x in W:
			if sin(x * 0.03 + k * 2.0) + sin(x * 0.011 + k) > 1.1:
				b.pset(x, cy + int(sin(x * 0.05) * 3), Pal.WHITE)
	return b
