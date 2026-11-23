extends SceneTree
## Raid the supply tent (scripts/camp_supplies.gd, 23 Nov 2026): the keeper's box, hiding in it,
## carried into the green tent, the stash inside and the flap out.
##
## In the real level (main.tscn at the developer menu's "fire" point, the camp's tasks revealed and the
## fire burning, so the keeper isn't off lighting it), with the campers blind to him (campsite.gd
## `cones_on` off); driven through the game loop with real key presses (Input.parse_input_event, and
## the move keys through Input.action_press), read each physics tick after the game's. The keeper is
## sent to his box steps by setting his routine's step, as tasks_test.gd `_settle` does. It checks:
##   - the task: on the camp's list, "Raid the supply tent", its hint 5 words at most;
##   - to start with: the box by the fire, not in the tent, its top two flaps, shut; walking at the
##     tent's door, he stays out;
##   - walking into the box, he dives in, hidden; the flap away from the camera opens a crack, and his
##     eyes peek out from under it; it shakes, then stands as it stood;
##   - the keeper picks it up (`take_box`) with him in it: he goes with it, still hidden, the box shut
##     and his eyes in; at the door (`store_box`) it goes in, he's in the tent with it, and the flap
##     opens again, his eyes peeking out;
##   - a move key hops him out of the box, a short way: in the tent, seen into (see-through), the flap
##     shut; and he can't walk out through its wall;
##   - E held at the crate: a cookie in his paws, eating; held to the end, it's gone and the task's
##     done;
##   - E at the flap: he slips out, in front of the door.
## Run it from the project folder:
##   bash scripts/run-test.sh test_supply_tent.gd 60
## It prints PASS or FAIL per check and a count, and quits with exit code 1 if any check fails.
## Written by Claude Code on 23 Nov 2026.

signal ticked

const DevMenu := preload("res://scripts/dev_menu.gd")
const Supplies := preload("res://scripts/camp_supplies.gd")
const KeeperBox := preload("res://scripts/keeper_box.gd")
const HideSpot := preload("res://scripts/hide_spot.gd")
const MOVES := ["move_left", "move_right", "move_forward", "move_back"]

var level: Node
var camp: Node
var player: CharacterBody3D
var supplies: Node3D
var box: Node3D

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
	print("Raid the supply tent: the real level at the developer menu's \"fire\" point, %d physics ticks a second"
		% Engine.physics_ticks_per_second)
	_run()


class Probe extends Node:
	var test: Object

	func _physics_process(_delta: float) -> void:
		test.call("step")


func step() -> void:
	if player == null and level and level.get("player") and level.get("campsite") \
			and level.campsite.get("supplies"):
		camp = level.campsite
		supplies = camp.supplies
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


## With him in it on the ground: [the top's flap away from the camera open FLAP_OPEN on its hinge at the
## box's far top edge, its free edge up, the other flap shut, and his eyes under the open one, in the
## middle, over the top and under the flap, as words]. After play his eyes were off ("the eyes look off
## when he is in it"), then peeking from under the box was: "maybe the upper flap peaking from there
## not from the botttom ... we are basicially inside the box".
func _peeking_out() -> Array:
	var side: float = box.flap_side()
	var inv: Transform3D = box.global_transform.affine_inverse()
	var cam: Vector3 = inv * level.camera.global_position
	var away: bool = side * cam.z < 0.0
	var open_flap: Node3D = box.flap(side)
	var shut_flap: Node3D = box.flap(-side)
	var angle: float = rad_to_deg(absf(open_flap.rotation.x))
	var shut: float = rad_to_deg(absf(shut_flap.rotation.x))
	var top: float = box.get("_top")
	var half: float = (box.get("_half") as Vector2).y
	var free_edge: Vector3 = inv * (open_flap.global_transform * Vector3(0, 0, -side * half))
	var eyes: Node3D = box.hide_spot.eyes()
	if eyes == null or not box.hide_spot.peeking():
		return [false, "open %.2f, the flap %.1f°, no eyes" % [box.opened(), angle]]
	var at: Vector3 = inv * eyes.global_position
	var back: float = side * at.z
	var radius: float = HideSpot.EYE * KeeperBox.EYES_SCALE
	var flap_over: float = (half - back) * tan(deg_to_rad(angle))
	var ok: bool = box.opened() == 1.0 and away and absf(angle - KeeperBox.FLAP_OPEN) < 0.01 and shut < 0.01 \
		and free_edge.y - top > 0.05 and absf(at.x) < 0.01 and back > 0.0 and at.y > top \
		and at.y + radius - top < flap_over
	return [ok, ("open %.2f, away from the camera %s, the flap %.1f° (the other %.1f°), its free edge %.3f m over"
		+ " the top; his eyes %.3f off the middle, %.3f m back under it, %.3f–%.3f m over the top, the flap %.3f"
		+ " over them") % [box.opened(), away, angle, shut, free_edge.y - top, absf(at.x), back, at.y - radius - top,
			at.y + radius - top, flap_over]]


## Both flaps shut, his eyes in: [true or false, as words].
func _shut() -> Array:
	var a: float = rad_to_deg(absf((box.flap(1.0) as Node3D).rotation.x))
	var b: float = rad_to_deg(absf((box.flap(-1.0) as Node3D).rotation.x))
	return [box.opened() == 0.0 and a < 0.01 and b < 0.01 and not box.hide_spot.peeking(),
		"open %.2f, the flaps %.1f° and %.1f°, peeking %s" % [box.opened(), a, b, box.hide_spot.peeking()]]


## The box's turn in its own space (for "stands as it stood").
func _box_turn(model: Node3D) -> Basis:
	return (box.global_transform.basis.inverse() * model.global_transform.basis).orthonormalized()


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


func _hold_e(ticks: int) -> Dictionary:
	var seen := {"eat_ticks": 0, "cookie_ticks": 0}
	_key(KEY_E, true)
	for i in ticks:
		await ticked
		if player.model.eating:
			seen.eat_ticks += 1
		if player.model.paws and player.model.paws.get_child_count() > 0:
			seen.cookie_ticks += 1
	_key(KEY_E, false)
	await _wait(2)
	return seen


## Sends the keeper to his routine's step called `name`, from wherever he is.
func _send_keeper(name: String) -> void:
	var keeper = camp.keeper
	var steps: Array = keeper.routine
	for i in steps.size():
		if steps[i].name == name:
			keeper.set("_step", i)
			keeper.set("_arrived", false)
			keeper.set("_step_left", Supplies.BEND)
			return


func _run() -> void:
	await _until(func() -> bool: return player != null, 60)
	camp.set("cones_on", false)
	await _wait(30)
	var tasks = level.tasks
	var task: Dictionary = {}
	for t: Dictionary in tasks.list:
		if t.id == "supplies":
			task = t
	_check("the task is on the camp's list: \"Raid the supply tent\"", task.get("text", "") == "Raid the supply tent" \
		and task.get("camp", false) and tasks.shown().has(task), task.get("text", "(none)"))
	var hint: String = task.get("hint", "")
	_check("its hint is 5 words at most: \"%s\"" % hint, hint != "" and hint.split(" ", false).size() <= 5,
		hint.split(" ", false).size())
	var tent: Node3D = supplies.tent
	_check("to start with: the box by the fire, not in the tent", box.visible and not supplies.in_tent
		and _flat(box.global_position, supplies.box_home) < 0.05, "in_tent %s, %.2f m from its place" % [
			supplies.in_tent, _flat(box.global_position, supplies.box_home)])
	var model: MeshInstance3D = box.find_children("Box1", "", true, false)[0]
	var shut_at_first := _shut()
	_check("its top is two flaps, shut (the model's own top taken out)", _faces_up(model) == 0
		and box.flap(1.0) != null and box.flap(-1.0) != null and shut_at_first[0],
		"faces up %d, %s" % [_faces_up(model), shut_at_first[1]])

	# Walking at the tent's door: he stays out.
	var door: Vector3 = Supplies.door_spot(tent.global_transform)
	_stand(door, tent.global_position)
	await _wait(5)
	_move(tent.global_position - door)
	await _wait(90)
	_move(Vector3.ZERO)
	await _wait(5)
	_check("walking at the tent's door, he stays out", not supplies.inside(player.global_position),
		"%.2f m from its middle" % _flat(player.global_position, tent.global_position))

	# Into the box.
	var from: Vector3 = box.global_position + Vector3(-1.2, 0, 0)
	_stand(from, box.global_position)
	await _wait(5)
	var model_before: Basis = _box_turn(model)
	_move(box.global_position - from)
	var dived := await _until(func() -> bool: return player.get("hiding_in") == box.hide_spot, 90)
	_move(Vector3.ZERO)
	await _until(func() -> bool: return box.hide_spot.peeking(), 60)
	_check("walking into the box, he dives in: hidden, his eyes peeking", dived and box.hide_spot.covers(player)
		and box.hide_spot.peeking(), "in it %s, covered %s, peeking %s" % [dived, box.hide_spot.covers(player),
			box.hide_spot.peeking()])
	await _wait(20)
	var peek := _peeking_out()
	_check("the flap away from the camera opens a crack, his eyes peeking out from under it", peek[0], peek[1])
	# The box shakes as he dives in, then stands as it stood (after play it was left on its side).
	await _wait(30)
	var turned: float = rad_to_deg(Quaternion(model_before).angle_to(Quaternion(_box_turn(model))))
	_check("diving in, the box shakes and then stands as it stood", turned < 0.1,
		"turned %.1f° from before" % turned)

	# The keeper takes it, with him in it, into the tent.
	_send_keeper("take_box")
	var taken := await _until(func() -> bool: return box.carried(), 60 * 40)
	await _wait(30)
	_check("the keeper picks it up: he goes with it, still hidden", taken and player.get("hiding_in") == box.hide_spot
		and _flat(player.global_position, box.global_position) < 0.05 and box.hide_spot.covers(player),
		"carried %s, %.2f m from it, hidden %s" % [taken, _flat(player.global_position, box.global_position),
			box.hide_spot.covers(player)])
	var carried_shut := _shut()
	_check("carried, it's shut in his arms and his eyes stay in", carried_shut[0], carried_shut[1])
	var stored := await _until(func() -> bool: return supplies.in_tent, 60 * 40)
	await _wait(10)
	_check("at the door it goes in: the box in the tent, and he's in the tent in it", stored and not box.carried()
		and supplies.inside(box.global_position) and supplies.inside(player.global_position)
		and player.get("hiding_in") == box.hide_spot,
		"in_tent %s, box inside %s, he's inside %s, hidden %s" % [stored, supplies.inside(box.global_position),
			supplies.inside(player.global_position), player.get("hiding_in") == box.hide_spot])
	await _wait(30)
	var peek_tent := _peeking_out()
	_check("put down in the tent, the flap opens again, his eyes peeking out", peek_tent[0], peek_tent[1])

	# Out of the box, in the tent.
	_move(Vector3(1, 0, 0))
	await _wait(6)
	_move(Vector3.ZERO)
	await _until(func() -> bool: return not player.call("is_hopping"), 60)
	await _wait(30)
	var seen: float = supplies.get("_seen")
	_check("a move key hops him out of the box, in the tent, seen into", player.get("hiding_in") == null
		and supplies.inside(player.global_position) and seen > 0.5,
		"hidden %s, inside %s, see-through %.2f" % [player.get("hiding_in") != null, supplies.inside(player.global_position), seen])
	var out_shut := _shut()
	_check("out of it, the flap shuts, his eyes gone", out_shut[0], out_shut[1])
	var wall_way: Vector3 = tent.global_transform.basis.x
	_move(wall_way)
	await _wait(120)
	_move(Vector3.ZERO)
	await _wait(5)
	_check("he can't walk out through its wall", supplies.inside(player.global_position),
		"%.2f m from its middle" % _flat(player.global_position, tent.global_position))

	# The cookies.
	var crate: Vector3 = supplies.stash_point()
	# From in front of it, toward the door: clear of the box (walking against the box dives him into it).
	_stand(crate + tent.global_basis.z * 0.55, crate)
	await _wait(10)
	var bite := await _hold_e(int(Supplies.EAT_FOR * 60) + 10)
	_check("E held at the crate: a cookie in his paws, eating; then it's gone", bite.cookie_ticks > 0 and bite.eat_ticks > 0
		and supplies.eaten == 1 and supplies.cookies_left() == Supplies.COOKIES - 1 and not player.model.eating,
		"cookie %d ticks, eating %d, eaten %d, left %d" % [bite.cookie_ticks, bite.eat_ticks, supplies.eaten, supplies.cookies_left()])
	_check("Raid the supply tent is done", tasks.is_done("supplies"), tasks.is_done("supplies"))

	# Out by the flap.
	var flap: Vector3 = supplies.flap_point()
	_stand(flap + (tent.global_position - flap).normalized() * 0.5, flap)
	await _wait(10)
	_key(KEY_E, true)
	await _wait(int(Supplies.FLAP_TIME * 60) + 6)
	_key(KEY_E, false)
	await _until(func() -> bool: return not player.call("is_hopping"), 120)
	await _wait(10)
	var out_to: Vector3 = tent.global_transform * Vector3(Supplies.OUT_TO.x, 0, Supplies.OUT_TO.y)
	_check("E at the flap: he slips out, in front of the door", not supplies.inside(player.global_position)
		and _flat(player.global_position, out_to) < 0.3, "%.2f m from where he lands" % _flat(player.global_position, out_to))

	print("RESULT: %s (%d checks, %d failed)" % ["FAILED" if _failed > 0 else "all checks passed", _checks, _failed])
	quit(1 if _failed > 0 else 0)
