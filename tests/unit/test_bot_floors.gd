extends TestCase
## The bot plays the real floors of dungeon 1 with the build a hero typically has there (SimBuild).
## Timer rule (GDD 10.4, decision D25): the bot is ~1.6x faster than a person, so
##   rush (stairs + goal, fights only what blocks it) <= 0.35 x limit  -> a person needs ~0.55;
##   full clear (immortal, timer stopped)            >= 0.60 x limit  -> a person needs ~1.0.
## Floors 1-2 are the tutorial: they must be fully clearable in time instead.

const RUSH_MAX := 0.35
const CLEAR_MIN := 0.6


func _floor_world(index: int, seed_value: int = 11) -> World:
	var base := "res://levels/d01/floor_%02d" % index
	var grid := FloorGrid.load_floor(base)
	var w := World.new()
	_owned.append(w)
	w.setup(grid, RngStreams.new(seed_value), index, float(grid.data.get("time_limit", 150)),
		SimBuild.make_run(seed_value, index))
	SimBuild.apply_gear(w.hero, index - 1)
	return w


func _check_rush(index: int) -> void:
	for s in [11, 12]:
		var w := _floor_world(index, s)
		var r := Bot.new(w, Bot.Mode.RUSH).run(400.0)
		print("    floor %d rush (seed %d): %.1f s of %.0f, hp %d / %d" % [index, s, r["time"], r["limit"], r["hp"],
			w.hero.max_hp])
		assert_true(r["completed"], "floor %d: the bot reached the stairs (seed %d)" % [index, s])
		assert_true(r["time"] <= r["limit"] * RUSH_MAX, "floor %d: rush %.1f s > %.2f x limit" % [index, r["time"], RUSH_MAX])


func _check_clear_does_not_fit(index: int) -> void:
	var w := _floor_world(index)
	w.timer.paused = true
	w.hero.immortal = true
	var r := Bot.new(w, Bot.Mode.CLEAR).run(900.0)
	print("    floor %d clear (raw): %.1f s, limit %.0f" % [index, r["bot_time"], w.timer.limit])
	assert_true(r["completed"], "floor %d: everything can be reached" % index)
	assert_almost(r["essence"], r["essence_total"], 0.01, "floor %d: all essence" % index)
	assert_true(r["bot_time"] >= w.timer.limit * CLEAR_MIN,
		"floor %d: full clear %.1f s < %.2f x limit" % [index, r["bot_time"], CLEAR_MIN])


func _check_clearable(index: int) -> void:
	var w := _floor_world(index)
	var r := Bot.new(w, Bot.Mode.CLEAR).run(400.0)
	print("    floor %d clear: %.1f s of %.0f" % [index, r["time"], r["limit"]])
	assert_true(r["completed"], "tutorial floor %d can be fully cleared in time" % index)
	assert_almost(r["essence"], r["essence_total"], 0.01, "floor %d: all essence" % index)


func test_floor_01() -> void:
	_check_rush(1)
	_check_clearable(1)


func test_floor_02() -> void:
	_check_rush(2)
	_check_clearable(2)


func test_floor_03() -> void:
	_check_rush(3)
	_check_clear_does_not_fit(3)


func test_floor_04() -> void:
	_check_rush(4)
	_check_clear_does_not_fit(4)


func test_floor_06() -> void:
	_check_rush(6)
	_check_clear_does_not_fit(6)


func test_floor_07() -> void:
	_check_rush(7)
	_check_clear_does_not_fit(7)


func test_floor_08() -> void:
	_check_rush(8)
	_check_clear_does_not_fit(8)


func test_floor_09() -> void:
	_check_rush(9)
	_check_clear_does_not_fit(9)


## Every floor of the dungeon exists and is wired: start, stairs (or a boss), packs on the map.
func test_all_floors_load() -> void:
	for i in range(1, GameState.LAST_FLOOR + 1):
		assert_true(GameState.floor_exists(i), "floor %d exists" % i)
		var g := FloorGrid.load_floor(GameState.floor_path(i))
		assert_true(g.in_bounds(g.start), "floor %d has a start" % i)
		var boss: bool = g.data.get("goal", {}).get("type", "") == "boss"
		assert_true(boss or g.in_bounds(g.exit), "floor %d has stairs" % i)
		for letter: String in g.data.get("packs", {}):
			assert_false(g.marker_cells(letter).is_empty(), "floor %d: pack %s is on the map" % [i, letter])
