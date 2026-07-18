## Swept circle-vs-AABB collision (tech_guidelines.md §3.4) via the
## Minkowski-sum slab method: the static box is expanded by the moving
## circle's radius, then the circle's *center* is swept as a point against
## that expanded box. This treats the box's rounded corners as square
## corners — a deliberate, documented simplification (a true rounded-corner
## sweep needs a quadratic/sqrt solve per corner, which buys very little
## for a top-down action game's collision feel over the square-corner
## approximation). Actor-vs-actor collision only needs a *static* overlap
## test for now (circles_overlap) — true swept circle-vs-moving-circle
## collision is deferred until multiple simultaneously-moving bodies
## actually need it (AI in Pass 5+), not built ahead of that need.
##
## All arithmetic verified against an executable Python reference (exact
## Fraction math) before being ported — see prng.gd's class doc for why
## this project treats "verify externally, then port" as the default for
## anything with real arithmetic risk, not just the PRNG.
class_name SweptCollision
extends RefCounted

## Returned when the swept circle never touches the box within this
## tick's movement (t would be < 0, > ONE, or the slabs never overlap).
const NO_HIT: int = -1

## Stands in for +/- infinity in the per-axis t bounds below. Any real t
## this sim produces stays within a tiny range around [0, ONE] for
## realistic per-tick deltas, so a value this large can never be mistaken
## for a genuine bound.
const _T_SENTINEL: int = 1 << 36


## Returns the Q16.16 fraction of `delta` (in [0, FixedMath.ONE]) at which
## a circle of `radius_mm` centered at `p0` first touches the AABB
## [box_min, box_max] while moving by `delta` this tick, or NO_HIT.
static func circle_vs_aabb_swept(
	p0: Vector2i, radius_mm: int, delta: Vector2i, box_min: Vector2i, box_max: Vector2i
) -> int:
	if delta == Vector2i.ZERO:
		# Nothing to sweep. A pre-existing overlap (if it can even arise)
		# is a separate static-query concern, not this function's job.
		return NO_HIT

	var exp_min := Vector2i(box_min.x - radius_mm, box_min.y - radius_mm)
	var exp_max := Vector2i(box_max.x + radius_mm, box_max.y + radius_mm)

	var t_enter: int = -_T_SENTINEL
	var t_exit: int = _T_SENTINEL

	for axis: int in range(2):
		var p: int = p0.x if axis == 0 else p0.y
		var d: int = delta.x if axis == 0 else delta.y
		var lo: int = exp_min.x if axis == 0 else exp_min.y
		var hi: int = exp_max.x if axis == 0 else exp_max.y

		if d == 0:
			if p < lo or p > hi:
				return NO_HIT  # parallel to this slab and outside it: never hits
			# else: unconstrained on this axis, t_enter/t_exit untouched
		else:
			var t1: int = FixedMath.div(FixedMath.from_int(lo - p), FixedMath.from_int(d))
			var t2: int = FixedMath.div(FixedMath.from_int(hi - p), FixedMath.from_int(d))
			var axis_enter: int = mini(t1, t2)
			var axis_exit: int = maxi(t1, t2)
			t_enter = maxi(t_enter, axis_enter)
			t_exit = mini(t_exit, axis_exit)

	if t_enter > t_exit:
		return NO_HIT
	if t_exit < 0:
		return NO_HIT
	if t_enter > FixedMath.ONE:
		return NO_HIT
	return maxi(t_enter, 0)


## Static (non-swept) overlap test between two circles — exact integer
## arithmetic via squared distance, no sqrt, no float, ever.
static func circles_overlap(p0: Vector2i, r0: int, p1: Vector2i, r1: int) -> bool:
	var dx: int = p1.x - p0.x
	var dy: int = p1.y - p0.y
	var dist_sq: int = dx * dx + dy * dy
	var combined_r: int = r0 + r1
	return dist_sq < combined_r * combined_r


## Resolves a requested move against every blocked cell in `grid`,
## returning the actor's safe new position: the full move if nothing
## blocks it, or clamped to just short of the earliest impact along the
## path. Iterates every currently-blocked cell (no spatial broad-phase) —
## an appropriately-scoped choice while levels are small/nonexistent
## (Pass 7 graybox); revisit only once profiling on a real level calls
## for it (tech_guidelines.md §11.1).
static func move_with_collision(
	p0: Vector2i, radius_mm: int, delta: Vector2i, grid: CollisionGrid
) -> Vector2i:
	if delta == Vector2i.ZERO:
		return p0

	var earliest_t: int = FixedMath.ONE
	var hit_found: bool = false
	for cell: Vector2i in grid.blocked_cells():
		var box: Dictionary = grid.cell_aabb(cell)
		var t: int = circle_vs_aabb_swept(p0, radius_mm, delta, box["min"], box["max"])
		if t != NO_HIT and t < earliest_t:
			earliest_t = t
			hit_found = true

	if not hit_found:
		return p0 + delta

	# Truncate toward zero per axis so the stop point never overshoots
	# past the impact boundary in either movement direction (flooring a
	# negative component would move *further* negative, not less).
	var moved_x: int = FixedMath.to_int_trunc(
		FixedMath.mul(FixedMath.from_int(delta.x), earliest_t)
	)
	var moved_y: int = FixedMath.to_int_trunc(
		FixedMath.mul(FixedMath.from_int(delta.y), earliest_t)
	)
	return Vector2i(p0.x + moved_x, p0.y + moved_y)
