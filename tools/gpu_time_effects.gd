extends SceneTree
## Assignment 6, the GPU price (8 Nov 2026, Claude Code): GPU render time per frame from the GPU's own timer
## (RenderingServer.viewport_get_measured_render_time_gpu), windowed at 1280 x 720, the
## raccoon between the bush and the fire so both effects are on screen. States in rounds,
## each followed by "off", so drift (clocks, warm-up) averages out:
##   off  no bursts, the smoke hidden and not emitting (its puffs gone);
##   a    Effect A at its peak: a dive-in burst and a hop-out 0.33 s later, frames with
##        two alive counted;
##   b    Effect B at its heaviest: the fire burning, smoke shown, amount_ratio ~1.
## It needs a real GPU, so it runs windowed, not through scripts/run-test.sh. From the repo root:
##   ../Godot/Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720
##     --script res://tools/gpu_time_effects.gd -- --dev-start=fire
## It reads the same GPU timer the Visual Profiler shows, per frame, but it is not the Visual
## Profiler. It writes no game state beyond the measurement setup (placing the raccoon, the
## cones off, the bursts sent, the smoke shown or hidden).
const SAMPLES := 200
const ROUNDS := 3
const SETTLE := 240
var _lvl: Node
var _rid: RID
var _frame := 0
var _plan: Array = []
var _i := 0
var _count := 0
var _settle := 0
var _t := 0.0
var _bursts: Node
var _vals := {"off": [], "a": [], "b": []}
var _round_means := {"off": [], "a": [], "b": []}
var _cur: Array = []

func _initialize() -> void:
	for r in ROUNDS:
		_plan.append_array(["off", "a", "off", "b"])
	_plan.append("off")
	_lvl = load("res://main.tscn").instantiate()
	root.add_child(_lvl)

func _set_state(s: String) -> void:
	var smoke_root: Node3D = _lvl.campfire_smoke.root
	var smoke: GPUParticles3D = _lvl.campfire_smoke.smoke
	smoke_root.visible = s == "b"
	_lvl.campfire_smoke.set_process(s == "b")
	smoke.emitting = s == "b"
	_t = 0.0

func _process(d: float) -> bool:
	_frame += 1
	_t += d
	if _frame == 2:
		_rid = root.get_viewport().get_viewport_rid()
		RenderingServer.viewport_set_measure_render_time(_rid, true)
		_lvl.campsite.cones_on = false
		var bush: Vector3 = _lvl.campsite.bush.global_position
		var fire: Vector3 = _lvl.campsite.campfire.global_position
		_lvl.player.place(bush.lerp(fire, 0.5) + Vector3(0, 0.02, 1.0))
		for c in _lvl.get_children():
			if c.get_script() and str(c.get_script().resource_path).ends_with("leaf_bursts.gd"):
				_bursts = c
		print("adapter: ", RenderingServer.get_video_adapter_name())
		_set_state(_plan[0])
	if _frame < 3:
		return false
	var s: String = _plan[_i]
	if s == "a":
		var phase := fmod(_t, 1.0)
		if phase < d:
			_lvl.campsite.bush.hiding_changed.emit(true)
		elif phase >= 0.333 and phase - d < 0.333:
			_lvl.campsite.bush.hiding_changed.emit(false)
	if _settle < SETTLE:
		_settle += 1
		return false
	var ok := true
	if s == "a":
		ok = _bursts.get_child_count() >= 2
	if ok:
		var gpu := RenderingServer.viewport_get_measured_render_time_gpu(_rid)
		_vals[s].append(gpu)
		_cur.append(gpu)
		_count += 1
	if _count >= SAMPLES:
		var m := 0.0
		for x in _cur: m += x
		_round_means[s].append(m / _cur.size())
		_cur = []
		_count = 0
		_settle = 0
		_i += 1
		if _i >= _plan.size():
			_report()
			return true
		_set_state(_plan[_i])
	return _frame > 40000

func _report() -> void:
	print("GPU render time per frame (ms), windowed 1280x720, %d frames a block:" % SAMPLES)
	for k in ["off", "a", "b"]:
		var v: Array = _vals[k].duplicate()
		v.sort()
		var mean := 0.0
		for x in v: mean += x
		mean /= v.size()
		var rm: Array = _round_means[k].map(func(x): return "%.3f" % x)
		print("  %-4s blocks %d  mean %.3f  median %.3f  p95 %.3f  block means %s" % [k, _round_means[k].size(), mean, v[v.size() / 2], v[int(v.size() * 0.95)], ", ".join(rm)])
