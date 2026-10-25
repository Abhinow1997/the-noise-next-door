extends Node3D
## A place at the campsite the raccoon works at with E, for the camp's puzzles
## (campsite.gd): a press, or a slow job he holds E for (the GDD: "E is the one action
## key"; "hold E" for slow jobs), such as unzipping the backpack tooth by tooth or
## pulling the speaker's plug. Added on 23 Oct 2026 with level 1's first tasks.
##   - He has to be within `reach` of it with his mouth and facing it within `facing`
##     degrees, and not carrying anything unless it's what it `needs`.
##   - camp_input.gd takes the E press (before the raccoon would grab or drop with it),
##     shows the E over the nearest one he can use and a ring while he works at it.
##   - Holding, `progress` fills over `hold_time` seconds; let go or walk off, and it
##     runs back slowly (FALL_BACK). Full, `finished` is emitted.
##   - Working is noisy: every NOISE_EVERY seconds it makes a noise `noise` metres
##     round (campsite.gd `noise`), which the campers may hear.
##   - `enabled` (a Callable returning a bool) can open and close it, for routines and
##     for puzzles already done.

const Player := preload("res://scripts/player.gd")

signal pressed
signal progressed(f: float)
signal finished

const FALL_BACK := 0.15
const NOISE_EVERY := 0.5

## Seconds of holding E it takes; 0 makes it a press.
@export var hold_time := 0.0
@export var reach := 0.7
@export var facing := 75.0
## How far its working noise carries (m); 0 is silent.
@export var noise := 0.0
## The group of what he must be carrying to use it, or "" for an empty mouth.
@export var needs := ""
## Where the E and the ring show, above it.
@export var prompt_height := 0.5

var enabled := Callable()
var camp
var progress := 0.0
## True while he's holding E at it.
var working := false

var _player: Player
var _noise_t := 0.0


func _ready() -> void:
	add_to_group("interactable")


## True if `player` can use it now.
func usable_by(player: Player) -> bool:
	if enabled.is_valid() and not enabled.call():
		return false
	if player.climbing or player.resting or player.is_hopping():
		return false
	var held: Node = player.held
	if needs == "" and held != null:
		return false
	if needs != "" and (held == null or not held.is_in_group(needs)):
		return false
	var mouth: Vector3 = player.model.mouth.global_position
	var to := global_position - mouth
	to.y = 0.0
	if to.length() > reach:
		return false
	var nose := -player.global_basis.z
	nose.y = 0.0
	return to.length() < 0.15 or rad_to_deg(nose.angle_to(to)) <= facing


## E pressed at it (camp_input.gd).
func press(player: Player) -> void:
	_player = player
	pressed.emit()
	if hold_time <= 0.0:
		_finish()
	else:
		working = true


func _physics_process(delta: float) -> void:
	if working and (not Input.is_action_pressed("grab") or not usable_by(_player)):
		working = false
	if working:
		progress = minf(progress + delta / hold_time, 1.0)
		progressed.emit(progress)
		_noise_t -= delta
		if _noise_t <= 0.0 and noise > 0.0 and camp:
			_noise_t = NOISE_EVERY
			camp.noise(global_position, noise)
		if progress >= 1.0:
			working = false
			_finish()
	elif progress > 0.0 and progress < 1.0:
		progress = maxf(progress - FALL_BACK * delta, 0.0)
		progressed.emit(progress)


func _finish() -> void:
	progress = 1.0
	finished.emit()


## Back as it was, for a puzzle that resets.
func reset() -> void:
	working = false
	progress = 0.0
	progressed.emit(0.0)
