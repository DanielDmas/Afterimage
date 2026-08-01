## master_plan.md §4.10's claim generation: "at mission end, the engine
## drafts the claim list from the event log's salient events... as
## perceived: a believed phantom the player acted on generates a claim
## candidate... because Eliška believes it. This is the system's quiet
## knife."
##
## Takes events already reduced to "what was perceived" form — each
## `{id, subject, predicate, object, qualifiers?}` — rather than reading
## raw percept/truth data itself. A believed phantom and a real event
## produce an identical-shaped Claim at this stage; that's the point ("the
## quiet knife" — drafting never looks at truth, only percept). Whether a
## drafted claim is actually true is determined later, at submission
## (DebriefLedger's truth-delta computation), not here. Where these
## "perceived events" actually come from — a ReplayTheater percept view
## (Pass 14), a TruthSim percept snapshot (Pass 8) — is the caller's job;
## this class only knows the reduced shape, the same "state now, consumer
## later" pattern used since Pass 12's DeckEntry.
class_name ClaimDrafter
extends RefCounted


static func draft_from_perceived_events(events: Array[Dictionary]) -> Array[Claim]:
	var claims: Array[Claim] = []
	for event: Dictionary in events:
		var provenance: Array[Dictionary] = [{"type": Claim.ProvenanceType.PERCEIVED}]
		claims.append(
			Claim.new(
				event["id"],
				event["subject"],
				event["predicate"],
				event["object"],
				event.get("qualifiers", {}),
				provenance
			)
		)
	return claims
