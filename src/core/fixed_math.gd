## Deterministic Q16.16 fixed-point arithmetic for sim-core scalar math —
## MindModel curves, DistortionDirector budget formulas, utility AI scores,
## decay constants (tech_guidelines.md §3.2).
##
## This is NOT for world-space coordinates: positions are plain integer
## millimeters (tech_guidelines.md D4) and need no scaling at all. FixedMath
## exists for the *fractional* quantities the sim reasons about — a 0-100
## mind variable, a weight, a multiplier — never for raw geometry.
##
## Safe operand domain for mul()/div(): pre-scale magnitudes up to roughly
## 2^23 (about 8.3 million) keep the 64-bit intermediate product inside
## int64 range. Every quantity this module is meant for sits many orders of
## magnitude below that ceiling, so callers in the intended domain never
## need to think about overflow.
class_name FixedMath
extends RefCounted

const FRAC_BITS: int = 16
const SCALE: int = 1 << FRAC_BITS  ## 65536
const ONE: int = SCALE
const HALF: int = SCALE >> 1
const ZERO: int = 0


static func from_int(i: int) -> int:
	return i * SCALE


static func from_float(f: float) -> int:
	return int(round(f * float(SCALE)))


static func to_float(fx: int) -> float:
	return float(fx) / float(SCALE)


## Floors toward negative infinity (matches GDScript's arithmetic >>).
static func to_int_floor(fx: int) -> int:
	return fx >> FRAC_BITS


static func to_int_round(fx: int) -> int:
	if fx >= 0:
		return (fx + HALF) >> FRAC_BITS
	return -(((-fx) + HALF) >> FRAC_BITS)


static func mul(a: int, b: int) -> int:
	return (a * b) >> FRAC_BITS


static func div(a: int, b: int) -> int:
	assert(b != 0, "FixedMath.div: division by zero")
	return (a << FRAC_BITS) / b


static func clamp_fx(fx: int, lo: int, hi: int) -> int:
	return clampi(fx, lo, hi)


## t is itself expected to be a Q16.16 value in [0, ONE]; values outside that
## range extrapolate rather than clamp — callers who want clamped lerp should
## clamp t themselves first.
static func lerp_fx(a: int, b: int, t: int) -> int:
	return a + mul(b - a, t)


static func abs_fx(fx: int) -> int:
	return absi(fx)


static func sign_fx(fx: int) -> int:
	return signi(fx)


## Convenience for the many "0-100 band value" scalars in MindModel
## (master_plan.md §4.4): builds a Q16.16 fixed value directly from an
## integer percentage-like scale without an intermediate float round-trip.
static func from_percent(p: int) -> int:
	return from_int(p)
