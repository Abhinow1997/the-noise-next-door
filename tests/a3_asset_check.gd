extends SceneTree
## Assignment 3's headless asset check. It loads each prop's imported .glb, places it at
## the origin and compares what it measures with CHANGE-BRIEF.md:
##   - size: the bounding box along X, Y, Z must match the brief's W, H, D within 5%,
##     so the height has to lie along Y (it doesn't just test "the longest side is up":
##     the pizza slice is flat, so its height is its smallest size);
##   - floor: the bottom of the box must be at Y = 0 within 1 mm;
##   - scale: every node's scale must be 1, 1, 1;
##   - triangles: at or under the brief's budget;
##   - parts: every part must rest on the floor or on another part, with no gap over
##     1 mm (box-to-box, so it catches a floating part but not one sunk into another;
##     the mutation proof prints that limit too);
##   - facing: where the brief says which way the asset faces, that it arrived that way.
## Run:            godot --headless --path . --script res://tests/a3_asset_check.gd
## Prove it fails: add `-- --mutate`. Each asset is broken in memory in known ways,
##                 and every break must make the check it targets fail.
## It can't tell whether an asset looks right, reads as what it is, or suits the game.

const SIZE_TOLERANCE := 0.05
const FLOOR_TOLERANCE := 0.001
const GAP_TOLERANCE := 0.001

## W x D x H in metres, as in the brief (Godot: X = W, Y = H, Z = D).
const ASSETS := [
	{"name": "S'more", "path": "res://assets/props/smore.glb", "wdh": Vector3(0.13, 0.085, 0.035), "budget": 420,
		"brief": "v2 size, v3 budget"},
	{"name": "Pizza slice", "path": "res://assets/props/pizza_slice.glb", "wdh": Vector3(0.15, 0.20, 0.02), "budget": 200,
		"brief": "v1"},
	{"name": "Cooler", "path": "res://assets/props/cooler.glb", "wdh": Vector3(0.58, 0.36, 0.36), "budget": 150,
		"brief": "v1"},
]

var _failures := 0


func _initialize() -> void:
	var mutate := "--mutate" in OS.get_cmdline_user_args()
	print("Assignment 3 asset check (%s)" % ("mutation proof" if mutate else "normal run"))
	if mutate:
		_mutation_proof()
	else:
		for asset: Dictionary in ASSETS:
			var inst := _place(asset)
			_report(asset, _check(asset, inst))
			inst.free()
		print("\n%s: %d check(s) failed" % ["FAIL" if _failures else "PASS", _failures])
	quit(1 if _failures else 0)


func _place(asset: Dictionary) -> Node3D:
	var scene: PackedScene = load(asset.path)
	return scene.instantiate()


## A part's transform relative to the scene the asset sits in, worked out from its parents.
## (global_transform isn't usable here: in _initialize the nodes aren't inside the tree
## yet, so it comes back as the identity and every part measures at the origin.)
func _world(node: Node, top: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n := node
	while n != null:
		if n is Node3D:
			t = (n as Node3D).transform * t
		if n == top:
			break
		n = n.get_parent()
	return t


func _parts(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		found.append(node)
	for child in node.get_children():
		found.append_array(_parts(child))
	return found


func _nodes(node: Node) -> Array[Node3D]:
	var found: Array[Node3D] = []
	if node is Node3D:
		found.append(node)
	for child in node.get_children():
		found.append_array(_nodes(child))
	return found


func _triangles(mesh: Mesh) -> int:
	var total := 0
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var indices = arrays[Mesh.ARRAY_INDEX]
		var count: int = indices.size() if indices != null and indices.size() > 0 else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		total += count / 3
	return total


## Returns [check name, passed, what was measured] rows.
func _check(asset: Dictionary, inst: Node3D) -> Array:
	var rows := []
	var parts := _parts(inst)
	var boxes := {}
	var box := AABB()
	var first := true
	var tris := 0
	for p in parts:
		var b: AABB = _world(p, inst) * p.mesh.get_aabb()
		boxes[p] = b
		box = b if first else box.merge(b)
		first = false
		tris += _triangles(p.mesh)

	var want := Vector3(asset.wdh.x, asset.wdh.z, asset.wdh.y)
	var size_ok := true
	for i in 3:
		if absf(box.size[i] - want[i]) > want[i] * SIZE_TOLERANCE:
			size_ok = false
	rows.append(["size X,Y,Z = W,H,D", size_ok, "%.4f x %.4f x %.4f m (brief %.3f x %.3f x %.3f)" %
			[box.size.x, box.size.y, box.size.z, want.x, want.y, want.z]])

	var tallest := "Y"
	if box.size.x > box.size.y and box.size.x >= box.size.z: tallest = "X"
	elif box.size.z > box.size.y: tallest = "Z"
	rows.append(["height along Y", absf(box.size.y - want.y) <= want.y * SIZE_TOLERANCE,
			"Y size %.4f m against the brief's H %.3f (longest side: %s)" % [box.size.y, want.y, tallest]])

	rows.append(["bottom on the floor", absf(box.position.y) <= FLOOR_TOLERANCE,
			"bottom at Y = %+.4f m" % box.position.y])

	var bad_scale := []
	for n in _nodes(inst):
		if not n.scale.is_equal_approx(Vector3.ONE):
			bad_scale.append("%s %s" % [n.name, n.scale])
	rows.append(["scale 1,1,1", bad_scale.is_empty(),
			"%d nodes, all 1,1,1" % _nodes(inst).size() if bad_scale.is_empty() else ", ".join(PackedStringArray(bad_scale))])

	rows.append(["triangles", tris <= asset.budget, "%d (budget %d)" % [tris, asset.budget]])

	var floating := []
	for p in parts:
		var b: AABB = boxes[p]
		var supported := absf(b.position.y - box.position.y) <= GAP_TOLERANCE
		for q in parts:
			if supported or q == p:
				continue
			var c: AABB = boxes[q]
			var overlaps_xz := b.position.x < c.end.x and c.position.x < b.end.x and b.position.z < c.end.z and c.position.z < b.end.z
			if overlaps_xz and b.position.y >= c.position.y - GAP_TOLERANCE and b.position.y <= c.end.y + GAP_TOLERANCE:
				supported = true
		if not supported:
			floating.append(String(p.name))
	rows.append(["every part resting", floating.is_empty(),
			"%d parts" % parts.size() if floating.is_empty() else "floating: " + ", ".join(PackedStringArray(floating))])

	match asset.name:
		"Pizza slice":
			var crust := _named(parts, "Crust")
			var base := _named(parts, "Base")
			var ok: bool = crust != null and base != null and boxes[crust].get_center().z < boxes[base].get_center().z
			rows.append(["facing", ok, "crust at the back (-Z), tip to the front (+Z)" if ok else "crust isn't behind the tip"])
		"S'more":
			var plain := _named(parts, "Marshmallow_Standing")
			var cracker := _named(parts, "CrackerBottom")
			var ok: bool = plain != null and cracker != null and boxes[plain].get_center().x > boxes[cracker].get_center().x
			rows.append(["facing", ok, "plain marshmallows on its +X side" if ok else "plain marshmallows aren't on +X"])
	return rows


func _named(parts: Array[MeshInstance3D], fragment: String) -> MeshInstance3D:
	for p in parts:
		if fragment in String(p.name):
			return p
	return null


func _report(asset: Dictionary, rows: Array) -> void:
	print("\n%s  (%s, brief %s)" % [asset.name, asset.path, asset.brief])
	for r in rows:
		print("  %-4s %-20s %s" % ["ok" if r[1] else "FAIL", r[0], r[2]])
		if not r[1]:
			_failures += 1


## Breaks each asset in memory in a known way and checks that the right check fails.
func _mutation_proof() -> void:
	var breaks := [
		["Cooler", "10 times too big", "size X,Y,Z = W,H,D", func(i: Node3D): i.scale = Vector3.ONE * 10.0],
		["Cooler", "scale not applied", "scale 1,1,1", func(i: Node3D): i.scale = Vector3(1.0, 1.0, 1.02)],
		["Pizza slice", "lying on its side", "height along Y", func(i: Node3D): i.rotation.x = PI / 2.0],
		["Pizza slice", "a pepperoni floating 3 mm", "every part resting",
				func(i: Node3D): _named(_parts(i), "Pepperoni3").position.y += 0.003],
		["Pizza slice", "turned round", "facing", func(i: Node3D): i.rotation.y = PI],
		["S'more", "floating 5 cm", "bottom on the floor", func(i: Node3D): i.position.y = 0.05],
		["S'more", "sunk 5 mm", "bottom on the floor", func(i: Node3D): i.position.y = -0.005],
	]
	var caught := 0
	for b in breaks:
		var asset: Dictionary = ASSETS.filter(func(a): return a.name == b[0])[0]
		var inst := _place(asset)
		(b[3] as Callable).call(inst)
		var rows := _check(asset, inst)
		var target_failed := false
		for r in rows:
			if r[0] == b[2] and not r[1]:
				target_failed = true
		print("  %-6s %-12s %-26s -> '%s' %s" % ["caught" if target_failed else "MISSED", b[0], b[1], b[2],
				"failed, as it should" if target_failed else "still passed"])
		if target_failed:
			caught += 1
		else:
			_failures += 1
		inst.free()
	print("\n%s: %d of %d breaks caught" % ["PASS" if caught == breaks.size() else "FAIL", caught, breaks.size()])

	# A known limit, shown rather than hidden: a part sunk INTO another part still counts as
	# resting on it, so every check passes. This happened to my pizza on 14 Oct (Pepperoni1
	# was 1.7 mm into the cheese); only measuring each part, or a look from the side, found it.
	var asset: Dictionary = ASSETS.filter(func(a): return a.name == "Pizza slice")[0]
	var inst := _place(asset)
	_named(_parts(inst), "Pepperoni1").position.y -= 0.0017
	var all_pass := true
	for r in _check(asset, inst):
		all_pass = all_pass and r[1]
	inst.free()
	print("  known limit: a pepperoni sunk 1.7 mm into the cheese -> %s" %
			("every check still passes (not caught)" if all_pass else "a check failed (now caught)"))
