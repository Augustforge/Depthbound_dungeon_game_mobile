class_name SharedAnims
extends RefCounted
## One animation library for every Meshy character: all Meshy rigs share bone names, so clips bought
## once on the hero rig play on mobs and bosses too (saves credits). Clips: "shared/<Name>".

const SOURCES: Array[String] = [
	"res://assets/models/hero_m/hero_m_anims.glb",
	"res://assets/models/shared/anims_pack2.glb",
	"res://assets/models/shared/anims_pack3.glb",
]
const LOOPING: Array[String] = ["Idle_02", "Run_02", "Monster_Walk", "Injured_Walk", "RunFast", "Axe_Spin_Attack"]

static var _library: AnimationLibrary


static func library() -> AnimationLibrary:
	if _library != null:
		return _library
	_library = AnimationLibrary.new()
	for path in SOURCES:
		if not ResourceLoader.exists(path):
			continue
		var inst: Node = (load(path) as PackedScene).instantiate()
		var player := RiggedModel._find(inst, "AnimationPlayer") as AnimationPlayer
		if player:
			for anim_name in player.get_animation_list():
				var anim := player.get_animation(anim_name).duplicate() as Animation
				RiggedModel._strip_root_motion(anim, "Hips")
				if String(anim_name) in LOOPING:
					anim.loop_mode = Animation.LOOP_LINEAR
				_library.add_animation(StringName(String(anim_name).get_file()), anim)
		inst.free()
	return _library
