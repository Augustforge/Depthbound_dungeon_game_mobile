extends TestCase

const ARENA := """
##########################
#S.......................#
#........................#
#........................#
##########################
"""


func _world_with(mob: String, at: Vector2, pack: String = "a") -> World:
	var w := make_world(ARENA)
	var m := Mob.new()
	m.setup(StringName(mob), DataDB.table(&"mobs")[mob], 1, at)
	m.pack_id = pack
	w.add_entity(m)
	return w


func _mobs(w: World) -> Array:
	return w.entities.filter(func(e: Entity) -> bool: return e is Mob)


func test_hero_kills_rat_while_standing() -> void:
	var w := _world_with("rat", Vector2(2.6, 1.5))
	var rat: Mob = _mobs(w)[0]
	run_world(w, 1.5)
	assert_false(rat.alive, "40 HP rat dies to one or two 40 ATK hits")


func test_no_attack_while_moving() -> void:
	var w := _world_with("prisoner", Vector2(2.6, 1.5))
	var m: Mob = _mobs(w)[0]
	w.hero.input.move = Vector2.DOWN
	run_world(w, 0.3)
	assert_almost(m.hp, m.max_hp, 0.01, "moving hero does not swing")


func test_whole_pack_aggroes() -> void:
	var w := _world_with("prisoner", Vector2(6.5, 2.5))
	var far := Mob.new()
	far.setup(&"prisoner", DataDB.table(&"mobs")["prisoner"], 1, Vector2(20.5, 2.5))
	far.pack_id = "a"
	w.add_entity(far)
	w.step(World.TICK)
	assert_eq(far.state, Mob.State.CHASE, "pack mate far away joins the fight")


func test_mob_damages_hero() -> void:
	var w := _world_with("prisoner", Vector2(2.6, 1.5))
	w.hero.input.move = Vector2.ZERO
	var hp0 := w.hero.hp
	run_world(w, 3.0)
	assert_true(w.hero.hp < hp0, "prisoner hits back")


func test_dodge_ignores_damage() -> void:
	var w := _world_with("prisoner", Vector2(2.6, 1.5))
	w.hero.input.dodge_requested = true
	w.step(World.TICK)
	var hp0 := w.hero.hp
	w.hero.take_damage(100.0, false, null)
	assert_almost(w.hero.hp, hp0, 0.01)


func test_leash_returns_and_heals() -> void:
	var w := make_world("""
##############################
#S...........................#
##############################
""")
	var m := Mob.new()
	m.setup(&"prisoner", DataDB.table(&"mobs")["prisoner"], 1, Vector2(4.5, 1.5))
	w.add_entity(m)
	m.hp = 10.0
	m.aggro()
	# Hero runs away along the corridor faster than the prisoner (4 vs 3.2 m/s).
	w.hero.pos = Vector2(8.5, 1.5)
	w.hero.input.move = Vector2.RIGHT
	run_world(w, 7.0)
	w.hero.input.move = Vector2.ZERO
	w.hero.pos = Vector2(28.5, 1.5)
	run_world(w, 12.0)
	assert_eq(m.state, Mob.State.IDLE, "went home")
	assert_almost(m.hp, m.max_hp, 0.01, "healed after leash")


func test_mob_paths_around_wall() -> void:
	var w := make_world("""
###########
#S....#...#
#.....#...#
#.........#
###########
""")
	var m := Mob.new()
	m.setup(&"rat", DataDB.table(&"mobs")["rat"], 1, Vector2(8.5, 1.5))
	w.add_entity(m)
	m.aggro()
	run_world(w, 4.0)
	# The hero kills the rat as soon as it is in reach (1.6 m + radius), so "reached" means within ~2 m.
	assert_true(m.pos.distance_to(w.hero.pos) < 2.0, "rat reached the hero around the wall: %s" % m.pos)
