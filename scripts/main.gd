extends Node3D
## Builds the forest, the props, the raccoon and the to-do list.
## Debug: `-- --screenshot=out.png [--closeup] [--pose=<state> [--left]]` saves a
## frame and quits; --pose shows the raccoon in one state (see raccoon_sprite.gd).
## `-- --sound-test` runs the automated sound check (scripts/sound_test.gd).

const LowPoly := preload("res://scripts/lowpoly.gd")
const Player := preload("res://scripts/player.gd")
const Forest := preload("res://scripts/forest.gd")
const CameraTuner := preload("res://scripts/camera_tuner.gd")
const RaccoonSprite := preload("res://scripts/raccoon_sprite.gd")
const SoundTest := preload("res://scripts/sound_test.gd")

## The author's generated grass texture (ENV-GROUND in SOURCES.md), repeated every
## GROUND_TILE metres, with GROUND_TINT to darken it. Off: on 6 Oct the author saw
## it in the game and chose the plain grass instead ("i dont like the ground").
const GROUND_TEXTURE := false
const GROUND_PATH := "res://assets/environment/env-ground.jpg"
const GROUND_TILE := 2.5
const GROUND_TINT := Color(1, 1, 1)

## The author's generated stump (ENV-STUMP), cut out by design/environment/make_props.gd.
## STUMP_HEIGHT is its height from the bottom of its roots to its rim, in metres; it
## stands STUMP_LEFT metres left of where he starts and STUMP_NEAR toward the camera.
const STUMP_PATH := "res://assets/environment/stump.png"
const STUMP_METRICS := "res://assets/environment/props.json"
const STUMP_HEIGHT := 0.6
const STUMP_LEFT := 2.2
const STUMP_NEAR := 0.6

## A to-do item ticked off: take B of the author's laugh (SFX-TASK-LAUGH).
const TASK_LAUGH_PATH := "res://assets/audio/sfx/task-laugh.wav"
const TASK_LAUGH_DB := -6.0
## How far the music dips under the laugh, how long the fade at the end takes, and
## how the music is muffled while paused (CHANGE-BRIEF.md, music behaviour).
const DUCK_DB := 4.0
const END_FADE := 3.0
const PAUSE_DB := 8.0
const PAUSE_CUTOFF_HZ := 900.0

const METAL := Color("8f9ba4")
const METAL_DARK := Color("6c7780")
const BIN_INSIDE := Color("454b50")
const CAN := Color("5f7387")
const SILVER := Color("c3c6c8")
const LID := Color("cfc8b8")
## The sky is never seen; this is the haze the far trees fade into.
const HAZE := Color("8fa58c")

## The camera view the author picked with the Tab panel (camera_tuner.gd): it looks
## down 27 degrees from 19.2 m away through a very narrow lens (15 degrees tall),
## turned 14 degrees and aimed just past the raccoon, so the scene reads like a
## tabletop diorama. The player can zoom it but not turn it.
const CAMERA_PITCH := 27.0
const CAMERA_YAW := -14.0
const CAMERA_FOV := 15.0
const CAMERA_DISTANCE := 19.2
## How far past the raccoon the camera aims, which moves him down the screen.
const CAMERA_AHEAD := 0.5
const ZOOM_MIN := 0.5
const ZOOM_MAX := 1.6
## The point on the raccoon that the camera follows and zooms around.
const PIVOT := Vector3(0, 0.27, 0)
## When he's near a camper (a node in the "camper" group), the camera leans this
## share of the way toward the camper, so you can keep watching his routine...
const LEAN := 0.3
## ...starting this far away and fully leaning at half of it.
const LEAN_RANGE := 9.0

## The level's music: a 16-bar loop cut from the generated forest track in
## design/music/ (see SOURCES.md). The WAV's own loop marker makes it repeat seamlessly.
const MUSIC_PATH := "res://assets/audio/music/forest-loop.wav"
## How loud the music sits under the sound effects, and its fade-in time in seconds.
const MUSIC_DB := -9.0
const MUSIC_FADE_IN := 2.0

const INPUTS := {
	"move_forward": [KEY_W, KEY_UP],
	"move_back": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"run": [KEY_SHIFT],
	"sneak": [KEY_CTRL, KEY_C],
	"grab": [KEY_E],
	"chitter": [KEY_SPACE],
}

var player: Player
var camera: Camera3D
var forest: Forest
var bin: RigidBody3D
var lid: RigidBody3D
var gnome: RigidBody3D
var cans: Array[RigidBody3D] = []
var zoom := 1.0
## The camera's settings, starting from the constants above. Tab in the game opens
## a panel (camera_tuner.gd) that changes them live.
var camera_pitch := CAMERA_PITCH
var camera_yaw := CAMERA_YAW
var camera_fov := CAMERA_FOV
var camera_distance := CAMERA_DISTANCE
var camera_ahead := CAMERA_AHEAD

var tasks := [
	{"id": "bin", "text": "Knock over the trash bin", "done": false},
	{"id": "lid", "text": "Steal the bin lid", "done": false},
	{"id": "cans", "text": "Stash 3 cans in your den", "done": false},
	{"id": "gnome", "text": "Kidnap the garden gnome", "done": false},
	{"id": "nap", "text": "Sneak into your den for a nap", "done": false},
]

var _todo: RichTextLabel
var _banner: Label
var _tuner: CameraTuner
var _cans_in_den := 0
var _nap_time := 0.0
var _sleep_time := 0.0
var _rng := RandomNumberGenerator.new()
var _closeup := false
var _grab_test := false
var _climb_test := false
var _shot_path := ""
var _frames := 0
var _zoom_now := 1.0
## Where the camera thinks the raccoon is; it trails him slightly for smoothness.
var _anchor := Vector3.ZERO
var _music: AudioStreamPlayer
var _music_tween: Tween
var _task_laugh: AudioStreamPlayer
var _finished := false
var _hint: Label
var _paused_label: Label
## How many times each sound effect has started, by asset ID.
var sound_counts := {}
var sprite: RaccoonSprite


## Turns the keys that work while paused (Esc, M, N) into calls on the level.
class Keys extends Node:
	var level: Node

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _unhandled_input(event: InputEvent) -> void:
		if not (event is InputEventKey and event.pressed and not event.echo):
			return
		match event.physical_keycode:
			KEY_ESCAPE:
				level.toggle_pause()
			KEY_M:
				level.toggle_mute("Music")
			KEY_N:
				level.toggle_mute("SFX")


func _enter_tree() -> void:
	_setup_buses()
	for action: String in INPUTS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: Key in INPUTS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("grab", click)


func _ready() -> void:
	var pose := ""
	var pose_left := false
	var sound_test := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			_shot_path = arg.get_slice("=", 1)
		elif arg == "--closeup":
			_closeup = true
		elif arg == "--grab-test":
			_grab_test = true
		elif arg == "--climb-test":
			_climb_test = true
		elif arg.begins_with("--pose="):
			pose = arg.get_slice("=", 1)
		elif arg == "--left":
			pose_left = true
		elif arg == "--sound-test":
			sound_test = true
	_rng.seed = 7

	_build_environment()
	forest = Forest.new()
	add_child(forest)
	_texture_ground()
	_build_props()

	camera = Camera3D.new()
	camera.fov = CAMERA_FOV
	add_child(camera)
	player = Player.new()
	player.position = Forest.START
	# Side-on to the camera and turned a little toward it, so his pose reads at once.
	player.rotation.y = deg_to_rad(-122.0)
	player.camera = camera
	player.trees = forest.climbable
	add_child(player)
	player.sound_started.connect(_count_sound)
	# He's drawn with the author's generated images; the 3D model underneath only
	# casts his shadow and carries things.
	sprite = RaccoonSprite.new()
	sprite.player = player
	sprite.camera = camera
	sprite.forced_state = pose
	sprite.forced_left = pose_left
	player.add_child(sprite)
	_anchor = player.global_position + PIVOT
	_place_camera()

	_task_laugh = AudioStreamPlayer.new()
	_task_laugh.bus = "SFX"
	_task_laugh.volume_db = TASK_LAUGH_DB
	if ResourceLoader.exists(TASK_LAUGH_PATH):
		_task_laugh.stream = load(TASK_LAUGH_PATH)
	add_child(_task_laugh)
	var keys := Keys.new()
	keys.level = self
	add_child(keys)

	_build_ui()
	_refresh_todo()
	_start_music()
	if sound_test:
		var test := SoundTest.new()
		test.level = self
		add_child(test)


func _process(delta: float) -> void:
	if _closeup:
		var focus := player.global_position + Vector3(0, 0.35, 0)
		camera.global_position = focus + Vector3(1.5, 0.45, -0.8)
		camera.look_at(focus)
	else:
		# Zoomed in, the camera follows more tightly, so he doesn't drift across the screen.
		var aim := player.global_position + PIVOT + _camper_lean()
		_anchor = _anchor.lerp(aim, 1.0 - exp(-6.0 / _zoom_now * delta))
		_zoom_now = lerpf(_zoom_now, zoom, 1.0 - exp(-10.0 * delta))
		_place_camera()
	_update_see_through()
	_check_tasks(delta)

	if _shot_path != "":
		_frames += 1
		if _grab_test and _frames == 1:
			player.global_position = forest.bin_spot + Vector3(0, 0.02, 0.75)
		elif _grab_test and _frames == 10:
			player._grab()
		elif _grab_test and _frames == 20:
			player.global_position = forest.bin_spot + Vector3(-1.5, 0.02, 2.4)
		elif _climb_test and _frames == 1:
			# Onto the nearest trunk, then up it for a moment.
			var nearest: Dictionary = forest.climbable[0]
			for tree: Dictionary in forest.climbable:
				if tree.base.distance_to(player.global_position) < nearest.base.distance_to(player.global_position):
					nearest = tree
			player._start_climb(nearest)
		elif _climb_test and _frames == 20:
			Input.action_press("move_forward")
		elif _climb_test and _frames == 38:
			Input.action_release("move_forward")
		if _frames == 30 and _music:
			# Stopped well before the quit, so the audio thread has let go of it.
			_music.stop()
		if _frames == 45:
			get_viewport().get_texture().get_image().save_png(_shot_path)
			get_tree().quit()


## Starts the forest loop with a soft fade-in. If the WAV hasn't been imported yet
## (the editor or the Play launcher does that), the game runs without music.
func _start_music() -> void:
	if not ResourceLoader.exists(MUSIC_PATH):
		push_warning("The music isn't imported yet: %s" % MUSIC_PATH)
		return
	_music = AudioStreamPlayer.new()
	_music.stream = load(MUSIC_PATH)
	_music.volume_db = -60.0
	_music.bus = "Music"
	# It keeps playing, muffled, while the game is paused.
	_music.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music)
	_music.play()
	_music_tween = create_tween()
	_music_tween.tween_property(_music, "volume_db", MUSIC_DB, MUSIC_FADE_IN)


# --- Sound -------------------------------------------------------------------

## Music and effects get buses of their own, so each can be muted on its own.
## The music bus has a low-pass filter, switched on only while paused.
func _setup_buses() -> void:
	for bus_name: String in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, "Master")
		if bus_name == "Music":
			var muffle := AudioEffectLowPassFilter.new()
			muffle.cutoff_hz = PAUSE_CUTOFF_HZ
			AudioServer.add_bus_effect(index, muffle)
			AudioServer.set_bus_effect_enabled(index, 0, false)


func _count_sound(id: String) -> void:
	sound_counts[id] = sound_counts.get(id, 0) + 1


## The laugh for a ticked-off task, with the music dipping under it.
func _play_task_laugh() -> void:
	if _task_laugh.stream == null:
		return
	_task_laugh.play()
	_count_sound("SFX-TASK-LAUGH")
	if _music == null or _finished:
		return
	_restart_music_tween()
	_music_tween.tween_property(_music, "volume_db", MUSIC_DB - DUCK_DB, 0.1)
	_music_tween.tween_interval(_task_laugh.stream.get_length())
	_music_tween.tween_property(_music, "volume_db", MUSIC_DB, 0.4)


## Every task done: after the last laugh, the music fades out and the clearing goes
## quiet (pillar 3, Home should be quiet).
func _end_music() -> void:
	if _music == null:
		return
	_restart_music_tween()
	_music_tween.tween_property(_music, "volume_db", MUSIC_DB - DUCK_DB, 0.1)
	if _task_laugh.stream:
		_music_tween.tween_interval(_task_laugh.stream.get_length())
	_music_tween.tween_property(_music, "volume_db", -60.0, END_FADE)
	_music_tween.tween_callback(_music.stop)


func _restart_music_tween() -> void:
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween()
	# The fades carry on while paused, like the music itself.
	_music_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)


## Esc: pauses the game. The music keeps playing, muffled and quieter; the effects
## pause with the game.
func toggle_pause() -> void:
	var tree := get_tree()
	tree.paused = not tree.paused
	var music := AudioServer.get_bus_index("Music")
	AudioServer.set_bus_effect_enabled(music, 0, tree.paused)
	AudioServer.set_bus_volume_db(music, -PAUSE_DB if tree.paused else 0.0)
	_paused_label.visible = tree.paused


## M or N: mutes or unmutes the music or the effects. Only the buses change, so
## nothing in the game depends on it.
func toggle_mute(bus_name: String) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_mute(index, not AudioServer.is_bus_mute(index))
	_update_hint()


func _update_hint() -> void:
	var music_on := not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music"))
	var sfx_on := not AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX"))
	_hint.text = "WASD move   Shift run   Ctrl sneak   E / click grab   Space chitter   Walk into a tree to climb (E lets go)\nWheel zoom   Tab camera   Esc pause   M music: %s   N effects: %s" % [
		"on" if music_on else "off", "on" if sfx_on else "off"]


# --- Ground ------------------------------------------------------------------

## Puts the generated grass texture on the forest floor, mapped in world space.
func _texture_ground() -> void:
	if not GROUND_TEXTURE:
		return
	if forest.ground == null or not ResourceLoader.exists(GROUND_PATH):
		push_warning("The ground texture isn't imported yet: %s" % GROUND_PATH)
		return
	var img := (load(GROUND_PATH) as Texture2D).get_image()
	if img.is_compressed():
		img.decompress()
	img.generate_mipmaps()
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.albedo_color = GROUND_TINT
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE / GROUND_TILE
	mat.roughness = 1.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	forest.ground.material_override = mat


## The aim point and the distance both scale with the zoom, so zooming slides the
## camera along its line to the raccoon and he stays put on screen.
func _place_camera() -> void:
	var pitch := deg_to_rad(camera_pitch)
	# From the raccoon toward the camera, along the ground; yaw 0 looks north (-Z).
	var back := Vector3.BACK.rotated(Vector3.UP, deg_to_rad(camera_yaw))
	var focus := _anchor - back * camera_ahead * _zoom_now
	camera.fov = camera_fov
	camera.global_position = focus + (back * cos(pitch) + Vector3.UP * sin(pitch)) * camera_distance * _zoom_now
	camera.look_at(focus)


## How far to shift the camera's aim toward the nearest camper.
func _camper_lean() -> Vector3:
	var lean := Vector3.ZERO
	var nearest := LEAN_RANGE
	for camper: Node3D in get_tree().get_nodes_in_group("camper"):
		var to_camper := camper.global_position - player.global_position
		to_camper.y = 0.0
		if to_camper.length() < nearest:
			nearest = to_camper.length()
			lean = to_camper * LEAN * smoothstep(LEAN_RANGE, LEAN_RANGE * 0.5, nearest)
	return lean


func _input(event: InputEvent) -> void:
	# Before the UI sees it, which would use Tab to move focus.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		_tuner.visible = not _tuner.visible
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom / 1.15, ZOOM_MIN, ZOOM_MAX)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom * 1.15, ZOOM_MIN, ZOOM_MAX)


# --- Tasks -----------------------------------------------------------------

func _check_tasks(delta: float) -> void:
	var cans_in := 0
	for can in cans:
		if _in_den(can):
			cans_in += 1
	var changed := cans_in != _cans_in_den
	_cans_in_den = cans_in

	# Sneaking into the den and keeping still sends him up into the hollow to sleep.
	if player.resting:
		if player.model.sleep >= 1.0:
			_sleep_time += delta
	else:
		var still := Vector2(player.velocity.x, player.velocity.z).length() < 0.1
		var napping := player.sneaking and still and not player.climbing and _in_den(player)
		_nap_time = _nap_time + delta if napping else 0.0
		if _nap_time > 1.0:
			_nap_time = 0.0
			player.rest(forest.rest_spot)

	var state := {
		"bin": bin.global_basis.y.y < 0.5,
		"lid": _in_den(lid),
		"cans": cans_in >= 3,
		"gnome": _in_den(gnome),
		"nap": _sleep_time > 2.0,
	}
	var ticked := 0
	for task: Dictionary in tasks:
		if not task.done and state[task.id]:
			task.done = true
			changed = true
			ticked += 1
	# The sound follows the change in state, never the other way round. One laugh
	# a frame, however many tasks finish together.
	if ticked > 0:
		_play_task_laugh()
	if changed:
		_refresh_todo()
		_banner.visible = tasks.all(func(t: Dictionary) -> bool: return t.done)
		if _banner.visible and not _finished:
			_finished = true
			_end_music()


## The den is the ground round the roots of the home pine.
func _in_den(node: Node3D) -> bool:
	if node == player.held:
		return false
	var p := node.global_position - Forest.HOME
	return Vector2(p.x, p.z).length() < Forest.DEN_RADIUS


## Points the trees' see-through window at the raccoon.
func _update_see_through() -> void:
	var target := player.global_position + Vector3(0, 0.25, 0)
	var mat := forest.see_through
	mat.set_shader_parameter("focus_uv", camera.unproject_position(target) / get_viewport().get_visible_rect().size)
	mat.set_shader_parameter("focus_depth", (target - camera.global_position).dot(-camera.global_basis.z))
	# Wide enough to show all of him: his size over the height of the view at his distance.
	var view_height := 2.0 * camera.global_position.distance_to(target) * tan(deg_to_rad(camera.fov) * 0.5)
	mat.set_shader_parameter("radius", 0.0 if player.resting or _closeup else 1.4 * player.size / view_height)


func _refresh_todo() -> void:
	var text := "[font_size=24][b]To do[/b][/font_size]\n"
	for task: Dictionary in tasks:
		var line: String = task.text
		if task.id == "cans":
			line += "  (%d/3)" % mini(_cans_in_den, 3)
		if task.done:
			text += "\n[color=#a39a88][s]%s[/s][/color]" % line
		else:
			text += "\n•  %s" % line
	_todo.text = text


# --- Level -------------------------------------------------------------------

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = HAZE
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e8eef0")
	env.ambient_light_energy = 0.8
	# Soft contact shading under the trees and round their roots.
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.6
	env.ssao_power = 1.2
	# A light haze, so the far trees fade a little, as in the reference.
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = HAZE
	env.fog_density = 0.35
	env.fog_depth_begin = 18.0
	env.fog_depth_end = 60.0
	env.fog_sun_scatter = 0.0
	env.fog_aerial_perspective = 0.0
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	# The reference is lit from the upper right.
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, 35, 0)
	sun.light_color = Color("fffaf0")
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	sun.shadow_blur = 2.0
	sun.shadow_opacity = 0.6
	sun.directional_shadow_max_distance = 40.0
	add_child(sun)


# --- Props -------------------------------------------------------------------

func _build_props() -> void:
	var spot := forest.bin_spot
	bin = _prop(spot, 3.0, _cylinder(0.28, 0.76), Vector3(0, 0.38, 0), ["bin"])
	_mesh(LowPoly.loft(
		[Vector3(0, 0, 0), Vector3(0, 0.03, 0), Vector3(0, 0.34, 0), Vector3(0, 0.37, 0),
			Vector3(0, 0.69, 0), Vector3(0, 0.72, 0), Vector3(0, 0.76, 0)],
		[Vector2(0.24, 0.24), Vector2(0.25, 0.25), Vector2(0.265, 0.265), Vector2(0.28, 0.28),
			Vector2(0.285, 0.285), Vector2(0.3, 0.3), Vector2(0.3, 0.3)],
		10, _bin_color), Vector3.ZERO, bin)
	for side: float in [-1.0, 1.0]:
		_mesh(LowPoly.box(Vector3(0.04, 0.05, 0.14), METAL_DARK), Vector3(0.3 * side, 0.6, 0), bin)

	lid = _prop(spot + Vector3(0, 0.785, 0), 0.5, _cylinder(0.3, 0.045), Vector3.ZERO,
		["grabbable", "lid"], 0.3, Vector3(0, -0.19, -0.2), Vector3(-0.8, 0, 0))
	_mesh(LowPoly.loft([Vector3(0, -0.022, 0), Vector3(0, 0.012, 0), Vector3(0, 0.026, 0)],
		[Vector2(0.3, 0.3), Vector2(0.3, 0.3), Vector2(0.2, 0.2)], 10, LowPoly.solid(LID)),
		Vector3.ZERO, lid)
	_mesh(LowPoly.box(Vector3(0.17, 0.02, 0.035), LID.darkened(0.1)), Vector3(0, 0.07, 0), lid)
	for side: float in [-1.0, 1.0]:
		_mesh(LowPoly.box(Vector3(0.02, 0.05, 0.03), LID.darkened(0.1)), Vector3(0.07 * side, 0.045, 0), lid)

	var can_spots := forest.can_spots
	for i in can_spots.size():
		var lying := i % 2 == 0
		var pos: Vector3 = can_spots[i] + Vector3(0, 0.061 if lying else 0.081, 0)
		var can := _prop(pos, 0.2, _cylinder(0.06, 0.16), Vector3.ZERO, ["grabbable", "can"],
			0.06, Vector3(0, -0.02, -0.04), Vector3(0, 0, PI / 2))
		if lying:
			can.rotation = Vector3(PI / 2, _rng.randf() * TAU, 0)
		can.continuous_cd = true
		_mesh(LowPoly.loft([Vector3(0, -0.08, 0), Vector3(0, -0.068, 0), Vector3(0, 0.068, 0), Vector3(0, 0.08, 0)],
			[Vector2(0.055, 0.055), Vector2(0.06, 0.06), Vector2(0.06, 0.06), Vector2(0.055, 0.055)],
			8, _can_color), Vector3.ZERO, can)
		cans.append(can)

	gnome = _prop(forest.gnome_spot + Vector3(0, 0.01, 0), 0.6, _cylinder(0.1, 0.44), Vector3(0, 0.22, 0),
		["grabbable", "gnome"], 0.1, Vector3(0, -0.36, -0.07), Vector3(0.15, 0, 0))
	_build_gnome(gnome)
	_build_stump()


## The stump: a flat image that always faces the camera, a collider he walks round,
## and an invisible cylinder about its size that casts its shadow.
func _build_stump() -> void:
	if not ResourceLoader.exists(STUMP_PATH):
		push_warning("The stump isn't imported yet: %s" % STUMP_PATH)
		return
	var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(STUMP_METRICS)).stump
	var right := Vector3.RIGHT.rotated(Vector3.UP, deg_to_rad(CAMERA_YAW))
	var back := Vector3.BACK.rotated(Vector3.UP, deg_to_rad(CAMERA_YAW))
	var stump := StaticBody3D.new()
	stump.position = Forest.START - right * STUMP_LEFT + back * STUMP_NEAR
	add_child(stump)

	var col := CollisionShape3D.new()
	col.shape = _cylinder(0.3, 0.5)
	col.position = Vector3(0, 0.25, 0)
	stump.add_child(col)
	var caster := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.26
	cylinder.bottom_radius = 0.34
	cylinder.height = 0.5
	caster.mesh = cylinder
	caster.position = Vector3(0, 0.25, 0)
	caster.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	stump.add_child(caster)

	var img := (load(STUMP_PATH) as Texture2D).get_image()
	if img.is_compressed():
		img.decompress()
	img.generate_mipmaps()
	var picture := Sprite3D.new()
	picture.texture = ImageTexture.create_from_image(img)
	picture.pixel_size = STUMP_HEIGHT / float(m.height_px)
	# Its anchor (the middle of its roots, on its lowest row) on the ground.
	picture.centered = false
	picture.offset = Vector2(-float(m.anchor_x), -(img.get_height() - 1.0 - float(m.feet_row)))
	picture.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	picture.shaded = false
	picture.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	picture.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	stump.add_child(picture)


func _build_gnome(root: Node3D) -> void:
	var skin := Color("e9c6a5")
	_mesh(LowPoly.box(Vector3(0.17, 0.04, 0.11), Color("4a3b33")), Vector3(0, 0.02, -0.01), root)
	_mesh(LowPoly.loft([Vector3(0, 0.04, 0), Vector3(0, 0.22, 0)], [Vector2(0.09, 0.08), Vector2(0.07, 0.065)],
		7, LowPoly.solid(Color("5c7a9c"))), Vector3.ZERO, root)
	_mesh(LowPoly.loft([Vector3(0, 0.21, 0), Vector3(0, 0.31, 0)], [Vector2(0.065, 0.06), Vector2(0.06, 0.055)],
		7, LowPoly.solid(skin)), Vector3.ZERO, root)
	_mesh(LowPoly.loft([Vector3(0, 0.27, -0.035), Vector3(0, 0.12, -0.055)], [Vector2(0.065, 0.04), Vector2(0.01, 0.01)],
		6, LowPoly.solid(Color("f2eee4"))), Vector3.ZERO, root)
	_mesh(LowPoly.loft([Vector3(0, 0.29, 0), Vector3(0, 0.38, 0.01), Vector3(0, 0.46, 0.035)],
		[Vector2(0.078, 0.075), Vector2(0.05, 0.05), Vector2(0.005, 0.005)], 7, LowPoly.solid(Color("b8574a"))),
		Vector3.ZERO, root)
	_mesh(LowPoly.box(Vector3(0.03, 0.03, 0.03), Color("d99a8a")), Vector3(0, 0.275, -0.065), root)


func _bin_color(segment: int, _side: int, _n: Vector3) -> Color:
	match segment:
		-1, 1, 3, 5:
			return METAL_DARK
		6:
			return BIN_INSIDE
	return METAL


func _can_color(segment: int, _side: int, _n: Vector3) -> Color:
	return CAN if segment == 1 else SILVER


func _prop(pos: Vector3, mass: float, shape: Shape3D, shape_offset: Vector3, groups: Array,
		grab_radius := 0.0, hold_offset := Vector3.ZERO, hold_rotation := Vector3.ZERO) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.position = pos
	body.mass = mass
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = shape_offset
	body.add_child(col)
	for g: String in groups:
		body.add_to_group(g)
	body.set_meta("grab_radius", grab_radius)
	body.set_meta("hold_offset", hold_offset)
	body.set_meta("hold_rotation", hold_rotation)
	add_child(body)
	return body


# --- Helpers -----------------------------------------------------------------

func _mesh(mesh: Mesh, pos: Vector3, parent: Node = self, rot_y := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation.y = rot_y
	parent.add_child(mi)
	return mi


func _cylinder(radius: float, height: float) -> CylinderShape3D:
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	return shape


# --- UI ----------------------------------------------------------------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	if _closeup:
		layer.visible = false

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f4eedc")
	style.set_corner_radius_all(6)
	style.set_content_margin_all(18)
	style.shadow_color = Color(0, 0, 0, 0.18)
	style.shadow_size = 6
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(24, 24)
	layer.add_child(panel)

	_todo = RichTextLabel.new()
	_todo.bbcode_enabled = true
	_todo.fit_content = true
	_todo.custom_minimum_size = Vector2(320, 0)
	_todo.add_theme_color_override("default_color", Color("3b3630"))
	_todo.add_theme_font_size_override("normal_font_size", 18)
	_todo.add_theme_font_size_override("bold_font_size", 18)
	panel.add_child(_todo)

	_hint = Label.new()
	_hint.add_theme_color_override("font_color", Color("f4eedc"))
	_hint.add_theme_color_override("font_outline_color", Color("3b3630"))
	_hint.add_theme_constant_override("outline_size", 6)
	layer.add_child(_hint)
	_update_hint()
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 20)

	_paused_label = Label.new()
	_paused_label.text = "Paused"
	_paused_label.visible = false
	_paused_label.add_theme_font_size_override("font_size", 48)
	_paused_label.add_theme_color_override("font_color", Color("f4eedc"))
	_paused_label.add_theme_color_override("font_outline_color", Color("3b3630"))
	_paused_label.add_theme_constant_override("outline_size", 12)
	layer.add_child(_paused_label)
	_paused_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)

	_banner = Label.new()
	_banner.text = "Mischief managed!"
	_banner.visible = false
	_banner.add_theme_font_size_override("font_size", 48)
	_banner.add_theme_color_override("font_color", Color("f4eedc"))
	_banner.add_theme_color_override("font_outline_color", Color("3b3630"))
	_banner.add_theme_constant_override("outline_size", 12)
	layer.add_child(_banner)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 40)

	_tuner = CameraTuner.new()
	_tuner.main = self
	_tuner.visible = false
	layer.add_child(_tuner)
	_tuner.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 24)
