## A uniform grid of blocked/free cells over integer world coordinates —
## the "grid-based navigation" half of tech_guidelines.md §3.4's collision
## contract. Sparse by design (a Dictionary of blocked cells, not a fixed
## width/height array): no real level exists yet (the graybox room lands
## in Pass 7), and a sparse grid needs no upfront bounds. Revisit only if
## profiling on a real level ever calls for it (tech_guidelines.md §11.1) —
## not before.
class_name CollisionGrid
extends RefCounted

var cell_size_mm: int
var _blocked: Dictionary = {}  ## Vector2i cell -> true


func _init(p_cell_size_mm: int) -> void:
	assert(p_cell_size_mm > 0, "CollisionGrid: cell_size_mm must be positive")
	cell_size_mm = p_cell_size_mm


## Floor division: GDScript's int `/` truncates toward zero (C semantics),
## which is wrong for a floor-based grid index when a coordinate is
## negative (e.g. -1mm at a 500mm cell size must map to cell -1, not 0).
static func _floor_div(a: int, b: int) -> int:
	var q: int = a / b
	if (a % b != 0) and ((a < 0) != (b < 0)):
		q -= 1
	return q


func world_to_cell(pos: Vector2i) -> Vector2i:
	return Vector2i(_floor_div(pos.x, cell_size_mm), _floor_div(pos.y, cell_size_mm))


func set_cell_blocked(cell: Vector2i, blocked: bool) -> void:
	if blocked:
		_blocked[cell] = true
	else:
		_blocked.erase(cell)


func is_cell_blocked(cell: Vector2i) -> bool:
	return _blocked.has(cell)


func is_position_blocked(pos: Vector2i) -> bool:
	return is_cell_blocked(world_to_cell(pos))


## The cell's world-space bounding box, as {"min": Vector2i, "max": Vector2i}.
func cell_aabb(cell: Vector2i) -> Dictionary:
	var min_corner := Vector2i(cell.x * cell_size_mm, cell.y * cell_size_mm)
	var max_corner := Vector2i(min_corner.x + cell_size_mm, min_corner.y + cell_size_mm)
	return {"min": min_corner, "max": max_corner}


static func _cell_less_than(a: Vector2i, b: Vector2i) -> bool:
	if a.x != b.x:
		return a.x < b.x
	return a.y < b.y


## Deterministic order (tech_guidelines.md §3.5): every blocked cell,
## sorted, so a sweep against "all blocked cells" never depends on
## Dictionary iteration order.
func blocked_cells() -> Array:
	var cells: Array = _blocked.keys()
	cells.sort_custom(_cell_less_than)
	return cells


func blocked_count() -> int:
	return _blocked.size()
