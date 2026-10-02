class_name VisualGlobals
extends RefCounted
## Sets the global shader uniforms declared in project.godot [shader_globals].


static func set_light_grid(texture: Texture2D, origin: Vector2, size: Vector2) -> void:
	RenderingServer.global_shader_parameter_set(&"light_grid", texture)
	RenderingServer.global_shader_parameter_set(&"light_grid_rect", Vector4(origin.x, origin.y, size.x, size.y))


static func set_water_height(h: float) -> void:
	RenderingServer.global_shader_parameter_set(&"water_height", h)


static func set_hero_pos(p: Vector3) -> void:
	RenderingServer.global_shader_parameter_set(&"hero_pos", p)
