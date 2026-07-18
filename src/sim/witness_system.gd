## Records who truly saw what (master_plan.md architecture diagram:
## "WitnessSystem — who truly saw what — feeds suspicion+story"). Reuses
## the same VisionCone + LineOfSight query AI perception uses — a witness
## is anyone who could have seen the event happen, evaluated against
## truth, independent of what the player later believes or claims.
##
## The witness log is the source WitnessSystem-consuming passes will read
## from: suspicion propagation (master_plan §4.7) and the debrief's
## truth-delta computation (§4.10) both need "did anyone really see this"
## as a truth-layer fact, not a percept-layer one.
class_name WitnessSystem
extends RefCounted

## Each candidate: {"id": int, "position": Vector2i, "facing": Vector2i,
## "range_mm": int, "cos_sq_half_angle_fx": int} — the same shape
## AiArchetype/AiAgent already carry, so a candidate list is trivially
## built from a roster of AiAgents.
var _log: Array = []


## Evaluates every candidate against the event and appends one log entry.
## Returns the sorted list of witnessing actor IDs for this event.
func record_event(
	tick: int, event_tag: String, position: Vector2i, candidates: Array, grid: CollisionGrid
) -> Array:
	var witnesses: Array = []
	for candidate: Dictionary in candidates:
		var saw_it: bool = (
			VisionCone.point_in_cone(
				candidate["position"],
				candidate["facing"],
				candidate["cos_sq_half_angle_fx"],
				candidate["range_mm"],
				position
			)
			and LineOfSight.has_clear_line(candidate["position"], position, grid)
		)
		if saw_it:
			witnesses.append(int(candidate["id"]))
	witnesses.sort()  # deterministic order (tech_guidelines.md §3.5)

	_log.append(
		{"tick": tick, "event_tag": event_tag, "position": position, "witnesses": witnesses}
	)
	return witnesses


func log() -> Array:
	return _log


func entry_count() -> int:
	return _log.size()
