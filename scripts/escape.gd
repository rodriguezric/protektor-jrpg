class_name Escape
extends Control
## Escape Mode (GDD 3.4): steer the supply shuttle through the debris field
## beyond the Academy. Cinematic, not punishing: hits shake you, never stop you.

const DURATION := 26.0

var t := 0.0
var ship: Sprite2D
var pos := Vector2(70, 90)
var rocks: Array = []
var spawn_t := 0.5
var fx: Fx
var bg1: TextureRect
var bg2: TextureRect
var stars: Node2D
var hull := 1.0
var hull_bar: ColorRect
var inv := 0.0
var lights: Node2D
var done := false


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	bg1 = TextureRect.new()
	bg1.texture = Art.space(320, 180, "tempestris_planet")
	add_child(bg1)
	bg2 = TextureRect.new()
	bg2.texture = bg1.texture
	bg2.position.x = 320
	add_child(bg2)
	stars = Node2D.new()
	stars.draw.connect(_draw_stars)
	add_child(stars)
	lights = Node2D.new()
	lights.draw.connect(_draw_lights)
	add_child(lights)
	ship = Sprite2D.new()
	ship.texture = Art.prop("shuttle", 0)
	ship.scale = Vector2(0.5, 0.5)
	add_child(ship)
	fx = Fx.new()
	add_child(fx)
	var hb := Art.make_box("bar_box")
	hb.position = Vector2(6, 6)
	hb.size = Vector2(86, 16)
	add_child(hb)
	var hl := Art.label("HULL", Pal.TEXT_DIM)
	hl.position = Vector2(5, 3)
	hb.add_child(hl)
	var bb := ColorRect.new()
	bb.color = Pal.INK
	bb.position = Vector2(30, 5)
	bb.size = Vector2(50, 6)
	hb.add_child(bb)
	hull_bar = ColorRect.new()
	hull_bar.color = Pal.GLOW
	hull_bar.position = Vector2(31, 6)
	hull_bar.size = Vector2(48, 4)
	hb.add_child(hull_bar)


func run() -> void:
	Sfx.music("tempestris", 1.0)
	Sfx.play("thrust", 1.0, -4.0)
	var banner := Art.shadow_label("ESCAPE", Pal.SYNC, 2)
	banner.position = Vector2(160 - Art.text_width("ESCAPE", 2) / 2.0, 70)
	add_child(banner)
	var help := Art.shadow_label("Arrows steer. Don't stop.", Pal.TEXT)
	help.position = Vector2(160 - Art.text_width(help.text) / 2.0, 92)
	add_child(help)
	var tw := create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(banner, "modulate:a", 0.0, 0.5)
	tw.parallel().tween_property(help, "modulate:a", 0.0, 0.5)
	while t < DURATION:
		await get_tree().process_frame
	done = true
	var clear := Art.shadow_label("You're clear.", Pal.TEXT, 2)
	clear.position = Vector2(160 - Art.text_width(clear.text, 2) / 2.0, 76)
	add_child(clear)
	Sfx.play("chime", 0.8, -4.0)
	create_tween().tween_property(ship, "position:x", 360.0, 2.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(2.4).timeout


func _process(delta: float) -> void:
	t += delta
	bg1.position.x = -fmod(t * 20.0, 320.0)
	bg2.position.x = bg1.position.x + 320
	stars.queue_redraw()
	lights.queue_redraw()
	if done:
		return
	var v := Input.get_vector("left", "right", "up", "down")
	pos += v * 95.0 * delta
	pos = pos.clamp(Vector2(30, 20), Vector2(290, 168))
	inv = maxf(0.0, inv - delta)
	ship.position = pos.round()
	ship.rotation = v.y * 0.12
	ship.modulate.a = 0.4 if inv > 0.0 and int(inv * 20) % 2 == 0 else 1.0
	fx.particle(pos + Vector2(-26, 2), Vector2(-60, randf_range(-8, 8)), 0.35, Pal.SYNC, {"size": 2.0, "size_end": 0.5, "color2": Color(Pal.EMBER, 0.0)})
	spawn_t -= delta
	var rate := lerpf(0.75, 0.28, clampf(t / DURATION, 0.0, 1.0))
	if spawn_t <= 0.0 and t < DURATION - 2.0:
		spawn_t = rate
		var d := randi_range(9, 18)
		var r := Sprite2D.new()
		r.texture = Art.asteroid(d, randi() % 5, 0) if randf() < 0.75 else Art.prop("crate")
		r.position = Vector2(340, randf_range(16, 170))
		r.set_meta("v", Vector2(-randf_range(90, 170), randf_range(-12, 12)))
		r.set_meta("spin", randf_range(-3, 3))
		r.set_meta("r", d * 0.45)
		add_child(r)
		rocks.append(r)
	for r in rocks.duplicate():
		r.position += r.get_meta("v") * delta
		r.rotation += r.get_meta("spin") * delta
		if r.position.x < -30:
			rocks.erase(r)
			r.queue_free()
			continue
		if inv <= 0.0 and r.position.distance_to(pos) < r.get_meta("r") + 9.0:
			inv = 1.0
			hull = maxf(0.15, hull - 0.12)
			hull_bar.size.x = 48.0 * hull
			hull_bar.color = Pal.GLOW if hull > 0.5 else Pal.BLOOD
			Sfx.play("hurt", 1.2, -6.0)
			Game.main.shake(3.0, 0.3)
			fx.burst(r.position, 16, [Pal.EMBER, Pal.WHITE, Pal.STONE], Vector2(30, 90), Vector2(0.2, 0.5))
			rocks.erase(r)
			r.queue_free()


func _draw_stars() -> void:
	for i in 50:
		var x := fmod(Pal.hash2(i, 1) * 320.0 - t * (40.0 + Pal.hash2(i, 2) * 120.0), 320.0)
		if x < 0:
			x += 320.0
		var y := Pal.hash2(i, 3) * 180.0
		var len := 2.0 + Pal.hash2(i, 2) * 6.0
		stars.draw_line(Vector2(x, y).round(), Vector2(x + len, y).round(), Color(Pal.WHITE, 0.6), 1.0)


func _draw_lights() -> void:
	# Helion pursuit: two red searchlights that fall away behind you.
	var k := clampf(1.0 - t / 9.0, 0.0, 1.0)
	if k <= 0.0:
		return
	for i in 2:
		var lp := Vector2(-10 + k * 30.0, 50 + i * 80 + sin(t * 2.0 + i) * 20)
		var tip := pos + Vector2(0, sin(t * 3.0 + i) * 30)
		for s in 10:
			var q := lp.lerp(tip, s / 10.0)
			lights.draw_circle(q, 1.0 + s * 0.8, Color(Pal.BLOOD, 0.08 * k))
		lights.draw_circle(lp, 3.0, Color(Pal.BLOOD, k))
