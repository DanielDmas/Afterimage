## Ground verb hold-duration state machine (master_plan.md §4.6). Input
## model is deliberately just "is grounding requested this tick" — a
## plain bool, agnostic to whether the caller derived it from a
## continuous hold or a hold-to-toggle accessibility alternative (§4.16):
## both schemes produce the exact same tick-by-tick true/false stream
## from this class's point of view, so there is nothing input-scheme-
## specific to model here. Building the actual input-sampling layer that
## turns a device signal into that stream is a future presentation-layer
## concern, the same "InputFrame arrives already resolved" contract every
## verb in this codebase has used since Pass 6.
class_name GroundState
extends RefCounted

const DURATION_TICKS: int = 75  # 2.5s at the fixed 30Hz tick rate (§4.6
# baseline). Fatigue Loud+ extends this to 3.5s (105 ticks) - MindModel
# (Pass 11) doesn't exist yet to gate that extension on, so only the
# baseline duration is wired; documented deferral, not a silent gap.

var use_count: int = 0

var _hold_ticks_elapsed: int = 0
var _completed_this_tick: bool = false


func is_holding() -> bool:
	return _hold_ticks_elapsed > 0 and _hold_ticks_elapsed < DURATION_TICKS


## True only on the exact tick the hold reaches DURATION_TICKS — the
## trigger for "resolve everything now" (§4.6: "resolves all active ops
## in scope simultaneously"), not a sustained state.
func just_completed() -> bool:
	return _completed_this_tick


## Advances the hold by one tick if `requested` is true; releasing early
## (requested=false before completion) resets progress — §4.6 doesn't
## describe a partial-hold consequence, so releasing early is simply
## "nothing happened," the same as never having held at all.
func advance_tick(requested: bool) -> void:
	_completed_this_tick = false
	if not requested:
		_hold_ticks_elapsed = 0
		return
	_hold_ticks_elapsed += 1
	if _hold_ticks_elapsed >= DURATION_TICKS:
		_hold_ticks_elapsed = 0
		_completed_this_tick = true
		use_count += 1
