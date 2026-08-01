## master_plan.md §4.2: "Bounded set only: map annotations, objective
## phrasing, clock time, journal margin notes. **Never** health, ammo,
## stamina, input prompts." Ground response: "Affected element flickers
## true."
##
## The "bounded set only" restriction is structural here, not just
## authoring guidance: `_init()` asserts `p_element_kind` is one of
## `ALLOWED_ELEMENT_KINDS`, so a content author (or a future op-builder
## bug) cannot construct a HUDGlitch targeting `"health"`/`"ammo"`/
## `"stamina"`/`"input_prompt"` at all — the same "make the illegal state
## unconstructible" discipline PhantomEntity's negative-id argument
## already established for Charter rule 1.
##
## Operates on an optional `snapshot["hud_elements"]` key (Array of
## `{"element_id", "element_kind", "true_value"}` Dictionaries) —  no HUD
## truth concept exists yet (no UI layer has been built in any pass so
## far), so this is a no-op whenever the key is absent, tested here
## against a hand-built synthetic snapshot, the same discipline
## SubtitleDrift's dialogue deferral already established.
class_name HUDGlitch
extends DistortionOp

const TIER: int = 2
const COST: int = 10

const ALLOWED_ELEMENT_KINDS: Array[String] = [
	"map_annotation",
	"objective_phrasing",
	"clock_time",
	"journal_margin_note",
]

var target_element_id: String
var glitched_value: String


func _init(
	p_target_element_id: String, p_glitched_value: String, p_dramatic_intent: String = "doubt"
) -> void:
	op_class = "HUDGlitch"
	tier = TIER
	cost = COST
	dramatic_intent = p_dramatic_intent
	fairness_tags = ["charter_rule_3_inputs_never_distorted", "charter_rule_5_always_disclosable"]
	target_element_id = p_target_element_id
	glitched_value = p_glitched_value


func apply(snapshot: Dictionary) -> Dictionary:
	if not snapshot.has("hud_elements"):
		return snapshot
	var out: Dictionary = snapshot.duplicate(true)
	var elements: Array = []
	for elt: Dictionary in out["hud_elements"] as Array:
		var e: Dictionary = elt.duplicate(true)
		if String(e.get("element_id", "")) == target_element_id:
			assert(
				String(e.get("element_kind", "")) in ALLOWED_ELEMENT_KINDS,
				(
					"HUDGlitch: element_kind '%s' is not in the Charter's bounded set"
					% e.get("element_kind", "")
				)
			)
			e["rendered_value"] = glitched_value
			e["grounded"] = false
		elements.append(e)
	out["hud_elements"] = elements
	return out


func resolve_grounded(snapshot: Dictionary) -> Dictionary:
	if not snapshot.has("hud_elements"):
		return snapshot
	var out: Dictionary = snapshot.duplicate(true)
	var elements: Array = []
	for elt: Dictionary in out["hud_elements"] as Array:
		var e: Dictionary = elt.duplicate(true)
		if String(e.get("element_id", "")) == target_element_id:
			e["rendered_value"] = e.get("true_value", "")
			e["grounded"] = true
		elements.append(e)
	out["hud_elements"] = elements
	return out
