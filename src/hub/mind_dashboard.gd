## master_plan.md §4.11's mind dashboard: "framed as Dr. Sova's worksheets
## — the four variables rendered diegetically... bands not numbers by
## default (numbers togglable in options; no shame in playing with the
## hood open)."
##
## A read-only view model over a MindModel (Pass 11) — never mutates it,
## only reads `value_fx()` off each sub-state and converts to the
## presentation shape a future worksheet UI (Pass 19) will bind to. Living
## in `src/hub/` rather than `src/percept/` is deliberate: this reads
## `src/sim/`'s MindModel directly by name, which `src/percept/` may never
## do (tools/percept_truth_boundary_lint.py) — the hub isn't part of the
## percept/truth boundary at all, so there's nothing to route around here.
class_name MindDashboard
extends RefCounted

const BAND_LABELS: Dictionary = {
	MindModel.Band.QUIET: "Quiet",
	MindModel.Band.MURMUR: "Murmur",
	MindModel.Band.LOUD: "Loud",
	MindModel.Band.CRISIS: "Crisis",
}


static func _variable_view(value_fx: int, show_numbers: bool) -> Dictionary:
	var band: MindModel.Band = MindModel.band_for(value_fx)
	var view: Dictionary = {"band": BAND_LABELS[band]}
	if show_numbers:
		view["value"] = FixedMath.to_int_round(value_fx)
	return view


## `show_numbers` defaults false — bands are the default presentation;
## exact values are an opt-in options toggle, per spec.
static func snapshot(mind: MindModel, show_numbers: bool = false) -> Dictionary:
	return {
		"acute_stress": _variable_view(mind.acute_stress.value_fx(), show_numbers),
		"fatigue": _variable_view(mind.fatigue.value_fx(), show_numbers),
		"moral_injury": _variable_view(mind.moral_injury.value_fx(), show_numbers),
		"identity_strain": _variable_view(mind.identity_strain.value_fx(), show_numbers),
	}
