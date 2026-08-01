## Deterministic xoshiro128** PRNG (Blackman & Vigna's public-domain
## algorithm), state-seeded via four splitmix64 draws from a single 64-bit
## seed (the seeding technique the algorithm's own reference code
## recommends). tech_guidelines.md D5: one named, seeded stream per system —
## never share an instance between systems, and never substitute Godot's
## built-in RandomNumberGenerator in sim code (we don't control its algorithm
## or its version-to-version stability, and determinism is the whole point).
##
## Every constant and shift below was cross-checked against an executable
## Python reference implementation before being ported (see
## tools/prng_reference/ once that lands; for now, the exact seed=0/1/42/
## 12345/2026071801 vectors are pinned in tests/unit/test_prng.gd). GDScript's
## `int` is a 64-bit signed integer; this implementation assumes standard
## two's-complement wraparound on overflow for +, -, * and that `>>` is an
## arithmetic (sign-extending) right shift — both are documented Godot 4
## behaviors. Where splitmix64's algorithm needs a *logical* (unsigned) right
## shift, that is emulated explicitly via _urshift64() rather than assumed.
class_name Xoshiro128StarStar
extends RefCounted

const MASK32: int = 0xFFFFFFFF

## 0x9E3779B97F4A7C15 as a signed 64-bit two's-complement literal.
const SPLITMIX_INC: int = -7046029254386353131
## 0xBF58476D1CE4E5B9 as a signed 64-bit two's-complement literal.
const SPLITMIX_MUL1: int = -4658895280553007687
## 0x94D049BB133111EB as a signed 64-bit two's-complement literal.
const SPLITMIX_MUL2: int = -7723592293110705685

## Logical-right-shift correction masks: (1 << (64 - k)) - 1, precomputed so
## no runtime shift ever approaches the 1<<63 overflow edge case.
const URSHIFT_MASK_27: int = 137438953471  ## (1 << 37) - 1
const URSHIFT_MASK_30: int = 17179869183  ## (1 << 34) - 1
const URSHIFT_MASK_31: int = 8589934591  ## (1 << 33) - 1

var _s0: int
var _s1: int
var _s2: int
var _s3: int
var _sm_state: int


func _init(seed: int = 0) -> void:
	seed_with(seed)


func seed_with(seed: int) -> void:
	_sm_state = seed
	_s0 = _splitmix_next() & MASK32
	_s1 = _splitmix_next() & MASK32
	_s2 = _splitmix_next() & MASK32
	_s3 = _splitmix_next() & MASK32


## Logical (unsigned-semantics) right shift of a value that represents a
## 64-bit unsigned quantity stored in a signed int64. When x is non-negative,
## arithmetic and logical shift already agree. When x is negative (its top
## bit is set), the sign-extended 1s introduced by `>>` are masked off.
static func _urshift64(x: int, k: int, mask_if_negative: int) -> int:
	if x >= 0:
		return x >> k
	return (x >> k) & mask_if_negative


func _splitmix_next() -> int:
	_sm_state = _sm_state + SPLITMIX_INC
	var z: int = _sm_state
	z = (z ^ _urshift64(z, 30, URSHIFT_MASK_30)) * SPLITMIX_MUL1
	z = (z ^ _urshift64(z, 27, URSHIFT_MASK_27)) * SPLITMIX_MUL2
	z = z ^ _urshift64(z, 31, URSHIFT_MASK_31)
	return z


static func _rotl32(x: int, k: int) -> int:
	var xm: int = x & MASK32
	return ((xm << k) | (xm >> (32 - k))) & MASK32


## Returns the next value as an unsigned 32-bit integer in [0, 2^32).
func next_u32() -> int:
	var result: int = (_rotl32((_s1 * 5) & MASK32, 7) * 9) & MASK32
	var t: int = (_s1 << 9) & MASK32
	_s2 = _s2 ^ _s0
	_s3 = _s3 ^ _s1
	_s1 = _s1 ^ _s2
	_s0 = _s0 ^ _s3
	_s2 = _s2 ^ t
	_s3 = _rotl32(_s3, 11)
	return result


## Returns a float in [0, 1).
func next_float() -> float:
	return float(next_u32()) / 4294967296.0


## Returns an integer in [lo, hi] inclusive, via Lemire-free modulo (accepted
## small bias for gameplay-scale ranges; if a range ever needs to be
## bias-free at scale, revisit with rejection sampling rather than silently
## "fixing" this one - see tests/unit/test_prng.gd for the documented bias
## bound at our actual usage ranges).
func next_range_int(lo: int, hi: int) -> int:
	assert(hi >= lo, "Xoshiro128StarStar.next_range_int: hi < lo")
	var span: int = hi - lo + 1
	return lo + (next_u32() % span)


## Returns a Q16.16 fixed-point value in [0, FixedMath.ONE) — for sim code
## that wants a fractional draw without ever touching a float (tech_guidelines
## §3.2's "no ad-hoc float math in sim code" applies to consumers of this
## stream, even though next_u32()'s own internals use only integer ops).
func next_fixed() -> int:
	return next_u32() >> 16
