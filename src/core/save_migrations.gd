## The save schema migration ladder (foundation_blueprints.md §6,
## tech_guidelines.md §5.3): version N loads version N-1 saves via chained,
## forward-only migrations, each covered by a fixture test. A save is never
## silently reinterpreted at the wrong version — migrate_to_current() fails
## loudly on anything it doesn't have a registered path for.
##
## CURRENT_SCHEMA_VERSION lives here, not in GameStateStore: this file is
## the single source of truth for "what version are we on," matching the
## rule that the migration ladder owns versioning.
class_name SaveMigrations
extends RefCounted

const CURRENT_SCHEMA_VERSION: int = 2


## v1 stored campaign fields at the save's top level; v2 nests them under
## "campaign" so hub/meta concerns and future top-level concerns (e.g. a
## settings block) don't collide in the same namespace. This is a real,
## exercised example of the ladder mechanism, not a stub — see
## tests/unit/test_save_migrations.gd.
static func _migrate_1_to_2(data: Dictionary) -> Dictionary:
	var migrated: Dictionary = data.duplicate(true)
	var campaign: Dictionary = migrated.get("campaign", {})
	if migrated.has("day"):
		campaign["day"] = migrated["day"]
		migrated.erase("day")
	if migrated.has("flags"):
		campaign["flags"] = migrated["flags"]
		migrated.erase("flags")
	migrated["campaign"] = campaign
	migrated["schema_version"] = 2
	return migrated


## One step of the ladder: dispatches version N to its migration function.
## Adding a schema change means adding one new match arm here, never
## touching the ones before it.
static func _migrate_one_step(from_version: int, data: Dictionary) -> Dictionary:
	match from_version:
		1:
			return _migrate_1_to_2(data)
		_:
			assert(false, "SaveMigrations: no migration registered from version %d" % from_version)
			return data


## Migrates a loaded save dict forward to CURRENT_SCHEMA_VERSION, applying
## each registered step in order. Asserts rather than guesses if the save
## is newer than this build understands, or if a step didn't advance the
## version — both are authoring/versioning bugs, not runtime conditions to
## paper over.
static func migrate_to_current(data: Dictionary) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	var version: int = int(result.get("schema_version", 1))
	assert(
		version <= CURRENT_SCHEMA_VERSION,
		(
			"SaveMigrations: save schema_version %d is newer than this build supports (%d)"
			% [version, CURRENT_SCHEMA_VERSION]
		)
	)
	while version < CURRENT_SCHEMA_VERSION:
		result = _migrate_one_step(version, result)
		var next_version: int = int(result.get("schema_version", version))
		assert(
			next_version > version,
			"SaveMigrations: migration from version %d did not advance schema_version" % version
		)
		version = next_version
	return result
