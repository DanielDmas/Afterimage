## docs/forward_dev_plan.md Phase C's "debrief-screen-as-data": extends
## `ScreenSpec`'s "a placeholder screen as data, not a Godot scene"
## discipline (that class's own doc) to the one screen `ScreenSpec`'s
## plain label/value rows can't quite express — a debrief claim needs its
## own per-row choice of legal honesty modes, not just a value to display.
##
## `available_modes` per row excludes `VERIFIED_ONLY` unless the claim
## actually carries GROUNDED/EVIDENCE provenance — surfacing the same
## eligibility rule `DebriefLedger.submit_claim()` enforces with an assert,
## here as a query the caller (a future real UI) can use to only ever
## offer legal choices, rather than letting the player pick an
## always-illegal option and hit the assert.
class_name DebriefScreen
extends RefCounted

const ALWAYS_AVAILABLE_MODES: Array[DebriefLedger.HonestyMode] = [
	DebriefLedger.HonestyMode.AS_SEEN, DebriefLedger.HonestyMode.FABRICATE
]

var title: String
var claim_rows: Array[Dictionary] = []  ## [{"claim_id", "summary", "available_modes"}]


func _init(p_title: String = "Debrief") -> void:
	title = p_title


static func build(ledger: DebriefLedger) -> DebriefScreen:
	var screen := DebriefScreen.new()
	for claim: Claim in ledger.candidates():
		var modes: Array[DebriefLedger.HonestyMode] = ALWAYS_AVAILABLE_MODES.duplicate()
		var verifiable: bool = (
			claim.has_provenance_type(Claim.ProvenanceType.GROUNDED)
			or claim.has_provenance_type(Claim.ProvenanceType.EVIDENCE)
		)
		if verifiable:
			modes.append(DebriefLedger.HonestyMode.VERIFIED_ONLY)
		(
			screen
			. claim_rows
			. append(
				{
					"claim_id": claim.id,
					"summary": "%s %s %s" % [claim.subject, claim.predicate, claim.object_value],
					"available_modes": modes,
				}
			)
		)
	return screen


## ux_charter §4's "screen-reader on all paperwork/menu screens" —
## MindDashboardScreen's own precedent, built from this spec's own data
## rather than scene-tree traversal (no scene tree exists to traverse).
func screen_reader_text() -> String:
	var text: String = title
	for row: Dictionary in claim_rows:
		text += "\nClaim: %s" % row["summary"]
	return text
