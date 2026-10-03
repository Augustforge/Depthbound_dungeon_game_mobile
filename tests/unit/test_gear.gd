extends TestCase
## Gear, loot, profile and run progress (GDD 11, 14).


func _rng(seed_value: int = 5) -> RandomNumberGenerator:
	return RngStreams.new(seed_value).stream("test", 1)


func test_main_stat_formula() -> void:
	var it := Item.new()
	for s in 200:
		it = Loot.roll_item("relic", 7, _rng(s), &"weapon")
		if it.rarity == 2:
			break
	assert_eq(it.rarity, 2)
	assert_almost(float(it.main[&"atk"]), (6.0 + 1.0 * 7) * 1.45, 0.001, "weapon damage (base + inc x ilvl) x rare")
	assert_eq(it.affixes.size(), 2, "rare has 2 properties")


func test_armor_has_hp_and_armor() -> void:
	var it := Loot.roll_item("wood", 1, _rng(), &"armor")
	assert_true(it.main.has(&"max_hp") and it.main.has(&"armor"))


func test_affixes_do_not_repeat_and_scale() -> void:
	for s in 50:
		var it := Loot.roll_item("final_3", 10, _rng(s))
		var seen := {}
		for a in it.affixes:
			assert_false(seen.has(a["stat"]), "no repeated properties")
			seen[a["stat"]] = true
			var r: Array = DataDB.table(&"gear")["affixes"][String(a["stat"])]["range"]
			var scale := 1.0 + 0.04 * 10
			assert_true(float(a["value"]) >= float(r[0]) * scale - 1e-6 and float(a["value"]) <= float(r[1]) * scale + 1e-6)


func test_rarity_odds_follow_the_source() -> void:
	var counts := [0, 0, 0, 0, 0]
	var rng := _rng(9)
	for i in 4000:
		counts[Loot.roll_rarity("wood", rng)] += 1
	assert_almost(counts[0] / 4000.0, 0.6, 0.04, "wood: 60 % common")
	assert_eq(counts[4], 0, "wood never gives a legendary")
	for i in 200:
		assert_true(Loot.roll_rarity("boss_executioner_morten", rng) >= 2, "Morten: rare or better")


func test_rolls_are_deterministic() -> void:
	var a := Loot.roll_item("iron", 3, RngStreams.new(77).stream("chest_4_5", 3))
	var b := Loot.roll_item("iron", 3, RngStreams.new(77).stream("chest_4_5", 3))
	assert_eq(a.to_dict(), b.to_dict())


func test_item_round_trip_and_prices() -> void:
	var it := Loot.roll_item("relic", 5, _rng(3))
	var back := Item.from_dict(JSON.parse_string(JSON.stringify(it.to_dict(), "", true, true)))
	assert_eq(JSON.stringify(back.to_dict()), JSON.stringify(it.to_dict()))
	var base: int = [50, 120, 300, 750, 1500][it.rarity]
	assert_eq(it.price(), roundi(base * 1.5), "price x (1 + 0.1 x ilvl)")
	assert_eq(it.sell_price(), roundi(it.price() * 0.25))


func test_gear_changes_hero_stats() -> void:
	var w := make_world("#####\n#S.E#\n#####")
	var base_atk := w.hero.stats.get_stat(&"atk")
	var p := Profile.create(1)
	var sword := Loot.roll_item("wood", 4, _rng(), &"weapon")
	var boots := Loot.roll_item("wood", 4, _rng(2), &"boots")
	p.add_item(sword)
	p.add_item(boots)
	p.equip(sword)
	p.equip(boots)
	p.apply_gear(w.hero)
	var expected := base_atk + float(sword.stats()[&"atk"]) + float(boots.stats().get(&"atk", 0.0))
	assert_almost(w.hero.stats.get_stat(&"atk"), expected, 0.01)
	assert_true(w.hero.move_speed > 4.0, "boots: percent move speed")


func test_world_applies_gear_and_floor_time() -> void:
	var it := Item.new()
	it.slot = &"ring"
	it.main = {&"crit_chance": 0.05}
	it.affixes = [{"stat": &"floor_time", "value": 0.1}]
	var w := World.new()
	_owned.append(w)
	w.setup(FloorGrid.from_text("#####\n#S.E#\n#####"), RngStreams.new(1), 1, 100.0, RunState.new_run(1), [it])
	assert_almost(w.timer.limit, 110.0, 0.01, "floor time property")
	assert_almost(w.hero.stats.get_stat(&"crit_chance"), 0.1, 0.001, "base 5 % + ring 5 %")


func test_equip_swaps_and_inventory_limit() -> void:
	var p := Profile.create(1)
	var a := Loot.roll_item("wood", 1, _rng(1), &"helmet")
	var b := Loot.roll_item("wood", 1, _rng(2), &"helmet")
	p.add_item(a)
	p.add_item(b)
	p.equip(a)
	p.equip(b)
	assert_eq(p.equipped[&"helmet"], b)
	assert_true(p.inventory.has(a), "old helmet back in the bag")
	while not p.inventory_full():
		p.add_item(Loot.roll_item("wood", 1, _rng(p.inventory.size() + 10)))
	var gold := p.gold
	var extra := Loot.roll_item("wood", 1, _rng(99))
	assert_false(p.add_item(extra), "no room")
	assert_eq(p.gold, gold + extra.sell_price(), "a full bag sells the item to Ulm")
	assert_false(p.unequip(&"helmet"), "cannot unequip into a full bag")


func test_merchant_buy_sell_refresh() -> void:
	var p := Profile.create(42)
	assert_eq(p.merchant_stock.size(), 6)
	for it in p.merchant_stock:
		assert_true(it.rarity <= 3, "Ulm sells up to epic")
	var it := p.merchant_stock[0]
	assert_false(p.buy(it), "no gold")
	p.gold = 100000
	assert_true(p.buy(it))
	assert_eq(p.gold, 100000 - it.price())
	assert_eq(p.merchant_stock.size(), 5)
	p.sell(it)
	assert_eq(p.gold, 100000 - it.price() + it.sell_price())
	assert_false(p.paid_refresh(), "refresh needs 5 crystals")
	p.crystals = 5
	assert_true(p.paid_refresh())
	assert_eq(p.crystals, 0)
	assert_eq(p.merchant_stock.size(), 6)


func test_profile_round_trip() -> void:
	var p := Profile.create(3)
	Progress.start_run(p, 11)
	p.gold = 321
	p.crystals = 7
	p.hero_look = &"female"
	p.add_item(Loot.roll_item("iron", 2, _rng()))
	var w := Loot.roll_item("iron", 2, _rng(4), &"weapon")
	p.add_item(w)
	p.equip(w)
	p.record_floor(1, 55.5, 2)
	p.run.take_card({"id": &"sharpness", "kind": &"stat", "rarity": 1})
	var d: Dictionary = JSON.parse_string(JSON.stringify(p.to_dict(), "", true, true))
	assert_eq(int(d["version"]), Profile.VERSION)
	var q := Profile.from_dict(d)
	# Json keeps ~15 digits: compare at that precision.
	assert_eq(JSON.stringify(q.to_dict()), JSON.stringify(p.to_dict()), "same after save and load")
	assert_eq(q.run.cards.size(), 1)
	assert_eq(JSON.stringify(q.equipped[&"weapon"].to_dict()), JSON.stringify(w.to_dict()))


func test_save_file_round_trip() -> void:
	var path := "user://test_save.json"
	var p := Profile.create(8)
	Progress.start_run(p, 5)
	p.gold = 77
	assert_true(SaveManager.save_profile(p, path))
	var q := SaveManager.load_profile(path)
	assert_true(q != null)
	assert_eq(q.gold, 77)
	assert_eq(q.run.run_seed, 5)
	SaveManager.delete_save(path)
	assert_true(SaveManager.load_profile(path) == null)


func test_complete_floor_banks_everything() -> void:
	var p := Profile.create(1)
	Progress.start_run(p, 21)
	var item := Loot.roll_item("iron", 1, _rng())
	var r := Progress.complete_floor(p, {"floor": 1, "time": 61.0, "stars": 3, "gold": 40, "crystals": 1,
		"loot": [item], "boss": ""})
	assert_eq(p.gold, 40)
	assert_eq(p.crystals, 1)
	assert_true(p.inventory.has(item))
	assert_eq(p.run_phase, &"reward")
	assert_true(bool(r["new_best"]))
	assert_almost(p.run.total_time, 61.0)
	assert_eq(int(p.run.stars["1"]), 3)
	assert_false(Progress.next_floor(p, 10))
	assert_eq(p.run.floor_index, 2)
	assert_eq(p.run_phase, &"floor")


func test_boss_chest_is_deterministic() -> void:
	var a := Profile.create(1)
	Progress.start_run(a, 99)
	var ra := Progress.complete_floor(a, {"floor": 5, "time": 50.0, "stars": 3, "gold": 0, "crystals": 0,
		"loot": [], "boss": "warden_grum"})
	var b := Profile.create(2)
	Progress.start_run(b, 99)
	var rb := Progress.complete_floor(b, {"floor": 5, "time": 70.0, "stars": 2, "gold": 0, "crystals": 0,
		"loot": [], "boss": "warden_grum"})
	assert_eq((ra["loot"] as Array).size(), 2, "boss chest: 2 items")
	assert_eq((ra["loot"][0] as Item).to_dict(), (rb["loot"][0] as Item).to_dict(), "same seed, same chest")
	assert_eq(a.crystals, 5)
	assert_eq(a.gold, 300)


func test_retry_counts_a_death() -> void:
	var p := Profile.create(1)
	Progress.start_run(p, 1)
	Progress.retry_floor(p)
	Progress.retry_floor(p)
	p.run.total_time = 100.0
	assert_almost(Progress.dungeon_time(p.run), 140.0, 0.001, "+20 s per death")


func test_final_chest_tiers_and_replay() -> void:
	var p := Profile.create(1)
	Progress.start_run(p, 5)
	for i in range(1, 11):
		p.run.stars[str(i)] = 3
	p.run.total_time = 900.0
	assert_eq(Progress.chest_tier(p.run, 10), 3, "all stars: legendary chest")
	var out := Progress.finish_dungeon(p, 10)
	assert_true(bool(out["granted"]))
	assert_eq(int(out["gold"]), 3500)
	assert_eq((out["items"] as Array).size(), 4)
	assert_true(p.run == null, "the run is over")
	assert_true(p.dungeon_completed())
	# A slower replay with the same tier gives no chest; replays halve chest gold.
	Progress.start_run(p, 6)
	assert_true(p.run.replay)
	for i in range(1, 11):
		p.run.stars[str(i)] = 3
	p.run.total_time = 1200.0
	var again := Progress.finish_dungeon(p, 10)
	assert_false(bool(again["granted"]))
	Progress.start_run(p, 7)
	p.run.stars = {"1": 1}
	assert_eq(Progress.chest_tier(p.run, 10), 0, "few stars: bronze")


func test_replay_halves_chest_gold() -> void:
	var map := "######\n#S.CE#\n######"
	var gold := []
	for replay in [false, true]:
		var run := RunState.new_run(4)
		run.replay = replay
		var w := World.new()
		_owned.append(w)
		w.setup(FloorGrid.from_text(map), RngStreams.new(4), 1, 150.0, run)
		for e in w.entities:
			if e is FloorObject and e.kind == FloorObject.Kind.CHEST:
				w.open_chest(e)
		gold.append(w.gold_collected)
	assert_eq(gold[1], roundi(gold[0] * 0.5))
