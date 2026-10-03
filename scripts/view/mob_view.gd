class_name MobView
extends Node3D
## Placeholder enemy built from primitives (until art track A2): colour and size per mob id.
## Reads Mob state: position, facing, attack lunge, hit flash, death fall.

const CHAR_SHADER := preload("res://shaders/character.gdshader")
const LOOKS := {
	&"rat": {"color": Color(0.36, 0.27, 0.22), "height": 0.55, "quadruped": true},
	&"prisoner": {"color": Color(0.6, 0.52, 0.4), "height": 1.75},
	&"jailer": {"color": Color(0.32, 0.3, 0.3), "height": 1.95},
	&"crossbowman": {"color": Color(0.3, 0.36, 0.45), "height": 1.8},
	&"drowned": {"color": Color(0.42, 0.58, 0.58), "height": 1.75},
	&"chain_brute": {"color": Color(0.45, 0.25, 0.2), "height": 2.5},
}

const MODELS := {
	&"prisoner": {"path": "res://assets/models/prisoner/prisoner.glb",
		"clips": {
			&"idle": &"Idle_02", &"run": &"Run_02",
			&"attack": &"Right_Hand_Sword_Slash", &"hit": &"Hit_Reaction", &"death": &"Dead"}},
	&"jailer": {"path": "res://assets/models/jailer/jailer.glb",
		"clips": {
			&"idle": &"Idle_02", &"run": &"Monster_Walk",
			&"attack": &"Heavy_Hammer_Swing", &"hit": &"Hit_Reaction", &"death": &"dying_backwards"}},
	&"crossbowman": {"path": "res://assets/models/crossbowman/crossbowman.glb",
		"clips": {
			&"idle": &"Idle_02", &"run": &"Run_02",
			&"attack": &"Draw_and_Shoot_from_Back_1", &"hit": &"Hit_Reaction", &"death": &"Dead"}},
	&"drowned": {"path": "res://assets/models/drowned/drowned.glb",
		"clips": {
			&"idle": &"Idle_02", &"run": &"Injured_Walk",
			&"attack": &"Right_Hand_Sword_Slash", &"hit": &"Hit_Reaction", &"death": &"Dead"}},
}

const RAT_MODEL := "res://assets/models/rat/rat.glb"

var mob: Mob
var model: RiggedModel
## Unrigged model animated procedurally (quadrupeds: Meshy cannot rig them).
var _static_model: Node3D
var _last_swing: float = 0.0
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
	var model_info: Dictionary = MODELS.get(m.def_id, {})
	if not model_info.is_empty() and ResourceLoader.exists(model_info["path"]):
		model = RiggedModel.new()
		_body.add_child(model)
		model.setup(load(model_info["path"]), model_info["clips"])
		_add_props()
	elif m.def_id == &"rat" and ResourceLoader.exists(RAT_MODEL):
		_static_model = _load_static(RAT_MODEL, look["height"])
		_body.add_child(_static_model)
	elif look.get("quadruped", false):
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


## Loads an unrigged model, swaps in the game shader and scales it to the given height.
func _load_static(path: String, height: float) -> Node3D:
	var inst: Node3D = (load(path) as PackedScene).instantiate()
	var aabb := AABB()
	var first := true
	for mi in RiggedModel._all_meshes(inst):
		var box := mi.transform * mi.get_aabb()
		aabb = box if first else aabb.merge(box)
		first = false
		for i in mi.mesh.get_surface_count():
			var src := mi.get_active_material(i) as BaseMaterial3D
			var mat := ShaderMaterial.new()
			mat.shader = CHAR_SHADER
			mat.set_shader_parameter(&"albedo", Color.WHITE)
			if src and src.albedo_texture:
				mat.set_shader_parameter(&"albedo_tex", src.albedo_texture)
			mi.set_surface_override_material(i, mat)
			_materials.append(mat)
	var holder := Node3D.new()
	holder.add_child(inst)
	var k := height / maxf(aabb.size.y, 0.001)
	inst.scale = Vector3.ONE * k
	inst.position = -Vector3(aabb.get_center().x, aabb.position.y, aabb.get_center().z) * k
	return holder


func _add_props() -> void:
	match mob.def_id:
		&"jailer":
			model.attach("RightHand", SwordMesh.build_club(), Vector3(0, 0.05, 0), Vector3(-90, 0, 0))
			model.attach("LeftForeArm", SwordMesh.build_shield(), Vector3(0, 0.15, 0.12), Vector3(0, 90, 0))
		&"crossbowman":
			model.attach("RightHand", SwordMesh.build_crossbow(), Vector3(0, 0.05, 0), Vector3(-90, 0, 0))


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
	if model:
		_animate_model(delta, flash)
		return
	if not mob.alive:
		_dead_time += delta
		_body.rotation.x = lerpf(_body.rotation.x, -PI / 2.0, minf(1.0, delta * 8.0))
		position.y = -minf(1.0, maxf(0.0, _dead_time - 1.0)) * 0.6
		if _dead_time > 2.5:
			queue_free()
		return
	_animate_placeholder()


func _animate_model(delta: float, flash: float) -> void:
	model.set_flash(flash * 0.8)
	if not mob.alive:
		_dead_time += delta
		model.play_state(&"death")
		position.y = -minf(1.0, maxf(0.0, _dead_time - 1.6)) * 0.8
		if _dead_time > 3.0:
			queue_free()
		return
	match mob.anim_state:
		&"cast":
			model.play_state(&"attack", 0.55)
		&"run":
			model.play_state(&"run", mob.move_speed / 3.2)
		&"attack":
			if mob.swing_left > _last_swing + 0.01:
				model.play_state(&"attack", model.clip_length(&"attack") / 0.9, true)
		_:
			if mob.swing_left <= 0.0:
				model.play_state(&"idle")
	_last_swing = mob.swing_left


func _animate_placeholder() -> void:
	if _static_model:
		# Scurry: fast bob, side wiggle and nose dip; lunge forward on bite.
		var run := mob.anim_state == &"run"
		_body.position.y = absf(sin(_time * 22.0)) * (0.05 if run else 0.01)
		_body.rotation.y = sin(_time * 18.0) * (0.12 if run else 0.02)
		_body.rotation.x = 0.08 if run else 0.0
		_body.position.z = sin((1.0 - mob.swing_left / 0.4) * PI) * 0.3 if mob.anim_state == &"attack" else 0.0
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
