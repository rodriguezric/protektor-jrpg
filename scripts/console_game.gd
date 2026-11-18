class_name ConsoleGame
extends Node2D
## One cartridge for the Starbox home console (ConsoleScreen). A game draws
## itself into the console's 144x80 screen, which the console shows at 2x
## with scanlines, so everything here is chunky on purpose.
##
## Subclasses override begin() (reset for a new run), step(delta) (one frame
## of play) and _draw(); they raise `score`, and call end() when the run is
## over. `stats` collects extra numbers for achievements (best values are
## kept per game, see Achievements.console_result).
## Controls: arrows / stick move, Z (A) and X (B) act. P / Esc / MENU pause.

signal over(score: int)

const W := 144
const H := 80

var score := 0
var t := 0.0
var done := false
var paused := false
var stats := {}
var hud: Label


func _ready() -> void:
	hud = Art.label("", Pal.WHITE)
	hud.position = Vector2(2, 0)
	hud.z_index = 10
	add_child(hud)
	begin()


func begin() -> void:
	pass


func step(_delta: float) -> void:
	pass


func hud_text() -> String:
	return "%06d" % score


func end() -> void:
	if done:
		return
	done = true
	over.emit(score)


func _process(delta: float) -> void:
	if paused or done:
		return
	t += delta
	step(delta)
	hud.text = hud_text()
	queue_redraw()


# ------------------------------------------------------------- helpers ---

static func pressed(action: String) -> bool:
	return Input.is_action_just_pressed(action)


static func held(action: String) -> bool:
	return Input.is_action_pressed(action)


static func stick() -> Vector2:
	var v := Vector2(Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up"))
	return v.limit_length(1.0)


func stat_max(key: String, v: int) -> void:
	stats[key] = maxi(int(stats.get(key, 0)), v)


func box(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(floorf(x), floorf(y), w, h), c)


func blip(pitch: float = 1.0, db: float = -10.0) -> void:
	Sfx.play("blip", pitch, db)
