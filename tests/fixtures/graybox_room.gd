## A minimal, code-defined graybox level (master_plan.md §4.9's combat-
## feel prototype: "one space, Sentry + Professional"). Deliberately not
## a real Godot scene/tilemap — no visual level exists before real
## content authoring (Pass 13+'s content pipeline, or a later art pass),
## and "content is data not code" (tech_guidelines) means even a real
## graybox room belongs in an authored level format, not hardcoded
## GDScript. This is the same kind of disposable stand-in Pass 2's
## StubSim was for the determinism corpus: good enough to prove Pass 7's
## wiring works, replaced wholesale once real level-authoring exists.
## Explicitly under tests/fixtures/, not src/, for the same reason.
class_name GrayboxRoom
extends RefCounted

const CELL_SIZE_MM: int = 500
const ROOM_WIDTH_CELLS: int = 12
const ROOM_HEIGHT_CELLS: int = 8
const PLAYER_RADIUS_MM: int = 250
const AI_RADIUS_MM: int = 250


## A perimeter-walled room (interior world coords roughly
## [0, ROOM_WIDTH_CELLS*CELL_SIZE_MM) x [0, ROOM_HEIGHT_CELLS*CELL_SIZE_MM))
## with the player spawned at `player_start`. Callers add AI via the
## returned TruthSim's own spawn_ai().
static func build(player_start: Vector2i, event_bus: EventBus = null) -> TruthSim:
	var sim := TruthSim.new(CELL_SIZE_MM, player_start, PLAYER_RADIUS_MM, event_bus)
	_wall_perimeter(sim.grid)
	return sim


static func _wall_perimeter(grid: CollisionGrid) -> void:
	for x: int in range(-1, ROOM_WIDTH_CELLS + 1):
		grid.set_cell_blocked(Vector2i(x, -1), true)
		grid.set_cell_blocked(Vector2i(x, ROOM_HEIGHT_CELLS), true)
	for y: int in range(-1, ROOM_HEIGHT_CELLS + 1):
		grid.set_cell_blocked(Vector2i(-1, y), true)
		grid.set_cell_blocked(Vector2i(ROOM_WIDTH_CELLS, y), true)
