class_name TvSerial
## Channel 4's serial, "Hearts of the Shield Grid" (see feature
## tv_serial_cheesy_drama). Until it airs, the channel stands by.


static func play(st: TvStage) -> void:
	st.backdrop("testcard")
	await st.say("", "HEARTS OF THE SHIELD GRID returns soon. Please stand by.", 2.0)
	st.caption_off()
	await st.wait(1.0)
