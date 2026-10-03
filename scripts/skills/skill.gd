class_name Skill
extends RefCounted
## Base class for hero skills (GDD 8). Parameters come from data/skills.json: base values are
## level 1, "levels" entries override them cumulatively up to the current level.

var id: StringName
var level: int = 1
var data: Dictionary = {}
var hero: Hero
var cooldown_left: float = 0.0
var charges: int = 1
## Extra cooldown reduction from rare skill cards (-10 % each, GDD 9.3).
var card_cdr: float = 0.0
var _params: Dictionary = {}


func setup(skill_id: StringName, h: Hero, lvl: int = 1) -> void:
	id = skill_id
	hero = h
	data = DataDB.table(&"skills").get(String(skill_id), {})
	set_level(lvl)
	charges = int(p("charges", 1))


func set_level(lvl: int) -> void:
	level = clampi(lvl, 1, 5)
	_params = data.duplicate(true)
	_params.erase("levels")
	var levels: Dictionary = data.get("levels", {})
	for l in range(2, level + 1):
		var over: Dictionary = levels.get(str(l), {})
		for k: String in over:
			_params[k] = over[k]
	_on_level_changed()


func p(key: String, default: Variant = null) -> Variant:
	return _params.get(key, default)


func is_active() -> bool:
	return String(data.get("type", "")) == "active"


func max_cooldown() -> float:
	var cdr := hero.stats.get_stat(&"cdr")
	return float(p("cooldown", 0.0)) * (1.0 - cdr) * (1.0 - card_cdr)


func max_charges() -> int:
	return int(p("charges", 1))


func ready() -> bool:
	return charges > 0


## Returns true if the skill was used.
func try_cast() -> bool:
	if not ready() or not hero.statuses.can_act() or hero.is_dodging():
		return false
	if not cast():
		return false
	charges -= 1
	if cooldown_left <= 0.0:
		cooldown_left = max_cooldown()
	return true


func tick(dt: float) -> void:
	if charges < max_charges():
		cooldown_left -= dt
		if cooldown_left <= 0.0:
			charges += 1
			cooldown_left = max_cooldown() if charges < max_charges() else 0.0


## 0..1 for the HUD ring: 1 = ready.
func ready_ratio() -> float:
	if charges > 0:
		return 1.0
	var m := max_cooldown()
	return 1.0 - cooldown_left / m if m > 0.0 else 1.0


func reduce_cooldown(seconds: float) -> void:
	if charges < max_charges():
		cooldown_left = maxf(0.01, cooldown_left - seconds)


## Direction to aim: the current/priority target or nearest enemy within reach, else facing.
func aim_dir(reach: float) -> Vector2:
	var t := aim_target(reach)
	return (t.pos - hero.pos).normalized() if t != null else hero.facing


func aim_target(reach: float) -> Combatant:
	if hero.priority_target != null and hero.priority_target.alive \
			and hero.pos.distance_to(hero.priority_target.pos) <= reach + hero.priority_target.radius:
		return hero.priority_target
	return hero.world.nearest_enemy(hero.pos, reach, hero)


func rules() -> Dictionary:
	return DataDB.table(&"skills").get("auto_rules", {}).get(String(id), {})


# --- Overridables ---------------------------------------------------------------------------

func cast() -> bool:
	return false


## AUTO mode (GDD 8.3): should the skill fire now?
func auto_wants() -> bool:
	return false


func _on_level_changed() -> void:
	pass


## Passive hooks.
func on_hit(_target: Combatant, _taken: float, _ctx: Dictionary) -> void:
	pass


func on_kill(_target: Combatant) -> void:
	pass


func on_auto_attack(_ctx: Dictionary) -> void:
	pass


func on_hero_damaged(_source: Entity, _amount: float) -> void:
	pass


## Return true to prevent death (Second Wind).
func on_lethal() -> bool:
	return false


func on_floor_start() -> void:
	pass


## Skill-specific queries with neutral defaults (overridden by the skills that have them).
func active_stance() -> bool:
	return false


func spinning() -> bool:
	return false


func parried(_source: Combatant, _parryable: bool) -> bool:
	return false


func overheal_shield_cap() -> float:
	return 0.0


func dash_step(_from: Vector2, _to: Vector2) -> void:
	pass


## Flat/percent stat bonuses this skill gives right now: {"flat": {}, "pct": {}} or {}.
func stat_bonus() -> Dictionary:
	return {}
