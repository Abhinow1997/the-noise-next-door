extends Node3D
## Eat the pizza, a level 1 task at the camp (camp_tasks.gd "pizza"), asked for on 23 Nov 2026,
## the author: "i want the table to have like a cloth and us to have an option of like pulling it.
## So when you pull it, the boxes drop and then we can potentially eat it", and "we need a new
## animation for the raccon where he is dragging this we might use for other things as well in
## the game". The plan was Claude Code's, kept by the author ("Yes, build both"). After play the
## same day: "the cloth needs to be pulled like the natrual movement e grab and pull the cloth also
## seems like a box texture not good".
##   - A gingham cloth lies over the pizza end of the table (its west half; the laptop is part of the
##     table's model and stays put), one soft sheet that hangs down over the end to where his jaws
##     reach. The pizza's boxes (pizza_boxes.gd) sit on it, the top one open.
##   - Once the tutorial's done (camp_tasks.gd `revealed`), E at its hanging hem takes it in his jaws
##     (player.gd `grip`). Then the move keys drag it: he faces the table and backs away from its
##     end, slowly, playing his `drag` clip, and the cloth comes with him, the boxes riding on it.
##     E or F lets go, and so does a fright; the cloth stays where it's got to, its hem hanging (or
##     lying on the ground), to be taken again.
##   - Pulled far enough (BOXES_TIP), the boxes go over the end and fall (FALL), and their weight
##     takes the rest of the cloth off the table with them: he lets go, and it comes down in the
##     same time as they do, settling in a heap under where they land (after play: "the fabric and
##     pizza fall syc is off"; till then the cloth came off on its own, later). They land on it
##     with a clatter heard CLATTER round, as his landing from a jump is (campsite.gd HEAR_STEPS):
##     anyone near enough comes to look. The bottom box lands shut, the top one open beside it with
##     the pizza in it. With nothing on it, the cloth comes off once it's pulled right off
##     (CLOTH_OFF).
##   - Holding E at the open box (EAT_FOR) he takes a slice, sits up and eats it from his paws in
##     BITES bites, as he eats the marshmallow (roast_plate.gd, raccoon_eat.gd). The first one
##     eaten ticks the task. There are five; each can be eaten.
##   - Nobody tidies it up yet: the boxes and the cloth stay where they fell.
## Built here in code, like the camp's other props. campsite.gd adds it; the tutorial's girl
## carries the boxes in and puts them back on the cloth (camp_tutorial.gd).

const Interactable := preload("res://scripts/interactable.gd")
const PizzaBoxes := preload("res://scripts/pizza_boxes.gd")
const RaccoonEat := preload("res://scripts/raccoon_eat.gd")

## The cloth, in the table's space (campsite.gd TABLE; its top is 1.28 × 0.83 m, at 0.742): from the
## table's west edge to CLOTH_TO, across its whole depth (HALF_WIDTH each side), and hanging HANG
## down over the end. It's a sheet of rows ROW apart and COLS columns, lying THICK above the top.
const TOP_Y := 0.742
const THICK := 0.003
const EDGE_X := -0.64
const CLOTH_TO := -0.06
const HALF_WIDTH := 0.415
const HANG := 0.34
const ROW := 0.03
const COLS := 14
## The gingham: one check's size (m), and its colours.
const CHECK := 0.07
const RED := Color("b23a32")
const CREAM := Color("efe6d2")
## Dragging it: the hem gathered in his jaws to this share of its width; how much slack sags (as
## a share of the spare cloth); and the ground (m).
const GATHER := 0.3
const SAG := 0.5
const GROUND := 0.006
## How far it's pulled (m) when the boxes go over the end, and when it comes right off.
const BOXES_TIP := 0.3
const CLOTH_OFF := CLOTH_TO - EDGE_X
## Lying on the ground once it's off: how long and wide it's bunched up (m), and how high its folds.
const LYING := Vector2(0.62, 0.78)
const FOLDS := 0.04
## Coming down: how fast the boxes fall (m/s²), how far off the table's end they land and how far
## they tip going over (degrees), and how far the clatter's heard (m, as campsite.gd HEAR_STEPS).
const FALL := 14.0
const LAND_OUT := 0.22
const TIP := 35.0
const CLATTER := 6.0
## The cloth's heap, from where the boxes land (x, z in the table's space: toward where the top box
## spills, pizza_boxes.gd SPILL_AT), and how high on it they come to rest (m).
const HEAP_FROM_BOXES := Vector2(-0.16, 0.06)
const ON_HEAP := 0.015
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
## How far the cloth's been pulled toward the table's end (m); the boxes have gone over the end
## (`pulled`) and are down on the ground (`down`); the cloth's off the table; slices eaten so far.
var slide := 0.0
var pulled := false
var down := false
var off := false
var eaten := 0

var _cloth: MeshInstance3D
var _material: StandardMaterial3D
var _grab: Interactable
var _eat: Interactable
var _boxes_at := Vector3.ZERO
var _fall_t := -1.0
var _fall_from := Transform3D.IDENTITY
var _player
## Taken in his jaws: how far it was pulled then, and how far his jaws were from the table's edge.
var _grip_slide := 0.0
var _grip_reach := 0.0
var _dirty := true
## Where it lies once it's off: its middle, in the table's space; and the sheet as it was the moment
## it came off, to come down from.
var _lying_at := Vector3.ZERO
var _cloth_from: Array = []
## How far it's come down (0..1); 1 when it came off with nothing on it.
var _cloth_k := 1.0
## The slice in his paws while he eats it, where it lay in the box, and how much of it's eaten.
var _slice: Node3D
var _slice_was := Transform3D.IDENTITY
var _bitten := 0.0


func _ready() -> void:
	_material = StandardMaterial3D.new()
	_material.albedo_texture = _gingham()
	_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.roughness = 1.0
	_material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	_cloth = MeshInstance3D.new()
	_cloth.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	table.add_child(_cloth)
	boxes = PizzaBoxes.new()
	table.add_child(boxes)
	_boxes_at = Vector3(slices.position.x, TOP_Y + THICK, slices.position.z)
	boxes.set_on(table, _boxes_at, slices)
	_grab = Interactable.new()
	_grab.camp = camp
	_grab.prompt_height = 0.25
	_grab.enabled = func() -> bool: return not off and camp.tasks != null and camp.tasks.revealed \
		and _player != null and _player.gripping == null and (pulled or on_table())
	_grab.finished.connect(_take_hem)
	add_child(_grab)
	_eat = Interactable.new()
	_eat.hold_time = EAT_FOR
	_eat.noise = EAT_NOISE
	_eat.camp = camp
	_eat.prompt_height = 0.3
	_eat.enabled = func() -> bool: return down and (slices_left() > 0 or _slice != null)
	_eat.finished.connect(_ate)
	add_child(_eat)
	_place_grab()
	_rebuild()


## True while the boxes are on the cloth, on the table (not being carried in, not hidden).
func on_table() -> bool:
	return boxes.visible and boxes.get_parent() == table and not boxes.carried()


## The boxes back on the cloth, open, with the pizza in them (the tutorial's girl puts them there).
func put_on_table() -> void:
	boxes.visible = true
	boxes.set_on(table, _boxes_at + Vector3(-slide, 0.0, 0.0), slices)


## How many slices are left to eat.
func slices_left() -> int:
	var n := 0
	for slice: Node in slices.get_children():
		if slice is Node3D and slice.visible and slice != _slice:
			n += 1
	return n


## True while he has it in his jaws.
func gripped() -> bool:
	return _player != null and _player.gripping == self


## For player.gd `grip`: the way he pulls it, level, away from the table's end; and what he faces.
func pull_axis() -> Vector3:
	var west := -table.global_basis.x
	return Vector3(west.x, 0.0, west.z).normalized()


func face_point() -> Vector3:
	return table.global_transform * Vector3(EDGE_X, 0.0, 0.0)


## player.gd `let_go`: let go of, it stays where it's got to.
func released(_by) -> void:
	_place_grab()
	_dirty = true


## Where he stands to take the hem (for the tests): off the table's west end, facing its edge.
func pull_from() -> Vector3:
	return table.global_transform * Vector3(EDGE_X - 0.42, 0.02, 0.0)


## Where the hem is, and where the open box is once it's down (for the tests).
func pull_point() -> Vector3:
	return _grab.global_position


func eat_point() -> Vector3:
	return _eat.global_position


## E at the hem: in his jaws.
func _take_hem() -> void:
	_grab.reset()
	if _player == null:
		return
	_grip_slide = slide
	_grip_reach = _reach()
	_player.grip(self)
	_dirty = true


## How far his jaws are from the table's edge, where the cloth goes over it.
func _reach() -> float:
	var mouth: Vector3 = table.global_transform.affine_inverse() * _player.model.mouth.global_position
	return mouth.distance_to(Vector3(EDGE_X, TOP_Y, clampf(mouth.z, -HALF_WIDTH, HALF_WIDTH)))


func _physics_process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		return
	if not gripped():
		return
	# Pulled as far as his jaws have gone back from where he took it; it doesn't push back on.
	var want := clampf(_grip_slide + _reach() - _grip_reach, 0.0, CLOTH_OFF)
	if want > slide:
		slide = want
		_dirty = true
		if on_table():
			boxes.position = _boxes_at + Vector3(-slide, 0.0, 0.0)
		if not pulled and on_table() and slide >= BOXES_TIP:
			_boxes_over()
		elif not off and slide >= CLOTH_OFF:
			# Nothing on it to bring it down sooner: off it comes, between him and the table.
			var mouth: Vector3 = table.global_transform.affine_inverse() * _player.model.mouth.global_position
			_come_off(Vector3((EDGE_X + mouth.x) * 0.5, 0.0, clampf(mouth.z, -0.2, 0.2)))


## Over the end the boxes go, tipping, and down; and their weight takes the rest of the cloth off
## the table with them (the author, after play: "the fabric and pizza fall syc is off"). It slides
## off and settles in a heap, in the same time as they fall, under where they land.
func _boxes_over() -> void:
	pulled = true
	_fall_t = 0.0
	boxes.reparent(self, true)
	_fall_from = boxes.global_transform
	var lands := table.global_transform.affine_inverse() * (_fall_from.origin + pull_axis() * LAND_OUT)
	_come_off(Vector3(lands.x + HEAP_FROM_BOXES.x, 0.0, lands.z + HEAP_FROM_BOXES.y), true)


## Off the table: he lets go, and it comes down to lie crumpled on the ground round `at` (in the
## table's space), from where it was: over the boxes' fall (`with_boxes`), or at once.
func _come_off(at: Vector3, with_boxes := false) -> void:
	# How it is now, while it's still on the table and in his jaws.
	_cloth_from = _grid(_mouth_now())
	_cloth_k = 0.0 if with_boxes else 1.0
	off = true
	_lying_at = at
	_player.let_go()
	_dirty = true


func _process(delta: float) -> void:
	if _fall_t >= 0.0:
		_fall(delta)
	if _dirty or gripped():
		_rebuild()
		_dirty = false
	_eat_process()


## Off the end and down: the boxes go out over the edge, tipping, and fall.
func _fall(delta: float) -> void:
	_fall_t += delta
	var drop := _fall_from.origin.y
	var time := sqrt(2.0 * maxf(drop, 0.01) / FALL)
	var k := clampf(_fall_t / time, 0.0, 1.0)
	var west := pull_axis()
	var fall := 0.5 * FALL * minf(_fall_t, time) ** 2
	var tip := Basis(table.global_basis.z, deg_to_rad(TIP) * k)
	boxes.global_transform = Transform3D(tip * _fall_from.basis,
		_fall_from.origin + west * LAND_OUT * k + Vector3.DOWN * minf(fall, drop))
	# The cloth comes down with them, as far through its fall as they are through theirs.
	_cloth_k = k
	_dirty = true
	if k >= 1.0:
		_fall_t = -1.0
		_land()


## Down: the boxes spilled on the cloth's heap, and a clatter the campers hear.
func _land() -> void:
	var at := boxes.global_position * Vector3(1, 0, 1)
	boxes.spill(self, at + Vector3.UP * ON_HEAP, table.global_rotation.y)
	down = true
	slices.add_to_group("food")
	_eat.global_position = boxes.pizza_point()
	if camp:
		camp.noise(at, CLATTER, 0.0, true)


## The E for the hem: where it is now, hanging from the edge or lying on the ground past it.
func _place_grab() -> void:
	var over := HANG + slide
	var beyond := maxf(over - (TOP_Y - GROUND), 0.0)
	_grab.global_position = table.global_transform * Vector3(EDGE_X - 0.03 - beyond, maxf(TOP_Y - over, GROUND) + 0.05, 0.0)


# --- The sheet ----------------------------------------------------------------------------

## His jaws as drawn, in the table's space, while he has it in them; else null.
func _mouth_now():
	if not gripped():
		return null
	return table.global_transform.affine_inverse() * _player.model.mouth.get_global_transform_interpolated().origin


## The sheet's rows of points: as it lies now (on the table, hanging, or in his jaws at `mouth`),
## or, once it's off, on its way down from how it was (_cloth_from) to its heap.
func _grid(mouth) -> Array:
	var length := (CLOTH_TO - EDGE_X) + HANG
	var rows := ceili(length / ROW)
	var ease_in := _cloth_k * _cloth_k * (3.0 - 2.0 * _cloth_k)
	var grid: Array = []
	for r in rows + 1:
		var c := length * r / rows
		var row: Array = []
		for k in COLS + 1:
			var v := lerpf(-HALF_WIDTH, HALF_WIDTH, float(k) / COLS)
			if not off:
				row.append(_point(c, v, mouth))
			elif _cloth_from.is_empty() or _cloth_k >= 1.0:
				row.append(_lying_point(c, v, length))
			else:
				row.append((_cloth_from[r][k] as Vector3).lerp(_lying_point(c, v, length), ease_in))
		grid.append(row)
	return grid


## The cloth's mesh for now: on the table and hanging, in his jaws, coming down, or lying on the
## ground.
func _rebuild() -> void:
	var length := (CLOTH_TO - EDGE_X) + HANG
	var rows := ceili(length / ROW)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var grid := _grid(_mouth_now())
	for r in rows:
		for k in COLS:
			var corners := [[r, k], [r + 1, k], [r + 1, k + 1], [r, k + 1]]
			for i: int in [0, 1, 2, 0, 2, 3]:
				var rr: int = corners[i][0]
				var kk: int = corners[i][1]
				st.set_uv(Vector2(length * rr / rows, lerpf(-HALF_WIDTH, HALF_WIDTH, float(kk) / COLS)) / (CHECK * 2.0))
				st.add_vertex(grid[rr][kk])
	# Shared corners merged, so it's shaded smooth across its folds.
	st.index()
	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, _material)
	_cloth.mesh = mesh
	_cloth.visible = true


## A point of the cloth, `c` along it from its hem and `v` across it, in the table's space: on the
## table's top, or beyond its edge hanging straight down (and what reaches the ground lying out
## along it), or, in his jaws at `mouth`, stretched from the edge to them, the hem gathered and the
## slack sagging.
func _point(c: float, v: float, mouth) -> Vector3:
	var over := HANG + slide
	if c >= over:
		return Vector3(EDGE_X + (c - over), TOP_Y + THICK, v)
	if mouth == null:
		var y := TOP_Y - (over - c)
		if y >= GROUND:
			return Vector3(EDGE_X - 0.006, y, v)
		return Vector3(EDGE_X - 0.006 - (GROUND - y), GROUND, v)
	var m: Vector3 = mouth
	var t := c / over
	var hem := Vector3(m.x, m.y, m.z + v * GATHER)
	var edge := Vector3(EDGE_X, TOP_Y + THICK, v)
	var p := hem.lerp(edge, t)
	var spare := maxf(over - hem.distance_to(Vector3(EDGE_X, TOP_Y, m.z)), 0.0)
	p.y -= SAG * spare * sin(PI * t)
	p.y = maxf(p.y, GROUND)
	return p


## A point of the cloth lying bunched on the ground once it's off, round `_lying_at`.
func _lying_point(c: float, v: float, length: float) -> Vector3:
	var a := c / length - 0.5
	var b := v / HALF_WIDTH * 0.5
	var fold := 0.5 + 0.5 * sin(a * 23.0 + b * 4.0) * cos(b * 9.0 - a * 5.0)
	var edge := 1.0 - maxf(absf(a), absf(b)) * 2.0
	return _lying_at + Vector3(a * LYING.x, GROUND + FOLDS * fold * clampf(edge * 3.0, 0.0, 1.0), b * LYING.y)


## The cloth's checks: red and cream bands across and along, darker where they cross, softened at
## their edges; two checks each way, repeated.
static func _gingham() -> ImageTexture:
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	for y in n:
		for x in n:
			var bx := _band(x, n)
			var by := _band(y, n)
			var red := clampf(bx * 0.55 + by * 0.55, 0.0, 1.0)
			img.set_pixel(x, y, CREAM.lerp(RED, red))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## How much of a band (0..1) pixel `i` of `n` is in: the first half of the tile, with a soft edge.
static func _band(i: int, n: int) -> float:
	var half := n / 2
	var d := minf(absf(i + 0.5 - half * 0.5), absf(i + 0.5 - half * 0.5 - n)) - half * 0.5
	return clampf(0.5 - d, 0.0, 1.0)


# --- Eating ---------------------------------------------------------------------------------

## Eating while E's held at the open box: a slice in his paws, bite by bite, sitting up (raccoon_model.gd
## `eating`). Let go, and the slice goes back where it was, as eaten as it was.
func _eat_process() -> void:
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
