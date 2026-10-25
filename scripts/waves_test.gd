extends Node
## The automated check for the party's sound waves (sound_waves.gd): a set of strokes
## goes out on the beat and fades after its time; wherever he is (by his tree, along
## the trail, at the camp) they come at him from the speaker's side of him on the
## screen, on the edge of the screen the music comes from, or out of the speaker itself once it's on
## the screen; and with the music stopped no more come.
## Run it headless from the project folder:
##   godot --headless --path . --audio-driver Dummy -- --waves-test
## It prints a table and quits with exit code 0 if every check passes, 1 if not. With
## `--waves-shots=<folder>` in a window it saves a picture at each place.

const Campsite := preload("res://scripts/campsite.gd")
const Forest := preload("res://scripts/forest.gd")
const SoundWaves := preload("res://scripts/sound_waves.gd")

## Set by the level (main.gd).
var level: Node
var shots := ""

var _results: Array[Array] = []
var _failed := false
var _camp: Campsite
var _waves: SoundWaves
var _player: Node3D


func _ready() -> void:
	_camp = level.campsite
	_player = level.player
	if DisplayServer.get_name() == "headless":
		# Headless, the screen is 64 pixels square; what's on it is checked on a game's.
		get_tree().root.size = Vector2i(1280, 720)
	_run.call_deferred()


func _run() -> void:
	await _wait(1.0)
	_waves = _camp._waves
	_check("The party plays from the start (no title)", true, _camp.party.playing)

	# On the beat: a set every EVERY beats, each gone after LIFE.
	var first := _waves.made
	await _wait(5.22)
	var every := SoundWaves.EVERY * 60.0 / Campsite.MUSIC_BPM
	_check("On the beat: a set every %d beats (%.2f s): %d in 5.22 s, give or take one" % [SoundWaves.EVERY,
		every, roundi(5.22 / every)], true, absi(_waves.made - first - roundi(5.22 / every)) <= 1)
	_check("Each lasts %.1f s: at most %d out at once" % [SoundWaves.LIFE, ceili(SoundWaves.LIFE / every)], true,
		_waves.sets.size() <= ceili(SoundWaves.LIFE / every)
		and _waves.sets.all(func(age: float) -> bool: return age < SoundWaves.LIFE))

	# Wherever he is, they come at him from the speaker's side of him on the screen.
	for place: Array in [["by his tree", Forest.START, false], ["on the trail", Vector3(Forest.TRAIL_POINTS[3].x, 0.02,
			Forest.TRAIL_POINTS[3].y), false], ["at the camp", Vector3(Campsite.FIRE.x + 1.8, 0.02, Campsite.FIRE.y - 2.4),
			true]]:
		_player.place(place[1])
		await _wait(1.0)
		var camera := get_viewport().get_camera_3d()
		var way := _waves.route(camera)
		var speaker := camera.unproject_position(_camp.party.global_position)
		var toward := (speaker - (way.him as Vector2)).normalized()
		_check("%s (%.0f m off): from the speaker's side of him" % [place[0], _waves._away()], true,
			(-way.way as Vector2).dot(toward) > 0.95)
		_check("%s: out of the speaker itself" % place[0], place[2], way.speaker)
		if not place[2]:
			var view := get_viewport().get_visible_rect()
			var from: Vector2 = way.from
			_check("%s: on the edge of the screen the music comes from" % place[0], true,
				minf(minf(absf(from.x - view.position.x), absf(from.x - view.end.x)),
					minf(absf(from.y - view.position.y), absf(from.y - view.end.y))) < 1.0)
		await _until(func() -> bool: return _waves.sets.any(func(age: float) -> bool:
			return absf(age - SoundWaves.LIFE * 0.5) < 0.05), 3.0)
		_shot("%s_by-claude" % String(place[0]).replace(" ", "_"))

	# The music stopped: no more sets, and the last ones fade.
	_camp.party.stop()
	await _wait(0.2)
	var made := _waves.made
	await _wait(SoundWaves.LIFE + 0.5)
	_check("The music stopped: no new sets", made, _waves.made)
	_check("The music stopped: the last ones have faded", 0, _waves.sets.size())

	for music: AudioStreamPlayer in [level._music, level._sleep_music]:
		if music:
			music.stop()
	await _wait(0.3)
	_finish()


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


func _shot(name: String) -> void:
	if shots == "" or DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute(shots)
	get_viewport().get_texture().get_image().save_png(shots.path_join(name + ".png"))


func _finish() -> void:
	print("")
	print("Sound waves check, %s" % Time.get_datetime_string_from_system())
	for r: Array in _results:
		print("  %-4s  %-66s expected %-6s got %s" % [r[3], r[0], r[1], r[2]])
	print("RESULT: %s (%d checks)" % ["all checks passed" if not _failed else "SOME CHECKS FAILED", _results.size()])
	get_tree().quit(1 if _failed else 0)
