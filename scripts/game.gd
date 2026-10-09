extends Node
## Game state autoload: the pilot, story choices and Protektor's progression rules
## (ported from MissionProgress: unlocks, relationships, Midas, endings).

## Three save slots hold playthroughs; the profile holds what carries over
## between them (planet unlocks, Protektor upgrades, Free Missions, endings).
const SLOTS := 3
const LEGACY_SAVE_PATH := "user://protektor_jrpg_save.json"
const PROFILE_PATH := "user://protektor_profile.json"
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
var slot := 1
## Carried between playthroughs. story.upgrades/specials/weapons point into it.
var profile := {}
var rng := RandomNumberGenerator.new()
## Set by ./run_mission: nothing is written to the save file.
var testing := false
## Achievements and their running stats outlive any one playthrough.
const ACH_PATH := "user://protektor_achievements.json"
var achieved := {}
var achv_stats := {}
## The window shell (game picture + touch controls).
var shell: Shell
## Touch: whether on-screen controls are in use, and in a mission the
## floating joystick's aim (a vector up to length 1; zero when released).
var touch_active := false
var touch_aim := Vector2.ZERO


func _ready() -> void:
	rng.randomize()
	_migrate_legacy_save()
	load_profile()
	new_game()
	load_achievements()


func new_game() -> void:
	vars = {}
	story = {
		"completed_levels": {}, "relationships": {"hiro": 0, "pala": 0, "midas": 0}, "conversations": [],
		"home_contacts": 0, "midas_dead": false, "midas_death_announced": false, "midas_death_response": "",
		"missions_failed": 0, "home_unavailable": false, "pala_unavailable": false, "pala_escape_chosen": false,
		"story_ending_requested": false, "interval_used": false, "interval_count": 0, "last_mission": "",
		"terminal_seen": false, "deployments": 0,
		"credits": 0, "medicine": 0, "training": {"block": 0, "shoot": 0, "combo": 0},
		"stripped": false, "bought": false,
	}
	chapter = "prologue"
	_link_profile()


func _link_profile() -> void:
	## Upgrades live in the profile; the story just points at them, so a
	## purchase in any playthrough carries into the next.
	if profile.is_empty():
		profile = _default_profile()
	story.upgrades = profile.upgrades
	story.specials = profile.specials
	story.weapons = profile.weapons
	story.weapon = profile.weapon
	unlocked = profile.unlocked
	seen = profile.unlocked
	arcade = profile.arcade
	history = profile.history
	games_completed = int(profile.games_completed)


func _default_profile() -> Dictionary:
	return {"unlocked": ["terra_virex"], "upgrades": {"cooldown": 0, "armor": 0}, "specials": [], "weapons": ["basic"],
		"weapon": "basic", "arcade": {}, "history": [], "games_completed": 0}


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
		Achievements.check()
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
	Achievements.check()
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
	Achievements.check()
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
	profile.games_completed = games_completed
	chapter = "done"
	save()
	var lo := loadout()
	var bare: bool = int(lo.cooldown) == 0 and int(lo.armor) == 0 and lo.weapon == "basic" and not lo.missile and not lo.ext_shield
	if bare and not bool(story.get("bought", false)):
		achv_stats.clean_endings = int(achv_stats.get("clean_endings", 0)) + 1
	save_achievements()
	Achievements.check()


# --------------------------------------------------------------- loadout ---

func credits() -> int:
	return int(story.get("credits", 0))


func add_credits(n: int) -> void:
	story.credits = credits() + n
	save()


func spend(n: int) -> bool:
	if credits() < n:
		return false
	story.credits = credits() - n
	save()
	return true


func upgrade_level(id: String) -> int:
	return int(story.get("upgrades", {}).get(id, 0))


func has_special(id: String) -> bool:
	return story.get("specials", []).has(id)


func has_weapon(id: String) -> bool:
	return id == "basic" or story.get("weapons", []).has(id)


func equipped_weapon() -> String:
	if bool(story.get("stripped", false)):
		return "basic"
	var w := str(story.get("weapon", "basic"))
	return w if has_weapon(w) else "basic"


func set_weapon(w: String) -> void:
	story.weapon = w
	profile.weapon = w
	save()


func loadout() -> Dictionary:
	## What the Protektor takes into a deployment.
	if bool(story.get("stripped", false)):
		return {"cooldown": 0, "armor": 0, "weapon": "basic", "missile": false, "ext_shield": false}
	return {"cooldown": upgrade_level("cooldown"), "armor": upgrade_level("armor"), "weapon": equipped_weapon(),
		"missile": has_special("missile"), "ext_shield": has_special("ext_shield")}


func training_level(module: String) -> int:
	return int(story.get("training", {}).get(module, 0))


func use_medicine() -> bool:
	## A stabilizer wipes one failure from the record.
	if int(story.get("medicine", 0)) <= 0 or int(story.missions_failed) <= 0:
		return false
	story.medicine = int(story.medicine) - 1
	story.missions_failed = int(story.missions_failed) - 1
	save()
	return true


# ----------------------------------------------------------- achievements ---

func has_achievement(id: String) -> bool:
	return achieved.has(id)


func unlock_achievement(id: String) -> void:
	if testing or achieved.has(id):
		return
	achieved[id] = int(Time.get_unix_time_from_system())
	save_achievements()
	if main and main.has_method("toast_achievement"):
		main.toast_achievement(Achievements.find(id))


func _ach_path() -> String:
	## Test runs can point achievements at a scratch file (PK_ACH).
	return OS.get_environment("PK_ACH") if OS.get_environment("PK_ACH") != "" else ACH_PATH


func save_achievements() -> void:
	if testing:
		return
	var f := FileAccess.open(_ach_path(), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"achieved": achieved, "stats": achv_stats}))


func load_achievements() -> void:
	if not FileAccess.file_exists(_ach_path()):
		return
	var f := FileAccess.open(_ach_path(), FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text()) if f else null
	if d is Dictionary:
		achieved = d.get("achieved", {})
		achv_stats = d.get("stats", {})


# ------------------------------------------------------------------- save ---

func slot_path(n: int) -> String:
	return "user://protektor_slot_%d.json" % n


func save() -> void:
	## Autosaves the active slot and the shared profile.
	if testing:
		return
	profile.weapon = story.get("weapon", "basic")
	var data := {"player_name": player_name, "look": look, "vars": vars, "story": story, "chapter": chapter,
		"saved_at": int(Time.get_unix_time_from_system())}
	var f := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
	save_profile()


func save_profile() -> void:
	if testing:
		return
	var f := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(profile))


func load_profile() -> void:
	profile = _default_profile()
	var d = _read(PROFILE_PATH)
	if d is Dictionary:
		for k in d:
			profile[k] = d[k]
	if not profile.unlocked.has("terra_virex"):
		profile.unlocked.push_front("terra_virex")
	if not profile.weapons.has("basic"):
		profile.weapons.push_front("basic")
	for k in ["cooldown", "armor"]:
		profile.upgrades[k] = int(profile.upgrades.get(k, 0))


func _read(path: String):
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	return JSON.parse_string(f.get_as_text())


func slot_info(n: int) -> Dictionary:
	## A summary for the slot picker, or {} if the slot is empty.
	var d = _read(slot_path(n))
	if not (d is Dictionary):
		return {}
	var st: Dictionary = d.get("story", {})
	var done := 0
	for v in st.get("completed_levels", {}).values():
		done += int(v)
	return {"name": str(d.get("player_name", "?")), "look": int(d.get("look", 0)), "chapter": str(d.get("chapter", "prologue")),
		"missions": done, "credits": int(st.get("credits", 0)), "saved_at": int(d.get("saved_at", 0)), "stripped": bool(st.get("stripped", false))}


func most_recent_slot() -> int:
	var best := 0
	var best_t := -1
	for n in range(1, SLOTS + 1):
		var info := slot_info(n)
		if info.is_empty() or info.chapter == "done":
			continue
		if int(info.saved_at) > best_t:
			best_t = int(info.saved_at)
			best = n
	return best


func has_save() -> bool:
	return most_recent_slot() > 0


func has_any_save() -> bool:
	for n in range(1, SLOTS + 1):
		if not slot_info(n).is_empty():
			return true
	return false


func load_slot(n: int) -> bool:
	var d = _read(slot_path(n))
	if not (d is Dictionary):
		return false
	slot = n
	new_game()
	player_name = str(d.get("player_name", "Ari"))
	look = int(d.get("look", 0))
	vars = d.get("vars", {})
	var st: Dictionary = d.get("story", {})
	for k in st:
		if k in ["upgrades", "specials", "weapons"]:
			continue
		story[k] = st[k]
	for k in ["hiro", "pala", "midas"]:
		story.relationships[k] = int(story.relationships.get(k, 0))
	chapter = str(d.get("chapter", "prologue"))
	_link_profile()
	story.weapon = str(st.get("weapon", profile.weapon))
	return true


func start_new_game(n: int, stripped: bool) -> void:
	slot = n
	new_game()
	story.stripped = stripped


func load_meta_only() -> void:
	## Free Missions and the title use the profile only.
	load_profile()
	new_game()


func _migrate_legacy_save() -> void:
	## Saves from before slots become Slot 1, and seed the profile.
	if not FileAccess.file_exists(LEGACY_SAVE_PATH) or FileAccess.file_exists(PROFILE_PATH):
		return
	var d = _read(LEGACY_SAVE_PATH)
	if not (d is Dictionary):
		return
	var st: Dictionary = d.get("story", {})
	var pr := _default_profile()
	pr.unlocked = d.get("unlocked", ["terra_virex"])
	for p in d.get("seen", []):
		if not pr.unlocked.has(p):
			pr.unlocked.append(p)
	pr.arcade = d.get("arcade", {})
	pr.history = d.get("history", [])
	pr.games_completed = int(d.get("games_completed", 0))
	pr.upgrades = st.get("upgrades", pr.upgrades)
	pr.specials = st.get("specials", [])
	pr.weapons = st.get("weapons", ["basic"])
	pr.weapon = str(st.get("weapon", "basic"))
	var f := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(pr))
	if not FileAccess.file_exists(slot_path(1)):
		d["saved_at"] = int(Time.get_unix_time_from_system())
		var g := FileAccess.open(slot_path(1), FileAccess.WRITE)
		if g:
			g.store_string(JSON.stringify(d))
	DirAccess.rename_absolute(ProjectSettings.globalize_path(LEGACY_SAVE_PATH), ProjectSettings.globalize_path(LEGACY_SAVE_PATH + ".migrated"))


func buzz(ms: int) -> void:
	## A short vibration, only when playing by touch.
	if touch_active:
		Input.vibrate_handheld(ms)
