## Fairness auditor v1 (master_plan.md §10: "static analysis of decks,
## missions, and op placements against the Charter"). Statically validates
## a deck — any Array of duck-typed op-like objects exposing op_class,
## tier, cost, dramatic_intent, fairness_tags (real DistortionOp instances,
## or minimal test doubles shaped like one) — against every rule in §4.5's
## Fairness Charter, returning a list of violation strings (empty = clean).
##
## Scope for v1: only the Charter rules that are genuinely checkable from
## deck-authoring data today. Several rules are also (or primarily)
## enforced structurally elsewhere and this auditor adds a second,
## independent static check on top rather than being their only guard —
## consistent with this codebase's existing belt-and-suspenders pattern for
## the percept/truth boundary (Pass 8): structural guarantee *and* a static
## check, not one or the other.
## - Rule 1 (phantoms never damage/block): structurally guaranteed by the
##   percept/truth boundary (a phantom has no truth-layer counterpart to
##   deal damage with); this auditor additionally requires every
##   Phantom*-class entry to *declare* compliance via fairness_tags.
## - Rule 2 (EntityMask never on damage-capable entities): not yet
##   structurally enforceable (EntityMask isn't implemented — Pass 9 built
##   4 of the 10 taxonomy classes) — this is real op-class-string matching
##   against a required tag, ready for whenever EntityMask lands.
## - Rule 3 (inputs never distorted): structurally guaranteed by the
##   taxonomy itself (no op class touches input/aim/hit registration);
##   this auditor additionally requires every entry, regardless of class,
##   to declare that tag.
## - Rule 4 (geometry never changes while observed): same status as rule 2
##   — real string matching, ready for GeometrySwap.
## - Rule 5 (everything disclosable): every entry must declare it.
## - Rule 6 (Clarity Mode can flag it): structurally guaranteed by
##   ClarityMode.active_flags()'s `is DistortionOp` check (Pass 10) — this
##   auditor's check is that every deck entry actually *is* a real
##   DistortionOp (not a Dictionary or unrelated object Clarity Mode would
##   silently skip).
## - Rule 7 (density/cooling caps): a deck-level check, not per-entry — the
##   mission's declared encounter cap must not exceed the Director's global
##   MAX_CONCURRENT_OPS.
## - Rule 8 (Theater never lies/forges): the Theater/debrief (Pass 14+)
##   can't honestly disclose an op's dramatic intent if the op never
##   declared a real one — every entry's dramatic_intent must be one of
##   the four named in §4.2 (dread/doubt/grief/paranoia).
class_name FairnessAuditor
extends RefCounted

const KNOWN_OP_CLASSES: Array[String] = [
	"SubtitleDrift",
	"AudioSwap",
	"PhantomAudio",
	"HUDGlitch",
	"ObjectSwap",
	"FamiliarFace",
	"PhantomEntity",
	"EntityMask",
	"GeometrySwap",
	"TimeGap",
	"MemoryEdit",
]
const PHANTOM_OP_CLASSES: Array[String] = ["PhantomEntity", "PhantomAudio"]
const VALID_DRAMATIC_INTENTS: Array[String] = ["dread", "doubt", "grief", "paranoia"]

const TAG_RULE_1: String = "charter_rule_1_never_damages_never_blocks"
const TAG_RULE_2: String = "charter_rule_2_never_masks_damage_capable_entities"
const TAG_RULE_3: String = "charter_rule_3_inputs_never_distorted"
const TAG_RULE_4: String = "charter_rule_4_never_changes_while_observed"
const TAG_RULE_5: String = "charter_rule_5_always_disclosable"

## DistortionDirector.MAX_CONCURRENT_OPS, inlined: a cross-file const
## reference would work in GDScript, but this codebase has consistently
## avoided any cross-file compile-time reference it hasn't had to make
## (see MindModel's per-state-class MIN_FX/MAX_FX duplication) — one less
## thing to re-verify if either constant ever moves.
const MAX_ENCOUNTER_CAP: int = 3


static func validate(deck: Array, encounter_cap: int) -> Array[String]:
	var violations: Array[String] = []
	for entry: Variant in deck:
		violations.append_array(_validate_entry(entry))
	if encounter_cap > MAX_ENCOUNTER_CAP:
		violations.append(
			"rule_7:encounter_cap_%d_exceeds_max_%d" % [encounter_cap, MAX_ENCOUNTER_CAP]
		)
	return violations


static func passes(deck: Array, encounter_cap: int) -> bool:
	return validate(deck, encounter_cap).is_empty()


static func _validate_entry(entry: Variant) -> Array[String]:
	var violations: Array[String] = []
	var op_class: String = entry.op_class
	if not (op_class in KNOWN_OP_CLASSES):
		violations.append("unknown_op_class:%s" % op_class)
		return violations

	var fairness_tags: Array = entry.fairness_tags
	if op_class in PHANTOM_OP_CLASSES and not (TAG_RULE_1 in fairness_tags):
		violations.append("rule_1:%s" % op_class)
	if op_class == "EntityMask" and not (TAG_RULE_2 in fairness_tags):
		violations.append("rule_2:%s" % op_class)
	if not (TAG_RULE_3 in fairness_tags):
		violations.append("rule_3:%s" % op_class)
	if op_class == "GeometrySwap" and not (TAG_RULE_4 in fairness_tags):
		violations.append("rule_4:%s" % op_class)
	if not (TAG_RULE_5 in fairness_tags):
		violations.append("rule_5:%s" % op_class)
	if not (entry is DistortionOp):
		violations.append("rule_6:%s" % op_class)
	if not (entry.dramatic_intent in VALID_DRAMATIC_INTENTS):
		violations.append("rule_8:%s" % op_class)
	return violations
