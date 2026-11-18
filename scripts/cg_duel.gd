extends ConsoleGame
## DUEL STRIDERS (Starbox cartridge): a pocket grid duel. A 6x3 grid, your
## three columns on the left, the CPU's on the right. Step between your
## panels with the arrows / stick, Z (A) fires your buster down the row, X (B)
## plays the card in hand: WIDE SWORD (the enemy's front column), BOMB (three
## panels ahead of you) or GUARD (blocks the next hit). Each card reloads on
## its own timer and the hand moves on to the next ready one.
##
## An endless ladder of CPU striders, each faster with more attacks: shots,
## ground waves, column strikes and bombs, every one telegraphed by a
## flashing panel. Your hearts carry between rounds (+1 per win).
## Score: 10 a hit, and per win 1000 + 200 a heart left + a speed bonus.
## Stats: wins, flawless (won a round untouched), buster (won with the buster
## alone).

const GX := 12
const GY := 30
const PW := 20
const PH := 12
const NAMES := ["SPARK", "BOLT", "HEX", "VOLT", "GRIM", "NOVA", "RUST", "ECHO", "FANG", "ZERO"]
const CARDS := [["WIDE SWORD", 3.0], ["BOMB", 4.0], ["GUARD", 5.0]]

var auto := false

var pc := Vector2i(1, 1)
var ec := Vector2i(4, 1)
var hp := 5
var ehp := 6
var ehp_max := 6
var foe := 0
var phase := "intro" # intro, fight, ko, lose
var phase_t := 1.4
var round_t := 0.0
var hit_this_round := false
var cards_used := false
var buster_cd := 0.0
var card_cd := [0.0, 0.0, 0.0]
var hand := 0
var guard_t := 0.0
var inv_t := 0.0
var e_move_t := 1.0
var e_act_t := 1.6
var e_flash := 0.0
var p_flash := 0.0
var shots: Array = []
var marks: Array = []
var fx: Array = []
var move_rep := 0.0
var banner: Label
var sub: Label
var card_l: Label


func begin() -> void:
	banner = Art.label("", Color("ffd36b"))
	add_child(banner)
	sub = Art.label("", Pal.WHITE)
	add_child(sub)
	card_l = Art.label("", Pal.WHITE)
	card_l.position = Vector2(2, 70)
	add_child(card_l)
	_new_foe()


func hud_text() -> String:
	return "%06d" % score


func _say(big: String, small: String = "") -> void:
	banner.text = big
	banner.position = Vector2(floorf(W / 2.0 - Art.text_width(big) / 2.0), 10)
	sub.text = small
	sub.position = Vector2(floorf(W / 2.0 - Art.text_width(small) / 2.0), 19)


func _new_foe() -> void:
	foe += 1
	ehp_max = 5 + foe * 2
	ehp = ehp_max
	ec = Vector2i(4, 1)
	pc = Vector2i(1, 1)
	shots.clear()
	marks.clear()
	phase = "intro"
	phase_t = 1.5
	round_t = 0.0
	hit_this_round = false
	cards_used = false
	_say("VS %s" % NAMES[(foe - 1) % NAMES.size()], "OPPONENT %d" % foe)
	Sfx.play("chime", 1.0 + foe * 0.03, -10.0)


func _speed() -> float:
	return 1.0 + minf(foe - 1, 14) * 0.12


func step(delta: float) -> void:
	phase_t -= delta
	_tick_fx(delta)
	match phase:
		"intro":
			if phase_t <= 0.4 and banner.text.begins_with("VS"):
				_say("FIGHT!")
				Sfx.play("confirm")
			if phase_t <= 0.0:
				_say("")
				phase = "fight"
			return
		"ko":
			if phase_t <= 0.0:
				hp = mini(5, hp + 1)
				_new_foe()
			return
		"lose":
			if phase_t <= 0.0:
				end()
			return
	round_t += delta
	buster_cd -= delta
	guard_t -= delta
	inv_t -= delta
	e_flash -= delta
	p_flash -= delta
	for i in 3:
		card_cd[i] = maxf(0.0, card_cd[i] - delta)
	_player(delta)
	_enemy(delta)
	_tick_shots(delta)
	_tick_marks(delta)
	var c: Array = CARDS[hand]
	card_l.text = "B:%s" % c[0] if card_cd[hand] <= 0.0 else "B:%s %.1f" % [c[0], card_cd[hand]]


# -------------------------------------------------------------- player ---

func _player(delta: float) -> void:
	var d := Vector2i.ZERO
	if auto:
		d = _auto_move()
	else:
		for pair in [["left", Vector2i(-1, 0)], ["right", Vector2i(1, 0)], ["up", Vector2i(0, -1)], ["down", Vector2i(0, 1)]]:
			if pressed(pair[0]):
				d = pair[1]
		if d == Vector2i.ZERO:
			move_rep -= delta
			var v := stick()
			if v.length() > 0.5 and move_rep <= 0.0:
				d = Vector2i(roundi(v.x), 0) if absf(v.x) > absf(v.y) else Vector2i(0, roundi(v.y))
				move_rep = 0.18
		else:
			move_rep = 0.25
	if d != Vector2i.ZERO:
		var n := pc + d
		if n.x >= 0 and n.x <= 2 and n.y >= 0 and n.y <= 2:
			pc = n
			blip(1.4, -18.0)
	var fire := pressed("accept") or held("accept")
	var card := pressed("cancel")
	if auto:
		fire = pc.y == ec.y
		card = card_cd[hand] <= 0.0 and (hand != 1 or ec == pc + Vector2i(3, 0)) and (hand != 0 or ec.x == 3)
	if fire and buster_cd <= 0.0:
		buster_cd = 0.3
		shots.append({"x": float(GX + pc.x * PW + PW), "row": pc.y, "vx": 140.0, "own": "p", "dmg": 1, "kind": "buster"})
		blip(1.8, -14.0)
	if card and card_cd[hand] <= 0.0:
		_play_card(hand)


func _play_card(i: int) -> void:
	cards_used = true
	card_cd[i] = CARDS[i][1]
	match i:
		0:
			# the whole enemy front column, at once
			for r in 3:
				_spark(Vector2(GX + 3 * PW + PW / 2, GY + r * PH + PH / 2), Color("9fe8ff"), 5)
			if ec.x == 3:
				_hurt_enemy(3)
			Sfx.play("lance", 1.4, -8.0)
		1:
			var tgt := pc + Vector2i(3, 0)
			marks.append({"cell": tgt, "t": 0.45, "dmg": 3, "own": "p", "kind": "bomb"})
			Sfx.play("whoosh", 1.2, -10.0)
		2:
			guard_t = 2.0
			Sfx.play("block", 1.2, -8.0)
	# the hand moves on to the next card that's ready (or the next in line)
	for k in range(1, 4):
		var j := (i + k) % 3
		if card_cd[j] <= 0.0 or k == 3:
			hand = j
			break
	if card_cd[hand] > 0.0:
		hand = (i + 1) % 3


# --------------------------------------------------------------- enemy ---

func _enemy(delta: float) -> void:
	var sp := _speed()
	e_move_t -= delta * sp
	if e_move_t <= 0.0:
		e_move_t = randf_range(0.7, 1.3)
		var n: Vector2i = ec + [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)][randi() % 4]
		if randf() < 0.45:
			# lean toward the player's row
			n = Vector2i(ec.x, ec.y + signi(pc.y - ec.y))
		if n.x >= 3 and n.x <= 5 and n.y >= 0 and n.y <= 2:
			ec = n
	e_act_t -= delta * sp
	if e_act_t > 0.0:
		return
	e_act_t = randf_range(1.2, 2.0)
	var moves := ["shot"]
	if foe >= 2:
		moves.append("wave")
	if foe >= 3:
		moves.append("column")
	if foe >= 5:
		moves.append("bomb")
	match moves[randi() % moves.size()]:
		"shot":
			shots.append({"x": float(GX + ec.x * PW), "row": ec.y, "vx": -90.0 * sp, "own": "e", "dmg": 1, "kind": "shot"})
			blip(0.9, -14.0)
		"wave":
			shots.append({"x": float(GX + ec.x * PW), "row": ec.y, "vx": -45.0 * sp, "own": "e", "dmg": 1, "kind": "wave"})
			Sfx.play("thrust", 1.6, -16.0)
		"column":
			var col := randi() % 3
			for r in 3:
				marks.append({"cell": Vector2i(col, r), "t": 0.9 / sqrt(sp), "dmg": 1, "own": "e", "kind": "strike"})
		"bomb":
			marks.append({"cell": pc, "t": 1.0 / sqrt(sp), "dmg": 2, "own": "e", "kind": "bomb"})


func _tick_shots(delta: float) -> void:
	for s in shots.duplicate():
		s.x += s.vx * delta
		var col := int(floorf((s.x - GX) / PW))
		if s.own == "p" and col >= 3 and col <= 5 and col == ec.x and s.row == ec.y:
			shots.erase(s)
			_hurt_enemy(s.dmg)
			continue
		if s.own == "e" and col >= 0 and col <= 2 and col == pc.x and s.row == pc.y:
			shots.erase(s)
			_hurt_player(s.dmg)
			continue
		if s.x < GX - 6 or s.x > GX + 6 * PW + 6:
			shots.erase(s)


func _tick_marks(delta: float) -> void:
	for m in marks.duplicate():
		m.t -= delta
		if m.t > 0.0:
			continue
		marks.erase(m)
		var p := Vector2(GX + m.cell.x * PW + PW / 2, GY + m.cell.y * PH + PH / 2)
		_spark(p, Color("ff9a5a") if m.own == "e" else Color("ffd36b"), 6)
		Sfx.play("explode", 1.5, -14.0)
		if m.own == "e" and m.cell == pc:
			_hurt_player(m.dmg)
		elif m.own == "p" and m.cell == ec:
			_hurt_enemy(m.dmg)


func _hurt_enemy(n: int) -> void:
	ehp -= n
	e_flash = 0.15
	score += 10 * n
	_spark(_cell_pos(ec), Color.WHITE, 4)
	blip(0.6, -10.0)
	if ehp <= 0 and phase == "fight":
		phase = "ko"
		phase_t = 1.6
		var bonus := 1000 + hp * 200 + int(maxf(0.0, 30.0 - round_t) * 20.0)
		score += bonus
		stat_max("wins", foe)
		if not hit_this_round:
			stats["flawless"] = 1
		if not cards_used:
			stats["buster"] = 1
		_say("K.O.!", "+%d" % bonus)
		Sfx.play("levelup", 1.2, -6.0)
		shots.clear()
		marks.clear()


func _hurt_player(n: int) -> void:
	if inv_t > 0.0 or phase != "fight":
		return
	if guard_t > 0.0:
		guard_t = 0.0
		Sfx.play("block", 0.9, -6.0)
		_spark(_cell_pos(pc), Color("9fe8ff"), 6)
		return
	hp -= n
	hit_this_round = true
	inv_t = 0.8
	p_flash = 0.2
	Sfx.play("hurt", 1.2, -6.0)
	if hp <= 0:
		hp = 0
		phase = "lose"
		phase_t = 1.8
		_say("DEFEATED", "%d opponents beaten" % (foe - 1))


# ------------------------------------------------------------------ bot ---

func _auto_move() -> Vector2i:
	# step off any panel about to be hit, else line up with the enemy's row
	for m in marks:
		if m.own == "e" and m.cell == pc:
			for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0)]:
				var n: Vector2i = pc + d
				if n.x >= 0 and n.x <= 2 and n.y >= 0 and n.y <= 2 and not _marked(n):
					return d
	for s in shots:
		if s.own == "e" and s.row == pc.y and s.x - (GX + pc.x * PW) < 40.0:
			var d := Vector2i(0, 1) if pc.y < 2 else Vector2i(0, -1)
			if not _marked(pc + d):
				return d
	if fmod(t, 0.25) < get_process_delta_time() and pc.y != ec.y:
		return Vector2i(0, signi(ec.y - pc.y))
	return Vector2i.ZERO


func _marked(c: Vector2i) -> bool:
	for m in marks:
		if m.own == "e" and m.cell == c:
			return true
	return false


# ---------------------------------------------------------------- draw ---

func _cell_pos(c: Vector2i) -> Vector2:
	return Vector2(GX + c.x * PW + PW / 2, GY + c.y * PH + PH - 2)


func _spark(p: Vector2, col: Color, n: int) -> void:
	for i in n:
		fx.append({"p": p, "v": Vector2.from_angle(randf() * TAU) * randf_range(10, 35), "life": randf_range(0.2, 0.45), "c": col})


func _tick_fx(delta: float) -> void:
	for f in fx.duplicate():
		f.p += f.v * delta
		f.life -= delta
		if f.life <= 0.0:
			fx.erase(f)


func _draw() -> void:
	# the floor: your panels blue, theirs red, a flashing warning on marked ones
	for r in 3:
		for c in 6:
			var mine := c <= 2
			var base := Color("2c4f8a") if mine else Color("8a2c3c")
			var x := GX + c * PW
			var y := GY + r * PH
			var warn := false
			for m in marks:
				if m.cell == Vector2i(c, r):
					warn = fmod(t, 0.16) < 0.08
			draw_rect(Rect2(x, y, PW - 1, PH - 1), Color("ffd36b") if warn else base)
			draw_rect(Rect2(x, y, PW - 1, 1), (Color("ffd36b") if warn else base).lerp(Color.WHITE, 0.3))
			draw_rect(Rect2(x, y + PH - 2, PW - 1, 1), base.darkened(0.4))
	draw_rect(Rect2(GX + 3 * PW - 1, GY - 2, 1, PH * 3 + 2), Color("ffd36b"))
	# striders
	_strider(_cell_pos(pc), Color("5fd3e0"), 1, p_flash > 0.0 or (inv_t > 0.0 and fmod(t, 0.1) < 0.05), guard_t > 0.0)
	if phase != "ko":
		var hue := fmod(foe * 0.13, 1.0)
		_strider(_cell_pos(ec), Color.from_hsv(hue, 0.6, 0.95), -1, e_flash > 0.0, false)
	for s in shots:
		var y: float = GY + s.row * PH + PH / 2
		match s.kind:
			"buster":
				draw_rect(Rect2(floorf(s.x), y - 3, 3, 1), Color("ffd36b"))
			"shot":
				draw_rect(Rect2(floorf(s.x), y - 3, 3, 2), Color("ff7a6b"))
			"wave":
				draw_rect(Rect2(floorf(s.x), y + 1, 4, 3), Color("ff9a5a"))
				draw_rect(Rect2(floorf(s.x) + 1, y - 1, 2, 2), Color("ffd36b"))
	for f in fx:
		draw_rect(Rect2((f.p as Vector2).floor(), Vector2(1, 1)), f.c)
	# hearts (yours) and the enemy's bar
	for i in 5:
		var on := i < hp
		draw_rect(Rect2(50 + i * 6, 2, 4, 4), Color("ff5a6e") if on else Color(0.3, 0.25, 0.35))
	draw_rect(Rect2(88, 3, 52, 3), Color(0.2, 0.15, 0.2))
	draw_rect(Rect2(88, 3, 52.0 * maxf(0, ehp) / ehp_max, 3), Color("ff7a6b"))
	# the card hand, with reload bars
	for i in 3:
		var x := 100 + i * 14
		draw_rect(Rect2(x, 69, 12, 9), Color("ffd36b") if i == hand else Color(0.25, 0.22, 0.3))
		draw_rect(Rect2(x + 1, 70, 10, 7), [Color("5fd3e0"), Color("ff9a5a"), Color("8ad16a")][i] if card_cd[i] <= 0.0 else Color(0.18, 0.16, 0.22))
		if card_cd[i] > 0.0:
			draw_rect(Rect2(x + 1, 77 - 7.0 * card_cd[i] / CARDS[i][1], 10, 1), Color.WHITE)


func _strider(at: Vector2, col: Color, face: int, flash: bool, guard: bool) -> void:
	var o := at.floor()
	var c := Color.WHITE if flash else col
	draw_rect(Rect2(o.x - 2, o.y - 9, 5, 4), c.lerp(Color.WHITE, 0.25))
	draw_rect(Rect2(o.x - 3, o.y - 5, 7, 4), c)
	draw_rect(Rect2(o.x - 2, o.y - 1, 2, 2), c.darkened(0.4))
	draw_rect(Rect2(o.x + 1, o.y - 1, 2, 2), c.darkened(0.4))
	draw_rect(Rect2(o.x + (1 if face > 0 else -2), o.y - 8, 1, 1), Color("1a1626"))
	draw_rect(Rect2(o.x + (4 if face > 0 else -5), o.y - 4, 2, 1), Color("ffd36b"))
	if guard:
		draw_rect(Rect2(o.x + (5 if face > 0 else -6), o.y - 10, 1, 10), Color("9fe8ff"))
