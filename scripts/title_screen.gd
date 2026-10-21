extends Node
## The title screen, after the author's picture design/reference/title-screen.webp,
## shown over the level itself (main.gd): the game's own home pine and woods at night,
## framed as in the picture, with the raccoon asleep in his hollow, his z's, the
## fireflies and falling leaves (night_life.gd) and the lullaby; and the title and menu
## in chalk over the sky (title_menu.gd). New Game fades the writing and glides the
## camera in to the level's nap close-up: it's the same world all the way, so nothing
## changes but the camera, and play starts from there.
## Debug: `-- --title-shot=out.png [--title-frame=N] [--title-settings]` saves a frame
## (with the Settings page open) and quits; `-- --title-test` runs the automated check
## (scripts/title_test.gd).

const TitleMenu := preload("res://scripts/title_menu.gd")
const GameSettings := preload("res://scripts/game_settings.gd")
const TitleTest := preload("res://scripts/title_test.gd")

## The picture's camera, as measured from it (1024 × 572, filling the width of a 16:9
## screen): nearly level, a little above the hollow, with a lens 40° tall, placed so
## that the home pine's foot is at HOME_PIXEL.
const PICTURE := Vector2(1024, 572)
const VIEW_PITCH := 3.0
const VIEW_HEIGHT := 3.5
const VIEW_FOV := 40.0
const HOME_PIXEL := Vector2(365, 505)
## The picture's haze, nearer and thicker than the level's (where it begins and ends,
## in metres, and how thick), so the far woods fade into the night as they do there.
const FOG := Vector3(14.0, 34.0, 0.85)
## The camera drifts this far side to side and up and down, very slowly (seconds a sway).
const DRIFT := Vector2(0.12, 0.05)
const DRIFT_TIME := Vector2(23.0, 31.0)
## Seconds to fade in from black when the game opens.
const FADE_IN := 1.5
## New Game: the writing fades over MENU_FADE seconds while the camera glides in over
## GLIDE seconds to the level's nap close-up.
const MENU_FADE := 0.6
const GLIDE := 2.6

## The level it's shown over (main.gd); set before it's added.
var level: Node3D
var menu: TitleMenu
var _view: Transform3D
var _fade: ColorRect
var _t := 0.0
## How far (0..1) the camera has glided in after New Game, or -1 before.
var _glide := -1.0
var _shot_path := ""
var _shot_frame := 45
var _frames := 0


## The camera the picture was taken from, with the home pine's foot at `home`.
static func picture_view(home: Vector3) -> Transform3D:
	var probe := Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-VIEW_PITCH)), Vector3(0, VIEW_HEIGHT, 0))
	var down := _ray(probe, HOME_PIXEL)
	var foot := probe.origin + down * (-probe.origin.y / down.y)
	return probe.translated(home - Vector3(foot.x, 0, foot.z))


## The point `depth` metres from the camera `view` along the ray through pixel `px` of
## the picture.
static func along(view: Transform3D, px: Vector2, depth: float) -> Vector3:
	return view.origin + _ray(view, px).normalized() * depth


static func _ray(view: Transform3D, px: Vector2) -> Vector3:
	var f := PICTURE.x * 0.5 / (tan(deg_to_rad(VIEW_FOV) * 0.5) * 16.0 / 9.0)
	return view.basis * Vector3((px.x - PICTURE.x * 0.5) / f, (PICTURE.y * 0.5 - px.y) / f, -1.0)


func _ready() -> void:
	var settings_shot := false
	var test := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--title-shot="):
			_shot_path = arg.get_slice("=", 1)
		elif arg.begins_with("--title-frame="):
			_shot_frame = int(arg.get_slice("=", 1))
		elif arg == "--title-settings":
			settings_shot = true
		elif arg == "--title-test":
			test = true
	GameSettings.load_settings()
	GameSettings.apply()

	_view = picture_view(level.Forest.HOME)
	level.title_camera = _view
	level.title_fov = VIEW_FOV
	level.title_fog = FOG
	level.title_view = 1.0

	# Over the level's own writing (which is hidden until he's up anyway).
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	menu = TitleMenu.new()
	menu.chosen.connect(_on_chosen)
	layer.add_child(menu)
	if settings_shot:
		menu.open_settings()
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	if _shot_path != "":
		_fade.color.a = 0.0
	else:
		create_tween().tween_property(_fade, "color:a", 0.0, FADE_IN)
	if test:
		# On the root, so it's there throughout.
		var check := TitleTest.new()
		check.title = self
		check.level = level
		get_tree().root.add_child.call_deferred(check)


func _process(delta: float) -> void:
	_t += delta
	if _glide >= 0.0:
		_glide = minf(_glide + delta / GLIDE, 1.0)
		level.title_view = 1.0 - smoothstep(0.0, 1.0, _glide)
		if _glide >= 1.0:
			level.begin_play()
			queue_free()
			return
	else:
		level.title_camera = _view.translated(Vector3(sin(_t * TAU / DRIFT_TIME.x) * DRIFT.x,
			sin(_t * TAU / DRIFT_TIME.y) * DRIFT.y, 0))

	if _shot_path != "":
		_frames += 1
		if _frames == _shot_frame - 15:
			# Stopped well before the quit, so the audio thread has let go of them.
			for music: AudioStreamPlayer in [level._music, level._sleep_music]:
				if music:
					music.stop()
		if _frames == _shot_frame:
			get_viewport().get_texture().get_image().save_png(_shot_path)
			get_tree().quit()


func _on_chosen(item: String) -> void:
	match item:
		"new_game":
			menu.locked = true
			var fade := create_tween().set_parallel()
			fade.tween_property(menu, "modulate:a", 0.0, MENU_FADE)
			# Chosen while the game is still fading in from black: finish that quickly.
			fade.tween_property(_fade, "color:a", 0.0, MENU_FADE)
			_glide = 0.0
		"quit":
			get_tree().quit()
