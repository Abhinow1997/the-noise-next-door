extends Node3D
## The cake, and how level 1 ends at the camp. Asked for on 23 Nov 2026, the author: "after some time
## maybe the fat guy can like go in the tent, maybe bring out a cake ... put it on the table, and he's
## like standing alongside the cake, and then we come up and tie his lace, something of that sort of a
## task, and then eventually when he walks away, he falls, and the cake falls on him, and the beanie sort
## of slips out, and we will grab it. As soon as we grab the [red] beanie ... we'll start a cutscene ...
## a quick like 10 seconds or 20 seconds cutscene, and then eventually we'll start a chase that will lead
## on to a new location". The beats are the author's; where things stand, how long each beat takes and
## the words are Claude Code's (CHANGE-BRIEF.md, the revision of that day).
##   1. Unlocked: once UNLOCK_AFTER of the camp's tasks are done (the tutorial's marshmallows count),
##      FETCH_AFTER seconds later, the next time he's at his routine, the camper goes into his tent for a
##      cake (camp_person.gd CAKE): bent in at its door, then out with it in both hands (his `carry`
##      clip) to a little folding table of his own by the tent (TABLE_AT), and sets it down. From then
##      his routine has a step by the cake (ADMIRE_TIME), standing at the table, facing it.
##   2. Tie his laces (a key task, at the bottom of the screen): while he stands at the cake, holding E
##      at his heels for LACE_TIME (interactable.gd) ties his laces together. Then he moves on within
##      LEAVE_AFTER, or sooner if anything sets him moving (a fright: seeing the raccoon, his laugh).
##   3. His first step, he falls (camp_person.gd `_fall`, his `trip` clip): back over his heels, a grab
##      at the table that takes the cake with him, and flat on his back. The cake flies off the table and
##      lands on his face (TRIP_LANDS), and his red beanie slips off his head and lands behind him: the
##      one on his head is hidden, and a loose one, its own mesh, lies on the ground.
##   4. Swipe his red beanie (the next key task): E takes it in the raccoon's mouth, and the cutscene
##      starts (CUTSCENE, about 10 s): black bars, the controls held; the camera on the camper; he sits
##      up, the cake slides off, he gets up (`get_up`) bare-headed and stamps at the raccoon; the others
##      take fright; the raccoon runs for the trees on his own (player.gd `run_off`), the men after him.
##   5. Get away with it: "RUN!", the bars go and the keys are his. The camper and the two men chase him
##      out of the camp and on through the forest (camp_person.gd PURSUE), never giving up; caught, he's
##      shooed, drops the beanie and leaps away, as in the camp. The moth flies ahead of him, leading the
##      way (props/moths.gd `guide_along`) toward a warm glow at the forest's north-east edge (EXIT), the
##      way to the new location. Reaching it with the beanie: the screen fades to "To be continued",
##      and the game goes back to the title. The new location isn't built yet.
## It's game code: the task, the laces, the fall, the beanie and the chase. It writes no animation: the
## camper's clips are camp_person.gd's to play; the cake and the beanie are moved here, in code, as props.

const Interactable := preload("res://scripts/interactable.gd")
const CampPerson := preload("res://scripts/camp_person.gd")
const Campsite := preload("res://scripts/campsite.gd")
const LowPoly := preload("res://scripts/lowpoly.gd")
const S := CampPerson.State

enum Phase { WAIT, READY, FETCHING, OUT, DOWN, CUTSCENE, CHASE, DONE }

## The camp's tasks done before the cake comes out, and how long after that (s) the camper goes for it.
const UNLOCK_AFTER := 5
const FETCH_AFTER := 6.0
## Where things are, from the fire (x, z): the cake's folding table, out behind his tent at the camp's
## east edge, clear of the walkways round it (its top, x by z, and its height); where the camper stands at
## it, facing it (east, his back to his tent); in front of his tent's door (campsite.gd CAMPER_TENT, its
## front facing west), facing it.
const TABLE_AT := Vector2(11.62, -0.6)
const TABLE_TOP := Vector2(0.52, 0.8)
const TABLE_HIGH := 0.72
const STAND_AT := Vector2(11.0, -0.6)
const DOOR_AT := Vector2(6.7, -0.6)
## How long he stands by the cake each time his routine comes round to it (s).
const ADMIRE_TIME := Vector2(20, 30)
## Tying his laces: how long E is held (s), how far from his heels the raccoon's mouth may be (m); and,
## tied, how soon he moves on (s).
const LACE_TIME := 2.5
const LACE_REACH := 0.75
const LEAVE_AFTER := 2.5
## His trip clip (tools/blender/animate_chubby.py): the frame he grabs at the table, and the one he hits
## the ground, at its 25 fps.
const TRIP_GRABS := 21.0 / 25.0
const TRIP_LANDS := 26.0 / 25.0
## Where the cake goes, from animate_chubby.py `cake_points`: held, in his chest bone's (schiena's) space;
## on his face, in his head bone's (testa's) space, and in his own space as he lands (Godot's axes).
const CAKE_HELD := Vector3(0.0003, -0.0143, 0.3398)
const CAKE_ON_FACE := Vector3(0.0043, 0.0915, 0.1703)
const CAKE_FACE_LANDED := Vector3(0.0, 0.4468, -1.1885)
## The cake on his face, squashed (x, its height, z).
const SPLAT := Vector3(1.1, 0.75, 1.1)
## The loose beanie: how it's thrown off his head as he lands (m/s, out toward the camera's side and back
## along his fall, and up).
const BEANIE_BACK := 0.9
const BEANIE_UP := 1.4
## The cutscene's beats (s from the grab): the camera settles on the camper; he gets up; he stamps and
## the others take fright; the raccoon runs off for RUN_OFF; "RUN!" and the keys back.
const CUT_GET_UP := 2.0
const CUT_CAKE_OFF := 2.6
const CUT_STAMP := 4.4
const CUT_OTHERS := 4.7
const CUT_RUN := 6.6
const RUN_OFF := 3.2
const CUT_END := 10.2
## Where he runs for, in the cutscene (world x, z): north-east, clear of the camper's tent.
const RUN_TO := Vector2(56.0, -4.0)
## The chase: the way the moth leads (world x, z), the forest's north-east edge it ends at (EXIT), and how
## near it counts as there (m).
const CHASE_WAY := [Vector2(54.0, 2.0), Vector2(60.0, -4.0), Vector2(64.0, -14.0), Vector2(68.0, -24.0),
	Vector2(73.0, -36.0)]
const EXIT := Vector2(73.0, -36.0)
const EXIT_REACH := 3.0
## The black bars' height (px), how long they take to come and go, and the fade to the end (s).
const BARS := 70.0
const BARS_TIME := 0.5
const FADE_TIME := 1.2
const END_HOLD := 3.0
## The tasks, each a key task in turn (camp_tasks.gd `add_finale`), their hints 5 words at most.
const LACES_TASK := {"id": "laces", "text": "Tie his laces", "hint": "Sneak behind him, hold E."}
const BEANIE_TASK := {"id": "beanie", "text": "Swipe his red beanie", "hint": "Grab it, quick!"}
const GETAWAY_TASK := {"id": "getaway", "text": "Get away with it", "hint": "Follow the moth, run!"}

const WOOD := Color("8a6a48")
const WOOD_DARK := Color("5e4630")
const BOARD := Color("e8e2d6")
const SPONGE := Color("c98a52")
const FROSTING := Color("f4e9df")
const CHERRY := Color("b0222e")
const CANDLE := Color("6fa6d6")
const FLAME := Color("ffc56a")
const GLOW := Color(1.0, 0.72, 0.42)

var level: Node
var camp
var tasks
var player
var moths: Node

var phase := Phase.WAIT
var table: StaticBody3D
var cake: Node3D
var laces: Interactable
var beanie: RigidBody3D

var _camper: CampPerson
var _worn: MeshInstance3D
var _head: BoneAttachment3D
var _chest: BoneAttachment3D
var _t := 0.0
var _fell_at := -1.0
var _tossed := false
var _toss_from := Vector3.ZERO
var _toss_v := Vector3.ZERO
var _toss_t := 0.0
var _landed := false
var _cake_off := false
var _flames: Array[Node3D] = []
var _beats := {}
var _bars_top: ColorRect
var _bars_bottom: ColorRect
var _fade: ColorRect
var _card: Label


func _ready() -> void:
	_camper = camp.camper
	_camper.fell.connect(_on_fell)
	for node in _camper.find_children("*", "MeshInstance3D", true, false):
		if "Beanie" in String(node.name):
			_worn = node
	var skeletons := _camper.find_children("*", "Skeleton3D", true, false)
	if not skeletons.is_empty():
		_head = BoneAttachment3D.new()
		_head.bone_name = "testa"
		skeletons[0].add_child(_head)
		_chest = BoneAttachment3D.new()
		_chest.bone_name = "schiena"
		skeletons[0].add_child(_chest)
	_build_table()
	_build_cake()
	cake.visible = false
	laces = Interactable.new()
	laces.hold_time = LACE_TIME
	laces.reach = LACE_REACH
	laces.facing = 80.0
	laces.prompt_height = 0.35
	laces.camp = camp
	laces.enabled = _can_tie
	laces.finished.connect(_on_tied)
	add_child(laces)
	_build_overlay()
	# The way out, toward the new location: a warm glow through the trees past the forest's edge.
	var glow := OmniLight3D.new()
	glow.light_color = GLOW
	glow.light_energy = 2.2
	glow.omni_range = 10.0
	glow.position = Vector3(EXIT.x + 4.5, 2.0, EXIT.y - 1.5)
	add_child(glow)
	tasks.ticked.connect(func(_id: String) -> void: _check_unlock())
	_check_unlock()


## The world point `at` (from the fire) on the ground.
static func spot(at: Vector2) -> Vector3:
	return Vector3(Campsite.FIRE.x + at.x, 0.0, Campsite.FIRE.y + at.y)


# --- For the camper (camp_person.gd CAKE) ------------------------------------------------------------

## Where he stands at his tent's door, and the door he faces.
func door_spot() -> Vector3:
	return spot(DOOR_AT)


func door_at() -> Vector3:
	return spot(DOOR_AT + Vector2(1.0, 0.0))


## Where he stands at the cake's table, and its middle, which he faces.
func stand_spot() -> Vector3:
	return spot(STAND_AT)


func table_at() -> Vector3:
	return spot(TABLE_AT)


## Out of the tent, the cake in both his hands (on his chest bone, at CAKE_HELD).
func cake_in_hands(_who) -> void:
	if _chest == null:
		return
	cake.reparent(_chest, false)
	cake.transform = Transform3D(Basis(), CAKE_HELD)
	cake.visible = true


## Set down on its table (or put down there in a hurry, frightened on the way).
func cake_on_table() -> void:
	if cake.get_parent() == table:
		return
	cake.reparent(table, false)
	cake.transform = Transform3D(Basis(), Vector3(0, TABLE_HIGH, 0))
	cake.visible = true
	if phase == Phase.FETCHING:
		_out()


## His routine's step by the cake, given to him the first time he's set it down: its index.
func cake_step(who) -> int:
	for i in who.routine.size():
		if who.routine[i].name == "cake":
			return i
	var facing := atan2(table_at().x - stand_spot().x, table_at().z - stand_spot().z)
	who.routine.append(camp._activity("cake", stand_spot(), facing, "idle", 1.0, ADMIRE_TIME))
	return who.routine.size() - 1


# --- Each tick ---------------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			return
	_t += delta
	match phase:
		Phase.READY:
			if _t >= FETCH_AFTER and _camper.fetch_cake(self):
				phase = Phase.FETCHING
		Phase.FETCHING:
			# Frightened before he had it in his hands: he goes for it again, once he's back at his routine.
			if _camper.state != S.CAKE:
				phase = Phase.READY
				_t = 0.0
		Phase.OUT:
			# The laces' spot: at his heels, behind him (he faces his +Z).
			var back := -_camper.global_basis.z
			laces.global_position = _camper.global_position + Vector3(back.x, 0.0, back.z).normalized() * 0.2 \
				+ Vector3.UP * 0.05
		Phase.DOWN:
			_fallen(delta)
		Phase.CUTSCENE:
			_cutscene()
		Phase.CHASE:
			_chase()


## Enough of the camp's tasks done: the camper's cake is next.
func _check_unlock() -> void:
	if phase == Phase.WAIT and tasks.camp_done() >= UNLOCK_AFTER:
		phase = Phase.READY
		_t = 0.0


## The developer menu's cake start (main.gd): unlocked already, he goes for it at once.
func fetch_now() -> void:
	_check_unlock()
	if phase == Phase.READY:
		_t = FETCH_AFTER


## The cake's out: Tie his laces.
func _out() -> void:
	phase = Phase.OUT
	tasks.add_finale(LACES_TASK)


## The laces can be tied while he's standing at the cake, untied.
func _can_tie() -> bool:
	return phase == Phase.OUT and not _camper.laces_tied and _camper.at_activity() and _camper.activity() == "cake"


func _on_tied() -> void:
	_camper.laces_tied = true
	_camper.leave_soon(LEAVE_AFTER)
	tasks.done("laces")


## Over he goes (camp_person.gd `_fall`).
func _on_fell() -> void:
	if phase != Phase.OUT:
		return
	phase = Phase.DOWN
	_fell_at = _t
	_tossed = false
	_landed = false


## Down: the cake off the table at his grab and onto his face as he lands; his beanie off his head.
func _fallen(delta: float) -> void:
	var since := _t - _fell_at
	if not _tossed and since >= TRIP_GRABS:
		_tossed = true
		_toss_from = cake.global_position
		var land := _camper.model.global_transform * CAKE_FACE_LANDED
		var flight := maxf(TRIP_LANDS - since, 0.05)
		_toss_v = (land - _toss_from) / flight - 0.5 * Vector3(0, -9.8, 0) * flight
		_toss_t = 0.0
		cake.reparent(self, true)
	if _tossed and not _landed:
		_toss_t += delta
		cake.global_position = _toss_from + _toss_v * _toss_t + 0.5 * Vector3(0, -9.8, 0) * _toss_t * _toss_t
		cake.rotate_object_local(Vector3.RIGHT, -9.0 * delta)
	if not _landed and since >= TRIP_LANDS:
		_landed = true
		# Splat: on his face (his head bone), squashed a little.
		if _head:
			cake.reparent(_head, false)
			# Upside down, its top on his face (his head bone's +Z is out of his face), squashed.
			cake.transform = Transform3D(Basis(Vector3.RIGHT, -PI / 2) * Basis.from_scale(SPLAT), CAKE_ON_FACE
				+ Vector3(0, 0, 0.1))
		for flame: Node3D in _flames:
			flame.visible = false
		_drop_beanie()
		tasks.add_finale(BEANIE_TASK)
	if _landed and beanie and player.held == beanie:
		tasks.done("beanie")
		_start_cutscene()


## His beanie slips off his head: the worn one hidden, a loose one thrown off behind him.
func _drop_beanie() -> void:
	beanie = RigidBody3D.new()
	beanie.mass = 0.1
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.11
	shape.height = 0.16
	col.shape = shape
	beanie.add_child(col)
	var at := _head.global_position + Vector3.UP * 0.12 if _head else _camper.global_position + Vector3.UP * 0.4
	if _worn:
		var mi := MeshInstance3D.new()
		mi.mesh = _worn.mesh
		var box := _worn.mesh.get_aabb()
		# The mesh is in his rig's space, at his head's height: its middle brought to the beanie's own.
		mi.position = -box.get_center()
		beanie.add_child(mi)
		_worn.visible = false
	beanie.set_meta("grab_radius", 0.13)
	beanie.set_meta("hold_offset", Vector3(0, -0.05, -0.09))
	beanie.set_meta("hold_rotation", Vector3(0.5, 0, 0))
	beanie.continuous_cd = true
	beanie.add_to_group("grabbable")
	camp.add_child(beanie)
	beanie.global_position = at
	var back := -_camper.global_basis.z
	var away := (Vector3(back.x, 0, back.z).normalized() * 0.5 + Vector3.BACK).normalized()
	beanie.linear_velocity = away * BEANIE_BACK + Vector3.UP * BEANIE_UP
	beanie.angular_velocity = Vector3(3.0, 1.0, 0.5)
	beanie.reset_physics_interpolation()


# --- The cutscene --------------------------------------------------------------------------------------

func _start_cutscene() -> void:
	phase = Phase.CUTSCENE
	_t = 0.0
	_beats = {}
	player.input_locked = true
	level.camera_focus = _camper.model.global_transform * Vector3(0, 0.2, -0.6)
	_bars(true)


## Each beat once, at its time.
func _beat(name: String, at: float) -> bool:
	if _t < at or _beats.has(name):
		return false
	_beats[name] = true
	return true


func _cutscene() -> void:
	if _beat("get_up", CUT_GET_UP):
		_camper.get_up()
	if _beat("cake_off", CUT_CAKE_OFF):
		# Sitting up, the cake slides off his face to the ground beside him.
		var at := cake.global_position - _camper.global_basis.x * 0.35
		cake.reparent(self, true)
		cake.global_transform = Transform3D(Basis(Vector3.UP, 0.6) * Basis(Vector3.RIGHT, PI)
			* Basis.from_scale(Vector3(1.15, 0.6, 1.15)), Vector3(at.x, 0.12, at.z))
		_cake_off = true
	if _beat("stamp", CUT_STAMP):
		# Up, bare-headed, he stamps at the raccoon: then he's after him.
		_camper.pursue(CUT_RUN - CUT_STAMP + 0.8)
		level.camera_focus = (_camper.global_position + player.global_position) * 0.5
	if _beat("others", CUT_OTHERS):
		for person: CampPerson in camp.people:
			if person == _camper:
				continue
			if person.role == "girl":
				person.alert()
			else:
				person.pursue(CUT_RUN - CUT_OTHERS + 0.9 + randf() * 0.3)
	if _beat("run", CUT_RUN):
		level.camera_focus = null
		var way: Vector3 = Vector3(RUN_TO.x, 0, RUN_TO.y) - player.global_position
		player.run_off(way, RUN_OFF)
	if _beat("end", CUT_END):
		_start_chase()


# --- The chase -----------------------------------------------------------------------------------------

func _start_chase() -> void:
	phase = Phase.CHASE
	_t = 0.0
	player.input_locked = false
	_bars(false)
	_flash("RUN!")
	tasks.add_finale(GETAWAY_TASK)
	if moths and moths.has_method("guide_along"):
		var way := PackedVector2Array()
		var from: Vector3 = player.global_position
		way.append(Vector2(from.x, from.z))
		for p: Vector2 in CHASE_WAY:
			if p.x > from.x - 1.0:
				way.append(p)
		moths.guide_along(player, way, func() -> bool: return phase == Phase.DONE)


func _chase() -> void:
	var at: Vector3 = player.global_position
	if beanie and player.held == beanie and Vector2(at.x, at.z).distance_to(EXIT) < EXIT_REACH:
		_end()


## Away with it: to be continued, and back to the title.
func _end() -> void:
	phase = Phase.DONE
	tasks.done("getaway")
	player.input_locked = true
	for person: CampPerson in camp.people:
		person.stand_down()
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, FADE_TIME)
	tween.tween_callback(_show_card.bind("To be continued"))
	tween.tween_interval(END_HOLD)
	tween.tween_callback(_back_to_title)


func _back_to_title() -> void:
	if level and level.has_method("finale_over"):
		level.finale_over()
	else:
		get_tree().reload_current_scene()


## True once he's away with it (the end's fade has started).
func over() -> bool:
	return phase == Phase.DONE


# --- Building ------------------------------------------------------------------------------------------

## A little folding camp table of his own, by his tent: a slatted top on crossed legs.
func _build_table() -> void:
	table = StaticBody3D.new()
	table.position = spot(TABLE_AT)
	camp.add_child(table)
	var top := MeshInstance3D.new()
	top.mesh = LowPoly.box(Vector3(TABLE_TOP.x, 0.03, TABLE_TOP.y), WOOD)
	top.position = Vector3(0, TABLE_HIGH - 0.015, 0)
	table.add_child(top)
	for z: float in [-TABLE_TOP.y * 0.36, TABLE_TOP.y * 0.36]:
		for lean: float in [-0.32, 0.32]:
			var leg := MeshInstance3D.new()
			leg.mesh = LowPoly.box(Vector3(0.03, TABLE_HIGH * 1.04, 0.03), WOOD_DARK)
			leg.position = Vector3(0, TABLE_HIGH * 0.5 - 0.02, z)
			leg.rotation.z = lean
			table.add_child(leg)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(TABLE_TOP.x, 0.06, TABLE_TOP.y)
	col.shape = shape
	col.position = Vector3(0, TABLE_HIGH - 0.03, 0)
	table.add_child(col)


## The cake: two round tiers of sponge under white frosting on a board, cherries round the top, and three
## lit candles. Its origin is the board's underside.
func _build_cake() -> void:
	cake = Node3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(LowPoly.loft([Vector3(0, 0, 0), Vector3(0, 0.015, 0)], [Vector2(0.21, 0.21), Vector2(0.21, 0.21)],
		12, LowPoly.solid(BOARD)), 0, Transform3D.IDENTITY)
	st.append_from(LowPoly.loft([Vector3(0, 0.015, 0), Vector3(0, 0.1, 0)], [Vector2(0.15, 0.15), Vector2(0.15, 0.15)],
		12, LowPoly.solid(SPONGE)), 0, Transform3D.IDENTITY)
	st.append_from(LowPoly.loft([Vector3(0, 0.1, 0), Vector3(0, 0.115, 0)], [Vector2(0.155, 0.155),
		Vector2(0.15, 0.15)], 12, LowPoly.solid(FROSTING)), 0, Transform3D.IDENTITY)
	st.append_from(LowPoly.loft([Vector3(0, 0.115, 0), Vector3(0, 0.18, 0)], [Vector2(0.1, 0.1), Vector2(0.1, 0.1)],
		10, LowPoly.solid(SPONGE)), 0, Transform3D.IDENTITY)
	st.append_from(LowPoly.loft([Vector3(0, 0.18, 0), Vector3(0, 0.192, 0)], [Vector2(0.104, 0.104),
		Vector2(0.098, 0.098)], 10, LowPoly.solid(FROSTING)), 0, Transform3D.IDENTITY)
	for i in 8:
		var a := TAU * i / 8.0
		var p := Vector3(cos(a) * 0.125, 0.125, sin(a) * 0.125)
		st.append_from(LowPoly.loft([p, p + Vector3(0, 0.022, 0)], [Vector2(0.012, 0.012), Vector2(0.008, 0.008)], 5,
			LowPoly.solid(CHERRY)), 0, Transform3D.IDENTITY)
	var flames := []
	for i in 3:
		var a := TAU * i / 3.0 + 0.3
		var p := Vector3(cos(a) * 0.05, 0.192, sin(a) * 0.05)
		st.append_from(LowPoly.loft([p, p + Vector3(0, 0.06, 0)], [Vector2(0.006, 0.006), Vector2(0.006, 0.006)], 5,
			LowPoly.solid(CANDLE)), 0, Transform3D.IDENTITY)
		flames.append(p + Vector3(0, 0.075, 0))
	var body := MeshInstance3D.new()
	body.mesh = LowPoly.commit(st)
	cake.add_child(body)
	var glow_mat := StandardMaterial3D.new()
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.albedo_color = FLAME
	glow_mat.emission_enabled = true
	glow_mat.emission = FLAME
	glow_mat.emission_energy_multiplier = 2.0
	for p: Vector3 in flames:
		var flame := MeshInstance3D.new()
		var drop := SphereMesh.new()
		drop.radius = 0.008
		drop.height = 0.024
		drop.radial_segments = 5
		drop.rings = 2
		drop.material = glow_mat
		flame.mesh = drop
		flame.position = p
		flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cake.add_child(flame)
		_flames.append(flame)
	var light := OmniLight3D.new()
	light.light_color = FLAME
	light.light_energy = 0.5
	light.omni_range = 1.2
	light.position = Vector3(0, 0.32, 0)
	cake.add_child(light)
	_flames.append(light)
	add_child(cake)


## The cutscene's bars, the end's fade and its card, over the game.
func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	_bars_top = ColorRect.new()
	_bars_top.color = Color.BLACK
	_bars_top.anchor_right = 1.0
	_bars_top.offset_bottom = 0.0
	_bars_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_bars_top)
	_bars_bottom = ColorRect.new()
	_bars_bottom.color = Color.BLACK
	_bars_bottom.anchor_top = 1.0
	_bars_bottom.anchor_right = 1.0
	_bars_bottom.anchor_bottom = 1.0
	_bars_bottom.offset_top = 0.0
	_bars_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_bars_bottom)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	_card = Label.new()
	_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_card.add_theme_font_size_override("font_size", 52)
	_card.add_theme_color_override("font_color", Color("f4ede0"))
	_card.visible = false
	layer.add_child(_card)


func _bars(on: bool) -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(_bars_top, "offset_bottom", BARS if on else 0.0, BARS_TIME)
	tween.tween_property(_bars_bottom, "offset_top", -BARS if on else 0.0, BARS_TIME)


## A word in the middle of the screen for a moment.
func _flash(text: String) -> void:
	_card.text = text
	_card.visible = true
	_card.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(0.6)
	tween.tween_property(_card, "modulate:a", 0.0, 0.5)
	tween.tween_callback(_hide_card)


func _show_card(text: String) -> void:
	_card.text = text
	_card.modulate.a = 1.0
	_card.visible = true


func _hide_card() -> void:
	_card.visible = false
	_card.modulate.a = 1.0
