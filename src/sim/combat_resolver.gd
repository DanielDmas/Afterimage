## Pure resolution functions for the aim/fire/takedown/throw verbs
## (master_plan.md §4.9), reusing Pass 4/5's line-of-sight and vision-cone
## primitives rather than inventing new geometry: firing resolves as "is
## this actor within a narrow aim cone, in range, and unobstructed," not
## continuous ray physics — the same squared-distance/dot-product
## discipline VisionCone already established (no sqrt/atan2 in sim code,
## tech_guidelines §3.2).
##
## Noise-hearing (sprint, gunfire, thrown objects) uses a distance-only v1
## model here rather than SoundGraph's room/portal graph (Pass 4):
## SoundGraph needs an authored room layout to propagate through, and no
## real level exists until Pass 7's graybox room. This gives every noise
## source a working, testable open-air hearing check now; swapping it for
## room-aware propagation later is an additive change, not a rewrite — the
## same kind of deliberate deferral Pass 3's dev_log entry documents for
## the determinism corpus (which stayed on a disposable stand-in until
## Pass 7's graybox room gave TruthSim a real divergence surface worth
## guarding — done post-arc, docs/review_and_forward_plan.md F9).
class_name CombatResolver
extends RefCounted

## cos²(3°), Q16.16 — a tight "dead-on" aim cone for hitscan fire. Computed
## offline via cos(radians(3.0))**2 * 65536 = 65356.09..., rounded, and
## hardcoded rather than computed at runtime via
## VisionCone.cos_sq_half_angle_fx_from_degrees() — even a content-load-
## time transcendental call is avoided here, so firing never depends on a
## platform's libm agreeing bit-for-bit with the machine that recorded the
## replay (see prng.gd's class doc on "verify externally, then port" for
## anything with real arithmetic risk).
const AIM_COS_SQ_HALF_ANGLE_FX: int = 65356

const NOISE_RANGE_MM_PER_LOUDNESS_UNIT: int = 100
const TAKEDOWN_RANGE_MM: int = 900
const THROW_MAX_RANGE_MM: int = 6000
const THROW_NOISE_LOUDNESS: int = 40


## Picks the nearest target (by squared distance) that is within the aim
## cone, within `weapon`'s range, and unobstructed. `targets` is an Array
## of {"id": int, "position": Vector2i} (the same candidate shape
## WitnessSystem/AiAgent already use elsewhere in this codebase). Returns
## -1 if nothing qualifies.
static func resolve_fire(
	shooter_pos: Vector2i, aim_dir: Vector2i, weapon: Weapon, targets: Array, grid: CollisionGrid
) -> int:
	var best_id: int = -1
	var best_dist_sq: int = -1
	for target: Dictionary in targets:
		var pos: Vector2i = target["position"]
		if not VisionCone.point_in_cone(
			shooter_pos, aim_dir, AIM_COS_SQ_HALF_ANGLE_FX, weapon.max_range_mm, pos
		):
			continue
		if not LineOfSight.has_clear_line(shooter_pos, pos, grid):
			continue
		var d: Vector2i = pos - shooter_pos
		var dist_sq: int = d.x * d.x + d.y * d.y
		if best_id == -1 or dist_sq < best_dist_sq:
			best_id = int(target["id"])
			best_dist_sq = dist_sq
	return best_id


## Melee takedown: proximity (within TAKEDOWN_RANGE_MM) plus an
## unobstructed line to the target — no aim cone, since a takedown is
## resolved on whatever is right in front of the actor at contact range,
## not aimed at a distance.
static func resolve_takedown(
	actor_pos: Vector2i, target_pos: Vector2i, grid: CollisionGrid
) -> bool:
	var d: Vector2i = target_pos - actor_pos
	var dist_sq: int = d.x * d.x + d.y * d.y
	if dist_sq > TAKEDOWN_RANGE_MM * TAKEDOWN_RANGE_MM:
		return false
	return LineOfSight.has_clear_line(actor_pos, target_pos, grid)


## Clamps a thrown distraction object to THROW_MAX_RANGE_MM: over-range
## throws simply fail to land (no partial/clamped landing point — doing
## that exactly would need a sqrt-based vector normalization this codebase
## deliberately avoids in sim code, tech_guidelines §3.2) rather than being
## silently rejected without saying why.
static func resolve_throw(thrower_pos: Vector2i, target_pos: Vector2i) -> Dictionary:
	var d: Vector2i = target_pos - thrower_pos
	var dist_sq: int = d.x * d.x + d.y * d.y
	if dist_sq > THROW_MAX_RANGE_MM * THROW_MAX_RANGE_MM:
		return {"landed": false}
	return {"landed": true, "position": target_pos, "noise_loudness": THROW_NOISE_LOUDNESS}


static func hearing_range_mm(loudness: int) -> int:
	return maxi(loudness, 0) * NOISE_RANGE_MM_PER_LOUDNESS_UNIT


static func is_noise_heard_at(source_pos: Vector2i, listener_pos: Vector2i, loudness: int) -> bool:
	var range_mm: int = hearing_range_mm(loudness)
	if range_mm <= 0:
		return false
	var d: Vector2i = listener_pos - source_pos
	var dist_sq: int = d.x * d.x + d.y * d.y
	return dist_sq <= range_mm * range_mm
