## Ties one Actor to an AiArchetype: builds this tick's Perception from
## TruthSim/VisionCone/LineOfSight and hands it to AiUtility for a
## decision. Owns the small piece of state a *pure* utility function
## deliberately can't hold itself (memory of the last-known position, and
## whether sight was just newly acquired this tick — master_plan §5.5's
## "memory of last-known").
class_name AiAgent
extends RefCounted

var actor_id: int
var archetype: AiArchetype
var facing_dir: Vector2i
var current_state: AiUtility.State = AiUtility.State.PATROL

var _has_last_known: bool = false
var _last_known_position: Vector2i
var _was_seeing_last_tick: bool = false


func _init(p_actor_id: int, p_archetype: AiArchetype, p_facing_dir: Vector2i) -> void:
	actor_id = p_actor_id
	archetype = p_archetype
	facing_dir = p_facing_dir


func has_last_known_position() -> bool:
	return _has_last_known


func last_known_position() -> Vector2i:
	return _last_known_position


## Perceives the target from `self_pos` and updates current_state.
## `heard_noise` is supplied by the caller (e.g. from SoundGraph) rather
## than computed here, since this class has no room/portal context of
## its own.
func perceive_and_decide(
	self_pos: Vector2i, target_pos: Vector2i, grid: CollisionGrid, heard_noise: bool
) -> AiUtility.State:
	var can_see: bool = (
		VisionCone.point_in_cone(
			self_pos,
			facing_dir,
			archetype.vision_cos_sq_half_angle_fx,
			archetype.vision_range_mm,
			target_pos
		)
		and LineOfSight.has_clear_line(self_pos, target_pos, grid)
	)
	var just_spotted: bool = can_see and not _was_seeing_last_tick

	if can_see:
		_last_known_position = target_pos
		_has_last_known = true

	var perception := AiUtility.Perception.new()
	perception.can_see_target = can_see
	perception.has_last_known_position = _has_last_known
	perception.heard_noise = heard_noise
	perception.just_spotted = just_spotted and archetype.uses_report

	current_state = AiUtility.best_state(perception)
	_was_seeing_last_tick = can_see
	return current_state
