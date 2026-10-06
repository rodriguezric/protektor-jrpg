class_name Data
## Cast, planets and other static tables. People are specs for ArtPeople /
## ArtPortraits; the looks follow Protektor's original painted portraits.

# Recruits wear the Academy's cream field jacket over their own hoodie.
const JACKET := Color("bdb39b")

static var CAST := {
	"hiro": {"id": "hiro", "name": "Hiro", "skin": Pal.SKIN2.lerp(Pal.SKIN, 0.5), "hair": Pal.WHITE, "style": "hiro", "patch": true,
		"eye": Pal.WOOD, "top": Pal.BLUE, "hood": true, "hoodc": Pal.BLUE, "jacket": Pal.FROST.lerp(Pal.STONE, 0.3), "bottom": Pal.INK2, "shoes": Pal.INK2,
		"smile": true, "badge": true, "voice": "boy"},
	"pala": {"id": "pala", "name": "Pala", "skin": Pal.SKIN, "hair": Pal.AUBURN, "style": "ponytail", "eye": Pal.SAGE.lerp(Pal.GLOW, 0.25),
		"top": Pal.CREAM, "hood": true, "hoodc": Pal.TEAL, "jacket": JACKET, "bottom": Pal.SLATE, "shoes": Pal.BARK, "badge": true, "voice": "girl"},
	"midas": {"id": "midas", "name": "Midas", "skin": Pal.SKIN2.lerp(Pal.SKIN, 0.3), "hair": Pal.BARK.lerp(Pal.INK, 0.25), "style": "messy",
		"eye": Pal.WOOD, "top": Pal.TEAL, "hood": true, "hoodc": Pal.TEAL.lerp(Pal.PINE, 0.3), "jacket": JACKET.lerp(Pal.PEACH, 0.3), "bottom": Pal.SLATE.lerp(Pal.BLUE, 0.3),
		"shoes": Pal.BARK, "badge": true, "voice": "boy2"},
	"instructor": {"id": "instructor", "name": "Instructor", "skin": Pal.SKIN2.lerp(Pal.SKIN, 0.6), "hair": Pal.STONE.lerp(Pal.WHITE, 0.4), "style": "slick",
		"glasses": true, "top": Pal.NAVY, "bottom": Pal.NAVY.lerp(Pal.INK, 0.3), "shoes": Pal.INK, "epaulettes": true, "sash": true, "belt": true,
		"adult": true, "voice": "adult_flat"},
	"mother": {"id": "mother", "name": "Mother", "skin": Pal.SKIN2.lerp(Pal.SKIN, 0.5), "hair": Pal.INK2.lerp(Pal.PLUM, 0.3), "style": "curly",
		"eye": Pal.WOOD, "top": Pal.PLUM.lerp(Pal.INK, 0.2), "floral": true, "skirt": true, "bottom": Pal.PLUM, "shoes": Pal.BARK, "adult": true, "voice": "woman"},
	"father": {"id": "father", "name": "Father", "skin": Pal.SKIN2, "hair": Pal.WOOD, "style": "short", "mustache": true, "scar": true,
		"top": Pal.WHITE, "bottom": Pal.SLATE.lerp(Pal.NAVY, 0.4), "shoes": Pal.INK2, "adult": true, "voice": "man"},
	"officer": {"id": "officer", "name": "Officer", "skin": Pal.SKIN, "hair": Pal.INK2, "style": "short", "top": Pal.NAVY.lerp(Pal.SLATE, 0.3),
		"bottom": Pal.NAVY, "shoes": Pal.INK, "belt": true, "adult": true, "voice": "adult_flat"},
	"announcer": {"id": "announcer", "name": "Announcer", "skin": Pal.SKIN2, "hair": Pal.INK2, "style": "slick", "top": Pal.WHITE, "bottom": Pal.NAVY,
		"epaulettes": true, "adult": true, "voice": "announcer"},
	"medic": {"id": "medic", "name": "Medic", "skin": Pal.SKIN3, "hair": Pal.INK2, "style": "bun", "top": Pal.FROST, "bottom": Pal.FROST, "shoes": Pal.SLATE,
		"apron": false, "adult": true, "voice": "adult_flat"},
}

## Player looks, chosen on the naming screen.
static var LOOKS := [
	{"skin": Pal.SKIN, "hair": Pal.INK2, "style": "short", "eye": Pal.BLUE},
	{"skin": Pal.SKIN2, "hair": Pal.BARK, "style": "bun", "eye": Pal.WOOD},
	{"skin": Pal.SKIN3, "hair": Pal.INK2.lerp(Pal.INK, 0.5), "style": "twin", "eye": Pal.WOOD},
	{"skin": Pal.SKIN, "hair": Pal.HONEY, "style": "long", "eye": Pal.SAGE},
]

## Background recruits and staff for the halls.
static var EXTRAS := [
	{"skin": Pal.SKIN, "hair": Pal.BARK, "style": "short", "top": Pal.SLATE, "jacket": JACKET, "badge": true},
	{"skin": Pal.SKIN2, "hair": Pal.INK2, "style": "twin", "top": Pal.ROSE, "jacket": JACKET, "badge": true},
	{"skin": Pal.SKIN3, "hair": Pal.INK2, "style": "spiky", "top": Pal.SAGE, "jacket": JACKET, "badge": true},
	{"skin": Pal.SKIN, "hair": Pal.HONEY, "style": "bun", "top": Pal.LILAC, "jacket": JACKET, "badge": true},
	{"skin": Pal.SKIN2, "hair": Pal.WOOD, "style": "long", "top": Pal.BLUE, "jacket": JACKET, "badge": true},
	{"skin": Pal.SKIN3, "hair": Pal.BARK, "style": "messy", "top": Pal.ORANGE, "jacket": JACKET, "badge": true},
	{"skin": Pal.SKIN, "hair": Pal.INK2, "style": "short", "top": Pal.PURPLE, "jacket": JACKET, "badge": true},
	{"skin": Pal.SKIN2, "hair": Pal.ROSE.lerp(Pal.INK2, 0.4), "style": "ponytail", "top": Pal.MINT, "jacket": JACKET, "badge": true},
]

static var CROWD := [
	{"skin": Pal.SKIN, "hair": Pal.BARK, "style": "short", "top": Pal.ROSE, "adult": true},
	{"skin": Pal.SKIN2, "hair": Pal.INK2, "style": "bun", "top": Pal.SAGE, "skirt": true, "bottom": Pal.PLUM, "adult": true},
	{"skin": Pal.SKIN3, "hair": Pal.INK2, "style": "curly", "top": Pal.HONEY, "adult": true},
	{"skin": Pal.SKIN, "hair": Pal.STONE, "style": "slick", "top": Pal.BLUE, "adult": true},
	{"skin": Pal.SKIN2, "hair": Pal.WOOD, "style": "long", "top": Pal.LILAC, "adult": true},
	{"skin": Pal.SKIN3, "hair": Pal.BARK, "style": "short", "top": Pal.TEAL, "mustache": true, "adult": true},
]

const PLANETS := ["terra_virex", "glacien_ix", "ignara_prime", "tempestris", "viscera_nova", "umbra_vacua", "mechanon_ascens"]

static var PLANET_INFO := {
	"terra_virex": {"name": "Terra Virex", "tex": "green_planet", "blurb": "Baseline colony world. Asteroids and Virex drones.", "boss": "Aegis Relay", "pos": Vector2(56, 96)},
	"glacien_ix": {"name": "Glacien IX", "tex": "cold_planet", "blurb": "Frozen silence. Danger that waits, then crowds.", "boss": "Boreal Colossus", "pos": Vector2(104, 52)},
	"ignara_prime": {"name": "Ignara Prime", "tex": "hot_planet", "blurb": "Heat and overload. Turn faster than it burns.", "boss": "Solar Crucible", "pos": Vector2(126, 108)},
	"tempestris": {"name": "Tempestris", "tex": "tempestris_planet", "blurb": "Storm chaos with a hidden structure.", "boss": "The Cyclarch", "pos": Vector2(176, 74)},
	"viscera_nova": {"name": "Viscera Nova", "tex": "viscera_nova_planet", "blurb": "A living planet. Read what it intends.", "boss": "Gestalt Heart", "pos": Vector2(222, 42)},
	"umbra_vacua": {"name": "Umbra Vacua", "tex": "umbra_vacua_planet", "blurb": "Void and restraint. It punishes panic.", "boss": "The Observer", "pos": Vector2(244, 106)},
	"mechanon_ascens": {"name": "Mechanon Ascens", "tex": "metal_planet", "blurb": "Machine perfection. Break your own rhythm.", "boss": "Paragon Protektor", "pos": Vector2(288, 66)},
}

## Comms chatter from the other pilots during deployments (Scene 2.3).
const COMMS := {
	"hiro": ["This is incredible!", "Faster. Don't think.", "I barely had to turn.", "Keep up!", "Clean. Again."],
	"pala": ["Steady. Don't rush.", "Breathe. Count it out.", "Watch your back side.", "It's louder in here today."],
	"midas": ["I see it...", "Is anyone down there?", "I can do this. I can.", "I miss the ground."],
}


# ------------------------------------------------------------- upgrades ---
## Basic upgrades are priced for training credits; specials and weapons cost
## mission money and also need a number of completed missions.

const FIRE_COOLDOWN := [0.14, 0.12, 0.10, 0.08]

static var UPGRADES := {
	"cooldown": {"name": "Cannon Cycler", "max": 3, "costs": [40, 80, 130],
		"desc": "Shortens the cooldown between shots."},
	"armor": {"name": "Red Integrity", "max": 3, "costs": [50, 95, 150],
		"desc": "An extra plate of red integrity, spent before your own."},
	"medicine": {"name": "Neural Stabilizer", "cost": 60,
		"desc": "Clears one failed deployment from your record. Taken automatically after a failure."},
}

static var SPECIALS := {
	"ext_shield": {"name": "Extended Shield", "cost": 300, "missions": 2,
		"desc": "Projects the rear shield further from the planet, catching threats earlier."},
	"missile": {"name": "Auto Missile", "cost": 450, "missions": 4,
		"desc": "Every few seconds a homing missile seeks the nearest target. Rocks shrug it off."},
}

static var WEAPONS := {
	"basic": {"name": "Basic Shot", "cost": 0, "missions": 0, "desc": "The Protektor's standard beam bolt."},
	"wave": {"name": "Wave Shot", "cost": 350, "missions": 3, "desc": "A wide crescent that is hard to miss."},
	"auto": {"name": "Auto Shot", "cost": 400, "missions": 5, "desc": "Hold fire for a fast stream, up to five shots at once."},
	"beam": {"name": "Beam Shot", "cost": 550, "missions": 7, "desc": "A focused lance that deals 3 damage."},
}

## Credits for clearing a story mission: deeper planets and later levels pay more.
static func mission_reward(planet: String, level: int) -> int:
	return 40 + 30 * level + 15 * maxi(0, PLANETS.find(planet))


# ------------------------------------------------------------- training ---

const TRAINING_MODULES := ["block", "shoot", "combo"]

static var TRAINING := {
	"block": {"name": "Shield Discipline", "short": "BLOCKING", "desc": "Rocks only. Turn your back to them and let the shield take the hit.",
		"rewards": [10, 16, 24], "pos": Vector2(76, 70), "tex": "cold_planet"},
	"shoot": {"name": "Beam Accuracy", "short": "SHOOTING", "desc": "Drones only. Face them and fire before they reach the planet.",
		"rewards": [10, 16, 24], "pos": Vector2(160, 50), "tex": "hot_planet"},
	"combo": {"name": "Full Orientation", "short": "COMBINED", "desc": "Both at once. Block what you can't shoot, shoot what you can't block.",
		"rewards": [14, 22, 32], "pos": Vector2(244, 70), "tex": "metal_planet"},
}
