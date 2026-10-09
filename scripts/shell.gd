class_name Shell
extends Control
## The window. The game itself always renders at 320x180 inside a SubViewport;
## the shell scales that picture up (whole-number steps where it fits, so the
## pixels stay square) and centres it. Whatever window space is left over (the
## side bars on wide phones) belongs to the touch controls, which draw at full
## window resolution around (or over) the game.
## Keyboard, gamepad and mouse events are passed on to the game (mouse
## positions mapped into its 320x180 space), so desktop play is unchanged.
## Touches stay with the touch controls.

const GAME_SIZE := Vector2i(320, 180)

var viewport: SubViewport
var screen: TextureRect
var touch: TouchControls
## Where the game picture sits in the window, and how many window pixels make
## one game pixel.
var game_rect := Rect2()
var game_scale := 1.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Game.shell = self
	var bg := ColorRect.new()
	bg.color = Pal.INK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	viewport = SubViewport.new()
	viewport.size = GAME_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	viewport.snap_2d_transforms_to_pixel = true
	viewport.snap_2d_vertices_to_pixel = true
	viewport.audio_listener_enable_2d = true
	add_child(viewport)
	screen = TextureRect.new()
	screen.texture = viewport.get_texture()
	screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	screen.stretch_mode = TextureRect.STRETCH_SCALE
	screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen)
	viewport.add_child(load("res://scenes/main.tscn").instantiate())
	touch = TouchControls.new()
	add_child(touch)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _layout() -> void:
	var win := get_viewport_rect().size
	var fit := minf(win.x / GAME_SIZE.x, win.y / GAME_SIZE.y)
	# whole-number scaling keeps every pixel the same size; only fall back to a
	# fractional fit when whole numbers would waste a lot of the screen
	var whole := floorf(fit)
	game_scale = whole if whole >= 1.0 and whole / fit >= 0.88 else fit
	var sz := Vector2(GAME_SIZE) * game_scale
	game_rect = Rect2(((win - sz) / 2.0).round(), sz.round())
	screen.position = game_rect.position
	screen.size = game_rect.size
	if touch:
		touch.relayout()


func to_game(window_pos: Vector2) -> Vector2:
	## Window coordinates -> game (320x180) coordinates.
	return (window_pos - game_rect.position) / game_scale


func to_window(game_pos: Vector2) -> Vector2:
	return game_rect.position + game_pos * game_scale


func _input(event: InputEvent) -> void:
	## Hand everything but touches to the game. Mouse events are mapped into
	## the game picture, so aiming with the mouse still points where you point.
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		return
	if event is InputEventMouse:
		var me := event.duplicate() as InputEventMouse
		me.position = to_game(event.position)
		me.global_position = me.position
		if me is InputEventMouseMotion:
			(me as InputEventMouseMotion).relative /= game_scale
		viewport.push_input(me, true)
	else:
		viewport.push_input(event, true)
