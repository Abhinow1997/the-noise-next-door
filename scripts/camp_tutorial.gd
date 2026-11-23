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
## Claude Code's. Then, later on 7 Nov 2026: "when the player jumps in the tutorial dont
## let the npcs run to him just let them be confused look around and go back to their
## working", and for the marshmallows "do the same pause and black tinge block like
## during the hiding ... no need for the word hints ... just give the raccon the food
## bubble ... after steling it make him run away making the npcs altered and we need
## eating for the stole marshmellow"; their picks: alerted, the men chase him; he eats
## it once they've calmed. On 8 Nov 2026: "remove the food bubble when the raccoon
## reaches the campsite / remove the laugh as well when he reaches the camp"; their
## picks: no laugh for the music's task (main.gd), and no food thought from facing food
## till the tutorial's done (thought_bubbles.gd `food_thoughts`); the chitter stays.
##   1. The pan: once he can see the party (main.gd), the game slows right down (SLOW)
##      and the camera glides slowly round the camp, past the cooler, the campers and the
##      camper's tent to the fire (main.gd `camera_focus`), with no words (8 Nov 2026).
##   2. The laugh: back on him, he chitters, the cones come on, and the nearest camper
##      hears it and comes to look. He's held still till he's seen (or a few seconds).
##   3. Hide: the campers freeze where they are (their nodes stop), the bush is lit
##      (campsite.gd `bush`), and he has to get into it, as he has to press Tab later.
##      In it (player.gd `hiding_in`), they carry on, but whoever was after him or
##      frightened is confused where they stand (camp_person.gd `lose_him`).
##   4. Lost: the camera's on the one who saw him, confused ("?", SEARCH), for a moment;
##      then they all go back to work.
##      Since 23 Nov 2026 (the author: only the camper at the camp while he waits for them to
##      look away, the others away from it), the wait has one camper to watch. Once he's in the
##      bush, the low-poly man, the girl and the fire keeper each go off the campsite, north past
##      the table and the string lights (AWAY), as soon as they're back at their routine. For the
##      confused ones that's after their search. For the keeper it's once the log he's fetching has
##      lit the fire. From then the fire holds till the tutorial's done (camp_fire.gd `cycle`, back
##      on with `open`), so it doesn't call him back. The same day (the author: "too much waiting
##      for them to look away shoten it out"), the roasting starts as before, once they're all at
##      work and the fire's lit, while the others are still walking off. The camper keeps roasting
##      till all three are off the campsite, and only then serves the first one. As he takes it,
##      their own routines come back and they head back to the camp.
##      The same day (the author: "Make one of the maybe the girl when she's coming back bring the
##      pizza in ... a couple of boxes ... stacked ... inside the pizza"), the table has no pizza
##      while the tutorial runs. The girl comes back carrying two stacked pizza boxes
##      (pizza_boxes.gd) and goes first to the table's end by the pizza (PIZZA_AT). She bends and
##      puts them down on the table, the top one open with the pizza in it, then goes on with her
##      routine. If the tutorial's done before she's put them down, they're put down then, so the
##      open world always starts with the pizza on the table. With no intro (the checks that skip
##      it), the pizza's on the table as before.
##   5. The roasting (roast_plate.gd), once they're all back at work: the camper roasts a
##      marshmallow, turns round to put it on a plate on the log and goes back for more,
##      with a note to sneak out if he's in the bush. The first one on the plate: the
##      campers freeze as they did for the hide, the plate's lit under the dark layer and
##      the raccoon's hungry (thought_bubbles.gd), with no words, till he takes it with E.
##      Then they come to: the camper, turned to the plate, spots him, the others catch
##      the fright, and the men chase him (camp_person.gd `alert`, `chase_next`). Caught,
##      he's shooed but keeps it. Once they've lost him and are all back at work, the E
##      shows over him: holding it, he sits up and eats it. Eaten: "Yum!".
##      Since 11 Nov 2026 (the author: "after the run is initiated, don't let the user hide
##      back in the bush. Initiate a run back and just give the control back to user"),
##      "Runnn!" sets him running back toward his tree on his own for RUN_OFF (player.gd
##      `run_off`), then the keys have him; and the bush is closed to him (hide_spot.gd
##      `closed`) till they're all back at work.
##   6. The list: a note says Tab; Tab brings up the TO DO list with the camp's tasks on it
##      (camp_tasks.gd `reveal`; Rock the party, their main task, came out on 22 Nov 2026), the game slowed; Tab again puts it away,
##      and the world's open, with no more notes. Since 11 Nov 2026 the marshmallow he
##      stole counts: Steal the marshmallows is ticked off then (the author: "after the
##      tutorial is done we can cross out steal the marshmallows"). Since 23 Nov 2026 it's
##      ticked off as he eats it, the moment it's his for good, before the note to press Tab
##      (the author: "steal the marshmellows is being checked off soo late literally after the
##      tutrial completes"). It's not ticked as he takes it, because he can still be caught
##      with it then.
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
const Forest := preload("res://scripts/forest.gd")
const Spotlight := preload("res://scripts/spotlight.gd")
const HideSpot := preload("res://scripts/hide_spot.gd")
const RoastPlate := preload("res://scripts/roast_plate.gd")
const KeeperBox := preload("res://scripts/keeper_box.gd")
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
## The pan: a slow glide round the camp from him, past these, ending on the fire, with no
## words and nothing lit, and how long it takes (real seconds). The author, 8 Nov 2026:
## "remove the the word hints humans and food looks werid just do a slow pan around the
## camp" (it had stopped on the campers, the marshmallows and the cooler with a word each).
const PAN := ["cooler", "campers", "tent", "fire"]
const PAN_TIME := 8.0
## Back on him, how long before he laughs (real seconds); and how long the campers have
## to see him before it goes on anyway (game seconds).
const LAUGH_AFTER := 0.7
const SEEN_WAIT := 5.0
## Hiding: how dark the rest is while the bush is lit.
const HIDE_DARK := 0.45
## Lost: how long after he's in the bush the camera goes to the one who saw him (game
## seconds), how long that one has to get confused, and how long at most the camera
## stays on them (real seconds).
const LOST_AFTER := 0.8
const LOST_WAIT := 12.0
const LOST_SHOW := 3.0
## The wait (23 Nov 2026): where the low-poly man, the girl and the fire keeper go off the
## campsite while he waits in the bush (x, z from the camp's middle, Forest.CAMP), in that order.
## They're north, past the table and the string lights, 13.3–14.0 m out, in a little group; the
## camp reaches 12.5 m (campsite.gd CAMP_ZONE). It's about 10.5 m from where the two dance, 8 m
## from the keeper's table, and 14–16 m from the bush and the plate. The two dancers dance
## there, and the keeper stands about.
const AWAY := [Vector2(-1.4, -14.0), Vector2(-0.4, -13.3), Vector2(-2.4, -13.3)]
## The pizza (23 Nov 2026): where the girl stands to put its boxes on the table, in the table's own
## space (x, z). That's at its west end, 0.62 m from where the pizza sits (campsite.gd `_set_table`),
## facing along it (+X). How long she bends there, and how long before the end of that the boxes go
## down (s).
const PIZZA_AT := Vector2(-1.0, 0.12)
const PIZZA_BEND := 1.7
const PIZZA_PUT := 0.9
## The keeper's box (23 Nov 2026): how far from it, on the fire's side, he stands to put it down
## (m). He bends there, and at the pit, as she does at the table (PIZZA_BEND, PIZZA_PUT).
const BOX_STAND := 0.75
## The first roasted marshmallow on the plate: how wide it's lit, and how long the
## raccoon's hungry thought stays up at most (it goes as he takes it).
const PLATE_RADIUS := 110.0
const HUNGRY_HOLD := 60.0
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
const YUM_LINE := "Yum!"
## Caught taking the roasted marshmallow (8 Nov 2026, the author: "the alerting in the
## tutorial after stealing should be a bit slower like the blackout thing explaing in conicse
## 5 or less words 'u have been caught!' 'runnn!'"): held under the dark layer with the first
## line, then the second, then the chase; how long each shows (real seconds).
const CAUGHT_LINE := "You've been caught!"
const RUN_LINE := "Runnn!"
const CAUGHT_TIME := 1.4
const RUN_TIME := 1.0
## Then "Runnn!" sends him running back toward his tree on his own for this long (game
## seconds) before the keys have him again.
const RUN_OFF := 1.0

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
var _pan_t := 0.0
var _pan_from := Vector3.ZERO
## On the camp's clock: when he laughed, and when he hid. Who heard him laugh, and who
## saw him.
var _laughed_at := -INF
var _hid_at := -INF
var _heard_by = null
var _spotter = null
var _frozen := false
## After the roasted marshmallow's taken: when, and whether being seen with it is still to
## set off the caught beat ("caught").
var _taken_at := -INF
var _caught_pending := false
## The wait: whether the others are to go off the campsite now; each one sent (AWAY), with their
## own routine and where they'd got to in it, to put back as he takes the roasted marshmallow;
## and whether the fire's held for the keeper.
var _away_on := false
var _away := {}
var _fire_held := false
## Where the pizza's got to ("" on the table, hidden; "carried"; "down"), and her own routine while
## she takes it to the table. The boxes are the camp's (campsite.gd `pizza`, camp_pizza.gd).
var _pizza := ""
var _pizza_kept := {}
## The keeper's box: where it's got to ("" not brought yet, "carried", "down", then "pot" once the
## tripod and pot are up), and his own routine meanwhile.
var _box := ""
var _box_kept := {}


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
	# No pizza on the table till the girl brings it in (_bring_pizza); with no intro, it's put back.
	if campsite and campsite.pizza:
		campsite.pizza.boxes.visible = false
	# Nor his box by the fire, nor the tripod and pot over it, till the keeper brings them (_bring_box).
	if campsite and campsite.keeper_box:
		campsite.keeper_box.put_away()
	if campsite and campsite.campfire:
		campsite.campfire.set_pot_up(false)


## True while it holds the game: the pan and the laugh till he's seen, the moment it
## shows the one who lost him, and the list; and him, while he sits eating.
func running() -> bool:
	return step in [Step.ARRIVAL, Step.PICKING, Step.LIST] \
		or (step == Step.INTRO and stage in ["pan", "laugh", "seen", "lost", "caught"]) \
		or (roast != null and roast.eating())


## The developer menu (dev_menu.gd): straight to the roasting, as once they've lost him
## in the bush and gone back to work.
func dev_roast() -> void:
	campsite.cones_on = true
	campsite.campfire.start_building()
	_laughed_at = campsite.clock
	step = Step.INTRO
	stage = "calming"
	_away_on = true


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
		if _flash_left <= 0.0 and stage not in ["pan", "hide", "grab", "caught"]:
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
	_keep_pizza()
	_keep_box()
	if player:
		player.input_locked = running()
	# No food thought from facing food till it's done: none as he gets to the camp (the
	# author, 8 Nov 2026), and the plate's, which it pops itself, is the one he has.
	if level and level.get("bubbles"):
		level.bubbles.food_thoughts = not intro or step == Step.DONE


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
	elif step == Step.INTRO and stage in ["pan", "lost"]:
		# Any key or a click goes on.
		_left = 0.0
		if stage == "pan":
			_pan_t = PAN_TIME
		get_viewport().set_input_as_handled()


# --- The intro -------------------------------------------------------------------

func _start_intro() -> void:
	step = Step.INTRO
	stage = "pan"
	_pan_t = 0.0
	_pan_from = player.global_position + Vector3.UP * 0.3
	spotlight.clear()
	_hold(true)
	_left = 0.0
	# The fire's out till now; the keeper sets about building it as the camera pans.
	if campsite.campfire:
		campsite.campfire.start_building()


func _intro(real: float) -> void:
	if _away_on:
		_keep_away()
	match stage:
		"pan":
			_pan_t += real
			level.camera_focus = _pan_at(_pan_t)
			if _pan_t >= PAN_TIME:
				level.camera_focus = null
				stage = "laugh"
				_left = LAUGH_AFTER
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
			# Held till he's in the bush; then they carry on, but they've lost him:
			# confused where they stand, not coming to look.
			if player.hiding_in != null:
				_freeze(false)
				for person in campsite.people:
					person.lose_him()
				# All but the camper go off the campsite while he waits, each once they're back at
				# their routine (_keep_away): the calm ones at once.
				_away_on = true
				_keep_away()
				spotlight.clear()
				_hid_at = campsite.clock
				plan.note(HIDDEN_NOTE)
				stage = "hidden"
		"hidden":
			var confused: bool = _spotter != null and _spotter.state == S.SEARCH
			if campsite.clock - _hid_at < LOST_AFTER:
				pass
			elif confused or campsite.clock - _hid_at > LOST_WAIT:
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
				stage = "calming"
		"calming":
			# The roasting starts once they've all gone back to work, and the keeper has the
			# fire lit (he builds it from the pan on, camp_fire.gd). Since 23 Nov 2026 the others
			# are walking off the campsite by then; the first one isn't served till they're off
			# it ("roast").
			if _all_calm() and campsite.campfire.burning():
				_start_roasting()
		"caught":
			_left -= real
			if _left <= RUN_TIME and spotlight.line() == CAUGHT_LINE:
				spotlight.point(player, 150.0, RUN_LINE, "", 0.3, HIDE_DARK)
			if _left <= 0.0:
				_freeze(false)
				spotlight.clear()
				for person in campsite.people:
					person.chase_now()
				# Off he goes, back the way he came, and the bush won't have him till
				# they've given up the chase ("escape").
				campsite.bush.closed = true
				player.run_off(Forest.HOME - player.global_position, RUN_OFF)
				stage = "escape"
		"roast":
			if player.hiding_in == null and plan.note_showing() == SNEAK_NOTE:
				plan.note("")
			# The wait (23 Nov 2026): he keeps roasting the first one till the others are off the
			# campsite, so the camper's alone at the camp when it's served.
			var camper = campsite.camper
			if not _all_away() and camper.activity() == "roast" and camper._step_left < 0.5:
				camper._step_left = 0.5
		"escape":
			# Seen with it, the first time since he took it: caught.
			if _caught_pending and roast.carrying() and campsite.last_seen >= _taken_at:
				_caught()
				return
			# Once they've lost him and are all back at work, he may eat it (roast_plate.gd
			# `can_eat`); a fright from now on is an ordinary one.
			if _all_calm():
				for person in campsite.people:
					person.chase_next = false
				if campsite.bush.closed:
					campsite.bush.closed = false


## Where the pan looks `t` real seconds in: from him through PAN's places in turn, an equal
## share of PAN_TIME to each leg, eased in and out on each.
func _pan_at(t: float) -> Vector3:
	var points: Array[Vector3] = [_pan_from]
	for what: String in PAN:
		points.append(_pan_point(what))
	var leg := PAN_TIME / PAN.size()
	var i := clampi(int(t / leg), 0, PAN.size() - 1)
	var f := smoothstep(0.0, 1.0, clampf((t - i * leg) / leg, 0.0, 1.0))
	return points[i].lerp(points[i + 1], f)


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
		roast.player = player
		roast.can_eat = func() -> bool: return stage == "escape" and _all_calm()
		campsite.add_child(roast)
		roast.served.connect(_on_served)
		roast.taken.connect(_on_taken)
		roast.eaten.connect(_on_eaten)
	roast.start()
	plan.note(SNEAK_NOTE if player.hiding_in != null else "")
	stage = "roast"


## A roasted marshmallow's on the plate: the first time, as for the hide, the campers
## freeze and it's lit under the dark layer, and he's hungry. No words.
func _on_served() -> void:
	if step != Step.INTRO or stage != "roast":
		return
	_freeze(true)
	spotlight.point(roast.plate_point(), PLATE_RADIUS, "", "", 0.0, HIDE_DARK)
	if level.get("bubbles"):
		level.bubbles.pop("hungry", HUNGRY_HOLD)
	plan.note("")
	stage = "grab"


## He's taken it: they come to, and the chase is forced (the author, 8 Nov 2026: "after he
## has been caught stealing the marshmallows force the chase"): every man goes straight after
## him, no flinch first, and the girl takes fright (camp_person.gd `chase_now`).
func _on_taken() -> void:
	if step != Step.INTRO or stage != "grab":
		return
	if level.get("bubbles"):
		level.bubbles.clear("hungry")
	# They come to, and go on as they were. The caught beat waits for one of them to see him
	# with it, in their cones (the author, 8 Nov 2026: "the u been cught and run should sync
	# with the vision cones and the actions in the game"): "escape" in _intro.
	_freeze(false)
	spotlight.clear()
	# The wait's over: the others head back to the camp.
	_bring_back()
	_taken_at = campsite.clock
	_caught_pending = true
	stage = "escape"


## Seen with the stolen marshmallow: everyone freezes as they are, the one who saw him
## with his cone red, under the dark layer with "You've been caught!", then "Runnn!", then
## the chase ("caught" in _intro).
func _caught() -> void:
	_caught_pending = false
	_freeze(true)
	spotlight.point(player, 150.0, CAUGHT_LINE, "", 0.3, HIDE_DARK)
	stage = "caught"
	_left = CAUGHT_TIME + RUN_TIME


func _on_eaten() -> void:
	if step != Step.INTRO:
		return
	_flash(YUM_LINE)
	_bring_back()
	# He's stolen a marshmallow and eaten it, his for good: that task's done now, written out
	# and crossed off at the bottom over the note to press Tab (plan_note.gd), with the coin
	# (main.gd). Since 23 Nov 2026; it was at the tutorial's very end, after the list.
	tasks.done("marshmallows")
	roast.stop()
	plan.note(OPEN_NOTE)
	stage = ""
	step = Step.TASKS


# --- The wait: the others off the campsite -------------------------------------------

## The low-poly man, the girl and the fire keeper: the ones who go off the campsite, in AWAY's
## order.
func _away_people() -> Array:
	var who: Array = campsite.dancers.duplicate()
	if campsite.keeper:
		who.append(campsite.keeper)
	return who.slice(0, AWAY.size())


## Through the wait, from his getting into the bush (and from the developer menu's roasting
## start). Each one goes off the campsite once they're back at their routine (WORK): the calm
## ones at once, the confused ones after their search where they stand. The keeper goes once the
## fire's lit. The log he's fetching is his last, because the fire holds from when he's at it
## (camp_fire.gd `cycle` off: no burning down, no call for another log) till the tutorial's done
## (`open`). While it's still out and he isn't at it, it's left to call him.
func _keep_away() -> void:
	var keeper = campsite.keeper
	var fire = campsite.campfire
	if not _fire_held:
		if fire.burning():
			fire.cycle = false
			_fire_held = true
		else:
			fire.cycle = keeper == null or keeper.state != S.TEND
	for person in _away_people():
		if _away.has(person) or person.state != S.WORK:
			continue
		if person == keeper and not fire.burning():
			continue
		_send(person)


## Sends one of them off to their place in AWAY, to stay there; their own routine is kept to put
## back.
func _send(person) -> void:
	var i: int = _away_people().find(person)
	_away[person] = {"routine": person.routine.duplicate(), "step": person._step, "left": person._step_left}
	var spot: Vector2 = AWAY[i]
	# Facing the other two, in a little group.
	var others := Vector2.ZERO
	for j in AWAY.size():
		if j != i:
			others += AWAY[j] / float(AWAY.size() - 1)
	var to := others - spot
	var at := Vector3(Forest.CAMP.x + spot.x, 0.0, Forest.CAMP.y + spot.y)
	# The dancers dance on there, on the music's beat as at the party (campsite.gd keeps it); the
	# keeper stands about as he does at the table.
	var stay: Dictionary
	if person in campsite.dancers:
		stay = campsite._activity("away", at, atan2(to.x, to.y), "dance", Campsite.MUSIC_BPM / Campsite.DANCE_BPM,
			Vector2(1.0e6, 1.0e6))
	else:
		stay = campsite._activity("away", at, atan2(to.x, to.y), "idle", 1.0, Vector2(1.0e6, 1.0e6), "dance", 0.4)
	person.routine.assign([stay])
	person._step = 0
	person._step_left = 1.0e6
	person._arrived = false


## True once all three have gone and are off the campsite (campsite.gd `in_camp`).
func _all_away() -> bool:
	for person in _away_people():
		if not _away.has(person) or campsite.in_camp(person.global_position):
			return false
	return true


## As he takes the roasted marshmallow: their own routines come back, where they'd got to, and
## they head back to the camp. While the roasting's on, the keeper goes back to eating behind
## the table, as roast_plate.gd `start` has him. The fire holds on till the tutorial's done
## (`open`): it was lit with one log, and below FEED_BELOW it would call him away again.
func _bring_back() -> void:
	_away_on = false
	var girl = campsite.dancers[1] if campsite.dancers.size() > 1 else null
	var girl_was_away: bool = girl != null and _away.has(girl)
	var keeper_was_away: bool = campsite.keeper != null and _away.has(campsite.keeper)
	for person in _away:
		var kept: Dictionary = _away[person]
		person.routine.assign(kept.routine)
		person._step = kept.step
		person._step_left = kept.left
		person._arrived = false
		if person == campsite.keeper and roast != null and roast.running:
			person._step = 0
			person._step_left = 1.0e6
	_away.clear()
	# She comes back with the pizza, and he with his box, the tripod and the pot in it.
	if girl_was_away:
		_bring_pizza(girl)
	if keeper_was_away:
		_bring_box(campsite.keeper)


# --- The keeper's box: the tripod and the pot -----------------------------------------

## As he comes back from AWAY: his box held in front of him (keeper_box.gd), and two steps first in
## his routine. He puts it down a little way from the fire (KeeperBox AT), then at the pit he puts up
## the tripod and hangs the pot from it (camp_fire.gd `set_pot_up`). His own routine is kept for after.
func _bring_box(keeper) -> void:
	var box = campsite.keeper_box
	if _box != "" or box == null:
		return
	box.carry(keeper)
	_box = "carried"
	_box_kept = {"routine": keeper.routine.duplicate(), "step": keeper._step, "left": keeper._step_left}
	var at: Vector3 = KeeperBox.spot(Campsite.FIRE)
	var fire: Vector3 = campsite.campfire.global_position
	var toward: Vector3 = ((fire - at) * Vector3(1, 0, 1)).normalized()
	var stand: Vector3 = at + toward * BOX_STAND
	var by_pit: Vector3 = campsite.campfire.bucket_spot()
	var to_pit: Vector3 = fire - by_pit
	var routine: Array = [
		campsite._activity("put_box", Vector3(stand.x, 0.0, stand.z), atan2(-toward.x, -toward.z), "bend", 1.0,
			Vector2(PIZZA_BEND, PIZZA_BEND)),
		campsite._activity("set_pot", Vector3(by_pit.x, 0.0, by_pit.z), atan2(to_pit.x, to_pit.z), "bend", 1.0,
			Vector2(PIZZA_BEND, PIZZA_BEND)),
	]
	routine.append_array(_box_kept.routine)
	keeper.routine.assign(routine)
	keeper._step = 0
	keeper._step_left = PIZZA_BEND
	keeper._arrived = false


## Each frame: halfway through his bend by the spot, the box goes down; halfway through his bend at
## the pit, the tripod and pot go up. Done there, his own routine comes back where it was.
func _keep_box() -> void:
	var keeper = campsite.keeper
	if _box == "" or keeper == null:
		return
	var bending: bool = keeper.at_activity() and keeper._step_left <= PIZZA_PUT
	if _box == "carried" and keeper.activity() == "put_box" and bending:
		_box_down()
	if _box == "down" and keeper.activity() == "set_pot" and bending:
		campsite.campfire.set_pot_up(true)
		_box = "pot"
	if _box == "pot" and not _box_kept.is_empty() and keeper.activity() not in ["put_box", "set_pot"]:
		_give_back_box_routine(keeper)


func _box_down() -> void:
	campsite.keeper_box.put_down(KeeperBox.spot(Campsite.FIRE), deg_to_rad(KeeperBox.TURN))
	_box = "down"


func _give_back_box_routine(keeper) -> void:
	keeper.routine.assign(_box_kept.routine)
	keeper._step = _box_kept.step
	keeper._step_left = _box_kept.left
	keeper._arrived = false
	# While the roasting's on he eats behind the table, as roast_plate.gd `start` has him.
	if roast != null and roast.running:
		keeper._step = 0
		keeper._step_left = 1.0e6
	_box_kept = {}


## The tutorial's done: the box down and the pot up for the open world, whether or not he's got to
## them yet.
func _finish_box() -> void:
	if campsite.keeper_box == null:
		return
	if _box in ["", "carried"]:
		_box_down()
	campsite.campfire.set_pot_up(true)
	_box = "pot"
	if not _box_kept.is_empty():
		_give_back_box_routine(campsite.keeper)


# --- The pizza: the girl brings it in -------------------------------------------------

## As she comes back from AWAY: two stacked boxes in her hand with the table's pizza in the top one,
## and a step first in her routine, to the table's end (PIZZA_AT) to put them down. Her own routine,
## where it had got to, is kept for after.
func _bring_pizza(girl) -> void:
	var table: Node3D = campsite.pizza.table if campsite.pizza else null
	if _pizza != "" or table == null:
		return
	campsite.pizza.boxes.visible = true
	campsite.pizza.boxes.carry(girl)
	_pizza = "carried"
	_pizza_kept = {"routine": girl.routine.duplicate(), "step": girl._step, "left": girl._step_left}
	var at: Vector3 = table.global_transform * Vector3(PIZZA_AT.x, 0.0, PIZZA_AT.y)
	var along: Vector3 = table.global_basis.x
	var put: Dictionary = campsite._activity("bring_pizza", Vector3(at.x, 0.0, at.z), atan2(along.x, along.z), "bend", 1.0,
		Vector2(PIZZA_BEND, PIZZA_BEND))
	var routine: Array = [put]
	routine.append_array(_pizza_kept.routine)
	girl.routine.assign(routine)
	girl._step = 0
	girl._step_left = PIZZA_BEND
	girl._arrived = false


## Each frame: once she's at the table's end and halfway through bending, the boxes go down on the
## table, open. Once she's done there, her own routine comes back where it was.
func _keep_pizza() -> void:
	if _pizza == "" or campsite.dancers.size() < 2:
		return
	var girl = campsite.dancers[1]
	if _pizza == "carried" and girl.activity() == "bring_pizza" and girl.at_activity() \
			and girl._step_left <= PIZZA_PUT:
		_put_pizza_down()
	if _pizza == "down" and not _pizza_kept.is_empty() and girl.activity() != "bring_pizza":
		_give_back_routine(girl)


## The boxes on the table's cloth, the top one open with the pizza in it (camp_pizza.gd).
func _put_pizza_down() -> void:
	campsite.pizza.put_on_table()
	_pizza = "down"


func _give_back_routine(girl) -> void:
	girl.routine.assign(_pizza_kept.routine)
	girl._step = _pizza_kept.step
	girl._step_left = _pizza_kept.left
	girl._arrived = false
	_pizza_kept = {}


## The tutorial's done: the pizza's on the table for the open world. If she's still carrying it, it's
## put down there and she goes on with her routine; if she never came back with it, it's as it was.
func _finish_pizza() -> void:
	if _pizza == "carried":
		_put_pizza_down()
	if not _pizza_kept.is_empty() and campsite.dancers.size() > 1:
		_give_back_routine(campsite.dancers[1])
	if _pizza == "" and campsite.pizza:
		campsite.pizza.boxes.visible = true


## True while all of them are at work on their routines: none alarmed, none on the way
## back.
func _all_calm() -> bool:
	# Tending the fire is the keeper's routine work too (8 Nov 2026).
	return campsite.people.all(func(person) -> bool: return person.state == S.WORK or person.state == S.TEND)


# --- The list --------------------------------------------------------------------

## Without the intro: the dark layer at once, with the note to press Tab.
func _arrive() -> void:
	step = Step.ARRIVAL
	# With no intro there's nobody to bring the pizza: it's on the table, as it always was.
	if campsite.pizza and _pizza == "":
		campsite.pizza.boxes.visible = true
	# Nor to bring the box and the pot: they're by the fire and over it, as in free play.
	_finish_box()
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
	# The open world starts with the pizza on the table, whether or not she's put it there yet; and
	# with the keeper's box down and the pot up.
	_finish_pizza()
	_finish_box()
	# The open world: the fire's circle, firelight and bucket start working (camp_fire.gd).
	if campsite.campfire:
		campsite.campfire.open()
	# Steal the marshmallows was ticked off as he ate it (_on_eaten).
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
		"tent":
			return campsite.tent_pegs.tent.global_position + Vector3.UP * 0.5
		"fire":
			return campsite.campfire.global_position + Vector3.UP * 0.5
	return player.global_position
