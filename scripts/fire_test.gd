extends Node
## The automated check for the campfire's life in the open world (camp_fire.gd, the
## keeper's TEND in camp_person.gd), added on 8 Nov 2026. The level starts as the open
## world does after the tutorial: the fire cold, its cycle on (main.gd, `--fire-test`).
##   - the keeper sets off for the woodpile on his own, lights the fire (it flares) and
##     builds it up, then goes back to his routine; the flames and light come back;
##   - near the bucket, it twinkles; holding E at it (through the level's input, as the
##     key would) tips it: the fire's out in DOUSE_TIME, and the hiss sets someone
##     wondering;
##   - the keeper, calm again, sets the bucket back up and lights the fire again.
## For the bucket the campers' cones are off (campsite.gd `cones_on`), so his being seen
## doesn't get in the way: what's checked is the fire, not the sneaking.
## Run it headless from the project folder:
##   bash scripts/run-test.sh --fire-test 60
## It prints a table and quits with exit code 0 if every check passes, 1 if not.

const CampPerson := preload("res://scripts/camp_person.gd")
const CampFire := preload("res://scripts/camp_fire.gd")
const S := CampPerson.State

## Set by the level (main.gd).
var level: Node

var _results: Array[Array] = []
var _failed := false
var _camp
var _fire: CampFire
var _keeper: CampPerson
var _player: Node3D
var _lit := 0
var _doused := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_camp = level.campsite
	_fire = _camp.campfire
	_keeper = _camp.keeper
	_player = level.player
	_fire.lit.connect(func() -> void: _lit += 1)
	_fire.doused.connect(func() -> void: _doused += 1)
	_run.call_deferred()


func _run() -> void:
	# Out of everyone's way while the keeper builds it.
	_player.place(Vector3(20.0, 0.02, 6.5))
	await _wait(0.2)
	_check("Start: the cycle on, the fire out", "true 0.00", "%s %.2f" % [_fire.cycle, _fire.strength])
	_check("Start: no flames, no light", "false 0.00", "%s %.2f" % [_flames_showing(), _camp._fire_light.light_energy])
	_check("Start: the bucket doesn't twinkle with the fire out", true, _fire._glint.get_meta("found"))
	await _until(func() -> bool: return _keeper.state == S.TEND, 2.0)
	_check("The keeper sets off to tend it on his own", "TEND", S.keys()[_keeper.state])

	await _until(func() -> bool: return _lit > 0, 40.0)
	_check("He lights it: lit once, flaring", "1 true", "%d %s" % [_lit, _fire.flare > 0.5])
	await _wait(0.1)
	_check("Lit: flames and light", "true true", "%s %s" % [_flames_showing(), _camp._fire_light.light_energy > 0.0])
	await _until(func() -> bool: return _keeper.state != S.TEND, 60.0)
	_check("He builds it up, then goes back to his routine", "true true",
		"%s %s" % [_fire.strength >= CampFire.FEED_TO - CampFire.LOG_ADDS, _keeper.state in [S.RETURN, S.WORK]])
	var before := _fire.strength
	await _wait(5.0)
	_check("It burns down slowly unfed", true, _fire.strength < before and _fire.strength > before - 0.1)

	# The firelight (campsite.gd `in_firelight`): standing in it, they see him further;
	# crouching, only as far as ever while he sneaks. Read off the camper's eyes.
	_camp.cones_on = false
	var camper: CampPerson = _camp.camper
	await _wait(0.1)
	var unlit: float = camper.eyes.reach
	_player.place(_fire.global_position + Vector3(0, 0.02, 2.6))
	await _wait(0.1)
	_check("In the firelight, standing: seen half as far again", "true %.2f" % CampPerson.FIRELIT_SIGHT,
		"%s %.2f" % [_camp.in_firelight(_player.global_position), camper.eyes.reach / unlit])
	Input.action_press("sneak")
	await _wait(0.2)
	_check("In it, crouching: only as far as while sneaking", "%.2f" % CampPerson.SNEAK_SIGHT, "%.2f" % (camper.eyes.reach / unlit))
	Input.action_release("sneak")
	_player.place(Vector3(20.0, 0.02, 6.5))
	_camp.cones_on = true
	await _wait(0.2)

	# The bucket, with the campers blind to him (above).
	_camp.cones_on = false
	_player.place(_fire.bucket.global_position + Vector3(-1.6, 0.02, 1.6))
	await _wait(0.5)
	_check("Near the bucket, it twinkles", true, _fire._glint in level.bubbles.glinting())
	_stand(_fire.bucket_spot() + Vector3(0, 0.02, 0) + (_fire.bucket_spot() - _fire.bucket.global_position).normalized() * -0.1,
		_fire.bucket.global_position)
	await _wait(0.3)
	var calm: int = _camp.people.filter(func(p) -> bool: return p.state in [S.WORK, S.RETURN, S.TEND]).size()
	await _press_e(CampFire.TIP_TIME + 0.3)
	_check("Holding E tips it over: doused once", "1 true", "%d %s" % [_doused, _fire.bucket_tipped])
	await _wait(CampFire.DOUSE_TIME + 0.1)
	_check("The fire's out, the flames gone", "0.00 false", "%.2f %s" % [_fire.strength, _flames_showing()])
	_check("The bucket's over: no twinkle", true, _fire._glint.get_meta("found"))
	_check("The hiss is heard: someone stops to wonder", true,
		_camp.people.filter(func(p) -> bool: return p.state in [S.WORK, S.RETURN, S.TEND]).size() < calm)

	# He's gone; they calm down, and the keeper sees to it.
	_player.place(Vector3(20.0, 0.02, 6.5))
	await _until(func() -> bool: return not _fire.bucket_tipped, 60.0)
	_check("The keeper sets the bucket back up", "false TEND", "%s %s" % [_fire.bucket_tipped, S.keys()[_keeper.state]])
	await _until(func() -> bool: return _lit > 1, 40.0)
	_check("And lights it again", 2, _lit)
	_finish()


func _flames_showing() -> bool:
	return _camp._flames.any(func(f: Dictionary) -> bool: return f.node.visible)


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
	print("Campfire check, %s" % Time.get_datetime_string_from_system())
	for r: Array in _results:
		print("  %-4s  %-60s expected %-14s got %s" % [r[3], r[0], r[1], r[2]])
	print("RESULT: %s (%d checks)" % ["all checks passed" if not _failed else "SOME CHECKS FAILED", _results.size()])
	get_tree().quit(1 if _failed else 0)
