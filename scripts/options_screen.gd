class_name OptionsScreen
extends Control
## Options: music and sound volume, text speed and (on touch devices)
## vibration. Left/Right change the selected row, Z cycles it (a second tap
## does the same by touch), X or Back leaves. Changes apply at once and are
## saved to the settings file when the screen closes.

var menu: Menu
var rows: Array = []
var bars: Dictionary = {}
var help: Label
var dirty := false


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(Pal.INK, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var tb := Art.make_box("sys_box")
	tb.position = Vector2(80, 30)
	tb.size = Vector2(160, 16)
	add_child(tb)
	var title := Art.label("OPTIONS", Pal.SYNC)
	title.position = Vector2(5, 3)
	tb.add_child(title)
	rows = ["music", "sfx", "text"]
	if Game.touch_active or OS.has_feature("mobile"):
		rows.append("vibration")
	rows.append("back")
	menu = Menu.make(self, _entries(), Vector2(80, 50), Vector2(160, rows.size() * 10 + 7))
	for i in rows.size():
		if rows[i] == "music" or rows[i] == "sfx":
			var bb := ColorRect.new()
			bb.color = Pal.INK
			bb.position = Vector2(76, 5 + i * 10)
			bb.size = Vector2(52, 6)
			menu.add_child(bb)
			var f := ColorRect.new()
			f.color = Pal.SYNC
			f.position = Vector2(77, 6 + i * 10)
			menu.add_child(f)
			bars[rows[i]] = f
	help = Art.label("", Pal.TEXT_DIM)
	help.position = Vector2(80, 50 + rows.size() * 10 + 12)
	add_child(help)
	_refresh()


func _label(id: String) -> String:
	return {"music": "Music", "sfx": "Sound", "text": "Text speed", "vibration": "Vibration", "back": "Back"}[id]


func _value(id: String) -> String:
	match id:
		"music", "sfx":
			return str(int(Game.settings[id]))
		"text":
			return str(Game.TEXT_SPEEDS[int(Game.settings.text)][0])
		"vibration":
			return "On" if bool(Game.settings.vibration) else "Off"
	return ""


func _entries() -> Array:
	var out := []
	for id in rows:
		out.append({"text": _label(id), "right": _value(id)} if id != "back" else {"text": "Back"})
	return out


func _refresh() -> void:
	var keep := menu.index
	menu.set_entries(_entries())
	menu.index = keep
	menu._place_cursor()
	for id in bars:
		bars[id].size = Vector2(50.0 * int(Game.settings[id]) / 10.0, 4)
	help.text = "Tap a row, tap again to change" if Game.touch_active else "Left/Right change   X back"


func _change(id: String, step: int, wrap: bool) -> void:
	match id:
		"music", "sfx":
			var v := int(Game.settings[id]) + step
			v = (v + 11) % 11 if wrap else clampi(v, 0, 10)
			if v == int(Game.settings[id]):
				return
			Game.settings[id] = v
		"text":
			var n: int = Game.TEXT_SPEEDS.size()
			var v := int(Game.settings.text) + step
			v = (v + n) % n if wrap else clampi(v, 0, n - 1)
			if v == int(Game.settings.text):
				return
			Game.settings.text = v
		"vibration":
			Game.settings.vibration = not bool(Game.settings.vibration)
			if Game.settings.vibration and Game.touch_active:
				Input.vibrate_handheld(30)
		_:
			return
	dirty = true
	Sfx.apply_volumes(Game.settings.music, Game.settings.sfx)
	# the blip goes through the SFX bus, so it previews the new sound level
	Sfx.play("blip", 1.0 + step * 0.08, -8.0)
	_refresh()


func _process(_d: float) -> void:
	if not menu.active:
		return
	var id: String = rows[menu.index]
	if Input.is_action_just_pressed("right"):
		_change(id, 1, false)
	elif Input.is_action_just_pressed("left"):
		_change(id, -1, false)


func run() -> void:
	await get_tree().process_frame
	while true:
		var r := await menu.ask()
		if r < 0 or rows[r] == "back":
			break
		_change(rows[r], 1, true)
	if dirty:
		Game.save_settings()
	Sfx.play("cancel")
