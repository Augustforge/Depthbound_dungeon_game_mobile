class_name HeroStats
extends RefCounted
## The hero's final stats outside a floor (camp, pause, summary): class base + gear + the run's
## stat cards, the same sources World uses (GDD 6.2).


static func preview(p: Profile) -> StatBlock:
	var hd: Dictionary = DataDB.table(&"hero_swordsman")
	var sb := StatBlock.new(hd["stats"], hd.get("stat_caps", {}))
	var gear := Loot.gear_bonuses(p.equipped_items())
	sb.set_source(&"gear", gear[0], gear[1])
	if p.run != null:
		var cards := p.run.card_bonuses()
		sb.set_source(&"cards", cards[0], cards[1])
	return sb


## [{"name": key, "value": text}] for the stats panel.
static func lines(p: Profile) -> Array[Dictionary]:
	var sb := preview(p)
	var out: Array[Dictionary] = []
	out.append({"key": "HSTAT_max_hp", "value": str(roundi(sb.get_stat(&"max_hp")))})
	out.append({"key": "HSTAT_atk", "value": str(roundi(sb.get_stat(&"atk")))})
	out.append({"key": "HSTAT_armor", "value": str(roundi(sb.get_stat(&"armor")))})
	out.append({"key": "HSTAT_attack_speed", "value": "%.2f" % (1.0 / sb.attack_interval())})
	out.append({"key": "HSTAT_move_speed", "value": "%.1f" % sb.get_stat(&"move_speed")})
	for s: StringName in [&"crit_chance", &"crit_damage", &"lifesteal", &"cdr"]:
		out.append({"key": "HSTAT_" + String(s), "value": ItemText.value_text(s, sb.get_stat(s))})
	var ft := Loot.floor_time_bonus(p.equipped_items()) + (p.run.time_bonus() if p.run else 0.0)
	out.append({"key": "HSTAT_floor_time", "value": "+" + ItemText.value_text(&"floor_time", ft)})
	return out
