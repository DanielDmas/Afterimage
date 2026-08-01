extends AfterimageTestCase


func _make_package(deck: Array[DeckEntry], weights_fx: Dictionary = {}) -> MissionPackage:
	return MissionPackage.new(
		"mission.test_fixture", DistortionDirector.SceneType.COMBAT, weights_fx, 3, deck
	)


func test_constructor_grants_budget_once_from_the_given_mind_state() -> void:
	var deck: Array[DeckEntry] = [DeckEntry.new("SubtitleDrift", 1, 5, ["acute_stress"])]
	var weights_fx: Dictionary = {"acute_stress": FixedMath.from_float(1.0)}
	var mind := MindModel.new()
	mind.acute_stress.gain_entering_combat()
	var runtime := MissionRuntime.new(_make_package(deck, weights_fx), 1, mind)

	var expected: int = (
		DistortionDirector
		. compute_budget(
			DistortionDirector.SceneType.COMBAT,
			{
				"acute_stress": mind.acute_stress.value_fx(),
				"fatigue": mind.fatigue.value_fx(),
				"moral_injury": mind.moral_injury.value_fx(),
				"identity_strain": mind.identity_strain.value_fx(),
			},
			weights_fx
		)
	)
	assert_eq(runtime.director.budget, expected)


func test_rising_acute_stress_increases_granted_budget() -> void:
	var deck: Array[DeckEntry] = [DeckEntry.new("SubtitleDrift", 1, 5, ["acute_stress"])]
	var weights_fx: Dictionary = {"acute_stress": FixedMath.from_float(1.0)}

	var calm_runtime := MissionRuntime.new(_make_package(deck, weights_fx), 1, MindModel.new())

	var stressed_mind := MindModel.new()
	stressed_mind.acute_stress.gain_near_discovery()
	var stressed_runtime := MissionRuntime.new(_make_package(deck, weights_fx), 1, stressed_mind)

	assert_gt(stressed_runtime.director.budget, calm_runtime.director.budget)


func test_grant_scene_budget_adds_another_scenes_worth_on_top() -> void:
	var deck: Array[DeckEntry] = [DeckEntry.new("SubtitleDrift", 1, 5, [])]
	var runtime := MissionRuntime.new(_make_package(deck), 1, MindModel.new())
	var after_construction: int = runtime.director.budget

	runtime.grant_scene_budget()
	assert_eq(runtime.director.budget, after_construction * 2)


func test_defaults_to_a_fresh_mind_model_when_none_is_given() -> void:
	var deck: Array[DeckEntry] = [DeckEntry.new("SubtitleDrift", 1, 5, [])]
	var runtime := MissionRuntime.new(_make_package(deck), 1)
	assert_eq(runtime.mind.acute_stress.value_fx(), 0)


func test_step_purchases_from_the_deck_and_activates_a_real_op() -> void:
	var deck: Array[DeckEntry] = [
		DeckEntry.new("SubtitleDrift", 1, 5, [], {"drifted_text": "wrong"})
	]
	var runtime := MissionRuntime.new(_make_package(deck), 1, MindModel.new())
	runtime.director.budget = 1000

	var purchased: bool = false
	for tick: int in range(1, 20):
		runtime.step(tick, false)
		if not runtime.active_ops.is_empty():
			purchased = true
			break

	assert_true(purchased)
	assert_true(runtime.active_ops[0] is SubtitleDrift)
	assert_eq((runtime.active_ops[0] as SubtitleDrift).drifted_text, "wrong")


func test_step_resolves_active_ops_on_ground_completion() -> void:
	var deck: Array[DeckEntry] = [DeckEntry.new("SubtitleDrift", 1, 5, [], {"drifted_text": "x"})]
	var runtime := MissionRuntime.new(_make_package(deck), 1, MindModel.new())
	runtime.director.budget = 1000

	for tick: int in range(1, 20):
		runtime.step(tick, false)
		if not runtime.active_ops.is_empty():
			break
	assert_false(runtime.active_ops.is_empty())
	assert_eq(runtime.director.active_op_count(), 1)

	runtime.step(999, true)
	assert_true(runtime.active_ops.is_empty())
	assert_eq(runtime.director.active_op_count(), 0)


func test_same_seed_and_mind_state_purchases_identically() -> void:
	var deck: Array[DeckEntry] = [
		DeckEntry.new("SubtitleDrift", 1, 5, [], {"drifted_text": "a"}),
		DeckEntry.new("AudioSwap", 1, 5, [], {"target_source_id": 1, "swapped_tag": "b"}),
	]
	var runtime_a := MissionRuntime.new(_make_package(deck), 7, MindModel.new())
	var runtime_b := MissionRuntime.new(_make_package(deck), 7, MindModel.new())
	runtime_a.director.budget = 1000
	runtime_b.director.budget = 1000

	for tick: int in range(1, 30):
		runtime_a.step(tick, false)
		runtime_b.step(tick, false)

	assert_eq(runtime_a.director.purchase_log(), runtime_b.director.purchase_log())


## The real content pipeline, end to end: a genuine MissionPackage loaded
## from the committed mission.json, purchasing and instantiating a real
## op through the exact same MissionRuntime.step() a live scene will call.
func test_real_stub_mission_purchases_a_real_op() -> void:
	var package: MissionPackage = MissionLoader.load_from_file(
		"res://content/missions/m00_stub/mission.json"
	)
	var runtime := MissionRuntime.new(package, 3, MindModel.new())
	runtime.director.budget = 1000

	for tick: int in range(1, 60):
		runtime.step(tick, false)
		if not runtime.active_ops.is_empty():
			break

	assert_false(runtime.active_ops.is_empty())
	var op: DistortionOp = runtime.active_ops[0]
	assert_true(FairnessAuditor.KNOWN_OP_CLASSES.has(op.op_class))
