extends Node
## The automated check for CHANGE-BRIEF.md's sound map. It plays a scripted input
## sequence, counts how often each sound effect starts, and compares the counts
## with the expected ones. It also checks the music's pause, mute, loop and end
## behaviour. Run it headless from the project folder:
##   godot --headless --path . -- --sound-test
## It prints a table and quits with exit code 0 if every check passes, 1 if not.

## Set by the level (main.gd).
var level: Node

var _frame := 0
var _steps := {}
var _results: Array[Array] = []
var _failed := false


func _ready() -> void:
	# Pausing is part of the test, so the test itself must keep running.
	process_mode = Node.PROCESS_MODE_ALWAYS
	var player: CharacterBody3D = level.player

	# Chitter: five quick presses, then one press held down with key repeats.
	for k in 5:
		_at(10 + 4 * k, _key.bind(KEY_SPACE, true, false))
		_at(11 + 4 * k, _key.bind(KEY_SPACE, false, false))
	_at(34, _key.bind(KEY_SPACE, true, false))
	for k in 8:
		_at(36 + 2 * k, _key.bind(KEY_SPACE, true, true))
	_at(52, _key.bind(KEY_SPACE, false, false))

	# Running: a run, then Shift tapped off and on quickly while he keeps moving,
	# then a stop, then a second run.
	_at(60, func() -> void:
		Input.action_press("move_right")
		Input.action_press("run"))
	for k in 10:
		_at(120 + 4 * k, Input.action_release.bind("run"))
		_at(122 + 4 * k, Input.action_press.bind("run"))
	_at(170, func() -> void:
		Input.action_release("run")
		Input.action_release("move_right"))
	_at(200, func() -> void: player.global_position = level.Forest.START)
	_at(210, func() -> void:
		Input.action_press("move_right")
		Input.action_press("run"))
	_at(270, func() -> void:
		Input.action_release("run")
		Input.action_release("move_right"))

	# Climbing: onto the nearest trunk, up, cling still, then down a little.
	_at(300, func() -> void:
		player.global_position = level.Forest.START
		var nearest: Dictionary = level.forest.climbable[0]
		for tree: Dictionary in level.forest.climbable:
			if tree.base.distance_to(player.global_position) < nearest.base.distance_to(player.global_position):
				nearest = tree
		player._start_climb(nearest))
	_at(320, Input.action_press.bind("move_forward"))
	_at(360, Input.action_release.bind("move_forward"))
	_at(380, Input.action_press.bind("move_back"))
	_at(395, Input.action_release.bind("move_back"))

	# Tasks: five ticked off over four frames, two of them in the same frame.
	var den: Vector3 = level.Forest.HOME
	_at(420, func() -> void: level.bin.rotation = Vector3(PI / 2, 0, 0))
	_at(440, func() -> void:
		level.lid.global_position = den + Vector3(1.4, 0.3, 0.6)
		level.gnome.global_position = den + Vector3(-1.4, 0.3, 0.6))
	_at(460, func() -> void:
		for k in 3:
			level.cans[k].global_position = den + Vector3(-0.6 + 0.6 * k, 0.3, 1.3))
	_at(480, func() -> void: level._sleep_time = 3.0)

	# Pause and mute: switched on and off again; the game mustn't care.
	_at(500, _check_pause_and_mute)
	# The end: after the last laugh and the fade, the music has stopped.
	_at(780, _finish)


func _physics_process(_delta: float) -> void:
	_frame += 1
	if _steps.has(_frame):
		for step: Callable in _steps[_frame]:
			step.call()


func _at(frame: int, step: Callable) -> void:
	if not _steps.has(frame):
		_steps[frame] = []
	_steps[frame].append(step)


func _key(keycode: Key, pressed: bool, echo: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	ev.pressed = pressed
	ev.echo = echo
	Input.parse_input_event(ev)


func _check(name: String, expected, actual) -> void:
	var ok: bool = expected == actual
	_failed = _failed or not ok
	_results.append([name, str(expected), str(actual), "pass" if ok else "FAIL"])


func _check_pause_and_mute() -> void:
	var music := AudioServer.get_bus_index("Music")
	var sfx := AudioServer.get_bus_index("SFX")
	level.toggle_pause()
	_check("Paused: the game stops", true, get_tree().paused)
	_check("Paused: the music is muffled", true, AudioServer.is_bus_effect_enabled(music, 0))
	_check("Paused: the music is 8 dB quieter", -8.0, AudioServer.get_bus_volume_db(music))
	level.toggle_pause()
	_check("Unpaused: the game runs", false, get_tree().paused)
	_check("Unpaused: the muffling is off", false, AudioServer.is_bus_effect_enabled(music, 0))
	_check("Unpaused: the music is back to full", 0.0, AudioServer.get_bus_volume_db(music))
	level.toggle_mute("Music")
	level.toggle_mute("SFX")
	_check("M and N: both buses muted", true, AudioServer.is_bus_mute(music) and AudioServer.is_bus_mute(sfx))
	level.toggle_mute("Music")
	level.toggle_mute("SFX")
	_check("M and N again: both unmuted", false, AudioServer.is_bus_mute(music) or AudioServer.is_bus_mute(sfx))


func _finish() -> void:
	var counts: Dictionary = level.sound_counts
	_check("SFX-CHITTER: 5 quick presses + 1 held press", 6, counts.get("SFX-CHITTER", 0))
	_check("SFX-RUN: 2 runs, Shift tapped during the first", 2, counts.get("SFX-RUN", 0))
	_check("SFX-CLIMB: 2 climbs, clinging still between", 2, counts.get("SFX-CLIMB", 0))
	_check("SFX-TASK-LAUGH: 5 tasks over 4 frames", 4, counts.get("SFX-TASK-LAUGH", 0))
	_check("Every task done", true, level.tasks.all(func(t: Dictionary) -> bool: return t.done))
	_check("End: the music has stopped after its fade", false, level._music.playing)
	for path: String in ["res://assets/audio/music/forest-loop.wav", "res://assets/audio/sfx/run-loop.wav", "res://assets/audio/sfx/climb-loop.wav"]:
		var s := load(path) as AudioStreamWAV
		var frames := roundi(s.get_length() * s.mix_rate)
		_check("Loop marker over the whole file: " + path.get_file(), true,
			s.loop_mode == AudioStreamWAV.LOOP_FORWARD and s.loop_begin == 0 and absi(s.loop_end - frames) <= 1)

	print("")
	print("Sound check, %s" % Time.get_datetime_string_from_system())
	for r: Array in _results:
		print("  %-4s  %-52s expected %-6s got %s" % [r[3], r[0], r[1], r[2]])
	print("RESULT: %s" % ("all checks passed" if not _failed else "SOME CHECKS FAILED"))
	get_tree().quit(1 if _failed else 0)
