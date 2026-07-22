## master_plan.md §4.2: "Between visits only, never mid-sight (Charter
## rule 4): a door where the wall was, a corridor shorter than memory."
## Ground response: "Layout snaps true; minimap annotates the
## correction."
##
## Charter rule 4 (§4.5): "Geometry never changes while observed; no
## distortion may contradict information the player is currently,
## actively verifying." FairnessAuditor's own class doc flags this rule,
## like rule 2, as not yet structurally enforceable — real enforcement
## needs a truth-layer "is this cell currently in the player's view"
## concept, which doesn't exist (TruthSim's collision grid isn't part of
## capture_percept_snapshot() at all today). This class declares the
## required Charter tag (real op-class-string matching, exactly what the
## auditor's comment asks for) and defers the "never mid-sight" structural
## guarantee honestly to whenever a real fog-of-war/visibility truth
## concept exists to check against — the same kind of gap SubtitleDrift's
## own doc names for dialogue, not smoothed over.
##
## Operates on an optional `snapshot["geometry_cells"]` key (Array of
## `{"cell_id", "true_kind"}` Dictionaries) — no geometry-as-percept-data
## concept exists yet, so this is a no-op whenever the key is absent,
## tested here against a hand-built synthetic snapshot.
class_name GeometrySwap
extends DistortionOp

const TIER: int = 3
const COST: int = 20

var target_cell_id: String
var swapped_kind: String


func _init(
	p_target_cell_id: String, p_swapped_kind: String, p_dramatic_intent: String = "doubt"
) -> void:
	op_class = "GeometrySwap"
	tier = TIER
	cost = COST
	dramatic_intent = p_dramatic_intent
	fairness_tags = [
		"charter_rule_4_never_changes_while_observed",
		"charter_rule_3_inputs_never_distorted",
		"charter_rule_5_always_disclosable",
	]
	target_cell_id = p_target_cell_id
	swapped_kind = p_swapped_kind


func apply(snapshot: Dictionary) -> Dictionary:
	if not snapshot.has("geometry_cells"):
		return snapshot
	var out: Dictionary = snapshot.duplicate(true)
	var cells: Array = []
	for cell: Dictionary in out["geometry_cells"] as Array:
		var c: Dictionary = cell.duplicate(true)
		if String(c.get("cell_id", "")) == target_cell_id:
			c["rendered_kind"] = swapped_kind
			c["grounded"] = false
		cells.append(c)
	out["geometry_cells"] = cells
	return out


func resolve_grounded(snapshot: Dictionary) -> Dictionary:
	if not snapshot.has("geometry_cells"):
		return snapshot
	var out: Dictionary = snapshot.duplicate(true)
	var cells: Array = []
	for cell: Dictionary in out["geometry_cells"] as Array:
		var c: Dictionary = cell.duplicate(true)
		if String(c.get("cell_id", "")) == target_cell_id:
			c["rendered_kind"] = c.get("true_kind", "")
			c["grounded"] = true
		cells.append(c)
	out["geometry_cells"] = cells
	return out
