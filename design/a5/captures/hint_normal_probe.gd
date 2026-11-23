extends SceneTree
# Claude Code's probe of what `hint_normal` does, on the cooler's body in the asset room, for
# LANGUAGE-NOTES.md's question 4 ("does it change only the Inspector, or also the value the
# shader receives?"). In a window, from the game's own rendered frame, lit as the interface
# sweep is (capture_sweep.gd): the Sun and the ambient light at 0.8, SSAO off, paused. On the
# body's material, in memory only, it saves five frames:
#   a: as committed;
#   b: `normal_strength` 0, with the normal map bound: the map has no effect;
#   c: the normal map unbound, at `normal_strength` 1: what an unbound `hint_normal` sampler gives;
#   d: the author's shader with `hint_normal` taken out of `normal_texture` (a copy built in
#      memory; shaders/ is untouched), with the map bound: what the hint does to a bound map;
#   e: that copy with the map unbound: what an unbound sampler gives without the hint, so c
#      against e is what the hint does when nothing is bound.
# Then it compares them inside the cooler's box on screen and writes probe.txt beside them.
# Nothing is saved to the material, the shader or the scene.
# Run in a window (not headless), from the project folder:
#   godot --path . --script "$(pwd)/design/a5/captures/hint_normal_probe.gd"
# (design/ is ignored by Godot, so it runs by its file path)
# Written by Claude Code on 1 Nov 2026, at the author's request ("Yes, add it").

const SCENE := "res://asset_room/asset_room.tscn"
const BODY := "res://materials/cooler_body.tres"
const OUT := "res://design/a5/captures/hint-normal"
const FRAME := Vector2i(1280, 720)  # project.godot's viewport size
const SETTLE_FRAMES := 10
const CROP_MARGIN := 0.15
const STEP := 2  # a pixel differs if a channel moves by more than this many 8-bit steps
const MAX_LISTED := 5  # a pair with this many differing pixels or fewer has each one listed
## The pairs compared, and what each pair answers.
const PAIRS := [
	["a_committed", "b_strength_0", "does the normal map change the cooler at all (the probe can see it)?"],
	["b_strength_0", "c_unbound", "unbound, does the sampler give a flat normal (the same as no map)?"],
	["a_committed", "d_bound_no_hint", "bound, does taking hint_normal out change what the shader samples?"],
	["c_unbound", "e_unbound_no_hint", "unbound, does taking hint_normal out change what the sampler gives?"],
]

var out := ""
var lines := PackedStringArray()


func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		print("Run this in a window: a headless run renders nothing.")
		quit(1)
		return
	out = ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(out)
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
	(room.get_node("WorldEnvironment") as WorldEnvironment).environment.ssao_enabled = false
	var material := _body_material(room.get_node("Cooler"))
	if material == null:
		quit(1)
		return
	var shader: Shader = material.shader
	var map: Texture2D = material.get_shader_parameter("normal_texture")
	var strength: float = material.get_shader_parameter("normal_strength")
	var no_hint := Shader.new()
	no_hint.code = shader.code.replace("normal_texture : hint_normal, ", "normal_texture : ")
	if no_hint.code == shader.code or not shader.code.contains("hint_normal"):
		print("STOPPED: normal_texture isn't declared with hint_normal as expected in %s." % shader.resource_path)
		quit(1)
		return
	for i in SETTLE_FRAMES:
		await process_frame  # the room places its camera in _process
	paused = true
	var crop := _cooler_on_screen(room)

	_line("hint_normal probe on %s (%s), %s, window %d x %d." % [BODY, shader.resource_path,
		Time.get_datetime_string_from_system(), FRAME.x, FRAME.y])
	_line("The asset room, framed as key 2 frames the cooler, paused, SSAO off. Committed: normal_strength %.3f, normal_texture %s."
		% [strength, map.resource_path])
	_line("Compared inside the cooler's box on screen, %s: a pixel differs if a channel moves by more than %d steps." % [crop, STEP])
	_line("")
	var frames := {}
	frames["a_committed"] = await _capture("a_committed")
	material.set_shader_parameter("normal_strength", 0.0)
	frames["b_strength_0"] = await _capture("b_strength_0")
	material.set_shader_parameter("normal_strength", strength)
	material.set_shader_parameter("normal_texture", null)
	frames["c_unbound"] = await _capture("c_unbound")
	material.set_shader_parameter("normal_texture", map)
	material.shader = no_hint
	frames["d_bound_no_hint"] = await _capture("d_bound_no_hint")
	material.set_shader_parameter("normal_texture", null)
	frames["e_unbound_no_hint"] = await _capture("e_unbound_no_hint")
	material.set_shader_parameter("normal_texture", map)
	material.shader = shader
	for frame: String in frames:
		if (frames[frame] as Image).get_size() != FRAME:
			print("STOPPED: %s came out %s, not %s. Leave the window as it opens, and run it again." % [frame, frames[frame].get_size(), FRAME])
			quit(1)
			return

	for pair: Array in PAIRS:
		var diff := _differ(frames[pair[0]], frames[pair[1]], crop)
		_line("%-16s vs %-16s %6d of %d pixels differ, largest %3d   (%s)" % [pair[0], pair[1], diff.x, crop.get_area(), diff.y, pair[2]])
		if diff.x > 0 and diff.x <= MAX_LISTED:
			_list_pixels(frames[pair[0]], frames[pair[1]], crop, pair)
	var f := FileAccess.open(out.path_join("probe.txt"), FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	for line in lines:
		print(line)
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


## Three frames drawn after the change, then the frame saved.
func _capture(name: String) -> Image:
	for i in 3:
		await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out.path_join(name + ".png"))
	return img


## How many pixels in `crop` differ by more than STEP on some channel, and the largest change.
func _differ(a: Image, b: Image, crop: Rect2i) -> Vector2i:
	var pa := a.get_region(crop)
	var pb := b.get_region(crop)
	pa.convert(Image.FORMAT_RGB8)
	pb.convert(Image.FORMAT_RGB8)
	var da := pa.get_data()
	var db := pb.get_data()
	var count := 0
	var largest := 0
	for i in range(0, da.size(), 3):
		var d := maxi(maxi(absi(da[i] - db[i]), absi(da[i + 1] - db[i + 1])), absi(da[i + 2] - db[i + 2]))
		largest = maxi(largest, d)
		if d > STEP:
			count += 1
	return Vector2i(count, largest)


## Where each differing pixel is, in the whole frame, with its colour in both frames.
func _list_pixels(a: Image, b: Image, crop: Rect2i, pair: Array) -> void:
	for y in range(crop.position.y, crop.end.y):
		for x in range(crop.position.x, crop.end.x):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if maxi(maxi(absi(ca.r8 - cb.r8), absi(ca.g8 - cb.g8)), absi(ca.b8 - cb.b8)) > STEP:
				_line("    pixel (%d, %d): #%s in %s, #%s in %s" % [x, y, ca.to_html(false), pair[0], cb.to_html(false), pair[1]])


## The cooler's box on screen, with a margin, kept inside the window (as capture_sweep.gd).
func _cooler_on_screen(room: Node3D) -> Rect2i:
	var box: AABB = room._bounds(room.get_node("Cooler"))
	var camera: Camera3D = room.get_node("Camera3D")
	var r := Rect2(camera.unproject_position(box.position), Vector2.ZERO)
	for i in 8:
		r = r.expand(camera.unproject_position(box.get_endpoint(i)))
	r = r.grow_individual(r.size.x * CROP_MARGIN, r.size.y * CROP_MARGIN, r.size.x * CROP_MARGIN, r.size.y * CROP_MARGIN)
	return Rect2i(r).intersection(Rect2i(Vector2i.ZERO, FRAME))


func _line(text: String) -> void:
	lines.append(text)
