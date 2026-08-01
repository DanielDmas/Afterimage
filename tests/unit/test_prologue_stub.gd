extends AfterimageTestCase

## Pass 20's capstone integration test: the whole playable prologue stub,
## end to end. Each stage is also tested independently below, but this
## file's real job is proving the *pipeline* — Ground verb, dialogue,
## distortion, replay reconstruction, and debrief — actually composes
## into one coherent run, not just that each piece works in isolation
## (every piece already has its own dedicated test suite from Passes
## 8-17).


func test_run_ground_tutorial_completes_the_ground_verb_exactly_once() -> void:
	var stub := PrologueStub.new()
	stub.run_ground_tutorial()
	assert_eq(stub.truth_sim.ground_use_count(), 1)
	assert_false(stub.truth_sim.is_grounding())


func test_play_scripted_misheard_line_distorts_percept_but_never_truth() -> void:
	var stub := PrologueStub.new()
	stub.run_ground_tutorial()
	var dual_view: Dictionary = stub.play_scripted_misheard_line()

	assert_eq(dual_view["truth"]["subtitle"]["true_text"], "Footsteps. Someone was there.")
	assert_eq(dual_view["percept"]["subtitle"]["rendered_text"], "Just the radiator, ticking.")
	assert_false(dual_view["percept"]["subtitle"]["grounded"])
	# the truth snapshot itself is never touched by rendering the percept
	assert_eq(dual_view["truth"]["subtitle"]["true_text"], "Footsteps. Someone was there.")


func test_scripted_line_records_the_players_claim_in_interrupt_memory() -> void:
	var stub := PrologueStub.new()
	stub.run_ground_tutorial()
	stub.play_scripted_misheard_line()

	var statements: Array = stub.interrupt_memory.statements()
	assert_eq(statements.size(), 1)
	assert_eq(statements[0]["subject"], "player")
	assert_eq(statements[0]["predicate"], "heard_sound")
	assert_eq(statements[0]["object"], "footsteps")


func test_mini_theater_reconstructs_the_exact_drift_tick() -> void:
	var stub := PrologueStub.new()
	stub.run_ground_tutorial()
	stub.play_scripted_misheard_line()
	var theater: ReplayTheater = stub.build_mini_theater()

	assert_eq(theater.tick_count(), GroundState.DURATION_TICKS + 1)
	var spans: Array[OpTimelineSpan] = theater.spans_active_at(theater.tick_count())
	assert_eq(spans.size(), 1)
	assert_eq(spans[0].op_class, "SubtitleDrift")

	# The theater's own re-simulation reaches the same truth as the live
	# run - the same correctness proof Pass 14 established, now exercised
	# against a real scripted scenario instead of a synthetic one.
	var reconstructed_truth: Dictionary = theater.truth_view_at(theater.tick_count())
	assert_eq(reconstructed_truth["tick"], theater.tick_count())


func test_debrief_produces_a_false_delta_for_the_honest_but_mistaken_claim() -> void:
	var stub := PrologueStub.new()
	stub.run_ground_tutorial()
	stub.play_scripted_misheard_line()
	var record: Dictionary = stub.draft_and_submit_debrief()

	assert_eq(record["mode"], DebriefLedger.HonestyMode.AS_SEEN)
	# the player told the truth as they believed it, and it was still
	# false - the quiet knife, played out for real.
	assert_eq(record["truth_delta"], 1)
	assert_true(stub.debrief.is_submitted("claim.prologue.heard_sound"))


## The full pipeline, run exactly the way a caller would: construct once,
## call run_full_stub(), and get back everything the (still-unbuilt) real
## UI would eventually bind to.
func test_run_full_stub_ties_every_stage_together() -> void:
	var stub := PrologueStub.new()
	var result: Dictionary = stub.run_full_stub()

	assert_eq(result["ground_use_count"], 1)
	assert_eq(
		result["dual_view"]["percept"]["subtitle"]["rendered_text"], "Just the radiator, ticking."
	)
	assert_eq(result["debrief_record"]["truth_delta"], 1)

	var theater: ReplayTheater = result["theater"]
	assert_eq(theater.tick_count(), GroundState.DURATION_TICKS + 1)
	assert_true(stub.dialogue.is_ended())
