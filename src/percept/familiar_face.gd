## master_plan.md §4.2: "A stranger rendered with a face from Eliška's
## ledger of the dead or the betrayed; moral-injury's signature purchase."
## Ground response: "Face resolves to the real stranger."
##
## Unlike HUDGlitch/ObjectSwap/GeometrySwap (whose truth concepts don't
## exist yet), this op targets `snapshot["actors"]`, which is real,
## truth-sourced data every capture_percept_snapshot() call already
## produces (Pass 8/9's boundary) — so this is the first of the new ops
## that can actually fire against a real running scene today, not only a
## hand-built fixture. It only ever adds a `rendered_face_id` /
## `is_face_swapped` key to the matching actor's percept-side copy; the
## actor's real identity, position, and every truth-layer field are
## untouched, matching AudioSwap's "relabel, never invent or remove"
## discipline.
class_name FamiliarFace
extends DistortionOp

const TIER: int = 2
const COST: int = 15

var target_actor_id: int
var familiar_face_id: String


func _init(
	p_target_actor_id: int, p_familiar_face_id: String, p_dramatic_intent: String = "grief"
) -> void:
	op_class = "FamiliarFace"
	tier = TIER
	cost = COST
	dramatic_intent = p_dramatic_intent
	fairness_tags = ["charter_rule_3_inputs_never_distorted", "charter_rule_5_always_disclosable"]
	target_actor_id = p_target_actor_id
	familiar_face_id = p_familiar_face_id


func apply(snapshot: Dictionary) -> Dictionary:
	var out: Dictionary = snapshot.duplicate(true)
	var actors: Array = []
	for a: Dictionary in out.get("actors", []) as Array:
		var actor: Dictionary = a.duplicate(true)
		if int(actor.get("id", -1)) == target_actor_id:
			actor["rendered_face_id"] = familiar_face_id
			actor["is_face_swapped"] = true
		actors.append(actor)
	out["actors"] = actors
	return out


func resolve_grounded(snapshot: Dictionary) -> Dictionary:
	var out: Dictionary = snapshot.duplicate(true)
	var actors: Array = []
	for a: Dictionary in out.get("actors", []) as Array:
		var actor: Dictionary = a.duplicate(true)
		if int(actor.get("id", -1)) == target_actor_id:
			actor.erase("rendered_face_id")
			actor["is_face_swapped"] = false
		actors.append(actor)
	out["actors"] = actors
	return out
