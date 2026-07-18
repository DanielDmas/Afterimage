## The sim's only notion of time (tech_guidelines.md §3.1): a whole-number
## tick counter advancing at a fixed 30 Hz. TruthSim (Pass 3+) never reads
## engine `delta` — every system that needs "how long" converts an
## authored duration to ticks once at load (TICKS_PER_SECOND) and then only
## ever counts ticks.
class_name FixedTickClock
extends RefCounted

const TICK_RATE_HZ: int = 30
const TICK_DURATION_SECONDS: float = 1.0 / float(TICK_RATE_HZ)

var current_tick: int = 0


func advance() -> int:
	current_tick += 1
	return current_tick


func reset() -> void:
	current_tick = 0


## Converts an authored duration (seconds) to a whole tick count, rounding
## to the nearest tick. Content authors write seconds; the sim only ever
## sees ticks (tech_guidelines.md §3.1).
static func seconds_to_ticks(seconds: float) -> int:
	return int(round(seconds * float(TICK_RATE_HZ)))
