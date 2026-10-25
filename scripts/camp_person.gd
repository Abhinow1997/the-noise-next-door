extends CharacterBody3D
## One of the people at level 1's campsite (campsite.gd): their routine, and how they
## take to the raccoon. Asked for on 23 Oct 2026: "when the raccoon comes close and is
## visible to them they should be scraed initially but then if it lingers around the camp
## the guys start to chasing it away and girl is always scared guys trying to protect
## them"; then "plan a smother working and rotuines and tasks ... puzzle like".
##   - Their routine (WORK): a loop of activities (campsite.gd gives each one theirs:
##     where, which way they face, what they do there, for how long), walking from one
##     to the next, so the raccoon can learn when someone's busy or has his back turned.
##   - Calm, each sees him in a cone in front of them (vision_cone.gd, drawn on the
##     ground) out to SIGHT metres, nearer while he sneaks, and nearer still while
##     they're dancing, lost in the music (DANCE_SIGHT).
##   - A noise (campsite.gd `noise`: a chitter, his running near, a job done with E)
##     makes them wonder (INVESTIGATE): "huh?", the men go and look where it came from,
##     everyone looks about, then back to the routine. Seeing him is a fright.
##   - Spotting him, they flinch (`scared`), and the others catch the fright.
##   - The girl is always scared: she hurries behind her protector (the low-poly man)
##     and cowers there (`cower`), runs further off if he comes near her, and only goes
##     back to her routine once he's been gone a while.
##   - The men stand guard (`guard`), facing him; the protector puts himself between the
##     raccoon and the girl. If he lingers in the camp for LINGER seconds, they chase him
##     (`run`), slower than he runs but faster than he walks. One who gets to him stamps
##     and shoos (`shoo`): he leaps away (player.gd startle); if he's carrying one of the
##     camp's things, it's snatched back (`take_away`, TAKE) and its puzzle reset (the
##     GDD: "the humans take it back" and "the puzzle resets"). Up a tree, they shoo at
##     the foot of it a while, then give up.
##   - When the music's plug is pulled, the low-poly man goes to find the plug and puts
##     it back (FIX).
##   - Once he's out of the camp or out of sight a while, they walk back (`walk`) to
##     where their routine had got to, and carry on.
## The camp (campsite.gd) keeps what they know between them: where and when he was last
## seen, the camp's bounds, when someone last took fright, and whether the music's on.

signal state_changed(state: int)

const VisionCone := preload("res://scripts/vision_cone.gd")
const Player := preload("res://scripts/player.gd")

enum State { WORK, STARTLED, GUARD, CHASE, SHOO, RETURN, FLEE, COWER, INVESTIGATE, TAKE, FIX }

## How far they see while calm (times SNEAK_SIGHT while he sneaks), while wondering
## about a noise, and once alarmed, and how wide; where their eyes are.
const SIGHT := 7.0
const SNEAK_SIGHT := 0.55
const CURIOUS_SIGHT := 9.0
const ALERT_SIGHT := 14.0
const SIGHT_ANGLE := 110.0
const EYES := Vector3(0, 1.55, 0.12)
## Dancing, they're lost in the music and see only this much as far.
const DANCE_SIGHT := 0.6
## His running this near them is heard (campsite.gd hears his chitters and other noises).
const HEAR_RUN := 4.0
## Wondering about a noise: how long the "huh?" lasts, how short of where it came from
## the men stop, how long they look about there, and how far (degrees) to each side.
const HUH := 0.6
const STOP_SHORT := 1.3
const LOOK_TIME := 3.0
const LOOK_SWING := 50.0
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
## Snatching something back takes as long as `take_away`.
const TAKE_TIME := 2.9
## Putting the plug back: bending down for it, and to push it in.
const FIX_BEND := 1.6
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
## Walking to a place, this near is there (m): near enough not to be seen settling in.
const ARRIVE := 0.08

## Set before it's added (campsite.gd).
var role := "guy"
## Their routine: activities, each {name, at (where), yaw (which way they face),
## clip, speed (the clip's), time (Vector2: how long, from, to)}, done in turn, looping.
var routine: Array[Dictionary] = []
## Their walk's and run's own speeds at 1x (m/s), and how fast they chase.
var walk_natural := 1.0
var run_natural := 3.3
var chase_speed := 3.0
## Which side of him they come at him from while chasing (+1 or -1).
var flank_side := 1.0
## Where something they hold sits in their right hand (mano_L's space).
var hand_grip := Vector3.ZERO
var camp
var model: Node3D
## The girl's protector, and whom a protector protects.
var protector
var protects

var state := State.WORK
var player: Player
var anim: AnimationPlayer
var eyes: VisionCone
## What they have in their hand (something snatched back, or the plug), or null.
var carrying: Node3D
## The way to where they're going, round things (campsite.gd bakes where they can
## walk): its points, the next one, where it goes, and how old it is.
var _path := PackedVector3Array()
var _path_i := 0
var _path_to := Vector3.INF
var _path_age := 0.0

var _t := 0.0
var _step := 0
var _step_left := 0.0
var _arrived := false
var _linger := 0.0
var _away := 0.0
var _alarmed_at := -INF
var _fright_seen := -INF
var _fright_at := INF
var _goal := Vector3.ZERO
var _noise_at := Vector3.ZERO
var _look_t := -1.0
var _huh := HUH
var _frozen := false
var _treed := false
var _fix_stage := 0
var _fix_t := 0.0
var _plug: Node3D
var _hand: BoneAttachment3D
var _stuck := 0.0
var _side := 0.0
var _side_left := 0.0
var _floor_y := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	_floor_y = global_position.y
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
	if not routine.is_empty():
		_step_left = _rng.randf_range(routine[0].time.x, routine[0].time.y)
		_arrived = true
		_play(routine[0].clip, routine[0].speed, 0.0)


## What they're doing in their routine, and whether they're at it (not walking there).
func activity() -> String:
	return "" if routine.is_empty() else routine[_step].name


func at_activity() -> bool:
	return state == State.WORK and _arrived


## Where the activity they're on is done, and which way they face there.
func activity_spot() -> Vector3:
	return global_position if routine.is_empty() else routine[_step].at


func activity_facing() -> float:
	return rotation.y if routine.is_empty() else routine[_step].yaw


## Seconds since they last took fright.
func alarmed_for() -> float:
	return camp.clock - _alarmed_at


func _physics_process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Player
		if player == null:
			return
	_t += delta
	var calm := state in [State.WORK, State.RETURN, State.FIX]
	if calm:
		eyes.reach = SIGHT * (SNEAK_SIGHT if player.sneaking else 1.0)
		if anim and anim.current_animation == "dance":
			eyes.reach *= DANCE_SIGHT
	elif state == State.INVESTIGATE:
		eyes.reach = CURIOUS_SIGHT * (SNEAK_SIGHT if player.sneaking else 1.0)
	else:
		eyes.reach = ALERT_SIGHT
	eyes.show_on_ground(calm or state == State.INVESTIGATE)
	if eyes.seeing:
		camp.saw(player.global_position)
	_away = _away + delta if not camp.in_camp(camp.last_seen_at, 3.0) else 0.0
	velocity = Vector3.ZERO
	match state:
		State.WORK:
			_work(delta)
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
		State.TAKE:
			_play("take_away", 1.0, 0.15)
			_face(camp.last_seen_at, delta)
			if _t >= TAKE_TIME:
				var item := carrying
				_let_go()
				camp.take_back(item)
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
			if camp.seen_within(0.5) and _flat(player.global_position - global_position).length() < TOO_NEAR \
					and _flat(_hiding_place() - global_position).length() > 0.3:
				# Somewhere further off to go: she runs (cornered, she stays cowering).
				_to_state(State.FLEE)
			elif _gone(GIRL_CALM):
				_to_state(State.RETURN)
		State.INVESTIGATE:
			_investigate(delta)
		State.FIX:
			_fix(delta)
	var meant := velocity.length()
	move_and_slide()
	# Sliding along something's slanted side shouldn't lift them off the ground.
	global_position.y = _floor_y
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


## Hears a noise at `at` (campsite.gd): going about their routine, they wonder about it.
## Dancing, a `freeze` (the music cutting out) catches them mid-move that many seconds
## before they turn to look.
func hear(at: Vector3, freeze := 0.0) -> void:
	if state in [State.WORK, State.RETURN, State.FIX] and not camp.let_be():
		_frozen = freeze > 0.0 and anim != null and anim.current_animation == "dance"
		_huh = freeze if _frozen else HUH
		_noise_at = at
		_to_state(State.INVESTIGATE)


## Goes to put the music's plug back in (campsite.gd), if they're calm.
func fix(plug: Node3D) -> void:
	if state in [State.WORK, State.RETURN]:
		_plug = plug
		_fix_stage = 0
		_to_state(State.FIX)


## Their routine: to the current activity's place, then at it until its time's up,
## then on to the next. Noticing him meanwhile.
func _work(delta: float) -> void:
	if not routine.is_empty():
		var a: Dictionary = routine[_step]
		if not _arrived and _flat(a.at - global_position).length() > ARRIVE:
			_go(a.at, WALK, delta, "walk", WALK / walk_natural)
		else:
			if not _arrived:
				_arrived = true
				global_position = Vector3(a.at.x, global_position.y, a.at.z)
			rotation.y = rotate_toward(rotation.y, a.yaw, TURN * delta)
			# A clip they don't have yet (`roast`, `idle`): its stand-in. And no dancing
			# without the music: they stand about instead.
			var clip: String = a.clip
			var speed: float = a.speed
			if anim and not anim.has_animation(clip):
				clip = a.fallback if a.fallback != "" else _stand()
				speed = a.fallback_speed if a.fallback != "" else 1.0
			if clip == "dance" and not camp.music_on:
				clip = _stand()
				speed = 1.0
			_play(clip, speed)
			_step_left -= delta
			if _step_left <= 0.0:
				_step = (_step + 1) % routine.size()
				_step_left = _rng.randf_range(routine[_step].time.x, routine[_step].time.y)
				_arrived = false
	if eyes.seeing and not camp.let_be():
		_startle()
	elif player.running and _flat(player.global_position - global_position).length() < HEAR_RUN:
		hear(player.global_position)
	elif camp.frightened > _fright_seen and camp.clock - camp.frightened < 1.0:
		# Someone else has just taken fright: so do they, a moment later.
		_fright_seen = camp.frightened
		_fright_at = camp.clock + _rng.randf_range(CATCH_FRIGHT.x, CATCH_FRIGHT.y)
	elif camp.clock >= _fright_at:
		_startle()


func _startle() -> void:
	_fright_at = INF
	_fright_seen = camp.clock
	_alarmed_at = camp.clock
	camp.frighten()
	_to_state(State.STARTLED)


## "Huh?": they stop and turn to the noise; the men go and look where it came from;
## then everyone looks about a while, and goes back to their routine. Seeing him there
## is a fright.
func _investigate(delta: float) -> void:
	if eyes.seeing and not camp.let_be():
		_startle()
		return
	var to := _flat(_noise_at - global_position)
	if _t < _huh:
		if _frozen:
			# Stopped dead, mid-move, where the music left them.
			anim.speed_scale = 0.0
		else:
			_play(_stand())
			_face(_noise_at, delta)
		return
	if _look_t < 0.0 and role == "guy" and to.length() > STOP_SHORT + 0.2 and _t < _huh + 8.0:
		_go(_noise_at - to.normalized() * STOP_SHORT, WALK * 1.1, delta, "walk", WALK * 1.1 / walk_natural)
		return
	if _look_t < 0.0:
		_look_t = 0.0
	_look_t += delta
	_play(_stand())
	var toward := atan2(to.x, to.z) if to.length() > 0.1 else rotation.y
	rotation.y = rotate_toward(rotation.y, toward + deg_to_rad(LOOK_SWING) * sin(_look_t * 2.1), TURN * 0.5 * delta)
	if _look_t > LOOK_TIME:
		_to_state(State.RETURN)


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
		_treed = false
		var item: Node3D = player.held
		if item and item.has_meta("camp_loot"):
			# Caught with something of theirs: they snatch it back.
			player._drop()
			_hold(item)
			player.startle(global_position)
			_to_state(State.TAKE)
		else:
			player.startle(global_position)
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


## Putting the music's plug back: to wherever it's got to, down for it, back to the
## table with it in hand, down to push it in.
func _fix(delta: float) -> void:
	if eyes.seeing and not camp.let_be():
		_startle()
		return
	match _fix_stage:
		0:
			if _plug == null or _plug == player.held:
				# Not where he can get at it: he wonders where it went instead.
				_noise_at = _plug.global_position if _plug else global_position
				_to_state(State.INVESTIGATE)
				return
			if _flat(_plug.global_position - global_position).length() > 0.65:
				_go(_plug.global_position, WALK * 1.2, delta, "walk", WALK * 1.2 / walk_natural)
			else:
				_fix_stage = 1
				_fix_t = 0.0
		1:
			_play("bend", 1.0, 0.15)
			_face(_plug.global_position, delta)
			_fix_t += delta
			if _fix_t >= FIX_BEND:
				_hold(_plug)
				_fix_stage = 2
		2:
			var socket: Vector3 = camp.socket_spot()
			if _flat(socket - global_position).length() > 0.3:
				_go(socket, WALK * 1.2, delta, "walk", WALK * 1.2 / walk_natural)
			else:
				_fix_stage = 3
				_fix_t = 0.0
		3:
			_play("bend", 1.0, 0.15)
			_face(camp.socket_at(), delta)
			_fix_t += delta
			if _fix_t >= FIX_BEND:
				var plug := carrying
				_let_go()
				camp.plug_in(plug)
				_to_state(State.RETURN)


func _return(delta: float) -> void:
	if _t > 0.5 and camp.seen_within(0.3) and camp.in_camp(camp.last_seen_at) and not camp.let_be():
		# He's back while they're still wary: no flinch this time.
		_to_state(State.FLEE if role == "girl" else State.GUARD)
		return
	var spot := activity_spot()
	if _flat(spot - global_position).length() > ARRIVE:
		_go(spot, WALK, delta, "walk", WALK / walk_natural)
		return
	_to_state(State.WORK)


func _to_state(to: State) -> void:
	if to == State.GUARD and state == State.STARTLED:
		_linger = 0.0
	if to == State.FLEE:
		_goal = _hiding_place()
	if to == State.WORK:
		# Calm: frights from before don't count.
		_fright_seen = camp.frightened
		_fright_at = INF
		_arrived = false
	if to == State.INVESTIGATE:
		_look_t = -1.0
	if carrying and to != State.TAKE and to != State.FIX:
		# Interrupted with something in hand (a fright while putting the plug back): put it down.
		var item := carrying
		_let_go()
		camp.put_down(item, global_position + global_basis.z * 0.4)
	state = to
	_t = 0.0
	state_changed.emit(to)


## Takes `item` in their right hand.
func _hold(item: Node3D) -> void:
	if _hand == null:
		var skeletons := find_children("*", "Skeleton3D", true, false)
		if skeletons.is_empty():
			return
		_hand = BoneAttachment3D.new()
		_hand.bone_name = "mano_L"
		skeletons[0].add_child(_hand)
	camp.lift(item)
	item.reparent(_hand, false)
	item.transform = Transform3D(Basis(), hand_grip)
	carrying = item


## Lets go of what they hold (the camp puts it where it belongs).
func _let_go() -> void:
	carrying = null


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
	for turn: float in [0.0, 30.0, -30.0, 60.0, -60.0, 90.0, -90.0, 120.0, -120.0]:
		for d: float in far:
			var at := from + dir.rotated(Vector3.UP, deg_to_rad(turn)) * d
			probe.transform = Transform3D(Basis(), at + Vector3.UP * 0.7)
			if space.intersect_shape(probe, 1).is_empty():
				return at
	return otherwise


## True once he's been out of sight `calm` seconds, or out of the camp a while.
func _gone(calm: float) -> bool:
	return not camp.seen_within(calm) or _away > AWAY


## What they do standing about: `idle` once they have it; till then the men stand
## guard and the girl, always scared, hugs herself.
func _stand() -> String:
	if anim and anim.has_animation("idle"):
		return "idle"
	return "cower" if role == "girl" else "guard"


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
