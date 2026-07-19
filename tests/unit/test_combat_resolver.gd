extends AfterimageTestCase

## resolve_fire's cone-boundary numbers below were checked against the
## exact integer formula VisionCone.point_in_cone() implements (see that
## class's doc) before being chosen, the same "verify the exact arithmetic,
## then write the test" discipline test_vision_cone.gd itself follows:
## with aim_dir (100, 0) and AIM_COS_SQ_HALF_ANGLE_FX, a target at
## (5000, 100) sits at ~1.146° off-axis (inside the 3° cone) and a target
## at (5000, 400) sits at ~4.57° off-axis (outside it).


func _target(id: int, position: Vector2i) -> Dictionary:
	return {"id": id, "position": position}


func test_target_directly_ahead_in_range_and_clear_is_hit() -> void:
	var weapon := Weapon.new(1, 10, 50, 10000)
	var grid := CollisionGrid.new(500)
	var hit: int = CombatResolver.resolve_fire(
		Vector2i(0, 0), Vector2i(100, 0), weapon, [_target(1, Vector2i(5000, 0))], grid
	)
	assert_eq(hit, 1)


func test_target_beyond_weapon_range_is_not_hit() -> void:
	var weapon := Weapon.new(1, 10, 50, 10000)
	var grid := CollisionGrid.new(500)
	var hit: int = CombatResolver.resolve_fire(
		Vector2i(0, 0), Vector2i(100, 0), weapon, [_target(1, Vector2i(20000, 0))], grid
	)
	assert_eq(hit, -1)


func test_target_within_the_narrow_aim_cone_is_hit() -> void:
	var weapon := Weapon.new(1, 10, 50, 10000)
	var grid := CollisionGrid.new(500)
	var hit: int = CombatResolver.resolve_fire(
		Vector2i(0, 0), Vector2i(100, 0), weapon, [_target(1, Vector2i(5000, 100))], grid
	)
	assert_eq(hit, 1)


func test_target_just_outside_the_narrow_aim_cone_is_not_hit() -> void:
	var weapon := Weapon.new(1, 10, 50, 10000)
	var grid := CollisionGrid.new(500)
	var hit: int = CombatResolver.resolve_fire(
		Vector2i(0, 0), Vector2i(100, 0), weapon, [_target(1, Vector2i(5000, 400))], grid
	)
	assert_eq(hit, -1)


func test_target_directly_behind_is_not_hit() -> void:
	var weapon := Weapon.new(1, 10, 50, 10000)
	var grid := CollisionGrid.new(500)
	var hit: int = CombatResolver.resolve_fire(
		Vector2i(0, 0), Vector2i(100, 0), weapon, [_target(1, Vector2i(-5000, 0))], grid
	)
	assert_eq(hit, -1)


func test_target_blocked_by_a_wall_is_not_hit() -> void:
	var weapon := Weapon.new(1, 10, 50, 10000)
	var grid := CollisionGrid.new(500)
	grid.set_cell_blocked(Vector2i(2, 0), true)  # directly between shooter and target
	var hit: int = CombatResolver.resolve_fire(
		Vector2i(0, 250), Vector2i(100, 0), weapon, [_target(1, Vector2i(2000, 250))], grid
	)
	assert_eq(hit, -1)


func test_nearest_of_multiple_hittable_targets_wins_regardless_of_list_order() -> void:
	var weapon := Weapon.new(1, 10, 50, 10000)
	var grid := CollisionGrid.new(500)
	var near := _target(1, Vector2i(3000, 0))
	var far := _target(2, Vector2i(5000, 0))

	var hit_a: int = CombatResolver.resolve_fire(
		Vector2i(0, 0), Vector2i(100, 0), weapon, [near, far], grid
	)
	var hit_b: int = CombatResolver.resolve_fire(
		Vector2i(0, 0), Vector2i(100, 0), weapon, [far, near], grid
	)
	assert_eq(hit_a, 1)
	assert_eq(hit_b, 1)


func test_no_targets_yields_no_hit() -> void:
	var weapon := Weapon.new(1, 10, 50, 10000)
	var grid := CollisionGrid.new(500)
	assert_eq(CombatResolver.resolve_fire(Vector2i(0, 0), Vector2i(100, 0), weapon, [], grid), -1)


func test_takedown_at_exact_max_range_succeeds() -> void:
	var grid := CollisionGrid.new(500)
	var hit: bool = CombatResolver.resolve_takedown(
		Vector2i(0, 0), Vector2i(CombatResolver.TAKEDOWN_RANGE_MM, 0), grid
	)
	assert_true(hit)


func test_takedown_just_beyond_max_range_fails() -> void:
	var grid := CollisionGrid.new(500)
	var hit: bool = CombatResolver.resolve_takedown(
		Vector2i(0, 0), Vector2i(CombatResolver.TAKEDOWN_RANGE_MM + 1, 0), grid
	)
	assert_false(hit)


func test_takedown_blocked_by_a_wall_within_range_fails() -> void:
	var grid := CollisionGrid.new(500)
	# (499,250) is cell (0,0), (1000,250) is cell (2,0): 501mm apart (within
	# the 900mm takedown range) with cell (1,0) strictly between them.
	grid.set_cell_blocked(Vector2i(1, 0), true)
	var hit: bool = CombatResolver.resolve_takedown(Vector2i(499, 250), Vector2i(1000, 250), grid)
	assert_false(hit)


func test_throw_at_exact_max_range_lands() -> void:
	var result: Dictionary = CombatResolver.resolve_throw(
		Vector2i(0, 0), Vector2i(CombatResolver.THROW_MAX_RANGE_MM, 0)
	)
	assert_true(result["landed"])
	assert_eq(result["position"], Vector2i(CombatResolver.THROW_MAX_RANGE_MM, 0))
	assert_eq(result["noise_loudness"], CombatResolver.THROW_NOISE_LOUDNESS)


func test_throw_just_beyond_max_range_fails_to_land() -> void:
	var result: Dictionary = CombatResolver.resolve_throw(
		Vector2i(0, 0), Vector2i(CombatResolver.THROW_MAX_RANGE_MM + 1, 0)
	)
	assert_false(result["landed"])


func test_hearing_range_scales_linearly_with_loudness() -> void:
	assert_eq(CombatResolver.hearing_range_mm(60), 6000)
	assert_eq(CombatResolver.hearing_range_mm(0), 0)
	assert_eq(CombatResolver.hearing_range_mm(-5), 0)


func test_noise_heard_within_range() -> void:
	assert_true(CombatResolver.is_noise_heard_at(Vector2i(0, 0), Vector2i(6000, 0), 60))


func test_noise_not_heard_just_beyond_range() -> void:
	assert_false(CombatResolver.is_noise_heard_at(Vector2i(0, 0), Vector2i(6001, 0), 60))


func test_silent_noise_is_never_heard_even_at_zero_distance() -> void:
	assert_false(CombatResolver.is_noise_heard_at(Vector2i(0, 0), Vector2i(0, 0), 0))
