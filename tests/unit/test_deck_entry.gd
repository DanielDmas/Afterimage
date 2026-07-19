extends AfterimageTestCase


func test_constructor_assigns_all_fields() -> void:
	var entry := DeckEntry.new("AudioSwap", 1, 8, ["acute_stress", "fatigue"])
	assert_eq(entry.op_class, "AudioSwap")
	assert_eq(entry.tier, 1)
	assert_eq(entry.cost, 8)
	assert_eq(entry.variable_affinity, ["acute_stress", "fatigue"])


func test_variable_affinity_may_be_empty() -> void:
	var entry := DeckEntry.new("SubtitleDrift", 1, 5, [])
	assert_eq(entry.variable_affinity.size(), 0)
