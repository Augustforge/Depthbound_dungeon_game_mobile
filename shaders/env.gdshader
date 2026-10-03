// Floor and walls: procedural stone until generated textures arrive (art track A0/A4),
// baked torch light, wet line under the water, and wall cutaway around the hero.
shader_type spatial;
render_mode unshaded, cull_back;

#include "res://shaders/common.gdshaderinc"

uniform vec3 stone_color : source_color = vec3(0.33, 0.34, 0.34);
uniform vec3 top_color : source_color = vec3(0.3, 0.31, 0.31);
uniform vec3 ambient : source_color = vec3(0.13, 0.2, 0.23);
uniform float is_wall = 0.0;
// Painted stone (art track A0/A4): tiled in world space, tinted by the floor's accent.
uniform sampler2D floor_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D wall_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float use_textures = 0.0;
uniform float floor_tile = 2.6;
uniform float wall_tile = 2.4;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

vec3 stones(vec2 uv, vec2 size, vec3 base) {
	vec2 g = uv / size;
	float row = floor(g.y);
	g.x += mod(row, 2.0) * 0.5;
	vec2 id = floor(g);
	vec2 f = fract(g);
	float h = hash12(id);
	float edge = min(min(f.x, 1.0 - f.x) * size.x, min(f.y, 1.0 - f.y) * size.y);
	float mortar = smoothstep(0.012, 0.045, edge);
	vec3 c = base * (0.72 + 0.4 * h);
	c *= 0.86 + 0.28 * value_noise(uv * 9.0 + id * 3.7);
	return c * mix(0.32, 1.0, mortar);
}

void fragment() {
	vec3 n = normalize(world_normal);
	bool wall = is_wall > 0.5;
	bool top = wall && n.y > 0.5;
	vec3 albedo;
	vec3 light;
	// Painted textures are about 0.45 grey: scale them to the accent's stone colour.
	vec3 tint = stone_color / 0.34 * 0.95;
	if (top) {
		albedo = use_textures > 0.5
				? texture(wall_tex, world_pos.xz / wall_tile).rgb * top_color / 0.31 * 0.62
				: stones(world_pos.xz, vec2(0.55, 0.42), top_color);
		// Wall tops take the brightest light of the floor around them.
		vec3 l0 = sample_light(world_pos.xz + vec2(0.0, 0.7), TIME);
		vec3 l1 = sample_light(world_pos.xz + vec2(0.0, -0.7), TIME);
		vec3 l2 = sample_light(world_pos.xz + vec2(0.7, 0.0), TIME);
		vec3 l3 = sample_light(world_pos.xz + vec2(-0.7, 0.0), TIME);
		light = ambient * 1.6 + max(max(l0, l1), max(l2, l3)) * 0.8;
	} else if (wall) {
		float u = abs(n.z) > 0.5 ? world_pos.x : world_pos.z;
		albedo = use_textures > 0.5
				? texture(wall_tex, vec2(u, -world_pos.y) / wall_tile).rgb * tint * 0.85
				: stones(vec2(u, world_pos.y), vec2(0.62, 0.3), stone_color * 0.85);
		albedo *= mix(0.55, 1.0, smoothstep(0.0, 1.6, world_pos.y));
		light = ambient + sample_light(world_pos.xz + n.xz * 0.35, TIME);
		light *= 0.92 + 0.08 * n.x; // key light from the top left
	} else {
		albedo = use_textures > 0.5
				? texture(floor_tex, world_pos.xz / floor_tile).rgb * tint
				: stones(world_pos.xz, vec2(0.5, 0.5), stone_color);
		light = ambient + sample_light(world_pos.xz, TIME);
	}
	// Wet stone below and just above the water line.
	float wet = 1.0 - smoothstep(water_height, water_height + 0.12, world_pos.y);
	albedo *= mix(1.0, 0.55, wet);
	albedo = mix(albedo, albedo * vec3(0.6, 0.95, 1.0), wet * 0.6);
	ALBEDO = albedo * light;

	// Cutaway: walls between the camera (south) and the hero dissolve.
	if (wall && cutaway_enabled > 0.5) {
		float dz = world_pos.z - hero_pos.z;
		float dx = abs(world_pos.x - hero_pos.x);
		float inside = (1.0 - smoothstep(2.0, 3.4, dx)) * smoothstep(0.55, 1.1, dz) * (1.0 - smoothstep(3.6, 5.0, dz));
		float fade = inside * (top ? 1.0 : smoothstep(0.35, 0.9, world_pos.y)) * 0.8;
		if (fade > bayer4(FRAGCOORD.xy)) {
			discard;
		}
	}
}
