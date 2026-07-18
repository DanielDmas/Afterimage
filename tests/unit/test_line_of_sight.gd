extends AfterimageTestCase

## Expected cell sequences below were derived from an executable Python
## reference before this algorithm was ported (see line_of_sight.gd's
## class doc), not hand-traced through the Bresenham loop by eye.


func _to_vectors(pairs: Array) -> Array:
	var out: Array = []
	for pair: Array in pairs:
		out.append(Vector2i(pair[0], pair[1]))
	return out


func test_horizontal_line() -> void:
	var cells: Array = LineOfSight.cells_along_line(Vector2i(0, 0), Vector2i(5, 0))
	assert_eq(cells, _to_vectors([[0, 0], [1, 0], [2, 0], [3, 0], [4, 0], [5, 0]]))


func test_vertical_line() -> void:
	var cells: Array = LineOfSight.cells_along_line(Vector2i(0, 0), Vector2i(0, 4))
	assert_eq(cells, _to_vectors([[0, 0], [0, 1], [0, 2], [0, 3], [0, 4]]))


func test_diagonal_line() -> void:
	var cells: Array = LineOfSight.cells_along_line(Vector2i(0, 0), Vector2i(3, 3))
	assert_eq(cells, _to_vectors([[0, 0], [1, 1], [2, 2], [3, 3]]))


func test_shallow_slope_line() -> void:
	var cells: Array = LineOfSight.cells_along_line(Vector2i(0, 0), Vector2i(5, 2))
	assert_eq(cells, _to_vectors([[0, 0], [1, 0], [2, 1], [3, 1], [4, 2], [5, 2]]))


func test_steep_slope_line() -> void:
	var cells: Array = LineOfSight.cells_along_line(Vector2i(0, 0), Vector2i(2, 5))
	assert_eq(cells, _to_vectors([[0, 0], [0, 1], [1, 2], [1, 3], [2, 4], [2, 5]]))


func test_negative_x_direction() -> void:
	var cells: Array = LineOfSight.cells_along_line(Vector2i(0, 0), Vector2i(-3, 4))
	assert_eq(cells, _to_vectors([[0, 0], [-1, 1], [-2, 2], [-2, 3], [-3, 4]]))


func test_negative_both_directions() -> void:
	var cells: Array = LineOfSight.cells_along_line(Vector2i(0, 0), Vector2i(-4, -2))
	assert_eq(cells, _to_vectors([[0, 0], [-1, -1], [-2, -1], [-3, -2], [-4, -2]]))


func test_single_point() -> void:
	var cells: Array = LineOfSight.cells_along_line(Vector2i(2, 2), Vector2i(2, 2))
	assert_eq(cells, [Vector2i(2, 2)])


func test_reversed_direction_is_the_reverse_sequence() -> void:
	var cells: Array = LineOfSight.cells_along_line(Vector2i(3, 3), Vector2i(0, 0))
	assert_eq(cells, _to_vectors([[3, 3], [2, 2], [1, 1], [0, 0]]))


# --- has_clear_line: the actual LOS query over a CollisionGrid ---


func test_clear_line_with_no_obstructions() -> void:
	var grid := CollisionGrid.new(500)
	assert_true(LineOfSight.has_clear_line(Vector2i(0, 0), Vector2i(2000, 0), grid))


func test_wall_between_two_points_blocks_line() -> void:
	var grid := CollisionGrid.new(500)
	grid.set_cell_blocked(Vector2i(2, 0), true)  # world [1000,1500]x[500,1000] roughly on the path
	assert_false(LineOfSight.has_clear_line(Vector2i(0, 250), Vector2i(2000, 250), grid))


func test_wall_off_the_path_does_not_block() -> void:
	var grid := CollisionGrid.new(500)
	grid.set_cell_blocked(Vector2i(10, 10), true)  # nowhere near this horizontal path
	assert_true(LineOfSight.has_clear_line(Vector2i(0, 250), Vector2i(2000, 250), grid))


func test_blocked_cell_at_the_observers_own_position_does_not_block() -> void:
	var grid := CollisionGrid.new(500)
	grid.set_cell_blocked(Vector2i(0, 0), true)  # the observer's own cell
	assert_true(LineOfSight.has_clear_line(Vector2i(100, 100), Vector2i(2000, 100), grid))


func test_blocked_cell_at_the_targets_own_position_does_not_block() -> void:
	var grid := CollisionGrid.new(500)
	grid.set_cell_blocked(Vector2i(4, 0), true)  # the target's own cell (world x in [2000,2500])
	assert_true(LineOfSight.has_clear_line(Vector2i(0, 100), Vector2i(2100, 100), grid))
