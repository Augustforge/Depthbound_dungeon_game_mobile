class_name TorchView
extends Node3D
## Wall torch: iron bracket, animated flame billboard and a few embers.

const FLAME_SHADER := preload("res://shaders/flame.gdshader")
const CHAR_SHADER := preload("res://shaders/character.gdshader")


func setup(t: Dictionary) -> void:
	var p: Vector2 = t["pos"]
	var n: Vector2 = t["normal"]
	position = Vector3(p.x - n.x * 0.42, LightGrid.TORCH_HEIGHT, p.y - n.y * 0.42)
	var bracket := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.12, 0.42, 0.12)
	bracket.mesh = box
	bracket.position = Vector3(n.x * 0.12, -0.25, n.y * 0.12)
	var mat := ShaderMaterial.new()
	mat.shader = CHAR_SHADER
	mat.set_shader_parameter(&"albedo", Color(0.25, 0.2, 0.17))
	bracket.material_override = mat
	add_child(bracket)
	var flame := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.5, 0.8)
	flame.mesh = quad
	flame.position = Vector3(n.x * 0.3, 0.3, n.y * 0.3)
	var fmat := ShaderMaterial.new()
	fmat.shader = FLAME_SHADER
	fmat.set_shader_parameter(&"seed", fposmod(p.x * 0.37 + p.y * 0.71, 1.0))
	flame.material_override = fmat
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(flame)
	var glow := MeshInstance3D.new()
	var glow_quad := QuadMesh.new()
	glow_quad.size = Vector2(1.6, 1.6)
	glow.mesh = glow_quad
	glow.position = flame.position + Vector3(n.x * 0.05, 0.0, n.y * 0.05)
	var gmat := ShaderMaterial.new()
	gmat.shader = FLAME_SHADER
	gmat.set_shader_parameter(&"halo", 1.0)
	gmat.set_shader_parameter(&"seed", fposmod(p.x * 0.37 + p.y * 0.71, 1.0))
	glow.material_override = gmat
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(glow)
	var embers := CPUParticles3D.new()
	embers.amount = 6
	embers.lifetime = 1.2
	embers.position = flame.position + Vector3(0, 0.15, 0)
	embers.direction = Vector3.UP
	embers.spread = 25.0
	embers.gravity = Vector3(0, 0.6, 0)
	embers.initial_velocity_min = 0.2
	embers.initial_velocity_max = 0.5
	embers.scale_amount_min = 0.02
	embers.scale_amount_max = 0.04
	var ember_mesh := SphereMesh.new()
	ember_mesh.radius = 1.0
	ember_mesh.height = 2.0
	ember_mesh.radial_segments = 4
	ember_mesh.rings = 2
	embers.mesh = ember_mesh
	var emat := StandardMaterial3D.new()
	emat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	emat.albedo_color = Color(1.0, 0.55, 0.2)
	embers.material_override = emat
	add_child(embers)
