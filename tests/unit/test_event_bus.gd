extends AfterimageTestCase

## Counters are mutated from inside lambdas/handlers in several tests below.
## GDScript lambdas capture outer local variables of primitive types (int,
## bool, ...) BY VALUE at creation time, not by reference — mutating them
## inside the lambda does not propagate outward. Arrays/Dictionaries and
## bound-method Callables on a helper instance don't have this problem
## (they're reference types), so every test here uses one of those instead
## of a bare captured int, specifically to avoid a false failure caused by
## that GDScript semantic rather than a real EventBus bug.


class _CallLogger:
	var calls: int = 0

	func handle(_e: Dictionary) -> void:
		calls += 1


class _SelfUnsubscriber:
	var calls: int = 0
	var bus: EventBus
	var event_type: String = ""

	func handle(_e: Dictionary) -> void:
		calls += 1
		bus.unsubscribe(event_type, Callable(self, "handle"))


func test_subscriber_receives_published_event() -> void:
	var bus := EventBus.new()
	var received: Array = []
	bus.subscribe("ClaimFiled", func(event: Dictionary) -> void: received.append(event))
	bus.publish("ClaimFiled", {"id": "claim.1"})
	assert_eq(received.size(), 1)
	assert_eq(received[0]["type"], "ClaimFiled")
	assert_eq(received[0]["payload"], {"id": "claim.1"})


func test_multiple_subscribers_all_receive_in_registration_order() -> void:
	var bus := EventBus.new()
	var order: Array = []
	bus.subscribe("Tick", func(_e: Dictionary) -> void: order.append("a"))
	bus.subscribe("Tick", func(_e: Dictionary) -> void: order.append("b"))
	bus.subscribe("Tick", func(_e: Dictionary) -> void: order.append("c"))
	bus.publish("Tick")
	assert_eq(order, ["a", "b", "c"])


func test_unrelated_event_types_do_not_cross_talk() -> void:
	var bus := EventBus.new()
	var a := _CallLogger.new()
	var b := _CallLogger.new()
	bus.subscribe("A", Callable(a, "handle"))
	bus.subscribe("B", Callable(b, "handle"))
	bus.publish("A")
	assert_eq(a.calls, 1)
	assert_eq(b.calls, 0)


func test_publish_with_no_subscribers_does_not_error() -> void:
	var bus := EventBus.new()
	bus.publish("NothingListensToThis")
	assert_true(true, "reaching this line means publish() didn't throw")


func test_unsubscribe_stops_further_delivery() -> void:
	var bus := EventBus.new()
	var logger := _CallLogger.new()
	var handler := Callable(logger, "handle")
	bus.subscribe("X", handler)
	bus.publish("X")
	bus.unsubscribe("X", handler)
	bus.publish("X")
	assert_eq(logger.calls, 1)


func test_reentrant_publish_is_queued_not_recursive() -> void:
	# A handler for "First" publishes "Second" mid-dispatch. Because
	# dispatch is not reentrant, "Second"'s subscriber must run only after
	# "First"'s own dispatch has fully finished — this proves the ordering
	# guarantee (tech_guidelines.md §3.5), not just eventual delivery.
	var bus := EventBus.new()
	var log: Array = []
	bus.subscribe(
		"First",
		func(_e: Dictionary) -> void:
			log.append("first_start")
			bus.publish("Second")
			log.append("first_end")
	)
	bus.subscribe("Second", func(_e: Dictionary) -> void: log.append("second"))
	bus.publish("First")
	assert_eq(log, ["first_start", "first_end", "second"])


func test_subscriber_count_reflects_registrations() -> void:
	var bus := EventBus.new()
	assert_eq(bus.subscriber_count("Y"), 0)
	bus.subscribe("Y", func(_e: Dictionary) -> void: pass)
	bus.subscribe("Y", func(_e: Dictionary) -> void: pass)
	assert_eq(bus.subscriber_count("Y"), 2)


func test_duplicate_subscription_is_idempotent() -> void:
	var bus := EventBus.new()
	var logger := _CallLogger.new()
	var handler := Callable(logger, "handle")
	bus.subscribe("Z", handler)
	bus.subscribe("Z", handler)
	bus.publish("Z")
	assert_eq(logger.calls, 1, "the same Callable subscribed twice should only fire once")


func test_handler_unsubscribing_itself_mid_dispatch_is_safe() -> void:
	var bus := EventBus.new()
	var h := _SelfUnsubscriber.new()
	h.bus = bus
	h.event_type = "Self"
	bus.subscribe("Self", Callable(h, "handle"))
	bus.publish("Self")
	bus.publish("Self")
	assert_eq(h.calls, 1)


func test_payload_source_and_tick_are_carried() -> void:
	var bus := EventBus.new()
	var seen: Array = []
	bus.subscribe("Tagged", func(e: Dictionary) -> void: seen.append(e))
	bus.publish("Tagged", "payload-value", "source-value", 42)
	assert_eq(seen.size(), 1)
	assert_eq(seen[0]["payload"], "payload-value")
	assert_eq(seen[0]["source"], "source-value")
	assert_eq(seen[0]["tick"], 42)


func test_pending_count_is_zero_after_dispatch_settles() -> void:
	var bus := EventBus.new()
	bus.subscribe("Anything", func(_e: Dictionary) -> void: pass)
	bus.publish("Anything")
	assert_eq(bus.pending_count(), 0)
