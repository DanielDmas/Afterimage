## foundation_blueprints.md §3: `Claim {id, subject, predicate, object,
## qualifiers{}, provenance[]}` — an atomic assertable fact. Subjects/
## objects are content ID strings (tech §5.2).
##
## A pure data record: honesty mode, truth-delta, and consequences are NOT
## fields here — those belong to the *submission* process (DebriefLedger's
## job), not to the claim itself. A Claim is drafted once and never
## mutated; DebriefLedger tracks what happens to it afterward in its own
## records, keyed by claim id.
##
## Provenance chain (§3): every claim knows how Eliška came to hold it.
## `PERCEIVED` may be distortion-tainted — "the taint is knowable to the
## engine, not to her" — `GROUNDED`/`EVIDENCE` are armored (can never later
## be contradicted, §4.10), `TOLD` carries the teller.
class_name Claim
extends RefCounted

enum ProvenanceType { PERCEIVED, GROUNDED, EVIDENCE, TOLD }

var id: String
var subject: String
var predicate: String
var object_value: String
var qualifiers: Dictionary
var provenance: Array[Dictionary]  ## [{"type": ProvenanceType, ...type-specific fields}]


func _init(
	p_id: String,
	p_subject: String,
	p_predicate: String,
	p_object_value: String,
	p_qualifiers: Dictionary = {},
	p_provenance: Array[Dictionary] = []
) -> void:
	id = p_id
	subject = p_subject
	predicate = p_predicate
	object_value = p_object_value
	qualifiers = p_qualifiers
	provenance = p_provenance


func has_provenance_type(provenance_type: ProvenanceType) -> bool:
	for entry: Dictionary in provenance:
		if entry["type"] == provenance_type:
			return true
	return false
