extends AfterimageTestCase

## Proves docs/review_and_forward_plan.md's F5 is actually closed: Ground
## observed by a real AI actor, inside a real TruthSim, lands as a real
## SuspicionLedger entry and propagates one real gossip hop — the
## designed pipeline (Ground observed -> suspicion -> gossip) running
## end to end for the first time, not three separately-tested segments
## that never once ran together.


func _make_seeing_scenario() -> Dictionary:
	var event_bus := EventBus.new()
	var sim := TruthSim.new(500, Vector2i(1000, 1000), 250, event_bus)
	# The AI stands 1000mm east of the player, facing west (back toward
	# it) - well inside Sentry's 6000mm range/50 degree half-angle, with
	# an empty grid so line-of-sight is trivially clear.
	var ai_id: int = sim.spawn_ai(Vector2i(2000, 1000), 250, AiArchetype.sentry(), Vector2i(-1, 0))
	return {"sim": sim, "event_bus": event_bus, "ai_id": ai_id}


func _hold_ground_to_completion(sim: TruthSim) -> void:
	for i: int in range(GroundState.DURATION_TICKS):
		sim.step(InputFrame.new(i + 1, {"ground": true}))


func test_ground_observed_by_a_mapped_actor_lands_a_suspicion_entry() -> void:
	var scenario: Dictionary = _make_seeing_scenario()
	var sim: TruthSim = scenario["sim"]
	var event_bus: EventBus = scenario["event_bus"]
	var ai_id: int = scenario["ai_id"]

	var graph := SuspicionGraph.new()
	graph.add_npc(NPC.new("npc.observer"))
	var gossip := GossipSim.new(1)
	var bridge := GroundObservationBridge.new(graph, gossip, {ai_id: "npc.observer"}, event_bus, 10)

	_hold_ground_to_completion(sim)

	assert_eq(graph.total_for("npc.observer", 10), SuspicionLedger.WEIGHT_SEEN_GROUNDING)
	assert_eq(bridge.current_day, 10)


func test_ground_observed_propagates_one_gossip_hop_to_a_confidant() -> void:
	var scenario: Dictionary = _make_seeing_scenario()
	var sim: TruthSim = scenario["sim"]
	var event_bus: EventBus = scenario["event_bus"]
	var ai_id: int = scenario["ai_id"]

	var edges: Array[Dictionary] = [
		{"npc_id": "npc.confidant", "delay_days": 2, "distortion": false}
	]
	var graph := SuspicionGraph.new()
	graph.add_npc(NPC.new("npc.observer", {}, [], [], [], [], edges))
	graph.add_npc(NPC.new("npc.confidant"))
	var gossip := GossipSim.new(1)
	# Kept alive in a local var deliberately - GroundObservationBridge is a
	# RefCounted with no other owner; discarding the constructor's return
	# value here is suspected (pending CI confirmation) to let it be freed
	# before Ground ever completes, silently invalidating its EventBus
	# subscription (EventBus._dispatch_one() checks handler.is_valid()
	# before calling it - a freed handler is skipped, not an error).
	var bridge := GroundObservationBridge.new(graph, gossip, {ai_id: "npc.observer"}, event_bus, 10)

	# Diagnostics (temporary, pending a real CI failure this pass hasn't
	# yet root-caused): confirm the edges actually stored, and that the
	# direct observer-side entry lands in this exact test's setup, before
	# asking anything about the confidant's propagated one.
	assert_eq(graph.npc("npc.observer").gossip_edges.size(), 1, "edges not stored on NPC")
	assert_eq(
		graph.npc("npc.observer").gossip_edges[0]["npc_id"],
		"npc.confidant",
		"wrong edge target stored"
	)

	_hold_ground_to_completion(sim)

	assert_eq(
		graph.total_for("npc.observer", 10),
		SuspicionLedger.WEIGHT_SEEN_GROUNDING,
		"direct observer entry never landed"
	)
	# Arrives 2 days after day 10 - absent before then, present at/after.
	assert_eq(graph.total_for("npc.confidant", 11), 0, "confidant entry arrived too early")
	assert_eq(
		graph.total_for("npc.confidant", 12),
		SuspicionLedger.WEIGHT_SEEN_GROUNDING,
		"confidant entry never arrived"
	)


func test_an_unmapped_observer_is_silently_skipped() -> void:
	var scenario: Dictionary = _make_seeing_scenario()
	var sim: TruthSim = scenario["sim"]
	var event_bus: EventBus = scenario["event_bus"]
	# ai_id deliberately absent from the mapping.

	var graph := SuspicionGraph.new()
	var gossip := GossipSim.new(1)
	var bridge := GroundObservationBridge.new(graph, gossip, {}, event_bus, 0)

	_hold_ground_to_completion(sim)
	# Nothing to assert against (no NPC even exists) - the point is this
	# doesn't error/crash when the observer has no social mapping.
	assert_true(true)


func test_ground_never_observed_leaves_the_graph_untouched() -> void:
	# No AI actor at all - Ground still resolves, but no one is watching.
	var event_bus := EventBus.new()
	var sim := TruthSim.new(500, Vector2i(1000, 1000), 250, event_bus)
	var graph := SuspicionGraph.new()
	graph.add_npc(NPC.new("npc.observer"))
	var gossip := GossipSim.new(1)
	var bridge := GroundObservationBridge.new(graph, gossip, {}, event_bus, 0)

	_hold_ground_to_completion(sim)

	assert_eq(graph.total_for("npc.observer", 0), 0)
