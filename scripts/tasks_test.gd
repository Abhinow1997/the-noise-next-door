extends Node
## The automated check for level 1's first puzzles (camp_puzzles.gd) and the campers'
## routines (camp_person.gd): it plays each task through E, as the player would (an E
## press goes through camp_input.gd), and checks what the campers make of it. Run it
## headless from the project folder:
##   godot --headless --path . --audio-driver Dummy -- --tasks-test
## It prints a table and quits with exit code 0 if every check passes, 1 if not. With
## `--tasks-shots=<folder>` in a window it saves a picture at each stage, and with
## `--tasks-debug` it prints each camper's every change of state as it goes.

const CampPerson := preload("res://scripts/camp_person.gd")
const Campsite := preload("res://scripts/campsite.gd")
const Forest := preload("res://scripts/forest.gd")
const S := CampPerson.State
## Where he's put out of everyone's way.
const AWAY := Vector3(20.0, 0.02, 6.5)

## Set by the level (main.gd).
var level: Node
var shots := ""

var _results: Array[Array] = []
var _failed := false
var _camp: Campsite
var _puzzles: Node
var _camper: CampPerson
var _man: CampPerson
var _girl: CampPerson
var _player: Node3D
var _seen_states := {}
var _been_at := {}
var _debug := false
var _last_state := {}
var _frame := 0


func _ready() -> void:
	_camp = level.campsite
	_puzzles = _camp.puzzles
	_camper = _camp.camper
	_man = _camp.dancers[0]
	_girl = _camp.dancers[1]
	_player = level.player
	_debug = OS.get_cmdline_user_args().has("--tasks-debug")
	_run.call_deferred()


func _physics_process(_delta: float) -> void:
	_frame += 1
	for person: CampPerson in [_camper, _man, _girl]:
		if not _seen_states.has(person):
			_seen_states[person] = {}
		_seen_states[person][person.state] = true
		if not _been_at.has(person):
			_been_at[person] = {}
		if person.at_activity():
			_been_at[person][person.activity()] = true
		if _debug and _last_state.get(person, -1) != person.state:
			_last_state[person] = person.state
			print("%6.1f %-8s %-11s %-6s %s %s  him %s seeing %s" % [_camp.clock, person.name.left(8),
				S.keys()[person.state], person.activity(), person.at_activity(),
				person.global_position.snapped(Vector3.ONE * 0.01), _player.global_position.snapped(Vector3.ONE * 0.01),
				person.eyes.seeing])


func _run() -> void:
	await _wait(1.0)
	_check("The to-do list is level 1's four tasks", "investigate marshmallows music cooler",
		" ".join(level.tasks.list.map(func(t: Dictionary) -> String: return t.id)))
	_check("Routines: the camper starts pegging out his tent", "peg", _camper.activity())
	_check("Routines: the low-poly man starts dancing", "dance", _man.activity())

	# Routines: each moves on to their next activity in turn, walking there.
	_camper._step_left = 0.01
	_man._step_left = 0.01
	_girl._step_left = 0.01
	await _wait(0.2)
	_check("Routines: each moves on to their next activity", "roast drink warm",
		" ".join([_camper.activity(), _man.activity(), _girl.activity()]))
	_check("Routines: walking there", "false false false",
		"%s %s %s" % [_camper.at_activity(), _man.at_activity(), _girl.at_activity()])
	await _until(func() -> bool: return _man.at_activity(), 10.0)
	await _wait(0.5)
	_check("Routines: the low-poly man gets to the cooler and opens it for a drink", true,
		_man.at_activity() and _man.activity() == "drink" and _puzzles._lid_open)
	await _until(func() -> bool: return _man.activity() == "dance", 6.0)
	_check("Routines: drink done, he goes back to dancing", "dance", _man.activity())
	await _wait(0.1)
	_check("Routines: he shuts the cooler after him, unless he forgets", _puzzles._forgot, _puzzles._lid_open)
	await _until(func() -> bool: return _camper.at_activity(), 15.0)
	_check("Routines: the camper sits roasting by the fire", true, _been_at[_camper].has("roast"))
	await _until(func() -> bool: return _been_at[_girl].has("warm"), 10.0)
	_check("Routines: the girl warms her hands at the fire", true, _been_at[_girl].has("warm"))
	if _girl.activity() == "warm":
		_girl._step_left = 0.01
	await _until(func() -> bool: return _girl.activity() == "dance" and _girl.at_activity(), 15.0)
	_check("Routines: and round again: she's back dancing", true, _girl.activity() == "dance" and _girl.at_activity())

	# Steal the marshmallows, caught: unzipped behind the roasting camper, then seen
	# with the bag; they snatch it back and the bag goes back in, zipped.
	await _settle([1, 0, 0])
	await _sneak_to(_backpack_front(), _puzzles._backpack.global_position)
	await _wait(0.3)
	_mark()
	await _press_e(Campsite.CampPuzzles.ZIP_TIME + 0.3)
	_check("Marshmallows: holding E unzips the backpack", true, _puzzles._unzipped)
	_check("Marshmallows: the bag tumbles out", true, _puzzles.bag.visible and _puzzles.bag.is_in_group("grabbable"))
	_check("Marshmallows: unzipped behind his back, unheard over the music", "WORK", S.keys()[_camper.state])
	await _press_e(0.0)
	await _wait(0.3)
	_check("Marshmallows: E picks the bag up", true, _player.held == _puzzles.bag)
	_mark()
	var by_fire := Vector3(Campsite.FIRE.x - 0.3, 0.02, Campsite.FIRE.y - 0.95)
	_stand(by_fire, _man.global_position)
	Input.action_release("sneak")
	await _until(func() -> bool: return S.TAKE in _seen(_camper) or S.TAKE in _seen(_man), 15.0)
	_check("Caught with the bag: a man snatches it back", true, S.TAKE in _seen(_camper) or S.TAKE in _seen(_man))
	_check("Caught with the bag: it's out of his mouth", false, _player.held == _puzzles.bag)
	await _wait(1.2)
	_shot("01_caught_with_the_bag_snatched_back_by-claude")
	await _wait(2.3)
	_check("Caught: the backpack's zipped up again", false, _puzzles._unzipped)
	_check("Caught: the bag's back inside", false, _puzzles.bag.visible)
	_check("Caught: the task's still to do", false, level.tasks.is_done("marshmallows"))
	_player.place(AWAY)
	await _until(func() -> bool: return _states() == "WORK WORK WORK", 30.0)
	_check("Calm again after the snatch", "WORK WORK WORK", _states())

	# Steal the marshmallows, clean: behind the roasting camper, then off home with it.
	await _settle([1, 0, 0])
	await _sneak_to(_backpack_front(), _puzzles._backpack.global_position)
	await _wait(0.3)
	_mark()
	await _press_e(Campsite.CampPuzzles.ZIP_TIME + 0.3, "02_unzipping_behind_his_back_by-claude")
	_shot("03_the_bag_tumbles_out_by-claude")
	await _press_e(0.0)
	await _wait(0.3)
	_check("Marshmallows again: the bag's in his mouth", true, _player.held == _puzzles.bag)
	_check("Marshmallows again: nobody noticed", "WORK WORK WORK", _states())
	Input.action_release("sneak")
	_player.place(Forest.HOME + Vector3(1.0, 0.02, 1.2))
	await _wait(0.3)
	await _press_e(0.0)
	await _wait(0.8)
	_check("Marshmallows: dropped in his stash, the task's done", true, level.tasks.is_done("marshmallows"))

	# Music off: tug the plug out, drag it off; everyone wonders, then the low-poly man
	# finds it and puts it back.
	await _settle([0, 0, 0])
	var socket: Vector3 = _puzzles._socket
	await _sneak_to(socket + Vector3(0.0, 0.02, 0.4), socket)
	await _wait(0.3)
	_mark()
	await _press_e(Campsite.CampPuzzles.PULL_TIME + 0.3)
	_check("Music off: the plug comes out in his mouth", true, _player.held == _puzzles.plug)
	_check("Music off: the music stops", false, _camp.music_on)
	_check("Music off: the speaker's quiet", false, _camp.party.playing)
	_check("Music off: the task's done", true, level.tasks.is_done("music"))
	_check("Music off: the dancers stop dead, mid-move", "0 0",
		"%d %d" % [_man.anim.speed_scale, _girl.anim.speed_scale])
	_shot("04_music_off_they_stop_dead_by-claude")
	_player.place(socket + Vector3(-1.6, 0.02, -0.8))
	await _wait(0.2)
	await _press_e(0.0)
	await _wait(0.3)
	_check("Music off: he drops the plug away from the socket", true, _player.held == null)
	_player.place(AWAY)
	await _wait(2.0)
	_check("Music off: frozen, they don't see him get away", false,
		S.STARTLED in _seen(_man) or S.STARTLED in _seen(_girl))
	_check("Music off: the dancers wonder what happened", true,
		S.INVESTIGATE in _seen(_man) and S.INVESTIGATE in _seen(_girl))
	await _until(func() -> bool: return S.FIX in _seen(_man), 20.0)
	_check("Music off: the low-poly man goes to put it back", true, S.FIX in _seen(_man))
	await _until(func() -> bool: return _camp.music_on, 30.0)
	_check("Music off: he plugs it back in and the music's on", true, _camp.music_on and _camp.party.playing)
	_check("Music off: the task stays done", true, level.tasks.is_done("music"))

	# Noise: the same clunk is lost in the music, and heard in the quiet.
	await _settle([0, 0, 0])
	_mark()
	var near_man: Vector3 = _man.global_position + Vector3(2.5, 0, 0)
	_camp.noise(near_man, Campsite.CampPuzzles.LID_NOISE)
	await _wait(0.5)
	_check("Noise: a clunk 2.5 m off, with the music on: unheard", false, S.INVESTIGATE in _seen(_man))
	_puzzles.music_on = false
	_camp.noise(near_man, Campsite.CampPuzzles.LID_NOISE)
	await _wait(0.5)
	_check("Noise: the same clunk with the music off: he wonders", true, S.INVESTIGATE in _seen(_man))
	_puzzles.music_on = true

	# Raid the cooler: nose the lid open while the camper's pegging his tent and the
	# others are dancing, lost in the music; take the sausages home.
	await _settle([0, 0, 0])
	if _puzzles._lid_open:
		# Left open after a drink: shut, so it's his to open.
		_puzzles._reset_cooler()
		await _wait(0.5)
	var cooler: Node3D = _puzzles.cooler
	await _sneak_to(cooler.global_position + cooler.global_basis.z * 0.45, cooler.global_position)
	await _wait(0.3)
	_mark()
	await _press_e(Campsite.CampPuzzles.LID_TIME + 0.3, "05_nosing_the_cooler_open_by-claude")
	await _wait(0.5)
	_check("Cooler: holding E noses the lid open", true, _puzzles._lid_open)
	_check("Cooler: the sausages can be reached", true, _puzzles.sausages.is_in_group("grabbable"))
	_shot("06_the_sausages_by-claude")
	await _press_e(0.0)
	await _wait(0.3)
	_check("Cooler: E takes the sausages", true, _player.held == _puzzles.sausages)
	_check("Cooler: nobody noticed", "WORK WORK WORK", _states())
	Input.action_release("sneak")
	_player.place(Forest.HOME + Vector3(-1.0, 0.02, 1.2))
	await _wait(0.3)
	await _press_e(0.0)
	await _wait(0.8)
	_check("Cooler: dropped in his stash, the task's done", true, level.tasks.is_done("cooler"))
	_check("All four tasks done", true, level.tasks.all_done())
	await _wait(1.0)
	_shot("07_loot_in_his_stash_all_ticked_by-claude")

	for music: AudioStreamPlayer in [level._music, level._sleep_music]:
		if music:
			music.stop()
	if _camp.party:
		_camp.party.stop()
	await _wait(0.3)
	_finish()


# --- Moves ---------------------------------------------------------------------

## Out of the way, everyone calm, then each at step `steps[i]` of their routine (the
## camper, the low-poly man, the girl), staying at it.
func _settle(steps: Array) -> void:
	Input.action_release("sneak")
	_player.place(AWAY)
	await _until(func() -> bool: return _states() == "WORK WORK WORK", 40.0)
	var people: Array[CampPerson] = [_camper, _man, _girl]
	for i in people.size():
		if people[i]._step != steps[i]:
			people[i]._step = steps[i]
			people[i]._arrived = false
		people[i]._step_left = 400.0
	await _until(func() -> bool: return people.all(func(p: CampPerson) -> bool: return p.at_activity()), 30.0)
	await _wait(0.5)


func _backpack_front() -> Vector3:
	var pack: Node3D = _puzzles._backpack
	return pack.global_position + pack.global_basis.z * 0.42 + Vector3(0, 0.02, 0)


## Sneaking, put at `at` facing `look`. He's sneaking before he's put there, as he
## would be walking up.
func _sneak_to(at: Vector3, look: Vector3) -> void:
	Input.action_press("sneak")
	await get_tree().physics_frame
	await get_tree().physics_frame
	_stand(at, look)


func _stand(at: Vector3, look: Vector3) -> void:
	var d := look - at
	_player.global_basis = Basis(Vector3.UP, atan2(-d.x, -d.z))
	_player.place(at)


## E pressed (through the level's input, as a key would be), held `hold` seconds;
## with `shot`, a picture halfway through.
func _press_e(hold: float, shot := "") -> void:
	var down := InputEventAction.new()
	down.action = "grab"
	down.pressed = true
	Input.parse_input_event(down)
	if shot != "":
		await _wait(hold * 0.5)
		_shot(shot)
		await _wait(hold * 0.5)
	else:
		await _wait(maxf(hold, 0.05))
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


func _mark() -> void:
	_seen_states.clear()


func _seen(person: CampPerson) -> Array:
	return _seen_states.get(person, {}).keys()


func _states() -> String:
	return " ".join([_camper, _man, _girl].map(func(p: CampPerson) -> String: return S.keys()[p.state]))


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
	print("Camp tasks check, %s" % Time.get_datetime_string_from_system())
	for r: Array in _results:
		print("  %-4s  %-66s expected %-16s got %s" % [r[3], r[0], r[1], r[2]])
	print("RESULT: %s (%d checks)" % ["all checks passed" if not _failed else "SOME CHECKS FAILED", _results.size()])
	get_tree().quit(1 if _failed else 0)
