extends SceneTree
## Assignment 7: the balloons task, "Let the balloons go" (CHANGE-BRIEF.md, "Boundaries: named
## changes"; "The evidence split": the task row; the revisions of 21 Nov 2026, last "the balloon
## task is 'Let the balloons go'").
##
## In the real level (main.tscn at the developer menu's "free" point, the camp's tasks
## revealed, as tests/jump_pins.gd runs it), with the campers blind to him (campsite.gd
## `cones_on` off, as bear_bag_test.gd and tent_test.gd do) except where a check needs them to
## see him; driven through the game loop with real key presses (Input.parse_input_event), read
## each physics tick after the game's. It checks:
##   - before her first visit: no chair, no balloons, and nothing to untie (E at the knot's place
##     does nothing);
##   - the task: on the camp's list (Rock the party came out on 22 Nov 2026), "Let the balloons
##     go", with its hint;
##   - one authority: in props/party_balloon.gd every play() and seek() is on its own
##     AnimationPlayer; camp_balloons.gd calls play() only on the bunch's player, and nothing
##     else plays or seeks; no other game script uses the balloon or the bunch;
##   - the girl blows them up: her routine dance, warm, then the balloons; from warming her
##     hands she walks out; there she sets out the chair, then blows up red, yellow and blue one
##     by one (each shown as a small bud, playing `inflate`, INFLATE apart and GAP between),
##     tying each to the chair; with the third tied she goes back to dancing;
##   - then the balloons: tinted low-poly meshes, 0.3 m across, their middles about 0.7 m up,
##     just outside the camp, clear of colliders, no collision, each playing `bob`, not in step;
##     their strings all end on one knot, low on the chair;
##   - later visits: she minds them, staying her drawn GIRL_DANCE_TIME; seeing him there she takes
##     fright, flees and cowers, as she always does;
##   - E at the knot (his grab) frees them, with her minding them: the bunch plays `float_away`,
##     rises 8 m and is gone after 5 s, and the task ticks; she sees it, takes fright facing the
##     chair and calls the others: each one who was calm or wondering comes to a spot round the
##     chair confused ("?", SEARCH) and searches there (the `confused` clip), then goes back to
##     their routine; so does she, once she's calmed down;
##   - in a second level, E at the knot with her dancing in the camp: nobody reacts while they
##     float away; when her step takes her back to the empty chair, she takes fright and calls
##     the others, who come and search there.
## A headless run draws nothing: this checks the game's state, not how the balloons look. The
## source scan can't see an indirect call.
## Run it from the project folder:
##   bash scripts/run-test.sh test_balloon_task.gd 60 300
## It prints PASS or FAIL per check and quits with exit code 1 if any check fails.
## Written by Claude Code on 21 Nov 2026.

signal ticked

const DevMenu := preload("res://scripts/dev_menu.gd")
const CampsiteScript := preload("res://scripts/campsite.gd")
const ForestScript := preload("res://scripts/forest.gd")
const CampPersonScript := preload("res://scripts/camp_person.gd")
const CampBalloonsScript := preload("res://scripts/camp_balloons.gd")
## Well out of the camp, where none of them can see him (scripts/cones_test.gd, _send_away).
const QUIET := Vector3(20.0, 0.02, 6.5)
const COLOURS := ["red", "yellow", "blue"]
## Each a low-poly 3D balloon, tinted (props/party_balloon.gd), and how wide its body is (m).
const TINTS := {"red": Color("b25d57"), "yellow": Color("e2c25a"), "blue": Color("2f5d8a")}
const BODY_ACROSS := 0.3
## Its string's end, in the balloon's own space (party_balloon.gd TAIL).
const STRING_END := Vector3(0.01, -0.68, 0.0)
## How far round each balloon (m, at the height of a person) nothing may collide, and how near
## her spot she must stand to have got there (camp_person.gd ARRIVE puts her on it).
const CLEAR := 0.5
const ON_SPOT := 0.35
## Searching "round the chair": within this of it (camp_person.gd CALL_NEAR, and its fallback
## 1.4 times that, and a little).
const ROUND := 2.2

var level: Node
var camp: Node
var player: CharacterBody3D
var balloons_node: Node3D
var girl: Node3D
## The girl's states since the last clear.
var _girl_states := {}
## Each person's state changes since the last _mark(): [[tick, state], ...]; and, for each,
## how many ticks they were confused (SEARCH, the `confused` clip) round the chair.
var _changes := {}
var _confused_round := {}
## For the blowing up: the tick each balloon was first shown, and its Float's scale then.
var _shown_at := {}
var _shown_scale := {}

var _tick := 0
var _checks := 0
var _failed := 0


func _initialize() -> void:
	var probe := Probe.new()
	probe.test = self
	# After the game's own physics ticks.
	probe.process_physics_priority = 1000
	root.add_child(probe)
	_load_level()
	print("Let the balloons go: the real level at the developer menu's \"free\" point, %d physics ticks a second"
		% Engine.physics_ticks_per_second)
	_run()


func _load_level() -> void:
	DevMenu._next = "free"
	level = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	player = null
	_shown_at.clear()
	_shown_scale.clear()


class Probe extends Node:
	var test: Object

	func _physics_process(_delta: float) -> void:
		test.call("step")


func step() -> void:
	_tick += 1
	if _refs():
		_record()
	# Every tick, whatever the level's state: the test's awaits count on it.
	ticked.emit()


## The level's nodes, once they're there (after a reload too); false until then.
func _refs() -> bool:
	if level == null or not is_instance_valid(level):
		return false
	if player == null:
		var p: CharacterBody3D = level.get("player")
		var c: Node = level.get("campsite")
		if p == null or c == null or c.get("balloons") == null:
			return false
		camp = c
		balloons_node = camp.get("balloons")
		girl = camp.get("dancers")[1]
		player = p
	return true


func _record() -> void:
	_girl_states[int(girl.get("state"))] = true
	var chair_at := _chair_at()
	for person: Node3D in camp.get("people"):
		var s := int(person.get("state"))
		var hist: Array = _changes.get(person, [])
		if hist.is_empty() or hist[-1][1] != s:
			hist.append([_tick, s])
			_changes[person] = hist
		var anim := person.get("anim") as AnimationPlayer
		if s == CampPersonScript.State.SEARCH and anim and anim.current_animation == "confused" \
				and _flat_dist(person.global_position, chair_at) <= ROUND:
			_confused_round[person] = int(_confused_round.get(person, 0)) + 1
	for b: Node3D in balloons_node.get("balloons"):
		if b.visible and not _shown_at.has(b):
			_shown_at[b] = _tick
		elif _shown_at.has(b) and not _shown_scale.has(b):
			# Its first look: `inflate` is applied on the process tick after the physics tick
			# that showed it, before that frame is drawn.
			_shown_scale[b] = (b.get_node("Float") as Node3D).scale.x


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


func _flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _real() -> Array[Node3D]:
	var out: Array[Node3D] = []
	out.assign(balloons_node.get("balloons"))
	return out


func _chair_at() -> Vector3:
	var c: Vector2 = CampBalloonsScript.CHAIR
	return balloons_node.to_global(Vector3(c.x, 0.0, c.y))


func _mark() -> void:
	_changes.clear()
	_confused_round.clear()
	for person: Node3D in camp.get("people"):
		_changes[person] = [[_tick, int(person.get("state"))]]


func _states_of(person: Node3D) -> Array:
	return (_changes.get(person, []) as Array).map(func(c: Array) -> int: return c[1])


func _names(states: Array) -> String:
	var S := CampPersonScript.State
	return " ".join(states.map(func(s: int) -> String: return S.keys()[s]))


## Sends her to her step `i`, from here, for `left` seconds there.
func _send_girl(i: int, left: float) -> void:
	girl.set("_step", i)
	girl.set("_arrived", false)
	girl.set("_step_left", left)


## Puts him by the knot, facing it, his mouth just short of it; presses and lets go of E.
func _press_e_at_knot() -> void:
	var knot: Vector3 = balloons_node.call("knot_at")
	player.call("place", Vector3(knot.x + 0.55, 0.02, knot.z))
	# Facing -X, toward the knot.
	player.rotation.y = PI / 2.0
	await _wait(10)
	_key(KEY_E, true)
	await _wait(2)
	_key(KEY_E, false)
	await _wait(1)


func _run() -> void:
	await ticked
	await _until(func() -> bool: return player != null, 30)
	camp.set("cones_on", false)
	await _wait(30)
	await _before()
	_structure()
	await _girl_blows_them_up()
	_balloons_up()
	await _girl_minds_them()
	await _girl_scared()
	await _let_go_seen()
	await _let_go_found()
	print("RESULT: %s (%d checks, %d failed)" % ["FAILED" if _failed > 0 else "all checks passed", _checks, _failed])
	quit(1 if _failed > 0 else 0)


# --- Before her first visit, the task, one authority -----------------------------------

func _before() -> void:
	var chair: Node3D = balloons_node.get("chair")
	var shown := _real().filter(func(b: Node3D) -> bool: return b.visible).size()
	_check("before she's been out: no chair, no balloons showing (%d), none tied" % shown,
		not chair.visible and shown == 0 and int(balloons_node.get("tied")) == 0, "chair %s" % chair.visible)
	_check("the tasks are revealed (so only the balloons' own state stops E)", camp.get("tasks").revealed, "")
	await _press_e_at_knot()
	_check("E where the knot will be: nothing to untie, nothing let go, the task not ticked",
		not balloons_node.get("released") and not camp.get("tasks").is_done("balloons"), "")
	player.call("place", QUIET)
	await _wait(10)


func _structure() -> void:
	var task: Dictionary = {}
	for t: Dictionary in camp.get("tasks").list:
		if t.id == "balloons":
			task = t
	_check("the task: Let the balloons go, on the camp's list, \"Untie them, let them fly.\"",
		task.get("text") == "Let the balloons go" and task.get("camp", false) and task.get("hint") == "Untie them, let them fly.", task)

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
	# play("inflate"), play("bob") and seek(): three.
	_check("party_balloon.gd: every play() and seek() is on its own AnimationPlayer (%d)" % on_anim, off.is_empty() and on_anim == 3, off)
	var game: String = files.get("res://scripts/camp_balloons.gd", "")
	var game_calls: Array = []
	for m in calls.search_all(game):
		game_calls.append(m.get_string(0))
	_check("camp_balloons.gd: its only play() or seek() is the bunch's player's play() (%s)" % ", ".join(game_calls),
		game_calls == ["_bunch_anim.play("], game_calls)
	var users: Array = []
	for path: String in files:
		if (files[path].contains("party_balloon") or files[path].contains("balloon_bunch")) \
				and path.get_file() not in ["camp_balloons.gd", "party_balloon.gd"]:
			users.append(path)
	_check("no other game script uses the balloon or the bunch", users.is_empty(), users)


# --- The girl blows them up -----------------------------------------------------------

## Her routine and her first time out there (CHANGE-BRIEF.md, "Let the balloons go"): the chair,
## then each balloon in turn, then back to the party. Driven as tasks_test.gd drives the
## routines: her warming is cut short (_step_left), and she goes on by herself.
func _girl_blows_them_up() -> void:
	var routine: Array = girl.get("routine")
	var names: Array = routine.map(func(a: Dictionary) -> String: return a.name)
	var minding: Vector2 = ForestScript.CAMP + CampBalloonsScript.PLACE + CampBalloonsScript.MINDER
	_check("her routine: dance, warm, then the balloons (%s)" % " ".join(names), names == ["dance", "warm", "balloons"], names)
	if names.size() < 3:
		return
	var step: Dictionary = routine[2]
	_check("her balloon step: by them, for about a dance's length (GIRL_DANCE_TIME %s s)" % str(step.time),
		Vector2(step.at.x, step.at.z).distance_to(minding) < 0.01 and step.time == CampsiteScript.GIRL_DANCE_TIME,
		"%s, %s" % [step.at, step.time])
	var path := NavigationServer3D.map_get_path((camp as Node3D).get_world_3d().navigation_map, routine[1].at, step.at, true)
	var reaches: bool = path.size() > 1 and Vector2(path[-1].x, path[-1].z).distance_to(minding) < ON_SPOT
	_check("the walkways reach her spot from the fire (%d points)" % path.size(), reaches, path[-1] if path.size() > 0 else "no path")

	player.call("place", QUIET)
	_send_girl(1, 0.01)
	await _until(func() -> bool: return girl.call("activity") == "balloons", 1800)
	var there := await _until(func() -> bool: return girl.call("at_activity"), 3600)
	var arrived := _tick
	var at := Vector2(girl.global_position.x, girl.global_position.z)
	_check("from warming her hands she walks out: on her spot, %.2f m from the camp's middle" % at.distance_to(ForestScript.CAMP),
		there and at.distance_to(minding) < ON_SPOT and at.distance_to(ForestScript.CAMP) > CampsiteScript.CAMP_ZONE,
		"%.2f m from her spot" % at.distance_to(minding))
	await _wait(5)
	var chair: Node3D = balloons_node.get("chair")
	_check("she sets out the chair as she gets there", chair.visible and balloons_node.get("chair_out"), chair.visible)

	# Each in turn: red, yellow, blue, shown as a bud and inflating; tied INFLATE after.
	var gone_back := await _until(func() -> bool: return girl.call("activity") == "dance", 60 * 20)
	var left_at := _tick
	var real := _real()
	var starts: Array = real.map(func(b: Node3D) -> int: return int(_shown_at.get(b, -1)))
	var first_start := (int(starts[0]) - arrived) / 60.0
	_check("after setting out the chair (SET_OUT %.1f s), red is the first she blows up (%.2f s after she got there)"
		% [CampBalloonsScript.SET_OUT, first_start], int(starts[0]) > 0 and absf(first_start - CampBalloonsScript.SET_OUT) < 0.1, starts)
	var apart := CampBalloonsScript.INFLATE + CampBalloonsScript.GAP
	var gaps: Array = []
	for i in range(1, 3):
		gaps.append((int(starts[i]) - int(starts[i - 1])) / 60.0)
	_check("one by one, in order, each started %.1f s after the last (INFLATE %.1f + GAP %.1f): %s"
		% [apart, CampBalloonsScript.INFLATE, CampBalloonsScript.GAP, str(gaps.map(func(g: float) -> String: return "%.2f s" % g))],
		gaps.all(func(g: float) -> bool: return absf(g - apart) < 0.1), gaps)
	var buds: Array = real.map(func(b: Node3D) -> float: return float(_shown_scale.get(b, 1.0)))
	_check("each shown as a small, limp bud (Float's scale on its first drawn frame: %s)" % str(buds.map(func(s: float) -> String: return "%.2f" % s)),
		buds.all(func(s: float) -> bool: return s < 0.3), buds)
	_check("all three tied to the chair", int(balloons_node.get("tied")) == 3, balloons_node.get("tied"))
	var took := (left_at - arrived) / 60.0
	var want := CampBalloonsScript.SET_OUT + 3.0 * CampBalloonsScript.INFLATE + 2.0 * CampBalloonsScript.GAP
	_check("with the third tied she goes back to dancing: there %.2f s (SET_OUT + three INFLATE + two GAP = %.2f s)" % [took, want],
		gone_back and absf(took - want) < 0.2, girl.call("activity"))


func _balloons_up() -> void:
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
	var knot: Vector3 = balloons_node.call("knot_at")
	for b in real:
		var c: String = b.get("colour")
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
		for v in verts:
			across = maxf(across, Vector2(v.x, v.z).length() * 2.0)
		_check("%s: 0.3 m across its body" % c, absf(across - BODY_ACROSS) < 0.005, "%.4f m" % across)
		var up: float = b.global_position.y - camp_at.y
		_check("%s: its middle about 0.7 m up (%.3f m)" % [c, up], absf(up - 0.7) < 0.05, "%.3f m up" % up)
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
		var end: Vector3 = b.global_transform * STRING_END
		_check("%s: its string ends on the knot (%.3f m off)" % [c, end.distance_to(knot)], end.distance_to(knot) < 0.03, end)
		var anim := b.get_node("AnimationPlayer") as AnimationPlayer
		_check("%s: its AnimationPlayer plays `bob` while it's tied" % c, anim.current_animation == "bob", anim.current_animation)
	var at := real.map(func(b) -> float: return (b.get_node("AnimationPlayer") as AnimationPlayer).current_animation_position)
	var apart := absf(at[0] - at[1]) > 0.1 and absf(at[1] - at[2]) > 0.1 and absf(at[0] - at[2]) > 0.1
	_check("not in step: each bobs from its own offset (positions %s s)" % str(at.map(func(p) -> String: return "%.3f" % p)), apart, at)
	var chair := _chair_at()
	var low := knot.y - camp_at.y
	_check("the knot: low on the chair (%.2f m up, %.2f m from its middle), in his reach" % [low, _flat_dist(knot, chair)],
		low < 0.15 and _flat_dist(knot, chair) < 0.4, knot)
	var chair_node: Node3D = balloons_node.get("chair")
	var chair_bodies := chair_node.find_children("*", "CollisionObject3D", true, false).size()
	_check("the chair: built in code (a low-poly mesh), no collider", chair_node is MeshInstance3D and chair_bodies == 0, chair_bodies)


## Later visits: she minds them, staying about a dance's length, then dances again.
func _girl_minds_them() -> void:
	_send_girl(1, 0.01)
	await _until(func() -> bool: return girl.call("activity") == "balloons", 1800)
	var drawn: float = girl.get("_step_left")
	await _until(func() -> bool: return girl.call("at_activity"), 3600)
	var arrived := _tick
	await _until(func() -> bool: return girl.call("activity") != "balloons", 3600)
	var stayed := (_tick - arrived) / 60.0
	_check("her next time out she minds them: stays %.2f s (drawn %.2f s, from GIRL_DANCE_TIME), all three still tied, then back to dancing"
		% [stayed, drawn], absf(stayed - drawn) < 0.1 and int(balloons_node.get("tied")) == 3 and girl.call("activity") == "dance",
		"%.2f s, then %s" % [stayed, girl.call("activity")])
	# Back out to them, staying, for the fright below.
	_send_girl(2, 400.0)
	await _until(func() -> bool: return girl.call("at_activity"), 3600)


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
	# Everyone back at their routine before the next part.
	await _until(func() -> bool: return camp.get("people").all(func(p: Node3D) -> bool: return p.get("state") == S.WORK), 60 * 40)


# --- He lets them go ------------------------------------------------------------------

## Waits for the call's search to play out, then checks it: each called one came round the
## chair confused and searched there, then went back to their routine.
func _check_call(label: String, called: Array) -> void:
	var S := CampPersonScript.State
	var everyone: Array = called + [girl]
	await _until(func() -> bool: return everyone.all(func(p: Node3D) -> bool:
		var st := _states_of(p)
		return st.has(S.SEARCH) and p.get("state") == S.WORK), 60 * 60)
	for p: Node3D in called:
		var st := _states_of(p)
		var searched := int(_confused_round.get(p, 0)) / 60.0
		_check("%s: %s comes to look: confused (\"?\"), round the chair, searching there %.2f s, then back to the routine (%s)"
			% [label, p.name, searched, _names(st)],
			st.size() >= 2 and st[1] == S.SEARCH and searched >= CampPersonScript.SEARCH_TIME - 0.1 and p.get("state") == S.WORK
				and not st.has(S.GUARD) and not st.has(S.CHASE), _names(st))
	var gst := _states_of(girl)
	var gsearched := int(_confused_round.get(girl, 0)) / 60.0
	_check("%s: she too, once calm: searches round the chair %.2f s, then back to her routine (%s)" % [label, gsearched, _names(gst)],
		gst.has(S.SEARCH) and gsearched >= CampPersonScript.SEARCH_TIME - 0.1 and girl.get("state") == S.WORK, _names(gst))


## Those who'd come when called: calm or wondering, not the girl.
func _callable() -> Array:
	var S := CampPersonScript.State
	return camp.get("people").filter(func(p: Node3D) -> bool:
		return p != girl and p.get("state") in [S.WORK, S.RETURN, S.INVESTIGATE, S.SEARCH])


## With her minding them, he tugs the knot loose: they float away, the task ticks, she sees it.
func _let_go_seen() -> void:
	var S := CampPersonScript.State
	_send_girl(2, 400.0)
	await _until(func() -> bool: return girl.call("at_activity"), 3600)
	var tasks = camp.get("tasks")
	_check("before: the knot can be untied, the task not ticked", balloons_node.call("can_untie") and not tasks.is_done("balloons"), "")
	var callable := _callable()
	_mark()
	await _press_e_at_knot()
	var released_tick: int = _tick
	var lift := (balloons_node.get("bunch") as Node3D).get_node("Lift") as Node3D
	var bunch_anim := (balloons_node.get("bunch") as Node3D).get_node("AnimationPlayer") as AnimationPlayer
	_check("E at the knot (his grab): let go, the task ticked, the bunch playing `float_away`",
		balloons_node.get("released") and tasks.is_done("balloons") and bunch_anim.current_animation == "float_away",
		"%s, %s, %s" % [balloons_node.get("released"), tasks.is_done("balloons"), bunch_anim.current_animation])
	_check("and nothing left to untie", not balloons_node.call("can_untie"), "")
	var gst := _states_of(girl)
	_check("she sees them go: takes fright at once (%s)" % _names(gst), gst.has(S.STARTLED), _names(gst))
	await _wait(30)
	var to_chair := _chair_at() - girl.global_position
	var facing := girl.global_basis.z
	# They face +Z (camp_person.gd).
	var faces := absf(rad_to_deg(Vector2(girl.global_basis.z.x, girl.global_basis.z.z).angle_to(Vector2(to_chair.x, to_chair.z))))
	print("INFO  half a second on: she faces %.0f degrees off the chair (facing %s)" % [faces, facing])
	_check("in her fright she faces where they were (within 30 degrees)", faces < 30.0, "%.0f" % faces)
	var called_now := callable.filter(func(p: Node3D) -> bool: return _states_of(p).has(S.SEARCH))
	_check("she calls the others: each one calm or wondering (%s) is confused at once, coming to look"
		% ", ".join(callable.map(func(p: Node3D) -> String: return p.name)),
		callable.size() > 0 and called_now.size() == callable.size(), called_now.map(func(p: Node3D) -> String: return p.name))
	await _until(func() -> bool: return _tick - released_tick >= 150, 200)
	_check("halfway (2.5 s): rising, %.2f m up, still showing" % lift.position.y, lift.visible and lift.position.y > 2.0 and lift.position.y < 6.0, "")
	await _until(func() -> bool: return _tick - released_tick >= 5 * 60 + 10, 200)
	_check("after 5 s: 8 m up (%.2f m) and gone" % lift.position.y, not lift.visible and absf(lift.position.y - 8.0) < 0.05, lift.visible)
	await _check_call("seen going", callable)


## In a fresh level: blown up, then let go while she's dancing in the camp. Nobody reacts while
## they float away; back at her step, she finds the chair empty and calls the others.
func _let_go_found() -> void:
	var S := CampPersonScript.State
	level.queue_free()
	await _wait(2)
	_load_level()
	await _until(func() -> bool: return player != null, 30)
	camp.set("cones_on", false)
	await _wait(30)
	player.call("place", QUIET)
	_send_girl(1, 0.01)
	await _until(func() -> bool: return int(balloons_node.get("tied")) == 3, 60 * 60)
	await _until(func() -> bool: return girl.call("activity") == "dance" and girl.call("at_activity"), 60 * 40)
	girl.set("_step_left", 400.0)
	await _until(func() -> bool: return camp.get("people").all(func(p: Node3D) -> bool: return p.get("state") == S.WORK), 60 * 20)
	var far := _flat_dist(girl.global_position, _chair_at())
	_mark()
	await _press_e_at_knot()
	var tasks = camp.get("tasks")
	_check("a second level, she's dancing %.1f m away (beyond her %.0f m sight): E at the knot lets them go, the task ticked"
		% [far, CampPersonScript.SIGHT], far > CampPersonScript.SIGHT and balloons_node.get("released") and tasks.is_done("balloons"), "")
	player.call("place", QUIET)
	await _wait(5 * 60 + 30)
	var reacted: Array = camp.get("people").filter(func(p: Node3D) -> bool: return _states_of(p).size() > 1)
	_check("while they float away out of her sight, nobody reacts (all still at their routines)",
		reacted.is_empty(), reacted.map(func(p: Node3D) -> String: return "%s %s" % [p.name, _names(_states_of(p))]))
	var callable := _callable()
	_mark()
	_send_girl(2, 400.0)
	await _until(func() -> bool: return girl.call("at_activity") or _states_of(girl).size() > 1, 60 * 40)
	await _wait(3)
	var gst := _states_of(girl)
	_check("back at her step she finds the chair empty: takes fright (%s)" % _names(gst), gst.has(S.STARTLED), _names(gst))
	var called_now := callable.filter(func(p: Node3D) -> bool: return _states_of(p).has(S.SEARCH))
	_check("and calls the others: each one calm or wondering (%s) is confused at once, coming to look"
		% ", ".join(callable.map(func(p: Node3D) -> String: return p.name)),
		callable.size() > 0 and called_now.size() == callable.size(), called_now.map(func(p: Node3D) -> String: return p.name))
	await _check_call("found empty", callable)
