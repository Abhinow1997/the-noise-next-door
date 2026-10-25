extends Node
## The automated check for THE PLAN (plan_note.gd): Tab brings the page up and puts it
## away, V has the camera panel now, the key task waits at the bottom until it's done,
## a task done comes up crossed off at the bottom and goes, and the page crosses off
## what's been done. Run it headless from the project folder:
##   godot --headless --path . --audio-driver Dummy -- --plan-test
## It prints a table and quits with exit code 0 if every check passes, 1 if not. With
## `--plan-shots=<folder>` in a window it saves a picture at each stage.

const Forest := preload("res://scripts/forest.gd")
const Campsite := preload("res://scripts/campsite.gd")
const PlanNote := preload("res://scripts/plan_note.gd")
## Where he's put at the camp's edge, on the side of his tree.
const AT_CAMP := Vector3(Forest.CAMP.x - Campsite.CAMP_ZONE + 1.5, 0.02, Forest.CAMP.y)
## The time a done task's scrap takes from coming up to having gone.
const SCRAP_LIFE := PlanNote.STRIKE_WAIT + PlanNote.STRIKE_TIME + PlanNote.HOLD + PlanNote.SCRAP_MOVE

## Set by the level (main.gd).
var level: Node
var shots := ""

var _results: Array[Array] = []
var _failed := false
var _plan: PlanNote


func _ready() -> void:
	_plan = level._plan
	_run.call_deferred()


func _run() -> void:
	await _wait(0.6)
	_check("Start: the page is put away", 0.0, _plan.up())
	_check("Start: the key task waits at the bottom", "investigate", _plan.key_showing())
	_check("Start: no line of controls along the bottom", false, "_hint" in level)
	_shot("1-key-task")

	_tab()
	await _wait(PlanNote.OPEN_TIME + 0.3)
	_check("Tab: the page is up", 1.0, _plan.up())
	_check("Tab: the camera panel stays shut", false, level._tuner.visible)
	_check("Tab: the scraps at the bottom make way", 0.0, _plan._scraps[0].modulate.a)
	_shot("2-the-plan")
	_tab()
	await _wait(PlanNote.OPEN_TIME + 0.1)
	_check("Tab again: the page is away", 0.0, _plan.up())
	_check("Tab again: the key task is back at the bottom", 1.0, _plan._scraps[0].modulate.a)
	_key(KEY_V)
	await _wait(0.1)
	_check("V: the camera panel opens", true, level._tuner.visible)
	_key(KEY_V)
	await _wait(0.1)
	_check("V again: the camera panel shuts", false, level._tuner.visible)

	# A task done comes up crossed off above the key task, then goes.
	level.tasks.done("marshmallows")
	await _wait(0.1)
	_check("Done: its scrap comes up above the key task's", "investigate (key), marshmallows", _scraps())
	await _wait(PlanNote.STRIKE_WAIT + PlanNote.STRIKE_TIME + 0.4)
	_check("Done: it's crossed off", "investigate (key), marshmallows (crossed off)", _scraps())
	_shot("3-done-at-the-bottom")
	await _wait(SCRAP_LIFE)
	_check("Done: its scrap has gone, the key task's stays", "investigate (key)", _scraps())

	# At the camp, the music's been followed: the key task's scrap is crossed off, then goes.
	level.player.place(AT_CAMP)
	await _wait(0.2)
	_check("At the camp: following the music is done", true, level.tasks.is_done("investigate"))
	await _wait(PlanNote.STRIKE_TIME + 0.4)
	_check("At the camp: the key task is crossed off where it is", "investigate (key) (crossed off)", _scraps())
	_shot("4-key-task-done")
	await _wait(PlanNote.HOLD + PlanNote.SCRAP_MOVE + 0.3)
	_check("At the camp: then it goes, with no key task left", "", _scraps())
	_check("At the camp: no key task left", "", _plan.key_showing())

	# The page crosses off what was done while it was away, as it comes up; and a task
	# done while it's up is crossed off there and then.
	level.player.place(Forest.HOME + Vector3(1.0, 0.02, 1.2))
	_tab()
	await _wait(PlanNote.OPEN_TIME + 0.05)
	_check("Up again: the two done are being crossed off", "investigate marshmallows",
		" ".join(_plan._struck.keys()))
	level.tasks.done("music")
	await _wait(0.05)
	_check("Up: a task done now is crossed off on the page", true, _plan._struck.has("music"))
	await _wait(PlanNote.STRIKE_TIME * 3.0 + 0.5)
	_shot("5-the-plan-crossed-off")
	_tab()
	await _wait(0.5)
	_finish()


## The scraps at the bottom, each as its task, and whether it's the key task's and
## crossed off.
func _scraps() -> String:
	return ", ".join(_plan.scraps().map(func(s: Array) -> String:
		return s[0] + (" (key)" if s[1] else "") + (" (crossed off)" if s[2] else "")))


func _tab() -> void:
	_key(KEY_TAB)


func _key(keycode: Key) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = keycode
		ev.physical_keycode = keycode
		ev.pressed = pressed
		Input.parse_input_event(ev)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout


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
	print("THE PLAN check, %s" % Time.get_datetime_string_from_system())
	for r: Array in _results:
		print("  %-4s  %-58s expected %-24s got %s" % [r[3], r[0], r[1], r[2]])
	print("RESULT: %s (%d checks)" % ["all checks passed" if not _failed else "SOME CHECKS FAILED", _results.size()])
	get_tree().quit(1 if _failed else 0)
