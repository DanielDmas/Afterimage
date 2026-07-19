extends AfterimageTestCase


func test_metadata_matches_master_plan_table() -> void:
	var op := PhantomEntity.new(Vector2i(0, 0), "dog")
	assert_eq(op.op_class, "PhantomEntity")
	assert_eq(op.tier, 3)
	assert_eq(op.cost, 25)
	assert_true(op.fairness_tags.has("charter_rule_1_never_damages_never_blocks"))


func test_apply_adds_a_phantom_actor_with_a_negative_id() -> void:
	var op := PhantomEntity.new(Vector2i(3000, 4000), "person", Vector2i(0, -1))
	var percept: Dictionary = op.apply({"tick": 1, "actors": []})
	var actors: Array = percept["actors"]
	assert_eq(actors.size(), 1)
	assert_true(
		int(actors[0]["id"]) < 0, "phantom ids must never collide with real (positive) actor ids"
	)
	assert_eq(actors[0]["position"], Vector2i(3000, 4000))
	assert_eq(actors[0]["facing_dir"], Vector2i(0, -1))
	assert_eq(actors[0]["entity_kind"], "person")
	assert_true(actors[0]["is_alive"])
	assert_true(actors[0]["is_phantom"])


func test_apply_coexists_with_real_actors() -> void:
	var op := PhantomEntity.new(Vector2i(0, 0), "car")
	var truth: Dictionary = {"tick": 1, "actors": [{"id": 1, "position": Vector2i(500, 500)}]}
	var percept: Dictionary = op.apply(truth)
	assert_eq((percept["actors"] as Array).size(), 2)


func test_resolve_grounded_removes_exactly_this_instances_phantom() -> void:
	var op_a := PhantomEntity.new(Vector2i(0, 0), "dog")
	var op_b := PhantomEntity.new(Vector2i(0, 0), "car")

	var percept: Dictionary = op_a.apply({"tick": 1, "actors": []})
	percept = op_b.apply(percept)
	assert_eq((percept["actors"] as Array).size(), 2)

	var grounded: Dictionary = op_a.resolve_grounded(percept)
	var remaining: Array = grounded["actors"]
	assert_eq(remaining.size(), 1)
	assert_eq(remaining[0]["entity_kind"], "car")


func test_apply_does_not_mutate_the_input_snapshot() -> void:
	var op := PhantomEntity.new(Vector2i(0, 0), "dog")
	var truth: Dictionary = {"tick": 1, "actors": []}
	op.apply(truth)
	assert_eq((truth["actors"] as Array).size(), 0)
