extends SkeletonModifier3D
## The rigged raccoon's body in turns, laid over whatever animation is playing: his
## back bends into the curve he's running, his head looks round to where he's steering
## before his body gets there, and his tail swings after him on springs, lagging into
## a turn and whipping round when it ends. raccoon_model.gd sets the inputs each frame.
## Angles are in radians about his up axis, positive to his left.

## How hard his back curves per rad/s of turn, and at most (summed along it).
const BEND_PER_RATE := 0.07
const BEND_MAX := 0.5
## Each bone's share of the curve, hips forward. The hips swing a little the other way,
## so he bends along his path rather than just turning his front.
const BEND_SHARES := {"pelvis": -0.35, "spine": 0.2, "chest": 0.3, "neck": 0.3, "head": 0.25}
## Each tail segment's share of the curve: it carries the hips' curve on round.
const TAIL_CURVE := -0.3
## How far round he looks toward where he's steering, at most, and the neck's and
## head's shares of it.
const LOOK_MAX := 0.8
const LOOK_SHARES := {"neck": 0.35, "head": 0.45}
## The tail segments, root to tip, each a damped spring: how stiff (natural frequency,
## rad/s) and how damped (1 = no overshoot). Softer toward the tip, but his tail is
## thick, so it swings out once and settles rather than flapping.
const TAIL := ["tail1", "tail2", "tail3", "tail4"]
const TAIL_FREQ := [16.0, 14.0, 12.0, 10.0]
const TAIL_DAMP := [0.75, 0.65, 0.6, 0.55]
## How much of a segment's swing flings the one after it.
const TAIL_PASS := 0.5
## Furthest a tail segment swings either way; it eases into this rather than stopping dead.
const TAIL_MAX := 0.6

## How fast he's turning (rad/s), and how far round the way he wants to go is from
## the way he faces.
var yaw_rate := 0.0
var look := 0.0
## 0..1, how much of all this to apply: none while he's asleep, climbing or leaping.
var amount := 0.0

## His up axis in the skeleton's space.
var _up := Vector3.UP
var _bones := {}
var _bend := 0.0
var _bend_v := 0.0
var _look := 0.0
var _look_v := 0.0
## The turn rate smoothed (the player's changes once a physics tick), from which the
## tail feels his angular acceleration.
var _rate := 0.0
var _tail: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _tail_v: Array[float] = [0.0, 0.0, 0.0, 0.0]


## `up` is his up axis in the skeleton's space.
func setup(up: Vector3) -> void:
	_up = up.normalized()


func _process_modification_with_delta(delta: float) -> void:
	var sk := get_skeleton()
	if sk == null or delta <= 0.0:
		return
	if _bones.is_empty():
		for name: String in BEND_SHARES.keys() + TAIL:
			_bones[name] = sk.find_bone(name)
	# Springs stepped at 120 Hz or finer, whatever the frame rate.
	delta = minf(delta, 0.1)
	var steps := maxi(1, ceili(delta * 120.0))
	var h := delta / steps
	var bend_to := clampf(yaw_rate * BEND_PER_RATE, -BEND_MAX, BEND_MAX) * amount
	var look_to := clampf(look, -LOOK_MAX, LOOK_MAX) * amount
	for i in steps:
		var before := _rate
		_rate += (yaw_rate * amount - _rate) * (1.0 - exp(-25.0 * h))
		var spin := (_rate - before) / h
		var b := spring_step(_bend, _bend_v, bend_to, 10.0, 0.8, h)
		_bend = b.x
		_bend_v = b.y
		var l := spring_step(_look, _look_v, look_to, 14.0, 0.9, h)
		_look = l.x
		_look_v = l.y
		# Each segment is flung by the spin of the one it hangs from: a tail that
		# kept still in the world would turn back against him as fast as he turns.
		var flung := spin
		for k in TAIL.size():
			var w: float = TAIL_FREQ[k]
			var a: float = w * w * (_bend * TAIL_CURVE - _tail[k]) - 2.0 * TAIL_DAMP[k] * w * _tail_v[k] - flung
			_tail_v[k] += a * h
			_tail[k] += _tail_v[k] * h
			flung += a * TAIL_PASS
	for name: String in BEND_SHARES:
		_turn_bone(sk, _bones[name], BEND_SHARES[name] * _bend + LOOK_SHARES.get(name, 0.0) * _look)
	for k in TAIL.size():
		_turn_bone(sk, _bones[TAIL[k]], TAIL_MAX * tanh(_tail[k] / TAIL_MAX))


## One step, `h` seconds long, of a damped spring from (x, v) toward `to`: returns the
## new (x, v). `freq` is how stiff it is (natural frequency, rad/s), `damp` how damped
## (1 = no overshoot).
static func spring_step(x: float, v: float, to: float, freq: float, damp: float, h: float) -> Vector2:
	v += (freq * freq * (to - x) - 2.0 * damp * freq * v) * h
	return Vector2(x + v * h, v)


## The same spring over `delta` seconds, stepped at 120 Hz or finer.
static func spring_for(x: float, v: float, to: float, freq: float, damp: float, delta: float) -> Vector2:
	delta = minf(delta, 0.1)
	var steps := maxi(1, ceili(delta * 120.0))
	var s := Vector2(x, v)
	for i in steps:
		s = spring_step(s.x, s.y, to, freq, damp, delta / steps)
	return s


## Turns `bone` by `angle` about his up axis, at its joint, on top of its pose.
func _turn_bone(sk: Skeleton3D, bone: int, angle: float) -> void:
	if bone < 0 or absf(angle) < 0.0001:
		return
	var parent := sk.get_bone_parent(bone)
	var frame := sk.get_bone_global_pose(parent).basis.orthonormalized() if parent >= 0 else Basis()
	var axis := (frame.inverse() * _up).normalized()
	sk.set_bone_pose_rotation(bone, Quaternion(axis, angle) * sk.get_bone_pose_rotation(bone))
