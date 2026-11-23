extends SceneTree
## The 3D balloons' read-back (CHANGE-BRIEF.md, revisions of 21 Nov 2026, "the balloons are 3D, and
## the moth is the graded sprite clip" and "the balloon task is 'Let the balloons go'"; not
## graded): a light one. It loads props/party_balloon.tscn and props/balloon_bunch.tscn and reads
## back:
##   - the balloon: a Node3D named Balloon with its script; no Sprite3D; its Float node with the
##     Body and String meshes, built (low-poly, the camp's matte material); no collision; hidden
##     until it's blown up; its own AnimationPlayer, callback_mode_process IDLE, autoplay empty,
##     with `inflate` and `bob` and no `pop` (it went with the bite);
##   - the bunch: a Node3D named Bunch with a Lift node and its own AnimationPlayer (IDLE,
##     autoplay empty) with `float_away`, and no script (camp_balloons.gd plays it);
##   - every track in every clip resolves (the course's check, tests/track_check.gd); the
##     balloon's tracks move only Float, never its own node; the bunch's only Lift;
##   - `inflate`: LOOP_NONE, step 1/24 s exactly, length 3.0 s (within half a frame), from a
##     small bud (its first scale key under a fifth) to full size (its last 1);
##   - `bob`: LOOP_LINEAR, step 1/24 s exactly, length 2.0 s;
##   - `float_away`: LOOP_NONE, step 1/24 s exactly, length 5.0 s, rising about 8 m (its last
##     position key 7.5-8.5 m above its first), its visible track discrete, shown then hidden;
##   - played through (the game's way: inflate() on the balloon; play() on the bunch's player, as
##     camp_balloons.gd does): the balloon shows, swells to full size, then plays `bob`; the
##     bunch ends 8 m up and hidden.
## A headless run draws nothing: this reads the balloons' structure and clips, not how they look.
## Run it from the project folder:
##   bash scripts/run-test.sh test_balloon_3d.gd 60
## It prints PASS or FAIL per check and a count, and quits with exit code 1 if any check fails.
## Written by Claude Code on 21 Nov 2026.

const TrackCheck := preload("res://tests/track_check.gd")
const LowPoly := preload("res://scripts/lowpoly.gd")
const SCENE := "res://props/party_balloon.tscn"
const BUNCH := "res://props/balloon_bunch.tscn"
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


func _frames(n: int) -> void:
	for i in n:
		await process_frame


## A clip's loop mode, step (exactly) and length (within half a frame).
func _clip(player: AnimationPlayer, clip_name: String, loop: int, length: float) -> Animation:
	_check(player.has_animation(clip_name), "the clip %s exists" % clip_name, str(player.get_animation_list()))
	if not player.has_animation(clip_name):
		return null
	var clip := player.get_animation(clip_name)
	print("  %s: %d tracks, length %.10f s, step %.10f s, loop_mode %d" % [clip_name, clip.get_track_count(), clip.length, clip.step, clip.loop_mode])
	_check(clip.loop_mode == loop, "%s: loop_mode is %s" % [clip_name, "LOOP_LINEAR" if loop == Animation.LOOP_LINEAR else "LOOP_NONE"],
		str(clip.loop_mode))
	_check(is_equal_approx(clip.step, 1.0 / FPS), "%s: step is 1/24 s" % clip_name, "%.10f" % clip.step)
	_check(_near(clip.length, length), "%s: length is %.4f s (within 1/48 s)" % [clip_name, length], "%.10f" % clip.length)
	return clip


func _track(clip: Animation, path: String) -> int:
	for t in clip.get_track_count():
		if str(clip.track_get_path(t)) == path:
			return t
	return -1


## Every track of every clip of `player` resolves, and each begins with `prefix`.
func _tracks(player: AnimationPlayer, label: String, prefix: String) -> void:
	var problems := TrackCheck.track_problems(player)
	_check(problems.is_empty(), "%s: every track in every clip resolves to a real node and property or bone" % label, "; ".join(problems))
	var paths: Array[String] = []
	for clip_name in player.get_animation_list():
		var clip := player.get_animation(clip_name)
		for t in clip.get_track_count():
			paths.append(str(clip.track_get_path(t)))
	_check(paths.size() > 0 and paths.all(func(p: String) -> bool: return p.begins_with(prefix)),
		"%s: every track moves only %s (%s)" % [label, prefix.trim_suffix(":").trim_suffix("/"), ", ".join(paths)], "")


func _run() -> void:
	# --- The balloon ----------------------------------------------------------------
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
	_check(not (balloon as Node3D).visible and player.current_animation == "",
		"not blown up yet: hidden, and playing nothing", "visible %s, %s" % [(balloon as Node3D).visible, player.current_animation])
	_check(not player.has_animation("pop"), "no `pop` (it went with the bite)", str(player.get_animation_list()))
	_tracks(player, "the balloon", "Float:")

	var inflate := _clip(player, "inflate", Animation.LOOP_NONE, 3.0)
	if inflate:
		var t := _track(inflate, "Float:scale")
		var n := inflate.track_get_key_count(t) if t >= 0 else 0
		var first: Vector3 = inflate.track_get_key_value(t, 0) if n > 0 else Vector3.ONE
		var last: Vector3 = inflate.track_get_key_value(t, n - 1) if n > 0 else Vector3.ZERO
		_check(n >= 2 and first.x < 0.2 and first.y < 0.2 and last.is_equal_approx(Vector3.ONE),
			"inflate: from a small bud (scale %s) to full size (%s)" % [first, last], "")
	_clip(player, "bob", Animation.LOOP_LINEAR, 2.0)

	# Played through, the game's way (camp_balloons.gd calls inflate()).
	balloon.call("inflate")
	await _frames(2)
	var float_node := balloon.get_node("Float") as Node3D
	var small := float_node.scale.x
	_check((balloon as Node3D).visible and player.current_animation == "inflate" and small < 0.3,
		"inflate(): it shows and swells from a bud (scale %.3f)" % small, "%s" % player.current_animation)
	await _frames(int(3.0 * 60) + 10)
	_check(player.current_animation == "bob" and float_node.scale.is_equal_approx(Vector3.ONE),
		"after 3 s: full size (scale %s), and bobbing" % float_node.scale, player.current_animation)

	# --- The bunch ------------------------------------------------------------------
	var packed_bunch := load(BUNCH) as PackedScene
	_check(packed_bunch != null, "the scene %s loads" % BUNCH)
	if packed_bunch == null:
		return
	var bunch := packed_bunch.instantiate()
	root.add_child(bunch)
	await process_frame
	var lift := bunch.get_node_or_null("Lift") as Node3D
	var bunch_player := bunch.get_node_or_null("AnimationPlayer") as AnimationPlayer
	_check(bunch.get_class() == "Node3D" and bunch.name == "Bunch" and bunch.get_script() == null and lift != null,
		"its root is a Node3D named Bunch, with a Lift node and no script", "")
	_check(bunch_player != null and bunch_player.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE
		and bunch_player.autoplay == "", "its own AnimationPlayer, callback_mode_process IDLE, autoplay empty", "")
	if bunch_player == null or lift == null:
		return
	_tracks(bunch_player, "the bunch", "Lift:")
	var away := _clip(bunch_player, "float_away", Animation.LOOP_NONE, 5.0)
	if away:
		var p := _track(away, "Lift:position")
		var n := away.track_get_key_count(p) if p >= 0 else 0
		var rise: float = (away.track_get_key_value(p, n - 1) as Vector3).y - (away.track_get_key_value(p, 0) as Vector3).y if n >= 2 else 0.0
		_check(rise > 7.5 and rise < 8.5, "float_away: rises about 8 m (%.2f m)" % rise, "")
		var v := _track(away, "Lift:visible")
		var vn := away.track_get_key_count(v) if v >= 0 else 0
		_check(v >= 0 and away.value_track_get_update_mode(v) == Animation.UPDATE_DISCRETE and vn >= 2
			and away.track_get_key_value(v, 0) == true and away.track_get_key_value(v, vn - 1) == false,
			"float_away: its visible track is discrete, shown then hidden at the end", "")

	# Played through, as camp_balloons.gd plays it.
	bunch_player.play("float_away")
	await _frames(int(2.5 * 60))
	var mid := lift.position.y
	_check(lift.visible and mid > 2.0 and mid < 6.0, "float_away, halfway: rising (%.2f m up), still showing" % mid, "")
	await _frames(int(2.5 * 60) + 10)
	_check(not lift.visible and absf(lift.position.y - 8.0) < 0.05,
		"float_away, done: 8 m up (%.2f m) and gone" % lift.position.y, "visible %s" % lift.visible)
