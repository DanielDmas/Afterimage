## Owns every Actor in a TruthSim and assigns entity IDs. IDs are
## sequential integers assigned by the sim itself, never a Godot object
## instance ID (tech_guidelines.md §3.5) — a requirement for determinism,
## since instance IDs are not stable/reproducible across runs.
class_name ActorRegistry
extends RefCounted

var _actors: Dictionary = {}  ## int id -> Actor
var _next_id: int = 1  ## starts at 1 so 0 stays available as an "unset" sentinel


func spawn_actor(position: Vector2i, radius_mm: int) -> int:
	var id: int = _next_id
	_next_id += 1
	_actors[id] = Actor.new(id, position, radius_mm)
	return id


func get_actor(id: int) -> Actor:
	return _actors.get(id)


func has_actor(id: int) -> bool:
	return _actors.has(id)


func remove_actor(id: int) -> void:
	_actors.erase(id)


func count() -> int:
	return _actors.size()


## Deterministic order (tech_guidelines.md §3.5) — any system iterating
## every actor (AI ticks, witness checks) must never rely on Dictionary
## iteration order, so this is sorted explicitly.
func all_ids() -> Array:
	var ids: Array = _actors.keys()
	ids.sort()
	return ids
