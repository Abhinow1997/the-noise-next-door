extends SceneTree
## The effects' headless CPU price (CHANGE-BRIEF.md, "Price predictions and budget" for
## Effect A and "Price" for Effect B), in the manner of the chapter's cost script
## (Example 09; there's no copy of it in this repository). At a fixed rate it measures the
## CPU time of each frame in four cases:
##   empty     an empty scene (one bare Node): the control, the script's own floor;
##   game      the game scene (main.tscn) with both effects off;
##   effect_a  the game scene with Effect A at the most bursts the brief says can be alive
##             at once: two, a dive in and a hop straight out (short answer 3);
##   effect_b  the game scene with Effect B in its heaviest state: strength 1, burning,
##             amount_ratio 1 (all 40 puffs).
## Each case runs ROUNDS times, each time in a fresh copy of the scene, warmed up WARMUP
## frames and then sampled for SAMPLES frames; the cases take turns in each round, so a
## drift in the machine falls on all of them alike. Per case it reports the mean and the
## spread (standard deviation, min and max over frames; min and max of the rounds' means).
##
## What's measured: the wall time from one frame's process_frame to the next, which is the
## whole main-loop iteration (physics, process, the dummy renderer); `--fixed-fps` makes
## game time follow frames, so every case runs the same game time per frame (the report
## prints the process delta, which is 1/60 s only if it's on). Not the engine's monitors:
## Performance TIME_PROCESS holds the slowest frame of the last real second, so it reads
## the level's load (about 0.4 s), not a frame (seen on the first run, 8 Nov 2026).
##
## How the cases are set, without changing any game or effect file:
##   - main.tscn starts as the game opens with no arguments: under the title, the fire's
##     cycle off, so its strength stays 1 (CLAUDE.md). That's Effect B's heaviest state,
##     and steady.
##   - "Off" is this script freeing the effect's node from its own copy of the level right
##     after it's ready, before its first frame: the leaf burst's listener (leaf_bursts.gd)
##     and the smoke's driver (main.gd `campfire_smoke`, with its copy of the smoke).
##   - Effect A is triggered by emitting the bush's `hiding_changed` (hide_spot.gd), the
##     signal leaf_bursts.gd listens to; nothing else in the game connects to it, so no
##     game state changes. A dive in, then the hop out RETRIGGER frames later (the brief's
##     preview retrigger, 0.33 s), then again once both are freed; only frames with exactly
##     two bursts alive are sampled.
##   - Each sampled frame checks the case is in the state it claims (bursts alive and their
##     amount_ratio; the smoke's emitting, amount_ratio and amount; effects absent). Any
##     frame that isn't makes the run fail.
## A headless run uses a dummy renderer that runs no GPU particle process (CLAUDE.md,
## "Headless facts"): this prices the effects' CPU side only. GPU time is the Visual
## Profiler's.
## Run: bash scripts/run-test.sh cost_effects.gd 60 300
## Written by Claude Code on 8 Nov 2026.

const LEVEL := "res://main.tscn"
const LeafBursts := preload("res://scripts/leaf_bursts.gd")
const CASES := ["empty", "game", "effect_a", "effect_b"]
const ROUNDS := 5
const WARMUP := 120
const SAMPLES := 300
## Frames between the dive-in burst and the hop-out burst (0.33 s at 60 fps).
const RETRIGGER := 20
## The hop-out's ratio (leaf_bursts.gd OUT_RATIO) and the smoke's amount (the brief).
const OUT_RATIO := 0.5
const SMOKE_AMOUNT := 40

## case -> every sampled frame's wall time (ms); each round's mean.
var _wall := {}
var _round_means := {}
## The process delta seen while sampling (smallest and largest), in seconds.
var _delta_lo := INF
var _delta_hi := 0.0
## case -> frames sampled in the wrong state, and the first such reason.
var _bad := {}
var _bad_why := {}
var _last := 0


func _initialize() -> void:
	for c: String in CASES:
		_wall[c] = []
		_round_means[c] = []
		_bad[c] = 0
		_bad_why[c] = ""
	_run()


func _run() -> void:
	print("Effects' headless CPU price (tests/cost_effects.gd)")
	print("  args: %s" % [OS.get_cmdline_args()])
	print("  renderer: %s, adapter: '%s'" % [RenderingServer.get_current_rendering_method(),
		RenderingServer.get_video_adapter_name()])
	print("  physics ticks/s: %d, max_fps: %d, rounds: %d, warm-up: %d frames, samples: %d frames a case a round"
		% [Engine.physics_ticks_per_second, Engine.max_fps, ROUNDS, WARMUP, SAMPLES])
	var t0 := Time.get_ticks_msec()
	for r in ROUNDS:
		# Rotate the order each round, so no case is always first or last.
		for i in CASES.size():
			var c: String = CASES[(i + r) % CASES.size()]
			await _measure(c, r)
		print("  round %d done (%.1f s)" % [r + 1, (Time.get_ticks_msec() - t0) / 1000.0])
	_report()


func _measure(c: String, r: int) -> void:
	var scene
	var bursts: Node = null
	var bush
	if c == "empty":
		scene = Node.new()
		scene.name = "Empty"
		root.add_child(scene)
	else:
		scene = (load(LEVEL) as PackedScene).instantiate()
		root.add_child(scene)
		for child in scene.get_children():
			if child.get_script() == LeafBursts:
				bursts = child
		bush = scene.campsite.bush
		if c in ["game", "effect_b"] and bursts:
			bursts.free()
			bursts = null
		if c in ["game", "effect_a"] and scene.campfire_smoke:
			scene.campfire_smoke.free()
			scene.campfire_smoke = null
	current_scene = scene
	for i in WARMUP:
		await process_frame

	var wall: Array = _wall[c]
	var got := 0
	var sum := 0.0
	var since_in := -1
	var prev_alive := 0
	await process_frame
	_last = Time.get_ticks_usec()
	while got < SAMPLES:
		await process_frame
		var now := Time.get_ticks_usec()
		var ms := (now - _last) / 1000.0
		_last = now
		var delta := root.get_process_delta_time()
		_delta_lo = minf(_delta_lo, delta)
		_delta_hi = maxf(_delta_hi, delta)
		var take := true
		if c == "effect_a":
			# Sample this frame only if it ran with exactly two bursts alive, at both ends.
			var alive := bursts.get_child_count()
			take = alive == 2 and prev_alive == 2
			prev_alive = alive
			if take:
				_check_bursts(bursts)
			# Then drive the next event: dive in when none are left, hop out RETRIGGER later.
			if since_in < 0 and alive == 0:
				bush.hiding_changed.emit(true)
				since_in = 0
			elif since_in >= 0:
				since_in += 1
				if since_in == RETRIGGER:
					bush.hiding_changed.emit(false)
					since_in = -1
		else:
			_check_state(c, scene, bursts)
		if take:
			wall.append(ms)
			sum += ms
			got += 1
	(_round_means[c] as Array).append(sum / got)
	if paused:
		_fail(c, "the tree was left paused")
	scene.queue_free()
	await process_frame
	await process_frame


func _check_bursts(bursts: Node) -> void:
	var ratios: Array = []
	for burst in bursts.get_children():
		var r: Array = []
		for p: GPUParticles3D in burst.get_children():
			r.append(p.amount_ratio)
		ratios.append(r)
	if ratios != [[1.0, 1.0], [OUT_RATIO, OUT_RATIO]]:
		_fail("effect_a", "burst ratios %s, not [[1, 1], [0.5, 0.5]]" % [ratios])


func _check_state(c: String, scene, bursts: Node) -> void:
	if c == "empty":
		if scene.get_child_count() != 0:
			_fail(c, "the empty scene has children")
		return
	if bursts != null:
		_fail(c, "the leaf burst's listener is still in")
	if c == "game":
		if scene.campfire_smoke != null:
			_fail(c, "the smoke's driver is still in")
		return
	# effect_b: the heaviest state.
	var smoke: GPUParticles3D = scene.campfire_smoke.smoke
	var fire = scene.campsite.campfire
	if not (smoke.emitting and smoke.amount_ratio == 1.0 and smoke.amount == SMOKE_AMOUNT
			and fire.strength == 1.0):
		_fail(c, "smoke emitting %s, amount_ratio %.3f, amount %d, strength %.3f"
			% [smoke.emitting, smoke.amount_ratio, smoke.amount, fire.strength])


func _fail(c: String, why: String) -> void:
	_bad[c] += 1
	if _bad_why[c] == "":
		_bad_why[c] = why


func _stats(a: Array) -> Dictionary:
	var n := a.size()
	var mean := 0.0
	for v: float in a:
		mean += v
	mean /= n
	var sq := 0.0
	for v: float in a:
		sq += (v - mean) * (v - mean)
	var sorted := a.duplicate()
	sorted.sort()
	return {"n": n, "mean": mean, "sd": sqrt(sq / maxi(n - 1, 1)), "min": sorted[0],
		"median": sorted[n / 2], "max": sorted[n - 1]}


func _report() -> void:
	print("")
	var fixed := absf(_delta_lo - 1.0 / 60.0) < 1e-6 and absf(_delta_hi - 1.0 / 60.0) < 1e-6
	print("Process delta while sampling: %.6f - %.6f s (%s)" % [_delta_lo, _delta_hi,
		"fixed at 1/60: --fixed-fps 60 is on" if fixed else "NOT fixed at 1/60: --fixed-fps 60 is off"])
	print("Per frame, wall time (ms), all rounds' samples together:")
	print("  %-9s %6s %8s %8s %8s %8s %8s   %s" % ["case", "frames", "mean", "sd", "min",
		"median", "max", "round means min - max"])
	var s := {}
	for c: String in CASES:
		var w := _stats(_wall[c])
		var rm: Array = (_round_means[c] as Array).duplicate()
		rm.sort()
		s[c] = {"w": w, "lo": rm[0], "hi": rm[rm.size() - 1]}
		print("  %-9s %6d %8.3f %8.3f %8.3f %8.3f %8.3f   %.3f - %.3f"
			% [c, w.n, w.mean, w.sd, w.min, w.median, w.max, rm[0], rm[rm.size() - 1]])
	print("Each round's mean (ms), in round order:")
	for c: String in CASES:
		var parts: PackedStringArray = []
		for v: float in _round_means[c]:
			parts.append("%.3f" % v)
		print("  %-9s %s" % [c, "  ".join(parts)])

	print("")
	print("Differences (the second case's mean minus the first's):")
	# Same within spread: the ranges of the rounds' means overlap.
	for pair: Array in [["empty", "game", true], ["game", "effect_a", false], ["game", "effect_b", false],
			["empty", "effect_a", true], ["empty", "effect_b", true]]:
		var a: Dictionary = s[pair[0]]
		var b: Dictionary = s[pair[1]]
		var d: float = b.w.mean - a.w.mean
		var same: bool = a.lo <= b.hi and b.lo <= a.hi
		var exact: bool = is_equal_approx(a.w.mean, b.w.mean)
		var line := "  %-8s -> %-8s %+8.3f ms (%+.1f%%)  %s" % [pair[0], pair[1], d, 100.0 * d / a.w.mean,
			"SAME within the spread (rounds' means overlap)" if same else "different (rounds' means don't overlap)"]
		if pair[2] and (same or exact):
			line += "  <-- should differ: the script may be measuring itself"
		elif not pair[2] and same:
			line += "  (the brief predicts this: no GPU particle process headless)"
		print(line)
	var limiter := absf(s["empty"].w.mean - 1000.0 / 60.0) < 0.05 * 1000.0 / 60.0
	if limiter:
		print("  <-- the empty scene's frame is about 1/60 s: frames are being paced, not measured")

	print("")
	var failed := false
	for c: String in CASES:
		if _bad[c] > 0:
			failed = true
			print("FAIL %s: %d sampled frames in the wrong state (first: %s)" % [c, _bad[c], _bad_why[c]])
		else:
			print("PASS %s: every sampled frame in its stated state" % c)
	print("Done: %s" % ("FAILED" if failed else "all cases measured in their stated states"))
	quit(1 if failed else 0)
