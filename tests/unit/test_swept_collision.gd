extends AfterimageTestCase

## Expected t values below were derived from an executable Python reference
## using exact Fraction arithmetic (not hand-guessed or reasoned about
## purely in GDScript) before this algorithm was ported — see
## swept_collision.gd's class doc. Hit cases compare the float-converted t
## with a tolerance far tighter than any plausible bug would produce;
## FixedMath.div() truncates rather than rounds, so an exact integer match
## isn't always expected even when the math is correct.


func test_straight_hit() -> void:
	var t: int = SweptCollision.circle_vs_aabb_swept(
		Vector2i(0, 1500), 100, Vector2i(1200, 0), Vector2i(1000, 1000), Vector2i(2000, 2000)
	)
	assert_ne(t, SweptCollision.NO_HIT)
	assert_almost_eq(FixedMath.to_float(t), 0.75, 0.0005)


func test_parallel_outside_slab_never_hits() -> void:
	var t: int = SweptCollision.circle_vs_aabb_swept(
		Vector2i(0, 0), 100, Vector2i(1200, 0), Vector2i(1000, 1000), Vector2i(2000, 2000)
	)
	assert_eq(t, SweptCollision.NO_HIT)


func test_delta_too_short_to_reach() -> void:
	var t: int = SweptCollision.circle_vs_aabb_swept(
		Vector2i(0, 1500), 100, Vector2i(500, 0), Vector2i(1000, 1000), Vector2i(2000, 2000)
	)
	assert_eq(t, SweptCollision.NO_HIT)


func test_already_overlapping_reports_t_zero() -> void:
	var t: int = SweptCollision.circle_vs_aabb_swept(
		Vector2i(1500, 1500), 100, Vector2i(-1200, 0), Vector2i(1000, 1000), Vector2i(2000, 2000)
	)
	assert_eq(t, 0)


func test_diagonal_hit() -> void:
	var t: int = SweptCollision.circle_vs_aabb_swept(
		Vector2i(0, 0), 50, Vector2i(1000, 1000), Vector2i(900, 900), Vector2i(1500, 1500)
	)
	assert_ne(t, SweptCollision.NO_HIT)
	assert_almost_eq(FixedMath.to_float(t), 0.85, 0.0005)


func test_moving_away_never_hits() -> void:
	var t: int = SweptCollision.circle_vs_aabb_swept(
		Vector2i(0, 1500), 100, Vector2i(-1200, 0), Vector2i(1000, 1000), Vector2i(2000, 2000)
	)
	assert_eq(t, SweptCollision.NO_HIT)


func test_exact_endpoint_touch() -> void:
	var t: int = SweptCollision.circle_vs_aabb_swept(
		Vector2i(0, 1500), 100, Vector2i(900, 0), Vector2i(1000, 1000), Vector2i(2000, 2000)
	)
	assert_ne(t, SweptCollision.NO_HIT)
	assert_almost_eq(FixedMath.to_float(t), 1.0, 0.0005)


func test_zero_delta_never_hits_even_if_outside() -> void:
	var t: int = SweptCollision.circle_vs_aabb_swept(
		Vector2i(0, 0), 100, Vector2i.ZERO, Vector2i(1000, 1000), Vector2i(2000, 2000)
	)
	assert_eq(t, SweptCollision.NO_HIT)


func test_zero_delta_never_hits_even_if_already_inside() -> void:
	var t: int = SweptCollision.circle_vs_aabb_swept(
		Vector2i(1500, 1500), 100, Vector2i.ZERO, Vector2i(1000, 1000), Vector2i(2000, 2000)
	)
	assert_eq(t, SweptCollision.NO_HIT, "no movement requested this tick means nothing to sweep")


# --- circles_overlap: exact integer distance-squared test, no sqrt ---


func test_circles_overlap_when_closer_than_combined_radius() -> void:
	assert_true(SweptCollision.circles_overlap(Vector2i(0, 0), 300, Vector2i(400, 0), 300))


func test_circles_do_not_overlap_when_farther_than_combined_radius() -> void:
	assert_false(SweptCollision.circles_overlap(Vector2i(0, 0), 300, Vector2i(700, 0), 300))


func test_circles_exactly_touching_do_not_count_as_overlapping() -> void:
	# distance == combined radius is tangency, not overlap (strict <).
	assert_false(SweptCollision.circles_overlap(Vector2i(0, 0), 300, Vector2i(600, 0), 300))


# --- move_with_collision: the full resolve-a-move-against-the-grid path ---


func test_move_with_collision_applies_full_delta_when_nothing_blocks() -> void:
	var grid := CollisionGrid.new(500)
	var result: Vector2i = SweptCollision.move_with_collision(
		Vector2i(0, 0), 100, Vector2i(500, 500), grid
	)
	assert_eq(result, Vector2i(500, 500))


func test_move_with_collision_ignores_blocked_cells_outside_the_path() -> void:
	var grid := CollisionGrid.new(500)
	grid.set_cell_blocked(Vector2i(10, 10), true)  # far away, irrelevant
	var result: Vector2i = SweptCollision.move_with_collision(
		Vector2i(0, 0), 100, Vector2i(500, 500), grid
	)
	assert_eq(result, Vector2i(500, 500))


func test_move_with_collision_stops_short_of_a_blocking_wall() -> void:
	var grid := CollisionGrid.new(500)
	# Wall cell (2,2) spans world [1000,1500]x[1000,1500].
	grid.set_cell_blocked(Vector2i(2, 2), true)
	var result: Vector2i = SweptCollision.move_with_collision(
		Vector2i(0, 1500), 100, Vector2i(1200, 0), grid
	)
	# Same geometry as test_straight_hit (t=0.75): 1200*0.75 = 900 exactly,
	# so this stop point is an exact integer with no truncation ambiguity.
	assert_eq(result, Vector2i(900, 1500))


func test_move_with_collision_zero_delta_is_a_no_op() -> void:
	var grid := CollisionGrid.new(500)
	var result: Vector2i = SweptCollision.move_with_collision(
		Vector2i(42, 7), 100, Vector2i.ZERO, grid
	)
	assert_eq(result, Vector2i(42, 7))
