extends AfterimageTestCase


func _perception(
	can_see: bool = false,
	has_last_known: bool = false,
	heard_noise: bool = false,
	just_spotted: bool = false,
	threat: int = 0
) -> AiUtility.Perception:
	var p := AiUtility.Perception.new()
	p.can_see_target = can_see
	p.has_last_known_position = has_last_known
	p.heard_noise = heard_noise
	p.just_spotted = just_spotted
	p.threat_level = threat
	return p


func test_default_perception_resolves_to_patrol() -> void:
	assert_eq(AiUtility.best_state(_perception()), AiUtility.State.PATROL)


func test_seeing_target_resolves_to_engage() -> void:
	assert_eq(AiUtility.best_state(_perception(true)), AiUtility.State.ENGAGE)


func test_heard_noise_without_sight_resolves_to_investigate() -> void:
	assert_eq(AiUtility.best_state(_perception(false, false, true)), AiUtility.State.INVESTIGATE)


func test_last_known_position_without_sight_resolves_to_investigate() -> void:
	assert_eq(AiUtility.best_state(_perception(false, true)), AiUtility.State.INVESTIGATE)


func test_engage_wins_over_investigate_when_both_apply() -> void:
	# heard_noise AND can_see_target both true: ENGAGE (100) must beat
	# INVESTIGATE, and score_investigate itself returns 0 once a sighting
	# is already resolved (no point investigating what you can see).
	var p := _perception(true, false, true)
	assert_eq(AiUtility.score_investigate(p), 0)
	assert_eq(AiUtility.best_state(p), AiUtility.State.ENGAGE)


func test_just_spotted_resolves_to_report() -> void:
	assert_eq(AiUtility.best_state(_perception(true, false, false, true)), AiUtility.State.REPORT)


func test_high_threat_resolves_to_flee() -> void:
	assert_eq(
		AiUtility.best_state(_perception(false, false, false, false, 100)), AiUtility.State.FLEE
	)


func test_zero_threat_never_triggers_flee() -> void:
	assert_ne(
		AiUtility.best_state(_perception(false, false, false, false, 0)), AiUtility.State.FLEE
	)


func test_score_flee_clamps_out_of_range_threat() -> void:
	assert_eq(AiUtility.score_flee(_perception(false, false, false, false, 500)), 100)
	assert_eq(AiUtility.score_flee(_perception(false, false, false, false, -50)), 0)


func test_just_spotted_outranks_engage_on_the_spotting_tick() -> void:
	# Both can_see_target and just_spotted true (the real tick an AiAgent
	# newly acquires sight): REPORT must win over ENGAGE, so the "call it
	# in" reaction actually happens instead of being silently dominated by
	# engage's own high score.
	var p := _perception(true, false, false, true)
	assert_gt(AiUtility.score_report(p), AiUtility.score_engage(p))
	assert_eq(AiUtility.best_state(p), AiUtility.State.REPORT)


func test_flee_beats_investigate_on_tie_per_priority_order() -> void:
	# heard_noise (no sight) -> INVESTIGATE scores 60; threat_level=60 ->
	# FLEE also 60. _PRIORITY_ORDER lists FLEE before INVESTIGATE, so
	# FLEE must win the tie.
	var p := _perception(false, false, true, false, 60)
	assert_eq(AiUtility.score_investigate(p), 60)
	assert_eq(AiUtility.score_flee(p), 60)
	assert_eq(AiUtility.best_state(p), AiUtility.State.FLEE)


func test_score_for_matches_each_dedicated_scorer() -> void:
	var p := _perception(true, true, true, true, 42)
	assert_eq(AiUtility.score_for(AiUtility.State.PATROL, p), AiUtility.score_patrol(p))
	assert_eq(AiUtility.score_for(AiUtility.State.INVESTIGATE, p), AiUtility.score_investigate(p))
	assert_eq(AiUtility.score_for(AiUtility.State.ENGAGE, p), AiUtility.score_engage(p))
	assert_eq(AiUtility.score_for(AiUtility.State.FLEE, p), AiUtility.score_flee(p))
	assert_eq(AiUtility.score_for(AiUtility.State.REPORT, p), AiUtility.score_report(p))
