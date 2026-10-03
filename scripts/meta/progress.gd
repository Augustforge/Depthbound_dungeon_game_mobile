class_name Progress
extends RefCounted
## The rules that move a run through the dungeon (GDD 4, 11, 14): banking a finished floor,
## the boss chest, the next floor, the final chest. Pure functions over a Profile, so they are
## tested without scenes and saving stays a separate step (GameState).

const DEATH_PENALTY := 20.0


static func start_run(p: Profile, seed_value: int) -> void:
	p.run = RunState.new_run(seed_value)
	p.run.replay = p.dungeon_completed()
	p.run_phase = &"floor"
	p.pending_result = {}


## Called once when a floor is completed, before its summary (GDD 11.1): banks gold, crystals and
## items, rolls the boss chest, updates records and switches the run to the reward phase.
## Returns the result extended with what was granted.
static func complete_floor(p: Profile, result: Dictionary) -> Dictionary:
	var run := p.run
	var r := result.duplicate()
	var index := int(r["floor"])
	run.total_time += float(r["time"])
	run.stars[str(index)] = maxi(int(run.stars.get(str(index), 0)), int(r["stars"]))
	var items: Array[Item] = []
	for it: Variant in r.get("loot", []):
		if it is Item:
			items.append(it)
	var gold := int(r["gold"])
	var crystals := int(r["crystals"])
	var boss := String(r.get("boss", ""))
	if not boss.is_empty():
		var reward: Dictionary = DataDB.table(&"bosses")[boss]["reward"]
		var rng := RngStreams.new(run.run_seed).stream("boss_chest", index)
		var mult := float(Item.cfg()["replay"]["gold_mult"]) if run.replay else 1.0
		r["boss_gold"] = roundi(float(reward["gold"]) * mult)
		r["boss_crystals"] = int(reward["crystals"])
		gold += int(r["boss_gold"])
		crystals += int(r["boss_crystals"])
		for i in int(reward["items"]):
			items.append(Loot.roll_item("boss_" + boss, index, rng))
	run.gold += gold
	run.crystals += crystals
	p.gold += gold
	p.crystals += crystals
	var sold := 0
	for it in items:
		if not p.add_item(it):
			sold += 1
	r["loot"] = items
	r["auto_sold"] = sold
	r["gold_total"] = gold
	r["crystals_total"] = crystals
	r["new_best"] = p.record_floor(index, float(r["time"]), int(r["stars"]))
	r["best_time"] = float(p.floor_record(index)["time"])
	p.best_floor = maxi(p.best_floor, index)
	p.run_phase = &"reward"
	p.pending_result = r
	return r


## After the summary / boss reward: on to the next floor. Returns true when the dungeon is done.
static func next_floor(p: Profile, last_floor: int) -> bool:
	p.run.floor_index += 1
	p.run.rerolls_used_on_floor = 0
	p.run_phase = &"floor"
	p.pending_result = {}
	p.best_floor = maxi(p.best_floor, mini(p.run.floor_index, last_floor))
	return p.run.floor_index > last_floor


## Floor retry after death (GDD 11.2, 11.3): the floor-start snapshot plus one death.
static func retry_floor(p: Profile) -> void:
	p.run.deaths += 1
	p.run_phase = &"floor"
	p.pending_result = {}


static func dungeon_time(run: RunState) -> float:
	return run.total_time + DEATH_PENALTY * run.deaths


## Share of stars over floors 1..last_floor -> chest tier 0 bronze .. 3 legendary (GDD 11.4).
static func chest_tier(run: RunState, last_floor: int) -> int:
	var got := 0
	for i in range(1, last_floor + 1):
		got += int(run.stars.get(str(i), 0))
	var share := float(got) / float(3 * last_floor)
	var tier := 0
	for t: Variant in Item.cfg()["final_chest"]["thresholds"]:
		if share >= float(t):
			tier += 1
	return tier


## The final chest and the dungeon records (GDD 11.4, 11.5). Ends the run.
## On a replay the chest is given only for a better total time or a higher tier.
static func finish_dungeon(p: Profile, last_floor: int) -> Dictionary:
	var run := p.run
	var rec := p.dungeon_record()
	var total := dungeon_time(run)
	var tier := chest_tier(run, last_floor)
	var better_time: bool = not rec["completed"] or total < float(rec["best_total"])
	var better_tier: bool = tier > int(rec["best_tier"])
	var granted: bool = not rec["completed"] or better_time or better_tier
	var cfg: Dictionary = Item.cfg()["final_chest"]
	var out := {"total_time": total, "deaths": run.deaths, "tier": tier, "granted": granted,
		"new_record": better_time, "gold": 0, "crystals": 0, "items": [] as Array[Item], "auto_sold": 0}
	if granted:
		var rng := RngStreams.new(run.run_seed).stream("final_chest", last_floor)
		out["gold"] = int(cfg["gold"][tier])
		out["crystals"] = int(cfg["crystals"][tier])
		p.gold += int(out["gold"])
		p.crystals += int(out["crystals"])
		for i in int(cfg["items"][tier]):
			var it := Loot.roll_item("final_%d" % tier, last_floor, rng)
			out["items"].append(it)
			if not p.add_item(it):
				out["auto_sold"] = int(out["auto_sold"]) + 1
	if better_time:
		rec["best_total"] = total
	rec["best_tier"] = maxi(tier, int(rec["best_tier"]))
	rec["completed"] = true
	p.run = null
	p.run_phase = &"floor"
	p.pending_result = {}
	# The merchant restocks after every finished run (GDD 14.5).
	p.refresh_merchant()
	return out
