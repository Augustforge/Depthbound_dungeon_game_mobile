extends Skill
## Battle Cry (GDD 8.2 #6): +30 % damage, +20 % attack speed, +15 % move speed for 6 s.
## Level 3 stuns enemies within 4 m; level 5 adds 15 % lifesteal while active.

var buff_left: float = 0.0


func cast() -> bool:
	buff_left = float(p("duration"))
	hero.play_skill_anim(&"battle_cry", 0.8)
	if p("stun_radius", 0.0) > 0.0:
		var shape := {"type": "circle", "radius": float(p("stun_radius"))}
		for e in Shapes.query(hero.world, shape, hero.pos, hero.facing, Entity.Team.ENEMY):
			e.statuses.apply(&"stun", float(p("stun")))
	return true


func tick(dt: float) -> void:
	super.tick(dt)
	buff_left = maxf(0.0, buff_left - dt)


func stat_bonus() -> Dictionary:
	if buff_left <= 0.0:
		return {}
	var pct := {&"atk": float(p("atk_pct")), &"attack_speed": float(p("attack_speed_pct")),
		&"move_speed": float(p("move_speed_pct"))}
	var flat := {}
	if p("lifesteal", 0.0) > 0.0:
		flat[&"lifesteal"] = float(p("lifesteal"))
	return {"flat": flat, "pct": pct}


func auto_wants() -> bool:
	var aggro := 0
	for e in hero.world.entities:
		if e is Mob and e.alive and e.state != Mob.State.IDLE and e.state != Mob.State.RETURN:
			aggro += 1
			if (e.elite or e.def_id in [&"warden_grum", &"executioner_morten"]) and hero.pos.distance_to(e.pos) < 8.0:
				return true
	return aggro >= int(rules().get("min_aggro", 4))
