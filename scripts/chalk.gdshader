shader_type canvas_item;
// Chalk, for the title screen's writing (title_menu.gd): a grain fixed to the screen
// nibbles at the soft edges of the lines and rubs a few specks thin inside them, so
// they read as chalk rather than clean type, as in the author's picture.

uniform sampler2D grain : repeat_enable, filter_linear;
// How big a grain is on the screen, in pixels.
uniform float grain_px = 2.5;
// How far into the edges the grain bites, and how thin the specks get.
uniform float bite = 0.6;
uniform float specks = 0.3;

void fragment() {
	float g = texture(grain, FRAGCOORD.xy / (grain_px * 128.0)).r;
	// COLOR comes multiplied by the glyph's coverage; the grain works on the coverage
	// alone, so faint writing is as rough as bright writing, just fainter.
	float coverage = texture(TEXTURE, UV).a;
	float tint = coverage > 0.001 ? COLOR.a / coverage : 0.0;
	float edge = smoothstep(g * bite, g * bite + 0.3, coverage);
	COLOR.a = tint * edge * (1.0 - specks * smoothstep(0.62, 0.85, g));
}
