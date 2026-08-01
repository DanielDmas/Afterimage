## master_plan.md §4.10 / foundation_blueprints.md §3: "DebriefLedger: per
## mission, the claim candidates drafted from salient log events, the
## honesty mode chosen per claim, the hidden engine-computed truth-delta,
## and consequences applied. Append-only across the campaign."
##
## Truth-delta v0: a claim's object either matches the corresponding
## ground-truth object exactly (delta 0, true) or it doesn't (delta 1,
## false) — §4.10 never specifies a graduated formula (unlike MindModel's
## §4.4 or the Director's §4.3, both given explicit math), so this is the
## simplest honest reading of "engine-computed truth-delta" rather than an
## invented scale with no spec to verify against.
##
## Consequence channels (§4.10: "Doubek trust... resource budget... plot
## flags... the psychological tick") are mostly Pass 18+ hub/mission
## territory this class has no access to yet — the one channel already
## real and available is moral injury ("lies price into moral injury
## immediately — the liar knows"), so FABRICATE submissions optionally
## bill a caller-supplied MoralInjuryState (Pass 11) directly. Every other
## channel is a documented deferral, not a silent omission.
class_name DebriefLedger
extends RefCounted

enum HonestyMode { AS_SEEN, VERIFIED_ONLY, FABRICATE }

var _candidate_ids: Array[String] = []
var _candidates: Dictionary = {}  ## claim_id -> Claim
var _submitted_ids: Dictionary = {}  ## claim_id -> true
var _submissions: Array[Dictionary] = []  ## append-only: [{claim_id, mode, truth_delta}]


func add_candidate(claim: Claim) -> void:
	assert(not _candidates.has(claim.id), "DebriefLedger: duplicate claim id '%s'" % claim.id)
	_candidate_ids.append(claim.id)
	_candidates[claim.id] = claim


func candidate(claim_id: String) -> Claim:
	return _candidates[claim_id]


## Deterministic draft order (tech_guidelines §3.5): candidates in the
## order they were added, never Dictionary iteration order.
func candidates() -> Array[Claim]:
	var result: Array[Claim] = []
	for claim_id: String in _candidate_ids:
		result.append(_candidates[claim_id])
	return result


func is_submitted(claim_id: String) -> bool:
	return _submitted_ids.has(claim_id)


## Submits a claim under `mode` against `truth_object` (the ground-truth
## object for this claim's subject+predicate — supplied by the caller,
## since Claim/DebriefLedger have no access to TruthSim themselves).
## Irreversible (§4.10: "submission irreversible with a dedicated
## autosave") — resubmitting an already-submitted claim is a contract
## violation, not a runtime case to handle gracefully.
## `VERIFIED_ONLY` requires GROUNDED or EVIDENCE provenance (§4.10: "only
## claims that were grounded or are evidence-backed... a verified claim
## can never later be contradicted") — asserting that here rather than
## silently downgrading an ineligible claim to a different mode.
##
## `game_state`, like `moral_injury`, is optional and caller-supplied
## (Phase C's consequence channels, docs/forward_dev_plan.md): when given,
## `DebriefConsequences.bill()`'s trust/resource deltas are written to
## `["campaign", "doubek_trust"]`/`["campaign", "resource_budget"]`, and a
## FABRICATE submission writes a discoverable plot flag
## (`["campaign", "flags", "claim_<id>_fabricated"]`) — the flag itself,
## not the discovery mechanic §4.10 defers to future work, which has
## nothing to *find* yet without this write existing first.
func submit_claim(
	claim_id: String,
	mode: HonestyMode,
	truth_object: String,
	moral_injury: MoralInjuryState = null,
	conceals_death: bool = false,
	game_state: GameStateStore = null
) -> Dictionary:
	assert(
		not _submitted_ids.has(claim_id),
		"DebriefLedger: claim '%s' already submitted, submission is irreversible" % claim_id
	)
	var claim: Claim = _candidates[claim_id]
	if mode == HonestyMode.VERIFIED_ONLY:
		assert(
			(
				claim.has_provenance_type(Claim.ProvenanceType.GROUNDED)
				or claim.has_provenance_type(Claim.ProvenanceType.EVIDENCE)
			),
			(
				"DebriefLedger: claim '%s' has no grounded/evidence provenance for VERIFIED_ONLY"
				% claim_id
			)
		)

	var truth_delta: int = 0 if claim.object_value == truth_object else 1

	if mode == HonestyMode.FABRICATE and moral_injury != null:
		moral_injury.gain_knowing_lie_in_debrief(conceals_death)

	var consequence: Dictionary = DebriefConsequences.bill(mode, truth_delta)
	if game_state != null:
		var trust: int = int(game_state.get_value(["campaign", "doubek_trust"]))
		game_state.set_value(["campaign", "doubek_trust"], trust + consequence["trust_delta"])
		var resources: int = int(game_state.get_value(["campaign", "resource_budget"]))
		game_state.set_value(
			["campaign", "resource_budget"], resources + consequence["resource_delta"]
		)
		if mode == HonestyMode.FABRICATE:
			game_state.set_value(["campaign", "flags", "claim_%s_fabricated" % claim_id], true)

	var record: Dictionary = {
		"claim_id": claim_id,
		"mode": mode,
		"truth_delta": truth_delta,
		"trust_delta": consequence["trust_delta"],
		"resource_delta": consequence["resource_delta"],
	}
	_submissions.append(record)
	_submitted_ids[claim_id] = true
	return record


func submissions() -> Array:
	return _submissions.duplicate(true)
