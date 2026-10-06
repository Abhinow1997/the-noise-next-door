extends CharacterBody3D
## Goose-game style controls: walk, run, sneak, carry things in your mouth, chitter.

signal chittered

const RaccoonModel := preload("res://scripts/raccoon_model.gd")

@export var walk_speed := 2.0
@export var run_speed := 4.0
@export var sneak_speed := 1.0
@export var turn_speed := 9.0
## Overall scale of the raccoon and its collider.
@export var size := 0.8
@export var grab_range := 0.55

## Set by the level so movement follows the camera's facing.
var camera: Camera3D
var model: RaccoonModel
var held: RigidBody3D
var sneaking := false
## True while curled up in the hollow, including the hops in and out.
var resting := false

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _push_speed := 0.0
var _speed := 0.0
var _turn := 0.0
var _voice: AudioStreamPlayer
var _shape: CollisionShape3D
var _hop_from: Transform3D
var _hop_to: Transform3D
## 0..1 through a hop into or out of the hollow; -1 when not hopping.
var _hop_t := -1.0
var _waking := false
## Where he hopped up from, to land there again.
var _rest_return: Transform3D


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
	if resting:
		_rest_process(delta)
		return
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
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


## Hops up to `spot` (the hollow in the home pine) and curls up there to sleep.
## A move key wakes him and he hops back down.
func rest(spot: Transform3D) -> void:
	if resting:
		return
	if held:
		_drop()
	resting = true
	_waking = false
	_rest_return = global_transform
	_hop(global_transform, spot)


func _hop(from: Transform3D, to: Transform3D) -> void:
	_hop_from = from
	_hop_to = to
	_hop_t = 0.0
	_shape.disabled = true
	velocity = Vector3.ZERO
	_speed = 0.0


func _rest_process(delta: float) -> void:
	model.walk_amount = 0.0
	model.turn = 0.0
	model.crouch = move_toward(model.crouch, 0.0, delta * 5.0)
	if _hop_t >= 0.0:
		_hop_t = minf(_hop_t + delta / 0.8, 1.0)
		var pos := _hop_from.origin.lerp(_hop_to.origin, _hop_t) + Vector3.UP * sin(PI * _hop_t) * 0.9
		global_transform = Transform3D(_hop_from.basis.slerp(_hop_to.basis, minf(_hop_t * 1.5, 1.0)), pos)
		if _hop_t >= 1.0:
			_hop_t = -1.0
			if _waking:
				_waking = false
				resting = false
				_shape.disabled = false
		return
	if not _waking:
		model.sleep = move_toward(model.sleep, 1.0, delta * 1.5)
		var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		_waking = model.sleep >= 1.0 and input.length_squared() > 0.1
		return
	model.sleep = move_toward(model.sleep, 0.0, delta * 3.0)
	if model.sleep <= 0.0:
		_hop(global_transform, _rest_return)


func _unhandled_input(event: InputEvent) -> void:
	if resting:
		return
	if event.is_action_pressed("grab"):
		if held:
			_drop()
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
	body.linear_velocity = velocity + Vector3.UP * 0.4 - global_basis.z * 0.6
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
