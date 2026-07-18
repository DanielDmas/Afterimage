## Utility-scored AI decision-making (master_plan.md §5.5: "utility-scored
## behaviors over small state" — patrol/investigate/engage/flee/report).
## Pure functions of a Perception snapshot: no hidden state, easy to test
## exhaustively, and the AI design bar ("legible over clever," §4.9) is
## best served by scoring formulas simple enough to read as a spec.
##
## `Perception.threat_level` is a placeholder for Pass 6 (combat/health):
## it defaults to 0, so FLEE never wins yet. This keeps the five-state
## shape master_plan.md names complete now, without fabricating health
## data that doesn't exist — Pass 6 populates it for real.
class_name AiUtility
extends RefCounted

enum State { PATROL, INVESTIGATE, ENGAGE, FLEE, REPORT }

## Fixed priority order for tie-breaking (first entry wins ties) — never
## depends on iteration/Dictionary order (tech_guidelines.md §3.5).
const _PRIORITY_ORDER: Array = [
	State.ENGAGE, State.REPORT, State.FLEE, State.INVESTIGATE, State.PATROL
]


class Perception:
	var can_see_target: bool = false
	var has_last_known_position: bool = false
	var heard_noise: bool = false
	var just_spotted: bool = false  ## true only on the tick sight is newly acquired
	var threat_level: int = 0  ## 0-100; Pass 6 will populate this for real


static func score_patrol(_p: Perception) -> int:
	return 10  # always somewhat viable: the idle/default state


static func score_investigate(p: Perception) -> int:
	if p.can_see_target:
		return 0  # already resolved to a sighting; no need to go investigate it
	if p.heard_noise or p.has_last_known_position:
		return 60
	return 0


static func score_engage(p: Perception) -> int:
	return 100 if p.can_see_target else 0


static func score_flee(p: Perception) -> int:
	return clampi(p.threat_level, 0, 100)


## Outranks score_engage() (100) deliberately: the intended narrative is
## "spot the player, call it in on the one tick that just happened, then
## engage from the next tick onward" (just_spotted is only true for that
## single tick — see AiAgent), not "report forever instead of engaging."
static func score_report(p: Perception) -> int:
	return 110 if p.just_spotted else 0


static func score_for(state: State, p: Perception) -> int:
	match state:
		State.PATROL:
			return score_patrol(p)
		State.INVESTIGATE:
			return score_investigate(p)
		State.ENGAGE:
			return score_engage(p)
		State.FLEE:
			return score_flee(p)
		State.REPORT:
			return score_report(p)
		_:
			assert(false, "AiUtility.score_for: unhandled state %s" % state)
			return 0


## Picks the highest-scoring state; ties broken by _PRIORITY_ORDER so the
## result never depends on iteration order.
static func best_state(p: Perception) -> State:
	var best: State = _PRIORITY_ORDER[0]
	var best_score: int = score_for(best, p)
	for state: State in _PRIORITY_ORDER:
		var score: int = score_for(state, p)
		if score > best_score:
			best = state
			best_score = score
	return best
