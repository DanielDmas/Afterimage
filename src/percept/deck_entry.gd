## A single purchasable entry in a mission's weighted DistortionOp deck
## (master_plan.md §4.3: "the director spends budget on ops from the
## mission's weighted deck"). Plain data, not a live op instance — content
## is data, not code (this is the deck-authoring shape Pass 13's real JSON
## loader populates; for tests it's constructed directly in GDScript, the
## same "test the mechanism before the pipeline exists" approach Pass 7's
## GrayboxRoom used for level data).
##
## `params` (post-arc addition, docs/review_and_forward_plan.md F1) is the
## generic, per-op-class-shaped Dictionary OpFactory.build() needs to
## actually construct a live op from this entry — DeckEntry stays
## deliberately ignorant of what shape any particular op_class expects
## (only OpFactory knows that), the same "plain data, no op-class
## knowledge" discipline DistortionDirector's own docstring already
## commits to. Defaults to `{}` (not required) so DeckEntry's existing
## 23 call sites across this codebase's tests, none of which build a real
## op from their entries, are unaffected.
class_name DeckEntry
extends RefCounted

var op_class: String
var tier: int
var cost: int
var variable_affinity: Array[String]
var params: Dictionary


func _init(
	p_op_class: String,
	p_tier: int,
	p_cost: int,
	p_variable_affinity: Array[String],
	p_params: Dictionary = {}
) -> void:
	op_class = p_op_class
	tier = p_tier
	cost = p_cost
	variable_affinity = p_variable_affinity
	params = p_params
