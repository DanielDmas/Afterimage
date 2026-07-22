extends AfterimageTestCase

const OUTSIDE_POSITION: Vector2i = Vector2i(5900, 3900)
const INSIDE_POSITION: Vector2i = PhantomEncounter.TRIGGER_POINT_MM


func test_starts_waiting_and_ignores_a_position_outside_the_trigger_radius() -> void:
	var encounter := PhantomEncounter.new()
	assert_true(encounter.is_waiting())

	encounter.maybe_trigger(OUTSIDE_POSITION, 1)
	assert_true(encounter.is_waiting())
	assert_null(encounter.op)


func test_triggers_exactly_on_entering_the_radius_and_never_retriggers() -> void:
	var encounter := PhantomEncounter.new()
	encounter.maybe_trigger(INSIDE_POSITION, 42)
	assert_true(encounter.is_active())
	assert_eq(encounter.start_tick, 42)
	assert_eq(encounter.op.op_class, "PhantomEntity")

	# A second call, even from a different position, must not re-arm.
	encounter.maybe_trigger(OUTSIDE_POSITION, 43)
	assert_true(encounter.is_active())
	assert_eq(encounter.start_tick, 42)


func test_advance_is_a_no_op_before_triggering() -> void:
	var encounter := PhantomEncounter.new()
	encounter.advance(100, true)
	assert_true(encounter.is_waiting())


func test_ground_completion_reveals_immediately_and_marks_grounded() -> void:
	var encounter := PhantomEncounter.new()
	encounter.maybe_trigger(INSIDE_POSITION, 0)
	encounter.advance(10, false)
	assert_true(encounter.is_active())

	encounter.advance(11, true)
	assert_true(encounter.is_revealed())
	assert_true(encounter.was_grounded)


func test_display_window_reveals_without_grounding_after_it_elapses() -> void:
	var encounter := PhantomEncounter.new()
	encounter.maybe_trigger(INSIDE_POSITION, 0)

	encounter.advance(PhantomEncounter.DISPLAY_DURATION_TICKS - 1, false)
	assert_true(encounter.is_active())

	encounter.advance(PhantomEncounter.DISPLAY_DURATION_TICKS, false)
	assert_true(encounter.is_revealed())
	assert_false(encounter.was_grounded)


## The full pipeline: the phantom actually renders into the percept
## actors list while active, and disappears once grounded — proving
## PhantomEncounter composes correctly with the real PhantomEntity/
## PerceptRenderer classes, not just its own state machine in isolation.
func test_percept_render_shows_the_phantom_then_resolves_it_on_ground() -> void:
	var encounter := PhantomEncounter.new()
	encounter.maybe_trigger(INSIDE_POSITION, 0)

	var truth_snapshot: Dictionary = {"tick": 5, "actors": [], "ground_just_completed": false}
	var percept: Dictionary = PerceptRenderer.render(truth_snapshot, [encounter.op])
	var actors: Array = percept["actors"]
	assert_eq(actors.size(), 1)
	assert_true(actors[0]["is_phantom"])
	assert_eq(actors[0]["position"], PhantomEncounter.PHANTOM_POSITION_MM)

	var grounded_snapshot: Dictionary = truth_snapshot.duplicate(true)
	grounded_snapshot["ground_just_completed"] = true
	var grounded_percept: Dictionary = PerceptRenderer.render(grounded_snapshot, [encounter.op])
	assert_eq((grounded_percept["actors"] as Array).size(), 0)
