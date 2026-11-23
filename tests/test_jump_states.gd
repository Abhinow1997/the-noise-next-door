extends SceneTree
## Assignment 7, Step 5 (Step 2 of its plan): the structure and state test for the raccoon's
## jump (CHANGE-BRIEF.md, "The state machine" and its revisions of 21 Nov 2026, "F while asleep
## or climbing" and "the jump plays as it did before, in three phases of its own"; "The evidence
## split": the state-machine row and the one-authority row; predicted failure 4).
## Since that last revision: no crouch (he takes off on the tick F is seen, and `jump` starts
## there), no bite, a 12-tick landing (LAND_TIME 0.2 s), and `jump` from frame 0 off a tree.
##
## Structure, against the resource and the source:
##   - every clip raccoon_model.gd can ask for (RM.CLIPS) is in the rig's
##     AnimationPlayer, and every clip it actually asked for in this run is one of them;
##   - one authority: in raccoon_model.gd every play(), seek() and speed_scale is on `_anim`,
##     the rig's player; no other script reaches `_anim`; player.gd has no AnimationPlayer;
##     no loop_mode =, Animation.new(), add_track() or track_insert_key() in either script
##     (other scripts' hits are printed as INFO: the dancers' are not this change's);
##   - the loops are the importer's: with the runtime loop line gone, the seven read
##     LOOP_LINEAR and the two jump clips LOOP_NONE in the game, and idle, walk, run and sneak
##     each wrap back to their start and play on (sneaking on the spot holds his pose, so he
##     sneaks forward). This reads the cache as it is; the empty-cache read-back is the
##     author's, in a separate worktree.
## State, in the real level (main.tscn at the developer menu's "free" point, as
## tests/jump_pins.gd runs it), through the game loop and real key presses
## (Input.parse_input_event), reading the rig's AnimationPlayer.current_animation each
## physics tick after the player's:
##   - F from idle, bored, walk, run and sneak: `jump`, then `jump_land` on `landed`, then
##     the clip for how he's moving, 12 ticks after landing;
##   - F during `jump_land`: `jump` again, the landing cut short;
##   - F from sleep: the leap out (the run clip), exactly as W gives it (the same ticks),
##     never `jump`;
##   - F from climb: the hop off, shown as `jump` from frame 0 (its push-off), then
##     `jump_land`; no `jumping` and no `landed` in it;
##   - in every jump the leap seek doesn't run: model.leap < 0 and `jump`'s position only
##     goes forward;
##   - each of the seven looping states plays its own clip, read as current_animation where
##     the run above reaches it (the brief's revision of 21 Nov 2026, "every raccoon animation"):
##     idle standing, walk with W, run with W and Shift, sneak with Ctrl and W, bored standing
##     still past BORED_AFTER, sleep in the hollow (put there by start_asleep, as the title does;
##     no key sends him to sleep), climb on the home pine (W into its trunk); then all seven
##     together;
##   - the one-tick lag on a gait change: walking, Shift is pressed; from the physics tick his
##     speed first passes RUN_FROM (the model's input) to the tick `run` is first asked for.
## The clip follows the game by one tick (the AnimationPlayer advances on the process tick,
## after the physics tick that changed his state); that lag is measured and printed. A
## one-shot that has run out reads current_animation "" while its last pose is held; those
## ticks are counted and printed, and pass only if assigned_animation is still that clip,
## stopped at its end.
## A headless run draws nothing: this checks clip names, positions and the game's state, not
## how the jump looks. The source scan can't see an indirect call.
## Run it from the project folder:
##   bash scripts/run-test.sh test_jump_states.gd 60
## It prints PASS or FAIL per check and quits with exit code 1 if any check fails.
## Written by Claude Code on 21 Nov 2026.

signal ticked

const DevMenu := preload("res://scripts/dev_menu.gd")
## raccoon_model.gd (RaccoonModel), for its CLIPS and ONE_SHOTS.
const RM := preload("res://scripts/raccoon_model.gd")
## Well out of the camp, where none of them can see him (scripts/cones_test.gd, _send_away).
const QUIET := Vector3(20.0, 0.02, 6.5)
## LAND_TIME 0.2 s at 60 ticks a second (player.gd; the brief's phase table: landing + 0-11).
const LAND_TICKS := 12
const TOL := 0.001
const SCAN := ["res://scripts", "res://props"]

var level: Node
var player: CharacterBody3D
var model: Node3D
var anim: AnimationPlayer

var _tick := 0
var _checks := 0
var _failed := 0
var _rec: Dictionary = {}
var _requested := {}
var _landed: Array[int] = []
## Each looping state's clip as current_animation read it when the run reached that state.
var _seven := {}


func _initialize() -> void:
	DevMenu._next = "free"
	level = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	var probe := Probe.new()
	probe.test = self
	# After the player's own _physics_process each tick.
	probe.process_physics_priority = 1000
	root.add_child(probe)
	print("Jump states: the real level at the developer menu's \"free\" point, %d physics ticks a second"
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
		model = player.get("model")
		anim = model.get("_anim")
		player.connect("landed", func() -> void: _landed.append(_tick + 1))
	_rec = {
		"tick": _tick,
		"cur": String(anim.current_animation),
		"asg": String(anim.assigned_animation),
		"pos": anim.current_animation_position,
		"len": anim.current_animation_length,
		"playing": anim.is_playing(),
		"leap": float(model.get("leap")),
		"pj": bool(player.get("jumping")),
		"mj": bool(model.get("jumping")),
		"ml": bool(model.get("landing")),
		"jid": int(model.get("jump_id")),
		"resting": bool(player.get("resting")),
		"climbing": bool(player.get("climbing")),
		"spd": float(model.get("speed")),
	}
	if _rec.asg != "":
		_requested[_rec.asg] = true
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


## Waits until `cond` holds (checked each tick), up to `most` ticks; true if it did.
func _until(cond: Callable, most: int) -> bool:
	for i in most:
		if cond.call():
			return true
		await ticked
	return cond.call()


## From now, the ticks' records until the model is out of a jump (or `most` ticks).
func _watch(most := 240) -> Array[Dictionary]:
	var recs: Array[Dictionary] = []
	var seen := false
	for i in most:
		await ticked
		recs.append(_rec.duplicate())
		if _rec.mj:
			seen = true
		elif seen:
			# Two more ticks, to see the clip after it.
			await ticked
			recs.append(_rec.duplicate())
			await ticked
			recs.append(_rec.duplicate())
			break
	return recs


func _settle() -> void:
	_key(KEY_F, false)
	for k in [KEY_W, KEY_SHIFT, KEY_CTRL]:
		_key(k, false)
	await _wait(5)
	player.call("place", QUIET)
	await _wait(40)


func _run() -> void:
	await ticked
	_structure()
	await _wait(30)

	# idle: stand still past idle's 4 s (it must keep looping), until bored; F from both.
	await _settle()
	await _from_idle_and_bored()

	# walk, run, sneak: hold the keys past each clip's length (they must keep looping), then F.
	await _settle()
	# (Sneaking on the spot holds his pose, so he sneaks forward: Ctrl and W.)
	await _from_moving("walk", [KEY_W], 120)
	await _settle()
	await _from_moving("run", [KEY_W, KEY_SHIFT], 120)
	await _settle()
	await _from_moving("sneak", [KEY_CTRL, KEY_W], 360)

	# The two clocks on a gait change: walk, then Shift.
	await _settle()
	await _walk_to_run()

	# F during the landing.
	await _settle()
	await _f_in_landing()

	# F asleep, then W asleep for comparison.
	await _settle()
	var by_f := await _wake_with(KEY_F)
	await _settle()
	var by_w := await _wake_with(KEY_W)
	_check("asleep: F wakes him into the same leap out as W, on the same ticks (F: %s, W: %s)" % [by_f, by_w],
		by_f.size() == 2 and by_f == by_w, "F %s, W %s" % [by_f, by_w])

	# F up a tree.
	await _settle()
	await _from_climb()

	# The seven looping states, each as current_animation read it where the run reached it.
	var wrong_states: Array = []
	for clip: String in ["idle", "walk", "run", "sneak", "bored", "sleep", "climb"]:
		if _seven.get(clip, "(not reached)") != clip:
			wrong_states.append("%s: %s" % [clip, _seven.get(clip, "(not reached)")])
	_check("each of the seven looping states plays its own clip (%s)" % _seven, wrong_states.is_empty(), wrong_states)

	# Every clip asked for in this run is one the code names.
	var stray: Array = []
	for clip: String in _requested:
		if clip not in RM.CLIPS:
			stray.append(clip)
	_check("every clip asked for in this run is in RM.CLIPS (%s)" % ", ".join(_requested.keys()),
		stray.is_empty(), stray)
	print("landed on ticks: ", _landed)
	print("RESULT: %s (%d checks, %d failed)" % ["FAILED" if _failed > 0 else "all checks passed", _checks, _failed])
	quit(1 if _failed > 0 else 0)


# --- Structure -------------------------------------------------------------------

func _structure() -> void:
	var missing: Array = []
	for clip: String in RM.CLIPS:
		if not anim.has_animation(clip):
			missing.append(clip)
	_check("every clip in RM.CLIPS (%s) is in the rig's AnimationPlayer" % ", ".join(RM.CLIPS),
		missing.is_empty(), "missing %s" % [missing])
	for clip: String in ["idle", "walk", "run", "sneak", "bored", "sleep", "climb"]:
		_check("%s: loop_mode LOOP_LINEAR as the game has it" % clip,
			anim.get_animation(clip).loop_mode == Animation.LOOP_LINEAR, anim.get_animation(clip).loop_mode)
	for clip: String in ["jump", "jump_land"]:
		_check("%s: loop_mode LOOP_NONE as the game has it" % clip,
			anim.get_animation(clip).loop_mode == Animation.LOOP_NONE, anim.get_animation(clip).loop_mode)

	var files := {}
	for dir: String in SCAN:
		for f: String in DirAccess.get_files_at(dir):
			if f.ends_with(".gd"):
				files[dir + "/" + f] = FileAccess.get_file_as_string(dir + "/" + f)
	var model_src: String = files.get("res://scripts/raccoon_model.gd", "")
	var player_src: String = files.get("res://scripts/player.gd", "")
	var calls := RegEx.create_from_string("([A-Za-z_][A-Za-z0-9_]*)\\.(play|seek)\\(|([A-Za-z_][A-Za-z0-9_]*)\\.speed_scale\\s*=")
	var off: Array = []
	var on_anim := 0
	for m in calls.search_all(model_src):
		var who := m.get_string(1) if m.get_string(1) != "" else m.get_string(3)
		if who == "_anim":
			on_anim += 1
		else:
			off.append(m.get_string(0))
	_check("raccoon_model.gd: every play(), seek() and speed_scale is on _anim, the rig's player (%d)" % on_anim,
		off.is_empty() and on_anim > 0, off)
	var reach: Array = []
	for path: String in files:
		if path != "res://scripts/raccoon_model.gd" and (files[path].contains("._anim") or files[path].contains("\"_anim\"")):
			reach.append(path)
	_check("no other game script reaches the rig's player (_anim)", reach.is_empty(), reach)
	_check("player.gd has no AnimationPlayer and no _anim (it writes the model's inputs only)",
		not player_src.contains("AnimationPlayer") and not player_src.contains("_anim"), "")
	var built := RegEx.create_from_string("loop_mode\\s*=[^=]|Animation\\.new\\(|add_track\\(|track_insert_key\\(")
	for path: String in ["res://scripts/raccoon_model.gd", "res://scripts/player.gd"]:
		var hits: Array = []
		for m in built.search_all(files.get(path, "")):
			hits.append(m.get_string(0).strip_edges())
		_check("%s: no loop_mode =, Animation.new(), add_track() or track_insert_key()" % path.get_file(), hits.is_empty(), hits)
	for path: String in files:
		if path.ends_with("raccoon_model.gd") or path.ends_with("player.gd") or path.ends_with("_test.gd"):
			continue
		var lines: PackedStringArray = files[path].split("\n")
		for i in lines.size():
			if built.search(lines[i]) != null and not lines[i].contains("AudioStream"):
				print("INFO  %s:%d builds or loops a clip in code (not this change's): %s" % [path, i + 1, lines[i].strip_edges()])


# --- One jump's ticks ------------------------------------------------------------

## Checks one jump (or hop off a tree) from its records: `jump` from the tick after it starts
## to the landing, from its frame 0, `jump_land` for the landing's 12 ticks, then `after`.
func _check_jump(label: String, recs: Array[Dictionary], after: String) -> Dictionary:
	var t0 := -1
	var land := -1
	var out := -1
	for i in recs.size():
		if t0 < 0 and recs[i].mj:
			t0 = i
		if t0 >= 0 and land < 0 and recs[i].ml:
			land = i
		if land >= 0 and out < 0 and not recs[i].mj:
			out = i
	if t0 < 0 or land < 0 or out < 0:
		_check("%s: starts, lands and ends" % label, false, "start %d, landing %d, end %d" % [t0, land, out])
		return {}
	var start_tick: int = recs[t0].tick
	_check("%s: the landing lasts %d ticks (landing on tick %d after the start)" % [label, LAND_TICKS, land - t0],
		out - land == LAND_TICKS, out - land)

	# The two clocks: the clip changes on the process tick after the physics tick.
	var first_jump := -1
	for i in range(t0, recs.size()):
		if recs[i].asg == "jump" and recs[i].jid == recs[t0].jid:
			first_jump = i
			break
	_check("%s: `jump` is asked for one tick after the game starts it (the two clocks)" % label,
		first_jump - t0 == 1, "%d tick(s)" % (first_jump - t0))

	var wrong: Array = []
	var held := 0
	for i in range(t0 + 1, land + 1):
		var r: Dictionary = recs[i]
		if r.cur == "jump":
			continue
		if r.cur == "" and r.asg == "jump" and not r.playing and absf(r.pos - r.len) < TOL:
			held += 1
			continue
		wrong.append("%d:%s/%s" % [r.tick - start_tick, r.cur, r.asg])
	_check("%s: current_animation is `jump` on every tick from the one after the start to the landing (%d ticks; %d read \"\" with `jump` held at its end)"
		% [label, land - t0, held], wrong.is_empty(), wrong)
	wrong.clear()
	var land_held := 0
	for i in range(land + 1, out + 1):
		var r: Dictionary = recs[i]
		if r.cur == "jump_land":
			continue
		if r.cur == "" and r.asg == "jump_land" and not r.playing and absf(r.pos - r.len) < TOL:
			land_held += 1
			continue
		wrong.append("%d:%s/%s" % [r.tick - start_tick, r.cur, r.asg])
	_check("%s: current_animation is `jump_land` on every tick of the landing, one tick late (%d ticks; %d read \"\" at its end)"
		% [label, out - land, land_held], wrong.is_empty(), wrong)
	var next: String = recs[out + 1].cur if out + 1 < recs.size() else "?"
	_check("%s: then `%s`, the tick after the landing ends" % [label, after], next == after, next)

	# The leap seek kept out: no leap set, and `jump` only goes forward.
	var leaps := 0
	var back := 0
	for i in range(t0, out + 1):
		if recs[i].leap >= 0.0:
			leaps += 1
		if i > t0 and recs[i].asg == "jump" and recs[i - 1].asg == "jump" and recs[i].pos < recs[i - 1].pos - TOL:
			back += 1
	_check("%s: the leap seek doesn't run (model.leap < 0 on every tick; `jump`'s position never goes back)" % label,
		leaps == 0 and back == 0, "%d ticks with leap, %d steps back" % [leaps, back])

	# From frame 0, its push-off (a jump and a hop off a tree alike), then advanced by that
	# process tick (at most 1/60 s).
	var p: float = recs[first_jump].pos
	_check("%s: `jump` starts from frame 0, its push-off (position %.4f s on its first tick)" % [label, p],
		p <= 1.0 / 60.0 + TOL, p)
	return {"t0": t0, "land": land, "out": out}


func _press_and_watch(keys_held: Array) -> Array[Dictionary]:
	for k in keys_held:
		_key(k, true)
	_key(KEY_F, true)
	var recs := await _watch()
	_key(KEY_F, false)
	return recs


# --- The states ------------------------------------------------------------------

## Waits up to `most` ticks for `clip` to wrap: its position drops back to its start while
## it's still that clip, playing. Returns "" if it did, or what happened instead.
func _wraps(clip: String, most: int) -> String:
	var prev := -1.0
	for i in most:
		await ticked
		if _rec.cur != clip:
			if _rec.asg == clip:
				return "current_animation \"\" at %.3f s: it ran out (LOOP_NONE)" % _rec.pos
			return "left %s for %s before it wrapped" % [clip, _rec.asg]
		if prev >= 0.0 and _rec.pos < prev - 0.05:
			return ""
		prev = _rec.pos
	return "no wrap in %.2f s" % (most / 60.0)


## One of the seven looping states, reached through real input: current_animation is its own
## clip. Kept for the summary check at the end.
func _state_plays(clip: String, how: String) -> void:
	_seven[clip] = _rec.cur
	_check("the %s state (%s): current_animation is `%s`" % [clip, how, clip], _rec.cur == clip, _rec.cur)


func _from_idle_and_bored() -> void:
	await _until(func() -> bool: return _rec.cur == "idle", 120)
	_state_plays("idle", "standing, no key held")
	var idle_len: float = anim.get_animation("idle").length
	var why := await _wraps("idle", 600)
	_check("idle loops: standing still, it wraps past its %.1f s and plays on" % idle_len, why == "", why)
	await _until(func() -> bool: return _rec.asg == "bored", 600)
	_check("standing still: bored after BORED_AFTER", _rec.asg == "bored", _rec.asg)
	_state_plays("bored", "standing still past BORED_AFTER %.0f s" % RM.BORED_AFTER)
	var recs := await _press_and_watch([])
	_check_jump("F from bored", recs, "idle")
	await _wait(20)
	_check("standing still again: idle", _rec.cur == "idle", _rec.cur)
	recs = await _press_and_watch([])
	_check_jump("F from idle", recs, "idle")


func _from_moving(clip: String, keys: Array, most: int) -> void:
	for k in keys:
		_key(k, true)
	await _until(func() -> bool: return _rec.cur == clip, 120)
	_state_plays(clip, "holding %s" % " and ".join(keys.map(func(k: int) -> String: return OS.get_keycode_string(k))))
	var length: float = anim.get_animation(clip).length
	var why := await _wraps(clip, most)
	_check("%s loops: held, it wraps past its %.3f s and plays on" % [clip, length], why == "", why)
	var recs := await _press_and_watch([])
	_check_jump("F from %s" % clip, recs, clip)
	for k in keys:
		_key(k, false)


## The two clocks on a gait change, as _check_jump measures them for the jump: walking (W),
## Shift is pressed; the model's input (speed past RUN_FROM) changes on a physics tick, and
## `run` is asked for on the process tick after it.
func _walk_to_run() -> void:
	_key(KEY_W, true)
	await _until(func() -> bool: return _rec.cur == "walk", 120)
	await _wait(30)
	var walking: bool = _rec.cur == "walk"
	_key(KEY_SHIFT, true)
	var fast := -1
	var asked := -1
	for i in 120:
		await ticked
		if fast < 0 and _rec.spd > RM.RUN_FROM:
			fast = _tick
		if asked < 0 and _rec.asg == "run":
			asked = _tick
			break
	_key(KEY_SHIFT, false)
	_key(KEY_W, false)
	var lag := asked - fast
	print("walk to run: speed past RUN_FROM %.2f m/s on tick %d, `run` asked for on tick %d: %d tick(s), %.4f s"
		% [RM.RUN_FROM, fast, asked, lag, lag / float(Engine.physics_ticks_per_second)])
	_check("walk to run (Shift while walking): `run` is asked for one tick after his speed passes RUN_FROM (the two clocks, %.4f s)"
		% (1.0 / Engine.physics_ticks_per_second), walking and fast > 0 and asked > 0 and lag == 1,
		"walking %s, %d tick(s)" % [walking, lag])


func _f_in_landing() -> void:
	await _until(func() -> bool: return _rec.cur == "idle", 120)
	_key(KEY_F, true)
	await _until(func() -> bool: return _rec.ml, 120)
	_key(KEY_F, false)
	var landed_tick := _tick
	var first_id: int = _rec.jid
	await _wait(2)
	# Pressed on the landing's tick 2: the game sees it on tick 3 and takes off at once.
	_key(KEY_F, true)
	var recs: Array[Dictionary] = []
	for i in 6:
		await ticked
		recs.append(_rec.duplicate())
	var cut := -1
	var asked := -1
	for r: Dictionary in recs:
		if cut < 0 and r.pj and not r.ml:
			cut = r.tick - landed_tick
		if asked < 0 and r.asg == "jump" and r.jid != first_id:
			asked = r.tick - landed_tick
	_check("F in the landing: the next jump takes off at once, cutting the landing (on landing tick %d of %d)" % [cut, LAND_TICKS],
		cut > 0 and cut < LAND_TICKS, cut)
	_check("F in the landing: `jump` again from `jump_land`, a tick after the takeoff", asked == cut + 1,
		"jump on landing tick %d" % asked)
	var rest := await _watch()
	_key(KEY_F, false)
	var all: Array[Dictionary] = recs
	all.append_array(rest)
	# The second jump, from its own start.
	var start := 0
	while start < all.size() and all[start].jid == first_id:
		start += 1
	var second: Array[Dictionary] = []
	second.assign(all.slice(start))
	_check_jump("F in the landing: the next jump", second, "idle")


## Curls him up asleep in the hollow (as the title leaves him), then holds `key`: returns
## [ticks from the press to the leap's first run pose, ticks from the press to resting off].
func _wake_with(key: int) -> Array:
	var forest: Node = level.get("forest")
	player.call("start_asleep", forest.get("rest_spot"), forest.get("rest_exit"))
	player.set("keep_asleep", false)
	await _until(func() -> bool: return _rec.cur == "sleep", 120)
	await _wait(30)
	var label := "F" if key == KEY_F else "W"
	_check("asleep: sleep", _rec.cur == "sleep", _rec.cur)
	if not _seven.has("sleep"):
		# The sleep state's own check is the one above.
		_seven["sleep"] = _rec.cur
	_key(key, true)
	var pressed := _tick
	var run_at := -1
	var up_at := -1
	var jumped := false
	var one_shot := false
	for i in 600:
		await ticked
		if _rec.pj:
			jumped = true
		if _rec.asg in RM.ONE_SHOTS:
			one_shot = true
		if run_at < 0 and _rec.asg == "run" and _rec.leap >= 0.0:
			run_at = _tick - pressed
		if not _rec.resting:
			up_at = _tick - pressed
			break
	_key(key, false)
	_check("asleep, %s: he wakes and leaps out (the run clip, leap set, then out of the hollow)" % label,
		run_at > 0 and up_at > 0, "run pose at %d, out at %d" % [run_at, up_at])
	if key == KEY_F:
		_check("asleep, F: never `jump` or `jump_land`, never `jumping`", not jumped and not one_shot,
			"jumping %s, a jump clip %s" % [jumped, one_shot])
	await _wait(20)
	return [run_at, up_at] if run_at > 0 and up_at > 0 else []


func _from_climb() -> void:
	# The home pine: walk into it (W, the way the camera faces), and he climbs.
	var tree: Dictionary = {}
	for t: Dictionary in player.get("trees"):
		if t.has("rest_spot"):
			tree = t
	var cam: Camera3D = player.get("camera")
	var fwd := Vector3(0, 0, -1).rotated(Vector3.UP, cam.global_rotation.y)
	fwd.y = 0.0
	fwd = fwd.normalized()
	var base: Vector3 = tree.base
	player.call("place", Vector3(base.x, 0.02, base.z) - fwd * (float(tree.clear) + 0.3))
	await _wait(5)
	_key(KEY_W, true)
	var up := await _until(func() -> bool: return _rec.climbing, 180)
	_key(KEY_W, false)
	await _wait(40)
	_check("up the home pine (W into the trunk): climb", up and _rec.cur == "climb", "climbing %s, %s" % [up, _rec.cur])
	# The climb state's own check is the one above.
	_seven["climb"] = _rec.cur if up else "(not climbing)"
	var landed_before := _landed.size()
	var recs := await _press_and_watch([])
	_check_jump("F from climb (the hop off)", recs, "idle")
	var pj := 0
	for r: Dictionary in recs:
		if r.pj:
			pj += 1
	_check("F from climb: the hop off isn't `jumping` (the hop's game is unchanged)",
		pj == 0, "%d ticks jumping" % pj)
	_check("F from climb: no `landed` (the hop's game is unchanged)", _landed.size() == landed_before,
		_landed.size() - landed_before)
