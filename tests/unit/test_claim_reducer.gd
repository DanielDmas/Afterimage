extends AfterimageTestCase


func _snapshot_with_actors(actors: Array[Dictionary]) -> Dictionary:
	return {"actors": actors}


func test_reduces_one_sighting_per_distinct_actor_id() -> void:
	var snapshots: Array[Dictionary] = [
		_snapshot_with_actors(
			[
				{"id": 1, "position": Vector2i(1000, 1000)},
				{"id": 2, "position": Vector2i(2000, 2000)}
			]
		)
	]
	var events: Array[Dictionary] = ClaimReducer.reduce_sightings(snapshots)
	assert_eq(events.size(), 2)
	assert_eq(events[0]["subject"], "player")
	assert_eq(events[0]["predicate"], "saw_entity")


func test_only_reduces_on_the_first_tick_an_actor_appears() -> void:
	var actor: Dictionary = {"id": 1, "position": Vector2i(1000, 1000)}
	var snapshots: Array[Dictionary] = [
		_snapshot_with_actors([actor]),
		_snapshot_with_actors([actor]),
		_snapshot_with_actors([actor]),
	]
	var events: Array[Dictionary] = ClaimReducer.reduce_sightings(snapshots)
	assert_eq(events.size(), 1)


func test_uses_entity_kind_as_the_label_when_present() -> void:
	var snapshots: Array[Dictionary] = [
		_snapshot_with_actors(
			[{"id": -7, "position": Vector2i.ZERO, "entity_kind": "second_guard"}]
		)
	]
	var events: Array[Dictionary] = ClaimReducer.reduce_sightings(snapshots)
	assert_eq(events[0]["object"], "second_guard")
	assert_eq(events[0]["qualifiers"]["actor_id"], -7)


func test_falls_back_to_a_generic_label_when_entity_kind_is_absent() -> void:
	var snapshots: Array[Dictionary] = [
		_snapshot_with_actors([{"id": 3, "position": Vector2i.ZERO}])
	]
	var events: Array[Dictionary] = ClaimReducer.reduce_sightings(snapshots)
	assert_eq(events[0]["object"], "actor_3")


## master_plan.md §4.10's "quiet knife": a percept-only PhantomEntity
## actor (negative id, exactly percept/phantom_entity.gd's own shape)
## reduces through the identical code path as a real one — same
## predicate, same shape, nothing here marks it as suspect.
func test_a_phantom_shaped_actor_reduces_identically_to_a_real_one() -> void:
	var real_actor: Dictionary = {"id": 4, "position": Vector2i.ZERO, "entity_kind": "real_guard"}
	var phantom_actor: Dictionary = {
		"id": -99, "position": Vector2i.ZERO, "entity_kind": "second_guard", "is_phantom": true
	}
	var snapshots: Array[Dictionary] = [_snapshot_with_actors([real_actor, phantom_actor])]
	var events: Array[Dictionary] = ClaimReducer.reduce_sightings(snapshots)

	assert_eq(events.size(), 2)
	for event: Dictionary in events:
		assert_eq(event["subject"], "player")
		assert_eq(event["predicate"], "saw_entity")
		assert_true(event.has("qualifiers"))
		assert_true(event["qualifiers"].has("actor_id"))


func test_empty_snapshots_reduce_no_sightings() -> void:
	var events: Array[Dictionary] = ClaimReducer.reduce_sightings([])
	assert_eq(events.size(), 0)


func test_reduces_one_claim_per_actor_downed_event() -> void:
	var downed_events: Array[Dictionary] = [
		{"type": "ActorDowned", "payload": {"id": 5}, "tick": 42},
	]
	var events: Array[Dictionary] = ClaimReducer.reduce_downed_events(downed_events)
	assert_eq(events.size(), 1)
	assert_eq(events[0]["subject"], "actor_5")
	assert_eq(events[0]["predicate"], "was_downed")
	assert_eq(events[0]["object"], "true")
	assert_eq(events[0]["qualifiers"]["tick"], 42)


func test_empty_downed_events_reduce_no_claims() -> void:
	var events: Array[Dictionary] = ClaimReducer.reduce_downed_events([])
	assert_eq(events.size(), 0)
