extends AfterimageTestCase

## As in test_event_bus.gd: event payloads are captured via a bound-method
## Callable on a small helper class rather than a lambda mutating a
## captured local, to avoid GDScript's by-value closure capture of
## primitives producing a false failure.


class _EventLogger:
	var events: Array = []

	func handle(event: Dictionary) -> void:
		events.append(event)


func test_default_state_has_current_schema_version() -> void:
	var store := GameStateStore.new()
	assert_eq(store.get_value(["schema_version"]), SaveMigrations.CURRENT_SCHEMA_VERSION)
	assert_eq(store.get_value(["campaign", "day"]), 0)


## Phase C's debrief consequence channels (docs/forward_dev_plan.md) —
## DebriefLedger.submit_claim() reads/writes these two key-paths.
func test_default_state_has_debrief_consequence_channels() -> void:
	var store := GameStateStore.new()
	assert_eq(store.get_value(["campaign", "doubek_trust"]), 50)
	assert_eq(store.get_value(["campaign", "resource_budget"]), 100)


func test_get_value_missing_path_returns_null() -> void:
	var store := GameStateStore.new()
	assert_null(store.get_value(["campaign", "nonexistent"]))
	assert_null(store.get_value(["nonexistent", "deeper", "path"]))


func test_set_value_writes_nested_path() -> void:
	var store := GameStateStore.new()
	store.set_value(["campaign", "day"], 5)
	assert_eq(store.get_value(["campaign", "day"]), 5)


func test_set_value_creates_intermediate_dictionaries() -> void:
	var store := GameStateStore.new()
	store.set_value(["campaign", "flags", "met_doubek"], true)
	assert_eq(store.get_value(["campaign", "flags", "met_doubek"]), true)


func test_set_value_publishes_state_value_changed() -> void:
	var bus := EventBus.new()
	var logger := _EventLogger.new()
	bus.subscribe("StateValueChanged", Callable(logger, "handle"))
	var store := GameStateStore.new(bus)

	store.set_value(["campaign", "day"], 3)

	assert_eq(logger.events.size(), 1)
	var payload: Dictionary = logger.events[0]["payload"]
	assert_eq(payload["path"], ["campaign", "day"])
	assert_eq(payload["old_value"], 0)
	assert_eq(payload["new_value"], 3)


func test_load_from_dict_publishes_state_loaded() -> void:
	var bus := EventBus.new()
	var logger := _EventLogger.new()
	bus.subscribe("StateLoaded", Callable(logger, "handle"))
	var store := GameStateStore.new(bus)

	store.load_from_dict({"schema_version": 2, "campaign": {"day": 1, "flags": {}}})

	assert_eq(logger.events.size(), 1)
	assert_eq(logger.events[0]["payload"]["schema_version"], 2)


func test_load_from_dict_migrates_old_saves() -> void:
	var store := GameStateStore.new()
	store.load_from_dict({"schema_version": 1, "day": 9, "flags": {"a": true}})
	assert_eq(store.get_value(["schema_version"]), 2)
	assert_eq(store.get_value(["campaign", "day"]), 9)


func test_reset_to_default_restores_fresh_state() -> void:
	var store := GameStateStore.new()
	store.set_value(["campaign", "day"], 100)
	store.reset_to_default()
	assert_eq(store.get_value(["campaign", "day"]), 0)


func test_to_dict_is_a_defensive_copy() -> void:
	var store := GameStateStore.new()
	var snapshot: Dictionary = store.to_dict()
	snapshot["campaign"]["day"] = 999
	assert_eq(
		store.get_value(["campaign", "day"]),
		0,
		"mutating a to_dict() snapshot must not affect the store"
	)


func test_to_dict_then_load_from_dict_round_trips() -> void:
	var store := GameStateStore.new()
	store.set_value(["campaign", "day"], 4)
	store.set_value(["campaign", "flags", "x"], true)

	var snapshot: Dictionary = store.to_dict()
	var restored := GameStateStore.new()
	restored.load_from_dict(snapshot)

	assert_eq(restored.to_dict(), snapshot)
