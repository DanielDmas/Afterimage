extends AfterimageTestCase


func test_metadata_matches_master_plan_table() -> void:
	var op := EntityMask.new(9)
	assert_eq(op.op_class, "EntityMask")
	assert_eq(op.tier, 3)
	assert_eq(op.cost, 25)
	assert_true(op.fairness_tags.has("charter_rule_2_never_masks_damage_capable_entities"))
	assert_true(op.fairness_tags.has("charter_rule_3_inputs_never_distorted"))
	assert_true(op.fairness_tags.has("charter_rule_5_always_disclosable"))


## The load-bearing structural guarantee (Charter rule 2): a real
## TruthSim actor snapshot never carries "is_damage_capable" at all today
## (no witness/evidence archetype exists yet), so .get(..., true) defaults
## closed and this op must refuse to mask it.
func test_apply_refuses_to_mask_an_actor_with_no_is_damage_capable_field() -> void:
	var op := EntityMask.new(9)
	var truth: Dictionary = {"tick": 1, "actors": [{"id": 9, "position": Vector2i(0, 0)}]}
	var percept: Dictionary = op.apply(truth)
	assert_eq((percept["actors"] as Array).size(), 1)


func test_apply_refuses_to_mask_an_actor_explicitly_marked_damage_capable() -> void:
	var op := EntityMask.new(9)
	var truth: Dictionary = {
		"tick": 1, "actors": [{"id": 9, "position": Vector2i(0, 0), "is_damage_capable": true}]
	}
	var percept: Dictionary = op.apply(truth)
	assert_eq((percept["actors"] as Array).size(), 1)


func test_apply_masks_an_actor_explicitly_marked_not_damage_capable() -> void:
	var op := EntityMask.new(9)
	var truth: Dictionary = {
		"tick": 1, "actors": [{"id": 9, "position": Vector2i(0, 0), "is_damage_capable": false}]
	}
	var percept: Dictionary = op.apply(truth)
	assert_eq((percept["actors"] as Array).size(), 0)


func test_apply_only_masks_the_targeted_actor() -> void:
	var op := EntityMask.new(9)
	var truth: Dictionary = {
		"tick": 1,
		"actors":
		[
			{"id": 9, "position": Vector2i(0, 0), "is_damage_capable": false},
			{"id": 1, "position": Vector2i(100, 100), "is_damage_capable": false},
		],
	}
	var percept: Dictionary = op.apply(truth)
	var remaining: Array = percept["actors"]
	assert_eq(remaining.size(), 1)
	assert_eq(int(remaining[0]["id"]), 1)


## "Unmasked entity fades in": the entity was never removed from truth,
## only hidden from percept, so resolve_grounded() just stops hiding it —
## the (already-real) actor reappears because it was never really gone.
func test_resolve_grounded_returns_the_snapshot_unchanged() -> void:
	var op := EntityMask.new(9)
	var truth: Dictionary = {
		"tick": 1, "actors": [{"id": 9, "position": Vector2i(0, 0), "is_damage_capable": false}]
	}
	assert_eq(op.resolve_grounded(truth), truth)


func test_apply_does_not_mutate_the_input_snapshot() -> void:
	var op := EntityMask.new(9)
	var truth: Dictionary = {
		"tick": 1, "actors": [{"id": 9, "position": Vector2i(0, 0), "is_damage_capable": false}]
	}
	op.apply(truth)
	assert_eq((truth["actors"] as Array).size(), 1)
