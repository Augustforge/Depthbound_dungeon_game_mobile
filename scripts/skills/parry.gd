extends Skill
## Parry (GDD 8.2 #4): 1 s stance blocking all damage; a parried hit triggers a 300 % counter on
## the attacker and everyone within 2 m. Never used by AUTO (author decision 15).

var stance_left: float = 0.0


func cast() -> bool:
	stance_left = float(p("duration"))
	hero.play_skill_anim(&"parry", float(p("duration")))
	return true


func tick(dt: float) -> void:
	super.tick(dt)
	stance_left = maxf(0.0, stance_left - dt)


func active_stance() -> bool:
	return stance_left > 0.0


## A strike reached the hero during the stance. Returns true if it was parried.
func parried(source: Combatant, parryable: bool) -> bool:
	if stance_left <= 0.0 or not parryable:
		return false
	var shape := {"type": "circle", "radius": float(p("radius"))}
	var targets := Shapes.query(hero.world, shape, hero.pos, hero.facing, Entity.Team.ENEMY)
	if source != null and source.alive and not targets.has(source):
		targets.append(source)
	for e in targets:
		hero.deal_damage(e, float(p("atk_coef")), {"skill": id})
		if p("stun", 0.0) > 0.0 and e == source:
			e.statuses.apply(&"stun", float(p("stun")))
	if p("halve_cooldowns", false):
		for s in hero.actives:
			if s != self and s != null:
				s.cooldown_left *= 0.5
	hero.world.parried.emit(source)
	return true
