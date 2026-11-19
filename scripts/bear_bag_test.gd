extends Node
## The automated check for Raid the bear bag (camp_bear_bag.gd, the camper's HANG in
## camp_person.gd, the limb in player.gd), added on 10 Nov 2026. The level starts as the
## open world does after the tutorial, with the list on the page (main.gd,
## `--bearbag-test`).
##   - the bag hangs out of his reach, its three treats in it; before the open world the
##     knot can't be chewed, and the rope above can't be chewed from the ground;
##   - the knot: holding E at it (through the level's input, as the key would) chews it
##     through; the bag falls under the limb with a thump the campers hear;
##   - holding E at it opens it and the treats spill out; one carried home to his stash
##     ticks the task off;
##   - a treat taken back goes into the bag, and the camper, once calm, hangs it up again
##     with the treats lying by it, but not the one in the stash;
##   - the limb: walking into the trunk climbs it, W takes him up, the keys pointing out
##     along the limb step him onto it and walk him out; it gives under him, and up there
##     the cones can't see him; holding E chews the rope over the bag; E drops him off.
## The campers' cones are off (campsite.gd `cones_on`), so his being seen doesn't get in
## the way.
## Run it headless from the project folder:
##   bash scripts/run-test.sh --bearbag-test 60 300
## It prints a table and quits with exit code 0 if every check passes, 1 if not.

const CampPerson := preload("res://scripts/camp_person.gd")
const CampBearBag := preload("res://scripts/camp_bear_bag.gd")
const VisionCone := preload("res://scripts/vision_cone.gd")
const Forest := preload("res://scripts/forest.gd")
const S := CampPerson.State
const MOVES := ["move_left", "move_right", "move_forward", "move_back"]

## Set by the level (main.gd).
var level: Node

var _results: Array[Array] = []
var _failed := false
var _camp
var _bag: CampBearBag
var _camper: CampPerson
var _player


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_camp = level.campsite
	_bag = _camp.bear_bag
	_camper = _camp.camper
	_player = level.player
	_run.call_deferred()


func _run() -> void:
	_camp.cones_on = false
	await _wait(0.3)
	var run := _bag._run()
	_check("Start: it hangs, its three treats in it", "true false 3",
		"%s %s %d" % [_bag.hung, _bag.down, _bag.treats.filter(func(t) -> bool: return t.get_meta("in_bag", false)).size()])
	_check("Start: out of his reach (its bottom over 1.2 m up)", true, _bag.bag_at().y > 1.2)
	_check("Start: the tree's his to climb, with its limb", true,
		_player.trees.any(func(t: Dictionary) -> bool: return is_same(t, _bag.tree) and t.has("limb")))
	_check("Start: it isn't on the forest's list", false,
		level.forest.climbable.any(func(t: Dictionary) -> bool: return is_same(t, _bag.tree)))

	# Before the open world, the knot's no use; from the ground, the rope above isn't.
	_stand(_bag.knot_at() + run * 0.35 + Vector3(0, 0.02, 0), _bag.knot_at())
	await _wait(0.3)
	_camp.tasks.revealed = false
	_check("Before the open world, the knot can't be chewed", false, _bag._knot_spot.usable_by(_player))
	_camp.tasks.revealed = true
	_check("Then it can", true, _bag._knot_spot.usable_by(_player))
	await _wait(0.4)
	_check("By the knot, it twinkles", true, _bag._knot_glint in level.bubbles.glinting())
	var under: Vector3 = _bag.over_point() * Vector3(1, 0, 1)
	_stand(under - run * 0.3 + Vector3(0, 0.02, 0), under)
	await _wait(0.2)
	_check("From the ground, the rope over the bag can't be chewed", false, _bag._limb_spot.usable_by(_player))

	# The knot: chewed through, down it comes.
	_stand(_bag.knot_at() + run * 0.35 + Vector3(0, 0.02, 0), _bag.knot_at())
	await _wait(0.2)
	await _press_e(CampBearBag.CHEW_KNOT * 0.5)
	_check("Half chewed, it still hangs", true, _bag.hung)
	await _press_e(CampBearBag.CHEW_KNOT * 0.5 + 0.4)
	_check("Chewed through at the knot", "knot false", "%s %s" % [_bag.cut_at, _bag.hung])
	await _until(func() -> bool: return _bag.down, 3.0)
	_check("It falls and lands", true, _bag.down)
	_check("It lands under the limb, on the ground", true,
		_flat(_bag.bag_at() - under).length() < 0.05 and absf(_bag.bag_at().y - _bag.global_position.y) < 0.01)
	_check("The ropes go with it", "false false", "%s %s" % [_bag._knot_rope.visible, _bag._hang_rope.visible])
	await _wait(0.3)
	_check("The thump: one of them wonders about it", true,
		_camp.people.any(func(p: CampPerson) -> bool: return p.state == S.INVESTIGATE))

	# Opened: the treats spill out.
	var at: Vector3 = _bag.bag_at()
	_stand(at + run * 0.5 + Vector3(0, 0.02, 0), at)
	await _wait(0.3)
	_check("Down, it twinkles", true, _bag._bag_glint in level.bubbles.glinting())
	await _press_e(CampBearBag.OPEN_TIME + 0.4)
	_check("Holding E opens it", true, _bag.opened)
	_check("The three treats spill out, his to grab", 3, _bag.treats.filter(func(t: RigidBody3D) -> bool:
		return not t.get_meta("in_bag", false) and t.visible and t.is_in_group("grabbable")).size())

	# One home to his stash: the task's done.
	await _wait(0.6)
	var choc: RigidBody3D = _bag.treats[1]
	var to_choc: Vector3 = _flat(choc.global_position - at).normalized()
	_stand(choc.global_position + to_choc * 0.4 + Vector3(0, 0.02, 0), choc.global_position)
	await _wait(0.2)
	await _press_e(0.0)
	_check("E picks a treat up", true, _player.held == choc)
	_player.place(Forest.HOME + Vector3(1.0, 0.02, 1.2))
	await _wait(0.3)
	await _press_e(0.0)
	await _wait(0.8)
	_check("A treat in his stash: the task's done", true, _camp.tasks.is_done("bearbag"))
	_check("It's his now", false, choc.has_meta("camp_loot"))

	# A treat taken back goes into the bag, and they'll want it up again.
	var cookies: RigidBody3D = _bag.treats[0]
	_check("Taken back, a treat goes home to the bag", true, _flat(_camp.home_of(cookies) - _bag.bag_at()).length() < 0.01)
	_camp.take_back(cookies)
	_check("Back in the bag", "true false", "%s %s" % [cookies.get_meta("in_bag", false), cookies.visible])
	_check("They'll want it hung up again", true, _bag.needs_hanging())

	# The camper, calm, hangs it up again.
	_player.place(Vector3(20.0, 0.02, 6.5))
	await _until(func() -> bool: return _camper.state == S.HANG, 60.0)
	_check("Calm, the camper goes to hang it", "HANG", S.keys()[_camper.state])
	await _until(func() -> bool: return _bag.hung, 60.0)
	_check("He hoists it up again", "true false", "%s %s" % [_bag.hung, _bag.down])
	await _wait(CampBearBag.HOIST_TIME + 0.3)
	_check("Up, out of reach again", true, _bag.bag_at().y > 1.2)
	_check("The treat lying by it is back in, the one in his stash isn't", "true false",
		"%s %s" % [_bag.treats[2].get_meta("in_bag", false), choc.get_meta("in_bag", false)])
	_check("Its ropes are back", "true true", "%s %s" % [_bag._knot_rope.visible, _bag._hang_rope.visible])

	# The limb: up the trunk, out along it, the rope chewed over the bag.
	_player.place(_bag.global_position + run * (float(_bag.tree.clear) + 0.45) + Vector3(0, 0.02, 0))
	await _wait(0.3)
	_hold_toward(-run)
	await _until(func() -> bool: return _player.climbing, 3.0)
	_check("Walking into the trunk, he climbs it", true, _player.climbing)
	_release_moves()
	Input.action_press("move_forward")
	await _until(func() -> bool: return _player._climb_along >= _player._climb_top() - 0.02, 6.0)
	_check("W takes him to the top of the trunk", true, _player._climb_along >= _player._climb_top() - 0.02)
	_release_moves()
	await _wait(0.1)
	_check("At the top, still on the trunk", false, _player.on_limb)
	_hold_toward(run)
	await _until(func() -> bool: return _player.on_limb and not _player.is_hopping(), 2.0)
	_check("The keys pointing out along the limb step him onto it", true, _player.on_limb)
	await _until(func() -> bool: return _bag._limb_spot.usable_by(_player), 5.0)
	_release_moves()
	await _wait(0.4)
	_check("He walks out along it, over the bag", true, _bag._limb_spot.usable_by(_player))
	_check("Out on it, he's still up the tree (they shoo at its foot)", true, _player.climbing)
	_check("It gives under him", true, _player.limb_bend() > 0.01 and not _bag._limb.basis.is_equal_approx(Basis()))
	_check("Up there, they can't see him", true, VisionCone.hidden(_player))
	await _press_e(CampBearBag.CHEW_LIMB + 0.4)
	_check("Chewed through over the bag", "limb false", "%s %s" % [_bag.cut_at, _bag.hung])
	await _until(func() -> bool: return _bag.down, 3.0)
	_check("It falls and lands", true, _bag.down)
	_check("The rope from the knot stays tied", "true false", "%s %s" % [_bag._knot_rope.visible, _bag._hang_rope.visible])
	await _press_e(0.0)
	await _until(func() -> bool: return not _player.climbing, 2.0)
	await _wait(0.2)
	_check("E drops him off it, onto the ground", "false false true",
		"%s %s %s" % [_player.climbing, _player.on_limb, _player.global_position.y < 0.15])
	_check("Down, they can see him again", false, VisionCone.hidden(_player))
	_finish()


static func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


## The move keys held so that, the way the camera faces, they point along `dir`.
func _hold_toward(dir: Vector3) -> void:
	_release_moves()
	var local := dir.normalized().rotated(Vector3.UP, -level.camera.global_rotation.y)
	if absf(local.x) > 0.01:
		Input.action_press("move_right" if local.x > 0.0 else "move_left", absf(local.x))
	if absf(local.z) > 0.01:
		Input.action_press("move_back" if local.z > 0.0 else "move_forward", absf(local.z))


func _release_moves() -> void:
	for action: String in MOVES:
		Input.action_release(action)


func _stand(at: Vector3, look: Vector3) -> void:
	var d := look - at
	_player.global_basis = Basis(Vector3.UP, atan2(-d.x, -d.z))
	_player.place(at)


## E pressed through the level's input, as a key would be, held `hold` seconds.
func _press_e(hold: float) -> void:
	var down := InputEventAction.new()
	down.action = "grab"
	down.pressed = true
	Input.parse_input_event(down)
	await _wait(hold)
	var up := InputEventAction.new()
	up.action = "grab"
	up.pressed = false
	Input.parse_input_event(up)
	await _wait(0.05)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout


func _until(done: Callable, timeout: float) -> void:
	var left := timeout
	while left > 0.0 and not done.call():
		await get_tree().physics_frame
		left -= get_physics_process_delta_time()


func _check(name: String, expected, actual) -> void:
	var ok: bool = str(expected) == str(actual)
	_failed = _failed or not ok
	_results.append([name, str(expected), str(actual), "pass" if ok else "FAIL"])


func _finish() -> void:
	_release_moves()
	print("")
	print("Raid the bear bag check, %s" % Time.get_datetime_string_from_system())
	for r: Array in _results:
		print("  %-4s  %-66s expected %-16s got %s" % [r[3], r[0], r[1], r[2]])
	print("RESULT: %s (%d checks)" % ["all checks passed" if not _failed else "SOME CHECKS FAILED", _results.size()])
	get_tree().quit(1 if _failed else 0)
