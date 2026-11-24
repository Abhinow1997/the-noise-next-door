extends Node3D
## The keeper's box at the camp (keeper_box.gd is its look): a hiding place he can drag about, and
## Scare a camper, a level 1 task (camp_tasks.gd "scare"). Asked for on 23 Nov 2026, after riding it
## into the green tent didn't work in play ("everything beyond hiding in the box looks wrong ...
## something other we need to think"), the author: "It can be just like scare a person. So when you
## hide inside the box, maybe we can have like rustling ... F maybe as a key to shuffle the box when
## somebody's around. If anybody whoever is around that box ... when they come to check the box, we
## can jump out to scare them, and then that would be a task ... It doesn't have to be the same guy.
## Anybody. And can we give the ability for the raccoon to like drag the box around? Like like it's a
## block ... similar to what we have done to the cloth."
##   - Once the camp's tasks are revealed it's a hiding place, as the bush is: walking into it, he
##     dives in.
##   - In it, F rustles it: it shakes, and it's a noise HEAR_RUSTLE round (campsite.gd `noise`), so
##     whoever hears it wonders. The nearest of them still going about their routine (or wondering)
##     comes right up to it and bends over it to look (camp_person.gd `check`). Not again for
##     RUSTLE_AGAIN.
##   - In it, E bursts him out, a short hop (BURST_OUT) at the nearest camper within SCARE_REACH:
##     each of them not alarmed already takes fright, as on seeing him (camp_person.gd `scare`), and
##     the task's done. With nobody near, he just pops out toward the camera.
##   - In it, the two keys show over it (camp_input.gd draws them, `prompts`): F, "Make noise", dim
##     till it can rustle again; and E, "Jump out", or "Scare!" while someone's near enough to be
##     frightened. Asked for the same day: "give me option when inside the box make noise and F option".
##   - Out of it, E held at its side takes it in his jaws (player.gd `grip`), as the tablecloth, but
##     free and light (after play: "the box seems difficult to move around its should be free object
##     it feels heavy ... E needs to be along with direction keys for it to move around"): while E's
##     held, the move keys take him and it any way they point, at DRAG_SPEED, facing it, playing his
##     `drag` clip. Anything solid stops it. Letting go of E (or F) lets go, and it stays where it's
##     got to. Till then it went only straight back or ahead, at the cloth's 0.45 m/s, and E toggled.
## Game code: the rustle's noise, who comes to look, the frights, the task and where the box is.

const KeeperBox := preload("res://scripts/keeper_box.gd")
const Interactable := preload("res://scripts/interactable.gd")
const CampPerson := preload("res://scripts/camp_person.gd")
const Player := preload("res://scripts/player.gd")

## The rustle: how far it's heard (m; as his footfalls and landings are, campsite.gd HEAR_STEPS), and
## how soon F rustles it again (s).
const HEAR_RUSTLE := 6.0
const RUSTLE_AGAIN := 1.0
## Bursting out: who's near enough to be scared, from its middle (m); and how far from its middle he
## lands, at them (clear of the box, and of whoever's bent over it, camp_person.gd CHECK_NEAR).
const SCARE_REACH := 2.0
const BURST_OUT := 0.7
## Dragged: how fast he takes it about (m/s; he walks at 2, and drags the cloth at 0.45).
const DRAG_SPEED := 1.4
## Where he takes it in his jaws: how far out from its side and how high (m).
const GRIP_OUT := 0.04
const GRIP_UP := 0.24
## Dragged, what stops it: anything solid on these layers in the way (the ground's left out by
## testing from GROUND_GAP up).
const BLOCK_MASK := 1
const GROUND_GAP := 0.04

## Set before it's added (campsite.gd): the camp and the box.
var camp
var box: KeeperBox
## How many he's scared out of the box so far, and how many rustles (for the tests).
var scared := 0
var rustles := 0

var _player: Player
var _grab: Interactable
var _rustled_at := -INF
## Gripped: the way out from the side he took (level), and where the box is from him.
var _axis := Vector3.ZERO
var _offset := Vector3.ZERO
var _shape: BoxShape3D


func _ready() -> void:
	# After he's moved each tick, so the box goes where he's got to.
	process_physics_priority = 10
	_shape = BoxShape3D.new()
	_shape.size = Vector3(KeeperBox.SIZE.x, KeeperBox.SIZE.y - GROUND_GAP * 2.0, KeeperBox.SIZE.z)
	_grab = Interactable.new()
	_grab.camp = camp
	_grab.prompt_height = 0.35
	_grab.enabled = func() -> bool: return _open() and _player != null and _player.gripping == null
	_grab.finished.connect(_take)
	add_child(_grab)


## True while he's in it.
func inside() -> bool:
	return _player != null and _player.hiding_in == box.hide_spot


## While he's in it, the keys to show over it (camp_input.gd), top first: each {key, text, ready}.
## Out of it, none.
func prompts() -> Array:
	if not inside():
		return []
	return [{"key": "F", "text": "Make noise", "ready": camp.clock >= _rustled_at + RUSTLE_AGAIN},
		{"key": "E", "text": "Scare!" if _scare_near() else "Jump out", "ready": true}]


## True if someone near enough to be scared (SCARE_REACH) would be frightened now.
func _scare_near() -> bool:
	for person: CampPerson in camp.people:
		if _flat(person.global_position - box.global_position).length() <= SCARE_REACH and person.scareable():
			return true
	return false


## True while he has it in his jaws.
func gripped() -> bool:
	return _player != null and _player.gripping == self


## For player.gd `grip`: dragged free, any way, at DRAG_SPEED; the way out from the side he took (for
## a straight pull, unused); and what he faces.
func drag_free() -> bool:
	return true


func drag_speed() -> float:
	return DRAG_SPEED


func pull_axis() -> Vector3:
	return _axis


func face_point() -> Vector3:
	return box.global_position


## player.gd `let_go`: it stays where it's got to.
func released(_by) -> void:
	pass


## Where he takes it in his jaws, on its side toward `from` (for the tests too).
func grip_point(from: Vector3) -> Vector3:
	var side := _side_toward(from)
	var half := Vector3(KeeperBox.SIZE.x, 0.0, KeeperBox.SIZE.z) * 0.5
	var out := absf(side.x) * half.x + absf(side.z) * half.z + GRIP_OUT
	return box.global_position + box.global_basis * (side * out) + Vector3.UP * GRIP_UP


## Once the camp's tasks are revealed, and not while he's in it.
func _open() -> bool:
	return camp.tasks != null and camp.tasks.revealed and box.visible \
		and (_player == null or _player.hiding_in != box.hide_spot)


func _physics_process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player
		return
	# A hiding place once the tasks are out, but not while he's dragging it.
	var hideable: bool = camp.tasks != null and camp.tasks.revealed and box.visible and not gripped()
	if box.hide_spot.monitoring != hideable:
		box.hide_spot.set_deferred("monitoring", hideable)
	# Held only while E is.
	if gripped() and not Input.is_action_pressed("grab"):
		_player.let_go()
	if gripped():
		_drag()
	_grab.global_position = grip_point(_player.global_position)


func _unhandled_input(event: InputEvent) -> void:
	if _player == null or _player.hiding_in != box.hide_spot or _player.input_locked or event.is_echo():
		return
	if event.is_action_pressed("jump"):
		_rustle()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("grab"):
		_burst()
		get_viewport().set_input_as_handled()


## F in the box: it shakes, it's heard, and the nearest who hears it and isn't busy comes to look.
func _rustle() -> void:
	if camp.clock < _rustled_at + RUSTLE_AGAIN:
		return
	_rustled_at = camp.clock
	rustles += 1
	box.rustle()
	var at: Vector3 = box.global_position
	camp.noise(at, HEAR_RUSTLE, 0.0, true)
	var near: Array = []
	for person: CampPerson in camp.people:
		if _flat(person.global_position - at).length() <= HEAR_RUSTLE:
			near.append(person)
	near.sort_custom(func(a, b) -> bool: return _flat(a.global_position - at).length() < _flat(b.global_position - at).length())
	for person: CampPerson in near:
		if person.check(at):
			return


## E in the box: out with a hop at the nearest camper near enough, and a fright for each of them.
func _burst() -> void:
	var at: Vector3 = box.global_position
	var near: Array = []
	for person: CampPerson in camp.people:
		if _flat(person.global_position - at).length() <= SCARE_REACH:
			near.append(person)
	near.sort_custom(func(a, b) -> bool: return _flat(a.global_position - at).length() < _flat(b.global_position - at).length())
	var way := Vector3.ZERO
	if not near.is_empty():
		way = _flat(near[0].global_position - at)
	if way.length() < 0.05:
		var camera := get_viewport().get_camera_3d()
		way = _flat(camera.global_position - at) if camera else box.global_basis.z
	_player.hop_out(way.normalized(), BURST_OUT)
	var frightened := 0
	for person: CampPerson in near:
		if person.scare():
			frightened += 1
	if frightened > 0:
		scared += frightened
		if camp.tasks:
			camp.tasks.done("scare")


## E at its side: in his jaws, to be dragged about while E's held.
func _take() -> void:
	_grab.reset()
	if _player == null:
		return
	_axis = box.global_basis * _side_toward(_player.global_position)
	_axis = _flat(_axis).normalized()
	_offset = _flat(box.global_position - _player.global_position)
	_player.grip(self)


## Gripped, each tick: the box where he's got to, if nothing solid's in the way; if it is, he's held
## where it is.
func _drag() -> void:
	var from: Vector3 = box.global_position
	var want: Vector3 = _player.global_position + _offset
	want.y = from.y
	if want.distance_to(from) < 0.0005:
		return
	var already := _in_the_way(from)
	for rid: RID in _in_the_way(want):
		if rid not in already:
			var back: Vector3 = from - _offset
			_player.global_position = Vector3(back.x, _player.global_position.y, back.z)
			_player.velocity = Vector3.ZERO
			return
	box.global_position = want


## What solid there is where the box would be at `at`, as RIDs (not him, not the ground).
func _in_the_way(at: Vector3) -> Array[RID]:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _shape
	query.transform = Transform3D(box.global_basis, at + Vector3.UP * (GROUND_GAP + _shape.size.y * 0.5))
	query.collision_mask = BLOCK_MASK
	query.exclude = [_player.get_rid()]
	var found: Array[RID] = []
	for hit: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 8):
		found.append(hit.rid)
	return found


## Its side toward `from`, outward, in its own space (±X or ±Z): the one a line from its middle to
## `from` crosses.
func _side_toward(from: Vector3) -> Vector3:
	var to: Vector3 = box.global_basis.inverse() * (from - box.global_position)
	var across := absf(to.x) / (KeeperBox.SIZE.x * 0.5)
	var along := absf(to.z) / (KeeperBox.SIZE.z * 0.5)
	if across >= along:
		return Vector3(1.0 if to.x >= 0.0 else -1.0, 0.0, 0.0)
	return Vector3(0.0, 0.0, 1.0 if to.z >= 0.0 else -1.0)


static func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)
