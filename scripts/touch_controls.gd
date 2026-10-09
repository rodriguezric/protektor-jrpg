class_name TouchControls
extends Control
## On-screen controls for phones and tablets, drawn at window resolution by the
## Shell (ported from Pumpkin Man). They press the game's own input actions
## (accept / cancel / up / down / left / right / run), so every screen works
## with them unchanged.
##
## - Hidden until the first touch; fade out again when a key or gamepad button
##   is used, so desktop players never see them.
## - Wide screens: the controls live in the side bars beside the game.
##   16:9 screens: they overlay the corners, semi-transparent.
## - Walking around: a floating joystick (touch anywhere on the left part of
##   the screen; a small push walks, a big push runs), A = OK, and MENU.
## - Tapping the game itself presses OK (advances dialog). Menus and dialog
##   choices are tapped directly: tap a row to select it, tap again to choose.
## - Screens driven by arrows (star map, training, slots...): the joystick
##   steers the cursor, with A and B.
## - Deployments: the joystick aims the Protektor (any angle, not just the
##   eight directions) and tapping anywhere else fires; hold to keep firing.
##   The top-right button pauses.
## - The top-right slot holds one button at a time, the same size either way:
##   MENU (pause), B wherever "back" exists, or nothing at all.

const PAD_ART := 37
## The floating joystick: where it can be summoned (share of screen width
## from the left), the dead centre, and how far to push to run.
const JOY_REGION := 0.45
const JOY_DEAD := 0.2
const JOY_RUN := 0.7
## A direction counts once the stick leans this far toward it (diagonals ok).
const JOY_AXIS := 0.38
## Smallest each control may be, as a share of the screen height, whatever
## room the black side bars leave (they overhang the game if they must).
const MIN_PAD := 0.24
const MIN_BUTTON := 0.12
## A dead ring around every control (share of screen height): touches there
## do nothing, so a thumb that just misses never becomes a confirm.
const GUARD := 0.07
## Screens that are steered with arrows rather than tapped.
const ARROW_SCREENS := ["StarMap", "Training", "SlotScreen", "AchievementsScreen", "NameEntry", "Escape", "Workshop", "PilotStatus", "TitleScreen"]

var active := false
var alpha := 0.0
var in_bars := false
var ck := 4.0
## Each control: {id, rect (window space), hit, guard, art, action, kind}
var controls: Array = []
## Which control each finger is holding, by touch index.
var fingers := {}
## Reference counts per action, so two sources can hold the same action.
var held := {}
## Joystick state: which finger holds it, its ring centre and knob, its size,
## where its ghost rests, and the directions it is pressing.
var joy_finger := -1
var joy_origin := Vector2.ZERO
var joy_knob := Vector2.ZERO
var joy_radius := 1.0
var joy_rest := Vector2.ZERO
var joy_dirs := {}
## When the ring had to shift to stay on screen, the thumb's starting offset
## from its centre, so touching down never counts as a push.
var joy_offset := Vector2.ZERO
var joy_blocked := true
var running := false
## "field" (walking around and every other screen) or "mission" (aim + fire).
var layout := ""
## 0..1: how far controls have faded aside for dialog or a tappable menu, and
## which ones. The top-right slot is handled on its own.
var dialog_fade := 0.0
var hidden_ids: Array = []
## What the shared top-right slot shows: "menu", "b" or "" (nothing).
var slot_mode := ""
var slot_alpha := {"menu": 0.0, "b": 0.0}
var web_unlocked := false


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func shell() -> Shell:
	return Game.shell


# ----------------------------------------------------------------- layout --

func relayout() -> void:
	## Places every control for the current window and layout.
	var sh := shell()
	if sh == null:
		return
	var win := get_viewport_rect().size
	var g := sh.game_rect
	var bar := g.position.x
	var target := maxf(1.0, roundf(win.y * 0.26 / PAD_ART))
	var min_k := ceilf(win.y * MIN_PAD / PAD_ART)
	var in_bar_k := floorf((bar - 8.0) / PAD_ART)
	in_bars = in_bar_k >= target * 0.55
	ck = minf(target, in_bar_k) if in_bars else target
	ck = maxf(ck, min_k)
	var m := 4.0 * ck
	controls.clear()
	var left_c: Vector2
	var right_c: Vector2
	if in_bars:
		left_c = Vector2(bar / 2.0, win.y * 0.62)
		right_c = Vector2(win.x - bar / 2.0, win.y * 0.62)
	else:
		left_c = Vector2(m + PAD_ART * ck / 2.0, win.y - m - PAD_ART * ck / 2.0)
		right_c = Vector2(win.x - m - PAD_ART * ck / 2.0, win.y - m - PAD_ART * ck / 2.0)
	# the shared top-right slot: MENU and B are the same size, same place
	var ss := 21.0 * _scale_for("b")
	var slot_c := Vector2(win.x - bar / 2.0, maxf(win.y * 0.14, m + ss / 2.0)) if in_bars else Vector2(win.x - m - ss / 2.0, m + ss / 2.0)
	_add("menu", slot_c, "menu", "", "menu")
	_add("b", slot_c, "b", "cancel", "button")
	# the joystick isn't a fixed control: it appears where you touch
	joy_rest = left_c
	joy_radius = PAD_ART * ck / 2.0
	if layout != "mission":
		# in a deployment every tap off the stick fires, so there's no A
		var s := 21.0 * _scale_for("a")
		_add("a", right_c + Vector2(s * 0.25, s * 0.1), "a", "accept", "button")
	queue_redraw()


func _scale_for(art: String) -> float:
	## Whole-number scale for a control: its layout size, shrunk to fit a
	## narrow side bar, but never below its minimum share of the screen.
	var tex := Art.ui("t_" + art)
	var win := get_viewport_rect().size
	var sc := roundf(ck)
	if in_bars:
		var bar := shell().game_rect.position.x
		sc = minf(sc, floorf((bar - 6.0) / tex.get_width()))
	return maxf(maxf(1.0, sc), ceilf(win.y * MIN_BUTTON / tex.get_height()))


func _add(id: String, center: Vector2, art: String, action: String, kind: String) -> void:
	var tex := Art.ui("t_" + art)
	var sc := _scale_for(art)
	var sz := tex.get_size() * sc
	var win := get_viewport_rect().size
	var pos := (center - sz / 2.0).round()
	# keep every control fully on screen
	pos = pos.clamp(Vector2(2, 2), win - sz - Vector2(2, 2))
	var r := Rect2(pos, sz)
	var hit := r.grow(r.size.x * 0.12)
	controls.append({"id": id, "rect": r, "hit": hit, "guard": hit.grow(win.y * GUARD), "art": art, "action": action, "kind": kind})


# ------------------------------------------------------------------ drawing --

func _process(delta: float) -> void:
	var want := "mission" if _mission() != null else "field"
	if want != layout:
		_release_all()
		layout = want
		relayout()
	var target := 1.0 if active else 0.0
	if not is_equal_approx(alpha, target):
		alpha = move_toward(alpha, target, delta * 4.0)
		queue_redraw()
	# while dialog is up the pad and buttons step aside (taps advance the
	# text, choices are tapped directly); they return when the box closes
	var want_hidden: Array = []
	if _dialog_up():
		want_hidden = ["pad", "a", "b"]
	elif _menu_up():
		want_hidden = ["pad", "a"]
	elif layout == "field" and not _field_control() and not _arrow_screen():
		# cutscenes and fades: nothing to steer, and a tap still means OK
		want_hidden = ["pad", "a", "b"]
	if not want_hidden.is_empty():
		if want_hidden != hidden_ids:
			if dialog_fade == 0.0 or not hidden_ids.has("pad"):
				_joy_release()
			hidden_ids = want_hidden
			relayout()
	if layout == "mission":
		joy_blocked = want_hidden.has("pad") or not _mission_steerable()
	else:
		joy_blocked = want_hidden.has("pad")
	if joy_blocked and joy_finger >= 0:
		_joy_release()
	var sm := _slot_mode()
	if sm != slot_mode:
		slot_mode = sm
		queue_redraw()
	for k in slot_alpha:
		var t := 1.0 if k == slot_mode else 0.0
		if not is_equal_approx(slot_alpha[k], t):
			slot_alpha[k] = move_toward(slot_alpha[k], t, delta * 6.0)
			queue_redraw()
	var dlg := 1.0 if not want_hidden.is_empty() else 0.0
	if not is_equal_approx(dialog_fade, dlg):
		dialog_fade = move_toward(dialog_fade, dlg, delta * 6.0)
		queue_redraw()
	if dialog_fade == 0.0 and dlg == 0.0 and not hidden_ids.is_empty():
		hidden_ids = []
		relayout()


func _draw() -> void:
	if alpha <= 0.0:
		return
	var a := alpha * (1.0 if in_bars else 0.6)
	for c in controls:
		var ca := a
		if slot_alpha.has(c.id):
			ca *= slot_alpha[c.id]
			if ca <= 0.01:
				continue
		elif hidden_ids.has(c.id):
			ca *= 1.0 - dialog_fade
			if ca <= 0.01:
				continue
		var art: String = c.art
		if fingers.values().has(c.id):
			art += "_on"
		draw_texture_rect(Art.ui("t_" + art), c.rect, false, Color(1, 1, 1, ca))
	_draw_joystick(a)


func _draw_joystick(a: float) -> void:
	## The stick under your thumb while held; otherwise a faint ghost where it
	## usually sits, so you know it's there.
	var base := Art.ui("t_joy_base")
	var knob := Art.ui("t_joy_knob_on" if running else "t_joy_knob")
	var bs := Vector2(joy_radius * 2.0, joy_radius * 2.0)
	var ks := bs * (19.0 / 37.0)
	if joy_finger >= 0:
		draw_texture_rect(base, Rect2((joy_origin - bs / 2.0).round(), bs), false, Color(1, 1, 1, a * 0.85))
		draw_texture_rect(knob, Rect2((joy_knob - ks / 2.0).round(), ks), false, Color(1, 1, 1, a))
		if running:
			draw_arc(joy_origin, joy_radius * 1.08, 0, TAU, 40, Color(Pal.SYNC, 0.4 * a), maxf(1.0, ck * 0.75))
	elif not joy_blocked:
		var g := a * 0.3 * (1.0 - dialog_fade)
		if g > 0.01:
			draw_texture_rect(base, Rect2((joy_rest - bs / 2.0).round(), bs), false, Color(1, 1, 1, g))
			draw_texture_rect(knob, Rect2((joy_rest - ks / 2.0).round(), ks), false, Color(1, 1, 1, g))


# -------------------------------------------------------------------- input --

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_set_active(false)
	elif event is InputEventJoypadButton and event.pressed:
		_set_active(false)
	elif event is InputEventScreenTouch:
		_touch(event)
	elif event is InputEventScreenDrag:
		_drag(event)


func _set_active(on: bool) -> void:
	if on == active:
		return
	active = on
	Game.touch_active = on
	if not on:
		_release_all()
	queue_redraw()


func _touch(e: InputEventScreenTouch) -> void:
	if e.pressed:
		_set_active(true)
		_web_unlock()
		var hit := _hit(e.position)
		var win := get_viewport_rect().size
		if hit.is_empty() and not joy_blocked and joy_finger < 0 and e.position.x < win.x * JOY_REGION:
			# the left part of the screen summons the joystick under the thumb
			fingers[e.index] = "joy"
			joy_finger = e.index
			joy_origin = e.position.clamp(Vector2(joy_radius + 2, joy_radius + 2), win - Vector2(joy_radius + 2, joy_radius + 2))
			joy_offset = e.position - joy_origin
			joy_knob = joy_origin
			Game.buzz(6)
			queue_redraw()
			return
		if hit.is_empty() and layout == "mission" and _mission_steerable():
			# a deployment: every other touch fires, and holding keeps firing
			fingers[e.index] = "fire"
			_press("accept")
			Game.buzz(5)
			return
		if hit.is_empty() and _guarded(e.position):
			# just beside a control (or on an empty bar): ignore it entirely
			fingers[e.index] = "guard"
			return
		if hit.is_empty():
			# the game picture itself: OK (advance dialog, choose, start...)
			fingers[e.index] = "game"
			# menus take the tap first; if one is open and the tap misses it,
			# nothing happens (no accidental confirm)
			match _offer_tap(shell().to_game(e.position)):
				0:
					_press("accept")
					set_meta("accept_%d" % e.index, true)
					Game.buzz(8)
				1:
					Game.buzz(8)
			return
		fingers[e.index] = hit.id
		Game.buzz(10)
		match hit.kind:
			"menu":
				_pause()
			"button":
				_press(hit.action)
	else:
		var id: String = fingers.get(e.index, "")
		fingers.erase(e.index)
		match id:
			"":
				pass
			"joy":
				_joy_release()
			"fire":
				_release("accept")
			"game":
				if get_meta("accept_%d" % e.index, false):
					set_meta("accept_%d" % e.index, false)
					_release("accept")
			"menu", "guard":
				pass
			_:
				for c in controls:
					if c.id == id:
						_release(c.action)
		queue_redraw()


func _drag(e: InputEventScreenDrag) -> void:
	if fingers.get(e.index, "") == "joy":
		_joy_move(e.position)


func _hit(p: Vector2) -> Dictionary:
	if alpha <= 0.01 and not active:
		return {}
	for c in controls:
		if not _shown(c):
			continue
		if (c.hit as Rect2).has_point(p):
			return c
	return {}


func _guarded(p: Vector2) -> bool:
	## True for touches in the dead ring around a control, or on the empty
	## black bars beside the game: these never count as a tap on the game.
	if not shell().game_rect.has_point(p):
		return true
	for c in controls:
		if not _shown(c):
			continue
		if (c.guard as Rect2).has_point(p):
			return true
	return false


func _shown(c: Dictionary) -> bool:
	## Whether a control is currently on screen (and so can be touched).
	if slot_alpha.has(c.id):
		return c.id == slot_mode
	return not (hidden_ids.has(c.id) and dialog_fade > 0.5)


# ------------------------------------------------------------ game state ---

func _main() -> Node:
	var m: Node = Game.main
	return m if m != null and is_instance_valid(m) else null


func _mission() -> Mission:
	var m := _main()
	if m == null:
		return null
	for c in m.mission_layer.get_children():
		if c is Mission and not c.is_queued_for_deletion():
			return c
	return null


func _mission_steerable() -> bool:
	## The deployment is live: aiming and firing mean something.
	var ms := _mission()
	return ms != null and ms.running and ms.alive and not ms.finished and not ms.paused


func _dialog_up() -> bool:
	var m := _main()
	return m != null and m.dialog.visible


func _field_control() -> bool:
	## The player is walking around: the one time MENU and the stick are for
	## the field itself.
	var m := _main()
	if m == null or m.dialog.visible or m.fade_rect.color.a > 0.5:
		return false
	var w: World = m.world
	if w == null or not is_instance_valid(w) or not w.is_visible_in_tree() or w.busy or w.paused or not w.player.visible:
		return false
	if _mission() != null:
		return false
	for c in m.cine_layer.get_children():
		if c is CanvasItem and c.visible:
			return false
	for c in m.ui.get_children():
		if _is_arrow_screen(c):
			return false
	return true


func _is_arrow_screen(n: Node) -> bool:
	if not (n is CanvasItem and n.visible) or n.is_queued_for_deletion():
		return false
	var sc: Script = n.get_script()
	return sc != null and ARROW_SCREENS.has(sc.get_global_name())


func _arrow_screen() -> bool:
	## A screen steered with arrows is open (the stick moves its cursor).
	var m := _main()
	if m == null:
		return false
	for layer in [m.cine_layer, m.ui]:
		for c in layer.get_children():
			if _is_arrow_screen(c):
				return true
	return false


func _slot_mode() -> String:
	## MENU while walking around or during a deployment (it pauses); B where
	## "back" means something; nothing during dialog and cutscenes.
	if _dialog_up():
		return ""
	if _menu_up():
		return "b" if _back_available() else ""
	if layout == "mission":
		return "menu" if _mission_steerable() else ""
	if _field_control():
		return "menu"
	if _arrow_screen():
		return "b"
	return ""


func _back_available() -> bool:
	for n in get_tree().get_nodes_in_group("tap_targets"):
		if not is_instance_valid(n) or not n.is_inside_tree():
			continue
		if n is Menu:
			if n.active and n.cancellable:
				return true
		elif not n is CanvasItem or n.is_visible_in_tree():
			return true
	return false


func _menu_up() -> bool:
	## A tappable menu is open (they're operated by tapping instead).
	for n in get_tree().get_nodes_in_group("tap_targets"):
		if is_instance_valid(n) and n.is_inside_tree() and (not n is CanvasItem or n.is_visible_in_tree()):
			return true
	return false


func _offer_tap(game_pos: Vector2) -> int:
	## Offers a tap on the picture to whatever is tappable right now (menus,
	## dialog choices). 0 = nothing tappable, 1 = taken, 2 = missed.
	var targets := get_tree().get_nodes_in_group("tap_targets").filter(func(n: Node) -> bool:
		return is_instance_valid(n) and n.is_inside_tree() and (not n is CanvasItem or n.is_visible_in_tree()))
	if targets.is_empty():
		return 0
	targets.sort_custom(func(a: Node, b: Node) -> bool: return int(a.get_meta("tap_priority", 0)) > int(b.get_meta("tap_priority", 0)))
	for t in targets:
		if t.tap(game_pos):
			return 1
	return 2


static func confirm() -> void:
	## For tap targets: the second tap on a selected row means OK.
	if Game.shell and Game.shell.touch:
		Game.shell.touch._tap("accept")


# ----------------------------------------------------------------- stick ---

func _joy_move(p: Vector2) -> void:
	## In a deployment the stick aims: its exact angle becomes the Protektor's
	## facing. Elsewhere each direction is pressed with a strength from how far
	## the stick leans that way, and pushing past JOY_RUN runs. Drag beyond the
	## ring and the ring follows the thumb.
	p -= joy_offset
	var v := p - joy_origin
	if v.length() > joy_radius:
		joy_origin += v.normalized() * (v.length() - joy_radius)
		v = p - joy_origin
	joy_knob = p
	var k := v.length() / joy_radius
	if layout == "mission":
		Game.touch_aim = v / joy_radius if k > JOY_DEAD else Vector2.ZERO
		queue_redraw()
		return
	var want := {}
	if k > JOY_DEAD:
		var n := v.normalized()
		var push := clampf((k - JOY_DEAD) / (1.0 - JOY_DEAD), 0.0, 1.0)
		for pair in [["right", n.x], ["left", -n.x], ["down", n.y], ["up", -n.y]]:
			if pair[1] > JOY_AXIS:
				want[pair[0]] = clampf(pair[1] * maxf(push, 0.5), 0.4, 1.0)
	for d in ["up", "down", "left", "right"]:
		if want.has(d):
			Input.action_press(d, want[d])
		elif joy_dirs.has(d):
			Input.action_release(d)
	joy_dirs = want
	var run := not want.is_empty() and k >= JOY_RUN and _field_control()
	if run != running:
		running = run
		if run:
			_press("run")
			Game.buzz(12)
		else:
			_release("run")
	queue_redraw()


func _joy_release() -> void:
	for d in joy_dirs:
		Input.action_release(d)
	joy_dirs.clear()
	if running:
		_release("run")
	running = false
	joy_finger = -1
	Game.touch_aim = Vector2.ZERO
	queue_redraw()


func _pause() -> void:
	## Opens the pause menu on the field; in a deployment it pauses; anywhere
	## else it acts as Back.
	var m := _main()
	if m == null:
		return
	if _field_control():
		m.world.run(m.field_menu)
	else:
		_tap("cancel")


func _web_unlock() -> void:
	## Web builds: go fullscreen on the first touch, which counts as the user
	## gesture browsers require.
	if web_unlocked or not OS.has_feature("web"):
		return
	web_unlocked = true
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


# -------------------------------------------------------------- actions ----

func _press(action: String) -> void:
	if action == "":
		return
	held[action] = int(held.get(action, 0)) + 1
	if int(held[action]) == 1:
		Input.action_press(action)


func _release(action: String) -> void:
	if action == "" or not held.has(action):
		return
	held[action] = int(held[action]) - 1
	if int(held[action]) <= 0:
		held.erase(action)
		Input.action_release(action)


func _tap(action: String) -> void:
	## A quick press and release, two frames apart so "just pressed" is seen.
	_press(action)
	await get_tree().process_frame
	await get_tree().process_frame
	_release(action)


func _release_all() -> void:
	for a in held.keys():
		Input.action_release(a)
	held.clear()
	fingers.clear()
	for d in joy_dirs:
		Input.action_release(d)
	joy_dirs.clear()
	joy_finger = -1
	running = false
	Game.touch_aim = Vector2.ZERO
	queue_redraw()
