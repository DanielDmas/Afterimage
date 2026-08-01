## docs/forward_dev_plan.md Phase C's "event-log reducer": turns raw
## simulation output into the `{id, subject, predicate, object,
## qualifiers?}` "perceived event" shape `ClaimDrafter.draft_from_perceived_events()`
## already consumes. Two independent reductions, from two different
## sources, matching this class's own two-source job description:
##
## `reduce_sightings()` reads a *percept* view (a `ReplayTheater.percept_view_at()`
## / `PerceptRenderer.render()` result per tick, never a truth snapshot —
## this file is under src/debrief/, outside tools/percept_truth_boundary_lint.py's
## src/percept/-only scope, but the discipline is worth keeping anyway: a
## reducer that peeked at truth to decide what counts as "seen" would
## defeat the exact thing it exists to prove). This is master_plan.md
## §4.10's "quiet knife" made mechanical: a `PhantomEntity` the player
## believes is present sits in `snapshot["actors"]` in exactly the same
## shape a real actor does (`percept/phantom_entity.gd`'s own doc), so
## reducing it produces a claim candidate indistinguishable from a real
## sighting. Whether it's actually true is answered later, at submission
## (`DebriefLedger`'s truth-delta) — never here.
##
## One claim per actor id, on the *first* tick it's ever present (rising
## edge only) — a "sighting" is a discrete event, not something to
## re-assert every tick an actor happens to still be standing there.
##
## `reduce_downed_events()` reads real, already-true `ActorDowned` facts
## (a truth-layer `EventBus` event, `{"id": target_id}` — src/sim/truth_sim.gd)
## collected by the caller during a run (EventBus has no built-in history;
## `MindModelEventBridge`'s own subscribe-and-react pattern is the
## precedent for a caller collecting events itself). Always
## truth-consistent by construction — a useful contrast case alongside the
## percept-sourced sightings, which may or may not be.
class_name ClaimReducer
extends RefCounted


## `percept_snapshots`: one entry per tick, in tick order, each already
## run through `PerceptRenderer.render()` (or `ReplayTheater.percept_view_at()`).
## `qualifiers.actor_id` carries the real numeric actor id for whatever
## later needs to look up ground truth by id (DebriefLedger's caller,
## never this class) — `object` itself is a human-facing label, not
## necessarily unique or truth-comparable on its own.
static func reduce_sightings(percept_snapshots: Array[Dictionary]) -> Array[Dictionary]:
	var seen_ids: Dictionary = {}  ## actor_id -> true
	var events: Array[Dictionary] = []
	for snapshot: Dictionary in percept_snapshots:
		for actor: Dictionary in snapshot.get("actors", []) as Array:
			var actor_id: int = actor["id"]
			if seen_ids.has(actor_id):
				continue
			seen_ids[actor_id] = true
			var label: String = String(actor.get("entity_kind", "actor_%d" % actor_id))
			(
				events
				. append(
					{
						"id": "sighting.%d" % actor_id,
						"subject": "player",
						"predicate": "saw_entity",
						"object": label,
						"qualifiers": {"actor_id": actor_id},
					}
				)
			)
	return events


## `downed_events`: raw EventBus-shaped `ActorDowned` facts the caller
## collected during a run — each `{"type": "ActorDowned", "payload":
## {"id": int}, ...}`, EventBus's own dispatched-event shape
## (src/core/event_bus.gd's class doc), not yet reduced to anything.
static func reduce_downed_events(downed_events: Array[Dictionary]) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for raw_event: Dictionary in downed_events:
		var actor_id: int = raw_event["payload"]["id"]
		(
			events
			. append(
				{
					"id": "downed.%d.tick_%d" % [actor_id, int(raw_event.get("tick", -1))],
					"subject": "actor_%d" % actor_id,
					"predicate": "was_downed",
					"object": "true",
					"qualifiers": {"actor_id": actor_id, "tick": raw_event.get("tick", -1)},
				}
			)
		)
	return events
