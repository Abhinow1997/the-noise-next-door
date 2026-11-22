extends Node3D
## Step 7's preview of the jump, for the author's Movie Maker frame strip (CHANGE-BRIEF.md, the
## jump's phase table as revised: startup ticks 0-14, the top on 15, landing on 25, the
## landing's end on 37, for a held jump). A fixture, not the game: it sets the scene up for the
## capture and only presses a key.
##   - The background is the game's own level (main.tscn, instanced as Level) at night: the
##     raccoon stands at the camp's edge by the fire, at the developer menu's "free" point.
##   - The campers' cones are off (campsite.gd `cones_on`, as bear_bag_test.gd does), so being
##     seen doesn't break the jump off.
##   - The camera is held at the game's pitch, yaw, field of view, distance and aim on where he
##     took off from, as the game's camera stays at a jump's take-off height (main.gd), and it
##     doesn't drift while he stands.
##   - F is pressed through Input.parse_input_event one frame before `takeoff_frame`, so the game
##     sees it on that frame's first physics tick: takeoff on frame 10. F is held (a held jump)
##     and let go once he's down.
##   - Every frame it writes a line to logs/jump_preview_frames.log: the frame, the physics
##     ticks since takeoff, his height, the game's state (jumping, landing) and the clip with
##     its position, so frame N of the capture can be read against line N.
## Run it windowed, with Movie Maker, from the project folder (the author's capture):
##   ..\Godot\Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720
##     res://previews/jump_preview.tscn --write-movie <folder>/frame.png --fixed-fps 30
##     --quit-after 60 -- --dev-start=free
## Written by Claude Code on 21 Nov 2026.

const Main := preload("res://scripts/main.gd")
const LOG := "res://logs/jump_preview_frames.log"

## The frame the game sees F on: takeoff.
@export var takeoff_frame := 10
## How many frames after landing F is let go.
@export var release_after := 2
## Where he stands for it, a clear spot at the camp's edge with the fire behind him.
@export var stand_at := Vector3(33.5, 0.02, 4.8)

@onready var level: Node3D = $Level
var player: CharacterBody3D
var anim: AnimationPlayer
var _frame := -1
var _ground_y := 0.0
var _takeoff_tick := -1
var _ticks := 0
var _landed_frame := -1
var _focus := Vector3.ZERO
var _log: FileAccess


func _ready() -> void:
	player = level.get("player")
	anim = player.get("model").get("_anim")
	var camp = level.get("campsite")
	if camp:
		camp.set("cones_on", false)
	player.call("place", stand_at)
	player.connect("landed", func() -> void: _landed_frame = _frame)
	_log = FileAccess.open(LOG, FileAccess.WRITE)
	_line("Jump preview: F seen on frame %d (a held jump), %d physics ticks a second, %d frames a second"
		% [takeoff_frame, Engine.physics_ticks_per_second, Engine.max_fps if Engine.max_fps > 0 else 0])
	_line("frame | tick since takeoff | height m | jumping | landing | clip @ position s")


func _physics_process(_delta: float) -> void:
	_ticks += 1
	if _takeoff_tick < 0 and bool(player.get("jumping")):
		_takeoff_tick = _ticks


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == 2:
		_ground_y = player.global_position.y
		_focus = player.global_position
	if _frame == takeoff_frame - 1:
		_key(KEY_F, true)
	if _landed_frame >= 0 and _frame == _landed_frame + release_after:
		_key(KEY_F, false)
	_hold_camera()
	if _frame >= 2:
		var since := (_ticks - _takeoff_tick) if _takeoff_tick >= 0 else -1
		_line("%5d | %18s | %8.3f | %7s | %7s | %s @ %.3f" % [_frame, str(since) if since >= 0 else "-",
			player.global_position.y - _ground_y, player.get("jumping"), player.get("model").get("landing"),
			anim.current_animation if anim.current_animation != "" else "\"\" (%s held)" % anim.assigned_animation,
			anim.current_animation_position])


func _key(keycode: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.physical_keycode = keycode
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _hold_camera() -> void:
	var camera: Camera3D = level.get("camera")
	if camera == null or _frame < 2:
		return
	var pitch := deg_to_rad(float(level.get("camera_pitch")))
	var back := Vector3.BACK.rotated(Vector3.UP, deg_to_rad(float(level.get("camera_yaw"))))
	var focus := _focus + Main.PIVOT - back * float(level.get("camera_ahead"))
	camera.fov = float(level.get("camera_fov"))
	camera.global_position = focus + (back * cos(pitch) + Vector3.UP * sin(pitch)) * float(level.get("camera_distance"))
	camera.look_at(focus)


func _line(text: String) -> void:
	print(text)
	if _log:
		_log.store_line(text)
		_log.flush()
