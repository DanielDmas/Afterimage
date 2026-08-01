## Single serializable source of truth for campaign/hub/meta state
## (foundation_blueprints.md §1.1). Mission-in-progress truth state lives in
## TruthSim instead (Pass 3+) and is reconstructed from a ReplayLog — this
## store is for everything that persists *across* missions.
##
## Design choice worth being explicit about: "all mutations are Events"
## (blueprints §1.1) is satisfied here by every mutating call publishing a
## corresponding fact on the EventBus, not by full event-sourced replay of
## this store's contents — that stronger guarantee belongs to TruthSim's
## tick-by-tick truth log (ReplayLog), which is what the Theater and
## determinism corpus actually depend on. This store's event stream exists
## so other systems can observe/react to state changes and so the log
## doubles as analytics/audit trail, per blueprints §1.1's stated payoff.
class_name GameStateStore
extends RefCounted

var _event_bus: EventBus
var _state: Dictionary


func _init(event_bus: EventBus = null) -> void:
	_event_bus = event_bus
	_state = default_state()


## A fresh save's shape at the current schema version. Kept intentionally
## small in Pass 2 — MindModel, claims, suspicion, etc. add their own
## branches under "campaign" as their own passes land, never by widening
## this file's responsibilities.
static func default_state() -> Dictionary:
	return {
		"schema_version": SaveMigrations.CURRENT_SCHEMA_VERSION,
		"campaign":
		{
			"day": 0,
			"flags": {},
		},
	}


## Reads a nested value by key path, e.g. ["campaign", "day"]. Returns null
## if any segment of the path doesn't exist — a missing value is not an
## error at this layer (callers with a required-value contract enforce
## that themselves).
func get_value(path: Array) -> Variant:
	var node: Variant = _state
	for key: String in path:
		if typeof(node) != TYPE_DICTIONARY or not (node as Dictionary).has(key):
			return null
		node = (node as Dictionary)[key]
	return node


## Writes a nested value by key path, creating intermediate Dictionaries as
## needed, and publishes a "StateValueChanged" event with the old and new
## value so observers never have to poll.
func set_value(path: Array, value: Variant) -> void:
	assert(path.size() > 0, "GameStateStore.set_value: path must not be empty")
	var old_value: Variant = get_value(path)
	_set_value_recursive(_state, path, 0, value)
	if _event_bus:
		_event_bus.publish(
			"StateValueChanged", {"path": path, "old_value": old_value, "new_value": value}
		)


func _set_value_recursive(node: Dictionary, path: Array, index: int, value: Variant) -> void:
	var key: String = path[index]
	if index == path.size() - 1:
		node[key] = value
		return
	if not node.has(key) or typeof(node[key]) != TYPE_DICTIONARY:
		node[key] = {}
	_set_value_recursive(node[key], path, index + 1, value)


## Full serializable snapshot. Always at CURRENT_SCHEMA_VERSION — this
## store never holds an old-schema state in memory (migration happens on
## load, once, in load_from_dict()).
func to_dict() -> Dictionary:
	return _state.duplicate(true)


## Replaces this store's state with `data`, migrating it to the current
## schema first if it's older. Publishes "StateLoaded" so observers can
## re-sync from a fresh load (new game, load save, or a test fixture).
func load_from_dict(data: Dictionary) -> void:
	var migrated: Dictionary = SaveMigrations.migrate_to_current(data)
	_state = migrated
	if _event_bus:
		_event_bus.publish("StateLoaded", {"schema_version": migrated.get("schema_version")})


func reset_to_default() -> void:
	load_from_dict(default_state())
