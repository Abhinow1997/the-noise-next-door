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
##     roasting waits till it's lit. The open world's parts (the circle of sight, the
##     firelight, the bucket) wait for the tutorial's end (`open`). In the checks that skip
##     the tutorial the cycle's off and it burns steadily, as it always did.
##   - The bucket of water by the pit twinkles as loot does (thought_bubbles.gd, "shiny")
##     while he could tip it: once the open world's on and the fire's lit. Holding E at it
##     (interactable.gd) noses it over: the water floods the pit with a hiss the campers
##     hear (campsite.gd `noise`), and the fire goes out in DOUSE_TIME. The keeper, once
##     he's calm, sets the bucket back up and builds the fire again.
##   - Its circle of sight (8 Nov 2026, the author: "the firepit and the surrounding campsite
##     when the fire is lit should have the vision cone in circle ... where if the raccon runs
##     or walks he gets spotted"): while it burns in the open world, a vision cone all the way
##     round (vision_cone.gd, angle 360, drawn on the ground in the cones' own shader) covers
##     its light (campsite.gd `in_firelight`'s reach), shrinking as it burns down. Moving in it
##     without crouching, he's spotted: the nearest calm camper is alerted to him (camp_person.gd
##     `alert`), and the circle turns red for the cones' RED_TIME. Crouching, or keeping still,
##     he isn't. Hidden in the bush, it can't see him.
## No task on the list and no note: the author asked for no direct hint.
## In the checks that skip the tutorial its cycle is off, so the fire burns as before.

const LowPoly := preload("res://scripts/lowpoly.gd")
const Forest := preload("res://scripts/forest.gd")
const Interactable := preload("res://scripts/interactable.gd")
const CampPerson := preload("res://scripts/camp_person.gd")
const VisionCone := preload("res://scripts/vision_cone.gd")

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
## Since 23 Nov 2026 the bucket is a pot, hung over the pit from a tripod of three sticks (the
## author: "We will replace the bucket which we are using to douse ... the fire ... three sticks
## ... the pot"; their pick, "Tip the pot"). The names stay `bucket`: `bucket` is now the foot of
## the tripod's leg he tips it by, on the side the bucket stood (TIP_LEG, from the fire, and how far
## out its foot is), where he works at it from (`bucket_spot`). The legs' feet are LEG_OUT from the
## pit's middle, a third of a turn apart; they cross at APEX; the pot hangs from there, its bottom
## POT_LOW up, POT_R across and POT_H deep.
const TIP_LEG := Vector2(-0.707, 0.707)
const LEG_OUT := 0.62
const APEX := 1.15
const LEG_R := 0.022
const POT_LOW := 0.4
const POT_R := 0.16
const POT_H := 0.17
## Tipped, the pot turns over this far, pouring into the pit.
const POT_TIP := 115.0
const STICK := Color("6b4a2e")
const ROPE := Color("4a4238")
const IRON := Color("33363a")
const IRON_RIM := Color("50555b")
## Tipping the bucket: how long E is held, how far that's heard, and how far the hiss.
const TIP_TIME := 1.0
const TIP_NOISE := 2.0
const HISS := 9.0
## The bucket twinkles within this many metres.
const GLINT_RANGE := 3.0
## The circle's eyes: how high over the pit they look from, how fast he must be going to
## count as moving (m/s; he sneaks at 1, walks at 2), and how long after the camp last saw
## him before it can spot him again.
const SIGHT_HEIGHT := 1.6
const MOVING := 0.3
const SPOT_AGAIN := 3.0
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
## The open world's on (after the tutorial, or a developer start): the circle of sight, the
## firelight (campsite.gd `in_firelight`) and the bucket work only then, so they can't upset
## the tutorial's beats while the keeper builds the fire during it.
var open_world := false
## 1 as it's lit from cold, easing to 0 over FLARE_TIME.
var flare := 0.0
var bucket_tipped := false
var bucket: StaticBody3D
var woodpile: StaticBody3D
## The tripod and the pot are up over the pit (23 Nov 2026). They are from the start, except in
## the tutorial, where the keeper brings them in his box and puts them up (camp_tutorial.gd).
var pot_up := true

var _dousing := false
## The pot, turning on its handle as it's tipped (it was the bucket's mesh); and the tripod and
## all that hangs on it.
var _bucket_mesh: Node3D
var _pot_rest := Transform3D.IDENTITY
var _tripod: Node3D
var _wet: MeshInstance3D
var _glint: Node3D
var _tip: Interactable
## The circle of sight, and when it last spotted him (camp clock).
var eyes: VisionCone
var spotted_at := -INF


func _ready() -> void:
	_build_woodpile()
	_build_bucket()
	eyes = VisionCone.new()
	eyes.angle = 360.0
	eyes.reach = 6.4
	eyes.driven = true
	eyes.position = Vector3(0, SIGHT_HEIGHT, 0)
	add_child(eyes)
	# Not one of the watchers the alert bubble follows (thought_bubbles.gd): it sees him
	# crouching too, and only spots him moving upright (_watch).
	eyes.remove_from_group("watcher")


## As he steals the roasted marshmallow (camp_tutorial.gd): nobody tends it now.
func die_out() -> void:
	dying = true


## The open world's on (the dev menu, the checks): it burns down and is fed, and the
## circle, the firelight and the bucket work. `out` starts it cold.
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


## The tutorial's done (camp_tutorial.gd): the circle, the firelight and the bucket work.
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


## The keeper sets the bucket back up, full again.
func set_bucket_upright() -> void:
	bucket_tipped = false
	_bucket_mesh.transform = _pot_rest
	_wet.visible = false


## True while he could tip the bucket (the pot) over.
func can_tip() -> bool:
	return pot_up and open_world and cycle and not dying and not _dousing and not bucket_tipped and strength > 0.0


## The tripod and pot up over the pit, or not (the keeper puts them up in the tutorial).
func set_pot_up(on: bool) -> void:
	pot_up = on
	_tripod.visible = on


## Where the keeper stands to take a log, and to set the bucket up.
func woodpile_spot() -> Vector3:
	var to_fire := (global_position - woodpile.global_position) * Vector3(1, 0, 1)
	return woodpile.global_position + to_fire.normalized() * 0.75


func bucket_spot() -> Vector3:
	var away := (bucket.global_position - global_position) * Vector3(1, 0, 1)
	return bucket.global_position + away.normalized() * 0.6


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
	_watch()
	var keeper = camp.keeper if camp else null
	if keeper and keeper.state == CampPerson.State.WORK and needs_tending():
		keeper.tend(self)


## True while the circle of sight is up: burning in the open world, the cones on.
func watching() -> bool:
	return open_world and burning() and camp != null and camp.cones_on


## The circle of sight: as far as the firelight reaches; moving in it upright, he's spotted.
func _watch() -> void:
	var on := watching()
	eyes.blind = not on
	eyes.show_on_ground(on)
	if camp == null or camp._fire_light == null:
		return
	eyes.reach = maxf(camp._fire_light.omni_range * camp.FIRELIGHT, 0.1)
	var red: bool = camp.clock < spotted_at + VisionCone.RED_TIME + VisionCone.FADE_OUT
	eyes.set_look(1.0 if red else 0.0, 1.0)
	var player = eyes.target
	if not on or player == null or not eyes.seeing or player.sneaking:
		return
	if Vector2(player.velocity.x, player.velocity.z).length() < MOVING or camp.seen_within(SPOT_AGAIN):
		return
	var nearest = null
	for person in camp.people:
		if person.state in [CampPerson.State.WORK, CampPerson.State.RETURN, CampPerson.State.TEND,
				CampPerson.State.PITCH, CampPerson.State.HANG, CampPerson.State.FIX] and (nearest == null
				or person.global_position.distance_to(player.global_position)
				< nearest.global_position.distance_to(player.global_position)):
			nearest = person
	spotted_at = camp.clock
	camp.saw(player.global_position)
	if nearest:
		nearest.alert()


## Held E at the tripod's leg (or a fixture, such as a preview): the pot swings over on its handle,
## away from him, and pours into the pit.
func douse() -> void:
	bucket_tipped = true
	_dousing = true
	flare = 0.0
	var away := -TIP_LEG.normalized()
	var axis := Vector3(away.x, 0, away.y).cross(Vector3.DOWN).normalized()
	_bucket_mesh.transform = Transform3D(Basis(axis, deg_to_rad(POT_TIP)), _pot_rest.origin)
	_wet.visible = true
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


## The tripod over the pit and the pot hanging from it (23 Nov 2026; it was a bucket beside the pit,
## at BUCKET). `bucket` is the foot of the leg he tips it by.
func _build_bucket() -> void:
	_tripod = Node3D.new()
	add_child(_tripod)
	var apex := Vector3(0, APEX, 0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 3:
		var way := TIP_LEG.normalized().rotated(TAU * i / 3.0)
		var foot := Vector3(way.x * LEG_OUT, 0.0, way.y * LEG_OUT)
		var beyond := apex + (apex - foot).normalized() * 0.14
		var leg := LowPoly.loft([foot, beyond], [Vector2(LEG_R, LEG_R), Vector2(LEG_R * 0.8, LEG_R * 0.8)], 6,
			LowPoly.solid(STICK))
		st.append_from(leg, 0, Transform3D.IDENTITY)
	# The lashing where they cross, and the cord down to the pot's handle.
	var hook := Vector3(0, POT_LOW + POT_H + 0.12, 0)
	st.append_from(LowPoly.box(Vector3(0.075, 0.07, 0.075), ROPE), 0, Transform3D(Basis(), apex))
	st.append_from(LowPoly.loft([apex, hook], [Vector2(0.006, 0.006), Vector2(0.006, 0.006)], 5, LowPoly.solid(ROPE)),
		0, Transform3D.IDENTITY)
	_add_mesh(LowPoly.commit(st), _tripod)
	# The pot: it turns on its handle, at its rim, as it's tipped.
	_bucket_mesh = Node3D.new()
	_bucket_mesh.position = Vector3(0, POT_LOW + POT_H, 0)
	_pot_rest = _bucket_mesh.transform
	_tripod.add_child(_bucket_mesh)
	var pot := LowPoly.loft([Vector3(0, -POT_H, 0), Vector3(0, -POT_H * 0.45, 0), Vector3(0, -0.012, 0), Vector3(0, 0, 0)],
		[Vector2(POT_R * 0.8, POT_R * 0.8), Vector2(POT_R, POT_R), Vector2(POT_R * 0.94, POT_R * 0.94),
			Vector2(POT_R * 0.97, POT_R * 0.97)], 10,
		func(segment: int, _side: int, _n: Vector3) -> Color: return IRON_RIM if segment == 2 else IRON)
	_add_mesh(pot, _bucket_mesh)
	var inside := SurfaceTool.new()
	inside.begin(Mesh.PRIMITIVE_TRIANGLES)
	inside.append_from(LowPoly.loft([Vector3(0, -0.04, 0), Vector3(0, -0.035, 0)],
		[Vector2(POT_R * 0.9, POT_R * 0.9), Vector2(POT_R * 0.9, POT_R * 0.9)], 10, LowPoly.solid(WATER)), 0, Transform3D.IDENTITY)
	# Its handle: up from each side of the rim to the cord.
	for side: float in [-1.0, 1.0]:
		inside.append_from(LowPoly.loft([Vector3(side * POT_R * 0.97, 0.0, 0.0), Vector3(0, 0.12, 0)],
			[Vector2(0.005, 0.005), Vector2(0.005, 0.005)], 4, LowPoly.solid(IRON)), 0, Transform3D.IDENTITY)
	_add_mesh(LowPoly.commit(inside), _bucket_mesh)
	# The leg he tips it by: where he works at it, and what twinkles and takes E.
	bucket = StaticBody3D.new()
	bucket.position = Vector3(TIP_LEG.normalized().x * LEG_OUT, 0, TIP_LEG.normalized().y * LEG_OUT)
	_tripod.add_child(bucket)
	# The water it poured, dark on the pit.
	_wet = _add_mesh(LowPoly.loft([Vector3(0, 0.004, 0), Vector3(0, 0.006, 0)], [Vector2(0.4, 0.4), Vector2(0.4, 0.4)],
		9, LowPoly.solid(WET)), self)
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
	_tip.reach = 0.6
	_tip.prompt_height = 0.35
	_tip.position = Vector3(0, 0.25, 0)
	_tip.enabled = can_tip
	_tip.finished.connect(douse)
	bucket.add_child(_tip)


func _add_mesh(mesh: Mesh, parent: Node) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = camp.forest.night_mesh(mesh) if camp and camp.forest else mesh
	parent.add_child(mi)
	return mi
