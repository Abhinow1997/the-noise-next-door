extends Node
## Effect B's state test (CHANGE-BRIEF.md, revised 8 Nov 2026, "Effect B, the campfire
## smoke": "Observable rules" and "The evidence split"; "Effect B's wiring, for Step 3").
## In the real level (main.tscn) with the tutorial skipped. Two starts, two flags (main.gd):
##   --smoke-test       the fire cold, its cycle on (as --fire-test). The game moves the
##                      fire: the keeper lights it and builds it a log at a time on his own,
##                      it burns down, Esc pauses the tree (a real key event, main.gd Keys),
##                      E held at the bucket douses it (as fire_test.gd), and the keeper
##                      lights it again.
##   --smoke-load-test  the fire burning at load (as --dev-start=fire).
## Every rendered frame, after the driver has run (process_priority), it reads the game's
## smoke (main.gd `campfire_smoke`, scripts/campfire_smoke.gd) against the fire's strength.
## Nothing here calls the driver, add_log(), douse() or start_cycle(). As fire_test.gd does,
## it sets him down (place()) and turns the cones off to reach the bucket: that's setup,
## not the condition. Hiding the smoke is the test's own doing: nothing in the game hides it.
## The numbers in the names are the plan's assertions (design/a6/session-6.jsonl).
## A headless run draws nothing and runs no particle process: this checks the node's state
## (amount_ratio, emitting, amount, pause and visibility), not how the smoke looks, how many
## puffs fly, or what the GPU does while paused or hidden (the strip and play do).
## Run it headless from the project folder:
##   bash scripts/run-test.sh --smoke-test 60
##   bash scripts/run-test.sh --smoke-load-test 60
## It prints a table and quits with exit code 0 if every check passes, 1 if not.
## Written by Claude Code on 8 Nov 2026.

## Emitted at the end of each sample (_process, after the driver's): the point checks read
## here, never straight after a physics tick, where strength has moved and the driver's
## frame hasn't come yet.
signal sampled

const CampPerson := preload("res://scripts/camp_person.gd")
const CampFire := preload("res://scripts/camp_fire.gd")
const SCENE := "res://effects/campfire_smoke.tscn"
## The scene's amount (effects/campfire_smoke.tscn, the brief's settings table).
const AMOUNT := 40
## amount_ratio = strength, within this: amount_ratio is a 32-bit float in the engine and
## strength a 64-bit one in GDScript, so 0.98... can't match bit for bit (a float32 step
## near 1 is about 1e-7). Any real lag is a frame's burn, 1e-4 or more.
const MATCH := 1e-6

## Set by the level (main.gd): the level, and which start ("cold" or "load").
var level: Node
var mode := "cold"

var _results: Array[Array] = []
var _failed := false
var _fire: CampFire
var _driver: Node3D
var _smoke: GPUParticles3D
var _player: Node3D
var _camp
var _lit := 0
var _doused := 0
## Over every sampled frame: how many, the largest |amount_ratio - strength|, the frames
## where emitting != burning(), and the frames where amount wasn't AMOUNT.
var _frames := 0
var _max_gap := 0.0
var _emit_wrong := 0
var _amount_wrong := 0
## Each log going on (strength up a step), as sampled the frame after: [strength, ratio].
var _steps: Array = []
var _prev_strength := -1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# After the level's nodes, the driver among them, so what's read is what it set.
	process_priority = 100
	_camp = level.campsite
	_fire = _camp.campfire
	_driver = level.campfire_smoke
	_smoke = _driver.smoke
	_player = level.player
	_fire.lit.connect(func() -> void: _lit += 1)
	_fire.doused.connect(func() -> void: _doused += 1)
	# The state the copy entered the tree with, which its preprocess runs on.
	_check("#%d At load: emitting, amount_ratio, amount, strength" % (2 if mode == "load" else 1),
		"%s %.2f %d %.2f" % [mode == "load", 1.0 if mode == "load" else 0.0, AMOUNT, 1.0 if mode == "load" else 0.0],
		"%s %.2f %d %.2f" % [_smoke.emitting, _smoke.amount_ratio, _smoke.amount, _fire.strength])
	_run.call_deferred()


func _process(_delta: float) -> void:
	if _smoke == null or not is_instance_valid(_smoke):
		return
	_frames += 1
	_max_gap = maxf(_max_gap, absf(_smoke.amount_ratio - _fire.strength))
	if _smoke.emitting != _fire.burning():
		_emit_wrong += 1
	if _smoke.amount != AMOUNT:
		_amount_wrong += 1
	if _prev_strength >= 0.0 and _fire.strength > _prev_strength + 0.1:
		_steps.append([snappedf(_fire.strength, 0.01), snappedf(_smoke.amount_ratio, 0.01)])
	_prev_strength = _fire.strength
	sampled.emit()


func _run() -> void:
	if mode == "load":
		await _run_load()
	else:
		await _run_cold()
	_whole_run()
	_finish()


## Burning at load: the column's state, and the feedback at 1.0 and below.
func _run_load() -> void:
	_check("#2 At load: preprocess on the copy (s)", "3.50", "%.2f" % _smoke.preprocess)
	await _wait(0.1)
	_check("#5 Burning at load: amount_ratio = strength = 1.00", "1.00 1.00",
		"%.2f %.2f" % [_smoke.amount_ratio, _fire.strength])
	await _wait(3.0)
	_check("#8 Burning down unfed: amount_ratio = strength, below 1", "true true",
		"%s %s" % [_follows(), _fire.strength < 1.0])


func _run_cold() -> void:
	# Out of everyone's way while the keeper builds it (as fire_test.gd).
	_player.place(Vector3(20.0, 0.02, 6.5))
	await _wait(0.2)
	_check("#3 Before it's lit: not emitting, amount_ratio 0", "false 0.00 0",
		"%s %.2f %d" % [_smoke.emitting, _smoke.amount_ratio, _lit])

	# 4. The keeper lights it on his own.
	await _until(func() -> bool: return _lit > 0, 40.0)
	await sampled
	_check("#4 Lit by the keeper: emitting, amount_ratio = strength = 0.30", "1 true 0.30 0.30",
		"%d %s %.2f %.2f" % [_lit, _smoke.emitting, _smoke.amount_ratio, _fire.strength])

	# 5. He builds it up, a log at a time, then goes back to his routine.
	await _until(func() -> bool: return _keeper_state() != CampPerson.State.TEND, 60.0)
	await sampled
	# What each log brings it to depends on how much burnt off while he fetched it, so the
	# values are read, not expected: each equal, at two values at least.
	var equal := _steps.all(func(s: Array) -> bool: return s[0] == s[1])
	_check("#5 Each log: amount_ratio = strength the frame after it goes on, 2 values or more %s" % str(_steps),
		"true true", "%s %s" % [equal, _steps.size() >= 2])

	# 8. Unfed, it burns down; the smoke follows.
	var before := _smoke.amount_ratio
	await _wait(3.0)
	_check("#8 Burning down 3 s unfed: amount_ratio fell, and = strength", "true true",
		"%s %s" % [_smoke.amount_ratio < before, _follows()])

	# 10. Esc pauses the tree; Esc again carries on.
	_press_key(KEY_ESCAPE)
	await sampled
	var held := [_smoke.amount_ratio, _smoke.emitting, _smoke.amount, _fire.strength]
	_check("#10 Esc: the tree paused, the smoke not processing", "true false",
		"%s %s" % [get_tree().paused, _smoke.can_process()])
	await _wait(1.0)
	_check("#10 Paused 1 s: amount_ratio, emitting, amount, strength unchanged", str(held),
		str([_smoke.amount_ratio, _smoke.emitting, _smoke.amount, _fire.strength]))
	_press_key(KEY_ESCAPE)
	await _wait(2.0)
	_check("#10 Esc again: running, strength moving again, amount_ratio = strength", "false true true true",
		"%s %s %s %s" % [get_tree().paused, _smoke.can_process(), _fire.strength < held[3],
			_follows()])

	# 11. Hidden (by the test: nothing in the game hides it).
	var settings := _settings()
	var shown_ratio := _smoke.amount_ratio
	_driver.root.visible = false
	await _wait(3.0)
	_check("#11 Hidden 3 s: not visible in the tree", false, _smoke.is_visible_in_tree())
	_check("#11 Hidden: amount_ratio still follows strength (fell, and equal)", "true true",
		"%s %s" % [_smoke.amount_ratio < shown_ratio, _follows()])
	_check("#11 Hidden: emitting, amount and the scene's settings unchanged", "true %s" % str(settings),
		"%s %s" % [_smoke.emitting, str(_settings())])
	_driver.root.visible = true
	await sampled
	_check("#11 Shown again: visible, amount_ratio = strength", "true true",
		"%s %s" % [_smoke.is_visible_in_tree(), _follows()])

	# 9. E held at the bucket douses it (as fire_test.gd), the campers blind to him.
	_camp.cones_on = false
	_player.place(_fire.bucket.global_position + Vector3(-1.6, 0.02, 1.6))
	await _wait(0.5)
	var spot: Vector3 = _fire.bucket_spot()
	_stand(spot + Vector3(0, 0.02, 0) + (spot - _fire.bucket.global_position).normalized() * -0.1,
		_fire.bucket.global_position)
	await _wait(0.3)
	var emit_wrong_before := _emit_wrong
	await _press_e(CampFire.TIP_TIME + 0.3)
	_check("#9 Holding E tips the bucket: doused once", 1, _doused)
	await _wait(CampFire.DOUSE_TIME + 0.1)
	_check("#9 Out: strength 0, amount_ratio 0, not emitting", "0.00 0.00 false",
		"%.2f %.2f %s" % [_fire.strength, _smoke.amount_ratio, _smoke.emitting])
	_check("#9 Through the douse, emitting = burning() every frame (off when out, not before)",
		0, _emit_wrong - emit_wrong_before)

	# 12. He's gone; the keeper sets the bucket up and lights it again.
	_player.place(Vector3(20.0, 0.02, 6.5))
	_camp.cones_on = true
	await _until(func() -> bool: return _lit > 1, 100.0)
	await sampled
	_check("#12 Lit again: emitting, amount_ratio = strength", "2 true true",
		"%d %s %s" % [_lit, _smoke.emitting, _follows()])


## Over the whole run, every sampled frame.
func _whole_run() -> void:
	_check("#6 Every frame (%d): largest |amount_ratio - strength| under 0.000001 (it was %.8f)"
		% [_frames, _max_gap], true, _max_gap < MATCH)
	_check("#7 Every frame: amount = %d (frames where it wasn't)" % AMOUNT, 0, _amount_wrong)
	_check("#9 Every frame: emitting = burning() (frames where it wasn't)", 0, _emit_wrong)
	var copies := level.find_children("*", "Node3D", true, false).filter(
		func(n: Node) -> bool: return n.scene_file_path == SCENE)
	_check("One copy of the smoke in the level", 1, copies.size())


## The scene's settings on the copy, for the hidden check.
func _settings() -> Array:
	return [_smoke.amount, _smoke.lifetime, _smoke.preprocess, _smoke.one_shot, _smoke.explosiveness,
		_smoke.local_coords, _smoke.visibility_aabb, _smoke.process_material.get_instance_id(),
		_smoke.draw_pass_1.get_instance_id()]


## True while amount_ratio = strength (within MATCH).
func _follows() -> bool:
	return absf(_smoke.amount_ratio - _fire.strength) < MATCH


func _keeper_state() -> int:
	return _camp.keeper.state


func _stand(at: Vector3, look: Vector3) -> void:
	var d := look - at
	_player.global_basis = Basis(Vector3.UP, atan2(-d.x, -d.z))
	_player.place(at)


## A key pressed and let go through the level's input, as the keyboard would.
func _press_key(key: Key) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		ev.keycode = key
		ev.pressed = pressed
		Input.parse_input_event(ev)


## E pressed through the level's input, as a key would be, held `hold` seconds (fire_test.gd).
func _press_e(hold: float) -> void:
	var down := InputEventAction.new()
	down.action = "grab"
	down.pressed = true
	Input.parse_input_event(down)
	await _wait(hold)
	var up := InputEventAction.new()
	up.action = "grab"
	up.pressed = false
	Input.parse_input_event(up)
	await _wait(0.05)


## Waits `seconds` of game time (counting while paused), then to the next sample.
func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout
	await sampled


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
	print("")
	print("Campfire smoke state check (%s), %s" % [mode, Time.get_datetime_string_from_system()])
	for r: Array in _results:
		print("  %-4s  %-78s expected %-14s got %s" % [r[3], r[0], r[1], r[2]])
	print("RESULT: %s (%d checks)" % ["all checks passed" if not _failed else "SOME CHECKS FAILED", _results.size()])
	get_tree().quit(1 if _failed else 0)
