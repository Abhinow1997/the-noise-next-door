extends SceneTree
## Lays each of the raccoon's frame strips out as one contact sheet, frames left to right in the
## order they were captured, so a strip can be seen at a glance (in the film, the README).
## captures/ holds the strips themselves (fixture captures, Movie Maker): the jump's r0 and r1
## (captures/jump/r<N>/, full 1280 x 720 frames) and the seven loops' r0
## (captures/loops/r0/<clip>/, crops cut by tools/crop_loop_strips.gd). This writes, into
## captures/sheets/:
##   - jump-r0.png and jump-r1.png: each frame cropped to the same box round the raccoon, the
##     box everything that moves in the jump stays inside (the pixels that change between the
##     frames of both strips, inside the middle of the picture, with a margin), 5 to a row;
##   - loops-r0-<clip>.png for each of the seven loops: its crops in one row.
## Pixels are copied, never resampled or redrawn; a white gap of GAP px between frames. Which
## frame is where is in captures/sheets/INDEX.md.
## Run from the project folder:
##   ..\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/make_strip_sheets.gd
## Written by Claude Code on 22 Nov 2026 at the author's request.

const OUT := "res://captures/sheets"
const JUMP := ["res://captures/jump/r0", "res://captures/jump/r1"]
const LOOPS := "res://captures/loops/r0"
const CLIPS := ["idle", "walk", "run", "sneak", "bored", "sleep", "climb"]
const GAP := 6
const PER_ROW := 5
## Where in the jump's frames to look for what moves (the raccoon jumps in place near the
## middle; the camp's people at the top right move too, and are left out), and the margin round it.
const LOOK := Rect2i(300, 100, 700, 500)
const MARGIN := 24
## How much a pixel's colour must change between frames to count as moving: above the firelight's flicker on
## the ground (0.08 takes in most of the picture), below the raccoon and his shadow.
const MOVES := 0.2


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	# The jump: one box for both strips, so they compare frame for frame.
	var strips: Array = []
	for dir: String in JUMP:
		strips.append(_frames(dir))
	var box := _moving_box(strips)
	print("the jump's box: %s" % box)
	for i in JUMP.size():
		var name := "jump-%s.png" % String(JUMP[i]).get_file()
		_sheet(strips[i], box, PER_ROW, name)
	for clip: String in CLIPS:
		var frames := _frames(LOOPS.path_join(clip))
		var size: Vector2i = frames[0][1].get_size()
		_sheet(frames, Rect2i(Vector2i.ZERO, size), frames.size(), "loops-r0-%s.png" % clip)
	quit(0)


## A folder's PNGs in name order, each as [file name, Image].
func _frames(dir: String) -> Array:
	var path := ProjectSettings.globalize_path(dir)
	var names := Array(DirAccess.get_files_at(path)).filter(func(f: String) -> bool: return f.ends_with(".png"))
	names.sort()
	var out: Array = []
	for n: String in names:
		var img := Image.load_from_file(path.path_join(n))
		img.convert(Image.FORMAT_RGB8)
		out.append([n, img])
	return out


## The box round every pixel in LOOK whose colour changes between any two frames of the strips
## (against each strip's first frame), with MARGIN round it.
func _moving_box(strips: Array) -> Rect2i:
	var box := Rect2i()
	for frames: Array in strips:
		var first: Image = frames[0][1]
		for f in range(1, frames.size()):
			var img: Image = frames[f][1]
			for y in range(LOOK.position.y, LOOK.end.y, 2):
				for x in range(LOOK.position.x, LOOK.end.x, 2):
					var a := first.get_pixel(x, y)
					var b := img.get_pixel(x, y)
					if maxf(maxf(absf(a.r - b.r), absf(a.g - b.g)), absf(a.b - b.b)) > MOVES:
						var p := Rect2i(x, y, 2, 2)
						box = p if box.size == Vector2i.ZERO else box.merge(p)
	return box.grow(MARGIN).intersection(Rect2i(0, 0, 1280, 720))


## The frames' `box` regions laid out `per_row` to a row, written to OUT/name.
func _sheet(frames: Array, box: Rect2i, per_row: int, name: String) -> void:
	var cols := mini(per_row, frames.size())
	var rows := ceili(frames.size() / float(per_row))
	var sheet := Image.create(cols * box.size.x + (cols - 1) * GAP, rows * box.size.y + (rows - 1) * GAP, false, Image.FORMAT_RGB8)
	sheet.fill(Color.WHITE)
	var order: PackedStringArray = []
	for i in frames.size():
		var img: Image = frames[i][1]
		sheet.blit_rect(img, box, Vector2i((i % per_row) * (box.size.x + GAP), (i / per_row) * (box.size.y + GAP)))
		order.append(String(frames[i][0]).get_basename())
	var out := ProjectSettings.globalize_path(OUT).path_join(name)
	sheet.save_png(out)
	print("%s: %d frames, %s px: %s" % [name, frames.size(), sheet.get_size(), ", ".join(order)])
