class_name DialogBox
extends Control
## Typewriter dialog box with portraits.
## `await dialog.say(lines, speaker, opts)`; `await dialog.ask(question, options, speaker, opts)`.
## opts: portrait (spec | "system" | "comm"), mood, side ("left"/"right"), voice,
## color, auto (advance by itself), sys (Helion box style).

const TEXT_W := 292
const LINES := 3

var box: NinePatchRect
var text: Label
var name_box: NinePatchRect
var name_label: Label
var arrow: TextureRect
var pframe: NinePatchRect
var pic: TextureRect
var _armed := 0
var _portrait_key := ""
var _portrait_side := ""
var _talking := false
var _anim_t := 0.0
var _anim_portrait := ""
var _box_tween: Tween
var _open := false
var skip_all := false


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pframe = Art.make_box("box")
	pframe.size = Vector2(54, 54)
	pframe.position = Vector2(8, 60)
	add_child(pframe)
	pic = TextureRect.new()
	pic.position = Vector2(3, 3)
	pframe.add_child(pic)
	pframe.visible = false
	box = Art.make_box()
	box.position = Vector2(6, 128)
	box.size = Vector2(308, 46)
	add_child(box)
	text = Label.new()
	text.position = Vector2(8, 5)
	text.size = Vector2(TEXT_W, 38)
	box.add_child(text)
	name_box = Art.make_box("bar_box")
	name_box.position = Vector2(10, 116)
	name_box.size = Vector2(60, 15)
	add_child(name_box)
	name_label = Label.new()
	name_label.position = Vector2(5, 3)
	name_box.add_child(name_label)
	arrow = TextureRect.new()
	arrow.texture = Art.ui("down")
	arrow.position = Vector2(294, 36)
	box.add_child(arrow)
	visible = false


func _process(delta: float) -> void:
	if arrow.visible:
		arrow.position.y = 35 + (1 if fmod(Time.get_ticks_msec() / 1000.0, 0.6) < 0.3 else 0)
	_anim_t += delta
	if pframe.visible:
		# the system eye / comm waveform animate
		if _anim_portrait == "system":
			pic.texture = Art.system_portrait(int(_anim_t * 8.0) % 48)
		elif _anim_portrait == "comm":
			pic.texture = Art.comm_portrait(int(_anim_t * 10.0) % 16 if _talking else 0)


func _pressed(action: String) -> bool:
	return Engine.get_process_frames() != _armed and Input.is_action_just_pressed(action)


func _open_box(sys: bool) -> void:
	box.texture = Art.ui("sys_box" if sys else "box")
	if _open:
		return
	_open = true
	visible = true
	if _box_tween:
		_box_tween.kill()
	box.position.y = 186
	_box_tween = create_tween()
	_box_tween.tween_property(box, "position:y", 128.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close() -> void:
	_open = false
	visible = false
	pframe.visible = false
	_portrait_key = ""
	name_box.visible = false


func _set_portrait(opts: Dictionary) -> void:
	var p = opts.get("portrait", null)
	if p == null:
		pframe.visible = false
		_portrait_key = ""
		_anim_portrait = ""
		return
	var side: String = opts.get("side", "left")
	var key := ""
	if p is String:
		_anim_portrait = p
		key = p
		pic.texture = Art.system_portrait(0) if p == "system" else Art.comm_portrait(0)
		pframe.texture = Art.ui("sys_box" if p == "system" else "bar_box")
	else:
		_anim_portrait = ""
		var mood: String = opts.get("mood", "")
		pic.texture = Art.portrait(p, mood)
		pframe.texture = Art.ui("box")
		key = "%s:%s" % [p.get("id", ""), p.get("variant", "")]
	var x := 8.0 if side == "left" else 258.0
	var changed := key != _portrait_key or side != _portrait_side or not pframe.visible
	_portrait_key = key
	_portrait_side = side
	pframe.visible = true
	if changed:
		pframe.position = Vector2(x + (-30 if side == "left" else 30), 60)
		pframe.modulate.a = 0.0
		var t := create_tween().set_parallel(true)
		t.tween_property(pframe, "position:x", x, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(pframe, "modulate:a", 1.0, 0.12)
	else:
		# mood swap: a little squash
		pframe.scale = Vector2(1.06, 0.94)
		pframe.pivot_offset = pframe.size / 2.0
		create_tween().tween_property(pframe, "scale", Vector2.ONE, 0.12)
	name_box.position.x = 10.0 if side == "left" else 310.0 - name_box.size.x


func paginate(line: String) -> Array:
	## Word-wraps into pages of LINES lines that fit TEXT_W.
	var pages := []
	for para in line.split("\n"):
		var words := para.split(" ", false)
		var lines := []
		var cur := ""
		for w in words:
			var trial := w if cur == "" else cur + " " + w
			if Art.text_width(trial) > TEXT_W and cur != "":
				lines.append(cur)
				cur = w
			else:
				cur = trial
		if cur != "":
			lines.append(cur)
		for i in range(0, lines.size(), LINES):
			pages.append("\n".join(lines.slice(i, i + LINES)))
	return pages


func say(lines: Array, speaker: String = "", opts: Dictionary = {}) -> void:
	var sys: bool = opts.get("sys", false)
	_open_box(sys)
	_set_portrait(opts)
	name_box.visible = speaker != ""
	name_label.text = speaker
	name_box.size.x = Art.text_width(speaker) + 12
	if pframe.visible:
		name_box.position.x = 10.0 if _portrait_side == "left" else 310.0 - name_box.size.x
		name_box.position.y = 116
	else:
		name_box.position = Vector2(10, 116)
	text.add_theme_color_override("font_color", opts.get("color", Pal.TEXT if speaker != "" else Pal.CREAM))
	var pages := []
	for l in lines:
		pages.append_array(paginate(str(l)))
	for i in pages.size():
		var auto: bool = opts.get("auto", false) and i == pages.size() - 1
		await _type(pages[i], opts.get("voice", "narrator"), auto)
		if auto:
			await get_tree().create_timer(opts.get("auto_delay", 0.05)).timeout
			continue
		arrow.visible = true
		_armed = Engine.get_process_frames()
		while not (_pressed("accept") or _pressed("cancel") or skip_all):
			await get_tree().process_frame
		Sfx.play("blip", 1.3, -10.0)
		arrow.visible = false
	if not opts.get("keep", false):
		close()


func _type(line: String, voice: String, auto: bool) -> void:
	text.text = line
	text.visible_characters = 0
	arrow.visible = false
	_armed = Engine.get_process_frames()
	_talking = true
	var t := 0.0
	var hold := 0.0
	var n := 0
	var count := 0
	while n < line.length():
		await get_tree().process_frame
		if skip_all:
			break
		if _pressed("accept") and not auto:
			break
		var dt := get_process_delta_time()
		if hold > 0.0:
			hold -= dt
			continue
		t += dt * 48.0
		while n < mini(int(t), line.length()):
			n += 1
			var ch := line[n - 1]
			if ch != " " and ch != "\n":
				count += 1
				if count % 2 == 1:
					Sfx.voice(voice, count)
			if ch in ".!?" and n < line.length() and line[n] in " \n":
				hold = 0.16
				t = n
				break
			if ch in ",;:" or ch == "—":
				hold = 0.07
				t = n
				break
		text.visible_characters = n
	text.visible_characters = -1
	_talking = false


func ask(question: String, options: Array, speaker: String = "", opts: Dictionary = {}) -> int:
	var sys: bool = opts.get("sys", false)
	_open_box(sys)
	_set_portrait(opts)
	name_box.visible = speaker != ""
	name_label.text = speaker
	name_box.size.x = Art.text_width(speaker) + 12
	text.add_theme_color_override("font_color", opts.get("color", Pal.TEXT if speaker != "" else Pal.CREAM))
	await _type(question, opts.get("voice", "narrator"), false)
	var w := 0
	for o in options:
		w = maxi(w, Art.text_width(o if o is String else o.text))
	var h := options.size() * 10 + 7
	var m := Menu.make(self, options, Vector2(312 - w - 22, 124 - h), Vector2(w + 20, h))
	m.cancellable = false
	m.scale = Vector2(1, 0.2)
	m.pivot_offset = Vector2(0, h)
	create_tween().tween_property(m, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var r := await m.ask()
	m.queue_free()
	if not opts.get("keep", false):
		close()
	return r
