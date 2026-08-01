extends AfterimageTestCase


func test_add_npc_registers_the_npc_and_a_fresh_ledger() -> void:
	var graph := SuspicionGraph.new()
	graph.add_npc(NPC.new("npc.vrba"))
	assert_true(graph.has_npc("npc.vrba"))
	assert_eq(graph.npc("npc.vrba").id, "npc.vrba")
	assert_eq(graph.total_for("npc.vrba", 0), 0)


func test_has_npc_is_false_for_unregistered_npc() -> void:
	var graph := SuspicionGraph.new()
	assert_false(graph.has_npc("npc.nonexistent"))


func test_add_entry_and_total_for_delegate_to_the_right_ledger() -> void:
	var graph := SuspicionGraph.new()
	graph.add_npc(NPC.new("npc.vrba"))
	graph.add_npc(NPC.new("npc.rohanova"))
	graph.add_entry("npc.vrba", "seen_grounding", SuspicionLedger.WEIGHT_SEEN_GROUNDING, 0)
	assert_eq(graph.total_for("npc.vrba", 0), 2)
	assert_eq(graph.total_for("npc.rohanova", 0), 0)  # unaffected


func test_level_for_total_thresholds() -> void:
	assert_eq(SuspicionGraph.level_for_total(0), SuspicionGraph.Level.CALM)
	assert_eq(SuspicionGraph.level_for_total(24), SuspicionGraph.Level.CALM)
	assert_eq(SuspicionGraph.level_for_total(25), SuspicionGraph.Level.WARY)
	assert_eq(SuspicionGraph.level_for_total(49), SuspicionGraph.Level.WARY)
	assert_eq(SuspicionGraph.level_for_total(50), SuspicionGraph.Level.ACTIVE)
	assert_eq(SuspicionGraph.level_for_total(74), SuspicionGraph.Level.ACTIVE)
	assert_eq(SuspicionGraph.level_for_total(75), SuspicionGraph.Level.CONVINCED)
	assert_eq(SuspicionGraph.level_for_total(100), SuspicionGraph.Level.CONVINCED)


func test_level_for_reads_the_correct_npcs_decayed_total() -> void:
	var graph := SuspicionGraph.new()
	graph.add_npc(NPC.new("npc.vrba"))
	graph.add_entry(
		"npc.vrba", "implausible_survival", SuspicionLedger.WEIGHT_IMPLAUSIBLE_SURVIVAL, 0
	)
	graph.add_entry(
		"npc.vrba",
		"cover_inconsistent_equipment",
		SuspicionLedger.WEIGHT_COVER_INCONSISTENT_EQUIPMENT,
		0
	)
	# 6 + 5 = 11, still CALM
	assert_eq(graph.level_for("npc.vrba", 0), SuspicionGraph.Level.CALM)

	graph.add_entry(
		"npc.vrba",
		"interrupt_memory_inconsistency",
		SuspicionLedger.WEIGHT_INTERRUPT_MEMORY_INCONSISTENCY_MAX,
		0
	)
	# 6 + 5 + 6 = 17, still CALM
	assert_eq(graph.level_for("npc.vrba", 0), SuspicionGraph.Level.CALM)

	graph.add_entry(
		"npc.vrba", "police_pattern_behavior", SuspicionLedger.WEIGHT_POLICE_PATTERN_BEHAVIOR, 0
	)
	# 6 + 5 + 6 + 4 = 21, still CALM
	assert_eq(graph.level_for("npc.vrba", 0), SuspicionGraph.Level.CALM)

	graph.add_entry("npc.vrba", "seen_grounding", SuspicionLedger.WEIGHT_SEEN_GROUNDING, 0)
	graph.add_entry("npc.vrba", "seen_grounding", SuspicionLedger.WEIGHT_SEEN_GROUNDING, 0)
	# 21 + 2 + 2 = 25 -> WARY
	assert_eq(graph.total_for("npc.vrba", 0), 25)
	assert_eq(graph.level_for("npc.vrba", 0), SuspicionGraph.Level.WARY)
