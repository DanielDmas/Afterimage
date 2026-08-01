## foundation_blueprints.md §5's GossipSim: "end-of-day breadth-first
## propagation of investigation-relevant knowledge along gossip edges with
## per-edge delay and distortion; deterministic per seed stream... its
## primary cargo is suspicion (master_plan §4.7)."
##
## v0 scope: propagates one hop — from the observing NPC directly to its
## own gossip_edges — not a full multi-hop BFS cascade through the whole
## graph. True breadth-first propagation (a rumor reaching a neighbor's
## neighbors, each leg with its own cumulative delay) needs a real
## day/event scheduling system to land arrivals on the correct future day
## and re-trigger further propagation from each newly-informed NPC — that
## scheduling infrastructure doesn't exist before Pass 18's hub calendar.
## What's real here: the actual per-edge delay/distortion mechanics
## (§4.7's "per-edge delay (1-3 days) and distortion (weight ±1, details
## blur)"), applied correctly and deterministically for a single hop, the
## exact building block multi-hop cascading will later call repeatedly.
class_name GossipSim
extends RefCounted

## "details blur": a distorted entry's specific type is replaced with a
## generic rumor tag rather than the exact original observation — the
## receiving NPC's suspicion ledger records vaguer knowledge than the
## originating one had firsthand.
const BLURRED_TYPE_PREFIX: String = "gossip_of:"

const EVENT_SUSPICION_ENTRY_ADDED: String = "SuspicionEntryAdded"

var _rng: Xoshiro128StarStar


func _init(seed: int) -> void:
	_rng = Xoshiro128StarStar.new(seed)


## Propagates one suspicion observation from `source_npc_id` along every
## one of its gossip_edges, writing a new ledger entry (arrival day =
## `source_day + edge.delay_days`) at each target NPC already present in
## `graph`. Edges to an NPC not in `graph` are skipped rather than erroring
## - content may reference a wider cast than any one scene's roster
## includes. `event_bus`, if given, gets one "SuspicionEntryAdded" fact per
## target (foundation_blueprints §1.2's own example event name),
## `tick|day` populated with the arrival day.
func propagate(
	graph: SuspicionGraph,
	source_npc_id: String,
	entry_type: String,
	weight: int,
	source_day: int,
	event_bus: EventBus = null
) -> void:
	var source: NPC = graph.npc(source_npc_id)
	for edge: Dictionary in source.gossip_edges:
		var target_id: String = edge["npc_id"]
		if not graph.has_npc(target_id):
			continue

		var arrival_day: int = source_day + int(edge["delay_days"])
		var propagated_type: String = entry_type
		var propagated_weight: int = weight

		if edge.get("distortion", false):
			var delta: int = _rng.next_range_int(-1, 1)
			propagated_weight = maxi(0, weight + delta)
			propagated_type = BLURRED_TYPE_PREFIX + entry_type

		graph.add_entry(target_id, propagated_type, propagated_weight, arrival_day)

		if event_bus != null:
			(
				event_bus
				. publish(
					EVENT_SUSPICION_ENTRY_ADDED,
					{
						"npc_id": target_id,
						"type": propagated_type,
						"weight": propagated_weight,
						"source_npc_id": source_npc_id,
					},
					source_npc_id,
					arrival_day
				)
			)
