extends SkeletonModifier3D
## The rigged raccoon eating something he holds in his front paws, laid over his bored
## animation's sit (raccoon_model.gd `eating`, `eat_bite`). The author, 7 Nov 2026,
## after the first version (the bored pose as it is, the marshmallow floating between
## his limp paws and his mouth): "the eating animation can be way better".
##   - He sits up straight out of the bored slump, ears up, eyes open.
##   - His paws come up together under his chin, holding it: two TwoBoneIK3D chains run
##     after this modifier, reaching for the targets it sets each frame.
##   - Each bite (`bite` from 0 to 1): his paws lift it to his mouth as his head dips to
##     meet it (LIFT); a chomp (to CHOMP); then he chews with quick little nods, his eyes
##     squeezed happily shut, while his paws lower it again.
## Angles are in radians; positive pitches nose down.

## Sitting up out of the bored slump, which bends his spine 0.25, chest 0.5, neck 0.45
## and head 0.2 forward (design/character/raccoon_v2/anim.py): how far each turns back.
## His head turns on down, so he looks at what he holds rather than at the sky.
const SIT_UP := {"spine": 0.22, "chest": 0.42, "neck": 0.22, "head": -0.22}
## His ears turned up from the bored droop.
const EARS_UP := 0.45
## Where his paws hold it, from his mouth, in metres along his forward and up (at model
## scale 1): between bites, a little in front of and under it; at a bite, at it.
const HOLD := Vector2(0.075, -0.21)
const BITE := Vector2(0.055, -0.03)
## How far apart his wrists are (m, model scale 1).
const WRIST_GAP := 0.07
## Where each elbow points, from its shoulder (m along back, down and out, scale 1).
const ELBOW := Vector3(0.12, 0.12, 0.06)
## His head's dip to meet it at a bite (the neck takes NECK_SHARE), and his nods as he
## chews: how far, and how many in a bite; and how far his head tilts from side to side
## as he chews, contented.
const DIP := 0.45
const NECK_SHARE := 0.4
const NOD := 0.12
const CHEWS := 3.0
const TILT := 0.12
## How shut his eyes squeeze while he chews (1 = open).
const SQUINT := 0.18
## A bite's parts, as shares of it: the lift to his mouth ends at LIFT, the chomp at
## CHOMP, and the paws are back down at LOWERED; he chews from CHOMP to the end.
const LIFT := 0.32
const CHOMP := 0.42
const LOWERED := 0.75

## 0..1, how much of this to apply (raccoon_model.gd eases it in and out).
var amount := 0.0
## How far through a bite (0..1), or negative between bites, just holding it.
var bite := -1.0
## The IK targets and poles, left then right (children of the skeleton, so their
## positions are in its space): raccoon_model.gd makes them.
var targets: Array[Node3D] = []
var poles: Array[Node3D] = []

## His axes in the skeleton's space, his scale, and his mouth in his head bone's space.
var _up := Vector3.UP
var _forward := Vector3.BACK
var _scale := 1.0
var _mouth := Vector3.ZERO
var _bones := {}


## His up and forward axes in the skeleton's space, metres in the skeleton per metre
## at model scale 1, and his mouth in his head bone's space.
func setup(up: Vector3, forward: Vector3, scale_: float, mouth: Vector3) -> void:
	_up = up.normalized()
	_forward = (forward - _up * forward.dot(_up)).normalized()
	_scale = scale_
	_mouth = mouth


func _process_modification_with_delta(_delta: float) -> void:
	var sk := get_skeleton()
	if sk == null or amount <= 0.0:
		return
	if _bones.is_empty():
		for name: String in ["spine", "chest", "neck", "head", "ear.L", "ear.R", "eye.L", "eye.R",
				"upperarm.L", "upperarm.R"]:
			_bones[name] = sk.find_bone(name)
	var a := amount
	var nod_axis := _up.cross(_forward).normalized()
	var side := nod_axis
	# Where in the bite he is.
	var lift := 0.0
	var chew := 0.0
	var tilt := 0.0
	var squint := 0.0
	if bite >= 0.0:
		var b := clampf(bite, 0.0, 1.0)
		if b < LIFT:
			lift = smoothstep(0.0, LIFT, b)
		elif b < CHOMP:
			lift = 1.0
		else:
			lift = 1.0 - smoothstep(CHOMP, LOWERED, b)
			var c := (b - CHOMP) / (1.0 - CHOMP)
			var fade := 1.0 - smoothstep(0.8, 1.0, c)
			chew = sin(c * CHEWS * TAU) * fade
			tilt = sin(c * PI) * fade
			squint = smoothstep(0.0, 0.12, c) * fade
	# Sitting up; the head dipping to it and nodding as he chews.
	for name: String in SIT_UP:
		_turn(sk, _bones[name], nod_axis, -SIT_UP[name] * a)
	_turn(sk, _bones.neck, nod_axis, DIP * NECK_SHARE * lift * a)
	_turn(sk, _bones.head, nod_axis, (DIP * (1.0 - NECK_SHARE) * lift + NOD * chew) * a)
	_turn(sk, _bones.head, _forward, TILT * tilt * a)
	# Ears up; eyes open, or squeezed shut as he chews.
	for name: String in ["ear.L", "ear.R"]:
		_turn(sk, _bones[name], nod_axis, -EARS_UP * a)
	for name: String in ["eye.L", "eye.R"]:
		var bone: int = _bones[name]
		if bone >= 0:
			var s := sk.get_bone_pose_scale(bone)
			sk.set_bone_pose_scale(bone, Vector3(s.x, lerpf(s.y, lerpf(1.0, SQUINT, squint), a), s.z))
	# The paws: where the IK reaches for, from his mouth as the head now holds it.
	var head: int = _bones.head
	if head < 0 or targets.size() < 2:
		return
	var mouth := sk.get_bone_global_pose(head) * _mouth
	var at: Vector2 = HOLD.lerp(BITE, lift) * _scale
	var middle := mouth + _forward * at.x + _up * at.y
	for i in 2:
		var out := 1.0 if i == 0 else -1.0
		var shoulder: int = _bones["upperarm.L" if i == 0 else "upperarm.R"]
		# Which way is his left in the skeleton: the side his left shoulder is on.
		if i == 0 and shoulder >= 0 and _bones["upperarm.R"] >= 0:
			var across := sk.get_bone_global_pose(shoulder).origin - sk.get_bone_global_pose(_bones["upperarm.R"]).origin
			if across.dot(side) < 0.0:
				side = -side
		targets[i].position = middle + side * out * WRIST_GAP * 0.5 * _scale
		if shoulder >= 0:
			var from := sk.get_bone_global_pose(shoulder).origin
			poles[i].position = from + (-_forward * ELBOW.x - _up * ELBOW.y + side * out * ELBOW.z) * _scale


## Turns `bone` by `angle` about `axis` (in the skeleton's space), at its joint, on top
## of its pose.
func _turn(sk: Skeleton3D, bone: int, axis: Vector3, angle: float) -> void:
	if bone < 0 or absf(angle) < 0.0001:
		return
	var parent := sk.get_bone_parent(bone)
	var frame := sk.get_bone_global_pose(parent).basis.orthonormalized() if parent >= 0 else Basis()
	sk.set_bone_pose_rotation(bone, Quaternion((frame.inverse() * axis).normalized(), angle) * sk.get_bone_pose_rotation(bone))
