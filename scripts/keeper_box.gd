extends Node3D
## The fire keeper's box (23 Nov 2026), the author: "the guy will carry the box, and in that he'll
## have ... a pot ... We will replace the bucket which we are using to douse ... the fire ... there
## are like three sticks ... and the pot will be inside the box which he'll bring ... he keeps the
## box a little far away, gets the pot, and then starts to fix the pot". Their picks: the pot comes
## at the tutorial's end (camp_tutorial.gd); a free CC0 model, the closed cube as it comes ("Use the
## closed cube").
##   - The model: Viktor Sano's "[CC0] Free Cardboard Boxes", Box1 with its tape
##     (assets/props/cardboard_box/, ATTRIBUTION.md there): 0.75 × 0.59 m, 0.47 m tall, closed. Shown
##     at SCALE of that (after play: "reduce its size"), 0.56 × 0.44 m, 0.35 m tall.
##   - `put_down`: on the ground, at AT (from the fire) near the camp's edge. It stands there from the
##     start, and the keeper takes the pot's stand out of it, piece by piece, at the tutorial's end. At first he
##     carried it in, and into the green tent and out on his rounds; after play ("everything beyond
##     hiding in the box looks wrong the animation of the guy carying it messed up"), nobody carries
##     it. The raccoon drags it about (camp_box.gd).
##   - A hiding spot like the bush (`hide_spot`, dive on), which camp_box.gd opens and closes. Its
##     solid shape is only there for the campers' walkways to be baked round it (`unsolid` after
##     that), so he can dive in.
##   - `rustle`: it shakes, as it does when he dives in (F in it: camp_box.gd).
##   - With him in it, on the ground, the top's flap on the far side from the camera opens a crack
##     and his eyes peek out from under it, blinking, out of the dark inside (after play: "the eyes
##     look off when he is in it", then "maybe the upper flap peaking from there not from the
##     botttom ... we are basicially inside the box"). The model's top is one face, so it's made
##     into two flaps, split down the tape (each flap takes its half of the tape), with the box dark
##     inside under them.
## Presentation and a hiding place: it writes nothing in the game.

const HideSpot := preload("res://scripts/hide_spot.gd")
const MODEL := "res://assets/props/cardboard_box/CardboardBoxes.fbx"
## Where it's put down, from the fire (x, z), and which way it's turned (degrees). Near the camp's edge,
## 8.5 m south-east of its middle, behind the green tent from the fire, where the trees begin 2.5 m on
## (forest.gd CAMP_RADIUS): out of the camp's middle (23 Nov 2026, after play: "the box needs to be kept
## away from the campsite its literally in the middle", then "somewhere near the edge of the camp").
## It was 1.9, 3.0, between the fire and the green tent.
const AT := Vector2(6.5, 8.3)
const TURN := 20.0
## How big it's shown against the model, and its size (m): the model's Box1 at that.
const SCALE := 0.75
const SIZE := Vector3(0.747, 0.472, 0.588) * SCALE
## As a hiding spot: how far round it he dives in (m, just over its own size, so it's walking into it
## that dives him in).
const HIDE := SIZE + Vector3(0.05, 0.03, 0.07)
## With him in it: how far the far flap opens (degrees, on its hinge at the box's far top edge), and how
## long it takes to open or shut (s).
const FLAP_OPEN := 18.0
const OPEN_TIME := 0.3
## His eyes under it: how far back from the middle of the top (m, toward the hinge), how high their
## middles are over the top, and how big against the bush's (hide_spot.gd), to fit under the flap.
## They show once it's this far open (0–1).
const EYES_IN := 0.04
const EYES_UP := 0.022
const EYES_SCALE := 0.65
const EYES_FROM := 0.6
## The dark inside, seen under the open flap: just under the top (under the flaps' undersides), and
## just in from the sides, so it shows none of the ground through the box.
const INSIDE_DARK := Color(0.02, 0.02, 0.025)
const INSIDE_DOWN := 0.003
const RIM := 0.001
## The flaps' undersides (the inside of the cardboard): the outside's colour this much darker; and
## how far under the outside they are (m).
const UNDERSIDE := 0.7
const FLAP_THICK := 0.002
## The tape on the flaps: how far over the flap (m), so it doesn't flicker into it.
const TAPE_UP := 0.0005

## The hiding spot in it (hide_spot.gd), shut till camp_box.gd opens it.
var hide_spot: HideSpot

var _body: StaticBody3D
var _box: Node3D
## How far the far flap is open (0–1), and which flap that is: the one hinged at the box's +Z top edge
## (1) or its −Z one (−1), the one away from the camera; chosen while both are shut.
var _open := 0.0
var _side := 1.0
## The two flaps, by the side of their hinge (1, −1), each turning on it; the dark inside.
var _flaps := {}
var _inside: MeshInstance3D
## The height of its top, and half its size across (x, z), from the model.
var _top := SIZE.y
var _half := Vector2(SIZE.x, SIZE.z) * 0.5


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var scene: Node3D = (load(MODEL) as PackedScene).instantiate()
	# What shakes as he dives in (hide_spot.gd `leaves`): a plain holder with the box in it. The model's
	# Box1 comes turned upright (a quarter turn about X, from the FBX's axes), and the rustle sets its
	# leaves' turn back to none, so shaking Box1 itself laid it on its side (23 Nov 2026, after play: "the
	# box looks compleltly different after gettin in it").
	var holder := Node3D.new()
	add_child(holder)
	_box = scene.get_node_or_null("Box1")
	if _box:
		# Box1 alone (the pack has four), its base on our origin, no longer the pack's.
		for part in [_box] + _box.find_children("*", "", true, false):
			(part as Node).owner = null
		_box.get_parent().remove_child(_box)
		_box.position = Vector3.ZERO
		_box.transform.basis = _box.transform.basis.scaled(Vector3.ONE * SCALE)
		holder.add_child(_box)
		_make_flaps(holder)
	scene.free()
	_body = StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = SIZE
	col.shape = shape
	col.position = Vector3(0, SIZE.y * 0.5, 0)
	_body.add_child(col)
	add_child(_body)
	hide_spot = HideSpot.new()
	hide_spot.dive = true
	hide_spot.height = SIZE.y
	hide_spot.leaves = holder
	# His eyes peek out from under the open flap (_process places them).
	hide_spot.own_eyes = true
	hide_spot.hold_eyes = true
	hide_spot.eye_scale = EYES_SCALE
	var area := CollisionShape3D.new()
	var hide := BoxShape3D.new()
	hide.size = HIDE
	area.shape = hide
	area.position = Vector3(0, HIDE.y * 0.5, 0)
	hide_spot.add_child(area)
	hide_spot.monitoring = false
	add_child(hide_spot)


## Where it's put down out of the tent, in the camp's space: AT from the fire at `fire` (x, z).
static func spot_by_fire(fire: Vector2) -> Vector3:
	return Vector3(fire.x + AT.x, 0.0, fire.y + AT.y)


## Kept for camp_tutorial.gd: the same as spot_by_fire.
static func spot(fire: Vector2) -> Vector3:
	return spot_by_fire(fire)


## The walkways are baked (campsite.gd): from now it isn't solid, so he can dive into it.
func unsolid() -> void:
	_body.process_mode = Node.PROCESS_MODE_DISABLED


## On the ground at `at` (the camp's space), turned `yaw`.
func put_down(at: Vector3, yaw: float) -> void:
	global_transform = Transform3D(Basis(Vector3.UP, yaw), Vector3(at.x, 0.0, at.z))


## It shakes, as when he dives in (hide_spot.gd), with him in it (F: camp_box.gd).
func rustle() -> void:
	hide_spot.rustle()


## How far the far flap is open (0–1), and which it is (the side of its hinge, 1 or −1, along the box's
## own Z): for the tests.
func opened() -> float:
	return _open


func flap_side() -> float:
	return _side


## The flap hinged on `side` (1 or −1): for the tests.
func flap(side: float) -> Node3D:
	return _flaps.get(side)


func _process(delta: float) -> void:
	_peek(delta)


## With him in it, the flap away from the camera opens a crack; his eyes peek out from under it once
## it's open far enough.
func _peek(delta: float) -> void:
	var want := hide_spot.occupied
	var camera := get_viewport().get_camera_3d()
	if _open == 0.0 and camera:
		var to_cam := global_transform.basis.inverse() * (camera.global_position - global_position)
		_side = -1.0 if to_cam.z > 0.0 else 1.0
	_open = move_toward(_open, 1.0 if want else 0.0, delta / OPEN_TIME)
	_show_open()
	hide_spot.hold_eyes = _open < EYES_FROM
	var eyes := hide_spot.eyes()
	if eyes:
		eyes.global_position = global_transform * Vector3(0, _top + EYES_UP, _side * EYES_IN)


## Turns the far flap `_open` of the way open; the other lies shut.
func _show_open() -> void:
	for side: float in _flaps:
		var flap_node: Node3D = _flaps[side]
		var angle: float = deg_to_rad(FLAP_OPEN) * smoothstep(0.0, 1.0, _open) if side == _side else 0.0
		# Its free edge (toward the middle) goes up.
		flap_node.rotation.x = side * angle


## The model's top made into two flaps, split down the middle along the tape: the top taken out of the
## box and of its tape, a flap for each half with its half of the tape, and the dark inside under them.
func _make_flaps(holder: Node3D) -> void:
	var box_mesh := _box as MeshInstance3D
	if box_mesh == null:
		return
	var tape := _box.get_node_or_null("Tape1") as MeshInstance3D
	var top := _top_face(box_mesh, box_mesh.transform)
	if top.is_empty():
		return
	var tape_top := _top_face(tape, box_mesh.transform * tape.transform) if tape else {}
	var lo: Vector3 = top.lo
	var hi: Vector3 = top.hi
	_top = hi.y
	_half = Vector2(hi.x - lo.x, hi.z - lo.z) * 0.5
	var middle := Vector2(lo.x + hi.x, lo.z + hi.z) * 0.5
	box_mesh.mesh = _without_top(box_mesh, box_mesh.transform)
	if tape and not tape_top.is_empty():
		tape.mesh = _without_top(tape, box_mesh.transform * tape.transform)
	var outside := box_mesh.mesh.surface_get_material(0)
	var inner: Material = outside.duplicate() if outside else StandardMaterial3D.new()
	if inner is BaseMaterial3D:
		(inner as BaseMaterial3D).albedo_color *= Color(UNDERSIDE, UNDERSIDE, UNDERSIDE)
	for side: float in [1.0, -1.0]:
		var edge := middle.y + side * _half.y
		var hinge := Vector3(middle.x, _top, edge)
		var mesh := ArrayMesh.new()
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_material(outside)
		_quad(st, top, Rect2(lo.x, minf(middle.y, edge), hi.x - lo.x, _half.y), _top, true, -hinge)
		if not tape_top.is_empty():
			var t_lo: Vector3 = tape_top.lo
			var t_hi: Vector3 = tape_top.hi
			var t_mid := (t_lo.z + t_hi.z) * 0.5
			var t_edge := t_lo.z if side < 0.0 else t_hi.z
			_quad(st, tape_top, Rect2(t_lo.x, minf(t_mid, t_edge), t_hi.x - t_lo.x, absf(t_edge - t_mid)),
				t_hi.y + TAPE_UP, true, -hinge)
		st.generate_tangents()
		st.commit(mesh)
		st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_material(inner)
		_quad(st, top, Rect2(lo.x, minf(middle.y, edge), hi.x - lo.x, _half.y), _top - FLAP_THICK, false, -hinge)
		st.generate_tangents()
		st.commit(mesh)
		var flap_node := MeshInstance3D.new()
		flap_node.name = "Flap+" if side > 0.0 else "Flap-"
		flap_node.mesh = mesh
		flap_node.position = hinge
		holder.add_child(flap_node)
		_flaps[side] = flap_node
	_inside = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(_half.x - RIM, _half.y - RIM) * 2.0
	var dark := StandardMaterial3D.new()
	dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dark.albedo_color = INSIDE_DARK
	plane.material = dark
	_inside.mesh = plane
	_inside.position = Vector3(middle.x, _top - INSIDE_DOWN, middle.y)
	_inside.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(_inside)


## The face of `mi`'s mesh that faces up, in this box's own space (`to_box`): its corners' lowest and
## highest (lo, hi), and how a point on it (x, z) maps onto its texture; empty if it has none.
func _top_face(mi: MeshInstance3D, to_box: Transform3D) -> Dictionary:
	var arrays := mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var at: Array[Vector3] = []
	var uv: Array[Vector2] = []
	for i in verts.size():
		if (to_box.basis * normals[i]).normalized().y > 0.99:
			at.append(to_box * verts[i])
			uv.append(uvs[i])
	if at.size() < 3:
		return {}
	var lo := at[0]
	var hi := at[0]
	for p in at:
		lo = lo.min(p)
		hi = hi.max(p)
	# Three of its corners not in a line give the map from (x, z) to the texture.
	for b in range(1, at.size()):
		for c in range(b + 1, at.size()):
			var ab := Vector2(at[b].x - at[0].x, at[b].z - at[0].z)
			var ac := Vector2(at[c].x - at[0].x, at[c].z - at[0].z)
			if absf(ab.cross(ac)) > 1e-8:
				return {"lo": lo, "hi": hi, "inv": Transform2D(ab, ac, Vector2(at[0].x, at[0].z)).affine_inverse(),
					"uv0": uv[0], "du": uv[b] - uv[0], "dv": uv[c] - uv[0]}
	return {}


## `mi`'s mesh without its face that faces up (in this box's own space, `to_box`), on its material.
func _without_top(mi: MeshInstance3D, to_box: Transform3D) -> ArrayMesh:
	var arrays := mi.mesh.surface_get_arrays(0)
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var kept := PackedInt32Array()
	for t in int(index.size() / 3.0):
		if (to_box.basis * normals[index[t * 3]]).normalized().y < 0.99:
			kept.append_array(index.slice(t * 3, t * 3 + 3))
	arrays[Mesh.ARRAY_INDEX] = kept
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, mi.get_active_material(0))
	return mesh


## A flat quad over `rect` (x, z) at height `y`, facing up or down, textured as `face` is there, moved
## by `offset`.
func _quad(st: SurfaceTool, face: Dictionary, rect: Rect2, y: float, up: bool, offset: Vector3) -> void:
	var n := Vector3.UP if up else Vector3.DOWN
	var a := Vector3(rect.position.x, y, rect.position.y)
	var b := Vector3(rect.end.x, y, rect.position.y)
	var c := Vector3(rect.end.x, y, rect.end.y)
	var d := Vector3(rect.position.x, y, rect.end.y)
	_tri(st, face, a, b, c, n, offset)
	_tri(st, face, a, c, d, n, offset)


## One triangle, turned so its front faces `n` (Godot's front faces wind clockwise).
func _tri(st: SurfaceTool, face: Dictionary, a: Vector3, b: Vector3, c: Vector3, n: Vector3, offset: Vector3) -> void:
	if (c - a).cross(b - a).dot(n) < 0.0:
		var swap := b
		b = c
		c = swap
	for p: Vector3 in [a, b, c]:
		var s: Vector2 = (face.inv as Transform2D) * Vector2(p.x, p.z)
		st.set_normal(n)
		st.set_uv(face.uv0 + face.du * s.x + face.dv * s.y)
		st.add_vertex(p + offset)

