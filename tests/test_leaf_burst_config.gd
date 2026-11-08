extends SceneTree
# Effect A's configuration test (CHANGE-BRIEF.md, "The evidence split": "Every setting as this
# brief says"). It loads effects/leaf_burst.tscn and reads every setting the brief's "The
# settings" names back from the loaded nodes and resources, with the brief's values as the
# expected ones; plus what the brief's rules and CLAUDE.md ask of the scene itself: one
# Node3D root over Leaves and Puff, nothing emitting at load, no fixed seed, and no script.
# It prints one PASS or FAIL line per check and quits 1 on any failure. Run it with:
#   bash scripts/run-test.sh test_leaf_burst_config.gd 60
# A headless run draws nothing: this reads the settings, not the look (the frame strip has
# that). The hop-out's amount_ratio 0.5 is set on its copy at the event, not in the scene,
# so here it is read as 1.0. Written by Claude Code on 7 Nov 2026.

const SCENE := "res://effects/leaf_burst.tscn"
const Forest := preload("res://scripts/forest.gd")

## The brief's settings table, per emitter. Node settings first, then the process
## material's, then the mesh's.
const NODE := {
	"Leaves": {"amount": 18, "one_shot": true, "explosiveness": 0.9, "lifetime": 0.9,
		"preprocess": 0.0, "local_coords": false},
	"Puff": {"amount": 12, "one_shot": true, "explosiveness": 1.0, "lifetime": 0.35,
		"preprocess": 0.0, "local_coords": false},
}
const PROCESS := {
	"Leaves": {"lifetime_randomness": 0.2,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_SPHERE,
		"emission_sphere_radius": 0.55, "emission_shape_offset": Vector3(0, 0.5, 0),
		"direction": Vector3(0, 1, 0), "spread": 70.0,
		"initial_velocity_min": 2.0, "initial_velocity_max": 3.2,
		"gravity": Vector3(0, -3.5, 0), "damping_min": 2.0, "damping_max": 3.0,
		"angle_min": 0.0, "angle_max": 360.0, "scale_min": 1.0, "scale_max": 1.0},
	"Puff": {"lifetime_randomness": 0.0,
		"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_SPHERE,
		"emission_sphere_radius": 0.4, "emission_shape_offset": Vector3(0, 0.5, 0),
		"direction": Vector3(0, 1, 0), "spread": 180.0,
		"initial_velocity_min": 1.0, "initial_velocity_max": 2.0,
		"gravity": Vector3(0, 0, 0), "damping_min": 4.0, "damping_max": 4.0,
		"angle_min": 0.0, "angle_max": 0.0, "scale_min": 1.0, "scale_max": 1.0},
}
const MESH_SIZE := {"Leaves": Vector2(0.12, 0.08), "Puff": Vector2(0.04, 0.04)}
## Both: 3.2 x 2.2 x 3.2 m round the bush (centred on it across the ground).
const AABB_SIZE := Vector3(3.2, 2.2, 3.2)
## Leaves fade: alpha 1 until 66% of the life, then down to 0. Puff: 1 down to 0.
const FADE := {"Leaves": [[0.0, 1.0], [0.66, 1.0], [1.0, 0.0]], "Puff": [[0.0, 1.0], [1.0, 0.0]]}

var _failed := 0


func _initialize() -> void:
	print("Effect A, the leaf burst: %s" % SCENE)
	_check("the scene exists", ResourceLoader.exists(SCENE))
	var packed := load(SCENE) as PackedScene
	_check("it loads as a PackedScene", packed != null)
	if packed == null:
		_finish()
		return
	var root := packed.instantiate()
	_check("root is a Node3D (got %s)" % root.get_class(), root.get_class() == "Node3D")
	_check("root has no script (settings live in the scene)", root.get_script() == null)
	var names: Array[String] = []
	for child in root.get_children():
		names.append("%s:%s" % [child.name, child.get_class()])
	_check("children are exactly Leaves and Puff, both GPUParticles3D (got %s)" % [names],
		names == ["Leaves:GPUParticles3D", "Puff:GPUParticles3D"])
	for emitter_name: String in ["Leaves", "Puff"]:
		var p := root.get_node_or_null(emitter_name) as GPUParticles3D
		if p == null:
			_check("%s exists" % emitter_name, false)
			continue
		_check_emitter(emitter_name, p)
	root.free()
	_finish()


func _check_emitter(n: String, p: GPUParticles3D) -> void:
	print("-- %s" % n)
	# Emission (on the node).
	for key: String in NODE[n]:
		_expect(n, key, p.get(key), NODE[n][key])
	_check("%s: emitting off at load (never fires on scene load; got %s)" % [n, p.emitting], not p.emitting)
	_check("%s: amount_ratio 1.0 in the scene (the hop-out's 0.5 is set on its copy; got %s)"
		% [n, p.amount_ratio], is_equal_approx(p.amount_ratio, 1.0))
	_check("%s: no fixed seed in the effect scene (got %s)" % [n, p.use_fixed_seed], not p.use_fixed_seed)
	_check("%s: no script" % n, p.get_script() == null)
	var box := p.visibility_aabb
	_check("%s: visibility_aabb size %s (got %s)" % [n, AABB_SIZE, box.size], box.size.is_equal_approx(AABB_SIZE))
	var centre := box.get_center()
	_check("%s: visibility_aabb centred on the bush across the ground, from the ground up (got %s at %s)"
		% [n, centre, box.position], is_zero_approx(centre.x) and is_zero_approx(centre.z)
		and is_zero_approx(box.position.y))

	# Process (the ParticleProcessMaterial).
	var m := p.process_material as ParticleProcessMaterial
	_check("%s: process_material is a ParticleProcessMaterial (got %s)"
		% [n, p.process_material.get_class() if p.process_material else "null"], m != null)
	if m:
		for key: String in PROCESS[n]:
			_expect(n, key, m.get(key), PROCESS[n][key])
		_check_fade(n, m.color_ramp)
		if n == "Leaves":
			_check_leaf_colours(m.color_initial_ramp)
		else:
			_check_puff_colours(m.color_initial_ramp)

	# Draw (the mesh and its StandardMaterial3D).
	_check("%s: draw_passes 1 (got %d)" % [n, p.draw_passes], p.draw_passes == 1)
	var q := p.draw_pass_1 as QuadMesh
	_check("%s: draw_pass_1 is a QuadMesh (got %s)" % [n, p.draw_pass_1.get_class() if p.draw_pass_1 else "null"], q != null)
	if q == null:
		return
	_expect(n, "QuadMesh.size", q.size, MESH_SIZE[n])
	var d := q.material as StandardMaterial3D
	_check("%s: the quad's material is a StandardMaterial3D (got %s)"
		% [n, q.material.get_class() if q.material else "null"], d != null)
	if d == null:
		return
	_expect(n, "shading_mode (UNSHADED)", d.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED)
	_expect(n, "vertex_color_use_as_albedo (predicted failure 1)", d.vertex_color_use_as_albedo, true)
	_expect(n, "transparency (ALPHA, predicted failure 2)", d.transparency, BaseMaterial3D.TRANSPARENCY_ALPHA)
	_expect(n, "blend_mode (MIX, not additive)", d.blend_mode, BaseMaterial3D.BLEND_MODE_MIX)
	_expect(n, "billboard_mode (PARTICLES)", d.billboard_mode, BaseMaterial3D.BILLBOARD_PARTICLES)
	_check("%s: no material_override hiding the quad's material" % n, p.material_override == null)


## color_ramp, fade only: every stop white (colour and size unchanged), alpha as FADE.
func _check_fade(n: String, tex: Texture2D) -> void:
	var g := _gradient(n, "color_ramp", tex)
	if g == null:
		return
	var want: Array = FADE[n]
	_check("%s: color_ramp has %d stops (got %d)" % [n, want.size(), g.get_point_count()],
		g.get_point_count() == want.size())
	if g.get_point_count() != want.size():
		return
	for i in want.size():
		var c := g.get_color(i)
		_check("%s: color_ramp stop %d at %.2f, white, alpha %.1f (got %.2f, %s)"
			% [n, i, want[i][0], want[i][1], g.get_offset(i), c],
			is_equal_approx(g.get_offset(i), want[i][0]) and is_equal_approx(c.a, want[i][1])
			and is_equal_approx(c.r, 1.0) and is_equal_approx(c.g, 1.0) and is_equal_approx(c.b, 1.0))
	_check("%s: color_ramp interpolates linearly (a smooth fade)" % n,
		g.interpolation_mode == Gradient.GRADIENT_INTERPOLATE_LINEAR)


## Leaves' color_initial_ramp: one colour picked at random per leaf (constant
## interpolation), yellow-greens lighter than the bush and some of the forest's
## fallen-leaf oranges and browns (forest.gd, LEAVES), all opaque.
func _check_leaf_colours(tex: Texture2D) -> void:
	var g := _gradient("Leaves", "color_initial_ramp", tex)
	if g == null:
		return
	_check("Leaves: color_initial_ramp is constant, one colour per leaf, no blends",
		g.interpolation_mode == Gradient.GRADIENT_INTERPOLATE_CONSTANT)
	var greens := 0
	var browns := 0
	for i in g.get_point_count():
		var c := g.get_color(i)
		_check("Leaves: colour %d #%s opaque" % [i, c.to_html(false)], is_equal_approx(c.a, 1.0))
		if Forest.LEAVES.any(func(l: Color) -> bool: return l.is_equal_approx(c)) and c.r > c.g:
			browns += 1
		elif c.g >= c.r and c.g > c.b and c.get_luminance() > Forest.BUSH.get_luminance():
			greens += 1
		else:
			_check("Leaves: colour %d #%s is a yellow-green lighter than the bush or a fallen-leaf brown"
				% [i, c.to_html(false)], false)
	_check("Leaves: yellow-greens lighter than the bush #%s (got %d)" % [Forest.BUSH.to_html(false), greens], greens > 0)
	_check("Leaves: a few fallen-leaf oranges and browns, fewer than the greens (got %d)" % browns,
		browns > 0 and browns < greens)


## Puff's color_initial_ramp: pale tan flecks, opaque.
func _check_puff_colours(tex: Texture2D) -> void:
	var g := _gradient("Puff", "color_initial_ramp", tex)
	if g == null:
		return
	for i in g.get_point_count():
		var c := g.get_color(i)
		_check("Puff: colour %d #%s is a pale tan (r > g > b, light, opaque)" % [i, c.to_html(false)],
			c.r > c.g and c.g > c.b and c.v > 0.7 and c.s < 0.4 and is_equal_approx(c.a, 1.0))


func _gradient(n: String, what: String, tex: Texture2D) -> Gradient:
	var t := tex as GradientTexture1D
	_check("%s: %s is a GradientTexture1D (got %s)" % [n, what, tex.get_class() if tex else "null"], t != null)
	if t == null:
		return null
	_check("%s: %s has a Gradient" % [n, what], t.gradient != null)
	return t.gradient


func _expect(n: String, key: String, got: Variant, want: Variant) -> void:
	var ok: bool
	match typeof(want):
		TYPE_FLOAT:
			ok = typeof(got) in [TYPE_FLOAT, TYPE_INT] and is_equal_approx(float(got), want)
		TYPE_VECTOR2, TYPE_VECTOR3:
			ok = typeof(got) == typeof(want) and got.is_equal_approx(want)
		_:
			ok = typeof(got) == typeof(want) and got == want
	_check("%s: %s = %s (got %s)" % [n, key, want, got], ok)


func _check(what: String, ok: bool) -> void:
	if not ok:
		_failed += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", what])


func _finish() -> void:
	print("%s: %d check(s) failed" % ["FAIL" if _failed else "PASS", _failed])
	quit(1 if _failed else 0)
