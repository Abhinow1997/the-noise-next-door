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

## A task has just been ticked off.
signal ticked(id: String)

var list: Array[Dictionary] = [
	{"id": "investigate", "text": "Investigate the music", "done": false, "key": true},
	{"id": "marshmallows", "text": "Steal the marshmallows", "done": false},
	{"id": "music", "text": "Turn the music off", "done": false},
	{"id": "cooler", "text": "Raid the cooler", "done": false},
]


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
