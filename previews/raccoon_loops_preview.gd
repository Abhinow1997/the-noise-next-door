extends Node3D
## The raccoon's seven loops side by side (CHANGE-BRIEF.md, revised 21 Nov 2026, "every raccoon
## animation meets the assignment's requirements": "My eyes"), for watching each one's seam over
## at least five wraps, at normal speed and at --time-scale 0.25.
## The background is the game's own level (main.tscn, instanced as Level): the camp at night,
## with its light and fog, as in play. Seven copies of his model (scripts/raccoon_model.gd), each
## at his size (player.gd's `size`) and night tint (night.gd), stand in a row across the view at
## `center` (the developer menu's "free" point, at the camp, by default). Each holds one loop
## through the model's own forced_animation, so its AnimationPlayer plays that clip at rate 1 and
## the model's script stays its only writer. Over each is the clip's name, its length and how
## many times it has wrapped so far.
## The camera is held on the row at the game camera's pitch, yaw, field of view, distance and aim
## (main.gd, _place_camera(), at the default zoom). The copies face as he does at the start, side
## on and turned a little toward the camera.
## main.gd shows the title screen when it gets no `--` argument, so run this with one:
## `-- --raccoon-loops-preview`. It moves only the camera and adds its own nodes; it writes nothing
## to the game (the player and the campers carry on as without it, the raccoon far off in the
## forest at his start).
## Written by Claude Code on 21 Nov 2026.

const Main := preload("res://scripts/main.gd")
const RaccoonModel := preload("res://scripts/raccoon_model.gd")
const Night := preload("res://scripts/night.gd")
const LOOPS: Array[String] = ["idle", "walk", "run", "sneak", "bored", "sleep", "climb"]

## The middle of the row, on the ground.
@export var center := Vector3(33.5, 0.0, 4.8)
## Metres between neighbours, across the view.
@export var spacing := 1.15

@onready var level: Node3D = $Level
var _models: Array[Node3D] = []
var _labels: Array[Label3D] = []
var _wraps: Array[int] = []
var _last_pos: Array[float] = []


## Runs after Level's _ready (it's a child), so the camp and the player are built.
func _ready() -> void:
	var size: float = level.player.size
	var yaw := deg_to_rad(level.camera_yaw)
	var across := Vector3.RIGHT.rotated(Vector3.UP, yaw)
	for i in LOOPS.size():
		var holder := Node3D.new()
		holder.name = "Loop_" + LOOPS[i]
		add_child(holder)
		holder.global_position = center + across * spacing * (i - (LOOPS.size() - 1) / 2.0)
		# As he faces at the start (main.gd: -122 deg with the camera's -14), side on and turned
		# a little toward the camera.
		holder.rotation.y = yaw - deg_to_rad(108.0)
		var model := RaccoonModel.new()
		model.scale = Vector3.ONE * size
		model.forced_animation = LOOPS[i]
		holder.add_child(model)
		if Main.NIGHT:
			Night.tint_raccoon(model)
		var label := Label3D.new()
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.font_size = 36
		label.outline_size = 10
		label.pixel_size = 0.004
		add_child(label)
		label.global_position = holder.global_position + Vector3.UP * 0.95
		_models.append(model)
		_labels.append(label)
		_wraps.append(0)
		_last_pos.append(0.0)
	print("Raccoon loops preview: %s in a row at %s, %.2f m apart" % [", ".join(LOOPS), center, spacing])


## Runs after the level's own _process (process_priority 100 in the scene), so the camera the
## level placed on the raccoon is moved onto the row every frame.
func _process(_delta: float) -> void:
	_hold_camera()
	for i in _models.size():
		var anim: AnimationPlayer = _models[i].get("_anim")
		if anim == null:
			_labels[i].text = "%s\n(no rig)" % LOOPS[i]
			continue
		var pos := anim.current_animation_position
		if pos < _last_pos[i] - 0.05:
			_wraps[i] += 1
			print("%s wrapped (%d)" % [LOOPS[i], _wraps[i]])
		_last_pos[i] = pos
		_labels[i].text = "%s\n%.2f s  wraps %d" % [anim.current_animation, anim.current_animation_length, _wraps[i]]


func _hold_camera() -> void:
	var camera: Camera3D = level.camera
	var pitch := deg_to_rad(level.camera_pitch)
	var back := Vector3.BACK.rotated(Vector3.UP, deg_to_rad(level.camera_yaw))
	var focus := center + Main.PIVOT - back * float(level.camera_ahead)
	camera.fov = level.camera_fov
	camera.global_position = focus + (back * cos(pitch) + Vector3.UP * sin(pitch)) * float(level.camera_distance)
	camera.look_at(focus)
