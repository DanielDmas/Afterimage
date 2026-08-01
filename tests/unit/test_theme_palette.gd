extends AfterimageTestCase


func test_color_parses_a_hex_anchor_correctly() -> void:
	var c: Color = ThemePalette.color(ThemePalette.SODIUM_ORANGE)
	assert_almost_eq(c.r, 0xE8 / 255.0, 0.001)
	assert_almost_eq(c.g, 0x94 / 255.0, 0.001)
	assert_almost_eq(c.b, 0x40 / 255.0, 0.001)


func test_all_anchors_dictionary_has_ten_entries() -> void:
	assert_eq(ThemePalette.ALL_ANCHORS.size(), 10)


func test_anchor_names_returns_sorted_names() -> void:
	var names: Array = ThemePalette.anchor_names()
	assert_eq(names.size(), 10)
	var sorted_copy: Array = names.duplicate()
	sorted_copy.sort()
	assert_eq(names, sorted_copy)


func test_every_anchor_parses_to_a_distinct_color() -> void:
	var seen: Array[Color] = []
	for hex: String in ThemePalette.ALL_ANCHORS.values():
		var c: Color = ThemePalette.color(hex)
		assert_false(seen.has(c), "anchor color %s duplicates an earlier one" % hex)
		seen.append(c)
	assert_eq(seen.size(), 10)
