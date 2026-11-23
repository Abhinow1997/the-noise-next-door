extends Node
## The automated check for Dismantle the tent (camp_tent.gd, the camper's PITCH in
## camp_person.gd), added on 8 Nov 2026. The level starts as the open world does after
## the tutorial, with the list on the page (main.gd, `--tent-test`).
##   - near a peg, it twinkles; holding E at it (through the level's input, as the key
##     would) pulls it, and the tent sags;
##   - a peg pulled unseen stays out; seen with one out, the camper, once calm, hammers it
##     back in;
##   - the fourth out: the tent falls, every one of them is alerted, and the task's done;
##     once they're calm, the camper pitches it again.
## While he pulls, the campers' cones are off (campsite.gd `cones_on`), so his being seen
## doesn't get in the way, except where being seen is the point.
## Run it headless from the project folder:
##   bash scripts/run-test.sh --tent-test 60
## It prints a table and quits with exit code 0 if every check passes, 1 if not.

const CampPerson := preload("res://scripts/camp_person.gd")
const CampTent := preload("res://scripts/camp_tent.gd")
const S := CampPerson.State

## Set by the level (main.gd).
var level: Node

var _results: Array[Array] = []
var _failed := false
var _camp
var _tent: CampTent
var _camper: CampPerson
var _player: Node3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_camp = level.campsite
	_tent = _camp.tent_pegs
	_camper = _camp.camper
	_player = level.player
	_run.call_deferred()


func _run() -> void:
	_camp.cones_on = false
	await _wait(0.3)
	_check("Start: four pegs in, the tent up", "4 0 false", "%d %d %s" % [_tent.pegs.size(), _tent.out_count(), _tent.down])
	_check("Start: far off, no peg twinkles", false, _tent.pegs.any(func(p) -> bool: return p.glint in level.bubbles.glinting()))
	_player.place(_outside(0, 1.5))
	await _wait(0.5)
	_check("Near a peg, it twinkles", true, _tent.pegs[0].glint in level.bubbles.glinting())

	# One peg, unseen: it stays out.
	await _pull(0)
	_check("Holding E pulls it: one out, the tent sags", "1 true", "%d %s" % [_tent.out_count(), _model_height() < 1.0])
	_check("Pulled, it doesn't twinkle", true, _tent.pegs[0].glint.get_meta("found"))
	_player.place(Vector3(20.0, 0.02, 6.5))
	await _wait(15.0)
	_check("Pulled unseen, it stays out", "1 false", "%d %s" % [_tent.out_count(), _camper.state == S.PITCH])

	# Seen with it out: the camper puts it back once he's calm.
	_camp.cones_on = true
	var eyes: Vector3 = _camper.global_position
	var ahead: Vector3 = _camper.global_basis.z * Vector3(1, 0, 1)
	_stand(eyes + ahead.normalized() * 2.5 + Vector3(0, 0.02, 0), eyes)
	await _until(func() -> bool: return _camp.seen_within(0.2), 3.0)
	_check("Seen by the camper", true, _camp.seen_within(0.5))
	_player.place(Vector3(20.0, 0.02, 6.5))
	await _until(func() -> bool: return _camper.state == S.PITCH, 60.0)
	_check("Calm again, he goes to pitch it", "PITCH", S.keys()[_camper.state])
	await _until(func() -> bool: return _tent.out_count() == 0, 40.0)
	_check("He hammers the peg back in", 0, _tent.out_count())

	# All four: down it comes.
	await _until(func() -> bool: return _camper.state == S.WORK or _camper.state == S.RETURN, 20.0)
	_camp.cones_on = false
	for i in 3:
		await _pull(i)
	_check("Three out: the tent's still up, sagging more", "3 false", "%d %s" % [_tent.out_count(), _tent.down])
	await _pull(3)
	_check("The fourth out: the tent falls", "4 true", "%d %s" % [_tent.out_count(), _tent.down])
	await _wait(0.6)
	_check("It lies flat", true, _model_height() <= CampTent.FLAT + 0.01)
	_check("Every one of them is alerted", true, _camp.people.all(func(p) -> bool: return p.state != S.WORK and p.state != S.PITCH))
	_check("The task's done", true, _camp.tasks.is_done("tent"))
	_player.place(Vector3(20.0, 0.02, 6.5))
	await _until(func() -> bool: return not _tent.down, 120.0)
	_check("Calm again, the camper pitches it again", "0 false", "%d %s" % [_tent.out_count(), _tent.down])
	await _wait(0.6)
	_check("It stands", true, _model_height() > 0.99)
	_finish()


## Where he stands to pull peg `i`: `far` metres out from it, away from the tent.
func _outside(i: int, far := 0.45) -> Vector3:
	var at: Vector3 = _tent.pegs[i].at
	var out: Vector3 = (at - _tent.tent.position) * Vector3(1, 0, 1)
	return at + out.normalized() * far + Vector3(0, 0.02, 0)


func _pull(i: int) -> void:
	_stand(_outside(i), _tent.pegs[i].at)
	await _wait(0.2)
	await _press_e(CampTent.PULL_TIME + 0.3)


func _model_height() -> float:
	return (_tent.tent.get_child(0) as Node3D).scale.y


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
	print("")
	print("Dismantle the tent check, %s" % Time.get_datetime_string_from_system())
	for r: Array in _results:
		print("  %-4s  %-60s expected %-14s got %s" % [r[3], r[0], r[1], r[2]])
	print("RESULT: %s (%d checks)" % ["all checks passed" if not _failed else "SOME CHECKS FAILED", _results.size()])
	get_tree().quit(1 if _failed else 0)
