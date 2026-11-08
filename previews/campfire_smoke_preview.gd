extends Node3D
## Effect B's preview (CHANGE-BRIEF.md, revised 8 Nov 2026, "Effect B, the campfire smoke",
## "The frame strip"). The background is the game's own level (main.tscn, instanced as
## Level): the real fire pit at the camp, with its flames, light and the level's fog, as in
## play. The camera is held on the pit at the game camera's pitch, yaw, field of view,
## distance and aim (main.gd, _place_camera(), at the default zoom), as if he stood at the
## pit, so the smoke is at in-game scale.
## The condition is the real fire's: cold at load (strength 0, its cycle left off so it
## holds); at `light_frame` (10) `logs` (3) logs go on (camp_fire.gd add_log(), 0.3 each:
## strength 0.9, lit from cold with its flare); at `douse_frame` (100) the bucket's tipped
## (douse(), which camp_fire.gd allows a fixture to call), and it goes out in 0.5 s.
## The smoke is one copy of effects/campfire_smoke.tscn at the pit. Its feedback is done
## here for the preview only (the game's wiring is not built yet): every frame, its
## amount_ratio = the fire's strength; amount is never touched. The fixed seed is set here,
## on this copy only. main.gd shows the title screen when it gets no `--` argument, so run
## this with one: `-- --campfire-smoke-preview`. It moves only the camera; the fire's
## changes are the strip's condition, through the fire's own calls.
## Written by Claude Code on 8 Nov 2026.

const CampfireSmoke := preload("res://effects/campfire_smoke.tscn")
const Main := preload("res://scripts/main.gd")
## The fire's script has no class_name: its type comes from here (review fix, 8 Nov 2026).
const CampFire := preload("res://scripts/camp_fire.gd")
## The brief's strip, printed with the fire's strength and the smoke's state at each.
const STRIP := [10, 25, 55, 100, 110, 160]

@export var light_frame := 10
@export var logs := 3
@export var douse_frame := 100
## The fixed seed for the preview's copy.
@export var preview_seed := 7

@onready var level: Node3D = $Level
var fire: CampFire
var smoke: GPUParticles3D
var _frame := -1


## Runs after Level's _ready (it's a child), so the camp and its fire are built.
func _ready() -> void:
	fire = level.campsite.campfire
	# Cold at load, as the strip starts. The cycle stays off, so nothing burns it down and
	# the keeper doesn't come to light it.
	fire.strength = 0.0
	var root := CampfireSmoke.instantiate() as Node3D
	smoke = root.get_node("Smoke") as GPUParticles3D
	smoke.use_fixed_seed = true
	smoke.seed = preview_seed
	smoke.amount_ratio = fire.strength
	add_child(root)
	root.global_position = fire.global_position
	print("Campfire smoke preview: smoke at %s; lit (%d logs) at frame %d, doused at frame %d"
		% [root.global_position, logs, light_frame, douse_frame])


## Runs after the level's own _process (process_priority 100 in the scene), so the camera
## the level placed on the raccoon is moved onto the pit every frame.
func _process(_delta: float) -> void:
	_frame += 1
	_hold_camera()
	if _frame == light_frame:
		for i in logs:
			fire.add_log()
		print("frame %d: lit, %d logs, strength %.2f" % [_frame, logs, fire.strength])
	elif _frame == douse_frame:
		fire.douse()
		print("frame %d: doused" % _frame)
	# The feedback: amount_ratio follows strength; amount never changes.
	smoke.amount_ratio = fire.strength
	if _frame in STRIP:
		print("frame %d: strength %.2f, amount_ratio %.2f, amount %d, emitting %s"
			% [_frame, fire.strength, smoke.amount_ratio, smoke.amount, smoke.emitting])


func _hold_camera() -> void:
	var camera: Camera3D = level.camera
	var pitch := deg_to_rad(level.camera_pitch)
	var back := Vector3.BACK.rotated(Vector3.UP, deg_to_rad(level.camera_yaw))
	# As in play with him at the pit: aimed at the pit, at the pivot's height.
	var focus := fire.global_position + Main.PIVOT - back * float(level.camera_ahead)
	camera.fov = level.camera_fov
	camera.global_position = focus + (back * cos(pitch) + Vector3.UP * sin(pitch)) * float(level.camera_distance)
	camera.look_at(focus)
