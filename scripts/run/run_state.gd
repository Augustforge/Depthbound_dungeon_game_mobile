class_name RunState
extends RefCounted
## Everything that lives for one dungeon run (GDD 4, 11.1): floor, build (skills, cards),
## currencies, times. Serialisable for the floor-start snapshot.

var run_seed: int = 0
var floor_index: int = 1
## [{"id": StringName, "level": int, "card_cdr": float}]
var skills: Array[Dictionary] = []
## Taken cards: [{"id", "kind", "rarity", "skill"?}]
var cards: Array[Dictionary] = []
var gold: int = 0
var crystals: int = 0
var deaths: int = 0
## Sum of successful floor times (GDD 11.3).
var total_time: float = 0.0
## floor index (String) -> stars
var stars: Dictionary = {}
var rerolls_used_on_floor: int = 0
## A run of an already completed dungeon: chests give less (GDD 11.5).
var replay: bool = false


static func new_run(seed_value: int) -> RunState:
	var r := RunState.new()
	r.run_seed = seed_value
	for id: String in DataDB.table(&"skills"):
		var sd: Variant = DataDB.table(&"skills")[id]
		if sd is Dictionary and sd.get("start", false):
			r.skills.append({"id": StringName(id), "level": 1, "card_cdr": 0.0})
	return r


func skill_entry(id: StringName) -> Dictionary:
	for s in skills:
		if s["id"] == id:
			return s
	return {}


func add_skill(id: StringName) -> void:
	if skill_entry(id).is_empty():
		skills.append({"id": id, "level": 1, "card_cdr": 0.0})


func count_card(id: StringName) -> int:
	var n := 0
	for c in cards:
		if c["id"] == id:
			n += 1
	return n


## Applies a chosen card to the build (GDD 9.3).
func take_card(card: Dictionary) -> void:
	cards.append(card)
	if card["kind"] == &"skill":
		var s := skill_entry(card["skill"])
		var cfg: Dictionary = DataDB.table(&"cards")["skill_upgrade"]
		s["level"] = mini(5, int(s["level"]) + int(cfg["levels"][card["rarity"]]))
		if card["rarity"] == 1:
			s["card_cdr"] = float(s["card_cdr"]) + float(cfg["rare_cooldown_cut"])


## Reforge (GDD 9.5): removes a taken card and fully undoes its effect.
func remove_card(index: int) -> void:
	var card: Dictionary = cards[index]
	cards.remove_at(index)
	if card["kind"] == &"skill":
		var s := skill_entry(card["skill"])
		if s.is_empty():
			return
		var cfg: Dictionary = DataDB.table(&"cards")["skill_upgrade"]
		s["level"] = maxi(1, int(s["level"]) - int(cfg["levels"][card["rarity"]]))
		if card["rarity"] == 1:
			s["card_cdr"] = maxf(0.0, float(s["card_cdr"]) - float(cfg["rare_cooldown_cut"]))


## Skills of a type the hero does not have yet (boss reward, GDD 8.1).
func missing_skills(skill_type: String) -> Array[StringName]:
	var out: Array[StringName] = []
	for id: String in DataDB.table(&"skills"):
		var sd: Variant = DataDB.table(&"skills")[id]
		if sd is Dictionary and String(sd.get("type", "")) == skill_type and skill_entry(StringName(id)).is_empty():
			out.append(StringName(id))
	return out


## Total floor time bonus from Respite cards.
func time_bonus() -> float:
	var t := 0.0
	var cfg: Dictionary = DataDB.table(&"cards")["time"]
	for c in cards:
		if c["kind"] == &"time":
			t += float(cfg[String(c["id"])]["time_pct"][c["rarity"]])
	return t


func gold_bonus() -> float:
	var g := 0.0
	var stats_cfg: Dictionary = DataDB.table(&"cards")["stats"]
	for c in cards:
		if c["kind"] == &"stat" and stats_cfg[String(c["id"])].has("gold_pct"):
			g += float(stats_cfg[String(c["id"])]["gold_pct"][c["rarity"]])
	return g


## Stat cards as a StatBlock source: [flat, pct].
func card_bonuses() -> Array[Dictionary]:
	var flat := {}
	var pct := {}
	var stats_cfg: Dictionary = DataDB.table(&"cards")["stats"]
	for c in cards:
		if c["kind"] != &"stat":
			continue
		var cfg: Dictionary = stats_cfg[String(c["id"])]
		var v := float(cfg["values"][c["rarity"]])
		if cfg.has("pct"):
			pct[StringName(cfg["pct"])] = float(pct.get(StringName(cfg["pct"]), 0.0)) + v
		else:
			flat[StringName(cfg["flat"])] = float(flat.get(StringName(cfg["flat"]), 0.0)) + v
	return [flat, pct]


## Builds the hero for a floor from this run: skills with levels, card stat bonuses, dodge mods.
func apply_to_hero(hero: Hero) -> void:
	hero.actives.clear()
	hero.actives.resize(Hero.MAX_ACTIVES)
	hero.passives.clear()
	for s in skills:
		hero.add_skill(s["id"], int(s["level"]))
		var sk := hero.find_skill(s["id"])
		if sk:
			sk.card_cdr = float(s["card_cdr"])
	var bonuses := card_bonuses()
	hero.stats.set_source(&"cards", bonuses[0], bonuses[1])
	var dodge_cfg: Dictionary = DataDB.table(&"cards")["dodge"]
	var agility := count_card(&"agility")
	hero.dodge_cooldown = maxf(float(dodge_cfg["agility"]["cooldown_min"]),
			hero.dodge_cooldown - agility * float(dodge_cfg["agility"]["cooldown_minus"]))
	hero.dodge_max_charges += count_card(&"second_roll") * int(dodge_cfg["second_roll"]["charges_plus"])
	hero.dodge_charges = hero.dodge_max_charges
	hero.riposte = count_card(&"riposte") > 0
	hero.refresh_stats()
	hero.hp = hero.max_hp


func to_dict() -> Dictionary:
	var sk := []
	for s in skills:
		sk.append({"id": String(s["id"]), "level": s["level"], "card_cdr": s["card_cdr"]})
	var cd := []
	for c in cards:
		var e := {"id": String(c["id"]), "kind": String(c["kind"]), "rarity": c["rarity"]}
		if c.has("skill"):
			e["skill"] = String(c["skill"])
		cd.append(e)
	return {"run_seed": run_seed, "floor_index": floor_index, "skills": sk, "cards": cd, "gold": gold,
		"crystals": crystals, "deaths": deaths, "total_time": total_time, "stars": stars,
		"rerolls_used_on_floor": rerolls_used_on_floor, "replay": replay}


static func from_dict(d: Dictionary) -> RunState:
	var r := RunState.new()
	r.run_seed = int(d.get("run_seed", 0))
	r.floor_index = int(d.get("floor_index", 1))
	for s: Dictionary in d.get("skills", []):
		r.skills.append({"id": StringName(s["id"]), "level": int(s["level"]), "card_cdr": float(s["card_cdr"])})
	for c: Dictionary in d.get("cards", []):
		var e := {"id": StringName(c["id"]), "kind": StringName(c["kind"]), "rarity": int(c["rarity"])}
		if c.has("skill"):
			e["skill"] = StringName(c["skill"])
		r.cards.append(e)
	r.gold = int(d.get("gold", 0))
	r.crystals = int(d.get("crystals", 0))
	r.deaths = int(d.get("deaths", 0))
	r.total_time = float(d.get("total_time", 0.0))
	var st: Dictionary = d.get("stars", {})
	for k: String in st:
		r.stars[k] = int(st[k])
	r.rerolls_used_on_floor = int(d.get("rerolls_used_on_floor", 0))
	r.replay = bool(d.get("replay", false))
	return r
