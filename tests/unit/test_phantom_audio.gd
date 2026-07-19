extends AfterimageTestCase


func test_metadata_matches_master_plan_table() -> void:
	var op := PhantomAudio.new(Vector2i(0, 0), "footsteps")
	assert_eq(op.op_class, "PhantomAudio")
	assert_eq(op.tier, 1)
	assert_eq(op.cost, 8)


func test_apply_adds_a_phantom_event_even_with_no_real_sound_events() -> void:
	var op := PhantomAudio.new(Vector2i(1000, 2000), "footsteps")
	var percept: Dictionary = op.apply({"tick": 1, "actors": []})
	var events: Array = percept["sound_events"]
	assert_eq(events.size(), 1)
	assert_eq(events[0]["position"], Vector2i(1000, 2000))
	assert_eq(events[0]["rendered_tag"], "footsteps")
	assert_true(events[0]["is_phantom"])
	assert_eq(events[0]["source_id"], -1)


func test_resolve_grounded_removes_exactly_this_instances_phantom() -> void:
	var op_a := PhantomAudio.new(Vector2i(0, 0), "footsteps")
	var op_b := PhantomAudio.new(Vector2i(0, 0), "your name")

	var percept: Dictionary = op_a.apply({"tick": 1, "actors": []})
	percept = op_b.apply(percept)
	assert_eq((percept["sound_events"] as Array).size(), 2)

	var grounded: Dictionary = op_a.resolve_grounded(percept)
	var remaining: Array = grounded["sound_events"]
	assert_eq(remaining.size(), 1)
	assert_eq(remaining[0]["rendered_tag"], "your name")


func test_apply_does_not_mutate_the_input_snapshot() -> void:
	var op := PhantomAudio.new(Vector2i(0, 0), "footsteps")
	var truth: Dictionary = {"tick": 1, "actors": []}
	op.apply(truth)
	assert_false(truth.has("sound_events"))
