class_name ArtPeople
## One renderer for every humanoid (Greywater's chibi rig). Recruits, parents and
## officers are just data: colours + a hair style + clothes + accessories.
## dir: 0 = down, 1 = up, 2 = side (facing right). frame: 0..3 walk cycle.
## mood changes only the face: "", smile, sad, hollow, closed, shock, cry, angry.
## pose: walk (default), sit (legs tucked behind a seat), lie (flat, for pods).

const W := 32
const H := 32
const HEAD_K := 1.28


static func render(s: Dictionary, dir: int, frame: int, mood: String = "", pose: String = "walk") -> PixBuf:
	var b := PixBuf.new(W, H)
	var cx := 16.0
	var by := 30.0
	var skin: Color = s.get("skin", Pal.SKIN)
	var hair: Color = s.get("hair", Pal.BARK)
	var top: Color = s.get("top", Pal.BLUE)
	var bottom: Color = s.get("bottom", Pal.SLATE)
	var shoes: Color = s.get("shoes", Pal.BARK)
	var style: String = s.get("style", "short")
	var jacket: Variant = s.get("jacket", null)
	var side := dir == 2
	var back := dir == 1
	var sit := pose == "sit"

	var lstep := 0.0
	var rstep := 0.0
	var bob := 0.0
	var swing := 0.0
	if not sit:
		if frame == 1:
			lstep = -1.0
			bob = -1.0
			swing = 1.0
		elif frame == 3:
			rstep = -1.0
			bob = -1.0
			swing = -1.0
	if sit:
		by = 29.0
	var hx := cx
	var hy := by - 14.0 + bob
	var head := [hx, hy, 6.4, 5.8]

	# --- behind the body -------------------------------------------------
	b.scale_about(Vector2(hx, hy), HEAD_K)
	if style == "long":
		b.ball(hx - (1.5 if side else 0.0), hy + 3.5, 6.4, 6.0, Pal.shade(hair))
	if style == "curly":
		for i in 5:
			var a := PI * 0.1 + i * PI * 0.8 / 4.0
			b.circ(hx + cos(a) * 6.4 - (1.0 if side else 0.0), hy + sin(a) * 3.5 + 1.5, 2.4, Pal.shade(hair))
	if style == "ponytail" and not back:
		var tx := hx - 6.5 if side else hx + 6.6
		b.ball(tx, hy + 2.0, 2.6, 4.2, Pal.shade(hair))
		b.ball(tx + (-1.0 if side else 0.8), hy + 5.5, 1.8, 2.4, Pal.shade(hair))
	b.scale_about(Vector2.ZERO, 1.0)
	if s.get("hood", false) and back:
		b.ball(cx, by - 9.0 + bob, 4.6, 2.4, s.get("hoodc", top))
	if side:
		b.cap(cx - 1, by - 7 + bob, cx - 2 - swing, by - 4 + bob, 1.2, Pal.shade(jacket if jacket != null else top))

	# --- legs --------------------------------------------------------------
	if sit:
		b.rect(cx - 3, by - 3, 2, 2, bottom)
		b.rect(cx + 1, by - 3, 2, 2, bottom)
	elif side:
		var la := -1.0 if frame == 1 else (1.0 if frame == 3 else 0.0)
		b.rect(cx - 2 - la, by - 3, 2, 3, bottom)
		b.rect(cx - 2 - la, by - 1, 3, 1, shoes)
		b.rect(cx + 0 + la, by - 3, 2, 3, Pal.shade(bottom))
		b.rect(cx + 0 + la, by - 1, 3, 1, Pal.shade(shoes))
	else:
		b.rect(cx - 3, by - 3, 2, 3 + lstep, bottom)
		b.rect(cx - 3, by - 1 + lstep, 2, 1, shoes)
		b.rect(cx + 1, by - 3, 2, 3 + rstep, bottom)
		b.rect(cx + 1, by - 1 + rstep, 2, 1, shoes)

	# --- body --------------------------------------------------------------
	var tx := cx
	var ty := by - 5.0 + bob
	if jacket != null:
		b.ball(tx, ty, 4.0, 3.2, jacket)
		if not back:
			if side:
				b.rect(tx + 1.5, ty - 2.5, 2.5, 4.5, top)
			else:
				b.rect(tx - 1, ty - 3, 2, 5, top)
				b.pset(int(tx) - 2, int(ty) - 2, Pal.shade(jacket))
				b.pset(int(tx) + 1, int(ty) - 2, Pal.shade(jacket))
	else:
		b.ball(tx, ty, 4.0, 3.2, top)
	if s.get("floral", false):
		for p in [Vector2(-2, -1), Vector2(2, 0), Vector2(0, 1), Vector2(-1, 2)]:
			b.pset(int(tx + p.x), int(ty + p.y), Pal.PINK)
	if s.get("skirt", false):
		b.poly([Vector2(tx - 3.5, ty + 0.5), Vector2(tx + 3.5, ty + 0.5), Vector2(tx + 5, by - 1.5), Vector2(tx - 5, by - 1.5)], bottom)
		b.rect(tx - 4.5, by - 2.5, 9.5, 1, Pal.shade(bottom))
	else:
		b.rect(tx - 3.5, ty + 1, 7, 1.5, Pal.shade(bottom))
	if s.get("belt", false):
		b.rect(tx - 3.5, ty + 0.5, 7, 1, Pal.INK2)
		b.pset(int(tx), int(ty + 0.5), Pal.LEMON)
	if s.get("sash", false) and not back:
		b.line(int(tx) - 3, int(ty) - 2, int(tx) + 2, int(ty) + 1, Pal.RED)
		b.line(int(tx) - 2, int(ty) - 2, int(tx) + 3, int(ty) + 1, Pal.RED)
	if s.get("epaulettes", false):
		b.rect(tx - 4.5, ty - 3, 2, 1.2, Pal.LEMON)
		b.rect(tx + 2.5, ty - 3, 2, 1.2, Pal.LEMON)
	if s.get("apron", false) and not back:
		b.rect(tx - 2 + (1.5 if side else 0.0), ty - 1, 4, 4.5, Pal.WHITE)
	if s.get("badge", false) and not back:
		b.pset(int(tx) + (2 if side else -2), int(ty) - 1, Pal.SYNC)
	if s.get("hood", false) and not back:
		b.rect(tx - 3.5, ty - 3.2, 7, 1.4, s.get("hoodc", top))

	# --- arms (front view) ---------------------------------------------------
	var sleeve: Color = jacket if jacket != null else top
	if not side:
		if sit:
			b.cap(cx - 3.8, by - 7, cx - 3.0, by - 4.0, 1.2, sleeve)
			b.cap(cx + 3.8, by - 7, cx + 3.0, by - 4.0, 1.2, sleeve)
			b.circ(cx - 2.6, by - 3.6, 1.2, skin)
			b.circ(cx + 2.6, by - 3.6, 1.2, skin)
		else:
			b.cap(cx - 3.8, by - 7 + bob, cx - 4.8, by - 4.5 + bob + swing, 1.2, sleeve)
			b.cap(cx + 3.8, by - 7 + bob, cx + 4.8, by - 4.5 + bob - swing, 1.2, sleeve)
			b.circ(cx - 4.8, by - 3.8 + bob + swing, 1.2, skin)
			b.circ(cx + 4.8, by - 3.8 + bob - swing, 1.2, skin)

	# --- head --------------------------------------------------------------
	b.scale_about(Vector2(hx, hy), HEAD_K)
	b.ball(hx, hy, 6.4, 5.8, skin)
	_hair(b, s, style, hair, dir, hx, hy, head)
	if not back:
		_face(b, s, dir, mood, hx, hy, skin, head)
	b.scale_about(Vector2(hx, hy), HEAD_K)
	_hair_front(b, s, style, hair, dir, hx, hy, head)
	b.scale_about(Vector2.ZERO, 1.0)

	if side:
		var hand_y := by - 4.5 + bob
		if sit:
			hand_y = by - 4.0
		b.cap(cx + 1, by - 7 + bob, cx + 1.5 + swing, hand_y, 1.2, sleeve)
		b.circ(cx + 1.5 + swing, hand_y + 0.7, 1.2, skin)

	b.outline()
	if pose == "lie":
		b.img.rotate_90(COUNTERCLOCKWISE)
	return b


static func _hair(b: PixBuf, s: Dictionary, style: String, hair: Color, dir: int, hx: float, hy: float, head: Array) -> void:
	if style == "bald":
		return
	var side := dir == 2
	if dir == 1:
		b.ball(hx, hy - 0.5, 6.7, 6.0, hair, head[0], head[1], head[2], head[3])
	elif side:
		b.ball(hx - 0.8, hy - 1.2, 6.6, 5.2, hair, head[0], head[1], head[2], head[3])
	else:
		b.ball(hx, hy - 1.4, 6.8, 5.0, hair, head[0], head[1], head[2], head[3])
	match style:
		"bun":
			b.ball(hx - (2.0 if side else 0.0), hy - 6.5, 2.8, 2.4, hair)
		"spiky":
			for i in 3:
				var sx := hx - 4.0 + i * 4.0 - (1.5 if side else 0.0)
				b.tri(sx - 2.5, hy - 4, sx + 2.5, hy - 4, sx - 1.0, hy - 8.5, hair)
		"hiro":
			# Shock of white hair that never sits flat.
			var pts := [[-6.5, -1.0, -9.5, -3.5], [-4.5, -4.0, -6.5, -8.5], [-0.5, -5.0, -1.0, -9.5], [3.5, -4.5, 5.0, -8.5], [6.0, -1.5, 9.0, -3.0]]
			for p in pts:
				var bx: float = hx + p[0] - (1.0 if side else 0.0)
				var by_: float = hy + p[1]
				b.tri(bx - 2.2, by_ + 1.5, bx + 2.2, by_ + 1.5, hx + p[2] - (1.0 if side else 0.0), hy + p[3], hair)
			if dir == 1:
				b.tri(hx - 4, hy + 3, hx + 4, hy + 3, hx, hy + 7, hair)
		"twin":
			if not side:
				b.ball(hx - 7.2, hy + 2.5, 2.4, 3.2, hair)
				b.ball(hx + 7.2, hy + 2.5, 2.4, 3.2, hair)
			else:
				b.ball(hx - 6.5, hy + 2.5, 2.4, 3.2, hair)
		"long":
			if dir == 0:
				b.rect(hx - 6.5, hy - 1, 2, 7, hair)
				b.rect(hx + 4.5, hy - 1, 2, 7, hair)
			elif dir == 1:
				b.ball(hx, hy + 3, 6.5, 6, hair)
		"ponytail":
			b.ball(hx + (-3.0 if side else 0.0), hy - 5.2, 3.0, 2.0, hair)
			if dir == 1:
				b.ball(hx, hy + 2.0, 2.6, 4.6, hair)
				b.rect(hx - 1.5, hy - 3.0, 3, 2, Pal.shade(hair))
			elif dir == 0:
				b.rect(hx - 6.6, hy - 1, 1.8, 5, hair)
				b.rect(hx + 4.8, hy - 1, 1.8, 5, hair)
		"curly":
			for i in 6:
				var a := PI + 0.1 + i * (PI - 0.2) / 5.0
				var px := hx + cos(a) * 6.4 - (0.8 if side else 0.0)
				var py := hy - 1.2 + sin(a) * 5.0
				b.circ(px, py, 2.3, hair)
				b.pset(int(px) - 1, int(py) - 1, Pal.hi(hair))
			if dir == 1:
				for i in 4:
					b.circ(hx - 4.5 + i * 3.0, hy + 3.0, 2.0, Pal.shade(hair))
		"slick":
			b.ball(hx - (1.0 if side else 0.0), hy - 2.6, 6.6, 4.4, hair, head[0], head[1], head[2], head[3])
			for k in 3:
				b.rect(hx - 4 + k * 3 - (1.0 if side else 0.0), hy - 6, 1, 3, Pal.shade(hair))
		"messy":
			b.tri(hx - 4, hy - 5, hx - 1, hy - 5, hx - 3.5, hy - 8, hair)
			b.tri(hx + 0, hy - 5.5, hx + 3, hy - 5.5, hx + 2.5, hy - 8.5, hair)


static func _flatten_face(b: PixBuf, skin: Color, ey: int) -> void:
	## Faces stay the bright skin colour: no shading at all above the eye line,
	## and below it only a soft shade along the jaw (never the deep band).
	var tones := [skin, Pal.shade(skin), Pal.deep(skin), Pal.hi(skin)]
	var is_skin := func(c: Color) -> bool:
		if c.a < 0.5:
			return false
		for t: Color in tones:
			if absf(c.r - t.r) < 0.01 and absf(c.g - t.g) < 0.01 and absf(c.b - t.b) < 0.01:
				return true
		return false
	var src := b.img.duplicate() as Image
	for y in b.h:
		for x in b.w:
			var c := src.get_pixel(x, y)
			if not is_skin.call(c):
				continue
			var jaw_edge: bool = y >= ey + 3 and (y + 1 >= b.h or not is_skin.call(src.get_pixel(x, y + 1)))
			b.pset(x, y, Pal.shade(skin) if jaw_edge else skin)


static func _hair_front(b: PixBuf, s: Dictionary, style: String, hair: Color, dir: int, hx: float, hy: float, head: Array) -> void:
	## Fringes and the like that fall over the face.
	if dir == 1:
		return
	var side := dir == 2
	match style:
		"hiro":
			if side:
				b.tri(hx + 1, hy - 4.5, hx + 6, hy - 4, hx + 5.5, hy - 1.0, hair)
			else:
				b.tri(hx - 6.5, hy - 3.5, hx + 1.5, hy - 4.5, hx - 4.5, hy + 0.2, hair)
				b.tri(hx + 0.5, hy - 4.5, hx + 5.5, hy - 3.5, hx + 3.5, hy - 1.8, hair)
		"ponytail":
			if not side:
				b.tri(hx - 6, hy - 3.5, hx - 0.5, hy - 4.2, hx - 4.8, hy - 0.5, hair)
		"curly":
			if not side:
				b.ball(hx - 3.5, hy - 3.6, 2.2, 1.6, hair)
				b.ball(hx + 1.5, hy - 3.9, 2.4, 1.6, hair)
		"messy":
			if not side:
				b.tri(hx - 2.5, hy - 4.6, hx + 2.0, hy - 4.6, hx - 0.5, hy - 2.4, hair)


static func _face(b: PixBuf, s: Dictionary, dir: int, mood: String, hx: float, hy: float, skin: Color, head: Array) -> void:
	var side := dir == 2
	var fx := hx + (1.8 if side else 0.0)
	var fy := hy + 1.4
	# Light the face as a taller form centred above it, so shadow only reaches
	# the chin and jaw line instead of crossing the cheeks and mouth.
	b.ball(fx, fy, 4.6 if side else 5.3, 4.2, skin, fx - 0.6, fy - 2.6, 7.2, 7.4)
	# Big chibi eyes, drawn at 1:1 so every eye pixel stays crisp.
	b.scale_about(Vector2.ZERO, 1.0)
	var ix := int(hx)
	var ey := int(hy) + 1
	_flatten_face(b, skin, ey)
	var iris: Color = s.get("eye", Pal.INK2.lerp(Pal.SKY, 0.5))
	# Talking variants ride along on the mood: "sad+blink", "+open", ...
	var flags := mood.split("+")
	mood = flags[0]
	var blink := flags.has("blink")
	var open := flags.has("open")
	if s.get("hollow", false) and mood == "":
		mood = "hollow"
	var eyes: Array = [ix + 3] if side else [ix - 4, ix + 2]
	for i in eyes.size():
		var ex: int = eyes[i]
		var patched: bool = s.get("patch", false) and (side or i == 0)
		if patched:
			b.rect(ex, ey, 2, 3, Pal.INK2)
			b.pset(ex - 1, ey + 1, Pal.INK2)
			b.pset(ex + 1, ey, Pal.SLATE)
			continue
		match "closed" if blink else mood:
			"closed":
				b.rect(ex, ey + 2, 2, 1, Pal.INK)
			"hollow":
				b.rect(ex, ey + 1, 2, 2, Pal.INK2)
				b.pset(ex + 1, ey + 2, Pal.SYNC.lerp(Pal.INK2, 0.3))
			"shock":
				b.rect(ex, ey, 2, 3, Pal.WHITE)
				b.pset(ex + (1 if i == 0 else 0), ey + 1, Pal.INK)
			"sad", "cry":
				b.rect(ex, ey + 1, 2, 2, Pal.INK)
				b.pset(ex, ey + 1, Pal.WHITE)
				b.pset(ex + (1 if i == 0 else 0) - (0 if i == 0 else 0), ey - 1, Pal.shade(skin).lerp(Pal.INK2, 0.5))
				if mood == "cry":
					b.pset(ex + 1, ey + 3, Pal.SKY)
					b.pset(ex + 1, ey + 4, Pal.hi(Pal.SKY))
			"angry":
				b.rect(ex, ey + 1, 2, 2, Pal.INK)
				b.pset(ex + (1 if i == 0 else 0), ey + 1, Pal.WHITE)
				b.pset(ex + (1 if i == 0 else 0), ey - 1, Pal.INK2)
				b.pset(ex + (0 if i == 0 else 1), ey, Pal.INK2)
			_:
				b.rect(ex, ey, 2, 3, Pal.INK)
				b.pset(ex, ey, Pal.WHITE)
				b.pset(ex + 1, ey + 2, iris)
		if s.get("glasses", false):
			b.rect(ex - 1, ey - 1, 4, 1, Pal.INK2)
			b.pset(ex - 1, ey + 2, Pal.INK2)
			b.pset(ex + 2, ey + 2, Pal.INK2)
	if s.get("patch", false) and not side:
		b.line(ix - 6, ey - 2, ix + 4, ey - 5, Pal.INK2)
	var blush := Pal.PINK.lerp(Pal.ROSE, 0.3)
	var mouth := Pal.shade(skin).lerp(Pal.INK2, 0.4)
	if side:
		if mood != "hollow":
			b.rect(ix + 1, ey + 3, 2, 1, blush)
		b.pset(ix + 6, ey + 2, Pal.shade(skin))
		if s.get("mustache", false):
			b.rect(ix + 4, ey + 3, 3, 1, Pal.deep(s.get("hair", Pal.BARK)))
	else:
		if mood != "hollow" and not s.get("adult", false):
			b.rect(ix - 6, ey + 3, 2, 1, blush)
			b.rect(ix + 4, ey + 3, 2, 1, blush)
		if s.get("mustache", false):
			b.rect(ix - 2, ey + 4, 4, 1, Pal.deep(s.get("hair", Pal.BARK)))
		elif mood == "smile" or (mood == "" and s.get("smile", false)):
			b.pset(ix - 1, ey + 4, Pal.INK2)
			b.pset(ix, ey + 4, Pal.INK2)
		elif mood == "sad" or mood == "cry":
			b.pset(ix - 1, ey + 5, Pal.INK2)
			b.pset(ix, ey + 4, mouth)
		elif mood == "shock":
			b.rect(ix - 1, ey + 4, 2, 2, Pal.INK2)
		else:
			b.pset(ix, ey + 4, mouth)
		if open:
			var my := ey + (5 if s.get("mustache", false) else 4)
			b.rect(ix - 1, my, 2, 2, Pal.INK2)
			b.pset(ix - 1, my + 1, Pal.ROSE)
		if s.get("scar", false):
			b.pset(ix + 4, ey + 1, Pal.ROSE.lerp(skin, 0.4))
			b.pset(ix + 5, ey + 2, Pal.ROSE.lerp(skin, 0.4))
