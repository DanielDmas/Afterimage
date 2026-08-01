## Wires TruthSim's real combat events ("WeaponFired", "ActorDowned",
## "GroundCompleted") to MindModel (Pass 11) — closing the one gap
## MindModel's own class doc named explicitly: "nothing calls gain_*/
## decay_* from TruthSim... Wiring those call sites is later passes' job
## once each has a real consumer-side reason to exist." DistortionDirector
## (Pass 12) already reads MindModel's band state to size its budget; this
## bridge is what makes that budget actually rise and fall with what
## happens in a real run, instead of staying wherever a caller happened to
## leave it — the first half of the §4.4↔§4.3 feedback loop master_plan.md
## describes actually running live.
##
## Deliberately coarse, the same honest-partial-step stance
## GroundObservationBridge's own "silently skip an unmapped observer"
## already took: every "WeaponFired" anywhere raises acute stress by
## GAIN_GUNFIRE_IN_EARSHOT regardless of distance (real earshot-radius
## gating needs SoundGraph's room propagation, docs/forward_dev_plan.md
## Phase D, not built yet); every "ActorDowned" raises acute stress by
## GAIN_WITNESSING_KILL regardless of whether the player actually saw it
## happen. Moral injury is deliberately NOT wired from "ActorDowned" here:
## §4.4.3's gains are context-weighted (open combat vs. an unaware victim
## vs. a civilian, +4/+6/+15) and "ActorDowned"'s payload ({id}) carries
## none of that context yet — wiring it to a flat, context-blind number
## would be a worse gap than leaving it unwired, the same "no code path
## to misrepresent this" discipline this codebase already applies to
## Charter rule 1.
##
## **The caller must keep a reference to the constructed bridge for as
## long as its subscription should stay active** — the same real
## RefCounted/Callable lifetime trap GroundObservationBridge's own class
## doc documents in full (a real CI failure once proved this the hard
## way): `_event_bus.subscribe()` stores a Callable bound to this
## instance, which does not by itself keep the instance alive.
class_name MindModelEventBridge
extends RefCounted

var mind: MindModel

var _event_bus: EventBus


func _init(p_mind: MindModel, p_event_bus: EventBus) -> void:
	mind = p_mind
	_event_bus = p_event_bus
	_event_bus.subscribe("WeaponFired", _on_weapon_fired)
	_event_bus.subscribe("ActorDowned", _on_actor_downed)
	_event_bus.subscribe("GroundCompleted", _on_ground_completed)


func _on_weapon_fired(_event: Dictionary) -> void:
	mind.acute_stress.gain_gunfire_in_earshot()


func _on_actor_downed(_event: Dictionary) -> void:
	mind.acute_stress.gain_witnessing_kill()


func _on_ground_completed(_event: Dictionary) -> void:
	mind.acute_stress.relieve_ground_completed()
