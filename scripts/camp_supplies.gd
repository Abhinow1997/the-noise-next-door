extends Node3D
## Raid the supply tent, a level 1 task at the camp (camp_tasks.gd "supplies"), asked for on 23 Nov
## 2026, the author: "we can use the box to create a particular task, in which after the box has been
## removed, it is like a interactable object in which we can potentially hide ... then they get like
## into a task in which we can hide into the box, and then it can be carried inside the somewhere,
## tent ... a particular place which is inaccessible for us generally". Their picks: the keeper's box
## (keeper_box.gd), carried into the green tent, with a stash inside ("Inside the green tent").
##   - The green tent (campsite.gd OTHER_TENT) is walled all round, its door laced shut: from outside
##     there's no way in.
##   - The keeper's box is a hiding spot once the tutorial's done (keeper_box.gd `hide_spot`): he dives
##     in as into the bush, his eyes peeking out.
##   - The keeper takes it there and back as part of his routine (campsite.gd `_keeper_routine`):
##     after stoking the fire he picks it up from by the fire ("take_box"), carries it to the tent's
##     door and puts it in ("store_box"); the next time round he fetches it out ("fetch_box") and sets
##     it by the fire again ("set_box"). Hiding in it, he goes with it, out of sight all the way.
##   - Inside, the tent goes see-through so he can be seen in it (SEE_THROUGH), and its walls hide
##     him from the campers. A move key hops him out of the box, a short way (BOX_HOP_OUT). There's a
##     crate of the campers' cookies (STASH): holding E at it he takes one, sits up and eats it, as he
##     eats the marshmallow and the pizza; the first one eaten ticks the task. E at the door's flap
##     (FLAP) and he slips out under it. Or he hides in the box again, to be carried out.
## Built here in code, like the camp's other props.

const Interactable := preload("res://scripts/interactable.gd")
const LowPoly := preload("res://scripts/lowpoly.gd")
const KeeperBox := preload("res://scripts/keeper_box.gd")
const RaccoonEat := preload("res://scripts/raccoon_eat.gd")

## The green tent in its own space (campsite.gd OTHER_TENT; 2.3 × 2.1 m, 1.2 m tall, its door on its
## +Z side, facing the fire): its walls' half-sizes, height and thickness.
const HALF := Vector2(1.15, 1.05)
const WALL_H := 1.2
const WALL_T := 0.08
## Where the keeper stands outside its door (m out from its middle), where the box goes inside, where
## the flap is (inside, by the door) and where he lands outside it, slipping out (x, z).
const DOOR_OUT := 1.7
const BOX_IN := Vector2(-0.45, 0.35)
const FLAP := Vector2(0.55, 0.85)
const OUT_TO := Vector2(0.55, 1.75)
## The crate of cookies: where, and how many.
const STASH := Vector2(0.6, -0.6)
const COOKIES := 4
## Seen into while he's in it: how see-through it is, and how fast it fades in and out (a second).
const SEE_THROUGH := 0.7
const FADE := 4.0
## How far a move key hops him out of the box in here (m; player.gd DIVE_OUT is 1.5): from BOX_IN, any
## way, still inside its walls.
const BOX_HOP_OUT := 0.45
## The keeper's box steps: how far from the box he stands, on the fire's side (m); how long he bends
## at each; and how far into the bend (seconds left) the box changes hands.
const BOX_STAND := 0.75
const BEND := 1.7
const HANDOFF := 0.9
## The flap: how long E's held to slip under it, and how far that's heard.
const FLAP_TIME := 0.5
const FLAP_NOISE := 1.0
## Eating a cookie: how long E's held, in how many bites, how far the munching's heard, how big it is
## in his paws, and how long and how hard a chomp squashes it.
const EAT_FOR := 2.4
const BITES := 3
const EAT_NOISE := 0.8
const IN_PAWS := 1.0
const SQUASH_FOR := 0.12
const SQUASH := 0.3
const CRATE := Color("8a6a44")
const CRATE_DARK := Color("6d5235")
const COOKIE := Color("c08a52")
const CHIP := Color("4a2e1c")

## Set before it's added (campsite.gd): the camp, the green tent and the keeper's box.
var camp
var tent: Node3D
var box: KeeperBox
## Where the box sits by the fire (keeper_box.gd `spot`), in the camp's space.
var box_home := Vector3.ZERO
## The box is inside the tent; cookies eaten so far.
var in_tent := false
var eaten := 0

var _player
var _walls: StaticBody3D
var _meshes: Array[GeometryInstance3D] = []
var _seen := 0.0
var _flap: Interactable
var _eat: Interactable
var _cookies: Array[MeshInstance3D] = []
## The keeper's box step last acted on (his step's index), so each acts once a visit.
var _done_step := -1
## The cookie in his paws while he eats it, and how much of it's eaten.
var _cookie: MeshInstance3D
var _bitten := 0.0


## Where the keeper stands outside the tent's door, in the camp's space, from the tent's transform.
static func door_spot(tent_xf: Transform3D) -> Vector3:
	return tent_xf * Vector3(0, 0, DOOR_OUT)


## Where he stands by the box when it's by the fire: BOX_STAND toward the fire from it.
static func box_stand(fire: Vector2) -> Vector3:
	var at := KeeperBox.spot(fire)
	var toward := (Vector3(fire.x, 0, fire.y) - at).normalized()
	return at + toward * BOX_STAND


func _ready() -> void:
	_build_walls()
	for mi in tent.find_children("*", "GeometryInstance3D", true, false):
		_meshes.append(mi)
	_build_stash()
	_flap = Interactable.new()
	_flap.hold_time = FLAP_TIME
	_flap.noise = FLAP_NOISE
	_flap.camp = camp
	_flap.prompt_height = 0.35
	_flap.enabled = func() -> bool: return _player != null and inside(_player.global_position) \
		and _player.hiding_in == null
	_flap.finished.connect(_slip_out)
	tent.add_child(_flap)
	_flap.position = Vector3(FLAP.x, 0.25, FLAP.y)


## True if `at` (the camp's space) is inside the green tent.
func inside(at: Vector3) -> bool:
	var p := tent.global_transform.affine_inverse() * at
	return absf(p.x) < HALF.x - WALL_T and absf(p.z) < HALF.y - WALL_T


## Cookies left in the crate.
func cookies_left() -> int:
	return _cookies.filter(func(c: MeshInstance3D) -> bool: return c.visible and c != _cookie).size()


## Where the box goes inside, where the flap is, where the crate is (the camp's space; for the tests).
func box_in_spot() -> Vector3:
	return tent.global_transform * Vector3(BOX_IN.x, 0, BOX_IN.y)


func flap_point() -> Vector3:
	return _flap.global_position


func stash_point() -> Vector3:
	return _eat.global_position


func _physics_process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		return
	_keeper_moves_box()
	# Hiding in the box, he goes where it goes.
	var in_box: bool = _player.hiding_in == box.hide_spot
	if in_box:
		_player.global_position = box.global_position + Vector3(0, 0.02, 0)
	# Carried, his collider's off, so the keeper doesn't walk into him (player.gd `riding`).
	var ride: bool = in_box and box.carried()
	if _player.riding != ride:
		_player.riding = ride
	# A hiding place once the tutorial's done, when it's down, or while he's in it.
	var open: bool = camp.tasks != null and camp.tasks.revealed and box.visible
	var hideable: bool = open and (not box.carried() or in_box)
	if box.hide_spot.monitoring != hideable:
		box.hide_spot.set_deferred("monitoring", hideable)
	box.hide_spot.hop_out = BOX_HOP_OUT if in_tent else 0.0


## His routine's box steps, each once a visit, as he bends: the box picked up, put in the tent,
## fetched out, set by the fire.
func _keeper_moves_box() -> void:
	var keeper = camp.keeper
	if keeper == null or not box.visible:
		return
	var act: String = keeper.activity()
	if act not in ["take_box", "store_box", "fetch_box", "set_box"]:
		_done_step = -1
		return
	if _done_step == keeper._step or not keeper.at_activity() or keeper._step_left > HANDOFF:
		return
	_done_step = keeper._step
	match act:
		"take_box":
			if not in_tent and not box.carried():
				box.carry(keeper)
		"store_box":
			if box.carrier() == keeper:
				box.put_down(box_in_spot(), tent.global_rotation.y)
				in_tent = true
		"fetch_box":
			if in_tent and not box.carried():
				box.carry(keeper)
				in_tent = false
		"set_box":
			if box.carrier() == keeper:
				box.put_down(box_home, deg_to_rad(KeeperBox.TURN))


func _process(delta: float) -> void:
	if _player == null:
		return
	# See-through while he's in it.
	var want := SEE_THROUGH if inside(_player.global_position) else 0.0
	if not is_equal_approx(_seen, want):
		_seen = move_toward(_seen, want, delta * FADE)
		for mi in _meshes:
			mi.transparency = _seen
	_eat_process()


## E at the flap: under it he slips, out in front of the door.
func _slip_out() -> void:
	_flap.reset()
	if _player:
		_player.hop_to(tent.global_transform * Vector3(OUT_TO.x, 0, OUT_TO.y),
			tent.global_transform * Vector3(0, 0, DOOR_OUT + 2.0))


## Four walls round the tent, its door laced shut: a way in only in the box.
func _build_walls() -> void:
	_walls = StaticBody3D.new()
	tent.add_child(_walls)
	for side: Array in [[Vector3(0, 0, HALF.y), Vector3(HALF.x * 2, WALL_H, WALL_T)],
			[Vector3(0, 0, -HALF.y), Vector3(HALF.x * 2, WALL_H, WALL_T)],
			[Vector3(HALF.x, 0, 0), Vector3(WALL_T, WALL_H, HALF.y * 2)],
			[Vector3(-HALF.x, 0, 0), Vector3(WALL_T, WALL_H, HALF.y * 2)]]:
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = side[1]
		col.shape = shape
		col.position = side[0] + Vector3(0, WALL_H * 0.5, 0)
		_walls.add_child(col)


## The crate of cookies in the back corner, and the E to eat one.
func _build_stash() -> void:
	var crate := Node3D.new()
	tent.add_child(crate)
	crate.position = Vector3(STASH.x, 0, STASH.y)
	crate.rotation.y = 0.3
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	LowPoly.add_box(st, Transform3D(Basis(), Vector3(0, 0.01, 0)), Vector3(0.36, 0.02, 0.26), CRATE_DARK)
	for x: float in [-1.0, 1.0]:
		LowPoly.add_box(st, Transform3D(Basis(), Vector3(x * 0.17, 0.06, 0)), Vector3(0.02, 0.1, 0.26), CRATE)
	for z: float in [-1.0, 1.0]:
		LowPoly.add_box(st, Transform3D(Basis(), Vector3(0, 0.06, z * 0.12)), Vector3(0.36, 0.1, 0.02), CRATE)
	var mi := MeshInstance3D.new()
	mi.mesh = LowPoly.commit(st)
	crate.add_child(mi)
	crate.add_to_group("food")
	for i in COOKIES:
		var cookie := _cookie_mesh()
		cookie.position = Vector3(-0.1 + 0.068 * i, 0.03 + 0.012 * (i % 2), 0.02 * (i % 2))
		crate.add_child(cookie)
		_cookies.append(cookie)
	_eat = Interactable.new()
	_eat.hold_time = EAT_FOR
	_eat.noise = EAT_NOISE
	_eat.camp = camp
	_eat.prompt_height = 0.3
	_eat.enabled = func() -> bool: return _player != null and inside(_player.global_position) \
		and (cookies_left() > 0 or _cookie != null)
	_eat.finished.connect(_ate)
	crate.add_child(_eat)
	_eat.position = Vector3(0, 0.1, 0)


func _cookie_mesh() -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(LowPoly.loft([Vector3(0, 0, 0), Vector3(0, 0.012, 0)], [Vector2(0.03, 0.03), Vector2(0.03, 0.03)], 8,
		LowPoly.solid(COOKIE)), 0, Transform3D.IDENTITY)
	for chip: Vector3 in [Vector3(0.01, 0.013, 0.008), Vector3(-0.012, 0.013, -0.004), Vector3(0.002, 0.013, -0.014)]:
		LowPoly.add_box(st, Transform3D(Basis(), chip), Vector3(0.008, 0.004, 0.008), CHIP)
	var mi := MeshInstance3D.new()
	mi.mesh = LowPoly.commit(st)
	return mi


## Eating while E's held at the crate: a cookie in his paws, bite by bite, sitting up (raccoon_model.gd
## `eating`). Let go, and it goes back, as eaten as it was.
func _eat_process() -> void:
	var model = _player.model
	if model == null:
		return
	if _eat.working and model.paws != null:
		if _cookie == null:
			for c: MeshInstance3D in _cookies:
				if c.visible:
					_cookie = c
					break
			if _cookie == null:
				return
			_cookie.set_meta("was", _cookie.transform)
			_cookie.set_meta("parent", _cookie.get_parent())
			_cookie.reparent(model.paws, false)
			_cookie.transform = Transform3D.IDENTITY
		_bitten = maxf(_bitten, _eat.progress)
		_eat.progress = _bitten
		var f := minf(_bitten * BITES, BITES - 0.001)
		var phase := f - floorf(f)
		model.eating = true
		model.eat_bite = phase
		var bites := clampi(floori(f - RaccoonEat.CHOMP) + 1, 0, BITES)
		var since := phase - RaccoonEat.CHOMP
		var squash := SQUASH * (1.0 - since / SQUASH_FOR) if since >= 0.0 and since < SQUASH_FOR else 0.0
		var size := IN_PAWS * (1.0 - 0.8 * bites / BITES)
		_cookie.scale = Vector3(1.0 + squash * 0.5, 1.0 - squash, 1.0 + squash * 0.5) * size
	elif _cookie != null:
		_cookie.reparent(_cookie.get_meta("parent"), false)
		_cookie.transform = _cookie.get_meta("was")
		_cookie = null
		model.eating = false
		model.eat_bite = -1.0


## A cookie eaten: gone, and the task's done with the first.
func _ate() -> void:
	if _cookie:
		_cookies.erase(_cookie)
		_cookie.queue_free()
		_cookie = null
	_bitten = 0.0
	_eat.reset()
	eaten += 1
	if _player and _player.model:
		_player.model.eating = false
		_player.model.eat_bite = -1.0
	if camp and camp.tasks:
		camp.tasks.done("supplies")
