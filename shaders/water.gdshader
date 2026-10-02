// Rising water (GDD 10.2): teal glow, moving caustics, warm torch reflections, hero ripples.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

#include "res://shaders/common.gdshaderinc"

uniform vec3 deep_color : source_color = vec3(0.01, 0.16, 0.18);
uniform vec3 bright_color : source_color = vec3(0.1, 0.62, 0.6);
uniform float opacity = 0.62;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float caustic(vec2 p, float t) {
	float a = value_noise(p * 1.6 + vec2(t * 0.21, t * 0.13));
	float b = value_noise(p * 1.6 * 1.7 - vec2(t * 0.17, -t * 0.19));
	float c = 1.0 - abs(a - b) * 3.0;
	return pow(clamp(c, 0.0, 1.0), 6.0);
}

void fragment() {
	vec2 p = world_pos.xz;
	if (floor_mask(p) < 0.35) {
		discard;
	}
	float t = TIME;
	float n = value_noise(p * 0.7 + vec2(t * 0.05, -t * 0.04));
	vec3 col = mix(deep_color, bright_color, 0.25 + 0.4 * n);
	col += bright_color * caustic(p, t) * 0.28;
	float d = distance(p, hero_pos.xz);
	float ripple = sin(d * 11.0 - t * 5.0) * exp(-d * 1.3) * step(0.25, d);
	col += vec3(0.25, 0.45, 0.45) * max(ripple, 0.0) * 0.35;
	vec2 wobble = vec2(value_noise(p * 3.0 + t), value_noise(p * 3.0 - t)) - 0.5;
	vec3 glints = sample_light(p + wobble * 0.6, t);
	col += glints * (0.45 + 0.9 * caustic(p * 1.3, t * 1.3));
	ALBEDO = col;
	// Shallow water at the edges of puddles is more transparent.
	ALPHA = opacity * (0.75 + 0.25 * n);
}
