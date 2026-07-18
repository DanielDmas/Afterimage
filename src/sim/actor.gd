## A truth-layer body: an entity with a position and a collision circle
## (master_plan.md §5.2 ActorSystem — "player+AI bodies, physics-lite").
## Positions are plain integer millimeters (tech_guidelines.md D4/§3.2),
## never Q16.16 fixed values — see fixed_math.gd's class doc for why.
class_name Actor
extends RefCounted

var id: int
var position: Vector2i
var radius_mm: int


func _init(p_id: int, p_position: Vector2i, p_radius_mm: int) -> void:
	id = p_id
	position = p_position
	radius_mm = p_radius_mm
