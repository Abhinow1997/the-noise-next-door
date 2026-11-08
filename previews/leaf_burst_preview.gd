extends Node3D
## Effect A's preview (CHANGE-BRIEF.md, "The frame strip", and its 7 Nov 2026 revision).
## The background is the game's own level (main.tscn, instanced as Level): the real bush on
## the camp's night grass, with the fire's light and the level's fog, as in play. The camera
## is held on the bush at the game camera's pitch, yaw, field of view, distance and aim
## (main.gd, _place_camera(), at the default zoom), so the burst is at in-game scale.
## At frame `trigger_frame` (10) a fresh copy of the effect fires at the bush, as diving in
## would; with `retrigger` on, a second copy with amount_ratio `retrigger_ratio` (0.5) fires
## at `retrigger_frame` (20), as hopping straight out would, while the first is still alive.
## Each copy is freed on a timer once its longest emitter is done (CLAUDE.md, "Headless
## facts": nothing waits on `finished`). The fixed seed is set here, on these copies only.
## main.gd shows the title screen when it gets no `--` argument, so run this with one, e.g.
## `-- --leaf-burst-preview`; `--retrigger=off` or `--retrigger=on` overrides the export.
## Nothing here writes game state: it reads the bush's position and moves only the camera.
## Written by Claude Code on 7 Nov 2026.

const LeafBurst := preload("res://effects/leaf_burst.tscn")
const Main := preload("res://scripts/main.gd")
## The brief's strip, printed with the bursts alive at each.
const STRIP := [10, 12, 15, 20, 30, 50]

@export var trigger_frame := 10
@export var retrigger := true
@export var retrigger_frame := 20
@export_range(0.0, 1.0) var retrigger_ratio := 0.5
## The fixed seed for the preview's copies (the second copy takes seed + 1).
@export var preview_seed := 7

@onready var level: Node3D = $Level
var _frame := -1
var _bursts := 0
var _alive: Array[Node3D] = []


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--retrigger=off":
			retrigger = false
		elif arg == "--retrigger=on":
			retrigger = true
	print("Leaf burst preview: trigger at frame %d%s" % [trigger_frame,
		", retrigger (amount_ratio %.1f) at frame %d" % [retrigger_ratio, retrigger_frame] if retrigger else ", no retrigger"])


## Runs after the level's own _process (process_priority 100 in the scene), so the camera
## the level placed on the raccoon is moved onto the bush every frame.
func _process(_delta: float) -> void:
	_frame += 1
	_hold_camera()
	if _frame == trigger_frame:
		_burst(1.0, "dive in")
	elif retrigger and _frame == retrigger_frame:
		_burst(retrigger_ratio, "hop out")
	_alive = _alive.filter(func(b: Node3D) -> bool: return is_instance_valid(b) and not b.is_queued_for_deletion())
	if _frame in STRIP:
		print("frame %d: %d burst(s) alive" % [_frame, _alive.size()])


func _bush() -> Vector3:
	return level.campsite.bush.global_position


func _hold_camera() -> void:
	var camera: Camera3D = level.camera
	var pitch := deg_to_rad(level.camera_pitch)
	var back := Vector3.BACK.rotated(Vector3.UP, deg_to_rad(level.camera_yaw))
	# As in play while he's hidden: aimed at him in the bush, at the pivot's height.
	var focus := _bush() + Main.PIVOT - back * float(level.camera_ahead)
	camera.fov = level.camera_fov
	camera.global_position = focus + (back * cos(pitch) + Vector3.UP * sin(pitch)) * float(level.camera_distance)
	camera.look_at(focus)


func _burst(ratio: float, what: String) -> void:
	var burst := LeafBurst.instantiate() as Node3D
	add_child(burst)
	burst.global_position = _bush()
	var longest := 0.0
	for p: GPUParticles3D in burst.get_children():
		p.use_fixed_seed = true
		p.seed = preview_seed + _bursts
		p.amount_ratio = ratio
		p.emitting = true
		longest = maxf(longest, p.lifetime)
	_bursts += 1
	_alive.append(burst)
	get_tree().create_timer(longest + 0.1, false).timeout.connect(burst.queue_free)
	print("frame %d: %s burst at %s, amount_ratio %.1f" % [_frame, what, burst.global_position, ratio])
