extends Sprite3D
## The raccoon as the player sees him: one generated image per state, swapped as
## his state changes and mirrored when he moves left on screen (CHANGE-BRIEF.md).
## The 3D raccoon stays underneath, invisible, for its mouth (where carried things
## go) and its shadow.

const DIR := "res://assets/characters/raccoon/"
## Each cut-out's scale and ground point, written by
## design/character/make_character_sheet.gd.
const METRICS := DIR + "cutouts.json"
## The scale cutouts.json is in: pixels per metre on screen at the default zoom.
const PX_PER_M := 146.0
## How long with no input before he gets bored, in seconds.
const BORED_AFTER := 5.0
## State -> cut-out. Climbing has no image of its own yet, so it shows the sneak
## pose turned upright.
const IMAGES := {
	"idle": "idle", "run": "running", "sneak": "sneak", "bored": "bored",
	"asleep": "asleep", "climb": "sneak",
}

## Set by the level.
var player: CharacterBody3D
var camera: Camera3D
## For screenshots: show this state ("" = his real one), facing left if set.
var forced_state := ""
var forced_left := false
## The state on screen now.
var state := "idle"

var _frames := {}
var _facing_left := false
var _idle_time := 0.0
var _bounce := 0.0


func _ready() -> void:
	var metrics: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(METRICS))
	for key: String in IMAGES:
		var file: String = IMAGES[key]
		var img := (load(DIR + file + ".png") as Texture2D).get_image()
		if img.is_compressed():
			img.decompress()
		img.generate_mipmaps()
		var m: Dictionary = metrics[file]
		_frames[key] = {
			"texture": ImageTexture.create_from_image(img),
			"pixel_size": float(m.game_scale) / PX_PER_M,
			"feet": float(m.feet_row),
			"anchor": float(m.anchor_x),
			"w": float(img.get_width()),
			"h": float(img.get_height()),
		}
	centered = false
	shaded = false
	alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	player.chittered.connect(func() -> void: _bounce = 1.0)
	# The 3D raccoon now only casts his shadow.
	for mesh: GeometryInstance3D in player.model.find_children("*", "GeometryInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY


func _process(delta: float) -> void:
	state = forced_state if forced_state != "" else _current_state(delta)
	var f: Dictionary = _frames[state]
	texture = f.texture
	pixel_size = f.pixel_size

	# Mirror him when he moves left on screen; moving straight up or down the
	# screen keeps his last facing.
	var across := camera.global_basis.x.dot(player.velocity)
	if across > 0.15:
		_facing_left = false
	elif across < -0.15:
		_facing_left = true
	var left := forced_left if forced_state != "" else _facing_left
	flip_h = left
	if state == "climb":
		# On a trunk he turns about his middle, which sits on the bark.
		offset = Vector2(-f.w * 0.5, -f.h * 0.5)
	else:
		# Put his anchor (between his paws, on his lowest row) on the player's origin.
		var anchor: float = f.w - f.anchor if left else f.anchor
		offset = Vector2(-anchor, -(f.h - 1.0 - f.feet))

	# Face the camera. On a trunk, turn him so his head points up it.
	var facing := camera.global_basis
	if state == "climb":
		facing = facing * Basis(Vector3.BACK, -PI / 2 if left else PI / 2)
	# A quick squash and hop when he chitters, so it reads with the sound off.
	_bounce = maxf(_bounce - delta / 0.35, 0.0)
	var squash := sin(_bounce * PI)
	global_basis = facing * Basis.from_scale(Vector3(1.0 + 0.07 * squash, 1.0 - 0.12 * squash, 1.0))
	global_position = player.global_position + camera.global_basis.y * 0.05 * squash
	if state == "climb":
		# Drawn a little toward the camera, so the bark doesn't cut through him.
		global_position += camera.global_basis.z * 0.35


func _current_state(delta: float) -> String:
	var active := Input.get_vector("move_left", "move_right", "move_forward", "move_back").length() > 0.1
	for action: String in ["sneak", "run", "grab", "chitter"]:
		active = active or Input.is_action_pressed(action)
	_idle_time = 0.0 if active else _idle_time + delta
	if player.is_hopping():
		return "run"
	if player.resting:
		return "asleep"
	if player.climbing:
		return "climb"
	if player.sneaking:
		return "sneak"
	if Vector2(player.velocity.x, player.velocity.z).length() > 0.1:
		return "run"
	if _idle_time > BORED_AFTER:
		return "bored"
	return "idle"
