shader_type spatial;
// The campfire's flames (campsite.gd): unlit, in their vertex colours, bright enough
// to glow (the level's glow starts at 1.0).
render_mode unshaded, cull_disabled, shadows_disabled;

uniform float energy = 2.4;

void fragment() {
	// The vertex colours are sRGB; the level renders in linear light.
	ALBEDO = pow(COLOR.rgb, vec3(2.2)) * energy;
}
