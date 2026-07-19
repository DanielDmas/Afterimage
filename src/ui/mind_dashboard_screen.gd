## Builds a ScreenSpec for master_plan.md §4.11's mind dashboard ("framed
## as Dr. Sova's worksheets") from a real MindModel, honoring
## AccessibilitySettings' "numbers togglable in options" preference — the
## first concrete tie between the hub's data (Pass 18's MindDashboard),
## the UI shell's screen-spec shape, and the accessibility settings this
## same pass introduces.
class_name MindDashboardScreen
extends RefCounted

const ROW_LABELS: Dictionary = {
	"acute_stress": "Acute Stress",
	"fatigue": "Fatigue",
	"moral_injury": "Moral Injury",
	"identity_strain": "Identity Strain",
}
## Deterministic row order (tech_guidelines §3.5) — never Dictionary
## iteration order.
const ROW_ORDER: Array[String] = ["acute_stress", "fatigue", "moral_injury", "identity_strain"]


static func build(mind: MindModel, settings: AccessibilitySettings) -> ScreenSpec:
	var snapshot: Dictionary = MindDashboard.snapshot(mind, settings.mind_dashboard_shows_numbers)
	var screen := ScreenSpec.new("Dr. Sova's Worksheets")
	for variable_name: String in ROW_ORDER:
		var view: Dictionary = snapshot[variable_name]
		var value_text: String = view["band"]
		if view.has("value"):
			value_text = "%s (%d)" % [view["band"], view["value"]]
		screen.add_row(ROW_LABELS[variable_name], value_text)
	return screen
