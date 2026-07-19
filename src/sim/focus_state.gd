## Tick-accurate activation/duration/cooldown state machine for the Focus
## verb (master_plan.md §4.9: "0.4× time for 3s; +6 acute stress billed
## after"). This class owns only the *gating* — can it be activated right
## now, and for how many more ticks is it active — not the perceptual
## time-dilation effect itself: TruthSim runs at a fixed 30 Hz always
## (tech_guidelines §3.1's determinism contract does not let the sim's own
## tick rate vary), so "0.4× time" has to be a presentation-layer trick —
## rendering the same fixed-rate ticks over more wall-clock time, slowing
## audio/visual playback — not a truth-sim mechanic. That presentation
## work has no consumer yet (nothing renders anything until Pass 7's
## graybox room), so it is deferred; what is real and sim-relevant right
## now is the resource gate itself (how often Focus can be used), which is
## what a future HUD meter and MindModel's acute-stress billing (Pass 11)
## will read from.
##
## The acute-stress cost (+6, per §4.9) is not applied here for the same
## reason: MindModel doesn't exist yet to receive it. `activation_count`
## is exposed so billing can be wired in later without this class
## changing shape — the same "build the state machine now, wire the
## consumer later" pattern Pass 5's AiUtility used for FLEE's threat_level.
class_name FocusState
extends RefCounted

const DURATION_TICKS: int = 90  # 3s at the fixed 30Hz tick rate
const COOLDOWN_TICKS: int = 150  # 5s before Focus can be used again

var activation_count: int = 0

var _active_ticks_remaining: int = 0
var _cooldown_ticks_remaining: int = 0


func is_active() -> bool:
	return _active_ticks_remaining > 0


func is_on_cooldown() -> bool:
	return _cooldown_ticks_remaining > 0


func can_activate() -> bool:
	return not is_active() and not is_on_cooldown()


func activate() -> bool:
	if not can_activate():
		return false
	_active_ticks_remaining = DURATION_TICKS
	activation_count += 1
	return true


## Advances all timers by one tick. Safe to call unconditionally once per
## TruthSim tick regardless of whether Focus is active — a no-op timer
## decrement costs nothing, and callers shouldn't need to inspect this
## class's internal state just to decide whether to call it.
func advance_tick() -> void:
	if _active_ticks_remaining > 0:
		_active_ticks_remaining -= 1
		if _active_ticks_remaining == 0:
			_cooldown_ticks_remaining = COOLDOWN_TICKS
	elif _cooldown_ticks_remaining > 0:
		_cooldown_ticks_remaining -= 1
