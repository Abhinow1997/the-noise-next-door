extends CharacterBody3D
## Goose-game style controls: walk, run, sneak, carry things in your mouth, chitter,
## and climb trees.

signal chittered

const RaccoonModel := preload("res://scripts/raccoon_model.gd")

@export var walk_speed := 2.0
@export var run_speed := 4.0
@export var sneak_speed := 1.0
@export var climb_speed := 1.2
@export var turn_speed := 9.0
## Overall scale of the raccoon and its collider.
@export var size := 0.8
@export var grab_range := 0.55

## Set by the level so movement follows the camera's facing.
var camera: Camera3D
## Set by the level: the trunks he can climb (see `climbable` in forest.gd).
var trees: Array[Dictionary] = []
var model: RaccoonModel
var held: RigidBody3D
var sneaking := false
## True while curled up in the hollow, including the hops in and out.
var resting := false
## True while on a tree trunk, including the hops on and off.
var climbing := false

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _push_speed := 0.0
var _speed := 0.0
var _turn := 0.0
var _voice: AudioStreamPlayer
var _shape: CollisionShape3D
var _hop_from: Transform3D
var _hop_to: Transform3D
## 0..1 through a hop (into or out of the hollow, onto or off a trunk); -1 when not hopping.
var _hop_t := -1.0
var _hop_time := 0.8
var _hop_height := 0.9
## Called when the hop lands.
var _hop_done := Callable()
var _waking := false
## Where he hopped up from, to land there again.
var _rest_return: Transform3D
## The trunk he's climbing, how far up it he is (metres along it) and where round
## it (radians, 0 on its +Z side).
var _tree: Dictionary
var _climb_along := 0.0
var _climb_angle := 0.0
## Which way round the trunk the held left/right key goes: 1 or -1, 0 when neither is held.
var _climb_side := 0.0
## How long he's been pushing into a trunk.
var _climb_push := 0.0


func _ready() -> void:
	model = RaccoonModel.new()
	model.scale = Vector3.ONE * size
	add_child(model)

	# Lying capsule, bottom flush with the feet.
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.2 * size
	capsule.height = 0.8 * size
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	shape.rotation.x = PI / 2
	shape.position = Vector3(0, 0.2, 0.04) * size
	add_child(shape)
	_shape = shape

	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050.0
	generator.buffer_length = 0.6
	_voice = AudioStreamPlayer.new()
	_voice.stream = generator
	_voice.volume_db = -6.0
	add_child(_voice)


func _physics_process(delta: float) -> void:
	if _hop_t >= 0.0:
		_hop_process(delta)
	elif resting:
		_rest_process(delta)
	elif climbing:
		_climb_process(delta)
	else:
		_walk_process(delta)


func _walk_process(delta: float) -> void:
	var input := _move_input()
	var dir := Vector3(input.x, 0.0, input.y)
	if camera:
		dir = dir.rotated(Vector3.UP, camera.global_rotation.y)

	sneaking = Input.is_action_pressed("sneak")
	var speed := walk_speed
	if sneaking:
		speed = sneak_speed
	elif Input.is_action_pressed("run"):
		speed = run_speed
	_push_speed = speed * dir.length()

	# Turn smoothly toward the input, then travel the way we face, so changes of
	# direction become arcs instead of the whole body pivoting on the spot.
	var old_yaw := rotation.y
	var forward := -global_basis.z
	var target_speed := 0.0
	if dir.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 1.0 - exp(-turn_speed * delta))
		forward = -global_basis.z
		# Slow down while facing away from where we want to go (tight U-turns).
		target_speed = speed * dir.length() * clampf(forward.dot(dir.normalized()), 0.25, 1.0)
	var accel := 10.0 if target_speed > _speed else 14.0
	_speed = move_toward(_speed, target_speed, accel * delta)
	velocity.x = forward.x * _speed
	velocity.z = forward.z * _speed
	if not is_on_floor():
		velocity.y -= _gravity * delta

	# How hard we're turning, smoothed, so the body can bend into it.
	var yaw_rate := wrapf(rotation.y - old_yaw, -PI, PI) / maxf(delta, 0.0001)
	_turn = lerpf(_turn, clampf(yaw_rate / 6.0, -1.0, 1.0), 1.0 - exp(-8.0 * delta))
	model.turn = _turn

	move_and_slide()
	_push_bodies(delta)
	_carry()

	var ground_speed := Vector2(velocity.x, velocity.z).length()
	model.walk_amount = clampf(ground_speed / walk_speed, 0.0, 1.0)
	model.walk_phase += ground_speed * delta * 7.0 / size
	model.crouch = move_toward(model.crouch, 1.0 if sneaking else 0.0, delta * 5.0)

	# Pushing into a tree trunk for a moment starts a climb.
	var tree := _trunk_ahead(dir) if is_on_floor() else {}
	_climb_push = _climb_push + delta if not tree.is_empty() else 0.0
	if _climb_push > 0.2:
		_start_climb(tree)


func _move_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_forward", "move_back")


## Hops up to `spot` (the hollow in the home pine) and curls up there to sleep.
## A move key wakes him and he hops back down.
func rest(spot: Transform3D) -> void:
	if resting:
		return
	if held:
		_drop()
	# Climbing in from the trunk, he wakes on the ground in front of the hollow.
	var from_trunk := climbing
	_rest_return = _ground_spot(0.0) if from_trunk else global_transform
	climbing = false
	resting = true
	_waking = false
	_hop(global_transform, spot, 0.5 if from_trunk else 0.8, 0.25 if from_trunk else 0.9)


## Moves him from one transform to another along an arc `height` high, turning as
## he goes, then calls `done`. Collisions are off meanwhile.
func _hop(from: Transform3D, to: Transform3D, time := 0.8, height := 0.9, done := Callable()) -> void:
	_hop_from = from
	_hop_to = to
	_hop_t = 0.0
	_hop_time = time
	_hop_height = height
	_hop_done = done
	_shape.disabled = true
	velocity = Vector3.ZERO
	_speed = 0.0


func _hop_process(delta: float) -> void:
	model.walk_amount = 0.0
	model.turn = 0.0
	model.crouch = move_toward(model.crouch, 0.0, delta * 5.0)
	_hop_t = minf(_hop_t + delta / _hop_time, 1.0)
	var pos := _hop_from.origin.lerp(_hop_to.origin, _hop_t) + Vector3.UP * sin(PI * _hop_t) * _hop_height
	global_transform = Transform3D(_hop_from.basis.slerp(_hop_to.basis, minf(_hop_t * 1.5, 1.0)), pos)
	_carry()
	if _hop_t >= 1.0:
		_hop_t = -1.0
		if _hop_done.is_valid():
			_hop_done.call()


func _rest_process(delta: float) -> void:
	model.walk_amount = 0.0
	model.turn = 0.0
	if not _waking:
		model.sleep = move_toward(model.sleep, 1.0, delta * 1.5)
		_waking = model.sleep >= 1.0 and _move_input().length_squared() > 0.1
		return
	model.sleep = move_toward(model.sleep, 0.0, delta * 3.0)
	if model.sleep <= 0.0:
		_hop(global_transform, _rest_return, 0.8, 0.9, _end_rest)


func _end_rest() -> void:
	resting = false
	_shape.disabled = false


# --- Climbing ------------------------------------------------------------------

## The trunk he's pressed against and pushing toward, or {} if there isn't one.
func _trunk_ahead(dir: Vector3) -> Dictionary:
	if dir.length_squared() < 0.25:
		return {}
	for tree: Dictionary in trees:
		var to_trunk: Vector3 = tree.base - global_position
		to_trunk.y = 0.0
		if to_trunk.length() - tree.clear < 0.45 * size and dir.normalized().dot(to_trunk.normalized()) > 0.6:
			return tree
	return {}


func _start_climb(tree: Dictionary) -> void:
	_climb_push = 0.0
	_tree = tree
	var from_trunk: Vector3 = global_position - tree.base
	_climb_angle = atan2(from_trunk.x, from_trunk.z)
	_climb_along = _climb_bottom()
	_climb_side = 0.0
	climbing = true
	_hop(global_transform, _climb_transform(), 0.25, 0.15)


## Up and down climbs; left and right go round the trunk. At the bottom he hops
## off, and at the top of the home pine he climbs into the hollow.
func _climb_process(delta: float) -> void:
	var input := _move_input()
	sneaking = Input.is_action_pressed("sneak")
	var speed := climb_speed
	if sneaking:
		speed *= 0.5
	elif Input.is_action_pressed("run"):
		speed *= 1.6
	# The way round chosen when the key went down sticks while it's held, so he
	# keeps going the same way past the side of the trunk.
	if absf(input.x) < 0.1:
		_climb_side = 0.0
	elif _climb_side == 0.0:
		var tangent := Vector3(cos(_climb_angle), 0.0, -sin(_climb_angle))
		_climb_side = -1.0 if camera and tangent.dot(camera.global_basis.x) < 0.0 else 1.0
	var up_speed := -input.y * speed
	var round_speed := input.x * _climb_side * speed * 0.7

	var top := _climb_top()
	if _climb_along >= top and up_speed > 0.0 and _tree.has("rest_spot"):
		rest(_tree.rest_spot)
		return
	if _climb_along <= _climb_bottom() and up_speed < 0.0:
		_climb_off()
		return
	var reach := _climb_radius() + 0.3 * size
	var before := Vector2(_climb_along, _climb_angle * reach)
	_climb_along = clampf(_climb_along + up_speed * delta, _climb_bottom(), top)
	_climb_angle = wrapf(_climb_angle + round_speed * delta / reach, -PI, PI)
	global_transform = _climb_transform()
	_carry()

	var moved := Vector2(_climb_along, _climb_angle * reach) - before
	moved.y = wrapf(moved.y, -PI * reach, PI * reach)
	var climbed := moved.length() / maxf(delta, 0.0001)
	model.walk_amount = clampf(climbed / walk_speed, 0.0, 1.0)
	model.walk_phase += climbed * delta * 7.0 / size
	model.crouch = move_toward(model.crouch, 1.0 if sneaking else 0.0, delta * 5.0)
	# Going round, he bends toward where he's going.
	_turn = lerpf(_turn, clampf(-round_speed / climb_speed, -1.0, 1.0) * 0.6, 1.0 - exp(-8.0 * delta))
	model.turn = _turn


## Hops down from the trunk onto the ground behind him.
func _climb_off() -> void:
	_hop(global_transform, _ground_spot(_climb_angle), 0.3 + 0.12 * _climb_along, 0.15, _end_climb)


func _end_climb() -> void:
	climbing = false
	_shape.disabled = false


## Low enough that his tail just reaches the ground.
func _climb_bottom() -> float:
	return 0.75 * size


## High enough that his head is among the branches.
func _climb_top() -> float:
	return maxf(_tree.base.distance_to(_tree.top) - 0.12 * size, _climb_bottom())


func _climb_radius() -> float:
	var t := clampf(_climb_along / _tree.base.distance_to(_tree.top), 0.0, 1.0)
	return lerpf(_tree.r0, _tree.r1, t)


## Where he clings at the current height and angle: feet on the bark, facing up the trunk.
func _climb_transform() -> Transform3D:
	var base: Vector3 = _tree.base
	var axis: Vector3 = (_tree.top - base).normalized()
	var out := Vector3(sin(_climb_angle), 0.0, cos(_climb_angle))
	out = (out - axis * out.dot(axis)).normalized()
	return Transform3D(Basis(axis.cross(out), out, -axis), base + axis * _climb_along + out * _climb_radius())


## A spot on the ground beside the trunk at `angle`, facing away from it and clear
## of its collider.
func _ground_spot(angle: float) -> Transform3D:
	var out := Vector3(sin(angle), 0.0, cos(angle))
	return Transform3D(Basis.looking_at(out), _tree.base + out * (_tree.clear + 0.5 * size))


# --- Grabbing and chittering -----------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if resting or _hop_t >= 0.0:
		return
	if event.is_action_pressed("grab"):
		if held:
			_drop()
		elif climbing:
			_climb_off()
		else:
			_grab()
	elif event.is_action_pressed("chitter"):
		chitter()


## Shoves rigid bodies we walk into; pushing high up lets tall things topple.
func _push_bodies(delta: float) -> void:
	for i in get_slide_collision_count():
		var hit := get_slide_collision(i)
		var body := hit.get_collider() as RigidBody3D
		if body == null or body == held:
			continue
		var push := -hit.get_normal()
		push.y = 0.0
		var impulse := push.normalized() * _push_speed * delta * 1.5 * minf(body.mass, 2.0)
		body.apply_impulse(impulse, hit.get_position() - body.global_position + Vector3.UP * 0.2)


func _carry() -> void:
	if held == null:
		return
	var offset: Vector3 = held.get_meta("hold_offset", Vector3.ZERO)
	var rot: Vector3 = held.get_meta("hold_rotation", Vector3.ZERO)
	held.global_transform = model.mouth.global_transform * Transform3D(Basis.from_euler(rot), offset)


func _grab() -> void:
	var mouth := model.mouth.global_position
	var best: RigidBody3D = null
	var best_dist := grab_range
	for node in get_tree().get_nodes_in_group("grabbable"):
		var body := node as RigidBody3D
		if absf(body.global_position.y - mouth.y) > 0.9:
			continue
		var reach: float = body.get_meta("grab_radius", 0.1)
		var flat := Vector2(body.global_position.x - mouth.x, body.global_position.z - mouth.z)
		var d := flat.length() - reach
		if d < best_dist:
			best_dist = d
			best = body
	if best == null:
		return
	held = best
	held.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	held.freeze = true
	# A carried kinematic body would shove everything with infinite force, so it
	# stops colliding until it's dropped.
	held.set_meta("layers", Vector2i(held.collision_layer, held.collision_mask))
	held.collision_layer = 0
	held.collision_mask = 0


func _drop() -> void:
	var body := held
	held = null
	var layers: Vector2i = body.get_meta("layers")
	body.collision_layer = layers.x
	body.collision_mask = layers.y
	body.freeze = false
	# Toss it forward, or away from the trunk while climbing.
	var toss := global_basis.y if climbing else -global_basis.z
	body.linear_velocity = velocity + Vector3.UP * 0.4 + toss * 0.6
	# Ignore it briefly so it doesn't pop off our nose.
	add_collision_exception_with(body)
	get_tree().create_timer(0.4).timeout.connect(func(): remove_collision_exception_with(body))


func chitter() -> void:
	model.chitter_time = 0.45
	chittered.emit()
	_voice.play()
	var playback := _voice.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	# A burst of quick falling chirps with a bit of breathy noise.
	var rate := 22050.0
	var pitch := randf_range(0.85, 1.2)
	var frames := mini(int(rate * 0.45), playback.get_frames_available())
	var phase := 0.0
	for i in frames:
		var t := i / rate
		var chirp := fmod(t, 0.075) / 0.075
		var envelope := sin(PI * chirp) * (1.0 - t / 0.45)
		var freq := (1500.0 + 1600.0 * (1.0 - chirp)) * pitch
		phase += TAU * freq / rate
		var sample := (sin(phase) * 0.7 + randf_range(-0.3, 0.3)) * envelope * 0.4
		playback.push_frame(Vector2(sample, sample))
