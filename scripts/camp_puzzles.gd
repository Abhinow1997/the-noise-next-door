extends Node3D
## Level 1's first puzzles at the campsite (campsite.gd), the GDD's tasks, built on
## 23 Oct 2026 when the author chose the first three: Steal the marshmallows, Music off
## and Raid the cooler. Each is worked with E (interactable.gd, camp_input.gd) and the
## campers' routines (camp_person.gd) decide when it's safe.
##   - Steal the marshmallows: the camper's backpack leans on the log behind where he
##     roasts. Hold E to unzip it tooth by tooth (ZIP_TIME; a little noise); the bag of
##     marshmallows tumbles out. Get it home to his tree, his stash: that's the task.
##     Running with the bag, it crinkles (CRINKLE).
##   - Music off: the speaker's cord runs to a plug in a socket under the table. Hold E
##     to tug the plug out with his teeth (PULL_TIME): the music stops, which is the
##     task. He can drag the plug away on its cord (CORD_LEN). The dancers stop dead
##     mid-move (FREEZE), which is his moment to get away; then everyone wonders where
##     the music went, and the low-poly man goes to find the plug and puts it back
##     (camp_person.gd FIX), and the music comes back on. While it's off, every noise
##     carries further (campsite.gd `noise`).
##   - Raid the cooler: hold E to nose its lid open (LID_TIME; it clunks), or wait for
##     the low-poly man, who opens it for a drink in his routine and sometimes leaves it
##     open (FORGET). Inside is a pack of sausages: get it home to his stash.
##   - Caught with the bag or the sausages, the men snatch it back (camp_person.gd TAKE)
##     and the puzzle resets: the bag zipped back in, the pack back in the shut cooler.
## Built in code with LowPoly, like the fire pit: placeholders for Blender props later.

const LowPoly := preload("res://scripts/lowpoly.gd")
const Forest := preload("res://scripts/forest.gd")
const Interactable := preload("res://scripts/interactable.gd")
const Player := preload("res://scripts/player.gd")
const ThoughtBubbles := preload("res://scripts/thought_bubbles.gd")

## Where things are, from the fire (x, z), and which way their fronts face (degrees).
const BACKPACK := Vector2(-2.05, 0.5)
const BACKPACK_FACING := -90.0
const SOCKET := Vector2(-0.75, -2.78)
## The backpack: how long the zip takes, and how far the zipping is heard (m).
const ZIP_TIME := 3.0
const ZIP_NOISE := 1.5
## The bag crinkles this far (m) every CRINKLE_EVERY seconds while he runs with it.
const CRINKLE := 4.0
const CRINKLE_EVERY := 0.5
## The plug: how long the tug takes and how far it's heard, how far it can go from the
## speaker on its cord, and how far from the socket counts as out.
const PULL_TIME := 0.8
const PULL_NOISE := 1.0
const CORD_LEN := 4.0
const PLUG_OUT := 0.25
## How long after the music stops the low-poly man goes to put it back, how far the
## music stopping is noticed, and how long the dancers stand frozen mid-move first.
const FIX_AFTER := 2.5
const SILENCE_HEARD := 12.0
const FREEZE := 2.0
## The cooler: how far its lid opens (degrees), how long nosing it open takes and how
## far its clunk carries, and the chance the low-poly man leaves it open after a drink.
const LID_OPEN := -100.0
const LID_TIME := 2.0
const LID_NOISE := 3.5
const FORGET := 0.3

const PACK := Color("3f7f86")
const PACK_DARK := Color("2f5f66")
const ZIP := Color("d8c27a")
const BAG := Color("f4f1e6")
const BAG_BAND := Color("4f7fc4")
const PLUG := Color("1e1f22")
const PRONG := Color("c9c9c4")
const STRIP := Color("e8e4da")
const STRIP_LED := Color("ff8a3a")
const WIRE := Color("2a2a2c")
const SAUSAGE := Color("c46a5a")
const TRAY := Color("eeeeea")

## Set before it's added (campsite.gd): the camp, the to-do list, where the fire is
## (x, z), and the props the puzzles use.
var camp
var tasks
var fire := Vector2.ZERO
var cooler: Node3D
var speaker: Node3D
var table: Node3D

## True while the plug's in and the music can play.
var music_on := true
var bag: RigidBody3D
var plug: RigidBody3D
var sausages: RigidBody3D

var _player: Player
var _backpack: StaticBody3D
var _zipper: Interactable
var _pull: Node3D
var _flap: Node3D
var _unzipped := false
var _socket: Vector3
var _socket_pull: Interactable
var _plugged := true
var _cut_at := -INF
var _cord: MeshInstance3D
var _cord_from := Vector3.ZERO
var _cord_to := Vector3.INF
var _lid: Node3D
var _lid_spot: Interactable
var _lid_open := false
var _lid_t := 0.0
var _lid_by_man := false
var _forgot := false
var _was_drinking := false
var _crinkle_t := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 5
	_build_backpack()
	_build_plug()
	_build_cooler()


func _physics_process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player
		if _player == null:
			return
	_stash_check()
	# The bag crinkles while he runs with it.
	_crinkle_t -= delta
	if _player.held == bag and _player.running and _crinkle_t <= 0.0:
		_crinkle_t = CRINKLE_EVERY
		camp.noise(_player.global_position, CRINKLE)
	_music(delta)
	_cooler_routine(delta)


# --- Loot ------------------------------------------------------------------------

## A thing of the campers' that he can carry off: in `groups`, worth task `task` once
## it's in his stash, and put back by `reset` if he's caught with it.
func _loot(mesh: Mesh, size: Vector3, task: String, reset: Callable, hold_offset: Vector3) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.mass = 0.2
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	body.add_child(mi)
	body.set_meta("grab_radius", maxf(size.x, size.z) * 0.5)
	body.set_meta("hold_offset", hold_offset)
	body.set_meta("hold_rotation", Vector3.ZERO)
	if task != "":
		body.set_meta("camp_loot", task)
	body.set_meta("reset", reset)
	body.continuous_cd = true
	camp.add_child(body)
	return body


## Out of play, kept where it is: frozen, solid to nothing, not to be grabbed.
func lift(item: RigidBody3D) -> void:
	if not item.has_meta("camp_layers"):
		item.set_meta("camp_layers", Vector2i(item.collision_layer, item.collision_mask))
	item.freeze = true
	item.collision_layer = 0
	item.collision_mask = 0
	item.remove_from_group("grabbable")


## Back in play at `at`: solid, falling, his to grab.
func put_down(item: RigidBody3D, at: Vector3) -> void:
	if item.get_parent() != camp:
		item.reparent(camp, true)
	item.global_transform = Transform3D(Basis(), at + Vector3.UP * 0.05)
	var layers: Vector2i = item.get_meta("camp_layers", Vector2i(1, 1))
	item.collision_layer = layers.x
	item.collision_mask = layers.y
	item.freeze = false
	item.add_to_group("grabbable")
	item.reset_physics_interpolation()


## Snatched back from him (camp_person.gd TAKE): it goes home and its puzzle resets.
func take_back(item: RigidBody3D) -> void:
	if item.get_parent() != camp:
		item.reparent(camp, true)
	var reset: Callable = item.get_meta("reset", Callable())
	if reset.is_valid():
		reset.call()


## Loot lying in his stash at his tree ticks its task off.
func _stash_check() -> void:
	for item: RigidBody3D in [bag, sausages]:
		if item == null or not item.has_meta("camp_loot") or item == _player.held or item.get_parent() != camp:
			continue
		var p := item.global_position - Forest.HOME
		if Vector2(p.x, p.z).length() < Forest.DEN_RADIUS:
			tasks.done(item.get_meta("camp_loot"))
			item.remove_meta("camp_loot")


# --- Steal the marshmallows ------------------------------------------------------

func _build_backpack() -> void:
	_backpack = StaticBody3D.new()
	_backpack.position = _at(BACKPACK)
	_backpack.rotation.y = deg_to_rad(BACKPACK_FACING)
	camp.add_child(_backpack)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(LowPoly.loft(
		[Vector3(0, 0, 0), Vector3(0, 0.05, 0), Vector3(0, 0.3, 0), Vector3(0, 0.38, -0.01), Vector3(0, 0.4, -0.02)],
		[Vector2(0.14, 0.08), Vector2(0.16, 0.1), Vector2(0.16, 0.1), Vector2(0.14, 0.085), Vector2(0.1, 0.05)],
		8, LowPoly.solid(PACK)), 0, Transform3D.IDENTITY)
	LowPoly.add_box(st, Transform3D(Basis(), Vector3(0, 0.15, 0.1)), Vector3(0.22, 0.15, 0.05), PACK_DARK)
	LowPoly.add_box(st, Transform3D(Basis(), Vector3(0, 0.31, 0.095)), Vector3(0.24, 0.012, 0.012), ZIP)
	for x: float in [-0.08, 0.08]:
		LowPoly.add_box(st, Transform3D(Basis(), Vector3(x, 0.22, -0.11)), Vector3(0.04, 0.32, 0.02), PACK_DARK)
	_mesh(LowPoly.commit(st), _backpack)
	# The flap over the top, which lifts when it's unzipped, and the zip's pull.
	_flap = Node3D.new()
	_flap.position = Vector3(0, 0.4, -0.04)
	_backpack.add_child(_flap)
	_mesh(LowPoly.box(Vector3(0.24, 0.025, 0.16), PACK_DARK), _flap).position = Vector3(0, 0.0, 0.07)
	_pull = _mesh(LowPoly.box(Vector3(0.03, 0.045, 0.012), ZIP), _backpack)
	_pull.position = Vector3(-0.12, 0.29, 0.105)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.34, 0.42, 0.22)
	col.shape = shape
	col.position = Vector3(0, 0.21, 0)
	_backpack.add_child(col)
	_zipper = Interactable.new()
	_zipper.hold_time = ZIP_TIME
	_zipper.noise = ZIP_NOISE
	_zipper.camp = camp
	_zipper.prompt_height = 0.25
	_zipper.position = Vector3(0, 0.3, 0.2)
	_zipper.enabled = func() -> bool: return not _unzipped
	_zipper.progressed.connect(func(f: float) -> void: _pull.position.x = lerpf(-0.12, 0.12, f))
	_zipper.finished.connect(_unzip)
	_backpack.add_child(_zipper)

	var st2 := SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	LowPoly.add_box(st2, Transform3D.IDENTITY, Vector3(0.16, 0.07, 0.11), BAG)
	LowPoly.add_box(st2, Transform3D.IDENTITY, Vector3(0.165, 0.074, 0.04), BAG_BAND)
	bag = _loot(LowPoly.commit(st2), Vector3(0.16, 0.07, 0.11), "marshmallows", _reset_backpack,
		Vector3(0, -0.04, -0.06))
	bag.add_to_group("food")
	_reset_backpack()


## Unzipped: the flap lifts and the bag tumbles out at his feet.
func _unzip() -> void:
	_unzipped = true
	_flap.rotation.x = deg_to_rad(-110.0)
	bag.visible = true
	put_down(bag, _backpack.global_transform * Vector3(0, 0.2, 0.3))
	bag.apply_central_impulse(_backpack.global_basis.z * 0.08 + Vector3.UP * 0.1)


## Zipped back up with the bag inside.
func _reset_backpack() -> void:
	_unzipped = false
	_flap.rotation.x = 0.0
	_pull.position.x = -0.12
	_zipper.reset()
	lift(bag)
	bag.global_transform = _backpack.global_transform * Transform3D(Basis(), Vector3(0, 0.22, 0))
	bag.visible = false
	bag.reset_physics_interpolation()
	if not bag.has_meta("camp_loot") and not tasks.is_done("marshmallows"):
		bag.set_meta("camp_loot", "marshmallows")


# --- Music off -------------------------------------------------------------------

func _build_plug() -> void:
	_socket = _at(SOCKET, 0.03)
	var strip := Node3D.new()
	strip.position = _at(SOCKET)
	camp.add_child(strip)
	_mesh(LowPoly.box(Vector3(0.26, 0.05, 0.08), STRIP), strip).position = Vector3(0.05, 0.025, 0)
	var led := MeshInstance3D.new()
	var dot := SphereMesh.new()
	dot.radius = 0.008
	dot.height = 0.016
	dot.radial_segments = 6
	dot.rings = 3
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = STRIP_LED
	glow.emission_enabled = true
	glow.emission = STRIP_LED
	glow.emission_energy_multiplier = 2.0
	dot.material = glow
	led.mesh = dot
	led.position = Vector3(0.15, 0.052, 0)
	strip.add_child(led)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	LowPoly.add_box(st, Transform3D.IDENTITY, Vector3(0.05, 0.03, 0.035), PLUG)
	for x: float in [-0.008, 0.008]:
		LowPoly.add_box(st, Transform3D(Basis(), Vector3(x, 0, -0.025)), Vector3(0.004, 0.012, 0.02), PRONG)
	plug = _loot(LowPoly.commit(st), Vector3(0.05, 0.03, 0.05), "", Callable(), Vector3(0, -0.02, -0.03))
	plug.set_meta("reset", plug_in.bind(plug))
	plug.mass = 0.1
	_cord_from = speaker.global_transform * Vector3(-0.1, 0.02, -0.15)
	_cord = MeshInstance3D.new()
	_cord.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camp.add_child(_cord)
	_socket_pull = Interactable.new()
	_socket_pull.hold_time = PULL_TIME
	_socket_pull.noise = PULL_NOISE
	_socket_pull.camp = camp
	_socket_pull.reach = 0.6
	_socket_pull.prompt_height = 0.25
	_socket_pull.position = _socket
	_socket_pull.enabled = func() -> bool: return _plugged
	_socket_pull.finished.connect(_unplug)
	camp.add_child(_socket_pull)
	plug_in(plug)


## Pushed into the socket (by the low-poly man, or at the start): the music comes on.
func plug_in(item: RigidBody3D) -> void:
	if item.get_parent() != camp:
		item.reparent(camp, true)
	lift(item)
	item.global_transform = Transform3D(Basis(Vector3.UP, PI * 0.5), _socket)
	item.reset_physics_interpolation()
	_plugged = true
	_socket_pull.reset()
	if not music_on:
		music_on = true
		if camp.party:
			camp.party.play()


## Tugged out with his teeth: it comes away in his mouth, and the music stops.
func _unplug() -> void:
	_plugged = false
	put_down(plug, _socket)
	plug.freeze = true
	plug.global_position = _player.model.mouth.global_position
	_player._grab()
	_music_off()


func _music_off() -> void:
	if not music_on:
		return
	music_on = false
	_cut_at = camp.clock
	if camp.party:
		camp.party.stop()
	tasks.done("music")
	# Everyone notices the quiet and wonders what happened to the music; the dancers
	# stop dead first, which gives him a moment to get away.
	camp.noise(speaker.global_position, SILENCE_HEARD, FREEZE)


## Where the low-poly man stands to plug it back in, and the socket itself.
func socket_spot() -> Vector3:
	return _socket + Vector3(0.35, 0, 0.55)


func socket_at() -> Vector3:
	return _socket


func _music(_delta: float) -> void:
	# Out of the socket some other way (dropped, carried off): the music's off.
	if _plugged and plug.global_position.distance_to(_socket) > PLUG_OUT:
		_plugged = false
		_music_off()
	# The cord only reaches so far: pulled taut, it's out of his mouth.
	var reach := plug.global_position - _cord_from
	reach.y = 0.0
	if reach.length() > CORD_LEN:
		if _player.held == plug:
			_player._drop()
			ThoughtBubbles.notify(_player, "frustrated")
		elif plug.get_parent() == camp and not plug.freeze:
			plug.global_position = _cord_from + reach.normalized() * CORD_LEN + Vector3.UP * 0.05
	# Someone goes to put it back.
	if not _plugged and camp.clock - _cut_at > FIX_AFTER:
		var man = camp.dancers[0]
		man.fix(plug)
	if plug.global_position.distance_to(_cord_to) > 0.01:
		_cord_to = plug.global_position
		_draw_cord()


## The cord from the back of the speaker along the ground to the plug, rising to it
## where it's lifted.
func _draw_cord() -> void:
	var to := _cord_to
	var ground := Vector3(to.x, 0.012, to.z)
	var mid := _cord_from.lerp(ground, 0.5) + (ground - _cord_from).cross(Vector3.UP).normalized() * 0.2
	var points := []
	var radii := []
	for i in 10:
		var s := i / 9.0
		var p: Vector3 = _cord_from.lerp(mid, s).lerp(mid.lerp(ground, s), s)
		p.y = lerpf(0.012, to.y, smoothstep(0.75, 1.0, s))
		points.append(p)
		radii.append(Vector2(0.008, 0.008))
	_cord.mesh = LowPoly.loft(points, radii, 4, LowPoly.solid(WIRE))


# --- Raid the cooler -------------------------------------------------------------

func _build_cooler() -> void:
	# The lid, its handle and the handle's posts turn together on a hinge along the lid's back edge.
	var model := cooler.get_child(0) as Node3D
	_lid = Node3D.new()
	_lid.name = "LidHinge"
	_lid.position = Vector3(0, 0.28, -0.18)
	model.add_child(_lid)
	for part in model.find_children("*", "MeshInstance3D", true, false):
		if part.name.contains("Lid") or part.name.contains("Handle") or part.name.contains("Post"):
			part.reparent(_lid, true)
	_lid_spot = Interactable.new()
	_lid_spot.hold_time = LID_TIME
	_lid_spot.noise = LID_NOISE
	_lid_spot.camp = camp
	_lid_spot.reach = 0.65
	_lid_spot.prompt_height = 0.2
	_lid_spot.position = Vector3(0, 0.3, 0.24)
	_lid_spot.enabled = func() -> bool: return not _lid_open
	_lid_spot.finished.connect(func() -> void:
		_lid_open = true
		_lid_by_man = false)
	cooler.add_child(_lid_spot)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	LowPoly.add_box(st, Transform3D.IDENTITY, Vector3(0.18, 0.015, 0.1), TRAY)
	for z: float in [-0.03, 0.0, 0.03]:
		st.append_from(LowPoly.loft([Vector3(-0.08, 0.02, z), Vector3(0.08, 0.02, z)],
			[Vector2(0.014, 0.014), Vector2(0.014, 0.014)], 6, LowPoly.solid(SAUSAGE)), 0, Transform3D.IDENTITY)
	sausages = _loot(LowPoly.commit(st), Vector3(0.18, 0.04, 0.1), "cooler", _reset_cooler, Vector3(0, -0.03, -0.07))
	sausages.add_to_group("food")
	_reset_cooler()


## The lid shut with the sausages inside.
func _reset_cooler() -> void:
	_lid_open = false
	_lid_by_man = false
	_lid_spot.reset()
	lift(sausages)
	sausages.global_transform = cooler.global_transform * Transform3D(Basis(), Vector3(0, 0.2, 0.02))
	sausages.reset_physics_interpolation()
	if not sausages.has_meta("camp_loot") and not tasks.is_done("cooler"):
		sausages.set_meta("camp_loot", "cooler")


## The lid follows whether it's open; the low-poly man opens it for his drink and shuts
## it after, unless he forgets; while it's open he can reach in for the sausages.
func _cooler_routine(delta: float) -> void:
	var man = camp.dancers[0]
	var drinking: bool = man.activity() == "drink" and man.at_activity()
	if drinking and not _was_drinking:
		# He opens it (or finds it open), and may forget to shut it after.
		_lid_open = true
		_lid_by_man = true
		_forgot = _rng.randf() < FORGET
	elif not drinking and _was_drinking and _lid_by_man and not _forgot:
		_lid_open = false
		_lid_by_man = false
		_lid_spot.reset()
	_was_drinking = drinking
	_lid_t = move_toward(_lid_t, 1.0 if _lid_open else 0.0, delta * 3.0)
	_lid.rotation.x = deg_to_rad(LID_OPEN) * smoothstep(0.0, 1.0, _lid_t)
	# The sausages can be reached while the lid's up and they're still inside.
	var inside: bool = sausages.get_parent() == camp and sausages.freeze and sausages.has_meta("camp_loot")
	if inside:
		if _lid_t > 0.8 and not sausages.is_in_group("grabbable"):
			var layers: Vector2i = sausages.get_meta("camp_layers", Vector2i(1, 1))
			sausages.collision_layer = layers.x
			sausages.collision_mask = layers.y
			sausages.add_to_group("grabbable")
		elif _lid_t < 0.8 and sausages.is_in_group("grabbable"):
			lift(sausages)


# --- Helpers ---------------------------------------------------------------------

func _at(p: Vector2, y := 0.0) -> Vector3:
	return Vector3(fire.x + p.x, y, fire.y + p.y)


func _mesh(mesh: Mesh, parent: Node) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	parent.add_child(mi)
	return mi
