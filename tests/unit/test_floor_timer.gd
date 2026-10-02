extends TestCase


func test_phases_follow_gdd() -> void:
	var t := FloorTimer.new(100.0)
	t.elapsed = 49.0
	assert_eq(t.phase(), FloorTimer.Phase.DRY)
	t.elapsed = 50.0
	assert_eq(t.phase(), FloorTimer.Phase.SHALLOW)
	t.elapsed = 80.0
	assert_eq(t.phase(), FloorTimer.Phase.KNEE)
	t.elapsed = 100.0
	assert_eq(t.phase(), FloorTimer.Phase.FLOOD)
	assert_false(t.drowned())
	t.elapsed = 104.0
	assert_true(t.drowned(), "flood fills in 4 s")


func test_pause_stops_time() -> void:
	var t := FloorTimer.new(100.0)
	t.paused = true
	t.tick(5.0)
	assert_eq(t.elapsed, 0.0)


func test_knee_deep_water_slows_hero() -> void:
	var w := make_world("#######\n#S....#\n#######", 10.0)
	run_world(w, 8.5)
	var x0 := w.hero.pos.x
	w.hero.input.move = Vector2.RIGHT
	run_world(w, 0.5)
	assert_almost(w.hero.pos.x - x0, 2.0 * 0.85, 0.05, "15% slower in knee-deep water")
