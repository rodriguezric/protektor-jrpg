extends ConsoleGame
## SWORD STORY (Starbox cartridge): a one-screen action RPG. The hero moves in
## eight directions (arrows / stick), Z (A) slashes in a short arc in front
## with knockback, X (B) rolls (a quick dash you can't be hit during). Five
## hearts; a heart sometimes drops from a beaten foe.
##
## Waves of bad guys: slimes hop at you, bats swoop, knights block from the
## front (hit them from the side or behind), archers keep their distance and
## shoot. Every fifth wave is a boss, the SLIME KING, who charges and splits.
## Score: each foe's value times the combo (hits within 1.5 s of each other,
## +10% per hit), and a bonus per wave cleared.
## Stats: wave (best wave cleared), combo, nohit (a boss beaten untouched).

const TOP := 9.0
const ARENA := Rect2(4, 12, 136, 64)
const DIRS := [Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector2(-1, 1), Vector2(-1, 0), Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1)]

var auto := false

var hero := Vector2(72, 46)
var face := Vector2(0, 1)
var hearts := 5
var slash_t := 0.0
var slash_cd := 0.0
var roll_t := 0.0
var roll_cd := 0.0
var roll_v := Vector2.ZERO
var inv_t := 0.0
var foes: Array = []
var arrows: Array = []
var drops: Array = []
var fx: Array = []
var wave := 0
var wave_t := 1.8
var combo := 0
var combo_t := 0.0
var boss_hit := false
var intro := 1.8
var dying := -1.0
var banner: Label
var combo_l: Label
var hit_list: Array = []


func begin() -> void:
	banner = Art.label("SWORD STORY", Color("8ad16a"))
	banner.position = Vector2(floorf(W / 2.0 - Art.text_width("SWORD STORY") / 2.0), 22)
	add_child(banner)
	combo_l = Art.label("", Color("ffd36b"))
	combo_l.position = Vector2(46, 0)
	add_child(combo_l)
	for i in 3:
		Sfx.play("blip", [1.0, 1.33, 2.0][i], -8.0)


func hud_text() -> String:
	combo_l.text = "%d HIT" % combo if combo >= 3 else ""
	return "" if intro > 0.0 else "%06d" % score


func _banner(s: String, col: Color = Color("ffd36b")) -> void:
	banner.text = s
	banner.add_theme_color_override("font_color", col)
	banner.position = Vector2(floorf(W / 2.0 - Art.text_width(s) / 2.0), 22)


func step(delta: float) -> void:
	_tick_fx(delta)
	if intro > 0.0:
		intro -= delta
		if intro <= 0.0:
			_banner("")
		return
	if dying >= 0.0:
		dying += delta
		if dying > 1.8:
			end()
		return
	slash_t -= delta
	slash_cd -= delta
	roll_cd -= delta
	inv_t -= delta
	combo_t -= delta
	if combo_t <= 0.0:
		combo = 0
	_hero(delta)
	_foes(delta)
	_arrows(delta)
	_drops()
	if foes.is_empty():
		wave_t -= delta
		if wave_t <= 0.9 and banner.text == "" and wave > 0:
			_banner("WAVE %d CLEAR" % wave)
		if wave_t <= 0.0:
			_next_wave()


# ---------------------------------------------------------------- hero ---

func _hero(delta: float) -> void:
	var v := stick()
	var do_slash := pressed("accept")
	var do_roll := pressed("cancel")
	if auto:
		var a := _auto()
		v = a[0]
		do_slash = a[1]
		do_roll = a[2]
	if roll_t > 0.0:
		roll_t -= delta
		hero += roll_v * delta
	else:
		if v.length() > 0.3:
			face = _dir8(v)
			hero += v.normalized() * 42.0 * minf(1.0, v.length() * 1.4) * delta * (0.55 if slash_t > 0.0 else 1.0)
		if do_roll and roll_cd <= 0.0:
			roll_t = 0.22
			roll_cd = 0.6
			roll_v = (v.normalized() if v.length() > 0.3 else face.normalized()) * 105.0
			Sfx.play("whoosh", 1.5, -12.0)
		elif do_slash and slash_cd <= 0.0:
			slash_t = 0.16
			slash_cd = 0.28
			hit_list.clear()
			Sfx.play("lance", 1.7, -12.0)
	hero = hero.clamp(ARENA.position + Vector2(3, 6), ARENA.end - Vector2(3, 1))
	if slash_t > 0.0:
		for f in foes.duplicate():
			if hit_list.has(f):
				continue
			var to: Vector2 = f.p - hero
			if to.length() < 11.0 + f.r and to.normalized().dot(face.normalized()) > 0.2:
				hit_list.append(f)
				_hit_foe(f, to.normalized())


func _dir8(v: Vector2) -> Vector2:
	var i := wrapi(roundi(v.angle() / (PI / 4.0)), 0, 8)
	return DIRS[i]


func _hit_foe(f: Dictionary, dir: Vector2) -> void:
	if f.kind == "knight" and (-dir).dot(f.face) > 0.5 and f.hp > 0:
		# a knight's shield turns aside blows from the front
		Sfx.play("block", 1.5, -10.0)
		_spark(f.p - dir * 3, Color("9fe8ff"), 4)
		f.v = dir * 30.0
		return
	f.hp -= 1
	f.v = dir * (60.0 if f.kind != "king" else 15.0)
	f.flash = 0.12
	combo += 1
	combo_t = 1.5
	stat_max("combo", combo)
	_spark(f.p, Color.WHITE, 4)
	blip(0.8, -12.0)
	if f.hp <= 0:
		_kill(f)


func _kill(f: Dictionary) -> void:
	foes.erase(f)
	var val: int = {"slime": 50, "bat": 75, "knight": 150, "archer": 120, "king": 1000}[f.kind]
	score += int(val * (1.0 + combo * 0.1))
	_spark(f.p, f.col, 10)
	Sfx.play("explode", 1.8 if f.kind != "king" else 0.7, -12.0)
	if f.kind == "king":
		if not boss_hit:
			stats["nohit"] = 1
		_banner("KING DEFEATED!", Color("8ad16a"))
	elif f.kind == "slime" and f.get("big", false):
		for k in 2:
			foes.append(_make("slime", f.p + Vector2(k * 6 - 3, 0)))
	if hearts < 5 and randf() < 0.1:
		drops.append({"p": f.p, "t": 6.0})


# ---------------------------------------------------------------- foes ---

func _make(kind: String, p: Vector2) -> Dictionary:
	var f := {"kind": kind, "p": p, "v": Vector2.ZERO, "hp": 1, "r": 3.0, "flash": 0.0, "t": randf() * 3.0, "face": Vector2(-1, 0), "cd": randf_range(1.0, 2.0), "col": Color("6ad16a")}
	match kind:
		"bat":
			f.col = Color("a07ad8")
		"knight":
			f.hp = 3
			f.col = Color("b9b3c4")
			f.r = 3.5
		"archer":
			f.hp = 2
			f.col = Color("e0a050")
		"king":
			f.hp = 12 + wave
			f.r = 8.0
			f.col = Color("4fbf6a")
			f.cd = 2.0
	return f


func _next_wave() -> void:
	wave += 1
	stat_max("wave", wave - 1)
	if wave > 1:
		score += 100 * (wave - 1)
	wave_t = 1.8
	var boss := wave % 5 == 0
	_banner("WAVE %d" % wave if not boss else "THE SLIME KING", Color("ffd36b") if not boss else Color("ff7a6b"))
	var shown := banner.text
	get_tree().create_timer(1.0, false).timeout.connect(func() -> void:
		if is_inside_tree() and banner.text == shown:
			_banner(""))
	Sfx.play("chime", 1.0 if not boss else 0.6, -8.0)
	if boss:
		boss_hit = false
		foes.append(_make("king", Vector2(ARENA.end.x - 20, ARENA.get_center().y)))
		return
	var n := 3 + wave
	var kinds := ["slime"]
	if wave >= 2:
		kinds.append("bat")
	if wave >= 3:
		kinds.append("knight")
	if wave >= 4:
		kinds.append("archer")
	for i in n:
		var edge := randi() % 4
		var p := Vector2(randf_range(ARENA.position.x + 4, ARENA.end.x - 4), ARENA.position.y + 6) if edge == 0 else \
			Vector2(randf_range(ARENA.position.x + 4, ARENA.end.x - 4), ARENA.end.y - 2) if edge == 1 else \
			Vector2(ARENA.position.x + 3, randf_range(ARENA.position.y + 6, ARENA.end.y - 2)) if edge == 2 else \
			Vector2(ARENA.end.x - 3, randf_range(ARENA.position.y + 6, ARENA.end.y - 2))
		if p.distance_to(hero) < 24.0:
			p = ARENA.position + ARENA.end - p
		foes.append(_make(kinds[randi() % kinds.size()], p))


func _foes(delta: float) -> void:
	var sp := 1.0 + minf(wave, 20) * 0.04
	for f in foes.duplicate():
		f.t += delta
		f.flash -= delta
		f.cd -= delta
		var to: Vector2 = hero - f.p
		var dir := to.normalized()
		var move := Vector2.ZERO
		match f.kind:
			"slime":
				# hop, rest, hop
				if fmod(f.t, 1.0) < 0.35:
					move = dir * 34.0
			"bat":
				move = (dir + Vector2(sin(f.t * 5.0), cos(f.t * 4.0)) * 0.9).normalized() * 30.0
			"knight":
				f.face = f.face.lerp(dir, delta * 1.8).normalized()
				move = f.face * 15.0
			"archer":
				move = (-dir if to.length() < 40.0 else dir * 0.4 + Vector2(-dir.y, dir.x) * 0.6) * 18.0
				if f.cd <= 0.0:
					f.cd = randf_range(1.6, 2.4) / sp
					arrows.append({"p": f.p, "v": dir * 55.0})
					blip(1.2, -18.0)
			"king":
				if f.cd <= 0.0 and f.get("wind", 0.0) <= 0.0 and f.get("charge", 0.0) <= 0.0:
					# winds up (quivering, flashing) before it charges
					f.wind = 0.5
					Sfx.play("tell", 1.0, -10.0)
				if f.get("wind", 0.0) > 0.0:
					f.wind -= delta
					f.flash = 0.04 if fmod(f.wind, 0.1) < 0.05 else 0.0
					if f.wind <= 0.0:
						f.cd = randf_range(2.0, 3.0) / sp
						f.charge = 0.5
						f.cdir = dir
						Sfx.play("thrust", 0.8, -10.0)
				elif f.get("charge", 0.0) > 0.0:
					f.charge -= delta
					move = f.cdir * 80.0
				else:
					move = dir * 9.0
				if fmod(f.t, 4.0) < delta and foes.size() < 8:
					var s := _make("slime", f.p)
					foes.append(s)
		f.p += (move * sp + f.v) * delta
		f.v = f.v.move_toward(Vector2.ZERO, 240.0 * delta)
		f.p = f.p.clamp(ARENA.position + Vector2(2, 4), ARENA.end - Vector2(2, 1))
		if to.length() < f.r + 3.0 and roll_t <= 0.0:
			_hurt(-dir)


func _arrows(delta: float) -> void:
	for a in arrows.duplicate():
		a.p += a.v * delta
		if not ARENA.grow(4).has_point(a.p):
			arrows.erase(a)
			continue
		if slash_t > 0.0 and (a.p as Vector2).distance_to(hero + face.normalized() * 6.0) < 6.0:
			arrows.erase(a)
			_spark(a.p, Color("ffd36b"), 3)
			continue
		if (a.p as Vector2).distance_to(hero) < 4.0 and roll_t <= 0.0:
			arrows.erase(a)
			_hurt((a.v as Vector2).normalized())


func _drops() -> void:
	for d in drops.duplicate():
		d.t -= get_process_delta_time()
		if d.t <= 0.0:
			drops.erase(d)
		elif (d.p as Vector2).distance_to(hero) < 6.0:
			drops.erase(d)
			hearts = mini(5, hearts + 1)
			Sfx.play("coin", 1.2, -8.0)


func _hurt(dir: Vector2) -> void:
	if inv_t > 0.0:
		return
	hearts -= 1
	inv_t = 1.0
	combo = 0
	for f in foes:
		if f.kind == "king":
			boss_hit = true
	hero += dir * 6.0
	Sfx.play("hurt", 1.4, -6.0)
	if hearts <= 0:
		dying = 0.0
		_spark(hero, Color("ff5a6e"), 16)
		_banner("THE END", Color("ff7a6b"))


# ------------------------------------------------------------------ bot ---

func _auto() -> Array:
	var near := {}
	var bd := 1e9
	for f in foes:
		var d := (f.p as Vector2).distance_to(hero)
		if d < bd:
			bd = d
			near = f
	for a in arrows:
		if (a.p as Vector2).distance_to(hero) < 14.0:
			return [Vector2(-a.v.y, a.v.x).normalized(), false, true]
	if near.is_empty():
		return [(ARENA.get_center() - hero) * 0.05, false, false]
	var to: Vector2 = near.p - hero
	var want := to
	if near.kind == "knight":
		# circle round to its back
		want = (near.p - near.face * 9.0) - hero
	var close: bool = to.length() < 10.0 + float(near.r)
	return [want.normalized() if not close or near.kind == "knight" else to.normalized() * 0.35, close and slash_cd <= 0.0, false]


# ---------------------------------------------------------------- draw ---

func _spark(p: Vector2, col: Color, n: int) -> void:
	for i in n:
		fx.append({"p": p, "v": Vector2.from_angle(randf() * TAU) * randf_range(12, 40), "life": randf_range(0.2, 0.5), "c": col})


func _tick_fx(delta: float) -> void:
	for f in fx.duplicate():
		f.p += f.v * delta
		f.life -= delta
		if f.life <= 0.0:
			fx.erase(f)


func _draw() -> void:
	# a meadow with a stone border
	draw_rect(ARENA.grow(2), Color("4a4458"))
	draw_rect(ARENA, Color("2f5a34"))
	for y in range(int(ARENA.position.y), int(ARENA.end.y), 8):
		for x in range(int(ARENA.position.x), int(ARENA.end.x), 8):
			if (x / 8 + y / 8) % 2 == 0:
				draw_rect(Rect2(x, y, 8, 8), Color("33623a"))
	for k in 9:
		draw_rect(Rect2(8 + (k * 37) % 128, 16 + (k * 23) % 56, 1, 2), Color("5c9a4e"))
	if intro > 0.0:
		_draw_hero(Vector2(72, 54), Vector2(0, 1), false)
		return
	for d in drops:
		if d.t > 1.5 or fmod(d.t, 0.2) < 0.1:
			_heart(d.p - Vector2(2, 3), true)
	for f in foes:
		_draw_foe(f)
	for a in arrows:
		var p: Vector2 = a.p
		draw_line(p, p - (a.v as Vector2).normalized() * 4.0, Color("e8d9b0"), 1.0)
	if dying < 0.0 and (inv_t <= 0.0 or fmod(inv_t, 0.12) < 0.07):
		_draw_hero(hero, face, roll_t > 0.0)
	if slash_t > 0.0:
		var a0 := face.angle()
		var k := 1.0 - slash_t / 0.16
		draw_arc(hero + Vector2(0, -3), 9.0, a0 - 1.0 + k * 0.3, a0 + 1.0, 8, Color(1, 1, 0.85, 0.9), 2.0, false)
	for f in fx:
		draw_rect(Rect2((f.p as Vector2).floor(), Vector2(1, 1)), f.c)
	for i in 5:
		_heart(Vector2(98 + i * 9, 2), i < hearts)


func _heart(p: Vector2, full: bool) -> void:
	p = p.floor()
	var c := Color("ff5a6e") if full else Color(0.3, 0.25, 0.35)
	draw_rect(Rect2(p, Vector2(2, 2)), c)
	draw_rect(Rect2(p + Vector2(3, 0), Vector2(2, 2)), c)
	draw_rect(Rect2(p + Vector2(0, 1), Vector2(5, 2)), c)
	draw_rect(Rect2(p + Vector2(1, 3), Vector2(3, 1)), c)
	draw_rect(Rect2(p + Vector2(2, 4), Vector2(1, 1)), c)


func _draw_hero(at: Vector2, f: Vector2, rolling: bool) -> void:
	var o := at.floor()
	if rolling:
		draw_rect(Rect2(o.x - 3, o.y - 5, 6, 5), Color("3f7fd0"))
		draw_rect(Rect2(o.x - 2, o.y - 6, 4, 2), Color("f0c890"))
		return
	draw_rect(Rect2(o.x - 2, o.y - 8, 5, 3), Color("f0c890"))       # face
	draw_rect(Rect2(o.x - 2, o.y - 9, 5, 2), Color("8a5a30"))       # hair
	draw_rect(Rect2(o.x - 3, o.y - 5, 7, 4), Color("3f7fd0"))       # tunic
	draw_rect(Rect2(o.x - 2, o.y - 1, 2, 1), Color("4a3020"))
	draw_rect(Rect2(o.x + 1, o.y - 1, 2, 1), Color("4a3020"))
	if f.y >= 0:
		draw_rect(Rect2(o.x - 1, o.y - 7, 1, 1), Color("1a1626"))
		draw_rect(Rect2(o.x + 1, o.y - 7, 1, 1), Color("1a1626"))
	# the sword at the side it's facing
	var sp := o + Vector2(f.x * 4.0, -3.0 + f.y * 2.0)
	draw_line(sp, sp + f.normalized() * 4.0, Color("dfe6f0"), 1.0)


func _draw_foe(f: Dictionary) -> void:
	var o: Vector2 = (f.p as Vector2).floor()
	var c: Color = Color.WHITE if f.flash > 0.0 else f.col
	match f.kind:
		"slime":
			var squash := 1 if fmod(f.t, 1.0) < 0.35 else 0
			draw_rect(Rect2(o.x - 3, o.y - 4 + squash, 7, 4 - squash), c)
			draw_rect(Rect2(o.x - 2, o.y - 5 + squash, 5, 1), c)
			draw_rect(Rect2(o.x - 1, o.y - 3 + squash, 1, 1), Color("1a1626"))
			draw_rect(Rect2(o.x + 1, o.y - 3 + squash, 1, 1), Color("1a1626"))
		"bat":
			var flap := 1 if fmod(f.t, 0.2) < 0.1 else -1
			draw_rect(Rect2(o.x - 1, o.y - 5, 3, 3), c)
			draw_rect(Rect2(o.x - 4, o.y - 5 + flap, 3, 1), c)
			draw_rect(Rect2(o.x + 2, o.y - 5 + flap, 3, 1), c)
			draw_rect(Rect2(o.x, o.y - 4, 1, 1), Color("ff5a6e"))
		"knight":
			draw_rect(Rect2(o.x - 2, o.y - 9, 5, 4), c.lerp(Color.WHITE, 0.2))
			draw_rect(Rect2(o.x - 3, o.y - 5, 7, 5), c.darkened(0.2))
			draw_rect(Rect2(o.x - 1, o.y - 8, 3, 1), Color("1a1626"))
			var sh: Vector2 = o + (f.face as Vector2) * 4.0 + Vector2(0, -4)
			draw_rect(Rect2(sh.x - 1, sh.y - 2, 3, 5), Color("6a8ad0"))
		"archer":
			draw_rect(Rect2(o.x - 2, o.y - 8, 5, 3), Color("f0c890"))
			draw_rect(Rect2(o.x - 2, o.y - 9, 5, 2), Color("3a7a3a"))
			draw_rect(Rect2(o.x - 3, o.y - 5, 7, 4), c)
			draw_rect(Rect2(o.x + 3, o.y - 8, 1, 6), Color("8a5a30"))
		"king":
			draw_rect(Rect2(o.x - 8, o.y - 9, 17, 9), c)
			draw_rect(Rect2(o.x - 6, o.y - 12, 13, 3), c)
			draw_rect(Rect2(o.x - 4, o.y - 15, 9, 3), Color("ffd36b"))
			draw_rect(Rect2(o.x - 4, o.y - 16, 1, 1), Color("ffd36b"))
			draw_rect(Rect2(o.x, o.y - 16, 1, 1), Color("ffd36b"))
			draw_rect(Rect2(o.x + 4, o.y - 16, 1, 1), Color("ffd36b"))
			draw_rect(Rect2(o.x - 4, o.y - 7, 2, 2), Color("1a1626"))
			draw_rect(Rect2(o.x + 3, o.y - 7, 2, 2), Color("1a1626"))
			# its health, over its crown
			draw_rect(Rect2(o.x - 8, o.y - 19, 17, 1), Color(0.2, 0.15, 0.2))
			draw_rect(Rect2(o.x - 8, o.y - 19, 17.0 * f.hp / (12 + wave), 1), Color("ff7a6b"))
