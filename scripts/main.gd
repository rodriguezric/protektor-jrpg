extends Node
## Root: owns the field, missions, cinematics, dialog, fades and the field menu.
## The story itself lives in Story (story*.gd); main is the stage it plays on.

const WIPE_SHADER := """
shader_type canvas_item;
uniform float progress = 0.0;
uniform vec4 tint : source_color = vec4(0.17, 0.21, 0.31, 1.0);
void fragment() {
	vec2 p = floor(FRAGCOORD.xy);
	vec2 cell = fract(p / 16.0) - 0.5;
	float d = abs(cell.x) + abs(cell.y);
	float sweep = (p.x + p.y * 0.6) / 428.0;
	float t = progress * 2.0 - sweep;
	COLOR = vec4(tint.rgb, step(d, t));
}
"""

var world: World
var world_root: Node2D
var mission_layer: CanvasLayer
var cine_layer: CanvasLayer
var ui: CanvasLayer
var dialog: DialogBox
var fade_rect: ColorRect
var wipe: ColorRect
var story: Story
var shake_t := 0.0
var shake_amt := 0.0


func _ready() -> void:
    Game.main = self
    _setup_input()
    world_root = Node2D.new()
    add_child(world_root)
    mission_layer = CanvasLayer.new()
    mission_layer.layer = 5
    add_child(mission_layer)
    cine_layer = CanvasLayer.new()
    cine_layer.layer = 8
    add_child(cine_layer)
    ui = CanvasLayer.new()
    ui.layer = 10
    add_child(ui)
    dialog = DialogBox.new()
    ui.add_child(dialog)
    wipe = ColorRect.new()
    wipe.set_anchors_preset(Control.PRESET_FULL_RECT)
    wipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var sh := Shader.new()
    sh.code = WIPE_SHADER
    var mat := ShaderMaterial.new()
    mat.shader = sh
    wipe.material = mat
    ui.add_child(wipe)
    fade_rect = ColorRect.new()
    fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
    fade_rect.color = Color(Pal.INK, 0.0)
    fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(fade_rect)
    story = Story.new()
    add_child(story)
    if OS.get_environment("PK_TEST") != "":
        add_child(load("res://tools/autotest.gd").new())
        return
    var test_mission := _arg("--mission=")
    if test_mission != "":
        test_level(test_mission)
        return
    title()


func _arg(prefix: String) -> String:
    for a in OS.get_cmdline_user_args():
        if a.begins_with(prefix):
            return a.substr(prefix.length())
    return ""


func test_level(level_id: String) -> void:
    ## ./run_mission <name>: play one mission straight away, again and again.
    ## Esc > Abort mission quits. Nothing is saved.
    Game.testing = true
    Game.player_name = "Tester"
    Game.chapter = "hub"
    # loadout flags: --weapon=beam --cooldown=3 --armor=2 --missile --shield, or --upgrades=max
    var user_args := OS.get_cmdline_user_args()
    var maxed := _arg("--upgrades=") == "max"
    Game.story.weapons = ["basic", "wave", "beam", "auto"]
    Game.story.weapon = _arg("--weapon=") if _arg("--weapon=") != "" else ("basic")
    Game.story.upgrades.cooldown = 3 if maxed else int(_arg("--cooldown=")) if _arg("--cooldown=") != "" else 0
    Game.story.upgrades.armor = 3 if maxed else int(_arg("--armor=")) if _arg("--armor=") != "" else 0
    if maxed or user_args.has("--missile"):
        Game.story.specials.append("missile")
    if maxed or user_args.has("--shield"):
        Game.story.specials.append("ext_shield")
    var tdata := {}
    if level_id.begins_with("training_"):
        var bits := level_id.split("_")
        if bits.size() == 3 and Data.TRAINING.has(bits[1]) and bits[2].is_valid_int():
            tdata = Training.build(bits[1], clampi(int(bits[2]) - 1, 0, 2))
    if tdata.is_empty() and not FileAccess.file_exists("res://data/missions/%s.json" % level_id):
        push_error("No mission named '%s' in data/missions/" % level_id)
        get_tree().quit(1)
        return
    var intro := _arg("--intro=") != "off"
    print("[run_mission] playing %s (intro %s). Esc > Abort mission to quit." % [level_id, "on" if intro else "off"])
    while true:
        var res: Dictionary = await start_mission(level_id, true, intro and tdata.is_empty(), null, tdata, not tdata.is_empty())
        print("[run_mission] %s: %s  score=%s" % [level_id, res.get("result", "?"), res.get("score", 0)])
        if res.get("result", "") == "retreat":
            break
    get_tree().quit()


func _setup_input() -> void:
    var binds := {
        "accept": [KEY_Z, KEY_ENTER, KEY_SPACE, KEY_KP_ENTER, KEY_J],
        "cancel": [KEY_X, KEY_ESCAPE, KEY_BACKSPACE],
        "up": [KEY_UP, KEY_W],
        "down": [KEY_DOWN, KEY_S],
        "left": [KEY_LEFT, KEY_A],
        "right": [KEY_RIGHT, KEY_D],
        "run": [KEY_SHIFT],
    }
    var pads := {"accept": [JOY_BUTTON_A, JOY_BUTTON_RIGHT_SHOULDER], "cancel": [JOY_BUTTON_B, JOY_BUTTON_START], "up": [JOY_BUTTON_DPAD_UP],
        "down": [JOY_BUTTON_DPAD_DOWN], "left": [JOY_BUTTON_DPAD_LEFT], "right": [JOY_BUTTON_DPAD_RIGHT], "run": [JOY_BUTTON_X]}
    for action in binds:
        if not InputMap.has_action(action):
            InputMap.add_action(action, 0.3)
        for k in binds[action]:
            var e := InputEventKey.new()
            e.physical_keycode = k
            InputMap.action_add_event(action, e)
        for b in pads.get(action, []):
            var j := InputEventJoypadButton.new()
            j.button_index = b
            InputMap.action_add_event(action, j)
    for pair in [["left", JOY_AXIS_LEFT_X, -1.0], ["right", JOY_AXIS_LEFT_X, 1.0], ["up", JOY_AXIS_LEFT_Y, -1.0], ["down", JOY_AXIS_LEFT_Y, 1.0]]:
        var m := InputEventJoypadMotion.new()
        m.axis = pair[1]
        m.axis_value = pair[2]
        InputMap.action_add_event(pair[0], m)


func _process(delta: float) -> void:
    if shake_t > 0.0:
        shake_t -= delta
        var a := int(ceilf(shake_amt * minf(1.0, shake_t * 4.0)))
        var o := Vector2(randi_range(-a, a), randi_range(-a, a))
        world_root.position = o
        cine_layer.offset = o
    else:
        world_root.position = Vector2.ZERO
        cine_layer.offset = Vector2.ZERO


func shake(amount: float, t: float) -> void:
    shake_amt = maxf(amount, shake_amt if shake_t > 0 else 0.0)
    shake_t = maxf(t, shake_t)


# ------------------------------------------------------------------ title --

func title() -> void:
    Sfx.music("title", 1.5)
    if world:
        world.queue_free()
        world = null
    var t := TitleScreen.new()
    cine_layer.add_child(t)
    await fade_in(0.8)
    var choice: String = await t.run()
    await fade_out(0.5)
    t.queue_free()
    match choice:
        "new":
            Game.load_meta_only()
            Game.new_game()
            await name_entry()
            story.begin("prologue")
        "continue":
            Game.load_save()
            story.begin(Game.chapter)
        "arcade":
            Game.load_meta_only()
            await arcade()


func name_entry() -> void:
    var n := NameEntry.new()
    cine_layer.add_child(n)
    await fade_in(0.4)
    await n.run()
    await fade_out(0.4)
    n.queue_free()


func arcade() -> void:
    ## Free Missions: replay any unlocked planet outside the story.
    while true:
        var pick: String = await starmap(true)
        if pick == "":
            break
        await start_mission(pick, true)
    await fade_out(0.3)
    title()


# ------------------------------------------------------------- field flow --

func load_map(map_def: Dictionary, tile: Vector2i, dir: int) -> World:
    if world:
        world.queue_free()
    world = World.new()
    world_root.add_child(world)
    world.setup(map_def, tile, dir, story)
    return world


func change_map(map_def: Dictionary, tile: Vector2i, dir: int, t: float = 0.3) -> World:
    await fade_out(t)
    load_map(map_def, tile, dir)
    await fade_in(t)
    return world


func wipe_in() -> void:
    var mat := wipe.material as ShaderMaterial
    var tw := create_tween()
    tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("progress", v), 0.0, 1.0, 0.5)
    await tw.finished


func wipe_out() -> void:
    var mat := wipe.material as ShaderMaterial
    var tw := create_tween()
    tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("progress", v), 1.0, 0.0, 0.45)
    await tw.finished


func start_mission(level_id: String, arcade_mode: bool = false, intro: bool = true, cover: CanvasItem = null, data: Dictionary = {}, training_mode: bool = false) -> Dictionary:
    ## Plays one mission JSON. Returns {result, score, ...}.
    ## cover: a cinematic still on screen; the mission starts beneath it and the
    ## cover dissolves away, so there is no cut or flash into the warp.
    if world:
        world.visible = false
        world.paused = true
    var m := Mission.new()
    mission_layer.add_child(m)
    m.setup(level_id, arcade_mode, intro, data, training_mode)
    await get_tree().process_frame
    if cover:
        var ct := cover.create_tween()
        ct.tween_property(cover, "modulate:a", 0.0, 0.5)
        ct.tween_callback(cover.queue_free)
    if fade_rect.color.a > 0.0:
        await fade_in(0.2)
    var res: Dictionary = await m.run()
    await fade_out(0.6)
    m.queue_free()
    if world:
        world.visible = true
        world.paused = false
    return res


func training() -> void:
    ## The sim pods: pick a drill, run it, come back to the module select.
    if world:
        world.paused = true
    while true:
        await fade_out(0.35)
        var tr := Training.new()
        cine_layer.add_child(tr)
        Sfx.music("level_select", 1.0)
        await fade_in(0.35)
        var pick: Dictionary = await tr.run()
        await fade_out(0.35)
        tr.queue_free()
        if pick.is_empty():
            break
        var data := Training.build(pick.module, pick.tier)
        var res: Dictionary = await start_mission(data.level_id, false, false, null, data, true)
        if res.get("result", "") == "win":
            Game.story.training[pick.module] = maxi(Game.training_level(pick.module), int(pick.tier) + 1)
            Game.save()
    if world:
        world.paused = false
        world.visible = true
    Sfx.music("low_mechanical_ambient", 1.0)
    await fade_in(0.35)


func workshop() -> void:
    if world:
        world.paused = true
    await fade_out(0.3)
    var w := Workshop.new()
    ui.add_child(w)
    await fade_in(0.3)
    await w.run()
    await fade_out(0.3)
    w.queue_free()
    if world:
        world.paused = false
    await fade_in(0.3)


func starmap(arcade_mode: bool = false, first_time: bool = false) -> String:
    if world:
        world.paused = true
    await fade_out(0.35)
    var s := StarMap.new()
    cine_layer.add_child(s)
    s.setup(arcade_mode, first_time)
    await fade_in(0.35)
    var pick: String = await s.run()
    await fade_out(0.35)
    s.queue_free()
    if world:
        world.paused = false
    if pick == "":
        await fade_in(0.3)
    return pick


func fade_out(t: float = 0.3, c: Color = Pal.INK) -> void:
    fade_rect.color = Color(c, fade_rect.color.a)
    var tw := create_tween()
    tw.tween_property(fade_rect, "color:a", 1.0, t)
    await tw.finished


func fade_in(t: float = 0.3) -> void:
    var tw := create_tween()
    tw.tween_property(fade_rect, "color:a", 0.0, t)
    await tw.finished


func flash(c: Color, t: float, a: float = 0.85) -> void:
    fade_rect.color = Color(c, a)
    var tw := create_tween()
    tw.tween_property(fade_rect, "color:a", 0.0, t)
    await tw.finished
    fade_rect.color = Color(Pal.INK, 0.0)


func wait(t: float) -> void:
    await get_tree().create_timer(t).timeout


# ------------------------------------------------------------- field menu --

func field_menu() -> void:
    world.paused = true
    Sfx.play("confirm")
    var panel := PilotStatus.new()
    ui.add_child(panel)
    var r: String = await panel.run()
    panel.queue_free()
    if r == "title":
        await fade_out(0.4)
        title()
        return
    world.paused = false
