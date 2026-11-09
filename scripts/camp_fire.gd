extends Node3D
## The campfire's life in the open world, at the fire pit (campsite.gd builds the pit, its
## flames, light and sparks, and shows them by `strength`). Asked for on 8 Nov 2026: "a
## couple of guys are working towards the campfire ... they are like getting logs ... and
## they're adding logs to it so that it can stay like lit ... and then eventually ...
## dousing the fire", given "naturally, rather than like forcing it ... something that you
## can see, that you can interact with ... everything with E, and ... a small twinkle".
##   - `strength`, 0 (out: ash and charred logs, no light) to 1 (burning well), is the
##     game value the fire's look follows, and the one Effect B's smoke is to follow.
##   - Through the tutorial at the camp it burns steadily, as it always did. As he steals
##     the roasted marshmallow it starts dying (`die_out`): nobody tends it through the
##     chase, and it's out within DIE seconds' worth. Once the tutorial's done
##     (camp_tutorial.gd), its `cycle` starts: it burns down by BURN a second, and the fire
##     keeper (camp_person.gd `tend`) fetches a log from the woodpile whenever it's below
##     FEED_BELOW, lighting it if it's out: it flares up (`flare`), then settles.
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
## 1 as it's lit from cold, easing to 0 over FLARE_TIME.
var flare := 0.0
var bucket_tipped := false
var bucket: StaticBody3D
var woodpile: StaticBody3D

var _dousing := false
var _bucket_mesh: Node3D
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


## The open world's on (camp_tutorial.gd, or the dev menu): it burns down and is fed.
## `out` starts it cold, as after the tutorial.
func start_cycle(out := false) -> void:
	cycle = true
	if out:
		strength = 0.0
		dying = false


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
	_bucket_mesh.transform = Transform3D.IDENTITY
	_wet.visible = false


## True while he could tip the bucket over.
func can_tip() -> bool:
	return cycle and not dying and not _dousing and not bucket_tipped and strength > 0.0


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
	return cycle and burning() and camp != null and camp.cones_on


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
				CampPerson.State.PITCH, CampPerson.State.FIX] and (nearest == null
				or person.global_position.distance_to(player.global_position)
				< nearest.global_position.distance_to(player.global_position)):
			nearest = person
	spotted_at = camp.clock
	camp.saw(player.global_position)
	if nearest:
		nearest.alert()


## Held E at the bucket (or a fixture, such as a preview): over it goes, toward the pit.
func douse() -> void:
	bucket_tipped = true
	_dousing = true
	flare = 0.0
	var toward := (-BUCKET).normalized()
	var axis := Vector3(toward.x, 0, toward.y).cross(Vector3.DOWN).normalized()
	_bucket_mesh.transform = Transform3D(Basis(axis, deg_to_rad(84.0)), Vector3(toward.x, 0, toward.y) * 0.14)
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


func _build_bucket() -> void:
	bucket = StaticBody3D.new()
	bucket.position = Vector3(BUCKET.x, 0, BUCKET.y)
	add_child(bucket)
	_bucket_mesh = Node3D.new()
	bucket.add_child(_bucket_mesh)
	var tub := LowPoly.loft([Vector3(0, 0, 0), Vector3(0, 0.27, 0), Vector3(0, 0.3, 0)],
		[Vector2(0.11, 0.11), Vector2(0.14, 0.14), Vector2(0.145, 0.145)], 10,
		func(segment: int, _side: int, _n: Vector3) -> Color:
			return WATER if segment == 2 else (BUCKET_RIM if segment == 1 else BUCKET_TIN))
	_add_mesh(tub, _bucket_mesh)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.14
	shape.height = 0.3
	col.shape = shape
	col.position = Vector3(0, 0.15, 0)
	bucket.add_child(col)
	# The water it spilt, dark on the ground between it and the pit.
	var toward := (-BUCKET).normalized()
	_wet = _add_mesh(LowPoly.loft([Vector3(0, 0.004, 0), Vector3(0, 0.006, 0)], [Vector2(0.32, 0.22), Vector2(0.32, 0.22)],
		9, LowPoly.solid(WET)), self)
	_wet.position = bucket.position + Vector3(toward.x, 0, toward.y) * 0.38
	_wet.rotation.y = atan2(toward.x, toward.y)
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
	_tip.prompt_height = 0.15
	_tip.position = Vector3(0, 0.25, 0)
	_tip.enabled = can_tip
	_tip.finished.connect(douse)
	bucket.add_child(_tip)


func _add_mesh(mesh: Mesh, parent: Node) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = camp.forest.night_mesh(mesh) if camp and camp.forest else mesh
	parent.add_child(mi)
	return mi
