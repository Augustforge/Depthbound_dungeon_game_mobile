extends TestCase
## The bot plays real floors: no dead ends, timer rule (GDD 10.4) on non-tutorial floors.


func _floor_world(index: int, seed_value: int = 11) -> World:
	var base := "res://levels/d01/floor_%02d" % index
	var grid := FloorGrid.load_floor(base)
	var w := World.new()
	_owned.append(w)
	w.setup(grid, RngStreams.new(seed_value), index, float(grid.data.get("time_limit", 150)), RunState.new_run(seed_value))
	return w


func test_floor_01_rush() -> void:
	var w := _floor_world(1)
	var r := Bot.new(w, Bot.Mode.RUSH).run(400.0)
	print("    floor 1 rush: ", r)
	assert_true(r["completed"], "bot reached the stairs")
	assert_true(r["time"] < r["limit"] * 0.6, "rush well within the limit")


func test_floor_01_clear() -> void:
	var w := _floor_world(1)
	var r := Bot.new(w, Bot.Mode.CLEAR).run(400.0)
	print("    floor 1 clear: ", r)
	assert_true(r["completed"], "tutorial floor can be fully cleared")
	assert_almost(r["essence"], r["essence_total"], 0.01, "all essence")
