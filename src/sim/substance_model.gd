## Substance & tool tradeoffs (master_plan.md §4.4.5): "using stabilizes
## short-term and damages long-term — modeled honestly... No mechanic ever
## makes sustained use optimal." Deliberately deferred out of Pass 11's
## MindModel scope (see that class's own docstring) because the
## stimulant's 3-day aftermath needs a real multi-day hub calendar to drive
## it — Pass 18 built that (HubCalendar), so this class is the genuinely
## unblocked follow-up the Pass 20 closing note flagged, not new scope
## invented from nothing.
##
## Sequences calls into the existing Mind Model state classes exactly like
## HubCalendar (Pass 18) and DebriefLedger (Pass 17) already do — no gain
## amount is redeclared here that a state class already owns (identity
## strain's alcohol gain lives on IdentityStrainState, matching every other
## named gain there). The two mechanics §4.4.5 needs that no existing class
## had are a temporary raised floor and a temporary gain multiplier — both
## added as small, generic primitives on FatigueState/AcuteStressState
## alongside this class, since a "floor" and a "multiplier" are per-variable
## state those classes must hold themselves.
##
## Interpretation notes (§4.4.5 states the tradeoffs in prose, not exact
## mechanics — these are the concrete, testable readings this class
## commits to, recorded here since nothing forced a single reading):
## - "fatigue floor +10 for 3 days": the fatigue variable's effective
##   minimum rises from 0 to 10 for exactly 3 subsequent advance_day()
##   calls, then reverts to 0 — a flat floor rather than a
##   snapshot-relative one, since it's simpler to reason about, to test,
##   and to disclose to the player, and produces the same honest
##   "you don't fully recover" cost either way.
## - "suppress all fatigue effects tonight": the stimulant night's own
##   sleep-choice billing is the caller's to skip entirely (this class
##   doesn't call HubCalendar.advance_day() itself) — apply_stimulant()
##   only starts the 3-day aftermath.
## - alcohol's "one random tier-1 op authorized for the scene" reads
##   literally: authorize_tier1_op() performs exactly one Director
##   authorization restricted to tier-1 entries (DistortionDirector.
##   authorize_free_tier()), bypassing budget but still respecting the
##   density cap.
## - sedatives (hub) "guarantee a full sleep block... +moral-injury decay
##   blocked that night": modeled as two independent same-night effects a
##   caller applies once — this class holds no sedative state at all,
##   unlike the stimulant's tracked 3-day window, because there is nothing
##   to remember the next day.
class_name SubstanceModel
extends RefCounted

const STIMULANT_FATIGUE_FLOOR_BONUS: int = 10
const STIMULANT_FLOOR_DURATION_DAYS: int = 3
const STIMULANT_ACUTE_STRESS_MULTIPLIER: float = 1.25

const ALCOHOL_TIER1: int = 1
const ALCOHOL_SUSPICION_RELIEF_PER_DRINK: int = -1

var _stimulant_days_remaining: int = 0


func is_stimulant_active() -> bool:
	return _stimulant_days_remaining > 0


func stimulant_days_remaining() -> int:
	return _stimulant_days_remaining


## Starts (or refreshes) the stimulant's 3-day aftermath: raises fatigue's
## temporary floor and inflates future acute-stress gains. Taking a second
## stimulant while one is still active refreshes the duration back to
## STIMULANT_FLOOR_DURATION_DAYS rather than stacking the floor/multiplier
## — §4.4.5 names one dose's effect, not a compounding one.
func apply_stimulant(fatigue: FatigueState, acute_stress: AcuteStressState) -> void:
	_stimulant_days_remaining = STIMULANT_FLOOR_DURATION_DAYS
	fatigue.set_temporary_floor(FixedMath.from_int(STIMULANT_FATIGUE_FLOOR_BONUS))
	acute_stress.set_gain_multiplier_fx(FixedMath.from_float(STIMULANT_ACUTE_STRESS_MULTIPLIER))


## Ticks the stimulant aftermath down by one day; call once per
## HubCalendar.advance_day() this stimulant is active for. Clears the
## floor and multiplier the instant the window expires — a no-op if no
## stimulant is active.
func advance_day(fatigue: FatigueState, acute_stress: AcuteStressState) -> void:
	if _stimulant_days_remaining <= 0:
		return
	_stimulant_days_remaining -= 1
	if _stimulant_days_remaining == 0:
		fatigue.clear_temporary_floor()
		acute_stress.clear_gain_multiplier()


## Alcohol at an Argus social (§4.4.5): +2 identity strain, billed
## directly since IdentityStrainState already owns that gain. Returns the
## suspicion relief this drink earns as a plain delta — this class has no
## opinion on which NPC's SuspicionLedger entries a given social scene's
## drinks discount (that's a real event-log/scene wiring question with no
## consumer yet, the same "build the real number now, wire the call site
## once a consumer exists" deferral this codebase has used since Pass 5's
## FLEE threat_level), so the caller applies it.
func apply_alcohol_drink(identity_strain: IdentityStrainState) -> int:
	identity_strain.gain_alcohol_use()
	return ALCOHOL_SUSPICION_RELIEF_PER_DRINK


## Alcohol's other clause: authorizes exactly one tier-1 Director op for
## the scene, bypassing budget. Thin pass-through to
## DistortionDirector.authorize_free_tier() — kept as its own method here
## (rather than making callers reach into the Director directly for this
## one case) so every §4.4.5 effect has exactly one SubstanceModel entry
## point, matching how HubCalendar is the one entry point for day-level
## fatigue billing.
func authorize_tier1_op(
	director: DistortionDirector, deck: Array[DeckEntry], current_tick: int
) -> Dictionary:
	return director.authorize_free_tier(deck, ALCOHOL_TIER1, current_tick)


## Sedatives (hub, §4.4.5): forces a full sleep block regardless of the
## player's chosen SleepChoice, and skips the night's moral-injury passive
## decay (the sedative meant the player didn't process anything, not that
## they processed it well) — the caller simply doesn't call
## MoralInjuryState.decay_passive_daily() for a sedative night, so this
## method only needs to own the sleep-block half.
func apply_sedative_night(fatigue: FatigueState) -> void:
	fatigue.apply_sleep_full_block()
