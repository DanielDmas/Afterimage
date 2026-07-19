extends AfterimageTestCase


## As in test_truth_sim.gd/test_truth_sim_combat.gd: event payloads are
## captured via a bound-method Callable on a helper class, not a lambda
## mutating a captured local.
class _EventLogger:
	var events: Array = []

	func handle(event: Dictionary) -> void:
		events.append(event)


func _build_graph_with_edges(edges: Array[Dictionary]) -> SuspicionGraph:
	var graph := SuspicionGraph.new()
	graph.add_npc(NPC.new("npc.source", {}, [], [], [], [], edges))
	graph.add_npc(NPC.new("npc.target_a"))
	graph.add_npc(NPC.new("npc.target_b"))
	return graph


func test_propagate_with_no_distortion_keeps_type_and_weight_unchanged() -> void:
	var edges: Array[Dictionary] = [
		{"npc_id": "npc.target_a", "delay_days": 2, "distortion": false}
	]
	var graph := _build_graph_with_edges(edges)
	var sim := GossipSim.new(1)

	sim.propagate(graph, "npc.source", "seen_grounding", 5, 10)

	assert_eq(graph.ledger("npc.target_a").entries()[0]["type"], "seen_grounding")
	assert_eq(graph.ledger("npc.target_a").entries()[0]["weight"], 5)
	assert_eq(graph.ledger("npc.target_a").entries()[0]["day_added"], 12)  # 10 + 2


func test_propagate_with_distortion_blurs_the_type_and_offsets_the_weight() -> void:
	## Hand-verified against test_prng.gd's pinned seed=1 next_u32() vector:
	## first draw % 3 = 1 -> delta 0 (weight unchanged, 5); second draw % 3
	## = 0 -> delta -1 (weight 4). Two distorted edges in one propagate()
	## call consume exactly these two draws in order.
	var edges: Array[Dictionary] = [
		{"npc_id": "npc.target_a", "delay_days": 2, "distortion": true},
		{"npc_id": "npc.target_b", "delay_days": 3, "distortion": true},
	]
	var graph := _build_graph_with_edges(edges)
	var sim := GossipSim.new(1)

	sim.propagate(graph, "npc.source", "seen_grounding", 5, 10)

	var entry_a: Dictionary = graph.ledger("npc.target_a").entries()[0]
	assert_eq(entry_a["type"], "gossip_of:seen_grounding")
	assert_eq(entry_a["weight"], 5)
	assert_eq(entry_a["day_added"], 12)

	var entry_b: Dictionary = graph.ledger("npc.target_b").entries()[0]
	assert_eq(entry_b["type"], "gossip_of:seen_grounding")
	assert_eq(entry_b["weight"], 4)
	assert_eq(entry_b["day_added"], 13)


func test_propagate_skips_edges_to_npcs_not_in_the_graph() -> void:
	var edges: Array[Dictionary] = [
		{"npc_id": "npc.unregistered", "delay_days": 1, "distortion": false}
	]
	var graph := SuspicionGraph.new()
	graph.add_npc(NPC.new("npc.source", {}, [], [], [], [], edges))
	var sim := GossipSim.new(1)

	# Must not error even though the edge targets an NPC never added.
	sim.propagate(graph, "npc.source", "seen_grounding", 5, 10)
	assert_false(graph.has_npc("npc.unregistered"))


func test_propagate_publishes_one_event_per_target() -> void:
	var edges: Array[Dictionary] = [
		{"npc_id": "npc.target_a", "delay_days": 2, "distortion": false}
	]
	var graph := _build_graph_with_edges(edges)
	var sim := GossipSim.new(1)
	var bus := EventBus.new()
	var logger := _EventLogger.new()
	bus.subscribe(GossipSim.EVENT_SUSPICION_ENTRY_ADDED, Callable(logger, "handle"))

	sim.propagate(graph, "npc.source", "seen_grounding", 5, 10, bus)

	assert_eq(logger.events.size(), 1)
	var payload: Dictionary = logger.events[0]["payload"]
	assert_eq(payload["npc_id"], "npc.target_a")
	assert_eq(payload["source_npc_id"], "npc.source")
	assert_eq(logger.events[0]["tick"], 12)  # arrival day, in the tick|day slot


func test_propagate_with_no_event_bus_does_not_error() -> void:
	var edges: Array[Dictionary] = [
		{"npc_id": "npc.target_a", "delay_days": 1, "distortion": false}
	]
	var graph := _build_graph_with_edges(edges)
	var sim := GossipSim.new(1)
	sim.propagate(graph, "npc.source", "seen_grounding", 5, 10)
	assert_eq(graph.ledger("npc.target_a").entries().size(), 1)
