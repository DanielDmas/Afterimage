extends AfterimageTestCase

const ORIGIN := Vector2i(1000, 2000)
const OFFSET := 300


func test_facing_east_left_offsets_positive_y() -> void:
	assert_eq(
		Lean.peek_origin(ORIGIN, Vector2i(1, 0), Lean.Side.LEFT, OFFSET),
		ORIGIN + Vector2i(0, OFFSET)
	)


func test_facing_east_right_offsets_negative_y() -> void:
	assert_eq(
		Lean.peek_origin(ORIGIN, Vector2i(1, 0), Lean.Side.RIGHT, OFFSET),
		ORIGIN + Vector2i(0, -OFFSET)
	)


func test_facing_west_left_offsets_negative_y() -> void:
	assert_eq(
		Lean.peek_origin(ORIGIN, Vector2i(-1, 0), Lean.Side.LEFT, OFFSET),
		ORIGIN + Vector2i(0, -OFFSET)
	)


func test_facing_south_left_offsets_negative_x() -> void:
	assert_eq(
		Lean.peek_origin(ORIGIN, Vector2i(0, 1), Lean.Side.LEFT, OFFSET),
		ORIGIN + Vector2i(-OFFSET, 0)
	)


func test_facing_north_left_offsets_positive_x() -> void:
	assert_eq(
		Lean.peek_origin(ORIGIN, Vector2i(0, -1), Lean.Side.LEFT, OFFSET),
		ORIGIN + Vector2i(OFFSET, 0)
	)


func test_left_and_right_are_opposite_offsets() -> void:
	var left: Vector2i = Lean.peek_origin(ORIGIN, Vector2i(0, 1), Lean.Side.LEFT, OFFSET)
	var right: Vector2i = Lean.peek_origin(ORIGIN, Vector2i(0, 1), Lean.Side.RIGHT, OFFSET)
	assert_eq(left - ORIGIN, -(right - ORIGIN))


func test_zero_offset_returns_actor_position_unchanged() -> void:
	assert_eq(Lean.peek_origin(ORIGIN, Vector2i(1, 0), Lean.Side.LEFT, 0), ORIGIN)


func test_peek_origin_composes_with_line_of_sight() -> void:
	# A wall directly ahead blocks a straight look, but peeking far enough
	# to one side opens a clear line to a target past the wall. Both the
	# blocked straight line and the clear peeked line were traced cell by
	# cell through LineOfSight.cells_along_line()'s exact Bresenham steps
	# before picking these numbers (see that class's test file for the
	# same discipline applied to the primitive itself).
	var grid := CollisionGrid.new(500)
	grid.set_cell_blocked(Vector2i(2, 0), true)  # world [1000,1500]x[0,500]
	var actor_pos := Vector2i(0, 250)
	var target_pos := Vector2i(2000, 250)

	assert_false(LineOfSight.has_clear_line(actor_pos, target_pos, grid))

	var peeked: Vector2i = Lean.peek_origin(actor_pos, Vector2i(1, 0), Lean.Side.LEFT, 1000)
	assert_true(LineOfSight.has_clear_line(peeked, target_pos, grid))
