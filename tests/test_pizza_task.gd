extends SceneTree
## Eat the pizza (scripts/camp_pizza.gd, 23 Nov 2026) and the raccoon's `drag` clip.
##
## In the real level (main.tscn at the developer menu's "free" point, the camp's tasks revealed, as
## tests/test_balloon_task.gd runs it), with the campers blind to him (campsite.gd `cones_on` off);
## driven through the game loop with real key presses (Input.parse_input_event), read each physics
## tick after the game's. It checks:
##   - the task: on the camp's list, "Eat the pizza", its hint 5 words at most;
##   - to start with: the cloth on the table, the boxes on it with five slices, nothing pulled;
##   - E held at the cloth's hem: he plays `drag` (raccoon_model.gd `dragging`) every tick he
##     holds it, and the cloth comes toward him; let go early, nothing comes down;
##   - held to the end (PULL_TIME): the boxes come off the table's end and land on the ground, the
##     cloth in a heap; the clatter's heard CLATTER round: someone within it wonders (INVESTIGATE),
##     nobody beyond it does; the cloth can't be pulled again;
##   - E held at the open box: a slice in his paws and him sitting up eating (`eating`); let go
##     early, it's back in the box; held to the end (EAT_FOR), it's gone and the task's done.
## Run it from the project folder:
##   bash scripts/run-test.sh test_pizza_task.gd 60
## It prints PASS or FAIL per check and a count, and quits with exit code 1 if any check fails.
## Written by Claude Code on 23 Nov 2026.

signal ticked

const DevMenu := preload("res://scripts/dev_menu.gd")
const CampPizzaScript := preload("res://scripts/camp_pizza.gd")
const CampPersonScript := preload("res://scripts/camp_person.gd")

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


func _clip() -> String:
	var anim: AnimationPlayer = player.model.get("_anim")
	return anim.assigned_animation if anim else ""


## Holds E for `ticks` physics ticks, noting each tick whether he's dragging and playing `drag`,
## and whether he's eating with a slice in his paws; then lets go.
func _hold_e(ticks: int) -> Dictionary:
	var seen := {"drag_ticks": 0, "drag_clip_ticks": 0, "eat_ticks": 0, "slice_ticks": 0}
	_key(KEY_E, true)
	for i in ticks:
		await ticked
		if player.model.dragging:
			seen.drag_ticks += 1
		# The clip's picked on the process tick after the physics tick that set `dragging`.
		if i >= 2 and _clip() == "drag":
			seen.drag_clip_ticks += 1
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
		pizza.on_table() and not pizza.pulled and not pizza.down and pizza.slices_left() == 5,
		"on_table %s pulled %s down %s slices %d" % [pizza.on_table(), pizza.pulled, pizza.down, pizza.slices_left()])

	# E held at the hem, let go early.
	_stand(pizza.pull_from(), pizza.pull_point())
	await _wait(10)
	var cloth: Node3D = pizza.get("_cloth")
	var early := await _hold_e(int(CampPizzaScript.PULL_TIME * 60 * 0.5))
	_check("E held at the hem: he's dragging every tick he holds it", early.drag_ticks >= int(CampPizzaScript.PULL_TIME * 30) - 3,
		"%d of %d" % [early.drag_ticks, int(CampPizzaScript.PULL_TIME * 30)])
	_check("E held at the hem: the rig plays `drag` (from the tick after)", early.drag_clip_ticks >= int(CampPizzaScript.PULL_TIME * 30) - 5,
		early.drag_clip_ticks)
	_check("let go halfway: nothing comes down, and the cloth had come toward him", not pizza.pulled and pizza.on_table()
		and cloth.position.x < -0.01, "pulled %s cloth x %.3f" % [pizza.pulled, cloth.position.x])
	await _wait(5)
	_check("let go: he's not dragging, nor playing `drag`", not player.model.dragging and _clip() != "drag",
		"%s %s" % [player.model.dragging, _clip()])

	# Held to the end.
	await _wait(200)
	_stand(pizza.pull_from(), pizza.pull_point())
	await _wait(10)
	var people: Array = camp.get("people")
	await _hold_e(int(CampPizzaScript.PULL_TIME * 60) + 6)
	_check("held to the end: the cloth's pulled", pizza.pulled, pizza.pulled)
	var calm_before := {}
	for person in people:
		calm_before[person] = int(person.get("state")) == CampPersonScript.State.WORK
	var landed := await _until(func() -> bool: return pizza.down, 60)
	var boxes: Node3D = pizza.boxes
	var table: Node3D = pizza.table
	var end := table.global_transform * Vector3(CampPizzaScript.EDGE_X, 0.0, 0.0)
	_check("down: the boxes land on the ground off the table's end", landed and absf(boxes.global_position.y) < 0.01
		and (boxes.global_position - end).dot(-table.global_basis.x) > 0.0,
		"down %s y %.3f past the end %.2f m" % [landed, boxes.global_position.y, (boxes.global_position - end).dot(-table.global_basis.x)])
	var heap: Node3D = pizza.get("_heap")
	_check("down: the cloth off the table, in a heap", not cloth.visible and heap.visible, "%s %s" % [cloth.visible, heap.visible])
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
	_check("the cloth can't be pulled again", not pizza.get("_pull").usable_by(player), "")

	# Eating: let go early, then held to the end.
	var box_at: Vector3 = pizza.eat_point()
	# Off the open box away from the table, far enough that his snout (about 0.4 m ahead of his
	# middle) is short of it.
	var away: Vector3 = ((pizza.pull_from() - pizza.pull_point()) * Vector3(1, 0, 1)).normalized()
	var from: Vector3 = box_at + away * 0.6
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
