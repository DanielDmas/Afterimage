extends AfterimageTestCase


func test_spawn_actor_returns_sequential_ids() -> void:
	var reg := ActorRegistry.new()
	var a: int = reg.spawn_actor(Vector2i(0, 0), 300)
	var b: int = reg.spawn_actor(Vector2i(100, 0), 300)
	var c: int = reg.spawn_actor(Vector2i(200, 0), 300)
	assert_eq(a, 1)
	assert_eq(b, 2)
	assert_eq(c, 3)


func test_spawned_actor_has_requested_position_and_radius() -> void:
	var reg := ActorRegistry.new()
	var id: int = reg.spawn_actor(Vector2i(1500, -300), 350)
	var actor: Actor = reg.get_actor(id)
	assert_eq(actor.id, id)
	assert_eq(actor.position, Vector2i(1500, -300))
	assert_eq(actor.radius_mm, 350)


func test_has_actor() -> void:
	var reg := ActorRegistry.new()
	var id: int = reg.spawn_actor(Vector2i.ZERO, 300)
	assert_true(reg.has_actor(id))
	assert_false(reg.has_actor(id + 999))


func test_remove_actor() -> void:
	var reg := ActorRegistry.new()
	var id: int = reg.spawn_actor(Vector2i.ZERO, 300)
	reg.remove_actor(id)
	assert_false(reg.has_actor(id))
	assert_null(reg.get_actor(id))


func test_count_reflects_spawns_and_removals() -> void:
	var reg := ActorRegistry.new()
	assert_eq(reg.count(), 0)
	var a: int = reg.spawn_actor(Vector2i.ZERO, 300)
	reg.spawn_actor(Vector2i.ZERO, 300)
	assert_eq(reg.count(), 2)
	reg.remove_actor(a)
	assert_eq(reg.count(), 1)


func test_all_ids_is_sorted_regardless_of_spawn_order() -> void:
	var reg := ActorRegistry.new()
	var ids: Array = []
	for i in range(5):
		ids.append(reg.spawn_actor(Vector2i.ZERO, 300))
	var sorted_ids: Array = reg.all_ids()
	assert_eq(
		sorted_ids, ids, "IDs are assigned sequentially, so spawn order already is sort order"
	)

	reg.remove_actor(ids[2])
	var remaining: Array = reg.all_ids()
	assert_eq(remaining.size(), 4)
	assert_false(remaining.has(ids[2]))
	for i in range(remaining.size() - 1):
		assert_lt(remaining[i], remaining[i + 1], "all_ids() must be sorted ascending")
