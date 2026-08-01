## master_plan.md §4.2: "Controlled jump-cut in safe zones only: 10–90 s
## of truth-layer time the percept layer skips. The truth sim runs it
## fully; the Theater shows what happened." Ground response: "Cannot be
## grounded during (it already happened); journal marks the gap."
##
## Unlike every other op, TimeGap doesn't relabel or invent percept
## content — it marks the whole snapshot as currently gapped
## (`out["time_gap"]`), leaving a future renderer to decide how a jump-cut
## actually looks (a black screen, a fade — no such UI exists in any pass
## yet, the same "state now, presentation later" deferral this codebase
## has used since Focus/Ground's own resource gates). The truth sim
## itself is untouched by this op — §4.2's "the truth sim runs it fully"
## is automatically true because this is a percept-layer decorator: it
## has no way to reach back into TruthSim even if it wanted to (Pass 8's
## boundary), so nothing here ever skips a truth tick, only what the
## player is shown of it.
##
## "Cannot be grounded during (it already happened)" is why
## `resolve_grounded()` is *not* an identity/reveal like every other
## op's: it re-applies the exact same gap marker `apply()` would. This op
## cannot prevent Ground's own cost from being paid at the truth layer
## (it has no way to reach TruthSim's Ground state machine to block the
## input at all — reaching back would itself violate Charter rule 3), but
## it can honestly refuse to grant Ground's normal reveal while the gap
## is active, which is the one guarantee that *is* this op's to give.
class_name TimeGap
extends DistortionOp

const TIER: int = 4
const COST: int = 30

var duration_ticks: int


func _init(p_duration_ticks: int, p_dramatic_intent: String = "dread") -> void:
	op_class = "TimeGap"
	tier = TIER
	cost = COST
	dramatic_intent = p_dramatic_intent
	fairness_tags = ["charter_rule_3_inputs_never_distorted", "charter_rule_5_always_disclosable"]
	duration_ticks = p_duration_ticks


func apply(snapshot: Dictionary) -> Dictionary:
	var out: Dictionary = snapshot.duplicate(true)
	out["time_gap"] = {
		"active": true,
		"gap_source_op_id": get_instance_id(),
		"true_duration_ticks": duration_ticks,
	}
	return out


func resolve_grounded(snapshot: Dictionary) -> Dictionary:
	return apply(snapshot)
