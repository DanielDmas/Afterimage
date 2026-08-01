extends AfterimageTestCase


func test_constructor_assigns_all_fields() -> void:
	var deck: Array[DeckEntry] = [DeckEntry.new("AudioSwap", 1, 8, ["acute_stress"])]
	var weights_fx: Dictionary = {"acute_stress": FixedMath.from_float(1.0)}
	var package := MissionPackage.new(
		"mission.m00_stub", DistortionDirector.SceneType.COMBAT, weights_fx, 3, deck
	)
	assert_eq(package.id, "mission.m00_stub")
	assert_eq(package.scene_type, DistortionDirector.SceneType.COMBAT)
	assert_eq(package.mission_weights_fx, weights_fx)
	assert_eq(package.encounter_cap, 3)
	assert_eq(package.deck, deck)
