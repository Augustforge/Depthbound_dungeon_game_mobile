extends Skill
## Dash Strike (GDD 8.2 #2): 5 m dash towards the target or the move direction, invulnerable,
## damages everyone on the path. Level 3: 2 charges; level 5: a kill restores a charge.

var _hit: Dictionary = {}
var _killed: bool = false


func cast() -> bool:
	var dist := float(p("distance"))
	var dir := hero.input.move.normalized() if hero.input.move.length() > 0.2 else aim_dir(dist + 1.0)
	_hit.clear()
	_killed = false
	hero.start_dash(dir, dist, float(p("duration")), self)
	hero.play_skill_anim(&"dash_strike", float(p("duration")) + 0.2)
	return true


## Called by the hero every dash step with the swept segment.
func dash_step(from: Vector2, to: Vector2) -> void:
	var shape := {"type": "line", "length": from.distance_to(to) + 0.01, "width": float(p("width"))}
	var dir := (to - from).normalized() if to != from else hero.facing
	for e in Shapes.query(hero.world, shape, from, dir, Entity.Team.ENEMY):
		if _hit.has(e.id):
			continue
		_hit[e.id] = true
		hero.deal_damage(e, float(p("atk_coef")), {"skill": id})
		if not e.alive and p("kill_reset", false) and not _killed:
			_killed = true
			charges = mini(charges + 1, max_charges())


func auto_wants() -> bool:
	var t := hero.current_target if hero.current_target != null else hero.world.nearest_enemy(hero.pos, 6.0, hero)
	if t == null:
		return false
	var d := hero.pos.distance_to(t.pos)
	return d >= float(rules().get("min_range", 3.0)) and d <= float(rules().get("max_range", 5.0))
