extends Node
## The automated check for the tutorial at the camp (camp_tutorial.gd) as remade on
## 7 Nov 2026, all of it on: it plays it through as a player would, with Tab, Enter and
## E going through the level's input, and checks each step:
##   - the pan: the game slowed behind the dark layer, the camera on the campers with a
##     word or two;
##   - the laugh: back on him, he chitters, the cones come on, and someone comes to look;
##   - seen: a beat with the bush lit, then a note to hide; hidden, a note to wait; once
##     they look away, a note to sneak out; out of sight, the note to press Tab;
##   - Tab: the TO DO list up, picking, the marshmallows marked;
##   - Enter: back to speed, then the guide's beats, each going on by itself: the
##     camper's routine, the sneak and unzip, the grab, the way home, and done;
##   - then the world's open: no notes, full speed, and he can move.
## While the camper's made to sit roasting, the others are kept at their first places,
## out of the way, as tasks_test.gd does. Run it headless from the project folder:
##   bash scripts/run-test.sh --tutorial-test 60
## It prints a table and quits with exit code 0 if every check passes, 1 if not. With
## `--tutorial-shots=<folder>` in a window it saves a picture at each stage.

const CampPerson := preload("res://scripts/camp_person.gd")
const Campsite := preload("res://scripts/campsite.gd")
const CampTutorial := preload("res://scripts/camp_tutorial.gd")
const HideSpot := preload("res://scripts/hide_spot.gd")
const Forest := preload("res://scripts/forest.gd")
const S := CampPerson.State
## Where he's put out of everyone's way (as tasks_test.gd).
const AWAY := Vector3(20.0, 0.02, 6.5)

## Set by the level (main.gd).
var level: Node
var shots := ""

var _results: Array[Array] = []
var _failed := false
var _camp: Campsite
var _puzzles: Node
var _tutorial: CampTutorial
var _plan
var _player: Node3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_camp = level.campsite
	_puzzles = _camp.puzzles
	_tutorial = level._tutorial
	_plan = level._plan
	_player = level.player
	_run.call_deferred()


func _run() -> void:
	await _wait(0.5)
	_check("Before the camp: no cones, no dark layer", "false false", "%s %s" % [_camp.cones_on, _tutorial.spotlight.showing()])

	# Into the clearing on its west side, by the bush, where he sees the party.
	_player.place(Vector3(Campsite.FIRE.x - 5.0, 0.02, Campsite.FIRE.y + 2.0))
	await _until(func() -> bool: return _tutorial.step == CampTutorial.Step.INTRO, 10.0)
	await _real(0.8)
	_shot("01_pan")
	_check("The pan: slowed, the camera on the campers, two words", "true true %s" % CampTutorial.PAN[0][1],
		"%s %s %s" % [Engine.time_scale <= CampTutorial.SLOW + 0.01, level.camera_focus != null, _tutorial.spotlight.line()])
	_check("The pan: he's held still, and no cones", "true false", "%s %s" % [_player.input_locked, _camp.cones_on])

	await _until_real(func() -> bool: return _tutorial.stage == "seen", 10.0)
	_check("The laugh: back on him, he laughs, the cones on", "true true true",
		"%s %s %s" % [level.camera_focus == null, _tutorial._laughed_at > -INF, _camp.cones_on])
	_check("The laugh: someone comes to look", true, _camp.people.any(func(p) -> bool: return p.state != S.WORK))

	await _until(func() -> bool: return _tutorial.stage == "seen_beat", 8.0)
	_shot("02_seen")
	_check("Seen: a beat, the bush lit, a word or two", "true true",
		"%s %s" % [_tutorial.spotlight.showing(), _tutorial.spotlight.line() in [CampTutorial.SEEN_LINE, CampTutorial.HEARD_LINE]])
	await _until_real(func() -> bool: return _tutorial.stage == "hiding", 5.0)
	_check("Then: a note to hide, back to speed, and he can move", "%s %s false" % [CampTutorial.HIDE_NOTE, 1.0],
		"%s %s %s" % [_plan.note_showing(), Engine.time_scale, _player.input_locked])

	# Into the bush.
	_player.place(_camp.bush.global_position + Vector3(0, 0.02, 0))
	await _until(func() -> bool: return _tutorial.stage == "hidden" and _player.hiding_in != null, 3.0)
	await _wait(0.5)
	_shot("02b_hidden")
	_check("In the bush: dived in, hidden, his eyes peeking, a note to wait",
		"true true true %s" % CampTutorial.HIDDEN_NOTE,
		"%s %s %s %s" % [_player.hiding_in == _camp.bush, HideSpot.is_hidden(_player), _camp.bush.peeking(),
			_plan.note_showing()])
	# Chased right to the bush he's hidden in: they can't catch him or shoo him out.
	var chaser: CampPerson = _camp.dancers[0]
	_camp.saw(_camp.bush.global_position)
	chaser._to_state(S.CHASE)
	var caught := false
	var came := INF
	for i in 300:
		await get_tree().physics_frame
		came = minf(came, Vector2(chaser.global_position.x - _player.global_position.x,
			chaser.global_position.z - _player.global_position.z).length())
		if chaser.state in [S.SHOO, S.TAKE] or _player.hiding_in == null:
			caught = true
	_check("Chased to the bush: they come right up, but can't catch him in it", "true false true",
		"%s %s %s" % [came < CampPerson.REACH, caught, _player.hiding_in == _camp.bush])

	await _until(func() -> bool: return _tutorial.stage == "sneak", 40.0)
	_check("They look away: a note to sneak out", CampTutorial.SNEAK_NOTE, _plan.note_showing())

	# Out of the bush with a move key, sneaking: a hop out, the way it points.
	Input.action_press("sneak")
	Input.action_press("move_left")
	await _wait(0.1)
	Input.action_release("move_left")
	await _wait(0.5)
	_check("A move key: he hops out that way, sneaking, his eyes gone", "false false true true",
		"%s %s %s %s" % [_player.hiding_in != null, _camp.bush.peeking(), _player.sneaking,
			_player.global_position.distance_to(_camp.bush.global_position) > 0.9])
	Input.action_release("sneak")

	# Away, out of sight.
	_player.place(AWAY)
	await _until(func() -> bool: return _tutorial.step == CampTutorial.Step.TASKS, 10.0)
	_check("Out of sight: a word, and the note to press Tab", "%s %s" % [CampTutorial.ESCAPED_LINE, CampTutorial.OPEN_NOTE],
		"%s %s" % [_tutorial.spotlight.line(), _plan.note_showing()])

	_key(KEY_TAB)
	await _real(1.0)
	_shot("03_to_do")
	_check("Tab: the TO DO list, picking, the marshmallows marked, slowed", "true true marshmallows true",
		"%s %s %s %s" % [_plan.open and _plan.up() >= 1.0, _plan.picking, _plan.highlighted(),
			Engine.time_scale <= CampTutorial.SLOW + 0.01])

	# Everyone calm and out of the way, the camper at his tent: the guide starts with
	# his routine.
	await _until(func() -> bool: return _calm(), 40.0)
	_settle([0, 0, 0])
	_key(KEY_ENTER)
	await _real(0.3)
	_check("Picked: the list away; a beat on the camper's routine", "false routine true",
		"%s %s %s" % [_plan.open, _tutorial.stage, _tutorial.spotlight.showing()])
	await _until_real(func() -> bool: return not _tutorial._holding, 4.0)
	_check("The beat goes on by itself: back to speed, a note to wait", "%s %s" % [1.0, CampTutorial.STEPS.routine[4]],
		"%s %s" % [Engine.time_scale, _plan.note_showing()])

	_settle([1, 0, 0])
	await _until(func() -> bool: return _tutorial.stage == "sneak", 30.0)
	_check("Roasting: a beat on the backpack", "sneak true", "%s %s" % [_tutorial.stage, _tutorial.spotlight.showing()])
	await _until_real(func() -> bool: return not _tutorial._holding, 4.0)
	await _sneak_to(_backpack_front(), _puzzles._backpack.global_position)
	await _wait(0.3)
	await _press_e(Campsite.CampPuzzles.ZIP_TIME + 0.3)
	await _until(func() -> bool: return _tutorial.stage == "grab", 5.0)
	_check("Unzipped: a beat on the bag", "grab true", "%s %s" % [_tutorial.stage, _tutorial.spotlight.showing()])
	await _until_real(func() -> bool: return not _tutorial._holding, 4.0)
	await _press_e(0.0)
	await _until(func() -> bool: return _tutorial.stage == "home", 5.0)
	_check("Grabbed: a beat on the way home", "home true true",
		"%s %s %s" % [_tutorial.stage, _tutorial.spotlight.showing(), _player.held == _puzzles.bag])
	await _until_real(func() -> bool: return not _tutorial._holding, 4.0)
	Input.action_release("sneak")
	_player.place(Forest.HOME + Vector3(1.0, 0.02, 1.2))
	await _wait(0.3)
	await _press_e(0.0)
	await _until(func() -> bool: return _tutorial.stage == "done", 5.0)
	_check("Home: the task done, and a last beat", "true done true",
		"%s %s %s" % [level.tasks.is_done("marshmallows"), _tutorial.stage, _tutorial.spotlight.showing()])
	await _until_real(func() -> bool: return not _tutorial._holding, 4.0)
	await _real(0.2)
	_check("Done: the world's open (no note, full speed, he can move)", "DONE  %s false" % 1.0,
		"%s %s %s %s" % [CampTutorial.Step.keys()[_tutorial.step], _plan.note_showing(), Engine.time_scale, _player.input_locked])

	for music: AudioStreamPlayer in [level._music, level._sleep_music]:
		if music:
			music.stop()
	if _camp.party:
		_camp.party.stop()
	await _wait(0.3)
	_finish()


# --- Moves ---------------------------------------------------------------------

## Each of the camper, the low-poly man and the girl at step `steps[i]` of their routine,
## staying at it, and the fire keeper eating behind the table.
func _settle(steps: Array) -> void:
	var people: Array = [_camp.camper, _camp.dancers[0], _camp.dancers[1], _camp.keeper]
	steps = steps + [0]
	for i in people.size():
		var person = people[i]
		if person._step != steps[i]:
			person._step = steps[i]
			person._arrived = false
		person._step_left = 400.0


## True while all four are calm, at work on their routines.
func _calm() -> bool:
	return _camp.people.all(func(p: CampPerson) -> bool: return p.state == S.WORK)


func _backpack_front() -> Vector3:
	var pack: Node3D = _puzzles._backpack
	return pack.global_position + pack.global_basis.z * 0.42 + Vector3(0, 0.02, 0)


func _sneak_to(at: Vector3, look: Vector3) -> void:
	Input.action_press("sneak")
	await get_tree().physics_frame
	await get_tree().physics_frame
	var d := look - at
	_player.global_basis = Basis(Vector3.UP, atan2(-d.x, -d.z))
	_player.place(at)


func _press_e(hold: float) -> void:
	var down := InputEventAction.new()
	down.action = "grab"
	down.pressed = true
	Input.parse_input_event(down)
	await _wait(maxf(hold, 0.05))
	var up := InputEventAction.new()
	up.action = "grab"
	up.pressed = false
	Input.parse_input_event(up)
	await _wait(0.05)


func _key(keycode: Key) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = keycode
		ev.physical_keycode = keycode
		ev.pressed = pressed
		Input.parse_input_event(ev)


## Game time.
func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout


## Real time, whatever speed the game runs at (under --fixed-fps, frames' worth).
func _real(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


## Until `done`, for at most `timeout` seconds of game time.
func _until(done: Callable, timeout: float) -> void:
	var left := timeout
	while left > 0.0 and not done.call():
		await get_tree().physics_frame
		left -= get_physics_process_delta_time()


## Until `done`, for at most `timeout` seconds of real time.
func _until_real(done: Callable, timeout: float) -> void:
	var left := timeout
	while left > 0.0 and not done.call():
		await get_tree().process_frame
		left -= get_process_delta_time() / maxf(Engine.time_scale, 0.001)


func _check(name: String, expected, actual) -> void:
	var ok: bool = str(expected) == str(actual)
	_failed = _failed or not ok
	_results.append([name, str(expected), str(actual), "pass" if ok else "FAIL"])


func _shot(name: String) -> void:
	if shots == "" or DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute(shots)
	get_viewport().get_texture().get_image().save_png(shots.path_join(name + ".png"))


func _finish() -> void:
	print("")
	print("Tutorial check, %s" % Time.get_datetime_string_from_system())
	for r: Array in _results:
		print("  %-4s  %-62s expected %-24s got %s" % [r[3], r[0], r[1], r[2]])
	print("RESULT: %s (%d checks)" % ["all checks passed" if not _failed else "SOME CHECKS FAILED", _results.size()])
	get_tree().quit(1 if _failed else 0)
