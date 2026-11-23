extends Node3D
## Raid the bear bag, a level 1 task at the camp (camp_tasks.gd "bearbag"), built on
## 10 Nov 2026 from Claude Code's design, at the author's word ("Build it"): real
## campers hang their food high in a tree, out of the reach of bears and raccoons, and
## getting it down is the puzzle.
##   - East of the fire, between it and the camper's tent, stands a tree with one long,
##     low limb reaching back toward the fire (TREE, LIMB_DIR, LIMB_HEIGHT). The campers'
##     food bag hangs from it on a rope that runs over the limb and down to a knot on the
##     trunk.
##   - Two ways to bring it down, once the tutorial's done (camp_tasks.gd `revealed`):
##     chew through the knot at the trunk (hold E, CHEW_KNOT; a little noisy), on the
##     ground and in the open; or climb the trunk, walk out along the limb (player.gd
##     `on_limb`) and chew the rope over the bag (hold E, CHEW_LIMB), up where none of
##     them looks (vision_cone.gd `hidden`). The limb gives under him.
##   - It drops with a thump the campers hear (THUMP), and they come to look. Holding E at
##     its drawstring (OPEN_TIME) opens it: three treats spill out, the camp's best food.
##   - A treat in his stash at his tree ticks the task off, as the marshmallows do.
##   - Caught with a treat, he drops it and it's carried back to the bag (camp_person.gd
##     TAKE). With the bag down and him seen since it fell, or a treat taken back, the
##     camper, once he's calm, puts the treats lying by it back in, ties it shut and
##     hoists it up again (camp_person.gd HANG). Treats in the stash stay his.
## The tree is built here, not in forest.gd, and it's given to the raccoon alone
## (main.gd: player.trees), so the checks that pick trees from the forest's list pick
## the ones they always have. The props are built in code, like the fire pit:
## placeholders for Blender props later.

const Interactable := preload("res://scripts/interactable.gd")
const LowPoly := preload("res://scripts/lowpoly.gd")
const Forest := preload("res://scripts/forest.gd")
const CampPerson := preload("res://scripts/camp_person.gd")
const Player := preload("res://scripts/player.gd")

## Where the tree stands, from the fire (x, z), and the way its limb runs out (x, z).
const TREE := Vector2(5.4, -2.0)
const LIMB_DIR := Vector2(-0.98, -0.2)
## The trunk: its radius at the foot and where the limb leaves it, and how high it goes
## on into its crown.
const TRUNK_R := Vector2(0.22, 0.16)
const TRUNK_TOP := 4.1
## The limb: how high it leaves the trunk, how long it is, its radius at the trunk and at
## its tip, how high on it he walks (its middle's radius), and how far it gives under him
## at its tip (radians at its root).
const LIMB_HEIGHT := 2.6
const LIMB_LENGTH := 2.4
const LIMB_R := Vector2(0.09, 0.045)
const LIMB_SIT := 0.07
const LIMB_BEND := 0.05
## The rope goes over the limb HANG_AT metres out from the trunk's middle; the bag hangs
## DROP below the limb (to its top). How big the bag is, and how high the knot is on the
## trunk.
const HANG_AT := 1.75
const DROP := 0.55
const BAG_SIZE := Vector3(0.36, 0.44, 0.3)
const KNOT_HEIGHT := 0.35
## Chewing: how long E is held at the knot and up on the limb, and how far the gnawing at
## the knot is heard (up on the limb it isn't).
const CHEW_KNOT := 4.0
const KNOT_NOISE := 1.2
const CHEW_LIMB := 2.0
## The fall (m/s²) and how far its thump carries; opening it: how long E is held at the
## drawstring, and how far that's heard. Hoisting it back up takes HOIST_TIME.
const FALL := 14.0
const THUMP := 9.0
const OPEN_TIME := 2.0
const OPEN_NOISE := 1.0
const HOIST_TIME := 1.2
## The knot and the fallen bag twinkle within this (thought_bubbles.gd "shiny"); the
## camper puts back the treats lying this near the bag.
const GLINT_RANGE := 2.0
const GATHER := 2.5
## Where the treats land as it spills, from the bag (x, z).
const SPILL := [Vector2(0.4, 0.05), Vector2(-0.12, 0.4), Vector2(-0.25, -0.34)]

const BARK := Color("5e554b")
const ROPE := Color("c9b58a")
const SACK := Color("2f5d8a")
const SACK_DARK := Color("1f4060")
const COOKIES := Color("c48a4a")
const COOKIE_BAND := Color("efe2c4")
const CHOCOLATE := Color("4a2c1e")
const FOIL := Color("c8ccd0")
const TRAIL_MIX := Color("6f8f3a")
const TRAIL_BAND := Color("e2c25a")

signal dropped

## Set before it's added (campsite.gd): the camp, and the forest (for its night colours
## and its see-through look).
var camp
var forest: Forest
## The tree, for his climbing (player.gd `trees`): forest.gd's `climbable` keys, and its
## `limb`: {from, to (its tip), r (how high on it he walks), bend}.
var tree := {}
## Up in the tree; on the ground (landed); open (spilled).
var hung := true
var down := false
var opened := false
## Where it was cut: "knot", "limb", or "" while it hangs.
var cut_at := ""
## The three treats, the camp's loot (camp_puzzles.gd `_loot`), each with "in_bag" meta.
var treats: Array[RigidBody3D] = []

var _player: Player
var _limb: Node3D
var _knot_rope: MeshInstance3D
var _hang_rope: MeshInstance3D
var _bag: Node3D
var _bag_mesh: MeshInstance3D
var _closed_mesh: Mesh
var _open_mesh: Mesh
var _knot_spot: Interactable
var _limb_spot: Interactable
var _open_spot: Interactable
var _knot_glint: Node3D
var _bag_glint: Node3D
var _falling := false
var _fall_speed := 0.0
var _bag_ground := Vector3.ZERO
var _landed_at := INF
var _noticed := false
var _hoist := 1.0
var _squash := 0.0


func _ready() -> void:
	var from := global_position + Vector3.UP * LIMB_HEIGHT
	tree = {"base": global_position, "top": from, "r0": TRUNK_R.x, "r1": TRUNK_R.y, "clear": TRUNK_R.x + 0.08,
		"limb": {"from": from, "to": from + _run() * LIMB_LENGTH, "r": LIMB_SIT, "bend": LIMB_BEND}}
	_build_tree()
	_build_rope_and_bag()
	_build_spots()
	_build_treats()


# --- Where things are ------------------------------------------------------------

func _run() -> Vector3:
	return Vector3(LIMB_DIR.x, 0.0, LIMB_DIR.y).normalized()


func _side() -> Vector3:
	return _run().cross(Vector3.UP).normalized()


## How far the limb's giving under him (player.gd turns it the same way), if he's on it.
func _bend() -> float:
	if _player and is_same(_player.climbing_tree(), tree):
		return _player.limb_bend()
	return 0.0


## The top of the limb where the rope goes over it.
func over_point() -> Vector3:
	return global_position + Vector3.UP * LIMB_HEIGHT + _run().rotated(_side(), -_bend()) * HANG_AT \
		+ Vector3.UP * LIMB_SIT


## Where the bag's bottom is while it hangs.
func _hang_point() -> Vector3:
	return over_point() - Vector3.UP * (DROP + BAG_SIZE.y)


## The knot on the trunk, on the limb's side.
func knot_at() -> Vector3:
	return global_position + _run() * TRUNK_R.x * 0.95 + Vector3.UP * KNOT_HEIGHT


## The bag, where it is now (its bottom's middle).
func bag_at() -> Vector3:
	return _bag.global_position


## Where the camper stands to gather it up: just past it, away from the trunk.
func bag_spot() -> Vector3:
	var away := (_bag_ground - global_position) * Vector3(1, 0, 1)
	return _bag_ground + away.normalized() * 0.55


## Where the camper stands to tie it off and hoist it: by the knot.
func knot_spot() -> Vector3:
	return global_position + _run() * (TRUNK_R.x + 0.6)


## True while the camper should put it right: it's down, and they've seen him since it
## fell or taken a treat back.
func needs_hanging() -> bool:
	return down and _noticed


func _open_world() -> bool:
	return camp.tasks != null and camp.tasks.revealed


# --- Building ---------------------------------------------------------------------

func _build_tree() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1110
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var crown := Vector3(0, TRUNK_TOP, 0) - _run() * 0.25
	LowPoly.add_tube(st, [Vector3.ZERO, Vector3(0, 0.12, 0), Vector3(0, LIMB_HEIGHT, 0), crown],
		[TRUNK_R.x * 1.35, TRUNK_R.x, TRUNK_R.y, TRUNK_R.y * 0.6], 6, LowPoly.solid(BARK), rng.randf() * TAU,
		[1.7, 1.0, 1.6, 1.05, 1.7, 1.0])
	# Its crown: limbs up from the top of the trunk to clumps of leaves, and none low down
	# but the one with the bag.
	var leaves: Color = Forest.CANOPIES["green"]
	var clumps: Array = [[crown + Vector3(0, 0.55, 0), 1.05]]
	for k in 5:
		var a := TAU * k / 5.0 + rng.randf_range(-0.3, 0.3)
		var d := rng.randf_range(0.8, 1.1)
		clumps.append([crown + Vector3(cos(a) * d, rng.randf_range(-0.3, 0.15), sin(a) * d), rng.randf_range(0.6, 0.8)])
	for clump: Array in clumps:
		var to: Vector3 = clump[0]
		LowPoly.add_tube(st, [crown - Vector3(0, 0.4, 0), crown.lerp(to, 0.5), to], [0.1, 0.07, 0.04], 5,
			LowPoly.solid(BARK))
	for clump: Array in clumps:
		var c := _vary(leaves, 0.05, rng)
		var size: float = clump[1]
		LowPoly.add_icosphere(st, clump[0], Vector3(size, size * 0.85, size), 1, 0.14, rng.randi(),
			func(_n: Vector3) -> Color: return c)
	# The rope's knot round the trunk: a turn of rope, and the knot on the limb's side.
	var ring: Array = []
	var radii: Array = []
	for k in 9:
		var a := TAU * k / 8.0
		ring.append(Vector3(cos(a), 0, sin(a)) * (TRUNK_R.x * 0.98 + 0.012) + Vector3.UP * KNOT_HEIGHT)
		radii.append(0.014)
	LowPoly.add_tube(st, ring, radii, 4, LowPoly.solid(ROPE))
	LowPoly.add_icosphere(st, _run() * (TRUNK_R.x + 0.02) + Vector3.UP * KNOT_HEIGHT, Vector3.ONE * 0.035, 0, 0.1, 3,
		func(_n: Vector3) -> Color: return ROPE)
	_tree_mesh(LowPoly.commit(st), self)

	# The limb, on its own so it can give under him: it turns down about its root.
	_limb = Node3D.new()
	_limb.position = Vector3.UP * LIMB_HEIGHT
	add_child(_limb)
	var st2 := SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tip := _run() * LIMB_LENGTH
	LowPoly.add_tube(st2, [-_run() * 0.05, tip * 0.55, tip], [LIMB_R.x, (LIMB_R.x + LIMB_R.y) * 0.5, LIMB_R.y], 5,
		LowPoly.solid(BARK))
	var twig := tip + _run() * 0.25 + Vector3(0, 0.22, 0)
	LowPoly.add_tube(st2, [tip * 0.9, twig], [LIMB_R.y, 0.02], 4, LowPoly.solid(BARK))
	for k in 2:
		var c := _vary(leaves, 0.05, rng)
		LowPoly.add_icosphere(st2, twig + Vector3(0, 0.1 + 0.15 * k, 0) - _side() * (0.15 - 0.3 * k),
			Vector3(0.32, 0.26, 0.32), 1, 0.14, rng.randi(), func(_n: Vector3) -> Color: return c)
	_tree_mesh(LowPoly.commit(st2), _limb)

	# The trunk's collider, as the forest's trees have (forest.gd _add_tree).
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = TRUNK_R.x + 0.08
	shape.height = 2.0
	col.shape = shape
	col.position.y = 1.0
	body.add_child(col)
	add_child(body)


func _tree_mesh(mesh: Mesh, parent: Node) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = forest.night_mesh(mesh) if forest else mesh
	if forest:
		mi.material_override = forest.see_through
	parent.add_child(mi)


func _build_rope_and_bag() -> void:
	var rope := LowPoly.box(Vector3(0.022, 1.0, 0.022), ROPE)
	_knot_rope = MeshInstance3D.new()
	_knot_rope.mesh = rope
	add_child(_knot_rope)
	_hang_rope = MeshInstance3D.new()
	_hang_rope.mesh = rope
	add_child(_hang_rope)
	_closed_mesh = _sack_mesh(false)
	_open_mesh = _sack_mesh(true)
	_bag = Node3D.new()
	add_child(_bag)
	_bag_mesh = MeshInstance3D.new()
	_bag_mesh.mesh = _closed_mesh
	_bag.add_child(_bag_mesh)
	_bag.global_position = _hang_point()
	_update_ropes()


## The stuff sack: round, cinched at the top by its drawstring, a dark band round it;
## open, its top's loose and gaping.
func _sack_mesh(open: bool) -> Mesh:
	var h := BAG_SIZE.y
	var w := Vector2(BAG_SIZE.x, BAG_SIZE.z) * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := [w * 0.85, w * 0.8] if open else [w * 0.4, w * 0.22]
	st.append_from(LowPoly.loft(
		[Vector3.ZERO, Vector3(0, 0.05, 0), Vector3(0, h * 0.7, 0), Vector3(0, h * 0.9, 0), Vector3(0, h, 0)],
		[w * 0.75, w, w * 0.95, top[0], top[1]], 8, LowPoly.solid(SACK)), 0, Transform3D.IDENTITY)
	LowPoly.add_box(st, Transform3D(Basis(), Vector3(0, h * 0.45, 0)), Vector3(w.x * 2.02, 0.05, w.y * 2.02), SACK_DARK)
	if open:
		LowPoly.add_box(st, Transform3D(Basis(), Vector3(0, h * 0.99, 0)), Vector3(w.x * 1.4, 0.01, w.y * 1.4), SACK_DARK)
	else:
		LowPoly.add_box(st, Transform3D(Basis(), Vector3(0, h + 0.01, 0)), Vector3(0.05, 0.04, 0.03), ROPE)
	return LowPoly.commit(st)


func _build_spots() -> void:
	_knot_spot = _spot(CHEW_KNOT, KNOT_NOISE, 0.6, 0.3, func() -> bool:
		return _open_world() and hung and _hoist >= 1.0)
	_knot_spot.position = to_local(knot_at())
	_knot_spot.finished.connect(_cut.bind("knot"))
	_limb_spot = _spot(CHEW_LIMB, 0.0, 0.55, 0.25, func() -> bool:
		return _open_world() and hung and _hoist >= 1.0 and _player != null and is_same(_player.climbing_tree(), tree))
	_limb_spot.up_tree = true
	_limb_spot.finished.connect(_cut.bind("limb"))
	_open_spot = _spot(OPEN_TIME, OPEN_NOISE, 0.6, 0.5, func() -> bool:
		return _open_world() and down and not opened)
	_open_spot.finished.connect(_open)
	_knot_glint = _glint(to_local(knot_at()) + Vector3(0, 0.05, 0))
	_bag_glint = _glint(Vector3.ZERO)


func _spot(hold: float, noise: float, reach: float, prompt: float, enabled: Callable) -> Interactable:
	var spot := Interactable.new()
	spot.hold_time = hold
	spot.noise = noise
	spot.camp = camp
	spot.reach = reach
	spot.prompt_height = prompt
	spot.enabled = enabled
	add_child(spot)
	return spot


func _glint(at: Vector3) -> Node3D:
	var glint := Node3D.new()
	glint.position = at
	glint.add_to_group("shiny")
	glint.set_meta("bubble_range", GLINT_RANGE)
	glint.set_meta("found", true)
	add_child(glint)
	return glint


## The cookies, the chocolate bar and the trail mix, in the bag to begin with.
func _build_treats() -> void:
	var kinds := [
		[_cookies_mesh(), Vector3(0.14, 0.05, 0.14), Vector3(0, -0.03, -0.07)],
		[_chocolate_mesh(), Vector3(0.16, 0.025, 0.07), Vector3(0, -0.02, -0.06)],
		[_trail_mix_mesh(), Vector3(0.1, 0.13, 0.06), Vector3(0, -0.06, -0.04)]]
	for kind: Array in kinds:
		var treat: RigidBody3D
		treat = camp.puzzles._loot(kind[0], kind[1], "bearbag", Callable(), kind[2])
		treat.set_meta("reset", _taken_back.bind(treat))
		treat.add_to_group("food")
		treats.append(treat)
		_stow(treat)


func _cookies_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(LowPoly.loft([Vector3.ZERO, Vector3(0, 0.05, 0)], [Vector2(0.07, 0.07), Vector2(0.07, 0.07)], 10,
		LowPoly.solid(COOKIES)), 0, Transform3D.IDENTITY)
	LowPoly.add_box(st, Transform3D(Basis(), Vector3(0, 0.025, 0)), Vector3(0.145, 0.02, 0.05), COOKIE_BAND)
	return LowPoly.commit(st)


func _chocolate_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	LowPoly.add_box(st, Transform3D(Basis(), Vector3(0, 0.0125, 0)), Vector3(0.12, 0.025, 0.07), CHOCOLATE)
	for x: float in [-0.07, 0.07]:
		LowPoly.add_box(st, Transform3D(Basis(), Vector3(x, 0.0125, 0)), Vector3(0.025, 0.027, 0.072), FOIL)
	return LowPoly.commit(st)


func _trail_mix_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(LowPoly.loft([Vector3.ZERO, Vector3(0, 0.02, 0), Vector3(0, 0.11, 0), Vector3(0, 0.13, 0)],
		[Vector2(0.04, 0.022), Vector2(0.05, 0.03), Vector2(0.05, 0.028), Vector2(0.05, 0.006)], 6,
		LowPoly.solid(TRAIL_MIX)), 0, Transform3D.IDENTITY)
	LowPoly.add_box(st, Transform3D(Basis(), Vector3(0, 0.07, 0)), Vector3(0.102, 0.03, 0.062), TRAIL_BAND)
	return LowPoly.commit(st)


func _vary(c: Color, by: float, rng: RandomNumberGenerator) -> Color:
	var d := rng.randf_range(-by, by)
	return Color(clampf(c.r + d, 0, 1), clampf(c.g + d, 0, 1), clampf(c.b + d * 0.5, 0, 1))


# --- What happens ----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player
	_limb.basis = Basis(_side(), -_bend())
	_limb_spot.global_position = over_point()
	if hung and _hoist < 1.0:
		_hoist = minf(_hoist + delta / HOIST_TIME, 1.0)
		_bag.global_position = _bag_ground.lerp(_hang_point(), smoothstep(0.0, 1.0, _hoist))
	elif hung:
		_bag.global_position = _hang_point()
	elif _falling:
		_fall_speed += FALL * delta
		var p := _bag.global_position - Vector3.UP * _fall_speed * delta
		if p.y <= _bag_ground.y:
			p = _bag_ground
			_land()
		_bag.global_position = p
	_squash = move_toward(_squash, 0.0, delta * 5.0)
	_bag.scale = Vector3(1.0 + 0.15 * _squash, 1.0 - 0.25 * _squash, 1.0 + 0.15 * _squash)
	_update_ropes()
	_open_spot.global_position = _bag.global_position + Vector3.UP * 0.2
	_bag_glint.global_position = _bag.global_position + Vector3.UP * 0.25
	_knot_glint.set_meta("found", not (_open_world() and hung and _hoist >= 1.0))
	_bag_glint.set_meta("found", not (_open_world() and down and not opened))
	if _player:
		_stash_check()
	# Seen since it came down: they'll want it hung up again.
	if down and camp.last_seen >= _landed_at:
		_noticed = true
	if needs_hanging() and camp.camper and camp.camper.state == CampPerson.State.WORK:
		camp.camper.hang(self)


func _update_ropes() -> void:
	var over := over_point()
	_knot_rope.visible = cut_at != "knot"
	_hang_rope.visible = hung
	if _knot_rope.visible:
		_span(_knot_rope, knot_at() + _run() * 0.02, over)
	if _hang_rope.visible:
		_span(_hang_rope, over, _bag.global_position + Vector3.UP * BAG_SIZE.y)


## A rope from `a` to `b`: the unit box stretched between them.
func _span(mi: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var d := b - a
	if d.length() < 0.001:
		return
	var y := d.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	mi.global_transform = Transform3D(Basis(x, y * d.length(), x.cross(y)), (a + b) * 0.5)


## Chewed through at the knot or up on the limb: down it comes.
func _cut(where: String) -> void:
	hung = false
	cut_at = where
	_falling = true
	_fall_speed = 0.0
	_bag_ground = Vector3(_bag.global_position.x, global_position.y, _bag.global_position.z)


func _land() -> void:
	_falling = false
	down = true
	_landed_at = camp.clock
	_squash = 1.0
	camp.noise(_bag_ground, THUMP)
	dropped.emit()


## E held at the drawstring: the treats still in it spill out round it.
func _open() -> void:
	opened = true
	_bag_mesh.mesh = _open_mesh
	for i in treats.size():
		var treat := treats[i]
		if treat.get_meta("in_bag", false):
			treat.set_meta("in_bag", false)
			treat.visible = true
			var spill: Vector2 = SPILL[i % SPILL.size()]
			camp.put_down(treat, _bag_ground + Vector3(spill.x, 0.0, spill.y))


## Into the bag, out of play: frozen, solid to nothing, hidden.
func _stow(treat: RigidBody3D) -> void:
	camp.lift(treat)
	treat.visible = false
	treat.set_meta("in_bag", true)
	treat.global_position = _bag.global_position + Vector3.UP * BAG_SIZE.y * 0.5


## Snatched back from him and carried to the bag (camp_person.gd TAKE): back in it, and
## they'll want it hung up again.
func _taken_back(treat: RigidBody3D) -> void:
	_stow(treat)
	_noticed = true


## A treat lying in his stash at his tree ticks the task off (as camp_puzzles.gd does
## for the marshmallows), and it's his from then on.
func _stash_check() -> void:
	for treat: RigidBody3D in treats:
		if not treat.has_meta("camp_loot") or treat == _player.held or treat.get_parent() != camp \
				or treat.get_meta("in_bag", false):
			continue
		var p := treat.global_position - Forest.HOME
		if Vector2(p.x, p.z).length() < Forest.DEN_RADIUS:
			camp.tasks.done(treat.get_meta("camp_loot"))
			treat.remove_meta("camp_loot")


## The camper, at the bag (camp_person.gd HANG): the treats lying by it go back in, and
## he ties it shut.
func gather() -> void:
	for treat: RigidBody3D in treats:
		if not treat.has_meta("camp_loot") or treat == _player.held or treat.get_parent() != camp \
				or treat.get_meta("in_bag", false):
			continue
		var d := (treat.global_position - _bag_ground) * Vector3(1, 0, 1)
		if d.length() < GATHER:
			_stow(treat)
	opened = false
	_bag_mesh.mesh = _closed_mesh
	_open_spot.reset()


## The camper, at the knot (camp_person.gd HANG): a new rope over the limb, and up it goes.
func hoist() -> void:
	gather()
	hung = true
	down = false
	cut_at = ""
	_hoist = 0.0
	_noticed = false
	_landed_at = INF
	_knot_spot.reset()
	_limb_spot.reset()
