## A single purchasable entry in a mission's weighted DistortionOp deck
## (master_plan.md §4.3: "the director spends budget on ops from the
## mission's weighted deck"). Plain data, not a live op instance — content
## is data, not code (this is the deck-authoring shape Pass 13's real JSON
## loader will eventually populate; for now it's constructed directly in
## GDScript, the same "test the mechanism before the pipeline exists"
## approach Pass 7's GrayboxRoom used for level data).
class_name DeckEntry
extends RefCounted

var op_class: String
var tier: int
var cost: int
var variable_affinity: Array[String]


func _init(
	p_op_class: String, p_tier: int, p_cost: int, p_variable_affinity: Array[String]
) -> void:
	op_class = p_op_class
	tier = p_tier
	cost = p_cost
	variable_affinity = p_variable_affinity
