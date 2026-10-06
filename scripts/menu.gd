class_name Menu
extends NinePatchRect
## A boxed list of options with a pixel cursor. `await menu.ask()` returns the
## chosen index, or -1 when cancelled.

signal done(index: int)
signal moved(index: int)

var entries: Array = []
var cols := 1
var col_w := 60
var row_h := 10
var index := 0
var active := false
var cancellable := true
var cursor: TextureRect
var labels: Array = []
var _armed := 0


static func make(parent: Node, opts: Array, pos: Vector2, size_: Vector2, p_cols: int = 1) -> Menu:
	var m := Menu.new()
	m.texture = Art.ui("box")
	m.patch_margin_left = 4
	m.patch_margin_right = 4
	m.patch_margin_top = 4
	m.patch_margin_bottom = 4
	m.position = pos
	m.size = size_
	m.cols = p_cols
	m.col_w = int((size_.x - 8) / p_cols)
	parent.add_child(m)
	m.set_entries(opts)
	return m


func set_entries(opts: Array) -> void:
	## opts: strings, or {text, enabled, right} dictionaries.
	for l in labels:
		l.queue_free()
	labels.clear()
	entries = []
	for o in opts:
		entries.append(o if o is Dictionary else {"text": o})
	for i in entries.size():
		var e: Dictionary = entries[i]
		var l := Label.new()
		l.text = e.text
		l.position = _slot(i) + Vector2(8, 0)
		var col := Pal.TEXT if e.get("enabled", true) else Pal.TEXT_DIM
		l.add_theme_color_override("font_color", col)
		add_child(l)
		labels.append(l)
		if e.has("right"):
			var r := Label.new()
			r.text = str(e.right)
			r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			r.size = Vector2(col_w - 12, 10)
			r.position = _slot(i)
			r.add_theme_color_override("font_color", col)
			add_child(r)
			labels.append(r)
	if cursor == null:
		cursor = TextureRect.new()
		cursor.texture = Art.ui("cursor")
		add_child(cursor)
	index = clampi(index, 0, maxi(0, entries.size() - 1))
	_place_cursor()


func _slot(i: int) -> Vector2:
	return Vector2(5 + (i % cols) * col_w, 3 + (i / cols) * row_h)


func _place_cursor() -> void:
	if cursor:
		cursor.position = _slot(index) + Vector2(0, 0)
		cursor.visible = active or entries.size() > 0


func ask() -> int:
	active = true
	_armed = Engine.get_process_frames()
	cursor.visible = true
	_place_cursor()
	moved.emit(index)
	var r: int = await done
	active = false
	return r


func _process(delta: float) -> void:
	if cursor:
		cursor.modulate.a = 1.0 if active else 0.45
		if active:
			cursor.position.x = _slot(index).x - (1 if fmod(Time.get_ticks_msec() / 1000.0, 0.5) < 0.25 else 0)
	if not active or Engine.get_process_frames() == _armed or entries.is_empty():
		return
	var old := index
	var n := entries.size()
	if Input.is_action_just_pressed("down"):
		index = (index + cols) % n if index + cols < n or cols == 1 else index % cols
	elif Input.is_action_just_pressed("up"):
		index = index - cols if index - cols >= 0 else (n - 1 if cols == 1 else index)
	elif Input.is_action_just_pressed("right") and cols > 1:
		index = mini(index + 1, n - 1)
	elif Input.is_action_just_pressed("left") and cols > 1:
		index = maxi(index - 1, 0)
	elif Input.is_action_just_pressed("accept"):
		if entries[index].get("enabled", true):
			Sfx.play("confirm")
			done.emit(index)
		else:
			Sfx.play("miss")
		return
	elif Input.is_action_just_pressed("cancel") and cancellable:
		Sfx.play("cancel")
		done.emit(-1)
		return
	if index != old:
		Sfx.play("blip")
		_place_cursor()
		moved.emit(index)
