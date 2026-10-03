extends TestCase
## Bosses (GDD 15).


func _arena(index: int, run: RunState = null) -> World:
	var grid := FloorGrid.load_floor("res://levels/d01/floor_%02d" % index)
	var w := World.new()
	_owned.append(w)
	w.setup(grid, RngStreams.new(3), index, 150.0, run if run else RunState.new_run(3))
	return w


func test_grum_spawns_with_enrage_timer() -> void:
	var w := _arena(5)
	assert_true(w.boss != null)
	assert_eq(w.boss.def_id, &"warden_grum")
	assert_almost(w.boss.max_hp, float(DataDB.table(&"bosses")["warden_grum"]["hp"]))
	assert_true(w.timer.boss_mode)
	assert_almost(w.timer.limit, 90.0)
	assert_eq(w.timer.phase(), FloorTimer.Phase.DRY)


func test_grum_whistle_summons_from_cages() -> void:
	var w := _arena(5)
	w.hero.immortal = true
	var summoned := []
	w.boss_summoned.connect(func(_b: Boss) -> void: summoned.append(true))
	run_world(w, 10.5)
	assert_true(summoned.size() >= 1, "first whistle at 10 s")
	var mobs := w.entities.filter(func(e: Entity) -> bool: return e is Mob and not (e is Boss))
	assert_true(mobs.size() >= 4, "3 rats and a prisoner")


func test_grum_rage_at_30_percent() -> void:
	var w := _arena(5)
	w.boss.hp = w.boss.max_hp * 0.29
	w.step(World.TICK)
	assert_almost(w.boss.attack_speed_bonus, 0.25)
	assert_almost(w.boss.cooldown_cut, 0.2)


func test_enrage_and_arena_flood() -> void:
	var w := _arena(5)
	w.hero.immortal = true
	w.hero.pos = Vector2(11.5, 19.5)
	w.boss.statuses.apply(&"stun", 1000.0)
	run_world(w, 91.0)
	assert_true(w.boss.enraged, "enrage after 90 s")
	assert_true(w.timer.phase() >= FloorTimer.Phase.SHALLOW, "water rises after enrage")
	var fails := []
	w.floor_failed.connect(func(c: StringName) -> void: fails.append(c))
	run_world(w, 34.0)
	assert_eq(fails, [&"drowned"], "arena floods 30 s after enrage")


func test_boss_stars_by_enrage_fraction() -> void:
	var w := _arena(5)
	w.timer.elapsed = 40.0
	assert_eq(w.stars(), 3)
	w.timer.elapsed = 60.0
	assert_eq(w.stars(), 2)
	w.timer.elapsed = 80.0
	assert_eq(w.stars(), 1)


func test_killing_boss_completes_floor() -> void:
	var w := _arena(5)
	var done := []
	w.floor_completed.connect(func(r: Dictionary) -> void: done.append(r))
	w.boss.take_damage(99999.0, false, w.hero)
	w.step(World.TICK)
	assert_eq(done.size(), 1)
	assert_eq(done[0]["boss"], "warden_grum")


func test_morten_phase_two() -> void:
	var w := _arena(10)
	assert_eq(w.boss.phase, 1)
	w.boss.hp = w.boss.max_hp * 0.49
	w.step(World.TICK)
	assert_eq(w.boss.phase, 2)
	assert_true(w.boss.is_invulnerable(), "2 s invulnerable on transition")
	assert_eq(w.puddles.size(), 3, "three puddles")


func test_morten_hook_pulls() -> void:
	var w := _arena(10)
	w.hero.pos = Vector2(12.5, 12.0)
	var p0 := w.hero.pos
	var hooked := []
	w.telegraph_fired.connect(func(t: Telegraph) -> void:
		if t.id == &"hook":
			hooked.append(true))
	run_world(w, 9.5)
	assert_true(hooked.size() >= 1, "hook used")


func test_bot_beats_grum_with_some_cards() -> void:
	var run := RunState.new_run(3)
	for c in [{"id": &"sharpness", "kind": &"stat", "rarity": 1}, {"id": &"vitality", "kind": &"stat", "rarity": 1},
			{"id": &"skill_up", "kind": &"skill", "skill": &"cleave", "rarity": 0},
			{"id": &"quick_hand", "kind": &"stat", "rarity": 0}, {"id": &"bloodthirst", "kind": &"stat", "rarity": 1}]:
		run.take_card(c)
	var w := _arena(5, run)
	_gear(w.hero, 4)
	var r := Bot.new(w, Bot.Mode.CLEAR).run(140.0)
	print("    grum fight: ", r, " boss hp ", w.boss.hp)
	assert_true(r["completed"], "a floor-5 build can beat Grum")


## Common gear of item level `ilvl` in weapon, helmet and armour (GDD 14.3), as found by floor 5.
func _gear(hero: Hero, ilvl: int) -> void:
	hero.stats.set_source(&"gear_sim", {&"atk": 6.0 + 1.0 * ilvl, &"max_hp": 30.0 + 6.0 * ilvl + 40.0 + 8.0 * ilvl,
		&"armor": 4.0 + 0.8 * ilvl})
	hero.refresh_stats()
	hero.hp = hero.max_hp


func test_bot_beats_morten_with_floor_10_build() -> void:
	var run := RunState.new_run(4)
	run.add_skill(&"whirlwind")
	for c in [{"id": &"sharpness", "kind": &"stat", "rarity": 1}, {"id": &"vitality", "kind": &"stat", "rarity": 1},
			{"id": &"skill_up", "kind": &"skill", "skill": &"cleave", "rarity": 1},
			{"id": &"skill_up", "kind": &"skill", "skill": &"bleed", "rarity": 0},
			{"id": &"quick_hand", "kind": &"stat", "rarity": 0}, {"id": &"bloodthirst", "kind": &"stat", "rarity": 1},
			{"id": &"sharpness", "kind": &"stat", "rarity": 0}, {"id": &"tempering", "kind": &"stat", "rarity": 0}]:
		run.take_card(c)
	var w := _arena(10, run)
	_gear(w.hero, 8)
	var r := Bot.new(w, Bot.Mode.CLEAR).run(220.0)
	print("    morten fight: ", r, " boss hp ", w.boss.hp)
	assert_true(r["completed"], "a floor-10 build can beat Morten")
