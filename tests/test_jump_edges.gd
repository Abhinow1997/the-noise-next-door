extends SceneTree
## Assignment 7, Step 6: the jump's edge tests (CHANGE-BRIEF.md, "The evidence split": "Takeoff
## ..., a 10-tick landing" and "An interrupt in each phase does what the table says"), against
## the phase table of the brief's revision of 21 Nov 2026, "the jump plays as it did before, in
## three phases of its own". Ticks are counted from takeoff, the tick F is seen (tick 0):
##   startup, the push and rise: ticks 0-14. Let go of F to cut the height; steer at AIR_CONTROL.
##   active, the top and the fall: ticks 15-24 held. Steer; a press up to 0.12 s (JUMP_BUFFER)
##     before landing is kept (and takes off the tick after he lands).
##   recovery, the landing: landing + 0-11 (tick 25 held). A kept or new press starts the next
##     jump at once.
##
## In the real level (main.tscn at the developer menu's "free" point, as tests/jump_pins.gd
## runs it), the raccoon set down out of the campers' sight, driven only by real key presses
## through Input.parse_input_event; the jump's functions are never called. A probe reads the
## game each physics tick after the player's.
##
## First a reference: a held jump, F held to the end. Its takeoff, top, landing (L) and the
## landing's end (E = L + 12) are measured and checked against the table. Then, for each
## boundary (takeoff; the top, tick 15; L; E), an interrupt is sent so the game sees it one tick
## before the boundary, on it, and one tick after:
##   - F let go (F held from takeoff until then);
##   - F again: F let go a frame or more earlier, then pressed again (F is the jump's only key,
##     so a held F can't be pressed again without letting go first);
##   - W, a move key, from standing still.
## Cells that can't exist are skipped and printed: one tick before takeoff F isn't down yet (its
## press is the takeoff), so there's nothing to let go or press again; on the takeoff tick "F
## let go" is the press and release arriving together (the shortest tap), and "F again" is a
## shortest tap and a new press the next tick. A fifth row, the buffer's edge, presses F again
## 8, 7, 6, 5 and 4 ticks before L, round JUMP_BUFFER's 0.12 s (7.2 ticks).
## Every case is judged by the tick the game actually saw its input, against what the table
## says of the phase that tick is in:
##   - F let go in startup cuts the height: he's lower than the held jump from that tick, and
##     his peak is lower if it was still ahead; from the top on, it changes nothing (the same
##     height on every tick, the same landing);
##   - F again in startup or early in active does nothing: no takeoff, the full landing; within
##     JUMP_BUFFER before landing it's kept and takes off the tick after he lands; in the
##     landing it takes off at once, cutting the landing; after the landing's end it's an
##     ordinary jump from the ground;
##   - W steers: its first tick's gain in speed is ACCEL's on the ground and AIR_CONTROL of it
##     in the air (startup and active); in the landing it steers (its share is printed); after
##     the landing's end it's the ground's again;
##   - after each case's last landing he's back on the ground as normal.
## The clip on every tick: `jump` while he's jumping, `jump_land` while he lands, a ground clip
## after, each read as current_animation (a finished one-shot reads "" with its last pose held:
## accepted when assigned_animation is that clip and it has stopped). The clip follows the
## game's state as it was at the last physics tick before the latest process frame: that lag is
## measured for every change of state and compared with that model, and `jump` restarts from
## its push-off at each takeoff.
##
## Frame rates. Physics is 60 ticks a second at every rate (CLAUDE.md), but key events reach
## the game once a frame: they're flushed at the start of the next frame, before its physics
## ticks, and _unhandled_input runs then. So an input sent on tick T is seen on the first tick
## of the next frame. At 60 and 144 fps every tick starts a frame (144: some frames have no
## tick), so it's seen on T + 1 and every tick can be hit. At 30 fps a frame is two ticks, so
## only every other tick can see a new input: a wanted tick that's the second of its frame is
## seen a tick late. Since takeoff (an input) starts a frame, at 30 fps inputs are seen only on
## even ticks from takeoff: "one tick before takeoff" becomes two, and "on the top (15)", "on
## the landing (25)" and "on its end (37)" can't be hit; those cases are seen on 16, 26 and 38,
## each then judged for the tick it was seen on. Each input's seen tick, and whether it was the
## first tick of a frame, is printed; this test doesn't take the frame rate out (it never
## calls the game's update functions itself).
##
## A headless run draws nothing: this checks the game's state, the clip's name and position
## on each tick, not how the jump looks.
## Run it from the project folder, at each rate:
##   bash scripts/run-test.sh test_jump_edges.gd 30 300
##   bash scripts/run-test.sh test_jump_edges.gd 60 300
##   bash scripts/run-test.sh test_jump_edges.gd 144 300
## It prints PASS or FAIL per check and quits with exit code 1 if any check fails.
## Written by Claude Code on 21 Nov 2026.

signal ticked

const DevMenu := preload("res://scripts/dev_menu.gd")
## player.gd, for its JUMP_BUFFER, AIR_CONTROL and ACCEL.
const PL := preload("res://scripts/player.gd")
## Well out of the camp, where none of them can see him (scripts/cones_test.gd, _send_away).
const QUIET := Vector3(20.0, 0.02, 6.5)
## The phase table's boundaries, in ticks from takeoff, for a held jump.
const TOP := 15
const HELD_LANDS := 25
const LAND_TICKS := 12
const TOL_Y := 0.0001

var level: Node
var player: CharacterBody3D
var model: Node3D
var anim: AnimationPlayer

var _tick := 0
var _checks := 0
var _failed := 0
var _rec: Dictionary = {}
var _landed_now := false
var _ref: Dictionary = {}
## Measured clip lags (ticks -> count), and lags that didn't match the frame model.
var _lags := {}
var _lag_off: Array = []
var _table: Array[String] = []


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
	print("Jump edges: the real level at the developer menu's \"free\" point, %d physics ticks a second"
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
		player.connect("landed", func() -> void: _landed_now = true)
	_rec = {
		"tick": _tick,
		"frame": Engine.get_process_frames(),
		"y": player.global_position.y,
		"vy": player.velocity.y,
		"spd": float(player.get("_speed")),
		"floor": player.is_on_floor(),
		"pj": bool(player.get("jumping")),
		"mj": bool(model.get("jumping")),
		"ml": bool(model.get("landing")),
		"jid": int(model.get("jump_id")),
		"cur": String(anim.current_animation),
		"asg": String(anim.assigned_animation),
		"pos": anim.current_animation_position,
		"playing": anim.is_playing(),
		"leap": float(model.get("leap")),
		"f": Input.is_action_pressed("jump"),
		"w": Input.is_action_pressed("move_forward"),
		# `landed` is emitted during the player's tick, before this probe.
		"landed": _landed_now,
	}
	_landed_now = false
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


func _settle() -> void:
	_key(KEY_F, false)
	_key(KEY_W, false)
	await _wait(3)
	player.call("place", QUIET)
	await _wait(35)


# --- The run -----------------------------------------------------------------------

func _run() -> void:
	await _wait(30)
	_ref = await _case("held", 0)
	_check_reference()
	if not _ref.ok:
		_finish()
		return
	var lr: int = _ref.landings[0]
	var er: int = lr + int(_ref.land_len[0])
	var rows := [
		["takeoff (tick 0)", [["letgo", 0], ["letgo", 1], ["again", 1], ["w", -1], ["w", 0], ["w", 1]]],
		["the top (tick %d)" % TOP, _three(TOP)],
		["landing (tick %d)" % lr, _three(lr)],
		["the landing's end (tick %d)" % er, _three(er)],
		["the buffer's edge (%.1f ticks before landing)" % (PL.JUMP_BUFFER * Engine.physics_ticks_per_second),
			[["again", lr - 8], ["again", lr - 7], ["again", lr - 6], ["again", lr - 5], ["again", lr - 4]]],
	]
	print("Not sent (can't exist): F let go at tick -1 (F isn't down before its press is seen); F again at ticks -1 and 0 (the press on 0 is the takeoff)")
	for row: Array in rows:
		for c: Array in row[1]:
			var a := await _case(c[0], c[1])
			a.row = row[0]
			_judge(a)
	_finish()


func _three(b: int) -> Array:
	var out := []
	for kind: String in ["letgo", "again", "w"]:
		for d in [-1, 0, 1]:
			out.append([kind, b + d])
	return out


## One case: a held jump from standing, with one interrupt timed so the game sees it on tick
## `want` from takeoff (or as soon after as a frame lets it). Returns its analysis.
func _case(kind: String, want: int) -> Dictionary:
	await _settle()
	var recs: Array[Dictionary] = [_rec.duplicate()]
	var jid0: int = _rec.jid
	var tap_start := (kind == "letgo" and want == 0) or (kind == "again" and want == 1)
	if kind == "w" and want < 0:
		# W first; F on the tick the game has seen W, so F is seen a frame later.
		_key(KEY_W, true)
		for i in 10:
			await ticked
			recs.append(_rec.duplicate())
			if _rec.w:
				break
	elif kind == "w" and want == 0:
		_key(KEY_W, true)
	_key(KEY_F, true)
	if tap_start:
		_key(KEY_F, false)
	# [tick from takeoff to send it on, key, pressed]: sent on want - 1, so seen on want.
	var plan: Array = []
	match kind:
		"letgo":
			if want >= 1:
				plan.append([want - 1, KEY_F, false])
		"again":
			if want == 1:
				plan.append([0, KEY_F, true])
			else:
				# Let go two ticks earlier: always an earlier frame, at every rate.
				plan.append([want - 3, KEY_F, false])
				plan.append([want - 1, KEY_F, true])
		"w":
			if want >= 1:
				plan.append([want - 1, KEY_W, true])
	var last_sent := 0
	for p: Array in plan:
		last_sent = maxi(last_sent, p[0])
	var t0i := -1
	var quiet := 0
	for i in 400:
		await ticked
		recs.append(_rec.duplicate())
		var idx := recs.size() - 1
		if t0i < 0 and _rec.jid != jid0:
			t0i = idx
		if t0i < 0:
			if i > 30:
				break
			continue
		var rel := idx - t0i
		for p: Array in plan:
			if p[0] == rel:
				_key(p[1], p[2])
		quiet = quiet + 1 if not _rec.mj else 0
		if rel > last_sent + 2 and quiet >= 6:
			break
	_key(KEY_F, false)
	_key(KEY_W, false)
	return _analyse(kind, want, recs, t0i, tap_start)


func _analyse(kind: String, want: int, recs: Array[Dictionary], t0i: int, tap_start: bool) -> Dictionary:
	var a := {"kind": kind, "want": want, "recs": recs, "t0i": t0i, "ok": t0i > 0, "tap": tap_start}
	if t0i <= 0:
		return a
	var ground_y: float = recs[t0i - 1].y
	var h: Array[float] = []
	var takeoffs: Array[int] = []
	var landings: Array[int] = []
	var peak := -1.0
	var peak_rel := -1
	for i in range(t0i, recs.size()):
		var rel := i - t0i
		h.append(recs[i].y - ground_y)
		if recs[i].jid != recs[i - 1].jid:
			takeoffs.append(rel)
		if recs[i].landed:
			landings.append(rel)
		if takeoffs.size() == 1 and h[-1] > peak:
			peak = h[-1]
			peak_rel = rel
	var land_len: Array[int] = []
	for l in landings:
		var n := 0
		var i := t0i + l
		while i < recs.size() and recs[i].ml:
			n += 1
			i += 1
		land_len.append(n)
	a.h = h
	a.takeoffs = takeoffs
	a.landings = landings
	a.land_len = land_len
	a.peak = peak
	a.peak_rel = peak_rel
	# F's own press: seen on the takeoff tick (a shortest tap is never seen held).
	var f_seen := -999
	if not tap_start:
		for i in recs.size():
			if recs[i].f:
				f_seen = i - t0i
				break
	a.f_seen = f_seen
	# The interrupt: the tick the game saw it.
	var seen := -999
	match kind:
		"letgo":
			if tap_start:
				seen = 0
			else:
				for i in range(t0i + 1, recs.size()):
					if not recs[i].f:
						seen = i - t0i
						break
		"again":
			var from := t0i + 1
			if not tap_start:
				while from < recs.size() and recs[from].f:
					from += 1
			for i in range(from, recs.size()):
				if recs[i].f:
					seen = i - t0i
					break
		"w":
			for i in recs.size():
				if recs[i].w:
					seen = i - t0i
					break
	a.seen = seen
	var si := t0i + seen
	a.frame_start = si > 0 and si < recs.size() and recs[si].frame != recs[si - 1].frame
	# The input model: seen on the first tick of the first frame after the tick it was sent on.
	if kind != "held" and not (kind == "letgo" and want == 0) and not (kind == "w" and want <= 0):
		var sent := t0i + want - 1
		var model_seen := sent + 1
		while model_seen < recs.size() and recs[model_seen].frame == recs[sent].frame:
			model_seen += 1
		a.model_seen = model_seen - t0i
	else:
		a.model_seen = seen
	_clip_check(a)
	return a


# --- The clip on each tick ---------------------------------------------------------

func _expect(r: Dictionary) -> String:
	if r.ml:
		return "jump_land"
	if r.mj:
		return "jump"
	return "ground"


func _shows(r: Dictionary, exp: String) -> bool:
	if exp == "ground":
		return r.cur not in ["jump", "jump_land", ""]
	return r.cur == exp or (r.cur == "" and r.asg == exp and not r.playing)


## First index after i whose tick is in a later process frame (recs.size() if none).
func _next_frame(recs: Array[Dictionary], i: int) -> int:
	var n := i + 1
	while n < recs.size() and recs[n].frame == recs[i].frame:
		n += 1
	return n


func _clip_check(a: Dictionary) -> void:
	var recs: Array[Dictionary] = a.recs
	var t0i: int = a.t0i
	var wrong: Array = []
	var held_end := 0
	for i in range(t0i, recs.size()):
		# The state the clip should show: the last tick before the latest process frame.
		var j := i - 1
		while j >= 0 and recs[j].frame == recs[i].frame:
			j -= 1
		if j < 0:
			continue
		var exp := _expect(recs[j])
		if not _shows(recs[i], exp):
			wrong.append("%d:%s/%s (wanted %s)" % [i - t0i, recs[i].cur, recs[i].asg, exp])
		elif recs[i].cur == "":
			held_end += 1
	a.clip_wrong = wrong
	a.clip_held_end = held_end
	# The lag, measured: from each change of state to the first tick that shows it.
	for i in range(t0i, recs.size()):
		var exp := _expect(recs[i])
		if exp == _expect(recs[i - 1]):
			continue
		var n := _next_frame(recs, i)
		# Not observable if the state changed again before the next process frame.
		if n >= recs.size() or _expect(recs[n - 1]) != exp:
			continue
		var shown := -1
		for k in range(i + 1, mini(i + 8, recs.size())):
			if _shows(recs[k], exp):
				shown = k
				break
		var lag := shown - i if shown > 0 else -1
		_lags[lag] = int(_lags.get(lag, 0)) + 1
		if lag != n - i:
			_lag_off.append("%s %d, tick %d -> %s: lag %d, the frame model %d" % [a.kind, a.want, i - t0i, exp, lag, n - i])
	# `jump` restarts at each takeoff: on the first tick it shows that takeoff, its position is
	# no further than the game time since takeoff.
	var restart_bad: Array = []
	for t: int in a.takeoffs:
		var ti := t0i + t
		var n := _next_frame(recs, ti)
		if n >= recs.size() or _expect(recs[n - 1]) != "jump" or recs[n - 1].jid != recs[ti].jid:
			continue
		var since := float(n - ti) / Engine.physics_ticks_per_second
		if recs[n].asg != "jump" or recs[n].pos > since + 0.001:
			restart_bad.append("takeoff %d: %s at %.4f s, %.4f s after takeoff" % [t, recs[n].asg, recs[n].pos, since])
	a.restart_bad = restart_bad


# --- The reference held jump -------------------------------------------------------

func _check_reference() -> void:
	var r := _ref
	_check("reference held jump: he takes off", r.ok, r.get("t0i"))
	if not r.ok:
		return
	var recs: Array[Dictionary] = r.recs
	var t0i: int = r.t0i
	var frames := float(recs[-1].frame - recs[0].frame)
	var ticks := float(recs.size() - 1)
	var per_frame := {}
	var i := 1
	while i < recs.size():
		var n := _next_frame(recs, i - 1)
		var c := n - (i - 1)
		per_frame[c] = int(per_frame.get(c, 0)) + 1
		i = n + 1
	print("Rate: %.1f process frames a second, %d physics ticks a second; physics ticks per frame (with a tick): %s"
		% [frames / ticks * Engine.physics_ticks_per_second, Engine.physics_ticks_per_second, per_frame])
	_check("reference: takes off on the tick F is seen (tick 0, the brief's frame 0)", r.f_seen == 0, r.f_seen)
	var vy13: float = recs[t0i + TOP - 2].vy
	var vy14: float = recs[t0i + TOP - 1].vy
	print("reference: heights by tick: %s" % ", ".join(r.h.slice(0, 30).map(func(v: float) -> String: return "%.3f" % v)))
	print("reference: peak %.4f m on tick %d; velocity.y after tick %d %.4f, after tick %d %.4f m/s"
		% [r.peak, r.peak_rel, TOP - 2, vy13, TOP - 1, vy14])
	_check("reference: the rise ends at the top: still rising into tick %d (F matters), falling from tick %d (the active phase)"
		% [TOP - 1, TOP], vy13 > 0.0 and vy14 <= 0.0, "%.4f, %.4f" % [vy13, vy14])
	_check("reference: lands on tick %d (the brief, from the pins)" % HELD_LANDS,
		r.landings.size() >= 1 and r.landings[0] == HELD_LANDS, r.landings)
	_check("reference: the landing lasts %d ticks (LAND_TIME)" % LAND_TICKS,
		r.land_len.size() >= 1 and r.land_len[0] == LAND_TICKS, r.land_len)
	_check("reference: one takeoff, `landed` once", r.takeoffs.size() == 1 and r.landings.size() == 1,
		"%s, %s" % [r.takeoffs, r.landings])
	_check_clips("reference", r)


func _check_clips(label: String, a: Dictionary) -> void:
	_check("%s: the clip on every tick is the game's state at the last tick before the latest process frame (jump, jump_land, then the ground's; %d ticks read \"\" at a one-shot's end)"
		% [label, a.clip_held_end], a.clip_wrong.is_empty(), a.clip_wrong.slice(0, 6))
	_check("%s: `jump` restarts from its push-off at each takeoff" % label, a.restart_bad.is_empty(), a.restart_bad)


# --- Judging a case ----------------------------------------------------------------

func _phase(s: int) -> String:
	var lr: int = _ref.landings[0]
	var er: int = lr + int(_ref.land_len[0])
	if s < 0:
		return "before takeoff"
	if s < TOP:
		return "startup"
	if s < lr:
		return "active"
	if s < er:
		return "recovery"
	return "after the landing"


func _judge(a: Dictionary) -> void:
	var names := {"letgo": "F let go", "again": "F again", "w": "W"}
	var label := "%s, %s wanted on %d" % [a.row, names[a.kind], a.want]
	if not a.ok:
		_check("%s: he takes off" % label, false, "no takeoff")
		return
	var s: int = a.seen
	var ph := _phase(s)
	label += ", seen on %d (%s)" % [s, ph]
	var outcome := ""
	var recs: Array[Dictionary] = a.recs
	var t0i: int = a.t0i
	var href: Array = _ref.h
	var l0: int = a.landings[0] if a.landings.size() > 0 else -999
	var len0: int = a.land_len[0] if a.land_len.size() > 0 else -999
	_check("%s: the input is seen on the first tick of the first frame after it was sent" % label,
		s == a.model_seen and a.frame_start, "seen %d, model %d, frame start %s" % [s, a.model_seen, a.frame_start])
	if not a.tap:
		_check("%s: takes off on the tick F is seen" % label, a.f_seen == 0, a.f_seen)
	match a.kind:
		"letgo":
			if s < TOP:
				var lower := true
				for rel in range(s, mini(l0, mini(a.h.size(), href.size()))):
					if a.h[rel] > href[rel] + TOL_Y:
						lower = false
				var dropped: bool = s < href.size() and a.h[s] < href[s] - 0.001
				_check("%s: startup: letting go cuts the height (lower than the held jump from tick %d: %.4f m vs %.4f m)"
					% [label, s, a.h[s], href[s]], lower and dropped, "lower throughout %s" % lower)
				if s < _ref.peak_rel:
					_check("%s: a lower peak than the held jump (%.3f m vs %.3f m)" % [label, a.peak, _ref.peak],
						a.peak < _ref.peak - 0.001, "%.3f m" % a.peak)
				else:
					print("INFO  %s: the held jump's peak (tick %d) is already behind, so its peak can't be lower: %.4f m vs %.4f m"
						% [label, _ref.peak_rel, a.peak, _ref.peak])
				outcome = "cut: peak %.3f m, lands %d" % [a.peak, l0]
			else:
				var most := 0.0
				for rel in mini(a.h.size(), href.size()):
					most = maxf(most, absf(a.h[rel] - href[rel]))
				_check("%s: changes nothing (the held jump's height on every tick, within %.4f m; lands %d, a %d-tick landing)"
					% [label, TOL_Y, l0, len0],
					most <= TOL_Y and l0 == _ref.landings[0] and len0 == LAND_TICKS and a.takeoffs.size() == 1,
					"%.6f m off at most, lands %d, landing %d, takeoffs %s" % [most, l0, len0, a.takeoffs])
				outcome = "nothing changed (off by %.6f m at most)" % most
		"again":
			var second: int = a.takeoffs[1] if a.takeoffs.size() > 1 else -999
			if s <= l0:
				var before := float(l0 - s) / Engine.physics_ticks_per_second
				var kept := before <= PL.JUMP_BUFFER + 0.000001
				if kept:
					_check("%s: %.3f s before landing, within JUMP_BUFFER %.2f s: kept, the next jump takes off the tick after he lands (%d)"
						% [label, before, PL.JUMP_BUFFER, l0 + 1], second == l0 + 1, "takeoffs %s, landed %d" % [a.takeoffs, l0])
				else:
					_check("%s: %.3f s before landing, earlier than JUMP_BUFFER %.2f s: does nothing (no takeoff, the full %d-tick landing)"
						% [label, before, PL.JUMP_BUFFER, LAND_TICKS], a.takeoffs.size() == 1 and len0 == LAND_TICKS,
						"takeoffs %s, landing %d" % [a.takeoffs, len0])
			else:
				_check("%s: a new press in or after the landing takes off at once (tick %d), the landing %d ticks"
					% [label, s, mini(s - l0, LAND_TICKS)], second == s and len0 == mini(s - l0, LAND_TICKS),
					"takeoffs %s, landing %d" % [a.takeoffs, len0])
				# Seen after the landing's end (not on it, where the full landing is the check
				# above): he had a tick back on the ground before it.
				if s > l0 + LAND_TICKS:
					var r: Dictionary = recs[t0i + s - 1]
					_check("%s: after the landing's end he was back on the ground as normal before it" % label,
						not r.mj and not r.ml and not r.pj and r.floor, "jumping %s, landing %s" % [r.mj, r.ml])
			outcome = "takeoffs %s, landings %s, first landing %d ticks" % [a.takeoffs, a.landings, len0]
		"w":
			var gain: float = (recs[t0i + s].spd - recs[t0i + s - 1].spd) / (PL.ACCEL / Engine.physics_ticks_per_second)
			var l_end: int = l0 + len0
			if s < 0 or s >= l_end:
				_check("%s: on the ground (%s): steers with full control (its first tick's speed gain %.2f of ACCEL's)"
					% [label, ph, gain], absf(gain - 1.0) < 0.1, "%.2f" % gain)
			elif s < l0:
				_check("%s: in the air (%s): steers at AIR_CONTROL %.2f (its first tick's speed gain %.2f of ACCEL's)"
					% [label, ph, PL.AIR_CONTROL, gain], absf(gain - PL.AIR_CONTROL) < 0.1, "%.2f" % gain)
			else:
				_check("%s: in the landing: steers (its first tick's speed gain %.2f of ACCEL's)" % [label, gain],
					gain > 0.2, "%.2f" % gain)
			outcome = "speed gain on tick %d: %.2f of ACCEL's" % [s, gain]
	# Every case ends with him back on the ground as normal.
	var last: Dictionary = recs[-1]
	_check("%s: `landed` once a jump, and back on the ground as normal at the end" % label,
		a.landings.size() == a.takeoffs.size() and not last.mj and not last.ml and last.floor and _shows(last, "ground"),
		"%d landed, %d takeoffs, %s" % [a.landings.size(), a.takeoffs.size(), last.cur])
	_check_clips(label, a)
	_table.append("| %s | %s | %d | %d | %s | %s | %s |" % [a.row, names[a.kind], a.want, s,
		"yes" if a.frame_start else "no", ph, outcome])


func _finish() -> void:
	print("")
	print("| boundary | input | wanted tick | seen tick | first tick of a frame | phase seen in | outcome |")
	print("|---|---|---|---|---|---|---|")
	for line in _table:
		print(line)
	print("")
	var lag_keys := _lags.keys()
	lag_keys.sort()
	var spread := []
	for k in lag_keys:
		spread.append("%d tick(s): %d" % [k, _lags[k]])
	var worst: int = lag_keys.max() if not lag_keys.is_empty() else -1
	print("The two clocks: the clip showed each change of the game's state after %s; the largest lag %d tick(s), %.4f s"
		% [", ".join(spread), worst, worst / float(Engine.physics_ticks_per_second)])
	_check("the two clocks: every lag is the ticks to the next process frame (the clip shows the state at the last tick before it)",
		_lag_off.is_empty() and not _lags.has(-1), _lag_off.slice(0, 6))
	print("RESULT: %s (%d checks, %d failed)" % ["FAILED" if _failed > 0 else "all checks passed", _checks, _failed])
	quit(1 if _failed > 0 else 0)
