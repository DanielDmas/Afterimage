extends AfterimageTestCase


func test_metadata_matches_master_plan_table() -> void:
	var op := PhantomAudio.new(Vector2i(0, 0), "footsteps")
	assert_eq(op.op_class, "PhantomAudio")
	assert_eq(op.tier, 1)
	assert_eq(op.cost, 8)


## Regression: PhantomAudio is one of FairnessAuditor.PHANTOM_OP_CLASSES,
## which requires the rule-1 tag ("phantoms never deal damage/block") —
## this class's own fairness_tags never actually declared it (a real gap
## the original FairnessAuditor test suite never caught, since it only
## ever exercised hand-built fixtures with deliberately complete tags,
## never PhantomAudio's own real, actual ones — caught post-arc by
## tests/unit/test_mission_content_fairness.gd running real content
## through the real classes, docs/review_and_forward_plan.md F1).
func test_declares_rule_1_and_rule_3_fairness_tags() -> void:
	var op := PhantomAudio.new(Vector2i(0, 0), "footsteps")
	assert_true(op.fairness_tags.has("charter_rule_1_never_damages_never_blocks"))
	assert_true(op.fairness_tags.has("charter_rule_3_inputs_never_distorted"))


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
