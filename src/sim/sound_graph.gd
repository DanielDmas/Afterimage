## Sound propagation over an abstract room/portal graph (tech_guidelines.md
## §3.4: "sound-propagation (BFS over a room/portal graph with integer
## attenuation)"). Rooms are opaque string IDs (no real level exists yet —
## Pass 7's graybox room); portals connect two rooms with an integer
## attenuation cost, always bidirectional (a doorway carries sound both
## ways equally).
##
## A sound's loudness is a subtractive integer budget: each portal crossed
## subtracts its cost, and a room is "reached" only while some positive
## loudness remains. Finding the loudest-possible arrival at every room is
## a shortest-path problem (minimize total attenuation == maximize
## remaining loudness) solved here by iterative relaxation rather than a
## priority-queue Dijkstra — with the small room counts any real mission
## will have (tens of rooms, not thousands), O(rooms * portals) is
## irrelevant, and relaxation is simpler to get right and verify than a
## heap-based implementation. Revisit only if profiling on a real level
## ever calls for it (tech_guidelines.md §11.1) — not before, matching the
## same choice already made for CollisionGrid's blocked-cell sweep.
class_name SoundGraph
extends RefCounted

## room_id (String) -> Array[{"to": String, "cost": int}]
var _portals: Dictionary = {}


func add_room(room_id: String) -> void:
	if not _portals.has(room_id):
		_portals[room_id] = []


func has_room(room_id: String) -> bool:
	return _portals.has(room_id)


## Portals are always bidirectional: sound carries through a doorway the
## same regardless of which side it started on.
func add_portal(room_a: String, room_b: String, cost: int) -> void:
	assert(cost >= 0, "SoundGraph.add_portal: attenuation cost must be non-negative")
	add_room(room_a)
	add_room(room_b)
	(_portals[room_a] as Array).append({"to": room_b, "cost": cost})
	(_portals[room_b] as Array).append({"to": room_a, "cost": cost})


func room_count() -> int:
	return _portals.size()


## Returns {room_id: remaining_loudness} for every room reachable from
## `source_room` with positive loudness left, given `initial_loudness` at
## the source and subtractive per-portal attenuation. A room omitted from
## the result is inaudible from this sound — every path to it attenuates
## fully. Deterministic regardless of portal-authoring order: the
## relaxation converges to a unique fixed point since all costs are
## non-negative (the same guarantee that makes Bellman-Ford correct for
## non-negative-weight shortest paths).
func propagate(source_room: String, initial_loudness: int) -> Dictionary:
	if not has_room(source_room) or initial_loudness <= 0:
		return {}

	var remaining: Dictionary = {source_room: initial_loudness}
	var room_ids: Array = _portals.keys()
	room_ids.sort()  # deterministic iteration order (tech_guidelines.md §3.5)

	var changed: bool = true
	while changed:
		changed = false
		for room_id: String in room_ids:
			if not remaining.has(room_id):
				continue
			var current_loudness: int = remaining[room_id]
			for portal: Dictionary in _portals[room_id] as Array:
				var neighbor: String = portal["to"]
				var arriving_loudness: int = current_loudness - int(portal["cost"])
				if arriving_loudness <= 0:
					continue
				if not remaining.has(neighbor) or arriving_loudness > remaining[neighbor]:
					remaining[neighbor] = arriving_loudness
					changed = true

	return remaining


## Convenience for a single yes/no/how-loud query without reading the
## whole propagation map.
func loudness_at(source_room: String, initial_loudness: int, target_room: String) -> int:
	var map: Dictionary = propagate(source_room, initial_loudness)
	return int(map.get(target_room, 0))
