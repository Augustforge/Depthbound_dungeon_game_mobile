class_name MobView
extends Node3D
## Placeholder enemy built from primitives (until art track A2): colour and size per mob id.
## Reads Mob state: position, facing, attack lunge, hit flash, death fall.

const CHAR_SHADER := preload("res://shaders/character.gdshader")
const LOOKS := {
	&"rat": {"color": Color(0.36, 0.27, 0.22), "height": 0.5, "quadruped": true},
	&"prisoner": {"color": Color(0.6, 0.52, 0.4), "height": 1.75},
	&"jailer": {"color": Color(0.32, 0.3, 0.3), "height": 1.95},
	&"crossbowman": {"color": Color(0.3, 0.36, 0.45), "height": 1.8},
	&"drowned": {"color": Color(0.42, 0.58, 0.58), "height": 1.75},
	&"chain_brute": {"color": Color(0.45, 0.25, 0.2), "height": 2.5},
}

var mob: Mob
var _body: Node3D
var _materials: Array[ShaderMaterial] = []
var _base_color: Color
var _dead_time: float = 0.0
var _time: float = 0.0


func setup(m: Mob) -> void:
	mob = m
	var look: Dictionary = LOOKS.get(m.def_id, {"color": Color(0.5, 0.5, 0.5), "height": 1.7})
	_base_color = look["color"]
	_body = Node3D.new()
	add_child(_body)
	var h: float = look["height"]
	if look.get("quadruped", false):
		_part(CapsuleMesh, Vector3(0.18, 0.75, 0), Vector3(0, 0.22, 0), _base_color, Vector3(90, 0, 0))
		_part(SphereMesh, Vector3(0.13, 0.13, 0), Vector3(0, 0.26, 0.4), _base_color.darkened(0.2))
		_part(CylinderMesh, Vector3(0.025, 0.5, 0), Vector3(0, 0.2, -0.55), Color(0.55, 0.4, 0.38), Vector3(70, 0, 0))
	else:
		var w := m.radius * 0.75
		_part(CylinderMesh, Vector3(w * 0.4, h * 0.45, 0), Vector3(-w * 0.45, h * 0.225, 0), _base_color.darkened(0.45))
		_part(CylinderMesh, Vector3(w * 0.4, h * 0.45, 0), Vector3(w * 0.45, h * 0.225, 0), _base_color.darkened(0.45))
		_part(CapsuleMesh, Vector3(w, h * 0.42, 0), Vector3(0, h * 0.62, 0), _base_color)
		_part(SphereMesh, Vector3(h * 0.085, h * 0.085, 0), Vector3(0, h * 0.9, 0), _base_color.lightened(0.15))
		if m.def_id == &"jailer":
			_part(BoxMesh, Vector3(0.7, 1.1, 0.08), Vector3(-0.3, h * 0.5, 0.35), Color(0.35, 0.24, 0.15))
		elif m.def_id == &"crossbowman":
			_part(BoxMesh, Vector3(0.6, 0.06, 0.5), Vector3(0, h * 0.62, 0.4), Color(0.35, 0.25, 0.15))
	var shadow := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = m.radius * 1.2
	disc.bottom_radius = m.radius * 1.2
	disc.height = 0.01
	shadow.mesh = disc
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.albedo_color = Color(0, 0, 0, 0.4)
	shadow.material_override = smat
	shadow.position.y = 0.03
	add_child(shadow)
	_sync(0.0)


func _part(mesh_type: Variant, size: Vector3, pos: Vector3, color: Color, rot_deg: Vector3 = Vector3.ZERO) -> void:
	var mi := MeshInstance3D.new()
	var mesh: PrimitiveMesh = mesh_type.new()
	if mesh is CylinderMesh:
		mesh.top_radius = size.x
		mesh.bottom_radius = size.x
		mesh.height = size.y
	elif mesh is CapsuleMesh:
		mesh.radius = size.x
		mesh.height = size.y
	elif mesh is SphereMesh:
		mesh.radius = size.x
		mesh.height = size.y * 2.0
	elif mesh is BoxMesh:
		mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees = rot_deg
	var mat := ShaderMaterial.new()
	mat.shader = CHAR_SHADER
	mat.set_shader_parameter(&"albedo", color)
	mi.material_override = mat
	_materials.append(mat)
	_body.add_child(mi)


func _process(delta: float) -> void:
	_sync(delta)


func _sync(delta: float) -> void:
	_time += delta
	position = Vector3(mob.pos.x, 0.0, mob.pos.y)
	rotation.y = lerp_angle(rotation.y, atan2(mob.facing.x, mob.facing.y), minf(1.0, delta * 12.0))
	var flash := clampf(1.0 - mob.since_hit / 0.15, 0.0, 1.0)
	for m in _materials:
		m.set_shader_parameter(&"emission", flash * 1.5)
	if not mob.alive:
		_dead_time += delta
		_body.rotation.x = lerpf(_body.rotation.x, -PI / 2.0, minf(1.0, delta * 8.0))
		position.y = -minf(1.0, maxf(0.0, _dead_time - 1.0)) * 0.6
		if _dead_time > 2.5:
			queue_free()
		return
	match mob.anim_state:
		&"run":
			_body.position.y = absf(sin(_time * 10.0)) * 0.06
			_body.position.z = 0.0
		&"attack":
			_body.position.z = sin((1.0 - mob.swing_left / 0.4) * PI) * 0.35
		_:
			_body.position.y = 0.0
			_body.position.z = 0.0
