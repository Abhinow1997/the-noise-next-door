extends Node3D
## A yard of stand-ins for trying the six thought bubbles (thought_bubbles.gd) in the
## forest: `-- --bubble-demo`. None of it is the level's design; it's only here so the
## bubbles have something to react to:
##   - a camper who watches the yard, and takes back what he sees you carrying;
##   - coins, keys and a ball of foil (shiny), and a cooler (food; you start hungry);
##   - a hose and an empty bucket (the hose is the bucket's idea);
##   - a shed whose door only the keys open, and a bush to hide in.
## A panel at the top right lists what to try and crosses each off once its bubble shows.

const Player := preload("res://scripts/player.gd")
const ThoughtBubbles := preload("res://scripts/thought_bubbles.gd")
const VisionCone := preload("res://scripts/vision_cone.gd")
const HideSpot := preload("res://scripts/hide_spot.gd")
const LowPoly := preload("res://scripts/lowpoly.gd")
const CAMPER_PATH := "res://assets/characters/camper.glb"
const COOLER_PATH := "res://assets/props/cooler.glb"

## Where things stand: metres right of where he starts and ahead of it, as the camera
## looks (right is to the right of the screen, ahead is into it).
const LOOT := Vector2(-5.5, 1.5)
const CAMPER := Vector2(-7.5, 4.0)
const BUSH := Vector2(-4.0, 0.0)
const SHED := Vector2(-9.0, 0.6)
const HOSE := Vector2(-2.5, -2.5)
const BUCKET := Vector2(-6.0, -2.8)
const COOLER := Vector2(4.5, -1.5)
## Getting this close to the cooler ends the "find food" task.
const FED_AT := 1.3
## The bush's hiding spot: smaller than the bush, so he has to get right in.
const BUSH_HIDE := 0.4

const GOLD := Color("f2c230")
const GOLD_EDGE := Color("c9971c")
const BRASS := Color("d9a93a")
const SILVER := Color("c9ced3")
const FOIL := Color("d7dce0")
const FOIL_DARK := Color("98a2ab")
const HOSE_GREEN := Color("3e9b4f")
const NOZZLE := Color("f2c230")
const PAIL := Color("8fa0ae")
const PAIL_DARK := Color("6f7f8c")
const PAIL_INSIDE := Color("3e4a55")
const WATER := Color("5b8fc9")
const WOOD := Color("8c6a48")
const WOOD_DARK := Color("6a4e36")
const FRAME := Color("5a4330")
const ROOF := Color("5e4b3e")
const INSIDE := Color("241c16")

const TRIES := [
	["shiny", "Shiny: walk near the coins, keys and foil"],
	["hungry", "Hungry: face the cooler or the trash bin up close"],
	["alert", "Alert: let the camper see you"],
	["hiding", "Hiding: duck into the bush while he's looking"],
	["idea", "Idea: pick up the keys or the hose, then use it"],
	["frustrated", "Frustrated: walk into a wall, try the shed door\n    without the keys, or get caught with loot"],
	["bored", "Bored: stand still for a few seconds"],
	["laugh", "Laugh: chitter (Space)"],
	["asleep", "Asleep: sneak into your den and keep still"],
]

## Set by the level (main.gd).
var level: Node
var camper: Watcher
var shed: Shed
var bucket: Bucket
var cooler: StaticBody3D
var bush: HideSpot
var coins: RigidBody3D
var keys: RigidBody3D
var foil: RigidBody3D
var hose: RigidBody3D

var _tried := {}
var _list: RichTextLabel


## The camper stand-in. He stands watching the yard, looking slowly from side to side.
## If he sees you carrying something, he comes (not far) to take it back, and it goes
## back where it came from. When he loses sight of you, he goes back to his spot.
class Watcher extends Node3D:
	## Degrees he looks to each side, and how fast (radians of the sweep a second).
	const LOOK_AROUND := 50.0
	const LOOK_RATE := 0.5
	## How fast he turns (rad/s), comes after you and walks back (m/s), how far from
	## his spot he'll go, how close he has to get to take it, and how long he looks
	## for you before giving up.
	const TURN := 3.0
	const CHASE := 1.7
	const WALK_BACK := 1.1
	const LEASH := 4.0
	const REACH := 1.0
	const GIVE_UP := 1.0

	var player: Player
	var eyes: VisionCone
	var post := Vector3.ZERO
	var facing := 0.0
	## Off for the automated check, so where he looks doesn't depend on timing.
	var look_around := true
	var model: Node3D
	var _t := 0.0
	var _lost := 0.0
	var _walk := 0.0
	var _busy := 0.0

	func _physics_process(delta: float) -> void:
		_t += delta
		_busy = maxf(_busy - delta, 0.0)
		var want := rotation.y
		var move := Vector3.ZERO
		var to_him := player.global_position - global_position
		to_him.y = 0.0
		var to_post := post - global_position
		to_post.y = 0.0
		if eyes.seeing:
			_lost = 0.0
			want = atan2(-to_him.x, -to_him.z)
			if player.held and _busy <= 0.0:
				if to_him.length() <= REACH:
					_take_back()
				elif (global_position + to_him.normalized() * CHASE * delta).distance_to(post) <= LEASH:
					move = to_him.normalized() * CHASE
		else:
			_lost += delta
			if to_post.length() > 0.05:
				if _lost > GIVE_UP:
					want = atan2(-to_post.x, -to_post.z)
					move = to_post.normalized() * minf(WALK_BACK, to_post.length() / delta)
			elif look_around:
				want = facing + deg_to_rad(LOOK_AROUND) * sin(_t * LOOK_RATE)
			else:
				want = facing
		rotation.y = rotate_toward(rotation.y, want, TURN * delta)
		global_position += move * delta
		# A bob in his step, as he has no walk of his own.
		_walk = move_toward(_walk, 1.0 if move.length() > 0.1 else 0.0, delta * 5.0)
		model.position.y = absf(sin(_t * 9.0)) * 0.05 * _walk

	## Takes what he's carrying out of his mouth and puts it back where it came from.
	func _take_back() -> void:
		var item: RigidBody3D = player.held
		player._drop()
		item.linear_velocity = Vector3.ZERO
		item.angular_velocity = Vector3.ZERO
		item.global_transform = item.get_meta("home", item.global_transform)
		item.reset_physics_interpolation()
		_busy = 2.5
		ThoughtBubbles.notify(self, "frustrated")


## A shed with a locked door. E at the door without the keys rattles it (and he's
## frustrated); with the keys in his mouth, they go into the lock and it swings open.
class Shed extends StaticBody3D:
	const WIDTH := 1.4
	const HEIGHT := 1.7
	const DEPTH := 1.1
	const DOOR_X := 0.18
	const DOOR_SIZE := Vector2(0.7, 1.3)
	## How near the door he has to stand to try it.
	const TRY_FROM := 0.8

	var player: Player
	var opened := false
	var door: Node3D
	var lock: Node3D

	func build() -> void:
		var walls := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(WIDTH, HEIGHT, DEPTH)
		walls.shape = box
		walls.position.y = HEIGHT * 0.5
		add_child(walls)
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		LowPoly.add_box(st, Transform3D(Basis(), Vector3(0, HEIGHT * 0.5, 0)), Vector3(WIDTH, HEIGHT, DEPTH), WOOD)
		# Boards up the front and sides, a roof, the door frame and the dark inside.
		for x: float in [-0.56, -0.36, 0.54]:
			LowPoly.add_box(st, Transform3D(Basis(), Vector3(x, HEIGHT * 0.5, DEPTH * 0.5 + 0.005)),
				Vector3(0.025, HEIGHT - 0.06, 0.012), WOOD_DARK)
		LowPoly.add_box(st, Transform3D(Basis(), Vector3(0, HEIGHT + 0.045, 0.06)), Vector3(WIDTH + 0.24, 0.09, DEPTH + 0.3), ROOF)
		LowPoly.add_box(st, Transform3D(Basis(), Vector3(DOOR_X, DOOR_SIZE.y * 0.5 + 0.03, DEPTH * 0.5 + 0.012)),
			Vector3(DOOR_SIZE.x + 0.12, DOOR_SIZE.y + 0.1, 0.02), FRAME)
		LowPoly.add_box(st, Transform3D(Basis(), Vector3(DOOR_X, DOOR_SIZE.y * 0.5 + 0.03, DEPTH * 0.5 + 0.024)),
			Vector3(DOOR_SIZE.x - 0.02, DOOR_SIZE.y - 0.02, 0.006), INSIDE)
		var walls_mesh := MeshInstance3D.new()
		walls_mesh.mesh = LowPoly.commit(st)
		add_child(walls_mesh)

		# The door hangs from its left edge.
		door = Node3D.new()
		door.position = Vector3(DOOR_X - DOOR_SIZE.x * 0.5, 0.03, DEPTH * 0.5 + 0.05)
		add_child(door)
		st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var mid := Vector3(DOOR_SIZE.x * 0.5, DOOR_SIZE.y * 0.5, 0)
		LowPoly.add_box(st, Transform3D(Basis(), mid), Vector3(DOOR_SIZE.x, DOOR_SIZE.y, 0.045), WOOD_DARK)
		for y: float in [0.2, DOOR_SIZE.y - 0.2]:
			LowPoly.add_box(st, Transform3D(Basis(), Vector3(DOOR_SIZE.x * 0.5, y, 0.03)), Vector3(DOOR_SIZE.x - 0.06, 0.07, 0.02), FRAME)
		LowPoly.add_box(st, Transform3D(Basis(Vector3.BACK, atan2(DOOR_SIZE.y - 0.4, DOOR_SIZE.x - 0.1)), mid + Vector3(0, 0, 0.03)),
			Vector3(sqrt(pow(DOOR_SIZE.x - 0.1, 2) + pow(DOOR_SIZE.y - 0.4, 2)), 0.06, 0.018), FRAME)
		# The padlock, by the door's free edge.
		LowPoly.add_box(st, Transform3D(Basis(), Vector3(DOOR_SIZE.x - 0.09, 0.66, 0.045)), Vector3(0.08, 0.09, 0.04), BRASS)
		LowPoly.add_box(st, Transform3D(Basis(), Vector3(DOOR_SIZE.x - 0.09, 0.73, 0.045)), Vector3(0.06, 0.05, 0.012), SILVER)
		var door_mesh := MeshInstance3D.new()
		door_mesh.mesh = LowPoly.commit(st)
		door.add_child(door_mesh)
		var door_body := StaticBody3D.new()
		var door_shape := CollisionShape3D.new()
		var slab := BoxShape3D.new()
		slab.size = Vector3(DOOR_SIZE.x, DOOR_SIZE.y, 0.05)
		door_shape.shape = slab
		door_shape.position = mid
		door_body.add_child(door_shape)
		door.add_child(door_body)
		lock = Node3D.new()
		lock.position = Vector3(DOOR_SIZE.x - 0.09, 0.62, 0.075)
		door.add_child(lock)

	## Where he stands to try the door.
	func at_door() -> Vector3:
		return global_transform * Vector3(DOOR_X, 0.0, DEPTH * 0.5 + 0.5)

	func _unhandled_input(event: InputEvent) -> void:
		if opened or not event.is_action_pressed("grab"):
			return
		if player.resting or player.climbing or player.is_hopping():
			return
		if player.global_position.distance_to(at_door()) > TRY_FROM:
			return
		# The door takes the key press, so he doesn't also drop or pick something up.
		get_viewport().set_input_as_handled()
		var item: RigidBody3D = player.held
		if item and item.is_in_group(get_meta("needs")):
			_unlock(item)
		else:
			_rattle()
			ThoughtBubbles.notify(self, "frustrated")

	func _unlock(key: RigidBody3D) -> void:
		player._drop()
		key.freeze = true
		key.collision_layer = 0
		key.collision_mask = 0
		key.remove_from_group("grabbable")
		key.reparent(lock, false)
		key.transform = Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3.ZERO)
		key.reset_physics_interpolation()
		opened = true
		set_meta("solved", true)
		var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		tween.tween_interval(0.25)
		tween.tween_property(door, "rotation:y", deg_to_rad(-105.0), 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	func _rattle() -> void:
		var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		for angle: float in [-0.05, 0.035, -0.02, 0.0]:
			tween.tween_property(door, "rotation:y", angle, 0.06)


## An empty bucket. Put the hose down beside it and it fills.
class Bucket extends StaticBody3D:
	## How near the hose has to be put down.
	const FILL_AT := 0.9

	var player: Player
	var water: MeshInstance3D

	func _physics_process(_delta: float) -> void:
		if get_meta("solved", false):
			return
		for node: Node in get_tree().get_nodes_in_group(get_meta("needs")):
			var thing := node as Node3D
			if thing == player.held:
				continue
			var d := Vector2(thing.global_position.x - global_position.x, thing.global_position.z - global_position.z)
			if d.length() < FILL_AT:
				set_meta("solved", true)
				water.visible = true
				water.scale = Vector3(0.2, 1, 0.2)
				var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
				tween.tween_property(water, "scale", Vector3.ONE, 1.2).set_trans(Tween.TRANS_SINE)
				return


func _ready() -> void:
	_build_loot()
	_build_hose_and_bucket()
	_build_shed()
	_build_bush()
	_build_cooler()
	_build_camper()
	# Everything he can carry remembers where it came from, so the camper can put it back.
	for node: Node in get_tree().get_nodes_in_group("grabbable"):
		if not node.has_meta("home"):
			node.set_meta("home", (node as Node3D).global_transform)
	level.bubbles.hungry_objective = true
	level.bubbles.shown.connect(_on_shown)
	level.bubbles.glinted.connect(func(_loot: Node3D) -> void: _on_shown("shiny"))
	_build_panel()


func _physics_process(_delta: float) -> void:
	if level.bubbles.hungry_objective and level.player.global_position.distance_to(cooler.global_position) < FED_AT:
		level.bubbles.hungry_objective = false


## A spot in the yard (see LOOT), on the ground.
func spot(at: Vector2) -> Vector3:
	var yaw := deg_to_rad(level.CAMERA_YAW)
	var p: Vector3 = level.Forest.START + Vector3.RIGHT.rotated(Vector3.UP, yaw) * at.x + Vector3.FORWARD.rotated(Vector3.UP, yaw) * at.y
	p.y = 0.0
	return p


func _build_loot() -> void:
	var at := spot(LOOT)
	coins = level._prop(at, 0.2, level._cylinder(0.05, 0.04), Vector3(0, 0.02, 0),
		["grabbable", "shiny", "coins"], 0.05, Vector3(0, -0.04, -0.03))
	for i in 3:
		var y := 0.013 * i
		var off := Vector3([0.0, 0.008, -0.006][i], 0, [0.0, -0.006, 0.007][i])
		level._mesh(LowPoly.loft([off + Vector3(0, y, 0), off + Vector3(0, y + 0.012, 0)],
			[Vector2(0.045, 0.045), Vector2(0.045, 0.045)], 10,
			func(segment: int, _side: int, _n: Vector3) -> Color: return GOLD_EDGE if segment == 0 else GOLD),
			Vector3.ZERO, coins)

	var box := BoxShape3D.new()
	box.size = Vector3(0.2, 0.025, 0.14)
	keys = level._prop(spot(LOOT + Vector2(0.5, 0.2)), 0.1, box, Vector3(0.05, 0.0125, 0),
		["grabbable", "shiny", "key"], 0.07, Vector3(0, -0.03, -0.03), Vector3(0.3, 0, 0))
	level._mesh(_keys_mesh(), Vector3.ZERO, keys, 0.6)

	var ball := SphereShape3D.new()
	ball.radius = 0.055
	foil = level._prop(spot(LOOT + Vector2(-0.4, 0.35)), 0.05, ball, Vector3(0, 0.055, 0),
		["grabbable", "shiny", "foil"], 0.05, Vector3(0, -0.05, -0.03))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	LowPoly.add_icosphere(st, Vector3(0, 0.052, 0), Vector3(0.056, 0.05, 0.056), 1, 0.25, 7,
		func(n: Vector3) -> Color: return FOIL.lerp(FOIL_DARK, clampf(0.45 - n.y * 0.45 + n.x * 0.25, 0.0, 1.0)))
	level._mesh(LowPoly.commit(st), Vector3.ZERO, foil)


## A key ring with two keys, lying flat.
func _keys_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring: Array = []
	var radii: Array = []
	for i in 13:
		var a := TAU * i / 12.0
		ring.append(Vector3(cos(a) * 0.035, 0.008, sin(a) * 0.035))
		radii.append(0.006)
	LowPoly.add_tube(st, ring, radii, 5, LowPoly.solid(SILVER))
	for k in 2:
		var turn := Transform3D(Basis(Vector3.UP, [0.25, -0.75][k]), Vector3.ZERO)
		var color: Color = [BRASS, SILVER][k]
		LowPoly.add_box(st, turn.translated_local(Vector3(0.058, 0.008, 0)), Vector3(0.032, 0.012, 0.03), color)
		LowPoly.add_box(st, turn.translated_local(Vector3(0.11, 0.008, 0)), Vector3(0.075, 0.008, 0.014), color)
		LowPoly.add_box(st, turn.translated_local(Vector3(0.132, 0.008, 0.011)), Vector3(0.012, 0.008, 0.012), color)
		LowPoly.add_box(st, turn.translated_local(Vector3(0.112, 0.008, 0.01)), Vector3(0.01, 0.008, 0.01), color)
	return LowPoly.commit(st)


func _build_hose_and_bucket() -> void:
	hose = level._prop(spot(HOSE), 0.6, level._cylinder(0.18, 0.11), Vector3(0, 0.055, 0),
		["grabbable", "hose"], 0.17, Vector3(0, -0.13, -0.1), Vector3(1.25, 0, 0))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Three loose coils, then the end led out to its nozzle.
	var centers: Array = []
	var radii: Array = []
	var steps := 48
	for i in steps + 1:
		var a := TAU * 3.0 * i / steps
		centers.append(Vector3(cos(a) * 0.15, 0.022 + 0.078 * i / steps, sin(a) * 0.15))
		radii.append(0.02)
	centers.append(Vector3(0.24, 0.1, 0.02))
	radii.append(0.02)
	centers.append(Vector3(0.3, 0.1, 0.05))
	radii.append(0.02)
	LowPoly.add_tube(st, centers, radii, 6, LowPoly.solid(HOSE_GREEN))
	LowPoly.add_tube(st, [Vector3(0.3, 0.1, 0.05), Vector3(0.36, 0.1, 0.08)], [0.026, 0.02], 6, LowPoly.solid(NOZZLE))
	level._mesh(LowPoly.commit(st), Vector3.ZERO, hose)

	bucket = Bucket.new()
	bucket.player = level.player
	bucket.position = spot(BUCKET)
	bucket.add_to_group("puzzle")
	bucket.set_meta("needs", "hose")
	bucket.set_meta("solved", false)
	add_child(bucket)
	var col := CollisionShape3D.new()
	col.shape = level._cylinder(0.19, 0.3)
	col.position.y = 0.15
	bucket.add_child(col)
	# The end cap at the rim is painted dark, so it reads as the inside.
	level._mesh(LowPoly.loft([Vector3(0, 0, 0), Vector3(0, 0.27, 0), Vector3(0, 0.3, 0)],
		[Vector2(0.15, 0.15), Vector2(0.185, 0.185), Vector2(0.195, 0.195)], 10, _pail_color),
		Vector3.ZERO, bucket)
	var handle: Array = []
	var thick: Array = []
	for i in 9:
		var a := PI * i / 8.0
		handle.append(Vector3(cos(a) * 0.19, 0.28 + sin(a) * 0.14, 0))
		thick.append(0.008)
	st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	LowPoly.add_tube(st, handle, thick, 4, LowPoly.solid(PAIL_DARK))
	level._mesh(LowPoly.commit(st), Vector3.ZERO, bucket, 0.5)
	bucket.water = level._mesh(LowPoly.loft([Vector3(0, 0.301, 0), Vector3(0, 0.304, 0)],
		[Vector2(0.18, 0.18), Vector2(0.18, 0.18)], 10, LowPoly.solid(WATER)), Vector3.ZERO, bucket)
	bucket.water.visible = false



func _pail_color(segment: int, _side: int, _n: Vector3) -> Color:
	return PAIL_INSIDE if segment == 2 else (PAIL_DARK if segment == 1 else PAIL)


func _build_shed() -> void:
	shed = Shed.new()
	shed.player = level.player
	shed.position = spot(SHED)
	# Its door faces the camera.
	shed.rotation.y = deg_to_rad(level.CAMERA_YAW)
	shed.add_to_group("puzzle")
	shed.set_meta("needs", "key")
	shed.set_meta("solved", false)
	add_child(shed)
	shed.build()


func _build_bush() -> void:
	var at := spot(BUSH)
	var leaves := MeshInstance3D.new()
	leaves.mesh = level.forest._bush_mesh(401)
	# Like the forest's own bushes, it opens a window where it hides him.
	leaves.material_override = level.forest.see_through
	leaves.position = at
	leaves.rotation.y = 0.7
	add_child(leaves)
	bush = HideSpot.new()
	bush.position = at
	var col := CollisionShape3D.new()
	col.shape = level._cylinder(BUSH_HIDE, 1.2)
	col.position.y = 0.6
	bush.add_child(col)
	add_child(bush)


func _build_cooler() -> void:
	cooler = StaticBody3D.new()
	cooler.position = spot(COOLER)
	cooler.rotation.y = deg_to_rad(level.CAMERA_YAW + 15.0)
	cooler.add_to_group("food")
	add_child(cooler)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.58, 0.36, 0.36)
	col.shape = box
	col.position.y = 0.18
	cooler.add_child(col)
	if ResourceLoader.exists(COOLER_PATH):
		cooler.add_child((load(COOLER_PATH) as PackedScene).instantiate())
	else:
		level._mesh(LowPoly.box(box.size, Color("3b7dbf")), Vector3(0, 0.18, 0), cooler)


func _build_camper() -> void:
	camper = Watcher.new()
	camper.player = level.player
	camper.position = spot(CAMPER)
	var to_loot := spot(LOOT) - camper.position
	camper.facing = atan2(-to_loot.x, -to_loot.z)
	camper.rotation.y = camper.facing
	camper.post = camper.position
	# The camera leans toward him when the raccoon is near (main.gd _camper_lean).
	camper.add_to_group("camper")
	add_child(camper)
	if ResourceLoader.exists(CAMPER_PATH):
		camper.model = (load(CAMPER_PATH) as PackedScene).instantiate()
		# The model faces +Z; the camper looks along -Z.
		camper.model.rotation.y = PI
	else:
		camper.model = Node3D.new()
		var stand_in := MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.28
		capsule.height = 1.8
		stand_in.mesh = capsule
		stand_in.position.y = 0.9
		camper.model.add_child(stand_in)
	camper.add_child(camper.model)
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	col.shape = level._cylinder(0.28, 1.8)
	col.position.y = 0.9
	body.add_child(col)
	camper.add_child(body)
	var eyes := VisionCone.new()
	eyes.position = Vector3(0, 1.62, -0.12)
	eyes.ignore.append(body.get_rid())
	camper.add_child(eyes)
	camper.eyes = eyes


func _build_panel() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f4eedc")
	style.set_corner_radius_all(6)
	style.set_content_margin_all(16)
	style.shadow_color = Color(0, 0, 0, 0.18)
	style.shadow_size = 6
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	_list = RichTextLabel.new()
	_list.bbcode_enabled = true
	_list.fit_content = true
	_list.custom_minimum_size = Vector2(360, 0)
	_list.add_theme_color_override("default_color", Color("3b3630"))
	_list.add_theme_font_size_override("normal_font_size", 15)
	_list.add_theme_font_size_override("bold_font_size", 15)
	panel.add_child(_list)
	_refresh()
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 24)


func _on_shown(kind: String) -> void:
	if kind != "" and not _tried.has(kind):
		_tried[kind] = true
		_refresh()


func _refresh() -> void:
	var text := "[b]Thought bubbles: try these[/b]\n"
	for t: Array in TRIES:
		if _tried.has(t[0]):
			text += "\n[color=#a39a88][s]%s[/s][/color]" % t[1]
		else:
			text += "\n•  %s" % t[1]
	_list.text = text
