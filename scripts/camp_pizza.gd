extends Node3D
## Eat the pizza, a level 1 task at the camp (camp_tasks.gd "pizza"), asked for on 23 Nov 2026,
## the author: "i want the table to have like a cloth and us to have an option of like pulling it.
## So when you pull it, the boxes drop and then we can potentially eat it", and "we need a new
## animation for the raccon where he is dragging this we might use for other things as well in
## the game". The plan was Claude Code's, kept by the author ("Yes, build both").
##   - A checked cloth lies over the pizza end of the table (its west half; the laptop is part of
##     the table's model and stays put), hanging down over the end to where his jaws reach. The
##     pizza's boxes (pizza_boxes.gd) sit on it, the top one open.
##   - Once the tutorial's done (camp_tasks.gd `revealed`) and the boxes are on it, holding E at
##     its hanging edge (PULL_TIME) drags at it: he plays his `drag` clip (interactable.gd `drag`),
##     tugging, and the cloth inches toward him with the boxes on it.
##   - Pulled off, it and the boxes come down off the end of the table (FALL) and land with a
##     clatter heard CLATTER round, as his landing from a jump is (campsite.gd HEAR_STEPS): anyone
##     near enough comes to look. The bottom box lands shut, the top one open beside it with the
##     pizza in it; the cloth lies in a heap.
##   - Holding E at the open box (EAT_FOR) he takes a slice, sits up and eats it from his paws in
##     BITES bites, as he eats the marshmallow (roast_plate.gd, raccoon_eat.gd). The first one
##     eaten ticks the task. There are five; each can be eaten.
##   - Nobody tidies it up yet: the boxes and the cloth stay where they fell.
## Built here in code, like the camp's other props. campsite.gd adds it; the tutorial's girl
## carries the boxes in and puts them back on the cloth (camp_tutorial.gd).

const Interactable := preload("res://scripts/interactable.gd")
const LowPoly := preload("res://scripts/lowpoly.gd")
const PizzaBoxes := preload("res://scripts/pizza_boxes.gd")
const RaccoonEat := preload("res://scripts/raccoon_eat.gd")

## The cloth, in the table's space (campsite.gd TABLE; its top is 1.28 × 0.83 m, at 0.742): from the
## table's west edge to CLOTH_TO, front to back and a little over each side, hanging HANG down
## over the end, checked in squares CHECK across.
const TOP_Y := 0.742
const THICK := 0.004
const EDGE_X := -0.64
const CLOTH_TO := -0.06
const CLOTH_Z := 0.44
const HANG := 0.34
const CHECK := 0.08
const RED := Color("b23a32")
const CREAM := Color("efe6d2")
## Pulling it: how long E's held (s), how far the tugging's heard (m), and how far the cloth, and
## what's on it, comes toward him while he tugs (m).
const PULL_TIME := 1.5
const PULL_NOISE := 1.0
const SLIDE := 0.14
## Coming down: how fast it falls (m/s²), how far off the table's end the boxes land and how far
## they tip going over (degrees), and how far the clatter's heard (m, as campsite.gd HEAR_STEPS).
## Where the cloth lands in a heap, from the table's west edge (x, z in its space).
const FALL := 14.0
const LAND_OUT := 0.34
const TIP := 35.0
const CLATTER := 6.0
const HEAP_AT := Vector2(-0.5, 0.3)
## Eating a slice: how long E's held, in how many bites, how far the munching's heard, how big the
## slice is in his paws (times its own size), and how long and how hard a chomp squashes it.
const EAT_FOR := 2.4
const BITES := 3
const EAT_NOISE := 0.8
const IN_PAWS := 0.55
const SQUASH_FOR := 0.12
const SQUASH := 0.3

## Set before it's added (campsite.gd): the camp, its table, and the table's pizza (its five slices).
var camp
var table: Node3D
var slices: Node3D
## The boxes, on the cloth to start with.
var boxes: PizzaBoxes
## Pulled off the table; down on the ground; slices eaten so far.
var pulled := false
var down := false
var eaten := 0

var _cloth: Node3D
var _heap: Node3D
var _pull: Interactable
var _eat: Interactable
var _boxes_at := Vector3.ZERO
var _fall_t := -1.0
var _fall_from := Transform3D.IDENTITY
var _cloth_from := Transform3D.IDENTITY
var _player
## The slice in his paws while he eats it, where it lay in the box, and how much of it's eaten.
var _slice: Node3D
var _slice_was := Transform3D.IDENTITY
var _bitten := 0.0


func _ready() -> void:
	_cloth = Node3D.new()
	table.add_child(_cloth)
	_cloth.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_mesh(_cloth_mesh(), _cloth)
	_heap = Node3D.new()
	_heap.visible = false
	add_child(_heap)
	_mesh(_heap_mesh(), _heap)
	boxes = PizzaBoxes.new()
	table.add_child(boxes)
	_boxes_at = Vector3(slices.position.x, TOP_Y + THICK, slices.position.z)
	boxes.set_on(table, _boxes_at, slices)
	_pull = Interactable.new()
	_pull.hold_time = PULL_TIME
	_pull.noise = PULL_NOISE
	_pull.drag = true
	_pull.camp = camp
	_pull.prompt_height = 0.25
	_pull.enabled = func() -> bool: return not pulled and camp.tasks != null and camp.tasks.revealed and on_table()
	_pull.progressed.connect(_slide)
	_pull.finished.connect(_pull_off)
	add_child(_pull)
	_pull.global_position = table.global_transform * Vector3(EDGE_X - 0.02, TOP_Y - HANG + 0.05, 0.0)
	_eat = Interactable.new()
	_eat.hold_time = EAT_FOR
	_eat.noise = EAT_NOISE
	_eat.camp = camp
	_eat.prompt_height = 0.3
	_eat.enabled = func() -> bool: return down and (slices_left() > 0 or _slice != null)
	_eat.finished.connect(_ate)
	add_child(_eat)


## True while the boxes are on the cloth, on the table (not being carried in, not hidden).
func on_table() -> bool:
	return boxes.visible and boxes.get_parent() == table and not boxes.carried()


## The boxes back on the cloth, open, with the pizza in them (the tutorial's girl puts them there).
func put_on_table() -> void:
	boxes.visible = true
	boxes.set_on(table, _boxes_at, slices)


## How many slices are left to eat.
func slices_left() -> int:
	var n := 0
	for slice: Node in slices.get_children():
		if slice is Node3D and slice.visible and slice != _slice:
			n += 1
	return n


## Where he stands to pull the cloth (for the tests): off the table's west end, facing its edge.
func pull_from() -> Vector3:
	return table.global_transform * Vector3(EDGE_X - 0.42, 0.02, 0.0)


## Where the hem he pulls is, and where the open box is once it's down (for the tests).
func pull_point() -> Vector3:
	return _pull.global_position


func eat_point() -> Vector3:
	return _eat.global_position


## E held at the hem: the cloth, and the boxes on it, come toward him as he tugs.
func _slide(f: float) -> void:
	if pulled:
		return
	_cloth.position = Vector3(-SLIDE * f, 0.0, 0.0)
	if on_table():
		boxes.position = _boxes_at + Vector3(-SLIDE * f, 0.0, 0.0)


## Pulled off: down it all comes, off the end of the table.
func _pull_off() -> void:
	pulled = true
	_fall_t = 0.0
	if on_table():
		boxes.reparent(self, true)
	_fall_from = boxes.global_transform
	_cloth_from = _cloth.global_transform


func _process(delta: float) -> void:
	if _fall_t >= 0.0:
		_fall(delta)
	_eat_process()


## Off the end and down: the boxes go out over the edge, tipping, and fall; the cloth with them.
func _fall(delta: float) -> void:
	_fall_t += delta
	var drop := _fall_from.origin.y
	var time := sqrt(2.0 * maxf(drop, 0.01) / FALL)
	var k := clampf(_fall_t / time, 0.0, 1.0)
	var west := -table.global_basis.x
	var fall := 0.5 * FALL * minf(_fall_t, time) ** 2
	var tip := Basis(table.global_basis.z, deg_to_rad(TIP) * k)
	boxes.global_transform = Transform3D(tip * _fall_from.basis,
		_fall_from.origin + west * LAND_OUT * k + Vector3.DOWN * minf(fall, drop))
	_cloth.global_transform = Transform3D(_cloth_from.basis,
		_cloth_from.origin + west * LAND_OUT * k + Vector3.DOWN * minf(fall, TOP_Y))
	if k >= 1.0:
		_fall_t = -1.0
		_land()


## Down: the boxes spilled on the ground, the cloth in a heap, and a clatter the campers hear.
func _land() -> void:
	var at := boxes.global_position * Vector3(1, 0, 1)
	boxes.spill(self, at, table.global_rotation.y)
	_cloth.visible = false
	_heap.visible = true
	_heap.global_transform = Transform3D(table.global_basis, table.global_transform * Vector3(EDGE_X + HEAP_AT.x, 0.0, HEAP_AT.y))
	down = true
	slices.add_to_group("food")
	_eat.global_position = boxes.pizza_point()
	if camp:
		camp.noise(at, CLATTER, 0.0, true)


## Eating while E's held at the open box: a slice in his paws, bite by bite, sitting up (raccoon_model.gd
## `eating`). Let go, and the slice goes back where it was, as eaten as it was.
func _eat_process() -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
	if _player == null or _player.model == null:
		return
	var model = _player.model
	if _eat.working and model.paws != null:
		if _slice == null:
			_take_slice(model)
		if _slice == null:
			return
		_bitten = maxf(_bitten, _eat.progress)
		_eat.progress = _bitten
		var f := minf(_bitten * BITES, BITES - 0.001)
		var phase := f - floorf(f)
		model.eating = true
		model.eat_bite = phase
		var bites := clampi(floori(f - RaccoonEat.CHOMP) + 1, 0, BITES)
		var since := phase - RaccoonEat.CHOMP
		var squash := SQUASH * (1.0 - since / SQUASH_FOR) if since >= 0.0 and since < SQUASH_FOR else 0.0
		var size := IN_PAWS * (1.0 - 0.8 * bites / BITES)
		_slice.scale = Vector3(1.0 + squash * 0.5, 1.0 - squash, 1.0 + squash * 0.5) * size
	elif _slice != null:
		# Let go before it's eaten: back in the box.
		_put_slice_back()
		model.eating = false
		model.eat_bite = -1.0


func _take_slice(model) -> void:
	for slice: Node in slices.get_children():
		if slice is Node3D and slice.visible:
			_slice = slice
			_slice_was = slice.transform
			_slice.reparent(model.paws, false)
			_slice.transform = Transform3D(Basis(), Vector3.ZERO)
			_slice.scale = Vector3.ONE * IN_PAWS
			return


func _put_slice_back() -> void:
	if _slice == null:
		return
	_slice.reparent(slices, false)
	_slice.transform = _slice_was
	_slice = null


## A slice eaten: gone, and the task's done with the first.
func _ate() -> void:
	if _slice:
		_slice.queue_free()
		_slice = null
	_bitten = 0.0
	_eat.reset()
	eaten += 1
	if _player and _player.model:
		_player.model.eating = false
		_player.model.eat_bite = -1.0
	if camp and camp.tasks:
		camp.tasks.done("pizza")
	if slices_left() == 0:
		slices.remove_from_group("food")


## The cloth: a checked top over the table's west end and a drop over that end, in squares.
func _cloth_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx := ceili((CLOTH_TO - EDGE_X) / CHECK)
	var nz := ceili(CLOTH_Z * 2.0 / CHECK)
	var w := (CLOTH_TO - EDGE_X) / nx
	var d := CLOTH_Z * 2.0 / nz
	for i in nx:
		for j in nz:
			LowPoly.add_box(st, Transform3D(Basis(), Vector3(EDGE_X + w * (i + 0.5), TOP_Y + THICK * 0.5,
				-CLOTH_Z + d * (j + 0.5))), Vector3(w, THICK, d), RED if (i + j) % 2 == 1 else CREAM)
	var nh := ceili(HANG / CHECK)
	var h := HANG / nh
	for k in nh:
		for j in nz:
			LowPoly.add_box(st, Transform3D(Basis(), Vector3(EDGE_X - THICK * 0.5, TOP_Y - h * (k + 0.5),
				-CLOTH_Z + d * (j + 0.5))), Vector3(THICK, h, d), RED if (k + j) % 2 == 0 else CREAM)
	return LowPoly.commit(st)


## The cloth pulled off: a low, rumpled heap on the ground.
func _heap_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var folds := [[Vector3(0, 0.02, 0), Vector3(0.4, 0.04, 0.32), 0.0, CREAM],
		[Vector3(0.05, 0.05, -0.03), Vector3(0.3, 0.04, 0.24), 0.4, RED],
		[Vector3(-0.06, 0.08, 0.04), Vector3(0.22, 0.04, 0.18), -0.3, CREAM],
		[Vector3(0.02, 0.105, 0.0), Vector3(0.14, 0.03, 0.12), 0.8, RED]]
	for fold: Array in folds:
		LowPoly.add_box(st, Transform3D(Basis(Vector3.UP, fold[2]), fold[0]), fold[1], fold[3])
	return LowPoly.commit(st)


func _mesh(mesh: Mesh, parent: Node) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	parent.add_child(mi)
	return mi
