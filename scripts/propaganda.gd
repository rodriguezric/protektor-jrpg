class_name Propaganda
## The Protektor, as Helion sells it: a chrome robot that never sleeps. The
## pieces of that story are scattered through the game; examining one files
## it (a toast, then the FILES page in the field menu). Two of them are the
## truth breaking through: Marketing Brief 7-C in the archive, and your own
## deployment cut into a robot advert on the evening news.
##
## Finds live in the profile, so the collection carries across playthroughs.

## id -> [title, where it's found, what it says]
const PIECES := {
	"poster": ["STEEL THAT NEVER SLEEPS", "Block 7 noticeboard",
		"A chrome robot strides over a green planet. No cockpit, no pilot, no face. Just the slogan, and the Helion seal."],
	"flyer": ["COULD YOUR CHILD BE CHOSEN?", "A bin in Block 7",
		"'Full nutrition. Permanent housing. A hero in the family.' The small print runs out before it says what the hero does."],
	"toy": ["PLASTIC PROTEKTOR", "Your room",
		"Helion Toys, ages 5 and up. The robot's arm was glued back on years ago. It has pointed the wrong way ever since."],
	"costume": ["CARDBOARD ROBO-PROTEKTOR", "Pip, in Block 7",
		"Helion's kids' page printed the pattern: one box, two holes, an antenna. Every child on the block has made one."],
	"cartridge": ["STARBOX: PROTEKTOR", "Your Starbox",
		"The cartridge's hero is a tin robot with an antenna. In the game, the planet never has anyone on it."],
	"news": ["'THE BRAVE MACHINES'", "Helion News, channel 1",
		"Footage of a Protektor over Terra Virex. Proud families cheer. The anchor never says the word 'pilot'."],
	"cartoon": ["ROBO-PROTEKTOR!", "Helion Kids, channel 2",
		"'Eat your rations... and ENLIST!' The robot has no pilot in the cartoon, either. It just wins."],
	"parade_mech": ["THE PARADE PROTEKTOR", "Helion Plaza",
		"Up close the display unit's seams are glued, and there's a hatch on its back with nothing behind it."],
	"vending": ["THE GRATEFUL MACHINE", "The Commons' vending machine",
		"A robot sticker giving a thumbs up: 'PROTEKTORS NEVER SLEEP. NEITHER DO I.'"],
	"cereal": ["PROTEKTOR CRUNCH", "The mess hall",
		"A cartoon robot flexes on the box. Inside, a prize: a pamphlet for your family, 'Could YOUR child be chosen?'"],
	"initiative": ["'A DELIBERATE SIMPLIFICATION'", "The archive",
		"'Public materials depict autonomous defense units. This is a deliberate simplification.'"],
	"brief": ["MARKETING BRIEF 7-C", "The archive",
		"'The public must never picture a child. Tested phrases: brave machines; steel that never sleeps; the Protektor never sleeps, so you can.'"],
	"footage": ["YOUR TURN, ON TELEVISION", "The rec room TV",
		"A robot advert cut from your own deployment: the shield swinging the way you swing it. They painted a robot over you."],
}
const ORDER := ["poster", "flyer", "toy", "costume", "cartridge", "news", "cartoon", "parade_mech", "vending", "cereal", "initiative", "brief", "footage"]


static func found_all() -> Dictionary:
	return Game.profile.get("propaganda", {})


static func has(id: String) -> bool:
	return found_all().has(id)


static func count() -> int:
	var n := 0
	for id in ORDER:
		if has(id):
			n += 1
	return n


static func find(id: String) -> bool:
	## Files a piece (once); shows a toast and checks the achievement.
	if not PIECES.has(id) or has(id):
		return false
	var all := found_all()
	all[id] = int(Time.get_unix_time_from_system())
	Game.profile.propaganda = all
	Game.save_profile()
	if Game.main and Game.main.has_method("toast_achievement"):
		Game.main.toast_achievement({"id": "prop_" + id, "icon": "propaganda", "name": PIECES[id][0], "header": "FILED  %d / %d" % [count(), ORDER.size()]})
	Achievements.check()
	return true
