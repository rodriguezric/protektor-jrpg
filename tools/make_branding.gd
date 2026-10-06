extends SceneTree
## Renders the app icon and the boot splash with the game's own art code.
## godot --headless --path . -s tools/make_branding.gd


func _init() -> void:
	var splash := _splash()
	splash.resize(320 * 4, 180 * 4, Image.INTERPOLATE_NEAREST)
	splash.save_png("res://boot_splash.png")
	var icon := _icon()
	icon.resize(256, 256, Image.INTERPOLATE_NEAREST)
	icon.save_png("res://icon.png")
	print("wrote icon.png and boot_splash.png")
	quit()


static func text(img: Image, s: String, x: int, y: int, k: int, c: Color, shadow: bool = true) -> void:
	## Pixel-font text straight into an image (PixFont's glyph grids).
	if shadow:
		text(img, s, x + k, y + k, k, Pal.INK, false)
	var cx := x
	for ch in s:
		if ch == " ":
			cx += 3 * k
			continue
		var rows: PackedStringArray = (PixFont.GLYPHS.get(ch, "") as String).split("|")
		var w := 0
		for r in rows.size():
			w = maxi(w, rows[r].length())
			for col in rows[r].length():
				if rows[r][col] == "#":
					img.fill_rect(Rect2i(cx + col * k, y + r * k, k, k), c)
		cx += (w + 1) * k


static func text_w(s: String, k: int) -> int:
	var w := 0
	for ch in s:
		if ch == " ":
			w += 3 * k
			continue
		var rows: PackedStringArray = (PixFont.GLYPHS.get(ch, "") as String).split("|")
		var gw := 0
		for r in rows:
			gw = maxi(gw, r.length())
		w += (gw + 1) * k
	return w


static func _shield(img: Image, c: Vector2, r: float, from: float, to: float, col: Color) -> void:
	## Segmented crescent of light, like the shield in a deployment.
	var n := int(r * 7.0)
	for i in n:
		var a := lerpf(from, to, float(i) / n)
		var seg := fmod((a - from) / (PI / 6.0), 1.0)
		if seg > 0.82:
			continue
		for dr in [0.0, 1.0]:
			var p: Vector2 = c + Vector2(cos(a), sin(a)) * (r + dr)
			var px := Vector2i(roundi(p.x), roundi(p.y))
			if Rect2i(Vector2i.ZERO, img.get_size()).has_point(px):
				img.set_pixelv(px, col if dr == 0.0 else Color(col, 0.55).blend(img.get_pixelv(px)))


static func _splash() -> Image:
	var img: Image = ArtMission.space(320, 180, "green_planet").img
	# stars that sparkle a little brighter than the nebula's
	for i in 30:
		var p := Vector2i(int(Pal.hash2(i, 7) * 320), int(Pal.hash2(i, 9) * 180))
		img.set_pixelv(p, Pal.WHITE)
	var planet: Image = ArtMission.planet("green_planet", 96, 6).img
	var pc := Vector2(232, 92)
	img.blend_rect(planet, Rect2i(Vector2i.ZERO, planet.get_size()), Vector2i(pc) - planet.get_size() / 2)
	# the Protektor: shield on the back side, cannon facing out
	_shield(img, pc, 56.0, PI * 0.35, PI * 1.15, Pal.SYNC)
	var f := Vector2.from_angle(-PI * 0.25)
	for k in 14:
		var p := pc + f * (50.0 + k)
		img.fill_rect(Rect2i(Vector2i(p) - Vector2i(1, 1), Vector2i(3, 3)), Pal.STEEL)
		img.set_pixelv(Vector2i(p), Pal.SYNC.lerp(Pal.WHITE, 0.4))
	img.fill_rect(Rect2i(Vector2i(pc + f * 64.0) - Vector2i(1, 1), Vector2i(3, 3)), Pal.WHITE)
	# title
	text(img, "PROTEKTOR", 18, 38, 3, Pal.SYNC.lerp(Pal.WHITE, 0.2))
	text(img, "CHILDREN OF THE VOID", 22, 72, 1, Pal.CREAM)
	# a loading line
	text(img, "SYNCHRONIZING", 22, 156, 1, Pal.TEXT_DIM, false)
	for k in 3:
		img.fill_rect(Rect2i(22 + text_w("SYNCHRONIZING", 1) + 2 + k * 4, 162, 2, 2), Pal.SYNC)
	img.fill_rect(Rect2i(22, 168, 120, 3), Pal.INK)
	img.fill_rect(Rect2i(23, 169, 46, 1), Pal.SYNC)
	return img


static func _icon() -> Image:
	var b := PixBuf.new(64, 64)
	# rounded dark tile with a sync-cyan rim
	b.rect(2, 0, 60, 64, Pal.INK)
	b.rect(0, 2, 64, 60, Pal.INK)
	b.rect(3, 1, 58, 62, Pal.TEAL.lerp(Pal.SYNC, 0.35))
	b.rect(1, 3, 62, 58, Pal.TEAL.lerp(Pal.SYNC, 0.35))
	for y in range(3, 61):
		for x in range(3, 61):
			var t := float(y) / 64.0
			b.pset(x, y, Pal.NAVY.lerp(Pal.INK, 0.3 + t * 0.5))
	for i in 14:
		b.pset(5 + int(Pal.hash2(i, 3) * 54), 5 + int(Pal.hash2(i, 4) * 54), Pal.WHITE.lerp(Pal.NAVY, Pal.hash2(i, 5) * 0.6))
	var planet: Image = ArtMission.planet("green_planet", 34, 6).img
	b.img.blend_rect(planet, Rect2i(Vector2i.ZERO, planet.get_size()), Vector2i(32, 33) - planet.get_size() / 2)
	_shield(b.img, Vector2(32, 33), 22.0, PI * 0.4, PI * 1.1, Pal.SYNC)
	var f := Vector2.from_angle(-PI * 0.25)
	for k in 8:
		var p := Vector2(32, 33) + f * (18.0 + k)
		b.img.fill_rect(Rect2i(Vector2i(p) - Vector2i(1, 1), Vector2i(3, 3)), Pal.STEEL)
		b.pset(int(p.x), int(p.y), Pal.SYNC.lerp(Pal.WHITE, 0.4))
	b.rect(int(32 + f.x * 26) - 1, int(33 + f.y * 26) - 1, 3, 3, Pal.WHITE)
	return b.img
