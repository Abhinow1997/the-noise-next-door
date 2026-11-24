extends SceneTree
## The keeper's box (scripts/camp_box.gd, keeper_box.gd, 23 Nov 2026): dragging it about, hiding in
## it, rustling it, and Scare a camper.
##
## In the real level (main.tscn at the developer menu's "fire" point, the camp's tasks revealed), with
## the campers blind to him (campsite.gd `cones_on` off, as `--dev-unseen` has them); driven through
## the game loop with real key presses (Input.parse_input_event, and the move keys through
## Input.action_press), read each physics tick after the game's. It checks:
##   - the task: on the camp's list, "Scare a camper", its hint 5 words at most;
##   - to start with: the box near the camp's edge, inside its clearing; its top two flaps, shut;
##   - it's three-quarters of the model's size;
##   - E held at its side takes it in his jaws, playing `drag`; with E held the move keys pull it back
##     with him, light (about DRAG_SPEED), push it ahead, and take it sideways; letting go of E lets
##     go, and it stays; pushed against the green tent, it stops there;
##   - walking into it, he dives in, hidden, his eyes peeking out from under a flap; its keys show over
##     it: F, "Make noise", and E, "Jump out";
##   - with nobody near, E pops him out: nobody's frightened and the task isn't done;
##   - by the fire, F in it: it shakes, and the nearest camper who hears it comes up to it and bends
##     over it; F is dim till it can rustle again, and E says "Scare!" while they're there; then E
##     bursts him out at them: they take fright, Scare a camper is done, and the keys are gone.
## Run it from the project folder:
##   bash scripts/run-test.sh test_box_scare.gd 60
## It prints PASS or FAIL per check and a count, and quits with exit code 1 if any check fails.
## Written by Claude Code on 23 Nov 2026.

signal ticked

const DevMenu := preload("res://scripts/dev_menu.gd")
const Campsite := preload("res://scripts/campsite.gd")
const KeeperBox := preload("res://scripts/keeper_box.gd")
const CampBox := preload("res://scripts/camp_box.gd")
const CampPerson := preload("res://scripts/camp_person.gd")
const Forest := preload("res://scripts/forest.gd")
const MOVES := ["move_left", "move_right", "move_forward", "move_back"]
## How far off its side he stands to take it in his jaws (m): within E's reach of it, his nose short of
## the box (walking into it dives him in).
const GRIP_FROM := 0.55

var level: Node
var camp: Node
var player: CharacterBody3D
var box: KeeperBox
var task_node: CampBox

var _checks := 0
var _failed := 0


func _initialize() -> void:
	var probe := Probe.new()
	probe.test = self
	probe.process_physics_priority = 1000
	root.add_child(probe)
	DevMenu._next = "fire"
	level = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	print("The keeper's box and Scare a camper: the real level at the developer menu's \"fire\" point, %d physics"
		% Engine.physics_ticks_per_second + " ticks a second")
	_run()


class Probe extends Node:
	var test: Object

	func _physics_process(_delta: float) -> void:
		test.call("step")


func step() -> void:
	if player == null and level and level.get("player") and level.get("campsite") \
			and level.campsite.get("box_task"):
		camp = level.campsite
		task_node = camp.box_task
		box = camp.keeper_box
		player = level.player
	ticked.emit()


func _check(what: String, ok: bool, got: Variant = "") -> void:
	_checks += 1
	if not ok:
		_failed += 1
	print("%s  %s  (got %s)" % ["PASS" if ok else "FAIL", what, str(got)])


func _key(keycode: int, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode as Key
	ev.physical_keycode = keycode as Key
	ev.pressed = pressed
	Input.parse_input_event(ev)


## A quick press of a key: down for two ticks, then up.
func _tap(keycode: int) -> void:
	_key(keycode, true)
	await _wait(2)
	_key(keycode, false)
	await _wait(2)


func _wait(n: int) -> void:
	for i in n:
		await ticked


func _until(cond: Callable, most: int) -> bool:
	for i in most:
		if cond.call():
			return true
		await ticked
	return cond.call()


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## Puts him at `from`, facing `at` (he faces his -Z).
func _stand(from: Vector3, at: Vector3) -> void:
	player.call("place", Vector3(from.x, 0.02, from.z))
	player.rotation.y = atan2(-(at.x - from.x), -(at.z - from.z))
	player.velocity = Vector3.ZERO


## Holds the move keys that point him along `way` on the ground (turned by the camera's yaw, as
## player.gd `_input_dir` turns them); `way` zero lets them go.
func _move(way: Vector3) -> void:
	for action: String in MOVES:
		Input.action_release(action)
	if way == Vector3.ZERO:
		return
	var keys := way.normalized().rotated(Vector3.UP, -level.camera.global_rotation.y)
	if keys.x > 0.01:
		Input.action_press("move_right", keys.x)
	elif keys.x < -0.01:
		Input.action_press("move_left", -keys.x)
	if keys.z > 0.01:
		Input.action_press("move_back", keys.z)
	elif keys.z < -0.01:
		Input.action_press("move_forward", -keys.z)


## How many of the model's faces face up (its top is the flaps instead).
func _faces_up(model: MeshInstance3D) -> int:
	var arrays := model.mesh.surface_get_arrays(0)
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var up := 0
	for t in int(index.size() / 3.0):
		if (model.transform.basis * normals[index[t * 3]]).normalized().y > 0.99:
			up += 1
	return up


## Stands him `gap` metres off the box's side along `out` (level, a side's outward way), facing it.
func _by_side(out: Vector3, gap: float) -> void:
	var half: float = absf((box.global_basis.inverse() * out).x) * KeeperBox.SIZE.x * 0.5 \
		+ absf((box.global_basis.inverse() * out).z) * KeeperBox.SIZE.z * 0.5
	_stand(box.global_position + out * (half + gap), box.global_position)


## True if the box's keys are F saying `f`, then E saying `e`.
func _keys_say(keys: Array, f: String, e: String) -> bool:
	return keys.size() == 2 and keys[0].key == "F" and keys[0].text == f and keys[1].key == "E" and keys[1].text == e


func _keys_text(keys: Array) -> String:
	var parts: Array[String] = []
	for row: Dictionary in keys:
		parts.append("%s %s%s" % [row.key, row.text, "" if row.ready else " (dim)"])
	return "none" if parts.is_empty() else ", ".join(parts)


## Walks him into the box from `out` (level) and waits till he's in it and peeking.
func _dive_in(out: Vector3) -> bool:
	_by_side(out, 0.9)
	await _wait(5)
	_move(-out)
	var dived := await _until(func() -> bool: return player.get("hiding_in") == box.hide_spot, 120)
	_move(Vector3.ZERO)
	await _until(func() -> bool: return box.hide_spot.peeking(), 60)
	return dived


func _run() -> void:
	await _until(func() -> bool: return player != null, 60)
	camp.set("cones_on", false)
	await _wait(30)
	var tasks = level.tasks
	var task: Dictionary = {}
	for t: Dictionary in tasks.list:
		if t.id == "scare":
			task = t
	_check("the task is on the camp's list: \"Scare a camper\"", task.get("text", "") == "Scare a camper" \
		and task.get("camp", false) and tasks.shown().has(task), task.get("text", "(none)"))
	var hint: String = task.get("hint", "")
	_check("its hint is 5 words at most: \"%s\"" % hint, hint != "" and hint.split(" ", false).size() <= 5,
		hint.split(" ", false).size())

	# To start with.
	var home: Vector3 = KeeperBox.spot(Campsite.FIRE)
	var out_from_middle: float = Vector2(box.global_position.x, box.global_position.z).distance_to(Forest.CAMP)
	var model: MeshInstance3D = box.find_children("Box1", "", true, false)[0]
	_check("to start with: the box near the camp's edge, inside its clearing, its top two flaps, shut",
		_flat(box.global_position, home) < 0.05 and out_from_middle > 7.5 and out_from_middle < Forest.CAMP_RADIUS - 1.5
		and _faces_up(model) == 0 and box.opened() == 0.0 and not box.hide_spot.peeking(),
		"%.2f m from its place, %.1f m from the camp's middle (its trees from %.1f m), faces up %d, open %.2f" % [
			_flat(box.global_position, home), out_from_middle, Forest.CAMP_RADIUS, _faces_up(model), box.opened()])
	# Smaller than the model (after play: "reduce its size"): its walls measured as shown.
	var shown: AABB = box.global_transform.affine_inverse() * model.global_transform * model.mesh.get_aabb()
	_check("it's three-quarters of the model's size: %.2f × %.2f m, %.2f m tall" % [KeeperBox.SIZE.x, KeeperBox.SIZE.z,
		KeeperBox.SIZE.y], shown.size.is_equal_approx(KeeperBox.SIZE) or (shown.size - KeeperBox.SIZE).length() < 0.005,
		"%.3f × %.3f m, %.3f m tall" % [shown.size.x, shown.size.z, shown.size.y])

	# Dragging it: E held at its side, with the move keys, any way, light.
	var side: Vector3 = box.global_basis.x
	side = Vector3(side.x, 0, side.z).normalized()
	var across: Vector3 = box.global_basis.z
	across = Vector3(across.x, 0, across.z).normalized()
	_by_side(side, GRIP_FROM)
	await _wait(10)
	_key(KEY_E, true)
	await _wait(5)
	_check("E held at its side takes it in his jaws, playing `drag`", task_node.gripped() and player.model.dragging,
		"gripped %s, dragging %s" % [task_node.gripped(), player.model.dragging])
	var box_before: Vector3 = box.global_position
	var him_before: Vector3 = player.global_position
	_move(side)
	await _wait(60)
	_move(Vector3.ZERO)
	await _wait(20)
	var pulled: float = (box.global_position - box_before).dot(side)
	var walked: float = (player.global_position - him_before).dot(side)
	_check("pulling, the box comes back with him, light: about %.1f m in a second" % CampBox.DRAG_SPEED,
		pulled > CampBox.DRAG_SPEED * 0.8 and absf(pulled - walked) < 0.02, "the box %.2f m, he %.2f m" % [pulled, walked])
	box_before = box.global_position
	_move(-side)
	await _wait(40)
	_move(Vector3.ZERO)
	await _wait(20)
	var pushed: float = (box_before - box.global_position).dot(side)
	_check("pushing, it goes ahead of him", pushed > 0.5, "%.2f m" % pushed)
	box_before = box.global_position
	him_before = player.global_position
	_move(across)
	await _wait(40)
	_move(Vector3.ZERO)
	await _wait(20)
	var slid: float = (box.global_position - box_before).dot(across)
	var stepped: float = (player.global_position - him_before).dot(across)
	_check("sideways, it goes with him too", slid > 0.5 and absf(slid - stepped) < 0.02,
		"the box %.2f m, he %.2f m" % [slid, stepped])
	_key(KEY_E, false)
	await _wait(3)
	box_before = box.global_position
	_move(side)
	await _wait(40)
	_move(Vector3.ZERO)
	await _wait(10)
	_check("letting go of E lets go, and it stays where it's got to", not task_node.gripped()
		and _flat(box.global_position, box_before) < 0.005, "gripped %s, moved %.3f m" % [task_node.gripped(),
			_flat(box.global_position, box_before)])

	# Pushed against the green tent's back, it stops there.
	var tent := Transform3D(Basis(Vector3.UP, deg_to_rad(Campsite.OTHER_TENT[1])),
		Vector3(Campsite.OTHER_TENT[0].x, 0, Campsite.OTHER_TENT[0].y))
	var back: Vector3 = -tent.basis.z
	var gap := 0.5
	box.put_down(tent.origin + back * (2.1 * 0.5 + KeeperBox.SIZE.z * 0.5 + gap), Campsite.OTHER_TENT[1] * PI / 180.0)
	await _wait(5)
	_by_side(back, GRIP_FROM)
	await _wait(10)
	_key(KEY_E, true)
	await _wait(5)
	box_before = box.global_position
	_move(-back)
	await _wait(90)
	_move(Vector3.ZERO)
	await _wait(10)
	var went: float = (box_before - box.global_position).dot(back)
	var clear: bool = task_node.call("_in_the_way", box.global_position).is_empty()
	_check("pushed against the green tent, it stops there", task_node.gripped() and went > gap - 0.1
		and went < gap + 0.02 and clear, "it went %.2f m of the %.2f m to the tent, clear of it %s" % [went, gap, clear])
	_key(KEY_E, false)
	await _wait(5)

	# Back home, and into it.
	box.put_down(home, deg_to_rad(KeeperBox.TURN))
	await _wait(10)
	var from_side: Vector3 = box.global_basis.x
	from_side = Vector3(from_side.x, 0, from_side.z).normalized()
	var dived: bool = await _dive_in(from_side)
	_check("walking into it, he dives in: hidden, his eyes peeking out from under a flap", dived
		and box.hide_spot.covers(player) and box.hide_spot.peeking() and box.opened() > 0.5,
		"in it %s, hidden %s, peeking %s, open %.2f" % [dived, box.hide_spot.covers(player), box.hide_spot.peeking(),
			box.opened()])
	var keys: Array = task_node.prompts()
	_check("in it, its keys show: F, \"Make noise\", and E, \"Jump out\"", _keys_say(keys, "Make noise", "Jump out")
		and keys[0].ready, _keys_text(keys))

	# With nobody near: E pops him out, no fright.
	var nearest := INF
	for person: CampPerson in camp.people:
		nearest = minf(nearest, _flat(person.global_position, box.global_position))
	await _wait(20)
	await _tap(KEY_E)
	await _until(func() -> bool: return not player.call("is_hopping"), 60)
	await _wait(5)
	_check("with nobody near, E pops him out: nobody's frightened, the task isn't done", player.get("hiding_in") == null
		and task_node.scared == 0 and not tasks.is_done("scare"),
		"out %s, scared %d, done %s (the nearest camper %.1f m off)" % [player.get("hiding_in") == null,
			task_node.scared, tasks.is_done("scare"), nearest])

	# By the fire, where people are: F, then E.
	var by_fire := Vector3(Campsite.FIRE.x - 0.2, 0, Campsite.FIRE.y + 3.3)
	box.put_down(by_fire, deg_to_rad(KeeperBox.TURN))
	await _wait(60)
	var in_again: bool = await _dive_in(from_side)
	await _wait(20)
	var hearers := 0
	for person: CampPerson in camp.people:
		if _flat(person.global_position, box.global_position) <= CampBox.HEAR_RUSTLE:
			hearers += 1
	await _tap(KEY_F)
	var shook: bool = box.hide_spot.get("_rustle_t") >= 0.0
	var dim: Array = task_node.prompts()
	var checker: CampPerson = null
	for person: CampPerson in camp.people:
		if person.get("_checking"):
			checker = person
	var came := false
	if checker:
		var bent := func() -> bool:
			return _flat(checker.global_position, box.global_position) < CampPerson.CHECK_NEAR + 0.3 				and checker.anim.current_animation == "bend"
		came = await _until(bent, 60 * 15)
	_check("F in it: it shakes, and the nearest who hears it comes up to it and bends over it", in_again
		and task_node.rustles == 1 and shook and checker != null and came,
		"in it %s, rustles %d, shook %s, %d within earshot, %s came %s (%.2f m off, playing %s)" % [in_again,
			task_node.rustles, shook, hearers, checker.role if checker else "nobody", came,
			_flat(checker.global_position, box.global_position) if checker else -1.0,
			checker.anim.current_animation if checker else "-"])
	var near_keys: Array = task_node.prompts()
	_check("F is dim till it can rustle again; with them there, E says \"Scare!\"", dim.size() == 2
		and not dim[0].ready and _keys_say(near_keys, "Make noise", "Scare!") and near_keys[0].ready,
		"just after F: %s; with them there: %s" % [_keys_text(dim), _keys_text(near_keys)])
	await _tap(KEY_E)
	await _wait(3)
	var startled: bool = checker != null and checker.state == CampPerson.State.STARTLED
	await _until(func() -> bool: return not player.call("is_hopping"), 60)
	await _wait(5)
	var toward: float = _flat(player.global_position, checker.global_position) if checker else INF
	_check("E bursts him out at them: they take fright, and Scare a camper is done", startled
		and player.get("hiding_in") == null and task_node.scared >= 1 and tasks.is_done("scare")
		and toward < _flat(box.global_position, checker.global_position) and task_node.prompts().is_empty(),
		"startled %s, out %s, scared %d, done %s, he's %.2f m from them, keys %s" % [startled,
			player.get("hiding_in") == null, task_node.scared, tasks.is_done("scare"), toward,
			_keys_text(task_node.prompts())])

	print("RESULT: %s (%d checks, %d failed)" % ["FAILED" if _failed > 0 else "all checks passed", _checks, _failed])
	quit(1 if _failed > 0 else 0)
