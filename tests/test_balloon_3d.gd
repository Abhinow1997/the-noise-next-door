extends SceneTree
## The 3D balloon's read-back (CHANGE-BRIEF.md, revision of 21 Nov 2026, "the balloons are 3D, and
## the moth is the graded sprite clip"; not graded): a light one, in place of the 2D balloon's
## tests/test_balloon_float.gd and tests/test_balloon_pop.gd. It loads props/party_balloon.tscn
## and reads back:
##   - the scene: a Node3D named Balloon with its script; no Sprite3D; its Float node with the
##     Body and String meshes, built (low-poly, the camp's matte material); no collision; its
##     own AnimationPlayer, callback_mode_process IDLE, autoplay empty;
##   - every track in every clip resolves (the course's check, tests/track_check.gd), and every
##     track moves only Float, never the balloon's own node (where the bite measures from);
##   - `bob`: LOOP_LINEAR, step 1/24 s exactly, length 2.0 s (within half a frame);
##   - `pop`: LOOP_NONE, step 1/24 s exactly, length 3/24 s (within half a frame), and it swells
##     (its last scale key larger than its first).
## A headless run draws nothing: this reads the balloon's structure and clips, not how it looks.
## Run it from the project folder:
##   bash scripts/run-test.sh test_balloon_3d.gd 60
## It prints PASS or FAIL per check and a count, and quits with exit code 1 if any check fails.
## Written by Claude Code on 21 Nov 2026.

const TrackCheck := preload("res://tests/track_check.gd")
const LowPoly := preload("res://scripts/lowpoly.gd")
const SCENE := "res://props/party_balloon.tscn"
const FPS := 24.0
const HALF_FRAME := 1.0 / 48.0

var _passed := 0
var _failed := 0


func _initialize() -> void:
	_go()


func _go() -> void:
	await _run()
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
	# Its script builds the meshes in _ready, once it's in the running tree.
	await process_frame
	_check(balloon.get_class() == "Node3D" and balloon.name == "Balloon" and balloon.get_script() != null,
		"its root is a Node3D named Balloon, with its script", "%s %s" % [balloon.get_class(), balloon.name])
	_check(balloon.find_children("*", "Sprite3D", true, false).is_empty() and not balloon is Sprite3D, "no Sprite3D", "")
	var body := balloon.get_node_or_null("Float/Body") as MeshInstance3D
	var string := balloon.get_node_or_null("Float/String") as MeshInstance3D
	_check(body != null and body.mesh != null and string != null and string.mesh != null,
		"its Float node holds the Body and String meshes, built", "")
	if body and body.mesh:
		_check(body.mesh.surface_get_material(0) == LowPoly.material(), "low-poly: the camp's one matte material (scripts/lowpoly.gd)", "")
	var bodies := balloon.find_children("*", "CollisionObject3D", true, false).size() + balloon.find_children("*", "CollisionShape3D", true, false).size()
	_check(bodies == 0, "no collision", str(bodies))
	var player := balloon.get_node_or_null("AnimationPlayer") as AnimationPlayer
	_check(player != null and player.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE and player.autoplay == "",
		"its own AnimationPlayer, callback_mode_process IDLE, autoplay empty", "")
	if player == null:
		return

	var problems := TrackCheck.track_problems(player)
	_check(problems.is_empty(), "every track in every clip resolves to a real node and property or bone", "; ".join(problems))
	var paths: Array[String] = []
	for clip_name in player.get_animation_list():
		var clip := player.get_animation(clip_name)
		for t in clip.get_track_count():
			paths.append(str(clip.track_get_path(t)))
	_check(paths.size() > 0 and paths.all(func(p: String) -> bool: return p.begins_with("Float:")),
		"every track moves only Float, never the balloon's own node (%s)" % ", ".join(paths), "")

	for want: Array in [["bob", Animation.LOOP_LINEAR, 2.0], ["pop", Animation.LOOP_NONE, 3.0 / 24.0]]:
		var clip_name: String = want[0]
		_check(player.has_animation(clip_name), "the clip %s exists" % clip_name, str(player.get_animation_list()))
		if not player.has_animation(clip_name):
			continue
		var clip := player.get_animation(clip_name)
		print("  %s: %d tracks, length %.10f s, step %.10f s, loop_mode %d" % [clip_name, clip.get_track_count(), clip.length, clip.step, clip.loop_mode])
		_check(clip.loop_mode == want[1], "%s: loop_mode is %s" % [clip_name, "LOOP_LINEAR" if want[1] == Animation.LOOP_LINEAR else "LOOP_NONE"],
			str(clip.loop_mode))
		_check(is_equal_approx(clip.step, 1.0 / FPS), "%s: step is 1/24 s" % clip_name, "%.10f" % clip.step)
		_check(_near(clip.length, want[2]), "%s: length is %.4f s (within 1/48 s)" % [clip_name, want[2]], "%.10f" % clip.length)
	if player.has_animation("pop"):
		var pop := player.get_animation("pop")
		var n := pop.track_get_key_count(0)
		var grows: bool = n >= 2 and (pop.track_get_key_value(0, n - 1) as Vector3).x > (pop.track_get_key_value(0, 0) as Vector3).x
		_check(grows, "pop: it swells (its last scale key larger than its first)", "")
