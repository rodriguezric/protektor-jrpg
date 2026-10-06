class_name Maps
## Field maps. Tiles: # wall, W window wall, D door, . floor, , rug, : tiles,
## = guide strip, _ grate, g grass, ~ road, + red carpet, space = void.
## Two wall rows above a floor render as a tall wall face (3/4 view).

const WARM := Color(1.0, 0.92, 0.84)
const NIGHT := Color(0.42, 0.48, 0.72)
const STERILE := Color(0.92, 0.96, 1.0)
const COLD := Color(0.8, 0.86, 0.98)
const DIM := Color(0.66, 0.7, 0.86)


static func p(kind: String, x: int, y: int, extra: Dictionary = {}) -> Dictionary:
	var d := {"kind": kind, "tile": Vector2i(x, y)}
	d.merge(extra)
	return d


# ------------------------------------------------------------------ home ---

static func home() -> Dictionary:
	var rows := [
		"#WW#####WW##D#########",
		"#WW#####WW##D###WW####",
		"#::::::::.....#......#",
		"#::::::::.....#......#",
		"#::::::::.....#......#",
		"#........,,,,.#......#",
		"#........,,,,.#......#",
		"#........,,,,........#",
		"#........,,,,........#",
		"#.............#......#",
		"#.............#......#",
		"######################",
	]
	var props := [
		p("counter", 2, 2, {"offset": Vector2(8, 0), "v": 1, "area": Rect2i(2, 2, 2, 1), "event": {"id": "sink"}}),
		p("counter", 4, 2, {"offset": Vector2(8, 0), "area": Rect2i(4, 2, 2, 1), "event": {"id": "packet"}}),
		p("packet", 4, 2, {"offset": Vector2(12, -1), "lift": 13, "id": "packet", "area": Rect2i()}),
		p("stove", 6, 2, {"event": {"id": "stove"}, "light": Pal.EMBER, "lr": 10, "light_off": Vector2(0, -10), "pulse": 3.0}),
		p("fridge", 7, 2, {"event": {"id": "fridge"}}),
		p("heater", 9, 2, {"anim": 2, "fps": 0.7, "event": {"id": "heater"}}),
		p("shelf", 13, 2, {"event": {"id": "photo"}}),
		p("foldbed", 11, 3, {"offset": Vector2(0, 0), "area": Rect2i(10, 3, 3, 1), "event": {"id": "foldbed"}}),
		p("table", 4, 6, {"offset": Vector2(8, 0), "area": Rect2i(4, 6, 2, 1), "event": {"id": "table"}}),
		p("letter", 4, 6, {"offset": Vector2(2, 1), "lift": 12, "id": "letter", "area": Rect2i()}),
		p("cup", 5, 6, {"offset": Vector2(6, 1), "lift": 12, "area": Rect2i()}),
		p("chair", 3, 6, {"offset": Vector2(2, 0), "area": Rect2i()}),
		p("chair", 6, 6, {"offset": Vector2(-2, 0), "area": Rect2i()}),
		p("lamp", 13, 9, {"light": Pal.LEMON, "lr": 26, "light_off": Vector2(0, -24), "pulse": 1.5}),
		p("plant", 1, 9, {}),
		p("kidbed", 19, 3, {"area": Rect2i(19, 2, 1, 2), "event": {"id": "bed"}}),
		p("plant", 15, 2, {}),
		p("lamp", 20, 9, {"light": Pal.LEMON, "lr": 20, "light_off": Vector2(0, -24), "id": "kidlamp"}),
	]
	return {"id": "home", "name": "Home, Block 7", "theme": "home", "tint": WARM, "outfit": "home", "rows": rows, "props": props,
		"npcs": [], "exits": [], "triggers": [], "music": "letter_discussion",
		"events": [{"tile": Vector2i(12, 1), "id": "frontdoor"}, {"tile": Vector2i(1, 1), "id": "window"}, {"tile": Vector2i(2, 1), "id": "window"},
			{"tile": Vector2i(8, 1), "id": "window"}, {"tile": Vector2i(9, 1), "id": "window"}, {"tile": Vector2i(16, 1), "id": "window"}, {"tile": Vector2i(17, 1), "id": "window"}]}


# ---------------------------------------------------------------- parade ---

static func parade() -> Dictionary:
	var rows := [
		"##WW####WW####WW####WW####WW##",
		"##WW####WW####WW####WW####WW##",
		"..............................",
		"..............................",
		"..............................",
		"..............................",
		"..............................",
		"..............................",
		"..............................",
		"++++++++++++++++++++++++++++..",
		"..............................",
		"..............................",
		"gggggggggggggggggggggggggggggg",
		"gggggggggggggggggggggggggggggg",
		"gggggggggggggggggggggggggggggg",
		"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	]
	var props := [
		p("stage", 14, 4, {"offset": Vector2(8, 0), "area": Rect2i(11, 2, 7, 3)}),
		p("mech", 6, 7, {"area": Rect2i(5, 5, 3, 3), "anim": 2, "fps": 1.2, "id": "mech1", "light": Pal.SYNC, "lr": 14, "light_off": Vector2(0, -44), "pulse": 2.0}),
		p("mech", 22, 7, {"area": Rect2i(21, 5, 3, 3), "anim": 2, "fps": 1.2, "id": "mech2", "light": Pal.SYNC, "lr": 14, "light_off": Vector2(0, -44), "pulse": 2.0}),
		p("pole", 2, 7, {"v": 0}), p("pole", 10, 7, {"v": 1}), p("pole", 18, 7, {"v": 1}), p("pole", 26, 4, {"v": 0}),
		p("speaker", 9, 3, {}), p("speaker", 19, 3, {}),
		p("shuttle", 27, 10, {"offset": Vector2(0, 0), "id": "shuttle", "area": Rect2i(25, 7, 5, 3)}),
	]
	for x in range(1, 27, 2):
		props.append(p("barrier", x, 11, {"offset": Vector2(8, 0), "area": Rect2i(x, 11, 2, 1)}))
	var npcs := [
		{"id": "announcer", "who": "announcer", "tile": Vector2i(14, 3), "dir": 0, "offset": Vector2(8, -4)},
		{"id": "hiro", "who": "hiro", "tile": Vector2i(11, 9), "dir": 1, "mood": "smile"},
		{"id": "pala", "who": "pala", "tile": Vector2i(13, 9), "dir": 1},
		{"id": "midas", "who": "midas", "tile": Vector2i(15, 9), "dir": 1, "mood": "sad"},
	]
	var ex := Data.EXTRAS
	var xs := [5, 7, 9, 19, 21]
	for i in xs.size():
		npcs.append({"id": "rec%d" % i, "spec": ex[i], "tile": Vector2i(xs[i], 9), "dir": 1})
	for i in 16:
		var cx := 1 + i * 2 + (i % 2)
		if cx >= 29:
			continue
		var spec: Dictionary = Data.CROWD[i % Data.CROWD.size()]
		npcs.append({"id": "crowd%d" % i, "spec": spec, "tile": Vector2i(cx, 12 + (i % 2)), "dir": 1, "no_turn": true})
	npcs.append({"id": "mother", "who": "mother", "tile": Vector2i(4, 13), "dir": 1, "mood": "sad"})
	npcs.append({"id": "father", "who": "father", "tile": Vector2i(6, 13), "dir": 1})
	return {"id": "parade", "name": "Helion Plaza", "theme": "outdoor", "tint": Color(1.05, 1.02, 0.95), "outfit": "parade", "rows": rows, "props": props,
		"npcs": npcs, "triggers": [{"rect": Rect2i(17, 9, 1, 1), "id": "lineup"}], "exits": []}


# ------------------------------------------------------------------ hall ---

static func hall() -> Dictionary:
	var rows := [
		"####################",
		"####################",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#........==........#",
		"####################",
	]
	var props := [
		p("podium", 10, 4, {"offset": Vector2(-8, 0), "area": Rect2i(9, 4, 2, 1)}),
		p("banner", 4, 1, {"wall": true, "area": Rect2i()}), p("banner", 15, 1, {"wall": true, "v": 1, "area": Rect2i()}),
		p("banner", 9, 1, {"wall": true, "offset": Vector2(8, 0), "area": Rect2i()}),
		p("pillar", 2, 4, {}), p("pillar", 17, 4, {}),
		p("pillar", 2, 10, {}), p("pillar", 17, 10, {}),
	]
	for r in [7, 9, 11]:
		for x in [5, 14]:
			props.append(p("bench", x, r, {"area": Rect2i(x - 1, r, 3, 1)}))
	var npcs := [
		{"id": "instructor", "who": "instructor", "tile": Vector2i(10, 3), "dir": 0, "offset": Vector2(-8, 0)},
		{"id": "hiro", "who": "hiro", "tile": Vector2i(4, 9), "dir": 1, "pose": "sit", "mood": "smile"},
		{"id": "pala", "who": "pala", "tile": Vector2i(6, 9), "dir": 1, "pose": "sit"},
		{"id": "midas", "who": "midas", "tile": Vector2i(5, 11), "dir": 1, "pose": "sit", "mood": "sad"},
	]
	var seats := [Vector2i(4, 7), Vector2i(5, 7), Vector2i(6, 7), Vector2i(13, 7), Vector2i(14, 7), Vector2i(15, 7),
		Vector2i(13, 9), Vector2i(14, 9), Vector2i(15, 9), Vector2i(4, 11), Vector2i(6, 11), Vector2i(13, 11), Vector2i(15, 11)]
	for i in seats.size():
		npcs.append({"id": "rec%d" % i, "spec": Data.EXTRAS[i % Data.EXTRAS.size()], "tile": seats[i], "dir": 1, "pose": "sit"})
	return {"id": "hall", "name": "Orientation Hall", "theme": "academy", "tint": STERILE, "rows": rows, "props": props, "npcs": npcs}


# -------------------------------------------------------------- corridor ---

static func corridor() -> Dictionary:
	var rows := [
		"#####D#####D#####D######WW#WW#####",
		"#####D#####D#####D######WW#WW#####",
		"#................................#",
		"#................................#",
		"#=====================...........#",
		"#................................#",
		"#................................#",
		"##################################",
	]
	var props := [
		p("pod", 26, 3, {"decal": true, "anim": 8, "fps": 6.0, "id": "pod1", "light": Pal.SYNC, "lr": 18, "light_off": Vector2(0, -10), "pulse": 3.0}),
		p("pod", 30, 3, {"decal": true, "anim": 8, "fps": 4.0}),
		p("pod", 26, 6, {"decal": true, "anim": 8, "fps": 4.0}),
		p("pod", 30, 6, {"decal": true, "anim": 8, "fps": 4.0}),
		p("console", 32, 2, {"anim": 2, "fps": 2.0, "area": Rect2i(31, 2, 2, 1), "light": Pal.SYNC, "lr": 12}),
		p("pillar", 22, 2, {}),
	]
	var npcs := [{"id": "instructor", "who": "instructor", "tile": Vector2i(23, 4), "dir": 3}]
	for i in 4:
		npcs.append({"id": "rec%d" % i, "spec": Data.EXTRAS[(i + 3) % Data.EXTRAS.size()], "tile": Vector2i(4 + i, 3 + (i % 2) * 2), "dir": 2})
	npcs.append({"id": "hiro", "who": "hiro", "tile": Vector2i(29, 3), "dir": 0, "mood": "smile"})
	npcs.append({"id": "pala", "who": "pala", "tile": Vector2i(29, 6), "dir": 1})
	npcs.append({"id": "midas", "who": "midas", "tile": Vector2i(31, 6), "dir": 3, "mood": "sad"})
	return {"id": "corridor", "name": "Pairing Wing", "theme": "academy", "tint": COLD, "rows": rows, "props": props, "npcs": npcs,
		"triggers": [{"rect": Rect2i(26, 2, 2, 3), "id": "pod"}]}


# -------------------------------------------------------------- briefing ---

static func briefing() -> Dictionary:
	var rows := [
		"####################",
		"####################",
		"#..................#",
		"#..................#",
		"#.......____.......#",
		"#.......____.......#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"#..................#",
		"####################",
	]
	var props := [
		p("holo", 10, 5, {"offset": Vector2(-8, 0), "area": Rect2i(8, 5, 4, 1), "planet": "green_planet", "id": "holo"}),
		p("console", 3, 2, {"anim": 2, "fps": 2.0, "area": Rect2i(2, 2, 2, 1), "light": Pal.SYNC, "lr": 12}),
		p("console", 16, 2, {"anim": 2, "fps": 1.5, "area": Rect2i(15, 2, 2, 1), "light": Pal.SYNC, "lr": 12}),
		p("banner", 6, 1, {"wall": true, "area": Rect2i()}), p("banner", 13, 1, {"wall": true, "area": Rect2i()}),
	]
	for r in [8, 10]:
		for x in [5, 14]:
			props.append(p("bench", x, r, {"area": Rect2i(x - 1, r, 3, 1)}))
	var npcs := [
		{"id": "instructor", "who": "instructor", "tile": Vector2i(13, 4), "dir": 3},
		{"id": "hiro", "who": "hiro", "tile": Vector2i(4, 8), "dir": 1, "pose": "sit", "mood": "smile"},
		{"id": "pala", "who": "pala", "tile": Vector2i(13, 8), "dir": 1, "pose": "sit"},
		{"id": "midas", "who": "midas", "tile": Vector2i(6, 10), "dir": 1, "pose": "sit", "mood": "sad"},
		{"id": "rec0", "spec": Data.EXTRAS[1], "tile": Vector2i(15, 10), "dir": 1, "pose": "sit"},
		{"id": "rec1", "spec": Data.EXTRAS[4], "tile": Vector2i(14, 8), "dir": 1, "pose": "sit"},
	]
	return {"id": "briefing", "name": "Briefing Hall", "theme": "academy", "tint": Color(0.86, 0.92, 1.0), "rows": rows, "props": props, "npcs": npcs}


# --------------------------------------------------------------- waiting ---

static func waiting() -> Dictionary:
	var rows := [
		"############",
		"#####D######",
		"#..........#",
		"#..........#",
		"#..........#",
		"#..........#",
		"#..........#",
		"############",
	]
	var props := [
		p("bench", 3, 2, {"v": 1, "offset": Vector2(0, -3), "area": Rect2i(2, 2, 3, 1)}),
		p("bench", 8, 2, {"v": 1, "offset": Vector2(0, -3), "area": Rect2i(7, 2, 3, 1)}),
		p("bench", 5, 6, {"v": 0, "area": Rect2i(4, 6, 3, 1)}),
	]
	var npcs := [
		{"id": "hiro", "who": "hiro", "tile": Vector2i(9, 4), "dir": 3},
		{"id": "pala", "who": "pala", "tile": Vector2i(3, 2), "dir": 0, "pose": "sit", "offset": Vector2(0, 3)},
		{"id": "midas", "who": "midas", "tile": Vector2i(8, 2), "dir": 0, "pose": "sit", "offset": Vector2(0, 3), "mood": "sad"},
	]
	return {"id": "waiting", "name": "Staging Room", "theme": "academy", "tint": DIM, "rows": rows, "props": props, "npcs": npcs}


# -------------------------------------------------------------- recovery ---

static func recovery() -> Dictionary:
	var rows := [
		"##############",
		"##############",
		"#::::::::::::#",
		"#::::::::::::#",
		"#::::::::::::#",
		"#::::::::::::#",
		"#::::::::::::#",
		"#::::::::::::#",
		"##############",
	]
	var props := [
		p("medbed", 2, 3, {"area": Rect2i(2, 2, 1, 2)}), p("medbed", 4, 3, {"area": Rect2i(4, 2, 1, 2)}),
		p("medbed", 11, 3, {"area": Rect2i(11, 2, 1, 2)}),
		p("scanner", 7, 5, {"offset": Vector2(8, 0), "anim": 6, "fps": 6.0, "id": "scanner", "area": Rect2i(), "light": Pal.SYNC, "lr": 20, "pulse": 4.0}),
		p("bench", 10, 7, {"v": 1, "offset": Vector2(0, -3), "area": Rect2i(9, 7, 3, 1)}),
		p("terminal", 12, 5, {"anim": 2, "fps": 2.0, "light": Pal.SYNC, "lr": 10}),
	]
	var npcs := [
		{"id": "hiro", "who": "hiro", "tile": Vector2i(3, 6), "dir": 2},
		{"id": "pala", "who": "pala", "tile": Vector2i(10, 7), "dir": 0, "pose": "sit", "offset": Vector2(0, 3), "mood": "closed"},
		{"id": "midas", "who": "midas", "tile": Vector2i(6, 2), "dir": 0, "mood": "sad"},
	]
	return {"id": "recovery", "name": "Recovery Bay", "theme": "academy", "tint": Color(1.0, 1.0, 1.02), "rows": rows, "props": props, "npcs": npcs}


# --------------------------------------------------------------- commons ---

static func commons() -> Dictionary:
	var rows := [
		"#####WW##WW##WW##WW#####D###",
		"#####WW##WW##WW##WW#####D###",
		"#..........................#",
		"#..........................#",
		"#.,,,,,,,..................#",
		"#.,,,,,,,..................#",
		"#.,,,,,,,..................#",
		"#.,,,,,,,..................#",
		"#..........................#",
		"#..........::::::..........#",
		"#..........::::::..........#",
		"#..........::==::..........#",
		"#............==............#",
		"###########DD###############",
		"###########DD###############",
	]
	var props := [
		p("simpod", 2, 3, {"anim": 2, "fps": 1.0, "area": Rect2i(2, 2, 2, 2), "offset": Vector2(8, 0), "light": Pal.SYNC, "lr": 14, "pulse": 2.0, "event": {"id": "simpod"}}),
		p("workshop", 6, 11, {"anim": 2, "fps": 1.5, "area": Rect2i(6, 11, 1, 1), "light": Pal.LEMON, "lr": 16, "pulse": 2.0, "event": {"id": "workshop"}, "id": "workshop"}),
		p("couch", 4, 5, {"offset": Vector2(8, 0), "area": Rect2i(4, 5, 2, 1)}),
		p("couch", 4, 8, {"offset": Vector2(8, 0), "v": 1, "area": Rect2i(4, 8, 2, 1)}),
		p("vending", 21, 2, {"anim": 2, "fps": 1.5, "event": {"id": "vending"}, "light": Pal.GLOW, "lr": 10}),
		p("console", 23, 3, {"anim": 2, "fps": 2.0, "area": Rect2i(22, 3, 2, 1), "offset": Vector2(-8, 0), "light": Pal.SYNC, "lr": 14, "event": {"id": "archive"}}),
		p("crate", 26, 2, {}), p("crate", 26, 3, {}),
		p("board", 9, 1, {"wall": true, "id": "board", "area": Rect2i(), "offset": Vector2(8, 0)}),
		p("comm", 26, 8, {"anim": 2, "fps": 2.0, "event": {"id": "comm"}, "light": Pal.GLOW, "lr": 10, "id": "comm"}),
		p("terminal", 14, 10, {"anim": 2, "fps": 3.0, "event": {"id": "terminal"}, "light": Pal.SYNC, "lr": 22, "pulse": 3.0, "id": "terminal"}),
		p("locker", 18, 12, {}), p("locker", 19, 12, {"v": 1, "event": {"id": "locker"}}), p("locker", 20, 12, {}),
		p("plant", 1, 2, {"v": 1, "event": {"id": "plant"}}),
		p("table", 21, 7, {"v": 1, "offset": Vector2(8, 0), "area": Rect2i(21, 7, 2, 1)}),
		p("chair", 20, 7, {"v": 1, "offset": Vector2(2, 0), "area": Rect2i()}),
		p("pillar", 9, 9, {}), p("pillar", 18, 9, {}),
	]
	return {"id": "commons", "name": "Pilot Commons", "theme": "academy", "tint": Color(0.82, 0.88, 1.0), "rows": rows, "props": props, "npcs": [],
		"music": "low_mechanical_ambient",
		"events": [{"tile": Vector2i(9, 1), "id": "board"}, {"tile": Vector2i(10, 1), "id": "board"}, {"tile": Vector2i(24, 1), "id": "dorm"},
			{"tile": Vector2i(11, 13), "id": "exitdoor"}, {"tile": Vector2i(12, 13), "id": "exitdoor"},
			{"tile": Vector2i(5, 1), "id": "spacewindow"}, {"tile": Vector2i(6, 1), "id": "spacewindow"}, {"tile": Vector2i(13, 1), "id": "spacewindow"},
			{"tile": Vector2i(14, 1), "id": "spacewindow"}, {"tile": Vector2i(17, 1), "id": "spacewindow"}, {"tile": Vector2i(18, 1), "id": "spacewindow"}]}


# ----------------------------------------------------------- launch wing ---

static func launch_wing() -> Dictionary:
	var rows := [
		"##############################",
		"##############################",
		"#____________________________#",
		"#____________________________#",
		"#____________________________#",
		"#____________________________#",
		"##############################",
	]
	var props := [
		p("crate", 6, 2, {}), p("crate", 7, 2, {}), p("crate", 13, 5, {}), p("crate", 18, 2, {}), p("crate", 19, 2, {}),
		p("shuttle", 26, 5, {"offset": Vector2(0, 0), "id": "shuttle", "area": Rect2i(24, 2, 5, 3), "v": 1}),
	]
	for x in [4, 11, 16, 22]:
		props.append(p("lamp", x, 2, {"light": Pal.BLOOD, "lr": 22, "light_off": Vector2(0, -24), "pulse": 6.0, "area": Rect2i()}))
	return {"id": "launch_wing", "name": "Service Route", "theme": "academy", "tint": Color(0.45, 0.42, 0.6), "rows": rows, "props": props, "npcs": [],
		"triggers": [{"rect": Rect2i(23, 2, 1, 4), "id": "shuttle"}]}
