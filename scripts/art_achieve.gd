class_name ArtAchieve
## Achievement emblems (24x24), one per kind, drawn like everything else.

const S := 24


static func icon(a: Dictionary, unlocked: bool) -> PixBuf:
	var b := PixBuf.new(S, S)
	var kind: String = a.get("icon", "")
	var tier: int = a.get("tier", 0)
	var c := Vector2(12, 12)
	match kind:
		"aim":
			var col: Color = [Pal.STEEL, Pal.SYNC, Pal.GLOW, Pal.LEMON, Pal.EMBER][tier]
			for k in 32:
				var ang := k * TAU / 32.0
				b.pset(int(c.x + cos(ang) * 9.5), int(c.y + sin(ang) * 9.5), col)
				if k % 2 == 0:
					b.pset(int(c.x + cos(ang) * 5.5), int(c.y + sin(ang) * 5.5), Pal.shade(col))
			b.rect(11, 0, 2, 7, col)
			b.rect(11, 17, 2, 7, col)
			b.rect(0, 11, 7, 2, col)
			b.rect(17, 11, 7, 2, col)
			b.ball(12, 12, 2.2, 2.2, Pal.LEMON)
			b.pset(11, 11, Pal.WHITE)
		"block":
			var col: Color = [Pal.STEEL, Pal.SYNC, Pal.GLOW, Pal.LEMON, Pal.EMBER][tier]
			b.ball(12, 13, 4.5, 4.5, Pal.SKY.lerp(Pal.BLUE, 0.4))
			for r in [8, 9, 10]:
				for k in 40:
					var ang := PI * 0.1 + k * PI * 0.8 / 39.0
					b.pset(int(c.x + cos(ang + PI) * r), int(c.y + 1 + sin(ang + PI) * r), col if r != 10 else Pal.hi(col))
			b.ball(5, 4, 2, 2, Pal.STONE.lerp(Pal.WOOD, 0.35))
			b.ball(19, 3, 1.6, 1.6, Pal.STONE.lerp(Pal.WOOD, 0.35))
		"flawless":
			b.poly([Vector2(12, 1), Vector2(22, 10), Vector2(12, 23), Vector2(2, 10)], Pal.SYNC.lerp(Pal.WHITE, 0.2 * tier))
			b.poly([Vector2(12, 1), Vector2(12, 23), Vector2(2, 10)], Pal.hi(Pal.SYNC))
			b.line(2, 10, 22, 10, Pal.WHITE)
			b.line(12, 1, 7, 10, Pal.WHITE)
			b.line(12, 1, 17, 10, Pal.shade(Pal.SYNC))
			for k in tier:
				b.rect(4 + k * 5, 20, 3, 3, Pal.LEMON)
		"clear", "unlock":
			var tex: Image = ArtMission.planet(Data.PLANET_INFO[a.planet].tex, 18, 4).img
			b.img.blend_rect(tex, Rect2i(Vector2i.ZERO, tex.get_size()), Vector2i(1, 2))
			if kind == "clear":
				b.rect(17, 2, 1, 14, Pal.STONE)
				b.poly([Vector2(18, 2), Vector2(23, 4.5), Vector2(18, 7)], Pal.SYNC)
				for k in 3:
					b.rect(15 + k * 3, 19, 2, 3, Pal.LEMON)
			else:
				b.ascii(["..XXX..", ".X...X.", ".X.....", "XXXXXXX", "XSSSSSX", "XSSWSSX", "XXXXXXX"], {"X": Pal.INK, "S": Pal.LEMON, "W": Pal.INK2}, 16, 14)
		"ending_partial_pala":
			_figure(b, 8, Pal.AUBURN)
			_figure(b, 16, Pal.INK2)
			b.ball(12, 4, 3, 3, Pal.CREAM)
		"ending_partial_parents":
			_figure(b, 6, Pal.INK2)
			_figure(b, 12, Pal.WOOD)
			_figure(b, 18, Pal.PLUM)
			b.ascii([".R.R.", "RRRRR", ".RRR.", "..R.."], {"R": Pal.BLOOD}, 10, 1)
		"ending_full_synchronization":
			b.ball(12, 12, 10, 10, Pal.STEEL)
			b.ball(12, 12, 7, 8, Pal.SYNC.lerp(Pal.NAVY, 0.5))
			b.rect(8, 11, 3, 2, Pal.SYNC)
			b.rect(14, 11, 3, 2, Pal.SYNC)
		"ending_full_synchronization_parents":
			b.ball(12, 13, 8, 9, Pal.SKIN2)
			b.rect(7, 11, 3, 1, Pal.INK2)
			b.rect(14, 11, 3, 1, Pal.INK2)
			b.rect(8, 13, 1, 3, Pal.SKY)
			b.rect(15, 14, 1, 4, Pal.SKY)
			b.ball(12, 6, 8, 4, Pal.INK2)
		"ending_ascended":
			var m := ArtProps.mech(0).img
			m.resize(16, 24, Image.INTERPOLATE_NEAREST)
			b.img.blend_rect(m, Rect2i(0, 0, 16, 24), Vector2i(4, 0))
			for k in 6:
				b.pset(int(Pal.hash2(k, 3) * 23), int(Pal.hash2(k, 5) * 23), Pal.WHITE)
		"all_endings":
			for k in 5:
				var ang := -PI / 2 + k * TAU / 5.0
				b.ball(c.x + cos(ang) * 8, c.y + sin(ang) * 8, 3, 3, [Pal.AUBURN, Pal.BLOOD, Pal.SYNC, Pal.SKY, Pal.LEMON][k])
			b.ball(12, 12, 3, 3, Pal.WHITE)
		"no_upgrades":
			b.ball(12, 12, 9, 9, Pal.GRASS.lerp(Pal.BLUE, 0.4))
			b.ball(9, 10, 4, 3, Pal.SAGE)
			for k in 18:
				var ang := k * TAU / 18.0
				b.pset(int(c.x + cos(ang) * 11), int(c.y + sin(ang) * 11), Pal.STEEL)
			b.line(3, 21, 21, 3, Pal.BLOOD)
			b.line(4, 21, 21, 4, Pal.BLOOD)
		"training":
			for r in [4, 7, 10]:
				for k in 36:
					var ang := k * TAU / 36.0
					if k % 3 != 0:
						b.pset(int(c.x + cos(ang) * r), int(c.y + sin(ang) * r * 0.5 + 4), Pal.SYNC.lerp(Pal.WHITE, 0.4 - r * 0.03))
			b.ball(12, 8, 4, 4, Pal.SYNC.lerp(Pal.NAVY, 0.3))
			b.ascii(["X.X.X"], {"X": Pal.LEMON}, 10, 20)
		"boss":
			# the boss itself, small, on a red warning ring
			for k in 28:
				var ang := k * TAU / 28.0
				if k % 2 == 0:
					b.pset(int(c.x + cos(ang) * 11), int(c.y + sin(ang) * 11), Pal.BLOOD)
			var bd: Dictionary = Boss.defs().get(str(a.get("boss_id", "")), {})
			var bc: Array = bd.get("color", [0.8, 0.4, 0.5])
			var spr := ArtMission.boss(bd.get("art", {}), Color(bc[0], bc[1], bc[2]), 16, 2, 0, true).img
			b.img.blend_rect(spr, Rect2i(Vector2i.ZERO, spr.get_size()), Vector2i(12 - spr.get_width() / 2, 12 - spr.get_height() / 2))
		"all_bosses":
			# seven eyes round a cracked shield
			b.ball(12, 12, 6, 6, Pal.STEEL)
			b.line(9, 7, 12, 12, Pal.INK)
			b.line(12, 12, 15, 17, Pal.INK)
			for k in 7:
				var ang := -PI / 2 + k * TAU / 7.0
				var p := c + Vector2(cos(ang), sin(ang)) * 9.5
				b.ball(p.x, p.y, 2.2, 2.2, Pal.WHITE)
				b.pset(int(p.x), int(p.y), Pal.BLOOD)
		"upgrades":
			for k in 8:
				var ang := k * TAU / 8.0
				b.rect(c.x + cos(ang) * 8 - 2, c.y + sin(ang) * 8 - 2, 4, 4, Pal.HONEY)
			b.ball(12, 12, 7.5, 7.5, Pal.HONEY)
			b.ball(12, 12, 3, 3, Pal.PANEL2)
			b.pset(9, 8, Pal.hi(Pal.HONEY))
		"propaganda":
			# a torn poster: the chrome robot, a strip of slogan
			b.rect(3, 1, 18, 22, Pal.CREAM)
			b.rect(4, 2, 16, 15, Pal.NAVY.lerp(Pal.SKY, 0.35))
			b.ball(12, 15, 6, 3, Pal.GRASS)
			b.rect(9, 5, 6, 4, Pal.FROST)
			b.rect(10, 6, 4, 1, Pal.SYNC)
			b.rect(8, 9, 8, 5, Pal.FROST.lerp(Pal.STEEL, 0.3))
			b.rect(4, 18, 16, 2, Pal.LEMON)
			b.poly([Vector2(16, 1), Vector2(21, 1), Vector2(21, 8)], Pal.INK)
		"pong":
			b.ball(9, 11, 6, 6, Pal.RED)
			b.rect(8, 16, 3, 7, Pal.WOOD)
			b.circ(19, 6, 2.5, Pal.WHITE)
			b.pset(16, 9, Pal.STONE)
			b.pset(14, 11, Pal.STONE)
		"cards":
			b.rect(3, 4, 11, 16, Pal.WHITE)
			b.rect(10, 3, 11, 16, Pal.CREAM)
			b.ascii([".R.R.", "RRRRR", ".RRR.", "..R.."], {"R": Pal.RED}, 13, 8)
			b.rect(5, 6, 2, 3, Pal.INK2)
		"drill":
			b.poly([Vector2(12, 1), Vector2(21, 11), Vector2(3, 11)], Pal.LEMON)
			b.rect(9, 11, 6, 9, Pal.LEMON)
			b.line(4, 22, 10, 16, Pal.SYNC)
			b.line(10, 16, 14, 20, Pal.SYNC)
			b.line(14, 20, 20, 14, Pal.SYNC)
		"tv":
			# the family set, a heart on its screen
			b.rect(2, 4, 20, 16, Color("5a3a24"))
			b.rect(4, 6, 16, 11, Pal.INK)
			b.ascii([".R.R.", "RRRRR", ".RRR.", "..R.."], {"R": Color("ff9ae0")}, 10, 9)
			b.line(8, 0, 11, 4, Pal.STEEL)
			b.line(16, 0, 13, 4, Pal.STEEL)
			b.rect(5, 20, 3, 2, Color("3a2414"))
			b.rect(16, 20, 3, 2, Color("3a2414"))
		"console":
			# the Starbox controller; more lit buttons for higher tiers
			var pad := Color("2a2633").lerp(Pal.STEEL, 0.35)
			b.ball(6, 14, 5, 5, pad)
			b.ball(18, 14, 5, 5, pad)
			b.rect(6, 9, 12, 10, pad)
			b.rect(4, 13, 5, 1, Pal.INK)
			b.rect(6, 11, 1, 5, Pal.INK)
			for k in 3:
				b.ball(16 + (k % 2) * 3, 12 + (k / 2) * 3, 1.2, 1.2, [Pal.RED, Pal.LEMON, Pal.SYNC][k] if k <= tier else Pal.SLATE)
			b.rect(10, 4, 4, 5, Pal.INK2)
		_:
			if kind.begins_with("cg_"):
				# a cartridge in its game's colour, stars for the tier
				var col := Pal.SYNC
				for g in ConsoleScreen.GAMES:
					if "cg_" + str(g.id) == kind:
						col = g.color
				b.rect(5, 2, 14, 20, col.lerp(Pal.INK2, 0.3))
				b.rect(7, 4, 10, 8, col.lerp(Pal.WHITE, 0.55))
				b.rect(7, 18, 10, 3, Pal.INK2)
				_cart_art(b, kind, col)
				for k in tier + 1:
					b.rect(7 + k * 4, 14, 2, 2, Pal.LEMON)
	b.outline()
	if not unlocked:
		b.recolor(func(_x: int, _y: int, col: Color) -> Color:
			var l := col.get_luminance()
			return Color(l * 0.35 + 0.08, l * 0.33 + 0.08, l * 0.42 + 0.1, 1.0))
	return b


static func _figure(b: PixBuf, x: int, hair: Color) -> void:
	b.ball(x, 13, 3, 3, Pal.SKIN)
	b.ball(x, 11.5, 3.2, 2, hair)
	b.rect(x - 3, 16, 6, 7, Pal.TEAL.lerp(Pal.CREAM, 0.4))


static func _cart_art(b: PixBuf, kind: String, col: Color) -> void:
	## The tiny picture on a cartridge label.
	match kind:
		"cg_protektor":
			b.ball(12, 8, 2.5, 2.5, Pal.SYNC.lerp(Pal.NAVY, 0.3))
			b.pset(12, 4, Pal.INK2)
			b.pset(15, 7, Pal.INK2)
		"cg_duel":
			for k in 3:
				b.rect(8 + k * 3, 6, 2, 4, col.lerp(Pal.INK2, 0.4) if k != 1 else Pal.BLOOD)
		"cg_sword":
			b.line(9, 10, 14, 5, Pal.STEEL)
			b.rect(9, 9, 2, 1, Pal.WOOD)

