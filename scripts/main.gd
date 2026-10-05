extends Node3D
## Builds the garden, the props, the raccoon and the to-do list.
## Debug: `-- --screenshot=out.png [--closeup]` saves a frame and quits.

const LowPoly := preload("res://scripts/lowpoly.gd")
const Player := preload("res://scripts/player.gd")

const GRASS := Color("7e9a80")
const PATH := Color("d5ccb6")
const TRUNK := Color("7a6250")
const LEAF := Color("5f7f63")
const LEAF_LIGHT := Color("6e8f6f")
const LEAF_DARK := Color("51705a")
const FENCE := Color("e9e2cf")
const HOUSE := Color("e4d9c3")
const ROOF := Color("9a6b5a")
const WINDOW := Color("56606a")
const DOOR := Color("8a5f4f")
const DEN := Color("6a5b4b")
const BARK := Color("6f5846")
const WOOD := Color("c8a47a")
const SOIL := Color("7a6554")
const METAL := Color("8f9ba4")
const METAL_DARK := Color("6c7780")
const BIN_INSIDE := Color("454b50")
const CAN := Color("5f7387")
const SILVER := Color("c3c6c8")
const LID := Color("cfc8b8")

const DEN_CENTER := Vector3(-6.2, 0, 6.3)
const DEN_RADIUS := 1.3
const CAMERA_OFFSET := Vector3(0, 5.0, 7.2)

const INPUTS := {
	"move_forward": [KEY_W, KEY_UP],
	"move_back": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"run": [KEY_SHIFT],
	"sneak": [KEY_CTRL, KEY_C],
	"grab": [KEY_E],
	"chitter": [KEY_SPACE],
}

var player: Player
var camera: Camera3D
var bin: RigidBody3D
var lid: RigidBody3D
var gnome: RigidBody3D
var cans: Array[RigidBody3D] = []
var zoom := 1.0

var tasks := [
	{"id": "bin", "text": "Knock over the trash bin", "done": false},
	{"id": "lid", "text": "Steal the bin lid", "done": false},
	{"id": "cans", "text": "Stash 3 cans in your den", "done": false},
	{"id": "gnome", "text": "Kidnap the garden gnome", "done": false},
	{"id": "nap", "text": "Sneak into your den for a nap", "done": false},
]

var _todo: RichTextLabel
var _banner: Label
var _cans_in_den := 0
var _nap_time := 0.0
var _rng := RandomNumberGenerator.new()
var _closeup := false
var _grab_test := false
var _shot_path := ""
var _frames := 0


func _enter_tree() -> void:
	for action: String in INPUTS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: Key in INPUTS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("grab", click)


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			_shot_path = arg.get_slice("=", 1)
		elif arg == "--closeup":
			_closeup = true
		elif arg == "--grab-test":
			_grab_test = true
	_rng.seed = 7

	_build_environment()
	_build_garden()
	_build_props()

	camera = Camera3D.new()
	camera.fov = 40.0
	add_child(camera)
	player = Player.new()
	player.position = Vector3(0, 0.02, 3.0)
	player.camera = camera
	add_child(player)
	camera.global_position = player.global_position + CAMERA_OFFSET
	camera.look_at(player.global_position)

	_build_ui()
	_refresh_todo()


func _process(delta: float) -> void:
	var focus := player.global_position + Vector3(0, 0.35, 0)
	var offset := Vector3(1.5, 0.45, -0.8) if _closeup else CAMERA_OFFSET * zoom
	camera.global_position = camera.global_position.lerp(focus + offset, 1.0 - exp(-6.0 * delta))
	if _closeup:
		camera.global_position = focus + offset
	camera.look_at(focus)
	_check_tasks(delta)

	if _shot_path != "":
		_frames += 1
		if _grab_test and _frames == 1:
			player.global_position = Vector3(4.5, 0.02, -6.85)
		elif _grab_test and _frames == 10:
			player._grab()
		elif _grab_test and _frames == 20:
			player.global_position = Vector3(3.0, 0.02, -5.0)
		if _frames == 45:
			get_viewport().get_texture().get_image().save_png(_shot_path)
			get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom - 0.1, 0.5, 1.8)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom + 0.1, 0.5, 1.8)


# --- Tasks -----------------------------------------------------------------

func _check_tasks(delta: float) -> void:
	var cans_in := 0
	for can in cans:
		if _in_den(can):
			cans_in += 1
	var changed := cans_in != _cans_in_den
	_cans_in_den = cans_in

	var still := Vector2(player.velocity.x, player.velocity.z).length() < 0.1
	_nap_time = _nap_time + delta if player.sneaking and still and _in_den(player) else 0.0

	var state := {
		"bin": bin.global_basis.y.y < 0.5,
		"lid": _in_den(lid),
		"cans": cans_in >= 3,
		"gnome": _in_den(gnome),
		"nap": _nap_time > 3.0,
	}
	for task: Dictionary in tasks:
		if not task.done and state[task.id]:
			task.done = true
			changed = true
	if changed:
		_refresh_todo()
		_banner.visible = tasks.all(func(t: Dictionary) -> bool: return t.done)


func _in_den(node: Node3D) -> bool:
	if node == player.held:
		return false
	var p := node.global_position
	return Vector2(p.x - DEN_CENTER.x, p.z - DEN_CENTER.z).length() < DEN_RADIUS


func _refresh_todo() -> void:
	var text := "[font_size=24][b]To do[/b][/font_size]\n"
	for task: Dictionary in tasks:
		var line: String = task.text
		if task.id == "cans":
			line += "  (%d/3)" % mini(_cans_in_den, 3)
		if task.done:
			text += "\n[color=#a39a88][s]%s[/s][/color]" % line
		else:
			text += "\n•  %s" % line
	_todo.text = text


# --- Level -------------------------------------------------------------------

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("a9c1ab")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d4dccb")
	env.ambient_light_energy = 0.5
	env.ssao_enabled = true
	env.ssao_intensity = 1.2
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_color = Color("fff4e0")
	sun.light_energy = 0.75
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 30.0
	add_child(sun)


func _build_garden() -> void:
	_mesh(LowPoly.box(Vector3(40, 0.2, 40), GRASS), Vector3(0, -0.1, 0))
	var ground := StaticBody3D.new()
	var plane := CollisionShape3D.new()
	plane.shape = WorldBoundaryShape3D.new()
	ground.add_child(plane)
	add_child(ground)

	_build_house()
	_build_fence()

	# Stepping-stone path from the back door to the south fence.
	for i in 22:
		var z := -9.3 + i * 0.85
		var x := sin(z * 0.45) * 1.2 + _rng.randf_range(-0.12, 0.12)
		var stone := LowPoly.loft([Vector3.ZERO, Vector3(0, 0.03, 0)],
			[Vector2(0.3, 0.24), Vector2(0.27, 0.21)], 6, LowPoly.solid(PATH), 0.0, 0.12, i)
		_mesh(stone, Vector3(x, 0.0, z), self, _rng.randf() * TAU)

	_tree(Vector3(-6.5, 0, -6.0), 1.0, 1)
	_tree(Vector3(6.8, 0, -3.5), 1.2, 2)
	_tree(Vector3(-7.4, 0, 0.8), 0.9, 3)
	_tree(Vector3(7.6, 0, 5.8), 1.0, 4)

	for p in [Vector3(-4.8, 0, -9.1), Vector3(-3.4, 0, -9.3), Vector3(2.6, 0, -9.2),
			Vector3(-8.0, 0, 7.9), Vector3(-8.1, 0, 5.3), Vector3(-5.2, 0, 8.3),
			Vector3(8.0, 0, 1.8), Vector3(1.8, 0, 8.3)]:
		_bush(p, _rng.randf_range(0.55, 0.8))

	# Flower bed with the gnome's stump nearby.
	_mesh(LowPoly.box(Vector3(1.4, 0.12, 3.0), SOIL), Vector3(5.6, 0.06, 1.8))
	var petals := [Color("e7b8b4"), Color("f0dc9a"), Color("ece5cf"), Color("c9a0c4")]
	for i in 14:
		var flower := _blob(0.12, 0.2, petals[i % petals.size()], 100 + i)
		_mesh(flower, Vector3(5.6 + _rng.randf_range(-0.55, 0.55), 0.22, 1.8 + _rng.randf_range(-1.3, 1.3)))
	_mesh(LowPoly.loft([Vector3.ZERO, Vector3(0, 0.25, 0)], [Vector2(0.28, 0.28), Vector2(0.25, 0.25)],
		8, _stump_color, 0.0, 0.05, 9), Vector3(4.4, 0, 3.6))
	_static_cylinder(0.28, 0.25, Vector3(4.4, 0.125, 3.6))

	# The den: a patch of dirt tucked behind a hollow log.
	_mesh(LowPoly.loft([Vector3.ZERO, Vector3(0, 0.02, 0)],
		[Vector2(DEN_RADIUS, DEN_RADIUS), Vector2(DEN_RADIUS - 0.05, DEN_RADIUS - 0.05)],
		11, LowPoly.solid(DEN), 0.0, 0.05, 5), DEN_CENTER)
	for i in 6:
		var leaf := LowPoly.box(Vector3(0.14, 0.01, 0.08), [Color("b5924f"), Color("9c6a45")][i % 2])
		var a := i * 1.1
		_mesh(leaf, DEN_CENTER + Vector3(cos(a) * 0.8, 0.03, sin(a) * 0.7), self, a)
	var log_mesh := LowPoly.loft([Vector3(-0.75, 0, 0), Vector3(-0.2, 0, 0), Vector3(0.75, 0, 0)],
		[Vector2(0.28, 0.28), Vector2(0.3, 0.29), Vector2(0.27, 0.28)], 8, _log_color, 0.0, 0.06, 6)
	_mesh(log_mesh, Vector3(-4.6, 0.27, 7.3), self, 0.35)
	var log_body := StaticBody3D.new()
	var log_shape := CollisionShape3D.new()
	var log_box := BoxShape3D.new()
	log_box.size = Vector3(1.5, 0.55, 0.55)
	log_shape.shape = log_box
	log_body.add_child(log_shape)
	log_body.position = Vector3(-4.6, 0.27, 7.3)
	log_body.rotation.y = 0.35
	add_child(log_body)


func _build_house() -> void:
	_mesh(LowPoly.box(Vector3(20, 3.2, 0.6), HOUSE), Vector3(0, 1.6, -10.3))
	_static_box(Vector3(20, 3.2, 0.6), Vector3(0, 1.6, -10.3))
	_mesh(LowPoly.box(Vector3(1.1, 2.0, 0.08), DOOR), Vector3(0, 1.0, -9.99))
	for x in [-6.0, -3.0, 3.0, 6.0]:
		_mesh(LowPoly.box(Vector3(1.3, 1.1, 0.06), FENCE), Vector3(x, 1.8, -9.99))
		_mesh(LowPoly.box(Vector3(1.1, 0.9, 0.08), WINDOW), Vector3(x, 1.8, -9.98))
	var roof_height := 1.5
	var roof_width := 2.4
	var r := Vector2(roof_width / 1.732, roof_height / 1.5)
	var roof := LowPoly.loft([Vector3(-10.4, 0, 0), Vector3(10.4, 0, 0)], [r, r], 3,
		func(_s: int, _i: int, n: Vector3) -> Color: return HOUSE if absf(n.x) > 0.9 else ROOF, PI / 2)
	_mesh(roof, Vector3(0, 3.2 + r.y * 0.5, -10.3))


func _build_fence() -> void:
	var picket := LowPoly.box(Vector3(0.12, 0.8, 0.05), FENCE)
	var transforms: Array[Transform3D] = []
	var x := -9.0
	while x <= 9.0:
		transforms.append(Transform3D(Basis(), Vector3(x, 0.4, 9.0)))
		x += 0.34
	var z := -10.0
	while z <= 9.0:
		transforms.append(Transform3D(Basis(Vector3.UP, PI / 2), Vector3(-9.0, 0.4, z)))
		transforms.append(Transform3D(Basis(Vector3.UP, PI / 2), Vector3(9.0, 0.4, z)))
		z += 0.34
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = picket
	multimesh.instance_count = transforms.size()
	for i in transforms.size():
		multimesh.set_instance_transform(i, transforms[i])
	var fence := MultiMeshInstance3D.new()
	fence.multimesh = multimesh
	add_child(fence)

	for y in [0.25, 0.6]:
		_mesh(LowPoly.box(Vector3(18.1, 0.07, 0.04), FENCE), Vector3(0, y, 8.96))
		_mesh(LowPoly.box(Vector3(0.04, 0.07, 19.1), FENCE), Vector3(-8.96, y, -0.5))
		_mesh(LowPoly.box(Vector3(0.04, 0.07, 19.1), FENCE), Vector3(8.96, y, -0.5))
	_static_box(Vector3(18.4, 1.2, 0.2), Vector3(0, 0.6, 9.0))
	_static_box(Vector3(0.2, 1.2, 19.4), Vector3(-9.0, 0.6, -0.5))
	_static_box(Vector3(0.2, 1.2, 19.4), Vector3(9.0, 0.6, -0.5))


func _tree(pos: Vector3, s: float, seed: int) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	_mesh(LowPoly.loft([Vector3.ZERO, Vector3(0, 1.3 * s, 0), Vector3(0.1 * s, 2.0 * s, 0)],
		[Vector2(0.22, 0.22) * s, Vector2(0.15, 0.15) * s, Vector2(0.1, 0.1) * s],
		6, LowPoly.solid(TRUNK), 0.0, 0.05, seed), Vector3.ZERO, root)
	_mesh(_blob(1.3 * s, 1.6 * s, LEAF, seed), Vector3(0, 2.5 * s, 0), root)
	_mesh(_blob(0.9 * s, 1.2 * s, LEAF_LIGHT, seed + 10), Vector3(0.6 * s, 2.2 * s, 0.4 * s), root)
	_mesh(_blob(0.8 * s, 1.1 * s, LEAF_DARK, seed + 20), Vector3(-0.6 * s, 2.1 * s, -0.3 * s), root)
	_static_cylinder(0.25 * s, 2.0, pos + Vector3(0, 1.0, 0))


func _bush(pos: Vector3, radius: float) -> void:
	var color: Color = [LEAF, LEAF_LIGHT, LEAF_DARK][_rng.randi() % 3]
	_mesh(_blob(radius, radius * 1.3, color, _rng.randi()), pos + Vector3(0, radius * 0.55, 0))
	_static_cylinder(radius * 0.8, 1.0, pos + Vector3(0, 0.5, 0))


func _blob(radius: float, height: float, color: Color, seed: int) -> ArrayMesh:
	var centers: Array = []
	var radii: Array = []
	for p in [[-0.5, 0.35], [-0.3, 0.85], [0.05, 1.0], [0.35, 0.7], [0.5, 0.2]]:
		centers.append(Vector3(0, p[0] * height, 0))
		radii.append(Vector2.ONE * p[1] * radius)
	return LowPoly.loft(centers, radii, 7, LowPoly.solid(color), 0.0, 0.08, seed)


func _log_color(segment: int, _side: int, _n: Vector3) -> Color:
	return WOOD if segment == -1 or segment == 2 else BARK


func _stump_color(segment: int, _side: int, _n: Vector3) -> Color:
	return WOOD if segment == 1 else BARK


# --- Props -------------------------------------------------------------------

func _build_props() -> void:
	bin = _prop(Vector3(4.5, 0, -7.6), 3.0, _cylinder(0.28, 0.76), Vector3(0, 0.38, 0), ["bin"])
	_mesh(LowPoly.loft(
		[Vector3(0, 0, 0), Vector3(0, 0.03, 0), Vector3(0, 0.34, 0), Vector3(0, 0.37, 0),
			Vector3(0, 0.69, 0), Vector3(0, 0.72, 0), Vector3(0, 0.76, 0)],
		[Vector2(0.24, 0.24), Vector2(0.25, 0.25), Vector2(0.265, 0.265), Vector2(0.28, 0.28),
			Vector2(0.285, 0.285), Vector2(0.3, 0.3), Vector2(0.3, 0.3)],
		10, _bin_color), Vector3.ZERO, bin)
	for side: float in [-1.0, 1.0]:
		_mesh(LowPoly.box(Vector3(0.04, 0.05, 0.14), METAL_DARK), Vector3(0.3 * side, 0.6, 0), bin)

	lid = _prop(Vector3(4.5, 0.785, -7.6), 0.5, _cylinder(0.3, 0.045), Vector3.ZERO,
		["grabbable", "lid"], 0.3, Vector3(0, -0.19, -0.2), Vector3(-0.8, 0, 0))
	_mesh(LowPoly.loft([Vector3(0, -0.022, 0), Vector3(0, 0.012, 0), Vector3(0, 0.026, 0)],
		[Vector2(0.3, 0.3), Vector2(0.3, 0.3), Vector2(0.2, 0.2)], 10, LowPoly.solid(LID)),
		Vector3.ZERO, lid)
	_mesh(LowPoly.box(Vector3(0.17, 0.02, 0.035), LID.darkened(0.1)), Vector3(0, 0.07, 0), lid)
	for side: float in [-1.0, 1.0]:
		_mesh(LowPoly.box(Vector3(0.02, 0.05, 0.03), LID.darkened(0.1)), Vector3(0.07 * side, 0.045, 0), lid)

	var can_spots := [Vector3(3.8, 0, -6.9), Vector3(5.3, 0, -6.8), Vector3(5.1, 0, -8.4),
		Vector3(1.6, 0, 1.2), Vector3(-2.4, 0, -3.8)]
	for i in can_spots.size():
		var lying := i % 2 == 0
		var pos: Vector3 = can_spots[i] + Vector3(0, 0.061 if lying else 0.081, 0)
		var can := _prop(pos, 0.2, _cylinder(0.06, 0.16), Vector3.ZERO, ["grabbable", "can"],
			0.06, Vector3(0, -0.02, -0.04), Vector3(0, 0, PI / 2))
		if lying:
			can.rotation = Vector3(PI / 2, _rng.randf() * TAU, 0)
		can.continuous_cd = true
		_mesh(LowPoly.loft([Vector3(0, -0.08, 0), Vector3(0, -0.068, 0), Vector3(0, 0.068, 0), Vector3(0, 0.08, 0)],
			[Vector2(0.055, 0.055), Vector2(0.06, 0.06), Vector2(0.06, 0.06), Vector2(0.055, 0.055)],
			8, _can_color), Vector3.ZERO, can)
		cans.append(can)

	gnome = _prop(Vector3(4.4, 0.26, 3.6), 0.6, _cylinder(0.1, 0.44), Vector3(0, 0.22, 0),
		["grabbable", "gnome"], 0.1, Vector3(0, -0.36, -0.07), Vector3(0.15, 0, 0))
	_build_gnome(gnome)


func _build_gnome(root: Node3D) -> void:
	var skin := Color("e9c6a5")
	_mesh(LowPoly.box(Vector3(0.17, 0.04, 0.11), Color("4a3b33")), Vector3(0, 0.02, -0.01), root)
	_mesh(LowPoly.loft([Vector3(0, 0.04, 0), Vector3(0, 0.22, 0)], [Vector2(0.09, 0.08), Vector2(0.07, 0.065)],
		7, LowPoly.solid(Color("5c7a9c"))), Vector3.ZERO, root)
	_mesh(LowPoly.loft([Vector3(0, 0.21, 0), Vector3(0, 0.31, 0)], [Vector2(0.065, 0.06), Vector2(0.06, 0.055)],
		7, LowPoly.solid(skin)), Vector3.ZERO, root)
	_mesh(LowPoly.loft([Vector3(0, 0.27, -0.035), Vector3(0, 0.12, -0.055)], [Vector2(0.065, 0.04), Vector2(0.01, 0.01)],
		6, LowPoly.solid(Color("f2eee4"))), Vector3.ZERO, root)
	_mesh(LowPoly.loft([Vector3(0, 0.29, 0), Vector3(0, 0.38, 0.01), Vector3(0, 0.46, 0.035)],
		[Vector2(0.078, 0.075), Vector2(0.05, 0.05), Vector2(0.005, 0.005)], 7, LowPoly.solid(Color("b8574a"))),
		Vector3.ZERO, root)
	_mesh(LowPoly.box(Vector3(0.03, 0.03, 0.03), Color("d99a8a")), Vector3(0, 0.275, -0.065), root)


func _bin_color(segment: int, _side: int, _n: Vector3) -> Color:
	match segment:
		-1, 1, 3, 5:
			return METAL_DARK
		6:
			return BIN_INSIDE
	return METAL


func _can_color(segment: int, _side: int, _n: Vector3) -> Color:
	return CAN if segment == 1 else SILVER


func _prop(pos: Vector3, mass: float, shape: Shape3D, shape_offset: Vector3, groups: Array,
		grab_radius := 0.0, hold_offset := Vector3.ZERO, hold_rotation := Vector3.ZERO) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.position = pos
	body.mass = mass
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = shape_offset
	body.add_child(col)
	for g: String in groups:
		body.add_to_group(g)
	body.set_meta("grab_radius", grab_radius)
	body.set_meta("hold_offset", hold_offset)
	body.set_meta("hold_rotation", hold_rotation)
	add_child(body)
	return body


# --- Helpers -----------------------------------------------------------------

func _mesh(mesh: Mesh, pos: Vector3, parent: Node = self, rot_y := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation.y = rot_y
	parent.add_child(mi)
	return mi


func _cylinder(radius: float, height: float) -> CylinderShape3D:
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	return shape


func _static_box(size: Vector3, pos: Vector3) -> void:
	var box := BoxShape3D.new()
	box.size = size
	_static(box, pos)


func _static_cylinder(radius: float, height: float, pos: Vector3) -> void:
	_static(_cylinder(radius, height), pos)


func _static(shape: Shape3D, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	body.position = pos
	add_child(body)


# --- UI ----------------------------------------------------------------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	if _closeup:
		layer.visible = false

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f4eedc")
	style.set_corner_radius_all(6)
	style.set_content_margin_all(18)
	style.shadow_color = Color(0, 0, 0, 0.18)
	style.shadow_size = 6
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(24, 24)
	layer.add_child(panel)

	_todo = RichTextLabel.new()
	_todo.bbcode_enabled = true
	_todo.fit_content = true
	_todo.custom_minimum_size = Vector2(320, 0)
	_todo.add_theme_color_override("default_color", Color("3b3630"))
	_todo.add_theme_font_size_override("normal_font_size", 18)
	_todo.add_theme_font_size_override("bold_font_size", 18)
	panel.add_child(_todo)

	var hint := Label.new()
	hint.text = "WASD move   Shift run   Ctrl sneak   E / click grab   Space chitter   Wheel zoom"
	hint.add_theme_color_override("font_color", Color("f4eedc"))
	hint.add_theme_color_override("font_outline_color", Color("3b3630"))
	hint.add_theme_constant_override("outline_size", 6)
	layer.add_child(hint)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 20)

	_banner = Label.new()
	_banner.text = "Mischief managed!"
	_banner.visible = false
	_banner.add_theme_font_size_override("font_size", 48)
	_banner.add_theme_color_override("font_color", Color("f4eedc"))
	_banner.add_theme_color_override("font_outline_color", Color("3b3630"))
	_banner.add_theme_constant_override("outline_size", 12)
	layer.add_child(_banner)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 40)
