extends SceneTree
# The author's hint-experiment capture (CHANGE-BRIEF.md, Assignment 5, "my hint experiment
# predictions" and "the hint experiment, on one quad split in two"): in a window, from the
# game's own rendered frame, not an OS screenshot. It opens hint_experiment/hint_experiment.tscn,
# lets a few frames settle, saves the frame as bands.png, and prints the pixel at the centre
# of each of the six bands beside the author's predicted value, writing the same lines to
# bands.txt beside the image.
# Run in a window (not headless), from the project folder:
#   godot --path . --script "$(pwd)/design/a5/captures/read_bands.gd"
# (design/ is ignored by Godot, so it runs by its file path)
# Written by Claude Code on 29 Oct 2026, at the author's request. The capture is the
# author's: it's taken when the author runs it.

const SCENE := "res://hint_experiment/hint_experiment.tscn"
const OUT := "res://design/a5/captures/hint"
const SETTLE_FRAMES := 10
const QUAD_WIDTH := 3.0  # metres: the Greys quad's size.x in the scene
# Left to right: the sampler, the grey in the file, and the author's predicted 8-bit value
# (CHANGE-BRIEF.md, "Revised 28 Oct 2026: my hint experiment predictions").
const BANDS := [
	["with source_color", 64, 64], ["with source_color", 128, 128], ["with source_color", 192, 192],
	["without source_color", 64, 135], ["without source_color", 128, 184], ["without source_color", 192, 225],
]


func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		print("Run this in a window: a headless run renders nothing.")
		quit(1)
		return
	var scene: Node = load(SCENE).instantiate()
	get_root().add_child(scene)
	for i in SETTLE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := get_root().get_texture().get_image()
	var cam: Camera3D = scene.get_node("Camera3D")
	var dir := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(dir)
	img.save_png(dir.path_join("bands.png"))
	var lines := PackedStringArray()
	lines.append("Hint experiment, %s, frame %dx%d" % [Time.get_datetime_string_from_system(), img.get_width(), img.get_height()])
	var band := QUAD_WIDTH / BANDS.size()
	for i in BANDS.size():
		var p := cam.unproject_position(Vector3(-QUAD_WIDTH / 2.0 + band * (i + 0.5), 0.0, 0.0))
		var c := img.get_pixelv(Vector2i(p.round()))
		lines.append("%-20s file %3d: pixel (%d, %d) = (%d, %d, %d); predicted %d" % [BANDS[i][0], BANDS[i][1], roundi(p.x), roundi(p.y), c.r8, c.g8, c.b8, BANDS[i][2]])
	for line in lines:
		print(line)
	var f := FileAccess.open(dir.path_join("bands.txt"), FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	quit(0)
