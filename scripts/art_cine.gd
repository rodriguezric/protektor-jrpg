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
		"hands": return hands()
		"city": return city(frame)
		"city_frame": return city_frame()
		"palm": return palm()
		"badge": return badge(frame)
		"horizon": return horizon()
		"chamber": return chamber(frame)
		"cradle": return cradle()
		"remote": return remote_world(frame)
		"kitchen": return kitchen()
		"ascend": return ascend()
		"academy_ext": return academy_ext()
		"transport_sky": return transport_sky()
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
	## The Helion letter. frame 1: crumpled where it's gripped.
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


static func hands() -> PixBuf:
	var b := PixBuf.new(W, H)
	var skin := Pal.SKIN2.lerp(Pal.SKIN, 0.5)
	for side in [-1, 1]:
		var cx: float = 160 + side * 86
		b.ball(cx, 96, 14, 18, skin)
		for f in 4:
			b.ball(cx - side * 9, 82 + f * 7, 6, 3.5, skin)
		b.ball(cx + side * 4, 74, 4, 7, Pal.shade(skin))
		b.poly([Vector2(cx - 12, 108), Vector2(cx + 12, 108), Vector2(cx + side * 30 + 14, 180), Vector2(cx + side * 30 - 14, 180)], Pal.PLUM.lerp(Pal.INK, 0.2))
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


static func palm() -> PixBuf:
	var b := PixBuf.new(W, H)
	gradient(b, [Color("1a2030"), Color("232c40"), Color("2c3850")])
	var skin: Color = Game.player_spec().get("skin", Pal.SKIN)
	b.ball(160, 130, 70, 50, skin)
	b.ell(160, 128, 50, 30, Pal.shade(skin).lerp(skin, 0.5))
	for f in 4:
		b.ball(108 + f * 34, 80, 13, 26, skin)
	b.ball(236, 120, 14, 22, skin)
	b.poly([Vector2(110, 168), Vector2(210, 168), Vector2(230, 180), Vector2(90, 180)], Data.JACKET)
	b.outline()
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
	b.rect(16, 44, 40, 10, Pal.deep(Pal.STEEL))
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
	var b := PixBuf.new(W, H)
	gradient(b, [Color("0b0d18"), Color("162036"), Color("243656")], 0, 120)
	stars(b, 90, 100, 41)
	ridge(b, 150, 14, 0.04, 0.3, Pal.INK2)
	var c := Pal.STEEL.lerp(Pal.NAVY, 0.4)
	b.rect(80, 70, 160, 80, c)
	b.rect(120, 40, 80, 40, c)
	b.rect(150, 14, 20, 30, Pal.shade(c))
	b.circ(160, 14, 6, Pal.SYNC)
	for x in range(86, 236, 12):
		for y in range(78, 146, 10):
			b.rect(x, y, 6, 3, Pal.SYNC.lerp(Pal.NAVY, 0.3 + Pal.hash2(x, y) * 0.5))
	ArtProps._emblem(b, 156, 52, Pal.HONEY, Pal.SYNC)
	b.outline()
	return b


static func transport_sky() -> PixBuf:
	var b := PixBuf.new(W, H)
	gradient(b, [Color("8aa0b8"), Color("b8c6d0"), Color("e0e2dc")], 0, H)
	for k in 5:
		var cy := 30 + k * 26
		for x in W:
			if sin(x * 0.03 + k * 2.0) + sin(x * 0.011 + k) > 1.1:
				b.pset(x, cy + int(sin(x * 0.05) * 3), Pal.WHITE)
	return b
