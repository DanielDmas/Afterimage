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


## A trivial test-only DistortionOp (Pass 10) whose apply()/
## resolve_grounded() outputs are trivially distinguishable, purely to
## prove render() picks the right one based on "ground_just_completed".
class _TaggedOp:
	extends DistortionOp

	func _init() -> void:
		op_class = "TaggedOp"
		tier = 1
		cost = 0
		dramatic_intent = "doubt"

	func apply(snapshot: Dictionary) -> Dictionary:
		var out: Dictionary = snapshot.duplicate(true)
		out["state"] = "distorted"
		return out

	func resolve_grounded(snapshot: Dictionary) -> Dictionary:
		var out: Dictionary = snapshot.duplicate(true)
		out["state"] = "grounded"
		return out


func test_render_calls_apply_when_ground_did_not_just_complete() -> void:
	var truth: Dictionary = {"tick": 1, "actors": [], "ground_just_completed": false}
	var percept: Dictionary = PerceptRenderer.render(truth, [_TaggedOp.new()])
	assert_eq(percept["state"], "distorted")


func test_render_calls_resolve_grounded_when_ground_just_completed() -> void:
	var truth: Dictionary = {"tick": 1, "actors": [], "ground_just_completed": true}
	var percept: Dictionary = PerceptRenderer.render(truth, [_TaggedOp.new()])
	assert_eq(percept["state"], "grounded")


func test_render_defaults_to_apply_when_ground_flag_is_absent() -> void:
	var truth: Dictionary = {"tick": 1, "actors": []}
	var percept: Dictionary = PerceptRenderer.render(truth, [_TaggedOp.new()])
	assert_eq(percept["state"], "distorted")
