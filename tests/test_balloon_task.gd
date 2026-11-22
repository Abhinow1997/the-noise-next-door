extends SceneTree
## Assignment 7, Step 5 (Step 3 of its plan): Pop the balloons (CHANGE-BRIEF.md, "Boundaries:
## named changes"; "The cycle spec: the balloon's float" for the balloons; "The phase table:
## the jump" for the bite; "The evidence split": the task row).
##
## In the real level (main.tscn at the developer menu's "free" point, the camp's tasks
## revealed, as tests/jump_pins.gd runs it), with the campers blind to him (campsite.gd
## `cones_on` off, as bear_bag_test.gd and tent_test.gd do) so none of them spots him and
## gives chase, but hearing as ever; driven through the game loop with real key presses
## (Input.parse_input_event), read each physics tick after the bite check. It checks:
##   - the balloons: three, red, yellow and blue, each a low-poly 3D mesh with its own tint
##     (CHANGE-BRIEF.md, "the balloons are 3D"), 0.3 m across its body, its middle 0.7 m up, just
##     outside the camp (beyond CAMP_ZONE, inside the walkways), clear of the camp's things and
##     colliders, with no collision; each AnimationPlayer playing `bob` (current_animation)
##     while it's up, not in step;
##   - the girl (CHANGE-BRIEF.md's revisions of 21 Nov 2026): her routine dance, warm, then
##     minding the balloons; from warming her hands she walks out to them and stays her drawn
##     GIRL_DANCE_TIME, then goes back to dancing; the pops below are made while she minds them;
##     seeing him there she takes fright, flees and cowers, as she always does;
##   - one authority: in props/party_balloon.gd every play() and seek() is on its own
##     AnimationPlayer; camp_balloons.gd calls neither; no other script uses the balloon;
##   - the task: on the list under Rock the party, with its hint;
##   - three jumps (F held), one under each balloon: each pops it within the bite (ticks 5-14
##     after F is seen); `pop` (animations/balloon_pop.tres) starts on that tick and plays once,
##     swelling it, and the balloon is hidden once it has played, not on the bite's
##     tick (Step 4); each pop heard by every camper within 8 m of it (HEAR_CHITTER: they
##     turn to it, camp_person.gd `_noise_at`) and by none further; the task not ticked after
##     one or two, ticked on the third;
##   - with balloons the test adds (from the same scene, given to camp_balloons.gd): one at
##     his mouth through the crouch (ticks 0-4) isn't popped, and pops on tick 5; two at his
##     mouth, one jump pops one; one in reach only as he comes down after a running jump
##     (after tick 14) isn't popped.
## A headless run draws nothing: this checks the game's state, not how the balloons or the
## jump look. The source scan can't see an indirect call.
## Run it from the project folder:
##   bash scripts/run-test.sh test_balloon_task.gd 60
## It prints PASS or FAIL per check and quits with exit code 1 if any check fails.
## Written by Claude Code on 21 Nov 2026.

signal ticked

const DevMenu := preload("res://scripts/dev_menu.gd")
const BalloonScene := preload("res://props/party_balloon.tscn")
const CampsiteScript := preload("res://scripts/campsite.gd")
const ForestScript := preload("res://scripts/forest.gd")
const CampPersonScript := preload("res://scripts/camp_person.gd")
const CampBalloonsScript := preload("res://scripts/camp_balloons.gd")
## Well out of the camp, where none of them can see him (scripts/cones_test.gd, _send_away).
const QUIET := Vector3(20.0, 0.02, 6.5)
const HEAR := 8.0
const REACH := 0.25
const COLOURS := ["red", "yellow", "blue"]
## Each a low-poly 3D balloon, tinted (CHANGE-BRIEF.md's revision of 21 Nov 2026, "the balloons
## are 3D": it replaced the sprite sheet): the tints from the camp's matte palette
## (props/party_balloon.gd), and how wide its body is (m).
const TINTS := {"red": Color("b25d57"), "yellow": Color("e2c25a"), "blue": Color("2f5d8a")}
const BODY_ACROSS := 0.3
## How far round each balloon (m, at the height of a person) nothing may collide, and how near
## her spot she must stand to have got there (camp_person.gd ARRIVE puts her on it).
const CLEAR := 0.5
const ON_SPOT := 0.35

var level: Node
var camp: Node
var player: CharacterBody3D
var balloons_node: Node3D
var girl: Node3D
## The girl's states since the last _mark_girl().
var _girl_states := {}

var _tick := 0
var _checks := 0
var _failed := 0
## Ticks since the current jump's press was seen (0 on that tick), -1 when not jumping.
var _jt := -1
var _was_jumping := false
## Every pop: {balloon, tick, jt, heard: [[name, distance, heard]], visible (on the pop's
## tick), clip (current_animation on it)}.
var _pops: Array[Dictionary] = []
var _seen_popped := {}
## For each popped balloon, after its pop tick: {swell: the largest scale its Float reached
## while still visible, starts: how often `pop` began (from its start), hidden: the tick it was
## first hidden, last: `pop`'s position last tick}.
var _after := {}


func _initialize() -> void:
	DevMenu._next = "free"
	level = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	var probe := Probe.new()
	probe.test = self
	# After the player's tick (0) and the bite check's (camp_balloons.gd, 1).
	probe.process_physics_priority = 1000
	root.add_child(probe)
	print("Pop the balloons: the real level at the developer menu's \"free\" point, %d physics ticks a second"
		% Engine.physics_ticks_per_second)
	_run()


class Probe extends Node:
	var test: Object

	func _physics_process(_delta: float) -> void:
		test.call("step")


func step() -> void:
	_tick += 1
	if player == null:
		player = level.get("player")
		camp = level.get("campsite")
		balloons_node = camp.get("balloons")
		girl = camp.get("dancers")[1]
	_girl_states[int(girl.get("state"))] = true
	var jumping: bool = player.get("jumping")
	if jumping and not _was_jumping:
		_jt = 0
	elif jumping:
		_jt += 1
	elif not jumping:
		_jt = -1
	_was_jumping = jumping
	for b: Node3D in balloons_node.get("balloons"):
		var anim := b.get_node("AnimationPlayer") as AnimationPlayer
		if b.get("popped") and not _seen_popped.has(b):
			_seen_popped[b] = true
			var heard: Array = []
			for person: Node3D in camp.get("people"):
				var d := Vector2(person.global_position.x - b.global_position.x, person.global_position.z - b.global_position.z).length()
				var at: Vector3 = person.get("_noise_at")
				heard.append([person.name, d, at.distance_to(b.global_position) < 0.01])
			_pops.append({"balloon": b, "tick": _tick, "jt": _jt, "heard": heard, "visible": b.visible,
				"clip": String(anim.current_animation)})
			_after[b] = {"swell": 1.0, "starts": 0, "hidden": -1, "last": INF, "pop_tick": _tick}
		elif _after.has(b):
			var a: Dictionary = _after[b]
			if b.visible:
				a.swell = maxf(a.swell, (b.get_node("Float") as Node3D).scale.x)
				# `pop` began again from its start: its position went back.
				if anim.assigned_animation == "pop" and anim.current_animation_position < a.last - 0.001:
					a.starts += 1
				a.last = anim.current_animation_position
			elif a.hidden < 0:
				a.hidden = _tick
	ticked.emit()


func _check(what: String, ok: bool, got: Variant = "") -> void:
	_checks += 1
	if not ok:
		_failed += 1
	print("%s  %s  (got %s)" % ["PASS" if ok else "FAIL", what, str(got)])


func _key(keycode: int, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode as Key
	ev.physical_keycode = keycode as Key
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _wait(n: int) -> void:
	for i in n:
		await ticked


func _until(cond: Callable, most: int) -> bool:
	for i in most:
		if cond.call():
			return true
		await ticked
	return cond.call()


func _real() -> Array[Node3D]:
	var out: Array[Node3D] = []
	out.assign(balloons_node.get("balloons").slice(0, 3))
	return out


## Holds F until he's down and the landing's over, then lets go.
func _jump() -> void:
	_key(KEY_F, true)
	await _until(func() -> bool: return _jt >= 0, 20)
	await _until(func() -> bool: return _jt < 0, 120)
	_key(KEY_F, false)
	await _until(func() -> bool: return not bool(player.get("model").get("jumping")), 30)
	await _wait(5)


## Puts him on the ground with his mouth (player.gd mouth_point()) under `at`.
func _under(at: Vector3) -> void:
	var off: Vector3 = player.call("mouth_point") - player.global_position
	player.call("place", Vector3(at.x - off.x, 0.02, at.z - off.z))
	await _wait(20)


func _run() -> void:
	await ticked
	camp.set("cones_on", false)
	await _wait(30)
	_structure()
	await _girl_minds_them()
	await _task()
	await _girl_scared()
	await _edges()
	print("RESULT: %s (%d checks, %d failed)" % ["FAILED" if _failed > 0 else "all checks passed", _checks, _failed])
	quit(1 if _failed > 0 else 0)


# --- The balloons, the task, one authority -------------------------------------------

func _structure() -> void:
	var real := _real()
	_check("three balloons, red, yellow and blue", real.size() == 3 and real.map(func(b) -> String: return b.get("colour")) == COLOURS,
		real.map(func(b) -> String: return b.get("colour")))
	var camp_at: Vector3 = (camp as Node3D).global_position
	var middle: Vector2 = ForestScript.CAMP
	var space := (camp as Node3D).get_world_3d().direct_space_state
	var probe := PhysicsShapeQueryParameters3D.new()
	var ball := SphereShape3D.new()
	ball.radius = CLEAR
	probe.shape = ball
	probe.exclude = [player.get_rid()]
	for b in real:
		var c: String = b.get("colour")
		# The 3D balloon (CHANGE-BRIEF.md, "the balloons are 3D"): its body a mesh in its tint,
		# 0.3 m across, with its middle on the balloon's origin, 0.7 m up.
		var body := b.get_node_or_null("Float/Body") as MeshInstance3D
		var verts := PackedVector3Array()
		var tint := Color.BLACK
		if body and body.mesh:
			var arrays := body.mesh.surface_get_arrays(0)
			verts = arrays[Mesh.ARRAY_VERTEX]
			tint = (arrays[Mesh.ARRAY_COLOR] as PackedColorArray)[0]
		_check("%s: a low-poly mesh, with its own tint" % c, body != null and verts.size() > 0 and b.find_children("*", "Sprite3D", true, false).is_empty()
			and tint.is_equal_approx(TINTS[c]), tint.to_html(false))
		var across := 0.0
		var low := INF
		var high := -INF
		for v in verts:
			across = maxf(across, Vector2(v.x, v.z).length() * 2.0)
			low = minf(low, v.y)
			high = maxf(high, v.y)
		_check("%s: 0.3 m across its body" % c, absf(across - BODY_ACROSS) < 0.005, "%.4f m" % across)
		var up: float = b.global_position.y - camp_at.y
		var mid := (low + high) * 0.5
		_check("%s: its middle 0.7 m up (the body's middle %.4f m from the balloon's origin)" % [c, mid],
			absf(up - 0.7) < 0.01 and absf(mid) < 0.01 and body.position == Vector3.ZERO, "%.3f m up" % up)
		# Just outside the camp (CHANGE-BRIEF.md, "out of the camp with the girl"): beyond
		# CAMP_ZONE from its middle, inside the walkways (campsite.gd: 6 m further), nothing
		# collidable within CLEAR of it at a person's height.
		var out := Vector2(b.global_position.x, b.global_position.z).distance_to(middle)
		_check("%s: just outside the camp, %.2f m from its middle (beyond CAMP_ZONE %.1f, inside the walkways' %.1f)"
			% [c, out, CampsiteScript.CAMP_ZONE, CampsiteScript.CAMP_ZONE + 6.0],
			out > CampsiteScript.CAMP_ZONE and out < CampsiteScript.CAMP_ZONE + 6.0, out)
		probe.transform = Transform3D(Basis(), Vector3(b.global_position.x, camp_at.y + 0.9, b.global_position.z))
		var hits := space.intersect_shape(probe, 4)
		_check("%s: clear of the camp's things and colliders (nothing within %.1f m)" % [c, CLEAR], hits.is_empty(),
			hits.map(func(h: Dictionary) -> String: return str(h.collider.name)))
		var bodies := b.find_children("*", "CollisionObject3D", true, false).size() + b.find_children("*", "CollisionShape3D", true, false).size()
		_check("%s: no collision" % c, bodies == 0, bodies)
		var anim := b.get_node("AnimationPlayer") as AnimationPlayer
		_check("%s: its AnimationPlayer plays `bob` while it's up" % c, anim.current_animation == "bob", anim.current_animation)
	var at := real.map(func(b) -> float: return (b.get_node("AnimationPlayer") as AnimationPlayer).current_animation_position)
	var apart := absf(at[0] - at[1]) > 0.1 and absf(at[1] - at[2]) > 0.1 and absf(at[0] - at[2]) > 0.1
	_check("not in step: each starts its bob at its own offset (positions %s s)" % str(at.map(func(p) -> String: return "%.3f" % p)), apart, at)

	var task: Dictionary = {}
	for t: Dictionary in camp.get("tasks").list:
		if t.id == "balloons":
			task = t
	_check("the task: Pop the balloons, under Rock the party, \"Jump and bite all three.\"",
		task.get("text") == "Pop the balloons" and task.get("parent") == "party" and task.get("hint") == "Jump and bite all three.", task)

	var files := {}
	for dir: String in ["res://scripts", "res://props"]:
		for f: String in DirAccess.get_files_at(dir):
			if f.ends_with(".gd"):
				files[dir + "/" + f] = FileAccess.get_file_as_string(dir + "/" + f)
	var calls := RegEx.create_from_string("([A-Za-z_][A-Za-z0-9_]*)\\.(play|seek)\\(")
	var off: Array = []
	var on_anim := 0
	for m in calls.search_all(files.get("res://props/party_balloon.gd", "")):
		if m.get_string(1) == "_anim":
			on_anim += 1
		else:
			off.append(m.get_string(0))
	# play("bob"), seek() and play("pop"): three.
	_check("party_balloon.gd: every play() and seek() is on its own AnimationPlayer (%d)" % on_anim, off.is_empty() and on_anim == 3, off)
	var game: String = files.get("res://scripts/camp_balloons.gd", "")
	_check("camp_balloons.gd calls no play() or seek(), and has no AnimationPlayer",
		calls.search(game) == null and not game.contains("AnimationPlayer"), "")
	var users: Array = []
	for path: String in files:
		if files[path].contains("party_balloon") and path.get_file() not in ["camp_balloons.gd", "party_balloon.gd"]:
			users.append(path)
	_check("no other game script uses the balloon", users.is_empty(), users)


## The girl's new step (CHANGE-BRIEF.md, "out of the camp with the girl" and "the girl's new step
## comes after warming her hands"): dance, warm, then out to mind the balloons for about a
## dance's length (GIRL_DANCE_TIME), then dancing again. Driven as tasks_test.gd drives the
## routines: her warming is cut short (_step_left), and she goes on by herself.
func _girl_minds_them() -> void:
	var routine: Array = girl.get("routine")
	var names: Array = routine.map(func(a: Dictionary) -> String: return a.name)
	var minding: Vector2 = ForestScript.CAMP + CampBalloonsScript.PLACE + CampBalloonsScript.MINDER
	_check("her routine: dance, warm, then mind the balloons (%s)" % " ".join(names), names == ["dance", "warm", "balloons"], names)
	if names.size() < 3:
		return
	var step: Dictionary = routine[2]
	_check("minding them: by the balloons, for about a dance's length (GIRL_DANCE_TIME %s s)" % str(step.time),
		Vector2(step.at.x, step.at.z).distance_to(minding) < 0.01 and step.time == CampsiteScript.GIRL_DANCE_TIME,
		"%s, %s" % [step.at, step.time])
	var path := NavigationServer3D.map_get_path((camp as Node3D).get_world_3d().navigation_map, routine[1].at, step.at, true)
	var reaches: bool = path.size() > 1 and Vector2(path[-1].x, path[-1].z).distance_to(minding) < ON_SPOT
	_check("the walkways reach her spot from the fire (%d points)" % path.size(), reaches, path[-1] if path.size() > 0 else "no path")

	# Out of the way and blind to him, as for the pops: from warming her hands, she walks out.
	player.call("place", QUIET)
	girl.set("_step", 1)
	girl.set("_arrived", false)
	girl.set("_step_left", 0.01)
	await _until(func() -> bool: return girl.call("activity") == "balloons", 1800)
	var drawn: float = girl.get("_step_left")
	_check("after warming her hands she sets off to mind the balloons, to stay %.1f s" % drawn,
		girl.call("activity") == "balloons" and drawn >= CampsiteScript.GIRL_DANCE_TIME.x and drawn <= CampsiteScript.GIRL_DANCE_TIME.y,
		girl.call("activity"))
	var there := await _until(func() -> bool: return girl.call("at_activity"), 3600)
	var at := Vector2(girl.global_position.x, girl.global_position.z)
	_check("she walks out to them: on her spot by the balloons, %.2f m from the camp's middle" % at.distance_to(ForestScript.CAMP),
		there and at.distance_to(minding) < ON_SPOT and at.distance_to(ForestScript.CAMP) > CampsiteScript.CAMP_ZONE,
		"%.2f m from her spot" % at.distance_to(minding))
	var arrived := _tick
	await _until(func() -> bool: return girl.call("activity") != "balloons", 3600)
	var stayed := (_tick - arrived) / 60.0
	_check("she stays about a dance's length (%.2f s, drawn from GIRL_DANCE_TIME), then goes back to dancing" % stayed,
		absf(stayed - drawn) < 0.1 and girl.call("activity") == "dance", "%.2f s, then %s" % [stayed, girl.call("activity")])

	# Back out to them for the pops, staying.
	girl.set("_step", 2)
	girl.set("_arrived", false)
	girl.set("_step_left", 400.0)
	await _until(func() -> bool: return girl.call("at_activity"), 3600)


func _task() -> void:
	var tasks = camp.get("tasks")
	var real := _real()
	for i in 3:
		var b := real[i]
		var c: String = b.get("colour")
		# Facing the camp's way, so he stands on the far side of the row from her.
		player.rotation.y = 0.0
		await _under(b.global_position)
		var before := _pops.size()
		await _jump()
		var mine := _pops.slice(before)
		_check("%s: a jump under it (F held) pops it" % c, mine.size() == 1 and mine[0].balloon == b and b.get("popped") and not b.visible,
			"%d pops, popped %s, visible %s" % [mine.size(), b.get("popped"), b.visible])
		if mine.size() == 1:
			var jt: int = mine[0].jt
			_check("%s: popped within the bite, ticks 5-14 after F is seen (on tick %d)" % [c, jt], jt >= 5 and jt <= 14, jt)
			# The pop clip: `pop` starts on the bite's tick, the balloon still showing; it plays
			# once, swelling it (the 3D balloon's: scale 1 to 1.35), and the balloon is hidden
			# when it ends.
			var a: Dictionary = _after[b]
			_check("%s: on the bite's tick, `pop` starts and the balloon is still showing" % c,
				mine[0].clip == "pop" and mine[0].visible, "%s, visible %s" % [mine[0].clip, mine[0].visible])
			_check("%s: `pop` plays once (started %d time(s)), swelling it to %.2f" % [c, a.starts, a.swell],
				a.starts == 1 and a.swell > 1.2, "%d, %.2f" % [a.starts, a.swell])
			var after: int = a.hidden - a.pop_tick
			_check("%s: hidden once `pop` has played, %d ticks after the bite (its 3/24 s is 7.5)" % [c, after],
				after >= 8 and after <= 10, after)
			var wrong: Array = []
			for h: Array in mine[0].heard:
				if (h[1] <= HEAR) != h[2]:
					wrong.append("%s at %.2f m: heard %s" % h)
			_check("%s: heard by every camper within 8 m and no one further (%s)" % [c,
				", ".join(mine[0].heard.map(func(h: Array) -> String: return "%s %.1f m %s" % [h[0], h[1], "heard" if h[2] else "not"]))],
				wrong.is_empty(), wrong)
		for other in real:
			if not other.get("popped"):
				var a := other.get_node("AnimationPlayer") as AnimationPlayer
				_check("%s still up: `bob` playing" % other.get("colour"), a.current_animation == "bob", a.current_animation)
		var want := i == 2
		_check("after %d popped: the task %s" % [i + 1, "ticked" if want else "not ticked yet"], tasks.is_done("balloons") == want,
			tasks.is_done("balloons"))
	var inside := 0
	var outside := 0
	for p: Dictionary in _pops:
		for h: Array in p.heard:
			if h[1] <= HEAR:
				inside += 1
			else:
				outside += 1
	_check("the hearing was tried both ways: campers within 8 m of a pop (%d) and further (%d)" % [inside, outside],
		inside > 0 and outside > 0, "%d, %d" % [inside, outside])


## Seeing him by the balloons, she does what she already does (camp_person.gd, unchanged): she
## takes fright, flees and cowers, and never chases. Where she flees to is the code's own
## choice (_hiding_place): behind her protector if he's within 6 m of her, else a few steps
## away from the raccoon; how far her protector is, is printed.
func _girl_scared() -> void:
	var S := CampPersonScript.State
	camp.set("cones_on", true)
	player.call("place", QUIET)
	await _until(func() -> bool: return girl.get("state") == S.WORK and girl.call("at_activity"), 2400)
	var protector: Node3D = girl.get("protector")
	var apart := Vector2(protector.global_position.x - girl.global_position.x, protector.global_position.z - girl.global_position.z).length()
	var ahead: Vector3 = girl.global_basis.z * Vector3(1, 0, 1)
	var him := girl.global_position + ahead.normalized() * 2.5
	player.call("place", Vector3(him.x, 0.02, him.z))
	_girl_states.clear()
	var from_him_before := Vector2(girl.global_position.x - him.x, girl.global_position.z - him.z).length()
	await _until(func() -> bool: return _girl_states.has(S.STARTLED), 120)
	_check("seeing him 2.5 m in front of her by the balloons: she takes fright", _girl_states.has(S.STARTLED), _girl_states.keys())
	await _until(func() -> bool: return girl.get("state") == S.COWER, 600)
	# Her clip follows her state on the process tick after.
	await _wait(5)
	var anim := girl.get("anim") as AnimationPlayer
	var from_him := Vector2(girl.global_position.x - him.x, girl.global_position.z - him.z).length()
	_check("then she flees and cowers, further from him (%.2f m, from %.2f m), as she always does" % [from_him, from_him_before],
		_girl_states.has(S.FLEE) and girl.get("state") == S.COWER and anim.current_animation == "cower" and from_him > from_him_before,
		"%s, %s" % [S.keys()[girl.get("state")], anim.current_animation])
	_check("she never chases or stands guard", not (_girl_states.has(S.CHASE) or _girl_states.has(S.GUARD)), _girl_states.keys())
	print("INFO  her protector (%s) was %.1f m from her: %s" % [protector.name, apart,
		"within the 6 m she runs to him from" if apart < 6.0 else "beyond the 6 m she runs to him from (camp_person.gd _hiding_place), so she backs off from the raccoon instead"])
	player.call("place", QUIET)
	camp.set("cones_on", false)
	await _wait(120)


# --- The bite's edges, with balloons the test adds ----------------------------------

func _extra() -> Node3D:
	var b := BalloonScene.instantiate() as Node3D
	balloons_node.add_child(b)
	balloons_node.get("balloons").append(b)
	return b


func _edges() -> void:
	# At his mouth through the crouch: not popped on ticks 0-4, popped on tick 5.
	player.call("place", QUIET)
	await _wait(40)
	var e1 := _extra()
	e1.global_position = player.call("mouth_point")
	await _wait(20)
	_check("a balloon at his mouth as he stands: not popped (no jump, no bite)", not e1.get("popped"), e1.get("popped"))
	var in_crouch: Array = []
	var popped_on := -1
	_key(KEY_F, true)
	for i in 30:
		await ticked
		if _jt >= 0 and _jt <= 4:
			in_crouch.append([_jt, e1.global_position.distance_to(player.call("mouth_point")), e1.get("popped")])
		if popped_on < 0 and e1.get("popped"):
			popped_on = _jt
	await _until(func() -> bool: return _jt < 0, 120)
	_key(KEY_F, false)
	_check("in reach through the crouch, ticks 0-4, and not popped (%s)" % ", ".join(in_crouch.map(func(r: Array) -> String: return "%d: %.3f m" % [r[0], r[1]])),
		in_crouch.size() == 5 and in_crouch.all(func(r: Array) -> bool: return r[1] <= REACH and not r[2]), in_crouch)
	_check("then popped on tick 5, the bite's first", popped_on == 5, popped_on)
	await _wait(20)

	# Two at his mouth: one jump pops one.
	player.call("place", QUIET)
	await _wait(40)
	var side: Vector3 = player.global_basis.x * 0.08
	var e2 := _extra()
	var e3 := _extra()
	e2.global_position = player.call("mouth_point") + side
	e3.global_position = player.call("mouth_point") - side
	await _jump()
	var n := int(e2.get("popped")) + int(e3.get("popped"))
	_check("two balloons at his mouth: one jump pops one", n == 1, n)
	for e in [e2, e3]:
		if not e.get("popped"):
			e.global_position = Vector3(0, -100, 0)

	# In reach only as he comes down from a running jump (after tick 14): not popped.
	player.call("place", QUIET)
	await _wait(40)
	var e4 := _extra()
	e4.global_position = Vector3(0, -100, 0)
	_key(KEY_W, true)
	_key(KEY_SHIFT, true)
	await _wait(70)
	var ground := player.global_position.y
	_key(KEY_F, true)
	await _until(func() -> bool: return _jt == 5, 20)
	# Taking off now: where he'll be as he lands, 25 ticks on (tests/jump_pins.gd), his mouth there.
	var v: Vector3 = player.velocity
	var land := player.global_position + Vector3(v.x, 0.0, v.z) * (25.0 / 60.0)
	var off: Vector3 = player.call("mouth_point") - player.global_position
	e4.global_position = Vector3(land.x, ground, land.z) + off
	var open_near := 0
	var closed_near: Array = []
	while _jt >= 0 or bool(player.get("model").get("jumping")):
		await ticked
		var d := e4.global_position.distance_to(player.call("mouth_point"))
		if player.call("bite_open") and d <= REACH:
			open_near += 1
		elif d <= REACH:
			closed_near.append(_jt)
		if _tick > 100000:
			break
	_key(KEY_F, false)
	_key(KEY_W, false)
	_key(KEY_SHIFT, false)
	_check("a running jump: the balloon out of reach on every tick of the bite", open_near == 0, open_near)
	_check("then in reach as he comes down and lands, after tick 14 (on %d ticks), and not popped" % closed_near.size(),
		closed_near.size() > 0 and not e4.get("popped"), "popped %s" % e4.get("popped"))
