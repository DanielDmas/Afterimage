## One NPC's suspicion ledger (master_plan.md §4.7): "typed observations
## with weight 1-10... Entries decay -1/week if unreinforced." Lives
## outside NPC itself (see npc.gd's header) — SuspicionGraph owns one of
## these per NPC.
##
## Decay is a pure function of (weight, day_added, query day) — recomputed
## on every query rather than mutating stored entries on some periodic
## tick, so `total()` is always consistent regardless of how often (or
## rarely) it's called, with no risk of double-decaying or missing a
## decay step. An entry whose `day_added` is still in the future (a
## gossip-propagated entry that hasn't "arrived" yet) contributes nothing
## until the query day reaches it.
class_name SuspicionLedger
extends RefCounted

## master_plan §4.7's own named weights.
const WEIGHT_SEEN_GROUNDING: int = 2
const WEIGHT_POLICE_PATTERN_BEHAVIOR: int = 4
const WEIGHT_COVER_INCONSISTENT_EQUIPMENT: int = 5
const WEIGHT_IMPLAUSIBLE_SURVIVAL: int = 6
## "inconsistency between two things Radek said: 3-6 via the
## interrupt-memory system" - a range, not a single value; callers pick
## within it based on how stark the contradiction was.
const WEIGHT_INTERRUPT_MEMORY_INCONSISTENCY_MIN: int = 3
const WEIGHT_INTERRUPT_MEMORY_INCONSISTENCY_MAX: int = 6

const DECAY_PER_WEEK: int = 1
const DAYS_PER_WEEK: int = 7

var _entries: Array[Dictionary] = []  ## [{type: String, weight: int, day_added: int}]


func add_entry(entry_type: String, weight: int, day_added: int) -> void:
	_entries.append({"type": entry_type, "weight": weight, "day_added": day_added})


func entries() -> Array:
	return _entries.duplicate(true)


## Sum of every entry's decayed weight as of `current_day`, floored at 0
## per entry (an entry can decay to nothing, never below it) and excluding
## entries that haven't arrived yet (`day_added > current_day`).
func total(current_day: int) -> int:
	var sum: int = 0
	for entry: Dictionary in _entries:
		var day_added: int = entry["day_added"]
		if day_added > current_day:
			continue
		var weeks_elapsed: int = (current_day - day_added) / DAYS_PER_WEEK
		sum += maxi(0, entry["weight"] - weeks_elapsed * DECAY_PER_WEEK)
	return sum
