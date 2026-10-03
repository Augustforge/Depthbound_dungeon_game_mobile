extends TestCase
## Floor dressing (data/accents.json, DecorView).


func test_every_floor_accent_exists() -> void:
	var table := DataDB.table(&"accents")
	for i in range(1, GameState.LAST_FLOOR + 1):
		var g := FloorGrid.load_floor(GameState.floor_path(i))
		var name := String(g.data.get("accent", "default"))
		assert_true(table.has(name), "floor %d accent '%s' is defined" % [i, name])


func test_accent_merges_over_default() -> void:
	var a := Accent.resolve("torture")
	assert_true(a.has("water_deep"), "inherits from default")
	assert_true(Accent.color(a, "torch").g < 0.5, "own torch colour")


func test_decor_is_deterministic_and_avoids_objects() -> void:
	var g := FloorGrid.load_floor("res://levels/d01/floor_07")
	var accent := Accent.resolve(String(g.data["accent"]))
	var torches := LightGrid.place_torches(g, Accent.torch_density(g, accent))
	var v1 := DecorView.new()
	_owned.append(v1)
	v1.build(g, accent, torches)
	var v2 := DecorView.new()
	_owned.append(v2)
	v2.build(g, accent, torches)
	assert_true(v1.decor_count() > 10, "the torture chamber is dressed")
	assert_eq(v1.decor_count(), v2.decor_count(), "same floor, same decor")
	assert_true(v1.mesh != null)
