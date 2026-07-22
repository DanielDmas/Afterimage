extends AfterimageTestCase


func _snapshot_with_actor() -> Dictionary:
	return {"tick": 1, "actors": [{"id": 6, "position": Vector2i(500, 500), "is_alive": true}]}


func test_metadata_matches_master_plan_table() -> void:
	var op := FamiliarFace.new(6, "eliska_ledger:jana_martinu")
	assert_eq(op.op_class, "FamiliarFace")
	assert_eq(op.tier, 2)
	assert_eq(op.cost, 15)
	assert_true(op.fairness_tags.has("charter_rule_3_inputs_never_distorted"))
	assert_true(op.fairness_tags.has("charter_rule_5_always_disclosable"))


func test_apply_renders_the_familiar_face_on_the_targeted_actor() -> void:
	var op := FamiliarFace.new(6, "eliska_ledger:jana_martinu")
	var percept: Dictionary = op.apply(_snapshot_with_actor())
	var actor: Dictionary = (percept["actors"] as Array)[0]
	assert_eq(actor["rendered_face_id"], "eliska_ledger:jana_martinu")
	assert_true(actor["is_face_swapped"])


func test_apply_leaves_non_targeted_actors_untouched() -> void:
	var op := FamiliarFace.new(6, "eliska_ledger:jana_martinu")
	var snapshot: Dictionary = {"tick": 1, "actors": [{"id": 1, "position": Vector2i(0, 0)}]}
	var percept: Dictionary = op.apply(snapshot)
	var actor: Dictionary = (percept["actors"] as Array)[0]
	assert_false(actor.has("rendered_face_id"))


func test_apply_coexists_with_other_real_actors() -> void:
	var op := FamiliarFace.new(6, "eliska_ledger:jana_martinu")
	var truth: Dictionary = {
		"tick": 1,
		"actors":
		[{"id": 1, "position": Vector2i(0, 0)}, {"id": 6, "position": Vector2i(500, 500)}],
	}
	var percept: Dictionary = op.apply(truth)
	assert_eq((percept["actors"] as Array).size(), 2)


func test_resolve_grounded_removes_the_rendered_face_id() -> void:
	var op := FamiliarFace.new(6, "eliska_ledger:jana_martinu")
	var percept: Dictionary = op.apply(_snapshot_with_actor())
	var grounded: Dictionary = op.resolve_grounded(percept)
	var actor: Dictionary = (grounded["actors"] as Array)[0]
	assert_false(actor.has("rendered_face_id"))
	assert_false(actor["is_face_swapped"])


func test_apply_does_not_mutate_the_input_snapshot() -> void:
	var op := FamiliarFace.new(6, "eliska_ledger:jana_martinu")
	var truth: Dictionary = _snapshot_with_actor()
	op.apply(truth)
	var actor: Dictionary = (truth["actors"] as Array)[0]
	assert_false(actor.has("rendered_face_id"))
