## master_plan.md §4.2: "Journal/board text differs from what the player
## actually saw — the cruelest one; always disclosable, never
## load-bearing for progression." Ground response: "Grounding near the
## journal restores the true entry, both versions kept visible."
##
## That last clause is the one Ground response in the whole taxonomy that
## isn't a clean revert (every other op's resolve_grounded() erases the
## lie; SubtitleDrift's own doc calls the strike-through animation a
## "flip back"). MemoryEdit's `resolve_grounded()` deliberately preserves
## both: `rendered_text` becomes the true entry again (so the world
## behaves truthfully from here on), but `edited_text_disclosed` keeps
## the false entry the player actually read on record, for a future
## journal UI to show side by side — matching the spec's own words rather
## than reusing the generic revert every earlier op used.
##
## Operates on an optional `snapshot["journal_entries"]` key (Array of
## `{"entry_id", "true_text"}` Dictionaries) — no journal truth concept
## exists yet, so this is a no-op whenever the key is absent, tested here
## against a hand-built synthetic snapshot.
class_name MemoryEdit
extends DistortionOp

const TIER: int = 4
const COST: int = 30

var target_entry_id: String
var edited_text: String


func _init(
	p_target_entry_id: String, p_edited_text: String, p_dramatic_intent: String = "grief"
) -> void:
	op_class = "MemoryEdit"
	tier = TIER
	cost = COST
	dramatic_intent = p_dramatic_intent
	fairness_tags = ["charter_rule_3_inputs_never_distorted", "charter_rule_5_always_disclosable"]
	target_entry_id = p_target_entry_id
	edited_text = p_edited_text


func apply(snapshot: Dictionary) -> Dictionary:
	if not snapshot.has("journal_entries"):
		return snapshot
	var out: Dictionary = snapshot.duplicate(true)
	var entries: Array = []
	for entry: Dictionary in out["journal_entries"] as Array:
		var e: Dictionary = entry.duplicate(true)
		if String(e.get("entry_id", "")) == target_entry_id:
			e["rendered_text"] = edited_text
			e["grounded"] = false
		entries.append(e)
	out["journal_entries"] = entries
	return out


func resolve_grounded(snapshot: Dictionary) -> Dictionary:
	if not snapshot.has("journal_entries"):
		return snapshot
	var out: Dictionary = snapshot.duplicate(true)
	var entries: Array = []
	for entry: Dictionary in out["journal_entries"] as Array:
		var e: Dictionary = entry.duplicate(true)
		if String(e.get("entry_id", "")) == target_entry_id:
			e["rendered_text"] = e.get("true_text", "")
			e["edited_text_disclosed"] = edited_text
			e["grounded"] = true
		entries.append(e)
	out["journal_entries"] = entries
	return out
