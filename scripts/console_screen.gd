class_name ConsoleScreen
extends Control
## The Starbox: the protagonist's home game console (a Helion Toys licensed
## product, naturally). A CRT set fills the screen; its picture is a 144x80
## SubViewport shown at 2x under scanlines, so the games inside look like a
## cheaper machine than the one you're holding.
##
## Flow: power-on line, boot logo and jingle, then the cartridge shelf.
## Pick a game, play it, game over shows the high scores (top 5 per game,
## kept in the profile so they outlive playthroughs). P / Esc / MENU pauses
## a game; X on the shelf powers off.
##
## Touch: the console sets Game.touch_layout = "console" (stick + A/B while a
## game runs, the shelf is tapped directly) and Game.touch_running while live.

const SW := 144
const SH := 80
const SCREEN := Rect2(16, 10, SW * 2, SH * 2)
const SCORES_KEPT := 5

## The cartridges, shelf order. A script that doesn't exist yet shows as an
## empty slot ("NO CARTRIDGE").
const GAMES := [
	{"id": "protektor", "name": "PROTEKTOR", "sub": "Defend the planet!", "script": "res://scripts/cg_protektor.gd", "color": Color("5fd3e0")},
	{"id": "duel", "name": "DUEL STRIDERS", "sub": "Grid duel champion", "script": "res://scripts/cg_duel.gd", "color": Color("f0b048")},
	{"id": "sword", "name": "SWORD STORY", "sub": "A hero's blade", "script": "res://scripts/cg_sword.gd", "color": Color("8ad16a")},
]

const CRT_SHADER := """
shader_type canvas_item;
uniform float time = 0.0;
uniform float power = 1.0;
void fragment() {
	vec2 px = UV * vec2(144.0, 80.0) * 2.0;
	vec3 c = texture(TEXTURE, UV).rgb;
	// each console pixel is two rows tall: the lower row is the dark gap
	c *= mod(floor(px.y), 2.0) < 1.0 ? 1.0 : 0.62;
	// a soft roll bar and a whisper of flicker
	float roll = fract(time * 0.12);
	c *= 1.0 + 0.05 * step(abs(UV.y - roll), 0.04);
	c *= 0.97 + 0.03 * step(0.5, fract(time * 30.0));
	// darker toward the curved edges of the tube
	vec2 d = abs(UV - 0.5) * 2.0;
	c *= 1.0 - 0.35 * pow(max(d.x, d.y), 6.0);
	COLOR = vec4(c * power, 1.0);
}
"""

var vp: SubViewport
var picture: TextureRect
var screen_root: Node2D
var shelf: Node2D
var game: ConsoleGame
var game_def: Dictionary = {}
var sel := 0
var state := "boot"
var _t := 0.0
var _labels: Array = []
var _tap_sel := -1
var _was_layout := ""


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var room := ColorRect.new()
	room.color = Color("100c16")
	room.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(room)
	var set_ := TextureRect.new()
	set_.texture = ImageTexture.create_from_image(_tv_set().img)
	set_.position = Vector2(4, 2)
	add_child(set_)
	vp = SubViewport.new()
	vp.size = Vector2i(SW, SH)
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var bg := ColorRect.new()
	bg.color = Color("0b0a12")
	bg.size = Vector2(SW, SH)
	vp.add_child(bg)
	screen_root = Node2D.new()
	vp.add_child(screen_root)
	picture = TextureRect.new()
	picture.texture = vp.get_texture()
	picture.position = SCREEN.position
	picture.size = SCREEN.size
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sh := Shader.new()
	sh.code = CRT_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	picture.material = mat
	add_child(picture)


func _tv_set() -> PixBuf:
	## The CRT cabinet around the picture: a chunky plastic bezel, a speaker
	## grille, the brand plate and a power light.
	var b := PixBuf.new(312, 176)
	var shell_c := Color("2a2633")
	b.rect(0, 2, 312, 172, Pal.INK)
	b.rect(2, 0, 308, 176, Pal.INK)
	b.rect(2, 2, 308, 172, shell_c)
	b.rect(4, 4, 304, 2, shell_c.lerp(Pal.WHITE, 0.12))
	b.rect(10, 6, 292, 166, Color("17141e"))
	b.rect(11, 7, 290, 164, Pal.INK)
	# bezel bottom lip with the brand and the light
	b.rect(120, 171, 72, 3, shell_c.lerp(Pal.WHITE, 0.06))
	return b


# ---------------------------------------------------------------- flow ---

func run() -> void:
	_was_layout = Game.touch_layout
	Game.touch_layout = "console"
	add_to_group("tap_targets")
	await _boot()
	while true:
		state = "shelf"
		_show_shelf()
		var pick := await _shelf_pick()
		if pick < 0:
			break
		var def: Dictionary = GAMES[pick]
		if not ResourceLoader.exists(def.script):
			await _no_cartridge()
			continue
		while true:
			var sc := await _play(def)
			var again := await _game_over(def, sc)
			if not again:
				break
	await _power_off()
	remove_from_group("tap_targets")
	Game.touch_layout = _was_layout
	Game.touch_running = false


func _process(delta: float) -> void:
	_t += delta
	picture.material.set_shader_parameter("time", _t)


func _clear() -> void:
	for c in screen_root.get_children():
		c.queue_free()
	_labels.clear()


func _text(s: String, pos: Vector2, col: Color = Pal.WHITE) -> Label:
	var l := Art.label(s, col)
	l.position = pos
	screen_root.add_child(l)
	return l


func _centered(s: String, y: float, col: Color = Pal.WHITE) -> Label:
	return _text(s, Vector2(floorf(SW / 2.0 - Art.text_width(s) / 2.0), y), col)


func _boot() -> void:
	## The tube warms up from a bright line, the logo drops in to a jingle.
	state = "boot"
	_clear()
	picture.pivot_offset = SCREEN.size / 2.0
	picture.scale = Vector2(1.0, 0.02)
	picture.modulate = Color(3, 3, 3)
	Sfx.play("static", 1.6, -18.0)
	var tw := create_tween()
	tw.tween_property(picture, "scale", Vector2(1, 1), 0.28).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(picture, "modulate", Color.WHITE, 0.5)
	await tw.finished
	var logo := _centered("STARBOX", -12, Color("ffd36b"))
	logo.add_theme_font_size_override("font_size", PixFont.SIZE * 2)
	logo.position.x = floorf(SW / 2.0 - Art.text_width("STARBOX", 2) / 2.0)
	var lt := create_tween()
	lt.tween_property(logo, "position:y", 20.0, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await lt.finished
	for i in 4:
		Sfx.play("blip", [1.0, 1.26, 1.5, 2.0][i], -8.0)
		await get_tree().create_timer(0.09).timeout
	_centered("Helion Toys (c)", 44, Pal.TEXT_DIM)
	_centered("Licensed Protektor product", 54, Pal.TEXT_DIM)
	await _wait_or_skip(1.4)


func _wait_or_skip(sec: float) -> void:
	var t := 0.0
	while t < sec:
		await get_tree().process_frame
		t += get_process_delta_time()
		if Input.is_action_just_pressed("accept"):
			return


func _power_off() -> void:
	_clear()
	Sfx.play("shutdown", 1.8, -14.0)
	var tw := create_tween()
	tw.tween_property(picture, "scale", Vector2(1, 0.02), 0.16).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(picture, "modulate", Color(3, 3, 3), 0.16)
	tw.tween_property(picture, "scale", Vector2(0.0, 0.02), 0.12)
	await tw.finished
	await get_tree().create_timer(0.25).timeout


# --------------------------------------------------------------- shelf ---

func _show_shelf() -> void:
	_clear()
	_centered("- SELECT GAME -", 1, Color("ffd36b"))
	for i in GAMES.size():
		var g: Dictionary = GAMES[i]
		var y := 13 + i * 19
		var cart := ColorRect.new()
		cart.position = Vector2(6, y + 1)
		cart.size = Vector2(9, 12)
		cart.color = g.color
		screen_root.add_child(cart)
		var lab := ColorRect.new()
		lab.position = Vector2(7, y + 3)
		lab.size = Vector2(7, 5)
		lab.color = Color(g.color).lerp(Pal.WHITE, 0.6)
		screen_root.add_child(lab)
		var have := ResourceLoader.exists(g.script)
		var name_l := _text(g.name if have else "NO CARTRIDGE", Vector2(20, y), Pal.WHITE if have else Pal.TEXT_DIM)
		var best := best_score(g.id)
		var sub_l := _text(("HI %06d" % best) if have else "- empty slot -", Vector2(20, y + 8), Pal.TEXT_DIM)
		_labels.append([name_l, sub_l, cart])
	_centered("Z play   X power off" if not Game.touch_active else "Tap a game, tap again to play", 70, Pal.TEXT_DIM)
	_mark_sel()


func _mark_sel() -> void:
	for i in _labels.size():
		var on := i == sel
		var l: Label = _labels[i][0]
		var c: Color = GAMES[i].color
		l.add_theme_color_override("font_color", c.lerp(Pal.WHITE, 0.3) if on else (Pal.WHITE if ResourceLoader.exists(GAMES[i].script) else Pal.TEXT_DIM))
		l.text = ("> " if on else "") + (GAMES[i].name if ResourceLoader.exists(GAMES[i].script) else "NO CARTRIDGE")
		_labels[i][2].position.x = 6 + (2 if on else 0)


func _shelf_pick() -> int:
	_tap_sel = -1
	await get_tree().process_frame
	while true:
		await get_tree().process_frame
		if not is_inside_tree():
			return -1
		var moved := 0
		if Input.is_action_just_pressed("down"):
			moved = 1
		elif Input.is_action_just_pressed("up"):
			moved = -1
		if moved != 0:
			sel = (sel + moved + GAMES.size()) % GAMES.size()
			Sfx.play("blip", 1.1, -10.0)
			_mark_sel()
		if _tap_sel >= 0 or Input.is_action_just_pressed("accept"):
			_tap_sel = -1
			Sfx.play("confirm")
			return sel
		if Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("pause"):
			Sfx.play("cancel")
			return -1
	return -1


func tap(game_pos: Vector2) -> bool:
	## Touch: tap a cartridge to select it, tap it again to play. Taps on the
	## game-over screen mean "again"; during play the console takes none.
	if state == "playing" or not SCREEN.has_point(game_pos):
		return false
	var p := (game_pos - SCREEN.position) / 2.0
	if state == "shelf":
		for i in GAMES.size():
			var y := 13 + i * 19
			if p.y >= y - 2 and p.y < y + 17:
				if i == sel:
					_tap_sel = i
				else:
					sel = i
					Sfx.play("blip", 1.1, -10.0)
					_mark_sel()
				return true
		return false
	if state == "over":
		_tap_sel = 1
		return true
	return false


func _no_cartridge() -> void:
	_clear()
	var l := _centered("INSERT CARTRIDGE", 34, Pal.TEXT_DIM)
	for i in 6:
		l.visible = i % 2 == 0
		await get_tree().create_timer(0.25).timeout


# ---------------------------------------------------------------- play ---

func _play(def: Dictionary) -> int:
	state = "playing"
	_clear()
	game_def = def
	game = load(def.script).new()
	screen_root.add_child(game)
	# while a game runs the console takes no taps: the stick and A/B do it all
	remove_from_group("tap_targets")
	Game.touch_running = true
	var res := {"score": 0, "done": false}
	game.over.connect(func(s: int) -> void:
		res.score = s
		res.done = true)
	while not res.done:
		await get_tree().process_frame
		if not is_inside_tree():
			return 0
		if Input.is_action_just_pressed("pause") and not game.paused:
			await _pause()
			if game.done:
				break
	Game.touch_running = false
	add_to_group("tap_targets")
	if not res.done:
		res.score = game.score
	Achievements.console_result(def.id, int(res.score), game.stats)
	await get_tree().create_timer(0.6).timeout
	return int(res.score)


func _pause() -> void:
	game.paused = true
	Game.touch_running = false
	Sfx.play("confirm")
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.size = Vector2(SW, SH)
	dim.z_index = 20
	screen_root.add_child(dim)
	var l := Art.label("PAUSED", Color("ffd36b"))
	l.position = Vector2(floorf(SW / 2.0 - Art.text_width("PAUSED") / 2.0), 26)
	dim.add_child(l)
	var h := Art.label("Z resume  X quit", Pal.TEXT_DIM)
	h.position = Vector2(floorf(SW / 2.0 - Art.text_width("Z resume  X quit") / 2.0), 42)
	dim.add_child(h)
	await get_tree().process_frame
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("accept") or Input.is_action_just_pressed("pause"):
			break
		if Input.is_action_just_pressed("cancel"):
			game.end()
			break
	dim.queue_free()
	game.paused = false
	Game.touch_running = not game.done


func _game_over(def: Dictionary, sc: int) -> bool:
	## Records the score, shows the table (the new entry flashing), and asks
	## for another go.
	var rank := record_score(def.id, sc)
	state = "over"
	_clear()
	_centered("GAME OVER", 1, Color("ff7a6b"))
	_centered("SCORE %06d" % sc, 10, Pal.WHITE)
	var rows := scores(def.id)
	var flash: Label = null
	for i in SCORES_KEPT:
		var y := 22 + i * 8
		var txt := "%d. ---     ------" % (i + 1)
		if i < rows.size():
			txt = "%d. %-6s %06d" % [i + 1, str(rows[i][0]), int(rows[i][1])]
		var l := _text(txt, Vector2(28, y), Color(def.color) if i == rank else Pal.TEXT)
		if i == rank:
			flash = l
	if rank >= 0:
		Sfx.play("chime", 1.2, -6.0)
		_centered("NEW HIGH SCORE!", 63, Color("ffd36b"))
	_centered("Z again   X shelf" if not Game.touch_active else "Tap: again   B: shelf", 72, Pal.TEXT_DIM)
	_tap_sel = -1
	var t := 0.0
	while true:
		await get_tree().process_frame
		if not is_inside_tree():
			return false
		t += get_process_delta_time()
		if flash:
			flash.visible = fmod(t, 0.5) < 0.35
		if t < 0.4:
			continue
		if _tap_sel >= 0 or Input.is_action_just_pressed("accept"):
			Sfx.play("confirm")
			return true
		if Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("pause"):
			Sfx.play("cancel")
			return false
	return false


# -------------------------------------------------------------- scores ---

static func player_tag() -> String:
	var n := Game.player_name.strip_edges().to_upper()
	return n.substr(0, 6) if n != "" else "YOU"


static func scores(id: String) -> Array:
	var all: Dictionary = Game.profile.get("console_scores", {})
	return all.get(id, [])


static func best_score(id: String) -> int:
	var s := scores(id)
	return int(s[0][1]) if not s.is_empty() else 0


static func record_score(id: String, sc: int) -> int:
	## Inserts the score into the top table; returns its rank or -1.
	if sc <= 0:
		return -1
	if not Game.profile.has("console_scores"):
		Game.profile.console_scores = {}
	var rows: Array = Game.profile.console_scores.get(id, [])
	var rank := rows.size()
	for i in rows.size():
		if sc > int(rows[i][1]):
			rank = i
			break
	if rank >= SCORES_KEPT:
		return -1
	rows.insert(rank, [player_tag(), sc])
	while rows.size() > SCORES_KEPT:
		rows.pop_back()
	Game.profile.console_scores[id] = rows
	Game.save_profile()
	return rank
