extends Node3D
## The tutorial's roasting (camp_tutorial.gd), asked for on 7 Nov 2026: "the human starts
## ... to tend to the fire, and makes one marshmallow, keeps it aside ... keeping them on
## the table ... and then going back to the fire to make more ... while he's going to the
## fire to make a little bit more, the task should be sort of to quickly steal them and
## eat them." The author picked, from Claude Code's options: only while the tutorial runs,
## and one eaten is enough.
##   - A plate on the log behind where the camper roasts, by his backpack (he "keeps it
##     aside"), holding up to MOST roasted marshmallows. It was on the table first; in
##     the first run the camper at the fire saw him there, and it was beside a dancer.
##     They sparkle as loot from far off (thought_bubbles.gd's "shiny", with a range of
##     their own) and count as food (its "food").
##   - start(): the camper's routine becomes roasting at the fire (ROAST_FOR), then
##     turning round with the roasted one in his hand to put it on the plate (SERVE_FOR),
##     then back to the fire, his back to it; the fire keeper eats behind the table
##     meanwhile (from the fire, stoking, he'd face the log). stop() puts both routines
##     back as they were.
##   - E at the plate (interactable.gd, a quick hold) eats one: `eaten`.

signal served
signal eaten

const Interactable := preload("res://scripts/interactable.gd")
const CampPerson := preload("res://scripts/camp_person.gd")
const Campsite := preload("res://scripts/campsite.gd")

## Where the plate stands: along the log behind where the camper roasts (campsite.gd
## LOGS[0], m from its middle toward its south end, past the s'mores), on its top; and
## how many it holds.
const PLATE_ALONG := -0.5
const LOG_TOP := 0.335
const MOST := 3
## Where each roasted marshmallow sits on the plate.
const ON_PLATE := [Vector3(-0.035, 0.0, 0.01), Vector3(0.035, 0.0, -0.005), Vector3(0.0, 0.0, 0.045)]
## The camper's roasting and serving: how long each (seconds). He serves from where he
## roasts, turned round to the plate.
const ROAST_FOR := Vector2(5.0, 6.0)
const SERVE_FOR := Vector2(1.6, 1.9)
## Where he stands to eat: this far south of the plate, past the log's end.
const EAT_FROM := 0.55
## Eating one: how long E is held, and how far its munching is heard (m).
const EAT_TIME := 0.3
const EAT_NOISE := 0.8
## How far off they sparkle (m).
const SPARKLE_RANGE := 16.0
const TOASTED := Color("c98a4a")
const PLATE := Color("e8e4da")

## Set before it's added: the camp (campsite.gd).
var camp
## How many are on the plate.
var on_plate := 0
var running := false

var _plate: Node3D
var _pieces: Array[MeshInstance3D] = []
var _carried: MeshInstance3D
var _eat: Interactable
var _saved := {}
var _last_activity := ""


func _ready() -> void:
	var log: Array = Campsite.LOGS[0]
	var middle: Vector2 = log[0]
	var along := Vector3.RIGHT.rotated(Vector3.UP, deg_to_rad(log[1]))
	_plate = Node3D.new()
	add_child(_plate)
	_plate.global_position = Vector3(middle.x, LOG_TOP, middle.y) + along * PLATE_ALONG
	var dish := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.1
	disc.bottom_radius = 0.095
	disc.height = 0.012
	disc.radial_segments = 14
	disc.material = _flat(PLATE)
	dish.mesh = disc
	dish.position.y = 0.006
	_plate.add_child(dish)
	for at: Vector3 in ON_PLATE:
		var piece := _piece()
		piece.position = at + Vector3(0, 0.012 + 0.014, 0)
		piece.visible = false
		piece.set_meta("bubble_range", SPARKLE_RANGE)
		_plate.add_child(piece)
		_pieces.append(piece)
	_eat = Interactable.new()
	_eat.hold_time = EAT_TIME
	_eat.noise = EAT_NOISE
	_eat.camp = camp
	_eat.prompt_height = 0.2
	_eat.enabled = func() -> bool: return on_plate > 0
	_eat.finished.connect(_eaten)
	_plate.add_child(_eat)


## Starts the camper roasting and serving (and the keeper eating behind the table).
func start() -> void:
	if running:
		return
	running = true
	var camper = camp.camper
	var keeper = camp.keeper
	_saved = {"routine": camper.routine.duplicate(), "step": camper._step}
	var roast: Dictionary = camper.routine[_roast_index(camper.routine)].duplicate()
	roast.time = ROAST_FOR
	# Serving: where he roasts, turned round to the plate.
	var to_plate: Vector3 = _plate.global_position - roast.at
	var serve: Dictionary = camp._activity("serve", roast.at, atan2(to_plate.x, to_plate.z), "bend", 1.0, SERVE_FOR)
	camper.routine.assign([roast, serve])
	_go_to(camper, 0)
	if keeper:
		_saved["keeper_step"] = keeper._step
		_go_to(keeper, 0, 1.0e6)
	_last_activity = camper.activity()


## Puts the routines back as they were.
func stop() -> void:
	if not running:
		return
	running = false
	var camper = camp.camper
	camper.routine.assign(_saved.routine)
	# Back to his own routine where it roasts, so he carries on at the fire.
	_go_to(camper, _roast_index(camper.routine))
	if camp.keeper and _saved.has("keeper_step"):
		_go_to(camp.keeper, _saved.keeper_step)
	if _carried:
		_carried.visible = false


## The plate, in the world (for the tutorial's spotlight and the camera).
func plate_point() -> Vector3:
	return _plate.global_position + Vector3.UP * 0.05


## Where he stands to eat (for the tests): south of the plate, past the log's end.
func eat_from() -> Vector3:
	return _plate.global_position * Vector3(1, 0, 1) + Vector3(0, 0.02, EAT_FROM)


func _physics_process(_delta: float) -> void:
	if not running:
		return
	var camper = camp.camper
	var activity: String = camper.activity()
	# From the fire to the table, a roasted one in his hand; at the table, it's put down.
	if _last_activity == "roast" and activity == "serve" and on_plate < MOST:
		_carry(camper, true)
	if activity == "serve" and camper.at_activity() and _carried and _carried.visible:
		_carry(camper, false)
		_pieces[on_plate].visible = true
		_pieces[on_plate].add_to_group("shiny")
		_pieces[on_plate].add_to_group("food")
		on_plate += 1
		served.emit()
	_last_activity = activity


func _eaten() -> void:
	if on_plate <= 0:
		return
	on_plate -= 1
	_pieces[on_plate].visible = false
	_pieces[on_plate].remove_from_group("shiny")
	_pieces[on_plate].remove_from_group("food")
	eaten.emit()


func _carry(camper, on: bool) -> void:
	if _carried == null:
		var skeletons: Array = camper.find_children("*", "Skeleton3D", true, false)
		if skeletons.is_empty():
			return
		var hand := BoneAttachment3D.new()
		hand.bone_name = "mano_L"
		skeletons[0].add_child(hand)
		_carried = _piece()
		_carried.position = camper.hand_grip
		hand.add_child(_carried)
	_carried.visible = on


func _go_to(person, step: int, stay := -1.0) -> void:
	person._step = step
	person._arrived = false
	if stay > 0.0:
		person._step_left = stay
	else:
		var t: Vector2 = person.routine[step].time
		person._step_left = (t.x + t.y) * 0.5


func _roast_index(routine: Array) -> int:
	for i in routine.size():
		if routine[i].name == "roast":
			return i
	return 0


## A roasted marshmallow: a little toasted cylinder.
func _piece() -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	var body := CylinderMesh.new()
	body.top_radius = 0.019
	body.bottom_radius = 0.02
	body.height = 0.028
	body.radial_segments = 10
	body.material = _flat(TOASTED)
	piece.mesh = body
	piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return piece


func _flat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	return m
