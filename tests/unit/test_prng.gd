extends AfterimageTestCase

## Reference vectors below were produced by an executable Python
## transliteration of the exact same splitmix64-seeding + xoshiro128**
## algorithm src/core/prng.gd ports, cross-checked against the canonical
## public-domain unsigned reference implementation before being pinned here
## (see prng.gd's class doc for the assumptions this cross-check exists to
## catch). If these ever fail, the first suspect is "GDScript's actual int
## overflow/shift semantics differ from the documented assumption" — not
## "the vectors were wrong."
const VECTORS: Dictionary = {
	0:
	[
		3413504692,
		1230390642,
		393209181,
		2793473942,
		2177640475,
		3613692986,
		924646641,
		2488730094,
		2732364261,
		4205770162,
		1385551876,
		1487413995
	],
	1:
	[
		264704485,
		1194741267,
		1678852802,
		535420451,
		3471461366,
		2588997986,
		4171330986,
		2629103435,
		1352480499,
		81010532,
		2975807960,
		2239492216
	],
	42:
	[
		204391854,
		1829846404,
		4021786942,
		3145627450,
		2680530925,
		1529356358,
		1652943494,
		3995478306,
		1667021057,
		2035511971,
		1935123814,
		1722865515
	],
	12345:
	[
		1096865841,
		933661059,
		3314798965,
		1305642763,
		1040785987,
		3574861911,
		2759576983,
		4258662271,
		3874155871,
		3036128573,
		2789103710,
		3614986412
	],
	2026071801:
	[
		3677068418,
		3308728261,
		1180829681,
		3328015610,
		2095502540,
		2302365635,
		1705412105,
		2681392361,
		346264552,
		3598007006,
		3165436192,
		1835141776
	],
}


func test_reference_vectors_match_across_seeds() -> void:
	for seed: int in VECTORS.keys():
		var rng := Xoshiro128StarStar.new(seed)
		var expected: Array = VECTORS[seed]
		for i: int in expected.size():
			var got: int = rng.next_u32()
			assert_eq(got, expected[i], "seed=%d draw #%d" % [seed, i])


func test_u32_stays_in_uint32_range() -> void:
	var rng := Xoshiro128StarStar.new(777)
	for i in range(2000):
		var v: int = rng.next_u32()
		assert_gte(v, 0)
		assert_lte(v, 0xFFFFFFFF)


func test_same_seed_reproduces_same_sequence() -> void:
	var a := Xoshiro128StarStar.new(9001)
	var b := Xoshiro128StarStar.new(9001)
	for i in range(50):
		assert_eq(a.next_u32(), b.next_u32(), "draw #%d" % i)


func test_different_seeds_diverge() -> void:
	var a := Xoshiro128StarStar.new(1)
	var b := Xoshiro128StarStar.new(2)
	var identical := true
	for i in range(16):
		if a.next_u32() != b.next_u32():
			identical = false
	assert_false(identical, "two different seeds produced an identical 16-draw sequence")


func test_next_float_in_unit_interval() -> void:
	var rng := Xoshiro128StarStar.new(55)
	for i in range(500):
		var f: float = rng.next_float()
		assert_gte(f, 0.0)
		assert_lt(f, 1.0)


func test_next_range_int_bounds_inclusive() -> void:
	var rng := Xoshiro128StarStar.new(123)
	for i in range(500):
		var v: int = rng.next_range_int(-3, 3)
		assert_gte(v, -3)
		assert_lte(v, 3)


func test_next_range_int_single_value_range() -> void:
	var rng := Xoshiro128StarStar.new(7)
	for i in range(20):
		assert_eq(rng.next_range_int(5, 5), 5)


func test_next_fixed_in_fixed_unit_interval() -> void:
	var rng := Xoshiro128StarStar.new(2020)
	for i in range(300):
		var fx: int = rng.next_fixed()
		assert_gte(fx, 0)
		assert_lt(fx, FixedMath.ONE)


func test_reseeding_resets_sequence() -> void:
	var rng := Xoshiro128StarStar.new(42)
	var first_draw: int = rng.next_u32()
	rng.seed_with(42)
	var after_reseed: int = rng.next_u32()
	assert_eq(first_draw, after_reseed)


func test_default_seed_is_zero() -> void:
	var a := Xoshiro128StarStar.new()
	var b := Xoshiro128StarStar.new(0)
	assert_eq(a.next_u32(), b.next_u32())
