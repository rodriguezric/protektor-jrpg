class_name ArtPortraits
## Dialog busts (48x48). Same shape tools, palette, banded lighting and outline
## pass as the field sprites, just closer: a big lit head over the shoulders.
## mood: "", smile, sad, worried, angry, hollow, closed, shock, cry, flat.

const S := 48


static func render(s: Dictionary, mood: String = "") -> PixBuf:
	var b := PixBuf.new(S, S)
	var skin: Color = s.get("skin", Pal.SKIN)
	var hair: Color = s.get("hair", Pal.BARK)
	var top: Color = s.get("top", Pal.BLUE)
	var style: String = s.get("style", "short")
	var jacket: Variant = s.get("jacket", null)
	var adult: bool = s.get("adult", false)
	if s.get("hollow", false) and (mood == "" or mood == "smile"):
		mood = "hollow"
	var hx := 24.0
	var hy := 21.0 if not adult else 20.0
	var head := [hx, hy, 13.5, 12.5]

	# --- hair behind the head ---------------------------------------------
	match style:
		"long":
			b.ball(hx, hy + 8, 15, 14, Pal.shade(hair))
		"curly":
			for i in 11:
				var a := -0.2 + i * (PI + 0.4) / 10.0
				b.ball(hx + cos(a) * 14.0, hy + 2 + sin(a) * 9.0, 5.2, 5.0, Pal.shade(hair))
		"ponytail":
			b.ball(hx + 13, hy - 2, 5, 7, Pal.shade(hair))
			b.ball(hx + 15, hy + 7, 4, 7, Pal.shade(hair))
			b.ball(hx + 13, hy + 15, 3, 4, Pal.shade(hair))
		"twin":
			b.ball(hx - 15, hy + 6, 4.5, 7, Pal.shade(hair))
			b.ball(hx + 15, hy + 6, 4.5, 7, Pal.shade(hair))
		"bun":
			b.ball(hx, hy - 13, 6, 5, hair)

	# --- shoulders --------------------------------------------------------
	var sh: Color = jacket if jacket != null else top
	b.ball(24, 50, 21 if adult else 19, 13, sh)
	if s.get("hood", false):
		b.ball(24, 39, 12, 4.5, s.get("hoodc", top))
		b.ball(24, 40, 8, 3, Pal.shade(s.get("hoodc", top)))
	if jacket != null:
		b.poly([Vector2(17, 38), Vector2(31, 38), Vector2(27, 48), Vector2(21, 48)], top)
		b.line(17, 39, 21, 47, Pal.shade(sh))
		b.line(31, 39, 27, 47, Pal.shade(sh))
		if s.get("hood", false):
			b.line(20, 41, 20, 46, Pal.CREAM)
			b.line(28, 41, 28, 46, Pal.CREAM)
	elif s.get("collar", true):
		b.poly([Vector2(19, 37), Vector2(29, 37), Vector2(24, 43)], Pal.shade(skin))
	if s.get("floral", false):
		for i in 14:
			var px := 6 + Pal.hash2(i, 3) * 36
			var py := 40 + Pal.hash2(i, 5) * 8
			if b.solid(int(px), int(py)):
				b.pset(int(px), int(py), Pal.PINK if i % 3 else Pal.ROSE)
				b.pset(int(px) + 1, int(py), Pal.shade(Pal.PINK))
	if s.get("epaulettes", false):
		for ox in [7, 31]:
			b.rect(ox, 38, 10, 4, Pal.HONEY)
			b.rect(ox, 38, 10, 1, Pal.LEMON)
			for k in 5:
				b.rect(ox + k * 2, 42, 1, 3, Pal.LEMON if k % 2 == 0 else Pal.HONEY)
		b.rect(18, 36, 12, 5, Pal.WHITE)
		b.rect(18, 36, 12, 1, Pal.LEMON)
	if s.get("sash", false):
		b.poly([Vector2(30, 39), Vector2(35, 39), Vector2(26, 48), Vector2(20, 48)], Pal.RED)
		b.line(30, 39, 21, 48, Pal.hi(Pal.RED))
		b.ball(24, 44, 2, 2, Pal.SYNC.lerp(Pal.BLUE, 0.4))
	if s.get("badge", false):
		b.rect(33, 43, 3, 3, Pal.SLATE)
		b.pset(34, 44, Pal.SYNC)

	# --- neck and head ----------------------------------------------------
	b.rect(20, 31, 8, 8, Pal.shade(skin))
	b.ball(hx - 13, hy + 3, 2.5, 3.5, skin)
	b.ball(hx + 13, hy + 3, 2.5, 3.5, skin)
	b.ball(hx, hy, 13.5, 12.5, skin)
	b.ell(hx - 0.5, hy + 3, 11.5, 10, skin)
	b.ell(hx - 4, hy - 1, 6, 4, skin.lerp(Pal.LIGHT_TINT, 0.12))

	# --- hair cap ---------------------------------------------------------
	if style != "bald":
		var cap_y := hy - 5.0
		match style:
			"slick":
				b.ball(hx, hy - 6.5, 14, 8.5, hair, head[0], head[1], head[2], head[3])
				for k in 5:
					b.line(int(hx) - 9 + k * 4, int(hy) - 13, int(hx) - 7 + k * 4, int(hy) - 3, Pal.shade(hair))
				b.rect(hx - 14, hy - 4, 3, 7, hair)
				b.rect(hx + 11, hy - 4, 3, 7, hair)
			"curly":
				b.ball(hx, cap_y, 14.5, 9, hair, head[0], head[1], head[2], head[3])
				for i in 13:
					var a := PI + 0.05 + i * (PI - 0.1) / 12.0
					var cxx := hx + cos(a) * 13.5
					var cyy := hy - 2 + sin(a) * 11.0
					b.ball(cxx, cyy, 3.8, 3.6, hair)
					b.pset(int(cxx) - 1, int(cyy) - 2, Pal.hi(hair))
				for i in 4:
					b.ball(hx - 7 + i * 5, hy - 6, 3.4, 2.6, hair)
			_:
				b.ball(hx, cap_y, 14.2, 9.5, hair, head[0], head[1], head[2], head[3])
				b.rect(hx - 14, hy - 5, 3, 9 if style != "short" else 6, hair)
				b.rect(hx + 11, hy - 5, 3, 9 if style != "short" else 6, hair)
		match style:
			"hiro":
				var spikes := [[-13, -4, -20, -10], [-8, -10, -10, -21], [0, -11, 4, -22], [7, -9, 15, -18], [12, -4, 21, -8], [14, 2, 20, 6]]
				for p in spikes:
					b.tri(hx + p[0] - 4, hy + p[1] + 3, hx + p[0] + 4, hy + p[1] + 3, hx + p[2], hy + p[3], hair)
					b.tri(hx + p[0], hy + p[1] + 3, hx + p[0] + 4, hy + p[1] + 3, hx + p[2], hy + p[3], Pal.shade(hair))
			"spiky":
				for i in 5:
					var sx := hx - 10 + i * 5
					b.tri(sx - 3.5, hy - 9, sx + 3.5, hy - 9, sx - 1, hy - 17, hair)
			"messy":
				b.tri(hx - 9, hy - 12, hx - 3, hy - 12, hx - 8, hy - 18, hair)
				b.tri(hx - 2, hy - 13, hx + 4, hy - 13, hx + 3, hy - 19, hair)
				b.tri(hx + 5, hy - 11, hx + 11, hy - 10, hx + 11, hy - 16, hair)
			"ponytail":
				b.ball(hx + 7, hy - 13, 5, 3, hair)
				b.rect(hx + 9, hy - 14, 3, 3, Pal.ROSE.lerp(Pal.INK2, 0.3))

	# --- face -------------------------------------------------------------
	_face(b, s, mood, int(hx), int(hy), skin)

	# --- fringe over the face ---------------------------------------------
	match style:
		"hiro":
			b.poly([Vector2(hx - 14, hy - 6), Vector2(hx + 2, hy - 9), Vector2(hx - 2, hy - 3), Vector2(hx - 9, hy + 3), Vector2(hx - 11, hy - 1)], hair)
			b.tri(hx + 1, hy - 9, hx + 12, hy - 7, hx + 8, hy - 3, hair)
			b.line(int(hx) - 10, int(hy) - 5, int(hx) - 6, int(hy) + 1, Pal.shade(hair))
		"short", "bun", "twin", "long":
			b.tri(hx - 12, hy - 6, hx + 2, hy - 8, hx - 9, hy - 1, hair)
			b.tri(hx - 1, hy - 8, hx + 12, hy - 6, hx + 8, hy - 2, hair)
		"ponytail":
			b.tri(hx - 13, hy - 6, hx + 1, hy - 9, hx - 11, hy + 3, hair)
			b.tri(hx - 2, hy - 9, hx + 11, hy - 6, hx + 3, hy - 3, hair)
			b.rect(hx - 14, hy - 4, 2, 12, hair)
		"messy":
			b.tri(hx - 12, hy - 6, hx - 2, hy - 8, hx - 8, hy - 1, hair)
			b.tri(hx - 4, hy - 8, hx + 6, hy - 8, hx + 1, hy - 2, hair)
			b.tri(hx + 3, hy - 7, hx + 12, hy - 5, hx + 9, hy - 1, hair)
		"curly":
			b.ball(hx - 6, hy - 7, 4, 3, hair)
			b.ball(hx + 3, hy - 8, 4.5, 3, hair)
			b.ball(hx + 10, hy - 6, 3, 3, hair)
	b.outline()
	return b


static func _face(b: PixBuf, s: Dictionary, mood: String, hx: int, hy: int, skin: Color) -> void:
	var iris: Color = s.get("eye", Pal.INK2.lerp(Pal.SKY, 0.5))
	var ey := hy + 2
	var brow := Pal.deep(s.get("hair", Pal.BARK)).lerp(Pal.INK2, 0.3)
	var adult: bool = s.get("adult", false)
	for i in 2:
		var ex := hx - 9 if i == 0 else hx + 4
		var inner := 4 if i == 0 else 0
		var outer := 0 if i == 0 else 4
		if s.get("patch", false) and i == 0:
			b.ball(ex + 2.5, ey + 2.5, 4.6, 4.0, Pal.INK2)
			b.ball(ex + 2, ey + 2, 2.8, 2.2, Pal.INK2.lerp(Pal.SLATE, 0.4))
			b.line(ex - 4, ey - 3, hx + 14, hy - 10, Pal.INK2)
			b.line(ex - 4, ey + 3, hx - 14, ey + 3, Pal.INK2)
			continue
		# brows
		match mood:
			"sad", "worried", "cry":
				b.line(ex + outer, ey - 1, ex + inner, ey - 3, brow)
			"angry":
				b.line(ex + outer, ey - 3, ex + inner, ey - 1, brow)
			"hollow", "flat":
				b.line(ex, ey - 2, ex + 4, ey - 2, brow)
			_:
				b.line(ex, ey - 3 + (1 if adult else 0), ex + 4, ey - 3, brow)
		match mood:
			"closed":
				b.line(ex, ey + 3, ex + 4, ey + 3, Pal.INK)
				b.pset(ex + outer, ey + 2, Pal.INK)
			"hollow":
				b.rect(ex, ey + 2, 5, 3, Pal.INK2)
				b.rect(ex + 1, ey + 3, 3, 1, Pal.SYNC.lerp(Pal.INK2, 0.35))
				b.line(ex, ey + 1, ex + 4, ey + 1, Pal.shade(skin))
			"flat":
				b.rect(ex, ey + 2, 5, 4, Pal.INK)
				b.rect(ex + 1, ey + 3, 3, 2, iris)
				b.line(ex, ey + 2, ex + 4, ey + 2, Pal.shade(skin))
			"shock":
				b.rect(ex, ey, 5, 6, Pal.INK)
				b.rect(ex + 1, ey + 1, 3, 4, Pal.WHITE)
				b.pset(ex + 2, ey + 2, Pal.INK)
			_:
				b.rect(ex, ey, 5, 6, Pal.INK)
				b.rect(ex + 1, ey + 2, 3, 3, iris)
				b.pset(ex + 2, ey + 3, iris.lerp(Pal.INK, 0.6))
				b.rect(ex + 1, ey + 1, 2, 2, Pal.WHITE)
				b.pset(ex + 3, ey + 4, Pal.hi(iris))
				if mood == "sad" or mood == "worried" or mood == "cry":
					b.line(ex, ey, ex + 4, ey, Pal.shade(skin))
		if s.get("glasses", false):
			var gx := ex + 2.0
			for k in 16:
				var a := k * TAU / 16.0
				b.pset(int(gx + cos(a) * 4.6), int(ey + 3 + sin(a) * 4.0), Pal.LEMON.lerp(Pal.INK2, 0.35))
		if mood == "cry":
			b.pset(ex + 1, ey + 6, Pal.hi(Pal.SKY))
			b.pset(ex + 1, ey + 7, Pal.SKY)
			b.pset(ex + 2, ey + 8, Pal.SKY)
	if s.get("glasses", false):
		b.line(hx - 2, ey + 1, hx + 2, ey + 1, Pal.LEMON.lerp(Pal.INK2, 0.35))
	# nose, blush, mouth
	b.pset(hx, ey + 6, Pal.shade(skin))
	b.pset(hx - 1, ey + 7, Pal.shade(skin))
	if mood != "hollow" and mood != "flat" and not adult:
		b.rect(hx - 11, ey + 6, 3, 1, Pal.PINK.lerp(Pal.ROSE, 0.3))
		b.rect(hx + 9, ey + 6, 3, 1, Pal.PINK.lerp(Pal.ROSE, 0.3))
	var my := ey + 10
	var mc := Pal.ROSE.lerp(Pal.INK2, 0.45)
	if s.get("mustache", false):
		var mh := Pal.deep(s.get("hair", Pal.BARK))
		b.rect(hx - 4, my - 2, 9, 2, mh)
		b.pset(hx - 5, my - 1, mh)
		b.pset(hx + 5, my - 1, mh)
	match mood:
		"smile":
			b.line(hx - 2, my, hx + 2, my, mc)
			b.pset(hx - 3, my - 1, mc)
			b.pset(hx + 3, my - 1, mc)
		"sad", "cry":
			b.line(hx - 2, my, hx + 2, my, mc)
			b.pset(hx - 3, my + 1, mc)
			b.pset(hx + 3, my + 1, mc)
		"shock":
			b.ball(hx, my + 0.5, 1.6, 2.0, Pal.INK2)
		"angry":
			b.line(hx - 2, my, hx + 2, my, mc)
			b.pset(hx - 3, my + 1, mc)
		"worried":
			b.line(hx - 1, my, hx + 1, my, mc)
			b.pset(hx + 2, my - 1, mc)
		_:
			b.line(hx - 1, my, hx + 1, my, mc)
	if s.get("scar", false):
		b.line(hx + 8, ey + 4, hx + 10, ey + 8, Pal.ROSE.lerp(skin, 0.35))
	if adult and mood != "smile":
		b.pset(hx - 9, ey + 8, Pal.shade(skin))
		b.pset(hx + 9, ey + 8, Pal.shade(skin))


static func system_icon(frame: int) -> PixBuf:
	## Helion Command's voice: a cold eye inside the badge sigil.
	var b := PixBuf.new(S, S)
	b.ball(24, 24, 20, 20, Pal.NAVY)
	b.ball(24, 24, 16, 16, Pal.PANEL)
	for k in 12:
		var a := k * TAU / 12.0 + frame * 0.13
		b.rect(24 + cos(a) * 18 - 1, 24 + sin(a) * 18 - 1, 2, 2, Pal.SYNC if k % 3 == 0 else Pal.STEEL)
	b.ell(24, 24, 11, 6, Pal.FROST)
	b.ball(24, 24, 5, 5, Pal.SYNC.lerp(Pal.TEAL, 0.3))
	b.circ(24, 24, 2, Pal.INK)
	b.pset(22, 22, Pal.WHITE)
	b.outline()
	return b


static func comm(frame: int) -> PixBuf:
	## Outgoing call: a scratchy receiver screen with a waveform.
	var b := PixBuf.new(S, S)
	b.rect(4, 6, 40, 34, Pal.INK2)
	b.rect(6, 8, 36, 30, Pal.PANEL2)
	for x in range(8, 40):
		var y := 23 + int(sin(x * 0.6 + frame * 0.9) * (3 + 3 * sin(frame * 0.4 + x * 0.1)))
		b.pset(x, y, Pal.GLOW.lerp(Pal.LEMON, 0.4))
	for i in 18:
		b.pset(8 + int(Pal.hash2(i, frame) * 32), 9 + int(Pal.hash2(frame, i) * 28), Pal.TEXT_DIM)
	b.rect(18, 40, 12, 4, Pal.INK2)
	b.outline()
	return b
