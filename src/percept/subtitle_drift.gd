## master_plan.md §4.2: "Rendered subtitle differs from the truth-layer
## line by a plausible mishearing; audio may stay true (the reader's
## poison) or drift with it." Ground response: "Subtitle visibly
## self-corrects, strike-through animation" (§4.2's table) — represented
## here as data (`grounded`/`rendered_text` flipping back to
## `true_text`), for a future UI layer to animate.
##
## Operates on an optional `snapshot["subtitle"]` key
## ({"speaker_id", "true_text"}) — dialogue doesn't exist as a truth
## concept yet (Pass 15's DialogueRunner), so this is a no-op whenever
## that key is absent, tested here against a hand-built synthetic
## snapshot rather than a real dialogue source, the same discipline
## Pass 8's PerceptOp/PerceptRenderer tests already established.
class_name SubtitleDrift
extends DistortionOp

const TIER: int = 1
const COST: int = 5

var drifted_text: String


func _init(p_drifted_text: String, p_dramatic_intent: String = "doubt") -> void:
	op_class = "SubtitleDrift"
	tier = TIER
	cost = COST
	dramatic_intent = p_dramatic_intent
	fairness_tags = ["charter_rule_3_inputs_never_distorted", "charter_rule_5_always_disclosable"]
	drifted_text = p_drifted_text


func apply(snapshot: Dictionary) -> Dictionary:
	if not snapshot.has("subtitle"):
		return snapshot
	var out: Dictionary = snapshot.duplicate(true)
	var sub: Dictionary = (out["subtitle"] as Dictionary).duplicate(true)
	sub["rendered_text"] = drifted_text
	sub["grounded"] = false
	out["subtitle"] = sub
	return out


func resolve_grounded(snapshot: Dictionary) -> Dictionary:
	if not snapshot.has("subtitle"):
		return snapshot
	var out: Dictionary = snapshot.duplicate(true)
	var sub: Dictionary = (out["subtitle"] as Dictionary).duplicate(true)
	sub["rendered_text"] = sub["true_text"]
	sub["grounded"] = true
	out["subtitle"] = sub
	return out
