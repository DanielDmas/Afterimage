extends AfterimageTestCase


func test_initial_state_can_activate() -> void:
	var focus := FocusState.new()
	assert_true(focus.can_activate())
	assert_false(focus.is_active())
	assert_false(focus.is_on_cooldown())
	assert_eq(focus.activation_count, 0)


func test_activate_succeeds_and_sets_active() -> void:
	var focus := FocusState.new()
	assert_true(focus.activate())
	assert_true(focus.is_active())
	assert_eq(focus.activation_count, 1)


func test_cannot_activate_while_already_active() -> void:
	var focus := FocusState.new()
	focus.activate()
	assert_false(focus.can_activate())
	assert_false(focus.activate())
	assert_eq(focus.activation_count, 1)


func test_becomes_inactive_and_enters_cooldown_after_duration_elapses() -> void:
	var focus := FocusState.new()
	focus.activate()
	for _i: int in range(FocusState.DURATION_TICKS - 1):
		focus.advance_tick()
	assert_true(focus.is_active(), "still active with one tick left")
	focus.advance_tick()
	assert_false(focus.is_active())
	assert_true(focus.is_on_cooldown())


func test_cannot_activate_during_cooldown() -> void:
	var focus := FocusState.new()
	focus.activate()
	for _i: int in range(FocusState.DURATION_TICKS):
		focus.advance_tick()
	assert_true(focus.is_on_cooldown())
	assert_false(focus.can_activate())
	assert_false(focus.activate())
	assert_eq(focus.activation_count, 1)


func test_can_activate_again_once_cooldown_elapses() -> void:
	var focus := FocusState.new()
	focus.activate()
	for _i: int in range(FocusState.DURATION_TICKS + FocusState.COOLDOWN_TICKS):
		focus.advance_tick()
	assert_true(focus.can_activate())
	assert_true(focus.activate())
	assert_eq(focus.activation_count, 2)


func test_advance_tick_with_nothing_active_is_a_no_op() -> void:
	var focus := FocusState.new()
	focus.advance_tick()
	focus.advance_tick()
	assert_true(focus.can_activate())
	assert_eq(focus.activation_count, 0)
