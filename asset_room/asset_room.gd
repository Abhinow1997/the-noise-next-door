extends Node3D
## Assignment 3's asset room: my three Blender props at game size, side by side on a
## floor, with the raccoon (raccoon_v2.glb at the game's size 0.8) beside them for scale.
## The light and haze copy the forest level (main.gd), so colours read as they do in play.
## Assignments 4 and 5 reuse this scene.
##
## Controls: drag with either mouse button to orbit, wheel to zoom,
##   1 raccoon, 2 cooler, 3 s'more, 4 pizza slice, 5 donut, 6 round pizza, 7 the camper,
##   8 his dropped beanie, 9 the tent, T the table with a laptop, M and F the male and female humans in their T-pose
##   (the author's downloads, made game-ready on 21 Oct 2026), C the male human dressed as the camper and rigged
##   (he walks; C again plays his next animation: run, bend, take_away, then walk again),
##   K the camper, the chubby man (TiZeta's download, made game-ready on 22 Oct 2026 and chosen as the game's camper,
##   the main NPC; he walks on the spot; K again plays his next animation, as C does),
##   P the low-poly man (TiZeta's too, made game-ready the same way on 23 Oct 2026; P again: his next animation),
##   W the simple girl (TiZeta's as well, made game-ready the same way on 23 Oct 2026; W again: her next animation),
##   0 all of them,
##   (the round pizza is 5 copies of the one pizza-slice asset, turned 45 degrees apart: 5 of 8
##   slices left, as if the raccoon has had the rest; the asset itself is still one slice),
##   G the game's own camera (looks down 27 degrees from 19.2 m, 15-degree lens; no labels),
##   B from below the floor, L labels on and off, Esc quit.
## Screenshot mode, for the build pictures:
##   -- --shot=<file.png> [--view=all|game|below|raccoon|cooler|smore|pizza|donut|whole_pizza|camper|beanie|tent|table|male|female|human_camper|chubby|lowpoly|girl] [--frames=N]
## How a grader opens it (Windows, macOS, Linux, by hand or from the editor) is in README.md, "For the grader".
## The donut started as my practice from the Blender tutorial (assets/practice/donut.blend is
## its life-size, game-ready copy); I may use it in the game later.

const GAME_PITCH := 27.0
const GAME_YAW := -14.0
const GAME_FOV := 15.0
const GAME_DISTANCE := 19.2
const CAMPER_CLIPS := ["walk", "run", "bend", "take_away", "dance", "hammer", "scared", "guard", "shoo", "cower"]
# (the people's animations, keys C, K, P and W; dance and hammer since 23 Oct 2026, for level 1's campsite, and
# scared, guard, shoo and cower the same day, for the campers' reactions; whoever doesn't have one skips it)

@onready var _camera: Camera3D = $Camera3D
@onready var _focus := {
	"raccoon": $Raccoon, "cooler": $Cooler, "smore": $Smore, "pizza": $PizzaSlice, "donut": $Donut,
	"whole_pizza": $WholePizza, "camper": $Camper, "beanie": $BeanieDropped, "tent": $Tent,
	"table": $TableWithLaptop, "male": $HumanMale, "female": $HumanFemale, "human_camper": $HumanCamper,
	"chubby": $ChubbyBoy, "lowpoly": $LowpolyMan, "girl": $SimpleGirl,
}

var _target := Vector3.ZERO
var _yaw := 20.0
var _pitch := 22.0
var _distance := 4.0
var _labels: Array[Label3D] = []
var _shot_path := ""
var _shot_frames := 30
var _frames := 0
var _view := "all"
var _clip := {"human_camper": 0, "chubby": 0, "lowpoly": 0, "girl": 0}   # which of them each one is playing
var _hooked := {}


func _ready() -> void:
	_play_idle($Raccoon)
	_play_camper("human_camper", 0)
	_play_camper("chubby", 0)
	_play_camper("lowpoly", 0)
	_play_camper("girl", 0)
	for key: String in _focus:
		_add_label(_focus[key], key)
	_add_help()
	var view := "all"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_shot_path = arg.get_slice("=", 1)
		elif arg.begins_with("--view="):
			view = arg.get_slice("=", 1)
		elif arg.begins_with("--frames="):
			_shot_frames = int(arg.get_slice("=", 1))
	_set_view(view)


func _process(_delta: float) -> void:
	_place_camera()
	if _shot_path != "":
		_frames += 1
		if _frames == _shot_frames:
			get_viewport().get_texture().get_image().save_png(_shot_path)
			get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask & (MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT):
		_yaw -= event.relative.x * 0.4
		_pitch = clampf(_pitch + event.relative.y * 0.3, -85.0, 85.0)
		_camera.fov = 30.0
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_distance = maxf(_distance * 0.9, 0.05)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_distance = minf(_distance * 1.1, 40.0)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: _set_view("raccoon")
			KEY_2: _set_view("cooler")
			KEY_3: _set_view("smore")
			KEY_4: _set_view("pizza")
			KEY_5: _set_view("donut")
			KEY_6: _set_view("whole_pizza")
			KEY_7: _set_view("camper")
			KEY_8: _set_view("beanie")
			KEY_9: _set_view("tent")
			KEY_T: _set_view("table")
			KEY_M: _set_view("male")
			KEY_F: _set_view("female")
			KEY_C:
				if _view == "human_camper":
					_play_camper("human_camper", _clip["human_camper"] + 1)
				_set_view("human_camper")
			KEY_K:
				if _view == "chubby":
					_play_camper("chubby", _clip["chubby"] + 1)
				_set_view("chubby")
			KEY_P:
				if _view == "lowpoly":
					_play_camper("lowpoly", _clip["lowpoly"] + 1)
				_set_view("lowpoly")
			KEY_W:
				if _view == "girl":
					_play_camper("girl", _clip["girl"] + 1)
				_set_view("girl")
			KEY_0: _set_view("all")
			KEY_G: _set_view("game")
			KEY_B: _set_view("below")
			KEY_L:
				for label in _labels:
					label.visible = not label.visible
			KEY_ESCAPE: get_tree().quit()


func _set_view(view: String) -> void:
	_view = view
	_camera.fov = 30.0
	for label in _labels:
		label.visible = view != "game"       # unreadable at 19.2 m, and they'd hide what's being judged
	if _focus.has(view):
		var box := _bounds(_focus[view])
		_target = box.get_center()
		_distance = maxf(box.size.length() * 2.2, 0.25)
		_yaw = 25.0
		_pitch = 25.0
		return
	var all := _bounds(self)
	_target = all.get_center()
	match view:
		"game":
			_yaw = GAME_YAW
			_pitch = GAME_PITCH
			_distance = GAME_DISTANCE
			_camera.fov = GAME_FOV
		"below":
			_yaw = 20.0
			_pitch = -25.0
			_distance = all.size.length() * 1.3
		_:
			_yaw = 20.0
			_pitch = 22.0
			_distance = all.size.length() * 1.25


func _place_camera() -> void:
	var p := deg_to_rad(_pitch)
	var y := deg_to_rad(_yaw)
	_camera.position = _target + Vector3(sin(y) * cos(p), sin(p), cos(y) * cos(p)) * _distance
	_camera.look_at(_target, Vector3.UP)


## The box round every mesh under `node`, in world space (the floor isn't counted). It's
## measured from the vertices themselves: a turned part's own box, turned, would be bigger
## than the part (the donut, while it was still turned about 17 degrees, measured 0.40 m that
## way, not 0.33 m).
func _bounds(node: Node) -> AABB:
	var meshes := node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D:
		meshes.append(node)
	var box := AABB()
	var first := true
	for m: MeshInstance3D in meshes:
		if m.name == "Floor":
			continue
		var xf := m.global_transform
		for s in m.mesh.get_surface_count():
			for v: Vector3 in m.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
				if first:
					box = AABB(xf * v, Vector3.ZERO)
					first = false
				else:
					box = box.expand(xf * v)
	return box


## A label above each one with its name and the size Godot measures (W x D x H, in metres).
func _add_label(node: Node3D, key: String) -> void:
	var box := _bounds(node)
	var names := {"raccoon": "Raccoon (game size 0.8)", "cooler": "Cooler", "smore": "S'more", "pizza": "Pizza slice",
			"donut": "Donut", "whole_pizza": "Pizza: 5 of 8 slices left", "camper": "Camper",
			"beanie": "Beanie (dropped)", "tent": "Tent (with its guy ropes)",
			"table": "Table with a laptop", "male": "Human, male (T-pose)", "female": "Human, female (T-pose)",
			"human_camper": "Camper on the male human (rigged)", "chubby": "Camper: the chubby man (TiZeta)",
			"lowpoly": "The low-poly man (TiZeta)", "girl": "The simple girl (TiZeta)"}
	var label := Label3D.new()
	label.text = "%s\n%.3f x %.3f x %.3f m" % [names[key], box.size.x, box.size.z, box.size.y]
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.fixed_size = true                  # the same size on screen however close the camera is
	label.pixel_size = 0.00032
	label.font_size = 28
	label.outline_size = 8
	label.no_depth_test = true
	label.position = Vector3(box.get_center().x, box.end.y + 0.06, box.get_center().z)
	add_child(label)
	_labels.append(label)


func _add_help() -> void:
	var layer := CanvasLayer.new()
	var help := Label.new()
	help.text = ("Assignment 3 asset room. Drag: orbit, wheel: zoom. 1 raccoon, 2 cooler, 3 s'more, 4 pizza, 5 donut, 6 round pizza, 7 camper, 8 beanie, 9 tent, T table, M/F humans, C camper on the male (C again: his next animation), K camper (chubby man; K again: his next animation), P low-poly man (P again: his next animation), W simple girl (W again: her next animation), 0 all.\n"
			+ "G: the game's camera (19.2 m away), B: from below, L: labels, Esc: quit. Sizes are W x D x H as Godot measures them.")
	help.position = Vector2(12, 10)
	help.add_theme_color_override("font_color", Color.WHITE)
	help.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	help.add_theme_constant_override("outline_size", 6)
	layer.add_child(help)
	add_child(layer)


## The rigged raccoon's idle loop, if the model has one.
func _play_idle(node: Node) -> void:
	var players := node.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return
	var player: AnimationPlayer = players[0]
	if player.has_animation("idle"):
		player.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
		player.play("idle")


## A camper's animations, one at a time: walk, run, dance, hammer, guard, shoo and cower loop; bend, take_away and
## scared play again after a pause.
func _play_camper(key: String, i: int) -> void:
	var player := _camper_player(key)
	if player == null:
		return
	_clip[key] = i % CAMPER_CLIPS.size()
	for skip in CAMPER_CLIPS.size():
		if player.has_animation(CAMPER_CLIPS[_clip[key]]):
			break
		_clip[key] = (_clip[key] + 1) % CAMPER_CLIPS.size()
	if not _hooked.has(key):
		player.animation_finished.connect(_replay_camper.bind(key))
		_hooked[key] = true
	if player.has_animation(CAMPER_CLIPS[_clip[key]]):
		player.play(CAMPER_CLIPS[_clip[key]])


func _replay_camper(clip: StringName, key: String) -> void:
	await get_tree().create_timer(0.8).timeout
	if CAMPER_CLIPS[_clip[key]] == clip:
		_camper_player(key).stop()
		_camper_player(key).play(clip)


func _camper_player(key: String) -> AnimationPlayer:
	var players: Array = _focus[key].find_children("*", "AnimationPlayer", true, false)
	return null if players.is_empty() else players[0]
