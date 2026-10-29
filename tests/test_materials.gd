extends SceneTree
# The material audit's test (MATERIALS.md), as CHANGE-BRIEF.md's material plan and evidence
# split ask. It pins what the audit found, headlessly:
# - both cooler materials use the one shader, with the uniform values and textures the brief's
#   "two materials" table gives;
# - each shader's uniforms (get_shader_uniform_list()), and each uniform's hints, group and
#   default, read from the shader's source text, since a headless run doesn't report them;
# - each bound texture's import settings, read from its .import file with ConfigFile, and the
#   format it imports as (get_image().get_format(), added in Claude Code's review);
# - the scenes: the cooler's surfaces in the asset room, the asset room's light and
#   environment, and the hint experiment's quad and environment;
# - each bound normal map's curl ratio under both conventions (tests/normal_map_check.gd), and
#   the brief's threshold, below 0.7 with directx = false.
# It prints one PASS or FAIL line per check, and INFO lines for measured numbers it doesn't
# assert, and quits 1 on any failure. Run it with:
#   bash scripts/run-test.sh test_materials.gd 60
# Nothing here renders: how anything looks is checked by eye. Written by Claude Code on
# 29 Oct 2026.

const NormalMapCheck := preload("res://tests/normal_map_check.gd")

const COOLER_SHADER := "res://shaders/cooler_paint.gdshader"
const HINT_SHADER := "res://shaders/hint_experiment.gdshader"
const TEX := "res://assets/textures/blue_metal_plate/blue_metal_plate_%s_1k.png"
const DIFF := TEX % "diff"
const ROUGH := TEX % "rough"
const NOR_GL := TEX % "nor_gl"
const NOR_DX := TEX % "nor_dx"
const GREYS := "res://hint_experiment/greys_3x1.png"
const BODY := "res://materials/cooler_body.tres"
const LID := "res://materials/cooler_lid.tres"
const SPLIT := "res://hint_experiment/split_quad.tres"
const ASSET_ROOM := "res://asset_room/asset_room.tscn"
const HINT_SCENE := "res://hint_experiment/hint_experiment.tscn"
const COOLER_GLB := "res://assets/props/cooler.glb"

## The brief's threshold for a normal map (CHANGE-BRIEF.md, "the normal-map check, calibrated,
## and its threshold").
const CURL_MAX := 0.7

## Each uniform as the brief's tables give it: [type, hints as written, default, group].
## Sampler defaults are "" (they have none).
const COOLER_UNIFORMS := {
	"tint": ["vec4", "source_color", "vec4(1.0)", "colour"],
	"detail": ["float", "hint_range(0.0, 1.0)", "0.5", "colour"],
	"uv_scale": ["float", "hint_range(0.25, 4.0)", "1.0", "colour"],
	"albedo_texture": ["sampler2D", "source_color, filter_linear_mipmap, repeat_enable", "", "colour"],
	"roughness_scale": ["float", "hint_range(0.0, 1.0)", "1.0", "surface"],
	"normal_strength": ["float", "hint_range(0.0, 2.0)", "1.0", "surface"],
	"roughness_texture": ["sampler2D", "hint_default_white, filter_linear_mipmap, repeat_enable", "", "surface"],
	"normal_texture": ["sampler2D", "hint_normal, filter_linear_mipmap, repeat_enable", "", "surface"],
}
const HINT_UNIFORMS := {
	"with_source_color": ["sampler2D", "source_color, filter_nearest", "", ""],
	"without_source_color": ["sampler2D", "filter_nearest", "", ""],
}

## The brief's "two materials" table (tint as sRGB hex), and the textures both bind.
const MATERIALS := {
	BODY: {"tint": "3b7dbf", "detail": 0.6, "roughness_scale": 1.0, "normal_strength": 1.0, "uv_scale": 1.0},
	LID: {"tint": "f2f2ee", "detail": 0.25, "roughness_scale": 0.6, "normal_strength": 0.5, "uv_scale": 1.0},
}
const COOLER_BINDINGS := {"albedo_texture": DIFF, "roughness_texture": ROUGH, "normal_texture": NOR_GL}
const SPLIT_BINDINGS := {"with_source_color": GREYS, "without_source_color": GREYS}

## Import settings: [compress/mode, compress/normal_map, mipmaps/generate, roughness/mode].
## compress/mode 0 Lossless, 2 VRAM Compressed; normal_map 0 Detect, 1 Enable, 2 Disabled; roughness/mode 1 Disabled
## (Godot 4.7.2's own option strings, looked up in Claude Code's review).
const IMPORTS := {
	DIFF: [2, 2, true, 1],
	ROUGH: [2, 2, true, 1],
	NOR_GL: [2, 1, true, 1],
	GREYS: [0, 2, false, 1],
}

## What each imported texture reads back as, headless: [Image format, has mipmaps].
## Added in Claude Code's review, which measured them (MATERIALS.md, "Review").
const FORMATS := {
	DIFF: [Image.FORMAT_DXT1, true],
	ROUGH: [Image.FORMAT_DXT1, true],
	NOR_GL: [Image.FORMAT_RGTC_RG, true],
	GREYS: [Image.FORMAT_RGB8, false],
}

var _failed := 0


func _initialize() -> void:
	print("Material audit test, %s" % Time.get_datetime_string_from_system())
	_check_shader_source(COOLER_SHADER, COOLER_UNIFORMS)
	_check_shader_source(HINT_SHADER, HINT_UNIFORMS)
	_check_uniform_list(COOLER_SHADER, COOLER_UNIFORMS)
	_check_uniform_list(HINT_SHADER, HINT_UNIFORMS)
	_check_cooler_materials()
	_check_split_material()
	_check_imports()
	_check_formats()
	_check_cooler_surfaces()
	_check_asset_room()
	_check_hint_scene()
	_check_normal_maps()
	_measure_diffuse()
	print("%s: %d check(s) failed" % ["FAIL" if _failed else "PASS", _failed])
	quit(1 if _failed else 0)


func _check(ok: bool, what: String) -> void:
	print("%s  %s" % ["PASS" if ok else "FAIL", what])
	if not ok:
		_failed += 1


# --- Shaders -----------------------------------------------------------------

## Every `uniform` line in the source, as {name: [type, hints, default, group]}.
func _parse_uniforms(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var line_re := RegEx.create_from_string(
		"^\\s*uniform\\s+(\\w+)\\s+(\\w+)\\s*(?::\\s*([^=;]*?))?\\s*(?:=\\s*([^;]*?))?\\s*;")
	var group_re := RegEx.create_from_string("^\\s*group_uniforms\\s*(\\w*)\\s*;")
	var group := ""
	var out := {}
	for line in text.split("\n"):
		var g := group_re.search(line)
		if g:
			group = g.get_string(1)
			continue
		var m := line_re.search(line)
		if m:
			out[m.get_string(2)] = [m.get_string(1), m.get_string(3), m.get_string(4), group]
	return out


func _check_shader_source(path: String, expected: Dictionary) -> void:
	var found := _parse_uniforms(path)
	_check(found.keys().size() == expected.keys().size(),
		"%s declares %d uniforms (%s)" % [path.get_file(), expected.size(), ", ".join(found.keys())])
	for name: String in expected:
		var want: Array = expected[name]
		var got: Array = found.get(name, ["", "", "", ""])
		_check(got[0] == want[0], "%s: %s is %s (source: %s)" % [path.get_file(), name, want[0], got[0]])
		_check(got[1] == want[1], "%s: %s hints are \"%s\" (source: \"%s\")" % [path.get_file(), name, want[1], got[1]])
		if want[0] != "sampler2D":
			_check(got[2] == want[2], "%s: %s defaults to %s (source: %s)" % [path.get_file(), name, want[2], got[2]])
		_check(got[3] == want[3], "%s: %s is in group \"%s\" (source: \"%s\")" % [path.get_file(), name, want[3], got[3]])
		# Failure 8 in the brief: a data texture decoded as if it were sRGB.
		if want[0] == "sampler2D" and (name.begins_with("roughness") or name.begins_with("normal")):
			_check(not "source_color" in str(got[1]), "%s: %s, a data texture, has no source_color" % [path.get_file(), name])


func _check_uniform_list(path: String, expected: Dictionary) -> void:
	var shader := load(path) as Shader
	_check(shader != null, "%s loads as a Shader" % path)
	if shader == null:
		return
	var types := {"vec4": [TYPE_COLOR, TYPE_VECTOR4], "float": [TYPE_FLOAT], "sampler2D": [TYPE_OBJECT]}
	var listed := {}
	for u: Dictionary in shader.get_shader_uniform_list():
		listed[u.name] = u
	print("INFO  %s get_shader_uniform_list(): %s" % [path.get_file(),
		", ".join(listed.keys().map(func(n): return "%s %s %s" % [n, type_string(listed[n].type), listed[n].hint_string]))])
	_check(listed.size() == expected.size(), "%s: get_shader_uniform_list() has %d uniforms (has %d)" % [
		path.get_file(), expected.size(), listed.size()])
	for name: String in expected:
		var ok: bool = listed.has(name) and listed[name].type in types[expected[name][0]]
		_check(ok, "%s: get_shader_uniform_list() has %s as %s" % [path.get_file(), name, expected[name][0]])


# --- Materials ---------------------------------------------------------------

func _texture_path(mat: ShaderMaterial, name: String) -> String:
	var tex = mat.get_shader_parameter(name)
	return tex.resource_path if tex is Texture2D else "<none>"


func _check_cooler_materials() -> void:
	var shaders := []
	for path: String in MATERIALS:
		var mat := load(path) as ShaderMaterial
		_check(mat != null, "%s loads as a ShaderMaterial" % path)
		if mat == null:
			continue
		var shader_path := mat.shader.resource_path if mat.shader else "<none>"
		shaders.append(shader_path)
		_check(shader_path == COOLER_SHADER, "%s uses %s (uses %s)" % [path.get_file(), COOLER_SHADER, shader_path])
		var want: Dictionary = MATERIALS[path]
		for name: String in want:
			var got = mat.get_shader_parameter(name)
			if name == "tint":
				var c := Color(want[name])
				var ok: bool = got is Color and (got as Color).is_equal_approx(c)
				_check(ok, "%s: tint is #%s (is %s)" % [path.get_file(), want[name], (got as Color).to_html(false) if got is Color else str(got)])
			else:
				_check(got != null and is_equal_approx(float(got), want[name]),
					"%s: %s is %s (is %s)" % [path.get_file(), name, want[name], got])
		for name: String in COOLER_BINDINGS:
			var got := _texture_path(mat, name)
			_check(got == COOLER_BINDINGS[name], "%s: %s binds %s (binds %s)" % [path.get_file(), name, COOLER_BINDINGS[name].get_file(), got])
		_check(mat.render_priority == 0 and mat.next_pass == null, "%s: render_priority 0, no next pass" % path.get_file())
	_check(shaders.size() == 2 and shaders[0] == shaders[1], "both cooler materials reference the same shader path")
	var body := load(BODY) as ShaderMaterial
	var lid := load(LID) as ShaderMaterial
	_check(body != lid, "the body and the lid are two separate material resources")


func _check_split_material() -> void:
	var mat := load(SPLIT) as ShaderMaterial
	_check(mat != null, "%s loads as a ShaderMaterial" % SPLIT)
	if mat == null:
		return
	var shader_path := mat.shader.resource_path if mat.shader else "<none>"
	_check(shader_path == HINT_SHADER, "%s uses %s (uses %s)" % [SPLIT.get_file(), HINT_SHADER, shader_path])
	for name: String in SPLIT_BINDINGS:
		var got := _texture_path(mat, name)
		_check(got == SPLIT_BINDINGS[name], "%s: %s binds %s (binds %s)" % [SPLIT.get_file(), name, SPLIT_BINDINGS[name].get_file(), got])
	var img := Image.load_from_file(ProjectSettings.globalize_path(GREYS))
	var ok := img != null and img.get_width() == 3 and img.get_height() == 1
	var greys := []
	if ok:
		for x in 3:
			greys.append(img.get_pixel(x, 0).r8)
	_check(ok and greys == [64, 128, 192], "greys_3x1.png is 3 x 1 with greys 64, 128, 192 (has %s)" % [greys])


# --- Imports -----------------------------------------------------------------

func _check_imports() -> void:
	for path: String in IMPORTS:
		var cfg := ConfigFile.new()
		var err := cfg.load(path + ".import")
		_check(err == OK, "%s.import reads with ConfigFile" % path.get_file())
		if err != OK:
			continue
		var want: Array = IMPORTS[path]
		var got := [cfg.get_value("params", "compress/mode", -1), cfg.get_value("params", "compress/normal_map", -1),
			cfg.get_value("params", "mipmaps/generate", null), cfg.get_value("params", "roughness/mode", -1)]
		_check(cfg.get_value("remap", "importer", "") == "texture", "%s: importer is texture" % path.get_file())
		_check(got[0] == want[0], "%s: compress/mode = %d (is %s)" % [path.get_file(), want[0], got[0]])
		_check(got[1] == want[1], "%s: compress/normal_map = %d (is %s)" % [path.get_file(), want[1], got[1]])
		_check(got[2] == want[2], "%s: mipmaps/generate = %s (is %s)" % [path.get_file(), want[2], got[2]])
		_check(got[3] == want[3], "%s: roughness/mode = %d, Disabled (is %s)" % [path.get_file(), want[3], got[3]])
		_check(cfg.get_value("params", "process/normal_map_invert_y", true) == false,
			"%s: process/normal_map_invert_y = false" % path.get_file())
	var dx := ConfigFile.new()
	_check(dx.load(NOR_DX + ".import") == OK and dx.get_value("remap", "importer", "") == "skip",
		"%s.import: importer is skip, so the game never loads it" % NOR_DX.get_file())
	var glb := ConfigFile.new()
	_check(glb.load(COOLER_GLB + ".import") == OK, "cooler.glb.import reads with ConfigFile")
	_check(glb.get_value("params", "meshes/ensure_tangents", false) == true, "cooler.glb.import: meshes/ensure_tangents = true")
	var mats: Dictionary = glb.get_value("params", "_subresources", {}).get("materials", {})
	for pair: Array in [["Cooler_Blue", BODY], ["Cooler_White", LID]]:
		var m: Dictionary = mats.get(pair[0], {})
		_check(m.get("use_external/enabled", false) == true and m.get("use_external/path", "") == pair[1]
			and m.get("use_external/fallback_path", "") == pair[1],
			"cooler.glb.import: %s is Use External, %s" % [pair[0], pair[1]])
	_check(not mats.has("Cooler_Grey"), "cooler.glb.import: Cooler_Grey stays embedded")


## The imported textures' formats, from get_image().get_format(), as MATERIALS.md says.
func _check_formats() -> void:
	for path: String in FORMATS:
		var tex := load(path) as Texture2D
		var img: Image = tex.get_image() if tex else null
		var want: Array = FORMATS[path]
		var ok: bool = img != null and img.get_format() == want[0] and img.has_mipmaps() == want[1]
		_check(ok, "%s imports as format %d, mipmaps %s (is %s, %s)" % [path.get_file(), want[0], want[1],
			str(img.get_format()) if img else "none", str(img.has_mipmaps()) if img else "-"])


# --- Scenes ------------------------------------------------------------------

## The surface materials of every mesh under `root`, as {material name or path: count}.
func _surface_materials(root: Node) -> Dictionary:
	var out := {}
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		for s in mi.mesh.get_surface_count():
			var m := mi.get_active_material(s)
			var key := "<none>"
			if m:
				key = m.resource_path if m.resource_path and not "::" in m.resource_path else "embedded " + m.resource_name
			out[key] = out.get(key, 0) + 1
	return out


func _check_cooler_surfaces() -> void:
	var cooler := (load(COOLER_GLB) as PackedScene).instantiate()
	var mats := _surface_materials(cooler)
	print("INFO  cooler.glb surfaces: %s" % mats)
	_check(mats.has(BODY), "cooler.glb: a surface draws with %s" % BODY.get_file())
	_check(mats.has(LID), "cooler.glb: a surface draws with %s" % LID.get_file())
	_check(mats.has("embedded Cooler_Grey"), "cooler.glb: the handle and posts keep the embedded Cooler_Grey")
	cooler.free()


func _check_asset_room() -> void:
	var room := (load(ASSET_ROOM) as PackedScene).instantiate()
	var cooler := room.get_node_or_null("Cooler")
	_check(cooler != null, "asset_room.tscn has the node Cooler")
	if cooler:
		var mats := _surface_materials(cooler)
		_check(mats.has(BODY) and mats.has(LID), "asset_room.tscn: Cooler draws with both cooler materials")
		var overrides := 0
		for mi: MeshInstance3D in cooler.find_children("*", "MeshInstance3D", true, false):
			if mi.material_override:
				overrides += 1
			for s in mi.get_surface_override_material_count():
				if mi.get_surface_override_material(s):
					overrides += 1
		_check(overrides == 0, "asset_room.tscn: no override on the Cooler's surfaces")
	var sun := room.get_node_or_null("Sun") as DirectionalLight3D
	_check(sun != null and is_equal_approx(sun.light_energy, 0.8), "asset_room.tscn: Sun light_energy 0.8")
	if sun:
		print("INFO  asset room Sun: colour #%s, energy %.2f, rotation %s deg, shadows %s" % [
			sun.light_color.to_html(false), sun.light_energy, sun.rotation_degrees.snapped(Vector3.ONE * 0.1), sun.shadow_enabled])
	var env := (room.get_node("WorldEnvironment") as WorldEnvironment).environment
	_check(is_equal_approx(env.ambient_light_energy, 0.8), "asset_room.tscn: ambient_light_energy 0.8")
	_check(env.tonemap_mode == Environment.TONE_MAPPER_LINEAR and is_equal_approx(env.tonemap_exposure, 1.0),
		"asset_room.tscn: tonemap Linear, exposure 1.0 (defaults; the scene doesn't set them)")
	print("INFO  asset room environment: ambient #%s x %.2f (source %d), SSAO %s, fog %s (depth %.0f to %.0f m), glow %s" % [
		env.ambient_light_color.to_html(false), env.ambient_light_energy, env.ambient_light_source,
		env.ssao_enabled, env.fog_enabled, env.fog_depth_begin, env.fog_depth_end, env.glow_enabled])
	# Pinned as found: the brief judges with SSAO off, but the scene has it on (MATERIALS.md, findings).
	_check(env.ssao_enabled, "asset_room.tscn: ssao_enabled is true as committed (switched off only by hand to judge)")
	room.free()


func _check_hint_scene() -> void:
	var scene := (load(HINT_SCENE) as PackedScene).instantiate()
	var quad := scene.get_node_or_null("Greys") as MeshInstance3D
	var path := quad.material_override.resource_path if quad and quad.material_override else "<none>"
	_check(path == SPLIT, "hint_experiment.tscn: Greys draws with %s (with %s)" % [SPLIT.get_file(), path])
	var count := 0
	for mi: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
		count += 1
	_check(count == 1, "hint_experiment.tscn: one quad (has %d)" % count)
	var env := (scene.get_node("WorldEnvironment") as WorldEnvironment).environment
	_check(env.tonemap_mode == Environment.TONE_MAPPER_LINEAR and is_equal_approx(env.tonemap_exposure, 1.0),
		"hint_experiment.tscn: tonemap Linear, exposure 1.0")
	_check(not env.glow_enabled and not env.fog_enabled and not env.adjustment_enabled,
		"hint_experiment.tscn: no glow, fog or adjustments")
	var lights := scene.find_children("*", "Light3D", true, false).size()
	print("INFO  hint experiment: %d light(s); the shader is unshaded" % lights)
	scene.free()


# --- Textures ----------------------------------------------------------------

func _check_normal_maps() -> void:
	# Every normal map a material binds (normal_texture in either cooler material).
	var maps := {}
	for path: String in MATERIALS:
		var mat := load(path) as ShaderMaterial
		if mat:
			maps[_texture_path(mat, "normal_texture")] = true
	for path: String in maps:
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		_check(img != null and not img.is_empty(), "%s decodes from the source file" % path.get_file())
		if img == null or img.is_empty():
			continue
		var gl := NormalMapCheck.curl_ratio(img, false)
		var dx := NormalMapCheck.curl_ratio(img, true)
		print("INFO  %s curl_ratio: directx = false %.3f, directx = true %.3f" % [path.get_file(), gl, dx])
		_check(gl < CURL_MAX, "%s: curl_ratio %.3f < %.1f with directx = false (Godot's convention)" % [path.get_file(), gl, CURL_MAX])


## Measures the diffuse against the shader's DIFFUSE_MEAN_LUMINANCE, and how far the colour line
## takes ALBEDO for each material. Asserts only the mean.
func _measure_diffuse() -> void:
	var text := FileAccess.get_file_as_string(COOLER_SHADER)
	var m := RegEx.create_from_string("DIFFUSE_MEAN_LUMINANCE\\s*=\\s*([0-9.]+)").search(text)
	var mean_const := float(m.get_string(1)) if m else -1.0
	var img := Image.load_from_file(ProjectSettings.globalize_path(DIFF))
	if img == null or img.is_empty():
		_check(false, "%s decodes from the source file" % DIFF.get_file())
		return
	var total := 0.0
	var top := 0.0
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y).srgb_to_linear()
			var l := c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
			total += l
			top = maxf(top, l)
			n += 1
	var mean := total / n
	print("INFO  %s: linear mean luminance %.4f, max %.4f (max / constant %.1f)" % [DIFF.get_file(), mean, top, top / mean_const])
	_check(absf(mean - mean_const) <= 0.02 * mean_const,
		"cooler_paint.gdshader: DIFFUSE_MEAN_LUMINANCE %.4f is the diffuse's linear mean within 2%% (%.4f)" % [mean_const, mean])
	for path: String in MATERIALS:
		var want: Dictionary = MATERIALS[path]
		var tint := Color(want.tint).srgb_to_linear()
		var k := lerpf(1.0, top / mean_const, want.detail)
		print("INFO  %s: brightest texel gives ALBEDO (%.2f, %.2f, %.2f) in linear" % [path.get_file(), tint.r * k, tint.g * k, tint.b * k])
