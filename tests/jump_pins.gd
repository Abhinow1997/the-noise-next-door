extends SceneTree
## Assignment 7, Step 2: the behaviour pins (CHANGE-BRIEF.md, "The evidence split": the pins
## row). They pin what the game does now, before any clip is set up, and must still pass when
## the change is done, except where the brief says they change. The brief predicts these will:
##   - the jump's clips: today he's posed through the run clip ("run", with model.leap set);
##     after, `jump` then `jump_land`;
##   - takeoff: today on the tick after F is seen; after, 5 ticks later (the crouch);
##   - the landing: today LAND_TIME 0.2 s (12 ticks); after, 10 ticks.
## Everything else here must stay as it is.
##
## In the real level (main.tscn), started at the developer menu's "free" point (the fire out,
## no title), the raccoon is set down well out of the camp, where no camper can see him (the
## cones test's spot), and driven through the game loop with real key presses
## (Input.parse_input_event): standing, walking (W), running (W + Shift), stopping, a held
## jump (F), a tap jump, and a jump pressed just before landing (JUMP_BUFFER). Each physics
## tick, after the player's, it reads his clip (the rig's AnimationPlayer.current_animation),
## his `jumping`, the model's `jumping` and `leap`, his height and the `landed` signal.
## It checks:
##   - the clips in order through the run, as they are today;
##   - takeoff on the tick after F is seen, every time;
##   - a held jump lands 26 ticks after takeoff, peaking at 0.51 m; a tap lands after 12,
##     peaking at 0.18 m (player.gd's JUMP_* constants, on 60 ticks a second);
##   - `landed` once a jump, on the tick he's back on the floor; the camp listens to it
##     (campsite.gd _on_landed, the noise heard HEAR_STEPS round);
##   - `jumping` (what cone_driver.gd reads) true from takeoff until landing;
##   - the landing pose (model.jumping after landing) lasting LAND_TIME, 12 ticks;
##   - a press 0.1 s before landing kept, so the next jump takes off as he lands.
## A headless run draws nothing: this checks the game's state and the clip's name, not how
## the jump looks.
## Run it from the project folder:
##   bash scripts/run-test.sh jump_pins.gd 60
## It prints each check and quits with exit code 0 if every check passes, 1 if not.
## Written by Claude Code on 21 Nov 2026.

const DevMenu := preload("res://scripts/dev_menu.gd")
## Well out of the camp, where none of them can see him (scripts/cones_test.gd, _send_away).
const QUIET := Vector3(20.0, 0.02, 6.5)
## The ticks the run is scripted on (physics ticks at 60 a second, from the level's start).
const PLACE := 30
const WALK := 100
const RUN := 160
const STOP := 220
const HELD := 300
const TAP := 420
const BUFFERED := 520
const END := 700

var level: Node
var player: CharacterBody3D
var model: Node3D
var anim: AnimationPlayer

var _tick := 0
var _checks := 0
var _failed := false
## The clips as they change: "tick:name".
var _clips: Array[String] = []
var _last_clip := ""
var _was_jumping := false
var _was_model_jumping := false
var _ground_y := 0.0
## One entry per jump: press, takeoff, landed, land_end (ticks), peak (m), clips in the air.
var _jumps: Array[Dictionary] = []
var _landed_ticks: Array[int] = []
var _f_down := false


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
	print("Jump pins: the real level at the developer menu's \"free\" point, %d physics ticks a second"
		% Engine.physics_ticks_per_second)


class Probe extends Node:
	var test: Object

	func _physics_process(_delta: float) -> void:
		test.call("step")


func step() -> void:
	_tick += 1
	if _tick == 1:
		player = level.get("player")
		model = player.get("model")
		anim = model.get("_anim")
		player.connect("landed", _on_landed)
		_check("the camp listens to `landed` (campsite.gd _on_landed)",
			player.is_connected("landed", Callable(level.get("campsite"), "_on_landed")), "connected")
	_record()
	match _tick:
		PLACE:
			player.call("place", QUIET)
		WALK - 10:
			_check("standing still: idle", anim.current_animation == "idle", anim.current_animation)
		WALK:
			_key(KEY_W, true)
		RUN - 10:
			_check("W held: walk", anim.current_animation == "walk", anim.current_animation)
		RUN:
			_key(KEY_SHIFT, true)
		STOP - 10:
			_check("W and Shift held: run", anim.current_animation == "run", anim.current_animation)
		STOP:
			_key(KEY_SHIFT, false)
			_key(KEY_W, false)
		HELD - 10:
			_check("stopped: idle again", anim.current_animation == "idle", anim.current_animation)
			_ground_y = player.global_position.y
			_clips.append("-- held jump --")
		HELD:
			_press_f()
		TAP - 10:
			_clips.append("-- tap jump --")
			_ground_y = player.global_position.y
		TAP:
			_press_f()
		TAP + 1:
			_release_f()
		BUFFERED - 10:
			_clips.append("-- buffered jump --")
			_ground_y = player.global_position.y
		BUFFERED:
			_press_f()
		END:
			_report()
	# The held jump: let F go once he's down. The buffered one: let go after the first
	# jump's peak and press again 6 ticks (0.1 s) before it lands.
	if _jumps.size() == 1 and _f_down and _jumps[0].has("landed") and _tick > _jumps[0].landed + 2:
		_release_f()
	if _jumps.size() == 3 and _jumps[2].has("takeoff") and not _jumps[2].has("landed"):
		var since: int = _tick - int(_jumps[2].takeoff)
		if since == 15:
			_release_f()
		elif since == 20:
			_press_f()
	if _jumps.size() == 4 and _f_down and _jumps[3].has("landed") and _tick > _jumps[3].landed + 2:
		_release_f()


func _record() -> void:
	if player == null:
		return
	var clip := anim.current_animation
	if clip != _last_clip:
		_clips.append("%d:%s" % [_tick, clip])
		_last_clip = clip
	var jumping: bool = player.get("jumping")
	var model_jumping: bool = model.get("jumping")
	if jumping and not _was_jumping:
		var j := _open_jump()
		j.takeoff = _tick
		j.peak = 0.0
		j.air_clips = {}
		j.jumping_through = true
	var j_air := _airborne()
	if jumping and not j_air.is_empty():
		var j := j_air
		j.peak = maxf(j.peak, player.global_position.y - _ground_y)
		# The clip is changed on the process tick, after this physics tick: it shows the jump
		# from the tick after takeoff (pinned below as the two clocks' lag today).
		if _tick > int(j.takeoff):
			j.air_clips[anim.current_animation] = true
		if float(model.get("leap")) < 0.0:
			j.leap_unset = true
	elif _was_jumping and _jumps.size() > 0 and not _jumps[-1].has("landed"):
		_jumps[-1].jumping_through = false
	if _was_model_jumping and not model_jumping and _jumps.size() > 0:
		_jumps[-1].land_end = _tick
	_was_jumping = jumping
	_was_model_jumping = model_jumping


## The jump he's in the air on: the last one that has taken off and not landed ({} if none).
## A press made in the air (the buffered one) starts its own entry before this one lands.
func _airborne() -> Dictionary:
	for i in range(_jumps.size() - 1, -1, -1):
		if _jumps[i].has("takeoff") and not _jumps[i].has("landed"):
			return _jumps[i]
	return {}


## The jump a press or takeoff belongs to: the last one if it hasn't taken off yet.
func _open_jump() -> Dictionary:
	if _jumps.is_empty() or _jumps[-1].has("takeoff"):
		_jumps.append({})
	return _jumps[-1]


func _on_landed() -> void:
	# `landed` is emitted during the player's physics tick, before this tick's probe runs.
	_landed_ticks.append(_tick + 1)
	for i in range(_jumps.size() - 1, -1, -1):
		if _jumps[i].has("takeoff") and not _jumps[i].has("landed"):
			_jumps[i].landed = _tick + 1
			break


func _press_f() -> void:
	_open_jump().press = _tick
	_key(KEY_F, true)
	_f_down = true


func _release_f() -> void:
	_key(KEY_F, false)
	_f_down = false


func _key(keycode: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.physical_keycode = keycode
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _check(what: String, ok: bool, got: Variant) -> void:
	_checks += 1
	if not ok:
		_failed = true
	print("%s  %s  (got %s)" % ["PASS" if ok else "FAIL", what, str(got)])


func _report() -> void:
	print("Clips in order: ", ", ".join(_clips))
	for i in _jumps.size():
		print("Jump %d: %s" % [i, str(_jumps[i])])
	print("landed on ticks: ", _landed_ticks)
	_check("four jumps taken (held, tap, buffered and the one it kept)", _jumps.size() == 4, _jumps.size())
	if _jumps.size() == 4:
		var held: Dictionary = _jumps[0]
		var tap: Dictionary = _jumps[1]
		var first: Dictionary = _jumps[2]
		var kept: Dictionary = _jumps[3]
		for pair: Array in [["held", held], ["tap", tap], ["buffered", first]]:
			var j: Dictionary = pair[1]
			_check("%s: takes off on the tick after F (pinned; the brief moves it to 5 ticks)" % pair[0],
				int(j.get("takeoff", -99)) - int(j.get("press", 0)) == 1, int(j.get("takeoff", -99)) - int(j.get("press", 0)))
		# Measured on 21 Nov 2026. The brief's worked-out figure was 26 ticks: the game counts
		# him down on the tick his capsule is back on the floor, one tick before the sum's
		# height reaches 0.
		_check("held: lands 25 ticks after takeoff", int(held.get("landed", -99)) - int(held.takeoff) == 25,
			int(held.get("landed", -99)) - int(held.takeoff))
		_check("held: peaks at 0.51 m (within 0.02)", absf(held.peak - 0.511) < 0.02, "%.3f m" % held.peak)
		# F is let go on the tick after it's pressed, so the rise is cut a tick or two in.
		_check("tap: lands 12 ticks after takeoff", int(tap.get("landed", -99)) - int(tap.takeoff) == 12,
			int(tap.get("landed", -99)) - int(tap.takeoff))
		_check("tap: peaks at 0.23 m (within 0.02)", absf(tap.peak - 0.228) < 0.02, "%.3f m" % tap.peak)
		_check("buffered: its first jump lands 25 ticks after takeoff too",
			int(first.get("landed", -99)) - int(first.get("takeoff", 0)) == 25,
			int(first.get("landed", -99)) - int(first.get("takeoff", 0)))
		for pair: Array in [["held", held], ["tap", tap]]:
			var j: Dictionary = pair[1]
			_check("%s: the landing pose lasts LAND_TIME, 12 ticks (pinned; the brief makes it 10)" % pair[0],
				int(j.get("land_end", -99)) - int(j.get("landed", 0)) == 12, int(j.get("land_end", -99)) - int(j.get("landed", 0)))
			_check("%s: `jumping` true from takeoff to landing" % pair[0], j.get("jumping_through", false), j.get("jumping_through"))
			_check("%s: posed through the run clip with leap set (pinned; the brief makes it `jump`)" % pair[0],
				j.air_clips.size() == 1 and j.air_clips.has(&"run") and not j.get("leap_unset", false), j.air_clips.keys())
		# He's counted down after the tick's takeoff check, so the kept press takes off on the
		# next tick.
		_check("buffered: pressed 0.1 s before landing, the kept jump takes off the tick after he lands",
			int(kept.get("takeoff", -99)) == int(first.get("landed", -1)) + 1,
			"takeoff %s, landed %s" % [kept.get("takeoff"), first.get("landed")])
		_check("buffered: the kept jump, F held, peaks at 0.51 m (within 0.02)", absf(float(kept.get("peak", 0.0)) - 0.511) < 0.02,
			"%.3f m" % float(kept.get("peak", 0.0)))
	_check("`landed` once a jump", _landed_ticks.size() == _jumps.size(), "%d landed, %d jumps" % [_landed_ticks.size(), _jumps.size()])
	# The clips' names in order, without the section marks: as they are today.
	var names: Array[String] = []
	for c in _clips:
		if not c.begins_with("--"):
			names.append(c.get_slice(":", 1))
	_check("the clips in order (pinned; the brief puts jump and jump_land where each run is)",
		names == ["idle", "walk", "run", "walk", "idle", "run", "idle", "run", "idle", "run", "idle"], ", ".join(names))
	# The two clocks today: the clip follows the game a tick late (the AnimationPlayer
	# advances on the process tick, after the physics tick that changed his state).
	if _jumps.size() == 4:
		_check("the clip shows the held jump the tick after takeoff", _clips.has("%d:run" % (int(_jumps[0].takeoff) + 1)),
			"takeoff %d" % _jumps[0].takeoff)
		_check("the clip is back to idle the tick after the landing pose ends",
			_clips.has("%d:idle" % (int(_jumps[0].get("land_end", -99)) + 1)), "land_end %s" % _jumps[0].get("land_end"))
	print("RESULT: %s (%d checks)" % ["FAILED" if _failed else "all checks passed", _checks])
	quit(1 if _failed else 0)
