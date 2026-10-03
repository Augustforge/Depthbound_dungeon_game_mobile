// Telegraph zone on the floor (GDD 12.1): translucent red shape that fills from the centre outwards.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

uniform int shape_type = 0; // 0 circle, 1 cone, 2 line/rect
uniform float half_angle = 1.0; // radians, cone only
uniform float progress = 0.0;
uniform vec3 color : source_color = vec3(1.0, 0.18, 0.08);

void fragment() {
	// UV (0..1) across the quad. Circle/cone: centre at (0.5, 0.5), forward = -V. Line: origin at V = 1.
	float inside = 0.0;
	float fill_d = 0.0;
	float edge = 0.0;
	if (shape_type == 2) {
		inside = 1.0;
		fill_d = 1.0 - UV.y;
		edge = max(smoothstep(0.42, 0.5, abs(UV.x - 0.5)), smoothstep(0.97, 1.0, 1.0 - UV.y));
	} else {
		vec2 c = UV * 2.0 - 1.0;
		float r = length(c);
		inside = step(r, 1.0);
		if (shape_type == 1) {
			float a = abs(atan(c.x, -c.y));
			inside *= step(a, half_angle);
			edge = smoothstep(half_angle - 0.06, half_angle, a);
		}
		fill_d = r;
		edge = max(edge, smoothstep(0.93, 1.0, r));
	}
	if (inside < 0.5) {
		discard;
	}
	float filled = step(fill_d, progress);
	ALBEDO = color * (1.2 + filled * 0.6);
	ALPHA = 0.18 + 0.35 * filled + 0.45 * edge;
}
