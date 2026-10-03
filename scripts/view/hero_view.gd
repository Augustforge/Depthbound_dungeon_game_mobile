class_name HeroView
extends Node3D
## The hero on screen: the Meshy model (art track A1) when available, otherwise a primitive placeholder.
## Reads Hero state each frame: position, facing, run, attack swings, dodge, hits, death.

const CHAR_SHADER := preload("res://shaders/character.gdshader")
const MODELS := {
	&"male": "res://assets/models/hero_m/hero_m_anims.glb",
	&"female": "res://assets/models/hero_f/hero_f.glb",
}
const CLIPS := {
	&"idle": &"Idle_02", &"run": &"Run_02", &"attack_a": &"Left_Slash", &"attack_b": &"Right_Hand_Sword_Slash",
	&"dodge": &"Roll_Dodge", &"hit": &"Hit_Reaction", &"death": &"dying_backwards",
	&"dash_strike": &"Thrust_Slash", &"whirlwind": &"Double_Blade_Spin", &"battle_cry": &"Sword_Shout",
	&"cleave": &"Charged_Slash", &"parry": &"Sword_Parry", &"throwing_blade": &"Crouch_Charge_and_Throw",
	&"interact": &"open_door",
}
const SWORD_OFFSET := Vector3(0.0, 0.08, 0.02)
const SWORD_ROTATION := Vector3(-90, 0, 0)
## Visible length of one auto-attack swing on screen.
const SWING_TIME := 0.55

var hero: Hero
var model: RiggedModel
var sword: Node3D
var _body: Node3D
var _time: float = 0.0
var _roll: float = 0.0
var _last_swing: float = 0.0
var _swing_alt: bool = false
var _hit_shown: float = 99.0
var _skill_shown: StringName = &""
var _skill_left_prev: float = 0.0


func setup(h: Hero, look: StringName = &"male") -> void:
	hero = h
	_body = Node3D.new()
	add_child(_body)
	var path: String = MODELS.get(look, "")
	if not path.is_empty() and ResourceLoader.exists(path):
		model = RiggedModel.new()
		_body.add_child(model)
		model.setup(load(path), CLIPS)
		_attach_sword()
	else:
		_build_placeholder()
	_add_shadow()


func _attach_sword() -> void:
	if model.skeleton == null:
		return
	var att := BoneAttachment3D.new()
	model.skeleton.add_child(att)
	att.bone_name = "RightHand"
	var holder := Node3D.new()
	att.add_child(holder)
	# Meshy rigs are authored in centimetres: undo the skeleton scale so the sword is in metres.
	var s := model.skeleton.global_transform.basis.get_scale()
	holder.scale = Vector3(1.0 / s.x, 1.0 / s.y, 1.0 / s.z)
	sword = SwordMesh.build()
	holder.add_child(sword)
	# The hand bone axes come from the rig; these offsets put the grip in the palm, blade forward.
	sword.position = SWORD_OFFSET
	sword.rotation_degrees = SWORD_ROTATION


func _add_shadow() -> void:
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


func _process(delta: float) -> void:
	if hero == null:
		return
	_time += delta
	position = Vector3(hero.pos.x, 0.0, hero.pos.y)
	var yaw := atan2(hero.facing.x, hero.facing.y)
	rotation.y = lerp_angle(rotation.y, yaw, minf(1.0, delta * 18.0))
	if model:
		_animate_model()
	else:
		_animate_placeholder(delta)
	VisualGlobals.set_hero_pos(global_position)


func _animate_model() -> void:
	_hit_shown += get_process_delta_time()
	model.set_flash(clampf(1.0 - hero.since_hit / 0.12, 0.0, 1.0) * 0.8)
	if not hero.alive:
		model.play_state(&"death")
		return
	if hero.anim_state == &"whirlwind":
		model.play_state(&"whirlwind", 1.6)
		return
	if hero.skill_anim_left > 0.0 and hero.anim_state != &"run":
		if _skill_shown != hero.skill_anim or hero.skill_anim_left > _skill_left_prev:
			_skill_shown = hero.skill_anim
			var len := model.clip_length(hero.skill_anim)
			model.play_state(hero.skill_anim, maxf(1.0, len / maxf(hero.skill_anim_left, 0.2)), true)
		_skill_left_prev = hero.skill_anim_left
		return
	_skill_shown = &""
	_skill_left_prev = 0.0
	match hero.anim_state:
		&"dodge", &"dash":
			model.play_state(&"dodge", model.clip_length(&"dodge") / hero.dodge_duration / 1.6)
		&"stunned":
			model.play_state(&"hit", 0.5)
		&"run":
			model.play_state(&"run", hero.move_speed * hero.speed_factor / 4.0)
		&"attack":
			if hero.attack_cooldown > _last_swing:
				_swing_alt = not _swing_alt
				var state := &"attack_a" if _swing_alt else &"attack_b"
				model.play_state(state, model.clip_length(state) / SWING_TIME, true)
			_last_swing = hero.attack_cooldown
		_:
			_last_swing = hero.attack_cooldown
			if hero.since_hit < 0.05 and _hit_shown > 0.6:
				_hit_shown = 0.0
				model.play_state(&"hit", 1.6, true)
			elif _hit_shown > 0.35:
				model.play_state(&"idle")


func _build_placeholder() -> void:
	_part(CylinderMesh, Vector3(0.11, 0.8, 0.11), Vector3(-0.11, 0.4, 0), Color(0.16, 0.14, 0.13))
	_part(CylinderMesh, Vector3(0.11, 0.8, 0.11), Vector3(0.11, 0.4, 0), Color(0.16, 0.14, 0.13))
	_part(CapsuleMesh, Vector3(0.24, 0.72, 0.2), Vector3(0, 1.12, 0), Color(0.78, 0.72, 0.6))
	_part(SphereMesh, Vector3(0.16, 0.16, 0.16), Vector3(0, 1.62, 0), Color(0.75, 0.55, 0.42))


func _part(mesh_type: Variant, size: Vector3, pos: Vector3, color: Color) -> void:
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
	mi.mesh = m
	mi.position = pos
	var mat := ShaderMaterial.new()
	mat.shader = CHAR_SHADER
	mat.set_shader_parameter(&"albedo", color)
	mi.material_override = mat
	_body.add_child(mi)


func _animate_placeholder(delta: float) -> void:
	match hero.anim_state:
		&"run":
			_body.position.y = absf(sin(_time * 11.0)) * 0.08
			_roll = 0.0
		&"dodge":
			_roll += delta * TAU / hero.dodge_duration
			_body.rotation.x = _roll
		_:
			_body.position.y = 0.0
			_body.rotation.x = 0.0
			_roll = 0.0
