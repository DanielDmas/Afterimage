extends AfterimageTestCase


func test_equip_and_is_equipped() -> void:
	var loadout := Loadout.new()
	var coat := LoadoutItem.new("item.coat", "Day coat", LoadoutItem.Category.PROP, true)
	assert_false(loadout.is_equipped(coat))
	loadout.equip(coat)
	assert_true(loadout.is_equipped(coat))


func test_equip_is_idempotent() -> void:
	var loadout := Loadout.new()
	var coat := LoadoutItem.new("item.coat", "Day coat", LoadoutItem.Category.PROP, true)
	loadout.equip(coat)
	loadout.equip(coat)
	assert_eq(loadout.equipped.size(), 1)


func test_unequip_removes_the_item() -> void:
	var loadout := Loadout.new()
	var coat := LoadoutItem.new("item.coat", "Day coat", LoadoutItem.Category.PROP, true)
	loadout.equip(coat)
	loadout.unequip(coat)
	assert_false(loadout.is_equipped(coat))


func test_empty_loadout_is_cover_consistent() -> void:
	var loadout := Loadout.new()
	assert_true(loadout.is_cover_consistent())


func test_loadout_with_only_consistent_items_is_cover_consistent() -> void:
	var loadout := Loadout.new()
	loadout.equip(LoadoutItem.new("item.coat", "Day coat", LoadoutItem.Category.PROP, true))
	loadout.equip(LoadoutItem.new("item.badge", "Argus badge", LoadoutItem.Category.PROP, true))
	assert_true(loadout.is_cover_consistent())


func test_one_inconsistent_item_flags_the_whole_loadout() -> void:
	var loadout := Loadout.new()
	loadout.equip(LoadoutItem.new("item.coat", "Day coat", LoadoutItem.Category.PROP, true))
	var silenced := LoadoutItem.new(
		"item.silenced_cz75", "Silenced CZ 75", LoadoutItem.Category.WEAPON, false
	)
	loadout.equip(silenced)
	assert_false(loadout.is_cover_consistent())


func test_inconsistent_items_lists_only_the_flagged_ones() -> void:
	var loadout := Loadout.new()
	var coat := LoadoutItem.new("item.coat", "Day coat", LoadoutItem.Category.PROP, true)
	var silenced := LoadoutItem.new(
		"item.silenced_cz75", "Silenced CZ 75", LoadoutItem.Category.WEAPON, false
	)
	loadout.equip(coat)
	loadout.equip(silenced)
	var flagged: Array[LoadoutItem] = loadout.inconsistent_items()
	assert_eq(flagged.size(), 1)
	assert_eq(flagged[0].id, "item.silenced_cz75")
