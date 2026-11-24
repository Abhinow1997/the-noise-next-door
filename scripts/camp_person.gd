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
##     everyone looks about, then back to the routine. Seeing him is a fright. His laugh,
##     his running and his landing from a jump draw them even while they're wondering or
##     confused (11 Nov 2026).
##   - Spotting him, they flinch (`scared`), and the others catch the fright.
##   - The girl is always scared: she hurries behind her protector (the low-poly man)
##     and cowers there (`cower`), runs further off if he comes near her, and only goes
##     back to her routine once he's been gone a while.
##   - The men stand guard (`guard`), facing him; the protector puts himself between the
##     raccoon and the girl. If he lingers in the camp for LINGER seconds, they chase him
##     (`run`), slower than he runs but faster than he walks. One who gets to him stamps
##     and shoos (`shoo`): he leaps away (player.gd startle); if he's carrying one of the
##     camp's things, it's snatched back (`take_away`, TAKE) and its puzzle reset (the
##     GDD). Since 8 Nov 2026 (the author: "when caught if he has anything in the mouth he
##     drops it and the humans pick it back and get it back to the camp reseting the
##     thing"), caught, he drops whatever he has; if it's theirs, the one who caught him
##     walks to it, picks it up, carries it home and puts it back, and only then does its
##     puzzle reset. Should he grab it again first, they're after him. Up a tree, they
##     shoo at the foot of it a while, then give up.
##   - When the music's plug is pulled, the low-poly man goes to find the plug and puts
##     it back (FIX).
##   - In the open world, since 8 Nov 2026, the fire keeper tends the fire (TEND,
##     camp_fire.gd): when it burns low or is out he fetches a log from the woodpile and
##     puts it on, and if the bucket's been tipped over he sets it back up first.
##   - The camper, since 8 Nov 2026, pitches his tent again (PITCH, camp_tent.gd): with
##     it down, or with them having seen the raccoon at its pegs, he goes round with his
##     mallet and hammers each one back in.
##   - The camper, since 10 Nov 2026, hangs the bear bag up again (HANG,
##     camp_bear_bag.gd): with it down and them having seen the raccoon since it fell, or
##     a treat taken back, he goes to it, puts the treats lying by it back in, then ties it
##     off at the trunk and hoists it up.
##   - Once he's out of the camp or out of sight a while, they walk back (`walk`) to
##     where their routine had got to, and carry on.
##   - Since 26 Oct 2026, before they walk back they're confused (SEARCH): "??" over
##     their heads (camp_input.gd), they look about where he was last seen for
##     SEARCH_TIME. The author: "make the npc confused with the '??' around his head
##     looking around and then walk back", "afetr he has shooed him away and after the
##     raccoon has evaded the sight". Up a tree, they still just give up and go back.
##     Since 10 Nov 2026 they stand still scratching their heads, and only the head looks
##     about (the `confused` clip, tools/blender/animate_chubby.py), with "?" over it. The
##     author: "the confusion where they have lost the sight animation for the npcs should
##     be head scratching and only the head should look around with the '?' sign over the
##     head". Their eyes (the cone) go where the head looks.
##   - Their cones (vision_cone.gd), since the same day: none, and no seeing him, until
##     the tutorial at the camp is done (campsite.gd `cones_on`). When one of them spots
##     him while watching for him, every cone shows until that one's red is over and has
##     faded (campsite.gd `spot`); then each goes, and comes back BACK_AFTER seconds after
##     its own person is calm again: when they start walking back, for the ones who took
##     fright.
##   - Since 21 Nov 2026 (CHANGE-BRIEF.md, "the balloon task is 'Let the balloons go'"), one
##     new trigger for reactions they already have: the girl, seeing the balloons float away or
##     coming back to find the chair empty (camp_balloons.gd), takes fright as she does on
##     seeing him, facing where they were, and calls the others (`call_out`). Each of them
##     who's calm or wondering comes to look (`called`): confused ("?", SEARCH), they walk to
##     a spot round where the balloons were tied and search there as after a fright, then go
##     back. She does the same once she's calmed down. How they search and what they do on
##     seeing him are unchanged.
##   - In the tutorial (camp_tutorial.gd), since 7 Nov 2026: as he dives into the bush,
##     `lose_him` leaves whoever was after him or frightened confused where they stand;
##     as he steals a roasted marshmallow, `alert` has the camper spot him, and
##     `chase_next` sends the men straight after him once their flinch is over.
## The camp (campsite.gd) keeps what they know between them: where and when he was last
## seen, the camp's bounds, when someone last took fright, and whether the music's on.

signal state_changed(state: int)

const VisionCone := preload("res://scripts/vision_cone.gd")
const Player := preload("res://scripts/player.gd")

## Since 23 Nov 2026 (the cake, camp_finale.gd), the camper's: CAKE (fetching it from his tent and
## putting it on its table), FALLEN (his laces tied, he's gone over backwards and lies there), RISE
## (getting up) and PURSUE (after him wherever he goes: the chase out of the camp).
enum State { WORK, STARTLED, GUARD, CHASE, SHOO, RETURN, FLEE, COWER, INVESTIGATE, TAKE, FIX, SEARCH, TEND, PITCH,
	HANG, CAKE, FALLEN, RISE, PURSUE }

## His laces tied, he's started to fall (camp_finale.gd).
signal fell

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
## Standing in the lit fire's light in the open world (campsite.gd `in_firelight`), he's
## seen this much further; crouching, he isn't. The author, 8 Nov 2026: "when the fire is
## lit, the ... raccoon has to always ... crouch, or else he'll be detected more quickly
## if the fire is up and he goes in the camp or like near the camp".
const FIRELIT_SIGHT := 1.5
## Wondering about a noise: how long the "huh?" lasts, how short of where it came from
## the men stop, how long they look about there, and how far (degrees) to each side.
const HUH := 0.6
const STOP_SHORT := 1.3
const LOOK_TIME := 3.0
const LOOK_SWING := 50.0
## Since 23 Nov 2026, a rustle in the keeper's box (`check`, camp_box.gd): how far from its middle
## they stand to look at it, how long they bend over it, and how long they may take to get there.
const CHECK_NEAR := 1.25
const CHECK_TIME := 3.5
const CHECK_WALK := 15.0
## Confused once he's got away: how long they look about before they go back, and the
## clip they do it in (it loops; 3 s, one look each way).
const SEARCH_TIME := 3.0
const CONFUSED := "confused"
## Called to look somewhere (call_out): how far from it they stand to search.
const CALL_NEAR := 1.3
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
## The cake (camp_finale.gd, 23 Nov 2026): how long he's bent in at his tent's door fetching it, and
## bent over its table setting it down; the clips he carries it in, falls in and gets up in
## (tools/blender/animate_chubby.py).
const CAKE_FETCH := 1.8
const CAKE_SET := 1.2
const CARRY := "carry"
const TRIP := "trip"
const GET_UP := "get_up"

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
## The next fright sends a man straight to chasing him after the flinch, instead of
## standing guard (the tutorial sets it as he steals a roasted marshmallow:
## camp_tutorial.gd). Used up by that flinch.
var chase_next := false
## The camper's laces, tied together (camp_finale.gd): the next step he takes, he falls (`_go`).
var laces_tied := false
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
## When their cone may show again (campsite.gd clock): INF from the moment someone spots
## him until they're calm again.
var _cone_back_at := -INF
## How far they saw while last watching for him: their cone stays that long while it
## shows after they've taken fright, rather than as far as they see then (ALERT_SIGHT).
var _watch_length := SIGHT
var _alarmed_at := -INF
var _fright_seen := -INF
var _fright_at := INF
var _goal := Vector3.ZERO
var _noise_at := Vector3.ZERO
## Going to look at the keeper's box close up (`check`), not just wondering about a noise.
var _checking := false
var _look_t := -1.0
var _huh := HUH
var _frozen := false
var _treed := false
var _fix_stage := 0
var _fix_t := 0.0
var _plug: Node3D
## Tending the fire: the fire (camp_fire.gd), where he's got to, and the log in his hand.
var _fire
var _tend_stage := 0
## Taking something of theirs home: the thing, and where they've got to.
var _take_item: Node3D
var _take_stage := 0
var _log: Node3D
## Pitching his tent again: the tent (camp_tent.gd), and the peg he's going to.
var _tent
var _peg := -1
## Hanging the bear bag up again: the bag (camp_bear_bag.gd), and where he's got to.
var _bear_bag
var _hang_stage := 0
## The cake (camp_finale.gd): who has it, how far he's got fetching it, and in the chase, how long
## he stamps before he runs (on catching him, too).
var _finale
var _cake_stage := 0
var _pursue_pause := 0.0
var _hand: BoneAttachment3D
## Their skeleton and its head bone, for where the head looks while confused.
var _skeleton: Skeleton3D
var _head := -1
## Called to look somewhere (`call_out`, `called`): where (INF when not), the spot round it
## they search from (INF until worked out), and whether they've got there.
var _called_to := Vector3.INF
var _call_spot := Vector3.INF
var _at_call := false
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
	# The older loops are set to loop in their .glb's import settings; this one here.
	if anim and anim.has_animation(CONFUSED):
		anim.get_animation(CONFUSED).loop_mode = Animation.LOOP_LINEAR
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


## Someone's spotted him (campsite.gd `spot`): their cone goes once the red's over, until
## they're calm again.
func hide_cone() -> void:
	_cone_back_at = INF


func _physics_process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Player
		if player == null:
			return
	_t += delta
	# Flat on his back, or getting up, he sees nothing (the cake, 23 Nov 2026).
	eyes.blind = not camp.cones_on or state in [State.FALLEN, State.RISE]
	var calm := state in [State.WORK, State.RETURN, State.FIX, State.TEND, State.PITCH, State.HANG, State.CAKE]
	if calm:
		eyes.reach = SIGHT * (SNEAK_SIGHT if player.sneaking else 1.0)
		if anim and anim.current_animation == "dance":
			eyes.reach *= DANCE_SIGHT
		if not player.sneaking and camp.in_firelight(player.global_position):
			eyes.reach *= FIRELIT_SIGHT
	elif state in [State.INVESTIGATE, State.SEARCH]:
		eyes.reach = CURIOUS_SIGHT * (SNEAK_SIGHT if player.sneaking else 1.0)
	else:
		eyes.reach = ALERT_SIGHT
	var watching := calm or state == State.INVESTIGATE
	if watching:
		_watch_length = eyes.reach
	eyes.held_length = -1.0 if watching else _watch_length
	if _cone_back_at == INF and watching and camp.clock >= camp.cones_shown_until():
		_cone_back_at = camp.clock + VisionCone.BACK_AFTER
	eyes.show_on_ground(camp.cones_on and (camp.clock < camp.cones_shown_until()
		or watching and camp.clock >= _cone_back_at))
	if eyes.seeing:
		camp.saw(player.global_position)
	_away = _away + delta if not camp.in_camp(camp.last_seen_at, 3.0) else 0.0
	velocity = Vector3.ZERO
	match state:
		State.WORK:
			_work(delta)
		State.STARTLED:
			_play("scared", 1.0, 0.15)
			_face(_threat(), delta)
			if _t >= FLINCH:
				var chase := chase_next and role != "girl"
				chase_next = false
				_to_state(State.FLEE if role == "girl" else (State.CHASE if chase else State.GUARD))
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
					_to_state(State.SEARCH)
		State.TAKE:
			_take(delta)
		State.RETURN:
			_return(delta)
		State.FLEE:
			_go(_goal, FLEE_SPEED, delta, "run", FLEE_SPEED / run_natural)
			if _flat(_goal - global_position).length() < 0.3 or _t > 4.0:
				_to_state(State.COWER)
		State.COWER:
			_play("cower")
			_face(_threat(), delta)
			if camp.seen_within(0.5) and _flat(player.global_position - global_position).length() < TOO_NEAR \
					and _flat(_hiding_place() - global_position).length() > 0.3:
				# Somewhere further off to go: she runs (cornered, she stays cowering).
				_to_state(State.FLEE)
			elif _gone(GIRL_CALM):
				_to_state(State.SEARCH)
		State.INVESTIGATE:
			_investigate(delta)
		State.FIX:
			_fix(delta)
		State.TEND:
			_tend(delta)
		State.PITCH:
			_pitch(delta)
		State.HANG:
			_hang(delta)
		State.SEARCH:
			_search(delta)
		State.CAKE:
			_cake(delta)
		State.FALLEN:
			# Down, as trip ends (a one-shot, held at its last frame), till he's told to get up.
			pass
		State.RISE:
			if _t >= anim_length(GET_UP):
				laces_tied = false
				_to_state(State.GUARD)
		State.PURSUE:
			_pursue(delta)
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
## before they turn to look. Since 11 Nov 2026 a `sharp` one (his laugh, his running, his
## landing from a jump: campsite.gd) also draws those confused after losing him, and turns
## those already wondering to where it came from: past their "huh?", they go on toward
## the new place with no second one, so his footfalls lead them on rather than stopping
## them (the author: "that should draw their attendtion to the location of the laugh").
## Other noises don't: some come again and again (a job held with E, the bag crinkling as
## he runs), and would keep pulling the one going to look back to the same place.
func hear(at: Vector3, freeze := 0.0, sharp := false) -> void:
	if camp.let_be():
		return
	if sharp and state == State.INVESTIGATE:
		_noise_at = at
		if _t > _huh:
			# Looking again from now: the men set off toward it, for a fresh while.
			_t = _huh
			_look_t = -1.0
		return
	var calm := state in [State.WORK, State.RETURN, State.FIX, State.TEND, State.PITCH, State.HANG]
	if calm or sharp and state == State.SEARCH:
		_frozen = freeze > 0.0 and anim != null and anim.current_animation == "dance"
		_huh = freeze if _frozen else HUH
		_noise_at = at
		_to_state(State.INVESTIGATE)


## Since 23 Nov 2026: a rustle in the keeper's box at `at` (camp_box.gd; the author: "If anybody
## whoever is around that box ... when they come to check the box, we can jump out to scare them").
## Going about their routine or wondering, whoever they are, they come right up to it (CHECK_NEAR)
## and bend over it a while (CHECK_TIME), then go back. True if they're coming.
func check(at: Vector3) -> bool:
	if camp.let_be():
		return false
	if state not in [State.WORK, State.RETURN, State.FIX, State.TEND, State.PITCH, State.HANG,
			State.INVESTIGATE, State.SEARCH]:
		return false
	_frozen = false
	_huh = HUH
	_noise_at = at
	_to_state(State.INVESTIGATE)
	_checking = true
	return true


## Since 23 Nov 2026: he bursts out of the keeper's box right by them (camp_box.gd). Unless they're
## alarmed already, it's a fright, as on seeing him (`alert`). True if it frightened them.
func scare() -> bool:
	if not scareable():
		return false
	alert()
	return true


## True if bursting out at them now would frighten them (`scare`): they aren't alarmed already.
func scareable() -> bool:
	if player == null or camp.let_be():
		return false
	return state not in [State.STARTLED, State.GUARD, State.CHASE, State.SHOO, State.FLEE, State.COWER, State.TAKE,
		State.CAKE, State.FALLEN, State.RISE, State.PURSUE]


## The tutorial (camp_tutorial.gd): they see him take a roasted marshmallow off the
## plate. A flinch, as on spotting him, which the others catch; with `chase_next` set,
## the men then go straight for him (the author's pick on 7 Nov 2026, "Alert and chase").
func alert() -> void:
	if player == null:
		return
	camp.saw(player.global_position)
	_startle(true)


## The tutorial (camp_tutorial.gd), as he's caught stealing the roasted marshmallow: the
## chase is forced. A man goes straight after him, with no flinch first, having spotted him;
## the girl takes fright as she does on spotting him.
func chase_now() -> void:
	if player == null:
		return
	camp.saw(player.global_position)
	if role == "girl":
		_startle(true)
		return
	chase_next = false
	_fright_at = INF
	_fright_seen = camp.clock
	_alarmed_at = camp.clock
	camp.frighten()
	camp.spot(self)
	_to_state(State.CHASE)


## The tutorial (camp_tutorial.gd), as he dives into the bush: whoever's after him or
## frightened is confused where they stand ("?", SEARCH), looks about, and goes back to
## work, without coming to look. The author, 7 Nov 2026: "when the player jumps in the
## tutorial dont let the npcs run to him just let them be confused look around and go
## back to their working".
func lose_him() -> void:
	chase_next = false
	# A fright still going round doesn't reach the calm ones now.
	_fright_seen = camp.frightened
	_fright_at = INF
	# Frozen, their eyes stopped looking (camp_tutorial.gd), and still say they see him
	# from before; looking again on the next tick, they won't.
	eyes.seeing = false
	if state in [State.STARTLED, State.GUARD, State.CHASE, State.SHOO, State.FLEE, State.COWER,
			State.INVESTIGATE]:
		_to_state(State.SEARCH)


## Ends the activity they're at now: they go on to the next one (the girl, once she's blown
## the balloons up: camp_balloons.gd). Only while they're at it.
func finish_activity() -> void:
	if at_activity():
		_step_left = 0.0


## Something of theirs gone from `at` (the balloons: camp_balloons.gd). They take fright as on
## seeing him, facing it (_threat), and call the others, who come to look (`called`).
func call_out(at: Vector3) -> void:
	_called_to = at
	_call_spot = Vector3.INF
	_at_call = false
	_startle()
	for person in camp.people:
		if person != self:
			person.called(at)


## Called to look round `at`: if they're calm or wondering, they're confused at once (SEARCH),
## walk there and search (`_search`), then go back.
func called(at: Vector3) -> void:
	if state in [State.WORK, State.RETURN, State.INVESTIGATE, State.SEARCH]:
		_called_to = at
		_call_spot = Vector3.INF
		_at_call = false
		_to_state(State.SEARCH)


## What a fright faces and flees from: where he was last seen, unless they've been called to
## look somewhere (call_out) and he hasn't been seen lately.
func _threat() -> Vector3:
	if _called_to != Vector3.INF and not camp.seen_within(LOSE):
		return _called_to
	return camp.last_seen_at


## Goes to put the music's plug back in (campsite.gd), if they're calm.
func fix(plug: Node3D) -> void:
	if state in [State.WORK, State.RETURN]:
		_plug = plug
		_fix_stage = 0
		_to_state(State.FIX)


## Taking it home: to where he dropped it, down for it, home with it in hand, and down to
## put it back, when its puzzle resets (camp_puzzles.gd `take_back`). If he's got it again
## before they reach it, they're after him.
func _take(delta: float) -> void:
	var item := _take_item
	if item == null or not is_instance_valid(item):
		_to_state(State.SEARCH)
		return
	match _take_stage:
		0:
			if item == player.held:
				camp.saw(player.global_position)
				_to_state(State.CHASE)
				return
			if _flat(item.global_position - global_position).length() > 0.6:
				_go(item.global_position, WALK * 1.4, delta, "walk", WALK * 1.4 / walk_natural)
			else:
				_take_stage = 1
				_fix_t = 0.0
		1:
			_play("bend", 1.0, 0.15)
			_face(item.global_position, delta)
			_fix_t += delta
			if _fix_t >= FIX_BEND:
				_hold(item)
				_take_stage = 2
		2:
			var home: Vector3 = camp.home_of(item)
			if _flat(home - global_position).length() > 0.9:
				_go(home, WALK * 1.2, delta, "walk", WALK * 1.2 / walk_natural)
			else:
				_take_stage = 3
				_fix_t = 0.0
		3:
			_play("bend", 1.0, 0.15)
			_face(camp.home_of(item), delta)
			_fix_t += delta
			if _fix_t >= FIX_BEND:
				_let_go()
				_take_item = null
				camp.take_back(item)
				_to_state(State.RETURN)


## Goes to tend the fire (camp_fire.gd), if they're at their routine: the bucket first,
## if it's over, then a log.
func tend(fire) -> void:
	if state == State.WORK:
		_fire = fire
		_tend_stage = 0 if fire.bucket_tipped else 2
		_fix_t = 0.0
		_to_state(State.TEND)


## Tending the fire: to the bucket and down to set it up, if it's over; to the woodpile
## and down for a log; to the pit, and down to put it on.
func _tend(delta: float) -> void:
	if eyes.seeing and not camp.let_be():
		_startle(true)
		return
	var to: Vector3 = [_fire.bucket_spot(), _fire.bucket_spot(), _fire.woodpile_spot(),
		_fire.woodpile_spot(), _fire.stoke_at, _fire.stoke_at][_tend_stage]
	var look: Vector3 = [_fire.bucket.global_position, _fire.bucket.global_position,
		_fire.woodpile.global_position, _fire.woodpile.global_position, _fire.global_position,
		_fire.global_position][_tend_stage]
	if _tend_stage % 2 == 0:
		if _flat(to - global_position).length() > 0.3:
			_go(to, WALK * 1.2, delta, "walk", WALK * 1.2 / walk_natural)
		else:
			_tend_stage += 1
			_fix_t = 0.0
		return
	_play("bend", 1.0, 0.15)
	_face(look, delta)
	_fix_t += delta
	if _fix_t < FIX_BEND:
		return
	match _tend_stage:
		1:
			_fire.set_bucket_upright()
			_tend_stage = 2
		3:
			_take_log()
			_tend_stage = 4
		5:
			_drop_log()
			_fire.add_log()
			# Not built up yet: straight back for another; otherwise back to his routine.
			if _fire.wants_more():
				_tend_stage = 0 if _fire.bucket_tipped else 2
			else:
				_to_state(State.RETURN)


## Goes to pitch his tent again (camp_tent.gd), if he's at his routine.
func pitch(tent) -> void:
	if state == State.WORK:
		_tent = tent
		_peg = tent.next_out()
		_fix_t = 0.0
		_to_state(State.PITCH)


## Pitching it: to each peg that's out, and the mallet on it till it's in; then back.
func _pitch(delta: float) -> void:
	if eyes.seeing and not camp.let_be():
		_startle(true)
		return
	if _peg < 0:
		_to_state(State.RETURN)
		return
	var to: Vector3 = _tent.stand_spot(_peg)
	if _fix_t == 0.0 and _flat(to - global_position).length() > 0.3:
		_go(to, WALK * 1.2, delta, "walk", WALK * 1.2 / walk_natural)
		return
	_play("hammer", 1.0, 0.15)
	_face(_tent.pegs[_peg].at, delta)
	_fix_t += delta
	if _fix_t >= FIX_BEND:
		_tent.peg_back(_peg)
		_peg = _tent.next_out()
		_fix_t = 0.0


## Goes to hang the bear bag up again (camp_bear_bag.gd), if he's at his routine.
func hang(bag) -> void:
	if state == State.WORK:
		_bear_bag = bag
		_hang_stage = 0
		_fix_t = 0.0
		_to_state(State.HANG)


## Hanging it up again: to the bag, and down to put the treats back in it and tie it shut;
## to the trunk, and down to tie the rope off and hoist it; then back.
func _hang(delta: float) -> void:
	if eyes.seeing and not camp.let_be():
		_startle(true)
		return
	var at_bag := _hang_stage < 2
	if _hang_stage % 2 == 0:
		var to: Vector3 = _bear_bag.bag_spot() if at_bag else _bear_bag.knot_spot()
		if _flat(to - global_position).length() > 0.3:
			_go(to, WALK * 1.2, delta, "walk", WALK * 1.2 / walk_natural)
		else:
			_hang_stage += 1
			_fix_t = 0.0
		return
	_play("bend", 1.0, 0.15)
	_face(_bear_bag.bag_at() if at_bag else _bear_bag.knot_at(), delta)
	_fix_t += delta
	if _fix_t < FIX_BEND:
		return
	if at_bag:
		_bear_bag.gather()
		_hang_stage = 2
	else:
		_bear_bag.hoist()
		_to_state(State.RETURN)


## The camper goes for the cake (camp_finale.gd, 23 Nov 2026), if he's at his routine: into his tent
## for it, then out to its table. True if he's going.
func fetch_cake(finale) -> bool:
	if state != State.WORK:
		return false
	_finale = finale
	_cake_stage = 0
	_fix_t = 0.0
	_to_state(State.CAKE)
	return true


## Fetching it: to his tent's door and bent in at it (CAKE_FETCH), the cake in his hands
## (camp_finale.gd puts it there); to the table with it, carrying it (`carry`); bent over the
## table to set it down (CAKE_SET). Then back at his routine, which camp_finale.gd has given a
## step by the cake, and he's at it.
func _cake(delta: float) -> void:
	if eyes.seeing and not camp.let_be():
		_startle(true)
		return
	if _cake_stage == 0 or _cake_stage == 2:
		var to: Vector3 = _finale.door_spot() if _cake_stage == 0 else _finale.stand_spot()
		if _flat(to - global_position).length() > 0.3:
			if _cake_stage == 0:
				_go(to, WALK * 1.2, delta, "walk", WALK * 1.2 / walk_natural)
			else:
				_go(to, WALK, delta, CARRY, WALK / walk_natural)
			return
		_cake_stage += 1
		_fix_t = 0.0
		return
	_play("bend", 1.0, 0.15)
	_face(_finale.door_at() if _cake_stage == 1 else _finale.table_at(), delta)
	_fix_t += delta
	if _cake_stage == 1 and _fix_t >= CAKE_FETCH:
		_finale.cake_in_hands(self)
		_cake_stage = 2
	elif _cake_stage == 3 and _fix_t >= CAKE_SET:
		_finale.cake_on_table()
		_cake_stage = 4
		_step = _finale.cake_step(self)
		_step_left = _rng.randf_range(routine[_step].time.x, routine[_step].time.y)
		_to_state(State.WORK)
		_arrived = true


## By the cake with his laces tied (camp_finale.gd): he goes on to the next step of his routine
## within `seconds`, and falls as he does.
func leave_soon(seconds: float) -> void:
	_step_left = minf(_step_left, seconds)


## His laces tied, the first step he takes (`_go`): over he goes (`trip`), and lies there.
func _fall() -> void:
	_to_state(State.FALLEN)
	if anim and anim.has_animation(TRIP):
		anim.play(TRIP, 0.1)
		anim.speed_scale = 1.0
	fell.emit()


## Flat on his back after his fall (camp_finale.gd): up he gets (`get_up`); then stands guard,
## facing the raccoon, his laces kicked loose.
func get_up() -> void:
	if state != State.FALLEN:
		return
	_to_state(State.RISE)
	if anim and anim.has_animation(GET_UP):
		anim.play(GET_UP, 0.1)
		anim.speed_scale = 1.0


## The length of clip `clip` (s), or 0 if they haven't got it.
func anim_length(clip: String) -> float:
	return anim.get_animation(clip).length if anim and anim.has_animation(clip) else 0.0


## After him, wherever he goes (camp_finale.gd's chase out of the camp, 23 Nov 2026): first a stamp
## at him for `stamp` seconds, then running straight at him at their chase speed. Catching him,
## they shoo him, he drops what he has and leaps away (as in the camp), and they're after him again.
## Only `stand_down` ends it.
func pursue(stamp := 0.0) -> void:
	if player == null:
		return
	chase_next = false
	_fright_at = INF
	_fright_seen = camp.clock
	_alarmed_at = camp.clock
	_to_state(State.PURSUE)
	_pursue_pause = stamp


## The chase is over (camp_finale.gd): back to their routine.
func stand_down() -> void:
	if state == State.PURSUE:
		_to_state(State.RETURN)


func _pursue(delta: float) -> void:
	var him := player.global_position
	if _pursue_pause > 0.0:
		_pursue_pause -= delta
		_play("shoo")
		_face(him, delta)
		return
	var to := _flat(him - global_position)
	# While the cutscene holds him (camp_finale.gd), he can't be caught.
	if to.length() < REACH and not player.is_hopping() and not player.resting and not VisionCone.hidden(player) 			and not player.input_locked:
		if player.held:
			player._drop()
		player.startle(global_position)
		_pursue_pause = SHOO_TIME
		return
	var dir := to.normalized()
	if _side != 0.0:
		dir = (dir + dir.cross(Vector3.UP) * _side).normalized()
	velocity = dir * chase_speed
	rotation.y = rotate_toward(rotation.y, atan2(dir.x, dir.z), TURN * delta)
	_play("run", chase_speed / run_natural)


## A log from the woodpile, in his right hand.
func _take_log() -> void:
	if _hand == null:
		var skeletons := find_children("*", "Skeleton3D", true, false)
		if skeletons.is_empty():
			return
		_hand = BoneAttachment3D.new()
		_hand.bone_name = "mano_L"
		skeletons[0].add_child(_hand)
	_log = MeshInstance3D.new()
	_log.mesh = _fire.woodpile.get_child(0).mesh
	_log.scale = Vector3.ONE * 0.45
	_hand.add_child(_log)
	_log.position = hand_grip


func _drop_log() -> void:
	if _log:
		_log.queue_free()
		_log = null


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
		_startle(true)
	elif camp.frightened > _fright_seen and camp.clock - camp.frightened < 1.0:
		# Someone else has just taken fright: so do they, a moment later.
		_fright_seen = camp.frightened
		_fright_at = camp.clock + _rng.randf_range(CATCH_FRIGHT.x, CATCH_FRIGHT.y)
	elif camp.clock >= _fright_at:
		_startle()


## A fright: from seeing him themselves (`spotted`), or caught from someone else's.
func _startle(spotted := false) -> void:
	if state in [State.FALLEN, State.RISE]:
		return
	_fright_at = INF
	_fright_seen = camp.clock
	_alarmed_at = camp.clock
	camp.frighten()
	if spotted:
		camp.spot(self)
	_to_state(State.STARTLED)


## "Huh?": they stop and turn to the noise; the men go and look where it came from;
## then everyone looks about a while, and goes back to their routine. Seeing him there
## is a fright.
func _investigate(delta: float) -> void:
	if eyes.seeing and not camp.let_be():
		_startle(true)
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
	if _checking:
		# The keeper's box (`check`): right up to it, whoever they are, then bent over it.
		if _look_t < 0.0 and to.length() > CHECK_NEAR + 0.15 and _t < _huh + CHECK_WALK:
			_go(_noise_at - to.normalized() * CHECK_NEAR, WALK * 1.1, delta, "walk", WALK * 1.1 / walk_natural)
			return
		if _look_t < 0.0:
			_look_t = 0.0
		_look_t += delta
		_play("bend")
		_face(_noise_at, delta)
		if _look_t > CHECK_TIME:
			_to_state(State.RETURN)
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
	elif camp.let_be():
		_to_state(State.RETURN)
	elif _gone(CALM):
		_to_state(State.SEARCH)


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
	# Hidden (in a hiding spot, the camp's bush), he can't be caught: they've come to where
	# they last saw him, and can only look about (7 Nov 2026: the author found them
	# shooing him out of the bush, "if you hide in the bushes, people should not be able
	# to see you. That should be the whole point").
	elif _flat(him - global_position).length() < REACH and not player.is_hopping() and not player.resting \
			and not VisionCone.hidden(player):
		_treed = false
		var item: Node3D = player.held
		# Caught, he drops whatever's in his mouth (the author, 8 Nov 2026).
		if item:
			player._drop()
		if item and item.has_meta("camp_loot"):
			# Something of theirs: they pick it up and take it home (_take).
			_take_item = item
			_take_stage = 0
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
		_to_state(State.SEARCH)
		return
	var toward := _flat(target - global_position)
	if toward.length() > 2.0:
		target += toward.normalized().cross(Vector3.UP) * FLANK * flank_side
	_go(target, chase_speed, delta, "run", chase_speed / run_natural)


## Putting the music's plug back: to wherever it's got to, down for it, back to the
## table with it in hand, down to push it in.
func _fix(delta: float) -> void:
	if eyes.seeing and not camp.let_be():
		_startle(true)
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


## Confused: he's got away, and they don't know where to. Standing where they are, they
## scratch their heads and look about (CONFUSED: only the head turns), with "?" over
## them (camp_input.gd), then go back. Their eyes look where the head does. Still wary:
## seeing him there sets them guarding (or her hiding) again, with no flinch.
## Called to look somewhere (call_out, `called`), they first walk to a spot round it, from
## the side they come from, and search there.
func _search(delta: float) -> void:
	if eyes.seeing and camp.in_camp(camp.last_seen_at) and not camp.let_be():
		camp.spot(self)
		_to_state(State.FLEE if role == "girl" else State.GUARD)
		return
	if _called_to != Vector3.INF and not _at_call:
		if _call_spot == Vector3.INF:
			var from := _flat(global_position - _called_to)
			var dir := from.normalized() if from.length() > 0.1 else -global_basis.z
			_call_spot = _clear_near(_called_to, dir, [CALL_NEAR, CALL_NEAR * 1.4], _called_to + dir * CALL_NEAR)
		if _flat(_call_spot - global_position).length() > 0.25:
			_go(_call_spot, WALK * 1.4, delta, "walk", WALK * 1.4 / walk_natural)
			return
		_at_call = true
		# The search's time from getting there.
		_t = 0.0
	if _at_call:
		_face(_called_to, delta)
	_play(CONFUSED if anim and anim.has_animation(CONFUSED) else _stand(), 1.0, 0.3)
	eyes.rotation.y = PI + _head_turn()
	if _t > SEARCH_TIME:
		_to_state(State.RETURN)


## How far their head's turned from straight ahead, about the vertical (radians, as
## rotation.y turns), from their skeleton's head bone; 0 without one.
func _head_turn() -> float:
	if _skeleton == null:
		var skeletons := find_children("*", "Skeleton3D", true, false)
		if skeletons.is_empty():
			return 0.0
		_skeleton = skeletons[0]
		_head = _skeleton.find_bone("testa")
	if _head < 0:
		return 0.0
	var turned := (_skeleton.get_bone_global_pose(_head).basis
		* _skeleton.get_bone_global_rest(_head).basis.inverse()).orthonormalized()
	var to_self := (global_transform.affine_inverse() * _skeleton.global_transform).basis.orthonormalized()
	# They face +Z.
	var ahead := to_self * (turned * (to_self.inverse() * Vector3.BACK))
	return atan2(ahead.x, ahead.z)


func _return(delta: float) -> void:
	if _t > 0.5 and camp.seen_within(0.3) and camp.in_camp(camp.last_seen_at) and not camp.let_be():
		# He's back while they're still wary: no flinch this time.
		if eyes.seeing:
			camp.spot(self)
		_to_state(State.FLEE if role == "girl" else State.GUARD)
		return
	var spot := activity_spot()
	if _flat(spot - global_position).length() > ARRIVE:
		_go(spot, WALK, delta, "walk", WALK / walk_natural)
		return
	_to_state(State.WORK)


func _to_state(to: State) -> void:
	# Down after his fall, he only gets up (`get_up`); getting up, he ends on his feet, on guard, or
	# goes after him (camp_finale.gd). Nothing else moves him on meanwhile.
	if state == State.FALLEN and to != State.RISE or state == State.RISE and to not in [State.GUARD, State.PURSUE]:
		return
	_checking = false
	if state == State.CAKE and to != State.CAKE and _finale and _cake_stage in [2, 3]:
		# Frightened with the cake in his hands: he puts it down on its table (camp_finale.gd).
		_finale.cake_on_table()
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
	if to not in [State.STARTLED, State.FLEE, State.COWER, State.SEARCH] or (to == State.SEARCH and _at_call):
		# A call to look somewhere lasts through her fright and their search there, and no further.
		_called_to = Vector3.INF
		_call_spot = Vector3.INF
		_at_call = false
	if to != State.TEND:
		# Interrupted with a log: it's dropped back on the pile.
		_drop_log()
	if carrying and to != State.TAKE and to != State.FIX:
		# Interrupted with something in hand (a fright while putting the plug back): put it down.
		var item := carrying
		_let_go()
		camp.put_down(item, global_position + global_basis.z * 0.4)
	# Their eyes look straight ahead again (confused, they follow the head: `_search`).
	eyes.rotation.y = PI
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
	var threat: Vector3 = _threat()
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
	# The camper's laces tied together (camp_finale.gd): his first step trips him.
	if laces_tied and state != State.FALLEN:
		_fall()
		return
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
	# Falling and getting up play their own one-shots (`_fall`, `get_up`), held to the end.
	if state in [State.FALLEN, State.RISE]:
		return
	if anim.current_animation != clip:
		anim.play(clip, blend)
	anim.speed_scale = rate


static func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)
