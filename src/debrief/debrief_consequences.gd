## docs/forward_dev_plan.md Phase C's "consequence channels": master_plan.md
## §4.10 names four channels (Doubek trust, resource budget, plot flags,
## the psychological tick) but — unlike MindModel's §4.4 or the Director's
## §4.3, both given explicit gain/decay constants — never pins a trust/
## resource formula; §4.10's own phrasing only constrains the *shape* of
## one ("an honest error costs less trust than a fabrication when
## discovered") and §4.13 constrains another ("[Doubek's operational
## budget] scales with trust and with verified claims"). Phase C's own
## acceptance item says to "define the key-paths, bill the deltas" — this
## is that definition, isolated as a pure function so the worked-example
## math is directly testable without touching `GameStateStore` at all
## (the same "math here, writing there" split `MovementProfile.resolve_delta()`/
## `ClarityMode.active_flags()` already established).
##
## Deliberately does *not* model discovery: §4.10 says a fabrication's
## full trust cost lands "when discovered," and that discovery machinery
## ("a future event can surface it") is explicitly future work, not this
## pass's. What's billed immediately here is Doubek's own base-rate
## skepticism overhead — real, but smaller than a discovered lie would
## cost — which is what keeps a fabrication strictly worse than an honest
## error even before any discovery mechanic exists to make it worse still.
class_name DebriefConsequences
extends RefCounted

const AS_SEEN_TRUE_TRUST: int = 2
const AS_SEEN_FALSE_TRUST: int = -1
const VERIFIED_TRUE_TRUST: int = 3  ## "trust in verified claims compounds" (§4.10)
const VERIFIED_FALSE_TRUST: int = -2  ## shouldn't arise in normal play; handled, not ignored
const FABRICATE_TRUST: int = -3  ## strictly more than AS_SEEN_FALSE_TRUST, any truth_delta

const VERIFIED_TRUE_RESOURCES: int = 5  ## §4.13: budget "scales with... verified claims"
const OTHER_RESOURCES: int = 0


## Pure: given the honesty mode a claim was submitted under and its
## engine-computed truth-delta (0 = matched truth, 1 = didn't —
## `DebriefLedger.submit_claim()`'s own v0 scale), returns the trust and
## resource-budget deltas to bill. Never touches `GameStateStore` or any
## other side effect — the caller (`DebriefLedger.submit_claim()`) decides
## whether and where to apply the result.
static func bill(mode: DebriefLedger.HonestyMode, truth_delta: int) -> Dictionary:
	if mode == DebriefLedger.HonestyMode.FABRICATE:
		return {"trust_delta": FABRICATE_TRUST, "resource_delta": OTHER_RESOURCES}
	if mode == DebriefLedger.HonestyMode.VERIFIED_ONLY:
		if truth_delta == 0:
			return {"trust_delta": VERIFIED_TRUE_TRUST, "resource_delta": VERIFIED_TRUE_RESOURCES}
		return {"trust_delta": VERIFIED_FALSE_TRUST, "resource_delta": OTHER_RESOURCES}
	# AS_SEEN
	if truth_delta == 0:
		return {"trust_delta": AS_SEEN_TRUE_TRUST, "resource_delta": OTHER_RESOURCES}
	return {"trust_delta": AS_SEEN_FALSE_TRUST, "resource_delta": OTHER_RESOURCES}
