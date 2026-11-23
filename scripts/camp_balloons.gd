extends Node3D
## Let the balloons go, a level 1 task at the camp (camp_tasks.gd "balloons"; CHANGE-BRIEF.md's
## revisions of 21 Nov 2026, last "the balloon task is 'Let the balloons go'"). Game code: what
## happens, and when, is decided here on the physics tick, never from the clips.
##   - The place: since 22 Nov 2026 by the table in the party's corner (PLACE; the author: "can u move
##     the chair near the table we have at camp ? and make the girl dance and come and sit on the chair
##     for some time", "so we can use the ballons"); before, just outside the camp. The node is turned
##     so the chair faces the fire (campsite.gd). The girl's "balloons" step takes her to MINDER.
##   - She sits on the chair: after her balloons step comes her "sit" step (campsite.gd _routines), on
##     the chair at SIT, playing her `sit` clip. Once they're blown up, her balloons step is only on the
##     way to her seat: arriving, she goes straight on to it.
##   - The girl blows them up: the first time she gets to her step there (`minder`), she sets
##     out a folding camp chair (built here, like the camp's props; no collider) and, after
##     SET_OUT, blows up the three balloons one by one (props/party_balloon.tscn, red, yellow,
##     blue), INFLATE seconds each with GAP between: each balloon plays its own `inflate`. As
##     each is done she ties it to the chair: the strings meet in one knot low on the chair's
##     back right leg (KNOT). With all three tied she goes on to sit (camp_person.gd
##     finish_activity). Interrupted, she carries on next time she's there. Until all three
##     are tied there's nothing to untie.
##   - He lets them go: E (his grab, camp_input.gd) at the knot tugs it loose, once the
##     tutorial has revealed the tasks. The bunch (props/balloon_bunch.tscn) floats away: its
##     own AnimationPlayer plays `float_away`, rising 8 m over FLOAT_TIME, then it's gone. That
##     ticks the task.
##   - The girl calls the others: seeing them float away (calm and within her sight,
##     CampPerson.SIGHT, of the chair during FLOAT_TIME), or coming back to her step to find
##     the chair empty, she takes fright and calls them (camp_person.gd call_out). Once a
##     release.
##   - One authority: each balloon's own script plays its clips; this script is the only
##     caller of play() on the bunch's player.
## Built on 21 Nov 2026 by Claude Code, from the brief and its revisions of the same day.

const Balloon := preload("res://props/party_balloon.tscn")
const Bunch := preload("res://props/balloon_bunch.tscn")
const Interactable := preload("res://scripts/interactable.gd")
const LowPoly := preload("res://scripts/lowpoly.gd")
const CampPerson := preload("res://scripts/camp_person.gd")

## Where they're tied, from the camp's middle (Forest.CAMP, x, z): by the table, in the party's
## corner (campsite.gd FIRE + (0.8, -4.3): 1.55 m east of the speaker, 2.75 m east of the table,
## 2.4 m from where she dances). Until 22 Nov 2026 it was (-6.5, 12.0), outside the camp.
const PLACE := Vector2(-1.7, -5.1)
## Where the girl stands minding them, from PLACE: 1.1 m on the camp's side.
const MINDER := Vector2(0.0, -1.1)
## The chair, from PLACE: where its middle stands (x, z), facing her (-Z); its seat's height,
## width and depth, and its back's top (m).
const CHAIR := Vector2(0.0, 0.3)
const SEAT := Vector3(0.48, 0.42, 0.42)
const BACK_TOP := 0.85
const CANVAS := Color("3f6a5c")
const FRAME := Color("8d9196")
## The knot, from PLACE: low on the chair's back right leg, in his reach. (In front of the chair
## until 22 Nov 2026; there they'd have floated in her lap once she sat.)
const KNOT := Vector3(0.24, 0.08, 0.48)
## Each balloon's colour and which way its string leans up from the knot (x, y, z; normalised):
## a bunch fanned round the chair's back right leg, out to its side and behind its back, each
## 0.3 m out from the knot and 65 degrees round from the next (0.32 m apart, middle to middle).
## Its string is STRING_LENGTH long (party_balloon.gd TAIL), so each one's middle is 0.69 m up,
## and at least 0.31 m from her elbow as she sits (measured 22 Nov 2026).
const SPOTS := [["red", Vector3(0.2954, 0.6103, -0.0521)], ["yellow", Vector3(0.1721, 0.6103, 0.2457)],
	["blue", Vector3(-0.15, 0.6103, 0.2598)]]
## Where she stands to sit, from PLACE: the seat's middle (the chair's), less her sit's SIT_BACK
## (tools/blender/animate_simple_girl.py: her hips go 0.37 m back over her feet), facing the
## chair's way. Then her hips are over the seat's middle, at its height.
const SIT := Vector2(CHAIR.x, CHAIR.y - 0.37)
const STRING_LENGTH := 0.68
const STRING := Color("ddd6c6")
## The girl's timing: setting the chair out, blowing each up (the length of `inflate`), and
## the pause before the next. Floating away takes FLOAT_TIME (the length of `float_away`).
const SET_OUT := 1.0
const INFLATE := 3.0
const GAP := 0.5
const FLOAT_TIME := 5.0

## Set before it's added (campsite.gd): the camp, and the girl who minds them.
var camp
var minder: CampPerson
## The balloons, in SPOTS's order, and the bunch they're in (its Lift is what floats away).
var balloons: Array[Node3D] = []
var bunch: Node3D
var chair: Node3D
## Where things are: whether the chair's out, how many are blown up and tied, whether he's let
## them go (and when, on the camp's clock), and whether she's raised the alarm for it.
var chair_out := false
var tied := 0
var released := false
var released_at := -INF
var reported := false

var _knot_mesh: MeshInstance3D
var _knot_spot: Interactable
var _bunch_anim: AnimationPlayer
## Counting down to her next step in blowing them up; whether one is being blown up now.
var _next := 0.0
var _blowing := false


func _ready() -> void:
	chair = _build_chair()
	chair.visible = false
	add_child(chair)
	bunch = Bunch.instantiate() as Node3D
	bunch.position = KNOT
	add_child(bunch)
	_bunch_anim = bunch.get_node("AnimationPlayer") as AnimationPlayer
	var lift := bunch.get_node("Lift") as Node3D
	for spot: Array in SPOTS:
		var balloon := Balloon.instantiate() as Node3D
		balloon.set("colour", spot[0])
		var up: Vector3 = (spot[1] as Vector3).normalized()
		# Its string's end (its own -Y, STRING_LENGTH down) on the knot.
		balloon.transform = Transform3D(Basis(Quaternion(Vector3.UP, up)), up * STRING_LENGTH)
		lift.add_child(balloon)
		balloons.append(balloon)
	_knot_mesh = MeshInstance3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	LowPoly.add_icosphere(st, Vector3.ZERO, Vector3.ONE * 0.022, 0, 0.1, 5, func(_n: Vector3) -> Color: return STRING)
	_knot_mesh.mesh = LowPoly.commit(st)
	_knot_mesh.visible = false
	lift.add_child(_knot_mesh)
	_knot_spot = Interactable.new()
	_knot_spot.camp = camp
	_knot_spot.reach = 0.6
	_knot_spot.prompt_height = 0.25
	_knot_spot.position = KNOT
	_knot_spot.enabled = func() -> bool: return camp.tasks != null and camp.tasks.revealed and can_untie()
	_knot_spot.finished.connect(_release)
	add_child(_knot_spot)


## True while there's a knot to untie: all three blown up and tied, and not yet let go.
func can_untie() -> bool:
	return tied == balloons.size() and not released


## Where the knot is (the chair's leg), in the world.
func knot_at() -> Vector3:
	return to_global(KNOT)


func _physics_process(delta: float) -> void:
	if minder == null:
		return
	var there: bool = minder.at_activity() and minder.activity() == "balloons"
	if tied < balloons.size():
		_blow_up(there, delta)
	elif released and not reported:
		var floating: bool = camp.clock - released_at <= FLOAT_TIME
		var calm := minder.state in [CampPerson.State.WORK, CampPerson.State.RETURN]
		var near := Vector2(minder.global_position.x - global_position.x, minder.global_position.z - global_position.z).length()
		if there or (floating and calm and near <= CampPerson.SIGHT):
			reported = true
			minder.call_out(to_global(Vector3(CHAIR.x, 0.0, CHAIR.y)))
	elif there:
		# Once they're blown up, her balloons step is only on her way to her seat (her next step).
		minder.finish_activity()


## Her first visits: the chair, then each balloon in turn, while she's there.
func _blow_up(there: bool, delta: float) -> void:
	_next -= delta
	if _blowing:
		# One she's started is finished, there or not.
		if _next <= 0.0:
			_blowing = false
			tied += 1
			_knot_mesh.visible = true
			_next = GAP
			if tied == balloons.size():
				minder.finish_activity()
		return
	if not there:
		return
	if not chair_out:
		chair_out = true
		chair.visible = true
		_next = SET_OUT
	elif _next <= 0.0:
		_blowing = true
		_next = INFLATE
		balloons[tied].call("inflate")


## E at the knot: it's tugged loose, the bunch floats away, the task's ticked.
func _release() -> void:
	if not can_untie():
		return
	released = true
	released_at = camp.clock
	_bunch_anim.play("float_away")
	camp.tasks.done("balloons")


## A folding camp chair, low-poly: a canvas seat and back on a frame of thin legs crossed at the
## sides, and armrests. Facing -Z (her), its middle on CHAIR.
func _build_chair() -> Node3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w := SEAT.x * 0.5
	var d := SEAT.z * 0.5
	var leg := 0.022
	# The seat, sagging a little, and the back, leaning back.
	LowPoly.add_box(st, Transform3D(Basis(), Vector3(0, SEAT.y, 0)), Vector3(SEAT.x, 0.03, SEAT.z), CANVAS)
	var lean := Basis(Vector3.RIGHT, -0.18)
	LowPoly.add_box(st, Transform3D(lean, Vector3(0, (SEAT.y + BACK_TOP) * 0.5, d + 0.04)),
		Vector3(SEAT.x, BACK_TOP - SEAT.y, 0.025), CANVAS)
	# The legs: an X at each side, from the front foot to the back of the seat and back again.
	for x: float in [-w, w]:
		for pair: Array in [[Vector3(x, 0, -d), Vector3(x, SEAT.y, d)], [Vector3(x, 0, d), Vector3(x, SEAT.y, -d)]]:
			_add_bar(st, pair[0], pair[1], leg)
		# The back's upright, and the armrest.
		_add_bar(st, Vector3(x, SEAT.y, d), Vector3(x, BACK_TOP, d + 0.13), leg)
		LowPoly.add_box(st, Transform3D(Basis(), Vector3(x, SEAT.y + 0.2, 0)), Vector3(0.05, 0.025, SEAT.z), CANVAS)
		_add_bar(st, Vector3(x, SEAT.y, -d), Vector3(x, SEAT.y + 0.2, -d), leg)
	# A bar along the front and the back at the feet.
	_add_bar(st, Vector3(-w, 0.03, -d), Vector3(w, 0.03, -d), leg)
	_add_bar(st, Vector3(-w, 0.03, d), Vector3(w, 0.03, d), leg)
	var mi := MeshInstance3D.new()
	mi.mesh = LowPoly.commit(st)
	mi.position = Vector3(CHAIR.x, 0, CHAIR.y)
	return mi


## A square bar of `size` from `a` to `b`.
func _add_bar(st: SurfaceTool, a: Vector3, b: Vector3, size: float) -> void:
	var along := b - a
	var basis := Basis(Quaternion(Vector3.UP, along.normalized()))
	LowPoly.add_box(st, Transform3D(basis, (a + b) * 0.5), Vector3(size, along.length(), size), FRAME)
