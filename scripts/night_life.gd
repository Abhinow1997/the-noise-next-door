extends Node3D
## Night in the woods round the home pine: fireflies wandering and glowing on and off,
## and a few leaves drifting down, where the author's title picture
## (design/reference/title-screen.webp) has them, seen through its camera
## (title_screen.gd). They're part of the level, so they carry on into play.

const TitleScreen := preload("res://scripts/title_screen.gd")
const Forest := preload("res://scripts/forest.gd")
const LowPoly := preload("res://scripts/lowpoly.gd")

## Fireflies: where each one is in the picture and how far from its camera (metres).
## They wander a little round there and glow on and off.
const FIREFLIES := [[Vector2(152, 312), 16.0], [Vector2(272, 348), 13.0], [Vector2(290, 302), 14.0],
	[Vector2(260, 410), 12.0], [Vector2(488, 275), 19.0], [Vector2(483, 330), 15.0], [Vector2(594, 262), 18.0],
	[Vector2(592, 300), 17.0], [Vector2(632, 348), 16.0], [Vector2(710, 345), 16.0], [Vector2(745, 347), 15.0],
	[Vector2(975, 305), 14.0], [Vector2(215, 330), 13.0], [Vector2(880, 380), 12.0], [Vector2(560, 470), 11.0]]
const FIREFLY := Color("eef59a")
const FIREFLY_GLOW := 3.0
const FIREFLY_SIZE := 0.045
## Leaves falling: where each is in the picture to begin with, how far away, its colour
## (one of forest.gd's LEAVES) and how fast it falls (m/s). They drift down rocking, and
## start again from high up once they reach the ground.
const FALLING := [[Vector2(505, 388), 11.5, 1, 0.32], [Vector2(752, 328), 13.0, 3, 0.27],
	[Vector2(300, 150), 12.0, 0, 0.3]]
const FALL_FROM := 5.5
const LEAF_SIZE := 1.4

var _fireflies: Array[Dictionary] = []
var _leaves: Array[Dictionary] = []
var _t := 0.0


func _ready() -> void:
	var view := TitleScreen.picture_view(Forest.HOME)
	var mesh := SphereMesh.new()
	mesh.radius = FIREFLY_SIZE
	mesh.height = FIREFLY_SIZE * 2.0
	mesh.radial_segments = 6
	mesh.rings = 3
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = FIREFLY
	glow.emission_enabled = true
	glow.emission = FIREFLY
	glow.emission_energy_multiplier = FIREFLY_GLOW
	mesh.material = glow
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	for fly: Array in FIREFLIES:
		var dot := MeshInstance3D.new()
		dot.mesh = mesh
		dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		dot.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		add_child(dot)
		_fireflies.append({"node": dot, "home": TitleScreen.along(view, fly[0], fly[1]),
			"phase": Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU),
			"rate": rng.randf_range(0.25, 0.45), "blink": rng.randf_range(0.6, 1.1)})

	var two_sided := LowPoly.material().duplicate() as StandardMaterial3D
	two_sided.cull_mode = BaseMaterial3D.CULL_DISABLED
	for fall: Array in FALLING:
		var leaf_mesh := Forest._leaf_mesh(Forest.LEAVES[fall[2]])
		leaf_mesh.surface_set_material(0, two_sided)
		var leaf := MeshInstance3D.new()
		leaf.mesh = leaf_mesh
		leaf.scale = Vector3.ONE * LEAF_SIZE
		leaf.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		add_child(leaf)
		var at := TitleScreen.along(view, fall[0], fall[1])
		_leaves.append({"node": leaf, "column": Vector2(at.x, at.z), "y": at.y, "speed": fall[3],
			"phase": at.x * 1.7})
	_process(0.0)


func _process(delta: float) -> void:
	_t += delta
	for fly: Dictionary in _fireflies:
		var ph: Vector3 = fly.phase
		var r: float = fly.rate
		var dot: MeshInstance3D = fly.node
		dot.position = fly.home + Vector3(sin(_t * r + ph.x) * 0.3, sin(_t * r * 1.3 + ph.y) * 0.18,
			sin(_t * r * 0.8 + ph.z) * 0.25)
		dot.scale = Vector3.ONE * (0.45 + 0.55 * pow(maxf(sin(_t * fly.blink + ph.x), 0.0), 0.6))
	for leaf: Dictionary in _leaves:
		leaf.y -= leaf.speed * delta
		if leaf.y < 0.02:
			leaf.y = FALL_FROM
		var sway: float = _t * 1.1 + leaf.phase
		var node: MeshInstance3D = leaf.node
		node.position = Vector3(leaf.column.x + sin(sway) * 0.35, leaf.y, leaf.column.y + cos(sway * 0.7) * 0.12)
		node.rotation = Vector3(sin(sway) * 0.9, sway * 0.6, cos(sway * 1.3) * 0.5)
