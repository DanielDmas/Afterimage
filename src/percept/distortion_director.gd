## The Distortion Director (master_plan.md §4.3): a deterministic
## AI-director-style budgeter that decides which DistortionOps a scene can
## afford and picks among them, seeded so the exact same purchase sequence
## replays given the same seed and mind-state trace.
##
## Deliberately takes plain data (Dictionary[String, int] fx values,
## Strings, ints) everywhere rather than referencing MindModel or any
## src/sim/ class directly — the Director's own output (a purchase log of
## op-class name/tier/cost/tick records) is equally plain data, not live
## DistortionOp instances. This keeps the whole class fully decoupled from
## both the truth layer and the concrete op classes: a future caller reads
## `mind.acute_stress.value_fx()` etc. into a Dictionary before calling in,
## and turns a purchase record's `op_class` String into a real DistortionOp
## afterwards. Nothing here mutates truth and nothing here needs to.
##
## Every worked-example fixture below was hand-verified against a Python
## Q16.16 reference before porting, per this project's "verify externally,
## then port" discipline — Pass 11 demonstrated that even careful
## per-formula verification can still miss a wrong premise about how two
## code paths relate, so this pass additionally double-checks any
## "these should produce the same number" assumption against the actual
## truncating arithmetic rather than trusting it by inspection.
class_name DistortionDirector
extends RefCounted

enum SceneType { SOCIAL, INFILTRATION, COMBAT, HUB }

const BASE_POINTS_SOCIAL: int = 20
const BASE_POINTS_INFILTRATION: int = 30
const BASE_POINTS_COMBAT: int = 25
const BASE_POINTS_HUB: int = 10

const BUDGET_BASE_MULTIPLIER: float = 0.4

const MAX_CONCURRENT_OPS: int = 3
const TIER_SPACING_MIN_TIER: int = 3
const TIER_SPACING_MIN_TICKS: int = 600  # 20s at the fixed 30Hz tick rate

const DEATH_COOLING_FIRST: float = 0.6
const DEATH_COOLING_SECOND_AND_LATER: float = 0.3

## Not given an exact number by §4.3 ("the op class's weight in this scene
## decays") — a tuning baseline for M3 playtests, same status as §4.4's
## named constants. Halves an op class's selection weight in this scene
## each time Ground resolves it, compounding on repeats.
const GROUND_RESOLVED_WEIGHT_DECAY_FACTOR: float = 0.5

## Every deck entry gets at least this much selection weight even when its
## affinity variables are all at 0 — otherwise a zero-affinity op could
## never be purchased at all, which "weighted deck" doesn't imply.
const MIN_AFFINITY_WEIGHT: float = 0.01

var budget: int = 0

var _rng: Xoshiro128StarStar
var _active_op_count: int = 0
var _last_tier_spacing_purchase_tick: int = -TIER_SPACING_MIN_TICKS
var _death_count_this_encounter: int = 0
var _purchase_log: Array[Dictionary] = []
var _op_class_weight_decay_fx: Dictionary = {}


func _init(seed: int) -> void:
	_rng = Xoshiro128StarStar.new(seed)


## One RNG stream per system (tech_guidelines D5), seeded from (run seed,
## mission id, scene id) so re-simulation reproduces every purchase
## tick-perfectly (§4.3's "Seeding"). A simple deterministic bit-mixing
## combination, not a cryptographic hash — mission_id/scene_id are expected
## to fit well within 20 bits each (a documented assumption, not enforced,
## matching this codebase's general "trust internal callers" stance).
static func seed_for(run_seed: int, mission_id: int, scene_id: int) -> int:
	return run_seed ^ (mission_id << 20) ^ (scene_id << 40)


static func base_points(scene_type: SceneType) -> int:
	match scene_type:
		SceneType.SOCIAL:
			return BASE_POINTS_SOCIAL
		SceneType.INFILTRATION:
			return BASE_POINTS_INFILTRATION
		SceneType.COMBAT:
			return BASE_POINTS_COMBAT
		SceneType.HUB:
			return BASE_POINTS_HUB
	return 0


static func _variable_fraction_fx(value_fx: int) -> int:
	return FixedMath.div(value_fx, FixedMath.from_int(100))


## §4.3: B = base(sceneType) × (0.4 + Σ wᵥ · v/100). `mind_values_fx` and
## `mission_weights_fx` are both Dictionary[String, int] keyed by mind
## variable name ("acute_stress", "fatigue", "moral_injury",
## "identity_strain"), values in Q16.16 — `mind_values_fx` from each
## MindModel sub-state's value_fx() (0-100 scale), `mission_weights_fx`
## mission-authored (typically 0-2ish). A variable absent from
## `mission_weights_fx` contributes zero. Result floors to an int budget
## point count (never rounds up past what was actually earned).
static func compute_budget(
	scene_type: SceneType, mind_values_fx: Dictionary, mission_weights_fx: Dictionary
) -> int:
	var variable_names: Array = mind_values_fx.keys()
	variable_names.sort()
	var sum_fx: int = 0
	for variable_name: String in variable_names:
		var weight_fx: int = mission_weights_fx.get(variable_name, 0)
		if weight_fx == 0:
			continue
		sum_fx += FixedMath.mul(weight_fx, _variable_fraction_fx(mind_values_fx[variable_name]))
	var multiplier_fx: int = FixedMath.from_float(BUDGET_BASE_MULTIPLIER) + sum_fx
	var budget_fx: int = FixedMath.mul(FixedMath.from_int(base_points(scene_type)), multiplier_fx)
	return FixedMath.to_int_floor(budget_fx)


func grant_budget(
	scene_type: SceneType, mind_values_fx: Dictionary, mission_weights_fx: Dictionary
) -> void:
	budget += compute_budget(scene_type, mind_values_fx, mission_weights_fx)


func active_op_count() -> int:
	return _active_op_count


func purchase_log() -> Array:
	return _purchase_log.duplicate(true)


## Called by a future caller once a purchased op's live instance stops
## being active, so the density cap reflects reality rather than
## cumulative purchase count.
func notify_op_deactivated() -> void:
	_active_op_count = maxi(0, _active_op_count - 1)


## §4.3's Ground-resolution rule: "refund 0 — but the op class's weight in
## this scene decays."
func notify_ground_resolved(op_class: String) -> void:
	var current_fx: int = _op_class_weight_decay_fx.get(op_class, FixedMath.ONE)
	_op_class_weight_decay_fx[op_class] = FixedMath.mul(
		current_fx, FixedMath.from_float(GROUND_RESOLVED_WEIGHT_DECAY_FACTOR)
	)


## §4.3/Charter rule 7: on player death, encounter budget ×0.6; second (and
## any later) death in the same encounter ×0.3.
func apply_death_cooling() -> void:
	_death_count_this_encounter += 1
	var factor: float = (
		DEATH_COOLING_FIRST if _death_count_this_encounter == 1 else DEATH_COOLING_SECOND_AND_LATER
	)
	budget = FixedMath.to_int_floor(
		FixedMath.mul(FixedMath.from_int(budget), FixedMath.from_float(factor))
	)


func _affinity_weight_fx(entry: DeckEntry, mind_values_fx: Dictionary) -> int:
	var weight_fx: int = 0
	for variable_name: String in entry.variable_affinity:
		weight_fx += _variable_fraction_fx(mind_values_fx.get(variable_name, 0))
	if weight_fx <= 0:
		weight_fx = FixedMath.from_float(MIN_AFFINITY_WEIGHT)
	var decay_fx: int = _op_class_weight_decay_fx.get(entry.op_class, FixedMath.ONE)
	return FixedMath.mul(weight_fx, decay_fx)


## Attempts one purchase from `deck` against the current budget, respecting
## the global density cap, tier-3+ spacing, and Ground-resolution weight
## decay. Returns the purchase record ({tick, op_class, tier, cost}) on
## success, or an empty Dictionary if nothing was eligible (cap reached, or
## every entry unaffordable/too-soon-after-a-tier-3+ purchase). Charter
## legality itself (§4.3: "an illegal purchase is a build failure, not a
## runtime clamp") is FairnessAuditor's job on the deck before it ever
## reaches here, not re-checked per purchase.
func purchase_one(
	deck: Array[DeckEntry], mind_values_fx: Dictionary, current_tick: int
) -> Dictionary:
	if _active_op_count >= MAX_CONCURRENT_OPS:
		return {}

	var eligible_indices: Array[int] = []
	var weights_fx: Array[int] = []
	var total_weight_fx: int = 0
	for i: int in range(deck.size()):
		var entry: DeckEntry = deck[i]
		if entry.cost > budget:
			continue
		if (
			entry.tier >= TIER_SPACING_MIN_TIER
			and current_tick - _last_tier_spacing_purchase_tick < TIER_SPACING_MIN_TICKS
		):
			continue
		var weight_fx: int = _affinity_weight_fx(entry, mind_values_fx)
		eligible_indices.append(i)
		weights_fx.append(weight_fx)
		total_weight_fx += weight_fx

	if eligible_indices.is_empty():
		return {}

	var draw_fx: int = FixedMath.mul(_rng.next_fixed(), total_weight_fx)
	var running_fx: int = 0
	var chosen_index: int = eligible_indices[-1]
	for j: int in range(eligible_indices.size()):
		running_fx += weights_fx[j]
		if draw_fx < running_fx:
			chosen_index = eligible_indices[j]
			break

	var chosen: DeckEntry = deck[chosen_index]
	budget -= chosen.cost
	_active_op_count += 1
	if chosen.tier >= TIER_SPACING_MIN_TIER:
		_last_tier_spacing_purchase_tick = current_tick
	var record: Dictionary = {
		"tick": current_tick, "op_class": chosen.op_class, "tier": chosen.tier, "cost": chosen.cost
	}
	_purchase_log.append(record)
	return record


## §4.4.5's alcohol clause: "one random tier-1 op authorized for the
## scene" — bypasses the budget/weight gate entirely (this op is
## authorized, not earned), picking uniformly at random via this
## Director's own seeded stream among deck entries at exactly `tier` so
## the determinism guarantee (§4.3: "same seed, same purchase sequence")
## extends to this path too. Still respects the density cap (Charter rule
## 7 is a hard cap, not a budget-gated one) — a saturated encounter gains
## no fourth op just because a drink was poured. Returns the authorized
## record (with "authorized": true so Theater/debrief disclosure, Charter
## rule 8, never conflates an authorized op with a purchased one), or an
## empty Dictionary if the cap is already full or no entry at that tier
## exists in this deck.
func authorize_free_tier(deck: Array[DeckEntry], tier: int, current_tick: int) -> Dictionary:
	if _active_op_count >= MAX_CONCURRENT_OPS:
		return {}

	var eligible_indices: Array[int] = []
	for i: int in range(deck.size()):
		if deck[i].tier == tier:
			eligible_indices.append(i)
	if eligible_indices.is_empty():
		return {}

	var pick: int = _rng.next_range_int(0, eligible_indices.size() - 1)
	var chosen: DeckEntry = deck[eligible_indices[pick]]

	_active_op_count += 1
	if chosen.tier >= TIER_SPACING_MIN_TIER:
		_last_tier_spacing_purchase_tick = current_tick
	var record: Dictionary = {
		"tick": current_tick,
		"op_class": chosen.op_class,
		"tier": chosen.tier,
		"cost": 0,
		"authorized": true,
	}
	_purchase_log.append(record)
	return record
