class_name NameEntry
extends Control
## Chapter 0: naming the protagonist. A letter grid, a look picker, and a live
## preview of your chibi walking in place.

const ROWS := ["ABCDEFGHIJKLM", "NOPQRSTUVWXYZ", "abcdefghijklm", "nopqrstuvwxyz"]
const MAXLEN := 8

var name_text := ""
var cx := 0
var cy := 0
var grid: Array = []
var cursor: TextureRect
var name_l: Label
var sprite: TextureRect
var pic: TextureRect
var look_l: Label
var t := 0.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = Art.space(320, 180, "green_planet")
	add_child(bg)
	var head := Art.make_box("sys_box")
	head.position = Vector2(6, 6)
	head.size = Vector2(308, 18)
	add_child(head)
	var q := Art.label("HELION COMMAND  -  PILOT REGISTRY", Pal.SYNC)
	q.position = Vector2(6, 4)
	head.add_child(q)
	var pb := Art.make_box("box")
	pb.position = Vector2(10, 32)
	pb.size = Vector2(80, 96)
	add_child(pb)
	pic = TextureRect.new()
	pic.position = Vector2(16, 4)
	pb.add_child(pic)
	sprite = TextureRect.new()
	sprite.position = Vector2(24, 56)
	pb.add_child(sprite)
	look_l = Art.label("", Pal.TEXT)
	look_l.position = Vector2(8, 84)
	pb.add_child(look_l)
	var gb := Art.make_box("box")
	gb.position = Vector2(96, 32)
	gb.size = Vector2(214, 96)
	add_child(gb)
	var nl := Art.label("Name:", Pal.TEXT_DIM)
	nl.position = Vector2(8, 5)
	gb.add_child(nl)
	name_l = Art.label("", Pal.LEMON)
	name_l.position = Vector2(40, 5)
	gb.add_child(name_l)
	for r in ROWS.size():
		var row := []
		for c in ROWS[r].length():
			var l := Art.label(ROWS[r][c], Pal.TEXT)
			l.position = Vector2(14 + c * 15, 22 + r * 13)
			gb.add_child(l)
			row.append(l)
		grid.append(row)
	var extras := ["< Look >", "Del", "End"]
	var row := []
	for i in extras.size():
		var l := Art.label(extras[i], Pal.SYNC)
		l.position = Vector2(14 + i * 60, 76)
		gb.add_child(l)
		row.append(l)
	grid.append(row)
	cursor = TextureRect.new()
	cursor.texture = Art.ui("cursor")
	gb.add_child(cursor)
	var help := Art.label("Z type   X erase   Left/Right on Look to change", Pal.TEXT_DIM)
	help.position = Vector2(12, 134)
	add_child(help)
	var tip := Art.label("Your name will be etched into your badge.", Pal.CREAM)
	tip.position = Vector2(12, 150)
	add_child(tip)
	name_text = Game.player_name


func _process(delta: float) -> void:
	t += delta
	var spec := Game.player_spec("home")
	pic.texture = Art.portrait(spec, "")
	sprite.texture = Art.person(spec, 0, [0, 1, 0, 3][int(t * 6.0) % 4])
	look_l.text = "Look %d/%d" % [Game.look + 1, Data.LOOKS.size()]
	name_l.text = name_text + ("_" if fmod(t, 0.8) < 0.4 and name_text.length() < MAXLEN else "")
	var l: Label = grid[cy][cx]
	cursor.position = l.position + Vector2(-8 - (1 if fmod(t, 0.5) < 0.25 else 0), 1)


func run() -> void:
	await get_tree().process_frame
	while true:
		await get_tree().process_frame
		var moved := false
		if Input.is_action_just_pressed("down"):
			cy = (cy + 1) % grid.size()
			moved = true
		elif Input.is_action_just_pressed("up"):
			cy = (cy - 1 + grid.size()) % grid.size()
			moved = true
		elif Input.is_action_just_pressed("right"):
			if cy == grid.size() - 1 and cx == 0:
				Game.look = (Game.look + 1) % Data.LOOKS.size()
				Sfx.play("pop")
			else:
				cx += 1
				moved = true
		elif Input.is_action_just_pressed("left"):
			if cy == grid.size() - 1 and cx == 0:
				Game.look = (Game.look - 1 + Data.LOOKS.size()) % Data.LOOKS.size()
				Sfx.play("pop")
			else:
				cx -= 1
				moved = true
		elif Input.is_action_just_pressed("cancel"):
			if name_text.length() > 0:
				name_text = name_text.substr(0, name_text.length() - 1)
				Sfx.play("cancel")
		elif Input.is_action_just_pressed("accept"):
			if cy < ROWS.size():
				if name_text.length() < MAXLEN:
					name_text += ROWS[cy][cx]
					Sfx.play("blip", 1.2)
					var l: Label = grid[cy][cx]
					l.scale = Vector2(1.6, 1.6)
					create_tween().tween_property(l, "scale", Vector2.ONE, 0.15)
				else:
					Sfx.play("miss")
			elif cx == 0:
				Game.look = (Game.look + 1) % Data.LOOKS.size()
				Sfx.play("pop")
			elif cx == 1:
				if name_text.length() > 0:
					name_text = name_text.substr(0, name_text.length() - 1)
					Sfx.play("cancel")
			else:
				if name_text.strip_edges() == "":
					Sfx.play("miss")
					continue
				Game.player_name = name_text.strip_edges()
				Sfx.play("confirm")
				return
		if moved:
			cx = clampi(cx, 0, (grid[cy] as Array).size() - 1)
			Sfx.play("blip")
