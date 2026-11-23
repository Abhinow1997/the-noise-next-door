extends Node
## The automated check for the party's sound waves (sound_waves.gd): sets of strokes go
## out on the beat in bursts (three on the first beats of every eight, since 22 Nov 2026)
## and each fades after its time; on the way (by his tree, along the
## trail) they come at him from the speaker's side of him on the screen, on the edge of
## the screen the music comes from; once he's reached the camp they keep to the speaker
## (since 11 Nov 2026), out of it a little way to each side, and none at the edge with
## it off the screen; and with the music stopped no more come.
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

	# On the beat, in bursts (since 22 Nov 2026, CHANGE-BRIEF.md "the moth guides him to the camp;
	# the waves come in bursts"): BURST sets, one on each of the first beats of every EVERY, each
	# gone after LIFE. Over one burst's period, which beat of it each set starts on.
	var first := _waves.made
	var seen := first
	var on_beats: Array[int] = []
	var started := Time.get_ticks_msec()
	var period := SoundWaves.EVERY * 60.0 / Campsite.MUSIC_BPM
	while Time.get_ticks_msec() - started < period * 1000.0:
		await get_tree().process_frame
		if _waves.made > seen:
			seen = _waves.made
			on_beats.append(posmod(floori(_camp.beat), SoundWaves.EVERY))
	var beat := 60.0 / Campsite.MUSIC_BPM
	_check("In bursts: %d sets every %d beats (%.2f s): %d in %.2f s, give or take one" % [SoundWaves.BURST,
		SoundWaves.EVERY, period, SoundWaves.BURST, period], true, absi(_waves.made - first - SoundWaves.BURST) <= 1)
	_check("Each on one of the burst's first %d beats, then quiet (on beats %s of %d)" % [SoundWaves.BURST,
		str(on_beats), SoundWaves.EVERY], true,
		not on_beats.is_empty() and on_beats.all(func(b: int) -> bool: return b < SoundWaves.BURST))
	_check("Each lasts %.1f s: at most %d out at once" % [SoundWaves.LIFE, ceili(SoundWaves.LIFE / beat)], true,
		_waves.sets.size() <= ceili(SoundWaves.LIFE / beat)
		and _waves.sets.all(func(age: float) -> bool: return age < SoundWaves.LIFE))

	# On the way, they come at him from the speaker's side of him on the screen; once he's
	# reached the camp, they keep to the speaker.
	for place: Array in [["by his tree", Forest.START, false], ["on the trail", Vector3(Forest.TRAIL_POINTS[3].x, 0.02,
			Forest.TRAIL_POINTS[3].y), false], ["at the camp", Vector3(Campsite.FIRE.x + 1.8, 0.02, Campsite.FIRE.y - 2.4),
			true]]:
		_player.place(place[1])
		await _wait(1.0)
		var camera := get_viewport().get_camera_3d()
		var way := _waves.route(camera)
		if place[2]:
			_check("%s (%.0f m off): kept to the speaker, a little way to each side, not toward him" % [place[0],
				_waves._away()], true, way.around and way.way == Vector2.RIGHT
				and is_equal_approx(way.reach, SoundWaves.AROUND * _waves._unit()))
		else:
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
		# For the picture, a set halfway through its life: up to one burst's period away.
		await _until(func() -> bool: return _waves.sets.any(func(age: float) -> bool:
			return absf(age - SoundWaves.LIFE * 0.5) < 0.05), 6.0)
		_shot("%s_by-claude" % String(place[0]).replace(" ", "_"))

	# Still in the camp, on its far side from the speaker, which is off the screen: none
	# at the edge of the screen.
	_player.place(Vector3(Campsite.FIRE.x + 7.0, 0.02, Campsite.FIRE.y + 2.5))
	await _wait(1.0)
	var far_camera := get_viewport().get_camera_3d()
	var far_speaker := far_camera.unproject_position(_camp.party.global_position)
	_check("At the camp's far side (%.0f m off), the speaker off the screen: no waves at the edge" % _waves._away(),
		"off the screen, none", "%s, %s" % ["on the screen" if get_viewport().get_visible_rect().has_point(far_speaker)
		else "off the screen", "none" if _waves.route(far_camera).is_empty() else "some"])
	_shot("camp_far_side_by-claude")

	# The music stopped: no more sets, and the last ones fade.
	_camp.party.stop()
	await _wait(0.2)
	var made := _waves.made
	await _wait(SoundWaves.LIFE + 0.5)
	_check("The music stopped: no new sets", made, _waves.made)
	_check("The music stopped: the last ones have faded", 0, _waves.sets.size())

	for music in [level._music, level._sleep_music]:
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
