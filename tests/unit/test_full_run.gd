extends TestCase
## The whole MVP path at the logic level (GDD 20.1): a fresh profile, floors 1-10 played by the
## bot as a typical player, cards and boss skills picked, better gear put on, retries after
## deaths, then the final chest. Nothing is simulated: the hero is only what the run gave it.


func test_bot_plays_the_whole_dungeon() -> void:
	var p := Profile.create(1)
	Progress.start_run(p, 2024)
	var deaths := 0
	var log := PackedStringArray()
	var guard := 0
	# After a death a person plays the floor more carefully: straight to the goal.
	var careful := false
	while p.run != null and p.run.floor_index <= GameState.LAST_FLOOR and guard < 40:
		guard += 1
		var idx := p.run.floor_index
		var grid := FloorGrid.load_floor(GameState.floor_path(idx))
		var w := World.new()
		_owned.append(w)
		w.setup(grid, RngStreams.new(p.run.run_seed), idx, float(grid.data.get("time_limit", 150)), p.run,
			p.equipped_items())
		var r := Bot.new(w, Bot.Mode.RUSH if careful else Bot.Mode.PLAYER).run(400.0)
		if not r["completed"]:
			deaths += 1
			log.append("F%d died (%s)%s" % [idx, "drowned" if w.timer.drowned() else "fell", " rushing" if careful else ""])
			Progress.retry_floor(p)
			careful = true
			# Stuck: off to the camp to spend the gold at Ulm's.
			var bought := _shop(p)
			if bought > 0:
				log.append("    bought %d items at Ulm's, %d gold left" % [bought, p.gold])
			continue
		careful = false
		var res := Progress.complete_floor(p, w.result())
		log.append("F%d %.0f s, %d stars, essence %d/%d, hp %d/%d, items %d" % [idx, float(res["time"]),
			int(res["stars"]), int(res["essence"]), int(res["essence_total"]), int(w.hero.hp), int(w.hero.max_hp),
			(res["loot"] as Array).size()])
		_pick_cards(p, res)
		if not String(res.get("boss", "")).is_empty():
			var reward: Dictionary = DataDB.table(&"bosses")[String(res["boss"])]["reward"]
			var pool := p.run.missing_skills(String(reward["skill_type"]))
			if not pool.is_empty():
				p.run.add_skill(pool[0])
		_equip_better(p)
		Progress.next_floor(p, GameState.LAST_FLOOR)
	for line in log:
		print("    ", line)
	assert_true(p.run != null and p.run.floor_index > GameState.LAST_FLOOR, "reached the end of floor 10")
	if p.run == null:
		return
	var out := Progress.finish_dungeon(p, GameState.LAST_FLOOR)
	print("    total %.0f s, deaths %d, chest tier %d, gold %d, bag %d" % [float(out["total_time"]), deaths,
		int(out["tier"]), p.gold, p.inventory.size()])
	assert_true(p.dungeon_completed())
	assert_true(deaths <= 6, "a typical player dies a few times, not on every floor (%d)" % deaths)


func _pick_cards(p: Profile, res: Dictionary) -> void:
	var rng := RngStreams.new(p.run.run_seed).stream("cards", int(res["floor"]))
	for i in (2 if res["double_card"] else 1):
		var offer := CardDeck.offer(p.run, float(res["essence_fill"]), rng)
		if not offer.is_empty():
			offer.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _card_value(a) > _card_value(b))
			p.run.take_card(offer[0])


func _equip_better(p: Profile) -> void:
	for it in p.inventory.duplicate():
		var worn: Item = p.equipped.get(it.slot)
		if worn == null or it.score() > worn.score():
			p.equip(it)


## Buys the best affordable upgrades from Ulm, refreshing his stock once for crystals.
func _shop(p: Profile) -> int:
	var bought := 0
	for round in 2:
		var stock := p.merchant_stock.duplicate()
		stock.sort_custom(func(a: Item, b: Item) -> bool: return a.score() / a.price() > b.score() / b.price())
		for it: Item in stock:
			var worn: Item = p.equipped.get(it.slot)
			if p.can_buy(it) and (worn == null or it.score() > worn.score()):
				p.buy(it)
				p.equip(it)
				bought += 1
		if not p.paid_refresh():
			break
	return bought


## How a sensible player rates a card: survival and damage first.
static func _card_value(c: Dictionary) -> float:
	var base := {&"vitality": 10.0, &"sharpness": 9.0, &"bloodthirst": 8.0, &"tempering": 7.0, &"quick_hand": 7.0,
		&"skill_up": 6.0, &"second_roll": 6.0, &"precision": 5.0, &"cruelty": 4.0, &"agility": 4.0, &"riposte": 4.0,
		&"respite": 3.0, &"focus": 3.0, &"light_step": 2.0, &"greed": 1.0}
	return float(base.get(c["id"], 2.0)) + 3.0 * int(c["rarity"])
