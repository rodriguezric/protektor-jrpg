extends SceneTree
## Debug: renders contact sheets of generated art to PNGs in $OUT.
## godot --headless --path . -s tools/sheet.gd -- people|portraits|mission|props

var out := Image.create_empty(480, 270, false, Image.FORMAT_RGBA8)
var cur := Vector2i(2, 2)
var row_h := 0


func put(img: Image) -> void:
	if cur.x + img.get_width() > out.get_width():
		cur.x = 2
		cur.y += row_h + 2
		row_h = 0
	out.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), cur)
	cur.x += img.get_width() + 2
	row_h = maxi(row_h, img.get_height())


func save(name: String, k: int = 3) -> void:
	out.resize(out.get_width() * k, out.get_height() * k, Image.INTERPOLATE_NEAREST)
	out.save_png(OS.get_environment("OUT") + "/" + name + ".png")


func _init() -> void:
	var what: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "people"
	out.fill(Color("3a3548"))
	match what:
		"people":
			for id in Data.CAST:
				var s: Dictionary = Data.CAST[id]
				for d in 3:
					put(ArtPeople.render(s, d, 0).img)
				put(ArtPeople.render(s, 0, 1).img)
				put(ArtPeople.render(s, 0, 0, "sad").img)
				put(ArtPeople.render(s, 0, 0, "hollow").img)
				put(ArtPeople.render(s, 0, 0, "", "sit").img)
			for s in Data.EXTRAS:
				put(ArtPeople.render(s, 0, 0).img)
		"portraits":
			out = Image.create_empty(66 * 8 + 2, 66 * 7 + 2, false, Image.FORMAT_RGBA8)
			out.fill(Color("1a1622"))
			for id in ["hiro", "pala", "midas", "instructor", "mother", "father"]:
				var s: Dictionary = Data.CAST[id]
				for m in ["", "smile", "sad", "hollow", "shock", "cry", "angry", "closed"]:
					put(ArtPortraits.from_sprite(s, m).img)
			for l in Data.LOOKS:
				var s: Dictionary = l.duplicate()
				s.merge({"top": Pal.TEAL, "hood": true, "hoodc": Pal.TEAL, "jacket": Data.JACKET, "badge": true})
				put(ArtPortraits.from_sprite(s, "").img)
			put(ArtPortraits.from_sprite(Data.CAST.hiro, "", true).img)
			put(ArtPortraits.from_sprite(Data.CAST.hiro, "", false, true).img)
			put(ArtPortraits.from_sprite(Data.CAST.father, "", false, true).img)
			put(ArtPortraits.system_icon(0).img)
			put(ArtPortraits.comm(0).img)
		"mission":
			out = Image.create_empty(480, 300, false, Image.FORMAT_RGBA8)
			out.fill(Color("0e1119"))
			for key in ["green_planet", "cold_planet", "hot_planet", "metal_planet", "tempestris_planet", "viscera_nova_planet", "umbra_vacua_planet"]:
				put(ArtMission.planet(key, 20, 0).img)
				put(ArtMission.planet(key, 20, 8).img)
				put(ArtMission.planet(key, 48, 3).img)
			for kind in ["drone_basic", "drone_fast", "drone_tank", "charger_drone", "drone_shifter", "drone_sine", "circle_shooter_drone", "spiral_drone"]:
				var sz: float = {"drone_basic": 22.0, "drone_fast": 22.0, "drone_tank": 40.0, "charger_drone": 30.0, "drone_shifter": 22.0, "drone_sine": 22.0, "circle_shooter_drone": 42.0, "spiral_drone": 26.0}[kind]
				var dd := ArtMission.sprite_size(kind, sz)
				for look in [0, 2, 5]:
					var im := ArtMission.drone(kind, dd, look, 0).img
					im.resize(im.get_width() * 2, im.get_height() * 2, Image.INTERPOLATE_NEAREST)
					put(im)
			for f in 4:
				var im := ArtMission.asteroid(ArtMission.sprite_size("asteroid", 18.0), 1, f).img
				im.resize(im.get_width() * 2, im.get_height() * 2, Image.INTERPOLATE_NEAREST)
				put(im)
			put(ArtMission.space(120, 60, "hot_planet").img)
		"props":
			out = Image.create_empty(480, 300, false, Image.FORMAT_RGBA8)
			out.fill(Color("3a3548"))
			for k in ["counter", "stove", "fridge", "table", "chair", "foldbed", "kidbed", "shelf", "heater", "lamp", "plant", "letter", "packet", "bench", "podium", "console", "terminal", "holo", "pod", "vending", "board", "couch", "crate", "scanner", "medbed", "comm", "pillar", "simpod", "banner", "locker", "tray", "bot", "stage", "mech", "barrier", "pole", "shuttle", "speaker"]:
				put(ArtProps.make(k, 1 if k == "shuttle" else 0).img)
		"tiles":
			out = ArtTiles.ground(["############", "#W##D###WW##", "#..........#", "#..,,,,::..#", "#..,,,,::..#", "#====______#", "############"], "academy")
			out.blend_rect(ArtTiles.ground(["#####", "#W#D#", "#...#", "#,,:#", "#####"], "home"), Rect2i(0, 0, 80, 80), Vector2i(0, 0))
	save(what)
	quit()
