extends AfterimageTestCase

const PLAYER_ID := 1
const AI_ID := 2


func _snapshot_with_events() -> Dictionary:
	return {
		"tick": 1,
		"sound_events":
		[
			{"position": Vector2i(0, 0), "loudness": 90, "tag": "gunshot", "source_id": PLAYER_ID},
			{"position": Vector2i(5000, 0), "loudness": 40, "tag": "footsteps", "source_id": AI_ID},
		]
	}


func test_metadata_matches_master_plan_table() -> void:
	var op := AudioSwap.new(PLAYER_ID, "alarm")
	assert_eq(op.op_class, "AudioSwap")
	assert_eq(op.tier, 1)
	assert_eq(op.cost, 8)


func test_apply_swaps_only_the_targeted_source() -> void:
	var op := AudioSwap.new(PLAYER_ID, "alarm")
	var percept: Dictionary = op.apply(_snapshot_with_events())
	var events: Array = percept["sound_events"]
	assert_eq(events[0]["rendered_tag"], "alarm")
	assert_false(events[1].has("rendered_tag"))


func test_apply_is_a_no_op_without_sound_events_key() -> void:
	var op := AudioSwap.new(PLAYER_ID, "alarm")
	var snapshot: Dictionary = {"tick": 1, "actors": []}
	assert_eq(op.apply(snapshot), snapshot)


func test_resolve_grounded_restores_the_true_tag() -> void:
	var op := AudioSwap.new(PLAYER_ID, "alarm")
	var percept: Dictionary = op.apply(_snapshot_with_events())
	var grounded: Dictionary = op.resolve_grounded(percept)
	assert_eq(grounded["sound_events"][0]["rendered_tag"], "gunshot")


func test_apply_does_not_mutate_the_input_snapshot() -> void:
	var op := AudioSwap.new(PLAYER_ID, "alarm")
	var truth: Dictionary = _snapshot_with_events()
	op.apply(truth)
	assert_false(truth["sound_events"][0].has("rendered_tag"))
