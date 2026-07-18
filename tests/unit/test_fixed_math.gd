extends AfterimageTestCase


func test_constants() -> void:
	assert_eq(FixedMath.SCALE, 65536, "SCALE must be 2^16")
	assert_eq(FixedMath.ONE, FixedMath.SCALE)
	assert_eq(FixedMath.HALF, 32768)
	assert_eq(FixedMath.FRAC_BITS, 16)
	assert_eq(FixedMath.ZERO, 0)


func test_from_int_and_to_float_roundtrip() -> void:
	assert_eq(FixedMath.from_int(0), 0)
	assert_eq(FixedMath.from_int(1), FixedMath.SCALE)
	assert_eq(FixedMath.from_int(-7), -7 * FixedMath.SCALE)
	assert_almost_eq(FixedMath.to_float(FixedMath.from_int(42)), 42.0, 0.0001)


func test_from_float_rounds_to_nearest() -> void:
	var fx: int = FixedMath.from_float(1.5)
	assert_eq(fx, int(round(1.5 * FixedMath.SCALE)))
	assert_almost_eq(FixedMath.to_float(fx), 1.5, 1.0 / FixedMath.SCALE)


func test_to_int_floor_positive_and_negative() -> void:
	assert_eq(FixedMath.to_int_floor(FixedMath.from_float(3.9)), 3)
	assert_eq(FixedMath.to_int_floor(FixedMath.from_float(-3.1)), -4, "floor(-3.1) == -4")
	assert_eq(FixedMath.to_int_floor(FixedMath.from_int(5)), 5)


func test_to_int_round_half_away_from_zero() -> void:
	assert_eq(FixedMath.to_int_round(FixedMath.from_float(3.4)), 3)
	assert_eq(FixedMath.to_int_round(FixedMath.from_float(3.5)), 4)
	assert_eq(FixedMath.to_int_round(FixedMath.from_float(-3.4)), -3)
	assert_eq(FixedMath.to_int_round(FixedMath.from_float(-3.5)), -4)


func test_mul_matches_float_multiplication() -> void:
	var a: int = FixedMath.from_float(1.5)
	var b: int = FixedMath.from_float(2.5)
	var product: int = FixedMath.mul(a, b)
	assert_almost_eq(FixedMath.to_float(product), 3.75, 0.001)


func test_mul_by_one_is_identity() -> void:
	var a: int = FixedMath.from_float(12.375)
	assert_eq(FixedMath.mul(a, FixedMath.ONE), a)


func test_mul_by_zero_is_zero() -> void:
	var a: int = FixedMath.from_float(999.5)
	assert_eq(FixedMath.mul(a, FixedMath.ZERO), 0)


func test_div_matches_float_division() -> void:
	var a: int = FixedMath.from_float(10.0)
	var b: int = FixedMath.from_float(4.0)
	var quotient: int = FixedMath.div(a, b)
	assert_almost_eq(FixedMath.to_float(quotient), 2.5, 0.001)


func test_div_by_one_is_identity() -> void:
	var a: int = FixedMath.from_float(9.5)
	assert_eq(FixedMath.div(a, FixedMath.ONE), a)


func test_clamp_fx() -> void:
	var lo: int = FixedMath.from_int(0)
	var hi: int = FixedMath.from_int(100)
	assert_eq(FixedMath.clamp_fx(FixedMath.from_int(150), lo, hi), hi)
	assert_eq(FixedMath.clamp_fx(FixedMath.from_int(-10), lo, hi), lo)
	assert_eq(FixedMath.clamp_fx(FixedMath.from_int(50), lo, hi), FixedMath.from_int(50))


func test_lerp_fx_endpoints_and_midpoint() -> void:
	var a: int = FixedMath.from_int(0)
	var b: int = FixedMath.from_int(100)
	assert_eq(FixedMath.lerp_fx(a, b, 0), a)
	assert_eq(FixedMath.lerp_fx(a, b, FixedMath.ONE), b)
	assert_almost_eq(FixedMath.to_float(FixedMath.lerp_fx(a, b, FixedMath.HALF)), 50.0, 0.01)


func test_abs_and_sign() -> void:
	assert_eq(FixedMath.abs_fx(FixedMath.from_int(-5)), FixedMath.from_int(5))
	assert_eq(FixedMath.abs_fx(FixedMath.from_int(5)), FixedMath.from_int(5))
	assert_eq(FixedMath.sign_fx(FixedMath.from_int(-5)), -1)
	assert_eq(FixedMath.sign_fx(FixedMath.from_int(5)), 1)
	assert_eq(FixedMath.sign_fx(0), 0)


func test_from_percent_matches_from_int() -> void:
	assert_eq(FixedMath.from_percent(50), FixedMath.from_int(50))
	assert_almost_eq(FixedMath.to_float(FixedMath.from_percent(75)), 75.0, 0.0001)


func test_worked_example_mind_variable_midpoint() -> void:
	# master_plan.md §4.4: bands over a 0-100 scale, Murmur starts at 25.
	# Sanity-check the exact boundary a MindModel implementation will lean on.
	var murmur_threshold: int = FixedMath.from_int(25)
	var just_below: int = FixedMath.from_float(24.999)
	var just_above: int = FixedMath.from_float(25.001)
	assert_lt(just_below, murmur_threshold)
	assert_gt(just_above, murmur_threshold)
