## Base class for a real DistortionOp (master_plan.md §4.2's taxonomy).
## Extends Pass 8's PerceptOp with the metadata every op class in that
## table ships with: a tier, a director cost (§4.3's purchase price), a
## dramatic intent (dread/doubt/grief/paranoia, so playtests can measure
## intent against effect), and fairness tags recording which Fairness
## Charter rules (§4.5) this op class complies with by construction —
## read later by the fairness auditor (Pass 12), not enforced by it yet.
##
## Subclasses set these fields directly in their own `_init()` rather
## than through a base constructor: they're just public vars, and this
## sidesteps relying on GDScript's `super._init()` chaining, one less
## untested-in-this-sandbox Godot behavior in an already content-facing
## pass's risk surface.
##
## §4.2 also requires every op to ship a Clarity Mode substitution and an
## accessibility twin. Neither is implemented here: Clarity Mode itself
## is a stub in Pass 10, and an accessibility twin needs real audio/visual
## presentation to substitute between, which doesn't exist before a real
## renderer (post-Pass-20 art/UI work). Deferred, not silently skipped —
## the same "no consumer yet" discipline as every prior pass.
class_name DistortionOp
extends PerceptOp

var op_class: String
var tier: int
var cost: int
var dramatic_intent: String
var fairness_tags: Array = []


## What the percept view would show if this op were resolved true
## (master_plan §4.2's "Ground response" column) — Pass 10's Ground verb
## will call this once it exists. Identity by default; every real op
## overrides it.
func resolve_grounded(snapshot: Dictionary) -> Dictionary:
	return snapshot
