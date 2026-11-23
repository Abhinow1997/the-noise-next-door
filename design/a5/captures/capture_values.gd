extends SceneTree
# The author's controlled-value captures of the camper's vision cone (CHANGE-BRIEF.md,
# Assignment 5, the evidence split's "How I take the captures"): in a window, with a
# debug key, from the game's own rendered frame, not an OS screenshot.
# It sets the game up and frames the camera as make_captures.gd did for the grass
# captures, so the two spots fall where they did then, and pauses it there. Then F9
# holds the driver off and, for `alarm` 0, 0.5, 1 and 2.0 (with `shown` 1), saves a
# capture with only the camper's cone showing and one of the same frame with every cone
# hidden, for the grass under the spots. Then one pair more with the fog off, at `alarm`
# 0. It prints the pixels at both spots and writes them to values.txt beside the images.
# Last, it holds the `alarm` 1 frame for an OS screenshot to compare; F9 again quits.
# Run in a window (not headless), from the project folder:
#   godot --path . --script "$(pwd)/design/a5/captures/capture_values.gd" -- --cone-capture="$(pwd)/design/a5/captures/values"
# (design/ is ignored by Godot, so it runs by its file path)
# Written by Claude Code on 29 Oct 2026, at the author's request. The captures are the
# author's: they're taken when the author presses the key.

const SPOTS := [["Base at Camper", 0.5], ["Far Edge", -0.5]]  # metres from the apex; negative = from the far end
const VALUES := [0.0, 0.5, 1.0, 2.0]
const FOG_OFF_AT := 0.0
const HOLD_AT := 1.0
const CAPTURE_KEY := KEY_F9

var level: Node
var out := ""
var t := 0.0
var phase := 0
var spots: Array = []
var lines: PackedStringArray = []
var _was_down := false
var _driver: Node
var _env: Environment


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--cone-capture="):
			out = arg.get_slice("=", 1)
	if out == "":
		push_error("Say where the captures go: -- --cone-capture=<folder>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(out)
	level = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(level)


func _process(delta: float) -> bool:
	t += delta
	var pressed := _key_pressed()
	match phase:
		0:
			if t > 1.5:
				# As after the tutorial, with him well away so nobody sees him (as
				# make_captures.gd).
				level.tasks.reveal()
				level.campsite.cones_on = true
				level.player.place(Vector3(20.0, 0.02, 6.5))
				phase = 1
				t = 0.0
		1:
			if t > 1.5:
				if not _shader_declares_the_uniforms():
					quit(1)
					return false
				_freeze_and_frame()
				print("READY: paused, and framed on the camper's cone. Press F9 in the game window to take the captures.")
				phase = 2
		2:
			if pressed:
				phase = 3
				_take_all()
		4:
			if pressed:
				return true
	return false


## The captures set `alarm` and `shown`, so the shader on disk must declare them: with a
## mutation left in place, every capture would quietly look like `alarm` 0.
func _shader_declares_the_uniforms() -> bool:
	var material: ShaderMaterial = level.campsite.camper.eyes.material()
	var names: Array = material.shader.get_shader_uniform_list().map(func(u: Dictionary) -> String: return u.name)
	if "alarm" in names and "shown" in names:
		return true
	print("STOPPED: the cone's shader doesn't declare alarm and shown (it has: %s). Is a mutation still on disk? Restore it with: git checkout -- shaders/vision_cone.gdshader" % ", ".join(names))
	return false


## True on the frame F9 goes down, in the game window.
func _key_pressed() -> bool:
	var down := Input.is_key_pressed(CAPTURE_KEY)
	var pressed := down and not _was_down
	_was_down = down
	return pressed


## Pauses the game (the people stop where they are, and so does the fire's flicker), hides
## the overlays, and centres the game's camera, as it is, on the middle of the camper's
## cone, as make_captures.gd did for the grass captures. Works out where the two spots are.
func _freeze_and_frame() -> void:
	paused = true
	for layer in level.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	level.forest.see_through.set_shader_parameter("focus_uv", Vector2(-10.0, -10.0))
	var eyes: Node3D = level.campsite.camper.eyes
	var apex := Vector3(eyes.global_position.x, 0.03, eyes.global_position.z)
	var ahead := -eyes.global_basis.z
	ahead.y = 0.0
	ahead = ahead.normalized()
	var length: float = eyes.drawn_length()
	var camera: Camera3D = level.camera
	var middle := apex + ahead * length * 0.5
	var him: Vector3 = level.player.global_position
	var depth: float = (him - camera.global_position).dot(-camera.global_basis.z)
	camera.global_position = middle + camera.global_basis.z * depth
	for spot: Array in SPOTS:
		var d: float = spot[1] if spot[1] >= 0.0 else length + spot[1]
		var p := camera.unproject_position(apex + ahead * d)
		# Along the fan's middle line the corner alpha falls straight from 0.55 at the
		# apex to 0.12 at the arc (vision_cone.gd _build_cone).
		spots.append({"name": spot[0], "metres": d, "length": length, "alpha": 0.55 - 0.43 * d / length,
			"px": Vector2i(roundi(p.x), roundi(p.y))})
	for child in level.campsite.get_children():
		var script: Script = child.get_script()
		if script and script.resource_path.ends_with("cone_driver.gd"):
			_driver = child
	var world: WorldEnvironment = level.find_children("*", "WorldEnvironment", true, false)[0]
	_env = world.environment


## Every capture, then the frame held for the OS screenshot. The driver is held off first,
## as in the course's capture(): otherwise it would set the values back before the frame
## is drawn.
func _take_all() -> void:
	_driver.set_process(false)
	_driver.set_physics_process(false)
	var size := root.get_texture().get_image().get_size()
	_line("Captures of the camper's cone, %s, window %d x %d. The game is paused and the driver held off."
		% [Time.get_datetime_string_from_system(), size.x, size.y])
	for s: Dictionary in spots:
		_line("%s: %.2f m from the apex of a %.2f m cone, corner alpha %.3f, pixel (%d, %d)"
			% [s.name, s.metres, s.length, s.alpha, s.px.x, s.px.y])
	for value: float in VALUES:
		await _pair("alarm_%.1f" % value, value)
	_env.fog_enabled = false
	await _pair("fog_off_alarm_%.1f" % FOG_OFF_AT, FOG_OFF_AT)
	_env.fog_enabled = true
	_set_alarm(HOLD_AT)
	_show_only_camper(true)
	await _drawn()
	var file := FileAccess.open(out.path_join("values.txt"), FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
	print("HOLDING the alarm %.1f frame: take your OS screenshot now, then press F9 in the game window to finish." % HOLD_AT)
	phase = 4


## A capture with only the camper's cone showing, at `alarm` = value and `shown` 1, and one
## of the same paused frame with every cone hidden, for the grass under both spots.
func _pair(name: String, value: float) -> void:
	_show_only_camper(false)
	await _drawn()
	var bare := _save(name + "_bare.png")
	_set_alarm(value)
	_show_only_camper(true)
	await _drawn()
	var cone := _save(name + ".png")
	_line("%s: alarm %.1f, shown 1.0, fog %s" % [name, value, "on" if _env.fog_enabled else "off"])
	for s: Dictionary in spots:
		if not Rect2i(Vector2i.ZERO, cone.get_size()).has_point(s.px):
			_line("  %-15s off the screen at (%d, %d)" % [s.name, s.px.x, s.px.y])
			continue
		_line("  %-15s cone %s, 5x5 mean %s   bare %s, 5x5 mean %s" % [s.name, _rgb(cone, s.px),
			_mean(cone, s.px), _rgb(bare, s.px), _mean(bare, s.px)])


func _set_alarm(value: float) -> void:
	var material: ShaderMaterial = level.campsite.camper.eyes.material()
	material.set_shader_parameter("alarm", value)
	material.set_shader_parameter("shown", 1.0)


func _show_only_camper(on: bool) -> void:
	for person in level.campsite.people:
		person.eyes.show_on_ground(false)
	if on:
		level.campsite.camper.eyes.show_on_ground(true)


## Until the change is on screen: three frames drawn after it.
func _drawn() -> void:
	for i in 3:
		await RenderingServer.frame_post_draw


func _save(name: String) -> Image:
	var img := root.get_texture().get_image()
	img.save_png(out.path_join(name))
	return img


func _line(text: String) -> void:
	print(text)
	lines.append(text)


func _rgb(img: Image, px: Vector2i) -> String:
	var c := img.get_pixelv(px)
	return "(%d, %d, %d)" % [roundi(c.r * 255.0), roundi(c.g * 255.0), roundi(c.b * 255.0)]


func _mean(img: Image, px: Vector2i) -> String:
	var sum := Vector3.ZERO
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var c := img.get_pixel(clampi(px.x + dx, 0, img.get_width() - 1), clampi(px.y + dy, 0, img.get_height() - 1))
			sum += Vector3(c.r, c.g, c.b)
	sum = sum / 25.0 * 255.0
	return "(%.1f, %.1f, %.1f)" % [sum.x, sum.y, sum.z]
