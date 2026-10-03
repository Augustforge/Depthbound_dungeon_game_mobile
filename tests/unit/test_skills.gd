extends TestCase
## Skills (GDD 8.2), statuses and telegraphs.

const ROOM := """
##########################
#S.......................#
#........................#
#........................#
#........................#
#........................#
##########################
"""


func _world() -> World:
	var w := make_world(ROOM)
	w.hero.pos = Vector2(5.5, 3.5)
	w.hero.facing = Vector2.RIGHT
	return w


func _mob(w: World, def: String, at: Vector2) -> Mob:
	var m := Mob.new()
	m.setup(StringName(def), DataDB.table(&"mobs")[def], 1, at)
	w.add_entity(m)
	return m


func _give(w: World, id: StringName, level: int = 1) -> Skill:
	var s := w.hero.find_skill(id)
	if s == null:
		w.hero.add_skill(id, level)
		s = w.hero.find_skill(id)
	s.set_level(level)
	return s


func test_start_skills() -> void:
	var w := _world()
	assert_true(w.hero.find_skill(&"cleave") != null, "Cleave at start")
	assert_true(w.hero.find_skill(&"bleed") != null, "Bleed at start")


func test_skill_levels_merge() -> void:
	var w := _world()
	var c := _give(w, &"cleave", 4)
	assert_almost(float(c.p("atk_coef")), 2.6)
	assert_almost(float(c.p("cooldown")), 4.5)
	assert_almost(float(c.p("shape")["angle"]), 180.0, 0.01, "level 3 widened the cone")


func test_cleave_hits_cone_only() -> void:
	var w := _world()
	var front := _mob(w, "prisoner", Vector2(7.0, 3.5))
	var behind := _mob(w, "prisoner", Vector2(3.5, 3.5))
	w.hero.priority_target = front
	assert_true(w.hero.find_skill(&"cleave").try_cast())
	assert_true(front.hp < front.max_hp, "front enemy hit")
	assert_almost(behind.hp, behind.max_hp, 0.01, "enemy behind not hit")
	assert_true(front.statuses.has(&"bleed"), "skills apply bleed")


func test_cleave_cooldown() -> void:
	var w := _world()
	var c := w.hero.find_skill(&"cleave")
	_mob(w, "prisoner", Vector2(7.0, 3.5))
	assert_true(c.try_cast())
	assert_false(c.try_cast(), "on cooldown")
	run_world(w, 5.05)
	assert_true(c.ready(), "5 s cooldown")


func test_bleed_ticks_and_stacks() -> void:
	var w := _world()
	var m := _mob(w, "jailer", Vector2(20.5, 3.5))
	var b := w.hero.find_skill(&"bleed")
	for i in 5:
		b.on_hit(m, 1.0, {})
	assert_eq(int(m.statuses.effects[&"bleed"]["stacks"]), 3, "max 3 stacks at level 1")
	var hp0 := m.hp
	run_world(w, 1.01)
	var expected := 40.0 * 0.15 * 3.0
	assert_almost(hp0 - m.hp, expected, 0.5, "15% ATK per stack per second, ignores armour")


func test_bleed_level5_explodes() -> void:
	var w := _world()
	_give(w, &"bleed", 5)
	var a := _mob(w, "rat", Vector2(20.5, 3.5))
	var b := _mob(w, "prisoner", Vector2(21.5, 3.5))
	w.hero.find_skill(&"bleed").on_hit(a, 1.0, {})
	w.hero.deal_damage(a, 10.0)
	assert_false(a.alive)
	assert_true(b.hp < b.max_hp, "explosion hit the neighbour")


func test_dash_strike_moves_and_hits() -> void:
	var w := _world()
	w.hero.add_skill(&"dash_strike")
	var m := _mob(w, "prisoner", Vector2(8.0, 3.5))
	w.hero.input.move = Vector2.RIGHT
	assert_true(w.hero.find_skill(&"dash_strike").try_cast())
	assert_true(w.hero.is_invulnerable(), "invulnerable while dashing")
	run_world(w, 0.3)
	assert_almost(w.hero.pos.x, 10.5, 0.2, "5 m dash")
	assert_true(m.hp < m.max_hp, "enemy on the path hit")


func test_whirlwind_ticks() -> void:
	var w := _world()
	w.hero.add_skill(&"whirlwind")
	var m := _mob(w, "jailer", Vector2(7.0, 3.5))
	m.statuses.apply(&"stun", 10.0)
	w.hero.find_skill(&"whirlwind").try_cast()
	run_world(w, 1.0)
	assert_true(m.max_hp - m.hp > 40.0 * 0.6 * 3.0 * 100.0 / 140.0 * 0.9, "several ticks landed")
	assert_true(w.hero.spinning())
	run_world(w, 2.0)
	assert_false(w.hero.spinning(), "2.5 s duration")


func test_parry_blocks_and_counters() -> void:
	var w := _world()
	w.hero.add_skill(&"parry")
	var m := _mob(w, "prisoner", Vector2(6.6, 3.5))
	w.hero.find_skill(&"parry").try_cast()
	var hp0 := w.hero.hp
	w.apply_strike(m, w.hero, 100.0, {}, true, m.pos)
	assert_almost(w.hero.hp, hp0, 0.01, "blocked")
	assert_true(m.hp < m.max_hp, "counter-attack")


func test_parry_cannot_block_unparryable() -> void:
	var w := _world()
	w.hero.add_skill(&"parry")
	var m := _mob(w, "prisoner", Vector2(6.6, 3.5))
	w.hero.find_skill(&"parry").try_cast()
	var hp0 := w.hero.hp
	w.apply_strike(m, w.hero, 100.0, {}, false, m.pos)
	assert_true(w.hero.hp < hp0)


func test_throwing_blade_pierces_three() -> void:
	var w := _world()
	w.hero.add_skill(&"throwing_blade")
	var mobs := []
	for i in 4:
		var m := _mob(w, "jailer", Vector2(8.0 + i * 1.2, 3.5))
		m.statuses.apply(&"stun", 10.0)
		mobs.append(m)
	w.hero.priority_target = mobs[0]
	w.hero.find_skill(&"throwing_blade").try_cast()
	run_world(w, 1.0)
	var hit := mobs.filter(func(m: Mob) -> bool: return m.hp < m.max_hp).size()
	assert_eq(hit, 3, "pierces up to 3 enemies")


func test_battle_cry_buffs() -> void:
	var w := _world()
	w.hero.add_skill(&"battle_cry")
	var atk0 := w.hero.stats.get_stat(&"atk")
	w.hero.find_skill(&"battle_cry").try_cast()
	w.step(World.TICK)
	assert_almost(w.hero.stats.get_stat(&"atk"), atk0 * 1.3, 0.01)
	run_world(w, 6.1)
	assert_almost(w.hero.stats.get_stat(&"atk"), atk0, 0.01, "buff ends after 6 s")


func test_blade_master_third_hit_crits() -> void:
	var w := _world()
	w.hero.add_skill(&"blade_master")
	var ctx := {}
	var bm := w.hero.find_skill(&"blade_master")
	bm.on_auto_attack({})
	bm.on_auto_attack({})
	bm.on_auto_attack(ctx)
	assert_true(ctx.get("force_crit", false))


func test_lifesteal_heals() -> void:
	var w := _world()
	w.hero.add_skill(&"lifesteal_passive")
	w.step(World.TICK)
	w.hero.hp = 100.0
	var m := _mob(w, "jailer", Vector2(20.5, 3.5))
	var taken := w.hero.deal_damage(m, 1.0)
	assert_almost(w.hero.hp, 100.0 + taken * 0.06, 0.01)


func test_second_wind_saves_once() -> void:
	var w := _world()
	w.hero.add_skill(&"second_wind")
	w.hero.take_damage(10000.0, false, null)
	assert_true(w.hero.alive)
	assert_almost(w.hero.hp, w.hero.max_hp * 0.3, 0.5)
	assert_true(w.hero.is_invulnerable())
	run_world(w, 2.1)
	w.hero.take_damage(10000.0, false, null)
	assert_false(w.hero.alive, "only once per floor")


func test_fury_scales_with_missing_hp() -> void:
	var w := _world()
	w.hero.add_skill(&"fury")
	w.hero.hp = w.hero.max_hp * 0.5
	w.step(World.TICK)
	assert_almost(w.hero.stats.get_stat(&"atk"), 40.0 * (1.0 + 50.0 * 0.005), 0.05)


func test_counterattack_can_trigger() -> void:
	var w := _world()
	_give(w, &"counterattack", 1)
	var m := _mob(w, "jailer", Vector2(6.6, 3.5))
	m.statuses.apply(&"stun", 100.0)
	for i in 40:
		w.hero.take_damage(1.0, false, m)
	assert_true(m.hp < m.max_hp, "25% chance fires at least once in 40 hits")


func test_auto_mode_casts_cleave() -> void:
	var w := _world()
	var m := _mob(w, "prisoner", Vector2(7.0, 3.5))
	w.hero.auto_mode = true
	w.step(World.TICK)
	assert_false(w.hero.find_skill(&"cleave").ready(), "AUTO used Cleave on a nearby enemy")
	assert_true(m.hp < m.max_hp)


func test_auto_never_parries() -> void:
	var w := _world()
	w.hero.add_skill(&"parry")
	_mob(w, "prisoner", Vector2(6.6, 3.5))
	w.hero.auto_mode = true
	run_world(w, 2.0)
	assert_true(w.hero.find_skill(&"parry").ready(), "Parry stays manual")


func test_telegraph_hits_inside_only_after_delay() -> void:
	var w := _world()
	var m := _mob(w, "jailer", Vector2(20.5, 3.5))
	var t := Telegraph.new()
	t.shape = {"type": "circle", "radius": 2.0}
	t.origin = w.hero.pos
	t.total = 1.0
	t.source = m
	t.damage = 100.0
	t.effect = {"stun": 1.0}
	w.add_telegraph(t)
	var hp0 := w.hero.hp
	run_world(w, 0.5)
	assert_almost(w.hero.hp, hp0, 0.01, "nothing before the telegraph fills")
	run_world(w, 0.55)
	assert_almost(hp0 - w.hero.hp, 100.0 * 100.0 / 120.0, 0.5, "damage reduced by hero armour 20")
	assert_true(w.hero.statuses.has(&"stun"))


func test_dodge_out_of_telegraph() -> void:
	var w := _world()
	var m := _mob(w, "jailer", Vector2(20.5, 3.5))
	var t := Telegraph.new()
	t.shape = {"type": "circle", "radius": 1.5}
	t.origin = w.hero.pos
	t.total = 1.0
	t.source = m
	t.damage = 100.0
	w.add_telegraph(t)
	w.hero.input.move = Vector2.LEFT
	w.hero.input.dodge_requested = true
	run_world(w, 1.1)
	assert_almost(w.hero.hp, w.hero.max_hp, 0.01, "dodged out of the zone")


func test_jailer_uses_shield_bash() -> void:
	var w := _world()
	var m := _mob(w, "jailer", Vector2(7.2, 3.5))
	m.aggro()
	w.hero.immortal = true
	var started := []
	w.telegraph_started.connect(func(t: Telegraph) -> void: started.append(t.id))
	run_world(w, 6.0)
	assert_true(started.has(&"shield_bash"), "jailer telegraphs Shield Bash")


func test_crossbow_shot_is_telegraphed_line() -> void:
	var w := _world()
	var m := _mob(w, "crossbowman", Vector2(11.5, 3.5))
	m.aggro()
	var started := []
	w.telegraph_started.connect(func(t: Telegraph) -> void: started.append(t.shape["type"]))
	run_world(w, 1.0)
	assert_true(started.has("line"), "crossbow aims with a line")


func test_stun_stops_mob() -> void:
	var w := _world()
	var m := _mob(w, "prisoner", Vector2(10.5, 3.5))
	m.aggro()
	m.statuses.apply(&"stun", 1.0)
	var p0 := m.pos
	run_world(w, 0.5)
	assert_true(m.pos.distance_to(p0) < 0.01, "stunned mob does not move")
