// Pale light falling from a hole in the vault: a soft upright additive beam with drifting dust.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

#include "res://shaders/common.gdshaderinc"

uniform vec3 color : source_color = vec3(0.42, 0.6, 0.72);
uniform float seed = 0.0;

void vertex() {
	// Upright billboard: turns to the camera around Y only.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
			vec4(0.0, 1.0, 0.0, 0.0),
			vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
			MODEL_MATRIX[3]);
}

void fragment() {
	float x = abs(UV.x * 2.0 - 1.0);
	// Wider at the bottom, like a cone of light; fades out towards the vault and at the floor.
	float width = mix(0.45, 1.0, UV.y);
	float beam = 1.0 - smoothstep(width * 0.35, width, x);
	beam *= smoothstep(0.0, 0.35, UV.y) * (1.0 - smoothstep(0.9, 1.0, UV.y));
	float dust = value_noise(vec2(UV.x * 9.0 + seed * 7.0, UV.y * 5.0 - TIME * 0.25));
	ALBEDO = color * beam * (0.16 + 0.1 * dust);
}
