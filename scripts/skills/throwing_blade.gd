extends Skill
## Throwing Blade (GDD 8.2 #5): 8 m, 200 %, pierces 3. Level 3: three blades in a 30° fan;
## level 5: blades fly back and hit again.


func cast() -> bool:
	var range_m := float(p("range"))
	var dir := aim_dir(range_m)
	hero.facing = dir
	hero.play_skill_anim(&"throwing_blade", 0.45)
	var count := int(p("count"))
	var spread := deg_to_rad(float(p("spread")))
	for i in count:
		var b := Projectile.new()
		b.pos = hero.pos
		b.dir = dir.rotated(0.0 if count == 1 else lerpf(-spread * 0.5, spread * 0.5, float(i) / (count - 1)))
		b.speed = float(p("speed"))
		b.max_range = range_m
		b.coef = float(p("atk_coef"))
		b.pierce = int(p("pierce"))
		b.returns = p("return", false)
		hero.world.add_entity(b)
		b.launch()
	return true


func auto_wants() -> bool:
	var t := hero.world.nearest_enemy(hero.pos, float(rules().get("max_range", 8.0)), hero)
	if t == null:
		return false
	var d := hero.pos.distance_to(t.pos)
	return d >= float(rules().get("min_range", 3.0)) and hero.world.grid.has_line_of_sight(hero.pos, t.pos)
