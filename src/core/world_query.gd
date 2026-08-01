## Duck-typed read interface the Predicate evaluator (predicate.gd) queries
## against (foundation_blueprints.md §2). GameStateStore will implement this
## surface for real once it lands; test doubles implement it for unit tests.
##
## GDScript has no formal interface keyword, so this base class exists to:
##  1. document the exact contract in one place,
##  2. give every method a loud, unmistakable failure if a concrete subclass
##     forgets to override something it actually needs at runtime, instead of
##     silently returning a wrong default that masquerades as a real answer.
## Subclasses override only the methods their tests/usage actually exercise;
## everything else here already returns a safe, inert default.
class_name WorldQuery
extends RefCounted


func _unimplemented(method_name: String) -> void:
	push_error(
		(
			"WorldQuery.%s: not implemented by %s"
			% [method_name, get_script().get_path() if get_script() else "<anonymous>"]
		)
	)


func has_claim(_claim_id: String) -> bool:
	_unimplemented("has_claim")
	return false


## mode: "" (empty) means "asserted in any honesty mode".
func claim_asserted(_claim_id: String, _mode: String = "") -> bool:
	_unimplemented("claim_asserted")
	return false


func trust(_npc_id: String) -> int:
	_unimplemented("trust")
	return 0


## target_id may be an NPC id or a faction id (master_plan.md §4.7).
func suspicion(_target_id: String) -> int:
	_unimplemented("suspicion")
	return 0


## variable: "stress" | "fatigue" | "moral_injury" | "identity_strain"
## returns the band name: "quiet" | "murmur" | "loud" | "crisis"
func mind_band(_variable: String) -> String:
	_unimplemented("mind_band")
	return "quiet"


func current_day() -> int:
	_unimplemented("current_day")
	return 0


func mission_done(_mission_id: String) -> bool:
	_unimplemented("mission_done")
	return false


func flag(_name: String) -> bool:
	_unimplemented("flag")
	return false


func flag_value(_name: String) -> Variant:
	_unimplemented("flag_value")
	return null


## context: e.g. "any" | "civilian" | "unaware" | "executed" (master_plan.md §4.4.3)
func kills(_context: String) -> int:
	_unimplemented("kills")
	return 0


func witnessed(_event_tag: String) -> bool:
	_unimplemented("witnessed")
	return false


## ref may be a specific DistortionOp id or an op class name.
func grounded(_ref: String) -> bool:
	_unimplemented("grounded")
	return false


## faction_id == "" means "blown to any faction".
func cover_blown_to(_faction_id: String = "") -> bool:
	_unimplemented("cover_blown_to")
	return false


func ending_gate_reached(_family: String) -> bool:
	_unimplemented("ending_gate_reached")
	return false


func item_held(_item_id: String) -> bool:
	_unimplemented("item_held")
	return false


## Relationship tiers are small ordered integers; the caller and content
## author agree on the ranking (e.g. 0=stranger .. 4=trusted).
func relationship_tier(_npc_id: String) -> int:
	_unimplemented("relationship_tier")
	return 0
