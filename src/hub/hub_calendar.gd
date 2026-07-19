## master_plan.md §4.11's Safehouse Hub calendar & sleep economy: "hub time
## advances in blocks (evening/night/morning); sleep consumes blocks
## (§4.4.2)... Mission windows are authored per mission — the pressure is
## scheduling, never a real-time timer."
##
## v0 scope: `Block` is modeled as real data (a future org-board/loadout-
## prep UI schedules activities within a day's three blocks), but the one
## mechanic this pass actually drives — because it's the one with a
## concrete AC ("a full sleep-debt week produces the §4.4.2 fatigue
## trace") — is the day-level sleep choice billing directly into Pass 11's
## `FatigueState`. Competing for blocks (org-board work, alibi
## construction, Sova sessions, Tereza calls, equipment prep, §4.11) needs
## those systems' own hub-time costs authored, which doesn't exist before
## real mission/hub content — this class doesn't invent numbers for them.
class_name HubCalendar
extends RefCounted

enum Block { EVENING, NIGHT, MORNING }
enum SleepChoice { SKIPPED, PARTIAL, FULL }

var current_day: int = 0


## Advances exactly one day, billing its sleep choice (and any extra
## fatigue-relevant activity that day) into `fatigue` via Pass 11's own
## FatigueState methods — this class never duplicates §4.4.2's constants,
## only sequences calls into the class that already owns them.
func advance_day(
	sleep_choice: SleepChoice,
	fatigue: FatigueState,
	hours_awake_past_18: int = 0,
	ground_uses: int = 0
) -> void:
	match sleep_choice:
		SleepChoice.SKIPPED:
			fatigue.gain_skipped_sleep_block()
		SleepChoice.PARTIAL:
			fatigue.apply_sleep_partial_block()
		SleepChoice.FULL:
			fatigue.apply_sleep_full_block()

	for _i: int in range(hours_awake_past_18):
		fatigue.gain_hour_awake_past_18()
	for _i: int in range(ground_uses):
		fatigue.gain_ground_use()

	current_day += 1
