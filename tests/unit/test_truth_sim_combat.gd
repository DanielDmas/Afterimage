extends AfterimageTestCase

## Pass 7: combat verbs + AI wired into TruthSim.step(). Split from
## test_truth_sim.gd (which still covers Pass 3's movement/replay/event
## contract) because a single file crossed gdlint's max-public-methods
## limit — the same split test_predicate.gd needed pre-Pass-1.


## As in test_truth_sim.gd: event payloads are captured via a bound-method
## Callable on a helper class, not a lambda mutating a captured local.
class _EventLogger:
	var events: Array = []

	func handle(event: Dictionary) -> void:
		events.append(event)


func test_spawn_ai_returns_a_valid_actor_with_defaults() -> void:
	var sim := TruthSim.new(500, Vector2i(0, 0), 300)
	var ai_id: int = sim.spawn_ai(Vector2i(5000, 0), 300, AiArchetype.sentry())
	assert_true(sim.actors.has_actor(ai_id))
	var ai_actor: Actor = sim.actors.get_actor(ai_id)
	assert_eq(ai_actor.hit_points, TruthSim.DEFAULT_AI_HIT_POINTS)
	assert_eq(ai_actor.facing_dir, Vector2i(1, 0))
	assert_eq(sim.ai_current_state(ai_id), AiUtility.State.PATROL)


## Player fires at an AI directly behind its own facing (so it can't see
## the shooter) but well within Weapon.cz75()'s gunshot hearing range
## (CombatResolver.hearing_range_mm(90) = 9000mm at a 5000mm separation)
## -- a single test proving both the hit resolution AND the noise-heard
## wiring land correctly: the AI can't see the shot but hears it.
func test_fire_hits_target_and_the_gunshot_is_heard_by_an_ai_that_cannot_see_the_shooter() -> void:
	var sim := TruthSim.new(500, Vector2i(0, 0), 300)
	# AiArchetype default facing is (1,0): the player, at the origin, is
	# directly behind this AI's own facing direction.
	var ai_id: int = sim.spawn_ai(Vector2i(5000, 0), 300, AiArchetype.sentry())
	sim.step(InputFrame.new(1, {"fire": true, "aim_dir": Vector2i(1, 0)}))
	var ai_actor: Actor = sim.actors.get_actor(ai_id)
	assert_eq(ai_actor.hit_points, TruthSim.DEFAULT_AI_HIT_POINTS - TruthSim.HIT_DAMAGE)
	assert_eq(sim.ai_current_state(ai_id), AiUtility.State.INVESTIGATE)


func test_fire_with_no_targets_still_consumes_ammo() -> void:
	var sim := TruthSim.new(500, Vector2i(0, 0), 300)
	sim.step(InputFrame.new(1, {"fire": true, "aim_dir": Vector2i(1, 0)}))
	assert_eq(sim.player_weapon_ammo(), Weapon.cz75().magazine_capacity - 1)


func test_fire_does_nothing_once_out_of_ammo() -> void:
	var sim := TruthSim.new(500, Vector2i(0, 0), 300)
	var capacity: int = Weapon.cz75().magazine_capacity
	for i: int in range(capacity):
		sim.step(InputFrame.new(i + 1, {"fire": true, "aim_dir": Vector2i(1, 0)}))
	assert_eq(sim.player_weapon_ammo(), 0)
	sim.step(InputFrame.new(capacity + 1, {"fire": true, "aim_dir": Vector2i(1, 0)}))
	assert_eq(sim.player_weapon_ammo(), 0)


func test_reload_restores_ammo_after_its_tick_count() -> void:
	var sim := TruthSim.new(500, Vector2i(0, 0), 300)
	var capacity: int = Weapon.cz75().magazine_capacity
	var reload_ticks: int = Weapon.cz75().reload_ticks

	sim.step(InputFrame.new(1, {"fire": true, "aim_dir": Vector2i(1, 0)}))
	assert_eq(sim.player_weapon_ammo(), capacity - 1)

	# weapon.advance_tick() runs unconditionally every step(), so the tick
	# that requests reload already consumes its first countdown tick —
	# exactly reload_ticks-1 further ticks complete it, not reload_ticks.
	sim.step(InputFrame.new(2, {"reload": true}))
	assert_true(sim.player_weapon_is_reloading())

	for i: int in range(reload_ticks - 2):
		sim.step(InputFrame.new(3 + i, {}))
	assert_true(sim.player_weapon_is_reloading(), "not finished yet")

	sim.step(InputFrame.new(1 + reload_ticks, {}))
	assert_false(sim.player_weapon_is_reloading())
	assert_eq(sim.player_weapon_ammo(), capacity)


func test_takedown_kills_an_adjacent_target_instantly() -> void:
	var sim := TruthSim.new(500, Vector2i(0, 0), 300)
	# 500mm away, within CombatResolver.TAKEDOWN_RANGE_MM (900mm).
	var ai_id: int = sim.spawn_ai(Vector2i(500, 0), 300, AiArchetype.sentry())
	sim.step(InputFrame.new(1, {"takedown_target_id": ai_id}))
	assert_false(sim.actors.get_actor(ai_id).is_alive())


func test_takedown_out_of_range_does_nothing() -> void:
	var sim := TruthSim.new(500, Vector2i(0, 0), 300)
	var ai_id: int = sim.spawn_ai(Vector2i(5000, 0), 300, AiArchetype.sentry())
	sim.step(InputFrame.new(1, {"takedown_target_id": ai_id}))
	assert_true(sim.actors.get_actor(ai_id).is_alive())
	assert_eq(sim.actors.get_actor(ai_id).hit_points, TruthSim.DEFAULT_AI_HIT_POINTS)


func test_throw_emits_noise_heard_by_an_ai_that_cannot_see_the_thrower() -> void:
	var sim := TruthSim.new(500, Vector2i(0, 0), 300)
	# Facing (1,0): the player, at the origin, is directly behind this AI.
	var ai_id: int = sim.spawn_ai(Vector2i(3000, 0), 300, AiArchetype.sentry())
	sim.step(InputFrame.new(1, {"throw_target": Vector2i(1000, 0)}))
	assert_eq(sim.ai_current_state(ai_id), AiUtility.State.INVESTIGATE)


func test_throw_beyond_max_range_does_not_land_and_emits_no_noise() -> void:
	var sim := TruthSim.new(500, Vector2i(0, 0), 300)
	var ai_id: int = sim.spawn_ai(Vector2i(3000, 0), 300, AiArchetype.sentry())
	sim.step(
		InputFrame.new(1, {"throw_target": Vector2i(CombatResolver.THROW_MAX_RANGE_MM + 1, 0)})
	)
	assert_eq(sim.ai_current_state(ai_id), AiUtility.State.PATROL)


func test_focus_can_be_activated_via_input_and_tracked() -> void:
	var sim := TruthSim.new(500, Vector2i(0, 0), 300)
	assert_false(sim.is_focus_active())
	sim.step(InputFrame.new(1, {"focus": true}))
	assert_true(sim.is_focus_active())
	assert_eq(sim.focus_activation_count(), 1)


func test_weapon_fired_event_publishes_with_hit_id_on_a_resolved_shot() -> void:
	var bus := EventBus.new()
	var logger := _EventLogger.new()
	bus.subscribe("WeaponFired", Callable(logger, "handle"))
	var sim := TruthSim.new(500, Vector2i(0, 0), 300, bus)
	var ai_id: int = sim.spawn_ai(Vector2i(5000, 0), 300, AiArchetype.sentry())

	sim.step(InputFrame.new(1, {"fire": true, "aim_dir": Vector2i(1, 0)}))

	assert_eq(logger.events.size(), 1)
	assert_eq(logger.events[0]["payload"]["shooter_id"], sim.player_id)
	assert_eq(logger.events[0]["payload"]["hit_id"], ai_id)


func test_actor_downed_event_publishes_when_hit_points_reach_zero() -> void:
	var bus := EventBus.new()
	var logger := _EventLogger.new()
	bus.subscribe("ActorDowned", Callable(logger, "handle"))
	var sim := TruthSim.new(500, Vector2i(0, 0), 300, bus)
	var ai_id: int = sim.spawn_ai(Vector2i(5000, 0), 300, AiArchetype.sentry(), Vector2i(1, 0), 1)

	sim.step(InputFrame.new(1, {"fire": true, "aim_dir": Vector2i(1, 0)}))

	assert_eq(logger.events.size(), 1)
	assert_eq(logger.events[0]["payload"]["id"], ai_id)
