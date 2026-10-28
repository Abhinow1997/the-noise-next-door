extends Node
## The automated check for the tutorial at the camp and the campers' cones and search
## (camp_tutorial.gd, camp_person.gd, vision_cone.gd), made on 26 Oct 2026. It puts the
## raccoon in plain sight at the camp and checks:
##   - before the tutorial: no cones, nobody sees him, only the music's task on the list;
##   - the tutorial: the game pauses with a note to press Tab, Esc doesn't unpause it,
##     Tab brings up THE PLAN with Rock the party and its sub-tasks, Tab again carries on;
##   - once he's spotted: the spotter's cone red and every cone shown for the red and its
##     fade, then none; the chase and the shoo as before;
##   - once he's got away: each of them confused ("??", SEARCH) for SEARCH_TIME, then
##     walking back, their cone back BACK_AFTER seconds after they start;
##   - Rock the party ticked off once its sub-tasks are.
## Durations are measured on the camp's clock, so they're the same at any frame rate
## (run it with --fixed-fps 30, 60 and 144). Run it headless from the project folder:
##   godot --headless --path . -- --cones-test
## It prints a table and quits with exit code 0 if every check passes, 1 if not. Run it
## in a window with `--cones-shots=<folder>` as well, and it saves pictures.

const CampPerson := preload("res://scripts/camp_person.gd")
const Campsite := preload("res://scripts/campsite.gd")
const VisionCone := preload("res://scripts/vision_cone.gd")
const CampTutorial := preload("res://scripts/camp_tutorial.gd")
const S := CampPerson.State
## How far a measured time may be off: a physics tick, and a frame at 30 fps.
const SLACK := 1.0 / 60.0 + 1.0 / 30.0

## Set by the level (main.gd).
var level: Node
var shots := ""

var _t := 0.0
var _steps: Array = []
var _results: Array[Array] = []
var _failed := false
var _camp: Campsite
var _people: Array[CampPerson] = []
var _camper: CampPerson
var _player: Node3D
var _tasks
var _plan
var _tutorial: CampTutorial
## What happened, frame by frame, from the first spotting on (camp clock).
var _spot := -INF
var _all_shown_in_red := true
var _spotter_red_in_red := true
var _others_red := false
var _gone_at := INF
var _shown_while_alarmed := false
## Through the red: how far off the ground the cones were drawn at most, and how long the
## camper's was.
var _off_ground := 0.0
var _red_length := 0.0
var _search_from := {}
var _search_took := {}
var _return_at := {}
var _back_at := {}
var _seen_states := {}
var _shot_red := false
var _shot_search := false


func _ready() -> void:
	# The tutorial pauses the game: this has to go on through it.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_camp = level.campsite
	_camper = _camp.camper
	_people.assign([_camper, _camp.dancers[0], _camp.dancers[1]])
	_player = level.player
	_tasks = level.tasks
	_plan = level._plan
	_tutorial = level._tutorial

	_at(0.5, func() -> void:
		_check("Before the tutorial: no cones", "false false false", _showing())
		_check("Before the tutorial: only the music's task on the list", "investigate", _shown_ids()))
	# In plain sight of the camper, 5 m in front of him, at the camp: the music's task
	# is done, and the tutorial starts a moment later.
	_at(0.6, func() -> void: _player.place(_in_view(_camper, 5.0)))
	_at(1.5, func() -> void:
		_check("Before the tutorial: in plain sight, nobody sees him", "false false false", _seeing())
		_check("Before the tutorial: nobody takes fright", "WORK WORK WORK", _states())
		_check("At the camp: the music's task is done", true, _tasks.is_done("investigate")))
	_at(2.6, func() -> void:
		_check("Tutorial: the game pauses", true, get_tree().paused)
		_check("Tutorial: a note says to press Tab", CampTutorial.OPEN_NOTE, _plan.note_showing())
		_check("Tutorial: the plan isn't up yet", false, _plan.open)
		_shot("01_tutorial_press_tab")
		_key(KEY_ESCAPE))
	_at(2.8, func() -> void:
		_check("Tutorial: Esc doesn't unpause it", true, get_tree().paused)
		_key(KEY_TAB))
	_at(3.4, func() -> void:
		_check("Tutorial: Tab brings up the plan", true, _plan.open and _plan.up() >= 1.0)
		_check("Tutorial: the plan shows Rock the party and its tasks",
			"investigate party marshmallows music cooler", _shown_ids())
		_check("Tutorial: the note says to sneak", CampTutorial.SNEAK_NOTE, _plan.note_showing())
		_check("Tutorial: still paused while he reads", true, get_tree().paused)
		_check("Tutorial: still no cones", "false false false", _showing())
		_shot("02_tutorial_the_plan")
		_key(KEY_TAB))
	_at(3.6, func() -> void:
		_check("Tutorial done: the game carries on", false, get_tree().paused)
		_check("Tutorial done: the plan goes away", false, _plan.open)
		_check("Tutorial done: the note goes", "", _plan.note_showing())
		_check("Tutorial done: the cones are on", true, _camp.cones_on))
	# Standing there in plain sight, he's spotted at once.
	_at(4.5, func() -> void:
		_check("Spotted: the camper takes fright", true, S.STARTLED in _seen(_camper))
		_check("Spotted: the camp knows when", true, _spot > -INF))
	_at(7.0, func() -> void:
		_check("Spotted: the camper's cone red all through its red", true, _spotter_red_in_red)
		_check("Spotted: the other cones not red", false, _others_red)
		_check("Spotted: every cone shown through the red and its fade", true, _all_shown_in_red)
		_check("Spotted: every cone flat on the ground (within 8 cm)", true, _off_ground < 0.08)
		_check("Spotted: the red cone as long as when it caught him", "%.2f" % CampPerson.SIGHT, "%.2f" % _red_length)
		_check("Then every cone goes, RED_TIME + FADE_OUT after", "%.2f" % (VisionCone.RED_TIME + VisionCone.FADE_OUT),
			"%.2f" % _near(_gone_at - _spot, VisionCone.RED_TIME + VisionCone.FADE_OUT))
		_mark())
	# Lingering, he's chased and shooed, as before; then he's gone from the camp.
	_at(13.5, func() -> void:
		_check("Lingering: chased", true, S.CHASE in _seen(_camper) or S.CHASE in _seen(_people[1]))
		_check("Caught: shooed", true, S.SHOO in _seen(_camper) or S.SHOO in _seen(_people[1]))
		_check("While they're after him: no cones", false, _shown_while_alarmed)
		_send_away())
	_at(30.0, func() -> void:
		for person: CampPerson in _people:
			_check("Gone: the %s is confused (SEARCH) first" % _label(person), true, _search_took.has(person))
			_check("Gone: the %s looks about for SEARCH_TIME" % _label(person), "%.2f" % CampPerson.SEARCH_TIME,
				"%.2f" % _near(_search_took.get(person, -1.0), CampPerson.SEARCH_TIME))
		_check("While they search: still no cones", false, _shown_while_alarmed))
	_at(45.0, func() -> void:
		for person: CampPerson in _people:
			_check("Calm: the %s's cone back BACK_AFTER after starting back" % _label(person), "%.2f" % VisionCone.BACK_AFTER,
				"%.2f" % _near(_back_at.get(person, INF) - _return_at.get(person, -INF), VisionCone.BACK_AFTER))
		_check("Calm again: all three at their routines", "WORK WORK WORK", _states())
		_check("Calm again: the cones shown, and not red", "true true true / false false false",
			_showing() + " / " + " ".join(_people.map(func(p: CampPerson) -> String: return str(p.eyes.red()))))
		_shot_of(Vector3(Campsite.FIRE.x, 0.0, Campsite.FIRE.y), "05_cones_back")
		for id: String in ["marshmallows", "music"]:
			_tasks.done(id)
		_check("Two of its tasks done: Rock the party isn't", false, _tasks.is_done("party"))
		_tasks.done("cooler")
		_check("All three done: Rock the party is ticked off", true, _tasks.is_done("party")))
	_at(45.5, _finish)


func _physics_process(delta: float) -> void:
	_t += delta
	if not get_tree().paused:
		_watch()
	while not _steps.is_empty() and _t >= _steps[0][0]:
		var step: Callable = _steps.pop_front()[1]
		step.call()


## Every frame of play: what the cones and the people are doing, on the camp's clock.
func _watch() -> void:
	var now: float = _camp.clock
	for person: CampPerson in _people:
		if not _seen_states.has(person):
			_seen_states[person] = {}
		_seen_states[person][person.state] = true
	if _spot == -INF and _camp.spotted_at > -INF:
		_spot = _camp.spotted_at
	if _spot == -INF:
		return
	var until: float = _spot + VisionCone.RED_TIME + VisionCone.FADE_OUT
	if now < until - 1e-4:
		_all_shown_in_red = _all_shown_in_red and _showing() == "true true true"
		# The cone counts its red from the frame it sees him, the camp from the frame
		# he's taken for spotted: through RED_TIME, both agree.
		if now < _spot + VisionCone.RED_TIME:
			_spotter_red_in_red = _spotter_red_in_red and _camper.eyes.red()
		_red_length = maxf(_red_length, _camper.eyes.drawn_length())
		for person: CampPerson in _people:
			_others_red = _others_red or person != _camper and person.eyes.red()
			var box: AABB = person.eyes.drawn_box()
			_off_ground = maxf(_off_ground, maxf(absf(box.position.y), absf(box.end.y)))
		if not _shot_red and now > _spot + 0.5:
			_shot_red = true
			_shot("03_spotted_red")
	elif _gone_at == INF and _showing() == "false false false":
		_gone_at = now
	for person: CampPerson in _people:
		var alarmed: bool = not person.state in [S.WORK, S.RETURN, S.FIX, S.INVESTIGATE]
		if now >= until and alarmed and person.eyes.showing():
			_shown_while_alarmed = true
		if person.state == S.SEARCH and not _search_from.has(person):
			_search_from[person] = now
		if person == _camper and not _shot_search and _search_from.has(person) and now > _search_from[person] + 1.0:
			_shot_search = true
			_shot_of(_camper.global_position, "04_confused")
		if person.state == S.RETURN and _search_from.has(person) and not _return_at.has(person):
			_return_at[person] = now
			_search_took[person] = now - _search_from[person]
		if _return_at.has(person) and not _back_at.has(person) and person.eyes.showing():
			_back_at[person] = now


func _at(t: float, step: Callable) -> void:
	_steps.append([t, step])
	_steps.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])


## Well out of the camp, where none of them can see him; once he's landed from the leap
## the shoo sent him on, which would carry him on from where he's put.
func _send_away() -> void:
	if _player.is_hopping():
		_at(_t + 0.1, _send_away)
	else:
		_player.place(Vector3(20.0, 0.02, 6.5))


## Presses and lets go of `keycode`, as a player would.
func _key(keycode: Key) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = keycode
		ev.physical_keycode = keycode
		ev.pressed = pressed
		Input.parse_input_event(ev)


## Forgets the states seen so far, so the next checks see only what happens after.
func _mark() -> void:
	_seen_states.clear()


func _seen(person: CampPerson) -> Array:
	return _seen_states.get(person, {}).keys()


## `measured` if it's within SLACK of `expected`, which then prints the same; else itself.
func _near(measured: float, expected: float) -> float:
	return expected if absf(measured - expected) <= SLACK else measured


func _label(person: CampPerson) -> String:
	return ["camper", "low-poly man", "girl"][_people.find(person)]


func _states() -> String:
	return " ".join(_people.map(func(p: CampPerson) -> String: return S.keys()[p.state]))


func _showing() -> String:
	return " ".join(_people.map(func(p: CampPerson) -> String: return str(p.eyes.showing())))


func _seeing() -> String:
	return " ".join(_people.map(func(p: CampPerson) -> String: return str(p.eyes.seeing)))


func _shown_ids() -> String:
	return " ".join(_tasks.shown().map(func(t: Dictionary) -> String: return t.id))


## `metres` in front of where `person`'s activity is done, on the ground, as near
## straight ahead as they can see it with nothing in the way, and out of the dancers'
## sight while they dance (as camp_test.gd).
func _in_view(person: CampPerson, metres: float) -> Vector3:
	var space := person.get_world_3d().direct_space_state
	var at := Vector3.ZERO
	for degrees: float in [0.0, -15.0, 15.0, -30.0, 30.0, -45.0, 45.0]:
		var yaw := person.activity_facing() + deg_to_rad(degrees)
		at = person.activity_spot() + Vector3(sin(yaw), 0, cos(yaw)) * metres + Vector3(0, 0.02, 0)
		var ray := PhysicsRayQueryParameters3D.create(person.eyes.global_position, at + Vector3.UP * 0.45, 1,
			[person.get_rid(), _player.get_rid()])
		var dancers_far := _people.slice(1).all(func(d: CampPerson) -> bool:
			return _flat(d.global_position - at).length() > CampPerson.SIGHT * CampPerson.DANCE_SIGHT + 0.3)
		if dancers_far and space.intersect_ray(ray).is_empty():
			return at
	return at


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


func _shot(name: String) -> void:
	if shots == "" or DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute(shots)
	get_viewport().get_texture().get_image().save_png(shots.path_join(name + ".png"))


## In a window, a picture with `at` in the middle rather than him, when he's away from
## the camp: the camera is held there for a frame (main.gd places it every frame).
func _shot_of(at: Vector3, name: String) -> void:
	if shots == "" or DisplayServer.get_name() == "headless":
		return
	var camera: Camera3D = level.camera
	level.set_process(false)
	var depth := (_player.global_position - camera.global_position).dot(-camera.global_basis.z)
	camera.global_position = at + camera.global_basis.z * depth
	await RenderingServer.frame_post_draw
	_shot(name)
	level.set_process(true)


func _check(name: String, expected, actual) -> void:
	var ok: bool = str(expected) == str(actual)
	_failed = _failed or not ok
	_results.append([name, str(expected), str(actual), "pass" if ok else "FAIL"])


func _finish() -> void:
	print("")
	print("Tutorial and cones check, %s" % Time.get_datetime_string_from_system())
	for r: Array in _results:
		print("  %-4s  %-62s expected %-16s got %s" % [r[3], r[0], r[1], r[2]])
	print("RESULT: %s (%d checks)" % ["all checks passed" if not _failed else "SOME CHECKS FAILED", _results.size()])
	get_tree().quit(1 if _failed else 0)
