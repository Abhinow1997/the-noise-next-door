extends RefCounted
## Level 1's to-do list: the campsite's tasks (GDD 7.4), which took the place of the
## prototype's (the bin, the lid, the cans, the gnome and the nap) on 23 Oct 2026, when
## the author chose "Replace with camp tasks" and the first three to build: Steal the
## marshmallows, Music off and Raid the cooler. The puzzles at the camp (campsite.gd)
## tick them off with `done(id)`; main.gd laughs, and THE PLAN (plan_note.gd) shows the
## list. No ending yet: when all of them are done, nothing more happens (the author: "No
## ending yet").
## On 24 Oct 2026, with THE PLAN, the list got a first task: following the party's music
## to the camp, which main.gd ticks off when he gets there. It's a key task, the one to
## follow now: THE PLAN keeps it at the bottom of the screen until it's done (the author:
## "if there is a specific task like investigate the music at the start when it come
## down let it linger down at the bottom").
## On 26 Oct 2026 the camp's tasks became the sub-tasks of one main task, Rock the party,
## which the list shows only once the tutorial at the camp has revealed it (main.gd,
## camp_tutorial.gd). The author: "before this there should be no taks other than
## "identify the music" and the in the rock the party main task should have sub tasks
## like steal marshmellows and all others which we have". The name is Claude Code's
## reading of that. Rock the party is done when all of its sub-tasks are.
## Since 8 Nov 2026 the TO DO page has shown no main task, just the tasks (plan_note.gd). On 22
## Nov 2026 Rock the party came out of the code as well (the author: "Rock the party remove this
## it should be just tasks", then "Remove it from code"; CHANGE-BRIEF.md's revision of that day):
## the camp's tasks are a plain list, each marked `camp`, which the tutorial reveals together
## (`revealed`). There's no main task to tick: all_done() says when every task is done.

## On 7 Nov 2026 each task got a hint, how it's done, which the TO DO list writes under
## itself while the mouse is on that task (plan_note.gd). Claude Code's words.

## A task has just been ticked off.
signal ticked(id: String)

var list: Array[Dictionary] = [
	{"id": "investigate", "text": "Investigate the music", "done": false, "key": true,
		"hint": "Follow the music's waves."},
	{"id": "marshmallows", "text": "Steal the marshmallows", "done": false, "camp": true,
		"hint": "Unzip the backpack, take it."},
	{"id": "music", "text": "Turn the music off", "done": false, "camp": true,
		"hint": "Pull the plug, get away."},
	{"id": "cooler", "text": "Raid the cooler", "done": false, "camp": true,
		"hint": "Open it, take the sausages."},
	# Added on 8 Nov 2026 (camp_tent.gd). No hint: the author, "don't give any additional
	# details on it".
	{"id": "tent", "text": "Dismantle the tent", "done": false, "camp": true, "hint": ""},
	# Added on 10 Nov 2026 (camp_bear_bag.gd).
	{"id": "bearbag", "text": "Raid the bear bag", "done": false, "camp": true,
		"hint": "Drop it, grab a treat."},
	# Added on 21 Nov 2026 (camp_balloons.gd; CHANGE-BRIEF.md, Assignment 7), as Pop the
	# balloons; Let the balloons go the same day (the brief's revision), keeping its id.
	{"id": "balloons", "text": "Let the balloons go", "done": false, "camp": true,
		"hint": "Untie them, let them fly."},
	# Added on 23 Nov 2026 (camp_pizza.gd): pull the table's cloth, the boxes drop, eat a slice.
	{"id": "pizza", "text": "Eat the pizza", "done": false, "camp": true,
		"hint": "Pull the cloth, then eat."},
	# Added on 23 Nov 2026 (camp_supplies.gd): ride in the keeper's box into the green tent, eat a cookie.
	{"id": "supplies", "text": "Raid the supply tent", "done": false, "camp": true,
		"hint": "Hide in the keeper's box."},
]
## Whether the camp's tasks are on the list yet (the tutorial reveals them).
var revealed := false


## The tasks the list shows: the first one, and the camp's once they're revealed.
func shown() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for task: Dictionary in list:
		if revealed or not task.get("camp", false):
			out.append(task)
	return out


func reveal() -> void:
	revealed = true


## Ticks task `id` off, if it isn't already.
func done(id: String) -> void:
	for task: Dictionary in list:
		if task.id == id and not task.done:
			task.done = true
			ticked.emit(id)


func is_done(id: String) -> bool:
	for task: Dictionary in list:
		if task.id == id:
			return task.done
	return false


## The first key task not yet done, or an empty one.
func key_task() -> Dictionary:
	for task: Dictionary in list:
		if task.get("key", false) and not task.done:
			return task
	return {}


func all_done() -> bool:
	return list.all(func(t: Dictionary) -> bool: return t.done)
