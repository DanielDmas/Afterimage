extends AfterimageTestCase

const STUB_MISSION_PATH: String = "res://content/missions/m00_stub/mission.json"


func test_load_from_file_loads_the_real_stub_fixture() -> void:
	var package: MissionPackage = MissionLoader.load_from_file(STUB_MISSION_PATH)
	assert_eq(package.id, "mission.m00_stub")
	assert_eq(package.scene_type, DistortionDirector.SceneType.COMBAT)
	assert_eq(package.encounter_cap, 3)
	assert_eq(package.deck.size(), 4)


func test_load_from_file_converts_mission_weights_to_fixed_point() -> void:
	var package: MissionPackage = MissionLoader.load_from_file(STUB_MISSION_PATH)
	assert_eq(package.mission_weights_fx["acute_stress"], FixedMath.from_float(1.0))
	assert_eq(package.mission_weights_fx["fatigue"], FixedMath.from_float(0.5))
	assert_eq(package.mission_weights_fx["moral_injury"], FixedMath.from_float(1.5))
	assert_eq(package.mission_weights_fx["identity_strain"], FixedMath.from_float(0.2))


func test_load_from_file_deck_entries_match_the_json() -> void:
	var package: MissionPackage = MissionLoader.load_from_file(STUB_MISSION_PATH)
	var first: DeckEntry = package.deck[0]
	assert_eq(first.op_class, "AudioSwap")
	assert_eq(first.tier, 1)
	assert_eq(first.cost, 8)
	assert_eq(first.variable_affinity, ["acute_stress"])

	var tier_3_entry: DeckEntry = package.deck[3]
	assert_eq(tier_3_entry.op_class, "PhantomEntity")
	assert_eq(tier_3_entry.tier, 3)
	assert_eq(tier_3_entry.variable_affinity, ["moral_injury", "identity_strain"])


## Post-arc: params (docs/review_and_forward_plan.md F1) pass through
## untouched — MissionLoader doesn't validate or reshape them, only
## OpFactory does.
func test_load_from_file_params_pass_through_untouched() -> void:
	var package: MissionPackage = MissionLoader.load_from_file(STUB_MISSION_PATH)
	var first: DeckEntry = package.deck[0]
	assert_eq(first.params["target_source_id"], 1.0)  # JSON numbers parse as float
	assert_eq(first.params["swapped_tag"], "muffled_thud")


func test_from_dict_matches_load_from_file() -> void:
	var file: FileAccess = FileAccess.open(STUB_MISSION_PATH, FileAccess.READ)
	assert_not_null(file, "stub fixture must exist: %s" % STUB_MISSION_PATH)
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	assert_eq(typeof(parsed), TYPE_DICTIONARY)

	var from_dict_package: MissionPackage = MissionLoader.from_dict(parsed as Dictionary)
	var from_file_package: MissionPackage = MissionLoader.load_from_file(STUB_MISSION_PATH)
	assert_eq(from_dict_package.id, from_file_package.id)
	assert_eq(from_dict_package.deck.size(), from_file_package.deck.size())


## Proves the loaded content actually drives DistortionDirector, not just
## that it parses — the same worked-example budget (26) Pass 12 already
## hand-verified against a Python reference, now reached by loading real
## JSON instead of constructing the Dictionary inline.
func test_loaded_mission_drives_distortion_director_compute_budget() -> void:
	var package: MissionPackage = MissionLoader.load_from_file(STUB_MISSION_PATH)
	var mind_values_fx: Dictionary = {
		"acute_stress": FixedMath.from_int(40),
		"fatigue": FixedMath.from_int(20),
		"moral_injury": FixedMath.from_int(10),
		"identity_strain": FixedMath.from_int(5),
	}
	var budget: int = DistortionDirector.compute_budget(
		package.scene_type, mind_values_fx, package.mission_weights_fx
	)
	assert_eq(budget, 26)


func test_loaded_mission_deck_is_purchasable_and_reproducible_by_seed() -> void:
	var package: MissionPackage = MissionLoader.load_from_file(STUB_MISSION_PATH)
	var mind_values_fx: Dictionary = {
		"acute_stress": FixedMath.from_int(40),
		"fatigue": FixedMath.from_int(20),
		"moral_injury": FixedMath.from_int(10),
		"identity_strain": FixedMath.from_int(5),
	}

	var director_a := DistortionDirector.new(DistortionDirector.seed_for(1, 0, 0))
	director_a.grant_budget(package.scene_type, mind_values_fx, package.mission_weights_fx)
	var record_a: Dictionary = director_a.purchase_one(package.deck, mind_values_fx, 0)

	var director_b := DistortionDirector.new(DistortionDirector.seed_for(1, 0, 0))
	director_b.grant_budget(package.scene_type, mind_values_fx, package.mission_weights_fx)
	var record_b: Dictionary = director_b.purchase_one(package.deck, mind_values_fx, 0)

	assert_false(record_a.is_empty())
	assert_eq(record_a, record_b)
