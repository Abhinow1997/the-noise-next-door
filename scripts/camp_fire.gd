extends Node3D
## The campfire's life in the open world, at the fire pit (campsite.gd builds the pit, its
## flames, light and sparks, and shows them by `strength`). Asked for on 8 Nov 2026: "a
## couple of guys are working towards the campfire ... they are like getting logs ... and
## they're adding logs to it so that it can stay like lit ... and then eventually ...
## dousing the fire", given "naturally, rather than like forcing it ... something that you
## can see, that you can interact with ... everything with E, and ... a small twinkle".
##   - `strength`, 0 (out: ash and charred logs, no light) to 1 (burning well), is the
##     game value the fire's look follows, and the one Effect B's smoke is to follow.
##   - With the tutorial to come, it's out from the start (`start_out`; the author, 8 Nov
##     2026: "from the start of the tutorial the fire should be off"). As the tutorial's pan
##     starts, its `cycle` does (`start_building`): it burns down by BURN a second, and the
##     fire keeper (camp_person.gd `tend`) fetches a log from the woodpile whenever it's
##     below FEED_BELOW, lighting it if it's out: it flares up (`flare`), then settles. The
##     roasting waits till it's lit. The open world's parts (the
##     firelight, the bucket) wait for the tutorial's end (`open`). In the checks that skip
##     the tutorial the cycle's off and it burns steadily, as it always did.
##   - The bucket of water by the pit twinkles as loot does (thought_bubbles.gd, "shiny")
##     while he could tip it: once the open world's on and the fire's lit. Holding E at it
##     (interactable.gd) noses it over: the water floods the pit with a hiss the campers
##     hear (campsite.gd `noise`), and the fire goes out in DOUSE_TIME. The keeper, once
##     he's calm, sets the bucket back up and builds the fire again.
##   - It had a circle of sight from 8 Nov 2026 (the author: "the firepit and the surrounding campsite
##     when the fire is lit should have the vision cone in circle ... where if the raccon runs or walks
##     he gets spotted"): a vision cone all the way round, as far as its light, that alerted the nearest
##     calm camper whenever he moved upright in it. It came out on 24 Nov 2026 (the author: "remove the
##     vision cone of the firepit its making it almost impossible to push over cause its alerting the
##     npcs"). In its light he's still seen half as far again by the campers' own eyes (campsite.gd
##     `in_firelight`).
## No task on the list and no note: the author asked for no direct hint.
## In the checks that skip the tutorial its cycle is off, so the fire burns as before.

const LowPoly := preload("res://scripts/lowpoly.gd")
const Forest := preload("res://scripts/forest.gd")
const Interactable := preload("res://scripts/interactable.gd")
const CampPerson := preload("res://scripts/camp_person.gd")

signal lit
signal doused

## How fast it burns down unfed (strength a second), and how fast it dies after the
## steal; what a log adds, and below what the keeper goes for one.
const BURN := 1.0 / 150.0
const DIE := 1.0 / 12.0
const LOG_ADDS := 0.3
const FEED_BELOW := 0.4
## Once he's at it, he builds it up to this.
const FEED_TO := 0.85
## Lit from cold, it flares up for this long; doused, it goes out in this long.
const FLARE_TIME := 0.7
const DOUSE_TIME := 0.5
## From the fire (x, z): the woodpile, a little way off in the camp (far enough that a log
## takes the keeper about 8 s, the author asked on 8 Nov 2026; it was at (3.0, 1.6)), and
## the bucket, to one side of the pit as the camera sees it, so its twinkle isn't lost in
## the flames.
const WOODPILE := Vector2(4.1, 2.2)
const BUCKET := Vector2(-1.15, 1.25)
## Since 23 Nov 2026 the bucket is a pot (the author: "We will replace the bucket which we are using
## to douse ... the fire ... three sticks ... the pot"; their pick, "Tip the pot"). It hung from a
## tripod of three sticks. Since 24 Nov 2026 it hangs as in the author's low-poly reference
## (design/reference/campfire-lowpoly.webp; "the tripod we have in this img looks good we can use
## that"): from a crossbar laid in the forks of two posts stood either side of the pit, by a wire bail
## over the bar. The names stay `bucket`: `bucket` is the foot of the near post, the one he tips it by,
## on the side the bucket stood (TIP_LEG, from the fire), and he works at it from `bucket_spot`,
## BUCKET_STAND out from it: where he did at the tripod's leg (0.62 + 0.6 m out). The bar runs from
## the near post over the pit's middle to the far one.
##   - The posts stand POST_OUT from the pit's middle, just outside its stones, POST_R across,
##     four-sided like squared sticks. Each one's fork opens either side of the bar, under BAR_Y (the
##     bar's middle), its prongs FORK long and FORK_SPREAD off upright. The bar is BAR_R across and
##     runs BAR_OVER past each post.
##   - The pot is ten-sided, POT_R across at its widest and POT_H deep, with a band RIM_H high round
##     its rim and its water WATER_DOWN under the rim. Its bail rises BAIL_UP over the rim from a lug at
##     either end along the bar, over the bar, as the reference's does. It tips on its lugs, so it swings
##     over sideways, off the bar's line, toward the camera's side, where its empty inside shows.
##   - They go up in PARTS' order. In the tutorial the keeper brings them one by one from his box
##     (camp_tutorial.gd `_fetch_pot`), each carried at his right hand (`carry_part`), and puts each up
##     (`put_up`): "something the human sets up slowly taking things from the box one by one".
const TIP_LEG := Vector2(-0.707, 0.707)
const POST_OUT := 0.82
const BUCKET_STAND := 0.4
const POST_R := 0.032
const BAR_Y := 0.92
const BAR_R := 0.028
const BAR_OVER := 0.13
const FORK := 0.1
const FORK_SPREAD := 30.0
const POT_R := 0.22
const POT_H := 0.28
const RIM_H := 0.03
const WATER_DOWN := 0.04
const BAIL_UP := 0.2
const BAIL_R := 0.0055
const PARTS := ["far_post", "near_post", "bar", "pot"]
## Where he stands to lay the bar in the forks: this far out from the pit's middle, square to the bar
## on its far side from the camera.
const BAR_SIDE := 1.0
## Tipped, the pot turns over this far on its lugs, onto its side, pouring into the pit. Its lugs are
## under the bar, so past about 82 degrees its rim would swing through the bar (on the tripod, 115).
const POT_TIP := 80.0
## How the tip looks (24 Nov 2026, after play: "the animation for the tipping over needs to be
## smother"; it snapped over and back). Presentation only: the game reads none of it, and the douse is
## as it was.
##   - While E is held at the post, he shoves at it up on his hind legs (his `push` clip, twice a second),
##     and the pot rocks on its lugs, up to ROCK degrees either way, just after each shove (ROCK_LAG
##     radians behind his clip), more as the hold fills.
##   - Tipped, it swings over to POT_TIP in TIP_SWING, easing in and out. Then it rocks back up to SETTLE
##     degrees and settles (SETTLE_PERIOD, SETTLE_DECAY), never past POT_TIP.
##   - Its water drains as it passes SPILL (degrees), and pours from its rim into the pit for POUR_TIME,
##     POUR_R across at most. The wet spreads over the pit as it pours.
##   - Set back up, it swings upright in RIGHT_TIME, wobbles a little (WOBBLE degrees), and fills again
##     over REFILL_TIME. The wet dries as it rights.
const ROCK := 7.0
const ROCK_RATE := 2.0
const ROCK_LAG := 0.94
const TIP_SWING := 0.55
const SETTLE := 9.0
const SETTLE_PERIOD := 0.6
const SETTLE_DECAY := 0.35
const SPILL := Vector2(12.0, 50.0)
const POUR_TIME := 0.8
const POUR_R := 0.03
const RIGHT_TIME := 0.7
const WOBBLE := 5.0
const REFILL_TIME := 0.5
const STICK := Color("7d4f35")
const IRON := Color("2e3033")
const IRON_RIM := Color("464a4f")
const IRON_IN := Color("1f2123")
const BAIL := Color("a3a8ad")
const POT_WATER := Color("a3c6d4")
## Carried at his right hand: how far out to his side from it, and how far below it (m).
const CARRY_OUT := 0.06
const CARRY_DOWN := 0.02
## Tipping the bucket: how long E is held, how far that's heard, and how far the hiss. The hold is 5 s
## since 24 Nov 2026, as he shoves at the post on his hind legs (the author: "have the push be on for 5
## seconds it seems too easy currently"); it was 1 s.
const TIP_TIME := 5.0
const TIP_NOISE := 2.0
const HISS := 9.0
## From how far his mouth may be from the near post's foot to start tipping it (m), and how far round
## from facing it (degrees). Since 24 Nov 2026; it was 0.6 m and 75 degrees.
const TIP_REACH := 0.95
const TIP_FACING := 120.0
## The bucket twinkles within this many metres.
const GLINT_RANGE := 3.0
const BUCKET_TIN := Color("8a9aa3")
const BUCKET_RIM := Color("5f6d75")
const WATER := Color("2f4d63")
const WET := Color("1d2422")

## Set before it's added (campsite.gd): the camp, and where the keeper stands to stoke it.
var camp
var stoke_at := Vector3.ZERO
var strength := 1.0
var cycle := false
var dying := false
## The open world's on (after the tutorial, or a developer start): the
## firelight (campsite.gd `in_firelight`) and the bucket work only then, so they can't upset
## the tutorial's beats while the keeper builds the fire during it.
var open_world := false
## 1 as it's lit from cold, easing to 0 over FLARE_TIME.
var flare := 0.0
var bucket_tipped := false
var bucket: StaticBody3D
var woodpile: StaticBody3D
## The posts, the bar and the pot are all up over the pit (23 Nov 2026; then a tripod). They are from
## the start, except in the tutorial, where the keeper takes them out of his box and puts them up
## (camp_tutorial.gd).
var pot_up := true

var _dousing := false
## The pot, turning on its lugs as it's tipped (it was the bucket's mesh), and its water; the stand
## and all that hangs on it, and its parts in PARTS' order.
var _bucket_mesh: Node3D
var _pot_water: MeshInstance3D
var _pot_rest := Transform3D.IDENTITY
## The tip as it's drawn (degrees, toward the camera's side), where it set out from, and how long since it
## was tipped or set back up; whether it's being set back up; how long it's rocked; how full it is drawn
## (0–1); and the water pouring from it.
var _tip_shown := 0.0
var _tip_from := 0.0
var _tip_clock := 0.0
var _righting := false
var _rock_clock := 0.0
var _fill := 1.0
var _pour: MeshInstance3D
var _tripod: Node3D
var _parts: Array[Node3D] = []
## A copy of a part, carried at someone's right hand (`carry_part`), and whose hand.
var _carried: Node3D
var _carried_part := -1
var _carrier: Node3D
var _carry_hand: BoneAttachment3D
var _wet: MeshInstance3D
var _glint: Node3D
var _tip: Interactable


func _ready() -> void:
	_build_woodpile()
	_build_bucket()


## As he steals the roasted marshmallow (camp_tutorial.gd): nobody tends it now.
func die_out() -> void:
	dying = true


## The open world's on (the dev menu, the checks): it burns down and is fed, and the
## firelight and the bucket work. `out` starts it cold.
func start_cycle(out := false) -> void:
	cycle = true
	open_world = true
	if out:
		strength = 0.0
		dying = false


## Out, as the level loads when the tutorial's to run (main.gd): the author, 8 Nov 2026,
## "from the start of the tutorial the fire should be off".
func start_out() -> void:
	strength = 0.0
	dying = false


## The tutorial's pan starts (camp_tutorial.gd): the keeper sets about building it, and it
## burns down and is fed from now on; the open world's parts wait for `open`.
func start_building() -> void:
	cycle = true


## The tutorial's done (camp_tutorial.gd): the firelight and the bucket work.
func open() -> void:
	cycle = true
	open_world = true


## True while it's burning at all.
func burning() -> bool:
	return strength > 0.0


## True while the keeper should see to it: the bucket's over, or it wants a log.
func needs_tending() -> bool:
	return cycle and not dying and not _dousing and (bucket_tipped or strength < FEED_BELOW)


## True while the keeper, at it already, should fetch another log.
func wants_more() -> bool:
	return cycle and not dying and not _dousing and (bucket_tipped or strength < FEED_TO)


## A log on it (the keeper): from cold, it catches with a flare.
func add_log() -> void:
	var was_out := strength <= 0.0
	strength = minf(strength + LOG_ADDS, 1.0)
	if was_out:
		flare = 1.0
		lit.emit()


## The keeper sets the bucket back up, full again. It swings upright and fills as it's drawn (`_show_tip`).
func set_bucket_upright() -> void:
	bucket_tipped = false
	_righting = true
	_tip_from = _tip_shown
	_tip_clock = 0.0
	_fill = 0.0


## True while he could tip the bucket (the pot) over.
func can_tip() -> bool:
	return pot_up and open_world and cycle and not dying and not _dousing and not bucket_tipped and strength > 0.0


## The posts, the bar and the pot all up over the pit, or none (the keeper puts them up in the
## tutorial, one by one: `put_up`).
func set_pot_up(on: bool) -> void:
	for part in _parts:
		part.visible = on
	pot_up = on


## Part `i` of PARTS up (the keeper's put it up); the pot's up once all of them are.
func put_up(i: int) -> void:
	_parts[i].visible = true
	pot_up = _parts.all(func(part: Node3D) -> bool: return part.visible)


## How many of PARTS are up.
func parts_up() -> int:
	return _parts.filter(func(part: Node3D) -> bool: return part.visible).size()


## Where the keeper stands to put part `i` up (on the ground), and what he faces there: by each post's
## foot, outside it; square to the bar's middle on the pit's far side for the bar; and where he works
## at the pot from (`bucket_spot`) for the pot.
func part_spot(i: int) -> Vector3:
	match PARTS[i]:
		"far_post":
			return global_position + _along() * -(POST_OUT + BUCKET_STAND)
		"bar":
			return global_position + _along().cross(Vector3.UP).normalized() * BAR_SIDE
	return bucket_spot()


func part_look(i: int) -> Vector3:
	match PARTS[i]:
		"far_post":
			return global_position + _along() * -POST_OUT
		"near_post":
			return bucket.global_position
	return global_position


## A copy of part `i` at `carrier`'s right hand (camp_person.gd `hand_grip`, on their hand bone), as
## the pizza's boxes are carried (pizza_boxes.gd): a post or the bar level along the way they face,
## the pot hung from its bail. Till `drop_carried`; shown or not by `show_carried`.
func carry_part(i: int, carrier: Node3D) -> void:
	drop_carried()
	var skeletons := carrier.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		return
	_carry_hand = BoneAttachment3D.new()
	_carry_hand.bone_name = "mano_L"
	skeletons[0].add_child(_carry_hand)
	_carried = _parts[i].duplicate()
	_carried.visible = true
	_carried.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if PARTS[i] == "pot":
		# Upright and full, however the pot over the pit was left (a fixture can tip it while it's down).
		var tipping := _carried.get_child(_bucket_mesh.get_index()) as Node3D
		tipping.transform = _pot_rest
		var water := tipping.get_child(_pot_water.get_index()) as Node3D
		water.visible = true
		water.scale = Vector3.ONE
	add_child(_carried)
	_carried_part = i
	_carrier = carrier
	_follow()


func drop_carried() -> void:
	if _carried:
		_carried.queue_free()
	if _carry_hand:
		_carry_hand.queue_free()
	_carried = null
	_carry_hand = null
	_carrier = null
	_carried_part = -1


func show_carried(on: bool) -> void:
	if _carried:
		_carried.visible = on


## True while someone's carrying one of the parts.
func carrying_part() -> bool:
	return _carried != null


## Where the keeper stands to take a log, and to set the bucket up.
func woodpile_spot() -> Vector3:
	var to_fire := (global_position - woodpile.global_position) * Vector3(1, 0, 1)
	return woodpile.global_position + to_fire.normalized() * 0.75


func bucket_spot() -> Vector3:
	var away := (bucket.global_position - global_position) * Vector3(1, 0, 1)
	return bucket.global_position + away.normalized() * BUCKET_STAND


func _process(delta: float) -> void:
	if _carried:
		_follow()
	_show_tip(delta)


## The pot as it's drawn, by the game's state (`bucket_tipped`, the hold at the post), easing between
## them: rocking while E is held, swinging over and settling, pouring, and swinging back up and filling.
func _show_tip(delta: float) -> void:
	if _bucket_mesh == null:
		return
	_tip_clock += delta
	var angle := 0.0
	var wet := 0.0
	var pour := 0.0
	if bucket_tipped:
		if _tip_clock < TIP_SWING:
			angle = lerpf(_tip_from, POT_TIP, _ease(_tip_clock / TIP_SWING))
		else:
			var r := _tip_clock - TIP_SWING
			angle = POT_TIP - SETTLE * exp(-r / SETTLE_DECAY) * (1.0 - cos(TAU * r / SETTLE_PERIOD)) * 0.5
		_fill = minf(_fill, 1.0 - smoothstep(SPILL.x, SPILL.y, angle))
		wet = 1.0 - pow(1.0 - clampf(_tip_clock / POUR_TIME, 0.0, 1.0), 2.0)
		pour = smoothstep(SPILL.x, SPILL.x + 10.0, angle) \
			* (1.0 - smoothstep(POUR_TIME - 0.25, POUR_TIME + 0.15, _tip_clock))
	elif _righting:
		if _tip_clock < RIGHT_TIME:
			angle = lerpf(_tip_from, 0.0, _ease(_tip_clock / RIGHT_TIME))
			wet = 1.0 - _ease(_tip_clock / RIGHT_TIME)
		else:
			var r := _tip_clock - RIGHT_TIME
			angle = -WOBBLE * exp(-r / SETTLE_DECAY) * sin(TAU * r / SETTLE_PERIOD)
			_fill = _ease(r / REFILL_TIME)
			if r > maxf(REFILL_TIME, SETTLE_DECAY * 5.0):
				_righting = false
				_fill = 1.0
	elif _tip and (_tip.working or (_tip.progress > 0.0 and _tip.progress < 1.0)):
		# He's shoving the post: it rocks, more as the hold fills.
		_rock_clock += delta
		angle = ROCK * clampf(_tip.progress, 0.0, 1.0) * sin(TAU * ROCK_RATE * _rock_clock - ROCK_LAG)
	else:
		_rock_clock = 0.0
	_tip_shown = angle
	# The pot's part is turned so its own X runs along the bar, through the lugs, and its Z away from the
	# camera's side: turning back about its X tips its mouth toward the camera.
	_bucket_mesh.transform = Transform3D(Basis(Vector3.RIGHT, -deg_to_rad(angle)), _pot_rest.origin)
	_pot_water.visible = _fill > 0.02
	_pot_water.scale = Vector3(_fill, 1.0, _fill)
	_wet.visible = wet > 0.0
	var spread := lerpf(0.3, 1.0, wet)
	_wet.scale = Vector3(spread, 1.0, spread)
	# The pour: from the lowest point of its rim (on its own -Z, the way it tips) straight down into the
	# pit.
	_pour.visible = pour > 0.02
	if _pour.visible:
		var lip: Vector3 = _bucket_mesh.global_transform * Vector3(0.0, 0.0, -POT_R * 1.05)
		var drop := maxf(lip.y - global_position.y - 0.03, 0.01)
		var width := POUR_R * pour
		_pour.global_transform = Transform3D(Basis().scaled(Vector3(width, drop, width)), lip)


## Eases in and out: 0 at 0, 1 at 1, still at both ends.
func _ease(u: float) -> float:
	return 0.5 - 0.5 * cos(PI * clampf(u, 0.0, 1.0))


## The carried part at the carrier's hand as it's drawn, a little out to their side.
func _follow() -> void:
	if _carry_hand == null or not is_instance_valid(_carrier):
		return
	var grip: Vector3 = _carrier.get("hand_grip") if _carrier.get("hand_grip") != null else Vector3.ZERO
	var hand := _carry_hand.get_global_transform_interpolated() * grip
	var body := _carrier.get_global_transform_interpolated()
	var out := (hand - body.origin) * Vector3(1, 0, 1)
	if out.length() < 0.05:
		out = -body.basis.x
	var at := hand + out.normalized() * CARRY_OUT + Vector3.DOWN * CARRY_DOWN
	var front := (body.basis.z * Vector3(1, 0, 1)).normalized()
	match PARTS[_carried_part]:
		"bar":
			# Its length (its own X) along the way they face, its middle in the hand.
			_carried.global_transform = Transform3D(Basis(front, Vector3.UP, front.cross(Vector3.UP)), at)
		"pot":
			# Hung from its bail, the bail across their side.
			_carried.global_transform = Transform3D(Basis(Vector3.UP, atan2(front.x, front.z)),
				at + Vector3.DOWN * BAIL_UP)
		_:
			# A post: its length (its own Y) along the way they face, held at its middle.
			var basis := Basis(Vector3.UP, front, Vector3.UP.cross(front))
			_carried.global_transform = Transform3D(basis, at - basis * Vector3(0, _crotch() * 0.5, 0))


## Toward the near post from the pit's middle, the way the bar runs.
func _along() -> Vector3:
	var way := TIP_LEG.normalized()
	return Vector3(way.x, 0.0, way.y)


## The crotch of each post's fork, under the bar, which rests between its prongs.
func _crotch() -> float:
	return BAR_Y - BAR_R * 1.6


func _physics_process(delta: float) -> void:
	flare = move_toward(flare, 0.0, delta / FLARE_TIME)
	if _dousing:
		strength = move_toward(strength, 0.0, delta / DOUSE_TIME)
		_dousing = strength > 0.0
	elif dying:
		strength = move_toward(strength, 0.0, delta * DIE)
		dying = strength > 0.0
	elif cycle:
		strength = move_toward(strength, 0.0, delta * BURN)
	_glint.set_meta("found", not can_tip())
	var keeper = camp.keeper if camp else null
	if keeper and keeper.state == CampPerson.State.WORK and needs_tending():
		keeper.tend(self)


## Held E at the near post (or a fixture, such as a preview): the pot swings over on its lugs, off the
## bar's line toward the camera's side, and pours into the pit. Its bail stays over the bar. (On the
## tripod it swung away from him; on the bar that way it would swing through the bar.)
func douse() -> void:
	bucket_tipped = true
	_dousing = true
	flare = 0.0
	# It swings over as it's drawn (`_show_tip`), from wherever its rocking had it.
	_righting = false
	_tip_from = _tip_shown
	_tip_clock = 0.0
	camp.noise(global_position, HISS)
	doused.emit()


func _build_woodpile() -> void:
	woodpile = StaticBody3D.new()
	woodpile.position = Vector3(WOODPILE.x, 0, WOODPILE.y)
	woodpile.rotation.y = deg_to_rad(-20.0)
	add_child(woodpile)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r := 0.075
	var rows := [[-0.17, -0.0, 0.17], [-0.085, 0.085]]
	for level in rows.size():
		for x: float in rows[level]:
			var y := r + level * r * 1.7
			var log := LowPoly.loft([Vector3(x, y, -0.42), Vector3(x, y, 0.42)], [Vector2(r, r), Vector2(r, r)], 7,
				func(segment: int, _side: int, _n: Vector3) -> Color: return Forest.WOOD if segment != 0 else Forest.LOG)
			st.append_from(log, 0, Transform3D.IDENTITY)
	_add_mesh(LowPoly.commit(st), woodpile)
	# No collider: low enough to step over, and solid it rerouted the campers' walks round
	# the camp, which the camp check times (it failed with the pile at its farther place).


## The stand over the pit, as in the author's reference (24 Nov 2026; a tripod from 23 Nov, and before
## that a bucket beside the pit, at BUCKET): two forked posts, the bar in their forks, and the pot hung
## from the bar by its bail. Each is a part of its own, in PARTS' order, shown as it's put up. No
## colliders, as the tripod had none, so the campers' walkways are baked as before. `bucket` is the
## near post's foot, which he tips the pot by.
func _build_bucket() -> void:
	_tripod = Node3D.new()
	add_child(_tripod)
	var along := _along()
	var across := along.cross(Vector3.UP).normalized()
	# Each part is turned so its own X runs across the bar (the posts' forks) or along it (the bar, and
	# the pot's lugs).
	var turn_across := atan2(-across.z, across.x)
	var turn_along := atan2(-along.z, along.x)
	var top := Vector3(0, _crotch(), 0)
	var spread := deg_to_rad(FORK_SPREAD)
	# The far post, then the near one: squared sticks, each forked at the top either side of the bar.
	for side: float in [-1.0, 1.0]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.append_from(LowPoly.loft([Vector3.ZERO, top], [Vector2(POST_R, POST_R), Vector2(POST_R * 0.85, POST_R * 0.85)],
			4, LowPoly.solid(STICK), PI / 4), 0, Transform3D.IDENTITY)
		for prong: float in [-1.0, 1.0]:
			var way := Vector3(prong * sin(spread), cos(spread), 0.0)
			st.append_from(LowPoly.loft([top - way * 0.012, top + way * FORK],
				[Vector2(POST_R * 0.7, POST_R * 0.7), Vector2(POST_R * 0.45, POST_R * 0.45)], 4, LowPoly.solid(STICK),
				PI / 4), 0, Transform3D.IDENTITY)
		_add_part(LowPoly.commit(st), along * side * POST_OUT, turn_across)
	# The bar, squared too, from past one post to past the other.
	var half := POST_OUT + BAR_OVER
	_add_part(LowPoly.loft([Vector3(-half, 0, 0), Vector3(half, 0, 0)], [Vector2(BAR_R, BAR_R), Vector2(BAR_R, BAR_R)],
		4, LowPoly.solid(STICK), PI / 4), Vector3(0, BAR_Y, 0), turn_along)
	# The pot, its rim at its part's middle, hung by its bail: from one lug up over the bar and down to
	# the other, along the bar. It turns on its lugs as it's tipped; the bail stays where it is.
	var pot_part := _add_part(null, Vector3(0, BAR_Y + BAR_R - BAIL_UP, 0), turn_along)
	var bail: Array = []
	var bail_r: Array = []
	for k in 11:
		var t := PI * k / 10.0
		bail.append(Vector3(POT_R * 1.06 * cos(t), BAIL_UP * sin(t), 0.0))
		bail_r.append(Vector2(BAIL_R, BAIL_R))
	_add_mesh(LowPoly.loft(bail, bail_r, 4, LowPoly.solid(BAIL)), pot_part)
	_bucket_mesh = Node3D.new()
	# Turned in _process as it's drawn (`_show_tip`), so not interpolated between physics ticks.
	_bucket_mesh.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	pot_part.add_child(_bucket_mesh)
	_pot_rest = _bucket_mesh.transform
	_add_mesh(_pot_mesh(), _bucket_mesh)
	_pot_water = _add_mesh(_disc(-WATER_DOWN, POT_R * 0.92, POT_WATER), _bucket_mesh)
	# The water pouring from its rim as it tips: 1 m long and 1 m across, sized as it pours.
	_pour = _add_mesh(LowPoly.loft([Vector3.ZERO, Vector3(0, -1.0, 0)], [Vector2(1.0, 1.0), Vector2(0.7, 0.7)], 5,
		LowPoly.solid(POT_WATER)), self)
	_pour.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_pour.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pour.visible = false
	# The near post's foot, which he tips it by: where he works at it, and what twinkles and takes E.
	bucket = StaticBody3D.new()
	bucket.position = along * POST_OUT
	_tripod.add_child(bucket)
	# The water it poured, dark on the pit.
	_wet = _add_mesh(LowPoly.loft([Vector3(0, 0.004, 0), Vector3(0, 0.006, 0)], [Vector2(0.4, 0.4), Vector2(0.4, 0.4)],
		9, LowPoly.solid(WET)), self)
	_wet.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_wet.visible = false
	# What twinkles: from its foot, as loot does, so the sparkles sit on it.
	_glint = Node3D.new()
	_glint.position = Vector3(0, 0.03, 0)
	_glint.add_to_group("shiny")
	_glint.set_meta("bubble_range", GLINT_RANGE)
	_glint.set_meta("found", true)
	bucket.add_child(_glint)
	_tip = Interactable.new()
	_tip.hold_time = TIP_TIME
	_tip.noise = TIP_NOISE
	_tip.camp = camp
	# Since 24 Nov 2026 (the author: "the E for tipping it over is very specific position"): from further
	# off and from more ways round (it was 0.6 m and interactable.gd's 75 degrees). Holding E, he shoves
	# at the post up on his hind legs, and is brought to it (interactable.gd `push`, player.gd PUSH_AT).
	_tip.reach = TIP_REACH
	_tip.facing = TIP_FACING
	_tip.push = true
	_tip.prompt_height = 0.35
	_tip.position = Vector3(0, 0.25, 0)
	_tip.enabled = can_tip
	_tip.finished.connect(douse)
	bucket.add_child(_tip)


## One of PARTS under the stand, at `at`, turned `turn` about the upright, with `mesh` if any.
func _add_part(mesh: Mesh, at: Vector3, turn: float) -> Node3D:
	var part := Node3D.new()
	part.position = at
	part.rotation.y = turn
	_tripod.add_child(part)
	if mesh:
		_add_mesh(mesh, part)
	_parts.append(part)
	return part


## The pot's shell, its rim at the origin, as the reference's: ten-sided, widest a little under the
## rim and narrowing to a chamfered bottom, a band round the rim, a lug on each side (on its own X) for
## the bail, and open at the top, dark inside down to a floor just under the water.
func _pot_mesh() -> ArrayMesh:
	var sides := 10
	# Up the outside, over the rim and down the inside: each ring's height, its radius (of POT_R), and
	# the colour of the faces from it to the next.
	var profile := [[-POT_H, 0.78, IRON], [-POT_H + 0.035, 0.9, IRON], [-POT_H * 0.3, 1.0, IRON],
		[-RIM_H, 0.98, IRON], [-RIM_H, 1.05, IRON_RIM], [0.0, 1.05, IRON_RIM], [0.0, 0.92, IRON_IN],
		[-WATER_DOWN - 0.01, 0.92, IRON_IN]]
	var rings: Array = []
	for p: Array in profile:
		var ring: Array[Vector3] = []
		for s in sides:
			var a := TAU * s / sides
			ring.append(Vector3(cos(a), 0.0, sin(a)) * p[1] * POT_R + Vector3.UP * p[0])
		rings.append(ring)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in profile.size() - 1:
		# The way out of the surface, in the profile: to the right of going along it.
		var d_r: float = profile[k + 1][1] - profile[k][1]
		var d_y: float = profile[k + 1][0] - profile[k][0]
		for s in sides:
			var a: Vector3 = rings[k][s]
			var b: Vector3 = rings[k][(s + 1) % sides]
			var c: Vector3 = rings[k + 1][(s + 1) % sides]
			var d: Vector3 = rings[k + 1][s]
			var mid := (a + b + c + d) * 0.25
			var radial := Vector3(mid.x, 0.0, mid.z).normalized()
			var inside := mid - (radial * d_y - Vector3.UP * d_r).normalized() * 0.05
			LowPoly.add_tri(st, a, b, c, inside, profile[k][2])
			LowPoly.add_tri(st, a, c, d, inside, profile[k][2])
	# Its bottom, and the floor inside.
	for f: Array in [[0, -1.0, IRON], [profile.size() - 1, 1.0, IRON_IN]]:
		var ring: Array = rings[f[0]]
		var middle := Vector3(0, profile[f[0]][0], 0)
		for s in sides:
			LowPoly.add_tri(st, middle, ring[s], ring[(s + 1) % sides], middle - Vector3.UP * f[1], f[2])
	for side: float in [-1.0, 1.0]:
		LowPoly.add_box(st, Transform3D(Basis(), Vector3(side * POT_R * 1.06, -0.012, 0.0)), Vector3(0.018, 0.04, 0.03),
			IRON_RIM)
	return LowPoly.commit(st)


## A flat ten-sided disc facing up, `y` high and `r` across.
func _disc(y: float, r: float, color: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var middle := Vector3(0, y, 0)
	for s in 10:
		var a := TAU * s / 10.0
		var b := TAU * (s + 1) / 10.0
		LowPoly.add_tri(st, middle, middle + Vector3(cos(a), 0, sin(a)) * r, middle + Vector3(cos(b), 0, sin(b)) * r,
			middle + Vector3.DOWN, color)
	return LowPoly.commit(st)


func _add_mesh(mesh: Mesh, parent: Node) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = camp.forest.night_mesh(mesh) if camp and camp.forest else mesh
	parent.add_child(mi)
	return mi
