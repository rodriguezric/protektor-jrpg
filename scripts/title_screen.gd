class_name TitleScreen
extends Control
## Title: Terra Virex turning under its shield, letters that drop into place.

var t := 0.0
var planet: TextureRect
var drawer: Node2D
var letters: Array = []
var press: Label
var menu: Menu


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = Art.space(320, 180, "green_planet")
	add_child(bg)
	drawer = Node2D.new()
	drawer.draw.connect(_draw_fx)
	add_child(drawer)
	planet = TextureRect.new()
	planet.position = Vector2(196, 44)
	add_child(planet)
	var word := "PROTEKTOR"
	var x := 18.0
	for i in word.length():
		var l := Art.shadow_label(word[i], Pal.SYNC.lerp(Pal.WHITE, 0.2), 3)
		l.position = Vector2(x, 30)
		l.modulate.a = 0.0
		add_child(l)
		letters.append(l)
		x += Art.text_width(word[i], 3) + 3
	var sub := Art.shadow_label("CHILDREN OF THE VOID", Pal.CREAM)
	sub.position = Vector2(22, 66)
	sub.modulate.a = 0.0
	sub.name = "sub"
	add_child(sub)
	var v := Art.label("v" + str(ProjectSettings.get_setting("application/config/version", "0.0.0")), Pal.TEXT_DIM)
	v.position = Vector2(22, 168)
	add_child(v)


func _process(delta: float) -> void:
	t += delta
	planet.texture = Art.planet("green_planet", 84, int(t * 3.0))
	drawer.queue_redraw()


func _draw_fx() -> void:
	var c := Vector2(planet.position.x + 44, planet.position.y + 44)
	# twinkling foreground stars
	for i in 40:
		var p := Vector2(Pal.hash2(i, 7) * 320, Pal.hash2(i, 9) * 180).round()
		var a := 0.5 + 0.5 * sin(t * (1.0 + Pal.hash2(i, 3) * 3.0) + i)
		drawer.draw_rect(Rect2(p, Vector2.ONE), Color(Pal.WHITE, a * 0.8))
	# the shield: eight plates orbiting, locking in, pulsing
	var lock := clampf((t - 1.2) / 1.2, 0.0, 1.0)
	for k in 8:
		var a := k * TAU / 8.0 + t * 0.35
		var r := lerpf(90.0, 50.0, ease(lock, 0.4))
		for s in 7:
			var aa := a - 0.18 + s * 0.06
			var p := c + Vector2(cos(aa), sin(aa) * 0.38) * r
			var front := sin(aa) > 0.0
			drawer.draw_rect(Rect2(p.round(), Vector2(2 if front else 1, 1)), Color(Pal.SYNC, 0.9 if front else 0.35))
	if lock >= 1.0 and fmod(t, 3.0) < 0.5:
		var rr := 50.0 + fmod(t, 3.0) * 40.0
		for s in 48:
			var aa := s * TAU / 48.0
			drawer.draw_rect(Rect2((c + Vector2(cos(aa), sin(aa) * 0.38) * rr).round(), Vector2.ONE), Color(Pal.SYNC, 0.5 - fmod(t, 3.0)))


func run() -> String:
	# The title surfaces slowly, letter by letter, over a low hum.
	Sfx.play("hum", 1.0, -4.0)
	for i in letters.size():
		var l: Label = letters[i]
		var tw := create_tween()
		tw.tween_interval(0.2 * i)
		tw.tween_property(l, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await get_tree().create_timer(0.2 * letters.size() + 0.6).timeout
	var sub: Label = get_node("sub")
	create_tween().tween_property(sub, "modulate:a", 1.0, 0.6)
	var opts := []
	var has := Game.has_save()
	opts.append({"text": "Continue", "enabled": has})
	opts.append("New Game")
	opts.append({"text": "Load Game", "enabled": Game.has_any_save()})
	opts.append("Free Missions")
	opts.append("Achievements")
	opts.append("Quit")
	menu = Menu.make(self, opts, Vector2(22, 186), Vector2(84, opts.size() * 10 + 7))
	menu.cancellable = false
	menu.index = 0 if has else 1
	menu.set_entries(opts)
	var mt := create_tween()
	mt.tween_property(menu, "position:y", 84.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await mt.finished
	var keys := Art.label("Arrows move  Z ok  X back  Shift run", Pal.TEXT_DIM)
	keys.position = Vector2(22, 156)
	add_child(keys)
	while true:
		var r := await menu.ask()
		match r:
			0:
				return "continue"
			1:
				return "new"
			2:
				return "load"
			3:
				return "arcade"
			4:
				return "achievements"
			5:
				get_tree().quit()
	return "new"
