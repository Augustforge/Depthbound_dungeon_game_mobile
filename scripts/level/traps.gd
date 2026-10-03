class_name SpikeZone
extends Entity
## Spike zone (GDD 13.1): hidden 2 s (trembles the last 0.4 s), extended 1 s. Hits everyone
## standing on its cells when it extends and while extended (once per cycle). Hits mobs too.

var cells: Array[Vector2i] = []
var cycle: float = 0.0
var _hit: Dictionary = {}


func _init() -> void:
	team = Team.NEUTRAL


func cfg() -> Dictionary:
	return DataDB.table(&"floor")["spikes"]


func period() -> float:
	return float(cfg()["hidden"]) + float(cfg()["extended"])


func extended() -> bool:
	return fmod(cycle, period()) >= float(cfg()["hidden"])


func trembling() -> bool:
	var t := fmod(cycle, period())
	return t < float(cfg()["hidden"]) and t >= float(cfg()["hidden"]) - float(cfg()["tremble"])


func covers(p: Vector2, r: float) -> bool:
	for c in cells:
		var nearest := Vector2(clampf(p.x, c.x, c.x + 1.0), clampf(p.y, c.y, c.y + 1.0))
		if nearest.distance_to(p) < r * 0.6:
			return true
	return false


func tick(dt: float) -> void:
	var was := extended()
	cycle += dt
	if not extended():
		if was:
			_hit.clear()
		return
	for e in world.entities:
		if not (e is Combatant) or not e.alive or e.team == Team.NEUTRAL or _hit.has(e.id):
			continue
		if covers(e.pos, e.radius):
			_hit[e.id] = true
			var dmg := Damage.mob_damage(float(cfg()["damage"]), world.floor_index)
			(e as Combatant).take_damage(dmg * Damage.armor_factor(e.armor), false, self)
