extends AfterimageTestCase


func test_constructor_defaults() -> void:
	var log := ReplayLog.new()
	assert_eq(log.run_seed, 0)
	assert_eq(log.content_version, "")
	assert_eq(log.frame_count(), 0)


func test_record_appends_frames_in_order() -> void:
	var log := ReplayLog.new(42, "m01")
	log.record(InputFrame.new(1, {"move_x": 1}))
	log.record(InputFrame.new(2, {"move_x": 0}))
	assert_eq(log.frame_count(), 2)
	assert_eq(log.frames[0].tick, 1)
	assert_eq(log.frames[1].tick, 2)


func test_to_dict_carries_seed_version_and_frames() -> void:
	var log := ReplayLog.new(99, "m02")
	log.record(InputFrame.new(1, {"jump": true}))
	var d: Dictionary = log.to_dict()
	assert_eq(d["run_seed"], 99)
	assert_eq(d["content_version"], "m02")
	assert_eq(d["replay_version"], ReplayLog.REPLAY_VERSION)
	assert_eq((d["frames"] as Array).size(), 1)


func test_round_trip_preserves_everything() -> void:
	var original := ReplayLog.new(12345, "corpus-fixture")
	original.record(InputFrame.new(1, {"move_x": 1, "move_y": -1}))
	original.record(InputFrame.new(2, {"roll": true}))
	original.record(InputFrame.new(3, {}))

	var restored := ReplayLog.from_dict(original.to_dict())
	assert_eq(restored.run_seed, original.run_seed)
	assert_eq(restored.content_version, original.content_version)
	assert_eq(restored.frame_count(), original.frame_count())
	for i: int in original.frame_count():
		assert_true(
			restored.frames[i].equals(original.frames[i]), "frame %d should survive round-trip" % i
		)


func test_from_dict_defaults_missing_fields() -> void:
	var log := ReplayLog.from_dict({"replay_version": ReplayLog.REPLAY_VERSION})
	assert_eq(log.run_seed, 0)
	assert_eq(log.content_version, "")
	assert_eq(log.frame_count(), 0)
