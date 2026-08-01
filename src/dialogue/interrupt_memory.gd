## foundation_blueprints.md §4.2: "owns interrupt memory — a transcript of
## NPC and player-as-Radek statements stored as claims with `told`
## provenance, so contradictions are detectable both ways: the player can
## catch NPC lies, and NPCs catch Radek's inconsistencies."
##
## A statement is {subject, predicate, object, source} — `source` is who
## *asserted* it (told provenance), which may differ from `subject` (an
## NPC can make a claim about someone else). Two statements contradict
## when they share (subject, predicate) but disagree on `object` —
## foundation_blueprints §3's "mechanical conflicts (same subject+
## predicate, incompatible object)". Checking every new statement against
## every prior one, regardless of either one's source, is what makes this
## symmetric: an NPC statement contradicted by a later player one is
## caught exactly the same way as the reverse.
##
## v0 scope: this is deliberately NOT the full Claims/Provenance/
## DebriefLedger system (Pass 17's job) — no claim IDs, no qualifiers, no
## campaign-wide persistence. It is exactly the subject/predicate/object/
## source tuple contradiction-checking needs, nothing more.
class_name InterruptMemory
extends RefCounted

var _statements: Array[Dictionary] = []
var _contradictions: Array[Dictionary] = []


func record_statement(
	subject: String, predicate: String, object_value: String, source: String
) -> void:
	var new_statement: Dictionary = {
		"subject": subject, "predicate": predicate, "object": object_value, "source": source
	}
	for existing: Dictionary in _statements:
		if (
			existing["subject"] == subject
			and existing["predicate"] == predicate
			and existing["object"] != object_value
		):
			_contradictions.append({"existing": existing, "new": new_statement})
	_statements.append(new_statement)


func statements() -> Array:
	return _statements.duplicate(true)


func contradictions() -> Array:
	return _contradictions.duplicate(true)


func has_contradiction() -> bool:
	return not _contradictions.is_empty()
