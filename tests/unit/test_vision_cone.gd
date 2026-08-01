extends AfterimageTestCase

## Expected results below were derived from an executable Python reference
## using exact Fraction arithmetic before this algorithm was ported (see
## vision_cone.gd's class doc). Test angles are chosen so cos²(half-angle)
## is an exact rational (30°→3/4, 45°→1/2, 60°→1/4 — all clean via the
## double-angle identity), so the Q16.16 constants below are exact, not
## rounded approximations.

const COS_SQ_30: int = 49152  # 0.75 * 65536, exact
const COS_SQ_45: int = 32768  # 0.5 * 65536, exact
const COS_SQ_60: int = 16384  # 0.25 * 65536, exact


func test_directly_ahead_is_inside_cone() -> void:
	assert_true(
		VisionCone.point_in_cone(
			Vector2i(0, 0), Vector2i(100, 0), COS_SQ_45, 1000, Vector2i(500, 0)
		)
	)


func test_exactly_on_the_cone_edge_counts_as_inside() -> void:
	assert_true(
		VisionCone.point_in_cone(
			Vector2i(0, 0), Vector2i(100, 0), COS_SQ_45, 1000, Vector2i(500, 500)
		)
	)


func test_just_outside_the_cone_angle_is_excluded() -> void:
	assert_false(
		VisionCone.point_in_cone(
			Vector2i(0, 0), Vector2i(100, 0), COS_SQ_45, 1000, Vector2i(100, 200)
		)
	)


func test_target_beyond_range_is_excluded_even_if_dead_ahead() -> void:
	assert_false(
		VisionCone.point_in_cone(
			Vector2i(0, 0), Vector2i(100, 0), COS_SQ_45, 1000, Vector2i(2000, 0)
		)
	)


func test_target_directly_behind_is_excluded() -> void:
	assert_false(
		VisionCone.point_in_cone(
			Vector2i(0, 0), Vector2i(100, 0), COS_SQ_45, 1000, Vector2i(-500, 0)
		)
	)


func test_inside_narrow_30_degree_cone() -> void:
	assert_true(
		VisionCone.point_in_cone(
			Vector2i(0, 0), Vector2i(100, 0), COS_SQ_30, 1000, Vector2i(900, 400)
		)
	)


func test_outside_narrow_30_degree_cone() -> void:
	assert_false(
		VisionCone.point_in_cone(
			Vector2i(0, 0), Vector2i(100, 0), COS_SQ_30, 1000, Vector2i(450, 300)
		)
	)


func test_inside_wide_60_degree_cone() -> void:
	assert_true(
		VisionCone.point_in_cone(
			Vector2i(0, 0), Vector2i(100, 0), COS_SQ_60, 1000, Vector2i(500, 800)
		)
	)


func test_outside_wide_60_degree_cone() -> void:
	assert_false(
		VisionCone.point_in_cone(
			Vector2i(0, 0), Vector2i(100, 0), COS_SQ_60, 1000, Vector2i(300, 600)
		)
	)


func test_observer_not_required_to_be_at_origin() -> void:
	# Same geometry as test_directly_ahead, translated by (10000, -5000).
	var offset := Vector2i(10000, -5000)
	assert_true(
		VisionCone.point_in_cone(
			offset, Vector2i(100, 0), COS_SQ_45, 1000, Vector2i(500, 0) + offset
		)
	)


func test_cos_sq_half_angle_fx_from_degrees_matches_known_exact_values() -> void:
	assert_almost_eq(
		FixedMath.to_float(VisionCone.cos_sq_half_angle_fx_from_degrees(45.0)), 0.5, 0.0005
	)
	assert_almost_eq(
		FixedMath.to_float(VisionCone.cos_sq_half_angle_fx_from_degrees(60.0)), 0.25, 0.0005
	)
	assert_almost_eq(
		FixedMath.to_float(VisionCone.cos_sq_half_angle_fx_from_degrees(30.0)), 0.75, 0.0005
	)
