extends SceneTree
# In-engine captures of the camper's vision cone on the night grass, for the author's
# predicted pixels (CHANGE-BRIEF.md, Assignment 5): the grass with every cone hidden,
# the cone as it's drawn today, and a copy of that with the two spots marked. Prints
# where the two spots are on the screen, the cone's corner alpha there, and the pixels.
# Run in a window (not headless):
#   godot --path . --script "$(pwd)/design/a5/captures/make_captures.gd" -- --cone-capture="$(pwd)/design/a5/captures"
# (from the project folder; design/ is ignored by Godot, so it runs by its file path)
# Written by Claude Code on 28 Oct 2026, at the author's request.

const SPOTS := [["Base at Camper", 0.5], ["Far Edge", -0.5]]  # metres from the apex; negative = from the far end

var level: Node
var out := ""
var t := 0.0
var phase := 0
var frames := 0
var spots: Array = []


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--cone-capture="):
			out = arg.get_slice("=", 1)
	DirAccess.make_dir_recursive_absolute(out)
	level = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(level)


func _process(delta: float) -> bool:
	t += delta
	match phase:
		0:
			if t > 1.5:
				# As after the tutorial, with him well away so nobody sees him.
				level.tasks.reveal()
				level.campsite.cones_on = true
				level.player.place(Vector3(20.0, 0.02, 6.5))
				phase = 1
				t = 0.0
		1:
			if t > 1.5:
				_freeze_and_frame()
				for cone in _cones():
					cone.show_on_ground(false)
				frames = 0
				phase = 2
		2:
			frames += 1
			if frames == 4:
				_save("01_grass_cones_hidden_by-claude.png")
				level.campsite.camper.eyes.show_on_ground(true)
				frames = 0
				phase = 3
		3:
			frames += 1
			if frames == 4:
				var img := _save("02_cone_as_now_by-claude.png")
				_report(img)
				_mark(img)
				img.save_png(out.path_join("03_spots_marked_by-claude.png"))
				return true
	return false


func _cones() -> Array:
	return level.campsite.people.map(func(p): return p.eyes)


## Pauses the game (the people stop where they are), hides the overlays, and centres
## the game's camera, as it is, on the middle of the camper's cone.
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
		spots.append({"name": spot[0], "metres": d, "length": length, "at": apex + ahead * d})


func _save(name: String) -> Image:
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out.path_join(name))
	return img


func _report(now: Image) -> void:
	var grass := Image.load_from_file(out.path_join("01_grass_cones_hidden_by-claude.png"))
	var camera: Camera3D = level.camera
	print("CAPTURE size %s, camera %s looking %s" % [now.get_size(), camera.global_position, -camera.global_basis.z])
	for s: Dictionary in spots:
		var p := camera.unproject_position(s.at)
		var x := roundi(p.x)
		var y := roundi(p.y)
		# Along the fan's middle line the corner alpha falls straight from 0.55 at the
		# apex to 0.12 at the arc (vision_cone.gd _build_cone).
		var alpha: float = 0.55 - 0.43 * float(s.metres) / float(s.length)
		print("SPOT %s: %.2f m from the apex of a %.2f m cone, corner alpha %.3f, pixel (%d, %d)" % [s.name, s.metres,
			s.length, alpha, x, y])
		print("  grass  centre %s  5x5 mean %s" % [_rgb(grass.get_pixel(x, y)), _mean(grass, x, y)])
		print("  now    centre %s  5x5 mean %s" % [_rgb(now.get_pixel(x, y)), _mean(now, x, y)])
		s["px"] = Vector2i(x, y)


func _rgb(c: Color) -> String:
	return "(%d, %d, %d)" % [roundi(c.r * 255.0), roundi(c.g * 255.0), roundi(c.b * 255.0)]


func _mean(img: Image, x: int, y: int) -> String:
	var sum := Vector3.ZERO
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var c := img.get_pixel(x + dx, y + dy)
			sum += Vector3(c.r, c.g, c.b)
	sum = sum / 25.0 * 255.0
	return "(%.1f, %.1f, %.1f)" % [sum.x, sum.y, sum.z]


## Small white rings round the spots, on a copy only: the other two are untouched.
func _mark(img: Image) -> void:
	for s: Dictionary in spots:
		var c: Vector2i = s.px
		for i in 72:
			var a := TAU * i / 72.0
			for r in [9.0, 10.0]:
				var q := c + Vector2i(roundi(cos(a) * r), roundi(sin(a) * r))
				if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height():
					img.set_pixelv(q, Color.WHITE)
