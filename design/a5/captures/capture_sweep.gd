extends SceneTree
# The author's interface sweep of the cooler's shader (shaders/cooler_paint.gdshader, the
# author's): the course's "Interface sweep (HUMAN CHECK)", each uniform at its minimum, the
# shader's default and its maximum, from the game's own rendered frame, not an OS screenshot.
# It opens the asset room lit as CHANGE-BRIEF.md's material plan says to judge it: the Sun
# and the ambient light at 0.8, with SSAO off (in this run only: nothing is saved). It frames
# the cooler as key 2 does, hides the labels and the help, and pauses the scene. Then F9
# steps through the settings on the body's material (materials/cooler_body.tres), one uniform
# at a time with the others at their committed values. Each is held on screen for HOLD
# seconds, named at the top of the window, and saved without the caption. Last, a strip per
# uniform with its captures side by side, cropped to the cooler, and sweep.txt with what
# each capture set. Nothing is written to the material or the scene: quitting puts it back.
# Run in a window (not headless), from the project folder:
#   godot --path . --script "$(pwd)/design/a5/captures/capture_sweep.gd"
# (design/ is ignored by Godot, so it runs by its file path). `-- --sweep-out=<folder>`
# saves somewhere else, and `-- --auto` starts without F9 (for checking the tool).
# Written by Claude Code on 1 Nov 2026, at the author's request. The captures are the
# author's: they're taken when the author presses the key, and what they show is the
# author's to judge.

const SCENE := "res://asset_room/asset_room.tscn"
const BODY := "res://materials/cooler_body.tres"
const OUT := "res://design/a5/captures/sweep"
const START_KEY := KEY_F9
const HOLD := 1.5  # seconds each setting stays on screen before it's saved
const SETTLE_FRAMES := 10
const CROP_MARGIN := 0.15  # of the cooler's size on screen, round the strips' crop
const FRAME := Vector2i(1280, 720)  # project.godot's viewport size
## Each uniform's settings, in strip order: [label, value]. The minimum and maximum are its
## hint_range, and the default is the shader's own (CHANGE-BRIEF.md, the material plan's
## uniform table). `tint` is a colour, with no range: black, the shader's white, and the
## committed red (null: the material's own value).
const SWEEP := {
	"detail": [["min", 0.0], ["shader default", 0.5], ["max", 1.0]],
	"uv_scale": [["min", 0.25], ["shader default", 1.0], ["max", 4.0]],
	"roughness_scale": [["min", 0.0], ["shader default and max", 1.0]],
	"normal_strength": [["min", 0.0], ["shader default", 1.0], ["max", 2.0]],
	"tint": [["black", Color.BLACK], ["shader default, white", Color.WHITE], ["committed", null]],
}

var out := ""
var lines := PackedStringArray()
var _caption: Label
var _crop: Rect2i
var _base_clipped := -1  # the as-committed capture's, which the others are compared with
var _stopped := false


func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		print("Run this in a window: a headless run renders nothing.")
		quit(1)
		return
	out = ProjectSettings.globalize_path(OUT)
	var auto := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--sweep-out="):
			out = arg.get_slice("=", 1)
		elif arg == "--auto":
			auto = true
	DirAccess.make_dir_recursive_absolute(out)
	# Every capture at one size, so they compare pixel for pixel and the strips' crop fits
	# them all: the project's window size, which can't be resized or maximized meanwhile.
	root.mode = Window.MODE_WINDOWED
	root.size = FRAME
	root.unresizable = true

	var room: Node3D = (load(SCENE) as PackedScene).instantiate()
	root.add_child(room)
	await process_frame  # the room's _ready(), which makes its camera, labels and help
	room._set_view("cooler")
	for label: Label3D in room._labels:
		label.visible = false
	for layer in room.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	var env: Environment = (room.get_node("WorldEnvironment") as WorldEnvironment).environment
	env.ssao_enabled = false
	var material := _body_material(room.get_node("Cooler"))
	if material == null or not _shader_declares_the_uniforms(material):
		quit(1)
		return
	var committed := {}
	for uniform: String in SWEEP:
		committed[uniform] = material.get_shader_parameter(uniform)
	_add_caption()
	for i in SETTLE_FRAMES:
		await process_frame  # the room places its camera in _process
	paused = true  # the raccoon's and the people's animations hold still
	_crop = _cooler_on_screen(room)

	var sun: DirectionalLight3D = room.get_node("Sun")
	_line("Interface sweep of shaders/cooler_paint.gdshader on %s, %s, window %d x %d." % [BODY,
		Time.get_datetime_string_from_system(), root.get_visible_rect().size.x, root.get_visible_rect().size.y])
	_line("The asset room, framed as key 2 frames the cooler, paused. Sun light_energy %.1f, ambient_light_energy %.1f, SSAO %s, tonemap %d, exposure %.1f."
		% [sun.light_energy, env.ambient_light_energy, "on" if env.ssao_enabled else "off", env.tonemap_mode, env.tonemap_exposure])
	_line("Committed: " + ", ".join(SWEEP.keys().map(func(u: String) -> String: return "%s %s" % [u, _text(committed[u])])))
	_line("Each capture changes one uniform; the others stay at the committed values. The strips are cropped to the cooler, at %s." % [_crop])
	_line("'clipped' counts the pixels in that crop with a channel at 254 or 255: blown out. The lid isn't swept, so its own")
	_line("clipped pixels are in every capture; the change against the as-committed capture is the body's setting.")

	if not auto:
		_show("The cooler as committed, SSAO off. With this window in front, press F9 to step through the sweep (about %d s)." % ceili(HOLD * 14))
		print("READY: the cooler as committed. Press F9 in the game window to take the sweep.")
		while not Input.is_key_pressed(START_KEY):
			await process_frame

	var n := 0
	_line("")
	await _capture("%02d_as_committed.png" % n, "as committed", HOLD)
	if _stopped:
		return
	for uniform: String in SWEEP:
		var strip: Array[Image] = []
		var labels := PackedStringArray()
		for setting: Array in SWEEP[uniform]:
			n += 1
			var value = committed[uniform] if setting[1] == null else setting[1]
			_set_all(material, committed)
			material.set_shader_parameter(uniform, value)
			var file := "%02d_%s_%s.png" % [n, uniform, setting[0].get_slice(",", 0).replace(" ", "_")]
			strip.append(await _capture(file, "%s = %s (%s)" % [uniform, _text(value), setting[0]], HOLD))
			if _stopped:
				return
			labels.append("%s %s" % [setting[0], _text(value)])
		_set_all(material, committed)
		_save_strip("strip_%s.png" % uniform, strip)
		_line("  strip_%s.png, left to right: %s" % [uniform, " | ".join(labels)])

	_line("")
	_line("What changed on screen, and whether a setting breaks the look, is the author's to write (TEST-REPORT.md).")
	var f := FileAccess.open(out.path_join("sweep.txt"), FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	print("DONE: %d captures and %d strips in %s" % [n + 1, SWEEP.size(), out])
	quit(0)


## The body's material, as the cooler draws it (behind cooler.glb's Use External).
func _body_material(cooler: Node) -> ShaderMaterial:
	for m: MeshInstance3D in cooler.find_children("*", "MeshInstance3D", true, false):
		for s in m.mesh.get_surface_count():
			var material := m.get_active_material(s)
			if material is ShaderMaterial and material.resource_path == BODY:
				return material
	print("STOPPED: no surface of the cooler draws with %s." % BODY)
	return null


## The sweep sets these names, so the shader on disk must declare them: setting one it
## doesn't declare raises no error, and every capture would quietly look the same.
func _shader_declares_the_uniforms(material: ShaderMaterial) -> bool:
	var names: Array = material.shader.get_shader_uniform_list().map(func(u: Dictionary) -> String: return u.name)
	var missing := SWEEP.keys().filter(func(u: String) -> bool: return not u in names)
	if missing.is_empty():
		return true
	print("STOPPED: the cooler's shader doesn't declare %s (it has: %s). Is a mutation still on disk? Restore it with: git checkout -- shaders/cooler_paint.gdshader"
		% [", ".join(missing), ", ".join(names)])
	return false


func _set_all(material: ShaderMaterial, values: Dictionary) -> void:
	for uniform: String in values:
		material.set_shader_parameter(uniform, values[uniform])


## Shows the setting for `hold` seconds, then saves the frame with the caption hidden.
func _capture(file: String, what: String, hold: float) -> Image:
	_show(what)
	await create_timer(hold).timeout
	_caption.visible = false
	for i in 3:
		await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img.get_size() != FRAME:
		print("STOPPED: the frame came out %d x %d, not %d x %d. Leave the window as it opens, and run it again."
			% [img.get_width(), img.get_height(), FRAME.x, FRAME.y])
		_stopped = true
		quit(1)
		return img
	img.save_png(out.path_join(file))
	_caption.visible = true
	var clipped := _clipped(img)
	if _base_clipped < 0:
		_base_clipped = clipped
	_line("%-46s %-46s clipped %d (%+d against as committed)" % [file, what, clipped, clipped - _base_clipped])
	return img


func _save_strip(file: String, images: Array[Image]) -> void:
	const GAP := 6
	var w := _crop.size.x
	var strip := Image.create_empty(w * images.size() + GAP * (images.size() - 1), _crop.size.y, false, Image.FORMAT_RGBA8)
	strip.fill(Color(0.15, 0.15, 0.15))
	for i in images.size():
		var part := images[i].get_region(_crop)
		part.convert(Image.FORMAT_RGBA8)
		strip.blit_rect(part, Rect2i(Vector2i.ZERO, _crop.size), Vector2i(i * (w + GAP), 0))
	strip.save_png(out.path_join(file))


## The cooler's box on screen, with a margin, kept inside the window.
func _cooler_on_screen(room: Node3D) -> Rect2i:
	var box: AABB = room._bounds(room.get_node("Cooler"))
	var camera: Camera3D = room.get_node("Camera3D")
	var r := Rect2(camera.unproject_position(box.position), Vector2.ZERO)
	for i in 8:
		r = r.expand(camera.unproject_position(box.get_endpoint(i)))
	r = r.grow_individual(r.size.x * CROP_MARGIN, r.size.y * CROP_MARGIN, r.size.x * CROP_MARGIN, r.size.y * CROP_MARGIN)
	return Rect2i(r).intersection(Rect2i(Vector2i.ZERO, Vector2i(root.get_visible_rect().size)))


func _clipped(img: Image) -> int:
	var part := img.get_region(_crop)
	part.convert(Image.FORMAT_RGB8)
	var data := part.get_data()
	var count := 0
	for i in range(0, data.size(), 3):
		if data[i] >= 254 or data[i + 1] >= 254 or data[i + 2] >= 254:
			count += 1
	return count


func _add_caption() -> void:
	var layer := CanvasLayer.new()
	_caption = Label.new()
	_caption.position = Vector2(12, 10)
	_caption.add_theme_color_override("font_color", Color.WHITE)
	_caption.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_caption.add_theme_constant_override("outline_size", 6)
	layer.add_child(_caption)
	root.add_child(layer)


func _show(text: String) -> void:
	_caption.text = text
	print(text)


func _text(value) -> String:
	if value is Color:
		return "#" + (value as Color).to_html(false)
	return "%.3f" % value if value is float else str(value)


func _line(text: String) -> void:
	lines.append(text)
