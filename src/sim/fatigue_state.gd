## Fatigue (master_plan.md §4.4.2): the daily Mind Model variable. Decays
## only via sleep — a deliberate design commitment against "coffee as
## cure," so this class has no per-tick advance_tick() at all, unlike
## AcuteStressState. See mind_model.gd for how the four states compose.
class_name FatigueState
extends RefCounted

const GAIN_SKIPPED_SLEEP_BLOCK: int = 12
const GAIN_HOUR_AWAKE_PAST_18: int = 2
const GAIN_GROUND_USE: float = 1.5
const GAIN_WHITE_NIGHT_MISSION: int = 10
const DECAY_SLEEP_FULL_BLOCK: int = -40
const DECAY_SLEEP_PARTIAL_BLOCK: int = -15

const _MIN_FX: int = 0
const _MAX_FX: int = 6553600  # FixedMath.from_int(100)

var _value_fx: int = 0

## A temporary raised minimum (§4.4.5's stimulant aftermath: "fatigue floor
## +10 for 3 days") — 0 (no floor beyond the permanent _MIN_FX) unless a
## caller (SubstanceModel) has raised it. Never lowers _MIN_FX itself.
var _temporary_floor_fx: int = _MIN_FX


func value_fx() -> int:
	return _value_fx


func _add_fx(delta_fx: int) -> void:
	_value_fx = clampi(_value_fx + delta_fx, _temporary_floor_fx, _MAX_FX)


## Raises the temporary floor to `floor_fx`, immediately lifting the
## current value to match if it's currently below that — the same
## raise-only-never-lower contract AcuteStressState.apply_hub_rest_floor()
## already established for hub rest. Calling this again before the floor
## is cleared simply re-raises it (SubstanceModel.apply_stimulant()
## refreshes the duration rather than stacking the amount).
func set_temporary_floor(floor_fx: int) -> void:
	_temporary_floor_fx = floor_fx
	_value_fx = maxi(_value_fx, _temporary_floor_fx)


## Removes the temporary floor. Deliberately does not touch `_value_fx` —
## clearing a floor should never itself reduce fatigue, only stop
## enforcing a raised minimum going forward.
func clear_temporary_floor() -> void:
	_temporary_floor_fx = _MIN_FX


func gain_skipped_sleep_block() -> void:
	_add_fx(FixedMath.from_int(GAIN_SKIPPED_SLEEP_BLOCK))


func gain_hour_awake_past_18() -> void:
	_add_fx(FixedMath.from_int(GAIN_HOUR_AWAKE_PAST_18))


func gain_ground_use() -> void:
	_add_fx(FixedMath.from_float(GAIN_GROUND_USE))


func gain_white_night_mission() -> void:
	_add_fx(FixedMath.from_int(GAIN_WHITE_NIGHT_MISSION))


func apply_sleep_full_block() -> void:
	_add_fx(FixedMath.from_int(DECAY_SLEEP_FULL_BLOCK))


func apply_sleep_partial_block() -> void:
	_add_fx(FixedMath.from_int(DECAY_SLEEP_PARTIAL_BLOCK))
