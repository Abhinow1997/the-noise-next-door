extends Node
## Effect A's state test (CHANGE-BRIEF.md, "The evidence split": the two state-test rows).
## In the real level (main.tscn) with the tutorial skipped, it drives the raccoon through
## the game loop with real move keys (Input.action_press): he walks into the camp's bush
## and dives in, hops straight out, walks back in, sits hidden, and hops out again. It
## counts the leaf bursts (copies of effects/leaf_burst.tscn in the tree) and checks:
##   - none at scene load, none before an event, none while he sits hidden or stands out;
##   - exactly one new burst per dive in and per hop out, at the bush, with amount_ratio 1.0
##     going in and 0.5 coming out, emitting as it's made;
##   - overlap: in and straight out leaves two alive at once, never more than two;
##   - each freed once its emitters' longer lifetime (read from the scene) and 0.1 s pass;
##   - bursts made = the bush's `hiding_changed` signals = the events the test drove. A
##     camper startling him out would be an extra event: this fails, and says so.
## `place()` only sets him down outside the bush before the first walk; it never takes
## him out of it. Nothing here calls the listener (scripts/leaf_bursts.gd) or `dived()`.
## A headless run draws nothing and runs no particle process: this checks the nodes, not
## how many leaves fly or how they look (the frame strip and play do).
## Run it headless from the project folder:
##   bash scripts/run-test.sh --leaf-burst-test 60
## It prints a table and quits with exit code 0 if every check passes, 1 if not.
## Written by Claude Code on 7 Nov 2026.

const SCENE := "res://effects/leaf_burst.tscn"
const Player := preload("res://scripts/player.gd")
## How far from the bush's middle he's set down before he walks in (m): outside its
## hiding shape (campsite.gd BUSH_HIDE, 0.8 m) and his own capsule.
const START_OFF := 2.2
## One physics tick at 60 a second, for timing tolerances.
const TICK := 1.0 / 60.0

## Set by the level (main.gd).
var level: Node

var _results: Array[Array] = []
var _failed := false
var _player: Node3D
var _bush: Node3D
## Game time since the test started (s), counted in physics ticks.
var _t := 0.0
## Every burst seen: instance id -> {node, born, freed, event}. `event` is the index in
## _events of the signal it came with, or -1 if it turned up with none.
var _seen := {}
var _events: Array[Dictionary] = []
var _max_alive := 0
var _unexplained := 0
var _driven := 0
var _free_after := 0.0


func _ready() -> void:
	_player = level.player
	_bush = level.campsite.bush
	# After the listener (main.gd adds it first), so its burst is already made here.
	_bush.hiding_changed.connect(_on_hiding_changed)
	var copy := (load(SCENE) as PackedScene).instantiate()
	for p: GPUParticles3D in copy.get_children():
		_free_after = maxf(_free_after, p.lifetime)
	copy.free()
	_free_after += 0.1
	_run.call_deferred()


func _physics_process(delta: float) -> void:
	_t += delta
	var alive := _bursts()
	_max_alive = maxi(_max_alive, alive.size())
	for b: Node3D in alive:
		if not _seen.has(b.get_instance_id()):
			_unexplained += 1
			_seen[b.get_instance_id()] = {"node": b, "born": _t, "freed": -1.0, "event": -1}
	for rec: Dictionary in _seen.values():
		if rec.freed < 0.0 and (not is_instance_valid(rec.node) or rec.node.is_queued_for_deletion()):
			rec.freed = _t


func _on_hiding_changed(inside: bool) -> void:
	var fresh: Array[Node3D] = []
	for b: Node3D in _bursts():
		if not _seen.has(b.get_instance_id()):
			fresh.append(b)
	var ev := {"inside": inside, "t": _t, "fresh": fresh.size(), "at": [], "ratios": [], "emitting": []}
	for b in fresh:
		_seen[b.get_instance_id()] = {"node": b, "born": _t, "freed": -1.0, "event": _events.size()}
		ev.at.append(b.global_position)
		for p: GPUParticles3D in b.get_children():
			ev.ratios.append(snappedf(p.amount_ratio, 0.01))
			ev.emitting.append(p.emitting)
	_events.append(ev)


func _run() -> void:
	# Scene load: half a second of the level, nobody touching anything.
	await _wait(0.5)
	_check("Scene load: no burst, no event (never on load)", "0 0", "%d %d" % [_seen.size(), _events.size()])

	# Set down west of the bush, facing it, so move_right walks him straight in (the camera
	# turns the keys, player.gd _move_input), and move_left hops him out away from the camp.
	var toward := _key_dir("move_right")
	var at: Vector3 = _bush.global_position - toward * START_OFF
	at.y = 0.02
	_player.global_basis = Basis(Vector3.UP, atan2(-toward.x, -toward.z))
	_player.place(at)
	await _wait(0.3)
	_check("Set down outside the bush: not hidden, no burst", "false 0",
		"%s %d" % [_player.hiding_in != null, _seen.size()])

	# 1. Walk in: he dives (a hop of DIVE_TIME); the key's let go as the hop starts, as a
	# player would, or he'd hop straight back out on landing.
	await _walk_in()
	_check("Walking in: no burst before he lands (never before the event)", "true 0",
		"%s %d" % [_player.is_hopping(), _seen.size()])
	await _until(func() -> bool: return _player.hiding_in == _bush, 1.0)
	_driven += 1
	_check("Dive in: hidden in the bush", true, _player.hiding_in == _bush)
	_check_event(0, true, "Dive in")

	# 2. Hop straight out: move_left the tick after he's landed, well inside one lifetime.
	Input.action_press("move_left")
	await _until(func() -> bool: return _player.hiding_in == null, 0.5)
	Input.action_release("move_left")
	_driven += 1
	_check("Hop out: out of the bush, by a move key", false, _player.hiding_in != null)
	_check_event(1, false, "Hop out")
	var both := _bursts()
	_check("Overlap: in and straight out, two bursts alive at once, different copies", "2 true",
		"%d %s" % [both.size(), both.size() == 2 and both[0] != both[1]])
	_check("Overlap: the second came inside the first's lifetime (s)", true,
		_events.size() > 1 and _events[1].t - _events[0].t < _free_after - 0.1)

	# Out, standing clear, till both are gone and DIVE_AGAIN has passed.
	var seen_before := _seen.size()
	await _until(func() -> bool: return _bursts().is_empty(), 2.0)
	var last_t: float = _events[-1].t if not _events.is_empty() else 0.0
	_check("Freed: none left %.2f s after the hop out (lifetime read + 0.1 s), give or take a tick"
		% _free_after, true, absf((_t - last_t) - _free_after) <= 2.5 * TICK)
	await _wait(0.2)
	_check("Standing out: no new burst", 0, _seen.size() - seen_before)

	# 3. Walk back in: a second dive in fires too (every event, not just the first).
	await _walk_in()
	await _until(func() -> bool: return _player.hiding_in == _bush, 1.0)
	_driven += 1
	_check("Dive in again: hidden in the bush", true, _player.hiding_in == _bush)
	_check_event(2, true, "Dive in again")

	# Sitting hidden for a second: nothing new.
	seen_before = _seen.size()
	await _wait(1.0)
	_check("Sitting hidden 1 s: no new burst, still hidden", "0 true",
		"%d %s" % [_seen.size() - seen_before, _player.hiding_in == _bush])

	# 4. Hop out after a while hidden: its own, smaller burst, alone.
	Input.action_press("move_left")
	await _until(func() -> bool: return _player.hiding_in == null, 0.5)
	Input.action_release("move_left")
	_driven += 1
	_check_event(3, false, "Hop out again")
	_check("Hop out again: one burst alive (the dive's is gone)", 1, _bursts().size())
	await _wait(_free_after + 0.3)

	# The whole run.
	var lives: Array[String] = []
	var lives_ok := true
	for rec: Dictionary in _seen.values():
		var life: float = rec.freed - rec.born if rec.freed >= 0.0 else -1.0
		lives.append("%.2f" % life)
		lives_ok = lives_ok and absf(life - _free_after) <= 2.5 * TICK
	_check("Each burst freed %.2f s after it was made, give or take a tick" % _free_after,
		"true", "%s %s" % [lives_ok, " ".join(lives)] if not lives_ok else "true")
	_check("At most 2 alive at once, over the whole run", true, _max_alive <= 2 and _max_alive == 2)
	_check("No burst without an event (never otherwise)", 0, _unexplained)
	_check("Bursts = hiding_changed signals = events driven (a startle would add one)", "4 4 4",
		"%d %d %d" % [_seen.size(), _events.size(), _driven])
	_check("None left at the end", 0, _bursts().size())
	_finish()


## Checks the burst that came with the `i`-th hiding_changed signal.
func _check_event(i: int, inside: bool, what: String) -> void:
	if i >= _events.size():
		_check("%s: a hiding_changed signal (%s)" % [what, "in" if inside else "out"], true, false)
		return
	var ev: Dictionary = _events[i]
	_check("%s: the signal says %s" % [what, "in" if inside else "out"], inside, ev.inside)
	_check("%s: exactly one new burst" % what, 1, ev.fresh)
	if ev.fresh != 1:
		return
	var pos: Vector3 = ev.at[0]
	_check("%s: at the bush %s" % [what, _bush.global_position], true, pos.is_equal_approx(_bush.global_position))
	var want := 1.0 if inside else 0.5
	_check("%s: amount_ratio %.1f on Leaves and Puff" % [what, want], "[%s, %s]" % [want, want], str(ev.ratios))
	_check("%s: emitting as it's made" % what, "[true, true]", str(ev.emitting))


## Holds move_right until he starts his dive (the hop), then lets go.
func _walk_in() -> void:
	Input.action_press("move_right")
	await _until(func() -> bool: return _player.is_hopping() or _player.hiding_in != null, 3.0)
	Input.action_release("move_right")


## Where a move key takes him on the ground, as player.gd turns it by the camera.
func _key_dir(action: String) -> Vector3:
	var v := Vector2.ZERO
	match action:
		"move_right": v = Vector2(1, 0)
		"move_left": v = Vector2(-1, 0)
	var dir := Vector3(v.x, 0.0, v.y)
	if _player.camera:
		dir = dir.rotated(Vector3.UP, _player.camera.global_rotation.y)
	return dir.normalized()


## The leaf bursts in the level now (copies of the effect's scene, not being freed).
func _bursts() -> Array[Node3D]:
	var out: Array[Node3D] = []
	for n in level.find_children("*", "Node3D", true, false):
		if n.scene_file_path == SCENE and not n.is_queued_for_deletion():
			out.append(n)
	return out


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false, true).timeout


## Until `done`, for at most `timeout` seconds of game time.
func _until(done: Callable, timeout: float) -> void:
	var left := timeout
	while left > 0.0 and not done.call():
		await get_tree().physics_frame
		left -= get_physics_process_delta_time()


func _check(name: String, expected, actual) -> void:
	var ok: bool = str(expected) == str(actual)
	_failed = _failed or not ok
	_results.append([name, str(expected), str(actual), "pass" if ok else "FAIL"])


func _finish() -> void:
	Input.action_release("move_right")
	Input.action_release("move_left")
	print("")
	print("Leaf burst state check, %s" % Time.get_datetime_string_from_system())
	for r: Array in _results:
		print("  %-4s  %-78s expected %-14s got %s" % [r[3], r[0], r[1], r[2]])
	print("RESULT: %s (%d checks)" % ["all checks passed" if not _failed else "SOME CHECKS FAILED", _results.size()])
	get_tree().quit(1 if _failed else 0)
