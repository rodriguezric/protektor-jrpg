extends Node
## Art autoload: every texture in the game is generated here on first use and cached.

var cache := {}
var font: FontFile
var theme: Theme


func _ready() -> void:
	font = PixFont.build()
	theme = Theme.new()
	theme.default_font = font
	theme.default_font_size = PixFont.SIZE
	theme.set_color("font_color", "Label", Pal.TEXT)
	get_tree().root.theme = theme
	# Controls under CanvasLayers don't inherit the window theme, so make the
	# pixel font the engine-wide default too.
	ThemeDB.fallback_font = font
	ThemeDB.fallback_font_size = PixFont.SIZE
	var d := ThemeDB.get_default_theme()
	d.default_font = font
	d.default_font_size = PixFont.SIZE
	d.set_color("font_color", "Label", Pal.TEXT)


func _cached(key: String, gen: Callable) -> Texture2D:
	if not cache.has(key):
		var r = gen.call()
		cache[key] = r.tex() if r is PixBuf else ImageTexture.create_from_image(r)
	return cache[key]


func _spec_key(spec: Dictionary) -> String:
	return "%s%s%s" % [spec.get("id", str(spec.hash())), "h" if spec.get("hollow", false) else "", spec.get("variant", "")]


func person(spec: Dictionary, dir: int, frame: int, mood: String = "", pose: String = "walk") -> Texture2D:
	return _cached("p:%s:%d:%d:%s:%s" % [_spec_key(spec), dir, frame, mood, pose], func(): return ArtPeople.render(spec, dir, frame, mood, pose))


func portrait(spec: Dictionary, mood: String = "", blink: bool = false, open: bool = false, zoom: int = 3) -> Texture2D:
	return _cached("pt:%s:%s:%d%d:%d" % [_spec_key(spec), mood, int(blink), int(open), zoom], func(): return ArtPortraits.from_sprite(spec, mood, blink, open, zoom))


func system_portrait(frame: int) -> Texture2D:
	return _cached("pt:system:%d" % frame, func(): return ArtPortraits.system_icon(frame))


func comm_portrait(frame: int) -> Texture2D:
	return _cached("pt:comm:%d" % frame, func(): return ArtPortraits.comm(frame))


func prop(kind: String, v: int = 0) -> Texture2D:
	return _cached("prop:%s:%d" % [kind, v], func(): return ArtProps.make(kind, v))


func ground(id: String, rows: Array, theme_name: String) -> Texture2D:
	return _cached("ground:" + id, func(): return ArtTiles.ground(rows, theme_name))


func planet(key: String, d: int, frame: int) -> Texture2D:
	return _cached("planet:%s:%d:%d" % [key, d, frame % ArtMission.PLANET_FRAMES], func(): return ArtMission.planet(key, d, frame % ArtMission.PLANET_FRAMES))


func drone(kind: String, d: int, look: int, frame: int) -> Texture2D:
	return _cached("drone:%s:%d:%d:%d" % [kind, d, look, frame], func(): return ArtMission.drone(kind, d, look, frame))


func asteroid(d: int, v: int, frame: int) -> Texture2D:
	return _cached("rock:%d:%d:%d" % [d, v, frame], func(): return ArtMission.asteroid(d, v, frame))


func portal(d: int, frame: int) -> Texture2D:
	return _cached("portal:%d:%d" % [d, frame], func(): return ArtMission.spawn_portal(d, frame))


func space(w: int, h: int, key: String, nebula: bool = true) -> Texture2D:
	return _cached("space:%d:%d:%s:%s" % [w, h, key, nebula], func(): return ArtMission.space(w, h, key, nebula))


func star(kind: int) -> Texture2D:
	return _cached("star:%d" % kind, func(): return ArtMission.star(kind))


func cine(name: String, frame: int = 0) -> Texture2D:
	return _cached("cine:%s:%d" % [name, frame], func(): return ArtCine.make(name, frame))


func shadow(w: int, h: int) -> Texture2D:
	return _cached("shadow:%d:%d" % [w, h], func():
		var b := PixBuf.new(w, h)
		b.ell(w / 2.0, h / 2.0, w / 2.0, h / 2.0, Pal.INK)
		return b)


func light(r: int, c: Color) -> Texture2D:
	## Dithered radial glow, for additive lamps and screens.
	return _cached("light:%d:%s" % [r, c.to_html()], func():
		var b := PixBuf.new(r * 2, r * 2)
		for y in r * 2:
			for x in r * 2:
				var d := Vector2(x + 0.5 - r, (y + 0.5 - r) * 1.3).length() / r
				if d >= 1.0:
					continue
				var k := (1.0 - d) * (1.0 - d)
				var lv := int(k * 4.0 * 16.0)
				var q := lv / 16
				if lv % 16 > ArtMission.BAYER[y % 4][x % 4]:
					q += 1
				if q > 0:
					b.pset(x, y, Color(c, minf(1.0, q * 0.12)))
		return b)


func achievement(a: Dictionary, unlocked: bool) -> Texture2D:
	return _cached("ach:%s:%d" % [a.get("id", ""), int(unlocked)], func(): return ArtAchieve.icon(a, unlocked))


func ui(name: String) -> Texture2D:
	return _cached("ui:" + name, func(): return ArtUI.make(name))


func number(text: String, c: Color) -> Texture2D:
	return _cached("num:%s:%s" % [text, c.to_html()], func(): return ArtUI.number(text, c))


func make_box(kind: String = "box") -> NinePatchRect:
	var n := NinePatchRect.new()
	n.texture = ui(kind)
	n.patch_margin_left = 4
	n.patch_margin_right = 4
	n.patch_margin_top = 4
	n.patch_margin_bottom = 4
	return n


func label(text: String, color: Color = Pal.TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	return l


func shadow_label(text: String, color: Color = Pal.TEXT, size_k: int = 1) -> Label:
	var l := label(text, color)
	if size_k > 1:
		l.add_theme_font_size_override("font_size", PixFont.SIZE * size_k)
	l.add_theme_color_override("font_shadow_color", Pal.INK)
	l.add_theme_constant_override("shadow_offset_x", size_k)
	l.add_theme_constant_override("shadow_offset_y", size_k)
	return l


func text_width(text: String, size_k: int = 1) -> int:
	return int(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, PixFont.SIZE * size_k).x)
