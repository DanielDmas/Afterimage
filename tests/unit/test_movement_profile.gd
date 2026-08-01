extends AfterimageTestCase


func test_speed_mm_per_tick_matches_named_constants() -> void:
	assert_eq(
		MovementProfile.speed_mm_per_tick(MovementProfile.Mode.WALK),
		MovementProfile.WALK_MM_PER_TICK
	)
	assert_eq(
		MovementProfile.speed_mm_per_tick(MovementProfile.Mode.SPRINT),
		MovementProfile.SPRINT_MM_PER_TICK
	)
	assert_eq(
		MovementProfile.speed_mm_per_tick(MovementProfile.Mode.CROUCH),
		MovementProfile.CROUCH_MM_PER_TICK
	)


func test_sprint_is_faster_than_walk_which_is_faster_than_crouch() -> void:
	assert_true(MovementProfile.SPRINT_MM_PER_TICK > MovementProfile.WALK_MM_PER_TICK)
	assert_true(MovementProfile.WALK_MM_PER_TICK > MovementProfile.CROUCH_MM_PER_TICK)


func test_only_sprint_makes_noise() -> void:
	assert_eq(MovementProfile.noise_loudness(MovementProfile.Mode.WALK), 0)
	assert_eq(MovementProfile.noise_loudness(MovementProfile.Mode.CROUCH), 0)
	assert_eq(
		MovementProfile.noise_loudness(MovementProfile.Mode.SPRINT),
		MovementProfile.SPRINT_NOISE_LOUDNESS
	)


func test_zero_direction_resolves_to_zero_delta() -> void:
	assert_eq(
		MovementProfile.resolve_delta(Vector2i.ZERO, MovementProfile.Mode.WALK), Vector2i.ZERO
	)


func test_cardinal_directions_resolve_to_full_speed_on_one_axis() -> void:
	var speed: int = MovementProfile.WALK_MM_PER_TICK
	assert_eq(
		MovementProfile.resolve_delta(Vector2i(1, 0), MovementProfile.Mode.WALK), Vector2i(speed, 0)
	)
	assert_eq(
		MovementProfile.resolve_delta(Vector2i(-1, 0), MovementProfile.Mode.WALK),
		Vector2i(-speed, 0)
	)
	assert_eq(
		MovementProfile.resolve_delta(Vector2i(0, 1), MovementProfile.Mode.WALK), Vector2i(0, speed)
	)
	assert_eq(
		MovementProfile.resolve_delta(Vector2i(0, -1), MovementProfile.Mode.WALK),
		Vector2i(0, -speed)
	)


func test_diagonal_direction_applies_full_speed_to_both_axes() -> void:
	# Documented in the class doc: diagonal movement is not speed-
	# normalized in this pass, so a diagonal direction gets full per-tick
	# speed on both axes rather than a normalized (slower) diagonal.
	var speed: int = MovementProfile.SPRINT_MM_PER_TICK
	assert_eq(
		MovementProfile.resolve_delta(Vector2i(1, -1), MovementProfile.Mode.SPRINT),
		Vector2i(speed, -speed)
	)


func test_out_of_range_direction_components_are_clamped() -> void:
	var speed: int = MovementProfile.CROUCH_MM_PER_TICK
	assert_eq(
		MovementProfile.resolve_delta(Vector2i(5, -9), MovementProfile.Mode.CROUCH),
		Vector2i(speed, -speed)
	)
