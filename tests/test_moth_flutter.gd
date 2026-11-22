extends SceneTree
## Assignment 7, Step 5 (Step 5 of its plan): the read-back of the moths' `flutter` (CHANGE-BRIEF.md,
## revision of 21 Nov 2026, "The extras' timings and places"; since that day's "the balloons are
## 3D, and the moth is the graded sprite clip", the graded sprite clip's read-back). It loads
## props/moths.tscn and reads back:
##   - four moths, each a Sprite3D on bugs.png sliced 4 x 3, 0.1 m across (pixel_size 0.1 / 8),
##     billboarded, nearest filtering, under its own pivot, with its own AnimationPlayer
##     (callback_mode_process IDLE, autoplay empty);
##   - every track in every clip resolves (the course's check, tests/track_check.gd);
##   - `flutter`: one value track on the Sprite3D's frame, UPDATE_DISCRETE; keys cells 4, 5 at 0
##     and 2/24 s, within half a frame (1/48 s), never ==; every cell inside the sheet; length
##     4/24 s (within half a frame), step 1/24 s exactly, LOOP_LINEAR;
##   - the seam for a frame track: the last key's cell differs from the first's, and the gap from
##     the last key to the length equals the key interval;
##   - bugs.png.import: detect_3d/compress_to 0.
## A headless run draws nothing: this reads the clip's structure, not how the moths look.
## Run it from the project folder:
##   bash scripts/run-test.sh test_moth_flutter.gd 60
## It prints PASS or FAIL per check and a count, and quits with exit code 1 if any check fails.
## Written by Claude Code on 21 Nov 2026.

## The course's track check (moved, unchanged, from the old 2D balloon's test).
const TrackCheck := preload("res://tests/track_check.gd")
const SCENE := "res://props/moths.tscn"
const SHEET := "res://assets/sprites/cutebugs/bugs.png"
const FPS := 24.0
const HALF_FRAME := 1.0 / 48.0
const CELLS: Array[int] = [4, 5]
const TIMES: Array[float] = [0.0, 2.0 / 24.0]
const LENGTH := 4.0 / 24.0

var _passed := 0
var _failed := 0


func _initialize() -> void:
	_run()
	print("%d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _check(ok: bool, what: String, detail: String = "") -> void:
	if ok:
		_passed += 1
		print("PASS %s" % what)
	else:
		_failed += 1
		print("FAIL %s%s" % [what, (": " + detail) if detail != "" else ""])


func _near(a: float, b: float) -> bool:
	return absf(a - b) <= HALF_FRAME


func _run() -> void:
	var moths := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(moths)
	var sprites: Array = moths.find_children("*", "Sprite3D", true, false)
	_check(sprites.size() == 4, "four moths", str(sprites.size()))
	var players: Array[AnimationPlayer] = []
	for s: Sprite3D in sprites:
		var label := "%s/%s" % [s.get_parent().name, s.name]
		var sheet := s.texture.resource_path if s.texture else ""
		_check(sheet == SHEET and s.hframes == 4 and s.vframes == 3, "%s: bugs.png, sliced 4 x 3" % label,
			"%s %d x %d" % [sheet, s.hframes, s.vframes])
		_check(absf(s.pixel_size * 8.0 - 0.1) < 0.0001, "%s: 0.1 m across (pixel_size 0.1 / 8)" % label, str(s.pixel_size))
		_check(s.billboard == BaseMaterial3D.BILLBOARD_ENABLED and s.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST,
			"%s: billboarded, nearest filtering" % label, "%d %d" % [s.billboard, s.texture_filter])
		_check(s.get_parent() != moths and s.get_parent().get_parent() == moths, "%s: under its own pivot" % label, label)
		var p := s.get_node_or_null("AnimationPlayer") as AnimationPlayer
		_check(p != null and p.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE and p.autoplay == "",
			"%s: its own AnimationPlayer, callback_mode_process IDLE, autoplay empty" % label,
			"%s" % ("none" if p == null else "%d '%s'" % [p.callback_mode_process, p.autoplay]))
		if p:
			players.append(p)
	if players.is_empty():
		return
	for p in players:
		var problems := TrackCheck.track_problems(p)
		_check(problems.is_empty(), "%s: every track in every clip resolves" % p.get_parent().get_parent().name, "; ".join(problems))

	var player := players[0]
	var sprite := player.get_parent() as Sprite3D
	_check(player.has_animation("flutter"), "the clip flutter exists", str(player.get_animation_list()))
	if not player.has_animation("flutter"):
		return
	var clip := player.get_animation("flutter")
	_check(players.all(func(q: AnimationPlayer) -> bool: return q.get_animation("flutter") == clip),
		"all four play the one flutter resource", "")
	_check(_near(clip.length, LENGTH), "the length is 4/24 s (within 1/48 s)", "%.10f" % clip.length)
	_check(is_equal_approx(clip.step, 1.0 / FPS), "step is 1/24 s", "%.10f" % clip.step)
	_check(clip.loop_mode == Animation.LOOP_LINEAR, "loop_mode is Animation.LOOP_LINEAR", str(clip.loop_mode))
	_check(clip.get_track_count() == 1, "one track", str(clip.get_track_count()))
	if clip.get_track_count() != 1:
		return
	var is_value := clip.track_get_type(0) == Animation.TYPE_VALUE
	_check(is_value, "track 0 is a value track (TYPE_VALUE)", str(clip.track_get_type(0)))
	var path := clip.track_get_path(0)
	var target := player.get_node(player.root_node).get_node_or_null(NodePath(path.get_concatenated_names()))
	_check(target == sprite and path.get_subname_count() == 1 and path.get_subname(0) == "frame", "track 0 is on the Sprite3D's frame", str(path))
	if not is_value:
		return
	_check(clip.value_track_get_update_mode(0) == Animation.UPDATE_DISCRETE, "track 0 uses discrete updates (UPDATE_DISCRETE)",
		str(clip.value_track_get_update_mode(0)))
	var cells: Array = []
	var times: Array = []
	for k in clip.track_get_key_count(0):
		cells.append(clip.track_get_key_value(0, k))
		times.append(clip.track_get_key_time(0, k))
	print("  keys: cells %s at %s s" % [cells, times])
	var inside := cells.all(func(c) -> bool: return typeof(c) == TYPE_INT and c >= 0 and c < sprite.hframes * sprite.vframes)
	_check(inside, "every frame key is a cell inside the sheet (0 to %d)" % (sprite.hframes * sprite.vframes - 1), str(cells))
	_check(cells == CELLS, "the key values are 4, 5", str(cells))
	var times_ok := times.size() == 2 and _near(times[0], TIMES[0]) and _near(times[1], TIMES[1])
	_check(times_ok, "the key times are 0, 2/24 s (within 1/48 s)", str(times))
	if cells.size() == 2 and times.size() == 2:
		_check(cells[-1] != cells[0], "the seam: the last key's cell differs from the first's", "last %s, first %s" % [cells[-1], cells[0]])
		var interval: float = times[1] - times[0]
		var gap: float = clip.length - times[-1]
		_check(_near(gap, interval), "the seam: the gap from the last key to the length equals the key interval",
			"gap %.6f, interval %.6f" % [gap, interval])

	var cfg := ConfigFile.new()
	var err := cfg.load(SHEET + ".import")
	_check(err == OK and int(cfg.get_value("params", "detect_3d/compress_to", -1)) == 0,
		"bugs.png.import: detect_3d/compress_to is 0", str(cfg.get_value("params", "detect_3d/compress_to", "missing")))
