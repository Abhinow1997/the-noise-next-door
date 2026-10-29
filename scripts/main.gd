extends Node3D
## Builds the forest, the props, the raccoon and the to-do list. The game opens on the
## title screen (title_screen.gd), shown over this level: him curled up asleep in his
## hollow at night with the lullaby playing. New Game glides the camera in to the nap
## close-up, and play starts from there when a move key wakes him. Any `--` argument
## other than the title's own (`--title-...`) skips the title, for the debug flags below.
## Debug: `-- --screenshot=out.png [--closeup] [--pose=<state> [--left]]` saves a
## frame and quits; --pose shows the raccoon in one state: an animation of the rigged
## model (idle, walk, run, sneak, bored, sleep, climb), or with USE_SPRITES a
## cut-out (see raccoon_sprite.gd). `-- --sprites` uses the cut-outs for one run.
## `-- --sound-test` runs the automated sound check (scripts/sound_test.gd).
## Screenshot helpers: --grab-test, --climb-test, --rest-test (he naps in the hollow),
## --tick-test (the bin is knocked over), --jump-test (he jumps on frame 1, F held; he's
## at the top around frame 14), --shot-frame=N (default 45), and
## --see-collision (the raccoon half see-through, for use with --debug-collisions).
## `-- --bubble-demo` adds a yard of stand-ins for trying the thought bubbles
## (scripts/bubble_demo.gd); `-- --bubble-test` runs their automated check in it
## (scripts/bubble_test.gd), with `--bubble-shots=<folder>` for a picture of each.
## `-- --camp-test` runs the automated check of the campers' reactions to the raccoon
## at the campsite (scripts/camp_test.gd), with `--camp-shots=<folder>` for pictures.
## `-- --tasks-test` plays level 1's camp tasks and routines through and checks them
## (scripts/tasks_test.gd), with `--tasks-shots=<folder>` for pictures.
## `-- --waves-test` checks the party's sound waves (scripts/waves_test.gd), with
## `--waves-shots=<folder>` for pictures.
## `-- --plan-test` checks THE PLAN, the to-do list on Tab, and the scraps at the bottom
## (scripts/plan_test.gd), with `--plan-shots=<folder>` for pictures.
## `-- --cones-test` checks the tutorial at the camp and the campers' cones and search
## (scripts/cones_test.gd), with `--cones-shots=<folder>` for pictures. The other tests
## skip the tutorial: for them the camp's tasks are on the list and the cones on from
## the start. `-- --cone-shader-test` checks the cones' shader and what drives it
## (tests/cone_shader_test.gd, cone_driver.gd), through the tutorial as --cones-test.

const LowPoly := preload("res://scripts/lowpoly.gd")
const Player := preload("res://scripts/player.gd")
const Forest := preload("res://scripts/forest.gd")
const CameraTuner := preload("res://scripts/camera_tuner.gd")
const RaccoonSprite := preload("res://scripts/raccoon_sprite.gd")
## Draw the raccoon with the author's generated cut-outs (the asset slice, 6 Oct)
## instead of the rigged 3D model.
const USE_SPRITES := false
## --pose names from the cut-outs, as the rigged model's animations.
const POSE_ANIMATIONS := {"asleep": "sleep"}
const SoundTest := preload("res://scripts/sound_test.gd")
## Pictures over his head that show what he notices, wants or feels.
const ThoughtBubbles := preload("res://scripts/thought_bubbles.gd")
const BubbleDemo := preload("res://scripts/bubble_demo.gd")
const BubbleTest := preload("res://scripts/bubble_test.gd")
const CampTest := preload("res://scripts/camp_test.gd")
const TasksTest := preload("res://scripts/tasks_test.gd")
const WavesTest := preload("res://scripts/waves_test.gd")
const PlanTest := preload("res://scripts/plan_test.gd")
const ConesTest := preload("res://scripts/cones_test.gd")
## His laughing face while he chitters.
const RaccoonFace := preload("res://scripts/raccoon_face.gd")
## The moonlight (night.gd), and the title screen's chalk writing (title_menu.gd) for the
## prompt to wake him.
const Night := preload("res://scripts/night.gd")
const TitleMenu := preload("res://scripts/title_menu.gd")
const TitleScreen := preload("res://scripts/title_screen.gd")
## Fireflies and falling leaves in the moonlight (night_life.gd).
const NightLife := preload("res://scripts/night_life.gd")
## Level 1's campsite under his tree: the fire, the tents and the party (23 Oct 2026).
const Campsite := preload("res://scripts/campsite.gd")
## Level 1's to-do list: the campsite's tasks (23 Oct 2026), shown as THE PLAN, a torn
## notebook page on Tab, with scraps at the bottom of the screen (24 Oct 2026).
const CampTasks := preload("res://scripts/camp_tasks.gd")
const PlanNote := preload("res://scripts/plan_note.gd")
const CampTutorial := preload("res://scripts/camp_tutorial.gd")
## The level is at night, as the title screen is: the author asked for the game to be at
## night too on 21 Oct 2026. Off, it's the daylight it had before.
const NIGHT := true

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
const TASK_LAUGH_DB := -2.0
## How far the music dips under the laugh, and how the music is muffled while paused
## (CHANGE-BRIEF.md, music behaviour). (Its fade at the end went with the prototype's
## to-do list on 23 Oct 2026: level 1 has no ending yet.)
const DUCK_DB := 4.0
const PAUSE_DB := 8.0
const PAUSE_CUTOFF_HZ := 900.0

const METAL := Color("8f9ba4")
const METAL_DARK := Color("6c7780")
const BIN_INSIDE := Color("454b50")
const CAN := Color("5f7387")
const SILVER := Color("c3c6c8")
const LID := Color("cfc8b8")
## The sky is never seen; this is the haze the far trees fade into by day (night.gd has
## the night's).
const HAZE := Color("8fa58c")

## The camera view the author picked with the camera panel (camera_tuner.gd): it looks
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
## The close-up the author picked with the Tab panel for watching him sleep in the
## hollow: low, nearly straight on, 9 m away. The camera eases into it as he curls
## up and back out as he wakes. Its distance and aim already include the wheel's
## zoom, so zooming doesn't change it.
const SLEEP_CAMERA_PITCH := 10.0
const SLEEP_CAMERA_YAW := -1.0
const SLEEP_CAMERA_FOV := 14.0
const SLEEP_CAMERA_DISTANCE := 9.0
const SLEEP_CAMERA_AHEAD := 0.5
## Seconds to ease into the close-up, and back out once he wakes.
const SLEEP_CAMERA_IN := 3.0
const SLEEP_CAMERA_OUT := 1.5

## The level's music: a 16-bar loop cut from the generated forest track in
## design/music/ (see SOURCES.md). The WAV's own loop marker makes it repeat seamlessly.
const MUSIC_PATH := "res://assets/audio/music/forest-loop.wav"
## How loud the music sits under the sound effects, and its fade-in time in seconds.
## Lowered 3 dB on 6 Oct, with the effects raised 4 dB, after the author's playtest
## found the effects too quiet against it.
const MUSIC_DB := -12.0
const MUSIC_FADE_IN := 2.0
## The nap music: the generated lullaby in design/music/ (MUS-THEME-SLOW), from its
## start, then round a 34 s section cut to loop seamlessly (see SOURCES.md). It fades
## in over the forest loop as he curls up in the hollow, and out as he wakes. It's
## as loud as the forest loop (both measure about -15 LUFS), so it plays at the same level.
const SLEEP_MUSIC_PATH := "res://assets/audio/music/lullaby-loop.wav"
const SLEEP_MUSIC_DB := MUSIC_DB
const SLEEP_FADE := 3.0
const WAKE_FADE := 1.5
## Starting under the title screen, asleep: how long the lullaby takes to fade in; once
## New Game has brought the camera in, how long the prompt to wake him waits to come
## up; how long it takes to fade in or out; and how long after he's woken the key task
## comes up (THE PLAN).
const LULLABY_FADE_IN := 2.5
const WAKE_PROMPT_AFTER := 2.5
const UI_FADE := 0.8
const WAKE_PROMPT := "Press W, A, S or D to wake up"

const INPUTS := {
	"move_forward": [KEY_W, KEY_UP],
	"move_back": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"run": [KEY_SHIFT],
	"sneak": [KEY_CTRL, KEY_C],
	"grab": [KEY_E],
	"chitter": [KEY_SPACE],
	"jump": [KEY_F],
}

var player: Player
var camera: Camera3D
var forest: Forest
var campsite: Campsite
## What the game hears through: on the raccoon, turned as the camera is, so sounds in
## the world (the party's music, campsite.gd) are as loud as they are where he is, and
## what's on the right of the screen is heard on the right.
var _ear: AudioListener3D
var bin: RigidBody3D
var lid: RigidBody3D
var gnome: RigidBody3D
var cans: Array[RigidBody3D] = []
var zoom := 1.0
## The camera's settings, starting from the constants above. V in the game opens a
## panel (camera_tuner.gd) that changes them live (it was Tab until THE PLAN took Tab).
var camera_pitch := CAMERA_PITCH
var camera_yaw := CAMERA_YAW
var camera_fov := CAMERA_FOV
var camera_distance := CAMERA_DISTANCE
var camera_ahead := CAMERA_AHEAD

## Level 1's to-do list (camp_tasks.gd), ticked off by the puzzles at the campsite.
## The prototype's bin, lid, cans and gnome are still about to play with, and he can
## still nap in his den, but none of them is a task any more.
var tasks := CampTasks.new()
## How many naps he's had in the hollow (not counting the one under the title).
var naps := 0

var _plan: PlanNote
## The tutorial at the camp (camp_tutorial.gd), or null in the tests that skip it.
var _tutorial: CampTutorial
var _tuner: CameraTuner
var _nap_time := 0.0
var _sleep_time := 0.0
## Tasks ticked off since the last frame: one laugh for them all.
var _ticked := 0
var _rng := RandomNumberGenerator.new()
var _closeup := false
var _grab_test := false
var _climb_test := false
var _rest_test := false
var _tick_test := false
var _jump_test := false
var _shot_frame := 45
var _see_collision := false
var _shot_path := ""
var _frames := 0
var _zoom_now := 1.0
## Where the camera thinks the raccoon is; it trails him slightly for smoothness.
var _anchor := Vector3.ZERO
var _music: AudioStreamPlayer
var _music_tween: Tween
var _sleep_music: AudioStreamPlayer
var _sleep_tween: Tween
## Whether he's napping in the hollow, and how far (0..1) the camera has eased
## toward the sleeping close-up.
var _napping := false
var _sleep_view := 0.0
var _task_laugh: AudioStreamPlayer
var _paused_label: Label
## How many times each sound effect has started, by asset ID.
var sound_counts := {}
var sprite: RaccoonSprite
var bubbles: ThoughtBubbles
## The title screen while it's up, or null. Meanwhile, how much (1..0) the camera is
## its view rather than the game's own, and that view; the game's keys wait for it.
var title: TitleScreen
var title_view := 0.0
var title_camera: Transform3D
var title_fov := 40.0
## And the title's haze (where it begins and ends, in metres, and how thick), eased
## into the level's own as the camera glides in.
var title_fog := Vector3.ZERO
var _env: Environment
var _fog := Vector3.ZERO
## True from the start under the title until he's out of the hollow. That nap isn't the
## nap task, and the key task stays hidden until he wakes.
var _first_nap := false
var _wake_prompt: Label
var _wake_tween: Tween


## Turns the keys that work while paused (Esc, M, N) into calls on the level.
class Keys extends Node:
	var level: Node

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _unhandled_input(event: InputEvent) -> void:
		if not (event is InputEventKey and event.pressed and not event.echo) or level.title:
			return
		match event.physical_keycode:
			KEY_ESCAPE:
				# The tutorial has the game paused already, until Tab.
				if not level.tutorial_running():
					level.toggle_pause()
			KEY_M:
				level.toggle_mute("Music")
			KEY_N:
				level.toggle_mute("SFX")


func _enter_tree() -> void:
	setup_buses()
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
	var use_sprites := USE_SPRITES
	var bubble_demo := false
	var bubble_test := false
	var bubble_shots := ""
	var camp_test := false
	var camp_shots := ""
	var tasks_test := false
	var tasks_shots := ""
	var waves_test := false
	var waves_shots := ""
	var plan_test := false
	var plan_shots := ""
	var cones_test := false
	var cones_shots := ""
	var cone_shader_test := false
	var title_mode := Array(OS.get_cmdline_user_args()).all(func(arg: String) -> bool: return arg.begins_with("--title"))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			_shot_path = arg.get_slice("=", 1)
		elif arg == "--closeup":
			_closeup = true
		elif arg == "--grab-test":
			_grab_test = true
		elif arg == "--climb-test":
			_climb_test = true
		elif arg == "--rest-test":
			_rest_test = true
		elif arg == "--tick-test":
			_tick_test = true
		elif arg == "--jump-test":
			_jump_test = true
		elif arg == "--see-collision":
			_see_collision = true
		elif arg.begins_with("--shot-frame="):
			_shot_frame = int(arg.get_slice("=", 1))
		elif arg.begins_with("--pose="):
			pose = arg.get_slice("=", 1)
		elif arg == "--left":
			pose_left = true
		elif arg == "--sound-test":
			sound_test = true
		elif arg == "--sprites":
			use_sprites = true
		elif arg == "--bubble-demo":
			bubble_demo = true
		elif arg == "--bubble-test":
			bubble_demo = true
			bubble_test = true
		elif arg.begins_with("--bubble-shots="):
			bubble_shots = arg.get_slice("=", 1)
		elif arg == "--camp-test":
			camp_test = true
		elif arg.begins_with("--camp-shots="):
			camp_shots = arg.get_slice("=", 1)
		elif arg == "--tasks-test":
			tasks_test = true
		elif arg.begins_with("--tasks-shots="):
			tasks_shots = arg.get_slice("=", 1)
		elif arg == "--waves-test":
			waves_test = true
		elif arg.begins_with("--waves-shots="):
			waves_shots = arg.get_slice("=", 1)
		elif arg == "--plan-test":
			plan_test = true
		elif arg.begins_with("--plan-shots="):
			plan_shots = arg.get_slice("=", 1)
		elif arg == "--cones-test":
			cones_test = true
		elif arg.begins_with("--cones-shots="):
			cones_shots = arg.get_slice("=", 1)
		elif arg == "--cone-shader-test":
			cone_shader_test = true
	_rng.seed = 7

	_build_environment()
	forest = Forest.new()
	forest.night = NIGHT
	forest.clearings.assign(Campsite.CLEARINGS)
	add_child(forest)
	if NIGHT:
		add_child(NightLife.new())
	_texture_ground()
	_build_props()
	# The bubble demo's yard of stand-ins stands where the campsite does.
	if not bubble_demo:
		campsite = Campsite.new()
		campsite.forest = forest
		campsite.tasks = tasks
		# Under the title the night's quiet; the party starts with New Game (start_party).
		campsite.party_from_start = not title_mode
		add_child(campsite)
		if sound_test or camp_test or tasks_test or waves_test or plan_test:
			# These skip the tutorial at the camp: everything's as it is after it.
			tasks.reveal()
			campsite.cones_on = true
	tasks.ticked.connect(func(_id: String) -> void: _ticked += 1)

	camera = Camera3D.new()
	camera.fov = CAMERA_FOV
	# Placed every frame in _process, so it isn't interpolated; it follows where
	# the raccoon is drawn instead (see _drawn).
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(camera)
	_ear = AudioListener3D.new()
	_ear.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_ear)
	_ear.make_current()
	player = Player.new()
	player.position = Forest.START
	# Side-on to the camera and turned a little toward it, so his pose reads at once.
	player.rotation.y = deg_to_rad(-122.0)
	player.camera = camera
	player.trees = forest.climbable
	add_child(player)
	player.sound_started.connect(_count_sound)
	if title_mode:
		# Under the title he's asleep in the hollow, and stays so until it has gone.
		_first_nap = true
		player.start_asleep(forest.rest_spot, forest.rest_exit)
		player.keep_asleep = true
		_napping = true
		_sleep_view = 1.0
	if use_sprites:
		# Drawn with the author's generated images; the 3D model underneath only
		# casts his shadow and carries things.
		sprite = RaccoonSprite.new()
		sprite.player = player
		sprite.camera = camera
		sprite.forced_state = pose
		sprite.forced_left = pose_left
		player.add_child(sprite)
	else:
		player.model.forced_animation = POSE_ANIMATIONS.get(pose, pose)
		if NIGHT:
			Night.tint_raccoon(player.model)
		# Before the model's first frame, while it's still at rest (see raccoon_face.gd).
		var face := RaccoonFace.new()
		face.player = player
		add_child(face)
	if sprite and _see_collision:
		# Half see-through, so `--debug-collisions` shows his capsule inside him.
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
		sprite.modulate = Color(1, 1, 1, 0.45)
	bubbles = ThoughtBubbles.new()
	bubbles.player = player
	bubbles.camera = camera
	add_child(bubbles)
	_anchor = _drawn() + PIVOT
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
	if campsite and not campsite.cones_on:
		_tutorial = CampTutorial.new()
		_tutorial.plan = _plan
		_tutorial.tasks = tasks
		_tutorial.campsite = campsite
		add_child(_tutorial)
	_start_music()
	if campsite:
		campsite.music = _music
	if title_mode:
		title = TitleScreen.new()
		title.level = self
		add_child(title)
	if sound_test:
		var test := SoundTest.new()
		test.level = self
		add_child(test)
	if camp_test and campsite:
		var camp_check := CampTest.new()
		camp_check.level = self
		camp_check.shots = camp_shots
		add_child(camp_check)
	if tasks_test and campsite:
		var tasks_check := TasksTest.new()
		tasks_check.level = self
		tasks_check.shots = tasks_shots
		add_child(tasks_check)
	if waves_test and campsite:
		var waves_check := WavesTest.new()
		waves_check.level = self
		waves_check.shots = waves_shots
		add_child(waves_check)
	if plan_test and campsite:
		var plan_check := PlanTest.new()
		plan_check.level = self
		plan_check.shots = plan_shots
		add_child(plan_check)
	if cones_test and campsite:
		var cones_check := ConesTest.new()
		cones_check.level = self
		cones_check.shots = cones_shots
		add_child(cones_check)
	if cone_shader_test and campsite:
		# Loaded only under its flag, so normal play doesn't load a file from tests/.
		var shader_check = load("res://tests/cone_shader_test.gd").new()
		shader_check.level = self
		add_child(shader_check)
	if bubble_demo:
		var demo := BubbleDemo.new()
		demo.level = self
		add_child(demo)
		if bubble_test:
			var check := BubbleTest.new()
			check.level = self
			check.demo = demo
			check.shots = bubble_shots
			add_child(check)


func _process(delta: float) -> void:
	# Curling up in the hollow, the camera eases in close and the lullaby takes over.
	var napping := player.is_napping()
	if napping != _napping:
		_napping = napping
		_nap_music(napping)
		if not napping and _first_nap:
			_show_ui()
	_sleep_view = move_toward(_sleep_view, 1.0 if napping else 0.0,
		delta / (SLEEP_CAMERA_IN if napping else SLEEP_CAMERA_OUT))
	if _closeup:
		var focus := _drawn() + Vector3(0, 0.35, 0)
		camera.global_position = focus + Vector3(1.5, 0.45, -0.8)
		camera.look_at(focus)
	else:
		# Zoomed in, the camera follows more tightly, so he doesn't drift across the screen.
		var aim := _drawn() + PIVOT + _camper_lean()
		# Through a jump it stays at the height he took off from, so the view doesn't bob.
		if player.jumping:
			aim.y = player.jump_from_y + PIVOT.y
		_anchor = _anchor.lerp(aim, 1.0 - exp(-6.0 / _zoom_now * delta))
		_zoom_now = lerpf(_zoom_now, zoom, 1.0 - exp(-10.0 * delta))
		_place_camera()
	_ear.global_transform = Transform3D(camera.global_basis, _drawn() + Vector3(0, 0.35, 0))
	_update_see_through()
	_check_tasks(delta)

	if _shot_path != "":
		_frames += 1
		if _grab_test and _frames == 1:
			player.place(forest.bin_spot + Vector3(0, 0.02, 0.75))
		elif _grab_test and _frames == 10:
			player._grab()
		elif _grab_test and _frames == 20:
			player.place(forest.bin_spot + Vector3(-1.5, 0.02, 2.4))
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
		elif _rest_test and _frames == 1:
			player.rest(forest.rest_spot, forest.rest_exit)
		elif _tick_test and _frames == 1:
			bin.rotation = Vector3(PI / 2, 0, 0)
			bin.reset_physics_interpolation()
		elif _jump_test and _frames == 1:
			Input.action_press("jump")
			player.jump()
		elif _jump_test and _frames == 30:
			Input.action_release("jump")
		if _frames == _shot_frame - 15:
			# Stopped well before the quit, so the audio thread has let go of them.
			for music: AudioStreamPlayer in [_music, _sleep_music]:
				if music:
					music.stop()
			if campsite and campsite.party:
				campsite.party.stop()
		if _frames == _shot_frame:
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
	# Starting asleep, it stays right down under the lullaby until he wakes (_nap_music).
	if not _first_nap:
		_music_tween = create_tween()
		_music_tween.tween_property(_music, "volume_db", MUSIC_DB, MUSIC_FADE_IN)
	if not ResourceLoader.exists(SLEEP_MUSIC_PATH):
		push_warning("The nap music isn't imported yet: %s" % SLEEP_MUSIC_PATH)
		return
	_sleep_music = AudioStreamPlayer.new()
	_sleep_music.stream = load(SLEEP_MUSIC_PATH)
	_sleep_music.volume_db = -60.0
	_sleep_music.bus = "Music"
	_sleep_music.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_sleep_music)
	if _first_nap:
		# Asleep under the title: the lullaby is the title's music.
		_sleep_music.play()
		_restart_sleep_tween()
		_sleep_tween.tween_property(_sleep_music, "volume_db", SLEEP_MUSIC_DB, LULLABY_FADE_IN)


## As he curls up, the lullaby starts from its beginning and fades in while the
## forest loop fades right down (it keeps playing, so it comes back where it was);
## as he wakes, it's the other way round.
func _nap_music(napping: bool) -> void:
	var time := SLEEP_FADE if napping else WAKE_FADE
	if _music:
		_restart_music_tween()
		_crossfade(_music_tween, _music, -60.0 if napping else MUSIC_DB, time)
	if _sleep_music == null:
		return
	_restart_sleep_tween()
	if napping:
		_sleep_music.volume_db = -60.0
		_sleep_music.play()
		_crossfade(_sleep_tween, _sleep_music, SLEEP_MUSIC_DB, time)
	else:
		_crossfade(_sleep_tween, _sleep_music, -60.0, time)
		_sleep_tween.tween_callback(_sleep_music.stop)


## Fades `music` to `to_db` evenly in power rather than in decibels, so while one
## track fades out and the other in they stay as loud together, with no dip between.
func _crossfade(tween: Tween, music: AudioStreamPlayer, to_db: float, time: float) -> void:
	var from := pow(db_to_linear(music.volume_db), 2.0)
	var to := pow(db_to_linear(to_db), 2.0)
	tween.tween_method(func(t: float) -> void:
		music.volume_db = maxf(linear_to_db(sqrt(lerpf(from, to, t))), -60.0), 0.0, 1.0, time)


func _restart_sleep_tween() -> void:
	if _sleep_tween:
		_sleep_tween.kill()
	_sleep_tween = create_tween()
	_sleep_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)


# --- Sound -------------------------------------------------------------------

## Music and effects get buses of their own, so each can be muted on its own.
## The music bus has a low-pass filter, switched on only while paused. The title screen
## (title_screen.gd) sets them up the same way first.
static func setup_buses() -> void:
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


## The laugh for a ticked-off task, with the forest loop dipping under it. It never
## plays while he's in the hollow (_check_tasks), so the lullaby never dips.
func _play_task_laugh() -> void:
	if _task_laugh.stream == null:
		return
	_task_laugh.play()
	_count_sound("SFX-TASK-LAUGH")
	if _music == null:
		return
	_restart_music_tween()
	_music_tween.tween_property(_music, "volume_db", MUSIC_DB - DUCK_DB, 0.1)
	_music_tween.tween_interval(_task_laugh.stream.get_length())
	_music_tween.tween_property(_music, "volume_db", MUSIC_DB, 0.4)


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


## True while the tutorial at the camp has the game paused.
func tutorial_running() -> bool:
	return _tutorial != null and _tutorial.running()


## M or N: mutes or unmutes the music or the effects. Only the buses change, so
## nothing in the game depends on it.
func toggle_mute(bus_name: String) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_mute(index, not AudioServer.is_bus_mute(index))


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
## camera along its line to the raccoon and he stays put on screen. While he naps
## it blends, eased, into the sleeping close-up, swinging round him rather than
## cutting across.
func _place_camera() -> void:
	var w := smoothstep(0.0, 1.0, _sleep_view)
	var pitch := deg_to_rad(lerpf(camera_pitch, SLEEP_CAMERA_PITCH, w))
	var distance := lerpf(camera_distance * _zoom_now, SLEEP_CAMERA_DISTANCE, w)
	var ahead := lerpf(camera_ahead * _zoom_now, SLEEP_CAMERA_AHEAD, w)
	# From the raccoon toward the camera, along the ground; yaw 0 looks north (-Z).
	var back := Vector3.BACK.rotated(Vector3.UP, deg_to_rad(lerpf(camera_yaw, SLEEP_CAMERA_YAW, w)))
	var focus := _anchor - back * ahead
	camera.fov = lerpf(camera_fov, SLEEP_CAMERA_FOV, w)
	camera.global_position = focus + (back * cos(pitch) + Vector3.UP * sin(pitch)) * distance
	camera.look_at(focus)
	# Under the title, its view; as New Game glides in, between the two.
	if title_view > 0.0:
		camera.global_transform = camera.global_transform.interpolate_with(title_camera, title_view)
		camera.fov = lerpf(camera.fov, title_fov, title_view)
		_set_fog(_fog.lerp(title_fog, title_view))


func _set_fog(fog: Vector3) -> void:
	_env.fog_depth_begin = fog.x
	_env.fog_depth_end = fog.y
	_env.fog_density = fog.z


## Where the raccoon is drawn this frame. He moves in physics ticks (60 a second)
## and is drawn between them (physics interpolation), so anything placed every frame
## follows this rather than his position, or he shakes on a faster screen.
func _drawn() -> Vector3:
	return player.get_global_transform_interpolated().origin


## How far to shift the camera's aim toward the nearest camper.
func _camper_lean() -> Vector3:
	var lean := Vector3.ZERO
	var nearest := LEAN_RANGE
	for camper: Node3D in get_tree().get_nodes_in_group("camper"):
		var to_camper := camper.global_position - _drawn()
		to_camper.y = 0.0
		if to_camper.length() < nearest:
			nearest = to_camper.length()
			lean = to_camper * LEAN * smoothstep(LEAN_RANGE, LEAN_RANGE * 0.5, nearest)
	return lean


func _input(event: InputEvent) -> void:
	if title:
		return
	# Before the UI sees it, which would use Tab to move focus. Tab brings THE PLAN up
	# or puts it away; V shows or hides the camera panel.
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_TAB:
		_plan.toggle()
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_V:
		_tuner.visible = not _tuner.visible
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if title:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom / 1.15, ZOOM_MIN, ZOOM_MAX)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom * 1.15, ZOOM_MIN, ZOOM_MAX)


# --- Tasks -----------------------------------------------------------------

func _check_tasks(delta: float) -> void:
	# Sneaking into the den and keeping still sends him up into the hollow to sleep;
	# two seconds asleep there counts as a nap (the one under the title doesn't).
	if player.resting:
		if player.model.sleep >= 1.0 and not _first_nap:
			if _sleep_time <= 2.0 and _sleep_time + delta > 2.0:
				naps += 1
			_sleep_time += delta
	else:
		_first_nap = false
		_sleep_time = 0.0
		var still := Vector2(player.velocity.x, player.velocity.z).length() < 0.1
		var napping := player.sneaking and still and not player.climbing and _in_den(player)
		_nap_time = _nap_time + delta if napping else 0.0
		if _nap_time > 1.0:
			_nap_time = 0.0
			player.rest(forest.rest_spot, forest.rest_exit)

	# The first task, following the party's music, is done once he's at the camp; and
	# then the tutorial there starts (camp_tutorial.gd).
	if campsite and not tasks.is_done("investigate") and campsite.in_camp(player.global_position):
		tasks.done("investigate")
		if _tutorial:
			_tutorial.begin()

	# The camp's puzzles tick tasks off (camp_tasks.gd). The sound follows the change in
	# state, never the other way round. One laugh a frame, however many tasks finish
	# together; and none in his sleep (the author asked): a task done while he's in the
	# hollow ticks off silently. THE PLAN (plan_note.gd) crosses them off itself.
	if _ticked > 0:
		if not player.resting:
			_play_task_laugh()
		_ticked = 0


## The den is the ground round the roots of the home pine.
func _in_den(node: Node3D) -> bool:
	if node == player.held:
		return false
	var p := node.global_position - Forest.HOME
	return Vector2(p.x, p.z).length() < Forest.DEN_RADIUS


## Points the trees' see-through window at the raccoon.
func _update_see_through() -> void:
	var target := _drawn() + Vector3(0, 0.25, 0)
	var mat := forest.see_through
	mat.set_shader_parameter("focus_uv", camera.unproject_position(target) / get_viewport().get_visible_rect().size)
	mat.set_shader_parameter("focus_depth", (target - camera.global_position).dot(-camera.global_basis.z))
	# Wide enough to show all of him: his size over the height of the view at his distance.
	var view_height := 2.0 * camera.global_position.distance_to(target) * tan(deg_to_rad(camera.fov) * 0.5)
	mat.set_shader_parameter("radius", 0.0 if player.resting or _closeup else 1.4 * player.size / view_height)


# --- Level -------------------------------------------------------------------

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	# At night the sky shows, from the title's view over the trees.
	env.background_color = Night.SKY.linear_to_srgb() if NIGHT else HAZE
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
	_env = env
	_fog = Vector3(env.fog_depth_begin, env.fog_depth_end, env.fog_density)
	if NIGHT:
		Night.light(env)
		env.fog_sky_affect = 0.0
		# Only the fireflies are bright enough to glow.
		env.glow_enabled = true
		env.glow_intensity = 0.8
		env.glow_bloom = 0.0
		env.glow_hdr_threshold = 1.0
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	if NIGHT:
		add_child(Night.moon(40.0))
		return

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
	# Facing it up close, he thinks of food (thought_bubbles.gd).
	bin = _prop(spot, 3.0, _cylinder(0.28, 0.76), Vector3(0, 0.38, 0), ["bin", "food"])
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
		# Shiny loot to a raccoon: they glint as he comes near one he hasn't picked up yet.
		var can := _prop(pos, 0.2, _cylinder(0.06, 0.16), Vector3.ZERO, ["grabbable", "can", "shiny"],
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
	if NIGHT:
		picture.modulate = Night.PICTURE_TINT.linear_to_srgb()
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

	# THE PLAN: put away until Tab, with the key task at the bottom once he's up. Only
	# to read: the mouse goes through it (to the title's menu while that's up). The line
	# of controls that ran along the bottom was taken out on 24 Oct 2026, when the author
	# asked to "remove the bottom suggestions"; the controls are in the README.
	_plan = PlanNote.new()
	_plan.tasks = tasks
	layer.add_child(_plan)
	if not _first_nap:
		_plan.show_key()

	_paused_label = Label.new()
	_paused_label.text = "Paused"
	_paused_label.visible = false
	_paused_label.add_theme_font_size_override("font_size", 48)
	_paused_label.add_theme_color_override("font_color", Color("f4eedc"))
	_paused_label.add_theme_color_override("font_outline_color", Color("3b3630"))
	_paused_label.add_theme_constant_override("outline_size", 12)
	layer.add_child(_paused_label)
	_paused_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)

	_tuner = CameraTuner.new()
	_tuner.main = self
	_tuner.visible = false
	layer.add_child(_tuner)
	_tuner.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 24)

	if _first_nap:
		# Asleep under the title: just him until he's woken, then a chalk prompt, as on
		# the title, saying how (begin_play).
		_wake_prompt = Label.new()
		_wake_prompt.text = WAKE_PROMPT
		_wake_prompt.add_theme_font_override("font", TitleMenu.FONT)
		_wake_prompt.add_theme_font_size_override("font_size", 34)
		_wake_prompt.add_theme_color_override("font_color", TitleMenu.CHALK)
		_wake_prompt.material = TitleMenu.chalk()
		_wake_prompt.modulate.a = 0.0
		layer.add_child(_wake_prompt)
		_wake_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 48)


## New Game, as the camera starts to glide in: the party next door starts up, and its
## sound waves (sound_waves.gd) pulse at the edge of the screen. Asked for on 25 Oct
## 2026: "when user selects new game start a loud music from the party". At first the
## party was heard and the lullaby dropped under it; later that day the author asked
## for just the waves ("remove the party sound just let the sound waves be there"), so
## the party is silent (campsite.gd PARTY_HEARD) and the lullaby plays on as it was.
func start_party() -> void:
	if campsite:
		campsite.start_party()


## New Game has brought the camera in: the title is gone, he can be woken now, and the
## prompt saying how comes up after a moment.
func begin_play() -> void:
	title = null
	title_view = 0.0
	_set_fog(_fog)
	player.keep_asleep = false
	if _wake_prompt:
		_wake_tween = create_tween()
		_wake_tween.tween_interval(WAKE_PROMPT_AFTER)
		_wake_tween.tween_property(_wake_prompt, "modulate:a", 1.0, UI_FADE)


## He's woken from the nap the game started with: the prompt goes, and once he's down,
## the key task comes up at the bottom (THE PLAN).
func _show_ui() -> void:
	if _wake_tween:
		_wake_tween.kill()
	_plan.show_key(UI_FADE)
	if _wake_prompt:
		create_tween().tween_property(_wake_prompt, "modulate:a", 0.0, UI_FADE * 0.5)
