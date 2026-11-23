extends SceneTree
# Writes the hint experiment's 3x1 PNG: one texel each of grey 64, 128 and 192 (the course's
# Assignment 5, Step 3; CHANGE-BRIEF.md, "my hint experiment predictions"). Its import is
# lossless, with no mipmaps (greys_3x1.png.import). Run it once, from the project folder:
#   godot --headless --path . --script res://hint_experiment/make_greys_png.gd
# Written by Claude Code on 29 Oct 2026.

const PATH := "res://hint_experiment/greys_3x1.png"
const GREYS := [64, 128, 192]


func _initialize() -> void:
	var img := Image.create_empty(GREYS.size(), 1, false, Image.FORMAT_RGB8)
	for x in GREYS.size():
		var v: float = GREYS[x] / 255.0
		img.set_pixel(x, 0, Color(v, v, v))
	var err := img.save_png(PATH)
	print("%s: %s" % [PATH, error_string(err)])
	var back := Image.load_from_file(PATH)
	for x in back.get_width():
		var c := back.get_pixel(x, 0)
		print("  texel %d: (%d, %d, %d)" % [x, roundi(c.r * 255.0), roundi(c.g * 255.0), roundi(c.b * 255.0)])
	quit(0 if err == OK else 1)
