extends Node3D
## Dismantle the tent, a level 1 task at the camp (camp_tasks.gd "tent"), asked for on
## 8 Nov 2026: "Dismantle the tent: The player must sneak around the perimeter and pull
## out ... structural tent pegs. Once the last peg is removed, the tent collapses"; then
## "we can do 4 pegs ... an E action for our raccoon to dismantle it. So if somebody sees
## him then ... they shoo him away ... the chubby guy tries to fit the tent back in ...
## just dismantle one tent ... don't give any additional details on it. If the user is
## closer to the peg, let the peg have a tinkle on it ... give it E option action ... the
## tent collapses and then all the NPCs are alerted".
##   - The camper's tent (campsite.gd CAMPER_TENT) is staked at its four corners. Each
##     peg twinkles as loot does (thought_bubbles.gd, "shiny") within GLINT_RANGE, and
##     holding E at it (interactable.gd) pulls it out, a little noisily (PULL_NOISE). It
##     lies on the ground by its hole and that corner sags.
##   - Only once the tutorial's done (the list is on the page: camp_tasks.gd `revealed`).
##   - The last peg out: the tent falls in (COLLAPSE_TIME), with a noise, and every one of
##     them is alerted to him (camp_person.gd `alert`). The task's done.
##   - Seen with any of its pegs out, or with it down, the camper, once he's calm again,
##     goes round with his mallet and hammers each one back in (camp_person.gd `pitch`),
##     and the tent stands again. Out unseen, they stay out.

const Interactable := preload("res://scripts/interactable.gd")
const CampPerson := preload("res://scripts/camp_person.gd")

## Where the pegs go, in the tent's own space: its corners, just outside its walls.
const PEGS := [Vector3(-1.2, 0, -1.1), Vector3(1.2, 0, -1.1), Vector3(1.2, 0, 1.1), Vector3(-1.2, 0, 1.1)]
## Pulling one: how long E is held, and how far that's heard.
const PULL_TIME := 1.0
const PULL_NOISE := 1.5
## How much each peg out lets the tent sag, and how flat it falls and how fast. (The fall
## alerts them all to him, rather than making a noise to wonder about.)
const SAG := 0.035
const FLAT := 0.2
const COLLAPSE_TIME := 0.5
const GLINT_RANGE := 2.0

signal collapsed

## Set before it's added (campsite.gd): the camp, the tent (its first child is its
## model), and the peg's mesh.
var camp
var tent: Node3D
var peg_mesh: Mesh
var down := false

## Each peg: {node (its mesh), glint, spot (Interactable), placed (bool), at (its hole)}.
var pegs: Array[Dictionary] = []
var _noticed := false
var _first_out := INF
var _height := 1.0


func _ready() -> void:
	for i in PEGS.size():
		var hole: Vector3 = tent.transform * PEGS[i]
		var mesh := MeshInstance3D.new()
		mesh.mesh = peg_mesh
		# Half as big again as the guy ropes' pegs, so the ones that matter show.
		mesh.scale = Vector3.ONE * 1.5
		mesh.position = hole
		add_child(mesh)
		var glint := Node3D.new()
		glint.position = hole + Vector3(0, 0.03, 0)
		glint.add_to_group("shiny")
		glint.set_meta("bubble_range", GLINT_RANGE)
		glint.set_meta("found", true)
		add_child(glint)
		var spot := Interactable.new()
		spot.hold_time = PULL_TIME
		spot.noise = PULL_NOISE
		spot.camp = camp
		spot.reach = 0.6
		spot.prompt_height = 0.2
		spot.position = hole + Vector3(0, 0.1, 0)
		spot.enabled = pullable.bind(i)
		spot.finished.connect(_pull.bind(i))
		add_child(spot)
		pegs.append({"node": mesh, "glint": glint, "spot": spot, "placed": true, "at": hole})


## True while he can pull peg `i`: the open world's on, it's in, and the tent's up.
func pullable(i: int) -> bool:
	return camp.tasks != null and camp.tasks.revealed and pegs[i].placed and not down


## How many pegs are out.
func out_count() -> int:
	return pegs.filter(func(p: Dictionary) -> bool: return not p.placed).size()


## True while the camper should put it right: it's down, or they've seen him with
## pegs out.
func needs_pitching() -> bool:
	return down or (_noticed and out_count() > 0)


## Where the camper stands to hammer peg `i` back in: just outside it.
func stand_spot(i: int) -> Vector3:
	var out: Vector3 = (pegs[i].at - tent.position) * Vector3(1, 0, 1)
	return pegs[i].at + out.normalized() * 0.45


## The next peg out, or -1.
func next_out() -> int:
	for i in pegs.size():
		if not pegs[i].placed:
			return i
	return -1


## The camper hammers peg `i` back in; with all four in, the tent stands again.
func peg_back(i: int) -> void:
	var peg: Dictionary = pegs[i]
	peg.placed = true
	peg.node.position = peg.at
	peg.node.rotation = Vector3.ZERO
	if out_count() == 0:
		down = false
		_noticed = false
		_first_out = INF


func _physics_process(delta: float) -> void:
	# Someone's seen him since a peg came out: they'll want it put right.
	if out_count() > 0 and camp.last_seen >= _first_out:
		_noticed = true
	for i in pegs.size():
		pegs[i].glint.set_meta("found", not pullable(i))
	var want := FLAT if down else 1.0 - SAG * out_count()
	_height = move_toward(_height, want, delta / COLLAPSE_TIME)
	var model: Node3D = tent.get_child(0)
	model.scale = Vector3(1.0, _height, 1.0)
	if needs_pitching() and camp.camper and camp.camper.state == CampPerson.State.WORK:
		camp.camper.pitch(self)


func _pull(i: int) -> void:
	var peg: Dictionary = pegs[i]
	peg.placed = false
	_first_out = minf(_first_out, camp.clock)
	# Lying on the ground beside its hole.
	var out: Vector3 = (peg.at - tent.position) * Vector3(1, 0, 1)
	peg.node.position = peg.at + out.normalized() * 0.12 + Vector3(0, 0.015, 0)
	peg.node.rotation = Vector3(0, atan2(out.x, out.z), PI * 0.5)
	if out_count() == pegs.size():
		_collapse()


func _collapse() -> void:
	down = true
	for person in camp.people:
		person.alert()
	if camp.tasks:
		camp.tasks.done("tent")
	collapsed.emit()
