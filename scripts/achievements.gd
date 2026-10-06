class_name Achievements
## Every achievement, and the checks that award them. Progress lives in Game
## (achieved + stats) and is saved to its own file, so it survives new games.

const SHOT_TIERS := [10, 25, 50, 100, 250]
const BLOCK_TIERS := [10, 25, 50, 100, 250]
const ROMAN := ["I", "II", "III", "IV", "V"]
const ENDING_NAMES := {
	"partial_pala": ["Somewhere Quiet", "Escape with Pala."],
	"partial_parents": ["The Kitchen Light", "Go home with your parents."],
	"full_synchronization": ["Ready for a New Child", "Reach full synchronization."],
	"full_synchronization_parents": ["They Came Anyway", "Reach full synchronization with your parents waiting."],
	"ascended": ["Beyond the Academy", "Ascend."],
}

## Categories, in tab order.
const CATS := ["combat", "worlds", "story", "protektor"]
const CAT_NAMES := {"combat": "COMBAT", "worlds": "WORLDS", "story": "STORY", "protektor": "PROTEKTOR"}


static func defs() -> Array:
	if Engine.has_meta("pk_achievement_defs"):
		return Engine.get_meta("pk_achievement_defs")
	var d := []
	for i in SHOT_TIERS.size():
		d.append({"id": "aim_%d" % SHOT_TIERS[i], "cat": "combat", "icon": "aim", "tier": i,
			"name": "Dead Eye " + ROMAN[i], "desc": "Land %d shots in a row without a miss." % SHOT_TIERS[i],
			"stat": "best_shot_streak", "target": SHOT_TIERS[i]})
	for i in BLOCK_TIERS.size():
		d.append({"id": "block_%d" % BLOCK_TIERS[i], "cat": "combat", "icon": "block", "tier": i,
			"name": "Bulwark " + ROMAN[i], "desc": "Block %d threats in a row without taking a hit." % BLOCK_TIERS[i],
			"stat": "best_block_chain", "target": BLOCK_TIERS[i]})
	d.append({"id": "flawless_1", "cat": "combat", "icon": "flawless", "tier": 0, "name": "Untouched",
		"desc": "Clear a mission without taking damage."})
	d.append({"id": "flawless_l3", "cat": "combat", "icon": "flawless", "tier": 1, "name": "Untouchable",
		"desc": "Clear a level 3 mission without taking damage."})
	d.append({"id": "flawless_10", "cat": "combat", "icon": "flawless", "tier": 2, "name": "Pristine Record",
		"desc": "Clear 10 missions without taking damage.", "stat": "flawless_count", "target": 10})
	for p in Data.PLANETS:
		var nm: String = Data.PLANET_INFO[p].name
		if p != "terra_virex":
			d.append({"id": "unlock_" + p, "cat": "worlds", "icon": "unlock", "planet": p, "name": "Coordinates: " + nm,
				"desc": "Unlock %s on the star map." % nm})
		d.append({"id": "clear_" + p, "cat": "worlds", "icon": "clear", "planet": p, "name": nm + " Secured",
			"desc": "Clear all three levels of %s." % nm})
	for e in ENDING_NAMES:
		d.append({"id": "ending_" + e, "cat": "story", "icon": "ending_" + e, "name": ENDING_NAMES[e][0], "desc": ENDING_NAMES[e][1]})
	d.append({"id": "all_endings", "cat": "story", "icon": "all_endings", "name": "Every Version of You",
		"desc": "See all five endings.", "stat": "endings_seen", "target": 5})
	d.append({"id": "no_upgrades", "cat": "story", "icon": "no_upgrades", "name": "As They Made You",
		"desc": "Reach an ending without buying a single upgrade."})
	d.append({"id": "all_training", "cat": "protektor", "icon": "training", "name": "Top of the Class",
		"desc": "Clear every training module at every tier.", "stat": "training_tiers", "target": 9})
	d.append({"id": "all_upgrades", "cat": "protektor", "icon": "upgrades", "name": "Fully Outfitted",
		"desc": "Own every upgrade, special and weapon.", "stat": "upgrades_owned", "target": 11})
	Engine.set_meta("pk_achievement_defs", d)
	return d


static func find(id: String) -> Dictionary:
	for a in defs():
		if a.id == id:
			return a
	return {}


# ---------------------------------------------------------------- stats ---

static func stat(name: String) -> int:
	match name:
		"endings_seen":
			var seen := {}
			for h in Game.history:
				seen[str(h.get("ending", ""))] = true
			var n := 0
			for e in ENDING_NAMES:
				if seen.has(e):
					n += 1
			return n
		"training_tiers":
			var t := 0
			for m in Data.TRAINING_MODULES:
				t += Game.training_level(m)
			return t
		"upgrades_owned":
			var n := Game.upgrade_level("cooldown") + Game.upgrade_level("armor")
			for s in ["ext_shield", "missile"]:
				if Game.has_special(s):
					n += 1
			for w in ["wave", "beam", "auto"]:
				if Game.has_weapon(w):
					n += 1
			return n
	return int(Game.achv_stats.get(name, 0))


static func progress(a: Dictionary) -> Array:
	## [current, target] for achievements that count toward something.
	if not a.has("stat"):
		return []
	return [mini(stat(a.stat), int(a.target)), int(a.target)]


# ---------------------------------------------------------------- checks ---

static func check() -> void:
	## Award anything whose condition now holds. Cheap; call it after progress.
	for a in defs():
		if Game.has_achievement(a.id):
			continue
		if _met(a):
			Game.unlock_achievement(a.id)


static func _met(a: Dictionary) -> bool:
	var id: String = a.id
	if a.has("stat") and a.has("target"):
		return stat(a.stat) >= int(a.target)
	if id.begins_with("unlock_"):
		return Game.is_planet_unlocked(a.planet)
	if id.begins_with("clear_"):
		return Game.highest(a.planet) >= 3 or int(Game.arcade.get(a.planet, 0)) >= 3
	if id.begins_with("ending_"):
		for h in Game.history:
			if "ending_" + str(h.get("ending", "")) == id:
				return true
		return false
	match id:
		"flawless_1":
			return int(Game.achv_stats.get("flawless_count", 0)) >= 1
		"flawless_l3":
			return int(Game.achv_stats.get("flawless_l3", 0)) >= 1
		"no_upgrades":
			return int(Game.achv_stats.get("clean_endings", 0)) >= 1
	return false


# ------------------------------------------------------- mission tracking ---

static func shot_hit() -> void:
	var s := int(Game.achv_stats.get("shot_streak", 0)) + 1
	Game.achv_stats.shot_streak = s
	if s > int(Game.achv_stats.get("best_shot_streak", 0)):
		Game.achv_stats.best_shot_streak = s
		if SHOT_TIERS.has(s):
			check()


static func shot_missed() -> void:
	Game.achv_stats.shot_streak = 0


static func blocked() -> void:
	var c := int(Game.achv_stats.get("block_chain", 0)) + 1
	Game.achv_stats.block_chain = c
	if c > int(Game.achv_stats.get("best_block_chain", 0)):
		Game.achv_stats.best_block_chain = c
		if BLOCK_TIERS.has(c):
			check()


static func took_damage() -> void:
	Game.achv_stats.block_chain = 0


static func mission_cleared(level: int, hits_taken: int) -> void:
	if hits_taken == 0:
		Game.achv_stats.flawless_count = int(Game.achv_stats.get("flawless_count", 0)) + 1
		if level >= 3:
			Game.achv_stats.flawless_l3 = int(Game.achv_stats.get("flawless_l3", 0)) + 1
	Game.save_achievements()
	check()
