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
##   - the balloons: three, red, yellow and blue, each on its sheet's 3 x 2 grid, 0.3 m across,
##     its middle 0.7 m up, clear of the table's top, with no collision; each AnimationPlayer
##     playing `float` (current_animation) while it's up, not in step with the others;
##   - one authority: in props/party_balloon.gd every play() and seek() is on its own
##     AnimationPlayer; camp_balloons.gd calls neither; no other script uses the balloon;
##   - the task: on the list under Rock the party, with its hint;
##   - three jumps (F held), one under each balloon: each pops it within the bite (ticks 5-14
##     after F is seen), each pop heard by every camper within 8 m of it (HEAR_CHITTER: they
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
## Well out of the camp, where none of them can see him (scripts/cones_test.gd, _send_away).
const QUIET := Vector3(20.0, 0.02, 6.5)
const HEAR := 8.0
const REACH := 0.25
const COLOURS := ["red", "yellow", "blue"]
const SHEETS := {
	"red": "res://assets/sprites/balloons/balloon_red_4.png",
	"yellow": "res://assets/sprites/balloons/balloon_yellow.png",
	"blue": "res://assets/sprites/balloons/balloon_blue_4.png",
}
## The table's top, from its middle (campsite.gd _table_legs: 1.28 x 0.83 m).
const TABLE_HALF := Vector2(0.64, 0.415)

var level: Node
var camp: Node
var player: CharacterBody3D
var balloons_node: Node3D

var _tick := 0
var _checks := 0
var _failed := 0
## Ticks since the current jump's press was seen (0 on that tick), -1 when not jumping.
var _jt := -1
var _was_jumping := false
## Every pop: {balloon, tick, jt, heard: [[name, distance, heard]]}.
var _pops: Array[Dictionary] = []
var _seen_popped := {}


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
	var jumping: bool = player.get("jumping")
	if jumping and not _was_jumping:
		_jt = 0
	elif jumping:
		_jt += 1
	elif not jumping:
		_jt = -1
	_was_jumping = jumping
	for b: Sprite3D in balloons_node.get("balloons"):
		if b.get("popped") and not _seen_popped.has(b):
			_seen_popped[b] = true
			var heard: Array = []
			for person: Node3D in camp.get("people"):
				var d := Vector2(person.global_position.x - b.global_position.x, person.global_position.z - b.global_position.z).length()
				var at: Vector3 = person.get("_noise_at")
				heard.append([person.name, d, at.distance_to(b.global_position) < 0.01])
			_pops.append({"balloon": b, "tick": _tick, "jt": _jt, "heard": heard})
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


func _real() -> Array[Sprite3D]:
	var out: Array[Sprite3D] = []
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
	await _task()
	await _edges()
	print("RESULT: %s (%d checks, %d failed)" % ["FAILED" if _failed > 0 else "all checks passed", _checks, _failed])
	quit(1 if _failed > 0 else 0)


# --- The balloons, the task, one authority -------------------------------------------

func _structure() -> void:
	var real := _real()
	_check("three balloons, red, yellow and blue", real.size() == 3 and real.map(func(b) -> String: return b.get("colour")) == COLOURS,
		real.map(func(b) -> String: return b.get("colour")))
	var table: Array = CampsiteScript.TABLE
	var camp_at: Vector3 = (camp as Node3D).global_position
	var table_mid: Vector3 = Vector3(table[0].x, 0.0, table[0].y) + camp_at
	for b in real:
		var c: String = b.get("colour")
		var sheet := b.texture.resource_path if b.texture else ""
		_check("%s: its own sheet, sliced 3 x 2" % c, sheet == SHEETS[c] and b.hframes == 3 and b.vframes == 2,
			"%s %d x %d" % [sheet, b.hframes, b.vframes])
		_check("%s: 0.3 m across (its body's 14 px at pixel_size)" % c, absf(b.pixel_size * 14.0 - 0.3) < 0.001, b.pixel_size * 14.0)
		var up: float = b.global_position.y - camp_at.y
		_check("%s: its middle 0.7 m up (the node's offset puts its origin on the body's middle)" % c,
			absf(up - 0.7) < 0.01 and b.offset == Vector2(0, -5.5), "%.3f m, offset %s" % [up, b.offset])
		var rel: Vector3 = b.global_position - table_mid
		_check("%s: clear of the table's top" % c, absf(rel.x) > TABLE_HALF.x or absf(rel.z) > TABLE_HALF.y,
			"%.2f, %.2f from its middle" % [rel.x, rel.z])
		var bodies := b.find_children("*", "CollisionObject3D", true, false).size() + b.find_children("*", "CollisionShape3D", true, false).size()
		_check("%s: no collision" % c, bodies == 0, bodies)
		var anim := b.get_node("AnimationPlayer") as AnimationPlayer
		_check("%s: its AnimationPlayer plays `float` while it's up" % c, anim.current_animation == "float", anim.current_animation)
	var at := real.map(func(b) -> float: return (b.get_node("AnimationPlayer") as AnimationPlayer).current_animation_position)
	var apart := absf(at[0] - at[1]) > 0.1 and absf(at[1] - at[2]) > 0.1 and absf(at[0] - at[2]) > 0.1
	_check("not in step: each starts its float at its own offset (positions %s s)" % str(at.map(func(p) -> String: return "%.3f" % p)), apart, at)

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
	_check("party_balloon.gd: every play() and seek() is on its own AnimationPlayer (%d)" % on_anim, off.is_empty() and on_anim == 2, off)
	var game: String = files.get("res://scripts/camp_balloons.gd", "")
	_check("camp_balloons.gd calls no play() or seek(), and has no AnimationPlayer",
		calls.search(game) == null and not game.contains("AnimationPlayer"), "")
	var users: Array = []
	for path: String in files:
		if files[path].contains("party_balloon") and path.get_file() not in ["camp_balloons.gd", "party_balloon.gd"]:
			users.append(path)
	_check("no other game script uses the balloon", users.is_empty(), users)


func _task() -> void:
	var tasks = camp.get("tasks")
	var real := _real()
	for i in 3:
		var b := real[i]
		var c: String = b.get("colour")
		await _under(b.global_position)
		var before := _pops.size()
		await _jump()
		var mine := _pops.slice(before)
		_check("%s: a jump under it (F held) pops it" % c, mine.size() == 1 and mine[0].balloon == b and b.get("popped") and not b.visible,
			"%d pops, popped %s, visible %s" % [mine.size(), b.get("popped"), b.visible])
		if mine.size() == 1:
			var jt: int = mine[0].jt
			_check("%s: popped within the bite, ticks 5-14 after F is seen (on tick %d)" % [c, jt], jt >= 5 and jt <= 14, jt)
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
				_check("%s still up: `float` playing" % other.get("colour"), a.current_animation == "float", a.current_animation)
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


# --- The bite's edges, with balloons the test adds ----------------------------------

func _extra() -> Sprite3D:
	var b := BalloonScene.instantiate() as Sprite3D
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
