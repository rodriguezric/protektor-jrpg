class_name PixBuf
extends RefCounted
## A tiny pixel canvas. Every shape tool loops over the pixels in its bounds and
## colours a pixel when the pixel's centre (x+0.5, y+0.5) falls inside the shape.

const CLEAR := Color(0, 0, 0, 0)
const LIGHT := Vector3(-0.55, -0.68, 0.48)

var w: int
var h: int
var img: Image
## Optional scale-about-a-point transform for shape tools (pixels stay 1:1).
## Used to draw chibi heads bigger without rewriting their coordinates.
var tc := Vector2.ZERO
var tk := 1.0


func scale_about(center: Vector2, k: float) -> void:
	tc = center
	tk = k


func _x(x: float) -> float:
	return tc.x + (x - tc.x) * tk


func _y(y: float) -> float:
	return tc.y + (y - tc.y) * tk


func _init(width: int, height: int) -> void:
	w = width
	h = height
	img = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)


func pset(x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < w and y < h:
		img.set_pixel(x, y, c)


func pget(x: int, y: int) -> Color:
	if x >= 0 and y >= 0 and x < w and y < h:
		return img.get_pixel(x, y)
	return CLEAR


func solid(x: int, y: int) -> bool:
	return pget(x, y).a > 0.5


func rect(x: float, y: float, rw: float, rh: float, c: Color) -> void:
	x = _x(x)
	y = _y(y)
	rw *= tk
	rh *= tk
	for py in range(maxi(0, floori(y)), mini(h, ceili(y + rh))):
		for px in range(maxi(0, floori(x)), mini(w, ceili(x + rw))):
			if px + 0.5 >= x and px + 0.5 <= x + rw and py + 0.5 >= y and py + 0.5 <= y + rh:
				img.set_pixel(px, py, c)


func circ(cx: float, cy: float, r: float, c: Color) -> void:
	ell(cx, cy, r, r, c)


func ell(cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	cx = _x(cx)
	cy = _y(cy)
	rx *= tk
	ry *= tk
	for py in range(maxi(0, floori(cy - ry)), mini(h, ceili(cy + ry) + 1)):
		for px in range(maxi(0, floori(cx - rx)), mini(w, ceili(cx + rx) + 1)):
			var dx := (px + 0.5 - cx) / rx
			var dy := (py + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(px, py, c)


func ball(cx: float, cy: float, rx: float, ry: float, c: Color, ncx: float = NAN, ncy: float = NAN, nrx: float = NAN, nry: float = NAN) -> void:
	## Ellipse shaded in four bands as if it were a lit dome. The optional n* args
	## take the surface normal from a different (enclosing) ellipse, so a face drawn
	## inside a head is lit like the head.
	if is_nan(ncx):
		ncx = cx; ncy = cy; nrx = rx; nry = ry
	cx = _x(cx)
	cy = _y(cy)
	rx *= tk
	ry *= tk
	ncx = _x(ncx)
	ncy = _y(ncy)
	nrx *= tk
	nry *= tk
	var l := LIGHT.normalized()
	for py in range(maxi(0, floori(cy - ry)), mini(h, ceili(cy + ry) + 1)):
		for px in range(maxi(0, floori(cx - rx)), mini(w, ceili(cx + rx) + 1)):
			var dx := (px + 0.5 - cx) / rx
			var dy := (py + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				var nx := clampf((px + 0.5 - ncx) / nrx, -1.0, 1.0)
				var ny := clampf((py + 0.5 - ncy) / nry, -1.0, 1.0)
				var nz := sqrt(maxf(0.0, 1.0 - nx * nx - ny * ny))
				img.set_pixel(px, py, Pal.band(c, Vector3(nx, ny, nz).dot(l)))


func tri(ax: float, ay: float, bx: float, by: float, qx: float, qy: float, c: Color) -> void:
	poly([Vector2(ax, ay), Vector2(bx, by), Vector2(qx, qy)], c)


func poly(pts: Array, c: Color) -> void:
	if tk != 1.0:
		pts = pts.map(func(p: Vector2) -> Vector2: return Vector2(_x(p.x), _y(p.y)))
	var mn := Vector2(INF, INF)
	var mx := Vector2(-INF, -INF)
	for p in pts:
		mn = mn.min(p)
		mx = mx.max(p)
	for py in range(maxi(0, floori(mn.y)), mini(h, ceili(mx.y) + 1)):
		for px in range(maxi(0, floori(mn.x)), mini(w, ceili(mx.x) + 1)):
			if _inside(pts, px + 0.5, py + 0.5):
				img.set_pixel(px, py, c)


static func _inside(pts: Array, x: float, y: float) -> bool:
	var inside := false
	var j := pts.size() - 1
	for i in pts.size():
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[j]
		if (a.y > y) != (b.y > y) and x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x:
			inside = not inside
		j = i
	return inside


func cap(x0: float, y0: float, x1: float, y1: float, r: float, c: Color) -> void:
	## Capsule: every pixel within r of the segment. Used for limbs and branches.
	x0 = _x(x0)
	y0 = _y(y0)
	x1 = _x(x1)
	y1 = _y(y1)
	r *= tk
	var a := Vector2(x0, y0)
	var ab := Vector2(x1, y1) - a
	var len2 := maxf(ab.length_squared(), 0.0001)
	for py in range(maxi(0, floori(minf(y0, y1) - r)), mini(h, ceili(maxf(y0, y1) + r) + 1)):
		for px in range(maxi(0, floori(minf(x0, x1) - r)), mini(w, ceili(maxf(x0, x1) + r) + 1)):
			var p := Vector2(px + 0.5, py + 0.5)
			var t := clampf((p - a).dot(ab) / len2, 0.0, 1.0)
			if p.distance_to(a + ab * t) <= r:
				img.set_pixel(px, py, c)


func recolor(fn: Callable) -> void:
	## Runs fn(x, y, color) -> color over every opaque pixel (used for patterns).
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if c.a > 0.5:
				img.set_pixel(x, y, fn.call(x, y, c))


func line(x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		pset(x0, y0, c)
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


func ascii(rows: Array, colors: Dictionary, ox: int = 0, oy: int = 0) -> void:
	## Paints a character grid, e.g. ['.XX.XX.', 'XXXXXXX'] with {'X': Pal.ROSE}.
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if colors.has(ch):
				pset(ox + x, oy + y, colors[ch])


func flip_h() -> void:
	img.flip_x()


func blit(src: PixBuf, ox: int, oy: int) -> void:
	for y in src.h:
		for x in src.w:
			var c := src.img.get_pixel(x, y)
			if c.a > 0.5:
				pset(ox + x, oy + y, c)


func rim() -> void:
	## Light from the top-left: pixels on a top-left edge get the highlight band,
	## pixels on a bottom-right edge get the shade band.
	var src := img.duplicate() as Image
	for y in h:
		for x in w:
			var c := src.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var tl := _clear(src, x - 1, y) or _clear(src, x, y - 1)
			var br := _clear(src, x + 1, y) or _clear(src, x, y + 1)
			if br and not tl:
				img.set_pixel(x, y, Pal.shade(c))
			elif tl and not br:
				img.set_pixel(x, y, c.lerp(Pal.LIGHT_TINT, 0.25))


func outline() -> void:
	## One outline pass: every empty pixel touching the sprite takes a darker
	## version of the colour next to it, so there are no flat black lines.
	var src := img.duplicate() as Image
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.5:
				continue
			for d in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx >= 0 and ny >= 0 and nx < w and ny < h:
					var n := src.get_pixel(nx, ny)
					if n.a > 0.5:
						img.set_pixel(x, y, Pal.dark(n))
						break


static func _clear(src: Image, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= src.get_width() or y >= src.get_height():
		return true
	return src.get_pixel(x, y).a < 0.5


func tex() -> ImageTexture:
	return ImageTexture.create_from_image(img)
