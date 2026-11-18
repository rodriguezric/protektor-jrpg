class_name TvSets
## Backdrops for TV shows (144x80), drawn with the same PixBuf tools as the
## rest of the game but brighter and flatter, like a studio set.

const W := 144
const H := 80


static func draw(kind: String) -> PixBuf:
	var b := PixBuf.new(W, H)
	match kind:
		"newsroom":
			_grad(b, Color("1d3a6b"), Color("0d1830"))
			# the Helion seal glowing behind the anchor, and a monitor
			b.circ(40, 26, 15, Color("2a5aa0"))
			b.circ(40, 26, 12, Color("1d3a6b"))
			b.ascii(ArtProps.EMBLEM, {"X": Color("ffd36b"), "S": Color("ffd36b")}, 37, 22)
			b.rect(92, 12, 40, 26, Pal.INK2)
			b.rect(94, 14, 36, 22, Color("2a6a8a"))
			b.rect(96, 30, 32, 4, Color("1d4a5a"))
			for k in 4:
				b.rect(99 + k * 8, 22 - k % 2 * 3, 3, 8, Color("c9ccd8"))
			b.rect(0, 56, W, 24, Color("2a2a3a"))
		"space":
			_grad(b, Color("0b0a1e"), Color("1a1438"))
			for k in 40:
				b.pset(int(Pal.hash2(k, 1) * W), int(Pal.hash2(k, 2) * H), Color(1, 1, 1, 0.4 + Pal.hash2(k, 3) * 0.6))
			b.circ(118, 62, 26, Color("3b8f6a"))
			b.circ(110, 54, 10, Color("62c08a"))
		"kitchen":
			_grad(b, Color("f0d8a8"), Color("e0b878"))
			for x in range(0, W, 12):
				b.rect(x, 0, 6, 44, Color("f5e2bd"))
			b.rect(0, 44, W, 36, Color("b07848"))
			b.rect(0, 44, W, 2, Color("d09868"))
			b.rect(96, 10, 26, 18, Color("8ad1e0"))
			b.rect(97, 11, 24, 16, Color("bfe8f0"))
			b.rect(108, 10, 2, 18, Pal.WHITE)
			# studio lights strung along the top
			for k in 6:
				b.circ(12 + k * 24, 4, 2, Color("ffd36b"))
		"weather":
			_grad(b, Color("2a7ac0"), Color("1a5a9a"))
			b.rect(8, 6, 92, 50, Color("0d2848"))
			b.rect(9, 7, 90, 48, Color("143a66"))
			for k in 6:
				b.rect(12 + k * 14, 50, 10, 3, Color("ffd36b") if k == 2 else Color("5fd3e0"))
			b.rect(0, 60, W, 20, Color("10305a"))
		"cartoon":
			_grad(b, Color("3a1f6b"), Color("1a0f40"))
			for k in 30:
				var x := int(Pal.hash2(k, 7) * W)
				var y := int(Pal.hash2(k, 8) * 60)
				b.rect(x, y, 1 + int(Pal.hash2(k, 9) * 2), 1, Color("ffe08a"))
			b.circ(30, 66, 22, Color("58c070"))
			b.circ(24, 60, 6, Color("88e090"))
			b.circ(36, 70, 4, Color("3a9a50"))
		"testcard":
			var bars := [Color("c0c0c0"), Color("c0c000"), Color("00c0c0"), Color("00c000"), Color("c000c0"), Color("c00000"), Color("0000c0")]
			for i in bars.size():
				b.rect(i * 21, 0, 21, 56, bars[i])
			b.rect(0, 56, W, 24, Color("101018"))
			b.circ(72, 28, 14, Color(0, 0, 0, 0.0))
		"black":
			b.rect(0, 0, W, H, Color("05040a"))
		# --- Hearts of the Shield Grid: lavish, soft-focus, very pink ---
		"observation":
			_grad(b, Color("2a1a4a"), Color("4a2a5a"))
			b.rect(10, 6, 124, 40, Color("0b0a1e"))
			for k in 30:
				b.pset(12 + int(Pal.hash2(k, 4) * 120), 8 + int(Pal.hash2(k, 5) * 36), Pal.WHITE)
			b.circ(100, 30, 12, Color("3b8f6a"))
			for x in range(10, 135, 31):
				b.rect(x, 6, 2, 40, Color("c9ccd8"))
			b.rect(0, 56, W, 24, Color("6a3a6a"))
			b.rect(0, 56, W, 2, Color("9a5a9a"))
		"parlor":
			_grad(b, Color("7a2a4a"), Color("5a1a3a"))
			for x in range(0, W, 10):
				b.rect(x, 0, 1, 56, Color("8a3a5a"))
			b.rect(60, 4, 24, 4, Color("ffd36b"))
			for k in 5:
				b.rect(62 + k * 5, 8, 1, 4 + k % 2 * 2, Color("ffe8a0"))
			b.rect(0, 56, W, 24, Color("4a2a1a"))
			b.rect(16, 40, 30, 16, Color("c04060"))
			b.rect(16, 38, 30, 4, Color("e06080"))
			b.rect(104, 24, 20, 30, Color("ffd36b"))
			b.rect(106, 26, 16, 26, Color("3a2a4a"))
		"hospital":
			_grad(b, Color("d8e8f0"), Color("b8d0e0"))
			b.rect(0, 56, W, 24, Color("a8c0d0"))
			b.rect(96, 10, 30, 22, Color("8ad1e0"))
			b.rect(98, 12, 26, 18, Color("c0e8f4"))
			for k in 3:
				b.rect(20 + k * 6, 14, 2, 10, Color("e05a6a") if k == 1 else Color("90a8b8"))
			b.rect(16, 24, 22, 2, Color("90a8b8"))
		"chapel":
			_grad(b, Color("f0e0f0"), Color("d8c0e0"))
			for k in 3:
				var x := 30 + k * 36
				b.rect(x, 4, 16, 30, Color("8ad1e0").lerp(Color("ff9ae0"), k * 0.4))
				b.rect(x + 7, 4, 2, 30, Pal.WHITE)
			b.rect(0, 56, W, 24, Color("c8a0b8"))
			b.rect(62, 56, 20, 24, Color("e05a7a"))
			for k in 6:
				b.circ(10 + k * 25, 52, 3, Color("ff9ae0"))
		"bedroom":
			_grad(b, Color("3a2a5a"), Color("2a1a40"))
			b.rect(0, 56, W, 24, Color("3a2a2a"))
			b.rect(100, 8, 28, 24, Color("0b0a1e"))
			b.circ(114, 18, 5, Color("ffe8a0"))
			b.rect(113, 8, 2, 24, Color("5a4a6a"))
			b.rect(100, 19, 28, 2, Color("5a4a6a"))
	return b


static func front(kind: String) -> PixBuf:
	## Set pieces that stand in front of the actors (a desk hides the
	## anchor's legs, a counter the chef's).
	match kind:
		"desk":
			var b := PixBuf.new(76, 18)
			b.rect(0, 0, 76, 18, Color("c9ccd8"))
			b.rect(0, 0, 76, 2, Pal.WHITE)
			b.rect(2, 8, 72, 2, Color("ffd36b"))
			b.ascii(ArtProps.EMBLEM, {"X": Color("2a5aa0"), "S": Color("2a5aa0")}, 34, 10)
			return b
		"counter":
			var b := PixBuf.new(112, 22)
			b.rect(0, 0, 112, 22, Color("e8e8f0"))
			b.rect(0, 0, 112, 3, Pal.WHITE)
			b.rect(0, 6, 112, 1, Color("c0c0d0"))
			for k in 4:
				b.rect(8 + k * 28, 10, 16, 8, Color("d0d0dc"))
				b.rect(15 + k * 28, 13, 2, 1, Color("909098"))
			return b
		"slime_lord":
			var b := PixBuf.new(40, 34)
			var c := Color("a05ad8")
			b.ball(20, 22, 18, 12, c)
			b.ball(20, 16, 12, 10, c)
			b.ball(14, 13, 4, 4, Pal.WHITE)
			b.ball(26, 13, 4, 4, Pal.WHITE)
			b.rect(13, 13, 2, 3, Pal.INK)
			b.rect(25, 13, 2, 3, Pal.INK)
			b.rect(12, 22, 16, 3, Pal.INK2)
			b.rect(14, 22, 2, 2, Pal.WHITE)
			b.rect(24, 22, 2, 2, Pal.WHITE)
			b.poly([Vector2(12, 6), Vector2(28, 6), Vector2(30, 0), Vector2(25, 3), Vector2(20, -1), Vector2(15, 3), Vector2(10, 0)], Color("ffd36b"))
			b.ball(10, 18, 3, 2, c.lerp(Pal.WHITE, 0.3))
			b.outline()
			return b
	return PixBuf.new(1, 1)


static func _grad(b: PixBuf, top: Color, bottom: Color) -> void:
	for y in H:
		b.rect(0, y, W, 1, top.lerp(bottom, float(y) / H))
