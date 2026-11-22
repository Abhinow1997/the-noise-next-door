extends SceneTree
## The moth guiding him to the camp (props/moths.gd guide(); CHANGE-BRIEF.md, revision of 22 Nov
## 2026, "the moth guides him to the camp; the waves come in bursts"), through the real level:
## main.tscn at the developer menu's "den" point (by his tree, no title; before he's been to the
## camp, so main.gd hands the moth to him). Each process tick, after the moth's driver, it reads
## where the moth and he are. It checks:
##   - the moth is guiding from the start, and shown once he's out of the hollow;
##   - while he stands still (6 s): it stays round his head (within a metre), dips close at
##     least once, and never comes within MIN_REACH of his head;
##   - while he's walked along the way to the camp (2 m/s, put there each tick): it's ahead of him
##     on the way on every tick, and never more than LEASH (and its wobble) from him;
##   - once he's reached the camp ("Investigate the music" ticked by main.gd): it stops guiding,
##     flies to the fire, and with the fire out there (the tutorial's to come) it's hidden.
## A headless run draws nothing: this checks where the moth is, not how it looks.
## Run it from the project folder:
##   bash scripts/run-test.sh test_moth_guide.gd 60
## It prints PASS or FAIL per check and quits with exit code 1 if any check fails.
## Written by Claude Code on 22 Nov 2026.

signal sampled

const DevMenu := preload("res://scripts/dev_menu.gd")
const Forest := preload("res://scripts/forest.gd")
const Moths := preload("res://props/moths.gd")
## How fast he's walked along the way (m/s), and how long he stands still first (s).
const WALK := 2.0
const STILL := 6.0

var level: Node
var moths: Node3D
var player: Node3D
var _checks := 0
var _failed := 0
var _way := PackedVector2Array()


func _initialize() -> void:
	DevMenu._next = "den"
	level = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	var probe := Probe.new()
	probe.test = self
	# After the level's nodes, the moth's driver among them, so what's read is what it set.
	probe.process_priority = 100
	root.add_child(probe)
	print("The moth's guide: the real level at the developer menu's \"den\" point")
	_run()


class Probe extends Node:
	var test: Object

	func _process(_delta: float) -> void:
		test.call("emit_signal", "sampled")


func _check(what: String, ok: bool, got: Variant = "") -> void:
	_checks += 1
	if not ok:
		_failed += 1
	print("%s  %s  (got %s)" % ["PASS" if ok else "FAIL", what, str(got)])


func _head() -> Vector3:
	return player.global_position + Vector3.UP * Moths.HEAD


## How far along the way (m) the nearest point on it to `p` is.
func _progress(p: Vector2) -> float:
	var best := INF
	var best_s := 0.0
	var run := 0.0
	for i in _way.size() - 1:
		var a := _way[i]
		var ab := _way[i + 1] - a
		var f := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var d := p.distance_to(a + ab * f)
		if d < best:
			best = d
			best_s = run + ab.length() * f
		run += ab.length()
	return best_s


func _at_length(s: float) -> Vector2:
	var run := 0.0
	for i in _way.size() - 1:
		var seg := _way[i].distance_to(_way[i + 1])
		if run + seg >= s:
			return _way[i].lerp(_way[i + 1], (s - run) / seg)
		run += seg
	return _way[-1]


func _run() -> void:
	await sampled
	moths = level.get("moths")
	player = level.get("player")
	_way = PackedVector2Array([Moths.WAY_START])
	for p: Vector2 in Forest.TRAIL_POINTS:
		_way.append(p)
	_check("guiding from the start (before he's been to the camp)", bool(moths.call("guiding")), moths.call("guiding"))
	await sampled
	_check("out of the hollow: the moth shown", moths.visible, moths.visible)

	# Standing still by his tree. The first second it's still fluttering in.
	var near := INF
	var far := 0.0
	var t := 0.0
	while t < STILL:
		await sampled
		var dt := get_root().get_process_delta_time()
		t += dt
		if t > 1.5:
			var d := moths.global_position.distance_to(_head())
			near = minf(near, d)
			far = maxf(far, d)
	_check("still: it buzzes round his head, within a metre of it (%.2f-%.2f m)" % [near, far], far <= 1.0, far)
	_check("still: it dips close as if to land, at least once (nearest %.3f m)" % near, near < 0.3, near)
	_check("still: never within MIN_REACH (%.2f m) of his head" % Moths.MIN_REACH, near >= Moths.MIN_REACH - 0.001, near)

	# Walked along the way to the camp.
	var s := 0.0
	var behind := 0
	var ahead := 0
	var most := 0.0
	var walked_ticks := 0
	while bool(moths.call("guiding")) and walked_ticks < 60 * 60:
		await sampled
		walked_ticks += 1
		s += WALK * get_root().get_process_delta_time()
		var p := _at_length(s)
		player.global_position = Vector3(p.x, player.global_position.y, p.y)
		if s > 3.0:
			var m := moths.global_position
			if _progress(Vector2(m.x, m.z)) > _progress(p):
				ahead += 1
			else:
				behind += 1
			most = maxf(most, Vector2(m.x, m.z).distance_to(p))
	_check("walking: ahead of him on the way on every tick (%d ahead, %d behind)" % [ahead, behind], behind == 0 and ahead > 0,
		behind)
	_check("walking: never more than LEASH (%.1f m) from him (at most %.2f m)" % [Moths.LEASH, most], most <= Moths.LEASH + 0.2, most)

	# At the camp.
	var tasks: Object = level.get("tasks")
	_check("at the camp (%.1f m along): Investigate the music ticked, and it stops guiding" % s,
		tasks.call("is_done", "investigate") and not bool(moths.call("guiding")), tasks.call("is_done", "investigate"))
	var fire: Node3D = level.get("campsite").get("campfire")
	for i in 600:
		await sampled
	_check("then off to the fire: with the fire out, it's hidden", not fire.call("burning") and not moths.visible,
		"burning %s, shown %s" % [fire.call("burning"), moths.visible])

	print("RESULT: %s (%d checks, %d failed)" % ["FAILED" if _failed > 0 else "all checks passed", _checks, _failed])
	quit(1 if _failed > 0 else 0)
