extends Skill
## Counterattack (GDD 8.2 #10): when hit, 25..35 % chance to strike back for 150..200 % ATK;
## level 5 hits everyone within 2.5 m.


func on_hero_damaged(source: Entity, _amount: float) -> void:
	if not (source is Combatant) or not source.alive:
		return
	if hero.world.rng.stream("combat", hero.world.floor_index).randf() >= float(p("chance")):
		return
	var targets: Array[Combatant] = [source as Combatant]
	if p("radius", 0.0) > 0.0:
		targets = Shapes.query(hero.world, {"type": "circle", "radius": float(p("radius"))}, hero.pos, hero.facing,
				Entity.Team.ENEMY)
	for e in targets:
		hero.deal_damage(e, float(p("atk_coef")), {"skill": id})
