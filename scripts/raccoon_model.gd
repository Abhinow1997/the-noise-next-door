@tool
extends Node3D
## Low-poly raccoon built from code, matched to the concept art.
## Faces -Z (Godot's forward) with its feet at y = 0. Parts are separate nodes
## so they can be animated; set walk_amount / walk_phase / crouch / chitter_time.

const LowPoly := preload("res://scripts/lowpoly.gd")

const GREY := Color("8a837c")
const GREY_DARK := Color("716b66")
const CREAM := Color("ece5cf")
const BLACK := Color("2e2d2c")
const PAW := Color("3a2f31")

## Rounded, smooth-shaded mesh. Turn off for the original faceted low-poly look.
@export var smooth := true:
	set(value):
		smooth = value
		if is_node_ready():
			_rebuild()

## 0 = standing still, 1 = full stride.
var walk_amount := 0.0
var walk_phase := 0.0
## 0 = standing, 1 = sneaking low to the ground.
var crouch := 0.0
## Seconds of chittering left.
var chitter_time := 0.0

var body: Node3D
var head: Node3D
var tail: Node3D
var legs: Array[Node3D] = []
## Where carried objects are held.
var mouth: Marker3D

var _leg_height: Array[float] = []
var _t := 0.0


func _ready() -> void:
	_build()


func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	legs.clear()
	_leg_height.clear()
	_build()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	chitter_time = maxf(chitter_time - delta, 0.0)

	# Diagonal leg pairs swing together, like a real trot.
	var stride := sin(walk_phase) * 0.65 * walk_amount
	var swings := [stride, -stride, -stride, stride]
	for i in legs.size():
		var h := _leg_height[i] - crouch * 0.1
		legs[i].rotation.x = swings[i]
		legs[i].position.y = h
		legs[i].scale.y = h / _leg_height[i]

	body.position.y = absf(sin(walk_phase)) * 0.025 * walk_amount - crouch * 0.1
	body.rotation.z = sin(walk_phase) * 0.03 * walk_amount
	tail.rotation.y = sin(_t * 2.3) * 0.22 + sin(walk_phase) * 0.15 * walk_amount
	tail.rotation.x = 0.1 * crouch - 0.05 * walk_amount
	head.rotation.y = sin(_t * 0.8) * 0.18 * (1.0 - walk_amount)
	head.rotation.x = sin(walk_phase * 2.0) * 0.04 * walk_amount - crouch * 0.12
	if chitter_time > 0.0:
		head.rotation.x += sin(_t * 45.0) * 0.07
		head.rotation.y += sin(_t * 31.0) * 0.05


func _build() -> void:
	body = _part("Body", self, Vector3.ZERO)
	_mesh(body, _loft(
		[Vector3(0, 0.36, 0.40), Vector3(0, 0.40, 0.28), Vector3(0, 0.43, 0.04),
			Vector3(0, 0.41, -0.18), Vector3(0, 0.41, -0.30)],
		[Vector2(0.08, 0.08), Vector2(0.2, 0.2), Vector2(0.24, 0.25),
			Vector2(0.2, 0.2), Vector2(0.13, 0.14)],
		8, _body_color, PI / 8))

	head = _part("Head", body, Vector3(0, 0.47, -0.31))
	# The mask starts and ends exactly at head segments, so those edges stay sharp.
	_mesh(head, _loft(
		[Vector3(0, 0, 0.03), Vector3(0, 0, -0.07), Vector3(0, -0.02, -0.15), Vector3(0, -0.045, -0.235)],
		[Vector2(0.11, 0.11), Vector2(0.16, 0.135), Vector2(0.09, 0.08), Vector2(0.038, 0.032)],
		8, _head_color, PI / 8, false))
	for side: float in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.022
		sphere.height = 0.044
		sphere.radial_segments = 16 if smooth else 8
		sphere.rings = 8 if smooth else 4
		sphere.material = _eye_material()
		eye.mesh = sphere
		eye.position = Vector3(0.105 * side, 0.03, -0.115)
		head.add_child(eye)

		var ear := _part("Ear" + ("R" if side > 0 else "L"), head, Vector3(0.075 * side, 0.09, 0.0))
		ear.rotation = Vector3(-0.15, 0.0, -0.3 * side)
		_mesh(ear, _ear_mesh())

	mouth = Marker3D.new()
	mouth.name = "Mouth"
	mouth.position = Vector3(0, -0.07, -0.22)
	head.add_child(mouth)

	tail = _part("Tail", body, Vector3(0, 0.38, 0.36))
	var centers: Array = []
	var radii: Array = []
	var segments := 12
	for k in segments + 1:
		var u := float(k) / segments
		centers.append(Vector3(0, 0.05 * u - 0.24 * u * u, 0.56 * u))
		var r := 0.03 if k == segments else 0.07 + 0.04 * sin(PI * minf(u * 1.1, 1.0))
		radii.append(Vector2(r, r))
	_mesh(tail, _loft(centers, radii, 7, _tail_color))

	_leg("LegFL", Vector3(-0.11, 0.36, -0.20), 0.075)
	_leg("LegFR", Vector3(0.11, 0.36, -0.20), 0.075)
	_leg("LegBL", Vector3(-0.13, 0.37, 0.22), 0.1)
	_leg("LegBR", Vector3(0.13, 0.37, 0.22), 0.1)


func _leg(leg_name: String, pos: Vector3, thigh: float) -> void:
	var leg := _part(leg_name, self, pos)
	var h := pos.y
	_mesh(leg, _loft(
		[Vector3(0, 0.02, 0), Vector3(0, -h * 0.58, 0), Vector3(0, -h * 0.8, -0.005),
			Vector3(0, -h + 0.035, -0.035), Vector3(0, -h + 0.02, -0.075)],
		[Vector2(thigh, thigh), Vector2(0.058, 0.06), Vector2(0.052, 0.052),
			Vector2(0.056, 0.038), Vector2(0.04, 0.022)],
		6, _leg_color, PI / 6))
	legs.append(leg)
	_leg_height.append(h)


## Builds one body part, smooth or faceted. The smooth version has four times the
## sides, so colour markings stay sharp enough to read once their edges are softened.
## `blend` softens colour changes between segments (see LowPoly.smooth_loft).
func _loft(centers: Array, radii: Array, sides: int, color_fn: Callable, twist := 0.0,
		blend := true) -> ArrayMesh:
	if smooth:
		return LowPoly.smooth_loft(centers, radii, sides * 4, color_fn, twist / 4.0, 4, blend)
	return LowPoly.loft(centers, radii, sides, color_fn, twist)


func _ear_mesh() -> ArrayMesh:
	if smooth:
		# A rounded cone with the same footprint and height as the faceted ear.
		return LowPoly.smooth_loft(
			[Vector3(0, -0.012, 0.016), Vector3(0, 0.04, 0.015), Vector3(0, 0.09, 0.012)],
			[Vector2(0.05, 0.018), Vector2(0.04, 0.014), Vector2(0.012, 0.007)],
			12, _ear_color, 0.0, 3)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var l := Vector3(-0.05, 0, 0)
	var r := Vector3(0.05, 0, 0)
	var back := Vector3(0, 0, 0.04)
	var tip := Vector3(0, 0.1, 0.012)
	var mid := (l + r + back + tip) / 4.0
	LowPoly.add_tri(st, l, r, tip, mid, CREAM)
	LowPoly.add_tri(st, l, back, tip, mid, GREY_DARK)
	LowPoly.add_tri(st, r, back, tip, mid, GREY_DARK)
	LowPoly.add_tri(st, l, r, back, mid, GREY_DARK)
	# Dark inner ear floated just in front of the cream rim.
	var inset := Vector3(0, 0.012, -0.004)
	LowPoly.add_tri(st, l * 0.6 + inset, r * 0.6 + inset, tip * 0.75 + inset, mid, BLACK)
	var mesh := st.commit()
	mesh.surface_set_material(0, LowPoly.material())
	return mesh


func _body_color(segment: int, _side: int, n: Vector3) -> Color:
	if segment >= 3 and n.y < 0.0:
		return CREAM
	if segment >= 2 and n.y < -0.6:
		return CREAM
	if n.y > 0.6:
		return GREY_DARK
	return GREY


func _head_color(segment: int, _side: int, n: Vector3) -> Color:
	match segment:
		0:
			return CREAM if n.y < -0.5 else GREY
		1:
			# Brow, black eye mask, white cheeks.
			if n.y > 0.8:
				return GREY
			if n.y > 0.35:
				return CREAM
			if n.y > -0.45:
				return BLACK
			return CREAM
		2:
			return GREY_DARK if n.y > 0.8 else CREAM
		3:
			return BLACK
	return GREY


func _tail_color(segment: int, _side: int, _n: Vector3) -> Color:
	if segment <= 0:
		return GREY
	if segment >= 11:
		return BLACK
	return CREAM if int((segment - 1) / 2.0) % 2 == 0 else BLACK


func _leg_color(segment: int, _side: int, _n: Vector3) -> Color:
	if segment <= 0:
		return GREY
	if segment == 1:
		return GREY_DARK
	return PAW


## Smooth ears face -Z: black inside, a cream rim, dark grey behind.
func _ear_color(_segment: int, _side: int, n: Vector3) -> Color:
	if n.z < -0.6:
		return BLACK
	if n.z < -0.2:
		return CREAM
	return GREY_DARK


func _eye_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("141313")
	mat.roughness = 0.15
	return mat


func _part(part_name: String, parent: Node, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = part_name
	node.position = pos
	parent.add_child(node)
	return node


func _mesh(parent: Node3D, mesh: Mesh) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	parent.add_child(mi)
	return mi
