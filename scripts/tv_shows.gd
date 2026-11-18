class_name TvShows
## What's on: each channel's show, staged on a TvStage with field actors.
## Every show is short (20-45 s) and ends on its own; the TV loops it.

const CHANNELS := [
	{"ch": 1, "id": "news", "name": "HELION NEWS"},
	{"ch": 2, "id": "cartoon", "name": "ROBO-PROTEKTOR!"},
	{"ch": 3, "id": "kitchen", "name": "RATION KITCHEN"},
	{"ch": 4, "id": "serial", "name": "HEARTS OF THE SHIELD GRID"},
	{"ch": 5, "id": "weather", "name": "PLANET OF THE WEEK"},
	{"ch": 6, "id": "static", "name": ""},
]

static var ANCHOR := {"id": "tv_anchor", "skin": Pal.SKIN, "hair": Pal.INK2, "style": "slick", "top": Pal.NAVY, "bottom": Pal.NAVY,
	"shoes": Pal.INK, "adult": true, "smile": true, "epaulettes": false, "voice": "man"}
static var CHEF := {"id": "tv_chef", "skin": Pal.SKIN2, "hair": Pal.HONEY, "style": "bun", "top": Pal.WHITE, "apron": true, "skirt": true,
	"bottom": Pal.ROSE, "shoes": Pal.BARK, "adult": true, "smile": true, "voice": "woman"}
static var FORECASTER := {"id": "tv_weather", "skin": Pal.SKIN3, "hair": Pal.INK2, "style": "long", "top": Pal.SKY, "bottom": Pal.NAVY,
	"shoes": Pal.INK, "adult": true, "glasses": true, "smile": true, "voice": "woman"}

const PLANET_FORECASTS := {
	"terra_virex": ["Terra Virex: mild, with scattered drones.", "Perfect parade weather, folks!"],
	"glacien_ix": ["Glacien IX: highs of minus two hundred.", "Lows: lower. Pack a scarf!"],
	"ignara_prime": ["Ignara Prime: hot. Very hot.", "Leave the chocolate at home!"],
	"tempestris": ["Tempestris: storms. Always storms.", "Hold onto your hats, pilots!"],
	"viscera_nova": ["Viscera Nova: warm, humid, and... breathing?", "Nothing to worry about!"],
	"umbra_vacua": ["Umbra Vacua: dark. That's the whole forecast.", "Bring a flashlight!"],
	"mechanon_ascens": ["Mechanon Ascens: precise. Clear. Calculated.", "Like clockwork, folks!"],
}


static func play(id: String, st: TvStage) -> void:
	match id:
		"news":
			await news(st)
		"cartoon":
			await cartoon(st)
		"kitchen":
			await kitchen(st)
		"weather":
			await weather(st)
		"serial":
			await TvSerial.play(st)


static func _front(st: TvStage, id: String, kind: String, pos: Vector2) -> void:
	var s := st.sprite(id, ImageTexture.create_from_image(TvSets.front(kind).img), pos)
	if s:
		s.z_index = 5


# ----------------------------------------------------------------- news ---

static func news(st: TvStage) -> void:
	await st.title("HELION NEWS", "The Evening Bulletin", Color("2a5aa0"))
	st.backdrop("newsroom")
	st.actor("anchor", ANCHOR, Vector2(46, 60), 0, "smile")
	_front(st, "desk", "desk", Vector2(46, 64))
	st.ticker_text("SHIELD GRID AT 100%  *  RATIONS UNCHANGED  *  PARADE TOMORROW 0900  *  SMILE, BLOCK 7  *")
	await st.say("CORVIN VALE", "Good evening, Block 7. I'm Corvin Vale.")
	await st.say("CORVIN VALE", "Recruitment is up forty percent this cycle!")
	st.hop("anchor")
	await st.wait(0.3)
	st.caption_off()
	st.ticker_off()
	# the footage: the machine at work over a planet
	st.clear_set()
	st.backdrop("space")
	var mech := st.sprite("mech", Art.prop("mech", 0), Vector2(40, 120), 0.55)
	st.say("", "Protektor units held the line over Terra Virex.", 0.6)
	await st.move("mech", Vector2(44, 42), 1.4)
	for k in 3:
		if st.cancelled:
			return
		st.flash(Color("9fe8ff"), 0.15)
		Sfx.play("lance", 1.2, -12.0)
		if mech:
			mech.texture = Art.prop("mech", k % 2)
		await st.wait(0.35)
	await st.wait(1.0)
	# proud families
	st.clear_set()
	st.backdrop("newsroom")
	for i in 4:
		var look: Dictionary = Data.LOOKS[i].duplicate()
		look.top = [Pal.ROSE, Pal.SKY, Pal.LEMON, Pal.MINT][i]
		look.bottom = Pal.SLATE
		st.actor("kid%d" % i, look, Vector2(26 + i * 30, 68), 0, "smile")
	st.sting("cheer")
	st.say("", "Proud families cheer the brave machines.", 0.4)
	for k in 6:
		st.hop("kid%d" % (k % 4), 4.0)
		if k == 2:
			st.emote("kid1", "heart", 1.0)
		await st.wait(0.35)
	await st.wait(0.8)
	st.clear_set()
	st.backdrop("newsroom")
	st.actor("anchor", ANCHOR, Vector2(46, 60), 0, "smile")
	_front(st, "desk", "desk", Vector2(46, 64))
	await st.say("CORVIN VALE", "Tomorrow, new pilots join the parade.")
	await st.zoom(1.6, Vector2(46, 46), 0.5)
	await st.say("CORVIN VALE", "Remember: the Protektor never sleeps... so you can.", 1.6)
	st.sting("happy")
	await st.zoom(1.0, Vector2.ZERO, 0.3)
	await st.say("CORVIN VALE", "Goodnight.", 1.0)
	st.caption_off()


# -------------------------------------------------------------- cartoon ---

static func cartoon(st: TvStage) -> void:
	await st.title("ROBO-PROTEKTOR!", "Steel that never sleeps!", Color("e0a030"))
	st.backdrop("cartoon")
	var slime := st.sprite("slime", ImageTexture.create_from_image(TvSets.front("slime_lord").img), Vector2(104, 34))
	await st.say("NARRATOR", "When the Space Slime Lord attacks...", 0.6, Color("9fe8ff"))
	st.shake(0.4, 1.5)
	await st.say("SLIME LORD", "GLORP! Your planet is MINE!", 0.8, Color("c890f0"))
	await st.say("NARRATOR", "...one hero answers the call!", 0.4, Color("9fe8ff"))
	st.caption_off()
	var mech := st.sprite("mech", Art.prop("mech", 0), Vector2(-20, 30), 0.5)
	st.sting("title")
	await st.move("mech", Vector2(70, 34), 0.6, Tween.TRANS_BACK)
	Sfx.play("explode", 1.2, -6.0)
	st.flash(Color.WHITE, 0.3)
	st.shake(0.4, 3.0)
	if slime:
		slime.scale = Vector2(1.3, 0.6)
	await st.big_text("KA-POW!", Color("ffd36b"), 0.8)
	if slime and not st.cancelled:
		var tw := slime.create_tween()
		tw.tween_property(slime, "scale", Vector2(0.0, 0.0), 0.3)
	await st.wait(0.4)
	st.remove("slime")
	await st.big_text("SPLORCH!", Color("c890f0"), 0.6)
	if mech:
		mech.texture = Art.prop("mech", 1)
	await st.say("ROBO-PROTEKTOR", "Justice never sleeps!", 0.8, Color("5fd3e0"))
	await st.zoom(1.8, Vector2(70, 22), 0.4)
	await st.say("ROBO-PROTEKTOR", "Remember, kids: eat your rations... and ENLIST!", 1.2, Color("5fd3e0"))
	st.sting("happy")
	await st.zoom(1.0, Vector2.ZERO, 0.3)
	st.caption_off()
	await st.title("ROBO-PROTEKTOR!", "Every week on Helion Kids", Color("e0a030"), 1.4)


# -------------------------------------------------------------- kitchen ---

static func kitchen(st: TvStage) -> void:
	await st.title("RATION KITCHEN", "with Chef Dilly", Color("d07838"))
	st.backdrop("kitchen")
	st.actor("chef", CHEF, Vector2(60, 60), 0, "smile")
	_front(st, "counter", "counter", Vector2(72, 65))
	var loaf := st.prop("loaf", "packet", Vector2(40, 52))
	if loaf:
		loaf.z_index = 6
	st.hop("chef", 4.0)
	await st.say("CHEF DILLY", "Welcome back to Ration Kitchen!", 0.8, Color("ffb070"))
	st.sting("laugh")
	await st.say("CHEF DILLY", "Today: Nutri-Loaf, three ways!", 0.6, Color("ffb070"))
	st.sting("happy")
	for way in [["Way one: sliced!", "smile"], ["Way two: cubed!", "smile"], ["Way three...", ""]]:
		if st.cancelled:
			return
		for k in 3:
			Sfx.play("knock", 1.6 + k * 0.1, -12.0)
			st.shake_actor("chef", 0.1)
			await st.wait(0.15)
		st.mood("chef", way[1])
		await st.say("CHEF DILLY", way[0], 0.5, Color("ffb070"))
	st.emote("chef", "sweat", 1.4)
	await st.wait(0.8)
	await st.say("CHEF DILLY", "...also sliced.", 0.4, Color("ffb070"))
	st.sting("laugh")
	await st.wait(1.0)
	st.mood("chef", "smile")
	st.hop("chef", 3.0)
	await st.say("CHEF DILLY", "Ration Kitchen: making do, deliciously!", 1.0, Color("ffb070"))
	st.caption_off()


# -------------------------------------------------------------- weather ---

static func weather(st: TvStage) -> void:
	await st.title("PLANET OF THE WEEK", "Your interplanetary forecast", Color("2a7ac0"))
	st.backdrop("weather")
	# the planet of the week turns over with the days
	var keys: Array = PLANET_FORECASTS.keys()
	var key: String = keys[int(Time.get_unix_time_from_system() / 86400.0) % keys.size()]
	var info: Dictionary = Data.PLANET_INFO[key]
	var pl := st.sprite("planet", Art.planet(info.tex, 36, 0), Vector2(54, 30))
	st.actor("fc", FORECASTER, Vector2(116, 66), 3, "smile")
	await st.say("SUNNY ROLLINS", "Good evening! This week's planet:", 0.4, Color("8ad1ff"))
	st.sting("title")
	await st.say("SUNNY ROLLINS", "%s!" % info.name.to_upper(), 0.4, Color("8ad1ff"))
	var lines: Array = PLANET_FORECASTS[key]
	for i in lines.size():
		if pl and not st.cancelled:
			pl.texture = Art.planet(info.tex, 36, i * 3)
		await st.say("SUNNY ROLLINS", lines[i], 0.6, Color("8ad1ff"))
	st.hop("fc", 3.0)
	st.face("fc", 0)
	await st.say("SUNNY ROLLINS", "Stay safe, and thank a Protektor!", 1.0, Color("8ad1ff"))
	st.sting("happy")
	st.caption_off()
	await st.wait(0.6)
