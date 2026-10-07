extends SceneTree
## Makes the character sheet's images from the generated raccoon poses in
## design/reference/raccoon/:
## - cutouts/<pose>.png: each pose with its background removed by a colour key;
## - silhouette.png: the silhouette test, at actual size in the game's window;
## - poses.png: the labelled pose sheet, every pose at one scale;
## - collision.png: the collision capsule drawn over every pose at that scale.
##
## Run it from the project folder. It opens a window for a moment, because the
## labels need the renderer:
##   godot --path . --script res://design/character/make_character_sheet.gd

const SRC := "res://design/reference/raccoon/"
const OUT := "res://design/character/"

## Image file, pose number, pose, game state, slice asset ID ("" = not in the slice).
const POSES := [
	["idle", "3", "Idle", "Standing still", "CHAR-IDLE"],
	["running", "7", "Run", "Walking or running", "CHAR-RUN"],
	["sneak", "6", "Sneak", "Sneaking", "CHAR-SNEAK"],
	["bored", "4", "Bored", "No input for 5 seconds", "CHAR-BORED"],
	["asleep", "12", "Asleep", "Asleep in the hollow", "CHAR-SLEEP"],
	["standing", "8", "Interact", "Working at a zip, plug or cord", ""],
	["picking-items", "9", "Carrying", "Carrying something in his mouth", ""],
	["busted", "10", "Busted", "Caught: the failure", ""],
	["knockedback", "13", "Hurt", "Knocked over", ""],
	["with-beanie", "8 + B", "Interact, beanie on", "From storyboard panel 9 on", ""],
]

## The game camera at the default zoom, in a 1280 x 720 window: it sees 4.94 m
## from top to bottom at the raccoon (a 15-degree lens about 18.75 m away).
const PX_PER_M := 146.0
## The 3D raccoon's size on screen at the default zoom, from a screenshot. The
## idle cut-out is scaled to cover the same area.
const GAME_W := 162.0
const GAME_H := 85.0
const ZOOM_OUT := 1.6
## The collision capsule, from scripts/player.gd at size 0.8.
const CAPSULE_LENGTH := 0.64
const CAPSULE_WIDTH := 0.32
## The pose and collision sheets show everything at this multiple of game size.
const SHEET_SCALE := 2.4

const PAPER := Color("efece5")
const INK := Color("2b2b28")
const MUTED := Color("6b675f")
const ACCENT := Color("c2410c")
const PALETTE := [
	["Fur, lit", "748087"], ["Fur, mid", "67737b"], ["Fur, shaded", "59656e"],
	["Charcoal", "26292e"], ["Cream", "d1c4a7"], ["Beanie", "d7263d"],
]

var cuts := {}
var bold: FontVariation


func _initialize() -> void:
	_run()


func _run() -> void:
	bold = FontVariation.new()
	bold.base_font = ThemeDB.fallback_font
	bold.variation_embolden = 0.6

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "cutouts"))
	for p in POSES:
		var c := _cut_out(p[0])
		cuts[p[0]] = c
		c.image.save_png(OUT + "cutouts/" + p[0] + ".png")
		print("%-14s %4d x %4d  %-12s  face %6d px  feet row %4d  anchor %6.1f" % [p[0], c.image.get_width(), c.image.get_height(), c.kind, c.cream, c.feet, c.anchor])

	# One scale for every pose: each face (the cream area) is matched to idle's,
	# and idle covers the same area on screen as the 3D raccoon did.
	var idle: Dictionary = cuts["idle"]
	var base := sqrt(GAME_W * GAME_H / float(idle.w * idle.h))
	var metrics := {}
	for p in POSES:
		var c: Dictionary = cuts[p[0]]
		c.game = base * sqrt(float(idle.cream) / float(c.cream))
		metrics[p[0]] = {
			"game_scale": snappedf(c.game, 0.0001),
			"feet_row": c.feet,
			"anchor_x": snappedf(c.anchor, 0.1),
			"on_screen_px": [roundi(c.w * c.game), roundi(c.h * c.game)],
		}
		print("%-14s on screen at the default zoom: %3d x %3d px" % [p[0], roundi(c.w * c.game), roundi(c.h * c.game)])
	var f := FileAccess.open(OUT + "cutouts/cutouts.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(metrics, "  ", false))
	f.close()

	await _render(_silhouette_sheet(), OUT + "silhouette.png")
	await _render(_pose_sheet(), OUT + "poses.png")
	await _render(_collision_sheet(), OUT + "collision.png")
	quit()


# --- Cutting out ---------------------------------------------------------------

## Removes the background from one pose. The background is whatever fills the
## image's border: the green screen, or the sage-green scene. Its "greenness"
## (green over the larger of red and blue) sets the key, since the raccoon is
## blue-grey, charcoal and cream and never green.
func _cut_out(file: String) -> Dictionary:
	var img := Image.load_from_file(ProjectSettings.globalize_path(SRC + file + ".jpg"))
	var s := 1024.0 / maxf(img.get_width(), img.get_height())
	img.resize(roundi(img.get_width() * s), roundi(img.get_height() * s), Image.INTERPOLATE_LANCZOS)
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var n := w * h
	var d := img.get_data()

	var border := PackedFloat32Array()
	var br := PackedInt32Array()
	var bgc := PackedInt32Array()
	var bb := PackedInt32Array()
	for i in _border_indices(w, h):
		border.append(_green(d, i))
		br.append(d[i * 4])
		bgc.append(d[i * 4 + 1])
		bb.append(d[i * 4 + 2])
	border.sort()
	br.sort()
	bgc.sort()
	bb.sort()
	var mid := border.size() / 2
	var bg_green := border[mid]
	var bg := Color8(br[mid], bgc[mid], bb[mid])
	var lo := 0.02
	var hi := bg_green * 0.85

	var alpha := PackedFloat32Array()
	alpha.resize(n)
	var solid := PackedByteArray()
	solid.resize(n)
	for i in n:
		var a := clampf(1.0 - (_green(d, i) - lo) / (hi - lo), 0.0, 1.0)
		alpha[i] = a
		solid[i] = 1 if a > 0.5 else 0

	# Keep the biggest solid shape, which drops the bench, the bushes and any
	# specks; fill holes the key opened inside him; keep his soft edge.
	var keep := _largest(solid, w, h)
	var outside := _flood_from_border(keep, w, h)
	var near := _dilate(keep, w, h, 2)
	for i in n:
		if keep[i] == 1:
			continue
		if outside[i] == 0:
			# Enclosed by him: a gap between his legs if it's clearly the
			# background colour, otherwise a hole the key bit into his fur.
			if _green(d, i) < hi * 0.5:
				alpha[i] = 1.0
		elif near[i] == 0 or solid[i] == 1:
			alpha[i] = 0.0

	# Take the background's colour back out of the soft edge, so no green fringe
	# is left when he's drawn on another ground.
	for i in n:
		var a := alpha[i]
		if a <= 0.05:
			alpha[i] = 0.0
		elif a < 0.999:
			for k in 3:
				var bgk: float = bg[k]
				var v := (d[i * 4 + k] / 255.0 - (1.0 - a) * bgk) / a
				d[i * 4 + k] = clampi(roundi(v * 255.0), 0, 255)
			var r := d[i * 4]
			var b := d[i * 4 + 2]
			d[i * 4 + 1] = mini(d[i * 4 + 1], maxi(r, b))
		d[i * 4 + 3] = roundi(alpha[i] * 255.0)

	var out := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, d)
	var used := out.get_used_rect()
	var margin := 6
	var rect := Rect2i(used.position - Vector2i(margin, margin), used.size + Vector2i(margin * 2, margin * 2)).intersection(Rect2i(0, 0, w, h))
	out = out.get_region(rect)
	out.fix_alpha_edges()

	# Measure: the face (cream pixels) for matching scale, the lowest row of
	# him for the ground line, and the middle of his lowest part (between his
	# front and hind paws) for the anchor.
	var ow := out.get_width()
	var oh := out.get_height()
	var od := out.get_data()
	var cream := 0
	var top := oh
	var bottom := -1
	var left := ow
	var right := -1
	for y in oh:
		for x in ow:
			var i := y * ow + x
			if od[i * 4 + 3] < 128:
				continue
			top = mini(top, y)
			bottom = maxi(bottom, y)
			left = mini(left, x)
			right = maxi(right, x)
			var r := od[i * 4] / 255.0
			var g := od[i * 4 + 1] / 255.0
			var b := od[i * 4 + 2] / 255.0
			if r > 0.6 and g > 0.55 and b > 0.42 and r >= g and g >= b and r - b > 0.06:
				cream += 1
	var low_left := ow
	var low_right := -1
	var band := maxi(2, roundi((bottom - top) * 0.12))
	for y in range(bottom - band, bottom + 1):
		for x in ow:
			if od[(y * ow + x) * 4 + 3] >= 128:
				low_left = mini(low_left, x)
				low_right = maxi(low_right, x)
	return {
		"image": out,
		"kind": "green screen" if bg_green > 0.25 else "scene",
		"cream": cream,
		"feet": bottom,
		"anchor": (low_left + low_right) * 0.5,
		"w": right - left + 1,
		"h": bottom - top + 1,
	}


func _green(d: PackedByteArray, i: int) -> float:
	return (d[i * 4 + 1] - maxi(d[i * 4], d[i * 4 + 2])) / 255.0


func _border_indices(w: int, h: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	for x in w:
		out.append(x)
		out.append((h - 1) * w + x)
	for y in range(1, h - 1):
		out.append(y * w)
		out.append(y * w + w - 1)
	return out


## The biggest 4-connected group of solid pixels.
func _largest(solid: PackedByteArray, w: int, h: int) -> PackedByteArray:
	var n := w * h
	var label := PackedInt32Array()
	label.resize(n)
	var stack := PackedInt32Array()
	var best := 0
	var best_size := 0
	var next := 1
	for start in n:
		if solid[start] == 0 or label[start] != 0:
			continue
		var size := 0
		label[start] = next
		stack.append(start)
		while not stack.is_empty():
			var i := stack[stack.size() - 1]
			stack.resize(stack.size() - 1)
			size += 1
			var x := i % w
			if x > 0 and solid[i - 1] == 1 and label[i - 1] == 0:
				label[i - 1] = next
				stack.append(i - 1)
			if x < w - 1 and solid[i + 1] == 1 and label[i + 1] == 0:
				label[i + 1] = next
				stack.append(i + 1)
			if i >= w and solid[i - w] == 1 and label[i - w] == 0:
				label[i - w] = next
				stack.append(i - w)
			if i + w < n and solid[i + w] == 1 and label[i + w] == 0:
				label[i + w] = next
				stack.append(i + w)
		if size > best_size:
			best_size = size
			best = next
		next += 1
	var keep := PackedByteArray()
	keep.resize(n)
	for i in n:
		keep[i] = 1 if label[i] == best else 0
	return keep


## Every pixel outside the shape that can be reached from the image's border.
func _flood_from_border(shape: PackedByteArray, w: int, h: int) -> PackedByteArray:
	var n := w * h
	var seen := PackedByteArray()
	seen.resize(n)
	var stack := PackedInt32Array()
	for i in _border_indices(w, h):
		if shape[i] == 0 and seen[i] == 0:
			seen[i] = 1
			stack.append(i)
	while not stack.is_empty():
		var i := stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		var x := i % w
		if x > 0 and shape[i - 1] == 0 and seen[i - 1] == 0:
			seen[i - 1] = 1
			stack.append(i - 1)
		if x < w - 1 and shape[i + 1] == 0 and seen[i + 1] == 0:
			seen[i + 1] = 1
			stack.append(i + 1)
		if i >= w and shape[i - w] == 0 and seen[i - w] == 0:
			seen[i - w] = 1
			stack.append(i - w)
		if i + w < n and shape[i + w] == 0 and seen[i + w] == 0:
			seen[i + w] = 1
			stack.append(i + w)
	return seen


func _dilate(mask: PackedByteArray, w: int, h: int, steps: int) -> PackedByteArray:
	var cur := mask
	for s in steps:
		var nxt := cur.duplicate()
		for i in w * h:
			if cur[i] == 1:
				continue
			var x := i % w
			if (x > 0 and cur[i - 1] == 1) or (x < w - 1 and cur[i + 1] == 1) \
					or (i >= w and cur[i - w] == 1) or (i + w < w * h and cur[i + w] == 1):
				nxt[i] = 1
		cur = nxt
	return cur


# --- Sheets ----------------------------------------------------------------------

func _silhouette_sheet() -> Control:
	var sheet := _paper(Vector2(1280, 720))
	_text(sheet, "Silhouette test, at actual size", Vector2(40, 26), 28, INK, 0.0, true)
	_text(sheet, "The five poses the slice uses, filled solid black, at the size they appear in the game's 1280 × 720 window.", Vector2(40, 68), 18, MUTED)
	var rows := [["Default zoom", 1.0, 330.0], ["Fully zoomed out (1.6×)", 1.0 / ZOOM_OUT, 590.0]]
	for row in rows:
		_text(sheet, row[0], Vector2(40, row[2] - 215.0), 20, INK, 0.0, true)
		for k in 5:
			var p: Array = POSES[k]
			var c: Dictionary = cuts[p[0]]
			var sc: float = c.game * row[1]
			var cx := 150.0 + k * 245.0
			var black := _silhouette(c.image)
			_picture(sheet, black, sc, Vector2(cx, row[2]), c)
			var size_text := "%d × %d px" % [roundi(c.w * sc), roundi(c.h * sc)]
			_text(sheet, "%s · %s" % [p[2], size_text], Vector2(cx - 110, row[2] + 10.0), 16, MUTED, 220.0, false, HORIZONTAL_ALIGNMENT_CENTER)
	_text(sheet, "He passes if his ears, hunched back and tail still read at the smaller size. The tail rings are inside the shape, so the silhouette can't show them.", Vector2(40, 676), 16, MUTED)
	return sheet


func _pose_sheet() -> Control:
	var sheet := _paper(Vector2(1800, 1620))
	_text(sheet, "The raccoon: generated poses", Vector2(40, 26), 30, INK, 0.0, true)
	_text(sheet, "Gemini images from design/reference/raccoon/, cut out and shown at one scale, %.1f× their size in the game. Each label gives the pose number from CHARACTER-SHEET.md and the game state." % SHEET_SCALE, Vector2(40, 72), 18, MUTED, 1720.0)
	for k in POSES.size():
		var p: Array = POSES[k]
		var c: Dictionary = cuts[p[0]]
		var origin := _cell(k)
		_picture(sheet, c.image, c.game * SHEET_SCALE, origin + Vector2(215, 350), c)
		_caption(sheet, origin, "%s · %s" % [p[1], p[2]], p[3], p[4], p[0] + ".jpg")
	# The silhouette, at actual size.
	var o := _cell(10)
	var idle: Dictionary = cuts["idle"]
	_picture(sheet, _silhouette(idle.image), idle.game, o + Vector2(215, 350), idle)
	_caption(sheet, o, "2 · Silhouette", "The shape at actual game size", "", "silhouette.png")
	# The palette.
	o = _cell(11)
	for k in PALETTE.size():
		var at := o + Vector2(20 + (k % 2) * 200, 40 + (k / 2) * 80)
		var swatch := ColorRect.new()
		swatch.color = Color(PALETTE[k][1])
		swatch.position = at
		swatch.size = Vector2(56, 56)
		sheet.add_child(swatch)
		_text(sheet, PALETTE[k][0], at + Vector2(66, 4), 16, INK)
		_text(sheet, "#" + PALETTE[k][1].to_upper(), at + Vector2(66, 28), 16, MUTED)
	_caption(sheet, o, "Palette", "Measured from the green-screen poses", "", "CHARACTER-SHEET.md")
	_text(sheet, "Edits: background removed by a colour key, cropped, and scaled so the faces match (Claude Code, make_character_sheet.gd). Nothing redrawn.", Vector2(40, 1576), 16, MUTED)
	return sheet


func _collision_sheet() -> Control:
	var sheet := _paper(Vector2(1800, 1620))
	_text(sheet, "Collision overlay", Vector2(40, 26), 30, INK, 0.0, true)
	_text(sheet, "The collision capsule drawn over every pose at the same scale (%.1f× game size). Dashed line: the ground." % SHEET_SCALE, Vector2(40, 72), 18, MUTED, 1720.0)
	var length := CAPSULE_LENGTH * PX_PER_M * SHEET_SCALE
	var height := CAPSULE_WIDTH * PX_PER_M * SHEET_SCALE
	for k in POSES.size():
		var p: Array = POSES[k]
		var c: Dictionary = cuts[p[0]]
		var origin := _cell(k)
		var foot := origin + Vector2(215, 350)
		var ground := Control.new()
		ground.position = origin + Vector2(10, 350)
		ground.size = Vector2(400, 2)
		var draw_ground := func() -> void:
			ground.draw_dashed_line(Vector2.ZERO, Vector2(400, 0), MUTED, 2.0, 8.0)
		ground.draw.connect(draw_ground)
		sheet.add_child(ground)
		_picture(sheet, c.image, c.game * SHEET_SCALE, foot, c)
		var cap := Control.new()
		cap.position = foot - Vector2(length * 0.5, height)
		cap.size = Vector2(length, height)
		var pts := _stadium(length, height)
		var draw_capsule := func() -> void:
			cap.draw_colored_polygon(pts, Color(ACCENT, 0.22))
			var ring := pts.duplicate()
			ring.append(pts[0])
			cap.draw_polyline(ring, ACCENT, 3.0, true)
		cap.draw.connect(draw_capsule)
		sheet.add_child(cap)
		_caption(sheet, origin, "%s · %s" % [p[1], p[2]], p[3], "", "")
	var o := _cell(10)
	_text(sheet, "The capsule", o + Vector2(20, 20), 22, INK, 0.0, true)
	_text(sheet, "0.64 m long and 0.32 m wide and tall, lying along his body with its bottom at his feet (scripts/player.gd at size 0.8). Drawn as it looks when he moves left or right on screen.", o + Vector2(20, 56), 17, INK, 380.0)
	o = _cell(11)
	_text(sheet, "Art beyond it", o + Vector2(20, 20), 22, INK, 0.0, true)
	_text(sheet, "His head, ears, upper back and most of his tail. That's fair: nothing in the game hits those parts, and he never jumps or ducks. When he walks toward or away from the camera, the capsule turns with him and looks shorter, while the flat image stays the same.", o + Vector2(20, 56), 17, INK, 380.0)
	return sheet


## Where cell k of the 4-column grid starts.
func _cell(k: int) -> Vector2:
	return Vector2(40 + (k % 4) * 430, 140 + (k / 4) * 470)


func _caption(sheet: Control, origin: Vector2, title: String, state: String, slice_id: String, file: String) -> void:
	_text(sheet, title, origin + Vector2(20, 362), 22, INK, 390.0, true)
	_text(sheet, state, origin + Vector2(20, 392), 17, INK, 390.0)
	if slice_id != "":
		_text(sheet, "In the slice: " + slice_id, origin + Vector2(20, 416), 16, ACCENT, 390.0)
	elif file != "" and file.ends_with(".jpg"):
		_text(sheet, "Not in the slice", origin + Vector2(20, 416), 16, MUTED, 390.0)
	if file != "":
		_text(sheet, file, origin + Vector2(20, 438), 14, MUTED, 390.0)


func _paper(size: Vector2) -> Control:
	var sheet := Control.new()
	sheet.size = size
	var bg := ColorRect.new()
	bg.color = PAPER
	bg.size = size
	sheet.add_child(bg)
	return sheet


func _text(parent: Control, text: String, pos: Vector2, font_size: int, colour: Color, width := 0.0, heavy := false, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", colour)
	if heavy:
		l.add_theme_font_override("font", bold)
	if width > 0.0:
		l.text = _wrap(text, width, font_size, bold if heavy else ThemeDB.fallback_font)
		l.size = Vector2(width, 0)
	parent.add_child(l)


## Breaks text into lines no wider than width.
func _wrap(text: String, width: float, font_size: int, font: Font) -> String:
	var lines := PackedStringArray()
	var line := ""
	for word in text.split(" "):
		var longer := word if line == "" else line + " " + word
		if line != "" and font.get_string_size(longer, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
			lines.append(line)
			line = word
		else:
			line = longer
	if line != "":
		lines.append(line)
	return "\n".join(lines)


## Draws a cut-out at a scale, with his anchor (the middle of his lowest part)
## on the given point, so every pose stands on the same ground line.
func _picture(parent: Control, img: Image, sc: float, foot: Vector2, c: Dictionary) -> void:
	var im := img.duplicate() as Image
	im.resize(maxi(1, roundi(img.get_width() * sc)), maxi(1, roundi(img.get_height() * sc)), Image.INTERPOLATE_LANCZOS)
	var tr := TextureRect.new()
	tr.texture = ImageTexture.create_from_image(im)
	tr.position = foot - Vector2(c.anchor * sc, (c.feet + 1) * sc)
	tr.size = Vector2(im.get_width(), im.get_height())
	parent.add_child(tr)


func _silhouette(img: Image) -> Image:
	var d := img.get_data()
	for i in d.size() / 4:
		d[i * 4] = 0
		d[i * 4 + 1] = 0
		d[i * 4 + 2] = 0
	return Image.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, d)


func _stadium(length: float, height: float) -> PackedVector2Array:
	var r := height * 0.5
	var pts := PackedVector2Array()
	for k in 25:
		var a := PI * 0.5 + PI * k / 24.0
		pts.append(Vector2(r + cos(a) * r, r + sin(a) * r))
	for k in 25:
		var a := -PI * 0.5 + PI * k / 24.0
		pts.append(Vector2(length - r + cos(a) * r, r + sin(a) * r))
	return pts


func _render(sheet: Control, path: String) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(sheet.size)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	vp.add_child(sheet)
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(path)
	vp.queue_free()
