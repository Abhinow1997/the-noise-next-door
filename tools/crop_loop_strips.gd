extends SceneTree
## Cuts each of the raccoon's seven loops' frame strips out of one Movie Maker capture of
## previews/raccoon_loops_preview.tscn (CHANGE-BRIEF.md, revised 22 Nov 2026, "a frame strip for
## each of the seven loops").
##   - The capture is windowed, at 24 fps (the clips' own rate), so each captured frame is one
##     frame of every clip. The preview's log of the same run, logs/raccoon_loops_preview_frames.log,
##     says where each copy is on the screen (`place`) and which frame of which wrap each clip
##     shows in each captured frame.
##   - Each strip is read from the clip's second wrap (wraps 1; the first blends in from his
##     standing pose): the brief's frames for that clip, then frame 0 of the third wrap, the seam.
##   - Each kept frame is cropped to that copy's box and saved as
##     captures/loops/r0/<clip>/frameNNNNNNNN_fMM.png (the captured frame, then the clip's frame).
##     Pixels are copied, never resampled. The full frames aren't kept.
## Run from the project folder, after the author's capture into <folder>:
##   ..\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script
##     res://tools/crop_loop_strips.gd -- --frames=<folder> [--log=<log>] [--out=<folder>]
## It stops with an error, and writes nothing, if the log isn't from a 1280 x 720 run the size of
## the frames, or a frame it needs is missing.
## Written by Claude Code on 22 Nov 2026.

const LOG := "res://logs/raccoon_loops_preview_frames.log"
const OUT := "res://captures/loops/r0"
## The brief's frames for each clip, before the seam (frame 0 of the next wrap, added here).
const KEEP := {
	"idle": [0, 24, 29, 48, 60, 72, 95],
	"walk": [0, 1, 7, 13, 19, 23],
	"run": [0, 4, 7, 8, 12, 15],
	"sneak": [0, 6, 12, 18, 24, 30, 36, 42, 47],
	"bored": [0, 24, 36, 53, 77, 95],
	"sleep": [0, 48, 95],
	"climb": [0, 6, 12, 18, 23],
}
## The wrap each strip is read from (0 is the first).
const WRAP := 1


func _init() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var kv := arg.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	if not args.has("frames"):
		_fail("Say where the capture is: -- --frames=<folder>")
		return
	var frames_dir := _abs(args["frames"])
	var log_path := _abs(args.get("log", LOG))
	var out_dir := _abs(args.get("out", OUT))

	# The log: the view, each copy's box, and each captured frame's clip frames and wraps.
	var text := FileAccess.get_file_as_string(log_path)
	if text == "":
		_fail("Can't read the log %s" % log_path)
		return
	var view := Vector2i.ZERO
	var places := {}
	var at := {}  # "<clip> <frame> <wrap>" -> captured frame
	for line in text.split("\n"):
		var words := line.strip_edges().split(" ", false)
		if words.size() == 3 and words[0] == "view":
			view = Vector2i(int(words[1]), int(words[2]))
		elif words.size() == 6 and words[0] == "place":
			places[words[1].trim_suffix(":")] = Rect2i(int(words[2]), int(words[3]), int(words[4]), int(words[5]))
		elif words.size() > 2 and words[0] == "frame":
			var n := int(words[1].trim_suffix(":"))
			for k in range(2, words.size() - 1, 2):
				var fw := words[k + 1].split("/")
				if fw.size() == 2:
					var key := "%s %s %s" % [words[k], fw[0], fw[1]]
					if not at.has(key):
						at[key] = n
	if view != Vector2i(1280, 720):
		_fail("The log is from a %d x %d run, not the 1280 x 720 capture: run the capture again, then this (a headless run of the preview writes the same log with a 64 x 64 view)" % [view.x, view.y])
		return

	# What to cut, all found before anything is written.
	var jobs: Array = []
	for clip: String in KEEP:
		if not places.has(clip):
			_fail("No place for %s in the log" % clip)
			return
		var wanted: Array = []
		for f: int in KEEP[clip]:
			wanted.append([f, WRAP])
		wanted.append([0, WRAP + 1])
		for fw: Array in wanted:
			var key := "%s %d %d" % [clip, fw[0], fw[1]]
			if not at.has(key):
				_fail("The log never shows %s at frame %d of wrap %d: capture longer (--quit-after 240)" % [clip, fw[0], fw[1]])
				return
			var n: int = at[key]
			var path := frames_dir.path_join("frame%08d.png" % n)
			if not FileAccess.file_exists(path):
				_fail("Missing %s" % path)
				return
			jobs.append([clip, n, fw[0], path])

	var cache := {}
	for job: Array in jobs:
		var clip: String = job[0]
		var path: String = job[3]
		var image: Image = cache.get(path)
		if image == null:
			image = Image.load_from_file(path)
			if image == null or image.get_size() != view:
				_fail("%s isn't a %d x %d frame" % [path, view.x, view.y])
				return
			cache[path] = image
		var dir := out_dir.path_join(clip)
		DirAccess.make_dir_recursive_absolute(dir)
		var crop := image.get_region(places[clip])
		var out := dir.path_join("frame%08d_f%02d.png" % [job[1], job[2]])
		if crop.save_png(out) != OK:
			_fail("Couldn't write %s" % out)
			return
	for clip: String in KEEP:
		var made: PackedStringArray = []
		for job: Array in jobs:
			if job[0] == clip:
				made.append("%d (f%d)" % [job[1], job[2]])
		print("%s: %s, box %s" % [clip, ", ".join(made), places[clip]])
	print("Cut %d frames into %s" % [jobs.size(), out_dir])
	quit(0)


func _abs(path: String) -> String:
	if path.begins_with("res://"):
		return ProjectSettings.globalize_path(path)
	if path.is_absolute_path():
		return path
	return ProjectSettings.globalize_path("res://").path_join(path)


func _fail(message: String) -> void:
	push_error(message)
	printerr(message)
	quit(1)
