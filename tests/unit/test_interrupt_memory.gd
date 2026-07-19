extends AfterimageTestCase


func test_no_contradiction_when_only_one_statement_recorded() -> void:
	var memory := InterruptMemory.new()
	memory.record_statement("npc.sova", "location", "archive_floor", "npc.sova")
	assert_false(memory.has_contradiction())


func test_matching_statements_do_not_contradict() -> void:
	var memory := InterruptMemory.new()
	memory.record_statement("npc.sova", "location", "archive_floor", "npc.sova")
	memory.record_statement("npc.sova", "location", "archive_floor", "player")
	assert_false(memory.has_contradiction())


func test_different_subject_or_predicate_does_not_contradict() -> void:
	var memory := InterruptMemory.new()
	memory.record_statement("npc.sova", "location", "archive_floor", "npc.sova")
	memory.record_statement("npc.vrba", "location", "safehouse", "npc.vrba")  # different subject
	memory.record_statement("npc.sova", "mood", "anxious", "player")  # different predicate
	assert_false(memory.has_contradiction())


## The AC's "fires both directions": an NPC statement contradicted later
## by the player is caught.
func test_contradiction_fires_when_npc_statement_is_later_contradicted_by_player() -> void:
	var memory := InterruptMemory.new()
	memory.record_statement("npc.sova", "location", "archive_floor", "npc.sova")
	memory.record_statement("npc.sova", "location", "safehouse", "player")

	assert_true(memory.has_contradiction())
	var contradictions: Array = memory.contradictions()
	assert_eq(contradictions.size(), 1)
	assert_eq(contradictions[0]["existing"]["source"], "npc.sova")
	assert_eq(contradictions[0]["new"]["source"], "player")


## The other direction: a player statement contradicted later by an NPC.
func test_contradiction_fires_when_player_statement_is_later_contradicted_by_npc() -> void:
	var memory := InterruptMemory.new()
	memory.record_statement("player", "heard_sound", "heating_pipes", "player")
	memory.record_statement("player", "heard_sound", "footsteps", "npc.sova")

	assert_true(memory.has_contradiction())
	var contradictions: Array = memory.contradictions()
	assert_eq(contradictions[0]["existing"]["source"], "player")
	assert_eq(contradictions[0]["new"]["source"], "npc.sova")


func test_statements_returns_a_copy_not_a_live_reference() -> void:
	var memory := InterruptMemory.new()
	memory.record_statement("player", "heard_sound", "heating_pipes", "player")
	var statements_copy: Array = memory.statements()
	statements_copy.clear()
	assert_eq(memory.statements().size(), 1)


func test_contradictions_returns_a_copy_not_a_live_reference() -> void:
	var memory := InterruptMemory.new()
	memory.record_statement("player", "heard_sound", "heating_pipes", "player")
	memory.record_statement("player", "heard_sound", "footsteps", "npc.sova")
	var contradictions_copy: Array = memory.contradictions()
	contradictions_copy.clear()
	assert_eq(memory.contradictions().size(), 1)
