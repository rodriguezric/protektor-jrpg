class_name ArtProps
## Furniture, fixtures and set pieces, all drawn with the same shape tools.
## Origin convention when placed on the field: bottom-centre (feet).

const EMBLEM := ["..XXX..", ".X...X.", "X..S..X", "X.SSS.X", "X..S..X", ".X...X.", "..XXX.."]


static func make(kind: String, v: int = 0) -> PixBuf:
	match kind:
		"counter": return counter(v)
		"stove": return stove()
		"fridge": return fridge()
		"table": return table(v)
		"chair": return chair(v)
		"foldbed": return foldbed()
		"kidbed": return kidbed()
		"shelf": return shelf()
		"heater": return heater(v)
		"lamp": return lamp(v)
		"plant": return plant(v)
		"letter": return letter()
		"packet": return packet()
		"bench": return bench(v)
		"podium": return podium()
		"console": return console(v)
		"terminal": return terminal(v)
		"holo": return holo_base()
		"pod": return pod(v)
		"vending": return vending(v)
		"board": return board(v)
		"couch": return couch(v)
		"crate": return crate()
		"scanner": return scanner(v)
		"medbed": return medbed()
		"comm": return comm(v)
		"pillar": return pillar()
		"simpod": return simpod(v)
		"banner": return banner(v)
		"stage": return stage()
		"mech": return mech(v)
		"barrier": return barrier()
		"pole": return pole(v)
		"shuttle": return shuttle(v)
		"speaker": return speaker()
		"tray": return tray()
		"bot": return bot(v)
		"locker": return locker(v)
		"window_rail": return rail()
		"cup": return cup()
		"quilt": return quilt()
		"memorial": return memorial()
	return crate()


static func _emblem(b: PixBuf, ox: int, oy: int, ring: Color, core: Color) -> void:
	b.ascii(EMBLEM, {"X": ring, "S": core}, ox, oy)


# ------------------------------------------------------------------ home ---

static func counter(v: int) -> PixBuf:
	var b := PixBuf.new(32, 26)
	b.rect(1, 8, 30, 17, Pal.WOOD)
	b.rect(1, 4, 30, 6, Pal.CREAM)
	b.rect(1, 4, 30, 1, Pal.hi(Pal.CREAM))
	b.rect(1, 9, 30, 1, Pal.shade(Pal.CREAM))
	for k in 3:
		b.rect(3 + k * 10, 12, 8, 11, Pal.shade(Pal.WOOD))
		b.rect(4 + k * 10, 13, 6, 9, Pal.WOOD)
		b.rect(6 + k * 10, 14, 2, 1, Pal.HONEY)
	if v == 1:
		b.ell(16, 6, 6, 1.6, Pal.SLATE)
		b.rect(15, 1, 2, 4, Pal.STONE)
		b.rect(15, 1, 4, 1, Pal.STONE)
		b.rect(6, 2, 3, 3, Pal.WHITE)
		b.rect(9, 3, 1, 1, Pal.WHITE)
	else:
		b.rect(22, 1, 3, 4, Pal.BLUE)
		b.rect(26, 2, 3, 3, Pal.CREAM)
		b.pset(23, 1, Pal.hi(Pal.BLUE))
	b.outline()
	return b


static func stove() -> PixBuf:
	var b := PixBuf.new(18, 26)
	b.rect(1, 4, 16, 21, Pal.STONE)
	b.rect(1, 4, 16, 6, Pal.FROST)
	b.rect(1, 4, 16, 1, Pal.hi(Pal.FROST))
	b.ell(5, 7, 2.5, 1.2, Pal.INK2)
	b.ell(12, 7, 2.5, 1.2, Pal.INK2)
	b.rect(3, 13, 12, 8, Pal.INK2)
	b.rect(4, 14, 10, 6, Pal.ORANGE.lerp(Pal.INK2, 0.6))
	b.rect(4, 11, 10, 1, Pal.SLATE)
	for k in 3:
		b.pset(5 + k * 4, 11, Pal.INK2)
	b.outline()
	return b


static func fridge() -> PixBuf:
	var b := PixBuf.new(18, 34)
	b.rect(1, 1, 16, 32, Pal.FROST)
	b.rect(1, 1, 16, 1, Pal.hi(Pal.FROST))
	b.rect(13, 1, 4, 32, Pal.shade(Pal.FROST))
	b.rect(1, 12, 16, 1, Pal.STEEL)
	b.rect(3, 5, 1, 5, Pal.SLATE)
	b.rect(3, 15, 1, 8, Pal.SLATE)
	b.rect(7, 4, 2, 2, Pal.ROSE)
	b.rect(10, 6, 3, 2, Pal.LEMON)
	b.rect(6, 17, 4, 5, Pal.WHITE)
	b.pset(7, 18, Pal.SKY)
	b.pset(8, 20, Pal.ROSE)
	b.outline()
	return b


static func table(v: int) -> PixBuf:
	var b := PixBuf.new(36, 22)
	var top := Pal.WOOD.lerp(Pal.PEACH, 0.15) if v == 0 else Pal.STEEL
	b.rect(4, 12, 2, 9, Pal.shade(top))
	b.rect(30, 12, 2, 9, Pal.shade(top))
	b.rect(1, 4, 34, 10, top)
	b.rect(1, 4, 34, 1, Pal.hi(top))
	b.rect(1, 12, 34, 2, Pal.shade(top))
	if v == 0:
		b.rect(6, 6, 6, 3, Pal.CREAM)
		b.pset(8, 7, Pal.SKY)
		b.ell(27, 8, 2.5, 1.5, Pal.WHITE)
	b.outline()
	return b


static func chair(v: int) -> PixBuf:
	var b := PixBuf.new(14, 18)
	var c := Pal.WOOD if v == 0 else Pal.SLATE
	b.rect(2, 9, 10, 3, c)
	b.rect(2, 9, 10, 1, Pal.hi(c))
	b.rect(3, 12, 1, 5, Pal.shade(c))
	b.rect(10, 12, 1, 5, Pal.shade(c))
	b.rect(2, 1, 10, 8, Pal.shade(c))
	b.rect(4, 3, 6, 4, c)
	b.outline()
	return b


static func foldbed() -> PixBuf:
	var b := PixBuf.new(36, 22)
	b.rect(1, 6, 34, 13, Pal.SLATE)
	b.rect(2, 4, 32, 11, Pal.CREAM)
	b.rect(2, 9, 32, 7, Pal.BLUE.lerp(Pal.CREAM, 0.3))
	b.rect(2, 9, 32, 1, Pal.hi(Pal.BLUE.lerp(Pal.CREAM, 0.3)))
	b.ball(7, 6, 4, 2.5, Pal.WHITE)
	b.rect(2, 18, 2, 3, Pal.INK2)
	b.rect(32, 18, 2, 3, Pal.INK2)
	b.outline()
	return b


static func kidbed() -> PixBuf:
	var b := PixBuf.new(22, 34)
	b.rect(1, 1, 20, 30, Pal.WOOD)
	b.rect(2, 2, 18, 4, Pal.hi(Pal.WOOD))
	b.rect(3, 5, 16, 24, Pal.CREAM)
	b.ball(11, 9, 6, 3, Pal.WHITE)
	var quilt := Pal.TEAL.lerp(Pal.CREAM, 0.15)
	b.rect(3, 13, 16, 16, quilt)
	b.rect(3, 13, 16, 2, Pal.hi(quilt))
	for k in 4:
		b.rect(4 + k * 4, 17, 2, 2, Pal.LEMON.lerp(quilt, 0.4))
	b.rect(1, 29, 20, 3, Pal.shade(Pal.WOOD))
	b.outline()
	return b


static func shelf() -> PixBuf:
	var b := PixBuf.new(18, 28)
	b.rect(1, 1, 16, 26, Pal.WOOD)
	b.rect(2, 2, 14, 24, Pal.BARK)
	for sy in [9, 17, 25]:
		b.rect(2, sy, 14, 1, Pal.WOOD)
	var cols := [Pal.ROSE, Pal.BLUE, Pal.HONEY, Pal.SAGE, Pal.LILAC]
	for k in 5:
		b.rect(3 + k * 2.6, 3 + (k % 2), 2, 6 - (k % 2), cols[k])
	# family photo: three little faces
	b.rect(4, 11, 10, 6, Pal.HONEY)
	b.rect(5, 12, 8, 4, Pal.SKY.lerp(Pal.CREAM, 0.4))
	b.pset(6, 13, Pal.SKIN2)
	b.pset(9, 13, Pal.SKIN)
	b.pset(11, 14, Pal.SKIN2)
	b.rect(4, 20, 4, 5, Pal.STONE)
	b.rect(10, 21, 5, 4, Pal.ROSE.lerp(Pal.INK2, 0.3))
	b.outline()
	return b


static func heater(v: int) -> PixBuf:
	var b := PixBuf.new(20, 14)
	b.rect(1, 2, 18, 10, Pal.STONE)
	for k in 5:
		b.rect(2 + k * 3.5, 3, 2, 8, Pal.hi(Pal.STONE) if k % 2 == 0 else Pal.STONE)
	b.rect(1, 11, 18, 1, Pal.shade(Pal.STONE))
	if v == 1:
		b.rect(16, 4, 2, 2, Pal.EMBER)
	else:
		b.rect(16, 4, 2, 2, Pal.ORANGE.lerp(Pal.INK2, 0.5))
	b.outline()
	return b


static func lamp(v: int) -> PixBuf:
	var b := PixBuf.new(12, 30)
	var lit := Pal.LEMON if v % 2 == 0 else Pal.LEMON.lerp(Pal.HONEY, 0.4)
	b.rect(5, 8, 2, 20, Pal.INK2)
	b.rect(3, 27, 6, 2, Pal.INK2)
	b.poly([Vector2(2, 9), Vector2(10, 9), Vector2(8, 2), Vector2(4, 2)], lit)
	b.rect(4, 3, 2, 3, Pal.WHITE)
	b.outline()
	return b


static func plant(v: int) -> PixBuf:
	var b := PixBuf.new(14, 20)
	b.rect(4, 13, 6, 6, Pal.ROSE.lerp(Pal.WOOD, 0.5))
	b.rect(3, 13, 8, 1, Pal.hi(Pal.ROSE.lerp(Pal.WOOD, 0.5)))
	if v == 1:
		# the Academy's plant: plastic, perfect, dusty
		b.cap(7, 13, 4, 4, 0.8, Pal.SAGE.lerp(Pal.STONE, 0.5))
		b.cap(7, 13, 10, 5, 0.8, Pal.SAGE.lerp(Pal.STONE, 0.5))
		b.cap(7, 13, 7, 2, 0.8, Pal.SAGE.lerp(Pal.STONE, 0.4))
	else:
		b.ball(5, 9, 3.5, 3, Pal.LEAF)
		b.ball(9, 8, 3.5, 3.5, Pal.SAGE)
		b.ball(7, 5, 3, 3, Pal.LEAF.lerp(Pal.SAGE, 0.5))
	b.outline()
	return b


static func letter() -> PixBuf:
	var b := PixBuf.new(10, 8)
	b.rect(1, 1, 8, 6, Pal.WHITE)
	b.rect(1, 1, 8, 1, Pal.CREAM)
	for k in 3:
		b.rect(2, 2 + k * 1.5, 5, 0.6, Pal.STONE)
	b.rect(6, 4, 2, 2, Pal.SYNC.lerp(Pal.BLUE, 0.4))
	b.outline()
	return b


static func packet() -> PixBuf:
	var b := PixBuf.new(12, 9)
	b.rect(1, 1, 10, 7, Pal.HONEY.lerp(Pal.CREAM, 0.4))
	b.line(1, 1, 6, 5, Pal.shade(Pal.CREAM))
	b.line(10, 1, 6, 5, Pal.shade(Pal.CREAM))
	b.rect(5, 4, 2, 2, Pal.RED)
	b.outline()
	return b


static func memorial() -> PixBuf:
	## Midas's jacket, folded by someone, with a cup and a ration-candle.
	var b := PixBuf.new(20, 12)
	var j := Data.JACKET.lerp(Pal.PEACH, 0.3)
	b.rect(2, 5, 12, 6, j)
	b.rect(2, 5, 12, 1, Pal.hi(j))
	b.rect(7, 5, 2, 6, Pal.TEAL)
	b.pset(11, 7, Pal.SYNC)
	b.rect(15, 6, 3, 5, Pal.CREAM)
	b.rect(16, 3, 1, 3, Pal.WHITE)
	b.pset(16, 2, Pal.LEMON)
	b.pset(16, 1, Pal.EMBER)
	b.outline()
	return b


static func quilt() -> PixBuf:
	var b := PixBuf.new(18, 14)
	var q := Pal.TEAL.lerp(Pal.CREAM, 0.15)
	b.rect(1, 1, 16, 12, q)
	b.rect(1, 1, 16, 2, Pal.hi(q))
	for k in 4:
		b.rect(2 + k * 4, 5, 2, 2, Pal.LEMON.lerp(q, 0.4))
	b.rect(1, 12, 16, 1, Pal.shade(q))
	return b


static func cup() -> PixBuf:
	var b := PixBuf.new(6, 6)
	b.rect(1, 1, 3, 4, Pal.BLUE.lerp(Pal.SKY, 0.4))
	b.pset(4, 2, Pal.BLUE)
	b.pset(1, 1, Pal.WHITE)
	b.outline()
	return b


# --------------------------------------------------------------- academy ---

static func bench(v: int) -> PixBuf:
	## A row of seats seen from behind (v=0) or front (v=1).
	var b := PixBuf.new(48, 16)
	var c := Pal.NAVY.lerp(Pal.STEEL, 0.35)
	if v == 0:
		b.rect(1, 5, 46, 7, c)
		b.rect(1, 5, 46, 1, Pal.hi(c))
		for k in 4:
			b.rect(12 * k + 1, 5, 1, 7, Pal.shade(c))
		b.rect(2, 12, 2, 3, Pal.INK2)
		b.rect(44, 12, 2, 3, Pal.INK2)
	else:
		b.rect(1, 8, 46, 4, c)
		b.rect(1, 8, 46, 1, Pal.hi(c))
		b.rect(1, 3, 46, 5, Pal.shade(c))
		b.rect(2, 12, 2, 3, Pal.INK2)
		b.rect(44, 12, 2, 3, Pal.INK2)
	b.outline()
	return b


static func podium() -> PixBuf:
	var b := PixBuf.new(24, 26)
	b.poly([Vector2(3, 6), Vector2(21, 6), Vector2(19, 24), Vector2(5, 24)], Pal.NAVY)
	b.rect(2, 4, 20, 4, Pal.STEEL)
	b.rect(2, 4, 20, 1, Pal.hi(Pal.STEEL))
	_emblem(b, 9, 12, Pal.HONEY, Pal.SYNC)
	b.outline()
	return b


static func console(v: int) -> PixBuf:
	var b := PixBuf.new(34, 24)
	b.rect(1, 12, 32, 11, Pal.STEEL.lerp(Pal.NAVY, 0.3))
	b.rect(1, 12, 32, 1, Pal.hi(Pal.STEEL))
	b.rect(3, 2, 28, 11, Pal.INK2)
	b.rect(4, 3, 26, 9, Pal.PANEL2)
	for k in 6:
		var y := 4 + k
		var len := 4 + int(Pal.hash2(k, v) * 18)
		b.rect(5, y, len, 1, Pal.SYNC.lerp(Pal.PANEL2, 0.3 + 0.4 * ((k + v) % 2)))
	b.rect(26, 4, 3, 3, Pal.BLOOD if v % 2 == 0 else Pal.GLOW)
	for k in 5:
		b.rect(5 + k * 5, 15, 3, 2, Pal.SLATE)
	b.outline()
	return b


static func terminal(v: int) -> PixBuf:
	var b := PixBuf.new(18, 32)
	b.rect(6, 18, 6, 12, Pal.STEEL)
	b.rect(3, 29, 12, 2, Pal.SLATE)
	b.rect(1, 2, 16, 16, Pal.STEEL.lerp(Pal.NAVY, 0.3))
	b.rect(2, 3, 14, 13, Pal.PANEL2)
	var glow := Pal.SYNC.lerp(Pal.PANEL2, 0.25 if v % 2 == 0 else 0.45)
	b.circ(9, 9, 4, glow.lerp(Pal.PANEL2, 0.5))
	b.circ(9, 9, 2, glow)
	b.pset(13, 5, Pal.GLOW if v % 2 == 0 else Pal.SLATE)
	b.rect(3, 14, 12, 1, glow.lerp(Pal.PANEL2, 0.4))
	b.outline()
	return b


static func holo_base() -> PixBuf:
	var b := PixBuf.new(40, 16)
	b.ell(20, 8, 18, 6, Pal.STEEL.lerp(Pal.NAVY, 0.3))
	b.ell(20, 7, 15, 4.5, Pal.NAVY)
	b.ell(20, 7, 9, 2.6, Pal.SYNC.lerp(Pal.NAVY, 0.4))
	b.ell(20, 7, 4, 1.2, Pal.SYNC)
	b.outline()
	return b


static func pod(v: int) -> PixBuf:
	## Floor ring of light (drawn under actors).
	var b := PixBuf.new(34, 20)
	b.ell(17, 10, 16, 9, Pal.SLATE.lerp(Pal.NAVY, 0.5))
	b.ell(17, 10, 13, 7, Pal.NAVY.lerp(Pal.INK, 0.3))
	for k in 24:
		var a := k * TAU / 24.0 + v * 0.26
		var on := (k + v) % 3 == 0
		b.pset(int(17 + cos(a) * 14.5), int(10 + sin(a) * 8.0), Pal.SYNC if on else Pal.TEAL)
	b.ell(17, 10, 5, 2.6, Pal.SYNC.lerp(Pal.NAVY, 0.55))
	return b


static func vending(v: int) -> PixBuf:
	var b := PixBuf.new(18, 34)
	b.rect(1, 1, 16, 32, Pal.ROSE.lerp(Pal.NAVY, 0.45))
	b.rect(1, 1, 16, 1, Pal.hi(Pal.ROSE.lerp(Pal.NAVY, 0.45)))
	b.rect(3, 3, 10, 18, Pal.PANEL2)
	for r in 4:
		for k in 3:
			b.rect(4 + k * 3, 4 + r * 4.5, 2, 3, [Pal.CREAM, Pal.GLOW.lerp(Pal.SAGE, 0.5), Pal.LEMON][(r + k) % 3])
	b.rect(14, 5, 2, 6, Pal.SLATE)
	b.rect(14, 12, 2, 1, Pal.GLOW if v % 2 == 0 else Pal.SLATE)
	b.rect(3, 24, 10, 4, Pal.INK2)
	b.outline()
	return b


static func board(v: int) -> PixBuf:
	## The pilot roster. v = how many names have been struck out.
	var b := PixBuf.new(34, 22)
	b.rect(1, 1, 32, 20, Pal.STEEL)
	b.rect(2, 2, 30, 18, Pal.PANEL2)
	b.rect(4, 3, 26, 2, Pal.SYNC.lerp(Pal.PANEL2, 0.3))
	for r in 6:
		for col in 2:
			var i := r * 2 + col
			var x := 4 + col * 14
			var y := 7 + r * 2
			var gone := i < v
			b.rect(x, y, 10, 1, Pal.TEXT_DIM if gone else Pal.CREAM.lerp(Pal.PANEL2, 0.2))
			if gone:
				b.rect(x - 1, y, 12, 1, Pal.BLOOD.lerp(Pal.PANEL2, 0.3))
	b.outline()
	return b


static func couch(v: int) -> PixBuf:
	var b := PixBuf.new(36, 20)
	var c := Pal.TEAL.lerp(Pal.NAVY, 0.4) if v == 0 else Pal.PLUM.lerp(Pal.SLATE, 0.3)
	b.rect(2, 2, 32, 9, Pal.shade(c))
	b.rect(2, 9, 32, 7, c)
	b.rect(2, 9, 32, 1, Pal.hi(c))
	b.rect(1, 5, 4, 12, c)
	b.rect(31, 5, 4, 12, c)
	b.rect(17, 9, 1, 7, Pal.shade(c))
	b.rect(3, 16, 2, 3, Pal.INK2)
	b.rect(31, 16, 2, 3, Pal.INK2)
	b.outline()
	return b


static func crate() -> PixBuf:
	var b := PixBuf.new(16, 16)
	var c := Pal.STEEL.lerp(Pal.SAGE, 0.3)
	b.rect(1, 2, 14, 13, c)
	b.rect(1, 2, 14, 2, Pal.hi(c))
	b.rect(1, 8, 14, 1, Pal.shade(c))
	b.rect(6, 4, 4, 3, Pal.LEMON.lerp(c, 0.4))
	b.rect(1, 14, 14, 1, Pal.shade(c))
	b.outline()
	return b


static func scanner(v: int) -> PixBuf:
	var b := PixBuf.new(30, 38)
	var c := Pal.FROST.lerp(Pal.STEEL, 0.3)
	b.rect(2, 4, 4, 33, c)
	b.rect(24, 4, 4, 33, Pal.shade(c))
	b.rect(2, 2, 26, 5, c)
	b.rect(2, 2, 26, 1, Pal.hi(c))
	var y := 8 + (v % 6) * 4
	b.rect(6, y, 18, 1, Pal.SYNC)
	b.rect(6, y + 1, 18, 1, Pal.SYNC.lerp(Pal.TEAL, 0.6))
	b.rect(3, 6, 2, 2, Pal.GLOW)
	b.outline()
	return b


static func medbed() -> PixBuf:
	var b := PixBuf.new(22, 34)
	b.rect(2, 4, 18, 26, Pal.STEEL)
	b.rect(3, 5, 16, 24, Pal.FROST)
	b.ball(11, 9, 5, 2.5, Pal.WHITE)
	b.rect(3, 15, 16, 14, Pal.SKY.lerp(Pal.FROST, 0.5))
	b.rect(3, 15, 16, 1, Pal.hi(Pal.SKY))
	b.rect(3, 30, 2, 3, Pal.INK2)
	b.rect(17, 30, 2, 3, Pal.INK2)
	b.outline()
	return b


static func comm(v: int) -> PixBuf:
	var b := PixBuf.new(20, 34)
	var c := Pal.NAVY.lerp(Pal.STEEL, 0.3)
	b.rect(1, 1, 18, 32, c)
	b.rect(1, 1, 18, 1, Pal.hi(c))
	b.rect(3, 4, 14, 10, Pal.PANEL2)
	for x in range(4, 16):
		b.pset(x, 9 + int(sin(x * 0.9 + v * 1.3) * (1 + v % 2)), Pal.GLOW.lerp(Pal.LEMON, 0.4))
	b.rect(4, 17, 4, 7, Pal.INK2)
	b.rect(5, 18, 2, 5, Pal.SLATE)
	for k in 6:
		b.rect(10 + (k % 3) * 2, 17 + (k / 3) * 3, 1, 2, Pal.STONE)
	b.rect(3, 27, 14, 1, Pal.TEAL)
	b.outline()
	return b


static func pillar() -> PixBuf:
	var b := PixBuf.new(14, 44)
	var c := Pal.FROST.lerp(Pal.STEEL, 0.4)
	b.rect(2, 2, 10, 40, c)
	b.rect(2, 2, 3, 40, Pal.hi(c))
	b.rect(9, 2, 3, 40, Pal.shade(c))
	b.rect(1, 1, 12, 3, Pal.STEEL)
	b.rect(1, 40, 12, 3, Pal.SLATE)
	b.rect(6, 12, 2, 18, Pal.TEAL.lerp(Pal.SYNC, 0.4))
	b.outline()
	return b


static func simpod(v: int) -> PixBuf:
	var b := PixBuf.new(28, 34)
	var c := Pal.FROST.lerp(Pal.STEEL, 0.25)
	b.ball(14, 18, 12, 15, c)
	b.ell(15, 17, 7, 10, Pal.NAVY.lerp(Pal.INK, 0.2))
	b.ell(15, 17, 5, 8, Pal.SYNC.lerp(Pal.NAVY, 0.55 + 0.15 * (v % 2)))
	b.rect(4, 30, 20, 3, Pal.SLATE)
	b.pset(6, 10, Pal.WHITE)
	b.outline()
	return b


static func banner(v: int) -> PixBuf:
	var b := PixBuf.new(16, 34)
	var c := Pal.NAVY if v == 0 else Pal.RED.lerp(Pal.ROSE, 0.3)
	b.rect(1, 1, 14, 2, Pal.HONEY)
	b.poly([Vector2(2, 3), Vector2(14, 3), Vector2(14, 30), Vector2(8, 26), Vector2(2, 30)], c)
	b.rect(2, 3, 1, 26, Pal.hi(c))
	_emblem(b, 5, 9, Pal.HONEY, Pal.SYNC if v == 0 else Pal.WHITE)
	b.outline()
	return b


static func locker(v: int) -> PixBuf:
	var b := PixBuf.new(16, 32)
	var c := Pal.STEEL.lerp(Pal.BLUE, 0.2)
	b.rect(1, 1, 14, 30, c)
	b.rect(1, 1, 14, 1, Pal.hi(c))
	b.rect(7, 1, 1, 30, Pal.shade(c))
	for k in 3:
		b.rect(3, 4 + k * 2, 3, 1, Pal.shade(c))
		b.rect(9, 4 + k * 2, 3, 1, Pal.shade(c))
	b.rect(5, 16, 1, 3, Pal.INK2)
	b.rect(9, 16, 1, 3, Pal.INK2)
	if v == 1:
		b.rect(9, 8, 4, 5, Pal.CREAM)
		b.pset(10, 10, Pal.ROSE)
	b.outline()
	return b


static func rail() -> PixBuf:
	var b := PixBuf.new(16, 10)
	b.rect(0, 2, 16, 2, Pal.STEEL)
	b.rect(0, 2, 16, 1, Pal.hi(Pal.STEEL))
	b.rect(2, 4, 2, 5, Pal.SLATE)
	b.rect(12, 4, 2, 5, Pal.SLATE)
	b.outline()
	return b


static func tray() -> PixBuf:
	var b := PixBuf.new(14, 6)
	b.rect(1, 2, 12, 3, Pal.STONE)
	b.rect(1, 2, 12, 1, Pal.hi(Pal.STONE))
	for k in 4:
		b.rect(2 + k * 3, 1, 2, 2, Pal.SLATE)
		b.pset(2 + k * 3, 1, Pal.SYNC)
	b.outline()
	return b


static func bot(v: int) -> PixBuf:
	var b := PixBuf.new(16, 14)
	b.ell(8, 9, 6.5, 3.5, Pal.FROST)
	b.ball(8, 7, 5.5, 4, Pal.FROST)
	b.rect(4, 6, 8, 2, Pal.INK2)
	b.rect(5 + (v % 2) * 4, 6, 2, 2, Pal.SYNC)
	b.rect(3, 11, 10, 1, Pal.SLATE)
	b.pset(8, 2, Pal.BLOOD if v % 2 == 0 else Pal.INK2)
	b.outline()
	return b


# ---------------------------------------------------------------- parade ---

static func stage() -> PixBuf:
	var b := PixBuf.new(112, 44)
	var c := Pal.NAVY.lerp(Pal.STEEL, 0.25)
	b.rect(2, 14, 108, 26, Pal.shade(c))
	b.rect(2, 10, 108, 8, c)
	b.rect(2, 10, 108, 1, Pal.hi(c))
	for k in 9:
		b.rect(6 + k * 12, 20, 8, 16, Pal.deep(c))
		b.rect(7 + k * 12, 21, 6, 1, Pal.SYNC.lerp(Pal.NAVY, 0.4))
	# steps
	for k in 3:
		b.rect(44 - k * 3, 36 + k * 2, 24 + k * 6, 2, Pal.STEEL.lerp(Pal.FROST, 0.2 * k))
	b.rect(46, 2, 20, 9, Pal.INK2)
	b.rect(47, 3, 18, 7, Pal.PANEL2)
	_emblem(b, 53, 3, Pal.HONEY, Pal.SYNC)
	b.outline()
	return b


static func mech(v: int) -> PixBuf:
	## A Protektor: bio-mechanical plating, glowing neural conduits, no face.
	var b := PixBuf.new(48, 72)
	var plate := Pal.FROST.lerp(Pal.STEEL, 0.35)
	var dark := Pal.NAVY.lerp(Pal.STEEL, 0.2)
	var glow := Pal.SYNC if v % 2 == 0 else Pal.SYNC.lerp(Pal.TEAL, 0.5)
	# legs
	b.poly([Vector2(14, 44), Vector2(22, 44), Vector2(21, 68), Vector2(12, 68)], dark)
	b.poly([Vector2(26, 44), Vector2(34, 44), Vector2(36, 68), Vector2(27, 68)], Pal.shade(dark))
	b.rect(10, 66, 13, 5, plate)
	b.rect(26, 66, 13, 5, Pal.shade(plate))
	b.ball(18, 50, 4, 4, plate)
	b.ball(30, 50, 4, 4, Pal.shade(plate))
	# arms
	b.poly([Vector2(6, 20), Vector2(12, 18), Vector2(12, 44), Vector2(5, 46)], dark)
	b.poly([Vector2(36, 18), Vector2(42, 20), Vector2(43, 46), Vector2(36, 44)], Pal.shade(dark))
	b.ball(9, 20, 6, 5, plate)
	b.ball(39, 20, 6, 5, Pal.shade(plate))
	b.ball(8, 46, 3.5, 4, plate)
	b.ball(40, 46, 3.5, 4, Pal.shade(plate))
	# torso
	b.ball(24, 30, 13, 15, plate)
	b.poly([Vector2(16, 36), Vector2(32, 36), Vector2(28, 46), Vector2(20, 46)], dark)
	b.rect(23, 18, 2, 26, glow.lerp(plate, 0.3))
	b.circ(24, 28, 3, glow)
	b.circ(24, 28, 1.5, Pal.WHITE)
	b.line(16, 24, 21, 28, glow.lerp(plate, 0.2))
	b.line(32, 24, 27, 28, glow.lerp(plate, 0.2))
	# head: smooth helm with one visor slit
	b.ball(24, 11, 8, 8, plate)
	b.rect(18, 10, 12, 3, Pal.INK2)
	b.rect(19, 11, 10, 1, glow)
	b.tri(24, 1, 21, 6, 27, 6, Pal.shade(plate))
	b.outline()
	return b


static func barrier() -> PixBuf:
	var b := PixBuf.new(34, 14)
	b.rect(1, 3, 32, 6, Pal.STONE)
	b.rect(1, 3, 32, 1, Pal.hi(Pal.STONE))
	for k in 4:
		b.rect(2 + k * 8, 4, 4, 4, Pal.LEMON.lerp(Pal.INK2, 0.15) if k % 2 == 0 else Pal.INK2)
	b.rect(3, 9, 2, 4, Pal.SLATE)
	b.rect(29, 9, 2, 4, Pal.SLATE)
	b.outline()
	return b


static func pole(v: int) -> PixBuf:
	var b := PixBuf.new(18, 56)
	b.rect(8, 4, 2, 50, Pal.STEEL)
	b.rect(5, 52, 8, 3, Pal.SLATE)
	b.ball(9, 3, 2, 2, Pal.HONEY)
	var c := Pal.NAVY if v % 2 == 0 else Pal.RED.lerp(Pal.ROSE, 0.3)
	b.poly([Vector2(10, 6), Vector2(17, 7 + v % 2), Vector2(17, 30), Vector2(13, 27), Vector2(10, 30)], c)
	b.rect(12, 14, 3, 3, Pal.HONEY)
	b.pset(13, 15, Pal.SYNC)
	b.outline()
	return b


static func shuttle(v: int) -> PixBuf:
	## Troop transport, side-on. v=1 opens the hatch.
	var b := PixBuf.new(104, 60)
	var hull := Pal.FROST.lerp(Pal.STEEL, 0.3)
	b.poly([Vector2(4, 30), Vector2(16, 14), Vector2(80, 10), Vector2(100, 24), Vector2(100, 44), Vector2(6, 46)], hull)
	b.poly([Vector2(6, 38), Vector2(100, 36), Vector2(100, 44), Vector2(6, 46)], Pal.shade(hull))
	b.rect(10, 22, 88, 2, Pal.NAVY)
	b.rect(10, 24, 88, 1, Pal.SYNC.lerp(Pal.NAVY, 0.4))
	for k in 5:
		b.rect(56 + k * 7, 15, 4, 4, Pal.SKY.lerp(Pal.INK, 0.35))
	b.poly([Vector2(84, 13), Vector2(96, 22), Vector2(86, 22)], Pal.SKY.lerp(Pal.INK, 0.2))
	_emblem(b, 20, 27, Pal.HONEY, Pal.SYNC)
	# hatch
	if v == 1:
		b.rect(34, 24, 16, 20, Pal.INK2)
		b.rect(35, 25, 14, 19, Pal.LEMON.lerp(Pal.INK2, 0.55))
		b.poly([Vector2(33, 44), Vector2(51, 44), Vector2(56, 56), Vector2(28, 56)], Pal.STEEL)
		b.rect(28, 55, 28, 1, Pal.shade(Pal.STEEL))
	else:
		b.rect(34, 24, 16, 20, Pal.shade(hull))
		b.rect(41, 24, 2, 20, Pal.deep(hull))
	# landing struts and engines
	b.rect(14, 46, 3, 8, Pal.SLATE)
	b.rect(86, 44, 3, 10, Pal.SLATE)
	b.rect(10, 53, 10, 2, Pal.INK2)
	b.rect(82, 53, 10, 2, Pal.INK2)
	b.ball(4, 32, 4, 7, Pal.SLATE)
	b.ell(1, 32, 1.5, 4, Pal.SYNC if v == 1 else Pal.TEAL)
	b.outline()
	return b


static func speaker() -> PixBuf:
	var b := PixBuf.new(16, 40)
	b.rect(7, 8, 2, 30, Pal.SLATE)
	b.rect(4, 37, 8, 2, Pal.INK2)
	b.poly([Vector2(2, 2), Vector2(14, 2), Vector2(12, 10), Vector2(4, 10)], Pal.STEEL)
	b.ell(8, 6, 4, 2.5, Pal.INK2)
	b.ell(8, 6, 2, 1.2, Pal.SLATE)
	b.outline()
	return b
