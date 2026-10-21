extends Node
## The automated check for the title screen (title_screen.gd, title_menu.gd) and the
## way into play: moving through the menu with the keys and the mouse, Continue passed
## over while there's no save, the Settings page's volumes reaching the buses and the
## settings file, the menu's keys leaving him asleep and the game not paused, and New
## Game gliding the camera in to the nap close-up in the same level, with no second
## scene, no picture laid over it and the lullaby playing on. Then the nap isn't counted
## as the nap task, and a move key wakes him and brings in the to-do list and the forest
## music. Run it headless from the project folder:
##   godot --headless --path . -- --title-test
## It prints a table and quits with exit code 0 if every check passes, 1 if not. The
## player's own settings file is put back as it was afterwards. Run in a window with
## `--title-shots=<folder>` as well, it saves pictures of the way in (the SHOTS lists).

const GameSettings := preload("res://scripts/game_settings.gd")
## How long the glide in may take, in seconds.
const GLIDE_LIMIT := 8.0
## After the glide, in seconds: the first look, the look once the prompt is up, the move
## key pressed and let go, and the look once he's up.
const FIRST_LOOK := 0.05
const SETTLED := 3.6
const WAKE_PRESS := 3.7
const WAKE_RELEASE := 3.9
const UP := 7.0
## The pictures: seconds after New Game while the camera glides in, then seconds after
## it has, and a name for each.
const GLIDE_SHOTS := [[0.05, "2-new-game"], [1.3, "3-gliding-in"], [2.5, "4-nearly-in"]]
const PLAY_SHOTS := [[0.1, "5-in-close"], [3.5, "6-asleep"], [4.6, "7-leaping-out"], [6.9, "8-awake"]]

## Set by the title screen.
var title: Node
var level: Node

var _menu: Control
var _frame := 0
var _steps := {}
var _results: Array[Array] = []
var _failed := false
var _saved_settings := ""
var _had_settings := false
## Seconds since New Game while the camera glides in, or -1; seconds since it's in, or -1.
var _gliding := -1.0
var _playing := -1.0
var _play_steps := []
var _glide_shots := []
var _lullaby: AudioStreamPlayer
var _lullaby_at := 0.0
var _scene: Node
var _shots := ""


func _ready() -> void:
	_menu = title.menu
	_scene = get_tree().current_scene
	_lullaby = level._sleep_music
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--title-shots="):
			_shots = arg.get_slice("=", 1)
	_glide_shots = GLIDE_SHOTS.duplicate()
	_had_settings = FileAccess.file_exists(GameSettings.PATH)
	if _had_settings:
		_saved_settings = FileAccess.get_file_as_string(GameSettings.PATH)
	# Start from full volumes in a window, whatever the player had.
	GameSettings.music = GameSettings.STEPS
	GameSettings.effects = GameSettings.STEPS
	GameSettings.fullscreen = false
	GameSettings.apply()

	_at(5, func() -> void:
		_check("Opens on New Game", "New Game", _picked())
		_check("Continue can't be picked without a save", false, _menu.can_continue)
		_check("The title is shown over the level itself", true, _scene == level))
	_at(6, _key.bind(KEY_DOWN))
	_at(8, func() -> void: _check("Down: Settings", "Settings", _picked()))
	_at(9, _key.bind(KEY_S))
	_at(11, func() -> void: _check("S: Quit", "Quit", _picked()))
	_at(12, _key.bind(KEY_DOWN))
	_at(14, func() -> void: _check("Down from Quit: round to New Game, past Continue", "New Game", _picked()))
	_at(15, _key.bind(KEY_UP))
	_at(17, func() -> void: _check("Up from New Game: round to Quit, past Continue", "Quit", _picked()))
	_at(18, _mouse.bind(2))
	_at(20, func() -> void: _check("Mouse over Settings", "Settings", _picked()))
	_at(21, _mouse.bind(0))
	_at(23, func() -> void: _check("Mouse over Continue: still Settings", "Settings", _picked()))

	_at(24, _key.bind(KEY_ENTER))
	_at(26, func() -> void: _check("Enter on Settings: the Settings page, on Music", "Music", _picked()))
	_at(27, _key.bind(KEY_LEFT))
	_at(29, func() -> void:
		_check("Left: music one step down", GameSettings.STEPS - 1, GameSettings.music)
		_check("The music bus is that much quieter", true,
			absf(_amp_db("Music") - linear_to_db(0.9)) < 0.01)
		_check("The settings file has it", GameSettings.STEPS - 1, _saved("audio", "music")))
	_at(30, _key.bind(KEY_RIGHT))
	_at(31, _key.bind(KEY_RIGHT))
	_at(33, func() -> void:
		_check("Right twice: back up to full, no further", GameSettings.STEPS, GameSettings.music)
		_check("The music bus is at full", true, absf(_amp_db("Music")) < 0.01))
	_at(34, _key.bind(KEY_DOWN))
	_at(35, _key.bind(KEY_A))
	_at(36, _key.bind(KEY_A))
	_at(38, func() -> void:
		_check("Effects two steps down", GameSettings.STEPS - 2, GameSettings.effects)
		_check("The effects bus is that much quieter", true,
			absf(_amp_db("SFX") - linear_to_db(0.8)) < 0.01))
	_at(39, _key.bind(KEY_D))
	_at(40, _key.bind(KEY_D))
	_at(41, _key.bind(KEY_DOWN))
	_at(42, _key.bind(KEY_ENTER))
	_at(44, func() -> void: _check("Enter on Full screen: on", true, GameSettings.fullscreen))
	_at(45, _key.bind(KEY_ENTER))
	_at(47, func() -> void: _check("And off again", false, GameSettings.fullscreen))
	_at(48, _key.bind(KEY_ESCAPE))
	_at(50, func() -> void:
		_check("Esc: back to the menu, on Settings", "Settings", _picked())
		_check("The menu's keys leave him asleep in the hollow", true,
			level.player.resting and level.player.is_napping())
		_check("Esc on the title doesn't pause the game", false, get_tree().paused)
		_check("The title's camera is in charge", 1.0, level.title_view)
		_check("The lullaby is playing", true, _lullaby != null and _lullaby.playing)
		_shot("1-title"))

	_at(51, _key.bind(KEY_UP))
	_at(52, func() -> void:
		_lullaby_at = _lullaby.get_playback_position() if _lullaby else 0.0
		_key(KEY_ENTER))
	_at(54, func() -> void:
		_check("New Game: the menu locks while the camera glides in", true, _menu.locked)
		_gliding = 0.0)

	_play_steps = [[FIRST_LOOK, _check_in], [SETTLED, _check_settled],
		[WAKE_PRESS, Input.action_press.bind("move_forward")],
		[WAKE_RELEASE, Input.action_release.bind("move_forward")], [UP, _check_up], [UP, _finish]]
	for shot: Array in PLAY_SHOTS:
		_play_steps.append([shot[0], _shot.bind(shot[1])])
	_play_steps.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])


func _process(delta: float) -> void:
	_frame += 1
	for step: Callable in _steps.get(_frame, []):
		step.call()
	if _playing >= 0.0:
		_playing += delta
		while not _play_steps.is_empty() and _playing >= _play_steps[0][0]:
			var step: Callable = _play_steps.pop_front()[1]
			step.call()
	elif _gliding >= 0.0:
		_gliding += delta
		while not _glide_shots.is_empty() and _gliding >= _glide_shots[0][0]:
			_shot(_glide_shots.pop_front()[1])
		if level.title == null:
			_gliding = -1.0
			_playing = 0.0
		elif _gliding > GLIDE_LIMIT:
			_check("New Game: the camera gets in", true, false)
			_finish()


## In close: still the one level, nothing laid over it, asleep with the lullaby going
## on from where it was, and the camera in the nap close-up.
func _check_in() -> void:
	var player: Node = level.player
	_check("In: still the same level, no second scene", true, get_tree().current_scene == _scene)
	_check("In: no picture laid over it", true, _overlay() == null)
	_check("In: the title has handed over", 0.0, level.title_view)
	_check("In: the camera is the nap close-up", 1.0, level._sleep_view)
	_check("In: he's still asleep in the hollow", true, player.resting and player.is_napping())
	_check("In: the lullaby is the same and still playing", true, level._sleep_music == _lullaby and _lullaby.playing)
	_check("In: it carried on, not from the start", true, _lullaby.get_playback_position() > _lullaby_at)
	_check("In: the forest loop waits, right down", true, level._music.volume_db <= -59.0)
	_check("In: no to-do list yet", 0.0, level._todo_panel.modulate.a)


## The prompt to wake him is up, and the nap he started with hasn't ticked the nap
## task off.
func _check_settled() -> void:
	_check("Settled: the prompt to wake him is up", 1.0, level._wake_prompt.modulate.a)
	_check("Settled: still asleep, still close", true, level.player.is_napping() and level._sleep_view == 1.0)
	_check("Settled: the nap he started with isn't the nap task", false, level.tasks[4].done)


## Woken by the move key: out of the hollow, the camera back out, the forest music back
## in place of the lullaby, and the to-do list up.
func _check_up() -> void:
	var player: Node = level.player
	_check("Up: out of the hollow and on the ground", true, not player.resting and player.is_on_floor())
	_check("Up: the camera is back out", 0.0, level._sleep_view)
	_check("Up: the lullaby has stopped", false, _lullaby.playing)
	_check("Up: the forest loop is back to full", true, absf(level._music.volume_db - level.MUSIC_DB) < 0.5)
	_check("Up: the to-do list is up", 1.0, level._todo_panel.modulate.a)
	_check("Up: the prompt has gone", 0.0, level._wake_prompt.modulate.a)
	_check("Up: the nap task is still to do", false, level.tasks[4].done)


## A full-screen picture laid over the game, if there is one (there shouldn't be).
func _overlay() -> Node:
	for layer in get_tree().root.find_children("*", "CanvasLayer", true, false):
		for child in layer.get_children():
			if child is TextureRect and child.visible:
				return child
	return null


func _at(frame: int, step: Callable) -> void:
	if not _steps.has(frame):
		_steps[frame] = []
	_steps[frame].append(step)


func _key(keycode: Key) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.physical_keycode = keycode
		ev.pressed = pressed
		Input.parse_input_event(ev)


## Moves the mouse over line `line` of the menu.
func _mouse(line: int) -> void:
	var ev := InputEventMouseMotion.new()
	var at := Vector2(_menu.DESIGN.x * 0.5, _menu.ITEM_CAP + line * _menu.ITEM_GAP + 12.0)
	ev.position = _menu.get_global_transform_with_canvas() * at
	Input.parse_input_event(ev)


## Saves what's on the screen as `<name>.png`, when asked for pictures and not headless.
func _shot(shot_name: String) -> void:
	if _shots == "" or DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute(_shots)
	get_viewport().get_texture().get_image().save_png(_shots.path_join(shot_name + ".png"))


func _picked() -> String:
	return _menu._page[_menu._pick]


func _amp_db(bus_name: String) -> float:
	var bus := AudioServer.get_bus_index(bus_name)
	for i in AudioServer.get_bus_effect_count(bus):
		var effect := AudioServer.get_bus_effect(bus, i)
		if effect is AudioEffectAmplify:
			return effect.volume_db
	return NAN


func _saved(section: String, key: String) -> Variant:
	var cfg := ConfigFile.new()
	cfg.load(GameSettings.PATH)
	return cfg.get_value(section, key)


func _check(name: String, expected, actual) -> void:
	var ok: bool = expected == actual
	_failed = _failed or not ok
	_results.append([name, str(expected), str(actual), "pass" if ok else "FAIL"])


func _finish() -> void:
	_gliding = -1.0
	_playing = -1.0
	# Put the player's own settings back.
	if _had_settings:
		var file := FileAccess.open(GameSettings.PATH, FileAccess.WRITE)
		file.store_string(_saved_settings)
		file.close()
	else:
		DirAccess.remove_absolute(GameSettings.PATH)
	print("")
	print("Title screen check, %s" % Time.get_datetime_string_from_system())
	for r in _results:
		print("  %-4s  %-58s expected %-10s got %s" % [r[3], r[0], r[1], r[2]])
	print("RESULT: %s" % ("all checks passed" if not _failed else "SOME CHECKS FAILED"))
	# Stop the music and give the audio thread a moment to let go of it, or the quit
	# complains that it's still in use.
	for music in level.find_children("*", "AudioStreamPlayer", true, false):
		music.stop()
	for i in 20:
		await get_tree().process_frame
	get_tree().quit(1 if _failed else 0)
