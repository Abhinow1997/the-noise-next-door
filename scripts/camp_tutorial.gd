extends Node
## The tutorial at the camp. First made on 26 Oct 2026 (the game paused, Tab, the list,
## a note to sneak); remade on 7 Nov 2026 to the author's design, in rounds after they
## played each version: the dark layer and Tab; "pan around the people and the food
## quickly ... the raccoon can make a laughing noise ... spot him ... hide in a bush ...
## sneak away ... Keep the hints to the minimum words"; and then "force the user to hide
## after he's been spotted ... make the spotter ... the confused animation ... the human
## starts ... to tend to the fire, and makes one marshmallow ... keeping them on the table
## ... going back to the fire to make more ... the task should be sort of to quickly steal
## them and eat them". Their picks from Claude Code's options: "TO DO" as the list's name
## (plan_note.gd); the campers freeze while he hides; the roasting only in the tutorial;
## one eaten is enough; then the list and free play. The rest, and the few words, are
## Claude Code's.
##   1. The pan: once he can see the party (main.gd), the game slows right down (SLOW)
##      behind a dark layer (spotlight.gd) and the camera pans over the campers, the
##      marshmallows and the cooler (main.gd `camera_focus`), a word or two on each.
##   2. The laugh: back on him, he chitters, the cones come on, and the nearest camper
##      hears it and comes to look. He's held still till he's seen (or a few seconds).
##   3. Hide: the campers freeze where they are (their nodes stop), the bush is lit
##      (campsite.gd `bush`), and he has to get into it, as he has to press Tab later.
##      In it (player.gd `hiding_in`), they carry on, and lose him.
##   4. Lost: once the one who saw him is confused ("??", SEARCH), the camera's on him
##      for a moment; then a note to sneak out.
##   5. The roasting (roast_plate.gd): the camper roasts a marshmallow, takes it to a
##      plate on the table and goes back for more. The first one on the plate: the camera
##      on it, sparkling, and the raccoon hungry (thought_bubbles.gd). Then: wait till
##      he's back at the fire; now, sneak over and eat one with E. Eaten: "Yum!".
##   6. The list: a note says Tab; Tab brings up the TO DO list with Rock the party and
##      its tasks on it (camp_tasks.gd `reveal`), the game slowed; Tab again puts it away,
##      and the world's open, with no more notes.
## While it holds the game it holds the raccoon still (player.gd `input_locked`) and Esc
## doesn't pause (main.gd). It's the only game script that changes Engine.time_scale,
## and only while it holds the game: it puts it back to 1 when it lets go.
## With `intro` off (cones_test.gd and tests/cone_shader_test.gd), he arrives to the
## dark layer and Tab at once, the list picks the marshmallows (plan_note.gd), and the
## cones come on at the pick, as those checks were made for. `guide` is left from an
## earlier version and does nothing now.

signal finished

const CampPerson := preload("res://scripts/camp_person.gd")
const Campsite := preload("res://scripts/campsite.gd")
const Spotlight := preload("res://scripts/spotlight.gd")
const HideSpot := preload("res://scripts/hide_spot.gd")
const RoastPlate := preload("res://scripts/roast_plate.gd")
const S := CampPerson.State

enum Step { WAITING, INTRO, ARRIVAL, TASKS, LIST, PICKING, DONE }

## The task picked on the list without the intro.
const FIRST := "marshmallows"
## How long after he's seen the party it starts: as long as the music's task takes to be
## crossed off at the bottom (plan_note.gd STRIKE_TIME, and a moment to read it).
const START_AFTER := 1.2
## How slow the game goes while it holds it, and how long it takes to get there (real
## seconds).
const SLOW := 0.15
const SLOW_IN := 0.5
## The pan: what it shows, with its words; how long on each (real seconds); how wide
## each is lit, and how dark the rest.
const PAN := [["campers", "The campers"], ["backpack", "Marshmallows"], ["cooler", "The cooler"]]
const PAN_DWELL := 1.4
const PAN_RADIUS := 210.0
const PAN_DARK := 0.55
## Back on him, how long before he laughs (real seconds); and how long the campers have
## to see him before it goes on anyway (game seconds).
const LAUGH_AFTER := 0.7
const SEEN_WAIT := 5.0
## Hiding: how dark the rest is while the bush is lit.
const HIDE_DARK := 0.45
## Lost: how long the one who saw him has to get confused (game seconds), and how long
## at most the camera stays on him (real seconds).
const LOST_WAIT := 12.0
const LOST_SHOW := 3.0
## The first roasted marshmallow: how long the camera's on it (real seconds).
const FOOD_SHOW := 1.8
## A few words on the screen, without holding the game (real seconds).
const FLASH := 1.2

## The words. Few, as the author asked.
const ARRIVAL_LINE := "The party"
const OPEN_NOTE := "Tab: your TO DO list"
const CLOSE_NOTE := "Tab to close"
const PICK_NOTE := "Pick the marshmallows"
const HIDE_LINE := "Hide!"
const HIDE_NOTE := "Hide in the bush"
const HIDDEN_NOTE := "Wait till they look away"
const LOST_LINE := "He lost you"
const SNEAK_NOTE := "Sneak out: hold Ctrl"
const WATCH_NOTE := "Watch the camper"
const FOOD_LINE := "Roasted marshmallows"
const WAIT_NOTE := "Wait till he's at the fire"
const NOW_LINE := "Now!"
const EAT_NOTE := "Sneak over: E to eat"
const YUM_LINE := "Yum!"

## Set before it's added (main.gd): the TO DO list, the tasks, the camp, the raccoon,
## the camera, the UI layer the dark layer goes in (under the list), and the level (for
## the camera's pan and the thought bubbles).
var plan
var tasks
var campsite
var player
var camera: Camera3D
var ui_layer: Node
var level: Node
## Off in some checks (above).
var intro := true
var guide := true
## Where it's got to, and the stage within the intro.
var step := Step.WAITING
var stage := ""
var spotlight: Spotlight
## The roasting (roast_plate.gd), made when it starts.
var roast: RoastPlate

var _wait := INF
var _slow := false
var _owns_time := false
## Real seconds left of a pan stop or a moment, and of a flash.
var _left := 0.0
var _flash_left := 0.0
var _pan_i := 0
## On the camp's clock: when he laughed, and when he hid. Who heard him laugh, and who
## saw him.
var _laughed_at := -INF
var _hid_at := -INF
var _heard_by = null
var _spotter = null
var _frozen := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	spotlight = Spotlight.new()
	spotlight.camera = camera
	if ui_layer:
		ui_layer.add_child(spotlight)
		ui_layer.move_child(spotlight, 0)
	else:
		var layer := CanvasLayer.new()
		add_child(layer)
		layer.add_child(spotlight)
	if plan and plan.has_signal("picked"):
		plan.picked.connect(_pick)


## True while it holds the game: the pan and the laugh till he's seen, the moments it
## shows something, and the list.
func running() -> bool:
	return step in [Step.ARRIVAL, Step.PICKING, Step.LIST] \
		or (step == Step.INTRO and stage in ["pan", "laugh", "seen", "lost", "food"])


## He's seen the party (main.gd): it starts START_AFTER seconds of play later.
func begin() -> void:
	if step == Step.WAITING and _wait == INF:
		_wait = START_AFTER


func _process(delta: float) -> void:
	# Real time: the frame's time without the slowing (under --fixed-fps, a frame's
	# worth, so the checks come out the same on any machine).
	var real := minf(delta / Engine.time_scale if Engine.time_scale > 0.0 else delta, 0.1)
	if _slow and _owns_time and not get_tree().paused:
		Engine.time_scale = move_toward(Engine.time_scale, SLOW, real * (1.0 - SLOW) / SLOW_IN)
	if _flash_left > 0.0:
		_flash_left -= real
		if _flash_left <= 0.0 and stage not in ["pan", "hide", "food"]:
			spotlight.clear()
	match step:
		Step.WAITING:
			if _wait != INF and not get_tree().paused:
				_wait -= delta
				if _wait <= 0.0:
					if intro:
						_start_intro()
					else:
						_arrive()
		Step.INTRO:
			_intro(real)
	if player:
		player.input_locked = running()


func _input(event: InputEvent) -> void:
	var key: bool = event is InputEventKey and event.pressed and not event.echo
	var click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if not (key or click):
		return
	if key and event.keycode == KEY_TAB:
		match step:
			Step.ARRIVAL:
				_open_list(true)
				get_viewport().set_input_as_handled()
			Step.TASKS:
				_open_list(false)
				get_viewport().set_input_as_handled()
			Step.LIST:
				_close_list()
				get_viewport().set_input_as_handled()
			Step.PICKING:
				get_viewport().set_input_as_handled()
	elif step == Step.INTRO and stage in ["pan", "lost", "food"]:
		# Any key or a click goes on.
		_left = 0.0
		if stage == "pan":
			_pan_i = PAN.size()
		get_viewport().set_input_as_handled()


# --- The intro -------------------------------------------------------------------

func _start_intro() -> void:
	step = Step.INTRO
	stage = "pan"
	_pan_i = 0
	_hold(true)
	_left = 0.0


func _intro(real: float) -> void:
	match stage:
		"pan":
			_left -= real
			if _left <= 0.0:
				_pan_next()
		"laugh":
			_left -= real
			if _left <= 0.0:
				_laugh()
		"seen":
			if campsite.spotted_at > _laughed_at or campsite.clock - _laughed_at > SEEN_WAIT:
				_spotter = campsite.spotters[0] if not campsite.spotters.is_empty() else _heard_by
				_freeze(true)
				spotlight.point(campsite.bush, 140.0, HIDE_LINE, "", 0.6, HIDE_DARK)
				plan.note(HIDE_NOTE)
				stage = "hide"
		"hide":
			# Held till he's in the bush; then they carry on, and lose him.
			if player.hiding_in != null:
				_freeze(false)
				spotlight.clear()
				_hid_at = campsite.clock
				plan.note(HIDDEN_NOTE)
				stage = "hidden"
		"hidden":
			var confused: bool = _spotter != null and _spotter.state == S.SEARCH
			if confused or campsite.clock - _hid_at > LOST_WAIT:
				if confused:
					level.camera_focus = _spotter.global_position
					_flash(LOST_LINE)
				stage = "lost"
				_left = LOST_SHOW if confused else 0.0
		"lost":
			_left -= real
			if _spotter != null and _spotter.state == S.SEARCH:
				level.camera_focus = _spotter.global_position
			if _left <= 0.0 or (_spotter != null and _spotter.state != S.SEARCH):
				level.camera_focus = null
				spotlight.clear()
				_start_roasting()
		"roast":
			if player.hiding_in == null and plan.note_showing() == SNEAK_NOTE:
				plan.note(WATCH_NOTE)
		"food":
			_left -= real
			if _left <= 0.0:
				level.camera_focus = null
				spotlight.clear()
				plan.note(WAIT_NOTE)
				stage = "wait"
		"wait":
			if _roasting():
				_flash(NOW_LINE)
				plan.note(EAT_NOTE)
				stage = "steal"
		"steal":
			if not _roasting() and campsite.camper.activity() != "roast":
				plan.note(WAIT_NOTE)
				stage = "wait"


func _pan_next() -> void:
	if _pan_i < PAN.size():
		var at := _pan_point(PAN[_pan_i][0])
		level.camera_focus = at
		spotlight.point(at, PAN_RADIUS, PAN[_pan_i][1], "", 0.0, PAN_DARK)
		_left = PAN_DWELL
		_pan_i += 1
	else:
		level.camera_focus = null
		spotlight.clear()
		stage = "laugh"
		_left = LAUGH_AFTER


## He laughs: the cones come on, and the nearest calm camper hears it and comes to look
## (as anyone near enough hears a chitter: campsite.gd `noise`).
func _laugh() -> void:
	_hold(false)
	campsite.cones_on = true
	_laughed_at = campsite.clock
	player.chitter()
	_heard_by = null
	for person in campsite.people:
		if person.state == S.WORK and (_heard_by == null or person.global_position.distance_to(player.global_position)
				< _heard_by.global_position.distance_to(player.global_position)):
			_heard_by = person
	if _heard_by:
		_heard_by.hear(player.global_position)
	stage = "seen"


## The campers stop where they are, or carry on.
func _freeze(on: bool) -> void:
	_frozen = on
	for person in campsite.people:
		person.process_mode = Node.PROCESS_MODE_DISABLED if on else Node.PROCESS_MODE_INHERIT


## True while the campers are frozen (for the tests).
func frozen() -> bool:
	return _frozen


func _start_roasting() -> void:
	if roast == null:
		roast = RoastPlate.new()
		roast.camp = campsite
		campsite.add_child(roast)
		roast.served.connect(_on_served)
		roast.eaten.connect(_on_eaten)
	roast.start()
	plan.note(SNEAK_NOTE if player.hiding_in != null else WATCH_NOTE)
	stage = "roast"


## A roasted marshmallow's on the plate: the first time, the camera's on it, sparkling,
## and he's hungry.
func _on_served() -> void:
	if step != Step.INTRO or stage != "roast":
		return
	var at := roast.plate_point()
	level.camera_focus = at
	spotlight.point(at, 110.0, FOOD_LINE, "", 0.0, PAN_DARK)
	if level.get("bubbles"):
		level.bubbles.pop("hungry", FOOD_SHOW + 1.0)
	_left = FOOD_SHOW
	stage = "food"


func _on_eaten() -> void:
	if step != Step.INTRO:
		return
	_flash(YUM_LINE)
	roast.stop()
	plan.note(OPEN_NOTE)
	stage = ""
	step = Step.TASKS


## True while the camper sits roasting, calm, turned all the way back to the fire (his
## back to the plate). He counts as at it the moment he's there, while still turning
## round from the plate; in the first run, "Now!" came then, and his cone swept over the
## raccoon as he turned.
func _roasting() -> bool:
	var camper = campsite.camper
	if not (camper.activity() == "roast" and camper.at_activity() and camper.state == S.WORK):
		return false
	return absf(angle_difference(camper.rotation.y, camper.activity_facing())) < 0.2


# --- The list --------------------------------------------------------------------

## Without the intro: the dark layer at once, with the note to press Tab.
func _arrive() -> void:
	step = Step.ARRIVAL
	_hold(true)
	var fire: Vector2 = Campsite.FIRE
	spotlight.point(Vector3(fire.x - 0.4, 0.5, fire.y - 2.0), 230.0, ARRIVAL_LINE)
	plan.note(OPEN_NOTE)


## The TO DO list, the game slowed: picking the marshmallows without the intro, or just
## to read with it.
func _open_list(picking: bool) -> void:
	tasks.reveal()
	if not plan.open:
		plan.toggle()
	spotlight.clear()
	_hold(true)
	if picking:
		plan.start_picking(FIRST)
		plan.note(PICK_NOTE)
		step = Step.PICKING
	else:
		plan.note(CLOSE_NOTE)
		step = Step.LIST


func _close_list() -> void:
	if plan.open:
		plan.toggle()
	plan.note("")
	_hold(false)
	step = Step.DONE
	finished.emit()


## A task picked on the list (plan_note.gd `picked`), without the intro: only the
## marshmallows.
func _pick(id: String) -> void:
	if step != Step.PICKING or id != FIRST:
		return
	plan.stop_picking()
	if plan.open:
		plan.toggle()
	plan.note("")
	_hold(false)
	campsite.cones_on = true
	step = Step.DONE
	finished.emit()


# --- Holding the game, and what's lit ----------------------------------------------

## Slows the game, or puts it back to speed at once.
func _hold(on: bool) -> void:
	_slow = on
	if on:
		_owns_time = true
	elif _owns_time:
		Engine.time_scale = 1.0
		_owns_time = false


## A few words on the screen for a moment, without holding the game.
func _flash(line: String) -> void:
	spotlight.point(null, 0.0, line, "", 0.0, 0.0)
	_flash_left = FLASH


## Where the pan looks: the middle of the campers, or a thing.
func _pan_point(what: String) -> Vector3:
	match what:
		"campers":
			var sum := Vector3.ZERO
			for person in campsite.people:
				sum += person.global_position
			return sum / maxf(campsite.people.size(), 1.0) + Vector3.UP * 0.8
		"backpack":
			return campsite.puzzles._backpack.global_position + Vector3.UP * 0.3
		"cooler":
			return campsite.puzzles.cooler.global_position + Vector3.UP * 0.3
	return player.global_position
