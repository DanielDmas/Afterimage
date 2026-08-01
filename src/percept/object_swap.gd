## master_plan.md §4.2: "A prop rendered as a different prop of similar
## silhouette (a dropped phone as a weapon — the classic tragic misread,
## used with extreme authorial care)." Ground response: "Snaps true with
## a lens-pull."
##
## Operates on an optional `snapshot["props"]` key (Array of
## `{"id", "position", "true_kind"}` Dictionaries) — props aren't a truth
## concept TruthSim emits yet (capture_percept_snapshot() only exports
## actors and sound_events today), so this is a no-op whenever the key is
## absent, tested here against a hand-built synthetic snapshot, matching
## AudioSwap's "relabel one real thing by id, never invent one" shape:
## the prop's real position/true_kind stay truthful, only `rendered_kind`
## changes (Charter rule 1 territory — inventing an entity — belongs to
## PhantomEntity, not this op).
class_name ObjectSwap
extends DistortionOp

const TIER: int = 2
const COST: int = 12

var target_prop_id: int
var swapped_kind: String


func _init(
	p_target_prop_id: int, p_swapped_kind: String, p_dramatic_intent: String = "paranoia"
) -> void:
	op_class = "ObjectSwap"
	tier = TIER
	cost = COST
	dramatic_intent = p_dramatic_intent
	fairness_tags = ["charter_rule_3_inputs_never_distorted", "charter_rule_5_always_disclosable"]
	target_prop_id = p_target_prop_id
	swapped_kind = p_swapped_kind


func apply(snapshot: Dictionary) -> Dictionary:
	if not snapshot.has("props"):
		return snapshot
	var out: Dictionary = snapshot.duplicate(true)
	var props: Array = []
	for prop: Dictionary in out["props"] as Array:
		var p: Dictionary = prop.duplicate(true)
		if int(p.get("id", -1)) == target_prop_id:
			p["rendered_kind"] = swapped_kind
			p["grounded"] = false
		props.append(p)
	out["props"] = props
	return out


func resolve_grounded(snapshot: Dictionary) -> Dictionary:
	if not snapshot.has("props"):
		return snapshot
	var out: Dictionary = snapshot.duplicate(true)
	var props: Array = []
	for prop: Dictionary in out["props"] as Array:
		var p: Dictionary = prop.duplicate(true)
		if int(p.get("id", -1)) == target_prop_id:
			p["rendered_kind"] = p.get("true_kind", "")
			p["grounded"] = true
		props.append(p)
	out["props"] = props
	return out
