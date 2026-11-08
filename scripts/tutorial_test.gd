extends Node
## The automated check for the tutorial at the camp (camp_tutorial.gd) as remade on
## 7 Nov 2026, all of it on: it plays it through as a player would, with Tab and E going
## through the level's input, and checks each step:
##   - the pan: the game slowed behind the dark layer, the camera on the campers with a
##     word or two;
##   - the laugh: back on him, he chitters, the cones come on, and someone comes to look;
##   - hide: the campers frozen and the bush lit till he's in it; then they carry on, the
##     ones who saw him confused where they stand, nobody coming for him;
##   - lost: the camera on the one who saw him, confused; chased right to the bush (set
##     going by the check), they can't catch him in it; all back at work, the roasting
##     starts, with a note to sneak out, and a move key hops him out, sneaking;
##   - the plate: the first roasted marshmallow on it, the campers frozen, the plate lit,
##     no words, the raccoon hungry; he takes it with E; they come to, alerted, and the
##     men chase him; E doesn't drop it, and he can't eat it yet;
##   - away, once they're all back at work: the E over him; holding it, he sits up and
##     eats it, held still, and nobody notices; "Yum!";
##   - Tab: the TO DO list up to read, the game slowed; Tab again, and the world's open:
##     no notes, full speed, and he can move.
## Run it headless from the project folder:
##   bash scripts/run-test.sh --tutorial-test 60
## It prints a table and quits with exit code 0 if every check passes, 1 if not. With
## `--tutorial-shots=<folder>` in a window it saves a picture at each stage.

const CampPerson := preload("res://scripts/camp_person.gd")
const Campsite := preload("res://scripts/campsite.gd")
const CampTutorial := preload("res://scripts/camp_tutorial.gd")
const RoastPlate := preload("res://scripts/roast_plate.gd")
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

	await _until(func() -> bool: return _tutorial.stage == "hide", 8.0)
	await _real(0.5)
	_shot("02_hide")
	_check("Seen: the campers frozen, the bush lit, 'Hide!'", "true true %s" % CampTutorial.HIDE_LINE,
		"%s %s %s" % [_tutorial.frozen(), _camp.people.all(func(p) -> bool: return p.process_mode == Node.PROCESS_MODE_DISABLED),
			_tutorial.spotlight.line()])
	_check("Seen: full speed, he can move, a note to hide", "%s false %s" % [1.0, CampTutorial.HIDE_NOTE],
		"%s %s %s" % [Engine.time_scale, _player.input_locked, _plan.note_showing()])
	await _wait(1.0)
	_check("Held: it waits for him to hide", "hide true", "%s %s" % [_tutorial.stage, _tutorial.frozen()])

	# Into the bush. Whoever saw him or took fright is confused where they stand; nobody
	# comes for him (the author: "dont let the npcs run to him").
	var alarmed: Array = _camp.people.filter(func(p) -> bool: return p.state != S.WORK)
	_player.place(_camp.bush.global_position + Vector3(0, 0.02, 0))
	await _until(func() -> bool: return _tutorial.stage == "hidden" and _player.hiding_in != null, 3.0)
	var went_for_him := false
	var drift := 0.0
	var was := {}
	for i in 30:
		await get_tree().physics_frame
		_watch_calm(was)
	_shot("03_hidden")
	_check("In the bush: the campers carry on, his eyes peeking, a note to wait",
		"false true true %s" % CampTutorial.HIDDEN_NOTE,
		"%s %s %s %s" % [_tutorial.frozen(), _player.hiding_in == _camp.bush, _camp.bush.peeking(), _plan.note_showing()])
	_check("In the bush: the ones who saw him are confused ('??') where they stand", "true true",
		"%s %s" % [not alarmed.is_empty(), alarmed.all(func(p) -> bool: return p.state == S.SEARCH)])

	await _until(func() -> bool: return _watch_calm(was) or _tutorial.stage == "lost", 20.0)
	_shot("04_lost")
	_check("Lost: the camera on the one who saw him, confused", "true true %s" % CampTutorial.LOST_LINE,
		"%s %s %s" % [level.camera_focus != null, _tutorial._spotter != null and _tutorial._spotter.state == S.SEARCH,
			_tutorial.spotlight.line()])
	await _until_real(func() -> bool: return _watch_calm(was) or _tutorial.stage == "calming", 6.0)
	went_for_him = was.get("went", false)
	drift = was.get("drift", 0.0)
	_check("In the bush, till they've lost him: nobody came for him, nobody moved while confused", "false true",
		"%s %s" % [went_for_him, drift < 0.1])

	# Chased right to the bush he's hidden in (set going by the check): they can't catch
	# him or shoo him out.
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

	await _until(func() -> bool: return _tutorial.stage == "roast", 40.0)
	_check("All back at work: the camper roasting and serving, a note to sneak out",
		"true roast serve %s" % CampTutorial.SNEAK_NOTE,
		"%s %s %s" % [_calm(), " ".join(_camp.camper.routine.map(func(a: Dictionary) -> String: return a.name)),
			_plan.note_showing()])

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
	await _wait(0.1)
	_check("Out: the note goes, and no other words", "", _plan.note_showing())

	# Back in the bush, to watch the camper roast and serve, as a player might.
	_player.place(_camp.bush.global_position + Vector3(0, 0.02, 0))
	await _until(func() -> bool: return _tutorial.stage == "grab", 30.0)
	await _real(0.4)
	_shot("05_plate")
	_check("Served: one on the plate, the campers frozen, it's lit with no words, he's hungry", "1 true true true  hungry",
		"%s %s %s %s %s %s" % [_tutorial.roast.on_plate, _tutorial.frozen(),
			_camp.people.all(func(p) -> bool: return p.process_mode == Node.PROCESS_MODE_DISABLED),
			_tutorial.spotlight.showing(), _tutorial.spotlight.line(), level.bubbles.showing()])
	_check("Served: no note, full speed, he can move", "%s %s false" % ["", 1.0],
		"%s %s %s" % [_plan.note_showing(), Engine.time_scale, _player.input_locked])
	await _wait(1.0)
	_check("Held: it waits for him to take it", "grab true 1", "%s %s %s" % [_tutorial.stage, _tutorial.frozen(),
		_tutorial.roast.on_plate])

	# Over to the plate, and E takes it.
	var spotted_before: float = _camp.spotted_at
	await _sneak_to(_tutorial.roast.take_from(), _tutorial.roast.plate_point())
	await _wait(0.3)
	await _press_e(RoastPlate.TAKE_TIME + 0.2)
	Input.action_release("sneak")
	await _wait(0.1)
	_check("Taken: in his mouth, off the plate, the campers come to, the dark layer gone", "true 0 false false",
		"%s %s %s %s" % [_tutorial.roast.carrying(), _tutorial.roast.on_plate, _tutorial.frozen(),
			_tutorial.spotlight.showing()])
	await _until(func() -> bool: return _camp.people.any(func(p) -> bool: return p.state == S.CHASE), 4.0)
	_shot("06_taken")
	_check("Taken: the camper spots him, the men chase him", "true true",
		"%s %s" % [_camp.spotted_at > spotted_before, _camp.people.any(func(p) -> bool: return p.state == S.CHASE)])
	# Away out of the camp. A chaser may have shooed him already, and his leap may have
	# landed him in the bush (a dive starts the tick after): it's all over first.
	await _wait(0.6)
	await _until(func() -> bool: return not _player.is_hopping(), 3.0)
	await _wait(0.2)
	_player.place(AWAY)
	await _wait(0.2)
	await _press_e(0.1)
	_check("Running with it: he keeps it, E doesn't drop it, and he can't eat it yet", "true true false",
		"%s %s %s" % [_player.global_position.distance_to(AWAY) < 0.5, _tutorial.roast.carrying(),
			_tutorial.roast.can_eat_now()])

	# Till they've lost him and all gone back to work.
	await _until(func() -> bool: return _tutorial.roast.can_eat_now(), 40.0)
	_check("Away, once they're all back at work: the E to eat it", "true true true",
		"%s %s %s" % [_calm(), _tutorial.roast.carrying(), _tutorial.roast.can_eat_now()])

	# Holding E, he sits up and eats it.
	var spotted_away: float = _camp.spotted_at
	var down := InputEventAction.new()
	down.action = "grab"
	down.pressed = true
	Input.parse_input_event(down)
	await _wait(RoastPlate.EAT_FOR * 0.45)
	_shot("07_eating")
	_check("Holding E: he sits up and eats it, held still", "bored true true",
		"%s %s %s" % [_player.model.forced_animation, _player.input_locked, _tutorial.roast.eating()])
	await _wait(RoastPlate.EAT_FOR * 0.55 + 0.2)
	var up := InputEventAction.new()
	up.action = "grab"
	up.pressed = false
	Input.parse_input_event(up)
	await _until(func() -> bool: return _tutorial.step == CampTutorial.Step.TASKS, 3.0)
	_check("Eaten once they'd calmed: nobody noticed", "true WORK WORK WORK WORK",
		"%s %s" % [_camp.spotted_at == spotted_away, " ".join(_camp.people.map(func(p) -> String: return S.keys()[p.state]))])
	_shot("08_yum")
	_check("Eaten: 'Yum!', the note to press Tab, he's up, the camper's own routine back",
		"%s %s false  peg roast pizza" % [CampTutorial.YUM_LINE, CampTutorial.OPEN_NOTE],
		"%s %s %s %s %s" % [_tutorial.spotlight.line(), _plan.note_showing(), _tutorial.roast.carrying(),
			_player.model.forced_animation, " ".join(_camp.camper.routine.map(func(a: Dictionary) -> String: return a.name))])

	_key(KEY_TAB)
	await _real(1.0)
	_shot("09_to_do")
	_check("Tab: the TO DO list up to read, the camp's tasks on it, slowed", "true investigate party marshmallows music cooler true",
		"%s %s %s" % [_plan.open and _plan.up() >= 1.0,
			" ".join(level.tasks.shown().map(func(t: Dictionary) -> String: return t.id)), Engine.time_scale <= CampTutorial.SLOW + 0.01])
	_key(KEY_TAB)
	await _real(0.5)
	_check("Tab again: the world's open (list away, no note, full speed, he can move)", "DONE false  %s false" % 1.0,
		"%s %s %s %s %s" % [CampTutorial.Step.keys()[_tutorial.step], _plan.open, _plan.note_showing(), Engine.time_scale,
			_player.input_locked])

	for music: AudioStreamPlayer in [level._music, level._sleep_music]:
		if music:
			music.stop()
	if _camp.party:
		_camp.party.stop()
	await _wait(0.3)
	_finish()


# --- Watching -------------------------------------------------------------------

## Notes in `was` whether anyone has gone for him (chasing, wondering, guarding or
## shooing) and how far anyone has moved while confused, since it was first called.
## Returns false, so it can ride along in an `_until`.
func _watch_calm(was: Dictionary) -> bool:
	for person: CampPerson in _camp.people:
		if person.state in [S.CHASE, S.INVESTIGATE, S.GUARD, S.SHOO]:
			was["went"] = true
		var key := person.get_instance_id()
		if person.state == S.SEARCH:
			if not was.has(key):
				was[key] = person.global_position
			was["drift"] = maxf(was.get("drift", 0.0), person.global_position.distance_to(was[key]))
		else:
			was.erase(key)
	return false


# --- Moves ---------------------------------------------------------------------

## True while all four are calm, at work on their routines.
func _calm() -> bool:
	return _camp.people.all(func(p: CampPerson) -> bool: return p.state == S.WORK)


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
