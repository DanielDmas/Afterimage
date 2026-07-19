## The four-variable Mind Model (master_plan.md §4.4): acute stress,
## fatigue, moral injury, identity strain — all diegetic, all clamped to a
## shared 0-100 band scale (Quiet/Murmur/Loud/Crisis). Each variable lives
## in its own small state class (AcuteStressState, FatigueState,
## MoralInjuryState, IdentityStrainState) — one file per variable, not one
## mega-class, because each variable's own gain/decay methods alone
## approach gdlint's 20-public-method cap. MindModel composes the four and
## owns the one piece of cross-variable logic §4.4 actually needs: the
## hub-rest floor, which reads fatigue and moral injury to raise acute
## stress.
##
## This class is intentionally a pure data/arithmetic model with no
## consumers wired in yet: nothing calls gain_*/decay_* from TruthSim or the
## hub, because combat (moral injury), Ground (fatigue), Focus (acute
## stress), and the day/night calendar (fatigue-by-hour, per-day decay,
## identity strain) all still bill nothing into MindModel (their own dev_log
## entries flagged this explicitly, back to Pass 5's AiUtility threat_level
## and Pass 6's FocusState.activation_count). Wiring those call sites is
## later passes' job once each has a real consumer-side reason to exist —
## DistortionDirector (Pass 12) is the first system that actually reads
## band state.
##
## Substance/tool modifiers (§4.4.5 — stimulant/alcohol/sedative tradeoffs)
## are deliberately out of scope here: they need a multi-day "effect window"
## (the stimulant's 3-day fatigue-floor-and-stress-multiplier aftermath)
## that only a real hub calendar (Pass 18) can drive, and they're their own
## roadmap.md M3 line item, not part of this pass's "four variables +
## worked-example fixtures" scope.
class_name MindModel
extends RefCounted

enum Band { QUIET, MURMUR, LOUD, CRISIS }

const MIN_FX: int = 0
const MAX_FX: int = 6553600  # FixedMath.from_int(100)

const BAND_MURMUR_THRESHOLD_FX: int = 1638400  # FixedMath.from_int(25)
const BAND_LOUD_THRESHOLD_FX: int = 3276800  # FixedMath.from_int(50)
const BAND_CRISIS_THRESHOLD_FX: int = 4915200  # FixedMath.from_int(75)

const HUB_REST_FLOOR_FACTOR: float = 0.3

var acute_stress: AcuteStressState
var fatigue: FatigueState
var moral_injury: MoralInjuryState
var identity_strain: IdentityStrainState


func _init() -> void:
	acute_stress = AcuteStressState.new()
	fatigue = FatigueState.new()
	moral_injury = MoralInjuryState.new()
	identity_strain = IdentityStrainState.new()


## Shared by all four variables — §4.4's band table is one scale, defined
## once here rather than duplicated in each state class.
static func band_for(value_fx: int) -> Band:
	if value_fx >= BAND_CRISIS_THRESHOLD_FX:
		return Band.CRISIS
	if value_fx >= BAND_LOUD_THRESHOLD_FX:
		return Band.LOUD
	if value_fx >= BAND_MURMUR_THRESHOLD_FX:
		return Band.MURMUR
	return Band.QUIET


## §4.4.1's hub-rest rule: rest returns acute stress to a floor of
## max(fatigue, moralInjury) × 0.3 — a floor, not a set.
func apply_hub_rest() -> void:
	var floor_fx: int = FixedMath.mul(
		maxi(fatigue.value_fx(), moral_injury.value_fx()),
		FixedMath.from_float(HUB_REST_FLOOR_FACTOR)
	)
	acute_stress.apply_hub_rest_floor(floor_fx)
