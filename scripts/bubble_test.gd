extends Node
## The automated check for the thought icons (thought_bubbles.gd), run in the demo yard
## (bubble_demo.gd). It puts the raccoon in every situation that should show an icon,
## and some that shouldn't, and checks what shows and where. Run it headless from the
## project folder:
##   godot --headless --path . --audio-driver Dummy -- --bubble-test
## It prints a table and quits with exit code 0 if every check passes, 1 if not.
## Run it in a window with `--bubble-shots=<folder>` as well, and it saves a picture
## of the yard and of each icon there.

const Scribbles := preload("res://scripts/scribbles.gd")
const Bubble := preload("res://scripts/thought_bubble.gd")
const HideSpot := preload("res://scripts/hide_spot.gd")

## Set by the level (main.gd).
var level: Node
var demo: Node
var shots := ""

var _frame := 0
var _steps := {}
var _results: Array[Array] = []
var _failed := false
var _player: Node3D
var _bubbles: Node
var _bubble: Bubble


func _ready() -> void:
	_player = level.player
	_bubbles = level.bubbles
	_bubble = _bubbles._bubble

	# The yard from further out, for its picture.
	_at(2, func() -> void:
		_quiet()
		level.zoom = 1.6
		_go(demo.spot(Vector2(-3.5, 0.6))))
	_at(55, _shot.bind("00_yard"))
	_at(56, func() -> void:
		level.zoom = 1.0
		_quiet()
		_go(_far()))
	_at(70, func() -> void:
		_expect("Nothing near: nothing over his head", "")
		_check("Nothing near: no sparkles", 0, _bubbles.glinting().size()))

	# Shiny: sparkles over loot within 5 m, once for a pile, until he picks it up or leaves.
	var pile := [demo.coins, demo.keys, demo.foil]
	_at(80, func() -> void: _go(_near_loot()))
	_at(84, func() -> void:
		var now: Array = _bubbles.glinting()
		_check("Shiny: the pile of coins, keys and foil glints once", true, now.size() == 1 and now[0] in pile)
		_expect("Shiny: nothing over his head", "")
		if now.size() == 1:
			var loot: Node3D = now[0]
			var over: Vector2 = level.camera.unproject_position(loot.global_position + Vector3.UP * _bubbles.GLINT_LIFT)
			_check("Shiny: the sparkles sit on the loot", true, _bubbles._glints[loot].anchor.distance_to(over) < 3.0))
	_at(120, _shot.bind("01_shiny"))
	_at(130, func() -> void: _mouth_to(demo.coins))
	_at(136, func() -> void: _player._grab())
	_at(140, func() -> void:
		var now: Array = _bubbles.glinting()
		_check("Shiny: coins picked up, the rest of the pile glints", true,
			now.size() == 1 and now[0] in [demo.keys, demo.foil]))
	_at(142, func() -> void: _player._drop())
	_at(146, func() -> void:
		_check("Shiny: put down again, the coins don't", false, demo.coins in _bubbles.glinting()))
	_at(150, func() -> void: _go(_far()))
	_at(156, func() -> void: _check("Shiny: none once he's well away", 0, _bubbles.glinting().size()))
	_at(160, func() -> void: _go(_near_loot()))
	_at(164, func() -> void:
		var now: Array = _bubbles.glinting()
		_check("Shiny: back again, the pile glints again (not the coins)", true,
			now.size() == 1 and now[0] in [demo.keys, demo.foil]))
	_at(170, func() -> void:
		_go(_far())
		# Found from here on, so the loot doesn't glint through the checks that follow.
		for loot: Node3D in [demo.coins, demo.keys, demo.foil]:
			loot.set_meta("found", true))

	# Hungry: facing food or a trash bin up close; a food's own picture; the level's task.
	_at(180, func() -> void: _face(demo.cooler, 1.6))
	_at(186, func() -> void:
		_expect("Hungry: facing the cooler up close", "hungry")
		_check("Hungry: the fish skeleton", "fish", _bubble.current()))
	_at(220, _shot.bind("02_hungry"))
	_at(230, func() -> void: _face(demo.cooler, 1.6, true))
	_at(236, _expect.bind("Hungry: still up just after he turns away", "hungry"))
	_at(280, _expect.bind("Hungry: gone once he's looked away", ""))
	_at(290, func() -> void:
		demo.cooler.set_meta("bubble_icon", "apple")
		_face(demo.cooler, 1.6))
	_at(296, func() -> void: _check("Hungry: a food with its own picture, the apple core", "apple", _bubble.current()))
	_at(300, func() -> void:
		demo.cooler.remove_meta("bubble_icon")
		_go(_far())
		_bubbles.clear("hungry"))
	_at(310, func() -> void: _face(level.bin, 1.2))
	_at(316, _expect.bind("Hungry: facing the trash bin", "hungry"))
	_at(320, func() -> void:
		_go(_far())
		_bubbles.clear("hungry"))
	_at(330, func() -> void: _bubbles.hungry_objective = true)
	_at(332, _expect.bind("Hungry: the level's 'find food' task starts", "hungry"))
	_at(336, func() -> void:
		_bubbles.clear("hungry")
		_bubbles._remind = 0.0)
	_at(338, _expect.bind("Hungry: the task's reminder", "hungry"))
	_at(342, func() -> void:
		_bubbles.clear("hungry")
		_face(demo.cooler, 1.0))
	_at(346, func() -> void: _check("Hungry: reaching the cooler ends the task", false, _bubbles.hungry_objective))
	_at(350, func() -> void:
		_go(_far())
		_bubbles.clear("hungry"))

	# Hiding with nobody about: nothing.
	_at(360, func() -> void:
		demo.camper.eyes.remove_from_group("watcher")
		_go(demo.bush.global_position))
	_at(366, func() -> void:
		_check("Bush: he's hidden in it", true, HideSpot.is_hidden(_player))
		_expect("Bush with nobody about: nothing", ""))
	_at(370, func() -> void:
		_go(_far())
		demo.camper.eyes.add_to_group("watcher"))

	# Alert: in the camper's sight. Hiding: into the bush while he's looking.
	_at(380, func() -> void:
		_eyes(true)
		_go(_in_view(3.0), demo.camper.global_position - _in_view(3.0)))
	_at(386, func() -> void:
		_check("Camper: he sees him", true, demo.camper.eyes.seeing)
		_expect("Alert: seen", "alert")
		_check("Alert: the red mark", "alert", _bubble.current()))
	_at(420, _shot.bind("03_alert"))
	_at(430, func() -> void: _go(demo.bush.global_position))
	_at(436, func() -> void:
		_check("Camper: he can't see him in the bush", false, demo.camper.eyes.seeing)
		_expect("Hiding: into the bush while seen", "hiding")
		_check("Hiding: the z's", "zzz", _bubble.current())
		_check("Hiding: the alert has ended", false, _bubbles._until.has("alert"))
		var top: Vector2 = level.camera.unproject_position(demo.bush.top())
		_check("Hiding: the z's rise off the top of the bush", true, _bubble.anchor.distance_to(top) < 3.0))
	_at(470, _shot.bind("04_hiding"))
	_at(526, _expect.bind("Hiding: still up after 1.5 s", "hiding"))
	_at(571, func() -> void:
		_expect("Hiding: gone after 2 s, though he's still hidden", "")
		_check("Hiding: he's still in the bush", true, HideSpot.is_hidden(_player)))
	_at(580, func() -> void:
		demo.camper.rotation.y = demo.camper.facing
		_go(_in_view(3.0), demo.camper.global_position - _in_view(3.0)))
	_at(586, _expect.bind("Alert: seen again", "alert"))
	_at(590, func() -> void: _go(_far()))
	_at(596, _expect.bind("Alert: stays up a moment after he's out of sight", "alert"))
	_at(630, _expect.bind("Alert: then it goes", ""))

	# Idea: picking up the hose near the empty bucket; putting it down fills the bucket.
	_at(640, func() -> void:
		_eyes(false)
		_mouth_to(demo.hose))
	_at(646, func() -> void: _player._grab())
	_at(648, func() -> void:
		_check("Hose: in his mouth", demo.hose, _player.held)
		_expect("Idea: the hose, near the bucket", "idea")
		_check("Idea: the bulb", "bulb", _bubble.current()))
	_at(680, _shot.bind("05_idea"))
	_at(690, func() -> void:
		var dir: Vector3 = demo.bucket.global_position - _player.global_position
		_go(demo.bucket.global_position - Vector3(dir.x, 0.0, dir.z).normalized() * 0.75, dir))
	_at(696, func() -> void:
		_bubbles.clear("idea")
		_player._drop())
	_at(750, func() -> void:
		_check("Bucket: filled by the hose", true, demo.bucket.get_meta("solved", false))
		_check("Bucket: the water shows", true, demo.bucket.water.visible)
		_expect("Idea: a puzzle solved", "idea"))

	# Frustrated: the shed door without the keys. Then the keys: an idea, and it opens.
	_at(760, func() -> void:
		_quiet()
		_go(demo.shed.at_door(), -demo.shed.global_basis.z))
	_at(766, _press.bind(true))
	_at(768, _press.bind(false))
	_at(772, func() -> void:
		_expect("Frustrated: the locked door, no keys", "frustrated")
		_check("Frustrated: the angry scribble", "scribble", _bubble.current())
		_check("Shed: still shut", false, demo.shed.opened)
		_check("Shed: E went to the door, not to picking anything up", null, _player.held))
	_at(800, _shot.bind("06_frustrated"))
	_at(810, func() -> void:
		_quiet()
		var keys: RigidBody3D = demo.keys
		keys.global_position = demo.spot(demo.SHED + Vector2(2.5, -1.5)) + Vector3(0, 0.01, 0)
		keys.linear_velocity = Vector3.ZERO
		keys.reset_physics_interpolation()
		_mouth_to(keys))
	_at(816, func() -> void: _player._grab())
	_at(818, func() -> void:
		_check("Keys: in his mouth", demo.keys, _player.held)
		_expect("Idea: the keys, near the shed", "idea"))
	_at(830, func() -> void: _go(demo.shed.at_door(), -demo.shed.global_basis.z))
	_at(834, func() -> void: _bubbles.clear("idea"))
	_at(836, _press.bind(true))
	_at(838, _press.bind(false))
	_at(880, func() -> void:
		_check("Shed: the keys open it", true, demo.shed.opened and demo.shed.get_meta("solved", false))
		_check("Shed: the keys are in the lock", demo.shed.lock, demo.keys.get_parent())
		_expect("Shed: opened, an idea and not frustrated", "idea"))

	# Frustrated: pushing against a wall and getting nowhere; once a push.
	_at(890, func() -> void:
		_quiet()
		_go(demo.shed.global_transform * Vector3(-1.15, 0.0, -0.1), demo.shed.global_basis.x)
		Input.action_press("move_right"))
	_at(980, _expect.bind("Frustrated: stuck pushing against the shed", "frustrated"))
	_at(990, func() -> void: _bubbles.clear("frustrated"))
	_at(1050, _expect.bind("Stuck: once a push, not again while he keeps pushing", ""))
	_at(1060, func() -> void: Input.action_release("move_right"))
	_at(1070, func() -> void:
		_go(_far(), Vector3.RIGHT.rotated(Vector3.UP, deg_to_rad(level.CAMERA_YAW)))
		Input.action_press("move_right"))
	_at(1160, func() -> void:
		_expect("Walking in the open: not frustrated", "")
		Input.action_release("move_right"))

	# Frustrated: the camper sees him with loot, comes and takes it back.
	_at(1170, func() -> void:
		_quiet()
		_mouth_to(demo.coins))
	_at(1176, func() -> void: _player._grab())
	_at(1178, func() -> void: _check("Coins: in his mouth", demo.coins, _player.held))
	_at(1180, func() -> void:
		_eyes(true)
		_go(_in_view(0.8), demo.camper.global_position - _in_view(0.8)))
	_at(1188, func() -> void:
		_check("Camper: took the coins back", null, _player.held)
		var home: Transform3D = demo.coins.get_meta("home")
		_check("Coins: back where they were", true, demo.coins.global_position.distance_to(home.origin) < 0.05)
		_expect("Frustrated: an NPC took his loot (over the alert)", "frustrated"))
	_at(1210, _shot.bind("07_taken_back"))
	_at(1306, _expect.bind("Alert: back once the frustration's over, still seen", "alert"))
	_at(1310, func() -> void: _go(demo.bush.global_position))
	_at(1316, _expect.bind("Hiding: from him again", "hiding"))

	# Bored: standing still as long as the bored pose takes; moving ends it.
	_at(1330, func() -> void:
		_quiet()
		# Turned half toward the camera, as in the author's mock-up of the bored raccoon.
		_go(_far(), Vector3(1, 0, 1).rotated(Vector3.UP, deg_to_rad(level.CAMERA_YAW))))
	_at(1600, _expect.bind("Bored: not yet, after 4.5 s still", ""))
	_at(1660, func() -> void:
		_expect("Bored: after 5.5 s still", "bored")
		_check("Bored: the bored face", "bored", _bubble.current())
		_check("Bored: a sigh out of his mouth", "sigh", _bubbles._sigh.current()))
	_at(1700, _shot.bind("08_bored"))
	_at(1710, func() -> void: Input.action_press("move_right"))
	_at(1740, func() -> void:
		_expect("Bored: moving ends it", "")
		_check("Bored: and the sigh", "", _bubbles._sigh.current())
		Input.action_release("move_right"))

	_at(1750, _check_drawing)
	# Stopped well before the quit, so the audio thread has let go of them.
	_at(1750, func() -> void:
		for music: AudioStreamPlayer in [level._music, level._sleep_music]:
			if music:
				music.stop())
	_at(1770, _finish)


func _physics_process(_delta: float) -> void:
	_frame += 1
	if _steps.has(_frame):
		for step: Callable in _steps[_frame]:
			step.call()


func _at(frame: int, step: Callable) -> void:
	if not _steps.has(frame):
		_steps[frame] = []
	_steps[frame].append(step)


# --- Places and moves ----------------------------------------------------------

## Out of reach of everything: no loot, food, NPC or hiding spot near.
func _far() -> Vector3:
	return demo.spot(Vector2(2.0, 4.0))


## Within 5 m of all the loot, out of the camper's reach.
func _near_loot() -> Vector3:
	return demo.spot(demo.LOOT + Vector2(3.0, -1.5))


## `distance` metres in front of the camper, on his line of sight.
func _in_view(distance: float) -> Vector3:
	var camper: Node3D = demo.camper
	return camper.post + Vector3.FORWARD.rotated(Vector3.UP, camper.facing) * distance


## Puts him at `pos`, facing `toward` if it's given. Being put somewhere isn't standing
## still, so his wait to get bored starts again.
func _go(pos: Vector3, toward := Vector3.ZERO) -> void:
	_player.model._still = 0.0
	pos.y = 0.02
	toward.y = 0.0
	if toward.length_squared() > 0.0001:
		_player.rotation.y = atan2(-toward.x, -toward.z)
	_player.velocity = Vector3.ZERO
	_player.place(pos)


## Puts him `distance` metres from `thing`, on the side toward the far spot, facing it
## (or facing away, with `away`).
func _face(thing: Node3D, distance: float, away := false) -> void:
	var from := _far() - thing.global_position
	from.y = 0.0
	var pos := thing.global_position + from.normalized() * distance
	_go(pos, (pos - thing.global_position) if away else (thing.global_position - pos))


## Puts him with his mouth over `thing`, facing right across the screen.
func _mouth_to(thing: Node3D) -> void:
	var dir := Vector3.RIGHT.rotated(Vector3.UP, deg_to_rad(level.CAMERA_YAW))
	_go(thing.global_position - dir * 0.4, dir)


## Turns the camper's eyes on (looking straight ahead from his spot) or off.
func _eyes(on: bool) -> void:
	var camper: Node3D = demo.camper
	camper.look_around = false
	camper.rotation.y = camper.facing
	camper.global_position = camper.post
	camper.reset_physics_interpolation()
	camper.eyes.set_physics_process(on)
	if not on:
		camper.eyes.seeing = false


## Nothing wanted over his head, and the camper not looking.
func _quiet() -> void:
	_eyes(false)
	_bubbles.hungry_objective = false
	for kind: String in _bubbles.KINDS:
		_bubbles.clear(kind)
	# The level's cans are shiny too; out of the way for this check.
	for can: Node in get_tree().get_nodes_in_group("can"):
		can.set_meta("found", true)


## E, as the player presses it.
func _press(down: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = "grab"
	ev.pressed = down
	Input.parse_input_event(ev)


# --- Checks ---------------------------------------------------------------------

func _check(name: String, expected, actual) -> void:
	var ok: bool = expected == actual
	_failed = _failed or not ok
	_results.append([name, str(expected), str(actual), "pass" if ok else "FAIL"])


func _expect(name: String, kind: String) -> void:
	_check(name, "none" if kind == "" else kind, "none" if _bubbles.showing() == "" else _bubbles.showing())


func _check_drawing() -> void:
	var empty: Array[String] = []
	for icon: String in ["sparkles", "fish", "apple", "alert", "zzz", "bulb", "scribble", "bored", "sigh"]:
		if Scribbles.strokes(icon, 0, 6).is_empty():
			empty.append(icon)
	_check("Every icon draws", "[]", str(empty))
	var a: Array = Scribbles.strokes("fish", 0, 0)
	var b: Array = Scribbles.strokes("fish", 1, 0)
	_check("Boil: each drawing of an icon wobbles differently", true, a[0].pts != b[0].pts)
	_check("Boil: the same drawing comes back the same", true, Scribbles.strokes("fish", 0, 0)[0].pts == a[0].pts)
	_check("Pop: starts small, overshoots, settles", true,
		Bubble.POP[0] < 0.7 and Bubble.POP.max() > 1.1 and Bubble.POP[Bubble.POP.size() - 1] == 1.0)


func _shot(name: String) -> void:
	if shots == "" or DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute(shots)
	get_viewport().get_texture().get_image().save_png(shots.path_join(name + ".png"))


func _finish() -> void:
	print("")
	print("Thought-icon check, %s" % Time.get_datetime_string_from_system())
	for r: Array in _results:
		print("  %-4s  %-62s expected %-16s got %s" % [r[3], r[0], r[1], r[2]])
	print("RESULT: %s (%d checks)" % ["all checks passed" if not _failed else "SOME CHECKS FAILED", _results.size()])
	get_tree().quit(1 if _failed else 0)
