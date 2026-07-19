## Moral injury (master_plan.md §4.4.3): the slow, sticky Mind Model
## variable. Decays near-zero passively; the only meaningful decay is
## active, confession-shaped (a Dr. Sova session, a hard truth to Doubek).
## See mind_model.gd for how the four states compose.
class_name MoralInjuryState
extends RefCounted

const GAIN_KILL_IN_OPEN_COMBAT: int = 4
const GAIN_KILL_OF_UNAWARE_VICTIM: int = 6
const GAIN_EXECUTING_DOWNED_ENEMY: int = 9
const GAIN_CIVILIAN_CASUALTY: int = 15
const GAIN_BETRAYING_FRIENDLY_ARGUS_NPC: int = 8
const GAIN_KNOWING_LIE_IN_DEBRIEF: int = 3
const GAIN_KNOWING_LIE_CONCEALING_DEATH: int = 5
const DECAY_PASSIVE_PER_DAY: float = -0.1
const SOVA_SESSION_MIN: int = -4
const SOVA_SESSION_MAX: int = -8
const DOUBEK_HARD_TRUTH: int = -6

const _MIN_FX: int = 0
const _MAX_FX: int = 6553600  # FixedMath.from_int(100)

var _value_fx: int = 0


func value_fx() -> int:
	return _value_fx


func _add_fx(delta_fx: int) -> void:
	_value_fx = clampi(_value_fx + delta_fx, _MIN_FX, _MAX_FX)


func gain_kill_in_open_combat() -> void:
	_add_fx(FixedMath.from_int(GAIN_KILL_IN_OPEN_COMBAT))


func gain_kill_of_unaware_victim() -> void:
	_add_fx(FixedMath.from_int(GAIN_KILL_OF_UNAWARE_VICTIM))


func gain_executing_downed_enemy() -> void:
	_add_fx(FixedMath.from_int(GAIN_EXECUTING_DOWNED_ENEMY))


func gain_civilian_casualty() -> void:
	_add_fx(FixedMath.from_int(GAIN_CIVILIAN_CASUALTY))


func gain_betraying_friendly_argus_npc() -> void:
	_add_fx(FixedMath.from_int(GAIN_BETRAYING_FRIENDLY_ARGUS_NPC))


func gain_knowing_lie_in_debrief(conceals_death: bool) -> void:
	var amount: int = (
		GAIN_KNOWING_LIE_CONCEALING_DEATH if conceals_death else GAIN_KNOWING_LIE_IN_DEBRIEF
	)
	_add_fx(FixedMath.from_int(amount))


func decay_passive_daily() -> void:
	_add_fx(FixedMath.from_float(DECAY_PASSIVE_PER_DAY))


## A Dr. Sova session heals -4 to -8, scaled by how much the player
## actually discloses. `disclosure_t_fx` is a Q16.16 value in
## [0, FixedMath.ONE]: 0 is minimal disclosure (-4), ONE is full disclosure
## (-8).
func apply_sova_session(disclosure_t_fx: int) -> void:
	var delta_fx: int = FixedMath.lerp_fx(
		FixedMath.from_int(SOVA_SESSION_MIN), FixedMath.from_int(SOVA_SESSION_MAX), disclosure_t_fx
	)
	_add_fx(delta_fx)


func apply_doubek_hard_truth() -> void:
	_add_fx(FixedMath.from_int(DOUBEK_HARD_TRUTH))
