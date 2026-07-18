## Angular field-of-view test for AI perception (master_plan.md §5.5:
## "vision cones") — the piece deliberately deferred out of Pass 4 until
## it had a real consumer (Sentry/Professional AI, this pass). Combines
## with LineOfSight.has_clear_line() for the full "can this observer see
## that point" query; this class only answers "is the point within range
## and within the facing angle," with no occlusion test of its own.
##
## Avoids atan2()/sqrt() entirely (tech_guidelines.md §3.2's "no ad-hoc
## float math in sim code") via squared dot-product comparison: for
## non-negative dot products, `dot(a,b)/(|a||b|) >= cos(theta)` is
## equivalent to `dot(a,b)^2 >= |a|^2 |b|^2 cos^2(theta)`, which needs only
## integer multiplication. This is why `cos_sq_half_angle_fx` — cos²(half
## angle), Q16.16 — is the parameter, not an angle in degrees; converting
## an authored half-angle to that value (via cos(), a transcendental
## function) happens once at content-load time, analogous to
## tech_guidelines §3.1's "durations authored in seconds are converted to
## ticks at load, once" — never per-tick in the hot path.
##
## Supported range: half-angle < 90° (total FOV < 180°). The dot<=0 early
## return assumes this; every vision archetype in this game's design is
## well under that bound (master_plan.md §4.9's enemy archetypes), so it
## is a documented contract, not a silent limitation.
##
## `facing_dir` must be a small-magnitude direction vector (a per-tick
## movement delta or a similarly bounded authored facing, not a raw
## world-space displacement): the arithmetic below keeps every
## intermediate product inside int64 range for realistic level sizes
## (up to ~100m per axis) only while `|facing_dir.x|, |facing_dir.y| <=
## FACING_COMPONENT_MAX`. Enforced by an assert rather than left as a
## silent overflow risk. Bound derived numerically (not guessed) for the
## worst case; see prng.gd's class doc for why "verify externally, then
## port" is the default here for anything with real arithmetic risk.
class_name VisionCone
extends RefCounted

## Comfortably covers any plausible per-tick facing/movement delta (a
## dash of 10,000 mm in a single 1/30s tick is 300 m/s — far beyond any
## authored gameplay speed) while keeping facing_sq * scaled_dist_sq
## inside int64 range for a ~100m-per-axis level.
const FACING_COMPONENT_MAX: int = 10000


static func point_in_cone(
	observer_pos: Vector2i,
	facing_dir: Vector2i,
	cos_sq_half_angle_fx: int,
	range_mm: int,
	target_pos: Vector2i
) -> bool:
	assert(
		absi(facing_dir.x) <= FACING_COMPONENT_MAX and absi(facing_dir.y) <= FACING_COMPONENT_MAX,
		"VisionCone.point_in_cone: facing_dir component exceeds FACING_COMPONENT_MAX"
	)
	var to_target: Vector2i = target_pos - observer_pos
	var dist_sq: int = to_target.x * to_target.x + to_target.y * to_target.y
	if dist_sq > range_mm * range_mm:
		return false

	var dot: int = facing_dir.x * to_target.x + facing_dir.y * to_target.y
	if dot <= 0:
		return false  # behind (or exactly perpendicular); see class doc's FOV contract

	var facing_sq: int = facing_dir.x * facing_dir.x + facing_dir.y * facing_dir.y
	var rhs: int = facing_sq * FixedMath.mul(dist_sq, cos_sq_half_angle_fx)
	var lhs: int = dot * dot
	return lhs >= rhs


## Converts an authored half-angle (degrees) to the Q16.16 cos² value
## point_in_cone() expects. Content-authoring-time only — uses cos(), a
## transcendental function, which is fine here precisely because it never
## runs in the per-tick hot path (see class doc).
static func cos_sq_half_angle_fx_from_degrees(half_angle_degrees: float) -> int:
	var c: float = cos(deg_to_rad(half_angle_degrees))
	return FixedMath.from_float(c * c)
