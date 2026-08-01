extends AfterimageTestCase


func test_constructor_assigns_all_fields() -> void:
	var item := LoadoutItem.new("item.cz75", "CZ 75", LoadoutItem.Category.WEAPON, false)
	assert_eq(item.id, "item.cz75")
	assert_eq(item.display_name, "CZ 75")
	assert_eq(item.category, LoadoutItem.Category.WEAPON)
	assert_false(item.cover_consistent)
