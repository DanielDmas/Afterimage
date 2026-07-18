## Line-of-sight over a CollisionGrid's occlusion data (tech_guidelines.md
## §3.4): "its own line-of-sight (Bresenham/DDA over the occlusion grid)".
## Reuses CollisionGrid's blocked-cell data as the occlusion source — wall
## geometry blocks both movement and vision, and maintaining two separate
## parallel grids for the same geometry would just be duplicated data
## with no behavioral upside.
##
## Deliberately does not include an angular vision cone (range + FOV
## angle): that's an AI-perception concern with no consumer until Sentry/
## Professional archetypes land (Pass 5), and building it before there's
## a caller to verify it against would be scope creep. This class answers
## exactly one question — "is anything blocking the straight line between
## these two points" — which is what both a vision check and other future
## systems (e.g. a bullet's path) actually need underneath.
class_name LineOfSight
extends RefCounted


## Enumerates every grid cell a line from `cell_a` to `cell_b` passes
## through, via Bresenham's line algorithm (integer-only, symmetric across
## all octants — the standard err/e2 formulation). Endpoints included.
## Verified against an executable Python reference before porting (see
## prng.gd's class doc for why that's the default here for anything with
## real arithmetic risk).
static func cells_along_line(cell_a: Vector2i, cell_b: Vector2i) -> Array:
	var cells: Array = []
	var x0: int = cell_a.x
	var y0: int = cell_a.y
	var x1: int = cell_b.x
	var y1: int = cell_b.y
	var dx: int = absi(x1 - x0)
	var dy: int = -absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy
	var x: int = x0
	var y: int = y0
	while true:
		cells.append(Vector2i(x, y))
		if x == x1 and y == y1:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy
	return cells


## True if the straight line from `pos_a` to `pos_b` is unobstructed by any
## blocked cell in `grid`. The two endpoints' own cells are exempted: an
## actor standing in a doorway (or anywhere else) shouldn't have their own
## occupied cell block their sightline — only cells strictly between the
## two matter.
static func has_clear_line(pos_a: Vector2i, pos_b: Vector2i, grid: CollisionGrid) -> bool:
	var cell_a: Vector2i = grid.world_to_cell(pos_a)
	var cell_b: Vector2i = grid.world_to_cell(pos_b)
	for cell: Vector2i in cells_along_line(cell_a, cell_b):
		if cell == cell_a or cell == cell_b:
			continue
		if grid.is_cell_blocked(cell):
			return false
	return true
