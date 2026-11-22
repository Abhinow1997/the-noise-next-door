extends SceneTree
## Makes the moth's sprite sheet, assets/sprites/moth_lowpoly/moth_lowpoly.png, from the author's
## generated image beside it, moth_lowpoly_generated.webp, which stays as it is (CHANGE-BRIEF.md,
## Assignment 7, 22 Nov 2026: the author's low-poly moth replacing the pixel-art one).
## The image is 1024 x 1024: four cells of 512 x 512, 2 across and 2 down, a wing flap read left to
## right then down (wings raised, halfway up, spread flat, angled down), on a flat green background
## with dark green lines between the cells. This:
##   - keys the green to transparent: how much greener a pixel is than its red and blue sets its
##     alpha, so the edges fade instead of keeping a green fringe; and takes the green spill out
##     of what's left (green no higher than the brighter of red and blue), which also takes the
##     green tint off the feathery antennae;
##   - clears a BORDER-pixel frame round every cell, where the lines between the cells are (it
##     warns if anything of the moth comes that close to a cell's edge);
##   - writes the sheet at the same size, every cell in its place;
##   - measures the registration it leaves: in each cell, the moth's left eye (the centroid of
##     its near-black pixels) and the abdomen's tip (the lowest opaque pixel down the cell's
##     middle). The generated cells already agree to within 2 px of 512, so nothing is shifted.
## Nothing is moved, resampled or repainted: pixels only lose their green.
## Run it from the project folder (it prints what it found and did):
##   ../Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/make_moth_sheet.gd
## Written by Claude Code on 22 Nov 2026 at the author's request, from the balloon's sheet tool
## (tools/make_balloon_sheet.gd at 7bd4aea).

const SOURCE := "res://assets/sprites/moth_lowpoly/moth_lowpoly_generated.webp"
const OUT := "res://assets/sprites/moth_lowpoly/moth_lowpoly.png"
const COLS := 2
const ROWS := 2
## How much greener than red and blue (0..1) a pixel must be to start fading, and to be gone. The
## background is about 0.88 and the lines between the cells about 0.51; the moth's own colours are
## below 0.1 (the antennae about 0.07), so a pixel half moth, half green (about 0.4) is half clear.
const KEY_FROM := 0.30
const KEY_TO := 0.50
## The frame cleared round every cell (px). The lines are about 6 px wide where they show at all.
const BORDER := 6
## The head's region, in a cell, where the eye is looked for; and how dark an eye pixel is.
const HEAD := Rect2i(196, 140, 120, 140)
const EYE_LUMA := 0.25
## Half the strip down a cell's middle the abdomen's tip is looked for in (px).
const STRIP := 6


func _init() -> void:
	var src := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if src == null:
		push_error("Couldn't load " + SOURCE)
		quit(1)
		return
	src.convert(Image.FORMAT_RGBA8)
	var w := src.get_width()
	var h := src.get_height()
	var cw := w / COLS
	var ch := h / ROWS
	print("source %s: %d x %d, cells %d x %d" % [SOURCE, w, h, cw, ch])
	var out := _key(src)
	for c in COLS * ROWS:
		var ox := (c % COLS) * cw
		var oy := (c / COLS) * ch
		for y in ch:
			for x in cw:
				if x < BORDER or y < BORDER or x >= cw - BORDER or y >= ch - BORDER:
					var p := out.get_pixel(ox + x, oy + y)
					# The lines are dark green and key out; a pale or brown pixel this close would be the moth.
					if p.a > 0.5 and x > 2 and y > 2 and x < cw - 3 and y < ch - 3:
						push_warning("cell %d: something opaque near its edge at %d, %d" % [c, x, y])
					out.set_pixel(ox + x, oy + y, Color(0, 0, 0, 0))
	for c in COLS * ROWS:
		print("cell %d: left eye at %s, abdomen tip at row %d, the moth's box %s" % [
				c, _eye(src, c, cw, ch), _tip(out, c, cw, ch), _box(out, c, cw, ch)])
	var err := out.save_png(ProjectSettings.globalize_path(OUT))
	print("wrote %s (%s)" % [OUT, error_string(err)])
	quit(0 if err == OK else 1)


## The image with its green keyed to transparent and the green spill taken out.
func _key(src: Image) -> Image:
	var img := src.duplicate() as Image
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			var other := maxf(c.r, c.b)
			var a := 1.0 - smoothstep(KEY_FROM, KEY_TO, c.g - other)
			if a <= 0.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			img.set_pixel(x, y, Color(c.r, minf(c.g, other), c.b, a * c.a))
	return img


## The centroid of the near-black pixels in cell `c`'s head region (its left eye), in the cell.
func _eye(img: Image, c: int, cw: int, ch: int) -> Vector2:
	var ox := (c % COLS) * cw
	var oy := (c / COLS) * ch
	var sum := Vector2.ZERO
	var n := 0
	for y in range(HEAD.position.y, HEAD.end.y):
		for x in range(HEAD.position.x, HEAD.end.x):
			var p := img.get_pixel(ox + x, oy + y)
			if p.get_luminance() < EYE_LUMA and p.g - maxf(p.r, p.b) < 0.2:
				sum += Vector2(x, y)
				n += 1
	return (sum / n).snappedf(0.1) if n > 0 else Vector2(-1, -1)


## The lowest opaque row in the strip down cell `c`'s middle: the abdomen's tip.
func _tip(img: Image, c: int, cw: int, ch: int) -> int:
	var ox := (c % COLS) * cw
	var oy := (c / COLS) * ch
	for y in range(ch - 1, -1, -1):
		for x in range(cw / 2 - STRIP, cw / 2 + STRIP + 1):
			if img.get_pixel(ox + x, oy + y).a > 0.5:
				return y
	return -1


## The box round cell `c`'s opaque pixels.
func _box(img: Image, c: int, cw: int, ch: int) -> Rect2i:
	var ox := (c % COLS) * cw
	var oy := (c / COLS) * ch
	var box := Rect2i()
	for y in ch:
		for x in cw:
			if img.get_pixel(ox + x, oy + y).a > 0.5:
				var p := Rect2i(x, y, 1, 1)
				box = p if box.size == Vector2i.ZERO else box.merge(p)
	return box
