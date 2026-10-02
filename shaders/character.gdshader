// Placeholder characters and props: flat colour lit by the baked torch grid, a fixed key light
// from the top left and a cool rim so silhouettes read on a small screen (GDD 18.1).
shader_type spatial;
render_mode unshaded, cull_back;

#include "res://shaders/common.gdshaderinc"

uniform vec3 albedo : source_color = vec3(0.7);
uniform vec3 ambient : source_color = vec3(0.2, 0.28, 0.31);
uniform vec3 rim_color : source_color = vec3(0.35, 0.65, 0.7);
uniform float emission = 0.0;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(world_normal);
	float key = clamp(dot(n, normalize(vec3(-0.5, 0.8, 0.35))), 0.0, 1.0);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 light = ambient + sample_light(world_pos.xz, TIME) * (0.6 + 0.6 * key) + vec3(0.12) * key;
	vec3 col = albedo * light + rim_color * rim * 0.45 + albedo * emission;
	float under = 1.0 - smoothstep(water_height - 0.02, water_height + 0.02, world_pos.y);
	col = mix(col, col * vec3(0.35, 0.7, 0.75), under * 0.7);
	ALBEDO = col;
}
