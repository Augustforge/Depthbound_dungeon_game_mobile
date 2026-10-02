extends TestCase


func test_same_seed_same_sequence() -> void:
	var a := RngStreams.new(1234).stream("loot", 3)
	var b := RngStreams.new(1234).stream("loot", 3)
	for i in 20:
		assert_eq(a.randi(), b.randi())


func test_streams_are_independent() -> void:
	var r := RngStreams.new(1234)
	var loot_first := RngStreams.new(1234).stream("loot", 1).randi()
	r.stream("cards", 1).randi()
	r.stream("cards", 1).randi()
	assert_eq(r.stream("loot", 1).randi(), loot_first, "using cards must not shift loot")


func test_reset_replays_floor() -> void:
	var r := RngStreams.new(99)
	var first := r.stream("loot", 2).randi()
	r.stream("loot", 2).randi()
	r.reset("loot", 2)
	assert_eq(r.stream("loot", 2).randi(), first)


func test_derive_seed_is_stable() -> void:
	# Pinned value: changing the hash would silently change every saved run.
	assert_eq(RngStreams.fnv1a32("abc", 2166136261), 440920331)
