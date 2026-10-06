class_name AchievementsScreen
extends Control
## The trophy wall. Category tabs along the top, a grid of cards that scrolls
## smoothly, and a detail panel for whatever card is selected.
## Arrows move; Up from the top row reaches the tabs; X goes back.

const COLS := 5
const CARD := Vector2(58, 50)
const GAP := 4
const GRID_TOP := 38.0
const GRID_H := 104.0

var tab := 0
var tabs: Array = ["all"]
var list: Array = []
var sel := 0
var on_tabs := false
var scroll := 0.0
var scroll_to := 0.0
var t := 0.0
var grid: Control
var cards: Array = []
var tab_labels: Array = []
var d_name: Label
var d_desc: Label
var d_info: Label
var d_icon: TextureRect
var bar_fill: ColorRect
var count_l: Label
var fx: Fx


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	tabs.append_array(Achievements.CATS)
	var bg := TextureRect.new()
	bg.texture = Art.space(320, 180, "tempestris_planet")
	bg.modulate = Color(0.7, 0.7, 0.8)
	add_child(bg)
	var tb := Art.make_box("bar_box")
	tb.position = Vector2(6, 4)
	tb.size = Vector2(100, 16)
	add_child(tb)
	var tl := Art.label("ACHIEVEMENTS", Pal.LEMON)
	tl.position = Vector2(5, 3)
	tb.add_child(tl)
	var pb := Art.make_box("bar_box")
	pb.position = Vector2(110, 4)
	pb.size = Vector2(204, 16)
	add_child(pb)
	count_l = Art.label("", Pal.TEXT)
	count_l.position = Vector2(5, 3)
	pb.add_child(count_l)
	var back := ColorRect.new()
	back.color = Pal.INK
	back.position = Vector2(56, 5)
	back.size = Vector2(142, 6)
	pb.add_child(back)
	bar_fill = ColorRect.new()
	bar_fill.color = Pal.LEMON
	bar_fill.position = Vector2(57, 6)
	bar_fill.size = Vector2(0, 4)
	pb.add_child(bar_fill)
	var x := 8.0
	for k in tabs:
		var nm: String = "ALL" if k == "all" else Achievements.CAT_NAMES[k]
		var l := Art.label(nm, Pal.TEXT_DIM)
		l.position = Vector2(x, 24)
		add_child(l)
		tab_labels.append(l)
		x += Art.text_width(nm) + 14
	grid = Control.new()
	grid.position = Vector2(0, GRID_TOP)
	grid.size = Vector2(320, GRID_H)
	grid.clip_contents = true
	add_child(grid)
	var db := Art.make_box("box")
	db.position = Vector2(6, 144)
	db.size = Vector2(308, 33)
	add_child(db)
	d_icon = TextureRect.new()
	d_icon.position = Vector2(4, 4)
	db.add_child(d_icon)
	d_name = Art.label("", Pal.LEMON)
	d_name.position = Vector2(32, 2)
	db.add_child(d_name)
	d_desc = Art.label("", Pal.TEXT)
	d_desc.position = Vector2(32, 12)
	db.add_child(d_desc)
	d_info = Art.label("", Pal.SYNC)
	d_info.position = Vector2(32, 21)
	db.add_child(d_info)
	fx = Fx.new()
	add_child(fx)
	_fill()


func _fill() -> void:
	for c in cards:
		c.queue_free()
	cards.clear()
	list = []
	for a in Achievements.defs():
		if tabs[tab] == "all" or a.cat == tabs[tab]:
			list.append(a)
	# unlocked first within each category, keeping the authored order otherwise
	var got := list.filter(func(a): return Game.has_achievement(a.id))
	var not_yet := list.filter(func(a): return not Game.has_achievement(a.id))
	list = got + not_yet
	for i in list.size():
		var card := AchievementCard.new()
		card.setup(list[i], false)
		card.position = _slot(i)
		grid.add_child(card)
		cards.append(card)
		# cards deal in, staggered
		card.modulate.a = 0.0
		card.create_tween().tween_property(card, "modulate:a", 1.0, 0.18).set_delay(0.02 * mini(i, 15))
	sel = clampi(sel, 0, maxi(0, list.size() - 1))
	scroll = 0.0
	scroll_to = 0.0
	var total := Achievements.defs().size()
	var have := Game.achieved.size()
	count_l.text = "%d / %d" % [have, total]
	bar_fill.size.x = 140.0 * have / maxf(1.0, total)
	_describe()


func _slot(i: int) -> Vector2:
	var row := i / COLS
	var col := i % COLS
	return Vector2(8 + col * (CARD.x + GAP), 2 + row * (CARD.y + GAP))


func _describe() -> void:
	if list.is_empty():
		return
	var a: Dictionary = list[sel]
	var have := Game.has_achievement(a.id)
	d_icon.texture = Art.achievement(a, have)
	d_name.text = a.name
	d_name.add_theme_color_override("font_color", Pal.LEMON if have else Pal.TEXT_DIM)
	d_desc.text = a.desc
	var info := ""
	if have:
		var dt := Time.get_datetime_dict_from_unix_time(int(Game.achieved[a.id]))
		info = "Unlocked %04d-%02d-%02d" % [dt.year, dt.month, dt.day]
	else:
		var pr := Achievements.progress(a)
		info = "Progress %d / %d" % [pr[0], pr[1]] if not pr.is_empty() else "Locked"
	d_info.text = info


func _process(delta: float) -> void:
	t += delta
	scroll = lerpf(scroll, scroll_to, minf(1.0, delta * 12.0))
	for i in cards.size():
		var c: AchievementCard = cards[i]
		var target := _slot(i) - Vector2(0, scroll)
		var chosen := i == sel and not on_tabs
		c.selected = chosen
		c.position = target + Vector2(0, -2.0 if chosen else 0.0) + Vector2(0, sin(t * 4.0) * 0.6 if chosen else 0.0)
	for k in tab_labels.size():
		var l: Label = tab_labels[k]
		var cur := k == tab
		l.add_theme_color_override("font_color", (Pal.LEMON if on_tabs else Pal.TEXT) if cur else Pal.TEXT_DIM)
		l.position.y = 24 - (1 if cur and on_tabs and fmod(t, 0.6) < 0.3 else 0)


func run() -> void:
	await get_tree().process_frame
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("cancel"):
			Sfx.play("cancel")
			return
		if on_tabs:
			var old_tab := tab
			if Input.is_action_just_pressed("right"):
				tab = (tab + 1) % tabs.size()
			elif Input.is_action_just_pressed("left"):
				tab = (tab - 1 + tabs.size()) % tabs.size()
			elif Input.is_action_just_pressed("down") or Input.is_action_just_pressed("accept"):
				on_tabs = false
				Sfx.play("blip")
				_describe()
			if old_tab != tab:
				Sfx.play("blip", 1.2)
				sel = 0
				_fill()
			continue
		var old := sel
		if Input.is_action_just_pressed("right"):
			sel = mini(sel + 1, list.size() - 1)
		elif Input.is_action_just_pressed("left"):
			sel = maxi(sel - 1, 0)
		elif Input.is_action_just_pressed("down"):
			sel = mini(sel + COLS, list.size() - 1)
		elif Input.is_action_just_pressed("up"):
			if sel < COLS:
				on_tabs = true
				Sfx.play("blip", 1.2)
				continue
			sel -= COLS
		elif Input.is_action_just_pressed("accept") and not list.is_empty():
			var c: AchievementCard = cards[sel]
			c.pop()
			if Game.has_achievement(list[sel].id):
				Sfx.play("chime", 1.2, -6.0)
				fx.burst(c.global_position + CARD / 2.0, 14, [Pal.LEMON, Pal.WHITE, Pal.HONEY], Vector2(20, 70), Vector2(0.2, 0.5), {"up": 20.0})
			else:
				Sfx.play("miss")
		if old != sel:
			Sfx.play("blip")
			_describe()
			# keep the selected row on screen
			var row_y := (sel / COLS) * (CARD.y + GAP)
			if row_y - scroll_to < 0:
				scroll_to = row_y
			elif row_y + CARD.y - scroll_to > GRID_H - 4:
				scroll_to = row_y + CARD.y - GRID_H + 4


class AchievementCard extends Control:
	## One trophy card: framed emblem and title. Unlocked cards are gilded and
	## catch a moving glint when selected; locked ones show a lock and a
	## progress sliver if they count toward something.
	var a: Dictionary
	var have := false
	var selected := false
	var t := 0.0
	var frame: NinePatchRect
	var name_l: Label

	func setup(p_a: Dictionary, _toast: bool) -> void:
		a = p_a
		have = Game.has_achievement(a.id)
		size = AchievementsScreen.CARD
		pivot_offset = size / 2.0
		frame = Art.make_box("gold_box" if have else "box")
		frame.size = size
		frame.modulate = Color.WHITE if have else Color(0.75, 0.75, 0.82)
		add_child(frame)
		var ic := TextureRect.new()
		ic.texture = Art.achievement(a, have)
		ic.position = Vector2(17, 4)
		add_child(ic)
		name_l = Label.new()
		name_l.text = _wrap(a.name, size.x - 6)
		name_l.position = Vector2(3, 28)
		name_l.size = Vector2(size.x - 6, 20)
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_l.clip_text = true
		name_l.add_theme_color_override("font_color", Pal.LEMON if have else Pal.TEXT_DIM)
		name_l.add_theme_constant_override("line_spacing", -2)
		add_child(name_l)
		if not have:
			var lock := TextureRect.new()
			lock.texture = Art.ui("lock")
			lock.position = Vector2(size.x - 12, 3)
			add_child(lock)

	static func _wrap(text: String, width: float) -> String:
		## Two lines at most, broken between words to fit the card.
		var lines := [""]
		for w in text.split(" "):
			var cur: String = lines[-1]
			var trial := w if cur == "" else cur + " " + w
			if Art.text_width(trial) <= width or cur == "":
				lines[-1] = trial
			elif lines.size() < 2:
				lines.append(w)
			else:
				lines[-1] = cur + "..."
				break
		return "\n".join(lines)

	func pop() -> void:
		scale = Vector2(1.15, 1.15)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		if selected:
			# a bright cursor frame
			var c := Pal.LEMON if have else Pal.SYNC
			draw_rect(Rect2(Vector2(-1, -1), size + Vector2(2, 2)), Color(c, 0.9), false, 1.0)
		if have and selected:
			# glint sweeping across the card
			var gx := fmod(t * 70.0, size.x + 40.0) - 20.0
			for k in 4:
				draw_line(Vector2(gx + k, 2), Vector2(gx + k - 10, size.y - 2), Color(1, 1, 1, 0.18 - k * 0.04), 1.0)
		if not have:
			var pr := Achievements.progress(a)
			if not pr.is_empty() and pr[0] > 0:
				draw_rect(Rect2(4, size.y - 4, size.x - 8, 1), Pal.INK2)
				draw_rect(Rect2(4, size.y - 4, (size.x - 8) * pr[0] / float(pr[1]), 1), Pal.SYNC)
