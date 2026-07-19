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


func value_fx() -> int:
	return _value_fx


func _add_fx(delta_fx: int) -> void:
	_value_fx = clampi(_value_fx + delta_fx, _MIN_FX, _MAX_FX)


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
