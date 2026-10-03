extends TestCase
## Floor loop (GDD 10–13): goals, stairs, essence, stars, objects, traps, death.


func _world(map: String, params: Dictionary = {}, limit: float = 100.0) -> World:
	var w := World.new()
	_owned.append(w)
	w.setup(FloorGrid.from_text(map, params), RngStreams.new(7), 1, limit)
	return w


func _obj(w: World, kind: FloorObject.Kind) -> FloorObject:
	for e in w.entities:
		if e is FloorObject and e.kind == kind:
			return e
	return null


func test_breakthrough_completes_on_stairs() -> void:
	var w := _world("#######\n#S...E#\n#######")
	var done := []
	w.floor_completed.connect(func(r: Dictionary) -> void: done.append(r))
	w.hero.input.move = Vector2.RIGHT
	run_world(w, 1.5)
	assert_eq(done.size(), 1, "floor completed")
	assert_eq(done[0]["stars"], 3, "fast = 3 stars")


func test_stars_by_time_left() -> void:
	var w := _world("#######\n#S...E#\n#######", {}, 100.0)
	w.timer.elapsed = 60.0
	assert_eq(w.stars(), 2, "40% left")
	w.timer.elapsed = 75.0
	assert_eq(w.stars(), 1, "25% left")


func test_key_holder_goal() -> void:
	var w := _world("##########\n#S...a..E#\n##########",
			{"goal": {"type": "key_holder", "pack": "a"}, "packs": {"a": [{"mob": "rat", "count": 1}]}})
	var rat: Mob = w.entities.filter(func(e: Entity) -> bool: return e is Mob)[0]
	assert_true(rat.key_holder)
	assert_almost(rat.max_hp, 60.0, 0.01, "key holder x1.5 HP")
	assert_false(w.goal_done())
	rat.take_damage(1000.0, false, w.hero)
	assert_true(w.goal_done(), "key dropped")


func test_seals_goal() -> void:
	var w := _world("#########\n#S.V.V.E#\n#########", {"goal": {"type": "seals", "count": 2}})
	assert_eq(w.seals_needed, 2)
	for e in w.entities:
		if e is FloorObject and e.kind == FloorObject.Kind.VALVE:
			e.activate()
	assert_true(w.goal_done())


func test_valve_interaction_takes_three_seconds() -> void:
	var w := _world("#########\n#SV....E#\n#########", {"goal": {"type": "seals", "count": 1}})
	w.hero.input.interact_requested = true
	run_world(w, 2.9)
	assert_eq(w.seals_done, 0)
	run_world(w, 0.2)
	assert_eq(w.seals_done, 1)


func test_moving_cancels_interaction() -> void:
	var w := _world("#########\n#SV....E#\n#########", {"goal": {"type": "seals", "count": 1}})
	w.hero.input.interact_requested = true
	run_world(w, 1.0)
	w.hero.input.move = Vector2.DOWN
	run_world(w, 3.0)
	assert_eq(w.seals_done, 0)


func test_essence_and_threshold() -> void:
	var packs := {"a": [{"mob": "rat", "count": 3}, {"mob": "jailer", "count": 1}]}
	var w := _world("############\n#S...a....E#\n############", {"packs": packs})
	assert_almost(w.essence_total, 5.0)
	assert_almost(w.essence_threshold(), 4.0, 0.01, "ceil(0.65 * 5)")
	for e in w.entities:
		if e is Mob and e.def_id == &"rat":
			e.take_damage(999.0, false, w.hero)
	assert_almost(w.essence, 3.0)
	assert_false(w.result()["double_card"])


func test_lever_opens_gate() -> void:
	var w := _world("##########\n#S.L..D.E#\n##########", {"links": [{"lever_at": [3, 1], "gate_at": [6, 1]}]})
	assert_false(w.grid.is_walkable(Vector2i(6, 1)))
	_obj(w, FloorObject.Kind.LEVER).activate()
	assert_true(w.grid.is_walkable(Vector2i(6, 1)))


func test_chest_gives_gold() -> void:
	var w := _world("#######\n#SC..E#\n#######")
	_obj(w, FloorObject.Kind.CHEST).activate()
	assert_true(w.gold_collected >= 20 and w.gold_collected <= 40)


func test_spring_heals() -> void:
	var w := _world("#######\n#SF..E#\n#######")
	w.hero.hp = 100.0
	_obj(w, FloorObject.Kind.SPRING).activate()
	assert_almost(w.hero.hp, 400.0)
	assert_false(_obj(w, FloorObject.Kind.SPRING).can_interact(), "single use")


func test_bear_trap_roots() -> void:
	var w := _world("#######\n#S.T.E#\n#######")
	w.hero.input.move = Vector2.RIGHT
	run_world(w, 0.6)
	assert_true(w.hero.statuses.has(&"root"))
	assert_true(w.hero.hp < w.hero.max_hp)


func test_spikes_hit_on_extension() -> void:
	var w := _world("#######\n#S^..E#\n#######")
	var zone: SpikeZone = w.entities.filter(func(e: Entity) -> bool: return e is SpikeZone)[0]
	zone.cycle = 0.0
	w.hero.pos = Vector2(2.5, 1.5)
	run_world(w, 1.9)
	assert_almost(w.hero.hp, w.hero.max_hp, 0.01, "hidden")
	run_world(w, 0.3)
	assert_true(w.hero.hp < w.hero.max_hp, "extended")
	var hp1 := w.hero.hp
	run_world(w, 0.5)
	assert_almost(w.hero.hp, hp1, 0.01, "once per extension")


func test_spikes_hit_mobs_too() -> void:
	var w := _world("#########\n#S...^.E#\n#########", {"packs": {}})
	var zone: SpikeZone = w.entities.filter(func(e: Entity) -> bool: return e is SpikeZone)[0]
	var m := Mob.new()
	m.setup(&"prisoner", DataDB.table(&"mobs")["prisoner"], 1, Vector2(5.5, 1.5))
	w.add_entity(m)
	m.statuses.apply(&"stun", 10.0)
	zone.cycle = 1.9
	run_world(w, 0.2)
	assert_true(m.hp < m.max_hp)


func test_harpoon_fires_and_lever_disables() -> void:
	var links := [{"lever_at": [1, 2], "harpoon_at": [5, 0]}]
	var w := _world("#####H###\n#S.....E#\n#L.......#\n#########", {"links": links})
	var h: HarpoonWall = w.entities.filter(func(e: Entity) -> bool: return e is HarpoonWall)[0]
	assert_eq(h.dir, Vector2.DOWN)
	var fired := []
	w.telegraph_fired.connect(func(t: Telegraph) -> void: fired.append(t.id))
	run_world(w, 3.5)
	assert_true(fired.has(&"harpoon"))
	_obj(w, FloorObject.Kind.LEVER).activate()
	assert_true(h.disabled)


func test_throwing_blade_breaks_harpoon() -> void:
	var w := _world("#####H###\n#S.....E#\n#.......#\n#.......#\n#########")
	var h: HarpoonWall = w.entities.filter(func(e: Entity) -> bool: return e is HarpoonWall)[0]
	w.hero.add_skill(&"throwing_blade")
	w.hero.pos = Vector2(5.5, 3.5)
	w.hero.facing = Vector2.UP
	w.hero.find_skill(&"throwing_blade").try_cast()
	run_world(w, 0.5)
	assert_true(h.hp < h.max_hp, "blade reached the harpoon wall")


func test_lock_gate_closes_during_fight() -> void:
	var packs := {"a": [{"mob": "rat", "count": 1}]}
	var w := _world("################\n#S....B....a...E#\n################", {"packs": packs})
	var gate := _obj(w, FloorObject.Kind.LOCK_GATE)
	assert_false(gate.closed, "open until the pack is pulled")
	w.hero.pos = Vector2(8.5, 1.5)
	w.hero.immortal = true
	w.step(World.TICK)
	assert_true(gate.closed, "closed while fighting")
	for e in w.entities:
		if e is Mob:
			e.take_damage(999.0, false, w.hero)
	w.step(World.TICK)
	assert_false(gate.closed, "opens when the pack is dead")


func test_flood_valve_drowns_mobs_for_half_essence() -> void:
	var w := _world("##############\n#SW....a....E#\n##############",
			{"floods": [{"valve_at": [2, 1], "rect": [5, 1, 5, 1]}], "packs": {"a": [{"mob": "prisoner", "count": 2}]}})
	_obj(w, FloorObject.Kind.FLOOD_VALVE).activate()
	w.step(World.TICK)
	assert_eq(w.living_enemies(), 0)
	assert_almost(w.essence, 1.0, 0.01, "2 mobs x 1 essence x 50%")


func test_drowning_fails_floor() -> void:
	var w := _world("#######\n#S...E#\n#######", {}, 10.0)
	var fails := []
	w.floor_failed.connect(func(c: StringName) -> void: fails.append(c))
	w.hero.add_skill(&"second_wind")
	run_world(w, 14.1)
	assert_eq(fails, [&"drowned"], "flood kills even with Second Wind")


func test_coins_drop_and_collect() -> void:
	var packs := {"a": [{"mob": "rat", "count": 1}]}
	var w := _world("##########\n#S.a....E#\n##########", {"packs": packs})
	for e in w.entities:
		if e is Mob:
			e.take_damage(999.0, false, w.hero)
	run_world(w, 1.0)
	assert_true(w.gold_collected >= 1, "coins flew into the pickup radius")


func test_seal_gates_open_when_all_seals_turned() -> void:
	var map := "#########\n#S.V.V..#\n####D####\n####E####\n#########"
	var w := World.new()
	_owned.append(w)
	var grid := FloorGrid.from_text(map, {"goal": {"type": "seals", "count": 2}, "seal_gates": [[4, 2]]})
	w.setup(grid, RngStreams.new(1), 1, 150.0)
	assert_false(w.grid.is_walkable(Vector2i(4, 2)), "sluice closed")
	assert_false(w.is_reachable(w.hero.pos, Vector2(4.5, 3.5)))
	var valves := w.entities.filter(func(e: Entity) -> bool: return e is FloorObject and e.kind == FloorObject.Kind.VALVE)
	valves[0].activate()
	assert_false(w.grid.is_walkable(Vector2i(4, 2)), "one seal is not enough")
	valves[1].activate()
	assert_true(w.grid.is_walkable(Vector2i(4, 2)), "both seals open the sluice")
	assert_true(w.is_reachable(w.hero.pos, Vector2(4.5, 3.5)))
