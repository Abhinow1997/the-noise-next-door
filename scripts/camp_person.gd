extends CharacterBody3D
## One of the people at level 1's campsite (campsite.gd), and how they take to the
## raccoon. Asked for on 23 Oct 2026: "when the raccoon comes close and is visible to
## them they should be scraed initially but then if it lingers around the camp the guys
## start to chasing it away and girl is always scared guys trying to protect them".
##   - Calm, each sees him in a cone in front of them (vision_cone.gd, drawn on the
##     ground) out to SIGHT metres, nearer while he sneaks. A chitter or his running
##     close by gets heard. When one takes fright, the others catch it a moment later.
##   - Spotting him, they flinch (`scared`).
##   - The girl is always scared: she hurries behind her protector (the low-poly man)
##     and cowers there (`cower`), runs further off if he comes near her, and only goes
##     back to dancing once he's been gone a while.
##   - The men stand guard (`guard`), facing him; the protector puts himself between the
##     raccoon and the girl. If he lingers in the camp for LINGER seconds, they chase him
##     (`run`), slower than he runs but faster than he walks. One who gets to him stamps
##     and shoos (`shoo`): he drops what he's carrying and leaps away (player.gd
##     startle). Up a tree, they shoo at the foot of it a while, then give up.
##   - Once he's out of the camp or out of sight a while, they walk back (`walk`), calm
##     down and go back to what they were doing.
## The camp (campsite.gd) keeps what they know between them: where and when he was last
## seen, the camp's bounds, and when someone last took fright.

signal state_changed(state: int)

const VisionCone := preload("res://scripts/vision_cone.gd")
const Player := preload("res://scripts/player.gd")

enum State { WORK, STARTLED, GUARD, CHASE, SHOO, RETURN, FLEE, COWER }

## How far they see while calm (times SNEAK_SIGHT while he sneaks) and once alarmed,
## and how wide; where their eyes are.
const SIGHT := 7.0
const SNEAK_SIGHT := 0.55
const ALERT_SIGHT := 14.0
const SIGHT_ANGLE := 110.0
const EYES := Vector3(0, 1.55, 0.12)
## His running this near them is heard (campsite.gd hears his chitters).
const HEAR_RUN := 4.0
## How long the flinch lasts, and how long the others take to catch the fright.
const FLINCH := 1.1
const CATCH_FRIGHT := Vector2(0.25, 0.6)
## Lingering in the camp this long, in sight, sets the men chasing.
const LINGER := 4.0
## How close a chaser has to get to shoo him, and how long a shoo lasts, or the shooing
## at the foot of a tree before they give up.
const REACH := 1.0
const SHOO_TIME := 1.1
const TREED_TIME := 4.0
## Out of sight this long, they stop chasing. Out of sight this long, or out of the camp
## for AWAY, they calm down and go back; the girl takes longer.
const LOSE := 2.5
const CALM := 4.0
const GIRL_CALM := 6.0
const AWAY := 1.5
## How near he may come to the girl while she cowers before she runs off again, how far
## behind her protector she hides, and how far from her toward him the protector stands.
const TOO_NEAR := 2.5
const HIDE_BEHIND := 1.1
const SHIELD := 1.2
## Chasing, each man heads this far to one side of him until he's near, so the two
## come at him from either side rather than in a line.
const FLANK := 0.8
## Turning (rad/s), walking and fleeing (m/s).
const TURN := 6.0
const WALK := 1.1
const FLEE_SPEED := 2.4

## Set before it's added (campsite.gd).
var role := "guy"
var work_clip := ""
var work_speed := 1.0
## Where they work and which way they face there.
var post: Transform3D
## Their walk's and run's own speeds at 1x (m/s), and how fast they chase.
var walk_natural := 1.0
var run_natural := 3.3
var chase_speed := 3.0
## Which side of him they come at him from while chasing (+1 or -1).
var flank_side := 1.0
var camp
var model: Node3D
## The girl's protector, and whom a protector protects.
var protector
var protects

var state := State.WORK
var player: Player
var anim: AnimationPlayer
var eyes: VisionCone
## The way to where they're going, round things (campsite.gd bakes where they can
## walk): its points, the next one, where it goes, and how old it is.
var _path := PackedVector3Array()
var _path_i := 0
var _path_to := Vector3.INF
var _path_age := 0.0

var _t := 0.0
var _linger := 0.0
var _away := 0.0
var _fright_seen := -INF
var _fright_at := INF
var _goal := Vector3.ZERO
var _treed := false
var _stuck := 0.0
var _side := 0.0
var _side_left := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	_rng.seed = hash(name)
	var players := find_children("*", "AnimationPlayer", true, false)
	anim = null if players.is_empty() else players[0]
	eyes = VisionCone.new()
	eyes.reach = SIGHT
	eyes.angle = SIGHT_ANGLE
	eyes.position = EYES
	# The cone looks along its -Z; they face +Z.
	eyes.rotation.y = PI
	eyes.ignore.append(get_rid())
	add_child(eyes)
	_play(work_clip, work_speed, 0.0)


func _physics_process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Player
		if player == null:
			return
	_t += delta
	var calm := state == State.WORK or state == State.RETURN
	eyes.reach = SIGHT * (SNEAK_SIGHT if player.sneaking else 1.0) if calm else ALERT_SIGHT
	eyes.show_on_ground(calm)
	if eyes.seeing:
		camp.saw(player.global_position)
	_away = _away + delta if not camp.in_camp(camp.last_seen_at, 3.0) else 0.0
	velocity = Vector3.ZERO
	match state:
		State.WORK:
			_work()
		State.STARTLED:
			_play("scared", 1.0, 0.15)
			_face(camp.last_seen_at, delta)
			if _t >= FLINCH:
				_to_state(State.FLEE if role == "girl" else State.GUARD)
		State.GUARD:
			_guard(delta)
		State.CHASE:
			_chase(delta)
		State.SHOO:
			_play("shoo")
			_face(player.global_position, delta)
			if _t >= (TREED_TIME if _treed else SHOO_TIME):
				if _treed:
					# They give up on him up there, and let him be while he stays.
					camp.gave_up_on_tree = true
					_to_state(State.RETURN)
				elif camp.seen_within(0.5) and camp.in_camp(player.global_position):
					_to_state(State.CHASE)
				else:
					_to_state(State.RETURN)
		State.RETURN:
			_return(delta)
		State.FLEE:
			_go(_goal, FLEE_SPEED, delta, "run", FLEE_SPEED / run_natural)
			if _flat(_goal - global_position).length() < 0.3 or _t > 4.0:
				_to_state(State.COWER)
		State.COWER:
			_play("cower")
			_face(camp.last_seen_at, delta)
			if camp.seen_within(0.5) and _flat(player.global_position - global_position).length() < TOO_NEAR:
				_to_state(State.FLEE)
			elif _gone(GIRL_CALM):
				_to_state(State.RETURN)
	var meant := velocity.length()
	move_and_slide()
	# Walking into something, step round it for a moment.
	_side_left -= delta
	if _side_left <= 0.0:
		_side = 0.0
	if meant > 0.3 and get_real_velocity().length() < meant * 0.3:
		_stuck += delta
		if _stuck > 0.4:
			_side = 1.0 if _rng.randf() < 0.5 else -1.0
			_side_left = 0.8
			_stuck = 0.0
	else:
		_stuck = maxf(_stuck - delta, 0.0)


## Hears him (his chitter, or his running near): as good as seeing him.
func hear() -> void:
	if (state == State.WORK or state == State.RETURN) and not camp.let_be():
		camp.saw(player.global_position)
		_startle()


func _work() -> void:
	_play(work_clip, work_speed)
	rotation.y = rotate_toward(rotation.y, post.basis.get_euler().y, TURN * get_physics_process_delta_time())
	if eyes.seeing and not camp.let_be():
		_startle()
	elif player.running and _flat(player.global_position - global_position).length() < HEAR_RUN:
		hear()
	elif camp.frightened > _fright_seen and camp.clock - camp.frightened < 1.0:
		# Someone else has just taken fright: so do they, a moment later.
		_fright_seen = camp.frightened
		_fright_at = camp.clock + _rng.randf_range(CATCH_FRIGHT.x, CATCH_FRIGHT.y)
	elif camp.clock >= _fright_at:
		_startle()


func _startle() -> void:
	_fright_at = INF
	_fright_seen = camp.clock
	camp.frighten()
	_to_state(State.STARTLED)


func _guard(delta: float) -> void:
	var spot := global_position
	if protects and protects.state in [State.FLEE, State.COWER]:
		var girl: Vector3 = protects.global_position
		var toward := _flat(camp.last_seen_at - girl)
		if toward.length() > 0.1:
			spot = _clear_near(girl, toward.normalized(), [SHIELD, SHIELD * 0.75, SHIELD * 1.3], spot)
	if _flat(spot - global_position).length() > 0.35:
		_go(spot, WALK * 1.4, delta, "walk", WALK * 1.4 / walk_natural)
	else:
		_play("guard")
		_face(camp.last_seen_at, delta)
	if camp.seen_within(1.5) and camp.in_camp(camp.last_seen_at):
		_linger += delta
	if _linger >= LINGER:
		_to_state(State.CHASE)
	elif _gone(CALM) or camp.let_be():
		_to_state(State.RETURN)


func _chase(delta: float) -> void:
	var him := player.global_position
	var target: Vector3 = him if camp.seen_within(0.5) else camp.last_seen_at
	if camp.let_be():
		_to_state(State.RETURN)
		return
	if player.climbing:
		# Up a tree: they go to the foot of it and shoo up at him, then give up.
		if _flat(him - global_position).length() < 1.3:
			_treed = true
			_to_state(State.SHOO)
			return
	elif _flat(him - global_position).length() < REACH and not player.is_hopping() and not player.resting:
		player.startle(global_position)
		_treed = false
		_to_state(State.SHOO)
		return
	if not camp.in_camp(him, 3.0):
		# Out of the camp: they stop and shoo after him.
		_treed = false
		_to_state(State.SHOO)
		return
	if not camp.seen_within(LOSE):
		_to_state(State.RETURN)
		return
	var toward := _flat(target - global_position)
	if toward.length() > 2.0:
		target += toward.normalized().cross(Vector3.UP) * FLANK * flank_side
	_go(target, chase_speed, delta, "run", chase_speed / run_natural)


func _return(delta: float) -> void:
	if _t > 0.5 and camp.seen_within(0.3) and camp.in_camp(camp.last_seen_at) and not camp.let_be():
		# He's back while they're still wary: no flinch this time.
		_to_state(State.FLEE if role == "girl" else State.GUARD)
		return
	if _flat(post.origin - global_position).length() > 0.15:
		_go(post.origin, WALK, delta, "walk", WALK / walk_natural)
		return
	var yaw := post.basis.get_euler().y
	rotation.y = rotate_toward(rotation.y, yaw, TURN * delta)
	_play(work_clip, work_speed)
	if absf(angle_difference(rotation.y, yaw)) < 0.05:
		global_position = post.origin
		_to_state(State.WORK)


func _to_state(to: State) -> void:
	if to == State.GUARD and state == State.STARTLED:
		_linger = 0.0
	if to == State.FLEE:
		_goal = _hiding_place()
	if to == State.WORK:
		# Calm: frights from before don't count.
		_fright_seen = camp.frightened
	state = to
	_t = 0.0
	state_changed.emit(to)


## Behind her protector, away from the raccoon, if he's near and standing his ground;
## otherwise a few steps away from the raccoon. Wherever there's room to stand.
func _hiding_place() -> Vector3:
	var threat: Vector3 = camp.last_seen_at
	if protector and protector.state in [State.STARTLED, State.GUARD] \
			and _flat(protector.global_position - global_position).length() < 6.0:
		var p: Vector3 = protector.global_position
		var away := _flat(p - threat)
		if away.length() > 0.1:
			return _clear_near(p, away.normalized(), [HIDE_BEHIND, HIDE_BEHIND * 1.5], global_position)
	var off := _flat(global_position - threat)
	if off.length() < 0.1:
		off = -global_basis.z
	return _clear_near(global_position, off.normalized(), [2.5, 1.5], global_position)


## The first spot with room to stand `far` metres from `from` along `dir`, or turned a
## little either side of it; `otherwise` if there's none.
func _clear_near(from: Vector3, dir: Vector3, far: Array, otherwise: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	var probe := PhysicsShapeQueryParameters3D.new()
	var ball := SphereShape3D.new()
	ball.radius = 0.32
	probe.shape = ball
	probe.exclude = [get_rid(), player.get_rid()]
	for turn: float in [0.0, 30.0, -30.0, 60.0, -60.0]:
		for d: float in far:
			var at := from + dir.rotated(Vector3.UP, deg_to_rad(turn)) * d
			probe.transform = Transform3D(Basis(), at + Vector3.UP * 0.7)
			if space.intersect_shape(probe, 1).is_empty():
				return at
	return otherwise


## True once he's been out of sight `calm` seconds, or out of the camp a while.
func _gone(calm: float) -> bool:
	return not camp.seen_within(calm) or _away > AWAY


## Heads for `to` at `speed`, round whatever's in the way, playing `clip` at `rate`,
## facing the way they go.
func _go(to: Vector3, speed: float, delta: float, clip: String, rate: float) -> void:
	var left := _flat(to - global_position).length()
	if left < 0.05:
		return
	# The way there, worked out again when where they're going moves, or now and then.
	_path_age += delta
	if _flat(to - _path_to).length() > 0.3 or _path_age > 0.5:
		_path = NavigationServer3D.map_get_path(get_world_3d().navigation_map, global_position, to, true)
		_path_to = to
		_path_i = 0
		_path_age = 0.0
	# Its points are on the walkways, a little above the ground: they're reached on the ground.
	while _path_i < _path.size() and _flat(_path[_path_i] - global_position).length() < 0.35:
		_path_i += 1
	var next: Vector3 = to if _path_i >= _path.size() else _path[_path_i]
	var d := _flat(next - global_position)
	if d.length() < 0.01:
		return
	var dir := d.normalized()
	if _side != 0.0:
		dir = (dir + dir.cross(Vector3.UP) * _side).normalized()
	velocity = dir * minf(speed, left / delta)
	rotation.y = rotate_toward(rotation.y, atan2(dir.x, dir.z), TURN * delta)
	_play(clip, rate)


func _face(point: Vector3, delta: float) -> void:
	var d := _flat(point - global_position)
	if d.length() > 0.05:
		rotation.y = rotate_toward(rotation.y, atan2(d.x, d.z), TURN * delta)


func _play(clip: String, rate := 1.0, blend := 0.25) -> void:
	if anim == null or not anim.has_animation(clip):
		return
	if anim.current_animation != clip:
		anim.play(clip, blend)
	anim.speed_scale = rate


static func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)
