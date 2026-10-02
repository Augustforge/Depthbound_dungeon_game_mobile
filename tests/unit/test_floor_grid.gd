extends TestCase

const MAP := """
#######
#S...E#
#.###.#
#..a..#
#######
"""


func test_parses_size_start_exit() -> void:
	var g := FloorGrid.from_text(MAP)
	assert_eq(g.width, 7)
	assert_eq(g.height, 5)
	assert_eq(g.start, Vector2i(1, 1))
	assert_eq(g.exit, Vector2i(5, 1))
	assert_eq(g.marker_cells("a"), [Vector2i(3, 3)])


func test_walls_and_bounds() -> void:
	var g := FloorGrid.from_text(MAP)
	assert_true(g.is_wall(Vector2i(0, 0)))
	assert_true(g.is_wall(Vector2i(3, 2)))
	assert_false(g.is_wall(Vector2i(2, 1)))
	assert_true(g.is_wall(Vector2i(-1, 3)), "outside the map counts as wall")
	assert_true(g.is_walkable(Vector2i(3, 3)), "pack letters are floor")


func test_move_circle_stops_at_wall() -> void:
	var g := FloorGrid.from_text(MAP)
	var p := g.move_circle(Vector2(1.5, 1.5), 0.35, Vector2(-5.0, 0.0))
	assert_almost(p.x, 1.35, 0.01, "pressed against the left wall")
	assert_almost(p.y, 1.5, 0.01)


func test_move_circle_slides_along_wall() -> void:
	var g := FloorGrid.from_text(MAP)
	# Moving diagonally up-right in the top corridor: y is blocked, x keeps going.
	var p := g.move_circle(Vector2(2.5, 1.5), 0.35, Vector2(1.0, -1.0))
	assert_almost(p.x, 3.5, 0.01)
	assert_almost(p.y, 1.35, 0.01)


func test_fast_move_does_not_tunnel() -> void:
	var g := FloorGrid.from_text(MAP)
	var p := g.move_circle(Vector2(1.5, 1.5), 0.35, Vector2(0.0, 30.0))
	assert_true(p.y < 4.0, "stayed inside the map")
	assert_true(g.circle_free(p, 0.34))


func test_closed_gate_blocks_until_opened() -> void:
	var g := FloorGrid.from_text("#####\n#.D.#\n#####")
	var p := g.move_circle(Vector2(1.5, 1.5), 0.35, Vector2(3.0, 0.0))
	assert_true(p.x < 2.0, "gate blocks")
	g.set_blocked(Vector2i(2, 1), false)
	p = g.move_circle(Vector2(1.5, 1.5), 0.35, Vector2(2.0, 0.0))
	assert_almost(p.x, 3.5, 0.01, "open gate lets through")


func test_line_of_sight() -> void:
	var g := FloorGrid.from_text(MAP)
	assert_true(g.has_line_of_sight(Vector2(1.5, 1.5), Vector2(5.5, 1.5)))
	assert_false(g.has_line_of_sight(Vector2(3.5, 1.5), Vector2(3.5, 3.5)), "wall row between")
