class_name CardDeck
extends RefCounted
## Builds card offers (GDD 9.4): weighted, 3 different cards, at least one skill upgrade if any
## skill is below level 5, at least one stat card (Respite counts as a stat card, decision D18).
## Rarity is rolled per card (9.2); dodge cards have a fixed rarity.


static func pool(run: RunState) -> Array[Dictionary]:
	var cfg: Dictionary = DataDB.table(&"cards")
	var out: Array[Dictionary] = []
	for id: String in cfg["stats"]:
		out.append({"id": StringName(id), "kind": &"stat"})
	for id: String in cfg["time"]:
		out.append({"id": StringName(id), "kind": &"time"})
	for s in run.skills:
		if int(s["level"]) < 5:
			out.append({"id": &"skill_up", "kind": &"skill", "skill": s["id"]})
	for id: String in cfg["dodge"]:
		if run.count_card(StringName(id)) < int(cfg["dodge"][id]["max_takes"]):
			out.append({"id": StringName(id), "kind": &"dodge", "rarity": int(cfg["dodge"][id]["rarity"])})
	return out


static func offer(run: RunState, essence_fill: float, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var cfg: Dictionary = DataDB.table(&"cards")
	var weights: Dictionary = cfg["weights"]
	var candidates := pool(run)
	var chosen: Array[Dictionary] = []
	var skills := candidates.filter(func(c: Dictionary) -> bool: return c["kind"] == &"skill")
	if not skills.is_empty():
		chosen.append(_take_weighted(skills, weights, rng, candidates))
	var statlike := candidates.filter(func(c: Dictionary) -> bool: return c["kind"] in [&"stat", &"time"])
	if not statlike.is_empty():
		chosen.append(_take_weighted(statlike, weights, rng, candidates))
	while chosen.size() < int(cfg["offer_size"]) and not candidates.is_empty():
		chosen.append(_take_weighted(candidates.duplicate(), weights, rng, candidates))
	# Deterministic shuffle so the guaranteed cards are not always first.
	for i in range(chosen.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := chosen[i]
		chosen[i] = chosen[j]
		chosen[j] = tmp
	for c in chosen:
		if not c.has("rarity"):
			c["rarity"] = roll_rarity(essence_fill, rng)
	return chosen


static func roll_rarity(essence_fill: float, rng: RandomNumberGenerator) -> int:
	var r: Dictionary = DataDB.table(&"cards")["rarity"]
	var fill := clampf(essence_fill, 0.0, 1.0)
	var epic := float(r["epic_base"]) + float(r["epic_per_essence"]) * fill
	var rare := float(r["rare_base"]) + float(r["rare_per_essence"]) * fill
	var x := rng.randf()
	if x < epic:
		return 2
	if x < epic + rare:
		return 1
	return 0


## Picks one card by weight from `from`, removes it (and identical cards) from `all`.
static func _take_weighted(from: Array, weights: Dictionary, rng: RandomNumberGenerator,
		all: Array[Dictionary]) -> Dictionary:
	var total := 0.0
	for c: Dictionary in from:
		total += float(weights[String(c["kind"])])
	var x := rng.randf() * total
	var pick: Dictionary = from[from.size() - 1]
	for c: Dictionary in from:
		x -= float(weights[String(c["kind"])])
		if x <= 0.0:
			pick = c
			break
	for i in range(all.size() - 1, -1, -1):
		if all[i]["id"] == pick["id"] and all[i].get("skill", &"") == pick.get("skill", &""):
			all.remove_at(i)
	return pick.duplicate()
