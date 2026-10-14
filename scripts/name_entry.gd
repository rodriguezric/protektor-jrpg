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
var help: Label
## Set by End: the name is accepted.
var done := false


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
	pb.size = Vector2(80, 112)
	add_child(pb)
	pic = TextureRect.new()
	pic.position = Vector2(16, 6)
	pb.add_child(pic)
	sprite = TextureRect.new()
	sprite.position = Vector2(24, 66)
	pb.add_child(sprite)
	look_l = Art.label("", Pal.TEXT)
	look_l.position = Vector2(8, 98)
	pb.add_child(look_l)
	var gb := Art.make_box("box")
	gb.position = Vector2(96, 32)
	gb.size = Vector2(214, 112)
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
			l.position = Vector2(14 + c * 15, 24 + r * 15)
			gb.add_child(l)
			row.append(l)
		grid.append(row)
	var extras := ["< Look >", "Del", "End"]
	var row := []
	for i in extras.size():
		var l := Art.label(extras[i], Pal.SYNC)
		l.position = Vector2(14 + i * 60, 90)
		gb.add_child(l)
		row.append(l)
	grid.append(row)
	cursor = TextureRect.new()
	cursor.texture = Art.ui("cursor")
	gb.add_child(cursor)
	help = Art.label("", Pal.TEXT_DIM)
	help.position = Vector2(12, 148)
	add_child(help)
	var tip := Art.label("Your name will be etched into your badge.", Pal.CREAM)
	tip.position = Vector2(12, 162)
	add_child(tip)
	name_text = Game.player_name


func _process(delta: float) -> void:
	t += delta
	help.text = "Tap letters to type   B erase" if Game.touch_active else "Z type   X erase   Left/Right on Look to change"
	var spec := Game.player_spec("home")
	pic.texture = Art.portrait(spec, "", false, false, 2)
	sprite.texture = Art.person(spec, 0, [0, 1, 0, 3][int(t * 6.0) % 4])
	look_l.text = "Look %d/%d" % [Game.look + 1, Data.LOOKS.size()]
	name_l.text = name_text + ("_" if fmod(t, 0.8) < 0.4 and name_text.length() < MAXLEN else "")
	var l: Label = grid[cy][cx]
	cursor.position = l.position + Vector2(-8 - (1 if fmod(t, 0.5) < 0.25 else 0), 1)


func tap(p: Vector2) -> bool:
	## Touch: works like a keyboard, so one tap types a letter (or presses
	## Del / End). Tap either half of "< Look >", or the portrait, to change
	## your look. Taps elsewhere are still taken, so they never confirm.
	if (pic.get_parent() as Control).get_global_rect().has_point(p):
		_change_look(1)
		return true
	for r in grid.size():
		for c in (grid[r] as Array).size():
			var l: Label = grid[r][c]
			var w := 15.0 if r < ROWS.size() else 60.0
			var cell := Rect2(l.global_position + Vector2(-5, -4), Vector2(w, 15))
			if not cell.has_point(p):
				continue
			cx = c
			cy = r
			if r == ROWS.size() and c == 0:
				_change_look(-1 if p.x < l.global_position.x + Art.text_width(l.text) / 2.0 else 1)
			else:
				_activate()
			return true
	return true


func _change_look(d: int) -> void:
	Game.look = (Game.look + d + Data.LOOKS.size()) % Data.LOOKS.size()
	Sfx.play("pop")


func run() -> void:
	await get_tree().process_frame
	add_to_group("tap_targets")
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
				_change_look(1)
			else:
				cx += 1
				moved = true
		elif Input.is_action_just_pressed("left"):
			if cy == grid.size() - 1 and cx == 0:
				_change_look(-1)
			else:
				cx -= 1
				moved = true
		elif Input.is_action_just_pressed("cancel"):
			if name_text.length() > 0:
				name_text = name_text.substr(0, name_text.length() - 1)
				Sfx.play("cancel")
		elif Input.is_action_just_pressed("accept"):
			_activate()
		if done:
			remove_from_group("tap_targets")
			return
		if moved:
			cx = clampi(cx, 0, (grid[cy] as Array).size() - 1)
			Sfx.play("blip")


func _activate() -> void:
	## OK on whatever the cursor is on: type a letter, change look, Del, End.
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
		_change_look(1)
	elif cx == 1:
		if name_text.length() > 0:
			name_text = name_text.substr(0, name_text.length() - 1)
			Sfx.play("cancel")
	else:
		if name_text.strip_edges() == "":
			Sfx.play("miss")
			return
		Game.player_name = name_text.strip_edges()
		Sfx.play("confirm")
		done = true
