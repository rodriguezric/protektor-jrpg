class_name ArtTiles
## Field ground: one image per map, built pixel by pixel from the tile rows
## (Greywater's approach), so seams, trims and wall faces never visibly repeat.
## Tiles: # wall, W window wall, D door (in a wall), . floor, , rug/carpet,
## : tiles, = guide strip, _ grate, g grass, ~ road, + red carpet, space = void.
## Walls are drawn in 3/4 view: the two wall rows above a floor become a face.

const TILE := 16
const WALLS := "#WD "


static func is_wall(ch: String) -> bool:
	return WALLS.contains(ch)


static func ground(rows: Array, theme: String) -> Image:
	var tw: int = (rows[0] as String).length()
	var th: int = rows.size()
	var w := tw * TILE
	var h := th * TILE
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var at := func(tx: int, ty: int) -> String:
		if tx < 0 or ty < 0 or tx >= tw or ty >= th:
			return " "
		return (rows[ty] as String)[tx]
	for ty in th:
		for tx in tw:
			var ch: String = at.call(tx, ty)
			var below: String = at.call(tx, ty + 1)
			var below2: String = at.call(tx, ty + 2)
			var mode := "floor"
			if ch == " ":
				mode = "void"
			elif is_wall(ch):
				if not is_wall(below):
					mode = "face_low"
				elif not is_wall(below2) and below != " ":
					mode = "face_high"
				else:
					mode = "top"
			for ly in TILE:
				for lx in TILE:
					var x := tx * TILE + lx
					var y := ty * TILE + ly
					var c: Color
					match mode:
						"void":
							c = Pal.INK
						"top":
							c = _wall_top(theme, x, y, lx, ly, at.call(tx, ty + 1) == " " or ty == th - 1)
						"face_high", "face_low":
							c = _wall_face(theme, ch, x, y, lx, ly + (0 if mode == "face_high" else TILE), at, tx, ty)
						_:
							c = _floor(theme, ch, x, y, lx, ly, at, tx, ty)
					img.set_pixel(x, y, c)
	# soft contact shadow under every wall face
	for ty in th:
		for tx in tw:
			if is_wall(at.call(tx, ty)) or not is_wall(at.call(tx, ty - 1)) or at.call(tx, ty - 1) == " ":
				continue
			for lx in TILE:
				for k in 3:
					var x := tx * TILE + lx
					var y := ty * TILE + k
					img.set_pixel(x, y, img.get_pixel(x, y).lerp(Pal.INK, 0.35 - k * 0.1))
	return img


static func _wall_top(theme: String, x: int, y: int, lx: int, ly: int, edge: bool) -> Color:
	var base := Pal.NAVY.lerp(Pal.INK, 0.45)
	if theme == "home":
		base = Pal.BARK.lerp(Pal.INK, 0.45)
	elif theme == "outdoor":
		base = Pal.PINE.lerp(Pal.INK, 0.5)
	var c := base
	if (x / 32 + y / 32) % 2 == 0:
		c = base.lerp(Pal.INK, 0.12)
	if Pal.hash2(x, y, 3) > 0.985:
		c = base.lerp(Pal.SLATE, 0.3)
	return c


static func _wall_face(theme: String, ch: String, x: int, y: int, lx: int, fy: int, at: Callable, tx: int, ty: int) -> Color:
	## fy: 0..31 down the two-tile face.
	var c: Color
	if theme == "home":
		var paper := Pal.CREAM.lerp(Pal.PEACH, 0.35)
		c = paper if (x / 3) % 3 != 0 else paper.lerp(Pal.ROSE, 0.12)
		if fy <= 1:
			c = Pal.WOOD.lerp(Pal.BARK, 0.3)
		elif fy >= 27:
			c = Pal.WOOD if fy < 31 else Pal.shade(Pal.WOOD)
			if fy == 27:
				c = Pal.hi(Pal.WOOD)
		elif fy == 2:
			c = Pal.shade(paper)
	elif theme == "outdoor":
		var brick := Pal.ROSE.lerp(Pal.STONE, 0.55)
		c = brick
		var row := fy / 4
		if fy % 4 == 0 or (x + (row % 2) * 4) % 8 == 0:
			c = Pal.shade(brick)
		if fy <= 1:
			c = Pal.STONE
	else:
		var panel := Pal.FROST.lerp(Pal.STEEL, 0.45)
		c = panel
		if x % 24 == 0:
			c = Pal.shade(panel)
		elif x % 24 == 1:
			c = Pal.hi(panel).lerp(panel, 0.5)
		if fy <= 1:
			c = Pal.hi(panel)
		elif fy == 9 or fy == 10:
			c = Pal.TEAL.lerp(Pal.SYNC, 0.35) if fy == 9 else Pal.TEAL.lerp(Pal.INK, 0.2)
		elif fy >= 27:
			c = Pal.SLATE if fy < 31 else Pal.deep(Pal.SLATE)
			if fy == 27:
				c = Pal.STEEL
		elif Pal.hash2(x, y, 9) > 0.97:
			c = panel.lerp(Pal.SLATE, 0.3)
	if ch == "W":
		c = _window(theme, x, y, lx, fy, c)
	elif ch == "D":
		c = _door(theme, lx, fy, c)
	return c


static func _window(theme: String, x: int, y: int, lx: int, fy: int, wall: Color) -> Color:
	if fy < 4 or fy > 24 or lx < 1 or lx > 14:
		return wall
	var frame := Pal.SLATE if theme != "home" else Pal.WOOD
	if fy == 4 or fy == 24 or lx == 1 or lx == 14:
		return frame
	if fy == 5 or lx == 2:
		return Pal.shade(frame)
	var sky := Pal.NAVY.lerp(Pal.INK, 0.5)
	var c := sky.lerp(Pal.PLUM, float(fy) / 40.0)
	if Pal.hash2(x, y, 41) > 0.965:
		c = Pal.WHITE.lerp(sky, Pal.hash2(x, y, 42) * 0.6)
	if theme == "home":
		# night city: lit windows on dark blocks, shield grid lines in the sky
		var block_top := 14 + int(Pal.hash2(x / 5, 2) * 6)
		if fy > block_top:
			c = Pal.INK2.lerp(Pal.INK, 0.3)
			if (x % 3 == 0) and fy % 3 == 0 and Pal.hash2(x, fy, 7) > 0.5:
				c = Pal.LEMON.lerp(Pal.HONEY, 0.4)
		if (x + fy * 2) % 13 == 0 and fy < block_top:
			c = c.lerp(Pal.SYNC, 0.35)
	return c


static func _door(theme: String, lx: int, fy: int, wall: Color) -> Color:
	if lx < 2 or lx > 13 or fy < 6:
		return wall
	var c := Pal.STEEL.lerp(Pal.NAVY, 0.4) if theme != "home" else Pal.WOOD
	if lx == 2 or lx == 13 or fy == 6:
		return Pal.deep(c)
	if theme != "home" and (lx == 7 or lx == 8):
		return Pal.INK2
	if theme != "home" and fy == 12 and (lx == 4 or lx == 11):
		return Pal.SYNC.lerp(Pal.TEAL, 0.4)
	if theme == "home" and lx == 11 and fy == 18:
		return Pal.HONEY
	return c if fy % 8 != 7 else Pal.shade(c)


static func _floor(theme: String, ch: String, x: int, y: int, lx: int, ly: int, at: Callable, tx: int, ty: int) -> Color:
	var n := Pal.noise(x, y, 2.0)
	var hs := Pal.hash2(x, y)
	var c: Color
	match ch:
		",":
			if theme == "home":
				var rug := Pal.ROSE.lerp(Pal.INK2, 0.35)
				c = rug
				var edge_x: bool = at.call(tx - 1, ty) != "," and lx < 2 or at.call(tx + 1, ty) != "," and lx > 13
				var edge_y: bool = at.call(tx, ty - 1) != "," and ly < 2 or at.call(tx, ty + 1) != "," and ly > 13
				if edge_x or edge_y:
					c = Pal.HONEY.lerp(Pal.ROSE, 0.4)
				elif (x + y) % 6 == 0:
					c = rug.lerp(Pal.LEMON, 0.15)
			else:
				c = Pal.NAVY.lerp(Pal.SLATE, 0.25)
				if hs > 0.9:
					c = Pal.shade(c)
				elif hs < 0.05:
					c = c.lerp(Pal.SKY, 0.2)
		":":
			if theme == "home":
				c = Pal.CREAM if ((x / 8) + (y / 8)) % 2 == 0 else Pal.STONE.lerp(Pal.CREAM, 0.3)
				if x % 8 == 0 or y % 8 == 0:
					c = Pal.shade(c)
			else:
				c = Pal.FROST.lerp(Pal.WHITE, 0.25)
				if x % 8 == 0 or y % 8 == 0:
					c = Pal.FROST.lerp(Pal.STEEL, 0.5)
				elif hs > 0.97:
					c = Pal.shade(Pal.FROST)
		"_":
			c = Pal.INK2.lerp(Pal.INK, 0.2)
			if x % 3 == 0 or y % 3 == 0:
				c = Pal.SLATE.lerp(Pal.INK2, 0.5)
		"g":
			c = Pal.GRASS
			if n > 0.42:
				c = Pal.GRASS.lerp(Pal.LEMON, 0.18)
			elif n < -0.38:
				c = Pal.GRASS.lerp(Pal.INK, 0.1)
			if hs > 0.955:
				c = Pal.GRASS.lerp(Pal.PINE, 0.45)
		"~":
			c = Pal.ASPHALT
			if n > 0.4:
				c = Pal.ASPHALT.lerp(Pal.SLATE, 0.25)
			if hs > 0.96:
				c = Pal.ASPHALT.lerp(Pal.STONE, 0.4)
		"+":
			c = Pal.RED.lerp(Pal.ROSE, 0.4)
			if lx == 0 or lx == 15:
				c = c
			if (at.call(tx - 1, ty) != "+" and lx < 1) or (at.call(tx + 1, ty) != "+" and lx > 14):
				c = Pal.LEMON.lerp(Pal.HONEY, 0.5)
			elif hs > 0.93:
				c = Pal.shade(c)
		_:
			c = _base_floor(theme, x, y, lx, ly, n, hs)
	if ch == "=":
		var horiz: bool = at.call(tx - 1, ty) == "=" or at.call(tx + 1, ty) == "="
		var d := ly if horiz else lx
		var along := lx if horiz else ly
		if d == 7 or d == 8:
			c = Pal.TEAL.lerp(Pal.SYNC, 0.55) if (along / 4) % 2 == 0 else Pal.TEAL.lerp(Pal.INK, 0.1)
		elif d == 6 or d == 9:
			c = c.lerp(Pal.TEAL, 0.3)
	return c


static func _base_floor(theme: String, x: int, y: int, lx: int, ly: int, n: float, hs: float) -> Color:
	var c: Color
	match theme:
		"home":
			var plank := Pal.WOOD.lerp(Pal.PEACH, 0.3)
			var row := y / 5
			c = plank.lerp(Pal.BARK, Pal.hash2(row, (x + row * 11) / 22, 3) * 0.18)
			if y % 5 == 0:
				c = Pal.shade(plank)
			elif (x + row * 11) % 22 == 0:
				c = Pal.shade(plank)
			elif n > 0.5:
				c = c.lerp(Pal.LEMON, 0.08)
		"outdoor":
			var tint := Pal.hash2(x / 8, y / 8, 3)
			c = Pal.STONE.lerp(Pal.SLATE, 0.25 * tint)
			if hs > 0.97:
				c = Pal.shade(c)
			if x % 8 == 0 or y % 8 == 0:
				c = Pal.shade(Pal.STONE)
		_:
			var panel := Pal.STEEL.lerp(Pal.SLATE, 0.45)
			c = panel
			if Pal.hash2(x / 16, y / 16, 5) > 0.7:
				c = panel.lerp(Pal.NAVY, 0.15)
			if lx == 0 or ly == 0:
				c = Pal.shade(panel)
			elif lx == 1 or ly == 1:
				c = c.lerp(Pal.LIGHT_TINT, 0.1)
			elif (lx == 3 or lx == 12) and (ly == 3 or ly == 12):
				c = Pal.deep(panel)
			elif n > 0.55:
				c = c.lerp(Pal.FROST, 0.08)
	return c
