## Typed publish/subscribe event bus — the spine of the application core
## (foundation_blueprints.md §1.2, tech_guidelines.md §3.5).
##
## Events are facts, past tense ("ClaimFiled", not "FileClaim"). Dispatch is
## synchronous and happens in subscriber-registration order; a handler that
## publishes another event during dispatch does NOT recurse — the new event
## is queued and processed only after the current dispatch finishes. This is
## what keeps ordering deterministic and reproducible from a recorded input
## stream: "subscribe in a fixed order, process one event fully before the
## next" is a total order with no scheduler nondeterminism in it.
##
## Deliberately a plain RefCounted, not a Node and never a Godot autoload:
## sim-core classes must not depend on the scene tree (tech_guidelines.md
## §2.2), and each TruthSim instance (or each test) owns its own EventBus so
## instances never leak state between unrelated simulations.
class_name EventBus
extends RefCounted

## event: {type: String, payload: Variant, source: Variant, tick: int}
## Callable signature: func(event: Dictionary) -> void
var _subscribers: Dictionary = {}  ## String -> Array[Callable], insertion order preserved
var _queue: Array = []
var _dispatching: bool = false


func subscribe(event_type: String, handler: Callable) -> void:
	if not _subscribers.has(event_type):
		_subscribers[event_type] = []
	var handlers: Array = _subscribers[event_type]
	if not handlers.has(handler):
		handlers.append(handler)


func unsubscribe(event_type: String, handler: Callable) -> void:
	if not _subscribers.has(event_type):
		return
	var handlers: Array = _subscribers[event_type]
	handlers.erase(handler)


## Publishes an event fact. If called while another event is already being
## dispatched, this event is queued and dispatched after the in-progress one
## completes (breadth-first, never reentrant) — see class doc.
func publish(
	event_type: String, payload: Variant = null, source: Variant = null, tick: int = -1
) -> void:
	var event: Dictionary = {
		"type": event_type,
		"payload": payload,
		"source": source,
		"tick": tick,
	}
	_queue.append(event)
	if _dispatching:
		return
	_drain_queue()


func _drain_queue() -> void:
	_dispatching = true
	while not _queue.is_empty():
		var event: Dictionary = _queue.pop_front()
		_dispatch_one(event)
	_dispatching = false


func _dispatch_one(event: Dictionary) -> void:
	var event_type: String = event["type"]
	if not _subscribers.has(event_type):
		return
	# Iterate a snapshot: a handler unsubscribing/subscribing mid-dispatch
	# must never mutate the array we're iterating.
	var handlers: Array = (_subscribers[event_type] as Array).duplicate()
	for handler: Callable in handlers:
		if handler.is_valid():
			handler.call(event)


func subscriber_count(event_type: String) -> int:
	if not _subscribers.has(event_type):
		return 0
	return (_subscribers[event_type] as Array).size()


func pending_count() -> int:
	return _queue.size()
