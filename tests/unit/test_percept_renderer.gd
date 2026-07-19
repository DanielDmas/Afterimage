extends AfterimageTestCase


## A trivial test-only op — not a real DistortionOp (those are Pass 9's
## job, master_plan §4.2) — that appends to a marker trail, purely to
## prove the pipeline actually calls apply() on each op in order.
class _MarkerOp:
	extends PerceptOp

	var marker: String

	func _init(p_marker: String) -> void:
		marker = p_marker

	func apply(snapshot: Dictionary) -> Dictionary:
		var trail: Array = snapshot.get("_trail", [])
		trail.append(marker)
		snapshot["_trail"] = trail
		return snapshot


func test_render_with_no_ops_returns_an_equal_snapshot() -> void:
	var truth: Dictionary = {"tick": 1, "actors": []}
	assert_eq(PerceptRenderer.render(truth, []), truth)


func test_render_does_not_mutate_the_input_snapshot() -> void:
	var truth: Dictionary = {"tick": 1, "actors": [{"id": 1, "position": Vector2i(0, 0)}]}
	var ops: Array = [_MarkerOp.new("a")]
	PerceptRenderer.render(truth, ops)
	assert_false(truth.has("_trail"))


func test_render_applies_ops_in_order() -> void:
	var truth: Dictionary = {"tick": 1, "actors": []}
	var ops: Array = [_MarkerOp.new("first"), _MarkerOp.new("second")]
	var percept: Dictionary = PerceptRenderer.render(truth, ops)
	assert_eq(percept["_trail"], ["first", "second"])
