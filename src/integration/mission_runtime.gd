## The runtime distortion spine (docs/forward_dev_plan.md Phase B): owns a
## real `MissionPackage`, a seeded `DistortionDirector`, and the `MindModel`
## whose band state sizes the Director's budget — the first class that
## actually turns a loaded mission's weighted deck into live, active
## `DistortionOp` instances tick by tick, rather than a scene hand-scripting
## its own encounters (`DriftEncounter`/`PhantomEncounter`) or a test
## building ops directly.
##
## `step()` is the whole contract: call once per tick with the current tick
## number and whether Ground just completed. On a normal tick, it attempts
## one purchase against the deck (a no-op most ticks —
## `DistortionDirector.purchase_one()` itself gates on affordability/
## spacing/the density cap) and, on a success, builds the live op via
## `OpFactory.build(package.deck[record["deck_index"]])` and appends it to
## `active_ops` — the exact Array a caller hands straight to
## `PerceptRenderer.render()`. On the tick Ground completes, every
## currently active op is resolved: the Director is told
## (`notify_ground_resolved`/`notify_op_deactivated`, §4.3's "refund 0, but
## the op class's weight in this scene decays") and `active_ops` is
## cleared, since `PerceptRenderer` already renders `resolve_grounded()`
## instead of `apply()` for that one tick (Pass 8) — after which a grounded
## op has nothing further to distort.
##
## Budget is granted exactly once, at construction, from whatever
## `MindModel` state the caller passes in at that moment (§4.3: "each
## scene, the director receives points") — not re-granted every tick,
## which would let budget grow unboundedly. A caller wiring this into a
## longer session (Phase B's own next step) re-grants explicitly via
## `director.grant_budget(...)` at whatever cadence the design calls for
## (once per scene, once per day, etc.) — that policy decision belongs to
## the caller, not this class.
class_name MissionRuntime
extends RefCounted

var package: MissionPackage
var director: DistortionDirector
var mind: MindModel
var active_ops: Array[DistortionOp] = []


func _init(p_package: MissionPackage, seed: int, p_mind: MindModel = null) -> void:
	package = p_package
	mind = p_mind if p_mind != null else MindModel.new()
	director = DistortionDirector.new(seed)
	director.grant_budget(package.scene_type, _mind_values_fx(), package.mission_weights_fx)


func _mind_values_fx() -> Dictionary:
	return {
		"acute_stress": mind.acute_stress.value_fx(),
		"fatigue": mind.fatigue.value_fx(),
		"moral_injury": mind.moral_injury.value_fx(),
		"identity_strain": mind.identity_strain.value_fx(),
	}


func step(current_tick: int, ground_just_completed: bool) -> void:
	if ground_just_completed:
		for op: DistortionOp in active_ops:
			director.notify_ground_resolved(op.op_class)
			director.notify_op_deactivated()
		active_ops.clear()
		return

	var record: Dictionary = director.purchase_one(package.deck, _mind_values_fx(), current_tick)
	if record.is_empty():
		return
	active_ops.append(OpFactory.build(package.deck[record["deck_index"]]))
