shader_type spatial;
render_mode diffuse_burley, specular_disabled;
// Material for the trees, bushes and cabin: the same flat vertex colours as
// LowPoly.material(), plus a dithered window wherever scenery stands between the
// camera and the raccoon, so he never gets lost behind a tree. main.gd sets the
// uniforms every frame.

// The raccoon's position on screen (0..1) and his distance from the camera.
uniform vec2 focus_uv = vec2(0.5);
uniform float focus_depth = 0.0;
// Size of the window as a fraction of the screen height; 0 turns it off.
uniform float radius = 0.0;

// 4x4 ordered dither, so the window has a soft, screen-door edge.
const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
		3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void vertex() {
	// Vertex colours are written in sRGB, as LowPoly.material() expects.
	vec3 c = COLOR.rgb;
	COLOR.rgb = mix(pow((c + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), c * (1.0 / 12.92),
			lessThan(c, vec3(0.04045)));
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 1.0;
	// The sun's shadow passes use an orthographic projection; keep shadows whole.
	bool camera_pass = PROJECTION_MATRIX[3][3] < 0.5;
	if (camera_pass && radius > 0.0 && -VERTEX.z < focus_depth - 0.8) {
		vec2 d = SCREEN_UV - focus_uv;
		d.x *= VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
		float cut = smoothstep(1.0, 0.55, length(d) / radius) * 0.9;
		int i = (int(FRAGCOORD.x) % 4) + (int(FRAGCOORD.y) % 4) * 4;
		if (cut > (BAYER[i] + 0.5) / 16.0) {
			discard;
		}
	}
}
