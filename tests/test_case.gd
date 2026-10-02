class_name TestCase
extends RefCounted
## Base class for unit tests. Methods named test_* are run by tests/test_runner.gd.

var failures: PackedStringArray = []
var _current: String = ""
var _owned: Array[Node] = []


func before_each() -> void:
	pass


## Frees nodes created by the test (called by the runner).
func cleanup() -> void:
	for n in _owned:
		if is_instance_valid(n):
			n.free()
	_owned.clear()


func fail(msg: String) -> void:
	failures.append("%s: %s" % [_current, msg])


func assert_true(cond: bool, msg: String = "expected true") -> void:
	if not cond:
		fail(msg)


func assert_false(cond: bool, msg: String = "expected false") -> void:
	if cond:
		fail(msg)


func assert_eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		fail("%s expected <%s> got <%s>" % [msg, str(expected), str(actual)])


func assert_almost(actual: float, expected: float, eps: float = 0.001, msg: String = "") -> void:
	if absf(actual - expected) > eps:
		fail("%s expected %.4f±%.4f got %.4f" % [msg, expected, eps, actual])


## Builds a World on a map without adding it to the scene tree.
func make_world(map_text: String, time_limit: float = 150.0, seed_value: int = 42) -> World:
	var w := World.new()
	_owned.append(w)
	w.setup(FloorGrid.from_text(map_text), RngStreams.new(seed_value), 1, time_limit)
	return w


static func run_world(w: World, seconds: float) -> void:
	var n := roundi(seconds / World.TICK)
	for i in n:
		w.step(World.TICK)
