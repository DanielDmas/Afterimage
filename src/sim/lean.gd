## The lean/peek verb (master_plan.md §4.9): offsets the position
## LineOfSight queries are made *from*, sideways relative to facing,
## without moving the actor's own collision circle — the point of leaning
## is seeing more without taking on more movement-based collision
## exposure. Restricted to a cardinal facing direction, the same
## simplified facing model VisionCone/AiArchetype already assume
## elsewhere in this codebase: a 90° rotation of a cardinal unit vector is
## exact integer arithmetic (swap components, negate one), with no need
## for the general-rotation trig this codebase deliberately avoids in sim
## code (tech_guidelines §3.2).
##
## Which rotation direction is labeled LEFT vs. RIGHT is an arbitrary but
## fixed convention (90° counter-clockwise in world (x, y) coordinates is
## LEFT) — it is not calibrated against screen-space "left," since this
## class has no opinion on camera orientation. A future presentation
## layer wiring an actual lean control maps its own left/right input to
## whichever side of this convention looks correct on screen.
class_name Lean
extends RefCounted

enum Side { LEFT, RIGHT }


## `facing_dir` must be a unit cardinal direction (exactly one axis
## nonzero, magnitude 1) — asserted, since a diagonal or scaled facing has
## no single well-defined "90° lateral" answer under this simplified model.
##
## `side` is typed `int`, not `Side`, despite `Side` existing right above:
## a static method's parameter typed with its own class's bare (unqualified)
## inner-enum name does not unify, under Godot 4.3's static type checker,
## with the fully-qualified `Lean.Side` a caller in a different file
## necessarily writes — a real parse error CI caught ("Cannot pass a value
## of type 'Lean.Side' as 'Side'") that no local Godot editor could have
## surfaced first. Enums are plain ints underneath, so relaxing the
## parameter to `int` sidesteps the mismatch entirely while `Side.LEFT`/
## `Side.RIGHT` stay the named constants callers pass.
static func peek_origin(
	actor_pos: Vector2i, facing_dir: Vector2i, side: int, offset_mm: int
) -> Vector2i:
	assert(
		absi(facing_dir.x) + absi(facing_dir.y) == 1,
		"Lean.peek_origin: facing_dir must be a unit cardinal direction"
	)
	var left_unit := Vector2i(-facing_dir.y, facing_dir.x)  # 90 deg CCW
	var lateral_unit: Vector2i = left_unit if side == Side.LEFT else -left_unit
	return actor_pos + lateral_unit * offset_mm
