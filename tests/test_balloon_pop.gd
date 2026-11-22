extends SceneTree
## Assignment 7, Step 5 (Step 4 of its plan): the read-back of the balloon's `pop` (CHANGE-BRIEF.md,
## revision of 21 Nov 2026, "The extras' timings and places"), a light one beside
## tests/test_balloon_float.gd. It loads props/party_balloon.tscn and reads back:
##   - every track in every clip resolves (the course's check, as in test_balloon_float.gd);
##   - `pop` beside `float` in the scene's library;
##   - one value track on the Sprite3D's frame, UPDATE_DISCRETE;
##   - keys: cells 3, 4, 5 at 0, 2/24 and 4/24 s, within half a frame (1/48 s), never ==; every
##     cell inside the sheet (below hframes * vframes);
##   - length 6/24 s (within half a frame), step 1/24 s exactly, LOOP_NONE;
##   - a one-shot that ends on its own pose: the last cell differs from the first.
## A headless run draws nothing: this reads the clip's structure, not how the pop looks.
## Run it from the project folder:
##   bash scripts/run-test.sh test_balloon_pop.gd 60
## It prints PASS or FAIL per check and a count, and quits with exit code 1 if any check fails.
## Written by Claude Code on 21 Nov 2026.

const FloatTest := preload("res://tests/test_balloon_float.gd")
const SCENE := "res://props/party_balloon.tscn"
const FPS := 24.0
const HALF_FRAME := 1.0 / 48.0
const CELLS: Array[int] = [3, 4, 5]
const TIMES: Array[float] = [0.0, 2.0 / 24.0, 4.0 / 24.0]
const LENGTH := 6.0 / 24.0

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
	var balloon := (load(SCENE) as PackedScene).instantiate() as Sprite3D
	root.add_child(balloon)
	var player := balloon.get_node("AnimationPlayer") as AnimationPlayer
	var problems := FloatTest.track_problems(player)
	_check(problems.is_empty(), "every track in every clip resolves to a real node and property or bone", "; ".join(problems))
	_check(player.has_animation("pop") and player.has_animation("float"), "`pop` is in the scene's library beside `float`",
		str(player.get_animation_list()))
	if not player.has_animation("pop"):
		return
	var clip := player.get_animation("pop")
	_check(_near(clip.length, LENGTH), "the length is 6/24 s (within 1/48 s)", "%.10f" % clip.length)
	_check(is_equal_approx(clip.step, 1.0 / FPS), "step is 1/24 s", "%.10f" % clip.step)
	_check(clip.loop_mode == Animation.LOOP_NONE, "loop_mode is Animation.LOOP_NONE", str(clip.loop_mode))
	_check(clip.get_track_count() == 1, "one track", str(clip.get_track_count()))
	if clip.get_track_count() != 1:
		return
	var is_value := clip.track_get_type(0) == Animation.TYPE_VALUE
	_check(is_value, "track 0 is a value track (TYPE_VALUE)", str(clip.track_get_type(0)))
	var path := clip.track_get_path(0)
	var target := player.get_node(player.root_node).get_node_or_null(NodePath(path.get_concatenated_names()))
	_check(target == balloon and path.get_subname_count() == 1 and path.get_subname(0) == "frame", "track 0 is on the Sprite3D's frame", str(path))
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
	var inside := cells.all(func(c) -> bool: return typeof(c) == TYPE_INT and c >= 0 and c < balloon.hframes * balloon.vframes)
	_check(inside, "every frame key is a cell inside the sheet (0 to %d)" % (balloon.hframes * balloon.vframes - 1), str(cells))
	_check(cells.size() == 3 and cells == CELLS, "the key values are 3, 4, 5", str(cells))
	var times_ok := times.size() == 3
	for k in mini(times.size(), 3):
		times_ok = times_ok and _near(times[k], TIMES[k])
	_check(times_ok, "the key times are 0, 2/24, 4/24 s (within 1/48 s)", str(times))
	_check(cells.size() > 1 and cells[-1] != cells[0], "a one-shot: it ends on its own cell, not its first", str(cells))
