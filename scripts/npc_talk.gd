class_name NpcTalk
## What the people you walk up to say (data/npc_talk.json, built by
## tools/build_npc_talk.py). Lines depend on the story so far, move on one
## each time you come back, cycle their last few once used up, and never
## repeat the line just said.

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var f := FileAccess.open("res://data/npc_talk.json", FileAccess.READ)
		if f:
			_data = JSON.parse_string(f.get_as_text())
	return _data


static func has(key: String) -> bool:
	return data().has(key)


static func pool(key: String) -> Array:
	var out := []
	for grp in data().get(key, {}).get("groups", []):
		var ok := true
		for c in grp.get("when", []):
			if not holds(str(c)):
				ok = false
				break
		if ok:
			out.append_array(grp.lines)
	return out


static func holds(c: String) -> bool:
	## One condition from the data file (see tools/build_npc_talk.py).
	for op in [">=", "<"]:
		if c.contains(op):
			var bits := c.split(op)
			var v := _value(bits[0])
			var n := int(bits[1])
			return v >= n if op == ">=" else v < n
	if c.begins_with("letter:"):
		return str(Game.vars.get("letter_choice", "")) == c.trim_prefix("letter:")
	match c:
		"evening":
			return Game.main and Game.main.story and Game.main.story.prologue.evening
		"block7":
			return bool(Game.story.get("block7_seen", false))
		"bracelet":
			return bool(Game.story.get("bracelet", false))
		"midas_dead":
			return Game.midas_dead()
		"midas_alive":
			return not Game.midas_dead()
		"pala_gone":
			return bool(Game.story.get("pala_unavailable", false))
		"won":
			return str(Game.story.get("last_result", "")) == "win"
		"lost":
			return ["lose", "retreat"].has(str(Game.story.get("last_result", "")))
	return false


static func _value(k: String) -> int:
	match k:
		"hiro", "pala", "midas":
			return Game.relationship(k)
		"done":
			return Game.completed_count()
		"sync":
			return Game.sync_percent()
		"home":
			return Game.home_contacts()
		"pong":
			return HubGame.best("pingpong")
	return 0


static func line(key: String, inst: String = "") -> Array:
	## [speaker, text, mood] for this talk, and moves the person on a line.
	var lines := pool(key)
	if lines.is_empty():
		return []
	var ck := key + ("#" + inst if inst != "" else "")
	var talks: Dictionary = Game.story.get("npc_talks", {})
	var n := int(talks.get(ck, 0))
	if inst != "":
		n += absi(inst.hash()) % lines.size()
	var idx := n
	if idx >= lines.size():
		var k := mini(3, lines.size())
		idx = lines.size() - k + (idx - lines.size()) % k
	var last: Dictionary = Game.story.get("npc_last", {})
	if lines.size() > 1 and str(lines[idx][0]) == str(last.get(ck, "")):
		idx = (idx + 1) % lines.size()
	talks[ck] = int(talks.get(ck, 0)) + 1
	Game.story.npc_talks = talks
	last[ck] = str(lines[idx][0])
	Game.story.npc_last = last
	return [str(data()[key].get("speaker", "")), str(lines[idx][0]), str(lines[idx][1]) if lines[idx].size() > 1 else ""]


static func say(s: Story, key: String, inst: String = "") -> bool:
	## Plays this person's next line; false if there's nothing for them.
	var l := line(key, inst)
	if l.is_empty():
		return false
	if l[0] == "":
		await s.say("", "\"%s\"" % l[1] if not l[1].begins_with("A ") and not l[1].begins_with("The ") and not l[1].begins_with("Someone") else l[1])
	else:
		await s.say(l[0], l[1], l[2])
	return true
