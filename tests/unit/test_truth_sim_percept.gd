extends AfterimageTestCase

## Pass 8: TruthSim.capture_percept_snapshot() is the one seam where truth
## hands data upward to the percept layer (master_plan §5.2). These tests
## exist alongside test_percept_renderer.gd/test_percept_op.gd because
## they exercise the truth side of the boundary, not the percept side.


func test_snapshot_reflects_actor_state() -> void:
	var sim := TruthSim.new(500, Vector2i(100, 200), 300)
	var ai_id: int = sim.spawn_ai(Vector2i(5000, 0), 250, AiArchetype.sentry(), Vector2i(-1, 0))

	var snapshot: Dictionary = sim.capture_percept_snapshot()

	assert_eq(snapshot["tick"], sim.clock.current_tick)
	assert_eq(snapshot["player_id"], sim.player_id)
	assert_eq(snapshot["actors"].size(), 2)

	var by_id: Dictionary = {}
	for a: Dictionary in snapshot["actors"]:
		by_id[a["id"]] = a

	var player_view: Dictionary = by_id[sim.player_id]
	assert_eq(player_view["position"], Vector2i(100, 200))
	assert_eq(player_view["radius_mm"], 300)
	assert_eq(player_view["hit_points"], TruthSim.DEFAULT_PLAYER_HIT_POINTS)
	assert_true(player_view["is_alive"])

	var ai_view: Dictionary = by_id[ai_id]
	assert_eq(ai_view["position"], Vector2i(5000, 0))
	assert_eq(ai_view["facing_dir"], Vector2i(-1, 0))
	assert_eq(ai_view["hit_points"], TruthSim.DEFAULT_AI_HIT_POINTS)


func test_snapshot_actors_are_sorted_by_id() -> void:
	var sim := TruthSim.new(500, Vector2i(0, 0), 300)
	sim.spawn_ai(Vector2i(1000, 0), 250, AiArchetype.sentry())
	sim.spawn_ai(Vector2i(2000, 0), 250, AiArchetype.professional())

	var snapshot: Dictionary = sim.capture_percept_snapshot()
	var ids: Array = []
	for a: Dictionary in snapshot["actors"]:
		ids.append(a["id"])

	var sorted_ids: Array = ids.duplicate()
	sorted_ids.sort()
	assert_eq(ids, sorted_ids)


func test_snapshot_reflects_a_downed_actor() -> void:
	var sim := TruthSim.new(500, Vector2i(0, 0), 300)
	var ai_id: int = sim.spawn_ai(Vector2i(500, 0), 250, AiArchetype.sentry(), Vector2i(1, 0), 1)
	sim.step(InputFrame.new(1, {"takedown_target_id": ai_id}))

	var snapshot: Dictionary = sim.capture_percept_snapshot()
	var ai_view: Dictionary = {}
	for a: Dictionary in snapshot["actors"]:
		if a["id"] == ai_id:
			ai_view = a
	assert_eq(ai_view["hit_points"], 0)
	assert_false(ai_view["is_alive"])


## The property that actually matters: the snapshot is data, not a
## reference into truth. Mutating it must be inert.
func test_mutating_the_returned_snapshot_does_not_affect_truth_sim() -> void:
	var sim := TruthSim.new(500, Vector2i(0, 0), 300)

	var snapshot: Dictionary = sim.capture_percept_snapshot()
	snapshot["player_id"] = -999
	snapshot["actors"][0]["position"] = Vector2i(99999, 99999)
	snapshot["actors"][0]["hit_points"] = 0
	snapshot["actors"].append({"id": 12345, "position": Vector2i.ZERO})

	assert_eq(sim.player_position(), Vector2i(0, 0))
	assert_eq(sim.actors.get_actor(sim.player_id).hit_points, TruthSim.DEFAULT_PLAYER_HIT_POINTS)
	assert_eq(sim.actors.count(), 1)
	assert_false(sim.actors.has_actor(12345))

	var fresh_snapshot: Dictionary = sim.capture_percept_snapshot()
	assert_eq(fresh_snapshot["player_id"], sim.player_id)
	assert_eq(fresh_snapshot["actors"].size(), 1)


## --- Pass 9: "sound_events" is the real truth source AudioSwap/
## PhantomAudio (master_plan §4.2) operate on. ---


func test_snapshot_includes_a_sound_event_from_sprinting() -> void:
	var sim := TruthSim.new(500, Vector2i(0, 0), 300)
	sim.step(InputFrame.new(1, {"move_x": 80, "move_y": 0, "sprinting": true}))
	var events: Array = sim.capture_percept_snapshot()["sound_events"]
	assert_eq(events.size(), 1)
	assert_eq(events[0]["tag"], "footsteps")
	assert_eq(events[0]["source_id"], sim.player_id)


func test_snapshot_includes_a_sound_event_from_firing() -> void:
	var sim := TruthSim.new(500, Vector2i(0, 0), 300)
	sim.step(InputFrame.new(1, {"fire": true, "aim_dir": Vector2i(1, 0)}))
	var events: Array = sim.capture_percept_snapshot()["sound_events"]
	assert_eq(events.size(), 1)
	assert_eq(events[0]["tag"], "gunshot")
	assert_eq(events[0]["source_id"], sim.player_id)


func test_snapshot_includes_a_sound_event_from_throwing() -> void:
	var sim := TruthSim.new(500, Vector2i(0, 0), 300)
	sim.step(InputFrame.new(1, {"throw_target": Vector2i(1000, 0)}))
	var events: Array = sim.capture_percept_snapshot()["sound_events"]
	assert_eq(events.size(), 1)
	assert_eq(events[0]["tag"], "thrown_object")


func test_snapshot_sound_events_do_not_persist_past_their_own_tick() -> void:
	var sim := TruthSim.new(500, Vector2i(0, 0), 300)
	sim.step(InputFrame.new(1, {"fire": true, "aim_dir": Vector2i(1, 0)}))
	sim.step(InputFrame.new(2, {}))
	assert_eq((sim.capture_percept_snapshot()["sound_events"] as Array).size(), 0)
