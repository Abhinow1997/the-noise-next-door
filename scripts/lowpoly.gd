@tool
extends RefCounted
## Helpers for building vertex-coloured low-poly meshes from code, flat-shaded with
## loft() or smooth with smooth_loft(). Everything shares one material, so colour
## lives in the vertices.

static var _material: StandardMaterial3D


static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.vertex_color_is_srgb = true
		_material.roughness = 1.0
		_material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return _material


## Colour callback that paints every face the same colour.
static func solid(color: Color) -> Callable:
	return func(_segment: int, _side: int, _normal: Vector3) -> Color: return color


## Adds one flat-shaded triangle whose normal points away from `inside`.
static func add_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, inside: Vector3, color: Color) -> void:
	var n := (b - a).cross(c - a)
	if n.length_squared() < 1e-12:
		return
	n = n.normalized()
	if n.dot((a + b + c) / 3.0 - inside) < 0.0:
		n = -n
	# Godot treats clockwise triangles as front-facing.
	if (b - a).cross(c - a).dot(n) > 0.0:
		var swap := b
		b = c
		c = swap
	for v in [a, b, c]:
		st.set_color(color)
		st.set_normal(n)
		st.add_vertex(v)


## Sweeps a `sides`-gon through `centers`, sized by `radii` (x = width, y = height).
## `color_fn(segment, side, normal) -> Color` paints each face; the start cap is
## segment -1 and the end cap is segment centers.size() - 1.
static func loft(centers: Array, radii: Array, sides: int, color_fn: Callable,
		twist := 0.0, jitter := 0.0, seed := 0) -> ArrayMesh:
	var count := centers.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var rings: Array = []
	for i in count:
		var c: Vector3 = centers[i]
		var r: Vector2 = radii[i]
		var prev: Vector3 = centers[maxi(i - 1, 0)]
		var next: Vector3 = centers[mini(i + 1, count - 1)]
		var t := (next - prev).normalized()
		var ref := Vector3.UP if absf(t.dot(Vector3.UP)) < 0.9 else Vector3.FORWARD
		var bx := ref.cross(t).normalized()
		var by := t.cross(bx).normalized()
		var ring: Array[Vector3] = []
		for s in sides:
			var angle := TAU * s / sides + twist
			var p := c + bx * cos(angle) * r.x + by * sin(angle) * r.y
			if jitter > 0.0:
				var wobble := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
				p += wobble * jitter * maxf(r.x, r.y)
			ring.append(p)
		rings.append(ring)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in count - 1:
		var c0: Vector3 = centers[i]
		var c1: Vector3 = centers[i + 1]
		var axis_mid := (c0 + c1) * 0.5
		for s in sides:
			var a: Vector3 = rings[i][s]
			var b: Vector3 = rings[i][(s + 1) % sides]
			var c: Vector3 = rings[i + 1][(s + 1) % sides]
			var d: Vector3 = rings[i + 1][s]
			var n := (b - a).cross(d - a)
			if n.length_squared() < 1e-12:
				n = (c - d).cross(a - d)
			n = n.normalized()
			if n.dot((a + b + c + d) * 0.25 - axis_mid) < 0.0:
				n = -n
			var color: Color = color_fn.call(i, s, n)
			add_tri(st, a, b, c, axis_mid, color)
			add_tri(st, a, c, d, axis_mid, color)
	_cap(st, rings[0], centers[0], centers[1], -1, color_fn)
	_cap(st, rings[count - 1], centers[count - 1], centers[count - 2], count - 1, color_fn)

	var mesh := st.commit()
	mesh.surface_set_material(0, material())
	return mesh


## Smooth-shaded loft() for organic shapes, taking the same arguments. The path is
## resampled along a curve through the centres (`steps` rings per segment),
## neighbouring faces share normals, colours are worked out per corner so markings
## have soft edges, and both ends are rounded off instead of capped.
## `color_fn` still gets loft()'s segment numbers (-1 and centers.size() - 1 for the
## ends), so one colour function serves both looks. `blend` softens colour changes
## between segments; turn it off when segment boundaries are deliberate markings.
static func smooth_loft(centers: Array, radii: Array, sides: int, color_fn: Callable,
		twist := 0.0, steps := 4, blend := true) -> ArrayMesh:
	var last := centers.size() - 1
	var path: Array[Vector3] = []
	var sizes: Array[Vector2] = []
	var path_segments: Array[int] = []
	for i in last:
		var p0: Vector3 = centers[maxi(i - 1, 0)]
		var p1: Vector3 = centers[i]
		var p2: Vector3 = centers[i + 1]
		var p3: Vector3 = centers[mini(i + 2, last)]
		var r0: Vector2 = radii[maxi(i - 1, 0)]
		var r1: Vector2 = radii[i]
		var r2: Vector2 = radii[i + 1]
		var r3: Vector2 = radii[mini(i + 2, last)]
		# The curve can dip between points; don't let a ring shrink below a quarter size.
		var smallest := Vector2(minf(r1.x, r2.x), minf(r1.y, r2.y)) * 0.25
		for k in steps:
			var weight := float(k) / steps
			path.append(p1.cubic_interpolate(p2, p0, p3, weight))
			var r := r1.cubic_interpolate(r2, r0, r3, weight)
			sizes.append(Vector2(maxf(r.x, smallest.x), maxf(r.y, smallest.y)))
			path_segments.append(i)
	path.append(centers[last])
	sizes.append(radii[last])

	# Rings are oriented exactly as in loft().
	var count := path.size()
	var tube: Array = []
	var frames: Array = []
	for i in count:
		var t := (path[mini(i + 1, count - 1)] - path[maxi(i - 1, 0)]).normalized()
		var ref := Vector3.UP if absf(t.dot(Vector3.UP)) < 0.9 else Vector3.FORWARD
		var bx := ref.cross(t).normalized()
		var by := t.cross(bx).normalized()
		tube.append(_ring(path[i], bx, by, sizes[i], sides, twist))
		frames.append([bx, by])

	# Start dome (tip first), then the tube, then the end dome.
	var start := _dome(path[0], frames[0], sizes[0], (path[0] - path[1]).normalized(), sides, twist)
	var finish := _dome(path[count - 1], frames[count - 1], sizes[count - 1],
		(path[count - 1] - path[count - 2]).normalized(), sides, twist)
	var rings: Array = []
	var ring_centers: Array = []
	var segments: Array = []
	for k in range(start[0].size() - 1, -1, -1):
		rings.append(start[0][k])
		ring_centers.append(start[1][k])
		segments.append(-1)
	rings.append_array(tube)
	ring_centers.append_array(path)
	segments.append_array(path_segments)
	for k in finish[0].size():
		segments.append(last)
		rings.append(finish[0][k])
		ring_centers.append(finish[1][k])

	# One normal per face, pointing away from the path.
	var ring_count := rings.size()
	var face_normals: Array = []
	for j in ring_count - 1:
		var axis_mid: Vector3 = (ring_centers[j] + ring_centers[j + 1]) * 0.5
		var row: Array[Vector3] = []
		for s in sides:
			var a: Vector3 = rings[j][s]
			var b: Vector3 = rings[j][(s + 1) % sides]
			var c: Vector3 = rings[j + 1][(s + 1) % sides]
			var d: Vector3 = rings[j + 1][s]
			var normal := (b - a).cross(d - a)
			if normal.length_squared() < 1e-12:
				normal = (c - d).cross(a - d)
			normal = normal.normalized()
			if normal.dot((a + b + c + d) * 0.25 - axis_mid) < 0.0:
				normal = -normal
			row.append(normal)
		face_normals.append(row)

	# Each corner's normal averages the faces around it (the two tips average a whole
	# ring), so shading is smooth.
	var corner_normals: Array = []
	for j in ring_count:
		var row: Array[Vector3] = []
		for s in sides:
			var sum := Vector3.ZERO
			for span: int in [j - 1, j]:
				if span < 0 or span >= ring_count - 1:
					continue
				var around: Array = range(sides) if j == 0 or j == ring_count - 1 else [s, (s + sides - 1) % sides]
				for side: int in around:
					sum += face_normals[span][side]
			row.append(sum.normalized())
		corner_normals.append(row)

	# Colour comes from color_fn at each corner rather than each face, so markings get
	# a soft edge one face wide instead of a staircase. With `blend`, a ring where the
	# segment changes takes the average of both segments' colours, so those changes are
	# soft too; without it, each span keeps its own segment and the change is a clean line.
	var blended: Array = []
	if blend:
		for j in ring_count:
			blended.append(_corner_colors(color_fn, segments[maxi(j - 1, 0)],
				segments[mini(j, ring_count - 2)], corner_normals[j]))

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in ring_count - 1:
		var near: Array = blended[j] if blend else _corner_colors(color_fn, segments[j], segments[j], corner_normals[j])
		var far: Array = blended[j + 1] if blend else _corner_colors(color_fn, segments[j], segments[j], corner_normals[j + 1])
		for s in sides:
			var s1 := (s + 1) % sides
			var normal: Vector3 = face_normals[j][s]
			_add_smooth_tri(st, [rings[j][s], rings[j][s1], rings[j + 1][s1]],
				[corner_normals[j][s], corner_normals[j][s1], corner_normals[j + 1][s1]],
				[near[s], near[s1], far[s1]], normal)
			_add_smooth_tri(st, [rings[j][s], rings[j + 1][s1], rings[j + 1][s]],
				[corner_normals[j][s], corner_normals[j + 1][s1], corner_normals[j + 1][s]],
				[near[s], far[s1], far[s]], normal)
	var mesh := st.commit()
	mesh.surface_set_material(0, material())
	return mesh


## Axis-aligned box centred on the origin.
static func box(size: Vector3, color: Color) -> ArrayMesh:
	var r := Vector2(size.x, size.z) * 0.70710678
	return loft([Vector3(0, -size.y * 0.5, 0), Vector3(0, size.y * 0.5, 0)], [r, r], 4, solid(color), PI / 4)


## Commits `st` into a mesh that uses the shared vertex-colour material.
static func commit(st: SurfaceTool) -> ArrayMesh:
	var mesh := st.commit()
	mesh.surface_set_material(0, material())
	return mesh


## Adds a box of `size`, placed by `xform`, to `st`.
static func add_box(st: SurfaceTool, xform: Transform3D, size: Vector3, color: Color) -> void:
	var h := size * 0.5
	var corners: Array[Vector3] = []
	for i in 8:
		corners.append(xform * Vector3(h.x if i & 1 != 0 else -h.x, h.y if i & 2 != 0 else -h.y,
			h.z if i & 4 != 0 else -h.z))
	for f: Array in [[0, 1, 3, 2], [4, 6, 7, 5], [0, 4, 5, 1], [2, 3, 7, 6], [0, 2, 6, 4], [1, 5, 7, 3]]:
		add_tri(st, corners[f[0]], corners[f[1]], corners[f[2]], xform.origin, color)
		add_tri(st, corners[f[0]], corners[f[2]], corners[f[3]], xform.origin, color)


## Adds one triangle with its own normal and colour at each corner, wound to face `facing`.
static func add_tri_attrs(st: SurfaceTool, points: Array, normals: Array, colors: Array, facing: Vector3) -> void:
	_add_smooth_tri(st, points, normals, colors, facing)


## Flat-shaded tube through `centers`, one radius per ring, added to `st` and capped at
## the far end (the near end usually sits in the ground). `flare` scales the first
## ring side by side, for root flares. `color_fn(segment, side, normal)` as in loft().
static func add_tube(st: SurfaceTool, centers: Array, radii: Array, sides: int, color_fn: Callable,
		twist := 0.0, flare: Array = []) -> void:
	var count := centers.size()
	var rings: Array = []
	for i in count:
		var c: Vector3 = centers[i]
		var t: Vector3 = (centers[mini(i + 1, count - 1)] - centers[maxi(i - 1, 0)]).normalized()
		var ref := Vector3.UP if absf(t.dot(Vector3.UP)) < 0.9 else Vector3.FORWARD
		var bx := ref.cross(t).normalized()
		var by := t.cross(bx).normalized()
		var ring: Array[Vector3] = []
		for s in sides:
			var angle := TAU * s / sides + twist
			var r: float = radii[i]
			if i == 0 and not flare.is_empty():
				r *= flare[s % flare.size()]
			ring.append(c + (bx * cos(angle) + by * sin(angle)) * r)
		rings.append(ring)
	for i in count - 1:
		var axis_mid: Vector3 = (centers[i] + centers[i + 1]) * 0.5
		for s in sides:
			var a: Vector3 = rings[i][s]
			var b: Vector3 = rings[i][(s + 1) % sides]
			var c: Vector3 = rings[i + 1][(s + 1) % sides]
			var d: Vector3 = rings[i + 1][s]
			var n := (b - a).cross(d - a)
			if n.length_squared() < 1e-12:
				n = (c - d).cross(a - d)
			n = n.normalized()
			if n.dot((a + b + c + d) * 0.25 - axis_mid) < 0.0:
				n = -n
			var color: Color = color_fn.call(i, s, n)
			add_tri(st, a, b, c, axis_mid, color)
			add_tri(st, a, c, d, axis_mid, color)
	_cap(st, rings[count - 1], centers[count - 1], centers[count - 2], count - 1, color_fn)


## Faceted, slightly lumpy ball, added to `st`: an icosahedron split `subdiv` times,
## each corner pushed in or out by up to `jitter` of the radius. Corners below
## `flat_bottom` (a fraction of radius.y, e.g. -0.3) are pressed flat, for rocks.
## `color_fn(normal) -> Color` paints each face.
static func add_icosphere(st: SurfaceTool, center: Vector3, radius: Vector3, subdiv: int, jitter: float,
		seed: int, color_fn: Callable, flat_bottom := -2.0) -> void:
	var g := (1.0 + sqrt(5.0)) / 2.0
	var verts: Array[Vector3] = []
	for v: Vector3 in [Vector3(-1, g, 0), Vector3(1, g, 0), Vector3(-1, -g, 0), Vector3(1, -g, 0),
			Vector3(0, -1, g), Vector3(0, 1, g), Vector3(0, -1, -g), Vector3(0, 1, -g),
			Vector3(g, 0, -1), Vector3(g, 0, 1), Vector3(-g, 0, -1), Vector3(-g, 0, 1)]:
		verts.append(v.normalized())
	var faces: Array = [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
		[1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
		[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]]
	for _level in subdiv:
		var midpoints := {}
		var split: Array = []
		for f: Array in faces:
			var m: Array[int] = []
			for k in 3:
				var a: int = f[k]
				var b: int = f[(k + 1) % 3]
				var key := Vector2i(mini(a, b), maxi(a, b))
				if not midpoints.has(key):
					verts.append(((verts[a] + verts[b]) * 0.5).normalized())
					midpoints[key] = verts.size() - 1
				m.append(midpoints[key])
			split.append([f[0], m[0], m[2]])
			split.append([f[1], m[1], m[0]])
			split.append([f[2], m[2], m[1]])
			split.append([m[0], m[1], m[2]])
		faces = split
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var points: Array[Vector3] = []
	for v in verts:
		var p := v * (1.0 + rng.randf_range(-jitter, jitter))
		p.y = maxf(p.y, flat_bottom)
		points.append(center + p * radius)
	for f: Array in faces:
		var a := points[f[0]]
		var b := points[f[1]]
		var c := points[f[2]]
		var n := (b - a).cross(c - a)
		if n.length_squared() < 1e-12:
			continue
		n = n.normalized()
		if n.dot((a + b + c) / 3.0 - center) < 0.0:
			n = -n
		add_tri(st, a, b, c, (a + b + c) / 3.0 - n, color_fn.call(n))


static func _cap(st: SurfaceTool, ring: Array, center: Vector3, neighbour: Vector3,
		segment: int, color_fn: Callable) -> void:
	var n := (center - neighbour).normalized()
	var inside := center - n * 0.1
	for s in ring.size():
		var a: Vector3 = ring[s]
		var b: Vector3 = ring[(s + 1) % ring.size()]
		add_tri(st, center, a, b, inside, color_fn.call(segment, s, n))


## `sides` points around `center` in the plane of `bx` and `by`, sized by `size`.
static func _ring(center: Vector3, bx: Vector3, by: Vector3, size: Vector2, sides: int,
		twist: float) -> Array[Vector3]:
	var ring: Array[Vector3] = []
	for s in sides:
		var angle := TAU * s / sides + twist
		ring.append(center + bx * cos(angle) * size.x + by * sin(angle) * size.y)
	return ring


## color_fn at each corner of a ring; a ring joining two segments averages both.
static func _corner_colors(color_fn: Callable, before: int, after: int, normals: Array) -> Array[Color]:
	var colors: Array[Color] = []
	for s in normals.size():
		var color: Color = color_fn.call(after, s, normals[s])
		if before != after:
			color = color.lerp(color_fn.call(before, s, normals[s]), 0.5)
		colors.append(color)
	return colors


## Shrinking rings that round off a tube end like half an egg, finishing at a point.
## Returns [rings, ring centres], from the end of the tube outwards.
static func _dome(center: Vector3, frame: Array, size: Vector2, out: Vector3, sides: int,
		twist: float) -> Array:
	var depth := 0.6 * minf(size.x, size.y)
	var rings: Array = []
	var centers: Array = []
	for angle: float in [PI / 6.0, PI / 3.0, PI / 2.0]:
		var c := center + out * depth * sin(angle)
		rings.append(_ring(c, frame[0], frame[1], size * cos(angle), sides, twist))
		centers.append(c)
	return [rings, centers]


## Adds one triangle with its own normal and colour at each corner, wound to face along `facing`.
static func _add_smooth_tri(st: SurfaceTool, points: Array, normals: Array, colors: Array,
		facing: Vector3) -> void:
	var a: Vector3 = points[0]
	var b: Vector3 = points[1]
	var c: Vector3 = points[2]
	var winding := (b - a).cross(c - a)
	if winding.length_squared() < 1e-12:
		return
	# Godot treats clockwise triangles as front-facing.
	var order := [0, 2, 1] if winding.dot(facing) > 0.0 else [0, 1, 2]
	for i: int in order:
		st.set_color(colors[i])
		st.set_normal(normals[i])
		st.add_vertex(points[i])
