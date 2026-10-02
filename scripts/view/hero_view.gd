class_name HeroView
extends Node3D
## Placeholder swordsman built from primitives (until art track A1). Reads Hero state each frame:
## position, facing, run bob, dodge roll.

const CHAR_SHADER := preload("res://shaders/character.gdshader")

var hero: Hero
var _body: Node3D
var _time: float = 0.0
var _roll: float = 0.0


func setup(h: Hero) -> void:
	hero = h
	_body = Node3D.new()
	add_child(_body)
	_part(CylinderMesh, Vector3(0.11, 0.8, 0.11), Vector3(-0.11, 0.4, 0), Color(0.16, 0.14, 0.13)) # legs
	_part(CylinderMesh, Vector3(0.11, 0.8, 0.11), Vector3(0.11, 0.4, 0), Color(0.16, 0.14, 0.13))
	_part(CapsuleMesh, Vector3(0.24, 0.72, 0.2), Vector3(0, 1.12, 0), Color(0.78, 0.72, 0.6)) # shirt
	_part(BoxMesh, Vector3(0.42, 0.1, 0.26), Vector3(0, 0.86, 0), Color(0.5, 0.12, 0.1)) # red sash
	_part(SphereMesh, Vector3(0.16, 0.16, 0.16), Vector3(0, 1.62, 0), Color(0.75, 0.55, 0.42)) # head
	_part(SphereMesh, Vector3(0.17, 0.12, 0.17), Vector3(0, 1.7, -0.02), Color(0.12, 0.09, 0.07)) # hair
	_part(CylinderMesh, Vector3(0.07, 0.6, 0.07), Vector3(0.3, 1.1, 0), Color(0.7, 0.62, 0.52)) # arm
	_part(BoxMesh, Vector3(0.05, 1.05, 0.02), Vector3(0.36, 0.95, 0.38), Color(0.75, 0.78, 0.8), Vector3(70, 0, 0)) # sword
	var shadow := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.42
	disc.bottom_radius = 0.42
	disc.height = 0.01
	shadow.mesh = disc
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.albedo_color = Color(0, 0, 0, 0.45)
	shadow.material_override = smat
	shadow.position.y = 0.03
	add_child(shadow)


func _part(mesh_type: Variant, size: Vector3, pos: Vector3, color: Color, rot_deg: Vector3 = Vector3.ZERO) -> void:
	var mi := MeshInstance3D.new()
	var m: PrimitiveMesh = mesh_type.new()
	if m is CylinderMesh:
		m.top_radius = size.x
		m.bottom_radius = size.x
		m.height = size.y
	elif m is CapsuleMesh:
		m.radius = size.x
		m.height = size.y
	elif m is SphereMesh:
		m.radius = size.x
		m.height = size.y * 2.0
	elif m is BoxMesh:
		m.size = size
	mi.mesh = m
	mi.position = pos
	mi.rotation_degrees = rot_deg
	var mat := ShaderMaterial.new()
	mat.shader = CHAR_SHADER
	mat.set_shader_parameter(&"albedo", color)
	mi.material_override = mat
	_body.add_child(mi)


func _process(delta: float) -> void:
	if hero == null:
		return
	_time += delta
	position = Vector3(hero.pos.x, 0.0, hero.pos.y)
	var yaw := atan2(hero.facing.x, hero.facing.y)
	rotation.y = lerp_angle(rotation.y, yaw, minf(1.0, delta * 18.0))
	match hero.anim_state:
		&"run":
			_body.position.y = absf(sin(_time * 11.0)) * 0.08
			_body.rotation.x = 0.12
			_roll = 0.0
		&"dodge":
			_roll += delta * TAU / hero.dodge_duration
			_body.rotation.x = _roll
			_body.position.y = 0.45 * sin(minf(_roll, PI))
		_:
			_body.position.y = sin(_time * 2.0) * 0.015
			_body.rotation.x = 0.0
			_roll = 0.0
	VisualGlobals.set_hero_pos(global_position)
