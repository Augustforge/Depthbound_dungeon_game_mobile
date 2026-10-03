class_name Loot
extends RefCounted
## Gear rolls (GDD 14.2, 14.3). Every roll takes a RandomNumberGenerator from RngStreams, so the
## same seed, floor and roll order always give the same items (GDD 11.1).


static func roll_rarity(source: String, rng: RandomNumberGenerator) -> int:
	var weights: Array = Item.cfg()["rarity_by_source"].get(source, [100, 0, 0, 0, 0])
	var total := 0.0
	for w: Variant in weights:
		total += float(w)
	var roll := rng.randf() * total
	for i in weights.size():
		roll -= float(weights[i])
		if roll < 0.0:
			return i
	return 0


static func roll_item(source: String, ilvl: int, rng: RandomNumberGenerator, slot: StringName = &"") -> Item:
	var cfg := Item.cfg()
	var it := Item.new()
	it.uid = rng.randi() & 0x7fffffff
	var slots: Array = cfg["slots"]
	it.slot = slot if not String(slot).is_empty() else StringName(slots[rng.randi_range(0, slots.size() - 1)])
	it.rarity = roll_rarity(source, rng)
	it.ilvl = maxi(1, ilvl)
	var mult := float(cfg["rarity_mult"][it.rarity])
	var mains: Dictionary = cfg["main_stats"][String(it.slot)]
	for stat: String in mains:
		var base_inc: Array = mains[stat]
		it.main[StringName(stat)] = (float(base_inc[0]) + float(base_inc[1]) * it.ilvl) * mult
	var pool: Dictionary = (cfg["affixes"] as Dictionary).duplicate()
	var scale := 1.0 + float(cfg["affix_ilvl_scale"]) * it.ilvl
	for i in int(cfg["affix_count"][it.rarity]):
		var stat := _weighted_key(pool, rng)
		if stat.is_empty():
			break
		var r: Array = pool[stat]["range"]
		pool.erase(stat)
		it.affixes.append({"stat": StringName(stat), "value": rng.randf_range(float(r[0]), float(r[1])) * scale})
	return it


static func _weighted_key(pool: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for k: String in pool:
		total += float(pool[k]["weight"])
	var roll := rng.randf() * total
	for k: String in pool:
		roll -= float(pool[k]["weight"])
		if roll < 0.0:
			return k
	return ""


## Sum of the stats of equipped items as StatBlock sources: [flat, pct].
static func gear_bonuses(items: Array) -> Array[Dictionary]:
	var flat := {}
	var pct := {}
	for it: Item in items:
		if it == null:
			continue
		var s := it.stats()
		for k: StringName in s:
			if k == &"floor_time":
				continue
			var target := pct if Item.is_pct(k) else flat
			target[k] = float(target.get(k, 0.0)) + float(s[k])
	return [flat, pct]


static func floor_time_bonus(items: Array) -> float:
	var t := 0.0
	for it: Item in items:
		if it != null:
			t += float(it.stats().get(&"floor_time", 0.0))
	return t
