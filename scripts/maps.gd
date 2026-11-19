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
	## The ground floor: the kitchen on the left, the living room on the
	## right, the front door, and the stairs up to the bedrooms.
	var rows := [
		"#WW############D##WW#U##",
		"#WW############D##WW#U##",
		"#::::::::#...........S.#",
		"#::::::::#...........S.#",
		"#::::::::#...........S.#",
		"#........#.............#",
		"#........#...,,,,,,....#",
		"#............,,,,,,....#",
		"#............,,,,,,....#",
		"#........#.............#",
		"#........#.............#",
		"########################",
	]
	var props := [
		# kitchen
		p("counter", 2, 2, {"offset": Vector2(8, 0), "v": 1, "area": Rect2i(2, 2, 2, 1), "event": {"id": "sink"}}),
		p("counter", 4, 2, {"offset": Vector2(8, 0), "area": Rect2i(4, 2, 2, 1), "event": {"id": "packet"}}),
		p("packet", 4, 2, {"offset": Vector2(12, -1), "lift": 13, "id": "packet", "area": Rect2i()}),
		p("stove", 6, 2, {"event": {"id": "stove"}, "light": Pal.EMBER, "lr": 10, "light_off": Vector2(0, -10), "pulse": 3.0}),
		p("fridge", 7, 2, {"event": {"id": "fridge"}}),
		p("calendar", 8, 1, {"wall": true, "lift": 12, "area": Rect2i()}),
		p("table", 4, 6, {"offset": Vector2(8, 0), "area": Rect2i(4, 6, 2, 1), "event": {"id": "table"}}),
		p("letter", 4, 6, {"offset": Vector2(2, 1), "lift": 12, "id": "letter", "area": Rect2i()}),
		p("cup", 5, 6, {"offset": Vector2(6, 1), "lift": 12, "area": Rect2i()}),
		p("chair", 3, 6, {"offset": Vector2(2, 0), "area": Rect2i()}),
		p("chair", 6, 6, {"offset": Vector2(-2, 0), "area": Rect2i()}),
		p("plant", 1, 9, {}),
		# living room
		p("tv", 11, 1, {"offset": Vector2(8, 0), "wall": true, "lift": 7, "area": Rect2i(), "light": Pal.SYNC, "lr": 16, "light_off": Vector2(0, -14), "pulse": 1.2}),
		p("clock", 13, 1, {"wall": true, "lift": 16, "area": Rect2i()}),
		p("coatrack", 14, 2, {"event": {"id": "coats"}}),
		p("shelf", 17, 2, {"event": {"id": "photo"}}),
		p("heater", 18, 2, {"offset": Vector2(8, 0), "area": Rect2i(18, 2, 2, 1), "anim": 2, "fps": 0.7, "event": {"id": "heater"}}),
		p("radio", 15, 7, {"offset": Vector2(8, 0), "area": Rect2i(15, 7, 2, 1), "event": {"id": "radio"}}),
		p("sofa", 15, 9, {"offset": Vector2(8, 0), "area": Rect2i(15, 9, 2, 1), "event": {"id": "couch"}}),
		p("lamp", 12, 9, {"light": Pal.LEMON, "lr": 26, "light_off": Vector2(0, -24), "pulse": 1.5}),
		p("plant", 22, 9, {}),
		p("plant", 10, 2, {"v": 0}),
	]
	return {"id": "home", "name": "Home, Block 7", "theme": "home", "tint": WARM, "outfit": "home", "rows": rows, "props": props,
		"npcs": [], "triggers": [], "music": "letter_discussion",
		"exits": [{"rect": Rect2i(21, 2, 1, 1), "to": "home_up", "tile": Vector2i(20, 9), "dir": 3}],
		"events": [{"tile": Vector2i(15, 1), "id": "frontdoor"}, {"tile": Vector2i(1, 1), "id": "window"}, {"tile": Vector2i(2, 1), "id": "window"},
			{"tile": Vector2i(18, 1), "id": "window"}, {"tile": Vector2i(19, 1), "id": "window"},
			{"tile": Vector2i(11, 1), "id": "tv"}, {"tile": Vector2i(12, 1), "id": "tv"}, {"tile": Vector2i(13, 1), "id": "clock"},
			{"tile": Vector2i(8, 1), "id": "calendar"}]}


static func midas_home() -> Dictionary:
	## Midas' memory: his mother's kitchen, years before the Academy. A table
	## with the chipped blue cup, the warm spot by the stove, the dresser
	## where the toys were hidden, and the doorway Mom came through each
	## morning (in the top wall, so it stays above the dialog box).
	var rows := [
		"#WW#####WW##D####WW##",
		"#WW#####WW##D####WW##",
		"#:::::::::::::::::::#",
		"#:::::::::::::::::::#",
		"#::::::,,,,,,:::::::#",
		"#::::::,,,,,,:::::::#",
		"#::::::,,,,,,:::::::#",
		"#:::::::::::::::::::#",
		"#####################",
	]
	var props := [
		p("counter", 2, 2, {"offset": Vector2(8, 0), "v": 1, "area": Rect2i(2, 2, 2, 1)}),
		p("stove", 4, 2, {"light": Pal.EMBER, "lr": 12, "light_off": Vector2(0, -10), "pulse": 3.0}),
		p("counter", 5, 2, {"offset": Vector2(8, 0), "area": Rect2i(5, 2, 2, 1)}),
		p("fridge", 7, 2, {}),
		p("calendar", 6, 1, {"wall": true, "lift": 12, "area": Rect2i()}),
		p("dresser", 14, 2, {"id": "dresser"}),
		p("plant", 19, 2, {}),
		p("table", 9, 5, {"offset": Vector2(8, 0), "area": Rect2i(9, 5, 2, 1)}),
		p("cup", 10, 5, {"offset": Vector2(6, 1), "lift": 12, "area": Rect2i()}),
		p("chair", 8, 5, {"offset": Vector2(2, 0), "area": Rect2i()}),
		p("chair", 11, 5, {"offset": Vector2(-2, 0), "area": Rect2i()}),
		p("lamp", 18, 7, {"light": Pal.LEMON, "lr": 24, "light_off": Vector2(0, -24), "pulse": 1.5}),
		p("plant", 1, 7, {}),
	]
	return {"id": "midas_home", "name": "", "theme": "home", "tint": WARM, "outfit": "home", "rows": rows, "props": props,
		"npcs": [], "triggers": [], "exits": [], "events": [], "no_player": true}


static func home_up() -> Dictionary:
	## Upstairs: your room, your parents' room and the bathroom, each behind a
	## door off the hallway, and the stairs back down.
	var rows := [
		"##WW######WW#####W####",
		"##WW######WW#####W####",
		"#......#......#::::::#",
		"#......#......#::::::#",
		"#......#......#::::::#",
		"#......#......#::::::#",
		"####d######d#####d####",
		"####d######d#####d####",
		"####d######d#####d####",
		"#....................#",
		"#...................v#",
		"####################v#",
	]
	var props := [
		# your room
		p("kidbed", 2, 3, {"area": Rect2i(2, 2, 1, 2), "event": {"id": "bed"}}),
		p("desk", 4, 2, {"offset": Vector2(8, 0), "area": Rect2i(4, 2, 2, 1), "event": {"id": "desk"}}),
		p("wardrobe", 6, 2, {"event": {"id": "wardrobe"}}),
		p("toy", 6, 4, {"event": {"id": "toy"}}),
		p("starbox", 3, 2, {"anim": 2, "fps": 1.5, "event": {"id": "starbox"}, "light": Pal.SYNC, "lr": 8, "light_off": Vector2(0, -14), "pulse": 2.0}),
		p("bag", 5, 5, {"event": {"id": "bag"}}),
		p("lamp", 1, 5, {"light": Pal.LEMON, "lr": 20, "light_off": Vector2(0, -24), "id": "kidlamp"}),
		# your parents' room
		p("bigbed", 10, 3, {"offset": Vector2(8, 0), "area": Rect2i(10, 2, 2, 2), "event": {"id": "parentsbed"}}),
		p("dresser", 13, 2, {"event": {"id": "dresser"}}),
		p("plant", 8, 5, {}),
		# bathroom
		p("tub", 15, 2, {"offset": Vector2(8, 0), "area": Rect2i(15, 2, 2, 1), "event": {"id": "tub"}}),
		p("basin", 19, 2, {"event": {"id": "basin"}}),
		p("mirror", 19, 1, {"wall": true, "lift": 13, "area": Rect2i()}),
		p("toilet", 20, 4, {"event": {"id": "toilet"}}),
		# hallway
		p("door", 4, 8, {"door": true, "area": Rect2i(), "shadow": false}),
		p("door", 11, 8, {"door": true, "area": Rect2i(), "shadow": false}),
		p("door", 17, 8, {"door": true, "area": Rect2i(), "shadow": false}),
		p("drawings", 7, 8, {"offset": Vector2(8, 0), "wall": true, "lift": 10, "area": Rect2i()}),
		p("basket", 14, 10, {"event": {"id": "basket"}}),
		p("plant", 1, 10, {}),
	]
	return {"id": "home_up", "name": "Home, Upstairs", "theme": "home", "tint": WARM, "outfit": "home", "rows": rows, "props": props,
		"npcs": [], "triggers": [], "music": "letter_discussion",
		"exits": [{"rect": Rect2i(20, 11, 1, 1), "to": "home", "tile": Vector2i(21, 5), "dir": 0}],
		"events": [{"tile": Vector2i(2, 1), "id": "window"}, {"tile": Vector2i(3, 1), "id": "window"},
			{"tile": Vector2i(10, 1), "id": "window"}, {"tile": Vector2i(11, 1), "id": "window"}, {"tile": Vector2i(17, 1), "id": "window"},
			{"tile": Vector2i(7, 8), "id": "drawings"}, {"tile": Vector2i(8, 8), "id": "drawings"}]}


# --------------------------------------------------------------- Block 7 ---

static func block7(time: String = "evening") -> Dictionary:
	## The street outside home: tenement fronts with lit windows along the
	## top (your door, Mrs. Okafor's), the sidewalk and lamps, a road, then
	## the ration kiosk and the noticeboard on the paving and a scrap of park
	## with swings and a slide. time: "evening" (neighbours out, friends on
	## the bench, kids playing) or "dawn" (everyone lined up to see you off).
	var rows := ["##WW##WW#D##WW####WW##WW#D##WW", "##WW##WW#D##WW####WW##WW#D##WW"]
	for i in 3:
		rows.append("..............................")
	for i in 2:
		rows.append("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
	for i in 6:
		rows.append("...............ggggggggggggggg")
	rows.append("##############################")
	var props := [
		p("streetlamp", 3, 4, {"anim": 2, "fps": 0.4, "light": Pal.LEMON, "lr": 30, "light_off": Vector2(0, -38), "pulse": 1.0}),
		p("streetlamp", 15, 4, {"light": Pal.LEMON, "lr": 30, "light_off": Vector2(0, -38), "pulse": 1.0}),
		p("streetlamp", 27, 4, {"light": Pal.LEMON, "lr": 30, "light_off": Vector2(0, -38), "pulse": 1.0}),
		p("bin", 12, 2, {"event": {"id": "bin"}}),
		p("plant", 7, 2, {}),
		p("plant", 27, 2, {"v": 1}),
		p("chair", 24, 2, {"v": 0}),
		p("kiosk", 4, 9, {"offset": Vector2(8, 0), "area": Rect2i(3, 8, 3, 2), "event": {"id": "kiosk"}, "light": Pal.LEMON, "lr": 18, "light_off": Vector2(0, -20), "pulse": 2.0}),
		p("noticeboard", 11, 8, {"offset": Vector2(8, 0), "area": Rect2i(11, 8, 2, 1), "event": {"id": "noticeboard"}}),
		p("bench", 7, 11, {"offset": Vector2(8, 0), "area": Rect2i(7, 11, 2, 1)}),
		p("swings", 19, 9, {"offset": Vector2(8, 0), "area": Rect2i(18, 9, 3, 1), "event": {"id": "swings"}}),
		p("slide", 25, 10, {"offset": Vector2(8, 0), "area": Rect2i(24, 10, 3, 1), "event": {"id": "slide"}}),
		p("plant", 15, 12, {}),
		p("plant", 28, 12, {"v": 1}),
	]
	if time == "evening":
		props.append(p("cat", 17, 3, {"anim": 2, "fps": 0.8, "event": {"id": "cat"}, "area": Rect2i()}))
	var npcs := []
	if time == "evening":
		npcs = [
			{"id": "okafor", "who": "okafor", "tile": Vector2i(24, 3), "dir": 0, "pose": "sit", "no_turn": true},
			{"id": "hale", "who": "hale", "tile": Vector2i(12, 9), "dir": 1},
			{"id": "benno", "who": "benno", "tile": Vector2i(4, 10), "dir": 0},
			{"id": "tomas", "who": "tomas", "tile": Vector2i(7, 11), "dir": 0},
			{"id": "juno", "who": "juno", "tile": Vector2i(8, 11), "dir": 0},
			{"id": "pip", "who": "pip", "tile": Vector2i(21, 11), "dir": 3},
			{"id": "wren", "who": "wren", "tile": Vector2i(23, 11), "dir": 3},
		]
	else:
		# dawn: the block lines the sidewalk
		npcs = [
			{"id": "okafor", "who": "okafor", "tile": Vector2i(24, 3), "dir": 0},
			{"id": "hale", "who": "hale", "tile": Vector2i(14, 2), "dir": 0},
			{"id": "benno", "who": "benno", "tile": Vector2i(17, 2), "dir": 0},
			{"id": "tomas", "who": "tomas", "tile": Vector2i(19, 2), "dir": 0},
			{"id": "juno", "who": "juno", "tile": Vector2i(20, 2), "dir": 0},
			{"id": "pip", "who": "pip", "tile": Vector2i(22, 2), "dir": 0},
			{"id": "wren", "who": "wren", "tile": Vector2i(23, 2), "dir": 0},
		]
	return {"id": "block7", "name": "Block 7", "theme": "block", "tint": Color(0.86, 0.78, 0.86) if time == "evening" else Color(1.0, 0.86, 0.78),
		"outfit": "home", "rows": rows, "props": props, "npcs": npcs, "music": "mellow_loop",
		"triggers": [{"rect": Rect2i(15, 7, 15, 6), "id": "kids_game"}] if time == "evening" else [],
		"exits": [{"rect": Rect2i(9, 2, 1, 1), "to": "home", "tile": Vector2i(15, 3), "dir": 0}],
		"events": [{"tile": Vector2i(9, 1), "id": "homedoor"}, {"tile": Vector2i(25, 1), "id": "okafordoor"},
			{"tile": Vector2i(2, 1), "id": "nwindow"}, {"tile": Vector2i(3, 1), "id": "nwindow"}, {"tile": Vector2i(18, 1), "id": "nwindow"},
			{"tile": Vector2i(19, 1), "id": "nwindow"}, {"tile": Vector2i(28, 1), "id": "dark_window"}, {"tile": Vector2i(29, 1), "id": "dark_window"}]}


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
		p("mech", 6, 7, {"area": Rect2i(5, 5, 3, 3), "anim": 2, "fps": 1.2, "id": "mech1", "light": Pal.SYNC, "lr": 14, "light_off": Vector2(0, -44), "pulse": 2.0, "event": {"id": "parade_mech"}}),
		p("mech", 22, 7, {"area": Rect2i(21, 5, 3, 3), "anim": 2, "fps": 1.2, "id": "mech2", "light": Pal.SYNC, "lr": 14, "light_off": Vector2(0, -44), "pulse": 2.0, "event": {"id": "parade_mech"}}),
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
		"#####WW##WW##WW##WW###D#D###",
		"#####WW##WW##WW##WW###D#D###",
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
			{"tile": Vector2i(22, 1), "id": "wing"},
			{"tile": Vector2i(11, 13), "id": "exitdoor"}, {"tile": Vector2i(12, 13), "id": "exitdoor"},
			{"tile": Vector2i(5, 1), "id": "spacewindow"}, {"tile": Vector2i(6, 1), "id": "spacewindow"}, {"tile": Vector2i(13, 1), "id": "spacewindow"},
			{"tile": Vector2i(14, 1), "id": "spacewindow"}, {"tile": Vector2i(17, 1), "id": "spacewindow"}, {"tile": Vector2i(18, 1), "id": "spacewindow"}]}


# ------------------------------------------------------------ pilot wing ---
## Off the Commons: a corridor with a door to each room. Doors are opened by
## examining them (face the door, Z); rooms are left by walking out of the
## doorway at the bottom.

const WING_ROOMS := ["rec", "mess", "archive", "gym", "observation", "memorial", "rooftop"]
const WING_DOOR_X := {"rec": 2, "mess": 6, "archive": 10, "gym": 14, "observation": 18, "memorial": 22, "rooftop": 26}
const WING_NAMES := {"rec": "Rec Room", "mess": "Mess Hall", "archive": "Archive", "gym": "Training Gym",
	"observation": "Observation Deck", "memorial": "Memorial Hall", "rooftop": "Rooftop Garden"}


static func wing() -> Dictionary:
	var top := "##D###D###D###D###D###D###D###"
	var rows := [top, top, "#............................#", "#............................#", "#............................#",
		"#############dd###############"]
	var props := [
		p("bench", 4, 4, {"offset": Vector2(8, 0), "area": Rect2i(4, 4, 2, 1)}),
		p("bench", 20, 4, {"offset": Vector2(8, 0), "area": Rect2i(20, 4, 2, 1)}),
		p("plant", 1, 2, {"v": 1}), p("plant", 28, 2, {}),
		p("pillar", 8, 4, {}), p("pillar", 24, 4, {}),
	]
	var events := []
	for id in WING_ROOMS:
		events.append({"tile": Vector2i(WING_DOOR_X[id], 1), "id": "room:" + id})
	return {"id": "wing", "name": "Pilot Wing", "theme": "academy", "tint": Color(0.84, 0.88, 1.0), "rows": rows, "props": props, "npcs": [],
		"music": "low_mechanical_ambient", "events": events,
		"exits": [{"rect": Rect2i(13, 5, 2, 1), "to": "commons", "tile": Vector2i(22, 2), "dir": 0}]}


static func wing_room(id: String) -> Dictionary:
	## One room off the wing: 16x9, the way out at the bottom middle.
	var rows := ["################", "################"]
	for i in 6:
		rows.append("#..............#")
	rows.append("#######dd#######")
	var props := []
	var npcs := []
	var events := []
	var tint := Color(0.86, 0.9, 1.0)
	var music := "low_mechanical_ambient"
	match id:
		"rec":
			rows[0] = "####WW####WW####"
			rows[1] = rows[0]
			props = [
				p("tv", 7, 1, {"offset": Vector2(8, 0), "wall": true, "lift": 7, "area": Rect2i(), "light": Pal.SYNC, "lr": 16, "light_off": Vector2(0, -14), "pulse": 1.2}),
				p("couch", 7, 4, {"offset": Vector2(8, 0), "area": Rect2i(7, 4, 2, 1), "v": 1}),
				p("starbox", 2, 2, {"anim": 2, "fps": 1.5, "event": {"id": "rec_starbox"}, "light": Pal.SYNC, "lr": 8, "light_off": Vector2(0, -14)}),
				p("pingpong", 12, 6, {"offset": Vector2(8, 0), "area": Rect2i(11, 6, 3, 1), "event": {"id": "pingpong"}}),
				p("table", 3, 6, {"offset": Vector2(8, 0), "v": 1, "area": Rect2i(3, 6, 2, 1), "event": {"id": "cards"}}),
				p("chair", 2, 6, {"v": 1, "offset": Vector2(2, 0), "area": Rect2i()}),
				p("plant", 14, 2, {}),
			]
			events = [{"tile": Vector2i(7, 1), "id": "rec_tv"}, {"tile": Vector2i(8, 1), "id": "rec_tv"}]
			npcs = [{"id": "fan", "spec": Data.EXTRAS[1], "tile": Vector2i(9, 4), "dir": 1, "pose": "sit", "no_turn": true}]
		"mess":
			props = [
				p("counter", 3, 2, {"offset": Vector2(8, 0), "area": Rect2i(3, 2, 2, 1), "event": {"id": "tray"}}),
				p("counter", 5, 2, {"offset": Vector2(8, 0), "v": 1, "area": Rect2i(5, 2, 2, 1), "event": {"id": "cereal"}}),
				p("vending", 12, 2, {"anim": 2, "fps": 1.5, "event": {"id": "dispenser"}, "light": Pal.GLOW, "lr": 10}),
				p("board", 9, 1, {"wall": true, "area": Rect2i(), "offset": Vector2(8, 0)}),
				p("table", 4, 5, {"offset": Vector2(8, 0), "area": Rect2i(3, 5, 4, 1), "v": 1}),
				p("table", 10, 5, {"offset": Vector2(8, 0), "area": Rect2i(9, 5, 4, 1), "v": 1}),
			]
			events = [{"tile": Vector2i(9, 1), "id": "quota"}, {"tile": Vector2i(10, 1), "id": "quota"}]
			npcs = [{"id": "gossip0", "spec": Data.EXTRAS[0], "tile": Vector2i(4, 6), "dir": 1},
				{"id": "gossip1", "spec": Data.EXTRAS[2], "tile": Vector2i(11, 6), "dir": 1}]
		"archive":
			tint = Color(0.8, 0.84, 0.98)
			props = [
				p("shelf", 2, 2, {"event": {"id": "shelf"}}), p("shelf", 4, 2, {"event": {"id": "shelf"}}),
				p("shelf", 11, 2, {"event": {"id": "shelf"}}), p("shelf", 13, 2, {"event": {"id": "shelf"}}),
				p("terminal", 7, 4, {"anim": 2, "fps": 2.0, "event": {"id": "lore"}, "light": Pal.SYNC, "lr": 18, "pulse": 2.0}),
				p("terminal", 9, 4, {"anim": 2, "fps": 2.5, "event": {"id": "lore"}, "light": Pal.SYNC, "lr": 18, "pulse": 2.5}),
				p("locker", 14, 6, {"v": 1, "event": {"id": "cabinet"}}),
				p("crate", 2, 7, {"event": {"id": "pala_stack"}}),
			]
		"gym":
			props = [
				p("simpod", 2, 3, {"anim": 2, "fps": 1.0, "area": Rect2i(2, 2, 2, 2), "offset": Vector2(8, 0), "light": Pal.SYNC, "lr": 14, "pulse": 2.0, "event": {"id": "simpod"}}),
				p("treadmill", 7, 3, {"anim": 2, "fps": 3.0, "offset": Vector2(8, 0), "area": Rect2i(7, 3, 2, 1), "event": {"id": "treadmill"}}),
				p("punchbag", 12, 3, {"event": {"id": "punchbag"}}),
				p("console", 13, 6, {"anim": 2, "fps": 2.0, "area": Rect2i(12, 6, 2, 1), "offset": Vector2(-8, 0), "light": Pal.GLOW, "lr": 12, "event": {"id": "drill"}}),
				p("board", 9, 1, {"wall": true, "area": Rect2i(), "offset": Vector2(8, 0)}),
			]
			events = [{"tile": Vector2i(9, 1), "id": "times"}, {"tile": Vector2i(10, 1), "id": "times"}]
		"observation":
			tint = Color(0.72, 0.76, 0.98)
			rows[0] = "#WWWWWWWWWWWWWW#"
			rows[1] = rows[0]
			props = [
				p("bench", 4, 5, {"offset": Vector2(8, 0), "area": Rect2i(4, 5, 2, 1)}),
				p("bench", 10, 5, {"offset": Vector2(8, 0), "area": Rect2i(10, 5, 2, 1)}),
				p("telescope", 13, 3, {"event": {"id": "telescope"}}),
				p("plant", 1, 7, {}),
			]
			for x in range(1, 15):
				events.append({"tile": Vector2i(x, 1), "id": "deckwindow"})
		"memorial":
			tint = Color(0.78, 0.74, 0.86)
			music = ""
			props = [
				p("board", 7, 1, {"wall": true, "area": Rect2i(), "offset": Vector2(8, 0), "v": 12, "id": "wall"}),
				p("candles", 7, 3, {"anim": 2, "fps": 3.0, "offset": Vector2(8, 0), "area": Rect2i(7, 3, 2, 1), "light": Pal.LEMON, "lr": 20, "pulse": 4.0, "event": {"id": "candles"}}),
				p("podium", 12, 5, {"event": {"id": "guestbook"}}),
				p("bench", 3, 6, {"offset": Vector2(8, 0), "area": Rect2i(3, 6, 2, 1)}),
				p("plant", 14, 2, {}), p("plant", 1, 2, {}),
			]
			events = [{"tile": Vector2i(7, 1), "id": "names"}, {"tile": Vector2i(8, 1), "id": "names"}]
		"rooftop":
			tint = Maps.NIGHT.lerp(Color.WHITE, 0.35)
			rows = ["................", "................"]
			for i in 6:
				rows.append("gggggggggggggggg")
			rows.append("#######dd#######")
			props = [
				p("planter", 3, 3, {"offset": Vector2(8, 0), "area": Rect2i(2, 3, 3, 1), "event": {"id": "planter"}}),
				p("planter", 12, 3, {"offset": Vector2(8, 0), "area": Rect2i(11, 3, 3, 1), "event": {"id": "planter"}}),
				# Midas' tomatoes: fruiting while he's alive, wilted once he's
				# gone, green again once someone waters them
				p("planter", 3, 6, {"offset": Vector2(8, 0), "area": Rect2i(2, 6, 3, 1), "id": "tomato", "event": {"id": "tomato"},
					"v": 1 if not Game.midas_dead() else (0 if bool(Game.story.get("watered_tomato", false)) else 2)}),
				p("bench", 11, 6, {"offset": Vector2(8, 0), "area": Rect2i(11, 6, 2, 1)}),
				p("streetlamp", 8, 3, {"light": Pal.LEMON, "lr": 26, "light_off": Vector2(0, -38), "pulse": 1.0}),
			]
			events = [{"tile": Vector2i(7, 1), "id": "rooftop_sky"}]
	return {"id": "room_" + id, "name": WING_NAMES[id], "theme": "academy" if id != "rooftop" else "outdoor", "tint": tint, "rows": rows,
		"props": props, "npcs": npcs, "music": music, "events": events,
		"exits": [{"rect": Rect2i(7, 8, 2, 1), "to": "wing", "tile": Vector2i(WING_DOOR_X[id], 2), "dir": 0}]}


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
