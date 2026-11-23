shader_type spatial;
render_mode unshaded;

uniform sampler2D with_source_color : source_color, filter_nearest;
uniform sampler2D without_source_color : filter_nearest;

void fragment() {
	float side = step(0.5, UV.x);
	vec2 sample_uv = vec2(fract(UV.x * 2.0), UV.y);
	ALBEDO = side < 0.5
		? texture(with_source_color, sample_uv).rgb
		: texture(without_source_color, sample_uv).rgb;
}
