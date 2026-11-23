extends Node
## His laughing face, while he laughs (when he chitters), from the author's mock-up of
## him laughing: his mouth pops open in a wide smile, dark inside with a pink tongue,
## and his eyes squeeze shut, for about as long as the laugh; never in his sleep. It's
## built onto the rigged model's head at run time (raccoon_v2.glb is untouched), so it
## turns and bobs with his head.

## How long the laugh lasts (about as long as chitter.wav), and how quickly his eyes
## squeeze shut and open again (seconds).
const LAUGH_TIME := 1.1
const SQUEEZE := 0.08
const RELAX := 0.15
## How far his eyes squeeze shut: 1 is shut.
const SQUINT := 0.85
const MOUTH := Color("2e1b1e")
const TONGUE := Color("e07f86")
## The open mouth in the model's own space (facing -Z, at size 1), measured on the mesh:
## its top edge is his painted smile line, from corner to corner under his nose, and it
## hangs open below, the tongue filling the lower part.
const SMILE := [Vector3(-0.055, 0.389, -0.497), Vector3(0.0, 0.383, -0.535), Vector3(0.055, 0.389, -0.497)]
const JAW := Vector3(0.0, 0.338, -0.53)
const TONGUE_SHARE := 0.45
## Just in front of the muzzle, so the mouth sits on it rather than in it.
const OUT := Vector3(0.0, -0.002, -0.005)

## Set by the level.
var player: Node

var _mouth: MeshInstance3D
var _squint: Squint
var _left := 0.0
var _shut := 0.0


## Squeezes his eyes shut over the animation (scaling the eye bones down, as a blink does).
class Squint extends SkeletonModifier3D:
	var amount := 0.0
	var eyes: Array[int] = []

	func _process_modification_with_delta(_delta: float) -> void:
		if amount <= 0.0:
			return
		var skeleton := get_skeleton()
		for i in eyes:
			var s := skeleton.get_bone_pose_scale(i)
			skeleton.set_bone_pose_scale(i, Vector3(s.x, s.y * (1.0 - SQUINT * amount), s.z))


func _ready() -> void:
	var model: Node3D = player.model
	var found := model.find_children("*", "Skeleton3D", true, false)
	if found.is_empty():
		return
	var skeleton := found[0] as Skeleton3D
	var head := skeleton.find_bone("head")
	if head < 0:
		return
	# As raccoon_model.gd places what he carries: from the model's space into the head
	# bone's, as they are at rest.
	var model_to_skeleton := skeleton.global_transform.affine_inverse() * model.global_transform
	var attach := BoneAttachment3D.new()
	attach.bone_name = "head"
	skeleton.add_child(attach)
	_mouth = MeshInstance3D.new()
	_mouth.mesh = _build_mouth()
	_mouth.transform = skeleton.get_bone_global_rest(head).affine_inverse() * model_to_skeleton
	_mouth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mouth.visible = false
	attach.add_child(_mouth)
	_squint = Squint.new()
	for eye: String in ["eye.L", "eye.R"]:
		var i := skeleton.find_bone(eye)
		if i >= 0:
			_squint.eyes.append(i)
	skeleton.add_child(_squint)
	player.chittered.connect(laugh)


## Starts (or carries on) the laugh, unless he's in the hollow, where he sleeps.
func laugh() -> void:
	if not player.resting:
		_left = LAUGH_TIME


func _process(delta: float) -> void:
	if _mouth == null:
		return
	# Hopping up into the hollow to sleep ends a laugh at once.
	_left = 0.0 if player.resting else maxf(_left - delta, 0.0)
	var laughing := _left > 0.0
	# The mouth pops open and shut at once, as the thought icons pop; the eyes ease.
	_mouth.visible = laughing
	_shut = move_toward(_shut, 1.0 if laughing else 0.0, delta / (SQUEEZE if laughing else RELAX))
	_squint.amount = _shut


## The open mouth: between the smile line and the curve of the dropped jaw, dark above
## and the tongue below, every face pointing forward and a little down, like the muzzle.
func _build_mouth() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var normal := Vector3(0.0, -0.35, -1.0).normalized()
	var steps := 10
	var rows: Array = []
	for i in steps + 1:
		var s := float(i) / steps
		var top := _bezier(SMILE[0], _through(SMILE[0], SMILE[1], SMILE[2]), SMILE[2], s)
		var bottom := _bezier(SMILE[0], _through(SMILE[0], JAW, SMILE[2]), SMILE[2], s)
		rows.append([top + OUT, bottom.lerp(top, TONGUE_SHARE) + OUT, bottom + OUT])
	for i in steps:
		var a: Array = rows[i]
		var b: Array = rows[i + 1]
		for band in 2:
			var color := MOUTH if band == 0 else TONGUE
			for v: Vector3 in [a[band], b[band], b[band + 1], a[band], b[band + 1], a[band + 1]]:
				st.set_color(color)
				st.set_normal(normal)
				st.add_vertex(v)
	var mesh := st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 1.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0, mat)
	return mesh


static func _bezier(a: Vector3, ctrl: Vector3, b: Vector3, t: float) -> Vector3:
	return a.lerp(ctrl, t).lerp(ctrl.lerp(b, t), t)


## The control point that takes a curve from `a` to `b` through `middle` halfway.
static func _through(a: Vector3, middle: Vector3, b: Vector3) -> Vector3:
	return 2.0 * middle - 0.5 * (a + b)
