extends Node
## The headless check of the cones' shader (shaders/vision_cone.gdshader, the author's)
## and what drives it (scripts/cone_driver.gd), against CHANGE-BRIEF.md's Assignment 5
## rules and their 28 and 29 Oct revisions. Made on 29 Oct 2026. Run it through the
## course's wrapper, at 30, 60 and 144 fps:
##   bash scripts/run-test.sh --cone-shader-test 60
## It plays the real game: the tutorial at the camp with Tab, the campers spotting him
## with their own sight (he's only put where they can see him, with player.place(), as
## cones_test.gd does), Esc to pause. It never calls spot() or the driver. A node with a
## high process_priority reads every cone's `alarm` and `shown` once a frame, after every
## other _process(); the checks run on that record at the end.
## The staged spottings, in order:
##   1. the camper spots him (as --cones-test);
##   2. within 0.25 s, before he can catch the camper's fright, the low-poly man spots
##      him too: a re-spotting during the red. Then he's gone ("lost early");
##   3. in front of a camper who's alarmed, during the red: nothing may change;
##   4. Esc mid-fade, then Esc again;
##   5. in front of someone still alarmed, the cones hidden: they stay hidden;
##   6. at time_scale 0.5, the first camper to be confused (SEARCH) spots him while the
##      cones are hidden;
##   7. 2.1 s later, during that fade, someone else confused, walking back, wondering or
##      fixing (so not one to catch a fright) does;
##   8. the cones come back, each fading in over FADE_OUT;
##   9. at time_scale 2.0, a camper at work spots him.
## A case it can't stage through play is reported as NOT STAGED, and fails the run.
## What it can't show: anything on screen. See TEST-REPORT.md for the checks by eye.

const CampPerson := preload("res://scripts/camp_person.gd")
const VisionCone := preload("res://scripts/vision_cone.gd")
const CampTutorial := preload("res://scripts/camp_tutorial.gd")
const S := CampPerson.State
const SHADER_PATH := "res://shaders/vision_cone.gdshader"
## The brief's two lines in fragment() ("my colour line and see-through line").
const COLOUR_LINE := "ALBEDO = mix(watch_color.rgb, alarm_color.rgb, alarm);"
const ALPHA_LINE := "ALPHA = COLOR.a * mix(watch_color.a, alarm_color.a, alarm) * shown;"
## Where he's out of the camp and everyone's sight (as cones_test.gd).
const AWAY := Vector3(20.0, 0.02, 6.5)
const EPS := 1e-4
const PHYSICS_RATE := 60.0
const CALM := [S.WORK, S.RETURN, S.FIX, S.INVESTIGATE, S.SEARCH]

## Set by the level (main.gd).
var level: Node

var _camp
var _people: Array = []
var _player
var _plan
var _fps := 60.0
var _fps_seen := 0.0
var _frames: Array[Dictionary] = []
var _results: Array[Array] = []
var _timings: Array[String] = []
var _failed := false
## The staging: where it's got to, since when (camp clock, ticks), and what it staged.
var _phase := "start"
var _phase_clock := 0.0
var _phase_ticks := 0
var _phase_frame := 0
var _t := 0.0
var _ticks := 0
var _spots: Array[Dictionary] = []
var _last_spot := -INF
var _who
var _who_was := ""
var _not_staged: Array[String] = []


class Sampler extends Node:
	var test

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_priority = 1000

	func _process(delta: float) -> void:
		test._sample(delta)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_camp = level.campsite
	_people.assign([_camp.camper, _camp.dancers[0], _camp.dancers[1]])
	_player = level.player
	_plan = level._plan
	_check_shader()
	var sampler := Sampler.new()
	sampler.test = self
	add_child(sampler)


# --- What the shader declares, and what each cone has ------------------------------

func _check_shader() -> void:
	var shader: Shader = load(SHADER_PATH)
	var types := {}
	for u: Dictionary in shader.get_shader_uniform_list():
		types[u.name] = type_string(u.type)
	_check("Uniform list: not empty (the shader parses)", true, not types.is_empty())
	_check("Uniform list: exactly alarm, shown, watch_color, alarm_color", "alarm alarm_color shown watch_color",
		" ".join(_sorted(types.keys())))
	_check("Uniform list: alarm is a float", "float", types.get("alarm", "missing"))
	_check("Uniform list: shown is a float", "float", types.get("shown", "missing"))
	# A vec4 with source_color is listed as a Color.
	_check("Uniform list: watch_color is a colour (vec4, source_color)", "Color", types.get("watch_color", "missing"))
	_check("Uniform list: alarm_color is a colour (vec4, source_color)", "Color", types.get("alarm_color", "missing"))
	# The names the driver sets (vision_cone.gd set_look) must be declared: setting one
	# that isn't raises no error.
	_check("Driver's names declared: alarm and shown", true, types.has("alarm") and types.has("shown"))

	# Hints and defaults, from the source: a headless run doesn't report them.
	var code := shader.code
	var decl := {}
	var re := RegEx.create_from_string("uniform\\s+(\\w+)\\s+(\\w+)\\s*(?::\\s*([^=;]+?))?\\s*(?:=\\s*([^;]+?))?\\s*;")
	for m: RegExMatch in re.search_all(code):
		decl[m.get_string(2)] = [m.get_string(1), m.get_string(3).strip_edges(), m.get_string(4).strip_edges()]
	_check("Source: alarm is float, hint_range(0.0, 1.0), default 0.0", "float|hint_range(0.0, 1.0)|0.0",
		"|".join(decl.get("alarm", ["missing"])))
	_check("Source: shown is float, hint_range(0.0, 1.0), default 1.0", "float|hint_range(0.0, 1.0)|1.0",
		"|".join(decl.get("shown", ["missing"])))
	_check("Source: watch_color is vec4, source_color", "vec4|source_color",
		"|".join(decl.get("watch_color", ["missing", "", ""]).slice(0, 2)))
	_check("Source: alarm_color is vec4, source_color", "vec4|source_color",
		"|".join(decl.get("alarm_color", ["missing", "", ""]).slice(0, 2)))
	_check("Source: watch_color's default is the game's WATCHING", _rgba(VisionCone.WATCHING),
		_rgba(_vec4(decl.get("watch_color", ["", "", ""])[2])))
	_check("Source: alarm_color's default is the game's SEEING", _rgba(VisionCone.SEEING),
		_rgba(_vec4(decl.get("alarm_color", ["", "", ""])[2])))
	_check("Source: render_mode blend_mix, unshaded, depth_draw_opaque", true,
		code.contains("render_mode blend_mix, unshaded, depth_draw_opaque;"))
	_check("Source: the brief's colour line, word for word", true, code.contains(COLOUR_LINE))
	_check("Source: the brief's see-through line, word for word", true, code.contains(ALPHA_LINE))

	# One material per cone, each with this shader, drawn on the cone.
	var materials := []
	var all_ours := true
	for p in _people:
		var m: ShaderMaterial = p.eyes.material()
		all_ours = all_ours and m != null and m.shader == shader and p.eyes._cone.material_override == m and p.eyes.driven
		if m and not m in materials:
			materials.append(m)
	_check("Each cone: a ShaderMaterial with the shader, as its override, driven", true, all_ours)
	_check("Each cone: a material of its own (3 cones, 3 materials)", 3, materials.size())


# --- The staging, through play -------------------------------------------------------

func _physics_process(delta: float) -> void:
	_t += delta
	_ticks += 1
	var now: float = _camp.clock
	if _t > 100.0 and _phase != "done":
		_note_not_staged("the run, stuck at '%s'" % _phase)
		_finish()
		return
	match _phase:
		"start":
			if _t >= 0.6:
				# In plain sight of the camper at the camp, as cones_test.gd: the music's
				# task is done, and the tutorial starts.
				_player.place(_in_view(_people[0], 5.0))
				_go("tutorial")
		"tutorial":
			if _since_ticks() > 10 and get_tree().paused and not _plan.open \
					and _plan.note_showing() == CampTutorial.OPEN_NOTE:
				_key(KEY_TAB)
				_go("plan")
		"plan":
			if _since_ticks() > 10 and _plan.open and _plan.up() >= 1.0:
				_key(KEY_TAB)
				_go("play")
		"play":
			# Spotted by the camper's own sight, once the cones are on.
			if not get_tree().paused and _camp.spotted_at > -INF:
				_spotted("spot 1: the camper", _camp.spotters[0])
				# Re-spotted during the red: the low-poly man, at work, before he catches
				# the camper's fright (CATCH_FRIGHT, 0.25 s at the soonest).
				var man = _people[1]
				_who = man
				var at = _view_point(man, _calm_except(man))
				if at == null or man.state != S.WORK:
					_note_not_staged("re-spot during the red (no clear spot in the low-poly man's view, or he isn't at work: %s)" % S.keys()[man.state])
					_go("lost_early")
				else:
					_player.place(at)
					_go("red_respot")
		"red_respot":
			if _camp.spotted_at > _last_spot and _who in _camp.spotters:
				_spotted("spot 2: the low-poly man, during the red", _who)
				_go("lost_early")
			elif now > _last_spot + CampPerson.CATCH_FRIGHT.x:
				_note_not_staged("re-spot during the red (the low-poly man didn't spot him within %.2f s; he was %s)" % [CampPerson.CATCH_FRIGHT.x, S.keys()[_who.state]])
				_go("lost_early")
		"lost_early":
			# Gone before the red is over: it still runs its 2 s and fades.
			if now >= _last_spot + 0.1:
				_send_away()
				_go("red_alarmed_wait")
		"red_alarmed_wait":
			# Seen during the red by someone alarmed (they've all taken fright by now):
			# no spotting, so nothing changes.
			if now >= _last_spot + CampPerson.CATCH_FRIGHT.y + 0.1:
				if not _stage_alarmed("seen by an alarmed camper during the red"):
					_go("fade_wait")
				else:
					_go("alarmed_red")
		"alarmed_red":
			if now >= _phase_clock + 0.4:
				_send_away()
				_go("fade_wait")
		"fade_wait":
			if now >= _last_spot + VisionCone.RED_TIME + 0.2:
				_key(KEY_ESCAPE)
				_go("paused")
		"paused":
			# The key is taken at the next frame: at 30 fps, two ticks on.
			if _since_ticks() == 4 and not get_tree().paused:
				_note_not_staged("pause mid-fade (Esc didn't pause the game)")
			if Engine.get_process_frames() - _phase_frame >= 45:
				_key(KEY_ESCAPE)
				_go("after_pause")
		"after_pause":
			if get_tree().paused:
				return
			if now >= _last_spot + VisionCone.RED_TIME + VisionCone.FADE_OUT + 0.1:
				# The cones hidden, and seen by someone still alarmed: they stay hidden.
				if _stage_alarmed("seen by an alarmed camper while the cones are hidden"):
					_go("alarmed_hidden")
				else:
					_go("wait_search")
		"alarmed_hidden":
			if now >= _phase_clock + 0.4:
				_send_away()
				_go("wait_search")
		"wait_search":
			# The first to be confused (SEARCH) after he's got away spots him, the cones
			# hidden: from here at half speed.
			if _people.any(func(p) -> bool: return p.state == S.SEARCH):
				Engine.time_scale = 0.5
				_who = null
				var at = null
				for p in _people:
					if p.state == S.SEARCH:
						at = _view_point(p, _calm_except(p))
						if at != null:
							_who = p
							break
				if _who == null:
					if now > _last_spot + 25.0:
						_note_not_staged("spotted while the cones are hidden (no clear spot in a confused camper's view)")
						_go("x2_wait")
				elif _people.any(func(p) -> bool: return p.eyes.showing()):
					_note_not_staged("spotted while the cones are hidden (a cone was showing)")
					_go("x2_wait")
				else:
					_player.place(at)
					_go("hidden_spot")
			elif now > _last_spot + 25.0:
				_note_not_staged("spotted while the cones are hidden (nobody confused 25 s on: %s)" % _states())
				_go("x2_wait")
		"hidden_spot":
			if _camp.spotted_at > _last_spot and _who in _camp.spotters:
				_spotted("spot 3: the %s, confused, while the cones are hidden, at time_scale 0.5" % _label(_who), _who)
				_go("hidden_away")
			elif now > _phase_clock + 0.5:
				_note_not_staged("spotted while the cones are hidden (the %s didn't spot him; %s)" % [_label(_who), S.keys()[_who.state]])
				_go("x2_wait")
		"hidden_away":
			if now >= _last_spot + 0.1:
				_send_away()
				_go("fade_respot_wait")
		"fade_respot_wait":
			# Re-spotted during the fade, by the other man: confused or walking back, so
			# not one to catch a fright.
			if now >= _last_spot + VisionCone.RED_TIME + 0.1:
				var other = null
				var at = null
				for p in _people:
					if p != _who and p.state in [S.SEARCH, S.RETURN, S.INVESTIGATE, S.FIX]:
						at = _view_point(p, _calm_except(p))
						if at != null:
							other = p
							break
				if other == null:
					_note_not_staged("re-spot during the fade (nobody else confused, walking back, wondering or fixing with a clear view: %s)" % _states())
					_go("comeback")
				else:
					_who = other
					_who_was = S.keys()[other.state]
					_player.place(at)
					_go("fade_respot")
		"fade_respot":
			if _camp.spotted_at > _last_spot and _who in _camp.spotters:
				_spotted("spot 4: the %s (%s), during the fade, at time_scale 0.5" % [_label(_who), _who_was], _who)
				_go("fade_away")
			elif now >= _last_spot + VisionCone.RED_TIME + VisionCone.FADE_OUT - 0.02:
				_note_not_staged("re-spot during the fade (the %s didn't spot him in time; %s)" % [_label(_who), S.keys()[_who.state]])
				_go("comeback")
		"fade_away":
			if now >= _last_spot + 0.1:
				_send_away()
				_go("comeback")
		"comeback":
			# Every cone back and faded in.
			var back := _people.all(func(p) -> bool:
				return p.eyes.showing() and float(p.eyes.material().get_shader_parameter("shown")) >= 1.0)
			if back and now >= _last_spot + 3.0:
				_go("x2_wait")
			elif now > _last_spot + 40.0:
				_note_not_staged("the cones coming back (not all back 40 s after the last spotting)")
				_go("x2_wait")
		"x2_wait":
			Engine.time_scale = 2.0
			_who = null
			for p in [_people[0], _people[1], _people[2]]:
				if p.state == S.WORK and _view_point(p, _calm_except(p)) != null:
					_who = p
					break
			if _who == null:
				_note_not_staged("a spotting at time_scale 2.0 (no camper at work with a clear view)")
				_go("end")
			else:
				_player.place(_view_point(_who, _calm_except(_who)))
				_go("x2_spot")
		"x2_spot":
			if _camp.spotted_at > _last_spot and _who in _camp.spotters:
				_spotted("spot 5: the %s, at work, at time_scale 2.0" % _label(_who), _who)
				_go("x2_away")
			elif now > _phase_clock + 0.5:
				_note_not_staged("a spotting at time_scale 2.0 (the %s didn't spot him)" % _label(_who))
				_go("end")
		"x2_away":
			if now >= _last_spot + 0.1:
				_send_away()
				_go("end")
		"end":
			if now >= _last_spot + VisionCone.RED_TIME + VisionCone.FADE_OUT + 0.5:
				_finish()


func _go(phase: String) -> void:
	_phase = phase
	_phase_clock = _camp.clock
	_phase_ticks = _ticks
	_phase_frame = Engine.get_process_frames()


func _since_ticks() -> int:
	return _ticks - _phase_ticks


func _spotted(label: String, by) -> void:
	_last_spot = _camp.spotted_at
	_spots.append({"T": _camp.spotted_at, "by": _people.find(by), "label": label})


func _note_not_staged(what: String) -> void:
	_not_staged.append(what)


## Puts him where someone alarmed sees him and nobody calm does, for the check that it
## changes nothing; or notes that it couldn't.
func _stage_alarmed(what: String) -> bool:
	for p in _people:
		if not p.state in CALM:
			var at = _view_point(p, _calm_except(null))
			if at != null:
				_player.place(at)
				return true
	_note_not_staged("%s (nobody alarmed with a clear view that nobody calm shares: %s)" % [what, _states()])
	return false


func _states() -> String:
	return " ".join(_people.map(func(p) -> String: return S.keys()[p.state]))


## The calm ones (who'd count a sighting as a spotting), but `who`.
func _calm_except(who) -> Array:
	return _people.filter(func(p) -> bool: return p != who and p.state in CALM)


func _send_away() -> void:
	_player.place(AWAY)


## Presses and lets go of `keycode`, as a player would (as cones_test.gd).
func _key(keycode: Key) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = keycode
		ev.physical_keycode = keycode
		ev.pressed = pressed
		Input.parse_input_event(ev)


## A point on the ground in the camp that `who` sees from where they are now, looking
## the way they look now, and that none of `not_by` sees.
func _view_point(who, not_by: Array) -> Variant:
	var eye: Vector3 = who.eyes.global_position
	var forward: Vector3 = -who.eyes.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var reach: float = who.eyes.reach
	for metres: float in [2.5, 2.0, 3.0, 1.6, 3.5]:
		if metres > reach * 0.85:
			continue
		for degrees: float in [0.0, -15.0, 15.0, -30.0, 30.0]:
			var at := Vector3(eye.x, 0.02, eye.z) + forward.rotated(Vector3.UP, deg_to_rad(degrees)) * metres
			if _camp.in_camp(at) and _sees(who, at) and not not_by.any(func(p) -> bool: return _sees(p, at)):
				return at
	return null


## Whether `who`'s eyes would see him standing at `at` (vision_cone.gd can_see, for a
## point, with a margin at the edges).
func _sees(who, at: Vector3) -> bool:
	var eyes = who.eyes
	var eye: Vector3 = eyes.global_position
	var forward: Vector3 = -eyes.global_basis.z
	forward.y = 0.0
	var flat := at - eye
	flat.y = 0.0
	if flat.length() > eyes.reach - 0.3 or rad_to_deg(forward.angle_to(flat)) > eyes.angle * 0.5 - 8.0:
		return false
	var space: PhysicsDirectSpaceState3D = who.get_world_3d().direct_space_state
	for height: float in VisionCone.LOOK_AT:
		var ray := PhysicsRayQueryParameters3D.create(eye, at + Vector3.UP * height, eyes.blocked_by,
			[who.get_rid(), _player.get_rid()])
		if space.intersect_ray(ray).is_empty():
			return true
	return false


## `metres` in front of where `person`'s activity is done, as cones_test.gd's _in_view.
func _in_view(person, metres: float) -> Vector3:
	var space: PhysicsDirectSpaceState3D = person.get_world_3d().direct_space_state
	var at := Vector3.ZERO
	for degrees: float in [0.0, -15.0, 15.0, -30.0, 30.0, -45.0, 45.0]:
		var yaw: float = person.activity_facing() + deg_to_rad(degrees)
		at = person.activity_spot() + Vector3(sin(yaw), 0, cos(yaw)) * metres + Vector3(0, 0.02, 0)
		var ray := PhysicsRayQueryParameters3D.create(person.eyes.global_position, at + Vector3.UP * 0.45, 1,
			[person.get_rid(), _player.get_rid()])
		var dancers_far := _people.slice(1).all(func(d) -> bool:
			var v: Vector3 = d.global_position - at
			return Vector2(v.x, v.z).length() > CampPerson.SIGHT * CampPerson.DANCE_SIGHT + 0.3)
		if dancers_far and space.intersect_ray(ray).is_empty():
			return at
	return at


# --- The record, once a frame, after every other _process() --------------------------

func _sample(delta: float) -> void:
	# The rate it runs at: --fixed-fps makes every frame's step 1/N (times time_scale).
	if _fps_seen == 0.0 and delta > 0.0 and Engine.time_scale == 1.0:
		_fps_seen = roundf(1.0 / delta)
	var f := {
		"frame": Engine.get_process_frames(),
		"clock": float(_camp.clock),
		"spotted_at": float(_camp.spotted_at),
		"spotters": _camp.spotters.map(func(p) -> int: return _people.find(p)),
		"paused": get_tree().paused,
		"scale": Engine.time_scale,
		"cones_on": _camp.cones_on,
		"phase": _phase,
		"alarm": [], "shown": [], "showing": [], "state": [], "seeing": [],
	}
	for p in _people:
		var m: ShaderMaterial = p.eyes.material()
		f.alarm.append(_param(m, "alarm", 0.0))
		f.shown.append(_param(m, "shown", 1.0))
		f.showing.append(p.eyes.showing())
		f.state.append(p.state)
		f.seeing.append(p.eyes.seeing)
	_frames.append(f)


func _param(m: ShaderMaterial, name: String, default: float) -> float:
	var v = m.get_shader_parameter(name)
	return default if v == null else float(v)


# --- The checks, on the record -------------------------------------------------------

func _analyse() -> void:
	var tol_frames := 3 if _fps > PHYSICS_RATE else 1

	# alarm snaps: nothing but 0 and 1, ever.
	var only_01 := true
	for f: Dictionary in _frames:
		for a: float in f.alarm:
			only_01 = only_01 and (a == 0.0 or a == 1.0)
	_check("alarm is only ever 0 or 1 (it snaps, nothing in between)", true, only_01)

	# No fade-in when the tutorial ends: the cones appear with shown 1, yellow.
	var first := -1
	for i in _frames.size():
		if _frames[i].cones_on and true in _frames[i].showing:
			first = i
			break
	if first < 0:
		_check("Tutorial over: the cones appear", true, false)
	else:
		# At 30 fps the camper can spot him in the frame's second tick: then his cone is
		# red already. Every other cone is yellow.
		var f: Dictionary = _frames[first]
		var want := []
		for c in 3:
			want.append(1.0 if c in f.spotters else 0.0)
		_check("Tutorial over: the cones appear at once, shown 1, yellow but for a spotter (no fade-in)",
			"%s %s" % ["[1.0, 1.0, 1.0]", _floats(want)], "%s %s" % [_floats(f.shown), _floats(f.alarm)])

	# Each spotting, as the frames saw it.
	var events: Array[Dictionary] = []
	for i in range(1, _frames.size()):
		if _frames[i].spotted_at != _frames[i - 1].spotted_at:
			var label := "an unstaged spotting"
			var by := -1
			for s: Dictionary in _spots:
				if s.T == _frames[i].spotted_at:
					label = s.label
					by = s.by
			events.append({"i": i, "T": _frames[i].spotted_at, "label": label, "by": by})
	_check("Spottings seen: the five staged, and no others", " | ".join(_spots.map(func(s) -> String: return s.label)),
		" | ".join(events.map(func(e) -> String: return e.label)))

	for k in events.size():
		var e: Dictionary = events[k]
		var i: int = e.i
		var T: float = e.T
		var f: Dictionary = _frames[i]
		var before: Dictionary = _frames[i - 1]
		var name: String = e.label.get_slice(":", 0)
		var fp: float = f.scale / _fps
		var tick: float = f.scale / PHYSICS_RATE
		var late: float = maxf(fp, tick)
		# The snap: on the very frame the game took him for spotted.
		var want_alarm := []
		for c in 3:
			want_alarm.append(1.0 if c in f.spotters else 0.0)
		_check("%s: the snap, the frame it happens: alarm on the spotters' cones only" % name,
			_floats(want_alarm), _floats(f.alarm))
		if e.by >= 0:
			_check("%s: the spotter's cone went 0 to 1 within one frame" % name, "0.0 -> 1.0",
				"%.1f -> %.1f" % [before.alarm[e.by], f.alarm[e.by]])
		_check("%s: shown 1 on every cone, the frame it happens" % name, "[1.0, 1.0, 1.0]", _floats(f.shown))
		# Whether the game draws every cone is camp_person.gd's: a confused camper who
		# spots him shows their own cone on the next tick (show_on_ground runs before
		# _search). So: within one frame or one tick.
		for j in range(i, _frames.size()):
			if _frames[j].showing == [true, true, true]:
				_first_frame(name, "every cone drawn", T, _frames[j].clock, late)
				break

		var next_T := INF
		var next_i := _frames.size()
		if k + 1 < events.size():
			next_T = events[k + 1].T
			next_i = events[k + 1].i
		var red_end: float = T + VisionCone.RED_TIME
		var gone: float = red_end + VisionCone.FADE_OUT
		if next_T < red_end:
			# Re-spotted during the red: shown stays at 1, and both spotters are red.
			var held := true
			for j in range(i, next_i):
				held = held and _frames[j].shown == [1.0, 1.0, 1.0]
			_check("%s: re-spotted during its red: shown stayed at 1 until then" % name, true, held)
			var nf: Dictionary = _frames[next_i]
			_check("%s: re-spotted during its red: both spotters' cones red" % name,
				"%d red" % nf.spotters.size(), "%d red" % nf.alarm.count(1.0))
			continue
		if next_T < gone:
			var prev: Dictionary = _frames[next_i - 1]
			var was_fading: bool = prev.shown.all(func(s: float) -> bool: return s > 0.0 and s < 1.0)
			_check("%s: re-spotted during its fade: shown was fading, then snapped back to 1" % name,
				"fading, then [1.0, 1.0, 1.0]", "%s, then %s" % ["fading" if was_fading else _floats(prev.shown), _floats(_frames[next_i].shown)])
		# Through the red and the fade (to the next spotting, if one comes first): the
		# spotters red, the rest yellow; shown 1 through the red.
		var red_held := true
		var shown_held := true
		for j in range(i, next_i):
			var g: Dictionary = _frames[j]
			if g.clock >= gone - EPS:
				break
			for c in 3:
				red_held = red_held and g.alarm[c] == (1.0 if c in f.spotters else 0.0)
			if g.clock < red_end - EPS:
				shown_held = shown_held and g.shown == [1.0, 1.0, 1.0]
		_check("%s: the spotters' cones red, the rest yellow, through the red and the fade" % name, true, red_held)
		_check("%s: shown 1 all through the 2 s of red" % name, true, shown_held)
		# The fade's start and end, off its slope, in game time.
		var starts := []
		var ends := []
		var first_change := -1
		var first_zero := -1
		for j in range(i, next_i):
			var g: Dictionary = _frames[j]
			if g.clock > gone + 0.1:
				break
			if g.paused:
				continue
			var s: float = g.shown[0]
			if first_change < 0 and s < 1.0 - 1e-6:
				first_change = j
			if s > 0.001 and s < 0.999 and g.clock > red_end - EPS and g.clock < gone + EPS:
				ends.append(g.clock + s * VisionCone.FADE_OUT)
				starts.append(g.clock + s * VisionCone.FADE_OUT - VisionCone.FADE_OUT)
			if first_zero < 0 and g.clock >= red_end and (g.shown == [0.0, 0.0, 0.0] or g.showing == [false, false, false]):
				first_zero = j
		if next_T < gone:
			if not starts.is_empty():
				_timing(name, "fade start, off the slope", red_end, _worst(starts, red_end), fp)
			if first_change >= 0:
				_first_frame(name, "fade start", red_end, _frames[first_change].clock, late)
			continue
		if starts.is_empty():
			_check("%s: the fade has frames to read its slope from" % name, true, false)
		else:
			_timing(name, "fade start, off the slope", red_end, _worst(starts, red_end), fp)
			_timing(name, "fade end, off the slope", gone, _worst(ends, gone), fp)
		if first_change >= 0:
			_first_frame(name, "fade start", red_end, _frames[first_change].clock, late)
			if not range(i, first_change).any(func(j: int) -> bool: return _frames[j].paused):
				var frames: int = _frames[first_change].frame - f.frame
				var want := roundi(2.0 * _fps / f.scale)
				_timings.append("  %-8s red, in frames at %.0f fps and time_scale %.1f: %d (2N/s = %d, within %d)" % [name, _fps, f.scale, frames, want, tol_frames])
				_check("%s: the red lasts 2N/s frames at time_scale %.1f, within %d" % [name, f.scale, tol_frames],
					str(want), str(want) if absi(frames - want) <= tol_frames else str(frames))
		if first_zero >= 0:
			var z: Dictionary = _frames[first_zero]
			_first_frame(name, "gone (shown 0)", gone, z.clock, late)
			_check("%s: once gone: every cone hidden, shown 0, alarm 0" % name, "[false, false, false] [0.0, 0.0, 0.0] [0.0, 0.0, 0.0]",
				"%s %s %s" % [str(z.showing), _floats(z.shown), _floats(z.alarm)])
		if next_T < INF and events[k + 1].label.contains("while the cones are hidden"):
			var prev: Dictionary = _frames[next_i - 1]
			_check("%s: then spotted while hidden: the frame before, every cone hidden" % events[k + 1].label.get_slice(":", 0),
				"[false, false, false]", str(prev.showing))

	_check_pause()
	_check_alarmed()
	_check_fade_ins()


func _check_pause() -> void:
	var block: Array[Dictionary] = []
	for f: Dictionary in _frames:
		if f.paused and f.cones_on:
			block.append(f)
	if block.size() < 30:
		_check("Paused mid-fade with Esc: 30 frames or more", true, false)
		return
	var a: Dictionary = block[0]
	var held := block.all(func(g: Dictionary) -> bool:
		return g.clock == a.clock and g.shown == a.shown and g.alarm == a.alarm)
	_check("Paused mid-fade: it was mid-fade when Esc paused it", true, a.shown.all(func(s: float) -> bool: return s > 0.0 and s < 1.0))
	_check("Paused mid-fade: clock, shown and alarm held through %d paused frames" % block.size(), true, held)


func _check_alarmed() -> void:
	for phase: String in ["alarmed_red", "alarmed_hidden"]:
		var window: Array[Dictionary] = []
		for f: Dictionary in _frames:
			if f.phase == phase:
				window.append(f)
		if window.is_empty():
			continue
		var when := "during the red" if phase == "alarmed_red" else "while the cones are hidden"
		var saw := false
		var calm_saw := false
		var a: Dictionary = window[0]
		var unchanged := true
		for f: Dictionary in window:
			unchanged = unchanged and f.spotted_at == a.spotted_at and f.alarm == a.alarm and f.showing == a.showing \
				and f.shown == a.shown and f.spotters == a.spotters
			for c in 3:
				if f.seeing[c]:
					saw = saw or not f.state[c] in CALM
					calm_saw = calm_saw or f.state[c] in CALM
		if not saw or calm_saw:
			_note_not_staged("seen by an alarmed camper %s (an alarmed one saw him: %s; a calm one did: %s)" % [when, saw, calm_saw])
			continue
		_check("Seen by an alarmed camper %s, %d frames: no spotting, nothing changes" % [when, window.size()], true, unchanged)
		if phase == "alarmed_red":
			_check("  ... and during the red, his sighting kept everything as it was: red, shown 1", "[1.0, 1.0, 1.0]", _floats(a.shown))
		else:
			_check("  ... and the hidden cones stayed hidden", "[false, false, false] [0.0, 0.0, 0.0]",
				"%s %s" % [str(a.showing), _floats(a.shown)])


## Each cone that comes back after its BACK_AFTER: yellow, and from 0 to 1 over FADE_OUT
## from the moment the game shows it again (the 28 Oct revision). When that moment comes
## is camp_person.gd's (cones_test.gd checks it); it's printed against 5 s after the
## camper started walking back.
func _check_fade_ins() -> void:
	var seen := 0
	for c in 3:
		var back_from := -INF
		for j in range(1, _frames.size()):
			var f: Dictionary = _frames[j]
			var p: Dictionary = _frames[j - 1]
			if f.state[c] == S.RETURN and p.state[c] != S.RETURN:
				back_from = f.clock
			if not (f.showing[c] and not p.showing[c] and f.cones_on and f.clock >= f.spotted_at + 2.5 and f.spotted_at > -INF):
				continue
			var name := "the %s's cone back" % ["camper", "low-poly man", "girl"][c]
			seen += 1
			var start: float = f.clock
			var fp: float = f.scale / _fps
			var late: float = maxf(fp, f.scale / PHYSICS_RATE)
			if back_from > -INF:
				_timings.append("  %-8s shown again at %8.4f, %+.2f ms from 5 s after walking back (%8.4f): the game's timing" % [name, start, (start - back_from - VisionCone.BACK_AFTER) * 1000.0, back_from + VisionCone.BACK_AFTER])
			else:
				_timings.append("  %-8s shown again at %8.4f (no walk back seen in the frames: the game's timing)" % [name, start])
			_check("%s: yellow (alarm 0)" % name, 0.0, f.alarm[c])
			_check("%s: shown 0 on the frame the game shows it again" % name, 0.0, f.shown[c])
			var starts := []
			var full := -1
			for n in range(j, _frames.size()):
				if _frames[n].clock > start + VisionCone.FADE_OUT + 0.1 or _frames[n].spotted_at != f.spotted_at:
					break
				var s: float = _frames[n].shown[c]
				if s > 0.001 and s < 0.999 and not _frames[n].paused:
					starts.append(_frames[n].clock - s * VisionCone.FADE_OUT)
				if full < 0 and s >= 1.0:
					full = n
			if starts.is_empty():
				_check("%s: the fade-in has frames to read its slope from" % name, true, false)
			else:
				_timing(name, "fade-in start, off the slope", start, _worst(starts, start), fp)
			if full >= 0:
				_first_frame(name, "fade-in end (shown 1)", start + VisionCone.FADE_OUT, _frames[full].clock, late)
			break
	_check("Cones coming back after their 5 s: all three seen", 3, seen)


## Within one frame (game time) of `want`.
func _timing(name: String, what: String, want: float, got: float, fp: float) -> void:
	var off := got - want
	_timings.append("  %-8s %-32s want %8.4f  got %8.4f  off %+7.2f ms (one frame %.2f ms)" % [name, what, want, got, off * 1000.0, fp * 1000.0])
	_check("%s: %s, within one frame" % [name, what], "ok", "ok" if absf(off) <= fp + EPS else "off %+.2f ms" % (off * 1000.0))


## The first frame where the value has changed: not before `want`, and no later than one
## frame or one tick, whichever is longer.
func _first_frame(name: String, what: String, want: float, got: float, late: float) -> void:
	var off := got - want
	_timings.append("  %-8s %-32s want %8.4f  first frame %8.4f  off %+7.2f ms (allowed 0 to %.2f ms)" % [name, what, want, got, off * 1000.0, late * 1000.0])
	_check("%s: %s, first changed frame within a frame or a tick" % [name, what], "ok",
		"ok" if off >= -EPS and off <= late + EPS else "off %+.2f ms" % (off * 1000.0))


## Of the values read off a slope, the one furthest from `want`.
func _worst(values: Array, want: float) -> float:
	var worst: float = values[0]
	for v: float in values:
		if absf(v - want) > absf(worst - want):
			worst = v
	return worst


func _label(person) -> String:
	return ["camper", "low-poly man", "girl"][_people.find(person)]


func _floats(values: Array) -> String:
	return "[" + ", ".join(values.map(func(v: float) -> String: return "%.1f" % v)) + "]"


func _rgba(c: Color) -> String:
	return "(%.2f, %.2f, %.2f, %.2f)" % [c.r, c.g, c.b, c.a]


## A vec4(...) default, as a Color, or black if it isn't one.
func _vec4(text: String) -> Color:
	var inner := text.trim_prefix("vec4(").trim_suffix(")")
	var parts := inner.split(",")
	if not text.begins_with("vec4(") or parts.size() != 4:
		return Color(0, 0, 0, 0)
	return Color(float(parts[0]), float(parts[1]), float(parts[2]), float(parts[3]))


func _sorted(values: Array) -> Array:
	var copy := values.duplicate()
	copy.sort()
	return copy


func _check(name: String, expected, actual) -> void:
	var ok: bool = str(expected) == str(actual)
	_failed = _failed or not ok
	_results.append([name, str(expected), str(actual), "pass" if ok else "FAIL"])


func _finish() -> void:
	_phase = "done"
	Engine.time_scale = 1.0
	if _fps_seen > 0.0:
		_fps = _fps_seen
	else:
		_note_not_staged("reading the frame rate (no frame at time_scale 1.0)")
	_analyse()
	for what: String in _not_staged:
		_failed = true
		_results.append(["NOT STAGED: " + what, "", "", "FAIL"])
	print("")
	print("Cone shader check at %.0f fps, %s" % [_fps, Time.get_datetime_string_from_system()])
	for r: Array in _results:
		print("  %-4s  %-78s expected %-20s got %s" % [r[3], r[0], r[1], r[2]])
	print("")
	print("Timings (game time; one frame is the frame period times time_scale):")
	for line: String in _timings:
		print(line)
	var passed := _results.filter(func(r: Array) -> bool: return r[3] == "pass").size()
	print("RESULT: %s (%d of %d checks passed)" % ["all checks passed" if not _failed else "SOME CHECKS FAILED", passed, _results.size()])
	get_tree().quit(1 if _failed else 0)
