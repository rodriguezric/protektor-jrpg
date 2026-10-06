extends Node
## Game state autoload: the pilot, story choices and Protektor's progression rules
## (ported from MissionProgress: unlocks, relationships, Midas, endings).

const SAVE_PATH := "user://protektor_jrpg_save.json"
const PILOTS := ["hiro", "pala", "midas"]
const LEVELS := 3
const FAILURE_ENDING_COUNT := 3

var main: Node
var player_name := "Ari"
var look := 0
var vars := {}
var story := {}
var unlocked: Array = ["terra_virex"]
var seen: Array = ["terra_virex"]
var arcade := {}
var games_completed := 0
var history: Array = []
var chapter := "prologue"
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	new_game()


func new_game() -> void:
	vars = {}
	story = {
		"completed_levels": {}, "relationships": {"hiro": 0, "pala": 0, "midas": 0}, "conversations": [],
		"home_contacts": 0, "midas_dead": false, "midas_death_announced": false, "midas_death_response": "",
		"missions_failed": 0, "home_unavailable": false, "pala_unavailable": false, "pala_escape_chosen": false,
		"story_ending_requested": false, "interval_used": false, "interval_count": 0, "last_mission": "",
		"terminal_seen": false, "deployments": 0,
	}
	chapter = "prologue"
	unlocked = ["terra_virex"]


# ------------------------------------------------------------------ pilot ---

func player_spec(outfit: String = "") -> Dictionary:
	var l: Dictionary = Data.LOOKS[look]
	var s := l.duplicate()
	s.id = "player%d" % look
	s.name = player_name
	s.voice = "child"
	if outfit == "":
		outfit = "home" if chapter == "prologue" else "academy"
	if outfit == "home":
		s.top = Pal.SAGE.lerp(Pal.TEAL, 0.3)
		s.hood = true
		s.hoodc = Pal.SAGE
		s.bottom = Pal.SLATE
		s.variant = "home"
	else:
		s.top = Pal.ROSE.lerp(Pal.SLATE, 0.35)
		s.hood = true
		s.hoodc = Pal.ROSE.lerp(Pal.SLATE, 0.2)
		s.jacket = Data.JACKET
		s.bottom = Pal.INK2.lerp(Pal.SLATE, 0.4)
		s.badge = outfit != "parade"
		s.variant = outfit
	s.shoes = Pal.BARK
	var sp := sync_percent()
	if sp >= 75:
		s.hollow = true
	return s


func cast(id: String) -> Dictionary:
	## Cast spec, aged by the story (Hiro empties out as he synchronizes).
	if id == "player":
		return player_spec()
	var s: Dictionary = Data.CAST[id].duplicate()
	if id == "hiro":
		var r := relationship("hiro")
		if r >= 1:
			s.smile = false
		if r >= 3:
			s.hollow = true
		s.variant = "r%d" % mini(r, 3)
	return s


func sync_percent() -> int:
	## Cosmetic pilot-status readout (GDD 11.1): missions and Hiro pull it up,
	## Pala, home and Midas keep you human.
	var v := 12 + completed_count() * 4 + relationship("hiro") * 7 - relationship("pala") * 3 - home_contacts() * 3 - relationship("midas") * 2
	v += int(story.get("missions_failed", 0)) * 2
	return clampi(v, 3, 99)


func stage_name() -> String:
	var p := sync_percent()
	if p < 30:
		return "Familiarity"
	if p < 55:
		return "Addiction"
	if p < 80:
		return "Desensitization"
	return "Vegetation"


# --------------------------------------------------------------- progress ---

func completed_levels() -> Dictionary:
	return story.completed_levels


func highest(planet: String) -> int:
	return int(story.completed_levels.get(planet, 0))


func completed_count() -> int:
	var t := 0
	for v in story.completed_levels.values():
		t += int(v)
	return t


func is_planet_unlocked(planet: String) -> bool:
	return unlocked.has(planet)


func is_level_unlocked(planet: String, level: int, arcade_mode: bool = false) -> bool:
	if not (seen.has(planet) if arcade_mode else is_planet_unlocked(planet)):
		return false
	if level <= 1:
		return true
	var h: int = int(arcade.get(planet, 0)) if arcade_mode else highest(planet)
	return h >= level - 1


func mark_completed(planet: String, level: int, arcade_mode: bool = false) -> Array:
	## Returns newly unlocked planets.
	if arcade_mode:
		arcade[planet] = maxi(int(arcade.get(planet, 0)), level)
		save()
		return []
	story.completed_levels[planet] = maxi(highest(planet), level)
	var before := unlocked.duplicate()
	if highest("terra_virex") >= 2:
		_unlock("glacien_ix")
		_unlock("ignara_prime")
	if completed_count() >= 5:
		_unlock("tempestris")
	if highest("tempestris") >= 2:
		_unlock("viscera_nova")
	var fresh := []
	for p in unlocked:
		if not before.has(p):
			fresh.append(p)
	save()
	return fresh


func _unlock(planet: String) -> bool:
	if unlocked.has(planet) or not Data.PLANETS.has(planet):
		return false
	unlocked.append(planet)
	if not seen.has(planet):
		seen.append(planet)
	return true


func unlock_planet(planet: String) -> bool:
	var r := _unlock(planet)
	save()
	return r


func record_failure() -> void:
	story.missions_failed = int(story.missions_failed) + 1
	save()


func has_failure_ending() -> bool:
	return int(story.missions_failed) >= FAILURE_ENDING_COUNT


func all_levels_done() -> bool:
	for p in Data.PLANETS:
		if highest(p) < LEVELS:
			return false
	return true


func relationship(pilot: String) -> int:
	return int(story.relationships.get(pilot, 0))


func home_contacts() -> int:
	return int(story.home_contacts)


func record_conversation(choice: String, response: String = "") -> void:
	story.conversations.append({"choice": choice, "response": response, "mission": completed_count()})
	if PILOTS.has(choice):
		story.relationships[choice] = relationship(choice) + 1
		if choice == "midas" and relationship("midas") >= 2:
			story.midas_dead = true
	elif choice == "home":
		story.home_contacts = home_contacts() + 1
	save()


func midas_dead() -> bool:
	return bool(story.midas_dead) or relationship("midas") >= 2


func ending_type() -> String:
	if bool(story.pala_escape_chosen):
		return "partial_pala"
	if home_contacts() >= 2 and story.get("home_escape", false):
		return "partial_parents"
	if home_contacts() >= 2:
		return "partial_parents"
	if relationship("hiro") >= 2:
		return "full_synchronization"
	return "full_synchronization_parents" if home_contacts() > 0 else "full_synchronization"


func automatic_ending_type() -> String:
	return "ascended" if all_levels_done() else "full_synchronization"


func complete_story(ending: String) -> void:
	history.append({"ending": ending, "missions": completed_count(), "failed": story.missions_failed, "at": int(Time.get_unix_time_from_system())})
	games_completed += 1
	chapter = "done"
	save()


# ------------------------------------------------------------------- save ---

func save() -> void:
	var data := {"player_name": player_name, "look": look, "vars": vars, "story": story, "unlocked": unlocked,
		"arcade": arcade, "seen": seen, "games_completed": games_completed, "history": history, "chapter": chapter}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func has_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var d = _read()
	return d is Dictionary and str(d.get("chapter", "")) not in ["", "done", "prologue"]


func has_any_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func _read():
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return null
	return JSON.parse_string(f.get_as_text())


func load_save() -> bool:
	var d = _read()
	if not (d is Dictionary):
		return false
	new_game()
	player_name = str(d.get("player_name", "Ari"))
	look = int(d.get("look", 0))
	vars = d.get("vars", {})
	var st: Dictionary = d.get("story", {})
	for k in st:
		story[k] = st[k]
	for k in ["hiro", "pala", "midas"]:
		story.relationships[k] = int(story.relationships.get(k, 0))
	unlocked = d.get("unlocked", ["terra_virex"])
	arcade = d.get("arcade", {})
	seen = d.get("seen", ["terra_virex"])
	games_completed = int(d.get("games_completed", 0))
	history = d.get("history", [])
	chapter = str(d.get("chapter", "prologue"))
	return true


func load_meta_only() -> void:
	## Keeps cross-playthrough data (arcade unlocks, endings seen) for a new game.
	var d = _read()
	if d is Dictionary:
		arcade = d.get("arcade", {})
		seen = d.get("seen", ["terra_virex"])
		games_completed = int(d.get("games_completed", 0))
		history = d.get("history", [])
