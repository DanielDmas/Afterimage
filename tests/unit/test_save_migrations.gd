extends AfterimageTestCase


func test_current_schema_version_is_2() -> void:
	# Pinned deliberately: this fixture suite exercises a real v1->v2 step,
	# not a stub. Bumping this is a real schema change and needs its own
	# new migration + fixture, per the ladder discipline.
	assert_eq(SaveMigrations.CURRENT_SCHEMA_VERSION, 2)


func test_migrates_v1_top_level_fields_into_campaign() -> void:
	var v1_save: Dictionary = {
		"schema_version": 1,
		"day": 7,
		"flags": {"prologue_complete": true},
	}
	var migrated: Dictionary = SaveMigrations.migrate_to_current(v1_save)
	assert_eq(migrated["schema_version"], 2)
	assert_false(migrated.has("day"), "v1's top-level 'day' must be removed after migration")
	assert_false(migrated.has("flags"), "v1's top-level 'flags' must be removed after migration")
	assert_eq(migrated["campaign"]["day"], 7)
	assert_eq(migrated["campaign"]["flags"], {"prologue_complete": true})


func test_already_current_version_is_a_no_op() -> void:
	var v2_save: Dictionary = {"schema_version": 2, "campaign": {"day": 3, "flags": {}}}
	var migrated: Dictionary = SaveMigrations.migrate_to_current(v2_save)
	assert_eq(migrated, v2_save)


func test_missing_schema_version_is_treated_as_v1() -> void:
	var legacy_save: Dictionary = {"day": 1, "flags": {}}
	var migrated: Dictionary = SaveMigrations.migrate_to_current(legacy_save)
	assert_eq(migrated["schema_version"], 2)
	assert_eq(migrated["campaign"]["day"], 1)


func test_migration_does_not_mutate_the_input_dictionary() -> void:
	var v1_save: Dictionary = {"schema_version": 1, "day": 5, "flags": {}}
	SaveMigrations.migrate_to_current(v1_save)
	assert_eq(v1_save["schema_version"], 1, "the caller's original dict must be left untouched")
	assert_true(v1_save.has("day"), "the caller's original dict must be left untouched")
