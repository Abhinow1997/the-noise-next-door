extends SceneTree
## Assignment 7, Step 4: the read-back of the raccoon's rig (CHANGE-BRIEF.md, "The evidence split":
## the first two rows; "The phase table: the jump" and its 21 Nov revision).
## It loads assets/characters/raccoon_v2.glb as imported (no game script runs on it, so the loop
## modes it sees are the importer's, from raccoon_v2.glb.import's _subresources) and reads back:
##   - every track in every clip resolves to a real node and property, bone or blend shape (the
##     course's check, as in tests/test_balloon_float.gd, branching on track type);
##   - all nine clips exist;
##   - jump's length is 12/24 s and jump_land's 4/24 s (within half a frame); every clip's step is
##     1/24 s exactly (is_equal_approx);
##   - jump has keys at frames 0, 2, 4, 6 and 12, and jump_land at 0 and 4, within half a frame
##     (1/48 s), never ==, on every track not held through that frame (the importer drops the keys
##     of a hold); each key time is printed beside the frame it comes from;
##   - jump's last pose is its own, not a copy of its first (a one-shot);
##   - loop modes: the seven loops LOOP_LINEAR, jump and jump_land LOOP_NONE;
##   - value_track_get_update_mode asked only of value tracks (CLAUDE.md, "Headless facts").
## The exporter samples every frame, so a track that moves has a key on nearly every frame: the key
## check proves the boundary frames are on the 24 fps grid, not which frames were posed in Blender.
## A headless run draws nothing: this reads the clips' structure, not how the jump looks.
## Run it from the project folder:
##   bash scripts/run-test.sh test_raccoon_rig.gd 60
## For the empty-cache check, delete .godot/, run --import, then this.
## It prints PASS or FAIL per check and a count, and quits with exit code 1 if any check fails.
## Written by Claude Code on 21 Nov 2026.

const RIG := "res://assets/characters/raccoon_v2.glb"
const FPS := 24.0
const HALF_FRAME := 1.0 / 48.0
const LOOPS: Array[String] = ["idle", "walk", "run", "sneak", "bored", "sleep", "climb"]
const ONE_SHOTS: Array[String] = ["jump", "jump_land"]
## Each one-shot's length and the phase table's frames it must have keys on.
const FRAMES := {"jump": 12, "jump_land": 4}
const KEY_FRAMES := {"jump": [0, 2, 4, 6, 12], "jump_land": [0, 4]}

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


func _find_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_player(child)
		if found != null:
			return found
	return null


func _run() -> void:
	var packed := load(RIG) as PackedScene
	_check(packed != null, "the rig %s loads" % RIG)
	if packed == null:
		return
	var rig := packed.instantiate()
	root.add_child(rig)
	var player := _find_player(rig)
	_check(player != null, "the rig has an AnimationPlayer")
	if player == null:
		return

	# Every track of every clip resolves.
	var problems := track_problems(player)
	_check(problems.is_empty(), "every track in every clip resolves to a real node and property, bone or blend shape",
			"; ".join(problems))

	# All nine clips.
	var missing: Array[String] = []
	for clip_name in LOOPS + ONE_SHOTS:
		if not player.has_animation(clip_name):
			missing.append(clip_name)
	_check(missing.is_empty(), "all nine clips exist (%s)" % ", ".join(LOOPS + ONE_SHOTS),
			"missing %s; the list is %s" % [missing, player.get_animation_list()])

	for clip_name in LOOPS + ONE_SHOTS:
		if not player.has_animation(clip_name):
			continue
		var clip := player.get_animation(clip_name)
		print("  %s: %d tracks, length %.10f s, step %.10f s, loop_mode %d" % [
				clip_name, clip.get_track_count(), clip.length, clip.step, clip.loop_mode])
		# step exactly, not within half a frame: the default 1/30 s is only 0.008 s from 1/24 s.
		_check(is_equal_approx(clip.step, 1.0 / FPS), "%s: step is 1/24 s" % clip_name, "%.10f" % clip.step)
		var want_loop := Animation.LOOP_LINEAR if clip_name in LOOPS else Animation.LOOP_NONE
		_check(clip.loop_mode == want_loop, "%s: loop_mode is Animation.%s" % [
				clip_name, "LOOP_LINEAR" if want_loop == Animation.LOOP_LINEAR else "LOOP_NONE"],
				str(clip.loop_mode))
		_check_update_modes(clip_name, clip)

	for clip_name in ONE_SHOTS:
		if player.has_animation(clip_name):
			_check_one_shot(clip_name, player.get_animation(clip_name))


## A one-shot's length, its keys on the phase table's frames, and its last pose its own.
func _check_one_shot(clip_name: String, clip: Animation) -> void:
	var frames: int = FRAMES[clip_name]
	_check(_near(clip.length, frames / FPS), "%s: length is %d/24 s (%.4f s, within 1/48 s)" % [
			clip_name, frames, frames / FPS], "%.10f" % clip.length)
	if clip.get_track_count() == 0:
		_check(false, "%s: has tracks" % clip_name, "none")
		return

	# The keys of the first track, each beside the frame it comes from.
	var t0 := 0
	var listed: Array[String] = []
	for k in clip.track_get_key_count(t0):
		var time := clip.track_get_key_time(t0, k)
		listed.append("frame %d at %.10f s" % [roundi(time * FPS), time])
	print("  %s keys on track 0 (%s): %s" % [clip_name, clip.track_get_path(t0), ", ".join(listed)])

	# The phase table's frames: the clip has a key within half a frame of each, on every track
	# that changes there. The importer drops keys a track doesn't need, so a track held through a
	# frame (the eyes open from frame 4 to 12, say) has none there: it passes only if its keys
	# either side of the frame hold the same value.
	var wanted: Array = KEY_FRAMES[clip_name]
	var missing: Array[String] = []
	for f in wanted:
		var target: float = f / FPS
		var keyed := 0
		var held: Array[String] = []
		var first_time := -1.0
		for t in clip.get_track_count():
			var before := -1
			var after := -1
			var found := -1.0
			for k in clip.track_get_key_count(t):
				var time := clip.track_get_key_time(t, k)
				if _near(time, target):
					found = time
					break
				if time < target:
					before = k
				elif after == -1:
					after = k
			if found >= 0.0:
				keyed += 1
				if first_time < 0.0:
					first_time = found
			elif before != -1 and after != -1 and _same(
					clip.track_get_key_value(t, before), clip.track_get_key_value(t, after)):
				held.append(str(clip.track_get_path(t)).get_slice(":", 1))
			else:
				missing.append("frame %d on %s" % [f, clip.track_get_path(t)])
		print("  %s frame %d (%.10f s): key at %s s on %d of %d tracks%s" % [clip_name, f, target,
				("%.10f" % first_time) if first_time >= 0.0 else "none", keyed, clip.get_track_count(),
				(", held through it on %s" % ", ".join(held)) if not held.is_empty() else ""])
	_check(missing.is_empty(),
			"%s: keys at frames %s (within 1/48 s) on every track that isn't held through them" % [clip_name, wanted],
			"; ".join(missing.slice(0, 6)) + (" (and %d more)" % (missing.size() - 6) if missing.size() > 6 else ""))

	# A one-shot ends on its own pose: some track's last key differs from its first.
	var differs := 0
	for t in clip.get_track_count():
		var n := clip.track_get_key_count(t)
		if n < 2:
			continue
		var a: Variant = clip.track_get_key_value(t, 0)
		var b: Variant = clip.track_get_key_value(t, n - 1)
		if not _same(a, b):
			differs += 1
	_check(differs > 0, "%s: its last pose is its own, not a copy of its first (%d of %d tracks differ)" % [
			clip_name, differs, clip.get_track_count()], "every track ends where it starts")


func _same(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b):
		return false
	match typeof(a):
		TYPE_VECTOR3:
			return (a as Vector3).is_equal_approx(b)
		TYPE_QUATERNION:
			return (a as Quaternion).is_equal_approx(b) or (a as Quaternion).is_equal_approx(-(b as Quaternion))
		TYPE_FLOAT:
			return is_equal_approx(a, b)
	return a == b


## value_track_get_update_mode only of value tracks: on a bone track it prints an ERROR.
func _check_update_modes(clip_name: String, clip: Animation) -> void:
	var values := 0
	var modes: Array[String] = []
	for t in clip.get_track_count():
		if clip.track_get_type(t) != Animation.TYPE_VALUE:
			continue
		values += 1
		modes.append("%s %d" % [clip.track_get_path(t), clip.value_track_get_update_mode(t)])
	if values == 0:
		print("  %s: no value tracks, so no update mode to ask" % clip_name)
	else:
		print("  %s: value tracks' update modes: %s" % [clip_name, ", ".join(modes)])
	_check(true, "%s: update mode asked only of value tracks (%d)" % [clip_name, values])


## The course's track check, as given (as in tests/test_balloon_float.gd).
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
