extends SceneTree
## Assignment 7, Step 4: the read-back of the balloon's float (CHANGE-BRIEF.md, "The evidence
## split": the float row; "The sheet, for each sprite clip"; "The cycle spec: the balloon's float").
## It loads props/party_balloon.tscn and reads back, against the brief's values:
##   - every track in every clip resolves to a real node and property or bone (the course's check,
##     branching on track type);
##   - the float's track: a value track on the Sprite3D's frame, UPDATE_DISCRETE;
##   - every frame key is a cell the sheet has (below hframes * vframes);
##   - the keys: cells 0, 1, 2, 1 at 0, 0.25, 0.5, 0.75 s, within half a frame (1/48 s), never ==;
##   - length 1.0 s, step 1/24 s, LOOP_LINEAR;
##   - the seam for a frame track: the last key's cell differs from the first's, and the gap from
##     the last key to the length equals the key interval;
##   - the Sprite3D: hframes 3, vframes 2, one of the five balloon sheets; the AnimationPlayer:
##     callback_mode_process IDLE, autoplay empty.
## A headless run draws nothing: this reads the clip's structure, not how the float looks.
## Run it from the project folder:
##   bash scripts/run-test.sh test_balloon_float.gd 60
## It prints PASS or FAIL per check and a count, and quits with exit code 1 if any check fails.
## Written by Claude Code on 21 Nov 2026.

const SCENE := "res://props/party_balloon.tscn"
const CLIP := "float"
const FPS := 24.0
const HALF_FRAME := 1.0 / 48.0
const HFRAMES := 3
const VFRAMES := 2
const CELLS: Array[int] = [0, 1, 2, 1]
const TIMES: Array[float] = [0.0, 0.25, 0.5, 0.75]
const LENGTH := 1.0
const SHEETS: Array[String] = [
	"res://assets/sprites/balloons/balloon_red_4.png",
	"res://assets/sprites/balloons/balloon_yellow.png",
	"res://assets/sprites/balloons/balloon_green_4.png",
	"res://assets/sprites/balloons/balloon_purple_2.png",
	"res://assets/sprites/balloons/balloon_blue_4.png",
]

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
	var packed := load(SCENE) as PackedScene
	_check(packed != null, "the scene %s loads" % SCENE)
	if packed == null:
		return
	var balloon := packed.instantiate()
	root.add_child(balloon)

	var sprite := balloon as Sprite3D
	_check(sprite != null and balloon.name == "Balloon", "the scene's root is a Sprite3D named Balloon",
			"%s %s" % [balloon.get_class(), balloon.name])
	var player := balloon.get_node_or_null("AnimationPlayer") as AnimationPlayer
	_check(player != null, "the Balloon has an AnimationPlayer")
	if sprite == null or player == null:
		return

	# The sheet and the node.
	_check(sprite.hframes == HFRAMES, "hframes is %d" % HFRAMES, str(sprite.hframes))
	_check(sprite.vframes == VFRAMES, "vframes is %d" % VFRAMES, str(sprite.vframes))
	var sheet := sprite.texture.resource_path if sprite.texture != null else ""
	_check(sheet in SHEETS, "the texture is one of the five balloon sheets", sheet)
	_check(player.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE,
			"callback_mode_process is ANIMATION_CALLBACK_MODE_PROCESS_IDLE", str(player.callback_mode_process))
	_check(player.autoplay == "", "autoplay is empty", "'%s'" % player.autoplay)

	# Every track of every clip resolves.
	var problems := track_problems(player)
	_check(problems.is_empty(), "every track in every clip resolves to a real node and property or bone",
			"; ".join(problems))

	# The float.
	_check(player.has_animation(CLIP), "the clip %s exists" % CLIP, str(player.get_animation_list()))
	if not player.has_animation(CLIP):
		return
	var clip := player.get_animation(CLIP)
	_check(_near(clip.length, LENGTH), "the length is 1.0 s (within 1/48 s)", "%.10f" % clip.length)
	_check(_near(clip.step, 1.0 / FPS), "step is 1/24 s (within 1/48 s)", "%.10f" % clip.step)
	_check(clip.loop_mode == Animation.LOOP_LINEAR, "loop_mode is Animation.LOOP_LINEAR", str(clip.loop_mode))
	_check(clip.get_track_count() == 1, "the float has one track", str(clip.get_track_count()))
	if clip.get_track_count() < 1:
		return

	var t := 0
	var is_value := clip.track_get_type(t) == Animation.TYPE_VALUE
	_check(is_value, "track 0 is a value track (TYPE_VALUE)", str(clip.track_get_type(t)))
	var path := clip.track_get_path(t)
	var target := player.get_node(player.root_node).get_node_or_null(NodePath(path.get_concatenated_names()))
	var on_frame := target == sprite and path.get_subname_count() == 1 and path.get_subname(0) == "frame"
	_check(on_frame, "track 0 is on the Sprite3D's frame", str(path))
	if not is_value:
		return
	# value_track_get_update_mode only of a value track (CLAUDE.md, "Headless facts").
	_check(clip.value_track_get_update_mode(t) == Animation.UPDATE_DISCRETE,
			"track 0 uses discrete updates (UPDATE_DISCRETE)", str(clip.value_track_get_update_mode(t)))

	var count := clip.track_get_key_count(t)
	var cells: Array = []
	var times: Array = []
	for k in count:
		cells.append(clip.track_get_key_value(t, k))
		times.append(clip.track_get_key_time(t, k))
	print("  keys: cells %s at %s s" % [cells, times])

	var inside := true
	for c in cells:
		if typeof(c) != TYPE_INT or c < 0 or c >= sprite.hframes * sprite.vframes:
			inside = false
	_check(inside, "every frame key is a cell inside the sheet (0 to %d)" % (sprite.hframes * sprite.vframes - 1),
			str(cells))

	_check(count == CELLS.size(), "the float has %d keys" % CELLS.size(), str(count))
	if count != CELLS.size():
		return
	var values_ok := true
	var times_ok := true
	for k in count:
		if typeof(cells[k]) != TYPE_INT or cells[k] != CELLS[k]:
			values_ok = false
		if not _near(times[k], TIMES[k]):
			times_ok = false
	_check(values_ok, "the key values are 0, 1, 2, 1", str(cells))
	_check(times_ok, "the key times are 0, 0.25, 0.5, 0.75 s (within 1/48 s)", str(times))

	# The seam rule for a frame track: no duplicate across the wrap, and the last gap equals the
	# key interval.
	_check(cells[count - 1] != cells[0], "the seam: the last key's cell differs from the first's",
			"last %s, first %s" % [cells[count - 1], cells[0]])
	var interval: float = times[1] - times[0]
	var gap: float = clip.length - times[count - 1]
	_check(_near(gap, interval), "the seam: the gap from the last key to the length equals the key interval",
			"gap %.6f, interval %.6f" % [gap, interval])


## The course's track check, as given.
static func track_problems(player: AnimationPlayer) -> Array[String]:
	var problems: Array[String] = []
	var root := player.get_node_or_null(player.root_node)
	if root == null:
		problems.append("root_node %s resolves to nothing" % player.root_node)
		return problems
	for clip_name in player.get_animation_list():
		var clip := player.get_animation(clip_name)
		for t in clip.get_track_count():
			var path := clip.track_get_path(t)
			var node := root.get_node_or_null(NodePath(path.get_concatenated_names()))
			if node == null:
				problems.append("%s track %d: no node at %s" % [clip_name, t, path])
				continue
			if path.get_subname_count() == 0:
				continue
			var sub := path.get_subname(0)
			match clip.track_get_type(t):
				Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D:
					var skeleton := node as Skeleton3D
					if skeleton == null or skeleton.find_bone(sub) == -1:
						problems.append("%s track %d: no bone %s on %s" % [clip_name, t, sub, node.name])
				Animation.TYPE_BLEND_SHAPE:
					var mesh := node as MeshInstance3D
					if mesh == null or mesh.find_blend_shape_by_name(sub) == -1:
						problems.append("%s track %d: no blend shape %s on %s" % [clip_name, t, sub, node.name])
				_:
					if not (sub in node):
						problems.append("%s track %d: %s has no property %s" % [clip_name, t, node.name, sub])
	return problems
