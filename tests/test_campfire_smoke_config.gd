extends SceneTree
# Effect B's configuration test (CHANGE-BRIEF.md, revised 8 Nov 2026, "Effect B, the campfire
# smoke", "The evidence split": "Every setting as this brief says, the feature included").
# It loads effects/campfire_smoke.tscn and reads every setting the brief's "The settings"
# names back from the loaded node and resources, with the brief's values as the expected
# ones; the features Effect A doesn't use included: turbulence, the scale curve, the box
# emission shape, preprocess and the soft round texture (the value-driven amount_ratio is
# the state test's: here it is read as 1.0, since the feedback sets it at run time).
# Before reading a property it asks ClassDB whether this build has it, so a name the class
# doesn't have fails as such instead of reading back null. It also checks what the brief
# and CLAUDE.md ask of the scene itself: one Node3D root over Smoke, continuous, no fixed
# seed, no script. One PASS or FAIL line per check; quits 1 on any failure. Run it with:
#   bash scripts/run-test.sh test_campfire_smoke_config.gd 60
# A headless run draws nothing: this reads the settings, not the look (the frame strip has
# that). Written by Claude Code on 8 Nov 2026.

const SCENE := "res://effects/campfire_smoke.tscn"

## The brief's settings table. Emission (on the node) first, then process (the material).
const NODE := {"amount": 40, "one_shot": false, "explosiveness": 0.0, "lifetime": 3.5,
	"preprocess": 3.5, "local_coords": false}
const PROCESS := {"lifetime_randomness": 0.2,
	"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
	"emission_box_extents": Vector3(0.25, 0.05, 0.25), "emission_shape_offset": Vector3(0, 0.35, 0),
	"direction": Vector3(0, 1, 0), "spread": 12.0,
	"initial_velocity_min": 0.35, "initial_velocity_max": 0.6,
	"gravity": Vector3(0, 0.12, 0), "damping_min": 0.1, "damping_max": 0.2,
	"turbulence_enabled": true, "turbulence_noise_strength": 0.6, "turbulence_noise_scale": 2.0,
	"angle_min": 0.0, "angle_max": 360.0, "scale_min": 0.8, "scale_max": 1.2}
const MESH_SIZE := Vector2(0.5, 0.5)
## 3 x 4 x 3 m round the pit, from the ground up.
const AABB_SIZE := Vector3(3, 4, 3)
## scale_curve: 0.4 -> 1.6 over the life.
const SCALE_FROM := 0.4
const SCALE_TO := 1.6
## color_ramp: alpha 0 -> 0.45 at 15% -> 0; warm grey -> blue-grey.
const ALPHA := [[0.0, 0.0], [0.15, 0.45], [1.0, 0.0]]
const WARM := Color("9b938a")
const COOL := Color("6f7a85")

var _failed := 0


func _initialize() -> void:
	print("Effect B, the campfire smoke: %s" % SCENE)
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
	_check("children are exactly Smoke, a GPUParticles3D (got %s)" % [names], names == ["Smoke:GPUParticles3D"])
	var p := root.get_node_or_null("Smoke") as GPUParticles3D
	if p:
		_check_emitter(p)
	root.free()
	_finish()


func _check_emitter(p: GPUParticles3D) -> void:
	print("-- Emission (the GPUParticles3D node)")
	for key: String in NODE:
		_expect_prop(p, "GPUParticles3D", key, NODE[key])
	_check("continuous: emitting on in the scene (got %s)" % p.emitting, p.emitting)
	_check("preprocess %.1f s = lifetime: a burning fire has its column on the first frame (failure 7)"
		% p.preprocess, p.preprocess > 0.0 and is_equal_approx(p.preprocess, p.lifetime))
	_check("amount_ratio 1.0 in the scene (the feedback sets it to strength at run time; got %s)"
		% p.amount_ratio, is_equal_approx(p.amount_ratio, 1.0))
	_check("no fixed seed in the effect scene (got %s)" % p.use_fixed_seed, not p.use_fixed_seed)
	_check("Smoke has no script", p.get_script() == null)
	var box := p.visibility_aabb
	_check("visibility_aabb size %s (got %s)" % [AABB_SIZE, box.size], box.size.is_equal_approx(AABB_SIZE))
	var centre := box.get_center()
	_check("visibility_aabb centred on the pit across the ground, from the ground up (got %s at %s)"
		% [centre, box.position], is_zero_approx(centre.x) and is_zero_approx(centre.z)
		and is_zero_approx(box.position.y))

	print("-- Process (the ParticleProcessMaterial)")
	var m := p.process_material as ParticleProcessMaterial
	_check("process_material is a ParticleProcessMaterial (got %s)"
		% [p.process_material.get_class() if p.process_material else "null"], m != null)
	if m:
		for key: String in PROCESS:
			_expect_prop(m, "ParticleProcessMaterial", key, PROCESS[key])
		_check_scale_curve(m)
		_check_color_ramp(m)
		_check("no color_initial_ramp (the brief names none; got %s)" % m.color_initial_ramp,
			m.color_initial_ramp == null)

	print("-- Draw (the quad and its StandardMaterial3D)")
	_check("draw_passes 1 (got %d)" % p.draw_passes, p.draw_passes == 1)
	var q := p.draw_pass_1 as QuadMesh
	_check("draw_pass_1 is a QuadMesh (got %s)" % [p.draw_pass_1.get_class() if p.draw_pass_1 else "null"], q != null)
	if q == null:
		return
	_expect("QuadMesh.size", q.size, MESH_SIZE)
	var d := q.material as StandardMaterial3D
	_check("the quad's material is a StandardMaterial3D (got %s)"
		% [q.material.get_class() if q.material else "null"], d != null)
	_check("no material_override hiding the quad's material", p.material_override == null)
	if d == null:
		return
	_expect("shading_mode (UNSHADED)", d.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED)
	_expect("vertex_color_use_as_albedo (the ramp shows)", d.vertex_color_use_as_albedo, true)
	_expect("transparency (ALPHA, the fade shows)", d.transparency, BaseMaterial3D.TRANSPARENCY_ALPHA)
	_expect("blend_mode (MIX, not additive)", d.blend_mode, BaseMaterial3D.BLEND_MODE_MIX)
	_expect("billboard_mode (PARTICLES)", d.billboard_mode, BaseMaterial3D.BILLBOARD_PARTICLES)
	_check_disc(d.albedo_texture)


## scale_curve: a CurveTexture whose curve runs 0.4 -> 1.6, straight, not clamped by the
## Curve's value range.
func _check_scale_curve(m: ParticleProcessMaterial) -> void:
	_check("ParticleProcessMaterial has scale_curve on this build", _has("ParticleProcessMaterial", "scale_curve"))
	var t := m.scale_curve as CurveTexture
	_check("scale_curve is a CurveTexture (got %s)" % [m.scale_curve.get_class() if m.scale_curve else "null"], t != null)
	if t == null or t.curve == null:
		_check("scale_curve has a Curve", false)
		return
	var c := t.curve
	_check("scale_curve has 2 points (got %d)" % c.point_count, c.point_count == 2)
	var a := c.sample(0.0)
	var mid := c.sample(0.5)
	var b := c.sample(1.0)
	_check("scale_curve starts at %.1f (got %.3f)" % [SCALE_FROM, a], is_equal_approx(a, SCALE_FROM))
	_check("scale_curve ends at %.1f, not clamped to the Curve's range (got %.3f, range %s..%s)"
		% [SCALE_TO, b, c.min_value, c.max_value], is_equal_approx(b, SCALE_TO))
	_check("scale_curve grows evenly: %.1f at half its life (got %.3f)" % [(SCALE_FROM + SCALE_TO) / 2.0, mid],
		absf(mid - (SCALE_FROM + SCALE_TO) / 2.0) < 0.01)


## color_ramp: alpha 0 -> 0.45 at 15% -> 0, linear; warm grey at the start, blue-grey at
## the end, and in between at 15%.
func _check_color_ramp(m: ParticleProcessMaterial) -> void:
	var t := m.color_ramp as GradientTexture1D
	_check("color_ramp is a GradientTexture1D (got %s)" % [m.color_ramp.get_class() if m.color_ramp else "null"], t != null)
	if t == null or t.gradient == null:
		_check("color_ramp has a Gradient", false)
		return
	var g := t.gradient
	_check("color_ramp has %d stops (got %d)" % [ALPHA.size(), g.get_point_count()], g.get_point_count() == ALPHA.size())
	_check("color_ramp interpolates linearly", g.interpolation_mode == Gradient.GRADIENT_INTERPOLATE_LINEAR)
	if g.get_point_count() != ALPHA.size():
		return
	for i in ALPHA.size():
		_check("color_ramp stop %d at %.2f, alpha %.2f (got %.2f, alpha %.3f)"
			% [i, ALPHA[i][0], ALPHA[i][1], g.get_offset(i), g.get_color(i).a],
			is_equal_approx(g.get_offset(i), ALPHA[i][0]) and absf(g.get_color(i).a - ALPHA[i][1]) < 0.002)
	var first := g.get_color(0)
	var last := g.get_color(ALPHA.size() - 1)
	_check("color_ramp starts warm grey #%s (got #%s)" % [WARM.to_html(false), first.to_html(false)],
		_same_rgb(first, WARM))
	_check("color_ramp ends blue-grey #%s (got #%s)" % [COOL.to_html(false), last.to_html(false)],
		_same_rgb(last, COOL))
	var at15 := g.get_color(1)
	_check("color_ramp at 15%% is warm grey to blue-grey at 0.15 (got #%s)" % at15.to_html(false),
		_same_rgb(at15, WARM.lerp(COOL, 0.15)))
	var peak := 0.0
	for i in 101:
		peak = maxf(peak, g.sample(i / 100.0).a)
	_check("alpha never above 0.45 (got %.3f)" % peak, peak <= 0.45 + 0.002)


## The soft disc (failure 6): a radial GradientTexture2D, opaque white at the centre and
## clear at the edge, written in the scene (no image file).
func _check_disc(tex: Texture2D) -> void:
	_check("albedo_texture is set (failure 6: a null texture draws hard squares)", tex != null)
	var t := tex as GradientTexture2D
	_check("albedo_texture is a GradientTexture2D (got %s)" % [tex.get_class() if tex else "null"], t != null)
	if t == null:
		return
	_check("albedo_texture is written in the scene, not an image file (path %s)" % [t.resource_path],
		t.resource_path == "" or t.resource_path.contains("::"))
	_expect("GradientTexture2D.fill (RADIAL)", t.fill, GradientTexture2D.FILL_RADIAL)
	_check("the disc is centred: fill_from (0.5, 0.5) (got %s)" % t.fill_from, t.fill_from.is_equal_approx(Vector2(0.5, 0.5)))
	_check("the disc reaches the quad's edge: fill_from to fill_to is 0.5 (got %.2f)"
		% t.fill_from.distance_to(t.fill_to), is_equal_approx(t.fill_from.distance_to(t.fill_to), 0.5))
	if t.gradient == null:
		_check("albedo_texture has a Gradient", false)
		return
	var centre := t.gradient.sample(0.0)
	var edge := t.gradient.sample(1.0)
	_check("the disc is white and opaque at the centre (got %s)" % centre, centre.is_equal_approx(Color(1, 1, 1, 1)))
	_check("the disc is clear at the edge (got alpha %.2f)" % edge.a, is_zero_approx(edge.a))
	_check("the disc is soft: half clear halfway (got alpha %.2f)" % t.gradient.sample(0.5).a,
		absf(t.gradient.sample(0.5).a - 0.5) < 0.05)


func _same_rgb(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.003 and absf(a.g - b.g) < 0.003 and absf(a.b - b.b) < 0.003


## Asks ClassDB whether this build has the property, then reads it back.
func _expect_prop(o: Object, cls: String, key: String, want: Variant) -> void:
	if not _has(cls, key):
		_check("%s has %s on this build" % [cls, key], false)
		return
	_expect(key, o.get(key), want)


## True if ClassDB lists the property on the class (or a class it inherits) on this build.
func _has(cls: String, key: String) -> bool:
	return ClassDB.class_get_property_list(cls).any(func(p: Dictionary) -> bool: return p.name == key)


func _expect(key: String, got: Variant, want: Variant) -> void:
	var ok: bool
	match typeof(want):
		TYPE_FLOAT:
			ok = typeof(got) in [TYPE_FLOAT, TYPE_INT] and is_equal_approx(float(got), want)
		TYPE_VECTOR2, TYPE_VECTOR3:
			ok = typeof(got) == typeof(want) and got.is_equal_approx(want)
		_:
			ok = typeof(got) == typeof(want) and got == want
	_check("%s = %s (got %s)" % [key, want, got], ok)


func _check(what: String, ok: bool) -> void:
	if not ok:
		_failed += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", what])


func _finish() -> void:
	print("%s: %d check(s) failed" % ["FAIL" if _failed else "PASS", _failed])
	quit(1 if _failed else 0)
