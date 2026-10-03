class_name Coin
extends Entity
## Gold coin (GDD 12.3): drops on the floor, flies to the hero inside the pickup radius.

var value: int = 1
var _flying: bool = false


func _init() -> void:
	team = Team.NEUTRAL
	radius = 0.1


func tick(dt: float) -> void:
	var hero := world.hero
	if not hero.alive:
		return
	var d := hero.pos.distance_to(pos)
	if d <= hero.stats.get_stat(&"pickup_radius"):
		_flying = true
	if _flying:
		if d < 0.35:
			alive = false
			world.collect_gold(value)
			world.remove_entity(self)
			return
		pos = pos.move_toward(hero.pos, dt * 12.0)
