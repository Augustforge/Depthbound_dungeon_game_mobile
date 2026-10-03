extends Skill
## Whirlwind (GDD 8.2 #3): spin for 2.5 s hitting around every 0.25 s, move at 70 %.
## Level 3 pulls enemies in at the start; level 5 reduces damage taken by 40 % while spinning.

var spin_left: float = 0.0
var _tick_left: float = 0.0


func cast() -> bool:
	spin_left = float(p("duration"))
	_tick_left = 0.0
	if p("pull_radius", 0.0) > 0.0:
		var shape := {"type": "circle", "radius": float(p("pull_radius"))}
		for e in Shapes.query(hero.world, shape, hero.pos, hero.facing, Entity.Team.ENEMY):
			var to_hero := hero.pos - e.pos
			var dist := maxf(0.0, to_hero.length() - e.radius - hero.radius - 0.3)
			e.statuses.push(to_hero.normalized() * dist / 0.3, 0.3)
	return true


func spinning() -> bool:
	return spin_left > 0.0


func tick(dt: float) -> void:
	super.tick(dt)
	if spin_left <= 0.0:
		return
	spin_left -= dt
	hero.damage_taken_mult = float(p("damage_taken", 1.0)) if spin_left > 0.0 else 1.0
	_tick_left -= dt
	if _tick_left <= 0.0:
		_tick_left += float(p("tick"))
		var shape := {"type": "circle", "radius": float(p("radius"))}
		for e in Shapes.query(hero.world, shape, hero.pos, hero.facing, Entity.Team.ENEMY):
			hero.deal_damage(e, float(p("atk_coef")), {"skill": id, "no_bleed_spam": true})


func auto_wants() -> bool:
	var r := float(rules().get("radius", 3.0))
	var near := Shapes.query(hero.world, {"type": "circle", "radius": r}, hero.pos, hero.facing, Entity.Team.ENEMY)
	if near.size() >= int(rules().get("min_enemies", 3)):
		return true
	for e in near:
		if e is Mob and (e.elite or e.key_holder):
			return true
	return false
