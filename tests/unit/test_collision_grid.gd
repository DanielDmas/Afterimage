extends AfterimageTestCase


func test_world_to_cell_positive_coordinates() -> void:
	var grid := CollisionGrid.new(500)
	assert_eq(grid.world_to_cell(Vector2i(0, 0)), Vector2i(0, 0))
	assert_eq(grid.world_to_cell(Vector2i(499, 0)), Vector2i(0, 0))
	assert_eq(grid.world_to_cell(Vector2i(500, 0)), Vector2i(1, 0))
	assert_eq(grid.world_to_cell(Vector2i(999, 999)), Vector2i(1, 1))
	assert_eq(grid.world_to_cell(Vector2i(1000, 1000)), Vector2i(2, 2))


func test_world_to_cell_negative_coordinates_floor_correctly() -> void:
	var grid := CollisionGrid.new(500)
	# -1mm at a 500mm cell size must map to cell -1, not 0 (floor, not
	# truncation-toward-zero, which is what GDScript's bare `/` gives).
	assert_eq(grid.world_to_cell(Vector2i(-1, 0)), Vector2i(-1, 0))
	assert_eq(grid.world_to_cell(Vector2i(-500, 0)), Vector2i(-1, 0))
	assert_eq(grid.world_to_cell(Vector2i(-501, 0)), Vector2i(-2, 0))
	assert_eq(grid.world_to_cell(Vector2i(-1, -1)), Vector2i(-1, -1))


func test_set_and_query_blocked_cell() -> void:
	var grid := CollisionGrid.new(500)
	var cell := Vector2i(3, -2)
	assert_false(grid.is_cell_blocked(cell))
	grid.set_cell_blocked(cell, true)
	assert_true(grid.is_cell_blocked(cell))
	grid.set_cell_blocked(cell, false)
	assert_false(grid.is_cell_blocked(cell))


func test_is_position_blocked_matches_containing_cell() -> void:
	var grid := CollisionGrid.new(500)
	grid.set_cell_blocked(Vector2i(2, 0), true)
	assert_true(grid.is_position_blocked(Vector2i(1000, 0)))
	assert_true(grid.is_position_blocked(Vector2i(1499, 250)))
	assert_false(grid.is_position_blocked(Vector2i(1500, 0)), "1500 is the start of the next cell")
	assert_false(grid.is_position_blocked(Vector2i(999, 0)))


func test_cell_aabb_matches_world_bounds() -> void:
	var grid := CollisionGrid.new(500)
	var box: Dictionary = grid.cell_aabb(Vector2i(2, -1))
	assert_eq(box["min"], Vector2i(1000, -500))
	assert_eq(box["max"], Vector2i(1500, 0))


func test_blocked_cells_returns_deterministic_sorted_order() -> void:
	var grid := CollisionGrid.new(500)
	grid.set_cell_blocked(Vector2i(5, 5), true)
	grid.set_cell_blocked(Vector2i(-3, 1), true)
	grid.set_cell_blocked(Vector2i(0, 0), true)
	grid.set_cell_blocked(Vector2i(-3, -1), true)

	var cells: Array = grid.blocked_cells()
	assert_eq(cells.size(), 4)
	for i in range(cells.size() - 1):
		var a: Vector2i = cells[i]
		var b: Vector2i = cells[i + 1]
		var a_before_b: bool = a.x < b.x or (a.x == b.x and a.y < b.y)
		assert_true(a_before_b, "blocked_cells() must be in a strict, deterministic order")


func test_blocked_count() -> void:
	var grid := CollisionGrid.new(500)
	assert_eq(grid.blocked_count(), 0)
	grid.set_cell_blocked(Vector2i(1, 1), true)
	grid.set_cell_blocked(Vector2i(2, 2), true)
	assert_eq(grid.blocked_count(), 2)
	grid.set_cell_blocked(Vector2i(1, 1), false)
	assert_eq(grid.blocked_count(), 1)
