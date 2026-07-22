## master_plan.md §4.2: "A real entity not rendered. Restricted per
## Charter rule 2 to non-threats: witnesses, evidence, the body that
## 'wasn't there'." Ground response: "Unmasked entity fades in."
##
## Charter rule 2 (§4.5): "EntityMask is never applied to entities that
## can damage the player while masked; it is used for witnesses,
## evidence, and dread, not for cheap ambushes." FairnessAuditor's own
## class doc (fairness_auditor.gd) flags this rule as "not yet
## structurally enforceable... real op-class-string matching against a
## required tag, ready for whenever EntityMask lands" — this class makes
## it structural, not just declared: `apply()` only ever masks an actor
## whose own truth-sourced snapshot entry explicitly says
## `"is_damage_capable": false`. TruthSim's real
## capture_percept_snapshot() never emits that key today (no
## witness/evidence archetype exists yet — every AI actor Pass 7 built is
## a combat-capable Sentry/Professional), so `.get("is_damage_capable",
## true)` defaults *closed*: against every real actor this codebase can
## produce right now, masking is structurally impossible no matter what
## `target_actor_id` a mission author supplies. The mask only takes
## effect once a future truth-layer concept explicitly vouches an entity
## is safe to hide — the same "no code path to violate the Charter"
## argument PhantomEntity's boundary already makes for rule 1, applied
## here to rule 2.
##
## Because the entity was only ever hidden from the percept-side render,
## never actually removed from truth, `resolve_grounded()` doesn't need
## to re-add anything: it just stops hiding it by returning the
## (already-real) snapshot unchanged, which is exactly what "unmasked
## entity fades in" means from the percept side.
class_name EntityMask
extends DistortionOp

const TIER: int = 3
const COST: int = 25

var target_actor_id: int


func _init(p_target_actor_id: int, p_dramatic_intent: String = "dread") -> void:
	op_class = "EntityMask"
	tier = TIER
	cost = COST
	dramatic_intent = p_dramatic_intent
	fairness_tags = [
		"charter_rule_2_never_masks_damage_capable_entities",
		"charter_rule_3_inputs_never_distorted",
		"charter_rule_5_always_disclosable",
	]
	target_actor_id = p_target_actor_id


func apply(snapshot: Dictionary) -> Dictionary:
	var out: Dictionary = snapshot.duplicate(true)
	var actors: Array = []
	for a: Dictionary in out.get("actors", []) as Array:
		var is_masked: bool = (
			int(a.get("id", -1)) == target_actor_id and not bool(a.get("is_damage_capable", true))
		)
		if not is_masked:
			actors.append(a)
	out["actors"] = actors
	return out


func resolve_grounded(snapshot: Dictionary) -> Dictionary:
	return snapshot
