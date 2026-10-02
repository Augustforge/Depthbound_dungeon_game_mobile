// Torch flame billboard: animated noise shape, additive.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

#include "res://shaders/common.gdshaderinc"

uniform vec3 core_color : source_color = vec3(1.0, 0.85, 0.45);
uniform vec3 edge_color : source_color = vec3(1.0, 0.38, 0.08);
uniform float seed = 0.0;
// 1 = soft round glow behind the flame instead of the flame itself.
uniform float halo = 0.0;

void vertex() {
	// Billboard that stays upright (keeps Y), so the flame never leans back into the wall.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
			vec4(0.0, 1.0, 0.0, 0.0),
			vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
			MODEL_MATRIX[3]);
}

void fragment() {
	if (halo > 0.5) {
		float r = length(UV * 2.0 - 1.0);
		float pulse = 0.85 + 0.15 * sin(TIME * 7.0 + seed * 20.0);
		ALBEDO = edge_color * pow(clamp(1.0 - r, 0.0, 1.0), 2.2) * 0.32 * pulse;
	} else {
	vec2 uv = UV * 2.0 - 1.0;
	uv.y = -uv.y;
	float t = TIME * 2.6 + seed * 13.0;
	float wob = (value_noise(vec2(uv.y * 3.0 - t * 2.0, seed)) - 0.5) * 0.35 * (uv.y + 1.0);
	float x = uv.x + wob;
	float width = mix(0.55, 0.05, clamp((uv.y + 1.0) * 0.5, 0.0, 1.0));
	float shape = 1.0 - smoothstep(width * 0.6, width, abs(x));
	shape *= smoothstep(-1.0, -0.75, uv.y) * (1.0 - smoothstep(0.55, 1.0, uv.y + value_noise(vec2(x * 4.0, t)) * 0.3));
	vec3 col = mix(edge_color, core_color, smoothstep(0.2, 0.9, shape * (1.0 - (uv.y + 1.0) * 0.35)));
	ALBEDO = col * shape * 0.85;
	}
}
