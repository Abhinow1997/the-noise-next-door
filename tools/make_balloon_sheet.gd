extends SceneTree
## Makes the balloon's sprite sheet, assets/sprites/balloon_lowpoly/balloon_lowpoly.png, from the
## author's generated image beside it, balloon_lowpoly_gemini.webp, which stays as it is.
## (CHANGE-BRIEF.md, Assignment 7: the low-poly balloon replacing the pixel-art one.)
## The image is 765 x 1024: six cells of 255 x 512, 3 across and 2 down, on a flat green
## background with faint dark green lines between the cells. This:
##   - keys the green to transparent: how much greener a pixel is than its red and blue sets
##     its alpha, so the edges fade instead of keeping a green fringe; and takes the green
##     spill out of what's left (green no higher than the brighter of red and blue);
##   - lines up the float's three cells (0, 1, 2): the balloon's body is found in each (the
##     opaque pixels in the cell's top 48 %), and cells 1 and 2 are shifted, whole pixels
##     only, so their body's box starts where cell 0's does; the pop's cells (3 to 5) are left
##     where they are;
##   - clears a BORDER-pixel frame round every cell, where the lines between the cells cross
##     (nothing of the balloon comes that close to a cell's edge: checked when it's run);
##   - writes the sheet at the same size, every cell in its place.
## Nothing is resampled or repainted: pixels only move within their cell, or lose their green.
## Run it from the project folder (it prints what it found and did):
##   ../Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/make_balloon_sheet.gd
## Written by Claude Code on 21 Nov 2026 at the author's request.

const SOURCE := "res://assets/sprites/balloon_lowpoly/balloon_lowpoly_gemini.webp"
const OUT := "res://assets/sprites/balloon_lowpoly/balloon_lowpoly.png"
const COLS := 3
const ROWS := 2
## How much greener than red and blue (0..1) a pixel must be to start fading, and to be gone.
## The background is about 0.95 and the faint lines between the cells about 0.72; the thin
## string, blended with the green round it, is about 0.4 at its core, so it stays.
const KEY_FROM := 0.45
const KEY_TO := 0.68
## The share of a cell's height, from its top, the balloon's body is looked for in.
const BODY_SHARE := 0.48
## The frame cleared round every cell (px).
const BORDER := 3


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
	var keyed := _key(src)

	var body0 := _body(keyed, 0, cw, ch)
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	for c in COLS * ROWS:
		var shift := Vector2i.ZERO
		var body := _body(keyed, c, cw, ch)
		if c < COLS:
			shift = body0.position - body.position
		print("cell %d: body %s, shifted by %s" % [c, body, shift])
		var ox := (c % COLS) * cw
		var oy := (c / COLS) * ch
		for y in ch:
			for x in cw:
				var sx := x - shift.x
				var sy := y - shift.y
				if sx < 0 or sy < 0 or sx >= cw or sy >= ch:
					continue
				var px := keyed.get_pixel(ox + sx, oy + sy)
				var at_edge := x < BORDER or y < BORDER or x >= cw - BORDER or y >= ch - BORDER
				if at_edge:
					# The lines between the cells; anything else this close would be lost.
					if px.a > 0.0 and _body(keyed, c, cw, ch).has_point(Vector2i(sx, sy)):
						push_warning("cell %d: the balloon reaches its edge at %d, %d" % [c, x, y])
					continue
				out.set_pixel(ox + x, oy + y, px)
	for c in COLS:
		print("cell %d after: body %s" % [c, _body(out, c, cw, ch)])
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
			var green := c.g - other
			var a := 1.0 - smoothstep(KEY_FROM, KEY_TO, green)
			if a <= 0.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			img.set_pixel(x, y, Color(c.r, minf(c.g, other), c.b, a * c.a))
	return img


## The box round the opaque pixels in the top BODY_SHARE of cell `c`, inside its BORDER (so
## the specks where the lines between the cells cross aren't counted).
func _body(img: Image, c: int, cw: int, ch: int) -> Rect2i:
	var ox := (c % COLS) * cw
	var oy := (c / COLS) * ch
	var box := Rect2i()
	for y in range(BORDER, int(ch * BODY_SHARE)):
		for x in range(BORDER, cw - BORDER):
			if img.get_pixel(ox + x, oy + y).a > 0.5:
				var p := Rect2i(x, y, 1, 1)
				box = p if box.size == Vector2i.ZERO else box.merge(p)
	return box
