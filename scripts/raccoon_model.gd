@tool
extends Node3D
## The raccoon: the rigged, animated Blender model (raccoon_v2), the first Blender
## model, or a low-poly one built from code. All match the concept art.
## Faces -Z (Godot's forward) with its feet at y = 0. The player sets walk_amount /
## walk_phase / crouch / turn / chitter_time / sleep, and for the rigged model also
## speed / climbing / hopping; the rigged model picks its animation from those, the
## other two swing their separate parts in code.

const LowPoly := preload("res://scripts/lowpoly.gd")
const RaccoonFlex := preload("res://scripts/raccoon_flex.gd")
## Exported from raccoon.blend by assets/characters/export_raccoon.py.
const MODEL_PATH := "res://assets/characters/raccoon.glb"
## Exported from raccoon_v2.blend by assets/characters/export_raccoon_v2.py: one
## skinned mesh and seven looping animations.
const RIGGED_PATH := "res://assets/characters/raccoon_v2.glb"
## Where carried things sit, just under the snout, in the model's own space.
const RIGGED_MOUTH := Vector3(0, 0.37, -0.57)
## The middle of his underside when he's curled up asleep, in model space, measured
## from each model's sleep pose. He curls up round his hips rather than over his
## feet, so while he sleeps the model slides by this to put the ball on his origin.
## (Moved by -0.034, 0, +0.006 when his rear was slimmed on 19 Oct: the curled ball's
## middle moved that much.)
const RIGGED_SLEEP_BED := Vector3(-0.296, 0.066, 0.333)
const MODEL_SLEEP_BED := Vector3(-0.111, 0.001, 0.104)
const CODE_SLEEP_BED := Vector3(-0.113, -0.038, -0.021)
## How long one animation takes to blend into the next, in seconds.
const RIGGED_BLEND := 0.2
## Between the ones he moves about in it's a little longer, so starting, stopping and
## changing gait ease in; and one gait changing to another carries on from the same
## point in its stride.
const LOCOMOTION := ["idle", "walk", "run", "sneak"]
const GAIT_BLEND := 0.3
## Turning on the spot faster than this (rad/s), he steps round rather than gliding.
const TURN_STEP := 2.5
## His weight, on the rigged model. He banks into a turn by LEAN_GAIN of the angle the
## sideways force on him would tip a cyclist, up to LEAN_MAX, and tips nose up by
## TILT_PER_ACCEL per m/s² of speeding up (nose down braking), up to TILT_MAX: both
## on springs, so a hard stop dips and settles. He tips on his paws, PAW_PIVOT ahead
## of and behind his middle (model scale 1). All in radians.
const LEAN_GAIN := 0.15
const LEAN_MAX := 0.2
const TILT_PER_ACCEL := 0.007
const TILT_MAX := 0.1
const PAW_PIVOT := 0.3
## Seconds standing still before he gets bored (as with the sprites).
const BORED_AFTER := 5.0
## Above this speed (m/s) he runs rather than walks; the player's walk is 2.0.
const RUN_FROM := 2.15
## Each gait's stride (metres a paw travels while it's down, at model scale 1), the
## share of the cycle the paw is down, the cycle's length in seconds (all from
## design/character/raccoon_v2/anim.py), and the fastest playback allowed. Played
## back at the speed that keeps the planted paws still, up to that cap, so the legs
## don't blur.
const GAITS := {
	"walk": [0.26, 0.60, 1.0, 3.0],
	"run": [0.46, 0.40, 0.6667, 3.0],
	"sneak": [0.16, 0.78, 2.0, 3.0],
	"climb": [0.22, 0.55, 1.0, 2.5],
}

# Sampled from design/reference/the-raccon.jpg: blue-grey coat, cream mask,
# slate eye patches, near-black paws and tail bands.
const GREY := Color("72848c")
const GREY_DARK := Color("5a6b72")
const CREAM := Color("dfd6b7")
const BLACK := Color("3a4547")
const INK := Color("1a1f20")
const PAW := INK
## The Blender model's materials, painted with this palette, which the game's
## lighting is tuned for.
const MODEL_COLORS := {
	"R_Fur": GREY,
	"R_Cream": CREAM,
	"R_Mask": BLACK,
	"R_EarInner": GREY_DARK,
	"R_Black": INK,
	"R_Nose": INK,
}

## Use the rigged, animated model. Turn off for the first Blender model (or the
## code-built one, with use_blender_model off too).
@export var use_rigged_model := true:
	set(value):
		use_rigged_model = value
		if is_node_ready():
			_rebuild()

## Use the first Blender model. Turn off to build the raccoon from code instead.
@export var use_blender_model := true:
	set(value):
		use_blender_model = value
		if is_node_ready():
			_rebuild()

## For the raccoon built from code: a rounded, smooth-shaded mesh. Turn off for
## the original faceted low-poly look.
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
## -1..1, how hard we're turning (positive = left). Head leads, tail trails.
var turn := 0.0
## Rigged model only: how fast he's turning (rad/s, positive = left), how far round
## the way he wants to go is from the way he faces (radians), and how fast he's
## speeding up (m/s², negative braking). He bends, looks and leans with these.
var yaw_rate := 0.0
var look := 0.0
var accel := 0.0
## Seconds of chittering left.
var chitter_time := 0.0
## 0 = awake, 1 = curled up asleep: legs tucked, tail wrapped round, eyes shut.
var sleep := 0.0
## Rigged model only: how fast he's moving over the ground or up the trunk (m/s),
## and whether he's on a trunk or in a hop.
var speed := 0.0
var climbing := false
var hopping := false
## Rigged model only: play this animation whatever he's doing ("" = his real state).
## For screenshots.
var forced_animation := ""
## Rigged model only: hold the run animation at this point in its cycle (wrapping
## round 1), for a leap; negative when he isn't leaping.
var leap := -1.0
## 0..1: squashes him down, crouching to spring or soaking up a landing.
var squash := 0.0

var body: Node3D
var head: Node3D
var tail: Node3D
var legs: Array[Node3D] = []
## Where carried objects are held.
var mouth: Node3D

var _leg_height: Array[float] = []
var _eyes: Array[Node3D] = []
var _curled_tail: Node3D
var _head_y := 0.47
## How far the tail pitches as he crouches; positive lowers it.
var _tail_crouch := 0.1
var _model_materials := {}
var _sleep_bed := Vector3.ZERO
## Rigged model: how far the sleep animation has blended in, 0..1.
var _curl := 0.0
var _t := 0.0
## The rigged model: its animation player, the turned-round scene root, how long
## he's been standing still, and the chitter hop.
var _anim: AnimationPlayer
var _rig: Node3D
var _still := 0.0
var _chitter_prev := 0.0
var _bounce := 0.0
## The rigged model: its give in turns (raccoon_flex.gd), the playback rate as eased,
## and his bank and tip (radians) with how fast each is changing.
var _flex: RaccoonFlex
var _rate := 1.0
var _lean := 0.0
var _lean_v := 0.0
var _tilt := 0.0
var _tilt_v := 0.0


func _ready() -> void:
	# His pose (the slide as he curls up, the rig's lean, squash and hop) is set
	# every frame in _process, so the model isn't interpolated itself; it still
	# rides on the player, who is, so he's drawn between physics ticks.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_build()


func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	legs.clear()
	_leg_height.clear()
	_eyes.clear()
	_anim = null
	_rig = null
	_flex = null
	_build()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _anim:
		_process_rigged(delta)
		chitter_time = maxf(chitter_time - delta, 0.0)
		return
	chitter_time = maxf(chitter_time - delta, 0.0)
	# As he curls up, slide the model so the middle of the ball lies where he was laid.
	position = -_sleep_bed * scale * sleep

	# Diagonal leg pairs swing together, like a real trot.
	var stride := sin(walk_phase) * 0.65 * walk_amount
	var swings := [stride, -stride, -stride, stride]
	for i in legs.size():
		var h := _leg_height[i] - crouch * 0.1
		legs[i].rotation.x = swings[i]
		legs[i].position.y = h
		legs[i].scale.y = h / _leg_height[i]

	body.position.y = absf(sin(walk_phase)) * 0.025 * walk_amount - crouch * 0.1
	body.rotation.z = sin(walk_phase) * 0.03 * walk_amount + turn * 0.08
	tail.rotation.y = sin(_t * 2.3) * 0.22 + sin(walk_phase) * 0.15 * walk_amount - turn * 0.5
	tail.rotation.x = _tail_crouch * crouch - 0.05 * walk_amount
	head.rotation.y = sin(_t * 0.8) * 0.18 * (1.0 - walk_amount) + turn * 0.35
	head.rotation.x = sin(walk_phase * 2.0) * 0.04 * walk_amount - crouch * 0.12
	if chitter_time > 0.0:
		head.rotation.x += sin(_t * 45.0) * 0.07
		head.rotation.y += sin(_t * 31.0) * 0.05

	# Asleep: lie flat and tuck the head round towards the tail. No breathing: he
	# doesn't swell and shrink, asleep or awake.
	body.position.y -= sleep * 0.17
	var wide := 1.0 + 0.12 * squash
	body.scale = Vector3(wide, 1.0 - 0.2 * squash, wide)
	head.position.y = _head_y - sleep * 0.07
	if sleep > 0.0:
		head.rotation.y = lerpf(head.rotation.y, 0.95, sleep)
		head.rotation.x = lerpf(head.rotation.x, -0.5, sleep)
	var curled := sleep > 0.5
	tail.visible = not curled
	_curled_tail.visible = curled
	for leg in legs:
		leg.visible = not curled
	for eye in _eyes:
		eye.scale.y = lerpf(1.0, 0.12, sleep)


func _build() -> void:
	if use_rigged_model and _build_rigged():
		_sleep_bed = RIGGED_SLEEP_BED
		return
	if use_blender_model and _build_from_model():
		_sleep_bed = MODEL_SLEEP_BED
		return
	_sleep_bed = CODE_SLEEP_BED
	_head_y = 0.47
	_tail_crouch = 0.1
	body = _part("Body", self, Vector3.ZERO)
	_mesh(body, _loft(
		[Vector3(0, 0.36, 0.40), Vector3(0, 0.40, 0.28), Vector3(0, 0.43, 0.04),
			Vector3(0, 0.41, -0.18), Vector3(0, 0.41, -0.30)],
		[Vector2(0.065, 0.072), Vector2(0.16, 0.18), Vector2(0.19, 0.225),
			Vector2(0.16, 0.18), Vector2(0.115, 0.13)],
		8, _body_color, PI / 8))

	head = _part("Head", body, Vector3(0, _head_y, -0.31))
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
		_eyes.append(eye)

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
		var r := 0.03 if k == segments else 0.06 + 0.035 * sin(PI * minf(u * 1.1, 1.0))
		radii.append(Vector2(r, r))
	_mesh(tail, _loft(centers, radii, 7, _tail_color))

	# The sleeping tail: the same tail, wrapped round his left side to the front, on the floor.
	_curled_tail = _part("TailCurled", body, tail.position)
	var curl: Array = []
	for k in segments + 1:
		var u := float(k) / segments
		var phi := u * deg_to_rad(205.0)
		curl.append(Vector3(-sin(phi) * 0.32, -0.15 * smoothstep(0.0, 0.35, u), -0.32 + cos(phi) * 0.32))
	_mesh(_curled_tail, _loft(curl, radii, 7, _tail_color))
	_curled_tail.visible = false

	_leg("LegFL", Vector3(-0.09, 0.36, -0.20), 0.065)
	_leg("LegFR", Vector3(0.09, 0.36, -0.20), 0.065)
	_leg("LegBL", Vector3(-0.105, 0.37, 0.22), 0.085)
	_leg("LegBR", Vector3(0.105, 0.37, 0.22), 0.085)


## Uses the Blender model. Its parts have the same names as the ones built in code
## and their origins at the joints, so _process() animates them the same way.
## Returns false if the model can't be loaded (e.g. the project was never imported).
func _build_from_model() -> bool:
	var scene := load(MODEL_PATH) as PackedScene
	if scene == null:
		push_warning("Couldn't load %s, so the raccoon is built from code." % MODEL_PATH)
		return false
	var model := scene.instantiate()
	add_child(model)
	var rig := model.get_node("Raccoon")
	body = rig.get_node("Body") as Node3D
	head = body.get_node("Head") as Node3D
	tail = body.get_node("Tail") as Node3D
	_curled_tail = body.get_node("TailCurled") as Node3D
	_curled_tail.visible = false
	for leg_name: String in ["LegFL", "LegFR", "LegBL", "LegBR"]:
		var leg := rig.get_node(leg_name) as Node3D
		legs.append(leg)
		_leg_height.append(leg.position.y)
	for eye_name: String in ["EyeL", "EyeR"]:
		_eyes.append(head.get_node(eye_name) as Node3D)
	mouth = head.get_node("Mouth") as Node3D
	_head_y = head.position.y
	# His tail droops to the ground, so it lifts as he crouches instead of dropping.
	_tail_crouch = -0.22
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			mi.set_surface_override_material(i, _model_material(mi.mesh.surface_get_material(i)))
	return true


## Uses the rigged model. Returns false if it can't be loaded (e.g. never imported).
func _build_rigged() -> bool:
	var scene := load(RIGGED_PATH) as PackedScene
	if scene == null:
		push_warning("Couldn't load %s, so the older raccoon is used." % RIGGED_PATH)
		return false
	_rig = scene.instantiate() as Node3D
	# He faces +Z in the file; turn him round to face -Z.
	_rig.rotation.y = PI
	add_child(_rig)
	_anim = _rig.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	for anim_name: StringName in _anim.get_animation_list():
		_anim.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	for mi: MeshInstance3D in _rig.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			mi.set_surface_override_material(i, _model_material(mi.mesh.surface_get_material(i)))
	# Carried things ride on the head bone, just under the snout.
	var skeleton := _rig.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var attach := BoneAttachment3D.new()
	attach.bone_name = "head"
	skeleton.add_child(attach)
	mouth = Marker3D.new()
	mouth.name = "Mouth"
	attach.add_child(mouth)
	var head_rest := skeleton.get_bone_global_rest(skeleton.find_bone("head"))
	var model_to_skeleton := skeleton.global_transform.affine_inverse() * global_transform
	mouth.transform = head_rest.affine_inverse() * model_to_skeleton * Transform3D(Basis(), RIGGED_MOUTH)
	# His back, head and tail give in turns, laid over the animation.
	_flex = RaccoonFlex.new()
	skeleton.add_child(_flex)
	var rig_to_skeleton := (_rig.global_basis.inverse() * skeleton.global_basis).orthonormalized()
	_flex.setup(rig_to_skeleton.inverse() * Vector3.UP)
	_anim.play("idle")
	return true


## Picks the animation for what he's doing and plays it at a speed to match.
func _process_rigged(delta: float) -> void:
	var anim_name := forced_animation
	if anim_name == "":
		anim_name = _rigged_state(delta)
	if _anim.current_animation != anim_name:
		_change_animation(anim_name)
	# Eased, so speeding up or slowing down doesn't jerk the stride.
	_rate = lerpf(_rate, _rigged_rate(anim_name), 1.0 - exp(-10.0 * delta))
	_anim.speed_scale = _rate
	if leap >= 0.0 and forced_animation == "":
		# Seek every frame rather than pausing: a paused player never finishes its blend.
		_anim.seek(fposmod(leap, 1.0) * _anim.current_animation_length, true)
	# As the sleep animation blends in, slide the model so the middle of the ball
	# lies where he was laid, and back again as it blends out.
	_curl = move_toward(_curl, 1.0 if anim_name == "sleep" else 0.0, delta / RIGGED_BLEND)
	position = -_sleep_bed * scale * _curl
	# A quick squash and hop when he chitters (there's no chitter animation yet).
	if chitter_time > _chitter_prev:
		_bounce = 1.0
	_chitter_prev = chitter_time
	_bounce = maxf(_bounce - delta / 0.35, 0.0)
	var hop := sin(_bounce * PI)

	# On the ground his body gives in turns (raccoon_flex.gd) and carries weight: he
	# banks into turns by the sideways force on him, and tips as he speeds up or brakes.
	var grounded := not climbing and not hopping and leap < 0.0 and _curl <= 0.0 and forced_animation == ""
	_flex.amount = move_toward(_flex.amount, 1.0 if grounded else 0.0, delta * 4.0)
	_flex.yaw_rate = yaw_rate
	_flex.look = look
	var lean_to := 0.0
	var tilt_to := 0.0
	if grounded:
		lean_to = clampf(atan(speed * yaw_rate / 9.8) * LEAN_GAIN, -LEAN_MAX, LEAN_MAX)
		tilt_to = clampf(accel * TILT_PER_ACCEL, -TILT_MAX, TILT_MAX)
	var lean := RaccoonFlex.spring_for(_lean, _lean_v, lean_to, 9.0, 0.75, delta)
	_lean = lean.x
	_lean_v = lean.y
	var tilt := RaccoonFlex.spring_for(_tilt, _tilt_v, tilt_to, 8.0, 0.45, delta)
	_tilt = tilt.x
	_tilt_v = tilt.y
	# Turned round to face -Z and squashed about his feet; banked about his feet; then
	# tipped nose up on his hind paws or nose down on his front ones.
	var wide := 1.0 + 0.07 * hop + 0.12 * squash
	var xf := Transform3D(Basis(Vector3.UP, PI) * Basis.from_scale(Vector3(wide, 1.0 - 0.12 * hop - 0.2 * squash, wide)),
		Vector3(0, 0.05 * hop, 0))
	xf = Transform3D(Basis(Vector3.BACK, _lean), Vector3.ZERO) * xf
	var pivot := Vector3(0, 0, PAW_PIVOT if _tilt > 0.0 else -PAW_PIVOT)
	var tip := Basis(Vector3.RIGHT, _tilt)
	_rig.transform = Transform3D(tip, pivot - tip * pivot) * xf


## Starts `anim_name`. Between the animations he moves about in the blend is longer,
## and a gait changing to another carries on from the same point in its stride.
func _change_animation(anim_name: String) -> void:
	var from := _anim.current_animation
	var phase := -1.0
	if from in GAITS and anim_name in GAITS and "climb" not in [from, anim_name] and leap < 0.0:
		phase = _anim.current_animation_position / maxf(_anim.current_animation_length, 0.001)
	_anim.play(anim_name, GAIT_BLEND if from in LOCOMOTION and anim_name in LOCOMOTION else RIGGED_BLEND)
	if phase >= 0.0:
		_anim.seek(phase * _anim.current_animation_length, true)


func _rigged_state(delta: float) -> String:
	var still := false
	var state := "idle"
	# A leap holds poses from the run; asleep, he's curled up from the moment he
	# starts dozing until he gets up.
	if leap >= 0.0:
		state = "run"
	elif sleep > 0.0:
		state = "sleep"
	elif hopping:
		state = "run"
	elif climbing:
		state = "climb"
	elif crouch > 0.5:
		state = "sneak"
	elif speed > RUN_FROM:
		state = "run"
	elif speed > 0.15 or absf(yaw_rate) > TURN_STEP:
		state = "walk"
	else:
		still = chitter_time <= 0.0
	_still = _still + delta if still else 0.0
	if still and _still > BORED_AFTER:
		state = "bored"
	return state


## Playback speed for an animation: for the gaits, the speed that keeps the planted
## paws still at his current speed (capped); 1 for the rest. Sneaking or climbing
## on the spot holds the pose.
func _rigged_rate(anim_name: String) -> float:
	if not GAITS.has(anim_name) or hopping or leap >= 0.0 or forced_animation != "":
		return 1.0
	var g: Array = GAITS[anim_name]
	var natural: float = g[0] * scale.x / (g[1] * g[2])
	# Turning on the spot, his paws travel round his middle.
	var pace := maxf(speed, absf(yaw_rate) * PAW_PIVOT * scale.x)
	return clampf(pace / natural, 0.0, g[3])


## A matte material in the palette colour for one of the Blender model's materials.
func _model_material(source: Material) -> Material:
	var key := source.resource_name if source else ""
	if key == "R_Eye":
		return _eye_material()
	if not _model_materials.has(key):
		var original := source as BaseMaterial3D
		var mat := StandardMaterial3D.new()
		mat.albedo_color = MODEL_COLORS.get(key, original.albedo_color if original else GREY)
		mat.roughness = 1.0
		mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		_model_materials[key] = mat
	return _model_materials[key]


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
	LowPoly.add_tri(st, l * 0.6 + inset, r * 0.6 + inset, tip * 0.75 + inset, mid, GREY_DARK)
	var mesh := st.commit()
	mesh.surface_set_material(0, LowPoly.material())
	return mesh


func _body_color(segment: int, _side: int, n: Vector3) -> Color:
	if n.y < -0.4:
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
			return GREY if n.y > 0.8 else CREAM
		3:
			return INK
	return GREY


func _tail_color(segment: int, _side: int, _n: Vector3) -> Color:
	if segment <= 0:
		return GREY
	if segment >= 11:
		return INK
	return GREY if int((segment - 1) / 2.0) % 2 == 0 else INK


func _leg_color(segment: int, _side: int, _n: Vector3) -> Color:
	if segment <= 0:
		return GREY
	if segment == 1:
		return GREY_DARK
	return PAW


## Smooth ears face -Z: grey inside, a cream rim, grey behind.
func _ear_color(_segment: int, _side: int, n: Vector3) -> Color:
	if n.z < -0.6:
		return GREY_DARK
	if n.z < -0.2:
		return CREAM
	return GREY


func _eye_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("171c20")
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
