class_name HubGame
extends Control
## The Pilot Wing's little games, each under a minute, drawn full screen:
##   pingpong - rally against another recruit: press Z (tap) as the ball
##              reaches your paddle (the closing ring turns lemon). A swing
##              outside the window whiffs; the rally ends on your first
##              miss. Score: the rally.
##   cards    - high-low: Up if the next card is higher, Down if lower (ties
##              win). Score: the streak.
##   drill    - the gym's sync-reflex drill: ten arrows flash up; press that
##              direction as fast as you can. Score: the average reaction in
##              ms (lower is better); a wrong press costs 250 ms.
## Touch: each game declares its layout in TOUCH (TouchControls); B quits.
## Ping-pong is a tap anywhere (side bars too), high-low has big UP / DOWN
## buttons, and the drill follows the "Arrow games" setting (swipe, buttons
## or both). Game.touch_running is set only while a round is live, so the
## READY card and the result take an ordinary tap.

const TITLES := {"pingpong": "PING-PONG", "cards": "HIGH - LOW", "drill": "SYNC-REFLEX DRILL"}
const HELP := {"pingpong": "Z / tap when the ball reaches your paddle", "cards": "Up: higher   Down: lower", "drill": "Press the arrow that lights up"}
## Touch layout per game, and the touch wording of its help line.
const TOUCH := {"pingpong": "tap", "cards": "ud", "drill": "arrows"}
const TOUCH_KEYS := {"pingpong": "Tap anywhere when the ring turns gold", "cards": "UP: higher   DOWN: lower",
	"drill": ["Swipe the way the arrow points", "Tap the arrow that lights up", "Swipe or tap the arrow"]}
const SUITS := ["S", "H", "D", "C"]
const RANKS := ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

var kind := "pingpong"
var opponent := {}
var board: Node2D
var title_l: Label
var info_l: Label
var big_l: Label
var t := 0.0
var auto := false
## pingpong
var ball_x := 0.0
var ball_dir := 1
var ball_speed := 120.0
var rally := 0
var swing_t := 0.0
var foe_swing := 0.0
var verdict := ""
var verdict_t := 0.0
## cards
var card := 0
var next_card := 0
var streak := 0
var flip_t := 0.0
## drill
var prompt := ""
var prompt_t := 0.0
var times: Array = []
var penalty := 0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("161320")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	board = Node2D.new()
	board.draw.connect(_draw_board)
	add_child(board)
	title_l = Art.shadow_label("", Pal.LEMON, 2)
	title_l.position = Vector2(12, 6)
	add_child(title_l)
	info_l = Art.label("", Pal.TEXT_DIM)
	info_l.position = Vector2(12, 166)
	add_child(info_l)
	big_l = Art.shadow_label("", Pal.WHITE, 2)
	add_child(big_l)


func _big(text: String, col: Color = Pal.WHITE, y: float = -1.0) -> void:
	## The big banner (READY?, WRONG, the result). In high-low it sits in the
	## felt strip under the card so it never covers the card face.
	if y < 0.0:
		y = 132.0 if kind == "cards" else 70.0
	big_l.text = text
	big_l.add_theme_color_override("font_color", col)
	big_l.position = Vector2(floorf(160 - Art.text_width(text, 2) / 2.0), y)


func run(p_kind: String, opp: Dictionary = {}) -> Dictionary:
	## Plays one round and returns {score, best, new_best, kind}.
	kind = p_kind
	opponent = opp
	title_l.text = TITLES[kind]
	Game.touch_layout = TOUCH[kind]
	info_l.text = _help()
	_big("READY?", Pal.LEMON)
	Sfx.play("chime", 1.2, -8.0)
	await _pause(1.0)
	_big("")
	var score := 0
	Game.touch_running = true
	match kind:
		"pingpong":
			score = await _pingpong()
		"cards":
			score = await _cards()
		"drill":
			score = await _drill()
	Game.touch_running = false
	var res := record(kind, score)
	var shown := ("%d ms" % score) if kind == "drill" else str(score)
	if score <= 0 and kind == "drill":
		shown = "--"
	_big(("NEW BEST!  " if res.new_best else "") + shown, Pal.LEMON if res.new_best else Pal.WHITE)
	if res.new_best:
		Sfx.play("levelup", 1.1, -6.0)
	info_l.text = "Best: %s" % (("%d ms" % res.best) if kind == "drill" else str(res.best))
	await _pause(1.6)
	Game.touch_layout = ""
	return res


func _help() -> String:
	## The help line, in touch words while playing by touch.
	if not Game.touch_active:
		return HELP[kind] + "   X quit"
	var k = TOUCH_KEYS[kind]
	return k[int(Game.settings.get("touch_arrows", 0))] if k is Array else str(k)


func _exit_tree() -> void:
	# leaving early (B, or the screen freed) must hand the controls back
	Game.touch_running = false
	if Game.touch_layout == TOUCH.get(kind, ""):
		Game.touch_layout = ""


func _pause(sec: float) -> void:
	var left := sec
	while left > 0.0:
		await get_tree().process_frame
		if not is_inside_tree():
			return
		left -= get_process_delta_time()


func _quit_pressed() -> bool:
	return Input.is_action_just_pressed("cancel") and not auto


func _process(delta: float) -> void:
	t += delta
	board.queue_redraw()
	if big_l.text == "" and info_l.text != _help() and not info_l.text.begins_with("Best"):
		info_l.text = _help()   # touch / keys switched mid-game
	# by touch the line sits centred, clear of the corner buttons
	info_l.position.x = floorf(160 - Art.text_width(info_l.text) / 2.0) if Game.touch_active else 12.0


# -------------------------------------------------------------- scores ---

static func best(k: String) -> int:
	var all: Dictionary = Game.profile.get("hub_games", {})
	return int(all.get(k, 0))


static func record(k: String, score: int) -> Dictionary:
	## Best scores live in the profile; the drill keeps its lowest time.
	if not Game.profile.has("hub_games"):
		Game.profile.hub_games = {}
	var old := best(k)
	var better := score > 0 and (old == 0 or (score < old if k == "drill" else score > old))
	if better:
		Game.profile.hub_games[k] = score
		Game.save_profile()
	Achievements.hub_result(k, score)
	return {"kind": k, "score": score, "best": best(k), "new_best": better}


# ------------------------------------------------------------- pingpong ---
## Side view of the rec-room table, players at 2x. The ball is hit from one
## end, bounces once on the far half and rises to the receiver's paddle. A
## ring closes on the sweet spot as the ball comes in (lemon = swing now).
## The timing window is in seconds, generous early and tightening with the
## rally. Hits get hit-stop, sparks and a knock that climbs in pitch.

const PADDLE_X := 54.0
const FOE_X := 266.0
const FLOOR_Y := 152.0
const TABLE_Y := 121.0 # middle of the table top, where the ball bounces
const TABLE_L := 64.0
const TABLE_R := 256.0
const BOUNCE_K := 0.74 # the ball lands this far along its flight
const CONTACT_H := 10.0 # ball height above the table at the paddle

var ball_h := 0.0
var ball_vh := 0.0
var missed := false
var stop_t := 0.0
var shake_t := 0.0
var pop_t := 0.0
var bounced := false
var trail: Array = []
var sparks: Array = []
var mood_t := 0.0
var my_mood := ""


func _window() -> float:
	return lerpf(0.13, 0.075, minf(1.0, rally / 25.0))


func _ttc() -> float:
	## Seconds until the ball reaches your paddle (negative once past it).
	return (ball_x - PADDLE_X) / ball_speed if ball_dir < 0 else 99.0


func _flight_h(k: float) -> float:
	## Ball height over the table along one shot, k = 0 at the hitter.
	if k < BOUNCE_K:
		var u := k / BOUNCE_K
		return lerpf(CONTACT_H, 0.0, u) + sin(u * PI) * 20.0
	var v := (k - BOUNCE_K) / (1.0 - BOUNCE_K)
	return sin(v * PI * 0.5) * CONTACT_H * 1.15 - maxf(0.0, v - 1.0) * 6.0


func _flight_k() -> float:
	var span := FOE_X - PADDLE_X
	return (FOE_X - ball_x) / span if ball_dir < 0 else (ball_x - PADDLE_X) / span


func _ball_pos() -> Vector2:
	return Vector2(ball_x, TABLE_Y - ball_h)


func _spark(at: Vector2, n: int, cols: Array, dir: float) -> void:
	for i in n:
		var a := dir + randf_range(-1.1, 1.1)
		sparks.append({"p": at, "v": Vector2.from_angle(a) * randf_range(30, 90), "life": randf_range(0.15, 0.35), "c": cols[i % cols.size()]})


func _pingpong() -> int:
	ball_x = FOE_X
	ball_dir = -1
	ball_speed = 120.0
	rally = 0
	missed = false
	bounced = false
	trail.clear()
	sparks.clear()
	foe_swing = 0.22
	Sfx.play("knock", 1.1, -8.0)
	var lock := 0.0
	while true:
		await get_tree().process_frame
		if not is_inside_tree():
			return rally
		if _quit_pressed():
			return rally
		var d := get_process_delta_time()
		swing_t -= d
		foe_swing -= d
		verdict_t -= d
		shake_t -= d
		pop_t -= d
		mood_t -= d
		lock -= d
		if mood_t <= 0.0:
			my_mood = ""
		for sp in sparks.duplicate():
			sp.p += sp.v * d
			sp.v.y += 160.0 * d
			sp.life -= d
			if sp.life <= 0.0:
				sparks.erase(sp)
		board.position = Vector2(randi_range(-1, 1), randi_range(-1, 1)) if shake_t > 0.0 else Vector2.ZERO
		if stop_t > 0.0:
			stop_t -= d
			continue
		if missed:
			# past you: off the end of the table and onto the floor
			ball_x -= ball_speed * 0.6 * d
			ball_vh -= 260.0 * d
			ball_h += ball_vh * d
			if TABLE_Y - ball_h >= FLOOR_Y - 2.0 and ball_vh < 0.0:
				ball_h = TABLE_Y - FLOOR_Y + 2.0
				ball_vh = -ball_vh * 0.45
			continue
		ball_x += ball_dir * ball_speed * d
		var k := _flight_k()
		ball_h = _flight_h(k)
		if k >= BOUNCE_K and not bounced:
			bounced = true
			Sfx.play("knock", 2.0, -16.0)
			_spark(Vector2(ball_x, TABLE_Y), 3, [Pal.WHITE], -PI / 2)
		trail.push_front(_ball_pos())
		if trail.size() > 5:
			trail.pop_back()
		var ttc := _ttc()
		var win := _window()
		var press := Input.is_action_just_pressed("accept")
		if auto:
			press = ball_dir < 0 and ttc <= 0.012
		if press and lock <= 0.0:
			swing_t = 0.22
			if ball_dir < 0 and absf(ttc) <= win:
				var perfect := absf(ttc) <= win * 0.38
				ball_dir = 1
				ball_x = PADDLE_X
				bounced = false
				rally += 1
				pop_t = 0.25
				ball_speed = minf(270.0, ball_speed + (8.0 if perfect else 5.0))
				verdict = "PERFECT" if perfect else "GOOD"
				verdict_t = 0.5
				stop_t = 0.07 if perfect else 0.035
				shake_t = 0.1 if perfect else 0.0
				_spark(_ball_pos(), 8 if perfect else 4, [Pal.LEMON, Pal.WHITE] if perfect else [Pal.WHITE], 0.0)
				Sfx.play("knock", 1.25 + mini(rally, 20) * 0.02 + (0.1 if perfect else 0.0), -5.0)
				if perfect:
					my_mood = "smile"
					mood_t = 0.4
					Game.buzz(12)
				if rally % 10 == 0:
					Sfx.play("chime", 1.0 + mini(rally, 40) * 0.01, -8.0)
			else:
				verdict = "EARLY" if ttc > 0.0 and ball_dir < 0 else ("LATE" if ball_dir < 0 else "WAIT")
				verdict_t = 0.5
				lock = 0.35
				Sfx.play("whoosh", 1.4, -12.0)
		if ball_dir > 0 and ball_x >= FOE_X:
			ball_x = FOE_X
			ball_dir = -1
			bounced = false
			foe_swing = 0.22
			Sfx.play("knock", 1.1 + mini(rally, 20) * 0.015, -8.0)
		if ball_dir < 0 and ttc < -win - 0.02:
			missed = true
			ball_vh = 30.0
			verdict = "MISS"
			verdict_t = 1.2
			my_mood = "sad"
			mood_t = 2.0
			shake_t = 0.15
			Sfx.play("cancel", 0.8, -4.0)
			await _pause(1.1)
			board.position = Vector2.ZERO
			return rally
	return rally


# ---------------------------------------------------------------- cards ---

func _cards() -> int:
	streak = 0
	card = randi() % 13
	while true:
		next_card = randi() % 13
		var guess := 0
		while guess == 0:
			await get_tree().process_frame
			if not is_inside_tree():
				return streak
			if _quit_pressed():
				return streak
			if Input.is_action_just_pressed("up"):
				guess = 1
			elif Input.is_action_just_pressed("down"):
				guess = -1
			if auto:
				guess = 1 if card < 6 else -1
		Sfx.play("paper", 1.2, -6.0)
		flip_t = 0.35
		await _pause(0.4)
		var ok := next_card == card or (guess > 0 and next_card > card) or (guess < 0 and next_card < card)
		card = next_card
		if not ok:
			_big("WRONG", Pal.RED)
			Sfx.play("cancel", 0.8, -4.0)
			await _pause(0.9)
			_big("")
			return streak
		streak += 1
		Sfx.play("coin", 1.0 + mini(streak, 10) * 0.05, -8.0)
	return streak


# ---------------------------------------------------------------- drill ---

func _drill() -> int:
	times.clear()
	penalty = 0
	for i in 10:
		prompt = ""
		var wait_left := randf_range(0.5, 1.4)
		while wait_left > 0.0:
			# X / B quits between arrows too, not only while one is lit
			await get_tree().process_frame
			if not is_inside_tree() or _quit_pressed():
				return 0
			wait_left -= get_process_delta_time()
		prompt = ["up", "down", "left", "right"][randi() % 4]
		Sfx.play("beep", 1.4, -8.0)
		var start := Time.get_ticks_msec()
		while true:
			await get_tree().process_frame
			if not is_inside_tree():
				return 0
			if _quit_pressed():
				return 0
			var hit := ""
			for d in ["up", "down", "left", "right"]:
				if Input.is_action_just_pressed(d):
					hit = d
			if auto and Time.get_ticks_msec() - start > 230:
				hit = prompt
			if hit == "":
				continue
			if hit == prompt:
				times.append(Time.get_ticks_msec() - start)
				Sfx.play("blip", 1.6, -10.0)
				break
			penalty += 250
			Sfx.play("cancel", 1.2, -10.0)
	prompt = ""
	var total := 0
	for ms in times:
		total += int(ms)
	return int(float(total + penalty) / maxf(1.0, times.size()))


# ----------------------------------------------------------------- draw ---

func _draw_board() -> void:
	match kind:
		"pingpong":
			_draw_pong()
		"cards":
			_draw_cards()
		"drill":
			_draw_drill()


func _draw_pong() -> void:
	var b := board
	_draw_rec_room(b)
	# the scoreboard on the wall
	var pop := maxf(0.0, pop_t) / 0.25
	var sb := Rect2(134, 22, 52, 30)
	b.draw_rect(sb.grow(1), Pal.deep(Pal.WOOD))
	b.draw_rect(sb, Pal.INK2)
	b.draw_rect(Rect2(sb.position, Vector2(sb.size.x, 1)), Pal.hi(Pal.INK2))
	b.draw_string(Art.font, Vector2(160 - Art.text_width("RALLY") / 2.0, 30), "RALLY", HORIZONTAL_ALIGNMENT_LEFT, -1, PixFont.SIZE, Pal.TEXT_DIM)
	var rs := str(rally)
	var rcol := Pal.LEMON.lerp(Pal.WHITE, 1.0 - pop) if pop > 0.0 else Pal.SYNC
	b.draw_string(Art.font, Vector2(160 - Art.text_width(rs, 2) / 2.0, 47 - round(pop * 3.0)), rs, HORIZONTAL_ALIGNMENT_LEFT, -1, PixFont.SIZE * 2, rcol)
	_draw_table(b)
	# the players, 2x, at either end
	var you := Art.person(Game.player_spec(), 2, 1 if swing_t > 0.0 else 0, my_mood, "walk")
	var lean := 3.0 if swing_t > 0.0 else 0.0
	b.draw_texture_rect(you, Rect2(PADDLE_X - 54 + lean, FLOOR_Y - 62, 64, 64), false)
	var opp := Art.person(opponent if not opponent.is_empty() else Data.EXTRAS[0], 2, 1 if foe_swing > 0.0 else 0, "", "walk")
	var flean := 3.0 if foe_swing > 0.0 else 0.0
	b.draw_texture_rect(opp, Rect2(FOE_X - 10 - flean, FLOOR_Y - 62, -64, 64), false)
	_draw_paddle(b, Vector2(PADDLE_X - 8 + lean, 116), 1.0, swing_t, Pal.RED)
	_draw_paddle(b, Vector2(FOE_X + 8 - flean, 116), -1.0, foe_swing, Pal.BLUE)
	# the timing ring: closes on the sweet spot, lemon when it's time
	var spot := Vector2(PADDLE_X, TABLE_Y - CONTACT_H * 1.15)
	var ttc := _ttc()
	if not missed and ball_dir < 0 and ttc < 0.6:
		var now := absf(ttc) <= _window()
		var r := 3.0 + maxf(0.0, ttc) * 26.0
		b.draw_arc(spot, r, 0, TAU, 20, Color(Pal.LEMON if now else Pal.SYNC, 0.9 if now else 0.55), 1.0)
	b.draw_arc(spot, 3.0, 0, TAU, 12, Color(Pal.SYNC, 0.35), 1.0)
	# the ball: shadow, trail, ball
	var bp := _ball_pos()
	var on_table := bp.x >= TABLE_L and bp.x <= TABLE_R
	var sy := TABLE_Y if on_table and not missed else FLOOR_Y + 1.0
	var sw := clampf(4.0 - ball_h * 0.08, 2.0, 4.0)
	b.draw_rect(Rect2(floorf(bp.x - sw / 2.0), sy, sw, 1), Color(Pal.INK, 0.45))
	if ball_speed > 160.0:
		for i in trail.size():
			b.draw_rect(Rect2((trail[i] as Vector2).floor() - Vector2(1, 1), Vector2(2, 2)), Color(Pal.WHITE, 0.25 - i * 0.05))
	b.draw_circle(bp.floor() + Vector2(0.5, 0.5), 2.0, Pal.WHITE)
	b.draw_rect(Rect2(bp.floor() + Vector2(-1, -1), Vector2(1, 1)), Pal.hi(Pal.WHITE))
	for sp in sparks:
		b.draw_rect(Rect2((sp.p as Vector2).floor(), Vector2(1, 1)), sp.c)
	if verdict_t > 0.0:
		var col := Pal.LEMON if verdict == "PERFECT" else (Pal.GLOW if verdict == "GOOD" else Pal.ROSE)
		var vy := 82.0 - minf(0.12, maxf(0.0, 0.5 - verdict_t)) * 40.0
		b.draw_string(Art.font, Vector2(PADDLE_X + 6 - Art.text_width(verdict) / 2.0, vy), verdict, HORIZONTAL_ALIGNMENT_LEFT, -1, PixFont.SIZE, col)


func _draw_rec_room(b: Node2D) -> void:
	## The Pilot Wing rec room: a banded wall, wood wainscot, tiled floor
	## and a hanging lamp lighting the table.
	var wall := Pal.PLUM
	b.draw_rect(Rect2(0, 0, 320, FLOOR_Y), Pal.deep(wall))
	b.draw_rect(Rect2(0, 18, 320, 88), Pal.shade(wall))
	b.draw_rect(Rect2(40, 30, 240, 70), wall)
	b.draw_rect(Rect2(0, 104, 320, FLOOR_Y - 104), Pal.shade(Pal.WOOD))
	b.draw_rect(Rect2(0, 104, 320, 2), Pal.hi(Pal.WOOD))
	for x in range(8, 320, 24):
		b.draw_rect(Rect2(x, 110, 1, FLOOR_Y - 114), Pal.deep(Pal.WOOD))
	b.draw_rect(Rect2(0, FLOOR_Y - 3, 320, 3), Pal.deep(Pal.WOOD))
	var floor_c := Pal.SLATE.lerp(Pal.INK, 0.45)
	b.draw_rect(Rect2(0, FLOOR_Y, 320, 180 - FLOOR_Y), floor_c)
	for x in range(-8, 330, 22):
		b.draw_line(Vector2(x, FLOOR_Y), Vector2(x - 10, 180), Pal.shade(floor_c), 1.0)
	b.draw_rect(Rect2(0, FLOOR_Y, 320, 1), Pal.hi(floor_c))
	# pennants on the wall
	for i in 2:
		var px := 60.0 + i * 172.0
		var pc := Pal.TEAL if i == 0 else Pal.ROSE
		b.draw_colored_polygon(PackedVector2Array([Vector2(px, 40), Vector2(px + 28, 46), Vector2(px, 52)]), pc)
		b.draw_rect(Rect2(px, 40, 1, 12), Pal.hi(pc))
	# the lamp and its pool of light
	b.draw_rect(Rect2(159, 0, 2, 58), Pal.INK2)
	b.draw_colored_polygon(PackedVector2Array([Vector2(150, 64), Vector2(170, 64), Vector2(166, 58), Vector2(154, 58)]), Pal.STEEL)
	b.draw_rect(Rect2(150, 64, 20, 1), Pal.LEMON)
	b.draw_colored_polygon(PackedVector2Array([Vector2(151, 65), Vector2(169, 65), Vector2(TABLE_R + 8, FLOOR_Y), Vector2(TABLE_L - 8, FLOOR_Y)]), Color(Pal.LIGHT_TINT, 0.05))
	b.draw_colored_polygon(PackedVector2Array([Vector2(154, 65), Vector2(166, 65), Vector2(TABLE_R - 30, TABLE_Y), Vector2(TABLE_L + 30, TABLE_Y)]), Color(Pal.LIGHT_TINT, 0.05))


func _draw_table(b: Node2D) -> void:
	var top := Pal.TEAL
	# shadow on the floor
	b.draw_rect(Rect2(TABLE_L + 6, FLOOR_Y, TABLE_R - TABLE_L - 12, 3), Color(Pal.INK, 0.35))
	# legs
	for lx in [TABLE_L + 10, TABLE_L + 22, TABLE_R - 26, TABLE_R - 14]:
		b.draw_rect(Rect2(lx, 128, 4, FLOOR_Y - 128), Pal.shade(Pal.STEEL))
		b.draw_rect(Rect2(lx, 128, 1, FLOOR_Y - 128), Pal.hi(Pal.STEEL))
	b.draw_rect(Rect2(TABLE_L + 10, 138, 16, 2), Pal.deep(Pal.STEEL))
	b.draw_rect(Rect2(TABLE_R - 26, 138, 16, 2), Pal.deep(Pal.STEEL))
	# the top face, seen a little from above
	b.draw_colored_polygon(PackedVector2Array([Vector2(TABLE_L + 4, 118), Vector2(TABLE_R - 4, 118), Vector2(TABLE_R, 124), Vector2(TABLE_L, 124)]), top)
	b.draw_colored_polygon(PackedVector2Array([Vector2(TABLE_L + 4, 118), Vector2(160, 118), Vector2(160, 124), Vector2(TABLE_L, 124)]), Pal.hi(top).lerp(top, 0.5))
	b.draw_line(Vector2(TABLE_L + 4, 118), Vector2(TABLE_R - 4, 118), Pal.WHITE, 1.0)
	b.draw_line(Vector2(TABLE_L + 2, 121), Vector2(TABLE_R - 2, 121), Color(Pal.WHITE, 0.45), 1.0)
	# the front edge and apron
	b.draw_rect(Rect2(TABLE_L, 124, TABLE_R - TABLE_L, 1), Pal.WHITE)
	b.draw_rect(Rect2(TABLE_L, 125, TABLE_R - TABLE_L, 3), Pal.shade(top))
	b.draw_rect(Rect2(TABLE_L, 128, TABLE_R - TABLE_L, 1), Pal.deep(top))
	# the net: posts, mesh and tape
	b.draw_rect(Rect2(158, 108, 1, 16), Pal.STEEL)
	b.draw_rect(Rect2(162, 108, 1, 16), Pal.shade(Pal.STEEL))
	for y in range(110, 121, 2):
		b.draw_rect(Rect2(159, y, 3, 1), Color(Pal.INK2, 0.8))
	b.draw_rect(Rect2(159, 109, 3, 11), Color(Pal.WHITE, 0.15))
	b.draw_rect(Rect2(158, 108, 5, 1), Pal.WHITE)


func _draw_paddle(b: Node2D, hand: Vector2, side: float, swing: float, rubber: Color) -> void:
	## A paddle held at the end of the table. It rests cocked back and,
	## during a swing, sweeps up and forward with a little motion arc.
	var a := -0.5
	if swing > 0.0:
		var u := 1.0 - swing / 0.22
		a = lerpf(1.1, -1.4, minf(1.0, u * 2.0))
		if u < 0.6:
			var a0 := -1.4 if side > 0 else PI - 1.1
			b.draw_arc(hand, 9.0, a0, a0 + 2.5, 8, Color(Pal.WHITE, 0.25), 1.0)
	var dir := Vector2.from_angle(a)
	dir.x *= side
	var head := hand + dir * 8.0
	b.draw_line(hand, hand + dir * 4.0, Pal.WOOD, 2.0)
	b.draw_circle(head, 4.0, Pal.shade(rubber))
	b.draw_circle(head + Vector2(-0.5 * side, -0.5), 3.0, rubber)
	b.draw_rect(Rect2(head.floor() + Vector2(-1, -2), Vector2(1, 1)), Pal.hi(rubber))


func _card_face(at: Vector2, rank: int, suit: int, w: float) -> void:
	var b := board
	b.draw_rect(Rect2(at + Vector2(1, 1), Vector2(w, 70)), Color(0, 0, 0, 0.4))
	b.draw_rect(Rect2(at, Vector2(w, 70)), Pal.WHITE)
	b.draw_rect(Rect2(at + Vector2(2, 2), Vector2(w - 4, 66)), Pal.CREAM)
	if w < 12:
		return
	var red := suit == 1 or suit == 2
	var col := Pal.RED if red else Pal.INK2
	var txt: String = RANKS[rank]
	# the doubled glyph is ASCENT * 2 tall above its baseline: keep its top
	# 3 px inside the card's cream face
	b.draw_string(Art.font, at + Vector2(5, 3 + PixFont.ASCENT * 2), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, PixFont.SIZE * 2, col)
	var c := at + Vector2(w / 2.0, 42)
	match suit:
		0:
			b.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -10), c + Vector2(9, 3), c + Vector2(-9, 3)]), col)
			b.draw_rect(Rect2(c + Vector2(-1, 2), Vector2(3, 6)), col)
		1:
			b.draw_circle(c + Vector2(-4, -3), 5, col)
			b.draw_circle(c + Vector2(4, -3), 5, col)
			b.draw_colored_polygon(PackedVector2Array([c + Vector2(-9, -1), c + Vector2(9, -1), c + Vector2(0, 10)]), col)
		2:
			b.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -10), c + Vector2(8, 0), c + Vector2(0, 10), c + Vector2(-8, 0)]), col)
		_:
			b.draw_circle(c + Vector2(0, -5), 4, col)
			b.draw_circle(c + Vector2(-5, 1), 4, col)
			b.draw_circle(c + Vector2(5, 1), 4, col)
			b.draw_rect(Rect2(c + Vector2(-1, 2), Vector2(3, 7)), col)


func _draw_cards() -> void:
	var b := board
	b.draw_rect(Rect2(20, 32, 280, 124), Pal.PINE.lerp(Pal.INK, 0.4))
	var w := 48.0
	if flip_t > 0.0:
		flip_t -= get_process_delta_time()
		w = maxf(2.0, 48.0 * absf(cos(flip_t / 0.35 * PI)))
	_card_face(Vector2(136 + (48 - w) / 2.0, 52), card, (card * 7 + streak) % 4, w)
	# the deck
	for k in 4:
		b.draw_rect(Rect2(220 + k, 56 - k, 40, 62), Pal.NAVY.lerp(Pal.RED, 0.3))
		b.draw_rect(Rect2(222 + k, 58 - k, 36, 58), Pal.NAVY)
	var s := "STREAK %d" % streak
	b.draw_string(Art.font, Vector2(160 - Art.text_width(s) / 2.0, 44), s, HORIZONTAL_ALIGNMENT_LEFT, -1, PixFont.SIZE, Pal.WHITE)
	b.draw_string(Art.font, Vector2(60, 80), "UP: higher", HORIZONTAL_ALIGNMENT_LEFT, -1, PixFont.SIZE, Pal.GLOW)
	b.draw_string(Art.font, Vector2(60, 100), "DOWN: lower", HORIZONTAL_ALIGNMENT_LEFT, -1, PixFont.SIZE, Pal.ROSE)


func _draw_drill() -> void:
	var b := board
	var c := Vector2(160, 96)
	for d in ["up", "down", "left", "right"]:
		var v: Vector2 = {"up": Vector2(0, -1), "down": Vector2(0, 1), "left": Vector2(-1, 0), "right": Vector2(1, 0)}[d]
		var p := c + v * 40.0
		var lit: bool = d == prompt
		var col := Pal.LEMON if lit else Pal.PANEL2
		var n := Vector2(-v.y, v.x)
		b.draw_colored_polygon(PackedVector2Array([p + v * 14.0, p - v * 6.0 + n * 12.0, p - v * 6.0 - n * 12.0]), col)
		if lit:
			b.draw_arc(p, 20.0, 0, TAU, 24, Color(Pal.LEMON, 0.5), 2.0)
	b.draw_circle(c, 8, Pal.SYNC if prompt != "" else Pal.PANEL2)
	var s := "%d / 10" % times.size()
	b.draw_string(Art.font, Vector2(160 - Art.text_width(s) / 2.0, 44), s, HORIZONTAL_ALIGNMENT_LEFT, -1, PixFont.SIZE, Pal.WHITE)
	if not times.is_empty():
		var last := "%d ms" % int(times[-1])
		b.draw_string(Art.font, Vector2(240, 100), last, HORIZONTAL_ALIGNMENT_LEFT, -1, PixFont.SIZE, Pal.TEXT_DIM)
