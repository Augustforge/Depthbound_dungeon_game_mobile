class_name ShaftView
extends Node3D
## A beam of pale light from the vault (LightGrid.place_shafts) with a few slow dust motes.

const SHAFT_SHADER := preload("res://shaders/shaft.gdshader")
const HEIGHT := 5.0


func setup(s: Dictionary) -> void:
	var p: Vector2 = s["pos"]
	position = Vector3(p.x, 0.0, p.y)
	var beam := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(2.2, HEIGHT)
	beam.mesh = quad
	beam.position.y = HEIGHT * 0.5
	var mat := ShaderMaterial.new()
	mat.shader = SHAFT_SHADER
	mat.set_shader_parameter(&"color", s.get("color", Color(0.42, 0.6, 0.72)))
	mat.set_shader_parameter(&"seed", fposmod(p.x * 0.31 + p.y * 0.57, 1.0))
	beam.material_override = mat
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(beam)
	var dust := CPUParticles3D.new()
	dust.amount = 8
	dust.lifetime = 5.0
	dust.preprocess = 5.0
	dust.position.y = 2.5
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(0.6, 2.0, 0.6)
	dust.direction = Vector3.DOWN
	dust.spread = 30.0
	dust.gravity = Vector3.ZERO
	dust.initial_velocity_min = 0.05
	dust.initial_velocity_max = 0.15
	dust.scale_amount_min = 0.015
	dust.scale_amount_max = 0.03
	var mote := SphereMesh.new()
	mote.radius = 1.0
	mote.height = 2.0
	mote.radial_segments = 4
	mote.rings = 2
	dust.mesh = mote
	var dmat := StandardMaterial3D.new()
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.albedo_color = Color(0.7, 0.85, 0.95)
	dust.material_override = dmat
	add_child(dust)
