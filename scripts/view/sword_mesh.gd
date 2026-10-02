class_name SwordMesh
extends RefCounted
## The hero's rusty longsword built from boxes (cheaper than a generated model, reads fine at game scale).
## Local +Y runs from the grip to the tip; the grip is at the origin.

const CHAR_SHADER := preload("res://shaders/character.gdshader")


static func build() -> Node3D:
	var root := Node3D.new()
	_box(root, Vector3(0.035, 0.2, 0.035), Vector3(0, 0.0, 0), Color(0.22, 0.14, 0.09)) # grip
	_box(root, Vector3(0.05, 0.05, 0.05), Vector3(0, -0.12, 0), Color(0.4, 0.33, 0.25)) # pommel
	_box(root, Vector3(0.24, 0.035, 0.05), Vector3(0, 0.11, 0), Color(0.42, 0.35, 0.28)) # crossguard
	_box(root, Vector3(0.055, 0.86, 0.012), Vector3(0, 0.56, 0), Color(0.5, 0.5, 0.49), 0.05) # blade
	return root


static func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, emission: float = 0.0) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	var mat := ShaderMaterial.new()
	mat.shader = CHAR_SHADER
	mat.set_shader_parameter(&"albedo", color)
	mat.set_shader_parameter(&"emission", emission)
	mi.material_override = mat
	parent.add_child(mi)
