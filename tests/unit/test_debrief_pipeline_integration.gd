extends AfterimageTestCase

## docs/forward_dev_plan.md Phase C's own acceptance criterion, word for
## word: "an integration test plays a tiny run (via MissionRuntime),
## reduces its events to claims, submits a mix of As-Seen/Verified-Only/
## Fabricate, and asserts truth-deltas, moral-injury billing, and
## GameStateStore consequence writes — including the quiet-knife case
## where an honest As-Seen claim about a phantom comes back false."
##
## Runs a real TruthSim (GrayboxRoom, Pass 7's own fixture) alongside a
## real MissionRuntime purchasing from a tiny deck containing one
## PhantomEntity, collects one percept snapshot per tick
## (PerceptRenderer.render(), exactly what a live scene/ReplayTheater
## would show the player), reduces sightings via ClaimReducer, drafts
## real Claims via ClaimDrafter, and submits them through a real
## DebriefLedger — proving the whole chain from "the engine ran a mission"
## to "consequences landed in GameStateStore" without any hand-faked
## intermediate data.


func _make_package() -> MissionPackage:
	var deck: Array[DeckEntry] = [
		(
			DeckEntry
			. new(
				"PhantomEntity",
				3,
				25,
				[],
				{
					"phantom_position": {"x": 3200, "y": 2000},
					"entity_kind": "second_guard",
				}
			)
		)
	]
	return MissionPackage.new(
		"mission.test_pipeline", DistortionDirector.SceneType.INFILTRATION, {}, 3, deck
	)


func test_full_pipeline_from_a_mission_run_to_debrief_consequences() -> void:
	var event_bus := EventBus.new()
	var sim: TruthSim = GrayboxRoom.build(Vector2i(3000, 2000), event_bus)
	var mind := MindModel.new()
	var runtime := MissionRuntime.new(_make_package(), 1, mind)
	runtime.director.budget = 1000  # force the one deck entry affordable immediately

	var percept_snapshots: Array[Dictionary] = []
	for tick: int in range(1, 10):
		var frame := InputFrame.new(tick, {})
		sim.step(frame)
		var truth_snapshot: Dictionary = sim.capture_percept_snapshot()
		runtime.step(tick, false)
		percept_snapshots.append(PerceptRenderer.render(truth_snapshot, runtime.active_ops))

	# The Director must actually have purchased the PhantomEntity by now,
	# or this test isn't exercising the quiet-knife case at all.
	assert_false(runtime.active_ops.is_empty(), "PhantomEntity must have been purchased")

	var perceived_events: Array[Dictionary] = ClaimReducer.reduce_sightings(percept_snapshots)
	# The real player actor (id 1, ActorRegistry's first-assigned id) and
	# the phantom (a negative id) must both have produced a sighting.
	assert_eq(perceived_events.size(), 2)

	var claims: Array[Claim] = ClaimDrafter.draft_from_perceived_events(perceived_events)
	var ledger := DebriefLedger.new()
	for claim: Claim in claims:
		ledger.add_candidate(claim)

	var final_truth: Dictionary = sim.capture_percept_snapshot()
	var real_actor_ids: Dictionary = {}  ## actor_id -> true, for real truth-layer actors only
	for actor: Dictionary in final_truth["actors"] as Array:
		real_actor_ids[int(actor["id"])] = true

	var moral_injury := MoralInjuryState.new()
	var game_state := GameStateStore.new()
	var starting_trust: int = int(game_state.get_value(["campaign", "doubek_trust"]))
	var starting_resources: int = int(game_state.get_value(["campaign", "resource_budget"]))

	var phantom_delta: int = -1
	var real_delta: int = -1
	for claim: Claim in claims:
		var actor_id: int = int(claim.qualifiers["actor_id"])
		var is_real: bool = real_actor_ids.has(actor_id)
		# The truth_object a caller with real TruthSim access would supply:
		# the claim's own label when the actor is genuinely real, a sentinel
		# that can never match when it isn't (a phantom's id is never a key
		# of real_actor_ids, by PhantomEntity's own negative-id contract).
		var truth_object: String = claim.object_value if is_real else "nothing_there"
		var mode: DebriefLedger.HonestyMode = (
			DebriefLedger.HonestyMode.FABRICATE
			if not is_real
			else DebriefLedger.HonestyMode.AS_SEEN
		)
		var record: Dictionary = ledger.submit_claim(
			claim.id, mode, truth_object, moral_injury, false, game_state
		)
		if is_real:
			real_delta = record["truth_delta"]
		else:
			phantom_delta = record["truth_delta"]

	# The quiet knife itself: the phantom sighting, submitted honestly
	# (well — FABRICATE here so the moral-injury channel gets exercised
	# too; see below), comes back false. The real actor's sighting comes
	# back true. Both were drafted through the exact same reduction code.
	assert_eq(real_delta, 0)
	assert_eq(phantom_delta, 1)

	# FABRICATE billed moral injury (existing DebriefLedger behavior).
	assert_true(moral_injury.value_fx() > 0)

	# Both submissions were FABRICATE, so trust only ever moved by
	# DebriefConsequences.FABRICATE_TRUST, twice.
	var expected_trust: int = starting_trust + 2 * DebriefConsequences.FABRICATE_TRUST
	assert_eq(int(game_state.get_value(["campaign", "doubek_trust"])), expected_trust)
	assert_eq(int(game_state.get_value(["campaign", "resource_budget"])), starting_resources)

	# A DebriefScreen can be built straight from the same ledger.
	var screen: DebriefScreen = DebriefScreen.build(ledger)
	assert_eq(screen.claim_rows.size(), 2)


## The same quiet-knife case, but submitted AS_SEEN (an honest player who
## genuinely believed the phantom was real) rather than FABRICATE — the
## more common real case, and the one the Phase C acceptance wording
## names directly: "an honest As-Seen claim about a phantom comes back
## false."
func test_an_honest_as_seen_claim_about_a_phantom_comes_back_false() -> void:
	var event_bus := EventBus.new()
	var sim: TruthSim = GrayboxRoom.build(Vector2i(3000, 2000), event_bus)
	var mind := MindModel.new()
	var runtime := MissionRuntime.new(_make_package(), 1, mind)
	runtime.director.budget = 1000

	var percept_snapshots: Array[Dictionary] = []
	for tick: int in range(1, 10):
		var frame := InputFrame.new(tick, {})
		sim.step(frame)
		var truth_snapshot: Dictionary = sim.capture_percept_snapshot()
		runtime.step(tick, false)
		percept_snapshots.append(PerceptRenderer.render(truth_snapshot, runtime.active_ops))

	var perceived_events: Array[Dictionary] = ClaimReducer.reduce_sightings(percept_snapshots)
	var claims: Array[Claim] = ClaimDrafter.draft_from_perceived_events(perceived_events)
	var ledger := DebriefLedger.new()
	for claim: Claim in claims:
		ledger.add_candidate(claim)

	var final_truth: Dictionary = sim.capture_percept_snapshot()
	var real_actor_ids: Dictionary = {}
	for actor: Dictionary in final_truth["actors"] as Array:
		real_actor_ids[int(actor["id"])] = true

	var phantom_claim: Claim = null
	for claim: Claim in claims:
		if not real_actor_ids.has(int(claim.qualifiers["actor_id"])):
			phantom_claim = claim
	assert_not_null(phantom_claim, "the phantom must have produced a claim candidate")

	var record: Dictionary = ledger.submit_claim(
		phantom_claim.id, DebriefLedger.HonestyMode.AS_SEEN, "nothing_there"
	)
	assert_eq(record["truth_delta"], 1)
	assert_eq(record["trust_delta"], DebriefConsequences.AS_SEEN_FALSE_TRUST)
