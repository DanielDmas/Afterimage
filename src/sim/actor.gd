## A truth-layer body: an entity with a position and a collision circle
## (master_plan.md §5.2 ActorSystem — "player+AI bodies, physics-lite").
## Positions are plain integer millimeters (tech_guidelines.md D4/§3.2),
## never Q16.16 fixed values — see fixed_math.gd's class doc for why.
##
## `hit_points`/`facing_dir` (Pass 7) are plain public fields, not wrapped
## in their own class, for the same reason `position`/`radius_mm` already
## aren't: master_plan §4.9's damage model ("2-4 hits"/"1-3 hits") is a
## tuning question for real playtesting, not a system this pass needs to
## over-engineer ahead of that data existing.
class_name Actor
extends RefCounted

var id: int
var position: Vector2i
var radius_mm: int
var hit_points: int
var facing_dir: Vector2i


func _init(
	p_id: int,
	p_position: Vector2i,
	p_radius_mm: int,
	p_hit_points: int = 1,
	p_facing_dir: Vector2i = Vector2i(1, 0)
) -> void:
	id = p_id
	position = p_position
	radius_mm = p_radius_mm
	hit_points = p_hit_points
	facing_dir = p_facing_dir


func is_alive() -> bool:
	return hit_points > 0


## Clamps at zero — damage past a kill doesn't go negative (matters for
## any future "how much overkill" query, and just for hygiene).
func apply_damage(amount: int) -> void:
	hit_points = maxi(hit_points - amount, 0)
