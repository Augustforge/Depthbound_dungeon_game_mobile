extends Skill
## Cleave (GDD 8.2 #1): cone strike; level 5 sends a blade wave forward.


func cast() -> bool:
	var shape: Dictionary = p("shape")
	var dir := aim_dir(float(shape["radius"]))
	hero.facing = dir
	hero.play_skill_anim(&"cleave", 0.45)
	for e in Shapes.query(hero.world, shape, hero.pos, dir, Entity.Team.ENEMY):
		hero.deal_damage(e, float(p("atk_coef")), {"skill": id})
	if p("wave", false):
		var w := Projectile.new()
		w.kind = &"wave"
		w.pos = hero.pos
		w.dir = dir
		w.speed = 14.0
		w.max_range = float(p("wave_range"))
		w.width = float(p("wave_width"))
		w.coef = float(p("wave_coef"))
		w.pierce = 99
		hero.world.add_entity(w)
		w.launch()
	return true


func auto_wants() -> bool:
	var shape: Dictionary = p("shape")
	var t := aim_target(float(shape["radius"]))
	if t == null:
		return false
	var dir := (t.pos - hero.pos).normalized()
	return Shapes.query(hero.world, shape, hero.pos, dir, Entity.Team.ENEMY).size() >= int(rules().get("min_enemies", 1))
