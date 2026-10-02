extends TestCase

const ROOM := """
############
#..........#
#....S.....#
#..........#
############
"""


func test_dodge_moves_three_metres_in_quarter_second() -> void:
	var w := make_world(ROOM)
	var start := w.hero.pos
	w.hero.input.move = Vector2.RIGHT
	w.hero.input.dodge_requested = true
	w.step(World.TICK)
	w.hero.input.move = Vector2.ZERO
	run_world(w, 0.25)
	assert_almost(w.hero.pos.x - start.x, 3.0, 0.05)


func test_dodge_invulnerability_window() -> void:
	var w := make_world(ROOM)
	w.hero.input.dodge_requested = true
	w.step(World.TICK)
	assert_true(w.hero.is_invulnerable())
	run_world(w, 0.36)
	assert_false(w.hero.is_invulnerable(), "invulnerable only 0.35 s")


func test_dodge_cooldown_six_seconds() -> void:
	var w := make_world(ROOM)
	w.hero.input.dodge_requested = true
	w.step(World.TICK)
	run_world(w, 1.0)
	w.hero.input.dodge_requested = true
	w.step(World.TICK)
	assert_eq(w.hero.dodge_charges, 0, "second dodge refused during cooldown")
	run_world(w, 5.1)
	assert_eq(w.hero.dodge_charges, 1, "charge back after 6 s")


func test_dodge_stops_at_walls() -> void:
	var w := make_world(ROOM)
	w.hero.input.move = Vector2.UP
	w.hero.input.dodge_requested = true
	run_world(w, 0.4)
	assert_true(w.hero.pos.y >= 1.0 + w.hero.radius - 0.01, "no dodging through walls")


func test_walk_speed() -> void:
	var w := make_world(ROOM)
	var x0 := w.hero.pos.x
	w.hero.input.move = Vector2.RIGHT
	run_world(w, 0.5)
	assert_almost(w.hero.pos.x - x0, 2.0, 0.05, "4 m/s")
