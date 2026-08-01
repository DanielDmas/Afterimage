extends AfterimageTestCase


func test_add_room_and_has_room() -> void:
	var graph := SoundGraph.new()
	assert_false(graph.has_room("hallway"))
	graph.add_room("hallway")
	assert_true(graph.has_room("hallway"))


func test_add_portal_registers_both_rooms() -> void:
	var graph := SoundGraph.new()
	graph.add_portal("hallway", "office", 10)
	assert_true(graph.has_room("hallway"))
	assert_true(graph.has_room("office"))
	assert_eq(graph.room_count(), 2)


func test_propagate_source_room_keeps_full_loudness() -> void:
	var graph := SoundGraph.new()
	graph.add_room("hallway")
	var map: Dictionary = graph.propagate("hallway", 100)
	assert_eq(map["hallway"], 100)


func test_propagate_from_unknown_room_returns_empty() -> void:
	var graph := SoundGraph.new()
	graph.add_room("hallway")
	assert_eq(graph.propagate("nonexistent", 100), {})


func test_propagate_with_zero_or_negative_loudness_returns_empty() -> void:
	var graph := SoundGraph.new()
	graph.add_room("hallway")
	assert_eq(graph.propagate("hallway", 0), {})
	assert_eq(graph.propagate("hallway", -5), {})


func test_single_portal_attenuates_by_its_cost() -> void:
	var graph := SoundGraph.new()
	graph.add_portal("hallway", "office", 30)
	var map: Dictionary = graph.propagate("hallway", 100)
	assert_eq(map["hallway"], 100)
	assert_eq(map["office"], 70)


func test_portal_is_bidirectional() -> void:
	var graph := SoundGraph.new()
	graph.add_portal("hallway", "office", 30)
	var map: Dictionary = graph.propagate("office", 100)
	assert_eq(map["office"], 100)
	assert_eq(map["hallway"], 70)


func test_two_portal_chain_attenuates_cumulatively() -> void:
	var graph := SoundGraph.new()
	graph.add_portal("hallway", "office", 30)
	graph.add_portal("office", "closet", 25)
	var map: Dictionary = graph.propagate("hallway", 100)
	assert_eq(map["hallway"], 100)
	assert_eq(map["office"], 70)
	assert_eq(map["closet"], 45)


func test_fully_attenuated_room_is_omitted_not_zero() -> void:
	var graph := SoundGraph.new()
	graph.add_portal("hallway", "office", 30)
	graph.add_portal("office", "closet", 80)  # 70 - 80 <= 0: never reaches closet
	var map: Dictionary = graph.propagate("hallway", 100)
	assert_true(map.has("office"))
	assert_false(
		map.has("closet"), "a room every path attenuates to <=0 must be absent, not present at 0"
	)


func test_loudest_path_wins_when_multiple_routes_exist() -> void:
	# hallway -> office (cost 10) -> closet (cost 10): arrives at closet with 80.
	# hallway -> closet directly (cost 50): arrives at closet with 50.
	# The loudest arrival (80, via office) must win.
	var graph := SoundGraph.new()
	graph.add_portal("hallway", "office", 10)
	graph.add_portal("office", "closet", 10)
	graph.add_portal("hallway", "closet", 50)
	var map: Dictionary = graph.propagate("hallway", 100)
	assert_eq(map["closet"], 80)


func test_loudness_at_convenience_query() -> void:
	var graph := SoundGraph.new()
	graph.add_portal("hallway", "office", 30)
	assert_eq(graph.loudness_at("hallway", 100, "office"), 70)
	assert_eq(graph.loudness_at("hallway", 100, "nonexistent_room"), 0)


func test_disconnected_room_is_never_reached() -> void:
	var graph := SoundGraph.new()
	graph.add_portal("hallway", "office", 10)
	graph.add_room("isolated_vault")
	var map: Dictionary = graph.propagate("hallway", 100)
	assert_false(map.has("isolated_vault"))
