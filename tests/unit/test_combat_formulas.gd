extends TestCase


func _hero_stats() -> StatBlock:
	var d: Dictionary = DataDB.table(&"hero_swordsman")
	return StatBlock.new(d["stats"], d["stat_caps"])


func test_base_stats_from_config() -> void:
	var s := _hero_stats()
	assert_almost(s.get_stat(&"max_hp"), 600.0)
	assert_almost(s.get_stat(&"atk"), 40.0)
	assert_almost(s.attack_interval(), 1.0)


func test_flat_then_percent() -> void:
	var s := _hero_stats()
	s.set_source(&"weapon", {&"atk": 10.0})
	s.set_source(&"card_sharpness", {}, {&"atk": 0.22})
	assert_almost(s.get_stat(&"atk"), (40.0 + 10.0) * 1.22)


func test_removing_source_restores_stat() -> void:
	var s := _hero_stats()
	s.set_source(&"card", {}, {&"max_hp": 0.3})
	s.remove_source(&"card")
	assert_almost(s.get_stat(&"max_hp"), 600.0)


func test_caps() -> void:
	var s := _hero_stats()
	s.set_source(&"lots", {&"crit_chance": 5.0, &"cdr": 2.0}, {&"move_speed": 2.0, &"attack_speed": 10.0})
	assert_almost(s.get_stat(&"crit_chance"), 0.75)
	assert_almost(s.get_stat(&"cdr"), 0.40)
	assert_almost(s.get_stat(&"move_speed"), 6.4)
	assert_almost(s.attack_interval(), 0.35)


func test_damage_formula_bounds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for i in 200:
		var d := Damage.roll(40.0, 1.0, 0.0, 1.5, 40.0, rng)
		assert_false(d.crit)
		var expected := 40.0 * 100.0 / 140.0
		assert_true(d.amount >= expected * 0.95 - 0.001 and d.amount <= expected * 1.05 + 0.001, "spread ±5%")


func test_crit_multiplies() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var d := Damage.roll(100.0, 1.0, 1.0, 1.5, 0.0, rng)
	assert_true(d.crit)
	assert_true(d.amount >= 142.5 - 0.01 and d.amount <= 157.5 + 0.01)


func test_floor_scaling() -> void:
	assert_almost(Damage.mob_hp(120.0, 1), 120.0)
	assert_almost(Damage.mob_hp(120.0, 10), 120.0 * 2.08)
	assert_almost(Damage.mob_damage(14.0, 10), 14.0 * 1.63)
