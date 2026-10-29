shader_type spatial;

const float DIFFUSE_MEAN_LUMINANCE = 0.0452;

group_uniforms colour;
uniform vec4 tint : source_color = vec4(1.0);
uniform float detail : hint_range(0.0, 1.0) = 0.5;
uniform float uv_scale : hint_range(0.25, 4.0) = 1.0;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;

group_uniforms surface;
uniform float roughness_scale : hint_range(0.0, 1.0) = 1.0;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;
uniform sampler2D roughness_texture : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap, repeat_enable;

void fragment() {
	vec3 diffuse_sample = texture(albedo_texture, UV * uv_scale).rgb;
	float diffuse_luminance = dot(diffuse_sample, vec3(0.2126, 0.7152, 0.0722));
	ALBEDO = tint.rgb * mix(1.0, diffuse_luminance / DIFFUSE_MEAN_LUMINANCE, detail);
	ROUGHNESS = texture(roughness_texture, UV * uv_scale).r * roughness_scale;
	NORMAL_MAP = texture(normal_texture, UV * uv_scale).rgb;
	NORMAL_MAP_DEPTH = normal_strength;
}
