class_name RiggedModel
extends Node3D
## Wraps an imported Meshy character (GLB with skeleton + animation clips):
## swaps materials to the game's character shader, removes root motion, plays clips by game state.

const CHAR_SHADER := preload("res://shaders/character.gdshader")

var player: AnimationPlayer
var skeleton: Skeleton3D
var materials: Array[ShaderMaterial] = []
## game state -> clip name
var clips: Dictionary = {}
var _current: StringName = &""


func setup(scene: PackedScene, clip_map: Dictionary, root_bone: String = "Hips") -> void:
	var inst := scene.instantiate()
	add_child(inst)
	clips = clip_map
	player = _find(inst, "AnimationPlayer") as AnimationPlayer
	skeleton = _find(inst, "Skeleton3D") as Skeleton3D
	for mi in _all_meshes(inst):
		for i in mi.mesh.get_surface_count():
			var src := mi.get_active_material(i) as BaseMaterial3D
			var mat := ShaderMaterial.new()
			mat.shader = CHAR_SHADER
			mat.set_shader_parameter(&"albedo", Color.WHITE)
			if src and src.albedo_texture:
				mat.set_shader_parameter(&"albedo_tex", src.albedo_texture)
			mi.set_surface_override_material(i, mat)
			materials.append(mat)
	if player:
		for anim_name in player.get_animation_list():
			_strip_root_motion(player.get_animation(anim_name), root_bone)
	for loop_state in [&"idle", &"run"]:
		if clips.has(loop_state) and player and player.has_animation(clips[loop_state]):
			player.get_animation(clips[loop_state]).loop_mode = Animation.LOOP_LINEAR


## Plays the clip mapped to a game state; restart=true replays one-shot clips (attacks).
func play_state(state: StringName, speed: float = 1.0, restart: bool = false) -> void:
	if player == null or not clips.has(state):
		return
	var clip: StringName = clips[state]
	if clip == _current and not restart:
		return
	_current = clip
	player.play(clip, 0.12, speed)
	if restart:
		player.seek(0.0, true)


func clip_length(state: StringName) -> float:
	if player == null or not clips.has(state):
		return 0.0
	return player.get_animation(clips[state]).length


func set_flash(amount: float) -> void:
	for m in materials:
		m.set_shader_parameter(&"emission", amount)


## Keeps the hips over the origin horizontally: movement comes from the game logic.
static func _strip_root_motion(anim: Animation, bone: String) -> void:
	for t in anim.get_track_count():
		if anim.track_get_type(t) != Animation.TYPE_POSITION_3D:
			continue
		if not String(anim.track_get_path(t)).ends_with(":" + bone):
			continue
		if anim.track_get_key_count(t) == 0:
			continue
		var first: Vector3 = anim.track_get_key_value(t, 0)
		for k in anim.track_get_key_count(t):
			var v: Vector3 = anim.track_get_key_value(t, k)
			anim.track_set_key_value(t, k, Vector3(first.x, v.y, first.z))


static func _find(n: Node, cls: String) -> Node:
	if n.is_class(cls):
		return n
	for c in n.get_children():
		var r := _find(c, cls)
		if r:
			return r
	return null


static func _all_meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_all_meshes(c))
	return out
