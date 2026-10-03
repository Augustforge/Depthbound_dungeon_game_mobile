extends TestCase
## Cards and run build (GDD 9).


func _rng(seed_value: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


func test_offer_has_three_distinct_with_constraints() -> void:
	var run := RunState.new_run(1)
	for seed_value in 200:
		var offer := CardDeck.offer(run, 0.5, _rng(seed_value))
		assert_eq(offer.size(), 3)
		var kinds := offer.map(func(c: Dictionary) -> StringName: return c["kind"])
		assert_true(kinds.has(&"skill"), "skill card while a skill is below 5")
		assert_true(kinds.has(&"stat") or kinds.has(&"time"), "at least one stat card")
		var keys := offer.map(func(c: Dictionary) -> String: return "%s/%s" % [c["id"], c.get("skill", "")])
		var uniq := {}
		for k in keys:
			uniq[k] = true
		assert_eq(uniq.size(), 3, "three different cards")


func test_no_skill_card_when_all_maxed() -> void:
	var run := RunState.new_run(1)
	for s in run.skills:
		s["level"] = 5
	for seed_value in 50:
		for c in CardDeck.offer(run, 0.0, _rng(seed_value)):
			assert_true(c["kind"] != &"skill")


func test_rarity_distribution() -> void:
	var rng := _rng(7)
	var counts := [0, 0, 0]
	for i in 20000:
		counts[CardDeck.roll_rarity(0.0, rng)] += 1
	assert_almost(counts[2] / 20000.0, 0.05, 0.01, "epic 5% at empty essence")
	assert_almost(counts[1] / 20000.0, 0.25, 0.015, "rare 25%")
	counts = [0, 0, 0]
	for i in 20000:
		counts[CardDeck.roll_rarity(1.0, rng)] += 1
	assert_almost(counts[2] / 20000.0, 0.10, 0.01, "epic 10% at full essence")
	assert_almost(counts[1] / 20000.0, 0.35, 0.015, "rare 35%")


func test_dodge_card_limits() -> void:
	var run := RunState.new_run(1)
	run.take_card({"id": &"second_roll", "kind": &"dodge", "rarity": 1})
	var ids := CardDeck.pool(run).map(func(c: Dictionary) -> StringName: return c["id"])
	assert_false(ids.has(&"second_roll"), "Second Roll only once")
	assert_true(ids.has(&"agility"))


func test_offers_are_deterministic() -> void:
	var run := RunState.new_run(5)
	var a := CardDeck.offer(run, 0.3, RngStreams.new(99).stream("cards", 3))
	var b := CardDeck.offer(run, 0.3, RngStreams.new(99).stream("cards", 3))
	assert_eq(str(a), str(b), "same seed and floor -> same offer")


func test_stat_cards_apply_to_hero() -> void:
	var run := RunState.new_run(1)
	run.take_card({"id": &"sharpness", "kind": &"stat", "rarity": 2})
	run.take_card({"id": &"tempering", "kind": &"stat", "rarity": 0})
	var w := make_world("#####\n#S..#\n#####")
	run.apply_to_hero(w.hero)
	assert_almost(w.hero.stats.get_stat(&"atk"), 40.0 * 1.22)
	assert_almost(w.hero.armor, 30.0)


func test_skill_card_levels_and_cdr() -> void:
	var run := RunState.new_run(1)
	run.take_card({"id": &"skill_up", "kind": &"skill", "skill": &"cleave", "rarity": 2})
	assert_eq(int(run.skill_entry(&"cleave")["level"]), 3, "epic = +2 levels")
	run.take_card({"id": &"skill_up", "kind": &"skill", "skill": &"cleave", "rarity": 1})
	assert_eq(int(run.skill_entry(&"cleave")["level"]), 4)
	assert_almost(float(run.skill_entry(&"cleave")["card_cdr"]), 0.1)
	run.take_card({"id": &"skill_up", "kind": &"skill", "skill": &"cleave", "rarity": 2})
	assert_eq(int(run.skill_entry(&"cleave")["level"]), 5, "never above 5")


func test_dodge_cards_apply() -> void:
	var run := RunState.new_run(1)
	run.take_card({"id": &"agility", "kind": &"dodge", "rarity": 0})
	run.take_card({"id": &"agility", "kind": &"dodge", "rarity": 0})
	run.take_card({"id": &"second_roll", "kind": &"dodge", "rarity": 1})
	var w := make_world("#####\n#S..#\n#####")
	run.apply_to_hero(w.hero)
	assert_almost(w.hero.dodge_cooldown, 4.0)
	assert_eq(w.hero.dodge_max_charges, 2)


func test_time_and_gold_bonus() -> void:
	var run := RunState.new_run(1)
	run.take_card({"id": &"respite", "kind": &"time", "rarity": 1})
	run.take_card({"id": &"greed", "kind": &"stat", "rarity": 0})
	assert_almost(run.time_bonus(), 0.08)
	assert_almost(run.gold_bonus(), 0.10)


func test_run_state_roundtrip() -> void:
	var run := RunState.new_run(42)
	run.take_card({"id": &"skill_up", "kind": &"skill", "skill": &"bleed", "rarity": 1})
	run.gold = 123
	var copy := RunState.from_dict(JSON.parse_string(JSON.stringify(run.to_dict())))
	assert_eq(copy.run_seed, 42)
	assert_eq(copy.gold, 123)
	assert_eq(int(copy.skill_entry(&"bleed")["level"]), 2)
	assert_eq(copy.cards[0]["skill"], &"bleed")
