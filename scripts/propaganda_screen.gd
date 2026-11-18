class_name PropagandaScreen
extends Control
## FILES: the Protektor propaganda you've found (Propaganda). The list on the
## left (unfound pieces are '? ? ?' with where to look), the selected piece
## on the right. X / B goes back.

var menu: Menu
var name_l: Label
var where_l: Label
var text_l: Label


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(Pal.INK, 0.9)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var tb := Art.make_box("sys_box")
	tb.position = Vector2(6, 4)
	tb.size = Vector2(308, 16)
	add_child(tb)
	var title := Art.label("FILES: HOW THEY SELL US   %d / %d" % [Propaganda.count(), Propaganda.ORDER.size()], Pal.SYNC)
	title.position = Vector2(5, 3)
	tb.add_child(title)
	var opts := []
	for id in Propaganda.ORDER:
		opts.append(Propaganda.PIECES[id][0] if Propaganda.has(id) else "? ? ?")
	menu = Menu.make(self, opts, Vector2(6, 24), Vector2(150, opts.size() * 10 + 7))
	var db := Art.make_box("box")
	db.position = Vector2(160, 24)
	db.size = Vector2(154, 137)
	add_child(db)
	name_l = Art.label("", Pal.LEMON)
	name_l.position = Vector2(6, 5)
	name_l.size = Vector2(142, 20)
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD
	db.add_child(name_l)
	where_l = Art.label("", Pal.TEXT_DIM)
	where_l.position = Vector2(6, 26)
	db.add_child(where_l)
	text_l = Art.label("", Pal.TEXT)
	text_l.position = Vector2(6, 40)
	text_l.size = Vector2(142, 92)
	text_l.autowrap_mode = TextServer.AUTOWRAP_WORD
	db.add_child(text_l)
	menu.moved.connect(_show)
	_show(0)


func _show(i: int) -> void:
	var id: String = Propaganda.ORDER[clampi(i, 0, Propaganda.ORDER.size() - 1)]
	var p: Array = Propaganda.PIECES[id]
	if Propaganda.has(id):
		name_l.text = p[0]
		where_l.text = p[1]
		text_l.text = p[2]
	else:
		name_l.text = "? ? ?"
		where_l.text = "Look: " + p[1]
		text_l.text = ""


func run() -> void:
	await get_tree().process_frame
	while true:
		var r := await menu.ask()
		if r < 0:
			break
		_show(r)
	Sfx.play("cancel")
