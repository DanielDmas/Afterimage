## master_plan.md §4.2: "A true sound replaced by a near-neighbor (phone
## ring → alarm; name → other name)." Ground response: "True sound
## replays clean once."
##
## Operates on `snapshot["sound_events"]` (TruthSim.capture_percept_snapshot()'s
## real, truth-sourced list — Pass 9 exposes it for the first time, from
## the same noise events Pass 7's AI hearing already used internally).
## Targets one truth event by its `source_id` and overrides its
## `rendered_tag` — the event's real position/loudness stay truthful
## (Charter rule 1 territory is PhantomEntity's; this op never invents an
## event, only relabels one that's real).
class_name AudioSwap
extends DistortionOp

const TIER: int = 1
const COST: int = 8

var target_source_id: int
var swapped_tag: String


func _init(
	p_target_source_id: int, p_swapped_tag: String, p_dramatic_intent: String = "doubt"
) -> void:
	op_class = "AudioSwap"
	tier = TIER
	cost = COST
	dramatic_intent = p_dramatic_intent
	fairness_tags = ["charter_rule_3_inputs_never_distorted", "charter_rule_5_always_disclosable"]
	target_source_id = p_target_source_id
	swapped_tag = p_swapped_tag


func apply(snapshot: Dictionary) -> Dictionary:
	if not snapshot.has("sound_events"):
		return snapshot
	var out: Dictionary = snapshot.duplicate(true)
	var events: Array = []
	for evt: Dictionary in out["sound_events"] as Array:
		var e: Dictionary = evt.duplicate(true)
		if int(e.get("source_id", -1)) == target_source_id:
			e["rendered_tag"] = swapped_tag
		events.append(e)
	out["sound_events"] = events
	return out


func resolve_grounded(snapshot: Dictionary) -> Dictionary:
	if not snapshot.has("sound_events"):
		return snapshot
	var out: Dictionary = snapshot.duplicate(true)
	var events: Array = []
	for evt: Dictionary in out["sound_events"] as Array:
		var e: Dictionary = evt.duplicate(true)
		if int(e.get("source_id", -1)) == target_source_id:
			e["rendered_tag"] = e.get("tag", "")
		events.append(e)
	out["sound_events"] = events
	return out
