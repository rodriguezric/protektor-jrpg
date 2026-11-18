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
const CATS := ["combat", "worlds", "bosses", "story", "protektor", "games"]
const CAT_NAMES := {"combat": "COMBAT", "worlds": "WORLDS", "bosses": "BOSSES", "story": "STORY", "protektor": "PROTEKTOR", "games": "GAMES"}

## Starbox cartridges (ConsoleScreen.GAMES) and their achievements: each
## entry is [id suffix, name, description, stat, target, icon tier]. Stats
## are the best value ever reached in one run, kept as cg_<game>_<key>
## (cg_<game>_score is the best score).
const CONSOLE_GAMES := ["protektor", "duel", "sword"]
const GAME_ACH := {
	"protektor": [["s1k", "Rookie Robot", "Score 1,000 in Starbox PROTEKTOR.", "score", 1000, 0],
		["s5k", "Ace Robot", "Score 5,000 in Starbox PROTEKTOR.", "score", 5000, 1],
		["s20k", "Robot Legend", "Score 20,000 in Starbox PROTEKTOR.", "score", 20000, 2],
		["survive", "Three-Minute Hero", "Survive 3 minutes in Starbox PROTEKTOR.", "survive", 180, 1],
		["chain", "Unbreakable Bot", "Block 50 in a row in Starbox PROTEKTOR.", "chain", 50, 2]],
	"duel": [["w3", "Rookie Strider", "Beat 3 opponents in Starbox DUEL STRIDERS.", "wins", 3, 0],
		["w10", "Grid Champion", "Beat 10 opponents in Starbox DUEL STRIDERS.", "wins", 10, 1],
		["w25", "Legend of the Grid", "Beat 25 opponents in Starbox DUEL STRIDERS.", "wins", 25, 2],
		["flawless", "Not a Scratch", "Win a DUEL STRIDERS round without taking a hit.", "flawless", 1, 1],
		["buster", "Buster Purist", "Win a DUEL STRIDERS round with the buster alone.", "buster", 1, 0]],
	"sword": [["wave5", "Squire", "Clear wave 5 in Starbox SWORD STORY.", "wave", 5, 0],
		["wave10", "Knight of the Meadow", "Clear wave 10 in Starbox SWORD STORY.", "wave", 10, 1],
		["wave20", "Hero of the Story", "Clear wave 20 in Starbox SWORD STORY.", "wave", 20, 2],
		["nohit", "Flawless Blade", "Beat the Slime King without taking a hit.", "nohit", 1, 2],
		["combo", "Blade Dancer", "Land a 30-hit combo in SWORD STORY.", "combo", 30, 1]],
}

## Each planet's boss (data/bosses.json) and its achievement.
const BOSSES := {
	"terra_virex": ["aegis_relay", "Relay Silenced"],
	"glacien_ix": ["boreal_colossus", "Thaw"],
	"ignara_prime": ["solar_crucible", "Heat Death"],
	"tempestris": ["cyclarch", "Eye of the Storm"],
	"viscera_nova": ["gestalt_heart", "Still Heart"],
	"umbra_vacua": ["observer", "Unobserved"],
	"mechanon_ascens": ["paragon_protektor", "Imperfect"],
}


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
	for p in Data.PLANETS:
		if not BOSSES.has(p):
			continue
		var bid: String = BOSSES[p][0]
		var bname: String = str(Boss.defs().get(bid, {}).get("name", bid.to_upper())).capitalize().trim_prefix("The ")
		d.append({"id": "boss_" + bid, "cat": "bosses", "icon": "boss", "boss_id": bid, "name": BOSSES[p][1],
			"desc": "Defeat the %s on %s." % [bname, Data.PLANET_INFO[p].name]})
	d.append({"id": "all_bosses", "cat": "bosses", "icon": "all_bosses", "name": "Every Shield Broken",
		"desc": "Defeat every planetary boss.", "stat": "bosses_defeated", "target": BOSSES.size()})
	for e in ENDING_NAMES:
		d.append({"id": "ending_" + e, "cat": "story", "icon": "ending_" + e, "name": ENDING_NAMES[e][0], "desc": ENDING_NAMES[e][1]})
	d.append({"id": "all_endings", "cat": "story", "icon": "all_endings", "name": "Every Version of You",
		"desc": "See all five endings.", "stat": "endings_seen", "target": 5})
	d.append({"id": "no_upgrades", "cat": "story", "icon": "no_upgrades", "name": "As They Made You",
		"desc": "Reach an ending without buying a single upgrade."})
	d.append({"id": "all_training", "cat": "protektor", "icon": "training", "name": "Top of the Class",
		"desc": "Clear every training module at every tier.", "stat": "training_tiers", "target": 9})
	d.append({"id": "all_upgrades", "cat": "protektor", "icon": "upgrades", "name": "Fully Outfitted",
		"desc": "Own every upgrade, special and weapon.", "stat": "upgrades_owned", "target": 13})
	d.append({"id": "console_on", "cat": "games", "icon": "console", "tier": 0, "name": "Player One",
		"desc": "Play a game on the Starbox.", "stat": "console_played", "target": 1})
	d.append({"id": "console_all", "cat": "games", "icon": "console", "tier": 1, "name": "Cartridge Collector",
		"desc": "Play all three Starbox games.", "stat": "console_played", "target": CONSOLE_GAMES.size()})
	d.append({"id": "console_scores", "cat": "games", "icon": "console", "tier": 2, "name": "Name on Every Board",
		"desc": "Set a high score in every Starbox game.", "stat": "console_scored", "target": CONSOLE_GAMES.size()})
	for g in GAME_ACH:
		for a in GAME_ACH[g]:
			d.append({"id": "cg_%s_%s" % [g, a[0]], "cat": "games", "icon": "cg_" + g, "tier": int(a[5]), "name": a[1],
				"desc": a[2], "stat": "cg_%s_%s" % [g, a[3]], "target": int(a[4])})
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
		"bosses_defeated":
			var beaten: Dictionary = Game.achv_stats.get("bosses", {})
			var n := 0
			for p in BOSSES:
				if beaten.has(BOSSES[p][0]):
					n += 1
			return n
		"console_played":
			return (Game.achv_stats.get("console_played", {}) as Dictionary).size()
		"console_scored":
			var n := 0
			for g in CONSOLE_GAMES:
				if ConsoleScreen.best_score(g) > 0:
					n += 1
			return n
		"upgrades_owned":
			var n := Game.upgrade_level("cooldown") + Game.upgrade_level("armor")
			if Game.has_special("ext_shield"):
				n += 1
			n += Game.missile_level()
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
	if id.begins_with("boss_"):
		return Game.achv_stats.get("bosses", {}).has(a.boss_id)
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


static func console_result(game: String, score: int, extra: Dictionary) -> void:
	## A Starbox run ended: remember that the game was played and keep the
	## best of each number it reported.
	var played: Dictionary = Game.achv_stats.get("console_played", {})
	played[game] = true
	Game.achv_stats.console_played = played
	var vals := extra.duplicate()
	vals["score"] = score
	for k in vals:
		var key := "cg_%s_%s" % [game, k]
		Game.achv_stats[key] = maxi(int(Game.achv_stats.get(key, 0)), int(vals[k]))
	Game.save_achievements()
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


static func boss_defeated(boss_id: String, is_mini: bool) -> void:
	## Called the moment a boss dies (story or Free Missions), so it counts
	## even if the mission is abandoned afterwards. Mini-bosses don't count.
	if is_mini:
		return
	var beaten: Dictionary = Game.achv_stats.get("bosses", {})
	if not beaten.has(boss_id):
		beaten[boss_id] = int(Time.get_unix_time_from_system())
	Game.achv_stats.bosses = beaten
	Game.save_achievements()
	check()


static func mission_cleared(level: int, hits_taken: int) -> void:
	if hits_taken == 0:
		Game.achv_stats.flawless_count = int(Game.achv_stats.get("flawless_count", 0)) + 1
		if level >= 3:
			Game.achv_stats.flawless_l3 = int(Game.achv_stats.get("flawless_l3", 0)) + 1
	Game.save_achievements()
	check()
