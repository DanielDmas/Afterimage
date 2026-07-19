## Identity strain (master_plan.md §4.4.4): how much of Radek's cover has
## started to feel like the truth. Decay only comes from deliberate
## Eliška-anchor acts, each authored with its own risk or time cost. See
## mind_model.gd for how the four states compose.
class_name IdentityStrainState
extends RefCounted

const GAIN_DAY_IN_COVER: int = 1
const GAIN_RADEK_SKILL_CHECK_PASSED: int = 2
const GAIN_RADEK_METHOD_ACT: int = 4
const GAIN_ARGUS_MONEY_PERSONAL_COMFORT: int = 2
const DECAY_ELISKA_ANCHOR_ACT: int = -3

const _MIN_FX: int = 0
const _MAX_FX: int = 6553600  # FixedMath.from_int(100)

var _value_fx: int = 0


func value_fx() -> int:
	return _value_fx


func _add_fx(delta_fx: int) -> void:
	_value_fx = clampi(_value_fx + delta_fx, _MIN_FX, _MAX_FX)


func gain_day_in_cover() -> void:
	_add_fx(FixedMath.from_int(GAIN_DAY_IN_COVER))


func gain_radek_skill_check_passed() -> void:
	_add_fx(FixedMath.from_int(GAIN_RADEK_SKILL_CHECK_PASSED))


func gain_radek_method_act() -> void:
	_add_fx(FixedMath.from_int(GAIN_RADEK_METHOD_ACT))


func gain_argus_money_personal_comfort() -> void:
	_add_fx(FixedMath.from_int(GAIN_ARGUS_MONEY_PERSONAL_COMFORT))


func decay_eliska_anchor_act() -> void:
	_add_fx(FixedMath.from_int(DECAY_ELISKA_ANCHOR_ACT))
