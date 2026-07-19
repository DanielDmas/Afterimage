extends AfterimageTestCase

## Integration/soak tests wiring GrayboxRoom + BotInputs (Pass 7) — proving
## the whole stack (movement, combat verbs, AI perception+reaction) works
## together deterministically, the actual point of M1's exit criterion
## ("a fight can be recorded and replayed tick-perfect"). This is
## master_plan §9's "headless bots... soak combat for crashes" v0 — see
## bot_inputs.gd's class doc for why these aren't literally the paranoid/
## credulous pair the design describes.

const PLAYER_START := Vector2i(500, 1750)
const SENTRY_START := Vector2i(4500, 1750)  # same row as the player; 4000mm apart, no walls between


func _build_encounter(event_bus: EventBus = null) -> Dictionary:
	var sim: TruthSim = GrayboxRoom.build(PLAYER_START, event_bus)
	var ai_id: int = sim.spawn_ai(
		SENTRY_START, GrayboxRoom.AI_RADIUS_MM, AiArchetype.sentry(), Vector2i(-1, 0)
	)
	return {"sim": sim, "ai_id": ai_id}


## Hand-traced outcome (docs/dev_log.md's Pass 7 entry has the full
## derivation): both combatants start dead-ahead of each other in an
## open room, so both land a dead-on shot every tick from tick 1 onward.
## Player movement+combat resolves before the AI's own tick within
## TruthSim.step(), so the AI (2 HP) dies on tick 2 one instant before it
## would have landed a second shot back — ending with the player alive
## at 2 of 3 HP.
func test_aggressive_bot_defeats_a_sentry_in_two_ticks() -> void:
	var built: Dictionary = _build_encounter()
	var sim: TruthSim = built["sim"]
	var ai_id: int = built["ai_id"]

	for tick: int in range(1, 3):
		var ai_pos: Vector2i = sim.actors.get_actor(ai_id).position
		sim.step(BotInputs.aggressive_frame(tick, sim.player_position(), ai_pos))

	assert_false(sim.actors.get_actor(ai_id).is_alive())
	assert_true(sim.actors.get_actor(sim.player_id).is_alive())
	assert_eq(sim.actors.get_actor(sim.player_id).hit_points, 2)


func test_aggressive_encounter_replays_identically() -> void:
	var built_a: Dictionary = _build_encounter()
	var built_b: Dictionary = _build_encounter()
	var sim_a: TruthSim = built_a["sim"]
	var sim_b: TruthSim = built_b["sim"]
	var ai_a: int = built_a["ai_id"]
	var ai_b: int = built_b["ai_id"]

	for tick: int in range(1, 6):
		var frame_a: InputFrame = BotInputs.aggressive_frame(
			tick, sim_a.player_position(), sim_a.actors.get_actor(ai_a).position
		)
		var frame_b: InputFrame = BotInputs.aggressive_frame(
			tick, sim_b.player_position(), sim_b.actors.get_actor(ai_b).position
		)
		assert_true(frame_a.equals(frame_b))
		sim_a.step(frame_a)
		sim_b.step(frame_b)

	assert_eq(sim_a.player_position(), sim_b.player_position())
	assert_eq(sim_a.actors.get_actor(ai_a).hit_points, sim_b.actors.get_actor(ai_b).hit_points)
	assert_eq(sim_a.actors.get_actor(ai_a).is_alive(), sim_b.actors.get_actor(ai_b).is_alive())


## A cautious bot never fires and always retreats — this doesn't stop the
## Sentry from noticing and firing back while still in range (v0 has no
## "mission end" state, so a downed player just keeps being simulated,
## same as a downed AI would). The property under test is the same one
## every soak test cares about: no crash, and byte-for-byte identical
## outcomes given identical inputs.
func test_cautious_bot_soak_runs_without_error_and_stays_deterministic() -> void:
	var built_a: Dictionary = _build_encounter()
	var built_b: Dictionary = _build_encounter()
	var sim_a: TruthSim = built_a["sim"]
	var sim_b: TruthSim = built_b["sim"]
	var ai_a: int = built_a["ai_id"]
	var ai_b: int = built_b["ai_id"]

	for tick: int in range(1, 61):
		sim_a.step(
			BotInputs.cautious_frame(
				tick, sim_a.player_position(), sim_a.actors.get_actor(ai_a).position
			)
		)
		sim_b.step(
			BotInputs.cautious_frame(
				tick, sim_b.player_position(), sim_b.actors.get_actor(ai_b).position
			)
		)

	assert_eq(sim_a.player_position(), sim_b.player_position())
	assert_eq(sim_a.actors.get_actor(ai_a).hit_points, sim_b.actors.get_actor(ai_b).hit_points)
