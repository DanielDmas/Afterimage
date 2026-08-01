extends AfterimageTestCase

## A capstone test: real TruthSim data through the real percept pipeline
## with real DistortionOp classes composed together — proving Pass 8's
## mechanism and Pass 9's ops genuinely wire up, not just against the
## synthetic fixtures each op's own unit test uses in isolation.


func test_phantom_entity_and_audio_swap_compose_over_a_real_truth_snapshot() -> void:
	var sim := TruthSim.new(500, Vector2i(0, 0), 300)
	sim.step(InputFrame.new(1, {"fire": true, "aim_dir": Vector2i(1, 0)}))
	var truth: Dictionary = sim.capture_percept_snapshot()

	var ops: Array = [
		PhantomEntity.new(Vector2i(9000, 9000), "dog"), AudioSwap.new(sim.player_id, "alarm")
	]
	var percept: Dictionary = PerceptRenderer.render(truth, ops)

	var real_count: int = 0
	var phantom_count: int = 0
	for a: Dictionary in percept["actors"] as Array:
		if a.get("is_phantom", false):
			phantom_count += 1
		else:
			real_count += 1
	assert_eq(real_count, 1)
	assert_eq(phantom_count, 1)

	var events: Array = percept["sound_events"]
	assert_eq(events.size(), 1)
	assert_eq(events[0]["tag"], "gunshot")
	assert_eq(events[0]["rendered_tag"], "alarm")

	# The original truth snapshot is untouched by any of this.
	assert_eq((truth["actors"] as Array).size(), 1)
	assert_false((truth["sound_events"] as Array)[0].has("rendered_tag"))
