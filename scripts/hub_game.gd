class_name HubGame
extends Control
## The Pilot Wing's little games, each under a minute, drawn full screen:
##   pingpong - rally against another recruit: press Z (tap) as the ball
##              reaches your paddle. Early or late is a miss; the rally ends
##              on your first miss. Score: the rally.
##   cards    - high-low: Up if the next card is higher, Down if lower (ties
##              win). Score: the streak.
##   drill    - the gym's sync-reflex drill: ten arrows flash up; press that
##              direction as fast as you can. Score: the average reaction in
##              ms (lower is better); a wrong press costs 250 ms.
## Touch: an arrow screen (the stick steers, a tap is Z, B leaves).

const TITLES := {"pingpong": "PING-PONG", "cards": "HIGH - LOW", "drill": "SYNC-REFLEX DRILL"}
const HELP := {"pingpong": "Z / tap when the ball reaches your paddle", "cards": "Up: higher   Down: lower", "drill": "Press the arrow that lights up"}
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


func _big(text: String, col: Color = Pal.WHITE, y: float = 70.0) -> void:
	big_l.text = text
	big_l.add_theme_color_override("font_color", col)
	big_l.position = Vector2(floorf(160 - Art.text_width(text, 2) / 2.0), y)


func run(p_kind: String, opp: Dictionary = {}) -> Dictionary:
	## Plays one round and returns {score, best, new_best, kind}.
	kind = p_kind
	opponent = opp
	title_l.text = TITLES[kind]
	info_l.text = HELP[kind] + ("   X quit" if not Game.touch_active else "")
	_big("READY?", Pal.LEMON)
	Sfx.play("chime", 1.2, -8.0)
	await _pause(1.0)
	_big("")
	var score := 0
	match kind:
		"pingpong":
			score = await _pingpong()
		"cards":
			score = await _cards()
		"drill":
			score = await _drill()
	var res := record(kind, score)
	var shown := ("%d ms" % score) if kind == "drill" else str(score)
	if score <= 0 and kind == "drill":
		shown = "--"
	_big(("NEW BEST!  " if res.new_best else "") + shown, Pal.LEMON if res.new_best else Pal.WHITE)
	if res.new_best:
		Sfx.play("levelup", 1.1, -6.0)
	info_l.text = "Best: %s" % (("%d ms" % res.best) if kind == "drill" else str(res.best))
	await _pause(1.6)
	return res


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

const PADDLE_X := 64.0
const FOE_X := 256.0
const HIT_WINDOW := 9.0


func _pingpong() -> int:
	ball_x = FOE_X
	ball_dir = -1
	ball_speed = 110.0
	rally = 0
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
		ball_x += ball_dir * ball_speed * d
		var press := Input.is_action_just_pressed("accept")
		if auto:
			press = ball_dir < 0 and absf(ball_x - PADDLE_X) < 3.0
		if press and swing_t <= 0.0:
			swing_t = 0.18
			if ball_dir < 0 and absf(ball_x - PADDLE_X) <= HIT_WINDOW:
				var perfect := absf(ball_x - PADDLE_X) <= 3.0
				ball_dir = 1
				rally += 1
				ball_speed = minf(320.0, ball_speed + (9.0 if perfect else 6.0))
				verdict = "PERFECT" if perfect else "GOOD"
				verdict_t = 0.5
				Sfx.play("knock", 1.5 if perfect else 1.3, -6.0)
				if perfect:
					Game.buzz(12)
			else:
				verdict = "EARLY" if ball_dir < 0 and ball_x > PADDLE_X else "WHIFF"
				verdict_t = 0.5
				Sfx.play("whoosh", 1.4, -12.0)
		if ball_dir > 0 and ball_x >= FOE_X:
			ball_x = FOE_X
			ball_dir = -1
			foe_swing = 0.18
			Sfx.play("knock", 1.1, -8.0)
		if ball_dir < 0 and ball_x < PADDLE_X - HIT_WINDOW - 6.0:
			verdict = "MISS"
			verdict_t = 1.0
			Sfx.play("cancel", 0.8, -4.0)
			await _pause(0.8)
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
		await _pause(randf_range(0.5, 1.4))
		if not is_inside_tree():
			return 0
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
	var table := Pal.TEAL.lerp(Pal.NAVY, 0.35)
	b.draw_rect(Rect2(40, 118, 240, 8), table)
	b.draw_rect(Rect2(40, 118, 240, 1), Pal.hi(table))
	b.draw_rect(Rect2(159, 104, 2, 14), Pal.WHITE)
	b.draw_rect(Rect2(60, 126, 4, 30), Pal.STEEL)
	b.draw_rect(Rect2(256, 126, 4, 30), Pal.STEEL)
	# the players: you on the left, them on the right
	var you := Art.person(Game.player_spec(), 2, 0, "smile" if verdict == "PERFECT" and verdict_t > 0.0 else "", "walk")
	b.draw_texture(you, Vector2(PADDLE_X - 40, 92))
	var opp := Art.person(opponent if not opponent.is_empty() else Data.EXTRAS[0], 2, 0, "", "walk")
	b.draw_texture_rect(opp, Rect2(FOE_X + 8, 92, -32, 32), false)
	var pa := -0.6 if swing_t > 0.0 else 0.3
	b.draw_line(Vector2(PADDLE_X - 8, 108), Vector2(PADDLE_X - 8, 108) + Vector2.from_angle(pa) * 9.0, Pal.RED, 3.0)
	var fa := PI + (0.6 if foe_swing > 0.0 else -0.3)
	b.draw_line(Vector2(FOE_X + 8, 108), Vector2(FOE_X + 8, 108) + Vector2.from_angle(fa) * 9.0, Pal.BLUE, 3.0)
	# the ball, arcing over the net
	var span := FOE_X - PADDLE_X
	var k := clampf((ball_x - PADDLE_X) / span, 0.0, 1.0)
	var y := 112.0 - sin(k * PI) * 34.0
	b.draw_circle(Vector2(ball_x, y), 2.5, Pal.WHITE)
	b.draw_rect(Rect2(ball_x - 2, 117, 4, 1), Color(0, 0, 0, 0.3))
	# the hit zone
	b.draw_rect(Rect2(PADDLE_X - HIT_WINDOW, 128, HIT_WINDOW * 2, 2), Color(Pal.SYNC, 0.5))
	var s := "RALLY %d" % rally
	b.draw_string(Art.font, Vector2(160 - Art.text_width(s) / 2.0, 44), s, HORIZONTAL_ALIGNMENT_LEFT, -1, PixFont.SIZE, Pal.WHITE)
	if verdict_t > 0.0:
		var col := Pal.LEMON if verdict == "PERFECT" else (Pal.GLOW if verdict == "GOOD" else Pal.RED)
		b.draw_string(Art.font, Vector2(PADDLE_X - Art.text_width(verdict) / 2.0, 82), verdict, HORIZONTAL_ALIGNMENT_LEFT, -1, PixFont.SIZE, col)


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
	b.draw_string(Art.font, at + Vector2(5, 12), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, PixFont.SIZE * 2, col)
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
