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
## Since 22 Nov 2026 (CHANGE-BRIEF.md, "a frame strip for each of the seven loops") it also writes
## logs/raccoon_loops_preview_frames.log, for the loops' strips:
##   - once, at the top, each copy's place on the screen: `place <clip>: x y w h`, a box in pixels
##     round the copy, as wide as the gap between neighbours (tools/crop_loop_strips.gd crops it);
##   - one line a frame: `frame N: <clip> <frame>/<wraps> ...`, each clip's frame (its position ×
##     24, from 0 to its last frame) and how many times it has wrapped. A clip's second wrap is
##     wraps 1.
## The author's capture, windowed, with Movie Maker, from the project folder:
##   ..\Godot\Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720
##     res://previews/raccoon_loops_preview.tscn --write-movie <folder>/frame.png --fixed-fps 24
##     --quit-after 240 -- --raccoon-loops-preview
## then `tools/crop_loop_strips.gd` cuts each loop's strip from <folder> into captures/loops/r0/.
## Written by Claude Code on 21 Nov 2026; the log added on 22 Nov 2026.

const Main := preload("res://scripts/main.gd")
const RaccoonModel := preload("res://scripts/raccoon_model.gd")
const Night := preload("res://scripts/night.gd")
const LOOPS: Array[String] = ["idle", "walk", "run", "sneak", "bored", "sleep", "climb"]
const LOG := "res://logs/raccoon_loops_preview_frames.log"
## The clips' rate (the importer's, animation/fps=24): a clip's frame is its position × FPS.
const FPS := 24.0
## The box round each copy, from below his paws to above his ears, in metres.
const BOX_BELOW := 0.12
const BOX_ABOVE := 0.85

## The middle of the row, on the ground.
@export var center := Vector3(33.5, 0.0, 4.8)
## Metres between neighbours, across the view.
@export var spacing := 1.15

@onready var level: Node3D = $Level
var _models: Array[Node3D] = []
var _labels: Array[Label3D] = []
var _holders: Array[Node3D] = []
var _wraps: Array[int] = []
var _last_frame: Array[int] = []
var _frame := -1
var _log: FileAccess


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
		_holders.append(holder)
		_wraps.append(0)
		_last_frame.append(-1)
	_log = FileAccess.open(LOG, FileAccess.WRITE)
	_line("Raccoon loops preview: %s in a row at %s, %.2f m apart; each clip at rate 1, its frame = position x %d"
		% [", ".join(LOOPS), center, spacing, FPS])


## Runs after the level's own _process (process_priority 100 in the scene), so the camera the
## level placed on the raccoon is moved onto the row every frame, and after the copies'
## AnimationPlayers have advanced, so a frame's line is the pose drawn in that frame.
func _process(_delta: float) -> void:
	_frame += 1
	_hold_camera()
	if _frame == 1:
		_log_places()
	var cells: PackedStringArray = []
	for i in _models.size():
		var anim: AnimationPlayer = _models[i].get("_anim")
		if anim == null:
			_labels[i].text = "%s\n(no rig)" % LOOPS[i]
			cells.append("%s -" % LOOPS[i])
			continue
		if anim.current_animation != LOOPS[i]:
			# Not started yet (the model starts every copy on idle and changes to its loop on
			# its first frame).
			cells.append("%s -" % LOOPS[i])
			continue
		# Its frame from 0 to its last: at its length it's frame 0 of the next wrap.
		var frames := roundi(anim.current_animation_length * FPS)
		var f := roundi(anim.current_animation_position * FPS) % frames
		if _last_frame[i] >= 0 and f < _last_frame[i]:
			_wraps[i] += 1
		_last_frame[i] = f
		cells.append("%s %d/%d" % [LOOPS[i], f, _wraps[i]])
		_labels[i].text = "%s\n%.2f s  wraps %d" % [anim.current_animation, anim.current_animation_length, _wraps[i]]
	_line("frame %d: %s" % [_frame, " ".join(cells)])


## Each copy's box on the screen, from below his paws to above his ears and as wide as the gap
## to his neighbours, in pixels (x y w h), for tools/crop_loop_strips.gd.
func _log_places() -> void:
	var camera: Camera3D = level.camera
	var view := get_viewport().get_visible_rect().size
	var across := Vector3.RIGHT.rotated(Vector3.UP, deg_to_rad(level.camera_yaw))
	_line("view %d %d" % [view.x, view.y])
	for i in _holders.size():
		var at := _holders[i].global_position
		var left := camera.unproject_position(at - across * spacing / 2.0).x
		var right := camera.unproject_position(at + across * spacing / 2.0).x
		var top := camera.unproject_position(at + Vector3.UP * BOX_ABOVE).y
		var bottom := camera.unproject_position(at - Vector3.UP * BOX_BELOW).y
		var x0 := clampi(floori(minf(left, right)), 0, int(view.x))
		var x1 := clampi(ceili(maxf(left, right)), 0, int(view.x))
		var y0 := clampi(floori(top), 0, int(view.y))
		var y1 := clampi(ceili(bottom), 0, int(view.y))
		_line("place %s: %d %d %d %d" % [LOOPS[i], x0, y0, x1 - x0, y1 - y0])


func _line(text: String) -> void:
	print(text)
	if _log:
		_log.store_line(text)
		_log.flush()


func _hold_camera() -> void:
	var camera: Camera3D = level.camera
	var pitch := deg_to_rad(level.camera_pitch)
	var back := Vector3.BACK.rotated(Vector3.UP, deg_to_rad(level.camera_yaw))
	var focus := center + Main.PIVOT - back * float(level.camera_ahead)
	camera.fov = level.camera_fov
	camera.global_position = focus + (back * cos(pitch) + Vector3.UP * sin(pitch)) * float(level.camera_distance)
	camera.look_at(focus)
