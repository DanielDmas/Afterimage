## Configurable WorldQuery test double for predicate/dialogue/validator unit
## tests. Not part of any shipped system — pure test-fixture support, kept
## under tests/framework/ so later passes (dialogue, suspicion, debrief
## tests) can reuse it instead of re-inventing a fake per test file.
class_name MockWorldQuery
extends WorldQuery

var claims: Dictionary = {}  ## claim_id -> true, or claim_id -> Array[String] of modes asserted
var trust_values: Dictionary = {}  ## npc_id -> int
var suspicion_values: Dictionary = {}  ## target_id -> int
var mind_bands: Dictionary = {
	"stress": "quiet", "fatigue": "quiet", "moral_injury": "quiet", "identity_strain": "quiet"
}
var day: int = 0
var missions_done: Dictionary = {}  ## mission_id -> true
var flags: Dictionary = {}  ## name -> bool
var flag_values: Dictionary = {}  ## name -> Variant
var kill_counts: Dictionary = {}  ## context -> int
var witnessed_tags: Dictionary = {}  ## tag -> true
var grounded_refs: Dictionary = {}  ## ref -> true
var blown_factions: Dictionary = {}  ## faction -> true
var ending_gates: Dictionary = {}  ## family -> true
var items: Dictionary = {}  ## item_id -> true
var relationship_tiers: Dictionary = {}  ## npc_id -> int


func has_claim(claim_id: String) -> bool:
	return claims.has(claim_id)


func claim_asserted(claim_id: String, mode: String = "") -> bool:
	if not claims.has(claim_id):
		return false
	var modes: Variant = claims[claim_id]
	if mode == "":
		return true
	if modes is Array:
		return (modes as Array).has(mode)
	return modes == mode


func trust(npc_id: String) -> int:
	return trust_values.get(npc_id, 0)


func suspicion(target_id: String) -> int:
	return suspicion_values.get(target_id, 0)


func mind_band(variable: String) -> String:
	return mind_bands.get(variable, "quiet")


func current_day() -> int:
	return day


func mission_done(mission_id: String) -> bool:
	return missions_done.has(mission_id)


func flag(name: String) -> bool:
	return flags.get(name, false)


func flag_value(name: String) -> Variant:
	return flag_values.get(name)


func kills(context: String) -> int:
	return kill_counts.get(context, 0)


func witnessed(event_tag: String) -> bool:
	return witnessed_tags.has(event_tag)


func grounded(ref: String) -> bool:
	return grounded_refs.has(ref)


func cover_blown_to(faction_id: String = "") -> bool:
	if faction_id == "":
		return not blown_factions.is_empty()
	return blown_factions.has(faction_id)


func ending_gate_reached(family: String) -> bool:
	return ending_gates.has(family)


func item_held(item_id: String) -> bool:
	return items.has(item_id)


func relationship_tier(npc_id: String) -> int:
	return relationship_tiers.get(npc_id, 0)
