// Shared helpers for Depthbound shaders.
// Globals are declared in project.godot [shader_globals] and set by scripts/view/visual_globals.gd.
global uniform sampler2D light_grid : filter_linear, repeat_disable;
global uniform vec4 light_grid_rect; // xy = world xz origin, zw = size in metres
global uniform float water_height;
global uniform vec3 hero_pos;
global uniform float cutaway_enabled;

const float LIGHT_SCALE = 4.0;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), u.x),
			mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Baked torch light at a world xz position (decision D4), with a cheap spatial flicker.
vec3 sample_light(vec2 xz, float time) {
	vec2 uv = (xz - light_grid_rect.xy) / light_grid_rect.zw;
	vec3 l = texture(light_grid, uv).rgb * LIGHT_SCALE;
	float flicker = 1.0 + 0.07 * sin(time * 9.0 + xz.x * 1.7 + xz.y * 2.3) + 0.04 * sin(time * 23.0 + xz.y * 3.1);
	// Soft cool-white light around the hero so the player always reads their own character.
	float d = distance(xz, hero_pos.xz);
	vec3 hero_glow = vec3(0.32, 0.36, 0.36) * pow(clamp(1.0 - d / 4.0, 0.0, 1.0), 2.0);
	return l * flicker + hero_glow;
}

// 1 on walkable floor, 0 inside walls.
float floor_mask(vec2 xz) {
	vec2 uv = (xz - light_grid_rect.xy) / light_grid_rect.zw;
	return texture(light_grid, uv).a;
}

// 4x4 ordered dither threshold for screen-door transparency.
float bayer4(vec2 frag) {
	ivec2 p = ivec2(mod(frag, 4.0));
	int i = p.x + p.y * 4;
	int m[16] = int[16](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[i]) + 0.5) / 16.0;
}
