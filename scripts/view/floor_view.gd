class_name FloorView
extends Node3D
## Builds the 3D geometry of a floor from its grid: uneven stone floor (low spots flood first),
## walls with dark tops, torches. Placeholder materials until the art track (A0/A4).

const WALL_HEIGHT := 2.2
const CHUNK := 16
const ENV_SHADER := preload("res://shaders/env.gdshader")
const FLOOR_TEX := "res://assets/textures/floor_stone.webp"
const WALL_TEX := "res://assets/textures/wall_stone.webp"

var grid: FloorGrid
var floor_material: ShaderMaterial
var wall_material: ShaderMaterial
var _noise := FastNoiseLite.new()


func build(floor_grid: FloorGrid, torches: Array[Dictionary], accent: Dictionary = {}) -> void:
	grid = floor_grid
	_noise.seed = 7
	_noise.frequency = 0.25
	floor_material = ShaderMaterial.new()
	floor_material.shader = ENV_SHADER
	wall_material = ShaderMaterial.new()
	wall_material.shader = ENV_SHADER
	wall_material.set_shader_parameter(&"is_wall", 1.0)
	for mat: ShaderMaterial in [floor_material, wall_material]:
		if ResourceLoader.exists(FLOOR_TEX) and ResourceLoader.exists(WALL_TEX):
			mat.set_shader_parameter(&"floor_tex", load(FLOOR_TEX))
			mat.set_shader_parameter(&"wall_tex", load(WALL_TEX))
			mat.set_shader_parameter(&"use_textures", 1.0)
	if not accent.is_empty():
		for mat: ShaderMaterial in [floor_material, wall_material]:
			mat.set_shader_parameter(&"stone_color", Accent.color(accent, "stone"))
			mat.set_shader_parameter(&"top_color", Accent.color(accent, "top"))
			mat.set_shader_parameter(&"ambient", Accent.color(accent, "ambient"))
	for cy in range(0, grid.height, CHUNK):
		for cx in range(0, grid.width, CHUNK):
			_build_chunk(Rect2i(cx, cy, CHUNK, CHUNK))
	for t in torches:
		var torch := TorchView.new()
		add_child(torch)
		torch.setup(t)


## Corner height: gentle noise, deep basins around decorative water cells (~).
func corner_height(x: int, z: int) -> float:
	for c in [Vector2i(x - 1, z - 1), Vector2i(x, z - 1), Vector2i(x - 1, z), Vector2i(x, z)]:
		if grid.marker_cells("~").has(c):
			return -0.32
	return _noise.get_noise_2d(x, z) * 0.06 - 0.01


func _build_chunk(r: Rect2i) -> void:
	var floor_st := SurfaceTool.new()
	floor_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wall_st := SurfaceTool.new()
	wall_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var has_floor := false
	var has_wall := false
	for y in range(r.position.y, mini(r.end.y, grid.height)):
		for x in range(r.position.x, mini(r.end.x, grid.width)):
			var c := Vector2i(x, y)
			if grid.is_wall(c):
				if _near_floor(c):
					_add_wall(wall_st, c)
					has_wall = true
			else:
				_add_floor_cell(floor_st, x, y)
				has_floor = true
	if has_floor:
		_add_mesh(floor_st, floor_material)
	if has_wall:
		_add_mesh(wall_st, wall_material)


func _add_mesh(st: SurfaceTool, mat: Material) -> void:
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _near_floor(c: Vector2i) -> bool:
	for oy in range(-1, 2):
		for ox in range(-1, 2):
			var n := c + Vector2i(ox, oy)
			if grid.in_bounds(n) and not grid.is_wall(n):
				return true
	return false


func _add_floor_cell(st: SurfaceTool, x: int, y: int) -> void:
	var a := Vector3(x, corner_height(x, y), y)
	var b := Vector3(x + 1, corner_height(x + 1, y), y)
	var c := Vector3(x + 1, corner_height(x + 1, y + 1), y + 1)
	var d := Vector3(x, corner_height(x, y + 1), y + 1)
	_quad(st, a, b, c, d)


func _add_wall(st: SurfaceTool, c: Vector2i) -> void:
	var x := float(c.x)
	var z := float(c.y)
	var h := WALL_HEIGHT
	_quad(st, Vector3(x, h, z), Vector3(x + 1, h, z), Vector3(x + 1, h, z + 1), Vector3(x, h, z + 1))
	# Side faces only where the neighbour is open floor.
	if not grid.is_wall(c + Vector2i(0, 1)):
		_quad(st, Vector3(x, h, z + 1), Vector3(x + 1, h, z + 1), Vector3(x + 1, -0.4, z + 1), Vector3(x, -0.4, z + 1))
	if not grid.is_wall(c + Vector2i(0, -1)):
		_quad(st, Vector3(x + 1, h, z), Vector3(x, h, z), Vector3(x, -0.4, z), Vector3(x + 1, -0.4, z))
	if not grid.is_wall(c + Vector2i(1, 0)):
		_quad(st, Vector3(x + 1, h, z + 1), Vector3(x + 1, h, z), Vector3(x + 1, -0.4, z), Vector3(x + 1, -0.4, z + 1))
	if not grid.is_wall(c + Vector2i(-1, 0)):
		_quad(st, Vector3(x, h, z), Vector3(x, h, z + 1), Vector3(x, -0.4, z + 1), Vector3(x, -0.4, z))


## Quad a-b-c-d given clockwise as seen from the side it faces (Godot's front-face winding).
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for v in [a, b, c, a, c, d]:
		st.add_vertex(v)
