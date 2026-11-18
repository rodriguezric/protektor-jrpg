class_name TvSerial
## Channel 4: HEARTS OF THE SHIELD GRID, a soap opera in six episodes, acted
## with total commitment and no restraint: zooms on gasps, slaps, amnesia,
## an evil twin, a wedding with objections, and a finale that leaves nothing
## resolved. One new episode each time it airs ("Previously on..." first);
## after the finale it reruns from the top. Progress is kept in the profile
## and the full run earns Must-See TV.

const EPISODES := ["A Love in Orbit", "The Slap Heard Round the Grid", "Who Is Brick Steele?", "Two Bricks, One Heart",
	"I Object!", "Hearts Forever?"]

## What "Previously on..." replays for each episode (from the one before).
const RECAPS := [
	[],
	[["BRICK", "Veronica... I've waited three tours to say this."], ["DR. NOIR", "Not so fast!"]],
	[["VERONICA", "How could you not tell me you had a TWIN?"], ["BRICK", "...I don't."]],
	[["BRICK", "Who... who am I?"]],
	[["BRACK", "Hello, brother."]],
	[["BRICK & BRACK", "WE OBJECT!"]],
]

static var BRICK := {"id": "tv_brick", "skin": Pal.SKIN2, "hair": Pal.HONEY, "style": "slick", "top": Pal.WHITE, "bottom": Pal.NAVY,
	"shoes": Pal.INK, "adult": true, "epaulettes": true, "sash": true, "shades": true, "voice": "man"}
static var VERONICA := {"id": "tv_veronica", "skin": Pal.SKIN, "hair": Pal.AUBURN, "style": "long", "top": Pal.ROSE, "floral": true,
	"skirt": true, "bottom": Pal.ROSE, "shoes": Pal.RED, "adult": true, "voice": "woman"}
static var NOIR := {"id": "tv_noir", "skin": Pal.SKIN3, "hair": Pal.INK, "style": "slick", "top": Pal.INK2, "bottom": Pal.INK,
	"shoes": Pal.INK, "adult": true, "mustache": true, "voice": "man"}
static var NURSE := {"id": "tv_nurse", "skin": Pal.SKIN2, "hair": Pal.INK2, "style": "bun", "top": Pal.FROST, "bottom": Pal.FROST,
	"shoes": Pal.SLATE, "adult": true, "voice": "woman"}
static var PRIEST := {"id": "tv_priest", "skin": Pal.SKIN, "hair": Pal.STONE, "style": "short", "top": Pal.INK2, "bottom": Pal.INK2,
	"shoes": Pal.INK, "adult": true, "glasses": true, "voice": "man"}

const PINK := Color("ff9ae0")
const GOLD := Color("ffd36b")


static func brack() -> Dictionary:
	var s := BRICK.duplicate()
	s.id = "tv_brack"
	s.mustache = true
	s.top = Pal.INK2
	return s


static func next_episode() -> int:
	return int(Game.profile.get("tv_serial_ep", 0)) % EPISODES.size()


static func play(st: TvStage) -> void:
	var ep := next_episode()
	var rerun := int(Game.profile.get("tv_serial_ep", 0)) >= EPISODES.size()
	await st.title("HEARTS OF THE", "SHIELD GRID", PINK, 1.2)
	await st.title("EPISODE %d" % (ep + 1), EPISODES[ep] + (" (RERUN)" if rerun else ""), PINK, 1.4)
	if not RECAPS[ep].is_empty():
		st.backdrop("black")
		await st.say("", "Previously on HEARTS OF THE SHIELD GRID...", 0.4, PINK)
		for r in RECAPS[ep]:
			await st.say(r[0], r[1], 0.4, PINK)
		st.caption_off()
	match ep:
		0:
			await _ep1(st)
		1:
			await _ep2(st)
		2:
			await _ep3(st)
		3:
			await _ep4(st)
		4:
			await _ep5(st)
		5:
			await _ep6(st)
	if st.cancelled:
		return
	# a whole episode watched: the next one airs next time
	Game.profile.tv_serial_ep = int(Game.profile.get("tv_serial_ep", 0)) + 1
	Game.save_profile()
	Game.achv_stats.serial_eps = maxi(int(Game.achv_stats.get("serial_eps", 0)), mini(EPISODES.size(), int(Game.profile.tv_serial_ep)))
	Game.save_achievements()
	Achievements.check()


static func _tbc(st: TvStage) -> void:
	st.caption_off()
	await st.freeze_frame("TO BE CONTINUED")


# --------------------------------------------------------------- episodes ---

static func _ep1(st: TvStage) -> void:
	st.backdrop("observation")
	st.actor("brick", BRICK, Vector2(52, 66), 2)
	st.actor("vero", VERONICA, Vector2(92, 66), 3)
	await st.say("VERONICA", "Brick. The stars are so... starry tonight.", 0.5, PINK)
	await st.say("BRICK", "Not as starry as you, Veronica.", 0.5, GOLD)
	st.emote("vero", "heart", 1.2)
	st.sting("happy")
	await st.wait(0.6)
	# he takes off his sunglasses. slowly.
	await st.zoom(2.0, Vector2(52, 52), 0.6)
	var bare := BRICK.duplicate()
	bare.id = "tv_brick_bare"
	bare.shades = false
	if st.a("brick"):
		st.a("brick").set_spec(bare)
	Sfx.play("chime", 0.8, -8.0)
	await st.say("BRICK", "Veronica... I've waited three tours to say this.", 0.6, GOLD)
	await st.zoom(1.0, Vector2.ZERO, 0.3)
	await st.say("VERONICA", "Say it, Brick. SAY IT.", 0.4, PINK)
	st.actor("noir", NOIR, Vector2(160, 66), 3)
	st.sting("drama")
	await st.walk("noir", Vector2(126, 66), 40.0)
	st.mood("vero", "shock")
	st.mood("brick", "shock")
	await st.say("DR. NOIR", "Not so fast!", 0.6, Color("c890f0"))
	await st.zoom(2.2, Vector2(126, 52), 0.25)
	await st.wait(0.5)
	await _tbc(st)


static func _ep2(st: TvStage) -> void:
	st.backdrop("parlor")
	st.actor("noir", NOIR, Vector2(110, 66), 3)
	st.actor("vero", VERONICA, Vector2(80, 66), 3)
	st.actor("brick", BRICK, Vector2(40, 66), 2)
	await st.say("DR. NOIR", "Veronica is engaged... to ME.", 0.5, Color("c890f0"))
	st.mood("brick", "shock")
	st.sting("drama")
	await st.zoom(2.0, Vector2(40, 52), 0.2)
	await st.wait(0.4)
	await st.zoom(1.0, Vector2.ZERO, 0.2)
	await st.walk("vero", Vector2(52, 66), 50.0)
	st.mood("vero", "angry")
	await st.say("VERONICA", "And YOU! How could you not tell me...", 0.3, PINK)
	await st.say("VERONICA", "...that you had a TWIN?", 0.3, PINK)
	# the slap
	Sfx.play("knock", 0.6, -2.0)
	st.flash(Color.WHITE, 0.2)
	st.shake(0.3, 2.0)
	st.face("brick", 3)
	await st.big_text("SLAP!", Color("ff7a6b"), 0.6)
	st.face("brick", 2)
	await st.say("BRICK", "...I don't.", 0.6, GOLD)
	await st.wait(0.4)
	st.mood("noir", "smile")
	await st.zoom(2.0, Vector2(110, 52), 0.3)
	await st.say("DR. NOIR", "Heh. Heh heh. HEH.", 0.4, Color("c890f0"))
	await _tbc(st)


static func _ep3(st: TvStage) -> void:
	st.backdrop("hospital")
	st.prop("bed", "foldbed", Vector2(56, 66))
	var b := st.actor("brick", BRICK, Vector2(56, 60), 0, "closed")
	if b:
		b.set_pose("lie")
	st.actor("nurse", NURSE, Vector2(100, 66), 3)
	st.actor("vero", VERONICA, Vector2(24, 66), 2)
	Sfx.play("beep", 1.0, -10.0)
	await st.wait(0.5)
	Sfx.play("beep", 1.0, -10.0)
	await st.say("NURSE PEARL", "He took a meteor to the head. He's lucky.", 0.4, Color("9fe8ff"))
	await st.say("NURSE PEARL", "Also unlucky. Mostly unlucky.", 0.4, Color("9fe8ff"))
	st.mood("brick", "")
	await st.wait(0.4)
	await st.zoom(2.2, Vector2(56, 54), 0.4)
	await st.say("BRICK", "Who... who am I?", 0.6, GOLD)
	await st.zoom(1.0, Vector2.ZERO, 0.2)
	st.hop("vero", 3.0)
	await st.say("VERONICA", "You're Brick Steele! The man I love!", 0.4, PINK)
	await st.say("BRICK", "...Brick? What a ridiculous name.", 0.5, GOLD)
	st.mood("vero", "shock")
	st.mood("nurse", "shock")
	Sfx.play("gasp", 1.0, -6.0)
	st.sting("drama")
	await st.zoom(2.0, Vector2(24, 52), 0.25)
	await _tbc(st)


static func _ep4(st: TvStage) -> void:
	st.backdrop("parlor")
	st.actor("vero", VERONICA, Vector2(72, 66), 0)
	st.actor("brick", BRICK, Vector2(36, 66), 2)
	await st.say("VERONICA", "Brick, you remember me now. Don't you?", 0.4, PINK)
	await st.say("BRICK", "I remember... everything. Except Tuesdays.", 0.4, GOLD)
	st.actor("brack", brack(), Vector2(160, 66), 3)
	Sfx.play("door", 1.0, -8.0)
	await st.walk("brack", Vector2(110, 66), 36.0)
	st.sting("drama")
	await st.zoom(2.2, Vector2(110, 52), 0.25)
	await st.say("BRACK STEELE", "Hello... brother.", 0.6, Color("ff9a5a"))
	await st.zoom(1.0, Vector2.ZERO, 0.2)
	st.mood("brick", "shock")
	await st.say("BRICK", "BRACK?! But you were lost in the Umbra!", 0.3, GOLD)
	await st.say("BRACK STEELE", "I found myself. And a mustache.", 0.4, Color("ff9a5a"))
	# Veronica faints. Of course she does.
	st.face("vero", 3)
	st.mood("vero", "closed")
	await st.wait(0.3)
	st.pose("vero", "lie")
	Sfx.play("gasp", 0.8, -6.0)
	await st.wait(0.6)
	await _tbc(st)


static func _ep5(st: TvStage) -> void:
	st.backdrop("chapel")
	st.actor("priest", PRIEST, Vector2(72, 58), 0)
	st.actor("noir", NOIR, Vector2(58, 66), 1)
	st.actor("vero", VERONICA, Vector2(86, 66), 1)
	st.sting("sad")
	await st.say("PRIEST", "If anyone objects to this union...", 0.3, Color("c9ccd8"))
	await st.say("PRIEST", "...speak now, or forever hold your peace.", 0.6, Color("c9ccd8"))
	await st.wait(0.8)
	await st.say("PRIEST", "Wonderful. Then by the power vested in-", 0.1, Color("c9ccd8"))
	Sfx.play("heavy_door", 1.0, -4.0)
	st.flash(Color.WHITE, 0.3)
	st.actor("brick", BRICK, Vector2(40, 80), 1)
	st.actor("brack", brack(), Vector2(104, 80), 1)
	await st.say("BRICK", "I OBJECT!", 0.2, GOLD)
	await st.say("BRACK STEELE", "I ALSO OBJECT!", 0.3, Color("ff9a5a"))
	st.face("vero", 0)
	st.face("noir", 0)
	st.mood("vero", "shock")
	st.mood("noir", "angry")
	st.sting("drama")
	await st.zoom(2.0, Vector2(86, 52), 0.25)
	await st.say("VERONICA", "BOTH of you?!", 0.4, PINK)
	await st.zoom(1.0, Vector2.ZERO, 0.2)
	await _tbc(st)


static func _ep6(st: TvStage) -> void:
	st.backdrop("chapel")
	st.actor("brick", BRICK, Vector2(44, 66), 2, "angry")
	st.actor("noir", NOIR, Vector2(100, 66), 3, "angry")
	await st.say("BRICK", "It ends here, Noir!", 0.3, GOLD)
	for k in 3:
		if st.cancelled:
			return
		Sfx.play("lance", 1.0 + k * 0.2, -8.0)
		st.flash(Color.WHITE, 0.12)
		st.shake(0.2, 2.0)
		await st.wait(0.35)
	await st.say("DR. NOIR", "Brick... before you strike...", 0.3, Color("c890f0"))
	await st.zoom(2.2, Vector2(100, 52), 0.4)
	await st.say("DR. NOIR", "I am your FATHER.", 0.8, Color("c890f0"))
	st.sting("drama")
	await st.zoom(2.2, Vector2(44, 52), 0.15)
	st.mood("brick", "shock")
	await st.say("BRICK", "NOOOOOOOOO!", 0.6, GOLD)
	await st.fade(true, 0.5)
	# ...and then she wakes up
	st.clear_set()
	st.backdrop("bedroom")
	st.prop("bed", "bigbed", Vector2(64, 68))
	var v := st.actor("vero", VERONICA, Vector2(64, 58), 0, "closed")
	if v:
		v.set_pose("lie")
	await st.fade(false, 0.5)
	st.mood("vero", "shock")
	await st.say("VERONICA", "It was... all a dream?", 0.8, PINK)
	st.actor("brick", BRICK, Vector2(100, 66), 3)
	await st.say("BRICK", "Or... WAS it?", 0.4, GOLD)
	await st.zoom(2.2, Vector2(100, 52), 0.4)
	# he takes off the sunglasses. there is another pair underneath.
	Sfx.play("chime", 0.8, -8.0)
	await st.wait(0.6)
	Sfx.play("chime", 1.2, -8.0)
	await st.say("", "(There is a second pair of sunglasses underneath.)", 0.6, PINK)
	st.caption_off()
	await st.freeze_frame("THE END?")
	await st.title("HEARTS OF THE SHIELD GRID", "Thank you for watching", PINK, 1.6)
