extends SceneTree
## Eat the pizza (scripts/camp_pizza.gd, 23 Nov 2026) and the raccoon's `drag` clip.
##
## In the real level (main.tscn at the developer menu's "free" point, the camp's tasks revealed, as
## tests/test_balloon_task.gd runs it), with the campers blind to him (campsite.gd `cones_on` off);
## driven through the game loop with real key presses (Input.parse_input_event, and the move keys
## through Input.action_press), read each physics tick after the game's. It checks:
##   - the task: on the camp's list, "Eat the pizza", its hint 5 words at most;
##   - to start with: the cloth on the table, the boxes on it with five slices, nothing pulled;
##   - E at the cloth's hem takes it in his jaws (player.gd `grip`); a move key away from the table
##     backs him away facing it, playing `drag` (raccoon_model.gd `dragging`) every tick, and the
##     cloth comes with him; E lets go: the cloth stays where it's got to, nothing comes down;
##   - taken again and pulled on: the boxes go over the end, and the cloth comes off with them as
##     he lets go, coming down in the same time as they fall; they land on the ground, on the
##     cloth's heap; the clatter's heard CLATTER round: someone within it wonders (INVESTIGATE),
##     nobody beyond it does; the cloth can't be taken again;
##   - E held at the open box: a slice in his paws and him sitting up eating (`eating`); let go
##     early, it's back in the box; held to the end (EAT_FOR), it's gone and the task's done.
## Run it from the project folder:
##   bash scripts/run-test.sh test_pizza_task.gd 60
## It prints PASS or FAIL per check and a count, and quits with exit code 1 if any check fails.
## Written by Claude Code on 23 Nov 2026; the pull by grip and move keys the same day.

signal ticked

const DevMenu := preload("res://scripts/dev_menu.gd")
const CampPizzaScript := preload("res://scripts/camp_pizza.gd")
const CampPersonScript := preload("res://scripts/camp_person.gd")
const MOVES := ["move_left", "move_right", "move_forward", "move_back"]

var level: Node
var camp: Node
var player: CharacterBody3D
var pizza: Node3D

var _tick := 0
var _checks := 0
var _failed := 0


func _initialize() -> void:
	var probe := Probe.new()
	probe.test = self
	# After the game's own physics ticks.
	probe.process_physics_priority = 1000
	root.add_child(probe)
	DevMenu._next = "free"
	level = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	print("Eat the pizza: the real level at the developer menu's \"free\" point, %d physics ticks a second"
		% Engine.physics_ticks_per_second)
	_run()


class Probe extends Node:
	var test: Object

	func _physics_process(_delta: float) -> void:
		test.call("step")


func step() -> void:
	_tick += 1
	if player == null and level and level.get("player") and level.get("campsite") \
			and level.campsite.get("pizza"):
		camp = level.campsite
		pizza = camp.pizza
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


## Holds the move keys that point him along `way` on the ground (the keys are turned by the
## camera's yaw: player.gd `_input_dir`); `way` zero lets them all go.
func _move(way: Vector3) -> void:
	for action: String in MOVES:
		Input.action_release(action)
	if way == Vector3.ZERO:
		return
	var yaw: float = level.camera.global_rotation.y
	var keys := way.rotated(Vector3.UP, -yaw)
	if keys.x > 0.01:
		Input.action_press("move_right", keys.x)
	elif keys.x < -0.01:
		Input.action_press("move_left", -keys.x)
	if keys.z > 0.01:
		Input.action_press("move_back", keys.z)
	elif keys.z < -0.01:
		Input.action_press("move_forward", -keys.z)


func _highest(mesh_node: MeshInstance3D) -> float:
	var top := -INF
	for p: Vector3 in mesh_node.mesh.get_faces():
		top = maxf(top, (mesh_node.global_transform * p).y)
	return top


func _clip() -> String:
	var anim: AnimationPlayer = player.model.get("_anim")
	return anim.assigned_animation if anim else ""


## Backs him away from the table for `ticks` physics ticks (or till `stop`), noting each tick whether
## he's dragging and playing `drag`, and the most he turned from facing the cloth.
func _pull(ticks: int, stop := Callable()) -> Dictionary:
	var seen := {"ticks": 0, "drag_ticks": 0, "drag_clip_ticks": 0, "worst_face": 0.0}
	_move(pizza.pull_axis())
	for i in ticks:
		await ticked
		if stop.is_valid() and stop.call():
			break
		seen.ticks += 1
		if player.model.dragging:
			seen.drag_ticks += 1
		if i >= 2 and _clip() == "drag":
			seen.drag_clip_ticks += 1
		if player.get("gripping") != null:
			var to: Vector3 = pizza.face_point() - player.global_position
			var nose := -player.global_basis.z
			seen.worst_face = maxf(seen.worst_face, rad_to_deg(Vector2(nose.x, nose.z).angle_to(Vector2(to.x, to.z))))
	_move(Vector3.ZERO)
	await _wait(2)
	return seen


## Holds E for `ticks` physics ticks, noting each tick whether he's eating with a slice in his paws.
func _hold_e(ticks: int) -> Dictionary:
	var seen := {"eat_ticks": 0, "slice_ticks": 0}
	_key(KEY_E, true)
	for i in ticks:
		await ticked
		if player.model.eating:
			seen.eat_ticks += 1
		if player.model.paws and player.model.paws.get_child_count() > 0:
			seen.slice_ticks += 1
	_key(KEY_E, false)
	await _wait(2)
	return seen


func _run() -> void:
	await _until(func() -> bool: return player != null, 60)
	camp.set("cones_on", false)
	await _wait(30)
	var tasks = level.tasks
	var task: Dictionary = {}
	for t: Dictionary in tasks.list:
		if t.id == "pizza":
			task = t
	_check("the task is on the camp's list: \"Eat the pizza\"", task.get("text", "") == "Eat the pizza" \
		and task.get("camp", false) and tasks.shown().has(task), task.get("text", "(none)"))
	var hint: String = task.get("hint", "")
	_check("its hint is 5 words at most: \"%s\"" % hint, hint != "" and hint.split(" ", false).size() <= 5,
		hint.split(" ", false).size())

	# To start with.
	_check("to start with: the cloth on the table, the boxes on it, five slices, nothing pulled",
		pizza.on_table() and not pizza.pulled and not pizza.down and not pizza.off and pizza.slices_left() == 5,
		"on_table %s pulled %s down %s off %s slices %d" % [pizza.on_table(), pizza.pulled, pizza.down, pizza.off,
			pizza.slices_left()])

	# E at the hem: in his jaws. Backed off a little, then let go.
	_stand(pizza.pull_from(), pizza.pull_point())
	await _wait(10)
	await _tap(KEY_E)
	_check("E at the hem: he has it in his jaws", player.get("gripping") == pizza, player.get("gripping"))
	var start := player.global_position
	var little := await _pull(20)
	var backed := (player.global_position - start).dot(pizza.pull_axis())
	_check("a move key away from the table: he backs off, facing it", backed > 0.05 and little.worst_face < 10.0,
		"backed %.2f m, turned at most %.1f°" % [backed, little.worst_face])
	_check("dragging: `dragging` and the rig's `drag` clip on every tick", little.drag_ticks == little.ticks
		and little.drag_clip_ticks >= little.ticks - 3, "%d and %d of %d" % [little.drag_ticks, little.drag_clip_ticks, little.ticks])
	_check("the cloth comes with him, the boxes on it", pizza.slide > 0.03 and pizza.on_table(),
		"slide %.3f m, on the table %s" % [pizza.slide, pizza.on_table()])
	var slid: float = pizza.slide
	await _tap(KEY_E)
	_check("E again: he lets go, the cloth stays where it's got to, nothing down",
		player.get("gripping") == null and not pizza.pulled and is_equal_approx(pizza.slide, slid),
		"gripping %s pulled %s slide %.3f" % [player.get("gripping"), pizza.pulled, pizza.slide])
	await _wait(5)
	_check("let go: he's not dragging, nor playing `drag`", not player.model.dragging and _clip() != "drag",
		"%s %s" % [player.model.dragging, _clip()])

	# Taken again and pulled right off.
	await _wait(120)
	var people: Array = camp.get("people")
	var calm_before := {}
	for person in people:
		calm_before[person] = int(person.get("state")) == CampPersonScript.State.WORK
	_stand(pizza.pull_point() + pizza.pull_axis() * 0.39, pizza.pull_point())
	await _wait(10)
	await _tap(KEY_E)
	_check("the hem taken again", player.get("gripping") == pizza, player.get("gripping"))
	await _pull(200, func() -> bool: return pizza.pulled)
	_check("pulled on: the boxes go over the end, the cloth comes off with them, he lets go",
		pizza.pulled and pizza.off and player.get("gripping") == null,
		"pulled %s off %s gripping %s slide %.2f" % [pizza.pulled, pizza.off, player.get("gripping"), pizza.slide])
	# Halfway down, the cloth is as far through its fall as the boxes are through theirs.
	var cloth: MeshInstance3D = pizza.get("_cloth")
	var top_at_start := _highest(cloth)
	await _until(func() -> bool: return pizza.get("_cloth_k") >= 0.5 or pizza.down, 60)
	var cloth_k: float = pizza.get("_cloth_k")
	var boxes_y: float = pizza.boxes.global_position.y
	_check("coming down together: the cloth halfway down as the boxes are halfway through their fall",
		cloth_k >= 0.4 and cloth_k < 1.0 and boxes_y < pizza.get("_fall_from").origin.y and _highest(cloth) < top_at_start,
		"cloth %.2f through, boxes at %.2f m, cloth's top %.2f m (was %.2f)" % [cloth_k, boxes_y, _highest(cloth), top_at_start])
	await _until(func() -> bool: return pizza.down, 60)
	var boxes: Node3D = pizza.boxes
	var table: Node3D = pizza.table
	var end := table.global_transform * Vector3(CampPizzaScript.EDGE_X, 0.0, 0.0)
	_check("down: the boxes land past the table's end, on the cloth, as it settles",
		pizza.down and is_equal_approx(pizza.get("_cloth_k"), 1.0) and absf(boxes.global_position.y - CampPizzaScript.ON_HEAP) < 0.01
		and (boxes.global_position - end).dot(pizza.pull_axis()) > 0.0,
		"down %s cloth %.2f y %.3f past the end %.2f m" % [pizza.down, pizza.get("_cloth_k"), boxes.global_position.y,
			(boxes.global_position - end).dot(pizza.pull_axis())])
	var near := []
	var far := []
	for person in people:
		if not calm_before[person]:
			continue
		(near if _flat(person.global_position, boxes.global_position) <= CampPizzaScript.CLATTER else far).append(person)
	await _wait(3)
	var S := CampPersonScript.State
	_check("the clatter's heard %.0f m round: someone near wonders" % CampPizzaScript.CLATTER, not near.is_empty()
		and near.all(func(p) -> bool: return int(p.get("state")) == S.INVESTIGATE),
		"%d near: %s" % [near.size(), " ".join(near.map(func(p) -> String: return S.keys()[int(p.get("state"))]))])
	_check("nobody beyond it does", far.all(func(p) -> bool: return int(p.get("state")) != S.INVESTIGATE),
		"%d far: %s" % [far.size(), " ".join(far.map(func(p) -> String: return S.keys()[int(p.get("state"))]))])
	var heap: Vector3 = table.global_transform * pizza.get("_lying_at")
	_check("the cloth lies on the ground, heaped under the boxes", _highest(cloth) < 0.1
		and _flat(heap, boxes.global_position) < 0.3, "its highest point %.3f m, %.2f m from the boxes" % [
			_highest(cloth), _flat(heap, boxes.global_position)])
	_check("it can't be taken again", not pizza.get("_grab").usable_by(player), "")

	# Eating: let go early, then held to the end.
	var box_at: Vector3 = pizza.eat_point()
	# Off the open box away from the table, far enough that his snout (about 0.4 m ahead of his
	# middle) is short of it.
	var from: Vector3 = box_at + pizza.pull_axis() * 0.6
	_stand(from, box_at)
	await _wait(10)
	var bite := await _hold_e(int(CampPizzaScript.EAT_FOR * 60 * 0.4))
	_check("E held at the open box: a slice in his paws, sitting up eating", bite.slice_ticks > 0 and bite.eat_ticks > 0,
		"slice %d ticks, eating %d" % [bite.slice_ticks, bite.eat_ticks])
	_check("let go early: the slice back in the box, not eating, the task not done",
		pizza.slices_left() == 5 and not player.model.eating and not tasks.is_done("pizza"),
		"slices %d eating %s done %s" % [pizza.slices_left(), player.model.eating, tasks.is_done("pizza")])
	_stand(from, box_at)
	await _wait(5)
	await _hold_e(int(CampPizzaScript.EAT_FOR * 60) + 10)
	_check("held to the end: a slice eaten, four left, not eating now", pizza.eaten == 1 and pizza.slices_left() == 4
		and not player.model.eating, "eaten %d left %d eating %s" % [pizza.eaten, pizza.slices_left(), player.model.eating])
	_check("Eat the pizza is done", tasks.is_done("pizza"), tasks.is_done("pizza"))

	print("RESULT: %s (%d checks, %d failed)" % ["FAILED" if _failed > 0 else "all checks passed", _checks, _failed])
	quit(1 if _failed > 0 else 0)
