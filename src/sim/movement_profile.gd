## Player movement-mode speeds and their sound signature (master_plan.md
## §4.9 combat verbs: move/sprint/crouch). Converts an authored per-tick
## speed and an input direction into the per-tick millimeter delta
## TruthSim.step() expects (see that class's doc: "turning player intent
## ... into that delta is a combat-verb concern (Pass 6), not this
## layer's"). Deliberately not wired into TruthSim yet — roadmap.md's
## Pass 7 is "graybox test level wiring TruthSim+AI+combat," the same
## order Pass 4 (LOS/sound) and Pass 5 (vision/AI) shipped their pieces
## standalone-and-tested before a later pass wired them together.
class_name MovementProfile
extends RefCounted

enum Mode { WALK, SPRINT, CROUCH }

## Per-tick speeds at the fixed 30 Hz sim rate (tech_guidelines.md §3.1),
## authored directly as integer mm/tick rather than derived at runtime
## from a float m/s division — positions and their deltas are plain
## integer millimeters (tech_guidelines D4), so no float division belongs
## anywhere near them.
const WALK_MM_PER_TICK: int = 47  # ~1.41 m/s, brisk walk
const SPRINT_MM_PER_TICK: int = 80  # ~2.40 m/s
const CROUCH_MM_PER_TICK: int = 23  # ~0.69 m/s, half of walk

## One tick's noise contribution, in the abstract loudness unit
## CombatResolver.is_noise_heard_at() consumes. Walking and crouching are
## silent under this v1 model; only sprinting is loud enough to model as
## a noise event (master_plan §4.9: "sprint (noise)").
const SPRINT_NOISE_LOUDNESS: int = 60
const _SILENT: int = 0


static func speed_mm_per_tick(mode: Mode) -> int:
	match mode:
		Mode.SPRINT:
			return SPRINT_MM_PER_TICK
		Mode.CROUCH:
			return CROUCH_MM_PER_TICK
		_:
			return WALK_MM_PER_TICK


static func noise_loudness(mode: Mode) -> int:
	if mode == Mode.SPRINT:
		return SPRINT_NOISE_LOUDNESS
	return _SILENT


## `dir`'s components are each expected to already be quantized to -1, 0,
## or 1 (tech_guidelines §3.1: sampled input is quantized before it ever
## reaches the sim, so a replay is byte-exact regardless of the recording
## device's analog precision) — any larger magnitude is clamped rather
## than trusted. Diagonal movement is not speed-normalized in this pass:
## that is a feel-tuning question for the Pass 7 graybox playtest (§4.9's
## tuning checklist), not a correctness one, so it is documented here
## rather than silently decided either way.
static func resolve_delta(dir: Vector2i, mode: Mode) -> Vector2i:
	var speed: int = speed_mm_per_tick(mode)
	return Vector2i(clampi(dir.x, -1, 1) * speed, clampi(dir.y, -1, 1) * speed)
