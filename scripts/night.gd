extends RefCounted
## The game's night, shared by the title screen (title_screen.gd) and the level
## (main.gd): the sky, a cool ambient light, the moon from the upper right, and the
## haze the far woods fade into. The forest's own night colours are in forest.gd
## (NIGHT). All of it was measured against the author's title picture,
## design/reference/title-screen.webp; on 21 Oct 2026 the author asked for the game
## itself to be at night too.

const SKY := Color("171a3b")
const AMBIENT := Color("6f78b0")
const AMBIENT_ENERGY := 0.28
const MOON := Color("aab4ff")
const MOON_ENERGY := 1.8
const MOON_ANGLES := Vector3(-38, 72, 0)
const HAZE := Color("26343f")
## The raccoon is bluer in the picture's moonlight than the moon alone makes him: his
## colours are multiplied by this, in linear light.
const RACCOON_TINT := Color(0.89, 0.89, 1.22)
## The generated stump in the level is a flat, unlit picture; this dims it to the night,
## in linear light, about as much as the moon and the night colours dim the trunks.
const PICTURE_TINT := Color(0.24, 0.3, 0.62)


## The moonlight, with soft shadows out to `shadow_distance` metres.
static func moon(shadow_distance: float) -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = MOON_ANGLES
	light.light_color = MOON
	light.light_energy = MOON_ENERGY
	light.shadow_enabled = true
	light.shadow_blur = 2.0
	light.shadow_opacity = 0.7
	light.directional_shadow_max_distance = shadow_distance
	return light


## Lights `env` for the night: the ambient light and the haze's colour.
static func light(env: Environment) -> void:
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = AMBIENT
	env.ambient_light_energy = AMBIENT_ENERGY
	env.fog_light_color = HAZE


## `c` multiplied by `gain` in linear light.
static func times(c: Color, gain: Color) -> Color:
	var l := c.srgb_to_linear()
	return Color(minf(l.r * gain.r, 1.0), minf(l.g * gain.g, 1.0), minf(l.b * gain.b, 1.0), c.a).linear_to_srgb()


## Turns the raccoon's colours bluer for the moonlight (RACCOON_TINT). His materials
## are his own, made for each model (raccoon_model.gd), so no other raccoon changes.
static func tint_raccoon(model: Node3D) -> void:
	var done := {}
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for i in mi.get_surface_override_material_count():
			var mat := mi.get_surface_override_material(i) as BaseMaterial3D
			if mat and not done.has(mat):
				done[mat] = true
				mat.albedo_color = times(mat.albedo_color, RACCOON_TINT)
