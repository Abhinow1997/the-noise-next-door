extends Node3D
## The table's pizza in its boxes (camp_pizza.gd, camp_tutorial.gd). Asked for on 23 Nov 2026, the
## author: "Make one of the maybe the girl when she's coming back bring the pizza in. Like let's not
## have the pizza directly in there. Maybe she's bringing in like couple of boxes in stacked over
## inside the pizza". Two low-poly cardboard pizza boxes, stacked, built in code like the camp's other
## small props (camp_puzzles.gd, LowPoly.box).
##   - `carry`: closed, held level at the carrier's right hand (camp_person.gd `hand_grip`, on their
##     hand bone, as they carry a log or a snatched-back thing), following them as they go.
##   - `set_on`: on the table's cloth where its pizza is: the bottom box closed, the top one open
##     with its lid up, and the table's five slices (campsite.gd `table_pizza`) inside it.
##   - `spill` (Eat the pizza, the same day): pulled off the table with the cloth, on the ground,
##     the bottom box shut and the top one beside it, open, the slices in it.
## Presentation only: it reads the carrier and writes nothing in the game.

const LowPoly := preload("res://scripts/lowpoly.gd")

## Each box: how far across (m; the five slices span about 0.4 m), how deep, and its cardboard's
## thickness. How far the top one's lid opens, about its back edge (degrees), on the table and on
## the ground.
const SIZE := 0.42
const DEPTH := 0.045
const WALL := 0.008
const LID_OPEN := 105.0
const LID_SPILLED := 150.0
## Carried: the stack's middle this far out from the hand, and its bottom this far below it (m).
const HOLD_OUT := 0.2
const HOLD_DOWN := 0.035
## Spilled: where the top box lands from the bottom one (x, z, in the stack's space), and how far
## it's turned (degrees).
const SPILL_AT := Vector2(-0.36, 0.14)
const SPILL_TURN := 28.0
const CARDBOARD := Color("b58b5b")
const INSIDE := Color("d8c29b")
const PRINT := Color("a83a2e")

## Where the pizza sits in the top box.
var pizza_spot: Node3D

var _top: Node3D
var _lid: Node3D
var _carrier: Node3D
var _hand: BoneAttachment3D


func _ready() -> void:
	# Moved in _process while carried or falling, from what's drawn (interpolated).
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	# The bottom box, closed, with a band printed round its front.
	_box(Vector3(SIZE, DEPTH, SIZE), Vector3(0, DEPTH * 0.5, 0), CARDBOARD)
	_box(Vector3(SIZE * 0.92, DEPTH * 0.4, 0.003), Vector3(0, DEPTH * 0.5, SIZE * 0.5 + 0.0015), PRINT)
	# The top box, on it: its floor and four sides, open at the top for the lid.
	_top = Node3D.new()
	_top.position = Vector3(0, DEPTH, 0)
	add_child(_top)
	_box(Vector3(SIZE, WALL, SIZE), Vector3(0, WALL * 0.5, 0), INSIDE, _top)
	for z: float in [-1.0, 1.0]:
		_box(Vector3(SIZE, DEPTH, WALL), Vector3(0, DEPTH * 0.5, z * (SIZE - WALL) * 0.5), CARDBOARD, _top)
	for x: float in [-1.0, 1.0]:
		_box(Vector3(WALL, DEPTH, SIZE - WALL * 2.0), Vector3(x * (SIZE - WALL) * 0.5, DEPTH * 0.5, 0), CARDBOARD, _top)
	_box(Vector3(SIZE * 0.92, DEPTH * 0.4, 0.003), Vector3(0, DEPTH * 0.5, SIZE * 0.5 + 0.0015), PRINT, _top)
	pizza_spot = Node3D.new()
	pizza_spot.position = Vector3(0, WALL, 0)
	_top.add_child(pizza_spot)
	# The lid, hinged along the top box's back edge, with a band across it.
	_lid = Node3D.new()
	_lid.position = Vector3(0, DEPTH, -SIZE * 0.5)
	_top.add_child(_lid)
	_box(Vector3(SIZE, WALL, SIZE), Vector3(0, WALL * 0.5, SIZE * 0.5), CARDBOARD, _lid)
	_box(Vector3(SIZE * 0.92, 0.003, 0.07), Vector3(0, WALL + 0.0015, SIZE * 0.5), PRINT, _lid)


## Closed and held level at `carrier`'s right hand, till `set_on`.
func carry(carrier: Node3D) -> void:
	_stack()
	_lid.rotation.x = 0.0
	_carrier = carrier
	if get_parent() != carrier.get_parent():
		reparent(carrier.get_parent(), false)
	var skeletons := carrier.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		return
	_hand = BoneAttachment3D.new()
	_hand.bone_name = "mano_L"
	skeletons[0].add_child(_hand)
	_follow()


## Put down on `table` at `at` (in the table's space, on its top or cloth), open, with `pizza`
## inside.
func set_on(table: Node3D, at: Vector3, pizza: Node3D) -> void:
	_let_go()
	if get_parent() != table:
		if get_parent():
			reparent(table, false)
		else:
			table.add_child(self)
	transform = Transform3D(Basis(), at)
	_stack()
	_lid.rotation.x = -deg_to_rad(LID_OPEN)
	put_in(pizza)


## On the ground at `at`, turned `yaw`, under `parent`: the bottom box shut, the top one beside it
## and open, the pizza still in it.
func spill(parent: Node3D, at: Vector3, yaw: float) -> void:
	_let_go()
	if get_parent() != parent:
		reparent(parent, false)
	global_transform = Transform3D(Basis(Vector3.UP, yaw), at)
	_top.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(SPILL_TURN)), Vector3(SPILL_AT.x, 0.0, SPILL_AT.y))
	_lid.rotation.x = -deg_to_rad(LID_SPILLED)


## `pizza` (the table's slices) into the top box, as they lay on the table.
func put_in(pizza: Node3D) -> void:
	if pizza == null:
		return
	if pizza.get_parent() != pizza_spot:
		pizza.reparent(pizza_spot, false)
	pizza.transform = Transform3D.IDENTITY
	pizza.visible = true


## The top box, where the pizza is (in the world).
func pizza_point() -> Vector3:
	return pizza_spot.global_position


## True while someone's carrying it.
func carried() -> bool:
	return _carrier != null


func _process(_delta: float) -> void:
	if _carrier:
		_follow()


func _stack() -> void:
	_top.transform = Transform3D(Basis(), Vector3(0, DEPTH, 0))


func _let_go() -> void:
	_carrier = null
	if _hand:
		_hand.queue_free()
		_hand = null


## At the carrier's hand as it's drawn, out to their side and level, turned the way they face.
func _follow() -> void:
	if _hand == null or not is_instance_valid(_carrier):
		return
	var grip: Vector3 = _carrier.get("hand_grip") if _carrier.get("hand_grip") != null else Vector3.ZERO
	var hand := _hand.get_global_transform_interpolated() * grip
	var body := _carrier.get_global_transform_interpolated()
	var out := (hand - body.origin) * Vector3(1, 0, 1)
	if out.length() < 0.05:
		out = -body.basis.x
	global_transform = Transform3D(Basis(Vector3.UP, body.basis.get_euler().y),
		hand + out.normalized() * HOLD_OUT + Vector3.DOWN * HOLD_DOWN)


func _box(size: Vector3, at: Vector3, color: Color, parent: Node = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = LowPoly.box(size, color)
	mi.position = at
	(parent if parent else self).add_child(mi)
	return mi
