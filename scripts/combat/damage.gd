class_name Damage
extends RefCounted
## Damage formula (GDD 6.3):
##   damage = ATK * K * crit * spread * 100 / (100 + target armor) * other multipliers

const SPREAD_MIN := 0.95
const SPREAD_MAX := 1.05

var amount: float = 0.0
var crit: bool = false


static func armor_factor(armor: float) -> float:
	return 100.0 / (100.0 + maxf(armor, 0.0))


static func roll(atk: float, coef: float, crit_chance: float, crit_damage: float, target_armor: float,
		rng: RandomNumberGenerator, multiplier: float = 1.0) -> Damage:
	var d := Damage.new()
	d.crit = rng.randf() < crit_chance
	var spread := rng.randf_range(SPREAD_MIN, SPREAD_MAX)
	d.amount = atk * coef * (crit_damage if d.crit else 1.0) * spread * armor_factor(target_armor) * multiplier
	return d


## Enemy scaling by floor (GDD 6.4).
static func mob_hp(base_hp: float, floor_index: int) -> float:
	return base_hp * (1.0 + 0.12 * (floor_index - 1))


static func mob_damage(base_damage: float, floor_index: int) -> float:
	return base_damage * (1.0 + 0.07 * (floor_index - 1))
