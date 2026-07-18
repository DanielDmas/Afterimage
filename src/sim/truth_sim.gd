## The truth-layer simulation (master_plan.md §5.2): fixed-tick, integer-
## only, engine-agnostic. Pass 3 scope is deliberately narrow — one
## player-controlled Actor, collision-resolved movement, no AI, no
## combat, no witnesses yet (those are Pass 5/6/4 respectively). This is
## the foundation those passes build onto, not a placeholder to be
## replaced: TruthSim.step() will keep this exact signature (advance one
## tick from one InputFrame) as more systems plug into it.
class_name TruthSim
extends RefCounted

var clock: FixedTickClock
var grid: CollisionGrid
var actors: ActorRegistry
var player_id: int

var _event_bus: EventBus


func _init(
	cell_size_mm: int, start_position: Vector2i, player_radius_mm: int, event_bus: EventBus = null
) -> void:
	clock = FixedTickClock.new()
	grid = CollisionGrid.new(cell_size_mm)
	actors = ActorRegistry.new()
	player_id = actors.spawn_actor(start_position, player_radius_mm)
	_event_bus = event_bus


## Advances the sim by exactly one tick, applying one InputFrame. Reads
## "move_x"/"move_y" as a raw per-tick millimeter delta request — turning
## player intent (a direction, a speed) into that delta is a combat-verb
## concern (Pass 6), not this layer's; TruthSim only ever sees "move by
## this many mm, resolved against collision."
func step(frame: InputFrame) -> void:
	clock.advance()
	var dx: int = int(frame.inputs.get("move_x", 0))
	var dy: int = int(frame.inputs.get("move_y", 0))
	var delta := Vector2i(dx, dy)
	if delta == Vector2i.ZERO:
		return

	var actor: Actor = actors.get_actor(player_id)
	var new_pos: Vector2i = SweptCollision.move_with_collision(
		actor.position, actor.radius_mm, delta, grid
	)
	if new_pos == actor.position:
		return
	actor.position = new_pos
	if _event_bus:
		_event_bus.publish(
			"ActorMoved", {"id": player_id, "position": new_pos}, null, clock.current_tick
		)


func run_replay(replay: ReplayLog) -> void:
	for frame: InputFrame in replay.frames:
		step(frame)


func player_position() -> Vector2i:
	return actors.get_actor(player_id).position
