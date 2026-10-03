class_name SkillDB
extends RefCounted
## Creates skill objects by id.

const SCRIPTS := {
	&"cleave": preload("res://scripts/skills/cleave.gd"),
	&"dash_strike": preload("res://scripts/skills/dash_strike.gd"),
	&"whirlwind": preload("res://scripts/skills/whirlwind.gd"),
	&"parry": preload("res://scripts/skills/parry.gd"),
	&"throwing_blade": preload("res://scripts/skills/throwing_blade.gd"),
	&"battle_cry": preload("res://scripts/skills/battle_cry.gd"),
	&"bleed": preload("res://scripts/skills/bleed.gd"),
	&"blade_master": preload("res://scripts/skills/blade_master.gd"),
	&"lifesteal_passive": preload("res://scripts/skills/lifesteal_passive.gd"),
	&"counterattack": preload("res://scripts/skills/counterattack.gd"),
	&"second_wind": preload("res://scripts/skills/second_wind.gd"),
	&"fury": preload("res://scripts/skills/fury.gd"),
}


static func create(skill_id: StringName, hero: Hero, level: int = 1) -> Skill:
	var s: Skill = SCRIPTS[skill_id].new()
	s.setup(skill_id, hero, level)
	return s


static func actives() -> Array[StringName]:
	var out: Array[StringName] = []
	for k: StringName in SCRIPTS:
		if String(DataDB.table(&"skills")[String(k)]["type"]) == "active":
			out.append(k)
	return out


static func passives() -> Array[StringName]:
	var out: Array[StringName] = []
	for k: StringName in SCRIPTS:
		if String(DataDB.table(&"skills")[String(k)]["type"]) == "passive":
			out.append(k)
	return out
