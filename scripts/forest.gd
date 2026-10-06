extends Node3D
## The forest from design/reference/the-forest.jpg and the-rest.jpg, built in code:
## faceted ground plates, pines, broadleaf trees and birches, the raccoon's home pine
## with its hollow, a bench, a dirt path, a stream with a footbridge, and the log cabin
## across it. Trees, bushes and the cabin use `see_through`, which main.gd drives so
## the raccoon can still be seen when he walks behind them.

const LowPoly := preload("res://scripts/lowpoly.gd")

# Albedo colours. Lighting changes them on screen, so they were tuned until
# screenshots matched colours sampled from the reference images.
const GRASS := Color("6e8a69")
const PINE := Color("42613f")
const PINE_TRUNK := Color("6b645c")
const BARK := Color("625b52")
const CANOPIES := {
	"green": Color("6f8c4b"),
	"olive": Color("6c773f"),
	"yellow": Color("9c9a46"),
	"gold": Color("ab9f45"),
}
const BIRCH_BARK := Color("d2d3cc")
const BIRCH_MARK := Color("2a2b2a")
const BIRCH_LEAF := Color("b3c680")
const BUSH := Color("507548")
const ROCK := Color("8f8f8b")
const CAP := Color("a8653f")
const STEM := Color("e2d8c6")
const LEAVES := [Color("c96a32"), Color("d27f38"), Color("b85a2e"), Color("a8763a"), Color("7d8a45")]
const TUFT := Color("567a50")
const CATTAIL := Color("6b4a32")
const PATH := Color("978b73")
const PATH_EDGE := Color("7f7a60")
const WATER := Color("6688a8")
const WATER_DEEP := Color("5b7c9c")
const BANK := Color("8a7c5f")
const WOOD := Color("b39a77")
const LOG := Color("84714f")
const ROOF := Color("5e4b3e")
const ROOF_MOSS := Color("8f6a3c")
const FRAME := Color("c8c2ae")
const GLASS := Color("4f6f94")
const DOOR := Color("6a4e36")
const PLANK := Color("8d7a5c")
const SLAT := Color("7c836d")
const IRON := Color("4b5547")
const HOLLOW_FLOOR := Color("6e5039")
const HOLLOW_WALL := Color("553c2a")
const HOLLOW_DARK := Color("3a291c")
const NEST := [Color("8a8a3e"), Color("9c9845"), Color("7b7f3a"), Color("6f7a3a"), Color("b0703a")]

## The raccoon's home pine. The ground round its roots is his den.
const HOME := Vector3(0, 0, -0.5)
const HOME_HEIGHT := 9.0
const DEN_RADIUS := 2.0
const START := Vector3(0, 0.02, 3.4)
const CABIN := Vector3(-5.5, 0, -20.0)
const BENCH := Vector3(6.0, 0, -1.6)
## Where the raccoon can walk. Trees beyond it are only scenery.
const BOUNDS := Rect2(-15, -23, 30, 33)
## Where scenery is generated.
const WORLD := Rect2(-44, -50, 88, 74)

## The hollow in the home pine: height of its centre, size (width, height), depth.
const HOLLOW_Y := 3.25
const HOLLOW_SIZE := Vector2(1.2, 1.15)
const HOLLOW_DEPTH := 0.95

# Control points (x, z) for the path, its fork to the east, and the stream.
const PATH_POINTS := [Vector2(-50, -2.6), Vector2(-30, -3.4), Vector2(-17, -3.0), Vector2(-10, -4.2),
	Vector2(-5.5, -6.4), Vector2(-1.5, -8.8), Vector2(2.6, -10.8), Vector2(4.6, -12.7), Vector2(4.4, -15.0),
	Vector2(1.8, -16.6), Vector2(-2.6, -17.4), Vector2(-5.5, -17.2)]
const FORK_POINTS := [Vector2(0.6, -9.9), Vector2(6.0, -9.6), Vector2(12.0, -8.4), Vector2(20.0, -8.8),
	Vector2(50.0, -7.6)]
const STREAM_POINTS := [Vector2(-50, -11.4), Vector2(-34, -12.8), Vector2(-20, -12.0), Vector2(-10, -13.4),
	Vector2(-2, -12.6), Vector2(4.5, -13.6), Vector2(12, -14.6), Vector2(22, -13.4), Vector2(34, -14.4),
	Vector2(50, -13.6)]

## Trees placed by hand to echo the reference's composition round the home pine:
## kind, position (x, z), scale.
const HERO_TREES := [["pine", Vector2(-3.6, -2.8), 1.05], ["green", Vector2(-6.9, -2.3), 1.12],
	["olive", Vector2(-10.3, -1.2), 1.0], ["yellow", Vector2(3.4, -3.4), 1.1], ["gold", Vector2(5.4, -5.4), 1.05],
	["birch", Vector2(8.9, -1.0), 1.0], ["birch", Vector2(10.0, -3.1), 1.08], ["olive", Vector2(12.3, -2.2), 1.05],
	["pine", Vector2(1.6, -6.6), 1.1], ["pine", Vector2(-1.4, -4.6), 0.95]]

## Resolution of the masks that say how far a spot is from the path and the stream.
const MASK := 0.5
## Cell size of the grid used to keep trees apart.
const SPACING_CELL := 3.3

## Where the raccoon curls up in the hollow, in world space.
var rest_spot: Transform3D
var bin_spot := Vector3(7.6, 0, -1.1)
var can_spots: Array[Vector3] = [Vector3(6.9, 0, -0.3), Vector3(8.4, 0, -0.5), Vector3(7.8, 0, 0.3),
	Vector3(2.8, 0, 2.4), Vector3(-4.2, 0, 6.0)]
## Top of the stump the gnome stands on.
var gnome_spot: Vector3
var see_through: ShaderMaterial

var _rng := RandomNumberGenerator.new()
var _body: StaticBody3D
var _path: PackedVector2Array
var _fork: PackedVector2Array
var _stream: PackedVector2Array
var _bridge := Vector2.ZERO
var _bridge_dir := Vector2.UP
var _near_path := {}
var _near_stream := {}
var _spacing := {}
## Every tree: [position (x, z), kind, trunk radius].
var _trees: Array = []
## Mesh variants by kind: [[mesh, trunk radius], ...].
var _variants := {}
## Instances waiting to become MultiMeshes: key -> {mesh, xforms, see, shadow}.
var _batches := {}


func _ready() -> void:
	_rng.seed = 11
	see_through = ShaderMaterial.new()
	see_through.shader = preload("res://scripts/see_through.gdshader")
	_body = StaticBody3D.new()
	add_child(_body)
	_collider(WorldBoundaryShape3D.new(), Transform3D.IDENTITY)

	_path = _spline(PATH_POINTS, 0.35)
	_fork = _spline(FORK_POINTS, 0.35)
	_stream = _spline(STREAM_POINTS, 0.35)
	_rasterize(_path, _near_path)
	_rasterize(_fork, _near_path)
	_rasterize(_stream, _near_stream)
	_find_bridge()

	_make_variants()
	_build_ground()
	_build_path_and_stream()
	_build_bridge()
	_build_home()
	_build_cabin()
	_build_bench()
	_plant_trees()
	_scatter()
	_build_walls()
	_flush()


# --- Ground, path and stream -------------------------------------------------

## The ground is big flat plates, each a slightly different green and tilt, with a
## thin dark seam wherever two plates meet.
func _build_ground() -> void:
	var cell := 2.8
	var origin := WORLD.position - Vector2(6, 4)
	var nx := int(ceil((WORLD.size.x + 12) / cell))
	var nz := int(ceil((WORLD.size.y + 8) / cell))
	var corners: Array = []
	for i in nx + 1:
		var column: Array[Vector2] = []
		for j in nz + 1:
			var p := origin + Vector2(i, j) * cell
			if i > 0 and i < nx and j > 0 and j < nz:
				p += Vector2(_rng.randf_range(-0.3, 0.3), _rng.randf_range(-0.3, 0.3)) * cell
			column.append(p)
		corners.append(column)

	# Merge neighbouring cells into bigger, irregular plates.
	var parent: Array[int] = []
	for k in nx * nz:
		parent.append(k)
	for i in nx:
		for j in nz:
			if i + 1 < nx and _rng.randf() < 0.32:
				_union(parent, i * nz + j, (i + 1) * nz + j)
			if j + 1 < nz and _rng.randf() < 0.32:
				_union(parent, i * nz + j, i * nz + j + 1)
	var plate: Array[int] = []
	var shade := {}
	var tilt := {}
	for k in nx * nz:
		var root := _find(parent, k)
		plate.append(root)
		if not shade.has(root):
			shade[root] = _vary(GRASS, 0.035)
			var lean := Vector3(_rng.randf_range(-1, 1), 0, _rng.randf_range(-1, 1)) * 0.07
			tilt[root] = (Vector3.UP + lean).normalized()

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in nx:
		for j in nz:
			var k := i * nz + j
			var a := _v3(corners[i][j])
			var b := _v3(corners[i + 1][j])
			var c := _v3(corners[i + 1][j + 1])
			var d := _v3(corners[i][j + 1])
			var color: Color = shade[plate[k]]
			var n: Vector3 = tilt[plate[k]]
			LowPoly.add_tri_attrs(st, [a, b, c], [n, n, n], [color, color, color], Vector3.UP)
			LowPoly.add_tri_attrs(st, [a, c, d], [n, n, n], [color, color, color], Vector3.UP)
	for i in nx:
		for j in nz:
			var k := i * nz + j
			if i + 1 < nx and plate[k] != plate[k + nz]:
				_seam(st, corners[i + 1][j], corners[i + 1][j + 1], plate[k], plate[k + nz], shade, tilt)
			if j + 1 < nz and plate[k] != plate[k + 1]:
				_seam(st, corners[i][j + 1], corners[i + 1][j + 1], plate[k + 1], plate[k], shade, tilt)
	_add_mesh(LowPoly.commit(st))


## A soft dark line along p -> q. `left` and `right` are the plates on either side.
func _seam(st: SurfaceTool, p: Vector2, q: Vector2, left: int, right: int, shade: Dictionary,
		tilt: Dictionary) -> void:
	var dir := (q - p).normalized()
	var side := Vector2(-dir.y, dir.x) * 0.025
	var lc: Color = shade[left]
	var rc: Color = shade[right]
	var mc := lc.lerp(rc, 0.5).darkened(0.17)
	var ln: Vector3 = tilt[left]
	var rn: Vector3 = tilt[right]
	var y := 0.003
	var pl := _v3(p + side, y)
	var pm := _v3(p, y)
	var pr := _v3(p - side, y)
	var ql := _v3(q + side, y)
	var qm := _v3(q, y)
	var qr := _v3(q - side, y)
	var up := Vector3.UP
	LowPoly.add_tri_attrs(st, [pl, pm, qm], [ln, up, up], [lc, mc, mc], up)
	LowPoly.add_tri_attrs(st, [pl, qm, ql], [ln, up, ln], [lc, mc, lc], up)
	LowPoly.add_tri_attrs(st, [pm, pr, qr], [up, rn, rn], [mc, rc, rc], up)
	LowPoly.add_tri_attrs(st, [pm, qr, qm], [up, rn, up], [mc, rc, mc], up)


func _build_path_and_stream() -> void:
	var off_stream := func(p: Vector2) -> bool: return _stream_dist(p) < 1.45
	for line: PackedVector2Array in [_path, _fork]:
		var lift := 0.0005 if line == _fork else 0.0
		_add_mesh(_ribbon(line, 0.88, 0.1, 0.004 + lift, PATH_EDGE, off_stream))
		_add_mesh(_ribbon(line, 0.74, 0.1, 0.006 + lift, PATH, off_stream))
	_add_mesh(_ribbon(_stream, 1.38, 0.12, 0.004, BANK))
	_add_mesh(_ribbon(_stream, 0.98, 0.1, 0.006, WATER))
	_add_mesh(_ribbon(_stream, 0.5, 0.12, 0.008, WATER_DEEP))


## A flat strip along `line` at height `y`, about `half_width` either side, with
## wobbly edges. Quads whose middle makes `skip` return true are left out.
func _ribbon(line: PackedVector2Array, half_width: float, wobble: float, y: float, color: Color,
		skip := Callable()) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lefts: Array[Vector3] = []
	var rights: Array[Vector3] = []
	var phase := _rng.randf() * TAU
	var s := 0.0
	for i in line.size():
		if i > 0:
			s += line[i].distance_to(line[i - 1])
		var dir := (line[mini(i + 1, line.size() - 1)] - line[maxi(i - 1, 0)]).normalized()
		var side := Vector2(-dir.y, dir.x)
		var wl := half_width + wobble * (sin(s * 0.8 + phase) * 0.6 + sin(s * 2.3 + phase * 1.7) * 0.4)
		var wr := half_width + wobble * (sin(s * 0.7 + phase * 2.3) * 0.6 + sin(s * 1.9 + phase * 0.6) * 0.4)
		lefts.append(_v3(line[i] + side * wl, y))
		rights.append(_v3(line[i] - side * wr, y))
	for i in line.size() - 1:
		if skip.is_valid() and skip.call((line[i] + line[i + 1]) * 0.5):
			continue
		var c := _vary(color, 0.02)
		var below := (lefts[i] + rights[i]) * 0.5 - Vector3.UP
		LowPoly.add_tri(st, lefts[i], rights[i], rights[i + 1], below, c)
		LowPoly.add_tri(st, lefts[i], rights[i + 1], lefts[i + 1], below, c)
	return LowPoly.commit(st)


## A plank footbridge where the path crosses the stream.
func _build_bridge() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 9:
		var plank := Transform3D(Basis(Vector3.UP, _rng.randf_range(-0.03, 0.03)), Vector3(0, 0.014, -1.6 + k * 0.4))
		LowPoly.add_box(st, plank, Vector3(1.3, 0.028, 0.36), _vary(PLANK, 0.06))
	for x: float in [-0.66, 0.66]:
		LowPoly.add_box(st, Transform3D(Basis(), Vector3(x, 0.03, 0)), Vector3(0.09, 0.05, 3.7), PLANK.darkened(0.2))
		for z: float in [-1.6, 0.0, 1.6]:
			LowPoly.add_box(st, Transform3D(Basis(), Vector3(x, 0.24, z)), Vector3(0.08, 0.44, 0.08), PLANK.darkened(0.12))
		LowPoly.add_box(st, Transform3D(Basis(), Vector3(x, 0.42, 0)), Vector3(0.06, 0.06, 3.5), PLANK)
	var xform := Transform3D(Basis(Vector3.UP, atan2(_bridge_dir.x, _bridge_dir.y)), _v3(_bridge))
	_add_mesh(LowPoly.commit(st), xform)
	for x: float in [-0.7, 0.7]:
		var rail := BoxShape3D.new()
		rail.size = Vector3(0.12, 2.0, 3.8)
		_collider(rail, xform * Transform3D(Basis(), Vector3(x, 1.0, 0)))


## Invisible walls round the play area and along both banks of the stream.
func _build_walls() -> void:
	var b := BOUNDS
	var c := b.get_center()
	for wall: Array in [[Vector2(c.x, b.position.y), Vector2(b.size.x, 0.4)], [Vector2(c.x, b.end.y), Vector2(b.size.x, 0.4)],
			[Vector2(b.position.x, c.y), Vector2(0.4, b.size.y)], [Vector2(b.end.x, c.y), Vector2(0.4, b.size.y)]]:
		var box := BoxShape3D.new()
		box.size = Vector3(wall[1].x, 3.0, wall[1].y)
		_collider(box, Transform3D(Basis(), _v3(wall[0], 1.5)))
	for i in range(0, _stream.size() - 2, 2):
		var p := _stream[i]
		var q := _stream[i + 2]
		var mid := (p + q) * 0.5
		if mid.x < b.position.x - 1.0 or mid.x > b.end.x + 1.0 or mid.distance_to(_bridge) < 0.75:
			continue
		var dir := (q - p).normalized()
		var side := Vector2(-dir.y, dir.x)
		for sgn: float in [-1.0, 1.0]:
			var box := BoxShape3D.new()
			box.size = Vector3(p.distance_to(q) + 0.3, 2.0, 0.3)
			_collider(box, Transform3D(Basis(Vector3.UP, -atan2(dir.y, dir.x)), _v3(mid + side * sgn * 1.15, 1.0)))


# --- The home pine -----------------------------------------------------------

func _build_home() -> void:
	var h := HOME_HEIGHT
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	LowPoly.add_tube(st, [Vector3.ZERO, Vector3(0, 0.45, 0), Vector3(0, 2.4, 0), Vector3(0, h * 0.6, 0)],
		[0.6, 0.5, 0.44, 0.28], 7, LowPoly.solid(PINE_TRUNK), 0.2, [1.7, 1.15, 1.6, 1.1, 1.65, 1.2, 1.5])
	var rest := _add_hollow_tier(st, h * 0.24, h * 0.8, h * 0.21)
	var tiers := [[0.45, 0.15], [0.6, 0.115], [0.74, 0.08]]
	for i in tiers.size():
		var hem: float = h * tiers[i][0]
		var apex := h if i == tiers.size() - 1 else hem + h * 0.26
		_add_pine_tier(st, hem, apex, h * tiers[i][1], 0.4 + i * 1.3, PINE)
	_add_mesh(LowPoly.commit(st), Transform3D(Basis(), HOME), true)
	var trunk := CylinderShape3D.new()
	trunk.radius = 0.85
	trunk.height = 3.0
	_collider(trunk, Transform3D(Basis(), HOME + Vector3(0, 1.5, 0)))
	_remember(_v2(HOME))
	# He lies across the hollow facing -X, so his side and curled tail face the camera.
	rest_spot = Transform3D(Basis(Vector3.UP, PI / 2), HOME + rest)


## The home pine's bottom skirt, with a hexagonal hollow cut into the side that faces
## the camera (+Z) and a nest of leaves inside. Returns where the raccoon lies,
## relative to the tree.
func _add_hollow_tier(st: SurfaceTool, hem: float, apex: float, radius: float) -> Vector3:
	var ring := _hem_ring(hem, radius, 5, 0.0)
	var top := Vector3(0, apex, 0)
	var n := ring.size()
	for k in range(1, n - 1):
		_tier_face(st, ring[k], ring[k + 1], top, hem, radius, PINE)

	# The hole straddles the fold that runs from the hem point at +Z up to the apex.
	var p: Vector3 = ring[0]
	var right: Vector3 = ring[1]
	var left: Vector3 = ring[n - 1]
	var fold := top - p
	var sc := (HOLLOW_Y - p.y) / fold.y
	var hs := HOLLOW_SIZE.y * 0.5 / fold.length()
	var t := p + fold * (sc + hs)
	var b := p + fold * (sc - hs)
	var corners: Array = []
	for notch: Vector3 in [right, left]:
		var span := notch - p
		var w := minf(HOLLOW_SIZE.x * 0.5 / absf(span.x), 0.86 - sc - hs * 0.5)
		corners.append([p + fold * (sc + hs * 0.5) + span * w, p + fold * (sc - hs * 0.5) + span * w])
	var ur: Vector3 = corners[0][0]
	var lr: Vector3 = corners[0][1]
	var ul: Vector3 = corners[1][0]
	var ll: Vector3 = corners[1][1]
	# What's left of the two faces round the hole, fanned from their notches.
	for tri: Array in [[right, top, t], [right, t, ur], [right, ur, lr], [right, lr, b], [right, b, p],
			[left, p, b], [left, b, ll], [left, ll, ul], [left, ul, t], [left, t, top]]:
		var a: Vector3 = tri[0]
		var bb: Vector3 = tri[1]
		var c: Vector3 = tri[2]
		LowPoly.add_tri(st, a, bb, c, Vector3(0, (a.y + bb.y + c.y) / 3.0, 0), PINE)
	for k: int in [0, n - 1]:
		LowPoly.add_tri(st, ring[k], ring[(k + 1) % n], Vector3(0, hem + radius * 0.3, 0), top, PINE.darkened(0.4))

	# The hollow itself: walls from the rim back into the tree, then a back wall.
	var rim: Array[Vector3] = [t, ur, lr, b, ll, ul]
	var center := (t + b) * 0.5
	var out := Vector3(0, -fold.z, fold.y).normalized()
	var inner: Array[Vector3] = []
	for v in rim:
		inner.append(center + (v - center) * 0.72 - out * HOLLOW_DEPTH)
	var axis := center - out * HOLLOW_DEPTH * 0.5
	for k in 6:
		var a := rim[k]
		var bb := rim[(k + 1) % 6]
		var c := inner[(k + 1) % 6]
		var d := inner[k]
		var mid := (a + bb + c + d) * 0.25
		var normal := (bb - a).cross(d - a).normalized()
		if normal.dot(axis - mid) < 0.0:
			normal = -normal
		var color := HOLLOW_WALL
		if normal.y > 0.35:
			color = HOLLOW_FLOOR
		elif normal.y < -0.35:
			color = HOLLOW_DARK
		LowPoly.add_tri(st, a, bb, c, mid - normal, color)
		LowPoly.add_tri(st, a, c, d, mid - normal, color)
	var back := center - out * HOLLOW_DEPTH
	for k in 6:
		LowPoly.add_tri(st, inner[k], inner[(k + 1) % 6], back, back - out, HOLLOW_DARK)

	var nest_rng := RandomNumberGenerator.new()
	nest_rng.seed = 5
	var nest := center - out * HOLLOW_DEPTH * 0.55 + Vector3(0, -HOLLOW_SIZE.y * 0.3, 0)
	LowPoly.add_icosphere(st, nest, Vector3(0.5, 0.13, 0.36), 1, 0.35, 21,
		func(_n: Vector3) -> Color: return NEST[nest_rng.randi() % NEST.size()])
	return nest + Vector3(0, 0.07, 0)


# --- Trees -------------------------------------------------------------------

## A pine hem: `panels` points hanging a little lower than the notches between them,
## which gives the reference's pleated skirts. Point 0 faces +Z (before `twist`).
func _hem_ring(hem: float, radius: float, panels: int, twist: float) -> Array[Vector3]:
	var ring: Array[Vector3] = []
	for k in panels * 2:
		var a := twist + TAU * k / (panels * 2)
		var point := k % 2 == 0
		var r := radius if point else radius * 0.84
		var y := hem - radius * 0.06 if point else hem + radius * 0.1
		ring.append(Vector3(sin(a) * r, y, cos(a) * r))
	return ring


## One face of a pine skirt, plus its underside so the skirt is solid from below.
func _tier_face(st: SurfaceTool, a: Vector3, b: Vector3, top: Vector3, hem: float, radius: float,
		color: Color) -> void:
	LowPoly.add_tri(st, a, b, top, Vector3(0, (a.y + b.y + top.y) / 3.0, 0), color)
	LowPoly.add_tri(st, a, b, Vector3(0, hem + radius * 0.3, 0), top, color.darkened(0.4))


func _add_pine_tier(st: SurfaceTool, hem: float, apex: float, radius: float, twist: float, color: Color) -> void:
	var ring := _hem_ring(hem, radius, 7, twist)
	var top := Vector3(0, apex, 0)
	for k in ring.size():
		_tier_face(st, ring[k], ring[(k + 1) % ring.size()], top, hem, radius, color)


func _pine_mesh(h: float, tiers: int, seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	LowPoly.add_tube(st, [Vector3.ZERO, Vector3(0, h * 0.05, 0), Vector3(0, h * 0.62, 0)],
		[h * 0.046, h * 0.038, h * 0.022], 6, LowPoly.solid(PINE_TRUNK), rng.randf() * TAU,
		[1.6, 1.1, 1.5, 1.05, 1.55, 1.15])
	var color := _vary(PINE, 0.04, rng)
	for i in tiers:
		var t := float(i) / (tiers - 1)
		var hem := h * lerpf(0.3, 0.8, t)
		var apex := h if i == tiers - 1 else hem + h * 0.25
		_add_pine_tier(st, hem, apex, h * lerpf(0.155, 0.06, pow(t, 1.3)), rng.randf() * TAU, color)
	return LowPoly.commit(st)


## A broadleaf tree: a trunk that forks into limbs, under a crown of faceted clumps.
func _broadleaf_mesh(h: float, color: Color, seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lean := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)) * h * 0.02
	var fork := Vector3(0, h * rng.randf_range(0.36, 0.44), 0) + lean
	var r := h * 0.03
	LowPoly.add_tube(st, [Vector3.ZERO, Vector3(0, h * 0.04, 0), fork * 0.6, fork], [r * 1.5, r * 1.15, r, r * 0.85],
		6, LowPoly.solid(BARK), rng.randf() * TAU, [1.8, 1.0, 1.6, 1.05, 1.7, 1.0])

	# One clump on top, a ring round the middle, a ring below, maybe one low on a limb.
	var clumps: Array = [[Vector3(0, h * 0.85, 0) + lean * 2.0, h * rng.randf_range(0.15, 0.17)]]
	for ring: Array in [[rng.randi_range(3, 4), 0.12, 0.16, 0.72, 0.78, 0.14, 0.16],
			[rng.randi_range(4, 5), 0.18, 0.23, 0.58, 0.64, 0.13, 0.15]]:
		var spin := rng.randf() * TAU
		for k in ring[0]:
			var a: float = spin + TAU * k / ring[0] + rng.randf_range(-0.3, 0.3)
			var d := h * rng.randf_range(ring[1], ring[2])
			var y := h * rng.randf_range(ring[3], ring[4])
			clumps.append([Vector3(cos(a) * d, y, sin(a) * d) + lean * 1.8, h * rng.randf_range(ring[5], ring[6])])
	if rng.randf() < 0.6:
		var a := rng.randf() * TAU
		clumps.append([Vector3(cos(a) * h * 0.27, h * 0.47, sin(a) * h * 0.27), h * rng.randf_range(0.085, 0.1)])
	for clump: Array in clumps:
		var target: Vector3 = clump[0]
		LowPoly.add_tube(st, [fork, fork.lerp(target, 0.5) + Vector3(0, h * 0.02, 0), target],
			[r * 0.6, r * 0.42, r * 0.25], 5, LowPoly.solid(BARK))
	for clump: Array in clumps:
		var c := _vary(color, 0.05, rng)
		var size: float = clump[1]
		LowPoly.add_icosphere(st, clump[0], Vector3(size, size * 0.88, size), 1, 0.14, rng.randi(),
			func(_n: Vector3) -> Color: return c)
	return LowPoly.commit(st)


## A birch: a white trunk with black dashes, thin limbs and small pale clumps.
func _birch_mesh(h: float, seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lean := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized() * h * 0.03
	var top := Vector3(0, h * 0.9, 0) + lean
	var r0 := h * 0.019
	var sides := 6
	# Bark rings, with a thin band between some of them for the dashes.
	var centers: Array = []
	var radii: Array = []
	var marks := {}
	var y := 0.0
	while y < top.y:
		var u := y / top.y
		centers.append(Vector3(0, y, 0) + lean * u * u)
		radii.append(lerpf(r0, r0 * 0.45, u))
		if y > 0.2 and rng.randf() < 0.55:
			marks[centers.size() - 1] = [rng.randi() % sides, rng.randi_range(1, 3)]
			y += h * 0.006
		else:
			y += h * rng.randf_range(0.035, 0.06)
	centers.append(top)
	radii.append(r0 * 0.4)
	var bark := func(segment: int, side: int, _n: Vector3) -> Color:
		if marks.has(segment):
			var m: Array = marks[segment]
			if (side - int(m[0]) + sides) % sides < int(m[1]):
				return BIRCH_MARK
		return BIRCH_BARK
	LowPoly.add_tube(st, centers, radii, sides, bark, 0.0, [1.25, 1.1, 1.2, 1.1, 1.3, 1.1])

	var leaf := func(_n: Vector3) -> Color: return _vary(BIRCH_LEAF, 0.04, rng)
	var limbs := rng.randi_range(3, 4)
	var spin := rng.randf() * TAU
	for k in limbs:
		var a := spin + k * 2.4
		var base_y := h * lerpf(0.45, 0.78, float(k) / maxf(limbs - 1, 1))
		var base := Vector3(0, base_y, 0) + lean * pow(base_y / top.y, 2.0)
		var tip := base + Vector3(cos(a) * h * rng.randf_range(0.12, 0.18), h * rng.randf_range(0.12, 0.18),
			sin(a) * h * rng.randf_range(0.12, 0.18))
		LowPoly.add_tube(st, [base, base.lerp(tip, 0.5), tip], [r0 * 0.5, r0 * 0.35, r0 * 0.22], 5,
			LowPoly.solid(BIRCH_BARK))
		for m in rng.randi_range(1, 2):
			var off := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.5, 0.8), rng.randf_range(-1, 1)) * h * 0.04
			var size := h * rng.randf_range(0.06, 0.08)
			LowPoly.add_icosphere(st, tip + off, Vector3(size, size * 0.9, size), 1, 0.15, rng.randi(), leaf)
	for m in rng.randi_range(3, 4):
		var off := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.6, 0.6), rng.randf_range(-1, 1)) * h * 0.06
		var size := h * rng.randf_range(0.065, 0.085)
		LowPoly.add_icosphere(st, top + off + Vector3(0, h * 0.02, 0), Vector3(size, size * 0.9, size), 1, 0.15,
			rng.randi(), leaf)
	return LowPoly.commit(st)


func _make_variants() -> void:
	var pines: Array = []
	for i in 5:
		var h: float = [5.0, 5.6, 6.2, 6.8, 4.6][i]
		pines.append([_pine_mesh(h, [5, 5, 6, 6, 4][i], 100 + i), h * 0.046])
	_variants["pine"] = pines
	for kind: String in CANOPIES:
		var list: Array = []
		for i in 2:
			var h := 4.4 + i * 0.7
			list.append([_broadleaf_mesh(h, CANOPIES[kind], kind.hash() + i), h * 0.034])
		_variants[kind] = list
	var birches: Array = []
	for i in 3:
		var h := 5.0 + i * 0.6
		birches.append([_birch_mesh(h, 300 + i), h * 0.022])
	_variants["birch"] = birches
	_variants["bush"] = [[_bush_mesh(400), 0.0], [_bush_mesh(401), 0.0], [_bush_mesh(402), 0.0]]
	var rocks: Array = []
	for i in 5:
		rocks.append([_rock_mesh(500 + i), 0.0])
	_variants["rock"] = rocks
	_variants["mushroom"] = [[_mushroom_mesh(600), 0.0], [_mushroom_mesh(601), 0.0]]
	_variants["tuft"] = [[_tuft_mesh(700), 0.0], [_tuft_mesh(701), 0.0], [_tuft_mesh(702), 0.0]]
	_variants["reed"] = [[_reed_mesh(800), 0.0], [_reed_mesh(801), 0.0]]
	var leaves: Array = []
	for color: Color in LEAVES:
		leaves.append([_leaf_mesh(color), 0.0])
	_variants["leaf"] = leaves
	_variants["stump"] = [[_stump_mesh(900), 0.0]]


func _plant_trees() -> void:
	for tree: Array in HERO_TREES:
		_add_tree(tree[0], tree[1], tree[2])
	for i in 7000:
		var p := Vector2(_rng.randf_range(WORLD.position.x, WORLD.end.x), _rng.randf_range(WORLD.position.y, WORLD.end.y))
		if _is_open(p) or _too_close(p, 2.9 if BOUNDS.has_point(p) else 2.6):
			continue
		_add_tree(_random_kind(), p)


func _random_kind() -> String:
	var r := _rng.randf()
	if r < 0.42:
		return "pine"
	if r < 0.56:
		return "green"
	if r < 0.66:
		return "olive"
	if r < 0.75:
		return "yellow"
	if r < 0.81:
		return "gold"
	return "birch"


func _add_tree(kind: String, p: Vector2, scale := 1.0) -> void:
	var list: Array = _variants[kind]
	var pick := _rng.randi() % list.size()
	var s := scale * _rng.randf_range(0.88, 1.12)
	var xform := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * s), _v3(p))
	_place("%s%d" % [kind, pick], list[pick][0], xform, true)
	_remember(p)
	var trunk: float = list[pick][1] * s
	_trees.append([p, kind, trunk])
	if BOUNDS.grow(1.0).has_point(p):
		var shape := CylinderShape3D.new()
		shape.radius = trunk + 0.08
		shape.height = 2.0
		_collider(shape, Transform3D(Basis(), _v3(p, 1.0)))


## Spots where no tree may grow: the clearing, the paths, the stream, the cabin's yard,
## and everything south of the clearing, where trees would stand in front of the camera.
func _is_open(p: Vector2) -> bool:
	if p.y > 10.5:
		return true
	if p.y > -1.8 + sin(p.x * 0.5) * 0.8 and absf(p.x) < 11.5 + sin(p.y * 0.45) * 1.5:
		return true
	if p.distance_to(_v2(HOME)) < 3.6 or p.distance_to(_v2(BENCH)) < 2.6 or p.distance_to(_v2(bin_spot)) < 1.8:
		return true
	if _path_dist(p) < 1.5 or _stream_dist(p) < 2.1:
		return true
	return Rect2(CABIN.x - 4.6, CABIN.z - 3.0, 9.2, 8.5).has_point(p)


# --- Small things ------------------------------------------------------------

func _bush_mesh(seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := rng.randi_range(3, 5)
	for k in count:
		var a := TAU * k / count + rng.randf_range(-0.4, 0.4)
		var d := 0.0 if k == 0 else rng.randf_range(0.35, 0.6)
		var r := rng.randf_range(0.42, 0.58) if k == 0 else rng.randf_range(0.32, 0.46)
		var c := _vary(BUSH, 0.04, rng)
		LowPoly.add_icosphere(st, Vector3(cos(a) * d, r * 0.72, sin(a) * d), Vector3(r, r * 0.85, r), 1, 0.16,
			rng.randi(), func(_n: Vector3) -> Color: return c)
	return LowPoly.commit(st)


## A rock about 1 m across; instances scale it down.
func _rock_mesh(seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	LowPoly.add_icosphere(st, Vector3(0, 0.09, 0), Vector3(1.0, 0.62, 0.82) * 0.5, 0, 0.22, seed,
		func(n: Vector3) -> Color: return _vary(ROCK, 0.05, rng).lightened(maxf(n.y, 0.0) * 0.08), -0.3)
	return LowPoly.commit(st)


func _mushroom_mesh(seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	LowPoly.add_tube(st, [Vector3.ZERO, Vector3(0, 0.075, 0)], [0.018, 0.015], 6, LowPoly.solid(STEM))
	var rim: Array[Vector3] = []
	var crown: Array[Vector3] = []
	for k in 8:
		var a := TAU * k / 8.0
		rim.append(Vector3(sin(a) * 0.06, 0.062, cos(a) * 0.06))
		crown.append(Vector3(sin(a) * 0.036, 0.098, cos(a) * 0.036))
	var tip := Vector3(0, 0.112, 0)
	var under := Vector3(0, 0.076, 0)
	var cap := _vary(CAP, 0.06, rng)
	for k in 8:
		var a := rim[k]
		var b := rim[(k + 1) % 8]
		var c := crown[(k + 1) % 8]
		var d := crown[k]
		LowPoly.add_tri(st, a, b, c, under, cap)
		LowPoly.add_tri(st, a, c, d, under, cap)
		LowPoly.add_tri(st, d, c, tip, under, cap.lightened(0.05))
		LowPoly.add_tri(st, a, b, under, tip, STEM.darkened(0.15))
	return LowPoly.commit(st)


## A tuft of grass blades; `tall` stretches them into reeds.
func _tuft_mesh(seed: int, tall := 1.0) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_blades(st, rng, tall)
	return LowPoly.commit(st)


func _add_blades(st: SurfaceTool, rng: RandomNumberGenerator, tall: float) -> void:
	var blades := rng.randi_range(5, 7)
	for k in blades:
		var a := TAU * k / blades + rng.randf_range(-0.5, 0.5)
		var out := Vector3(cos(a), 0, sin(a))
		var height := rng.randf_range(0.13, 0.25) * tall
		var base := out * rng.randf_range(0.0, 0.04)
		var tip := base + out * height * rng.randf_range(0.2, 0.55) + Vector3(0, height, 0)
		var side := Vector3(-out.z, 0, out.x) * 0.017 * sqrt(tall)
		var c := _vary(TUFT, 0.07, rng)
		var n := (side * 2.0).cross(tip - (base - side)).normalized()
		var mid := (base + tip) * 0.5
		LowPoly.add_tri(st, base - side, base + side, tip, mid - n, c)
		LowPoly.add_tri(st, base - side, base + side, tip, mid + n, c.darkened(0.1))


## Reeds for the stream banks: tall blades and a couple of cattails.
func _reed_mesh(seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_blades(st, rng, 2.4)
	for k in 2:
		var at := Vector3(rng.randf_range(-0.05, 0.05), 0, rng.randf_range(-0.05, 0.05))
		var height := rng.randf_range(0.42, 0.55)
		LowPoly.add_tube(st, [at, at + Vector3(0, height, 0)], [0.006, 0.005], 4, LowPoly.solid(TUFT))
		LowPoly.add_tube(st, [at + Vector3(0, height, 0), at + Vector3(0, height + 0.11, 0)], [0.018, 0.016], 6,
			LowPoly.solid(CATTAIL))
	return LowPoly.commit(st)


func _leaf_mesh(color: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var outline: Array[Vector3] = [Vector3(0.075, 0, 0), Vector3(0.027, 0, 0.031), Vector3(-0.033, 0, 0.028),
		Vector3(-0.075, 0, 0), Vector3(-0.03, 0, -0.03), Vector3(0.03, 0, -0.031)]
	for k in 6:
		LowPoly.add_tri(st, Vector3.ZERO, outline[k], outline[(k + 1) % 6], Vector3.DOWN, color)
	return LowPoly.commit(st)


func _stump_mesh(seed: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	LowPoly.add_tube(st, [Vector3.ZERO, Vector3(0, 0.07, 0), Vector3(0, 0.32, 0)], [0.27, 0.23, 0.22], 8,
		func(_s: int, _i: int, n: Vector3) -> Color: return WOOD if n.y > 0.9 else BARK, float(seed % 7),
		[1.5, 1.05, 1.4, 1.0, 1.45, 1.1, 1.35, 1.0])
	# Growth rings on the cut.
	for k in 8:
		var a := TAU * k / 8.0
		var b := TAU * (k + 1) / 8.0
		LowPoly.add_tri(st, Vector3(0, 0.323, 0), Vector3(sin(a) * 0.12, 0.323, cos(a) * 0.12),
			Vector3(sin(b) * 0.12, 0.323, cos(b) * 0.12), Vector3(0, 0, 0), WOOD.darkened(0.12))
	return LowPoly.commit(st)


func _scatter() -> void:
	# Rocks, mostly small, plus the big ones in the corner of the clearing.
	for i in 150:
		var p := _random_spot()
		if _free_ground(p, 0.6):
			_add_rock(p, 0.12 + pow(_rng.randf(), 2.2) * 0.45)
	for rock: Array in [[Vector2(9.2, 7.4), 1.5], [Vector2(9.95, 8.25), 1.0], [Vector2(8.5, 8.4), 0.75],
			[Vector2(-2.6, -13.4), 0.7], [Vector2(-8.3, -15.2), 0.9], [Vector2(-7.4, -15.6), 0.55]]:
		_add_rock(rock[0], rock[1])

	# Stumps: one by the stream as in the reference, and the gnome's in the cabin's yard.
	for spot: Vector2 in [Vector2(-0.9, -11.0), Vector2(-8.6, 4.8), Vector2(11.4, 5.6)]:
		_add_stump(spot)
	var gnome_stump := Vector2(CABIN.x + 3.6, CABIN.z + 0.8)
	_add_stump(gnome_stump)
	gnome_spot = _v3(gnome_stump, 0.32)

	# Mushrooms round the roots of some trees.
	for i in 22:
		var tree: Array = _trees[_rng.randi() % _trees.size()]
		for k in _rng.randi_range(1, 3):
			var p: Vector2 = tree[0] + Vector2.from_angle(_rng.randf() * TAU) * (tree[2] + _rng.randf_range(0.3, 0.8))
			if _free_ground(p, 0.0):
				var xform := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.8, 1.5)), _v3(p))
				_place_variant("mushroom", xform, false)

	# Grass tufts: half at the feet of trees and rocks, half anywhere.
	for i in 520:
		var p := _random_spot()
		if i % 2 == 0:
			var tree: Array = _trees[_rng.randi() % _trees.size()]
			p = tree[0] + Vector2.from_angle(_rng.randf() * TAU) * (tree[2] + _rng.randf_range(0.2, 1.0))
		if _free_ground(p, 0.0):
			var xform := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.8, 1.3)), _v3(p))
			_place_variant("tuft", xform, false)

	# Fallen leaves, mostly under the broadleaf trees and birches.
	var leafy: Array = _trees.filter(func(t: Array) -> bool: return t[1] != "pine")
	for i in 1400:
		var p := _random_spot()
		if _rng.randf() < 0.7:
			var tree: Array = leafy[_rng.randi() % leafy.size()]
			p = tree[0] + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(0.3, 3.4)
		if _path_dist(p) > 0.9 and _stream_dist(p) > 1.5:
			var xform := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU), _v3(p, 0.01))
			_place_variant("leaf", xform, false)

	# Reeds along the banks of the stream.
	for i in 40:
		var at := _rng.randi_range(4, _stream.size() - 5)
		var q := _stream[at]
		if absf(q.x) > 24.0 or q.distance_to(_bridge) < 2.0:
			continue
		var dir := (_stream[at + 1] - _stream[at - 1]).normalized()
		var p := q + Vector2(-dir.y, dir.x) * (1.05 + _rng.randf() * 0.3) * (1.0 if _rng.randf() < 0.5 else -1.0)
		var xform := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.8, 1.2)), _v3(p))
		_place_variant("reed", xform, false)


func _random_spot() -> Vector2:
	return Vector2(_rng.randf_range(BOUNDS.position.x - 14, BOUNDS.end.x + 14),
		_rng.randf_range(BOUNDS.position.y - 12, BOUNDS.end.y + 4))


## True where small things can lie: off the path and the stream, clear of trunks,
## out of the cabin and away from the bench.
func _free_ground(p: Vector2, margin: float) -> bool:
	if _path_dist(p) < 1.0 + margin or _stream_dist(p) < 1.45 + margin:
		return false
	if Rect2(CABIN.x - 2.9, CABIN.z - 2.3, 5.8, 4.8).has_point(p) or p.distance_to(_v2(BENCH)) < 1.0:
		return false
	if p.distance_to(_v2(HOME)) < 1.5:
		return false
	var c := _cell(p, SPACING_CELL)
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			for q: Vector2 in _spacing.get(c + Vector2i(dx, dy), []):
				if p.distance_to(q) < 0.45 + margin:
					return false
	return true


func _add_rock(p: Vector2, size: float) -> void:
	var s := Vector3(size, size * _rng.randf_range(0.75, 1.2), size * _rng.randf_range(0.8, 1.1))
	_place_variant("rock", Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(s), _v3(p)))
	if size > 0.45 and BOUNDS.has_point(p):
		var shape := CylinderShape3D.new()
		shape.radius = size * 0.42
		shape.height = 1.0
		_collider(shape, Transform3D(Basis(), _v3(p, 0.5)))


func _add_stump(p: Vector2) -> void:
	_place_variant("stump", Transform3D(Basis(Vector3.UP, _rng.randf() * TAU), _v3(p)))
	_remember(p)
	var shape := CylinderShape3D.new()
	shape.radius = 0.3
	shape.height = 0.64
	_collider(shape, Transform3D(Basis(), _v3(p, 0.0)))


func _add_bush(p: Vector2, scale: float) -> void:
	var xform := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * scale), _v3(p))
	_place_variant("bush", xform, true, true)
	_remember(p)
	var shape := CylinderShape3D.new()
	shape.radius = 0.7 * scale
	shape.height = 1.2
	_collider(shape, Transform3D(Basis(), _v3(p, 0.6)))


# --- Bench and cabin -----------------------------------------------------------

func _build_bench() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 3:
		LowPoly.add_box(st, Transform3D(Basis(), Vector3(0, 0.44, -0.12 + k * 0.12)), Vector3(1.4, 0.035, 0.1),
			_vary(SLAT, 0.03))
	var lean := Basis(Vector3.RIGHT, -0.18)
	for y: float in [0.62, 0.77]:
		LowPoly.add_box(st, Transform3D(lean, Vector3(0, y, -0.2 - (y - 0.5) * 0.18)), Vector3(1.4, 0.1, 0.03),
			_vary(SLAT, 0.03))
	for x: float in [-0.58, 0.58]:
		LowPoly.add_box(st, Transform3D(Basis(), Vector3(x, 0.21, 0.14)), Vector3(0.05, 0.42, 0.05), IRON)
		LowPoly.add_box(st, Transform3D(lean, Vector3(x, 0.42, -0.2)), Vector3(0.05, 0.84, 0.05), IRON)
		LowPoly.add_box(st, Transform3D(Basis(), Vector3(x, 0.41, -0.02)), Vector3(0.05, 0.04, 0.42), IRON)
	var xform := Transform3D(Basis(Vector3.UP, 0.12), BENCH)
	_add_mesh(LowPoly.commit(st), xform)
	var seat := BoxShape3D.new()
	seat.size = Vector3(1.5, 1.0, 0.55)
	_collider(seat, xform * Transform3D(Basis(), Vector3(0, 0.5, -0.03)))
	_remember(_v2(BENCH))
	# Bushes huddled behind the bench, as in the reference.
	for bush: Array in [[Vector2(-1.5, -1.0), 0.95], [Vector2(-0.2, -1.5), 1.1], [Vector2(1.4, -1.1), 1.0],
			[Vector2(-2.4, 0.1), 0.8]]:
		_add_bush(_v2(BENCH) + bush[0], bush[1])


func _build_cabin() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w := 5.0
	var d := 3.8
	var r := 0.12
	var wall := 2.16
	var ridge := 3.55
	# Front and back walls: logs along X that poke out past the corners.
	var y := r
	while y < wall:
		for z: float in [d * 0.5, -d * 0.5]:
			_log(st, Vector3(-w * 0.5 - 0.24, y, z), Vector3(w * 0.5 + 0.24, y, z), r)
		y += r * 2.0
	# Side walls sit half a log higher and carry on up into the gables.
	y = r * 2.0
	while y < ridge - 0.2:
		var half := d * 0.5 + 0.24
		if y > wall:
			half = d * 0.5 * (1.0 - (y - wall) / (ridge - wall))
		for x: float in [-w * 0.5, w * 0.5]:
			_log(st, Vector3(x, y, -half), Vector3(x, y, half), r)
		y += r * 2.0

	# Roof: stepped rows of shingles down each side of the ridge, with a few mossy patches.
	var eave := d * 0.5 + 0.5
	var drop := ridge + 0.1 - (wall - 0.1)
	var angle := atan2(drop, eave)
	var row_length := Vector2(eave, drop).length() / 4.0
	for side: float in [1.0, -1.0]:
		var tilt := Basis(Vector3.RIGHT, side * angle)
		for k in 4:
			var u := (k + 0.5) / 4.0
			var pos := Vector3(0, ridge + 0.1 - drop * u, side * eave * u) + tilt.y * 0.03 * (k % 2)
			LowPoly.add_box(st, Transform3D(tilt, pos), Vector3(w + 0.9, 0.08, row_length + 0.1), _vary(ROOF, 0.05))
		for k in 3:
			var u := _rng.randf_range(0.2, 0.85)
			var pos := Vector3(_rng.randf_range(-2.0, 2.0), ridge + 0.1 - drop * u, side * eave * u) + tilt.y * 0.075
			LowPoly.add_box(st, Transform3D(tilt, pos), Vector3(_rng.randf_range(0.4, 0.9), 0.02, 0.4), _vary(ROOF_MOSS, 0.08))
	LowPoly.add_box(st, Transform3D(Basis(), Vector3(0, ridge + 0.14, 0)), Vector3(w + 0.95, 0.12, 0.26), ROOF.darkened(0.2))

	# Door, windows and a step at the front; another window on the east side.
	var front := d * 0.5 + r + 0.02
	LowPoly.add_box(st, Transform3D(Basis(), Vector3(1.2, 0.98, front)), Vector3(1.0, 1.96, 0.05), DOOR.darkened(0.25))
	LowPoly.add_box(st, Transform3D(Basis(), Vector3(1.2, 0.95, front + 0.02)), Vector3(0.86, 1.86, 0.05), DOOR)
	for x: float in [-1.7, -0.3]:
		_window(st, Transform3D(Basis(), Vector3(x, 1.3, front)))
	_window(st, Transform3D(Basis(Vector3.UP, PI / 2), Vector3(w * 0.5 + r + 0.02, 1.3, -0.3)))
	LowPoly.add_box(st, Transform3D(Basis(), Vector3(1.2, 0.08, front + 0.3)), Vector3(1.4, 0.16, 0.55), PLANK)

	_add_mesh(LowPoly.commit(st), Transform3D(Basis(), CABIN), true)
	var box := BoxShape3D.new()
	box.size = Vector3(w + 0.6, 3.0, d + 0.6)
	_collider(box, Transform3D(Basis(), CABIN + Vector3(0, 1.5, 0)))


func _log(st: SurfaceTool, a: Vector3, b: Vector3, r: float) -> void:
	var color := _vary(LOG, 0.06)
	var mesh := LowPoly.loft([a, b], [Vector2(r, r), Vector2(r, r)], 7,
		func(segment: int, _side: int, _n: Vector3) -> Color: return WOOD if segment != 0 else color)
	st.append_from(mesh, 0, Transform3D.IDENTITY)


func _window(st: SurfaceTool, xform: Transform3D) -> void:
	LowPoly.add_box(st, xform, Vector3(0.78, 0.78, 0.05), FRAME)
	LowPoly.add_box(st, xform.translated_local(Vector3(0, 0, 0.012)), Vector3(0.64, 0.64, 0.05), GLASS)
	LowPoly.add_box(st, xform.translated_local(Vector3(0, 0, 0.02)), Vector3(0.05, 0.64, 0.05), FRAME)
	LowPoly.add_box(st, xform.translated_local(Vector3(0, 0, 0.02)), Vector3(0.64, 0.05, 0.05), FRAME)


# --- Helpers -----------------------------------------------------------------

## Adds an instance of a mesh to its MultiMesh batch.
func _place(key: String, mesh: Mesh, xform: Transform3D, see := false, shadow := true) -> void:
	if not _batches.has(key):
		_batches[key] = {"mesh": mesh, "xforms": [], "see": see, "shadow": shadow}
	_batches[key].xforms.append(xform)


func _place_variant(kind: String, xform: Transform3D, shadow := true, see := false) -> void:
	var list: Array = _variants[kind]
	var pick := _rng.randi() % list.size()
	_place("%s%d" % [kind, pick], list[pick][0], xform, see, shadow)


## Turns the batches into one MultiMeshInstance3D each.
func _flush() -> void:
	for key: String in _batches:
		var batch: Dictionary = _batches[key]
		var xforms: Array = batch.xforms
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = batch.mesh
		multimesh.instance_count = xforms.size()
		for i in xforms.size():
			multimesh.set_instance_transform(i, xforms[i])
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multimesh
		if batch.see:
			instance.material_override = see_through
		if not batch.shadow:
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)
	_batches.clear()


func _add_mesh(mesh: Mesh, xform := Transform3D.IDENTITY, see := false) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.transform = xform
	if see:
		instance.material_override = see_through
	add_child(instance)
	return instance


func _collider(shape: Shape3D, xform: Transform3D) -> void:
	var col := CollisionShape3D.new()
	col.shape = shape
	col.transform = xform
	_body.add_child(col)


## Catmull-Rom curve through `points`, sampled about every `step` metres.
func _spline(points: Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in points.size() - 1:
		var p0: Vector2 = points[maxi(i - 1, 0)]
		var p1: Vector2 = points[i]
		var p2: Vector2 = points[i + 1]
		var p3: Vector2 = points[mini(i + 2, points.size() - 1)]
		var n := maxi(1, int(ceil(p1.distance_to(p2) / step)))
		for k in n:
			out.append(p1.cubic_interpolate(p2, p0, p3, float(k) / n))
	out.append(points[points.size() - 1])
	return out


## Records, for every mask cell within `reach` of `line`, how far it is from the line.
func _rasterize(line: PackedVector2Array, into: Dictionary, reach := 3.0) -> void:
	var cells := int(ceil(reach / MASK))
	for p in line:
		var c := _cell(p, MASK)
		for dx in range(-cells, cells + 1):
			for dy in range(-cells, cells + 1):
				var k := c + Vector2i(dx, dy)
				var d := ((Vector2(k) + Vector2(0.5, 0.5)) * MASK).distance_to(p)
				if d < into.get(k, INF):
					into[k] = d


func _path_dist(p: Vector2) -> float:
	return _near_path.get(_cell(p, MASK), INF)


func _stream_dist(p: Vector2) -> float:
	return _near_stream.get(_cell(p, MASK), INF)


func _find_bridge() -> void:
	var best := INF
	var at := 0
	for i in _path.size():
		for q in _stream:
			var d := _path[i].distance_squared_to(q)
			if d < best:
				best = d
				at = i
	_bridge = _path[at]
	_bridge_dir = (_path[mini(at + 3, _path.size() - 1)] - _path[maxi(at - 3, 0)]).normalized()


func _too_close(p: Vector2, spacing: float) -> bool:
	var c := _cell(p, SPACING_CELL)
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			for q: Vector2 in _spacing.get(c + Vector2i(dx, dy), []):
				if p.distance_squared_to(q) < spacing * spacing:
					return true
	return false


func _remember(p: Vector2) -> void:
	var c := _cell(p, SPACING_CELL)
	if not _spacing.has(c):
		_spacing[c] = []
	_spacing[c].append(p)


func _find(parent: Array[int], k: int) -> int:
	while parent[k] != k:
		parent[k] = parent[parent[k]]
		k = parent[k]
	return k


func _union(parent: Array[int], a: int, b: int) -> void:
	parent[_find(parent, a)] = _find(parent, b)


## `color`, randomly lightened or darkened by up to `amount`.
func _vary(color: Color, amount: float, rng: RandomNumberGenerator = null) -> Color:
	var r := (rng if rng else _rng).randf_range(-amount, amount)
	return color.lightened(r) if r > 0.0 else color.darkened(-r)


func _cell(p: Vector2, size: float) -> Vector2i:
	return Vector2i(floori(p.x / size), floori(p.y / size))


func _v3(p: Vector2, y := 0.0) -> Vector3:
	return Vector3(p.x, y, p.y)


func _v2(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z)
