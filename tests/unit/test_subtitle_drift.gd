extends AfterimageTestCase

const TRUE_LINE := "the door is unlocked"
const DRIFTED_LINE := "the store is unlocked"


func _snapshot_with_subtitle() -> Dictionary:
	return {"tick": 1, "subtitle": {"speaker_id": 7, "true_text": TRUE_LINE}}


func test_metadata_matches_master_plan_table() -> void:
	var op := SubtitleDrift.new(DRIFTED_LINE)
	assert_eq(op.op_class, "SubtitleDrift")
	assert_eq(op.tier, 1)
	assert_eq(op.cost, 5)


func test_apply_renders_the_drifted_text_not_the_true_text() -> void:
	var op := SubtitleDrift.new(DRIFTED_LINE)
	var percept: Dictionary = op.apply(_snapshot_with_subtitle())
	assert_eq(percept["subtitle"]["rendered_text"], DRIFTED_LINE)
	assert_false(percept["subtitle"]["grounded"])


func test_apply_is_a_no_op_without_a_subtitle_key() -> void:
	var op := SubtitleDrift.new(DRIFTED_LINE)
	var snapshot: Dictionary = {"tick": 1, "actors": []}
	assert_eq(op.apply(snapshot), snapshot)


func test_resolve_grounded_restores_the_true_text() -> void:
	var op := SubtitleDrift.new(DRIFTED_LINE)
	var percept: Dictionary = op.apply(_snapshot_with_subtitle())
	var grounded: Dictionary = op.resolve_grounded(percept)
	assert_eq(grounded["subtitle"]["rendered_text"], TRUE_LINE)
	assert_true(grounded["subtitle"]["grounded"])


func test_apply_does_not_mutate_the_input_snapshot() -> void:
	var op := SubtitleDrift.new(DRIFTED_LINE)
	var truth: Dictionary = _snapshot_with_subtitle()
	op.apply(truth)
	assert_eq(truth["subtitle"]["true_text"], TRUE_LINE)
	assert_false(truth["subtitle"].has("rendered_text"))
