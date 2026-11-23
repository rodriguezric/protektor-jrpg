class_name Building
## The Academy between missions, laid out as one building (feature
## hub_building_layout). Everything hangs off the Pilot Commons:
##
##   Pilot Commons (the lounge: pilots, recruits, couches, windows)
##     |- door: Operations (deploy terminal, comm booth, sim pod)
##     '- door: Main Concourse (a T-junction with a building directory)
##          |- door: Engineering Bay (the workshop)
##          |- door: Dormitories -> your room, Hiro's, Pala's, Midas', washroom
##          |- stairs west, down: Lower Deck -> rec room, mess hall, gym
##          '- stairs east, up: Upper Deck -> archive, observation deck,
##                                          memorial hall, roof access
##
## Doors in a top wall are opened by examining them (event "go:<map id>");
## doorways in a bottom wall and stairs are walked through ("exits", {to}).
## Each map also carries "entry" (where you appear coming in from its parent)
## and "route" (where the marker points once it's time to deploy: the next
## step back toward Operations). Plaques over the doors come from "signs".

const PARENT := {
	"ops": "commons", "concourse": "commons",
	"engineering": "concourse", "dorms": "concourse", "rec_deck": "concourse", "upper_deck": "concourse",
	"room_rec": "rec_deck", "room_mess": "rec_deck", "room_gym": "rec_deck",
	"room_archive": "upper_deck", "room_observation": "upper_deck", "room_memorial": "upper_deck", "room_rooftop": "upper_deck",
	"dorm_you": "dorms", "dorm_hiro": "dorms", "dorm_pala": "dorms", "dorm_midas": "dorms", "dorm_wash": "dorms",
}

## Doors in a map's top wall: map id -> {where it leads: tile x of its left
## half}. Every door is two tiles wide (DD), so people fit through it.
const DOORS := {
	"commons": {"concourse": 21, "ops": 25},
	"concourse": {"engineering": 6, "dorms": 19},
	"dorms": {"dorm_you": 3, "dorm_hiro": 8, "dorm_pala": 13, "dorm_midas": 18, "dorm_wash": 23},
	"rec_deck": {"room_rec": 7, "room_mess": 12, "room_gym": 19},
	"upper_deck": {"room_archive": 6, "room_observation": 12, "room_memorial": 18, "room_rooftop": 23},
}

## Arrivals that aren't "below the door you came through": stairs and the
## Concourse's south doorway. to -> {from: [tile, facing]}.
const ARRIVE := {
	"concourse": {"commons": [Vector2i(13, 8), 1], "rec_deck": [Vector2i(3, 3), 2], "upper_deck": [Vector2i(26, 3), 3]},
	"rec_deck": {"concourse": [Vector2i(3, 3), 2]},
	"upper_deck": {"concourse": [Vector2i(3, 3), 2]},
}

const ROOMS := ["rec", "mess", "archive", "gym", "observation", "memorial", "rooftop"]
const ROOM_NAMES := {"rec": "Rec Room", "mess": "Mess Hall", "archive": "Archive", "gym": "Training Gym",
	"observation": "Observation Deck", "memorial": "Memorial Hall", "rooftop": "Rooftop Garden"}
## Rooms are sized by what they're for: a big mess hall, a narrow archive.
const ROOM_SIZE := {"rec": Vector2i(16, 9), "mess": Vector2i(22, 10), "archive": Vector2i(12, 10), "gym": Vector2i(18, 9),
	"observation": Vector2i(22, 8), "memorial": Vector2i(12, 9), "rooftop": Vector2i(18, 9)}
const DORMS := ["you", "hiro", "pala", "midas", "wash"]

const SIGN := {"concourse": "CONCOURSE", "ops": "OPERATIONS", "engineering": "ENGINEERING", "dorms": "DORMITORIES",
	"room_rec": "REC ROOM", "room_mess": "MESS HALL", "room_gym": "GYM", "room_archive": "ARCHIVE",
	"room_observation": "OBSERVATION", "room_memorial": "MEMORIAL", "room_rooftop": "ROOF",
	"dorm_hiro": "HIRO", "dorm_pala": "PALA", "dorm_midas": "MIDAS", "dorm_wash": "WASHROOM"}

const HALL_TINT := Color(0.84, 0.88, 1.0)


static func p(kind: String, x: int, y: int, extra: Dictionary = {}) -> Dictionary:
	return Maps.p(kind, x, y, extra)


static func is_building(id: String) -> bool:
	return id == "commons" or PARENT.has(id)


static func name_of(id: String) -> String:
	match id:
		"commons":
			return "Pilot Commons"
		"ops":
			return "Operations"
		"concourse":
			return "Main Concourse"
		"engineering":
			return "Engineering Bay"
		"dorms":
			return "Dormitories"
		"rec_deck":
			return "Lower Deck"
		"upper_deck":
			return "Upper Deck"
		"dorm_you":
			return "Your Room"
		"dorm_wash":
			return "Washroom"
	if id.begins_with("room_"):
		return ROOM_NAMES.get(id.trim_prefix("room_"), "")
	if id.begins_with("dorm_"):
		return "%s's Room" % id.trim_prefix("dorm_").capitalize()
	return ""


# ------------------------------------------------------------- grid bits ---

static func _box(w: int, h: int) -> Array:
	## Walls all round (two rows on top for the 3/4 face), floor inside.
	var rows := []
	for y in h:
		var r := ""
		for x in w:
			r += "#" if y < 2 or y == h - 1 or x == 0 or x == w - 1 else "."
		rows.append(r)
	return rows


static func _put(rows: Array, x: int, y: int, ch: String) -> void:
	var r: String = rows[y]
	rows[y] = r.substr(0, x) + ch + r.substr(x + 1)


static func _fill(rows: Array, r: Rect2i, ch: String) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			_put(rows, x, y, ch)


static func _finish(id: String, rows: Array, d: Dictionary) -> Dictionary:
	## Adds the doors in the top wall (tiles, events, plaques) and the rest of
	## the common keys.
	var events: Array = d.get("events", [])
	var signs: Array = d.get("signs", [])
	var doors: Dictionary = DOORS.get(id, {})
	for to in doors:
		var x: int = doors[to]
		for k in 2:
			_put(rows, x + k, 0, "D")
			_put(rows, x + k, 1, "D")
			events.append({"tile": Vector2i(x + k, 1), "id": "go:" + to})
		var label := _sign_text(to)
		if label != "":
			signs.append({"x": x * 16 + 16, "y": 1, "text": label})
	d.events = events
	d.signs = signs
	d.rows = rows
	d.id = id
	if not d.has("name"):
		d.name = name_of(id)
	if not d.has("theme"):
		d.theme = "academy"
	if not d.has("npcs"):
		d.npcs = []
	if not d.has("music"):
		d.music = "low_mechanical_ambient"
	return d


static func _sign_text(to: String) -> String:
	if to == "dorm_you":
		return Game.player_name.to_upper() if Game.player_name != "" else "YOU"
	if to == "dorm_midas" and Game.midas_dead():
		return ""
	return SIGN.get(to, "")


# ----------------------------------------------------------- navigation ---

static func map(id: String) -> Dictionary:
	## The bare map for any building id (the Commons' people come from
	## StoryHub._map, room casts from StoryWing).
	match id:
		"commons":
			return commons()
		"ops":
			return ops()
		"concourse":
			return concourse()
		"engineering":
			return engineering()
		"dorms":
			return dorms()
		"rec_deck":
			return rec_deck()
		"upper_deck":
			return upper_deck()
	if id.begins_with("room_"):
		return room(id.trim_prefix("room_"))
	if id.begins_with("dorm_"):
		return dorm_room(id.trim_prefix("dorm_"))
	return commons()


static func arrival(to: String, from: String, def: Dictionary) -> Array:
	## [tile, facing] for walking into map `to` from map `from`.
	var special: Dictionary = ARRIVE.get(to, {})
	if special.has(from):
		return special[from]
	var doors: Dictionary = DOORS.get(to, {})
	if doors.has(from):
		# out of that door's sill, facing away from it
		return [Vector2i(doors[from], 2), 0]
	return def.get("entry", [Vector2i(2, 2), 0])


# --------------------------------------------------------------- commons ---

static func commons() -> Dictionary:
	## The lounge. Social things only; the work moved to Operations and the
	## workshop to the Engineering Bay.
	var rows := [
		"#####WW##WW##WW##WW##D###D##",
		"#####WW##WW##WW##WW##D###D##",
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
		# the double doors back to the briefing halls: a real doorway people
		# walk through in scenes, locked to you (solid_tiles below)
		"###########dd###############",
		"############################",
	]
	var props := [
		p("couch", 4, 5, {"offset": Vector2(8, 0), "area": Rect2i(4, 5, 2, 1)}),
		p("couch", 4, 8, {"offset": Vector2(8, 0), "v": 1, "area": Rect2i(4, 8, 2, 1)}),
		p("lamp", 1, 7, {"light": Pal.LEMON, "lr": 22, "light_off": Vector2(0, -24), "pulse": 1.5}),
		p("vending", 19, 2, {"anim": 2, "fps": 1.5, "event": {"id": "vending"}, "light": Pal.GLOW, "lr": 10}),
		p("console", 23, 3, {"anim": 2, "fps": 2.0, "area": Rect2i(22, 3, 2, 1), "offset": Vector2(-8, 0), "light": Pal.SYNC, "lr": 14, "event": {"id": "archive"}}),
		p("board", 9, 1, {"wall": true, "id": "board", "area": Rect2i(), "offset": Vector2(8, 0)}),
		p("shelf", 16, 2, {"event": {"id": "games"}}),
		p("plant", 1, 2, {"v": 1, "event": {"id": "plant"}}),
		p("plant", 26, 5, {}),
		p("plant", 26, 12, {"v": 1}),
		p("plant", 1, 12, {}),
		p("table", 21, 7, {"v": 1, "offset": Vector2(8, 0), "area": Rect2i(21, 7, 2, 1)}),
		p("chair", 20, 7, {"v": 1, "offset": Vector2(2, 0), "area": Rect2i()}),
		p("table", 6, 11, {"offset": Vector2(8, 0), "area": Rect2i(6, 11, 2, 1), "event": {"id": "commons_table"}}),
		p("chair", 5, 11, {"offset": Vector2(2, 0), "area": Rect2i()}),
		p("pillar", 9, 9, {}), p("pillar", 18, 9, {}),
	]
	var events := [{"tile": Vector2i(9, 1), "id": "board"}, {"tile": Vector2i(10, 1), "id": "board"},
		{"tile": Vector2i(11, 13), "id": "exitdoor"}, {"tile": Vector2i(12, 13), "id": "exitdoor"}]
	for x in [5, 6, 13, 14, 17, 18]:
		events.append({"tile": Vector2i(x, 1), "id": "spacewindow"})
	return _finish("commons", rows, {"name": "Pilot Commons", "tint": Color(0.82, 0.88, 1.0), "props": props, "events": events,
		"solid_tiles": [Vector2i(11, 13), Vector2i(12, 13)], "route": Vector2i(25, 2)})


# ------------------------------------------------------------ operations ---

static func ops() -> Dictionary:
	## The ready room: where you go to work. The deploy terminal in the
	## middle, the comm booth for calls home, the sim pod for training.
	var rows := _box(18, 10)
	for x in [4, 5, 12, 13]:
		_put(rows, x, 0, "W")
		_put(rows, x, 1, "W")
	_fill(rows, Rect2i(7, 4, 5, 3), ":")
	_fill(rows, Rect2i(8, 7, 2, 2), "=")
	_put(rows, 8, 9, "d")
	_put(rows, 9, 9, "d")
	var props := [
		p("terminal", 9, 5, {"anim": 2, "fps": 3.0, "event": {"id": "terminal"}, "light": Pal.SYNC, "lr": 22, "pulse": 3.0, "id": "terminal"}),
		p("simpod", 2, 3, {"anim": 2, "fps": 1.0, "area": Rect2i(2, 2, 2, 2), "offset": Vector2(8, 0), "light": Pal.SYNC, "lr": 14, "pulse": 2.0, "event": {"id": "simpod"}}),
		p("comm", 15, 2, {"anim": 2, "fps": 2.0, "event": {"id": "comm"}, "light": Pal.GLOW, "lr": 10, "id": "comm"}),
		p("holo", 4, 7, {"offset": Vector2(-8, 0), "area": Rect2i(2, 7, 4, 1), "planet": "green_planet", "id": "ops_holo", "event": {"id": "ops_holo"}}),
		p("console", 15, 6, {"anim": 2, "fps": 1.5, "area": Rect2i(14, 6, 2, 1), "offset": Vector2(-8, 0), "light": Pal.SYNC, "lr": 12, "event": {"id": "flightlog"}}),
		p("banner", 8, 1, {"wall": true, "offset": Vector2(8, 0), "area": Rect2i()}),
		p("bench", 13, 8, {"v": 0, "area": Rect2i(12, 8, 3, 1)}),
		p("plant", 1, 8, {}),
	]
	var events := []
	for x in [4, 5, 12, 13]:
		events.append({"tile": Vector2i(x, 1), "id": "opswindow"})
	return _finish("ops", rows, {"tint": Color(0.8, 0.86, 1.0), "props": props, "events": events,
		"exits": [{"rect": Rect2i(8, 9, 2, 1), "to": "commons"}], "entry": [Vector2i(8, 8), 1], "route": Vector2i(9, 4)})


# -------------------------------------------------------------- concourse ---

static func concourse() -> Dictionary:
	## A T-junction: the hall runs east-west, the spur south to the Commons.
	## Stairs down to the Lower Deck at the west end, up to the Upper Deck at
	## the east end.
	var rows := []
	for y in 10:
		rows.append("#".repeat(30))
	_fill(rows, Rect2i(1, 2, 28, 3), ".")
	_fill(rows, Rect2i(12, 5, 4, 4), ".")
	_fill(rows, Rect2i(13, 5, 2, 4), "=")
	_fill(rows, Rect2i(11, 2, 6, 3), ":")
	_put(rows, 13, 9, "d")
	_put(rows, 14, 9, "d")
	# stairs down (west)
	_fill(rows, Rect2i(1, 4, 2, 2), "v")
	# stairs up (east)
	_fill(rows, Rect2i(27, 0, 2, 2), "U")
	_fill(rows, Rect2i(27, 2, 2, 1), "S")
	for x in [23, 24]:
		_put(rows, x, 0, "W")
		_put(rows, x, 1, "W")
	var props := [
		p("board", 11, 1, {"wall": true, "area": Rect2i(), "offset": Vector2(8, 0), "v": 0}),
		p("pillar", 11, 4, {}), p("pillar", 16, 4, {}),
		p("bench", 8, 4, {"offset": Vector2(8, 0), "area": Rect2i(8, 4, 2, 1)}),
		p("plant", 4, 2, {}), p("plant", 25, 2, {"v": 1}),
		p("bin", 21, 4, {}),
	]
	var events := [{"tile": Vector2i(11, 1), "id": "directory"}, {"tile": Vector2i(12, 1), "id": "directory"},
		{"tile": Vector2i(23, 1), "id": "hallwindow"}, {"tile": Vector2i(24, 1), "id": "hallwindow"}]
	# over each stairwell
	var signs := [{"x": 4, "y": 1, "text": "LOWER DECK", "left": true}, {"x": 28 * 16, "y": 1, "text": "UPPER DECK"}]
	return _finish("concourse", rows, {"tint": HALL_TINT, "props": props, "events": events, "signs": signs,
		"exits": [{"rect": Rect2i(13, 9, 2, 1), "to": "commons"}, {"rect": Rect2i(1, 5, 2, 1), "to": "rec_deck"},
			{"rect": Rect2i(27, 2, 2, 1), "to": "upper_deck"}],
		"entry": [Vector2i(13, 8), 1], "route": Vector2i(13, 9)})


# ------------------------------------------------------------ engineering ---

static func engineering() -> Dictionary:
	var rows := _box(20, 10)
	_fill(rows, Rect2i(11, 4, 8, 3), "_")
	_put(rows, 9, 9, "d")
	_put(rows, 10, 9, "d")
	for x in [14, 15]:
		_put(rows, x, 0, "D")
		_put(rows, x, 1, "D")
	var props := [
		p("workshop", 4, 3, {"anim": 2, "fps": 1.5, "area": Rect2i(4, 3, 1, 1), "light": Pal.LEMON, "lr": 16, "pulse": 2.0, "event": {"id": "workshop"}, "id": "workshop"}),
		p("shelf", 2, 2, {"event": {"id": "parts"}}), p("shelf", 6, 2, {"event": {"id": "parts"}}),
		p("console", 10, 2, {"anim": 2, "fps": 2.0, "area": Rect2i(9, 2, 2, 1), "offset": Vector2(-8, 0), "light": Pal.SYNC, "lr": 12, "event": {"id": "diagnostics"}}),
		p("crate", 17, 7, {"event": {"id": "eng_crate"}}), p("crate", 18, 7, {}), p("crate", 18, 6, {}),
		p("crate", 2, 7, {}),
		p("lamp", 12, 2, {"light": Pal.LEMON, "lr": 22, "light_off": Vector2(0, -24), "pulse": 2.0, "area": Rect2i()}),
		p("lamp", 17, 2, {"light": Pal.BLOOD, "lr": 18, "light_off": Vector2(0, -24), "pulse": 4.0, "area": Rect2i()}),
	]
	var events := [{"tile": Vector2i(14, 1), "id": "baydoor"}, {"tile": Vector2i(15, 1), "id": "baydoor"}]
	return _finish("engineering", rows, {"tint": Color(0.92, 0.88, 0.86), "props": props, "events": events,
		"signs": [{"x": 15 * 16, "y": 1, "text": "LAUNCH CRADLES"}],
		"exits": [{"rect": Rect2i(9, 9, 2, 1), "to": "concourse"}], "entry": [Vector2i(9, 8), 1], "route": Vector2i(9, 9)})


# ------------------------------------------------------------ dormitories ---

static func dorms() -> Dictionary:
	var rows := _box(27, 6)
	_put(rows, 12, 5, "d")
	_put(rows, 13, 5, "d")
	var props := [
		p("board", 10, 1, {"wall": true, "area": Rect2i(), "offset": Vector2(8, 0), "v": 0}),
		p("basket", 25, 4, {"event": {"id": "laundry"}}),
		p("plant", 1, 2, {}),
		p("bench", 6, 4, {"offset": Vector2(8, 0), "area": Rect2i(6, 4, 2, 1)}),
		p("bench", 20, 4, {"offset": Vector2(8, 0), "area": Rect2i(20, 4, 2, 1)}),
	]
	var events := [{"tile": Vector2i(10, 1), "id": "rota"}, {"tile": Vector2i(11, 1), "id": "rota"}]
	return _finish("dorms", rows, {"tint": Color(0.76, 0.8, 0.96), "props": props, "events": events,
		"exits": [{"rect": Rect2i(12, 5, 2, 1), "to": "concourse"}], "entry": [Vector2i(12, 4), 1], "route": Vector2i(12, 5)})


static func dorm_room(who: String) -> Dictionary:
	## A small room off the dorm corridor: a bunk, a desk, a window, and
	## whatever its pilot has made of it.
	var rows := _box(10, 7)
	_put(rows, 4, 6, "d")
	_put(rows, 5, 6, "d")
	var dead := Game.midas_dead()
	var props := []
	var events := []
	if who != "wash":
		for x in [6, 7]:
			_put(rows, x, 0, "W")
			_put(rows, x, 1, "W")
			events.append({"tile": Vector2i(x, 1), "id": "dormwindow"})
	var tint := Color(0.86, 0.88, 1.0)
	match who:
		"you":
			props = [
				p("foldbed", 1, 3, {"offset": Vector2(8, 0), "area": Rect2i(1, 3, 2, 1), "event": {"id": "yourbed"}}),
				p("desk", 7, 2, {"offset": Vector2(8, 0), "area": Rect2i(7, 2, 2, 1), "event": {"id": "yourdesk"}}),
				p("locker", 8, 5, {"v": 1, "event": {"id": "locker"}}),
				p("lamp", 4, 2, {"light": Pal.LEMON, "lr": 18, "light_off": Vector2(0, -24), "area": Rect2i()}),
			]
			tint = Color(0.92, 0.9, 0.96)
		"hiro":
			props = [
				p("foldbed", 1, 3, {"offset": Vector2(8, 0), "area": Rect2i(1, 3, 2, 1), "event": {"id": "hirobed"}}),
				p("board", 2, 1, {"wall": true, "area": Rect2i(), "offset": Vector2(8, 0), "v": 0}),
				p("crate", 8, 5, {"event": {"id": "hirocrate"}}),
				p("punchbag", 8, 3, {"event": {"id": "hirobag"}}),
			]
			events.append_array([{"tile": Vector2i(2, 1), "id": "hiroboard"}, {"tile": Vector2i(3, 1), "id": "hiroboard"}])
		"pala":
			props = [
				p("foldbed", 1, 3, {"offset": Vector2(8, 0), "area": Rect2i(1, 3, 2, 1), "event": {"id": "palabed"}}),
				p("drawings", 2, 1, {"offset": Vector2(8, 0), "wall": true, "lift": 10, "area": Rect2i()}),
				p("desk", 5, 2, {"offset": Vector2(8, 0), "area": Rect2i(5, 2, 2, 1), "event": {"id": "paladesk"}}),
				p("shelf", 8, 2, {"event": {"id": "palashelf"}}),
				p("crate", 8, 5, {"event": {"id": "pala_stack"}}),
			]
			events.append_array([{"tile": Vector2i(2, 1), "id": "palastars"}, {"tile": Vector2i(3, 1), "id": "palastars"}])
			tint = Color(0.82, 0.84, 1.0)
		"midas":
			props = [
				p("foldbed", 1, 3, {"offset": Vector2(8, 0), "area": Rect2i(1, 3, 2, 1), "event": {"id": "midasbed"}}),
				p("desk", 5, 2, {"offset": Vector2(8, 0), "area": Rect2i(5, 2, 2, 1), "event": {"id": "midasdesk"}}),
			]
			if dead:
				props.append(p("crate", 8, 5, {"event": {"id": "effects"}}))
				tint = Color(0.74, 0.74, 0.86)
			else:
				props.append(p("toy", 5, 2, {"offset": Vector2(4, 0), "lift": 12, "v": 1, "area": Rect2i()}))
				props.append(p("cup", 6, 2, {"offset": Vector2(4, 1), "lift": 12, "area": Rect2i()}))
				props.append(p("plant", 8, 2, {"event": {"id": "seedling"}}))
				tint = Color(0.96, 0.9, 0.86)
		"wash":
			_fill(rows, Rect2i(1, 2, 8, 4), ":")
			_put(rows, 4, 6, "d")
			_put(rows, 5, 6, "d")
			for x in [2, 4, 6]:
				# you look in the mirror from the basin under it
				props.append(p("basin", x, 2, {"event": {"id": "mirror"}}))
				props.append(p("mirror", x, 1, {"wall": true, "lift": 13, "area": Rect2i()}))
			props.append(p("tub", 7, 4, {"offset": Vector2(8, 0), "area": Rect2i(7, 4, 2, 1), "event": {"id": "showers"}}))
			tint = Color(0.94, 0.98, 1.0)
	# a window behind the desk can't be looked out of
	for pr in props:
		var ar: Rect2i = pr.get("area", Rect2i(pr.tile.x, pr.tile.y, 1, 1))
		events = events.filter(func(e): return not (e.id == "dormwindow" and ar.has_point(Vector2i(e.tile.x, 2))))
	return _finish("dorm_" + who, rows, {"tint": tint, "props": props, "events": events,
		"exits": [{"rect": Rect2i(4, 6, 2, 1), "to": "dorms"}], "entry": [Vector2i(4, 5), 1], "route": Vector2i(4, 6)})


# ------------------------------------------------------------------ decks ---

static func rec_deck() -> Dictionary:
	## The lower deck: loud, wide, smells of the mess hall.
	var rows := _box(24, 8)
	_fill(rows, Rect2i(1, 0, 2, 2), "U")
	_fill(rows, Rect2i(1, 2, 2, 1), "S")
	_fill(rows, Rect2i(9, 4, 8, 2), ",")
	var props := [
		p("vending", 22, 2, {"anim": 2, "fps": 1.5, "event": {"id": "deck_vending"}, "light": Pal.GLOW, "lr": 10}),
		p("board", 15, 1, {"wall": true, "area": Rect2i(), "offset": Vector2(8, 0), "v": 0}),
		p("bench", 12, 6, {"offset": Vector2(8, 0), "area": Rect2i(12, 6, 2, 1)}),
		p("plant", 4, 6, {}), p("plant", 22, 6, {"v": 1}),
	]
	var events := [{"tile": Vector2i(15, 1), "id": "ladder"}, {"tile": Vector2i(16, 1), "id": "ladder"}]
	var signs := [{"x": 4, "y": 1, "text": "CONCOURSE", "left": true}]
	var npcs := [{"id": "deck_kid", "spec": Data.EXTRAS[3], "tile": Vector2i(18, 5), "dir": 3, "wander": true, "range": 2.0}]
	return _finish("rec_deck", rows, {"tint": Color(0.88, 0.9, 1.0), "props": props, "events": events, "signs": signs, "npcs": npcs,
		"exits": [{"rect": Rect2i(1, 2, 2, 1), "to": "concourse"}], "entry": [Vector2i(3, 3), 2], "route": Vector2i(1, 2)})


static func upper_deck() -> Dictionary:
	## The upper deck: carpeted, quieter, long windows.
	var rows := _box(26, 7)
	_fill(rows, Rect2i(3, 3, 21, 2), ",")
	_fill(rows, Rect2i(1, 5, 2, 2), "v")
	for x in [9, 10, 15, 16, 20, 21]:
		_put(rows, x, 0, "W")
		_put(rows, x, 1, "W")
	var props := [
		p("bench", 9, 5, {"offset": Vector2(8, 0), "area": Rect2i(9, 5, 2, 1)}),
		p("bench", 15, 5, {"offset": Vector2(8, 0), "area": Rect2i(15, 5, 2, 1)}),
		p("plant", 4, 2, {"v": 1}), p("plant", 24, 5, {}),
		p("lamp", 21, 5, {"light": Pal.LEMON, "lr": 20, "light_off": Vector2(0, -24), "pulse": 1.5}),
	]
	var events := []
	for x in [9, 10, 15, 16, 20, 21]:
		events.append({"tile": Vector2i(x, 1), "id": "upperwindow"})
	var signs := [{"x": 4, "y": 1, "text": "CONCOURSE", "left": true}]
	return _finish("upper_deck", rows, {"tint": Color(0.8, 0.82, 0.98), "props": props, "events": events, "signs": signs,
		"exits": [{"rect": Rect2i(1, 6, 2, 1), "to": "concourse"}], "entry": [Vector2i(3, 3), 2], "route": Vector2i(1, 6)})


# ------------------------------------------------------------------ rooms ---

static func room_door(id: String) -> Vector2i:
	## The left tile of a room's doorway (in its bottom wall).
	var sz: Vector2i = ROOM_SIZE[id]
	return Vector2i(sz.x / 2 - 1, sz.y - 1)


static func room_out(id: String) -> Array:
	## A walk from inside a room out through its doorway.
	var d := room_door(id)
	return [d + Vector2i(0, -1), d]


static func room(id: String) -> Dictionary:
	## One room off a deck, sized for what it's for; the way out is in the
	## middle of the bottom wall.
	var sz: Vector2i = ROOM_SIZE[id]
	var rows := _box(sz.x, sz.y)
	var dx := sz.x / 2 - 1
	_put(rows, dx, sz.y - 1, "d")
	_put(rows, dx + 1, sz.y - 1, "d")
	var props := []
	var npcs := []
	var events := []
	var tint := Color(0.86, 0.9, 1.0)
	var music := "low_mechanical_ambient"
	var theme := "academy"
	match id:
		"rec":
			for x in [4, 5, 10, 11]:
				_put(rows, x, 0, "W")
				_put(rows, x, 1, "W")
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
			# the big room: a serving line, long tables, the quota board
			_fill(rows, Rect2i(1, 2, 20, 2), ":")
			props = [
				p("counter", 3, 2, {"offset": Vector2(8, 0), "area": Rect2i(3, 2, 2, 1), "event": {"id": "tray"}}),
				p("counter", 5, 2, {"offset": Vector2(8, 0), "v": 1, "area": Rect2i(5, 2, 2, 1), "event": {"id": "cereal"}}),
				p("counter", 7, 2, {"offset": Vector2(8, 0), "area": Rect2i(7, 2, 2, 1), "event": {"id": "tray"}}),
				p("vending", 19, 2, {"anim": 2, "fps": 1.5, "event": {"id": "dispenser"}, "light": Pal.GLOW, "lr": 10}),
				p("board", 12, 1, {"wall": true, "area": Rect2i(), "offset": Vector2(8, 0)}),
				p("table", 4, 5, {"offset": Vector2(8, 0), "area": Rect2i(3, 5, 4, 1), "v": 1}),
				p("table", 16, 5, {"offset": Vector2(8, 0), "area": Rect2i(15, 5, 4, 1), "v": 1}),
				p("table", 4, 7, {"offset": Vector2(8, 0), "area": Rect2i(3, 7, 4, 1), "v": 1}),
				p("table", 16, 7, {"offset": Vector2(8, 0), "area": Rect2i(15, 7, 4, 1), "v": 1}),
				p("plant", 1, 8, {}), p("plant", 20, 8, {"v": 1}),
			]
			events = [{"tile": Vector2i(12, 1), "id": "quota"}, {"tile": Vector2i(13, 1), "id": "quota"}]
			npcs = [{"id": "gossip0", "spec": Data.EXTRAS[0], "tile": Vector2i(4, 6), "dir": 1},
				{"id": "gossip1", "spec": Data.EXTRAS[2], "tile": Vector2i(17, 8), "dir": 1},
				{"id": "eater", "spec": Data.EXTRAS[4], "tile": Vector2i(16, 4), "dir": 0}]
		"archive":
			# narrow and deep: shelves down both sides, terminals in the aisle
			tint = Color(0.8, 0.84, 0.98)
			props = [
				p("shelf", 2, 2, {"event": {"id": "shelf"}}), p("shelf", 3, 2, {"event": {"id": "shelf"}}),
				p("shelf", 8, 2, {"event": {"id": "shelf"}}), p("shelf", 9, 2, {"event": {"id": "shelf"}}),
				p("shelf", 1, 5, {"event": {"id": "shelf"}}), p("shelf", 10, 5, {"event": {"id": "shelf"}}),
				p("terminal", 3, 4, {"anim": 2, "fps": 2.0, "event": {"id": "lore"}, "light": Pal.SYNC, "lr": 18, "pulse": 2.0}),
				p("terminal", 8, 4, {"anim": 2, "fps": 2.5, "event": {"id": "lore"}, "light": Pal.SYNC, "lr": 18, "pulse": 2.5}),
				p("locker", 10, 7, {"v": 1, "event": {"id": "cabinet"}}),
				p("crate", 1, 8, {"event": {"id": "pala_stack"}}),
			]
		"gym":
			_fill(rows, Rect2i(5, 4, 8, 3), "_")
			props = [
				p("simpod", 2, 3, {"anim": 2, "fps": 1.0, "area": Rect2i(2, 2, 2, 2), "offset": Vector2(8, 0), "light": Pal.SYNC, "lr": 14, "pulse": 2.0, "event": {"id": "simpod"}}),
				p("treadmill", 6, 3, {"anim": 2, "fps": 3.0, "offset": Vector2(8, 0), "area": Rect2i(6, 3, 2, 1), "event": {"id": "treadmill"}}),
				p("punchbag", 13, 3, {"event": {"id": "punchbag"}, "id": "punchbag"}),
				p("console", 16, 6, {"anim": 2, "fps": 2.0, "area": Rect2i(15, 6, 2, 1), "offset": Vector2(-8, 0), "light": Pal.GLOW, "lr": 12, "event": {"id": "drill"}}),
				p("board", 9, 1, {"wall": true, "area": Rect2i(), "offset": Vector2(8, 0)}),
				p("bench", 3, 7, {"offset": Vector2(8, 0), "area": Rect2i(3, 7, 2, 1)}),
			]
			events = [{"tile": Vector2i(9, 1), "id": "times"}, {"tile": Vector2i(10, 1), "id": "times"}]
		"observation":
			# wide and low: the whole wall is window
			tint = Color(0.72, 0.76, 0.98)
			for x in range(1, sz.x - 1):
				_put(rows, x, 0, "W")
				_put(rows, x, 1, "W")
				events.append({"tile": Vector2i(x, 1), "id": "deckwindow"})
			props = [
				p("bench", 5, 4, {"offset": Vector2(8, 0), "area": Rect2i(5, 4, 2, 1)}),
				p("bench", 15, 4, {"offset": Vector2(8, 0), "area": Rect2i(15, 4, 2, 1)}),
				p("telescope", 19, 3, {"event": {"id": "telescope"}}),
				p("plant", 1, 6, {}), p("plant", 20, 6, {"v": 1}),
			]
		"memorial":
			tint = Color(0.78, 0.74, 0.86)
			music = ""
			props = [
				p("board", 5, 1, {"wall": true, "area": Rect2i(), "offset": Vector2(8, 0), "v": 12, "id": "wall"}),
				p("candles", 5, 3, {"anim": 2, "fps": 3.0, "offset": Vector2(8, 0), "area": Rect2i(5, 3, 2, 1), "light": Pal.LEMON, "lr": 20, "pulse": 4.0, "event": {"id": "candles"}}),
				p("podium", 9, 5, {"event": {"id": "guestbook"}}),
				p("bench", 2, 6, {"offset": Vector2(8, 0), "area": Rect2i(2, 6, 2, 1)}),
				p("plant", 10, 2, {}), p("plant", 1, 2, {}),
			]
			events = [{"tile": Vector2i(5, 1), "id": "names"}, {"tile": Vector2i(6, 1), "id": "names"}]
		"rooftop":
			tint = Maps.NIGHT.lerp(Color.WHITE, 0.35)
			theme = "outdoor"
			for y in sz.y - 1:
				rows[y] = ".".repeat(sz.x) if y < 2 else "g".repeat(sz.x)
			props = [
				p("planter", 3, 3, {"offset": Vector2(8, 0), "area": Rect2i(2, 3, 3, 1), "event": {"id": "planter"}}),
				p("planter", 14, 3, {"offset": Vector2(8, 0), "area": Rect2i(13, 3, 3, 1), "event": {"id": "planter"}}),
				# Midas' tomatoes: fruiting while he's alive, wilted once he's
				# gone, green again once someone waters them
				p("planter", 3, 6, {"offset": Vector2(8, 0), "area": Rect2i(2, 6, 3, 1), "id": "tomato", "event": {"id": "tomato"},
					"v": 1 if not Game.midas_dead() else (0 if bool(Game.story.get("watered_tomato", false)) else 2)}),
				p("bench", 13, 6, {"offset": Vector2(8, 0), "area": Rect2i(13, 6, 2, 1)}),
				p("streetlamp", 11, 3, {"light": Pal.LEMON, "lr": 26, "light_off": Vector2(0, -38), "pulse": 1.0}),
			]
			events = [{"tile": Vector2i(8, 1), "id": "rooftop_sky"}, {"tile": Vector2i(9, 1), "id": "rooftop_sky"}]
	var rid := "room_" + id
	var d := room_door(id)
	return _finish(rid, rows, {"name": ROOM_NAMES[id], "theme": theme, "tint": tint, "props": props, "npcs": npcs, "music": music,
		"events": events, "exits": [{"rect": Rect2i(d.x, d.y, 2, 1), "to": PARENT[rid]}],
		"entry": [d + Vector2i(0, -1), 1], "route": d})
