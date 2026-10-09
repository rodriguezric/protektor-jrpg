class_name CompanySplash
extends Control
## The studio card shown once at launch, before the title: the company name in
## the middle of a deep ink screen. The letters surface one by one over a low
## hum (the style's title rule: fade, never drop), a sync-cyan rule draws out
## beneath them, a few stars twinkle and cyan motes drift, then it fades away.
## Skippable with confirm or cancel; skipping and finishing end the same way.

const NAME := "BAYERIAN"
const SCALE := 3
const STAGGER := 0.12
const LETTER_FADE := 0.7
const HOLD := 1.3

var t := 0.0
var letters: Array = []
var rule := 0.0
var rule_y := 0.0
var drawer: Node2D
var done := false


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = Art.cine("studio")
	add_child(bg)
	drawer = Node2D.new()
	drawer.draw.connect(_draw_fx)
	add_child(drawer)
	var gap := SCALE * 2
	var total := 0.0
	for ch in NAME:
		total += Art.text_width(ch, SCALE) + gap
	total -= gap
	var x := roundf(160.0 - total / 2.0)
	var y := roundf(90.0 - PixFont.ASCENT * SCALE / 2.0) - 2
	for ch in NAME:
		var l := Art.shadow_label(ch, Pal.TEXT.lerp(Pal.SYNC, 0.25), SCALE)
		l.position = Vector2(x, y)
		l.modulate.a = 0.0
		add_child(l)
		letters.append(l)
		x += Art.text_width(ch, SCALE) + gap
	# the rule sits a few pixels under the letters' cap height
	rule_y = y + PixFont.ASCENT * SCALE + SCALE + 4


func _process(delta: float) -> void:
	t += delta
	drawer.queue_redraw()


func _draw_fx() -> void:
	# a thin sync-cyan rule growing outward under the name
	var half := 64.0 * rule
	if half >= 1.0:
		drawer.draw_rect(Rect2(Vector2(160 - half, rule_y).round(), Vector2(half * 2, 1)), Color(Pal.SYNC, 0.85))
		drawer.draw_rect(Rect2(Vector2(160 - half * 0.5, rule_y + 1).round(), Vector2(half, 1)), Color(Pal.SYNC, 0.3))
	# distant stars twinkling, and a few cyan motes drifting up very slowly
	var k := minf(1.0, t)
	for i in 30:
		var p := Vector2(Pal.hash2(i, 7) * 320, Pal.hash2(i, 9) * 180).round()
		var a := 0.25 + 0.25 * sin(t * (1.0 + Pal.hash2(i, 3) * 2.0) + i)
		drawer.draw_rect(Rect2(p, Vector2.ONE), Color(Pal.WHITE, a * k))
	for i in 14:
		var p := Vector2(60 + Pal.hash2(i, 3) * 200, fmod(170.0 - t * (5.0 + Pal.hash2(i, 4) * 7.0) + Pal.hash2(i, 5) * 160.0, 160.0) + 10)
		var a := 0.3 + 0.3 * sin(t * 2.0 + i)
		drawer.draw_rect(Rect2(p.round(), Vector2.ONE), Color(Pal.SYNC if i % 3 else Pal.WHITE, a * k))


func run() -> void:
	## Plays the card; returns once it has faded out (or been skipped).
	Sfx.play("hum", 1.0, -6.0)
	for i in letters.size():
		var tw := create_tween()
		tw.tween_interval(0.3 + STAGGER * i)
		tw.tween_property(letters[i], "modulate:a", 1.0, LETTER_FADE).set_trans(Tween.TRANS_SINE)
	var rt := create_tween()
	rt.tween_interval(0.3 + STAGGER * letters.size())
	rt.tween_method(func(v: float) -> void: rule = v, 0.0, 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var length := 0.3 + STAGGER * letters.size() + LETTER_FADE + HOLD
	var e := 0.0
	await get_tree().process_frame
	while e < length:
		await get_tree().process_frame
		e += get_process_delta_time()
		if Input.is_action_just_pressed("accept") or Input.is_action_just_pressed("cancel"):
			break
	await _finish()


func _finish() -> void:
	## The one way out, for skipping and finishing alike.
	if done:
		return
	done = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	await tw.finished
