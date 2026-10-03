extends Skill
## Bleed (GDD 8.2 #7): auto-attacks and active skills apply 15 % ATK/s for 3 s, up to 3 stacks.
## Level 5: an enemy that dies bleeding explodes for 100 % ATK in 2 m, also applying bleed.


func on_hit(target: Combatant, _taken: float, _ctx: Dictionary) -> void:
	if not target.alive:
		return
	var dps := hero.stats.get_stat(&"atk") * float(p("dps_coef"))
	target.statuses.apply_bleed(dps, float(p("duration")), int(p("max_stacks")), hero)


func on_kill(target: Combatant) -> void:
	if p("explode_coef", 0.0) <= 0.0 or not target.statuses.has(&"bleed"):
		return
	var shape := {"type": "circle", "radius": float(p("explode_radius"))}
	for e in Shapes.query(hero.world, shape, target.pos, hero.facing, Entity.Team.ENEMY):
		hero.deal_damage(e, float(p("explode_coef")), {"skill": id, "explosion": true})
	hero.world.bleed_exploded.emit(target.pos)
