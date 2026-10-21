extends Node3D
## The forest from design/reference/the-forest.jpg and the-rest.jpg, built in code:
## faceted ground plates, pines, broadleaf trees and birches, the raccoon's home pine
## with its hollow (now the title picture's, see HOME_TRUNK_HEIGHTS), a bench, a dirt
## path, a stream with a footbridge, and the log cabin across it. Trees, bushes and the
## cabin use `see_through`, which main.gd drives so the raccoon can still be seen when
## he walks behind them. With `night` on it's all drawn in its night colours (NIGHT),
## for the moonlit game.

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

## The night colours (with `night` on), measured against the author's title picture,
## design/reference/title-screen.webp. Under the moon alone (night.gd) the day colours
## above come out too grey: the picture keeps its yellow trees warm, turns the
## pines blue-green and the grass dark. So at night each day colour is
## multiplied by its gain here, in linear light, as measured against the picture region
## by region. A vertex colour takes the gain of the day colour it's nearest to (or of
## that colour's darkened underside), if it's within NIGHT_MATCH; others stay as they are.
const NIGHT := [
	[GRASS, Color(0.48, 0.48, 0.48)], [TUFT, Color(0.62, 0.58, 0.44)],
	[PINE, Color(1.15, 1.0, 1.35)], [PINE_TRUNK, Color(0.77, 0.68, 0.67)], [BARK, Color(0.77, 0.68, 0.67)],
	[Color("6f8c4b"), Color(0.61, 0.56, 0.37)], [Color("6c773f"), Color(3.0, 2.0, 0.68)],
	[Color("9c9a46"), Color(2.5, 1.6, 0.52)], [Color("ab9f45"), Color(2.5, 1.55, 0.5)],
	[BIRCH_BARK, Color(1.38, 1.25, 1.22)], [BIRCH_MARK, Color(1, 1, 1)], [BIRCH_LEAF, Color(1.2, 1.15, 1.15)],
	[ROCK, Color(1.03, 1.03, 1.27)], [PATH, Color(1.4, 1.45, 1.45)], [PATH_EDGE, Color(1.4, 1.45, 1.45)],
	[WATER, Color(0.97, 0.79, 0.71)], [WATER_DEEP, Color(0.97, 0.79, 0.71)],
	[HOLLOW_WALL, Color(1.3, 0.9, 0.8)], [HOLLOW_FLOOR, Color(1.3, 0.9, 0.8)], [HOLLOW_DARK, Color(1.3, 0.9, 0.8)],
	[NEST[0], Color(1.2, 1.15, 1.5)], [NEST[1], Color(1.2, 1.15, 1.5)], [NEST[2], Color(1.2, 1.15, 1.5)],
	[NEST[3], Color(1.2, 1.15, 1.5)], [NEST[4], Color(1.0, 1.0, 1.3)],
]
const NIGHT_MATCH := 0.1

## The raccoon's home pine. The ground round its roots is his den.
const HOME := Vector3(0, 0, -0.5)
const DEN_RADIUS := 2.0
const START := Vector3(0, 0.02, 3.4)
const CABIN := Vector3(-5.5, 0, -20.0)
const BENCH := Vector3(6.0, 0, -1.6)
## Where the raccoon can walk. Trees beyond it are only scenery.
const BOUNDS := Rect2(-15, -23, 30, 33)
## Where scenery is generated.
const WORLD := Rect2(-44, -50, 88, 74)

## The home pine, from the author's title picture (design/reference/title-screen.webp):
## since 21 Oct 2026 the level has the title's pine too, so the title hands over to the
## level's nap close-up without the tree changing. (The level's first home pine, from
## the-rest.jpg, was 9 m tall and wider, with a smaller hollow.) The trunk (heights and
## radii), then the skirt the hollow is cut into: its hem, its shoulder (where the tier
## above covers it), apex and radius, and how much narrower it is at the shoulder. Then
## the two tiers above it: hem, apex, radius.
const HOME_TRUNK_HEIGHTS := [0.0, 0.45, 2.4, 4.6]
const HOME_TRUNK_RADII := [0.62, 0.44, 0.36, 0.2]
const SKIRT_HEM := 2.1
const SKIRT_SHOULDER := 4.0
const SKIRT_APEX := 4.9
const SKIRT_RADIUS := 1.16
const SKIRT_TAPER := 0.82
const HOME_TIERS := [[4.12, 6.3, 1.0], [5.07, 7.3, 0.8]]
## Round the skirt (degrees from the front), its points and the notches between them in
## turn. The point at the front is a fold, and the two faces either side of it, out to
## the notches at SKIRT_FRONT degrees, hold the hollow, which straddles the fold as in
## the picture.
const SKIRT_ANGLES := [0.0, 54.0, 108.0, 144.0, 180.0, 216.0, 252.0, 306.0]
const SKIRT_FRONT := 54.0
## The hollow's opening, as measured in the picture (x across, height up): a pointed top
## on the fold, upper and lower corners, and the bottom on the fold. Then how deep it goes.
const OPENING := [Vector2(0, 3.95), Vector2(0.58, 3.69), Vector2(0.64, 2.77), Vector2(0, 2.53),
	Vector2(-0.64, 2.77), Vector2(-0.58, 3.69)]
const OPENING_DEPTH := 0.95
## The nest: leafy lumps (centre across and up from the middle of the hollow's floor,
## radius) that spill out over the lip.
const NEST_LUMPS := [[Vector2(0.0, 0.0), 0.26], [Vector2(-0.3, -0.02), 0.22], [Vector2(0.3, -0.02), 0.22],
	[Vector2(-0.12, 0.05), 0.2], [Vector2(0.16, 0.04), 0.2], [Vector2(-0.45, -0.06), 0.15], [Vector2(0.46, -0.06), 0.15]]

# Control points (x, z) for the path, its fork to the east, and the stream.
const PATH_POINTS := [Vector2(-50, -2.6), Vector2(-30, -3.4), Vector2(-17, -3.0), Vector2(-10, -4.2),
	Vector2(-5.5, -6.4), Vector2(-1.5, -8.8), Vector2(2.6, -10.8), Vector2(4.6, -12.7), Vector2(4.4, -15.0),
	Vector2(1.8, -16.6), Vector2(-2.6, -17.4), Vector2(-5.5, -17.2)]
const FORK_POINTS := [Vector2(0.6, -9.9), Vector2(6.0, -9.6), Vector2(12.0, -8.4), Vector2(20.0, -8.8),
	Vector2(50.0, -7.6)]
const STREAM_POINTS := [Vector2(-50, -11.4), Vector2(-34, -12.8), Vector2(-20, -12.0), Vector2(-10, -13.4),
	Vector2(-2, -12.6), Vector2(4.5, -13.6), Vector2(12, -14.6), Vector2(22, -13.4), Vector2(34, -14.4),
	Vector2(50, -13.6)]

## Trees placed by hand round the home pine, so that from the title screen's camera
## (title_screen.gd) they stand as the trees do in the author's title picture
## (design/reference/title-screen.webp): kind, position (x, z), and height in metres,
## worked out from where each stands and how tall it is in the picture. Those that would
## have stood on the path, in the stream or by the bin were moved along the camera's
## line of sight to the nearest free spot and resized to cover the same part of the
## picture; the two in the clearing in front of the pine, where he plays, were left out.
const HERO_TREES := [
	["olive", Vector2(-9.06, -8.29), 5.44], ["pine", Vector2(-6.52, -7.70), 7.13],
	["pine", Vector2(-18.28, -22.33), 8.45], ["pine", Vector2(-20.46, -31.00), 10.29],
	["green", Vector2(-3.07, -4.97), 5.46], ["green", Vector2(-5.73, -10.19), 3.97],
	["pine", Vector2(-0.06, -25.69), 9.58], ["pine", Vector2(2.44, -26.64), 8.47],
	["green", Vector2(4.61, -8.11), 6.85], ["gold", Vector2(5.44, -5.62), 5.77],
	["yellow", Vector2(9.66, -10.41), 6.98], ["birch", Vector2(8.35, -7.25), 4.46],
	["birch", Vector2(7.74, -3.55), 4.80], ["olive", Vector2(11.01, -6.88), 5.75],
	["pine", Vector2(15.95, -11.88), 7.66],
]

## Resolution of the masks that say how far a spot is from the path and the stream.
const MASK := 0.5
## Where the random sequence stood after the old plated ground, which the rest of
## the forest was laid out from (see _build_ground).
const RNG_AFTER_GROUND := 6889569028940052091
## Cell size of the grid used to keep trees apart.
const SPACING_CELL := 3.3

## Where the raccoon curls up in the hollow, in world space.
var rest_spot: Transform3D
## Where he lands when he leaps out of the hollow: on the ground clear of the skirt,
## facing away from the tree.
var rest_exit: Transform3D
## The trunks the raccoon can climb, one per tree he can reach: `base` and `top`
## (where the branches start) in world space, the trunk's radius at each (`r0`, `r1`),
## and `clear`, its collider's radius. The home pine's also has `rest_spot` and `rest_exit`.
var climbable: Array[Dictionary] = []
var bin_spot := Vector3(7.6, 0, -1.1)
var can_spots: Array[Vector3] = [Vector3(6.9, 0, -0.3), Vector3(8.4, 0, -0.5), Vector3(7.8, 0, 0.3),
	Vector3(2.8, 0, 2.4), Vector3(-4.2, 0, 6.0)]
## Top of the stump the gnome stands on.
var gnome_spot: Vector3
var see_through: ShaderMaterial
## Set before it's added: draws everything in its night colours (NIGHT), for the
## moonlit game (night.gd).
var night := false
## The grass sheet under everything, so the level can give it a texture.
var ground: MeshInstance3D

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
## Each mesh's night version, by its batch name, and each colour's.
var _night_meshes := {}
var _night_colors := {}


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

## The ground: one smooth sheet of grass, lit evenly, with only a soft colour drift
## over tens of metres so it doesn't look painted on.
func _build_ground() -> void:
	var cell := 2.0
	var origin := WORLD.position - Vector2(6, 4)
	var nx := int(ceil((WORLD.size.x + 12) / cell))
	var nz := int(ceil((WORLD.size.y + 8) / cell))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var up := [Vector3.UP, Vector3.UP, Vector3.UP]
	for i in nx:
		for j in nz:
			var corners: Array[Vector3] = []
			var colors: Array[Color] = []
			for c: Vector2i in [Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i + 1, j + 1), Vector2i(i, j + 1)]:
				var p := origin + Vector2(c) * cell
				corners.append(_v3(p))
				colors.append(_grass_at(p))
			LowPoly.add_tri_attrs(st, [corners[0], corners[1], corners[2]], up, [colors[0], colors[1], colors[2]], Vector3.UP)
			LowPoly.add_tri_attrs(st, [corners[0], corners[2], corners[3]], up, [colors[0], colors[2], colors[3]], Vector3.UP)
	ground = _add_mesh(LowPoly.commit(st))
	# The old plated ground drew from _rng. Carry on from where it left off, so every
	# tree, rock and leaf placed after this stays where it was.
	_rng.state = RNG_AFTER_GROUND


## GRASS at `p`, at most 2% lighter or darker in broad, soft patches.
func _grass_at(p: Vector2) -> Color:
	var drift := (sin(p.x * 0.11 + 1.3) * sin(p.y * 0.09 + 0.4) + sin((p.x + p.y) * 0.05)) * 0.5
	return GRASS.lightened(drift * 0.02) if drift > 0.0 else GRASS.darkened(-drift * 0.02)


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

## The home pine at `at` (HOME in the level), with its collider, the trunk he climbs,
## and where he curls up in the hollow and lands when he leaps out.
func _build_home(at := HOME) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	LowPoly.add_tube(st, HOME_TRUNK_HEIGHTS.map(func(y: float) -> Vector3: return Vector3(0, y, 0)), HOME_TRUNK_RADII, 7,
		LowPoly.solid(PINE_TRUNK), 0.2, [1.7, 1.15, 1.6, 1.1, 1.65, 1.2, 1.5])
	var rest := _add_skirt(st)
	for i in HOME_TIERS.size():
		_add_pine_tier(st, HOME_TIERS[i][0], HOME_TIERS[i][1], HOME_TIERS[i][2], 0.4 + i * 1.3, PINE)
	_add_mesh(LowPoly.commit(st), Transform3D(Basis(), at), true)
	var trunk := CylinderShape3D.new()
	trunk.radius = 0.85
	trunk.height = 3.0
	_collider(trunk, Transform3D(Basis(), at + Vector3(0, 1.5, 0)))
	_remember(_v2(at))
	# He lies across the hollow facing -X, so his side and curled tail face the camera.
	rest_spot = Transform3D(Basis(Vector3.UP, PI / 2), at + rest)
	# Far enough out that his leap clears the lip of the hollow and the skirt below it.
	rest_exit = Transform3D(Basis(Vector3.UP, PI), at + Vector3(0, 0, 2.8))
	# He can climb the trunk up to the skirt's lowest points; from there he goes in.
	climbable.append({"base": at, "top": at + Vector3(0, SKIRT_HEM - SKIRT_RADIUS * 0.06, 0), "r0": 0.5,
		"r1": 0.4, "clear": trunk.radius, "rest_spot": rest_spot, "rest_exit": rest_exit})


## A point of the skirt's hem (`shoulder` false) or of its shoulder, `angle` degrees
## round from the front. Points hang a little lower and stand further out than notches,
## except that the notches either side of the front sit level with the front point, so
## the two faces that hold the hollow are flat.
func _skirt_point(angle: float, shoulder: bool) -> Vector3:
	var r := SKIRT_RADIUS * (SKIRT_TAPER if shoulder else 1.0)
	var y := SKIRT_SHOULDER if shoulder else SKIRT_HEM - SKIRT_RADIUS * 0.06
	if SKIRT_ANGLES.find(angle) % 2 == 1:
		r *= 0.84
		if not is_equal_approx(absf(angle_difference(deg_to_rad(angle), 0.0)), deg_to_rad(SKIRT_FRONT)):
			y += 0.05 if shoulder else SKIRT_RADIUS * 0.16
	var a := deg_to_rad(angle)
	return Vector3(sin(a) * r, y, cos(a) * r)


## The skirt: a pleated band from the hem up to the shoulder and a cone above it. The
## hollow straddles the fold at the front, as in the picture, cut through the two flat
## faces either side of it; inside are its walls, a back wall and a nest of leaves.
## Returns where the middle of the curled-up raccoon lies.
func _add_skirt(st: SurfaceTool) -> Vector3:
	var apex := Vector3(0, SKIRT_APEX, 0)
	var below := Vector3(0, SKIRT_HEM + SKIRT_RADIUS * 0.3, 0)
	var n := SKIRT_ANGLES.size()
	for k in n:
		var a: float = SKIRT_ANGLES[k]
		var b: float = SKIRT_ANGLES[(k + 1) % n]
		var h0 := _skirt_point(a, false)
		var h1 := _skirt_point(b, false)
		var s0 := _skirt_point(a, true)
		var s1 := _skirt_point(b, true)
		var axis := Vector3(0, (h0.y + s1.y) * 0.5, 0)
		# The two faces at the front are cut round the opening below.
		if k != 0 and k != n - 1:
			LowPoly.add_tri(st, h0, h1, s1, axis, PINE)
			LowPoly.add_tri(st, h0, s1, s0, axis, PINE)
		LowPoly.add_tri(st, s0, s1, apex, Vector3(0, s0.y, 0), PINE)
		LowPoly.add_tri(st, h0, h1, below, apex, PINE.darkened(0.4))

	# Each front face, from the fold out to its notch, with half the opening cut out of
	# it: laid out flat (across, up), split into triangles, and lifted back onto the face.
	var fold_low := _skirt_point(0.0, false)
	var fold_high := _skirt_point(0.0, true)
	var rim: Array[Vector3] = []
	rim.resize(OPENING.size())
	var out := Vector3.ZERO
	for side: float in [1.0, -1.0]:
		var notch_low := _skirt_point(SKIRT_FRONT if side > 0.0 else 360.0 - SKIRT_FRONT, false)
		var notch_high := _skirt_point(SKIRT_FRONT if side > 0.0 else 360.0 - SKIRT_FRONT, true)
		var normal := (notch_low - fold_low).cross(fold_high - fold_low).normalized()
		if normal.z < 0.0:
			normal = -normal
		out += normal
		var lift := func(p: Vector2) -> Vector3:
			return Vector3(p.x, p.y, fold_low.z - (normal.x * p.x + normal.y * (p.y - fold_low.y)) / normal.z)
		# The face's outline, then round the half of the opening on this side of the fold.
		var flat := PackedVector2Array([Vector2(0, fold_low.y), Vector2(notch_low.x, notch_low.y),
			Vector2(notch_high.x, notch_high.y), Vector2(0, fold_high.y)])
		for i: int in ([0, 1, 2, 3] if side > 0.0 else [0, 5, 4, 3]):
			flat.append(OPENING[i])
		var tris := Geometry2D.triangulate_polygon(flat)
		for t in range(0, tris.size(), 3):
			var a: Vector3 = lift.call(flat[tris[t]])
			var b: Vector3 = lift.call(flat[tris[t + 1]])
			var c: Vector3 = lift.call(flat[tris[t + 2]])
			LowPoly.add_tri(st, a, b, c, Vector3(0, (a.y + b.y + c.y) / 3.0, 0), PINE)
		for i in OPENING.size():
			if signf(OPENING[i].x) == side or (OPENING[i].x == 0.0 and side > 0.0):
				rim[i] = lift.call(OPENING[i])
	out = out.normalized()

	# The hollow: walls from the rim back into the tree, then a back wall.
	var top := rim[0]
	var bottom := rim[3]
	var center := (top + bottom) * 0.5
	var inner: Array[Vector3] = []
	for v in rim:
		inner.append(center + (v - center) * 0.72 - out * OPENING_DEPTH)
	var axis := center - out * OPENING_DEPTH * 0.5
	for k in 6:
		var a := rim[k]
		var b := rim[(k + 1) % 6]
		var c := inner[(k + 1) % 6]
		var d := inner[k]
		var mid := (a + b + c + d) * 0.25
		var normal := (b - a).cross(d - a).normalized()
		if normal.dot(axis - mid) < 0.0:
			normal = -normal
		var color := HOLLOW_WALL
		if normal.y > 0.35:
			color = HOLLOW_FLOOR
		elif normal.y < -0.35:
			color = HOLLOW_DARK
		LowPoly.add_tri(st, a, b, c, mid - normal, color)
		LowPoly.add_tri(st, a, c, d, mid - normal, color)
	var back := center - out * OPENING_DEPTH
	for k in 6:
		LowPoly.add_tri(st, inner[k], inner[(k + 1) % 6], back, back - out, HOLLOW_DARK)

	# The nest: leafy lumps across the floor, spilling out over the lip.
	var nest_rng := RandomNumberGenerator.new()
	nest_rng.seed = 5
	var nest := center - out * OPENING_DEPTH * 0.42 + Vector3(0, -(top.y - bottom.y) * 0.3, 0)
	for lump: Array in NEST_LUMPS:
		var at: Vector2 = lump[0]
		var r: float = lump[1]
		LowPoly.add_icosphere(st, nest + Vector3(at.x, at.y, 0), Vector3(r, r * 0.5, r * 0.85), 1, 0.3,
			nest_rng.randi(), func(_n: Vector3) -> Color: return NEST[nest_rng.randi() % 4])
	return nest + Vector3(0, 0.1, 0)


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


## `trunk` gets the climbable part of the trunk, as described for `climbable`.
func _pine_mesh(h: float, tiers: int, seed: int, trunk := {}) -> ArrayMesh:
	# Up to the points of the lowest skirt.
	trunk.merge({"top": Vector3(0, h * 0.3 - h * 0.155 * 0.06, 0), "r0": h * 0.038, "r1": h * 0.031})
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
## `trunk` gets the climbable part of the trunk, up to the fork.
func _broadleaf_mesh(h: float, color: Color, seed: int, trunk := {}) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lean := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)) * h * 0.02
	var fork := Vector3(0, h * rng.randf_range(0.36, 0.44), 0) + lean
	var r := h * 0.03
	trunk.merge({"top": fork, "r0": r * 1.15, "r1": r * 0.85})
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
## `trunk` gets the climbable part of the trunk, up to the lowest limb.
func _birch_mesh(h: float, seed: int, trunk := {}) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lean := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized() * h * 0.03
	var top := Vector3(0, h * 0.9, 0) + lean
	var r0 := h * 0.019
	var limb := h * 0.45 / top.y
	trunk.merge({"top": Vector3(0, h * 0.45, 0) + lean * limb * limb, "r0": r0, "r1": lerpf(r0, r0 * 0.45, limb)})
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


## Trees are [mesh, trunk radius, climbable trunk]; everything else is [mesh, 0.0].
func _make_variants() -> void:
	var pines: Array = []
	for i in 5:
		var h: float = [5.0, 5.6, 6.2, 6.8, 4.6][i]
		var trunk := {}
		pines.append([_pine_mesh(h, [5, 5, 6, 6, 4][i], 100 + i, trunk), h * 0.046, trunk])
	_variants["pine"] = pines
	for kind: String in CANOPIES:
		var list: Array = []
		for i in 2:
			var h := 4.4 + i * 0.7
			var trunk := {}
			list.append([_broadleaf_mesh(h, CANOPIES[kind], kind.hash() + i, trunk), h * 0.034, trunk])
		_variants[kind] = list
	var birches: Array = []
	for i in 3:
		var h := 5.0 + i * 0.6
		var trunk := {}
		birches.append([_birch_mesh(h, 300 + i, trunk), h * 0.022, trunk])
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
		_add_tree(tree[0], tree[1], 1.0, tree[2])
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


## A tree of `kind` at `p`, `scale` times its size give or take a little, or exactly
## `height` metres tall if that's given.
func _add_tree(kind: String, p: Vector2, scale := 1.0, height := 0.0) -> void:
	var list: Array = _variants[kind]
	var pick := _rng.randi() % list.size()
	var s := scale * _rng.randf_range(0.88, 1.12)
	if height > 0.0:
		s = height / (list[pick][0] as Mesh).get_aabb().end.y
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
		var climb: Dictionary = list[pick][2]
		climbable.append({"base": xform.origin, "top": xform * climb.top, "r0": climb.r0 * s,
			"r1": climb.r1 * s, "clear": shape.radius})


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


static func _leaf_mesh(color: Color) -> ArrayMesh:
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
	if night:
		if not _night_meshes.has(key):
			_night_meshes[key] = _at_night(mesh)
		mesh = _night_meshes[key]
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
	instance.mesh = _at_night(mesh) if night else mesh
	instance.transform = xform
	if see:
		instance.material_override = see_through
	add_child(instance)
	return instance


## `mesh` with every vertex colour in its night colour.
func _at_night(mesh: Mesh) -> ArrayMesh:
	var out := ArrayMesh.new()
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		for i in colors.size():
			colors[i] = _night_color(colors[i])
		arrays[Mesh.ARRAY_COLOR] = colors
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		out.surface_set_material(s, mesh.surface_get_material(s))
	return out


func _night_color(c: Color) -> Color:
	if _night_colors.has(c):
		return _night_colors[c]
	var best := NIGHT_MATCH
	var gain := Color(1, 1, 1)
	for pair: Array in NIGHT:
		var day: Color = pair[0]
		for base: Color in [day, day.darkened(0.4)]:
			var d := Vector3(c.r - base.r, c.g - base.g, c.b - base.b).length()
			if d < best:
				best = d
				gain = pair[1]
	var l := c.srgb_to_linear()
	var out := Color(minf(l.r * gain.r, 1.0), minf(l.g * gain.g, 1.0), minf(l.b * gain.b, 1.0), c.a).linear_to_srgb()
	_night_colors[c] = out
	return out


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
