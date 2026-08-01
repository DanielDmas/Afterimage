## master_plan.md §4.2: "A sound with no truth-layer source: footsteps
## behind you, your name from another room." Ground response: "Fades
## under the breath rhythm" — represented here as the phantom event
## simply disappearing on resolve_grounded(), since it was never real.
##
## Appends a synthetic entry to `snapshot["sound_events"]` with no
## backing truth event (`source_id: -1`, `is_phantom: true`). Tagged with
## this op instance's own `get_instance_id()` so resolve_grounded() only
## ever removes the phantom *this* op added, not another PhantomAudio
## instance's — correctness that matters once more than one is active at
## once, which Ground's "resolves every active op simultaneously"
## contract (§4.6) means is the normal case, not an edge case.
class_name PhantomAudio
extends DistortionOp

const TIER: int = 1
const COST: int = 8

var phantom_position: Vector2i
var phantom_tag: String


func _init(
	p_phantom_position: Vector2i, p_phantom_tag: String, p_dramatic_intent: String = "dread"
) -> void:
	op_class = "PhantomAudio"
	tier = TIER
	cost = COST
	dramatic_intent = p_dramatic_intent
	fairness_tags = [
		"charter_rule_1_never_damages_never_blocks",
		"charter_rule_3_inputs_never_distorted",
		"charter_rule_5_always_disclosable",
	]
	phantom_position = p_phantom_position
	phantom_tag = p_phantom_tag


func apply(snapshot: Dictionary) -> Dictionary:
	var out: Dictionary = snapshot.duplicate(true)
	var events: Array = (out.get("sound_events", []) as Array).duplicate(true)
	(
		events
		. append(
			{
				"position": phantom_position,
				"rendered_tag": phantom_tag,
				"tag": null,
				"source_id": -1,
				"is_phantom": true,
				"phantom_source_op_id": get_instance_id(),
			}
		)
	)
	out["sound_events"] = events
	return out


func resolve_grounded(snapshot: Dictionary) -> Dictionary:
	var out: Dictionary = snapshot.duplicate(true)
	var events: Array = []
	for evt: Dictionary in out.get("sound_events", []) as Array:
		var is_mine: bool = (
			evt.get("is_phantom", false) and evt.get("phantom_source_op_id") == get_instance_id()
		)
		if not is_mine:
			events.append(evt)
	out["sound_events"] = events
	return out
