## Acute stress (master_plan.md §4.4.1): the fast-moving Mind Model
## variable. One of MindModel's four composed sub-states — split into its
## own file (rather than one giant MindModel class) because each variable's
## gain/decay methods alone approach gdlint's 20-public-method cap; see
## mind_model.gd for how the four compose and for the shared Band/band_for.
class_name AcuteStressState
extends RefCounted

enum Zone { SAFE, MISSION_CALM, MISSION_ALERTED }

const TICK_RATE: int = 30

const GAIN_ENTERING_COMBAT: int = 8
const GAIN_GUNFIRE_IN_EARSHOT: int = 2
const GAIN_NEAR_DISCOVERY: int = 10
const GAIN_WITNESSING_KILL: int = 6
const GAIN_ACTING_ON_BELIEVED_PHANTOM: int = 5
const GAIN_FOCUS_USE: int = 6
const RELIEF_GROUND_COMPLETED: int = -8
const DECAY_SAFE_PER_SECOND: float = -0.4
const DECAY_MISSION_CALM_PER_SECOND: float = -0.1

## FixedMath.from_int(100); every state class inlines this, matching
## MindModel.MAX_FX — consts can't call statics.
const _MIN_FX: int = 0
const _MAX_FX: int = 6553600

var _value_fx: int = 0

## §4.4.5's stimulant aftermath: "acute-stress gains ×1.25" — FixedMath.ONE
## (no inflation) unless a caller (SubstanceModel) has raised it. Applies
## only to the gain_* methods below, never to relieve_ground_completed()
## (a relief, not a gain) or advance_tick()/advance_ticks() (passive decay,
## not something the stimulant's cost inflates).
var _gain_multiplier_fx: int = FixedMath.ONE


static func _trunc_div(a: int, b: int) -> int:
	var quotient: int = absi(a) / absi(b)
	if (a < 0) != (b < 0):
		return -quotient
	return quotient


static func _per_tick_decay_fx(rate_per_second: float, ticks: int) -> int:
	var rate_fx: int = FixedMath.from_float(rate_per_second)
	return _trunc_div(rate_fx * ticks, TICK_RATE)


func value_fx() -> int:
	return _value_fx


func _add_fx(delta_fx: int) -> void:
	_value_fx = clampi(_value_fx + delta_fx, _MIN_FX, _MAX_FX)


## Every gain_* method routes its named constant through this instead of
## calling _add_fx() directly, so the stimulant multiplier applies
## uniformly without each gain method having to know it exists.
func _add_gain_fx(base_amount: int) -> void:
	_add_fx(FixedMath.mul(FixedMath.from_int(base_amount), _gain_multiplier_fx))


func gain_multiplier_fx() -> int:
	return _gain_multiplier_fx


## §4.4.5's stimulant cost: inflate every future stress gain by this
## multiplier (Q16.16; ONE = no change) until clear_gain_multiplier() is
## called. Setting it again before clearing simply replaces it — there is
## no stacking rule to honor since only one stimulant multiplier exists.
func set_gain_multiplier_fx(multiplier_fx: int) -> void:
	_gain_multiplier_fx = multiplier_fx


func clear_gain_multiplier() -> void:
	_gain_multiplier_fx = FixedMath.ONE


func gain_entering_combat() -> void:
	_add_gain_fx(GAIN_ENTERING_COMBAT)


func gain_gunfire_in_earshot() -> void:
	_add_gain_fx(GAIN_GUNFIRE_IN_EARSHOT)


func gain_near_discovery() -> void:
	_add_gain_fx(GAIN_NEAR_DISCOVERY)


func gain_witnessing_kill() -> void:
	_add_gain_fx(GAIN_WITNESSING_KILL)


func gain_acting_on_believed_phantom() -> void:
	_add_gain_fx(GAIN_ACTING_ON_BELIEVED_PHANTOM)


func gain_focus_use() -> void:
	_add_gain_fx(GAIN_FOCUS_USE)


func relieve_ground_completed() -> void:
	_add_fx(FixedMath.from_int(RELIEF_GROUND_COMPLETED))


## One sim tick's worth of decay. Safe to call unconditionally once per
## TruthSim tick regardless of zone — MISSION_ALERTED applies no decay at
## all (§4.4.1 only names safe-zone and no-hostiles-alerted rates), matching
## FocusState/GroundState's call-every-tick-regardless-of-state style.
func advance_tick(zone: Zone) -> void:
	advance_ticks(1, zone)


## Batch form of advance_tick for `ticks` consecutive ticks in the same
## zone — one multiply-then-divide instead of `ticks` separate truncating
## divisions, so a long soak doesn't accumulate more rounding error than a
## single call would.
func advance_ticks(ticks: int, zone: Zone) -> void:
	match zone:
		Zone.SAFE:
			_add_fx(_per_tick_decay_fx(DECAY_SAFE_PER_SECOND, ticks))
		Zone.MISSION_CALM:
			_add_fx(_per_tick_decay_fx(DECAY_MISSION_CALM_PER_SECOND, ticks))
		Zone.MISSION_ALERTED:
			pass


## §4.4.1's hub-rest rule: rest raises acute stress to `floor_fx` — a
## floor, not a set: it only ever raises the value toward it, never lowers
## it below wherever it already was. `floor_fx` is computed by MindModel
## (max(fatigue, moralInjury) × 0.3) since that spans two other states this
## class has no reference to.
func apply_hub_rest_floor(floor_fx: int) -> void:
	_value_fx = maxi(_value_fx, floor_fx)
