extends CharacterBody3D
## Goose-game style controls: walk, run, sneak, jump, carry things in your mouth,
## chitter, and climb trees.

signal chittered
## A sound effect started; `id` is its asset ID (SOURCES.md). Counted by the level.
signal sound_started(id: String)

const RaccoonModel := preload("res://scripts/raccoon_model.gd")

## The author's generated sounds (CHANGE-BRIEF.md v2): two loops that play while he
## runs or climbs, and take A of the laugh for the chitter.
const RUN_LOOP := "res://assets/audio/sfx/run-loop.wav"
const CLIMB_LOOP := "res://assets/audio/sfx/climb-loop.wav"
const CHITTER_SOUND := "res://assets/audio/sfx/chitter.wav"
## Raised 4 dB on 6 Oct, after the author's playtest found the effects too quiet.
const RUN_DB := 6.0
const CLIMB_DB := 8.0
const CHITTER_DB := -4.0
## A loop keeps going this long after he stops, so a one-frame stumble doesn't
## restart it.
const LOOP_HOLD := 0.12
## Shooed off by a camper (startle): how far he leaps, trying the longest first, how
## long it takes and how high it goes.
const STARTLE_LEAPS := [1.6, 1.1, 0.7]
const STARTLE_TIME := 0.42
const STARTLE_HEIGHT := 0.35
## How fast he drops off in the hollow (sleep per second). He starts just before he
## lands there, so the sleep animation has blended in by the time he touches down.
const DOZE_RATE := 1.5
## Getting out of the hollow (see _leave_process), in seconds: waking, uncurling and
## turning to the opening; crouching to spring; in the air; soaking up the landing.
const LEAVE_WAKE := 0.35
const LEAVE_CROUCH := 0.15
const LEAVE_FLIGHT := 0.8
const LEAVE_LAND := 0.22
## How far he steps toward the opening before he leaps, and how high the leap rises
## above where he takes off.
const LEAVE_STEP := 0.3
const LEAVE_RISE := 0.35
## Points in the run animation's cycle he passes through in the air, against the
## share of the flight gone: paws gathered, the hind legs' push, the full stretch
## (held), then the front paws reaching down for the ground.
const LEAP_AIR := [[0.0, 0.95], [0.15, 1.15], [0.35, 1.38], [0.8, 1.43], [1.0, 1.5]]
## Where his front and hind paws are, ahead of and behind his middle (model scale 1).
## Tipping nose up he pivots on the hind paws, nose down on the front ones.
const PAW_REACH := 0.3
## His turning has weight: the turn rate builds up at TURN_ACCEL (rad/s²) and eases off
## at TURN_BRAKE as he comes round, so he neither snaps nor overshoots. Flat out he
## turns at RUN_TURN of turn_speed, so runs carve wider arcs.
const TURN_ACCEL := 40.0
const TURN_BRAKE := 70.0
const RUN_TURN := 0.7
## His velocity carries his weight too: its speed changes at ACCEL / DECEL (m/s²), and
## its direction swings round no faster than GRIP allows (sideways m/s²). His feet push
## him up to SLIP (radians) toward where he wants to go before he faces it.
const ACCEL := 10.0
const DECEL := 14.0
const GRIP := 30.0
const SLIP := 0.44
## Jumping (F). He takes off the moment it's pressed and rises JUMP_HEIGHT (m) under
## JUMP_GRAVITY, a snappier pull than the world's, then comes down under FALL_GRAVITY;
## let go of F on the way up and the pull is JUMP_CUT times stronger, so a tap is a
## small hop. A press up to JUMP_BUFFER (s) before he lands is kept until he does,
## and he can still jump JUMP_COYOTE (s) after stepping off an edge. In the air he has
## AIR_CONTROL of his turning and footing, and he soaks up a landing for LAND_TIME (s).
const JUMP_HEIGHT := 0.55
const JUMP_GRAVITY := 20.0
const FALL_GRAVITY := 28.0
const JUMP_CUT := 2.5
const JUMP_BUFFER := 0.12
const JUMP_COYOTE := 0.1
const AIR_CONTROL := 0.35
const LAND_TIME := 0.2
## Points in the run animation's cycle he passes through in a jump, against how far
## along he is from taking off (0) to coming down as fast as he went up (1): the hind
## legs' push, the full stretch at the top, the front paws reaching down for the ground.
const JUMP_AIR := [[0.0, 1.02], [0.25, 1.2], [0.5, 1.38], [1.0, 1.48]]

@export var walk_speed := 2.0
@export var run_speed := 4.0
@export var sneak_speed := 1.0
@export var climb_speed := 1.2
## Fastest he turns standing or walking (rad/s).
@export var turn_speed := 10.0
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
## True while curled up in the hollow, including the hop in and the leap out.
var resting := false
## Set while the title screen is up: asleep in the hollow, a move key doesn't wake him
## (the menu uses W, S and the arrows).
var keep_asleep := false
## True while on a tree trunk, including the hops on and off.
var climbing := false
## True while he runs on the ground: Shift held, not sneaking, faster than a walk.
var running := false
## True while he moves on a trunk.
var climb_moving := false
## True from a jump's takeoff until he lands, and the height he took off from (the
## camera stays at it meanwhile).
var jumping := false
var jump_from_y := 0.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _push_speed := 0.0
var _speed := 0.0
var _turn := 0.0
## How fast he's turning on the ground (rad/s, positive = left).
var _yaw_rate := 0.0
var _voice: AudioStreamPlayer
var _run_sfx: AudioStreamPlayer
var _climb_sfx: AudioStreamPlayer
## How long each loop's condition has been false, for LOOP_HOLD.
var _quiet := {}
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
## Where he lies in the hollow and where he lands when he leaps out.
var _rest_spot: Transform3D
var _rest_exit: Transform3D
## Seconds since he woke and started getting out of the hollow; -1 when he isn't.
var _leave_t := -1.0
## The trunk he's climbing, how far up it he is (metres along it) and where round
## it (radians, 0 on its +Z side).
var _tree: Dictionary
var _climb_along := 0.0
var _climb_angle := 0.0
## Which way round the trunk the held left/right key goes: 1 or -1, 0 when neither is held.
var _climb_side := 0.0
## How long he's been pushing into a trunk.
var _climb_push := 0.0
## A jump press waiting to be used (seconds it has left), and how long he can still
## jump since he was last on the ground.
var _jump_press := 0.0
var _coyote := 0.0
## Seconds since a jump's takeoff; seconds into soaking up its landing (-1 when he
## isn't), how hard that landing was (0..1) and how far he was tipped as he touched down.
var _air_t := 0.0
var _land_t := -1.0
var _land_hard := 0.0
var _land_pitch := 0.0


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

	_voice = _sound(CHITTER_SOUND, CHITTER_DB)
	_run_sfx = _sound(RUN_LOOP, RUN_DB)
	_climb_sfx = _sound(CLIMB_LOOP, CLIMB_DB)


## A player for one sound effect on the effects bus. If the sound hasn't been
## imported yet, the player stays silent.
func _sound(path: String, db: float) -> AudioStreamPlayer:
	var sfx := AudioStreamPlayer.new()
	sfx.bus = "SFX"
	sfx.volume_db = db
	if ResourceLoader.exists(path):
		sfx.stream = load(path)
	else:
		push_warning("This sound isn't imported yet: %s" % path)
	add_child(sfx)
	return sfx


func _physics_process(delta: float) -> void:
	running = false
	climb_moving = false
	model.hopping = _hop_t >= 0.0
	model.climbing = climbing
	# Only walking sets these.
	model.yaw_rate = 0.0
	model.look = 0.0
	model.accel = 0.0
	if _hop_t >= 0.0:
		_hop_process(delta)
	elif resting:
		_rest_process(delta)
	elif climbing:
		_climb_process(delta)
	else:
		_walk_process(delta)
	# After walking, which may have just taken off, so the model knows it the same tick.
	model.jumping = jumping or _land_t >= 0.0
	_loop(_run_sfx, running, "SFX-RUN", delta)
	_loop(_climb_sfx, climb_moving, "SFX-CLIMB", delta)


## Starts a loop when its condition turns true and stops it once it has been false
## for LOOP_HOLD. A held key keeps the one loop going; it never stacks.
func _loop(sfx: AudioStreamPlayer, on: bool, id: String, delta: float) -> void:
	_quiet[id] = 0.0 if on else _quiet.get(id, 0.0) + delta
	if sfx.stream == null:
		return
	if on and not sfx.playing:
		sfx.play()
		sound_started.emit(id)
	elif not on and sfx.playing and _quiet[id] >= LOOP_HOLD:
		sfx.stop()


func is_hopping() -> bool:
	return _hop_t >= 0.0 or _leave_t >= 0.0


## True from when he starts curling up in the hollow until he wakes.
func is_napping() -> bool:
	return resting and not _waking and model.sleep > 0.0


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

	# Turn toward the input with weight: the turn rate builds up toward what it takes
	# to face it, and brakes in time to finish facing it. In the air he has less to
	# push against, so he turns less and keeps his momentum.
	var has_input := dir.length_squared() > 0.01
	var control := AIR_CONTROL if jumping else 1.0
	var want := 0.0
	var target_rate := 0.0
	if has_input:
		want = wrapf(atan2(-dir.x, -dir.z) - rotation.y, -PI, PI)
		# Asked to go nearly straight back, he keeps turning the way he already is.
		if absf(want) > 2.6 and _yaw_rate * want < 0.0:
			want -= signf(want) * TAU
		var top := turn_speed * lerpf(1.0, RUN_TURN, clampf(_speed / run_speed, 0.0, 1.0)) * control
		var braking := minf(sqrt(1.6 * TURN_BRAKE * absf(want)), 12.0 * absf(want))
		target_rate = signf(want) * minf(top, braking)
	var building := absf(target_rate) > absf(_yaw_rate) and target_rate * _yaw_rate >= 0.0
	_yaw_rate = move_toward(_yaw_rate, target_rate, (TURN_ACCEL if building else TURN_BRAKE) * control * delta)
	rotation.y = wrapf(rotation.y + _yaw_rate * delta, -PI, PI)
	var forward := -global_basis.z

	# Then travel with momentum, mostly the way he faces: slower while facing away
	# from where he wants to go, so U-turns become arcs, and his heading swings
	# round after his body rather than snapping to it.
	var planar := Vector3(velocity.x, 0.0, velocity.z)
	var moving := planar.length()
	var heading := planar / moving if moving > 0.05 else forward
	var target_speed := 0.0
	if has_input:
		var travel := forward.rotated(Vector3.UP, clampf(want, -SLIP, SLIP))
		target_speed = speed * dir.length() * lerpf(0.35, 1.0, (1.0 + forward.dot(dir.normalized())) * 0.5)
		if moving <= 0.05:
			heading = travel
		else:
			var most := GRIP * control / maxf(moving, 0.5) * delta
			heading = heading.rotated(Vector3.UP, clampf(heading.signed_angle_to(travel, Vector3.UP), -most, most))
	elif jumping:
		target_speed = moving
	var before := moving
	moving = move_toward(moving, target_speed, (ACCEL if target_speed > moving else DECEL) * control * delta)
	_speed = moving
	running = not sneaking and Input.is_action_pressed("run") and _speed > walk_speed + 0.1 and not jumping
	velocity.x = heading.x * moving
	velocity.z = heading.z * moving

	# Jumping: off at once (or as soon as he can, for a press just before he lands),
	# up under a snappy pull that's stronger still if F is let go, down faster still.
	_jump_press = maxf(_jump_press - delta, 0.0)
	_coyote = JUMP_COYOTE if is_on_floor() and not jumping else maxf(_coyote - delta, 0.0)
	if _jump_press > 0.0 and _coyote > 0.0:
		_jump_press = 0.0
		_coyote = 0.0
		jumping = true
		jump_from_y = global_position.y
		_air_t = 0.0
		_land_t = -1.0
		velocity.y = sqrt(2.0 * JUMP_GRAVITY * JUMP_HEIGHT)
	if jumping:
		var pull := JUMP_GRAVITY if velocity.y > 0.0 else FALL_GRAVITY
		if velocity.y > 0.0 and not Input.is_action_pressed("jump"):
			pull *= JUMP_CUT
		velocity.y -= pull * delta
	elif not is_on_floor():
		velocity.y -= _gravity * delta
	var rising := velocity.y

	# For the body: how hard he's turning, where he's looking to go, how he's speeding up.
	model.turn = clampf(_yaw_rate / 6.0, -1.0, 1.0)
	model.yaw_rate = _yaw_rate
	model.look = want
	model.accel = (moving - before) / maxf(delta, 0.0001)

	move_and_slide()
	_push_bodies(delta)
	_carry()
	_jump_pose(delta, rising)

	var ground_speed := Vector2(velocity.x, velocity.z).length()
	model.speed = ground_speed
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


## Jumps: now if he's on the ground, or as soon as he lands (see JUMP_BUFFER).
func jump() -> void:
	_jump_press = JUMP_BUFFER


## Lands a jump once he's back down, and poses him through it. Leaving, his hind legs
## push off and he squashes for a moment; at the top he's stretched out; he tips nose
## up on the way up and nose down coming down. Landed, his front paws take it, he
## squashes as hard as he came down and his hind legs come in, and then he's back in
## his own stride. `rising` is how fast he was going up (m/s) before this tick's move.
func _jump_pose(delta: float, rising: float) -> void:
	var lift := sqrt(2.0 * JUMP_GRAVITY * JUMP_HEIGHT)
	if jumping and _air_t > 0.0 and rising <= 0.0 and is_on_floor():
		jumping = false
		_land_t = 0.0
		_land_hard = clampf(-rising / lift, 0.3, 1.0)
		_land_pitch = model.pitch
	if jumping:
		_air_t += delta
		model.leap = _keyed(JUMP_AIR, clampf((1.0 - velocity.y / lift) * 0.5, 0.0, 1.0))
		model.squash = 0.5 * maxf(0.0, 1.0 - _air_t / 0.1)
		var tip := clampf(atan2(velocity.y, maxf(_speed, 1.5)) * 0.35, -0.35, 0.3)
		model.pitch = tip * smoothstep(0.0, 0.08, _air_t)
	elif _land_t >= 0.0:
		_land_t += delta
		var f := minf(_land_t / LAND_TIME, 1.0)
		model.leap = lerpf(1.48, 1.78, f)
		model.squash = 0.8 * _land_hard * sin(PI * sqrt(f))
		model.pitch = _land_pitch * (1.0 - smoothstep(0.0, 0.6, f))
		if f >= 1.0:
			_end_jump()


## Out of a jump's poses, landed or not.
func _end_jump() -> void:
	jumping = false
	_land_t = -1.0
	model.leap = -1.0
	model.squash = 0.0
	model.pitch = 0.0


## Puts him straight at `pos` with whatever he's carrying, for the tests. He's drawn
## between physics ticks, so this resets that, or he'd be drawn sliding there.
func place(pos: Vector3) -> void:
	global_position = pos
	_carry()
	reset_physics_interpolation()
	if held:
		held.reset_physics_interpolation()


## Hops up to `spot` (the hollow in the home pine) and curls up there to sleep.
## A move key wakes him and he leaps out, landing on `exit`.
func rest(spot: Transform3D, exit: Transform3D) -> void:
	if resting:
		return
	if held:
		_drop()
	var from_trunk := climbing
	_rest_spot = spot
	_rest_exit = exit
	climbing = false
	resting = true
	_waking = false
	_hop(global_transform, spot, 0.5 if from_trunk else 0.8, 0.25 if from_trunk else 0.9)


## Puts him straight into `spot` in the hollow, already curled up asleep, as the title
## screen leaves him when the game starts. A move key wakes him and he leaps out to
## `exit`, as after any nap.
func start_asleep(spot: Transform3D, exit: Transform3D) -> void:
	_rest_spot = spot
	_rest_exit = exit
	resting = true
	_waking = false
	_shape.disabled = true
	velocity = Vector3.ZERO
	global_transform = spot
	model.sleep = 1.0
	reset_physics_interpolation()


## Moves him from one transform to another along an arc `height` high, turning as
## he goes, then calls `done`. Collisions are off meanwhile.
## Shooed by one of the campers standing at `from` (camp_person.gd): he drops what he's
## carrying and leaps away from them, as far as STARTLE_LEAPS allows without landing
## in anything. Not while he's up a tree, in the hollow or already in the air.
func startle(from: Vector3) -> void:
	if resting or climbing or is_hopping():
		return
	if held:
		_drop()
	var away := global_position - from
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else global_basis.z
	var facing := Basis(Vector3.UP, atan2(-away.x, -away.z))
	var space := get_world_3d().direct_space_state
	var probe := PhysicsShapeQueryParameters3D.new()
	var ball := SphereShape3D.new()
	ball.radius = 0.25
	probe.shape = ball
	probe.exclude = [get_rid()]
	for far: float in STARTLE_LEAPS:
		var land := global_position + away * far
		probe.transform = Transform3D(Basis(), land + Vector3.UP * 0.3)
		if space.intersect_shape(probe, 1).is_empty():
			_hop(global_transform, Transform3D(facing, land), STARTLE_TIME, STARTLE_HEIGHT, _end_startle)
			return


func _end_startle() -> void:
	_shape.disabled = false


func _hop(from: Transform3D, to: Transform3D, time := 0.8, height := 0.9, done := Callable()) -> void:
	# Tidied into pure turns: one whose axes have drifted a hair apart in length is no
	# rotation to Basis.slerp (_hop_process), which then fails and logs an error on every
	# frame of the hop, as it did 116 and 120 times in the author's plays on 26 Oct 2026.
	_hop_from = from.orthonormalized()
	_hop_to = to.orthonormalized()
	_hop_t = 0.0
	_hop_time = time
	_hop_height = height
	_hop_done = done
	_shape.disabled = true
	velocity = Vector3.ZERO
	_speed = 0.0
	_yaw_rate = 0.0
	if jumping or _land_t >= 0.0:
		_end_jump()


func _hop_process(delta: float) -> void:
	model.speed = 0.0
	model.walk_amount = 0.0
	model.turn = 0.0
	model.crouch = move_toward(model.crouch, 0.0, delta * 5.0)
	_hop_t = minf(_hop_t + delta / _hop_time, 1.0)
	if resting and not _waking and (1.0 - _hop_t) * _hop_time <= RaccoonModel.RIGGED_BLEND:
		model.sleep = move_toward(model.sleep, 1.0, delta * DOZE_RATE)
	var pos := _hop_from.origin.lerp(_hop_to.origin, _hop_t) + Vector3.UP * sin(PI * _hop_t) * _hop_height
	global_transform = Transform3D(_hop_from.basis.slerp(_hop_to.basis, minf(_hop_t * 1.5, 1.0)), pos)
	_carry()
	if _hop_t >= 1.0:
		_hop_t = -1.0
		if _hop_done.is_valid():
			_hop_done.call()


func _rest_process(delta: float) -> void:
	model.speed = 0.0
	model.walk_amount = 0.0
	model.turn = 0.0
	if not _waking:
		model.sleep = move_toward(model.sleep, 1.0, delta * DOZE_RATE)
		_waking = not keep_asleep and model.sleep >= 1.0 and _move_input().length_squared() > 0.1
		if _waking:
			_leave_t = 0.0
		return
	_leave_process(delta)


## Getting out of the hollow, as one movement: he wakes, uncurls and turns to the
## opening as he steps up to it, crouches, leaps out and falls in an arc to `exit`,
## lands front paws first and soaks it up, then he's the player's again.
func _leave_process(delta: float) -> void:
	_leave_t += delta
	var exit := _rest_exit
	var out := exit.origin - _rest_spot.origin
	out.y = 0.0
	out = out.normalized()
	var takeoff := _rest_spot.origin + out * LEAVE_STEP
	var t := _leave_t
	if t < LEAVE_WAKE:
		var f := t / LEAVE_WAKE
		var e := smoothstep(0.0, 1.0, f)
		model.sleep = 1.0 - f
		model.leap = lerpf(0.8, 0.88, f)
		global_transform = Transform3D(_rest_spot.basis.slerp(exit.basis, e), _rest_spot.origin.lerp(takeoff, e))
		return
	model.sleep = 0.0
	t -= LEAVE_WAKE
	if t < LEAVE_CROUCH:
		var f := t / LEAVE_CROUCH
		model.leap = lerpf(0.88, 0.95, f)
		model.squash = 0.6 * smoothstep(0.0, 1.0, f)
		global_transform = Transform3D(exit.basis, takeoff)
		return
	t -= LEAVE_CROUCH
	if t < LEAVE_FLIGHT:
		var f := t / LEAVE_FLIGHT
		model.leap = _keyed(LEAP_AIR, f)
		model.squash = 0.6 * (1.0 - smoothstep(0.0, 0.12, f))
		var arc := _leap_arc(takeoff, exit.origin, t)
		global_transform = _pitched(Transform3D(exit.basis, arc[0]), arc[1])
		return
	t -= LEAVE_FLIGHT
	# Landed: he slides to a stop as he levels out and his hind legs come in.
	var ground_speed := Vector2(exit.origin.x - takeoff.x, exit.origin.z - takeoff.z).length() / LEAVE_FLIGHT
	var f := minf(t / LEAVE_LAND, 1.0)
	var pos := exit.origin + out * ground_speed * LEAVE_LAND * (f - f * f * 0.5)
	var pitch: float = _leap_arc(takeoff, exit.origin, LEAVE_FLIGHT)[1]
	model.leap = lerpf(1.5, 1.78, f)
	model.squash = 0.8 * sin(PI * sqrt(f))
	global_transform = _pitched(Transform3D(exit.basis, pos), pitch * (1.0 - smoothstep(0.0, 0.6, f)))
	if f >= 1.0:
		_leave_t = -1.0
		model.leap = -1.0
		model.squash = 0.0
		_end_rest()


## Where he is `t` seconds into the leap from `from` to `to`, and how far he's
## tipped (radians, nose up), as [position, pitch]. He falls under a gravity that
## takes him LEAVE_RISE above `from` and lands him on `to` after LEAVE_FLIGHT; he
## tips into the way he's moving, easing in as he leaves.
func _leap_arc(from: Vector3, to: Vector3, t: float) -> Array:
	var drop := from.y - to.y
	var g := pow((sqrt(2.0 * LEAVE_RISE) + sqrt(2.0 * (LEAVE_RISE + drop))) / LEAVE_FLIGHT, 2.0)
	var rise_speed := sqrt(2.0 * g * LEAVE_RISE)
	var pos := from.lerp(to, t / LEAVE_FLIGHT)
	pos.y = from.y + rise_speed * t - 0.5 * g * t * t
	var ground_speed := Vector2(to.x - from.x, to.z - from.z).length() / LEAVE_FLIGHT
	var pitch := clampf(atan2(rise_speed - g * t, ground_speed) * 0.4, -0.5, 0.35)
	return [pos, pitch * smoothstep(0.0, 0.15, t / LEAVE_FLIGHT)]


## `xf` tipped nose up by `pitch` (radians) on his hind paws, or nose down on his
## front ones, so the paws he's tipping on stay put.
func _pitched(xf: Transform3D, pitch: float) -> Transform3D:
	var pivot := Vector3(0, 0, PAW_REACH * size * (1.0 if pitch > 0.0 else -1.0))
	var tip := Transform3D(Basis(Vector3.RIGHT, pitch), Vector3.ZERO)
	return xf * Transform3D(Basis(), pivot) * tip * Transform3D(Basis(), -pivot)


## The value at `f` along a list of [f, value] keys, straight between them.
func _keyed(keys: Array, f: float) -> float:
	for i in range(1, keys.size()):
		if f <= keys[i][0]:
			return lerpf(keys[i - 1][1], keys[i][1], inverse_lerp(keys[i - 1][0], keys[i][0], f))
	return keys[-1][1]


func _end_rest() -> void:
	resting = false
	_waking = false
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
		rest(_tree.rest_spot, _tree.rest_exit)
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
	climb_moving = climbed > 0.05
	model.speed = climbed
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
	elif event.is_action_pressed("jump"):
		# Up a tree, a jump hops him off, as E does.
		if climbing:
			_climb_off()
		else:
			jump()


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
	# Straight into his mouth, rather than drawn flying there over a physics tick.
	_carry()
	held.reset_physics_interpolation()


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


## Plays the laugh. Pressing again while it plays restarts it rather than
## stacking a second copy.
func chitter() -> void:
	model.chitter_time = 0.45
	chittered.emit()
	if _voice.stream:
		_voice.play()
		sound_started.emit("SFX-CHITTER")
