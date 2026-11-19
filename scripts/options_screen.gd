class_name OptionsScreen
extends Control
## Options: music and sound volume, text speed and (on touch devices)
## vibration and how arrow minigames are played (swipe, buttons or both).
## Left/Right change the selected row, Z cycles it (a second tap does the
## same by touch; tapping along a volume bar sets it), X or Back leaves.
## Changes apply at once and are saved to the settings file when the screen
## closes.

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
		rows.append("touch_arrows")
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
	# volume bars take taps along their length, ahead of the menu
	set_meta("tap_priority", 11)
	add_to_group("tap_targets")
	help = Art.label("", Pal.TEXT_DIM)
	help.position = Vector2(80, 50 + rows.size() * 10 + 12)
	add_child(help)
	_refresh()


func _label(id: String) -> String:
	return {"music": "Music", "sfx": "Sound", "text": "Text speed", "vibration": "Vibration", "touch_arrows": "Arrow games", "back": "Back"}[id]


func _value(id: String) -> String:
	match id:
		"music", "sfx":
			return str(int(Game.settings[id]))
		"text":
			return str(Game.TEXT_SPEEDS[int(Game.settings.text)][0])
		"vibration":
			return "On" if bool(Game.settings.vibration) else "Off"
		"touch_arrows":
			return Game.TOUCH_ARROWS[int(Game.settings.touch_arrows)]
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
		"touch_arrows":
			var n: int = Game.TOUCH_ARROWS.size()
			var v := int(Game.settings.touch_arrows) + step
			v = (v + n) % n if wrap else clampi(v, 0, n - 1)
			if v == int(Game.settings.touch_arrows):
				return
			Game.settings.touch_arrows = v
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


func tap(p: Vector2) -> bool:
	## A tap along a volume bar sets that volume (and selects the row);
	## anything else goes on to the menu.
	if not menu.active:
		return false
	for id in bars:
		var i := rows.find(id)
		var r := Rect2(menu.global_position + Vector2(76, 5 + i * 10), Vector2(52, 6)).grow(3)
		if r.has_point(p):
			menu.index = i
			menu._place_cursor()
			# the fill starts 1 px into the bar (r is grown by 3)
			var v := clampi(roundi((p.x - r.position.x - 4.0) / 50.0 * 10.0), 0, 10)
			_change(id, v - int(Game.settings[id]), false)
			return true
	return false


func run() -> void:
	await get_tree().process_frame
	while true:
		var r := await menu.ask()
		if r < 0 or rows[r] == "back":
			break
		_change(rows[r], 1, true)
	remove_from_group("tap_targets")
	if dirty:
		Game.save_settings()
	Sfx.play("cancel")
