class_name ArtUI
## Boxes, cursors, icons and emote bubbles.


static func make(name: String) -> PixBuf:
	match name:
		"box":
			return _box(Pal.LILAC, Pal.PANEL)
		"bar_box":
			return _box(Pal.TEAL, Pal.PANEL2)
		"sys_box":
			return _box(Pal.SYNC.lerp(Pal.TEAL, 0.45), Pal.NAVY.lerp(Pal.INK, 0.55))
		"gold_box":
			return _box(Pal.HONEY.lerp(Pal.LEMON, 0.3), Pal.PANEL)
		"red_box":
			return _box(Pal.BLOOD.lerp(Pal.ROSE, 0.3), Pal.PANEL2)
		"cursor":
			var b := PixBuf.new(7, 9)
			b.ascii(["X......", "XX.....", "XWX....", "XWWX...", "XWWWX..", "XWWX...", "XWX....", "XX.....", "X......"], {"X": Pal.INK, "W": Pal.SYNC})
			return b
		"down":
			var b := PixBuf.new(9, 7)
			b.ascii(["XXXXXXXXX", "XWWWWWWWX", ".XWWWWWX.", "..XWWWX..", "...XWX...", "....X....", "........."], {"X": Pal.INK, "W": Pal.SYNC})
			return b
		"marker":
			var b := PixBuf.new(9, 9)
			b.ascii(["..XXXXX..", ".XWWWWWX.", "XWWWWWWWX", ".XWWWWWX.", "..XWWWX..", "...XWX...", "....X...."], {"X": Pal.INK, "W": Pal.SYNC}, 0, 1)
			return b
		"cell_on":
			var b := PixBuf.new(7, 9)
			b.ascii([".XXXXX.", "XWSSSSX", "XSSSSSX", "XSSSSSX", "XSSSSSX", "XSSSSSX", "XSSSTSX", "XTTTTTX", ".XXXXX."], {"X": Pal.INK, "W": Pal.WHITE, "S": Pal.SYNC, "T": Pal.TEAL})
			return b
		"cell_red":
			var b := PixBuf.new(7, 9)
			b.ascii([".XXXXX.", "XWRRRRX", "XRRRRRX", "XRRRRRX", "XRRRRRX", "XRRRRRX", "XRRRDRX", "XDDDDDX", ".XXXXX."], {"X": Pal.INK, "W": Pal.WHITE, "R": Pal.BLOOD, "D": Pal.RED.lerp(Pal.INK, 0.3)})
			return b
		"credit":
			var b := PixBuf.new(9, 9)
			b.ascii(["..XXXX.", ".XHHHHX", "XHLLLHX", "XHLHLHX", "XHLLLHX", ".XHHHHX", "..XXXX."], {"X": Pal.INK, "H": Pal.HONEY, "L": Pal.LEMON}, 1, 1)
			return b
		"cell_off":
			var b := PixBuf.new(7, 9)
			b.ascii([".XXXXX.", "XSSSSSX", "XSSSSSX", "XSSSSSX", "XSSSSSX", "XSSSSSX", "XSSSSSX", "XSSSSSX", ".XXXXX."], {"X": Pal.INK, "S": Pal.INK2})
			return b
		"heart":
			var b := PixBuf.new(9, 9)
			b.ascii([".XX.XX.", "XWRRRRX", "XRRRRRX", ".XRRRX.", "..XRX..", "...X..."], {"X": Pal.INK, "R": Pal.BLOOD, "W": Pal.WHITE}, 1, 1)
			return b
		"heart_off":
			var b := PixBuf.new(9, 9)
			b.ascii([".XX.XX.", "XRRRRRX", "XRRRRRX", ".XRRRX.", "..XRX..", "...X..."], {"X": Pal.INK, "R": Pal.INK2}, 1, 1)
			return b
		"sparkle":
			var b := PixBuf.new(9, 9)
			b.ascii(["..X..", "..X..", "XXWXX", "..X..", "..X.."], {"X": Pal.SYNC, "W": Pal.WHITE}, 2, 2)
			return b
		"lock":
			var b := PixBuf.new(9, 10)
			b.ascii(["..XXX..", ".X...X.", ".X...X.", "XXXXXXX", "XSSSSSX", "XSSWSSX", "XSSSSSX", "XXXXXXX"], {"X": Pal.INK, "S": Pal.STONE, "W": Pal.INK2}, 1, 1)
			return b
		"check":
			var b := PixBuf.new(9, 9)
			b.ascii(["......X", ".....XX", "X...XX.", "XX.XX..", ".XXX...", "..X...."], {"X": Pal.GLOW}, 1, 2)
			return b
	if name.begins_with("t_"):
		return touch(name.substr(2))
	if name.begins_with("emote_"):
		return _emote(name.substr(6))
	return PixBuf.new(1, 1)


# ------------------------------------------------------------ touch controls --
# Drawn small like everything else and scaled up whole-number by the shell.
# "_on" variants are the pressed look: the face sinks a pixel and brightens.

static func touch(name: String) -> PixBuf:
	var on := name.ends_with("_on")
	if on:
		name = name.trim_suffix("_on")
	var face := Pal.NAVY.lerp(Pal.INK, 0.35)
	var rim := Pal.SYNC.lerp(Pal.TEAL, 0.45)
	var lit := Pal.SYNC
	if name == "joy_base":
		# the floating stick's ring: a dark well with four sync ticks
		var b := PixBuf.new(37, 37)
		b.circ(18.5, 18.5, 18, Pal.INK)
		b.circ(18.5, 18.5, 17, rim)
		b.circ(18.5, 18.5, 15.5, Color(Pal.PANEL2, 0.75))
		b.circ(18.5, 18.5, 9, Color(Pal.PANEL, 0.6))
		for t in [Vector2i(17, 4), Vector2i(17, 31), Vector2i(4, 17), Vector2i(31, 17)]:
			b.rect(t.x, t.y, 3, 3, lit)
		return b
	if name == "joy_knob":
		# the thumb knob; brightens (on) when pushed far enough to run
		var b := PixBuf.new(19, 19)
		b.circ(9.5, 10.5, 8.5, Pal.INK)
		b.circ(9.5, 9.5, 8, rim)
		b.circ(9.5, 9.5, 6.5, face.lerp(lit, 0.45) if on else face)
		b.rect(6, 4, 5, 1, face.lerp(Pal.WHITE, 0.3))
		b.circ(9.5, 9.5, 2, lit if not on else Pal.WHITE)
		return b
	if name in ["a", "b"]:
		var b := PixBuf.new(21, 21)
		var dy := 1 if on else 0
		b.circ(10.5, 11.5, 9.5, Pal.INK)
		b.circ(10.5, 10.5 + dy, 9, rim if name == "a" else Pal.ROSE.lerp(Pal.LILAC, 0.3))
		b.circ(10.5, 10.5 + dy, 7.5, face.lerp(lit, 0.3) if on else face)
		b.rect(6, 4 + dy, 6, 1, face.lerp(Pal.WHITE, 0.25))
		var g: PackedStringArray = (PixFont.GLYPHS[name.to_upper()] as String).split("|")
		for y in g.size():
			for x in g[y].length():
				if g[y][x] == "#":
					b.pset(9 + x, 7 + y + dy, Pal.WHITE if on else Pal.TEXT)
		return b
	if name == "menu":
		# same size and shape as A/B, so it can share B's spot; two bars,
		# which also read as "pause" in a deployment
		var b := PixBuf.new(21, 21)
		var dy := 1 if on else 0
		b.circ(10.5, 11.5, 9.5, Pal.INK)
		b.circ(10.5, 10.5 + dy, 9, Pal.TEAL.lerp(Pal.NAVY, 0.3))
		b.circ(10.5, 10.5 + dy, 7.5, face.lerp(lit, 0.3) if on else face)
		b.rect(6, 4 + dy, 6, 1, face.lerp(Pal.WHITE, 0.25))
		b.rect(7, 7 + dy, 2, 7, Pal.WHITE if on else lit)
		b.rect(12, 7 + dy, 2, 7, Pal.WHITE if on else lit)
		return b
	return PixBuf.new(1, 1)


static func _box(border: Color, panel: Color) -> PixBuf:
	var b := PixBuf.new(12, 12)
	b.rect(1, 0, 10, 12, Pal.INK)
	b.rect(0, 1, 12, 10, Pal.INK)
	b.rect(1, 1, 10, 10, border)
	b.rect(2, 2, 8, 8, panel)
	b.rect(2, 2, 8, 1, panel.lerp(border, 0.3))
	return b


static func _emote(kind: String) -> PixBuf:
	## Speech-bubble emotes that pop over a character's head.
	var b := PixBuf.new(13, 13)
	b.ball(6.5, 5.5, 6, 5, Pal.WHITE)
	b.tri(4, 9, 8, 9, 5, 12.5, Pal.WHITE)
	var m := {"X": Pal.INK, "R": Pal.BLOOD, "B": Pal.BLUE, "S": Pal.SYNC}
	match kind:
		"!":
			b.ascii(["X", "X", "X", ".", "X"], m, 6, 3)
		"?":
			b.ascii([".XX.", "X..X", "..X.", "....", "..X."], m, 5, 3)
		"...":
			b.ascii(["X.X.X"], m, 4, 6)
		"heart":
			b.ascii(["RR.RR", "RRRRR", ".RRR.", "..R.."], m, 4, 3)
		"sweat":
			b.ascii(["..B", ".BB", "BBB", ".B."], m, 5, 3)
		"note":
			b.ascii(["..XX", "..X.", "..X.", "XXX.", "XX.."], m, 4, 3)
		"anger":
			b.ascii(["R.R", ".R.", "R.R"], m, 5, 4)
		"sync":
			b.ascii(["..S..", ".S.S.", "S.S.S", ".S.S.", "..S.."], m, 4, 3)
	b.outline()
	return b


static func number(n: String, c: Color) -> PixBuf:
	var glyphs: Array = []
	var w := 1
	for ch in n:
		var g: PackedStringArray = (PixFont.GLYPHS.get(ch, "") as String).split("|")
		glyphs.append(g)
		w += g[0].length() + 1
	var b := PixBuf.new(w + 1, 10)
	var x := 1
	for g in glyphs:
		for y in g.size():
			for xx in g[y].length():
				if g[y][xx] == "#":
					b.pset(x + xx, y + 1, Pal.hi(c) if y < 2 else c)
		x += (g[0] as String).length() + 1
	b.outline()
	return b
