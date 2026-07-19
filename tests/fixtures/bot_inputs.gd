## Simple scripted InputFrame generators for a "does the wiring survive a
## soak" bot harness v0 (master_plan.md §9: "headless bots... soak combat
## for crashes"). These are deliberately NOT the paranoid/credulous bots
## master_plan actually describes — those specifically probe Ground usage
## (§4.6/§9), and Ground doesn't exist before Pass 10. Named for what they
## actually do here instead: "aggressive" always closes distance and
## fires whenever it has a nonzero aim vector; "cautious" always retreats
## and never fires. The real paranoid/credulous pair is deferred to
## whichever pass gives Ground a consumer — the same "no consumer yet"
## discipline as every prior deferral in this log.
class_name BotInputs
extends RefCounted


## Walks (not sprints — sprint's whole point is noise, and this bot
## doesn't need extra tells for a soak test) one step toward
## `target_pos` and fires toward it whenever not exactly overlapping it.
static func aggressive_frame(tick: int, self_pos: Vector2i, target_pos: Vector2i) -> InputFrame:
	var delta: Vector2i = MovementProfile.resolve_delta(
		_step_direction(self_pos, target_pos), MovementProfile.Mode.WALK
	)
	var aim_dir: Vector2i = _clamped_direction(self_pos, target_pos)
	return (
		InputFrame
		. new(
			tick,
			{
				"move_x": delta.x,
				"move_y": delta.y,
				"aim_dir": aim_dir,
				"fire": aim_dir != Vector2i.ZERO,
			}
		)
	)


## Walks one step away from `target_pos` and never fires.
static func cautious_frame(tick: int, self_pos: Vector2i, target_pos: Vector2i) -> InputFrame:
	var delta: Vector2i = MovementProfile.resolve_delta(
		_step_direction(target_pos, self_pos), MovementProfile.Mode.WALK
	)
	return InputFrame.new(tick, {"move_x": delta.x, "move_y": delta.y})


static func _step_direction(from_pos: Vector2i, to_pos: Vector2i) -> Vector2i:
	var d: Vector2i = to_pos - from_pos
	return Vector2i(signi(d.x), signi(d.y))


static func _clamped_direction(from_pos: Vector2i, to_pos: Vector2i) -> Vector2i:
	var d: Vector2i = to_pos - from_pos
	return Vector2i(
		clampi(d.x, -VisionCone.FACING_COMPONENT_MAX, VisionCone.FACING_COMPONENT_MAX),
		clampi(d.y, -VisionCone.FACING_COMPONENT_MAX, VisionCone.FACING_COMPONENT_MAX)
	)
