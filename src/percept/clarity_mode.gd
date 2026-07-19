## Real-time distortion flagging via a subtle vignette (master_plan.md
## §4.16, Fairness Charter rule 6, §4.5: "the psychological pressure
## drops, the story stays intact... no content loss"). Clarity Mode never
## removes or changes an op's effect — it only tells the player *that*
## something is currently active, not what — so this is purely a
## read-only reporting function over whatever ops are already active.
##
## This is the data-layer stub the roadmap AC asks for: which ops are
## active this tick and their class/tier, for a future vignette-rendering
## UI to consume. No such UI exists yet (no Godot scene has been built in
## any pass so far), and the on/off toggle itself belongs to a settings
## system (Pass 19's UI shell + accessibility scaffolding) — the same
## "state now, presentation later" pattern Focus/Ground's own resource-
## gates used before either had a renderer to attach to.
class_name ClarityMode
extends RefCounted


static func active_flags(active_ops: Array) -> Array:
	var flags: Array = []
	for op: PerceptOp in active_ops:
		if op is DistortionOp:
			var d: DistortionOp = op
			flags.append({"op_class": d.op_class, "tier": d.tier})
	return flags
