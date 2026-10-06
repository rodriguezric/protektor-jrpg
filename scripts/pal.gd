class_name Pal
## One murky palette for everything (shared with Greywater). INK (purple-grey) is
## shared by shadows, outlines and eyes, which is what makes every sprite feel like
## part of a set. Protektor adds a cold "academy" family and one saturated colour,
## SYNC cyan, which only ever means the machine.

const INK := Color("16131f")
const INK2 := Color("383148")
const WHITE := Color("e6e1d3")
const CREAM := Color("c9c0a8")
const PEACH := Color("a8907a")
const PINK := Color("94707f")
const ROSE := Color("8a4458")
const RED := Color("a83838")
const ORANGE := Color("b0703c")
const HONEY := Color("a8893f")
const LEMON := Color("d6cf72")
const MINT := Color("78a596")
const SAGE := Color("5c7b66")
const GRASS := Color("56684f")
const LEAF := Color("465f49")
const PINE := Color("2c4440")
const TEAL := Color("3d7672")
const SKY := Color("8496a0")
const BLUE := Color("4a6688")
const LILAC := Color("776d8f")
const PURPLE := Color("5a4677")
const PLUM := Color("3a2b4e")
const SKIN := Color("d9c6b2")
const SKIN2 := Color("b5917a")
const SKIN3 := Color("7a5a48")
const WOOD := Color("6b5243")
const BARK := Color("463631")
const STONE := Color("97969c")
const SLATE := Color("66667a")
const DIRT := Color("766752")
const WATER := Color("344f5c")
const ASPHALT := Color("3f3f4a")

# Academy: sterile, cold, a little blue.
const STEEL := Color("7d8798")
const NAVY := Color("2b3550")
const FROST := Color("b9c4cc")
const AUBURN := Color("a65a3a")

# Glows: the only saturated colours, so they always read as "not human".
const SYNC := Color("7fe4ee")
const GLOW := Color("9cf08c")
const VOID := Color("a777f0")
const BLOOD := Color("d0484a")
const EMBER := Color("f0a050")

# UI: dark panels, bone text.
const TEXT := Color("e6e1d3")
const TEXT_DIM := Color("7c768c")
const PANEL := Color("231f2f")
const PANEL2 := Color("1c1926")

const LIGHT_TINT := Color("dfe6c8")


static func hi(c: Color) -> Color:
	return c.lerp(LIGHT_TINT, 0.45)


static func shade(c: Color) -> Color:
	return c.lerp(INK, 0.25)


static func deep(c: Color) -> Color:
	return c.lerp(INK, 0.45)


static func dark(c: Color) -> Color:
	## Outline colour: a darker version of the neighbouring colour.
	var d := c.lerp(INK, 0.62)
	d.a = 1.0
	return d


static func band(c: Color, l: float) -> Color:
	## Four lighting bands instead of smooth gradients.
	if l > 0.78:
		return hi(c)
	if l > 0.22:
		return c
	if l > -0.3:
		return shade(c)
	return deep(c)


static func hash2(x: int, y: int, s: int = 0) -> float:
	var n: int = x * 374761393 + y * 668265263 + s * 2246822519
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0xffff) / 65535.0


static func noise(x: float, y: float, s: float = 0.0) -> float:
	## Cheap layered sine noise in roughly -1..1.
	return (sin(x * 0.19 + sin(y * 0.11 + s) * 2.1) + sin(y * 0.23 + x * 0.07 + s * 1.7) * 0.7 + sin((x + y) * 0.051 + s * 0.3) * 0.5) / 2.2
