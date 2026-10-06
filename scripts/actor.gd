class_name Actor
extends Node2D
## A walking character on the field. Origin = feet. Scripted scenes drive it with
## walk_to / hop / emote; the field drives the player with input.

const DIRS := [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT]

var spec: Dictionary = {}
var dir := 0
var frame := 0
var moving := false
var anim_t := 0.0
var sprite: Sprite2D
var shadow: Sprite2D
var info: Dictionary = {}
var home_tile := Vector2i.ZERO
var walk_target: Variant = null
var wander_t := 0.0
var mood := ""
var pose := "walk"
var bubble: Sprite2D
var lift := 0.0
var walk_speed := 50.0
var bot := false
var walk_id := 0
## True while a script is walking this actor; the field leaves its animation alone.
var scripted := false


func _init(p_spec: Dictionary = {}) -> void:
	spec = p_spec
	shadow = Sprite2D.new()
	shadow.texture = Art.shadow(14, 5)
	shadow.modulate = Color(1, 1, 1, 0.28)
	shadow.position = Vector2(0, -1)
	add_child(shadow)
	sprite = Sprite2D.new()
	sprite.centered = false
	add_child(sprite)
	wander_t = randf_range(1.0, 3.0)
	refresh()


func set_spec(s: Dictionary) -> void:
	spec = s
	refresh()


func face(d: int) -> void:
	if d != dir:
		dir = d
		refresh()


func face_toward(p: Vector2) -> void:
	var v := p - position
	if absf(v.x) > absf(v.y):
		face(2 if v.x > 0 else 3)
	else:
		face(0 if v.y > 0 else 1)


func set_mood(m: String) -> void:
	mood = m
	refresh()


func set_pose(p: String) -> void:
	pose = p
	refresh()


func refresh() -> void:
	if bot:
		sprite.texture = Art.prop("bot", frame % 2)
		sprite.offset = Vector2(-8, -13 - lift)
		return
	var td: int = [0, 1, 2, 2][dir]
	sprite.texture = Art.person(spec, td, frame if pose == "walk" else 0, mood, pose)
	if pose == "lie":
		sprite.offset = Vector2(-16, -20 - lift)
	else:
		sprite.offset = Vector2(-16, -31 - lift)
	sprite.flip_h = dir == 3


func _process(delta: float) -> void:
	if moving:
		anim_t += delta * 8.0
		var f := int(anim_t) % 4
		if f != frame:
			frame = f
			refresh()
	elif frame != 0:
		frame = 0
		anim_t = 0.0
		refresh()
	if bot:
		anim_t += delta
		var f2 := int(anim_t * 2.0) % 2
		if f2 != frame:
			frame = f2
			refresh()


# ------------------------------------------------------------- scripting ---

func stop_walk() -> void:
	walk_id += 1
	moving = false
	scripted = false


func walk_to(points: Array, speed: float = -1.0) -> bool:
	## Walks through world positions (Vector2) in order. Returns false if
	## another walk (or stop_walk) interrupted it.
	if speed < 0.0:
		speed = walk_speed
	walk_id += 1
	var my := walk_id
	scripted = true
	for p in points:
		var target: Vector2 = p
		while position.distance_to(target) > 0.5:
			if my != walk_id or not is_inside_tree():
				if my == walk_id:
					scripted = false
				return false
			var v := target - position
			if absf(v.x) > absf(v.y):
				face(2 if v.x > 0 else 3)
			else:
				face(0 if v.y > 0 else 1)
			moving = true
			var step := minf(speed * get_process_delta_time(), v.length())
			position += v.normalized() * step
			await get_tree().process_frame
		if my != walk_id:
			return false
		position = target
	moving = false
	scripted = false
	return true


func hop(height: float = 4.0, t: float = 0.22) -> void:
	var tw := create_tween()
	tw.tween_method(_set_lift, 0.0, height, t * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_method(_set_lift, height, 0.0, t * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished


func _set_lift(v: float) -> void:
	lift = v
	sprite.offset.y = (-20.0 if pose == "lie" else -31.0) - lift
	if bot:
		sprite.offset.y = -13 - lift


func emote(kind: String, hold: float = 1.2) -> void:
	## Pops a bubble over the head; doesn't block.
	if bubble:
		bubble.queue_free()
	bubble = Sprite2D.new()
	bubble.texture = Art.ui("emote_" + kind)
	bubble.position = Vector2(5, -38)
	bubble.z_index = 20
	add_child(bubble)
	bubble.scale = Vector2(0.2, 0.2)
	var b := bubble
	Sfx.play("pop", 1.0 + randf() * 0.2, -14.0)
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2(1.2, 1.2), 0.08)
	tw.tween_property(b, "scale", Vector2.ONE, 0.08)
	tw.tween_interval(hold)
	tw.tween_property(b, "modulate:a", 0.0, 0.2)
	tw.tween_callback(b.queue_free)


func shake(t: float = 0.3, amp: float = 1.0) -> void:
	var tw := create_tween()
	var n := int(t / 0.04)
	for i in n:
		tw.tween_property(sprite, "position:x", amp * (1 if i % 2 == 0 else -1), 0.04)
	tw.tween_property(sprite, "position:x", 0.0, 0.04)
