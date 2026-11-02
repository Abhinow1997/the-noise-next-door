// NOTE: Shader automatically converted from Godot Engine 4.7.2.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx; // Opaque 3D surface with back-face culling and Godot's PBR lighting.

uniform vec4 albedo : source_color; // Base colour; source_color converts the colour from sRGB to linear.
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable; // Colour image, filtered smoothly and tiled across UVs.
uniform ivec2 albedo_texture_size; // Width and height of the albedo texture in pixels.
uniform float point_size : hint_range(0.1, 128.0, 0.1); // Point size for particle rendering; unused on this sphere.

uniform float roughness : hint_range(0.0, 1.0); // Overall roughness: 0 is smooth and 1 is rough.
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable; // Metallic data; defaults to white if no image is set.
uniform vec4 metallic_texture_channel; // Selects which texture channel supplies the metallic value.
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable; // Roughness data is read from the red channel.

uniform float specular : hint_range(0.0, 1.0, 0.01); // Controls the strength of specular reflections.
uniform float metallic : hint_range(0.0, 1.0, 0.01); // Controls how metallic the surface is.

uniform sampler2D texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable; // Normal data changes how light reacts to the surface.
uniform float normal_scale : hint_range(-16.0, 16.0); // Scales the strength of the normal map.

uniform vec3 uv1_scale; // Scale applied to the first UV set.
uniform vec3 uv1_offset; // Offset applied to the first UV set.
uniform vec3 uv2_scale; // Scale for a second UV set; unused by this converted shader.
uniform vec3 uv2_offset; // Offset for a second UV set; unused by this converted shader.

void vertex() { // Runs once for each vertex before the surface is rasterized.
	UV = UV * uv1_scale.xy + uv1_offset.xy; // Transform the built-in UV coordinates for texture sampling.
}

void fragment() { // Runs for each visible fragment (pixel) on the surface.
	vec2 base_uv = UV; // Copy the interpolated UV coordinates for the texture lookups.

	vec4 albedo_tex = texture(texture_albedo, base_uv); // Read the colour texture at this surface point.
	ALBEDO = albedo.rgb * albedo_tex.rgb; // Combine its colour with the material's base colour.

	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel); // Read the chosen metallic channel.
	METALLIC = metallic_tex * metallic; // Apply the metallic amount to that texture value.
	SPECULAR = specular; // Set the specular reflection amount.

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0); // Select the red channel from the roughness image.
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel); // Read roughness at this UV.
	ROUGHNESS = roughness_tex * roughness; // Combine the texture value with the overall roughness.

	// Normal Map: Enabled // The converted StandardMaterial3D had normal mapping enabled.
	NORMAL_MAP = texture(texture_normal, base_uv).rgb; // Pass the sampled normal data to Godot's lighting.
	NORMAL_MAP_DEPTH = normal_scale; // Set the normal map's strength.
}
