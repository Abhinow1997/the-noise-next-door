extends Node
## The tutorial at the camp. First made on 26 Oct 2026 (the game paused, Tab, the list,
## a note to sneak); remade on 7 Nov 2026 to the author's design, in two goes the same
## day. The first: "the game should slow down ... like a black layer over the game ...
## click tab ... hover over it ... select maybe one task as a tutorial". The second, after
## playing it ("Still it feels a little bit choppy ... it's just too many words"): "pan
## around the people and the food quickly, and maybe the raccoon can make a laughing
## noise. And one of the person maybe can just spot him ... you can quickly hide in a
## bush ... he's looking a little away from the bush, and now you can ask the user to
## sneak away ... Keep the hints to the minimum words." Their picks from Claude Code's
## options: the marshmallows as the task walked through, "TO DO" as the list's name
## (plan_note.gd), a spotlight at each step. The rest, and the few words, are Claude
## Code's.
##   1. The pan: once he can see the party (main.gd), the game slows right down (SLOW)
##      behind a dark layer (spotlight.gd) and the camera pans over the campers, the
##      marshmallows and the cooler (main.gd `camera_focus`), a word or two on each.
##   2. The laugh: back on him, he chitters, and the nearest camper hears it and comes to
##      look; the cones come on. He's held still till he's seen (or a few seconds).
##   3. Seen: a beat with the bush lit (campsite.gd `bush`), "Seen! Hide!". Then a note:
##      hide in the bush; hidden, wait till they look away; then sneak out with Ctrl.
##      Seen again, it's back to hiding. Out of sight, far enough from the bush, and
##      nobody after him: "Out of sight".
##   4. The list: a note says Tab; Tab brings up the TO DO list with Rock the party and
##      its tasks on it (camp_tasks.gd `reveal`), hovering shows how, and the
##      marshmallows are marked to start with; a click or Enter picks them.
##   5. The guide: each step a beat, the game slowed with that step's thing lit and a
##      few words, that goes on by itself (BEAT) or with any key; then a note while he
##      does it: wait till the camper roasts, sneak up and hold E, grab the bag, take it
##      home, done. Caught and the bag taken back, it goes back to waiting.
##   6. Then the world's open: everything plays as before, with no more notes.
## While a beat holds the game it holds the raccoon still (player.gd `input_locked`) and
## Esc doesn't pause (main.gd). It's the only game script that changes Engine.time_scale,
## and only while it holds the game: it puts it back to 1 when it lets go.
## The checks that go through it turn parts off: cones_test.gd and
## tests/cone_shader_test.gd turn `intro` and `guide` off (he arrives to the dark layer
## and Tab at once, and the cones come on at the pick); tutorial_test.gd plays it all.

signal finished

const CampPerson := preload("res://scripts/camp_person.gd")
const Campsite := preload("res://scripts/campsite.gd")
const Spotlight := preload("res://scripts/spotlight.gd")
const HideSpot := preload("res://scripts/hide_spot.gd")
const Forest := preload("res://scripts/forest.gd")
const S := CampPerson.State

enum Step { WAITING, INTRO, ARRIVAL, TASKS, PICKING, GUIDE, DONE }

## The task walked through.
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
## to see him before the tutorial goes on anyway (game seconds).
const LAUGH_AFTER := 0.7
const SEEN_WAIT := 5.0
## How long a beat holds the game (real seconds), and a word shown without holding it.
const BEAT := 1.5
const FLASH := 1.2
## Out of sight: how far from the bush, and how long unseen.
const ESCAPE := 5.0
const UNSEEN := 1.0

## The words. Few, as the author asked.
const ARRIVAL_LINE := "The party"
const OPEN_NOTE := "Tab: your TO DO list"
const PICK_NOTE := "Pick the marshmallows"
const SEEN_LINE := "Seen! Hide!"
const HEARD_LINE := "Hide!"
const HIDE_NOTE := "Hide in the bush"
const HIDDEN_NOTE := "Wait till they look away"
const SNEAK_NOTE := "Sneak out: hold Ctrl"
const AGAIN_NOTE := "Seen! Hide again"
const ESCAPED_LINE := "Out of sight"
const RETRY_NOTE := "Caught! Wait till he roasts"
## The guide's steps: what's lit (see _target), how wide, how high above it, the words
## on the beat, and the note while he does it ("" for none).
const STEPS := {
	"routine": ["camper", 150.0, 1.0, "Wait till he roasts", "Wait till he roasts"],
	"sneak": ["backpack", 110.0, 0.3, "Now! Sneak up, hold E", "Sneak up, hold E"],
	"grab": ["bag", 100.0, 0.1, "Grab it: E", "Grab the bag: E"],
	"home": ["home", 120.0, 0.0, "Take it home", "Take it home"],
	"done": ["player", 140.0, 0.4, "Nice!", ""],
}
## The states in which a camper is after him or looking for the noise.
const ALARMED := [S.STARTLED, S.GUARD, S.CHASE, S.SHOO, S.TAKE, S.INVESTIGATE]

## Set before it's added (main.gd): the TO DO list, the tasks, the camp, the raccoon,
## the camera, the UI layer the dark layer goes in (under the list), and the level (for
## the camera's pan).
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
## Where it's got to, the task picked, and the step within the intro or the guide.
var step := Step.WAITING
var task := ""
var stage := ""
var spotlight: Spotlight

var _wait := INF
var _slow := false
var _owns_time := false
## Real seconds left of a pan stop, a beat or a flash.
var _left := 0.0
var _flash_left := 0.0
## True while a beat holds the game.
var _holding := false
var _pan_i := 0
## On the camp's clock: when he laughed, and when he last hid.
var _laughed_at := -INF
var _hid_at := -INF


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


## True while it holds the game: the pan and the laugh till he's seen, a beat, and from
## the dark layer at arriving until the pick.
func running() -> bool:
	return _holding or step == Step.ARRIVAL or step == Step.PICKING \
		or (step == Step.INTRO and stage in ["pan", "laugh", "seen"])


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
		if _flash_left <= 0.0 and not _holding:
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
		Step.GUIDE:
			_guide(real)
	if player:
		player.input_locked = running()


func _input(event: InputEvent) -> void:
	var key: bool = event is InputEventKey and event.pressed and not event.echo
	var click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if not (key or click):
		return
	if key and event.keycode == KEY_TAB and step in [Step.ARRIVAL, Step.TASKS]:
		_open_list()
		get_viewport().set_input_as_handled()
	elif key and event.keycode == KEY_TAB and step == Step.PICKING:
		get_viewport().set_input_as_handled()
	elif _holding or (step == Step.INTRO and stage == "pan"):
		# Any key or a click goes on: a beat ends, and the pan is skipped.
		_left = 0.0
		if stage == "pan":
			_pan_i = PAN.size()
		get_viewport().set_input_as_handled()


# --- The intro: the pan, the laugh, seen, hide and sneak away ----------------------

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
			if campsite.spotted_at > _laughed_at:
				_seen_beat(SEEN_LINE)
			elif campsite.clock - _laughed_at > SEEN_WAIT:
				_seen_beat(HEARD_LINE)
		"seen_beat":
			_left -= real
			if _left <= 0.0:
				_let_go()
				plan.note(HIDE_NOTE)
				stage = "hiding"
		"hiding":
			if HideSpot.is_hidden(player):
				_hid_at = campsite.clock
				plan.note(HIDDEN_NOTE)
				stage = "hidden"
			elif _escaped() and player.global_position.distance_to(campsite.bush.global_position) > ESCAPE * 2.0:
				# Got clean away without the bush: that'll do too.
				_flash(ESCAPED_LINE)
				plan.note(OPEN_NOTE)
				step = Step.TASKS
		"hidden", "sneak":
			if campsite.spotted_at > _hid_at:
				plan.note(AGAIN_NOTE)
				stage = "hiding"
			elif stage == "hidden" and _looking_away():
				plan.note(SNEAK_NOTE)
				stage = "sneak"
			elif _escaped():
				_flash(ESCAPED_LINE)
				plan.note(OPEN_NOTE)
				step = Step.TASKS


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
	var nearest = null
	for person in campsite.people:
		if person.state == S.WORK and (nearest == null or person.global_position.distance_to(player.global_position)
				< nearest.global_position.distance_to(player.global_position)):
			nearest = person
	if nearest:
		nearest.hear(player.global_position)
	stage = "seen"


func _seen_beat(line: String) -> void:
	stage = "seen_beat"
	spotlight.point(campsite.bush, 120.0, line, "", 0.6)
	_hold(true)
	_holding = true
	_left = BEAT


## True once nobody's after him or looking for the noise.
func _looking_away() -> bool:
	return campsite.people.all(func(p) -> bool: return not p.state in ALARMED)


## True once he's out of the bush, well away from it, nobody's seen him lately, and
## nobody's after him.
func _escaped() -> bool:
	return not HideSpot.is_hidden(player) \
		and player.global_position.distance_to(campsite.bush.global_position) >= ESCAPE \
		and campsite.clock - campsite.last_seen > UNSEEN and _looking_away()


# --- The list and the pick -------------------------------------------------------

## Without the intro: the dark layer at once, with the note to press Tab.
func _arrive() -> void:
	step = Step.ARRIVAL
	_hold(true)
	var fire: Vector2 = Campsite.FIRE
	spotlight.point(Vector3(fire.x - 0.4, 0.5, fire.y - 2.0), 230.0, ARRIVAL_LINE)
	plan.note(OPEN_NOTE)


func _open_list() -> void:
	tasks.reveal()
	if not plan.open:
		plan.toggle()
	plan.start_picking(FIRST)
	plan.note(PICK_NOTE)
	spotlight.clear()
	_hold(true)
	step = Step.PICKING


## A task picked on the list (plan_note.gd `picked`): only the marshmallows start it.
func _pick(id: String) -> void:
	if step != Step.PICKING or id != FIRST:
		return
	task = id
	plan.stop_picking()
	if plan.open:
		plan.toggle()
	plan.note("")
	_hold(false)
	campsite.cones_on = true
	if guide:
		step = Step.GUIDE
		_show("sneak" if _roasting() else "routine")
	else:
		step = Step.DONE
		finished.emit()


# --- The guide -------------------------------------------------------------------

func _show(id: String) -> void:
	stage = id
	var s: Array = STEPS[id]
	spotlight.point(_target(s[0]), s[1], s[3], "", s[2])
	plan.note("")
	_hold(true)
	_holding = true
	_left = BEAT


## A beat over: back to play, with the step's note.
func _carry_on() -> void:
	_let_go()
	match stage:
		"routine":
			stage = "wait"
			plan.note(STEPS.routine[4])
		"done":
			plan.note("")
			step = Step.DONE
			finished.emit()
		_:
			plan.note(STEPS[stage][4])


## Each frame of the guide: a beat runs out, or he's done this step and it's the next.
func _guide(real: float) -> void:
	if _holding:
		_left -= real
		if _left <= 0.0:
			_carry_on()
		return
	var puzzles = campsite.puzzles
	if tasks.is_done(FIRST):
		_show("done")
		return
	match stage:
		"wait":
			if _roasting():
				_show("sneak")
		"sneak":
			if puzzles._unzipped:
				_show("grab")
			elif not _roasting():
				stage = "wait"
				plan.note(STEPS.routine[4])
		"grab":
			if player.held == puzzles.bag:
				_show("home")
			elif not puzzles._unzipped:
				_retry()
		"home":
			if player.held != puzzles.bag and not puzzles._unzipped:
				_retry()


## Caught with the bag, it's gone back in the backpack: wait for him to roast again.
func _retry() -> void:
	stage = "wait"
	plan.note(RETRY_NOTE)


## True while the camper sits roasting, calm, his back to the backpack.
func _roasting() -> bool:
	var camper = campsite.camper
	return camper.activity() == "roast" and camper.at_activity() and camper.state == S.WORK


# --- Holding the game, and what's lit ----------------------------------------------

## Slows the game, or puts it back to speed at once.
func _hold(on: bool) -> void:
	_slow = on
	if on:
		_owns_time = true
	elif _owns_time:
		Engine.time_scale = 1.0
		_owns_time = false


## A beat's over: the dark layer goes and the game's back to speed.
func _let_go() -> void:
	_holding = false
	spotlight.clear()
	_hold(false)


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


## What a guide step lights: a node, or his home (a point off the screen, lit at its edge).
func _target(what: String):
	match what:
		"camper":
			return campsite.camper
		"backpack":
			return campsite.puzzles._backpack
		"bag":
			return campsite.puzzles.bag
		"home":
			return Forest.HOME
		"player":
			return player
	return null
