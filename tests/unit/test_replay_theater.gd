extends AfterimageTestCase


## A trivial test-only op — the same pattern test_percept_renderer.gd's
## _MarkerOp established in Pass 8 — proving percept_view_at()/
## dual_view_at() actually delegate to PerceptRenderer.render() rather
## than reimplementing dispatch logic of their own.
class _MarkerOp:
	extends PerceptOp

	var marker: String

	func _init(p_marker: String) -> void:
		marker = p_marker

	func apply(snapshot: Dictionary) -> Dictionary:
		var out: Dictionary = snapshot.duplicate(true)
		out["_marker"] = marker
		return out


func _build_scenario() -> Callable:
	return func() -> TruthSim: return TruthSim.new(500, Vector2i(0, 0), 300)


func _movement_replay(tick_count: int) -> ReplayLog:
	var replay := ReplayLog.new(1, "test-fixture")
	for i: int in range(tick_count):
		replay.record(InputFrame.new(i + 1, {"move_x": 50}))
	return replay


func test_tick_count_matches_the_replay_length() -> void:
	var theater := ReplayTheater.new(_build_scenario(), _movement_replay(10))
	assert_eq(theater.tick_count(), 10)


## The real correctness proof: the cached snapshot at tick 5 must equal
## what independently re-simulating 5 ticks from a fresh scenario produces
## — proving the cache isn't just returning *something*, but the actual
## tick-accurate state re-simulation would have produced.
func test_truth_view_at_matches_independent_resimulation() -> void:
	var replay: ReplayLog = _movement_replay(10)
	var theater := ReplayTheater.new(_build_scenario(), replay)

	var reference_sim: TruthSim = _build_scenario().call()
	for i: int in range(5):
		reference_sim.step(replay.frames[i])

	assert_eq(theater.truth_view_at(5), reference_sim.capture_percept_snapshot())


func test_truth_view_at_returns_a_copy_not_a_live_reference() -> void:
	var theater := ReplayTheater.new(_build_scenario(), _movement_replay(3))
	var view: Dictionary = theater.truth_view_at(1)
	view["tampered"] = true
	assert_false(theater.truth_view_at(1).has("tampered"))


func test_spans_active_at_filters_by_tick_range() -> void:
	var spans: Array[OpTimelineSpan] = [
		OpTimelineSpan.new("AudioSwap", 1, "acute_stress", 2, 5),
		OpTimelineSpan.new("PhantomAudio", 1, "moral_injury", 6, 8),
	]
	var theater := ReplayTheater.new(_build_scenario(), _movement_replay(10), spans)

	assert_eq(theater.spans_active_at(1).size(), 0)
	assert_eq(theater.spans_active_at(3).size(), 1)
	assert_eq(theater.spans_active_at(3)[0].op_class, "AudioSwap")
	assert_eq(theater.spans_active_at(7).size(), 1)
	assert_eq(theater.spans_active_at(7)[0].op_class, "PhantomAudio")
	assert_eq(theater.spans_active_at(10).size(), 0)


func test_op_timeline_returns_a_copy_not_a_live_reference() -> void:
	var spans: Array[OpTimelineSpan] = [OpTimelineSpan.new("AudioSwap", 1, "acute_stress", 1, 3)]
	var theater := ReplayTheater.new(_build_scenario(), _movement_replay(3), spans)
	var timeline_copy: Array[OpTimelineSpan] = theater.op_timeline()
	timeline_copy.clear()
	assert_eq(theater.op_timeline().size(), 1)


func test_percept_view_at_delegates_to_percept_renderer() -> void:
	var theater := ReplayTheater.new(_build_scenario(), _movement_replay(3))
	var percept: Dictionary = theater.percept_view_at(2, [_MarkerOp.new("hello")])
	assert_eq(percept["_marker"], "hello")


func test_dual_view_at_exposes_matching_truth_and_percept() -> void:
	var theater := ReplayTheater.new(_build_scenario(), _movement_replay(3))
	var dual: Dictionary = theater.dual_view_at(2, [_MarkerOp.new("hello")])
	assert_eq(dual["truth"], theater.truth_view_at(2))
	assert_eq(dual["percept"]["_marker"], "hello")
	assert_false(dual["truth"].has("_marker"))
