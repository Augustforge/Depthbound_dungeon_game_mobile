class_name ProjectileView
extends Node3D
## Spinning throwing blade or a flat blade wave (Cleave level 5).

const CHAR_SHADER := preload("res://shaders/character.gdshader")

var proj: Projectile
var _mesh: MeshInstance3D


func setup(p: Projectile) -> void:
	proj = p
	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.5, 0.04, 0.12) if p.kind == &"blade" else Vector3(p.width, 0.05, 0.3)
	_mesh.mesh = box
	var mat := ShaderMaterial.new()
	mat.shader = CHAR_SHADER
	mat.set_shader_parameter(&"albedo", Color(0.75, 0.75, 0.72) if p.kind == &"blade" else Color(0.6, 0.85, 0.9))
	mat.set_shader_parameter(&"emission", 0.4 if p.kind == &"blade" else 1.2)
	_mesh.material_override = mat
	add_child(_mesh)
	_process(0.0)


func _process(delta: float) -> void:
	if proj == null or not proj.alive:
		queue_free()
		return
	position = Vector3(proj.pos.x, 1.0, proj.pos.y)
	rotation.y = atan2(proj.dir.x, proj.dir.y)
	if proj.kind == &"blade":
		_mesh.rotation.y += delta * 25.0
