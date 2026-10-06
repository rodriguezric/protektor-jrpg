class_name ArtPortraits
## Dialog portraits are the characters' own field sprites, zoomed in on the head
## and shoulders, so the face you talk to is the face you walk beside. The
## talking variants (blink, mouth open) come from ArtPeople. Helion's System
## voice and the call-home screen get their own icons.

const S := 64
const CROP := Rect2i(4, 4, 24, 24)

## Dialog moods that the field sprite's face doesn't have, mapped to ones it does.
const FIELD_MOOD := {"worried": "sad", "flat": "", "smile": "smile", "sad": "sad", "angry": "angry",
	"hollow": "hollow", "closed": "closed", "shock": "shock", "cry": "cry"}


static func from_sprite(s: Dictionary, mood: String = "", blink: bool = false, open: bool = false, zoom: int = 3) -> PixBuf:
	## The character's own walkaround sprite, head and shoulders, zoomed in.
	var m: String = FIELD_MOOD.get(mood, "")
	if blink:
		m += "+blink"
	if open:
		m += "+open"
	var src := ArtPeople.render(s, 0, 0, m)
	var crop := src.img.get_region(CROP)
	crop.resize(CROP.size.x * zoom, CROP.size.y * zoom, Image.INTERPOLATE_NEAREST)
	var b := PixBuf.new(crop.get_width(), crop.get_height())
	b.img = crop
	return b


# ------------------------------------------------------------- non-human ---

static func system_icon(frame: int) -> PixBuf:
	## Helion Command's voice: a cold eye inside the badge sigil.
	var b := PixBuf.new(S, S)
	var c := S / 2.0
	b.ball(c, c, 27, 27, Pal.NAVY)
	b.ball(c, c, 22, 22, Pal.PANEL)
	for k in 12:
		var a := k * TAU / 12.0 + frame * 0.13
		b.rect(c + cos(a) * 24 - 1, c + sin(a) * 24 - 1, 2, 2, Pal.SYNC if k % 3 == 0 else Pal.STEEL)
	b.ell(c, c, 15, 8, Pal.FROST)
	b.ball(c, c, 7, 7, Pal.SYNC.lerp(Pal.TEAL, 0.3))
	b.circ(c, c, 3, Pal.INK)
	b.pset(int(c) - 3, int(c) - 3, Pal.WHITE)
	b.outline()
	return b


static func comm(frame: int) -> PixBuf:
	## Outgoing call: a scratchy receiver screen with a waveform.
	var b := PixBuf.new(S, S)
	b.rect(6, 8, 52, 44, Pal.INK2)
	b.rect(8, 10, 48, 40, Pal.PANEL2)
	for x in range(10, 54):
		var y := 30 + int(sin(x * 0.5 + frame * 0.9) * (4 + 4 * sin(frame * 0.4 + x * 0.08)))
		b.pset(x, y, Pal.GLOW.lerp(Pal.LEMON, 0.4))
	for i in 24:
		b.pset(10 + int(Pal.hash2(i, frame) * 44), 11 + int(Pal.hash2(frame, i) * 38), Pal.TEXT_DIM)
	b.rect(24, 52, 16, 5, Pal.INK2)
	b.outline()
	return b
