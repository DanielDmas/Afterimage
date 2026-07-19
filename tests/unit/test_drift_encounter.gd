extends AfterimageTestCase

const OUTSIDE_POSITION: Vector2i = Vector2i(0, 0)
const INSIDE_POSITION: Vector2i = DriftEncounter.TRIGGER_POINT_MM


func test_starts_waiting_and_ignores_a_position_outside_the_trigger_radius() -> void:
	var encounter := DriftEncounter.new()
	assert_true(encounter.is_waiting())

	encounter.maybe_trigger(OUTSIDE_POSITION, 1)
	assert_true(encounter.is_waiting())
	assert_null(encounter.op)


func test_triggers_exactly_on_entering_the_radius_and_never_retriggers() -> void:
	var encounter := DriftEncounter.new()
	encounter.maybe_trigger(INSIDE_POSITION, 42)
	assert_true(encounter.is_active())
	assert_eq(encounter.start_tick, 42)
	assert_eq(encounter.op.op_class, "SubtitleDrift")

	# A second call, even from a different position, must not re-arm.
	encounter.maybe_trigger(OUTSIDE_POSITION, 43)
	assert_true(encounter.is_active())
	assert_eq(encounter.start_tick, 42)


func test_advance_is_a_no_op_before_triggering() -> void:
	var encounter := DriftEncounter.new()
	encounter.advance(100, true)
	assert_true(encounter.is_waiting())


func test_ground_completion_reveals_immediately_and_marks_grounded() -> void:
	var encounter := DriftEncounter.new()
	encounter.maybe_trigger(INSIDE_POSITION, 0)
	encounter.advance(10, false)
	assert_true(encounter.is_active())

	encounter.advance(11, true)
	assert_true(encounter.is_revealed())
	assert_true(encounter.was_grounded)


func test_display_window_reveals_without_grounding_after_it_elapses() -> void:
	var encounter := DriftEncounter.new()
	encounter.maybe_trigger(INSIDE_POSITION, 0)

	encounter.advance(DriftEncounter.DISPLAY_DURATION_TICKS - 1, false)
	assert_true(encounter.is_active())

	encounter.advance(DriftEncounter.DISPLAY_DURATION_TICKS, false)
	assert_true(encounter.is_revealed())
	assert_false(encounter.was_grounded)


func test_subtitle_truth_fact_carries_the_true_text() -> void:
	var encounter := DriftEncounter.new()
	var fact: Dictionary = encounter.subtitle_truth_fact()
	assert_eq(fact["true_text"], DriftEncounter.TRUE_TEXT)


## The full pipeline: a drifted subtitle actually renders drifted, and
## resolves to true once grounded — proving DriftEncounter composes
## correctly with the real SubtitleDrift/PerceptRenderer classes, not just
## its own state machine in isolation.
func test_percept_render_reflects_drift_then_ground_resolution() -> void:
	var encounter := DriftEncounter.new()
	encounter.maybe_trigger(INSIDE_POSITION, 0)

	var truth_snapshot: Dictionary = {"tick": 5, "ground_just_completed": false}
	truth_snapshot["subtitle"] = encounter.subtitle_truth_fact()
	var percept: Dictionary = PerceptRenderer.render(truth_snapshot, [encounter.op])
	assert_eq(percept["subtitle"]["rendered_text"], DriftEncounter.DRIFTED_TEXT)
	assert_false(percept["subtitle"]["grounded"])

	var grounded_snapshot: Dictionary = truth_snapshot.duplicate(true)
	grounded_snapshot["ground_just_completed"] = true
	var grounded_percept: Dictionary = PerceptRenderer.render(grounded_snapshot, [encounter.op])
	assert_eq(grounded_percept["subtitle"]["rendered_text"], DriftEncounter.TRUE_TEXT)
	assert_true(grounded_percept["subtitle"]["grounded"])
