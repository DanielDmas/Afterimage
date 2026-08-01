## Wires TruthSim's `"GroundObserved"` event (Pass 7's own
## `_resolve_ground_completion()`) to the suspicion/gossip pipeline
## (master_plan.md §4.7) — closing the one designed-but-disconnected loop
## docs/review_and_forward_plan.md's F5 flagged: Ground observed → a real
## suspicion ledger entry → one hop of gossip propagation, run for real
## for the first time, not three separately-tested segments that never
## once ran together.
##
## TruthSim identifies actors by sequential int IDs (`ActorRegistry`);
## `SuspicionGraph` identifies NPCs by authored String ids — there is no
## existing correspondence between the two namespaces anywhere in this
## codebase, so this class is constructed with the one mapping a scene
## actually knows (which AI actor socially *is* which NPC) rather than
## inventing a convention neither system already commits to. An observer
## with no NPC mapping is silently skipped, not an error — not every AI
## actor needs to be a real, named NPC (a faceless patrol guard has no
## social consequence to carry).
##
## Deliberately does not reference `TruthSim`/`Actor` by name anywhere —
## only `EventBus`'s own generic `{type, payload, source, tick}` event
## shape (duck-typed Dictionary access), matching `DistortionDirector`'s
## own "plain data, no direct sim-layer reference" discipline. Lives
## under `src/social/`, not `src/percept/`, so this isn't a boundary-lint
## question at all — it's a social-layer consumer of a truth-layer fact,
## exactly the kind of cross-directory reference this codebase has always
## allowed everywhere except the one percept/truth seam.
##
## **The caller must keep a reference to the constructed bridge for as
## long as its subscription should stay active.** This class is a plain
## `RefCounted` with no other owner; `_init()`'s `event_bus.subscribe()`
## call stores a `Callable` bound to this instance, but that alone does
## not keep the instance alive against Godot's reference counting once
## the constructor call's own temporary reference goes out of scope — a
## real CI failure (`tests/unit/test_ground_observation_bridge.gd`'s own
## first version, which discarded `GroundObservationBridge.new()`'s
## return value in three of its four tests) proved this the hard way: the
## bridge got freed before Ground ever completed, and `EventBus.
## _dispatch_one()`'s own `handler.is_valid()` check silently skipped the
## now-dead subscription — no error, just a suspicion entry that quietly
## never landed. Assign the constructor's result to a variable that
## outlives the scene/session this bridge should watch.
class_name GroundObservationBridge
extends RefCounted

const ENTRY_TYPE_SEEN_GROUNDING: String = "seen_grounding"

var graph: SuspicionGraph
var gossip: GossipSim
var actor_id_to_npc_id: Dictionary  ## int -> String
var current_day: int

var _event_bus: EventBus


## `current_day` is "which calendar day this scene's Ground-observed
## events count as happening on" — real hub-calendar wiring (Pass 18's
## `HubCalendar`) would set this from the actual campaign day; until a
## caller wires that up, it defaults to 0, the same "state now, real
## call site once a consumer exists" deferral this codebase has used
## since Pass 5's `FLEE` `threat_level`.
func _init(
	p_graph: SuspicionGraph,
	p_gossip: GossipSim,
	p_actor_id_to_npc_id: Dictionary,
	p_event_bus: EventBus,
	p_current_day: int = 0
) -> void:
	graph = p_graph
	gossip = p_gossip
	actor_id_to_npc_id = p_actor_id_to_npc_id
	current_day = p_current_day
	_event_bus = p_event_bus
	_event_bus.subscribe("GroundObserved", _on_ground_observed)


func _on_ground_observed(event: Dictionary) -> void:
	var payload: Dictionary = event["payload"]
	var observer_id: int = int(payload["observer_id"])
	if not actor_id_to_npc_id.has(observer_id):
		return
	var npc_id: String = actor_id_to_npc_id[observer_id]
	if not graph.has_npc(npc_id):
		return

	var weight: int = int(payload["suspicion_weight"])
	graph.add_entry(npc_id, ENTRY_TYPE_SEEN_GROUNDING, weight, current_day)
	gossip.propagate(graph, npc_id, ENTRY_TYPE_SEEN_GROUNDING, weight, current_day, _event_bus)
