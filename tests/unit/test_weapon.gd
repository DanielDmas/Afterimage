extends AfterimageTestCase


func test_starts_with_a_full_magazine() -> void:
	var w := Weapon.new(12, 60, 90, 12000)
	assert_eq(w.ammo_in_magazine, 12)
	assert_false(w.is_reloading())
	assert_true(w.can_fire())


func test_fire_decrements_ammo_and_returns_true() -> void:
	var w := Weapon.new(2, 60, 90, 12000)
	assert_true(w.fire())
	assert_eq(w.ammo_in_magazine, 1)


func test_fire_at_zero_ammo_fails_and_leaves_state_untouched() -> void:
	var w := Weapon.new(1, 60, 90, 12000)
	assert_true(w.fire())
	assert_eq(w.ammo_in_magazine, 0)
	assert_false(w.can_fire())
	assert_false(w.fire())
	assert_eq(w.ammo_in_magazine, 0)


func test_cannot_fire_while_reloading() -> void:
	var w := Weapon.new(6, 10, 90, 12000)
	w.fire()
	w.start_reload()
	assert_true(w.is_reloading())
	assert_false(w.can_fire())
	assert_false(w.fire())


func test_start_reload_is_a_no_op_when_already_full() -> void:
	var w := Weapon.new(6, 10, 90, 12000)
	w.start_reload()
	assert_false(w.is_reloading())


func test_start_reload_is_a_no_op_when_already_reloading() -> void:
	var w := Weapon.new(6, 10, 90, 12000)
	w.fire()
	w.start_reload()
	w.advance_tick()  # 9 ticks left
	w.start_reload()  # should not reset the countdown
	for _i: int in range(9):
		w.advance_tick()
	assert_eq(w.ammo_in_magazine, 6)


func test_advance_tick_counts_down_and_refills_exactly_on_completion() -> void:
	var w := Weapon.new(6, 3, 90, 12000)
	w.fire()
	w.fire()
	w.start_reload()
	assert_true(w.is_reloading())
	w.advance_tick()
	assert_true(w.is_reloading())
	assert_eq(w.ammo_in_magazine, 4)  # not refilled until the countdown hits zero
	w.advance_tick()
	assert_true(w.is_reloading())
	w.advance_tick()
	assert_false(w.is_reloading())
	assert_eq(w.ammo_in_magazine, 6)


func test_advance_tick_without_reloading_is_a_no_op() -> void:
	var w := Weapon.new(6, 3, 90, 12000)
	w.advance_tick()
	assert_eq(w.ammo_in_magazine, 6)
	assert_false(w.is_reloading())


func test_cz75_is_loud_and_reliable() -> void:
	var w := Weapon.cz75()
	assert_eq(w.magazine_capacity, 12)
	assert_true(w.lethal)
	assert_true(w.fire_noise_loudness > Weapon.suppressed_32().fire_noise_loudness)


func test_suppressed_32_is_quieter_and_holds_less_ammo_than_cz75() -> void:
	var quiet := Weapon.suppressed_32()
	var loud := Weapon.cz75()
	assert_true(quiet.fire_noise_loudness < loud.fire_noise_loudness)
	assert_true(quiet.magazine_capacity < loud.magazine_capacity)
