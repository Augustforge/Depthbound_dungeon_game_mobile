class_name ItemText
extends RefCounted
## How gear reads in the UI: name (slot) in rarity colour, rarity and level, stat lines, and the
## difference against another item (green / red arrows, GDD 14.3).

const RARITY_COLORS: Array[Color] = [
	Color(0.85, 0.84, 0.8), Color(0.45, 0.85, 0.4), Color(0.4, 0.65, 1.0), Color(0.78, 0.45, 1.0), Color(1.0, 0.6, 0.2),
]
## Stats shown as percents (stored as fractions).
const FRACTION_STATS: Array[StringName] = [
	&"attack_speed", &"move_speed", &"crit_chance", &"crit_damage", &"lifesteal", &"cdr", &"floor_time",
]
const ORDER: Array[StringName] = [
	&"atk", &"max_hp", &"armor", &"attack_speed", &"move_speed", &"crit_chance", &"crit_damage", &"lifesteal",
	&"cdr", &"floor_time",
]


static func color(it: Item) -> Color:
	return RARITY_COLORS[clampi(it.rarity, 0, 4)]


static func title(it: Item) -> String:
	return TranslationServer.translate("SLOT_" + String(it.slot).to_upper())


static func subtitle(it: Item) -> String:
	return "%s · %s" % [TranslationServer.translate("ITEM_RARITY_%d" % it.rarity),
		TranslationServer.translate("ITEM_LEVEL") % it.ilvl]


static func value_text(stat: StringName, v: float) -> String:
	if stat in FRACTION_STATS:
		var pct := v * 100.0
		return ("%.1f%%" % pct).replace(".0%", "%")
	return str(roundi(v))


static func stat_line(stat: StringName, v: float) -> String:
	return TranslationServer.translate("STAT_" + String(stat)) % value_text(stat, v)


## Main stats first, then properties: [{"text": String, "main": bool}]
static func lines(it: Item) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for stat in ORDER:
		if it.main.has(stat):
			out.append({"text": stat_line(stat, float(it.main[stat])), "main": true})
	for a in it.affixes:
		out.append({"text": stat_line(a["stat"], float(a["value"])), "main": false})
	return out


## Stat differences if `it` replaced `other` (null = empty slot): [{"text", "delta"}], delta > 0 better.
static func compare(it: Item, other: Item) -> Array[Dictionary]:
	var a := it.stats()
	var b := other.stats() if other != null else {}
	var out: Array[Dictionary] = []
	for stat in ORDER:
		var d := float(a.get(stat, 0.0)) - float(b.get(stat, 0.0))
		if absf(d) < 0.0005:
			continue
		var arrow := "▲" if d > 0.0 else "▼"
		out.append({"text": "%s %s" % [arrow, TranslationServer.translate("STAT_" + String(stat)).replace("+", "")
			% value_text(stat, absf(d))], "delta": d})
	return out
