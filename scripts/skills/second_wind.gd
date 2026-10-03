extends Skill
## Second Wind (GDD 8.2 #11): once per floor (twice at level 5) lethal damage leaves the hero at
## 30..50 % HP with 2..3 s of invulnerability. Does not save from the flood.

var uses_left: int = 1
var speed_left: float = 0.0


func _on_level_changed() -> void:
	uses_left = int(p("uses", 1))


func on_floor_start() -> void:
	uses_left = int(p("uses", 1))


func on_lethal() -> bool:
	if uses_left <= 0:
		return false
	uses_left -= 1
	hero.hp = hero.max_hp * float(p("hp_pct"))
	hero.grant_invulnerability(float(p("invulnerable")))
	speed_left = float(p("speed_time", 0.0))
	hero.world.second_wind.emit()
	return true


func tick(dt: float) -> void:
	super.tick(dt)
	speed_left = maxf(0.0, speed_left - dt)


func stat_bonus() -> Dictionary:
	if speed_left > 0.0:
		return {"flat": {}, "pct": {&"move_speed": float(p("move_speed_pct", 0.0))}}
	return {}
