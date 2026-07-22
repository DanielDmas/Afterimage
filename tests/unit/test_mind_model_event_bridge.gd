extends AfterimageTestCase


func test_weapon_fired_raises_acute_stress_by_the_gunfire_in_earshot_amount() -> void:
	var mind := MindModel.new()
	var event_bus := EventBus.new()
	var bridge := MindModelEventBridge.new(mind, event_bus)

	event_bus.publish("WeaponFired", {"shooter_id": 1, "hit_id": 2})
	assert_eq(
		mind.acute_stress.value_fx(),
		FixedMath.from_int(AcuteStressState.GAIN_GUNFIRE_IN_EARSHOT),
	)
	assert_not_null(bridge)


func test_actor_downed_raises_acute_stress_by_the_witnessing_kill_amount() -> void:
	var mind := MindModel.new()
	var event_bus := EventBus.new()
	var bridge := MindModelEventBridge.new(mind, event_bus)

	event_bus.publish("ActorDowned", {"id": 5})
	assert_eq(
		mind.acute_stress.value_fx(), FixedMath.from_int(AcuteStressState.GAIN_WITNESSING_KILL)
	)
	assert_not_null(bridge)


## AcuteStressState clamps at a floor of 0 (it's a 0-100 scale, never
## negative) — a single WeaponFired's +2 followed by GroundCompleted's -8
## would clamp to 0 regardless of whether the relief actually fired,
## proving nothing. Five WeaponFired events first (+10 total) keeps the
## post-relief value positive and unambiguous.
func test_ground_completed_relieves_acute_stress() -> void:
	var mind := MindModel.new()
	var event_bus := EventBus.new()
	var bridge := MindModelEventBridge.new(mind, event_bus)

	for i: int in range(5):
		event_bus.publish("WeaponFired", {"shooter_id": 1, "hit_id": -1})
	event_bus.publish("GroundCompleted", {"observed_by": -1})
	assert_eq(
		mind.acute_stress.value_fx(),
		FixedMath.from_int(
			(
				(5 * AcuteStressState.GAIN_GUNFIRE_IN_EARSHOT)
				+ AcuteStressState.RELIEF_GROUND_COMPLETED
			)
		),
	)
	assert_not_null(bridge)


func test_multiple_events_accumulate() -> void:
	var mind := MindModel.new()
	var event_bus := EventBus.new()
	var bridge := MindModelEventBridge.new(mind, event_bus)

	event_bus.publish("WeaponFired", {"shooter_id": 1, "hit_id": -1})
	event_bus.publish("WeaponFired", {"shooter_id": 1, "hit_id": -1})
	event_bus.publish("ActorDowned", {"id": 5})
	assert_eq(
		mind.acute_stress.value_fx(),
		FixedMath.from_int(
			(2 * AcuteStressState.GAIN_GUNFIRE_IN_EARSHOT) + AcuteStressState.GAIN_WITNESSING_KILL
		),
	)
	assert_not_null(bridge)
