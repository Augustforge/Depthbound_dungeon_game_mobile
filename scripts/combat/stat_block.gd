class_name StatBlock
extends RefCounted
## Final stats recomputed from scratch from all sources (GDD 6.2):
##   final = (base + flat bonuses) * (1 + sum of percent bonuses), then caps.
## Sources are dictionaries: {"flat": {stat: value}, "pct": {stat: value}}.

const STATS: Array[StringName] = [
	&"max_hp", &"atk", &"attack_speed", &"attack_range", &"move_speed", &"armor",
	&"crit_chance", &"crit_damage", &"lifesteal", &"cdr", &"pickup_radius",
]

var base: Dictionary = {}
var caps: Dictionary = {}
## source id -> {"flat": {}, "pct": {}}
var sources: Dictionary = {}
var _final: Dictionary = {}


func _init(base_stats: Dictionary = {}, stat_caps: Dictionary = {}) -> void:
	for s in STATS:
		base[s] = float(base_stats.get(String(s), 0.0))
	caps = stat_caps
	recompute()


func set_source(id: StringName, flat: Dictionary = {}, pct: Dictionary = {}) -> void:
	sources[id] = {"flat": flat, "pct": pct}
	recompute()


func remove_source(id: StringName) -> void:
	sources.erase(id)
	recompute()


func get_stat(stat: StringName) -> float:
	return _final.get(stat, 0.0)


func recompute() -> void:
	for s in STATS:
		var flat := 0.0
		var pct := 0.0
		for src: Dictionary in sources.values():
			flat += float(src["flat"].get(s, 0.0))
			pct += float(src["pct"].get(s, 0.0))
		_final[s] = (base[s] + flat) * (1.0 + pct)
	_apply_caps()


## Attack interval in seconds, respecting the minimum interval cap.
func attack_interval() -> float:
	var speed := maxf(get_stat(&"attack_speed"), 0.01)
	return maxf(1.0 / speed, float(caps.get("attack_interval_min", 0.0)))


func _apply_caps() -> void:
	var pairs := {
		&"move_speed": "move_speed_max",
		&"crit_chance": "crit_chance_max",
		&"lifesteal": "lifesteal_max",
		&"cdr": "cdr_max",
	}
	for stat: StringName in pairs:
		var key: String = pairs[stat]
		if caps.has(key):
			_final[stat] = minf(_final[stat], float(caps[key]))
