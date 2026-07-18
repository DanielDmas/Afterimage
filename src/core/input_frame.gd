## One tick's worth of sampled player input (tech_guidelines.md §3.1): the
## sim never reads a raw device state, only a serializable InputFrame keyed
## by input-map action name. The recorded stream of these + a run seed +
## content version *is* the replay and the mission save (ReplayLog).
##
## `inputs` is intentionally a generic String -> Variant map rather than a
## fixed set of named fields: which actions exist is an InputMap concern
## that lands with the combat verbs (Pass 6), and this class must not need
## to change shape when that happens.
class_name InputFrame
extends RefCounted

var tick: int = 0
var inputs: Dictionary = {}


func _init(p_tick: int = 0, p_inputs: Dictionary = {}) -> void:
	tick = p_tick
	inputs = p_inputs.duplicate(true)


func to_dict() -> Dictionary:
	return {"tick": tick, "inputs": inputs.duplicate(true)}


static func from_dict(d: Dictionary) -> InputFrame:
	return InputFrame.new(int(d.get("tick", 0)), d.get("inputs", {}))


func equals(other: InputFrame) -> bool:
	return tick == other.tick and inputs == other.inputs
