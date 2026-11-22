extends SceneTree
## Assignment 7, Step 5 (Step 5 of its plan): the moths round the campfire through the real level
## (CHANGE-BRIEF.md, revision of 21 Nov 2026, "The extras' timings and places"; not graded).
## main.tscn at the developer menu's "fire" point (the fire burning at load, as
## tests/campfire_smoke_state_test.gd's load mode starts), the raccoon out of the way. Each
## process tick, after the moths' driver (props/moths.gd), it reads them. It checks:
##   - shown while the fire burns (camp_fire.gd burning()), on every tick of the run;
##   - each moth fluttering (`flutter`, current_animation), from its own offset, showing cells 4
##     and 5 only; each on its circle, 0.55-0.9 m out from the fire's middle and 0.85-1.5 m up,
##     and moving;
##   - doused (the fire's own douse(), as the bucket tipping does): hidden once it's out;
##   - lit again by the keeper (the fire's own add_log(), `lit`): shown again;
##   - one writer each: props/moths.gd writes no Sprite3D frame, plays and seeks only the moths'
##     AnimationPlayers, writes nothing to the fire and calls only burning() on it; only main.gd
##     adds the moths.
## A headless run draws nothing: this checks what's shown and where, not how the moths look.
## Run it from the project folder:
##   bash scripts/run-test.sh test_moths_state.gd 60
## It prints PASS or FAIL per check and quits with exit code 1 if any check fails.
## Written by Claude Code on 21 Nov 2026.

signal sampled

const DevMenu := preload("res://scripts/dev_menu.gd")
const QUIET := Vector3(20.0, 0.02, 6.5)

var level: Node
var fire: Node3D
var moths: Node3D
var _checks := 0
var _failed := 0
var _frames := 0
## Ticks where the moths' visible didn't match the fire's burning().
var _wrong := 0
var _lit := 0


func _initialize() -> void:
	DevMenu._next = "fire"
	level = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	var probe := Probe.new()
	probe.test = self
	# After the level's nodes, the moths' driver among them, so what's read is what it set.
	probe.process_priority = 100
	root.add_child(probe)
	print("Moths: the real level at the developer menu's \"fire\" point")
	_run()


class Probe extends Node:
	var test: Object

	func _process(_delta: float) -> void:
		test.call("step")


func step() -> void:
	if moths == null:
		moths = level.get("moths")
		fire = level.get("campsite").get("campfire")
		fire.connect("lit", func() -> void: _lit += 1)
	_frames += 1
	if moths.visible != bool(fire.call("burning")):
		_wrong += 1
	sampled.emit()


func _check(what: String, ok: bool, got: Variant = "") -> void:
	_checks += 1
	if not ok:
		_failed += 1
	print("%s  %s  (got %s)" % ["PASS" if ok else "FAIL", what, str(got)])


func _wait(n: int) -> void:
	for i in n:
		await sampled


func _until(cond: Callable, most: int) -> bool:
	for i in most:
		if cond.call():
			return true
		await sampled
	return cond.call()


func _run() -> void:
	await sampled
	level.get("player").call("place", QUIET)
	await _wait(10)
	_check("burning at load: the moths shown", fire.call("burning") and moths.visible,
		"burning %s, shown %s" % [fire.call("burning"), moths.visible])

	var sprites: Array = moths.find_children("*", "Sprite3D", true, false)
	var players: Array = sprites.map(func(s: Sprite3D) -> AnimationPlayer: return s.get_node("AnimationPlayer"))
	_check("four moths, each fluttering (current_animation `flutter`)",
		players.size() == 4 and players.all(func(p: AnimationPlayer) -> bool: return p.current_animation == "flutter"),
		players.map(func(p: AnimationPlayer) -> String: return p.current_animation))
	var at: Array = players.map(func(p: AnimationPlayer) -> float: return snappedf(p.current_animation_position, 0.001))
	var apart := true
	for i in at.size():
		for j in range(i + 1, at.size()):
			apart = apart and absf(at[i] - at[j]) > 0.01
	_check("not in step: each from its own offset (positions %s s)" % str(at), apart, at)

	# Their circles, over two seconds.
	var out := Vector2(INF, -INF)
	var up := Vector2(INF, -INF)
	var cells := {}
	var first: Array = sprites.map(func(s: Sprite3D) -> Vector3: return s.global_position)
	for i in 120:
		await sampled
		for s: Sprite3D in sprites:
			var d: Vector3 = s.global_position - fire.global_position
			var r := Vector2(d.x, d.z).length()
			out = Vector2(minf(out.x, r), maxf(out.y, r))
			up = Vector2(minf(up.x, d.y), maxf(up.y, d.y))
			cells[s.frame] = true
	_check("each 0.55-0.9 m out from the fire's middle (%.3f-%.3f m)" % [out.x, out.y], out.x >= 0.549 and out.y <= 0.901, out)
	_check("each 0.85-1.5 m up (%.3f-%.3f m)" % [up.x, up.y], up.x >= 0.849 and up.y <= 1.501, up)
	var moved := true
	for i in sprites.size():
		moved = moved and (sprites[i] as Sprite3D).global_position.distance_to(first[i]) > 0.01
	_check("each moving on its circle", moved, "")
	var seen := cells.keys()
	seen.sort()
	_check("showing cells 4 and 5 only (%s)" % str(seen), seen == [4, 5], seen)

	# Doused, as the bucket tipping does: hidden once it's out.
	fire.call("douse")
	var out_at := await _until(func() -> bool: return not fire.call("burning"), 1200)
	await _wait(1)
	_check("doused: the fire goes out, and the moths are hidden", out_at and not moths.visible,
		"burning %s, shown %s" % [fire.call("burning"), moths.visible])
	await _wait(30)
	_check("out: still hidden", not moths.visible, moths.visible)

	# Lit again by the keeper: shown again.
	var relit := await _until(func() -> bool: return _lit > 0, 4800)
	await _wait(1)
	_check("lit again by the keeper: the moths shown again", relit and moths.visible,
		"lit %d, shown %s" % [_lit, moths.visible])
	_check("on every tick of the run, shown exactly while the fire burns (%d ticks)" % _frames, _wrong == 0,
		"%d ticks wrong" % _wrong)

	# One writer each.
	var src := FileAccess.get_file_as_string("res://props/moths.gd")
	_check("moths.gd writes no Sprite3D frame", RegEx.create_from_string("\\.frame\\s*=").search(src) == null, "")
	var calls := RegEx.create_from_string("([A-Za-z_][A-Za-z0-9_]*)\\.(play|seek)\\(")
	var on := calls.search_all(src).map(func(m: RegExMatch) -> String: return m.get_string(1))
	_check("moths.gd plays and seeks only the moths' AnimationPlayers (%s)" % str(on),
		on.size() == 2 and on.all(func(w: String) -> bool: return w == "anim"), on)
	var writes := RegEx.create_from_string("fire\\.[A-Za-z_]+\\s*=[^=]").search_all(src)
	var asks: Array = RegEx.create_from_string("fire\\.call\\(\"([a-z_]+)\"").search_all(src).map(
		func(m: RegExMatch) -> String: return m.get_string(1))
	# Any method called on the fire other than through call("burning") above.
	var direct := RegEx.create_from_string("fire\\.(?!call\\()([a-z_]+)\\(").search_all(src)
	_check("moths.gd writes nothing to the fire and asks it only burning() (%s)" % str(asks),
		writes.is_empty() and direct.is_empty() and asks.all(func(a: String) -> bool: return a == "burning"), "")
	var adders: Array = []
	for f: String in DirAccess.get_files_at("res://scripts"):
		if f.ends_with(".gd") and not f.ends_with("_test.gd") and FileAccess.get_file_as_string("res://scripts/" + f).contains("moths.tscn"):
			adders.append(f)
	_check("only main.gd adds the moths", adders == ["main.gd"], adders)

	print("RESULT: %s (%d checks, %d failed)" % ["FAILED" if _failed > 0 else "all checks passed", _checks, _failed])
	quit(1 if _failed > 0 else 0)
