class_name WaterView
extends MeshInstance3D
## The water surface: one plane over the whole floor that rises with the floor timer.

const WATER_SHADER := preload("res://shaders/water.gdshader")


func setup(grid: FloorGrid, accent: Dictionary = {}) -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(grid.width, grid.height)
	mesh = plane
	position = Vector3(grid.width * 0.5, -0.2, grid.height * 0.5)
	var mat := ShaderMaterial.new()
	mat.shader = WATER_SHADER
	if not accent.is_empty():
		mat.set_shader_parameter(&"deep_color", Accent.color(accent, "water_deep"))
		mat.set_shader_parameter(&"bright_color", Accent.color(accent, "water_bright"))
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func set_level(h: float) -> void:
	position.y = h
	VisualGlobals.set_water_height(h)
