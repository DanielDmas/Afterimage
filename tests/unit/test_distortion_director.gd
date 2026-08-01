extends AfterimageTestCase

## Every fx-value assertion was hand-verified against a Python Q16.16
## reference before porting. The weighted-pick tests additionally reuse the
## exact next_u32()/next_fixed() vectors already pinned and CI-confirmed in
## test_prng.gd (seed=0 and seed=1) rather than re-deriving them — the same
## real, executable-reference discipline, just against an existing
## already-verified fixture instead of a fresh script.


func test_seed_for_produces_distinct_seeds_for_distinct_inputs() -> void:
	var a: int = DistortionDirector.seed_for(1, 2, 3)
	var b: int = DistortionDirector.seed_for(1, 2, 4)
	var c: int = DistortionDirector.seed_for(1, 3, 3)
	assert_ne(a, b)
	assert_ne(a, c)
	assert_ne(b, c)


## Worked example (§4.3): combat scene (base 25), acute_stress=40,
## fatigue=20, moral_injury=10, identity_strain=5 (v/100 = 0.4/0.2/0.1/0.05)
## with mission weights 1.0/0.5/1.5/0.2 sums to Σ ≈ 0.66, multiplier ≈ 1.06,
## B ≈ 26.5, floored to 26.
func test_compute_budget_worked_example() -> void:
	var mind_values_fx: Dictionary = {
		"acute_stress": FixedMath.from_int(40),
		"fatigue": FixedMath.from_int(20),
		"moral_injury": FixedMath.from_int(10),
		"identity_strain": FixedMath.from_int(5),
	}
	var mission_weights_fx: Dictionary = {
		"acute_stress": FixedMath.from_float(1.0),
		"fatigue": FixedMath.from_float(0.5),
		"moral_injury": FixedMath.from_float(1.5),
		"identity_strain": FixedMath.from_float(0.2),
	}
	var budget: int = DistortionDirector.compute_budget(
		DistortionDirector.SceneType.COMBAT, mind_values_fx, mission_weights_fx
	)
	assert_eq(budget, 26)


func test_compute_budget_ignores_variables_absent_from_mission_weights() -> void:
	var mind_values_fx: Dictionary = {"acute_stress": FixedMath.from_int(100)}
	var budget: int = DistortionDirector.compute_budget(
		DistortionDirector.SceneType.HUB, mind_values_fx, {}
	)
	# multiplier is just the 0.4 floor term; base_hub=10 * 0.4 = 4.0
	# mathematically, but 0.4 has no exact Q16.16 representation
	# (0.4 * 65536 = 26214.4, rounds down to 26214), so 10 * 0.4 in fixed
	# point lands at fx 262140 (3.99993...), which floors to 3, not 4 —
	# verified against a Python reference before pinning this number.
	assert_eq(budget, 3)


func test_grant_budget_adds_to_existing_budget() -> void:
	var director := DistortionDirector.new(1)
	director.budget = 10
	director.grant_budget(DistortionDirector.SceneType.HUB, {}, {})
	assert_eq(director.budget, 13)  # 10 + floor(10 * 0.4 in fixed point) = 10 + 3


## Worked example: budget 26 -> floor(26*0.6)=15 after the first death ->
## floor(15*0.3)=4 after the second.
func test_apply_death_cooling_worked_example() -> void:
	var director := DistortionDirector.new(1)
	director.budget = 26
	director.apply_death_cooling()
	assert_eq(director.budget, 15)
	director.apply_death_cooling()
	assert_eq(director.budget, 4)


func test_apply_death_cooling_uses_the_second_factor_for_every_death_after_the_first() -> void:
	var director := DistortionDirector.new(1)
	director.budget = 100
	director.apply_death_cooling()  # ->60
	director.apply_death_cooling()  # ->18
	var before_third: int = director.budget
	director.apply_death_cooling()  # third death: still x0.3, not a further-decaying factor
	assert_eq(
		director.budget,
		FixedMath.to_int_floor(
			FixedMath.mul(FixedMath.from_int(before_third), FixedMath.from_float(0.3))
		)
	)


func test_purchase_one_reproducible_given_same_seed() -> void:
	var deck: Array[DeckEntry] = [
		DeckEntry.new("AudioSwap", 1, 5, ["acute_stress"]),
		DeckEntry.new("PhantomAudio", 1, 5, ["moral_injury"]),
	]
	var mind_values_fx: Dictionary = {
		"acute_stress": FixedMath.from_int(40), "moral_injury": FixedMath.from_int(20)
	}

	var log_a: Array = []
	var director_a := DistortionDirector.new(1)
	director_a.budget = 1000
	for i: int in range(12):
		log_a.append(director_a.purchase_one(deck, mind_values_fx, i))
		director_a.notify_op_deactivated()

	var log_b: Array = []
	var director_b := DistortionDirector.new(1)
	director_b.budget = 1000
	for i: int in range(12):
		log_b.append(director_b.purchase_one(deck, mind_values_fx, i))
		director_b.notify_op_deactivated()

	assert_eq(log_a, log_b)
	assert_eq(director_a.purchase_log(), director_b.purchase_log())


## Hand-verified against test_prng.gd's pinned seed=0/seed=1 next_u32()
## vectors: seed=1's first weighted draw picks "AudioSwap" (draw_fx 2423 <
## weight_A_fx 26214), seed=0's first draw picks "PhantomAudio" instead
## (draw_fx 31250 >= 26214) — different seeds are not required to diverge
## on every draw, but this pair genuinely does on the very first one.
func test_purchase_one_picks_differ_across_seeds() -> void:
	var deck: Array[DeckEntry] = [
		DeckEntry.new("AudioSwap", 1, 5, ["acute_stress"]),
		DeckEntry.new("PhantomAudio", 1, 5, ["moral_injury"]),
	]
	var mind_values_fx: Dictionary = {
		"acute_stress": FixedMath.from_int(40), "moral_injury": FixedMath.from_int(20)
	}

	var director_seed1 := DistortionDirector.new(1)
	director_seed1.budget = 1000
	var first_pick_seed1: Dictionary = director_seed1.purchase_one(deck, mind_values_fx, 0)

	var director_seed0 := DistortionDirector.new(0)
	director_seed0.budget = 1000
	var first_pick_seed0: Dictionary = director_seed0.purchase_one(deck, mind_values_fx, 0)

	assert_eq(first_pick_seed1["op_class"], "AudioSwap")
	assert_eq(first_pick_seed0["op_class"], "PhantomAudio")


func test_purchase_one_respects_the_global_density_cap() -> void:
	var deck: Array[DeckEntry] = [DeckEntry.new("SubtitleDrift", 1, 1, [])]
	var director := DistortionDirector.new(1)
	director.budget = 1000
	for i: int in range(DistortionDirector.MAX_CONCURRENT_OPS):
		var record: Dictionary = director.purchase_one(deck, {}, i)
		assert_false(record.is_empty())
	assert_eq(director.active_op_count(), DistortionDirector.MAX_CONCURRENT_OPS)

	var blocked: Dictionary = director.purchase_one(deck, {}, 999)
	assert_true(blocked.is_empty())


## deck_index (post-arc addition) is what lets a caller turn a purchase
## record back into a real op instance (OpFactory.build(deck[deck_index]))
## without matching op_class/tier/cost by value, which would be ambiguous
## the moment a deck ever authors two same-shaped entries with different
## params — see MissionRuntime, the first real caller.
func test_purchase_one_records_the_purchased_deck_index() -> void:
	var deck: Array[DeckEntry] = [
		DeckEntry.new("SubtitleDrift", 1, 5, []), DeckEntry.new("AudioSwap", 1, 5, [])
	]
	var director := DistortionDirector.new(1)
	director.budget = 1000
	var record: Dictionary = director.purchase_one(deck, {}, 0)
	assert_eq(deck[record["deck_index"]].op_class, record["op_class"])


func test_purchase_one_skips_unaffordable_entries() -> void:
	var deck: Array[DeckEntry] = [DeckEntry.new("TimeGap", 4, 30, [])]
	var director := DistortionDirector.new(1)
	director.budget = 5
	var record: Dictionary = director.purchase_one(deck, {}, 0)
	assert_true(record.is_empty())
	assert_eq(director.budget, 5)


func test_purchase_one_enforces_tier_3_plus_spacing() -> void:
	var deck: Array[DeckEntry] = [DeckEntry.new("PhantomEntity", 3, 25, [])]
	var director := DistortionDirector.new(1)
	director.budget = 1000

	var first: Dictionary = director.purchase_one(deck, {}, 0)
	assert_false(first.is_empty())
	director.notify_op_deactivated()

	var too_soon: Dictionary = director.purchase_one(
		deck, {}, DistortionDirector.TIER_SPACING_MIN_TICKS - 1
	)
	assert_true(too_soon.is_empty())

	var after_spacing: Dictionary = director.purchase_one(
		deck, {}, DistortionDirector.TIER_SPACING_MIN_TICKS
	)
	assert_false(after_spacing.is_empty())


## §4.3's Ground-resolution rule made concrete: 4 undecayed purchase_one()
## calls against seed=1's known draws all pick "AudioSwap" (the higher
## base-weight entry). After notify_ground_resolved("AudioSwap") halves
## its weight, the next 8 calls (continuing the same seed=1 draw sequence)
## pick "PhantomAudio" 6 of 8 times where they'd have split differently
## undecayed — hand-computed against the exact same Python reference as
## the rest of this file, not asserted from a vague "it should shift"
## expectation.
func test_notify_ground_resolved_decays_future_selection_weight() -> void:
	var deck: Array[DeckEntry] = [
		DeckEntry.new("AudioSwap", 1, 5, ["acute_stress"]),
		DeckEntry.new("PhantomAudio", 1, 5, ["moral_injury"]),
	]
	var mind_values_fx: Dictionary = {
		"acute_stress": FixedMath.from_int(40), "moral_injury": FixedMath.from_int(20)
	}
	var director := DistortionDirector.new(1)
	director.budget = 1000

	var picks: Array[String] = []
	for i: int in range(4):
		var record: Dictionary = director.purchase_one(deck, mind_values_fx, i)
		picks.append(record["op_class"])
		director.notify_op_deactivated()

	director.notify_ground_resolved("AudioSwap")

	for i: int in range(4, 12):
		var record: Dictionary = director.purchase_one(deck, mind_values_fx, i)
		picks.append(record["op_class"])
		director.notify_op_deactivated()

	assert_eq(
		picks,
		[
			"AudioSwap",
			"AudioSwap",
			"AudioSwap",
			"AudioSwap",
			"PhantomAudio",
			"PhantomAudio",
			"PhantomAudio",
			"PhantomAudio",
			"AudioSwap",
			"AudioSwap",
			"PhantomAudio",
			"PhantomAudio",
		]
	)


func test_purchase_log_returns_a_copy_not_a_live_reference() -> void:
	var deck: Array[DeckEntry] = [DeckEntry.new("SubtitleDrift", 1, 1, [])]
	var director := DistortionDirector.new(1)
	director.budget = 1000
	director.purchase_one(deck, {}, 0)

	var log_copy: Array = director.purchase_log()
	log_copy.clear()
	assert_eq(director.purchase_log().size(), 1)


## §4.4.5's alcohol clause: seed=0's first draw (3413504692, test_prng.gd's
## own pinned vector) is even, so `% 2` selects index 0 among the two
## tier-1 entries (indices 0 and 2 in this 3-entry deck) — the first one,
## "SubtitleDrift". No budget is spent: authorize_free_tier() never earns
## anything, it authorizes for free.
func test_authorize_free_tier_picks_uniformly_among_the_requested_tier() -> void:
	var deck: Array[DeckEntry] = [
		DeckEntry.new("SubtitleDrift", 1, 5, []),
		DeckEntry.new("AudioSwap", 2, 5, []),
		DeckEntry.new("PhantomAudio", 1, 5, []),
	]
	var director := DistortionDirector.new(0)
	director.budget = 0
	var record: Dictionary = director.authorize_free_tier(deck, 1, 42)

	assert_eq(record["op_class"], "SubtitleDrift")
	assert_eq(record["tier"], 1)
	assert_eq(record["cost"], 0)
	assert_true(record["authorized"])
	assert_eq(director.budget, 0)
	assert_eq(director.active_op_count(), 1)
	assert_eq(deck[record["deck_index"]].op_class, "SubtitleDrift")


func test_authorize_free_tier_respects_the_global_density_cap() -> void:
	var deck: Array[DeckEntry] = [
		DeckEntry.new("SubtitleDrift", 1, 0, []),
		DeckEntry.new("AudioSwap", 1, 0, []),
		DeckEntry.new("PhantomAudio", 1, 0, []),
	]
	var director := DistortionDirector.new(0)
	for i: int in range(DistortionDirector.MAX_CONCURRENT_OPS):
		var record: Dictionary = director.authorize_free_tier(deck, 1, i)
		assert_false(record.is_empty())
	assert_eq(director.active_op_count(), DistortionDirector.MAX_CONCURRENT_OPS)

	var blocked: Dictionary = director.authorize_free_tier(deck, 1, 999)
	assert_true(blocked.is_empty())


func test_authorize_free_tier_returns_empty_when_no_entry_matches_the_tier() -> void:
	var deck: Array[DeckEntry] = [DeckEntry.new("AudioSwap", 2, 5, [])]
	var director := DistortionDirector.new(0)
	var record: Dictionary = director.authorize_free_tier(deck, 1, 0)
	assert_true(record.is_empty())
	assert_eq(director.active_op_count(), 0)
