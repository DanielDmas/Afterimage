## Replay Theater v0 — data model only (master_plan.md §4.12: "synchronized
## dual-pane replay — truth view and percept view — with a scrubber,
## tick-accurate, driven by re-simulation"). No UI exists before Pass 19;
## this class is the reconstruction + checkpoint-caching mechanism a
## future scrubber widget will read from.
##
## Deliberately takes a `scenario_factory: Callable` rather than a typed
## sim-layer parameter: the class that Callable constructs (TruthSim) lives
## under src/sim/, and nothing under src/percept/ may reference a
## src/sim/ class by name (tools/percept_truth_boundary_lint.py, Pass 8).
## The factory is called exactly once, then only `.step(frame)` and
## `.capture_percept_snapshot()` are called on its result — both duck-typed,
## so this file never writes the forbidden identifier anywhere. `ReplayLog`
## lives under src/core/, outside that denylist, so it's referenced
## directly.
##
## Checkpoint strategy (the AC's "scrub-to-any-point ≤ 100 ms"): every
## tick's `capture_percept_snapshot()` is precomputed once, in one forward
## pass, and cached — turning every later `truth_view_at()` call into an
## O(1) array lookup rather than a re-simulation. This is a real memory-
## for-speed trade, not a sparse checkpoint-plus-partial-resume scheme:
## TruthSim has no `capture_full_state()`/restore mechanism to resume
## mid-simulation from (only the percept-safe, read-only
## `capture_percept_snapshot()`), so "resume from the nearest checkpoint"
## isn't buildable yet without that — deferred until real memory profiling
## (Pass 19+) shows full-tick caching doesn't scale to actual mission
## lengths.
class_name ReplayTheater
extends RefCounted

var _truth_snapshots: Array[Dictionary] = []
var _op_timeline: Array[OpTimelineSpan] = []


func _init(
	scenario_factory: Callable, replay: ReplayLog, op_timeline: Array[OpTimelineSpan] = []
) -> void:
	_op_timeline = op_timeline
	var sim: Variant = scenario_factory.call()
	for frame: InputFrame in replay.frames:
		sim.step(frame)
		_truth_snapshots.append(sim.capture_percept_snapshot())


func tick_count() -> int:
	return _truth_snapshots.size()


## Ticks are 1-indexed, matching InputFrame's own tick numbering
## throughout this codebase (tick 1 is the result of the first step()).
func truth_view_at(tick: int) -> Dictionary:
	assert(
		tick >= 1 and tick <= tick_count(),
		"ReplayTheater: tick %d out of range [1, %d]" % [tick, tick_count()]
	)
	return _truth_snapshots[tick - 1].duplicate(true)


func spans_active_at(tick: int) -> Array[OpTimelineSpan]:
	var active: Array[OpTimelineSpan] = []
	for span: OpTimelineSpan in _op_timeline:
		if span.is_active_at(tick):
			active.append(span)
	return active


## `active_ops` are already-instantiated PerceptOp/DistortionOp instances
## for whatever `spans_active_at(tick)` says should be live this tick — the
## caller supplies them (turning an OpTimelineSpan's op_class String into a
## real op instance is a future content-pipeline factory this pass doesn't
## build, the same gap Pass 13 already documented for DistortionDirector's
## purchase records).
func percept_view_at(tick: int, active_ops: Array) -> Dictionary:
	return PerceptRenderer.render(truth_view_at(tick), active_ops)


func dual_view_at(tick: int, active_ops: Array) -> Dictionary:
	return {"truth": truth_view_at(tick), "percept": percept_view_at(tick, active_ops)}


func op_timeline() -> Array[OpTimelineSpan]:
	return _op_timeline.duplicate()
