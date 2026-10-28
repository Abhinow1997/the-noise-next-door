extends Node
## The tutorial at the camp, asked for on 26 Oct 2026: once he's followed the music to
## the camp, the game stops and shows him what there is to do there before the campers
## can see him. The author: "yes lets how him the tasks as some sort of tutorial workflow
## prompting him to open tab" and "its a interactive tutorial style". Its steps are
## Claude Code's, as the author asked ("take liberties with the gaps that feel
## approriate"):
##   1. He reaches the camp, and the music's task is crossed off at the bottom; then the
##      game pauses, and a note at the bottom says to press Tab.
##   2. Tab brings up THE PLAN (plan_note.gd) with the camp's tasks on it now, under
##      Rock the party (camp_tasks.gd `reveal`), and the note says to sneak past them.
##   3. Tab puts the plan away, the game carries on, and the campers' cones come on
##      (campsite.gd `cones_on`): from then on they can see him.
## The game is paused while it runs, so it reads Tab itself (main.gd reads it otherwise).

signal finished

const OPEN_NOTE := "Press Tab to see THE PLAN"
const SNEAK_NOTE := "Hold Ctrl to sneak, so they don't see you. Tab to put it away"
## How long after he gets to the camp the game stops: as long as the music's task takes
## to be crossed off at the bottom (plan_note.gd STRIKE_TIME, and a moment to read it).
const START_AFTER := 1.2

## Set before it's added (main.gd).
var plan
var tasks
var campsite
## Where it's got to: 0 not started, 1 waiting for Tab to open the plan, 2 waiting for
## Tab to put it away, 3 done.
var step := 0

var _wait := INF


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## True while it has the game paused.
func running() -> bool:
	return step == 1 or step == 2


## He's at the camp (main.gd): it starts START_AFTER seconds of play later.
func begin() -> void:
	if step == 0 and _wait == INF:
		_wait = START_AFTER


func _process(delta: float) -> void:
	if step != 0 or _wait == INF or get_tree().paused:
		return
	_wait -= delta
	if _wait <= 0.0:
		step = 1
		get_tree().paused = true
		plan.process_mode = Node.PROCESS_MODE_ALWAYS
		plan.note(OPEN_NOTE)


func _input(event: InputEvent) -> void:
	if not running() or not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode != KEY_TAB:
		return
	get_viewport().set_input_as_handled()
	if step == 1:
		tasks.reveal()
		if not plan.open:
			plan.toggle()
		plan.note(SNEAK_NOTE)
		step = 2
	else:
		if plan.open:
			plan.toggle()
		plan.note("")
		step = 3
		get_tree().paused = false
		plan.process_mode = Node.PROCESS_MODE_INHERIT
		campsite.cones_on = true
		finished.emit()
