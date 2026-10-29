shader_type spatial;
render_mode blend_mix, unshaded, depth_draw_opaque;

uniform float alarm : hint_range(0.0, 1.0) = 0.0;
uniform float shown : hint_range(0.0, 1.0) = 1.0;
uniform vec4 watch_color : source_color = vec4(1.0, 0.93, 0.62, 0.5);
uniform vec4 alarm_color : source_color = vec4(1.0, 0.33, 0.27, 0.65);

void fragment() {
	ALBEDO = mix(watch_color.rgb, alarm_color.rgb, alarm);
	ALPHA = COLOR.a * mix(watch_color.a, alarm_color.a, alarm) * shown;
}