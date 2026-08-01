extends AfterimageTestCase


func test_constructor_defaults() -> void:
	var vrba := NPC.new("npc.vrba")
	assert_eq(vrba.id, "npc.vrba")
	assert_eq(vrba.knows.size(), 0)
	assert_eq(vrba.trust, 0)
	assert_eq(vrba.relationship_tier, 0)
	assert_eq(vrba.state, NPC.State.NEUTRAL)


func test_constructor_assigns_all_fields() -> void:
	var personality: Dictionary = {"pride": 7, "fear": 3, "greed": 5}
	var loyalty: Array[String] = ["faction.argus"]
	var knows: Array[String] = ["claim.a", "claim.b"]
	var hides: Array[Dictionary] = [
		{"claim_id": "claim.c", "unlock": {"op": "flag", "args": {"name": "x"}}}
	]
	var lies: Array[Dictionary] = [
		{"claim_id": "claim.d", "tell": {"op": "flag", "args": {"name": "y"}}}
	]
	var edges: Array[Dictionary] = [{"npc_id": "npc.doubek", "delay_days": 2, "distortion": true}]

	var sova := NPC.new(
		"npc.sova", personality, loyalty, knows, hides, lies, edges, 40, 3, NPC.State.ALLY
	)
	assert_eq(sova.personality, personality)
	assert_eq(sova.loyalty_targets, loyalty)
	assert_eq(sova.knows, knows)
	assert_eq(sova.hides, hides)
	assert_eq(sova.lies, lies)
	assert_eq(sova.gossip_edges, edges)
	assert_eq(sova.trust, 40)
	assert_eq(sova.relationship_tier, 3)
	assert_eq(sova.state, NPC.State.ALLY)


func test_knows_claim_reflects_the_knows_array() -> void:
	var knows: Array[String] = ["claim.a"]
	var vrba := NPC.new("npc.vrba", {}, [], knows)
	assert_true(vrba.knows_claim("claim.a"))
	assert_false(vrba.knows_claim("claim.nonexistent"))
