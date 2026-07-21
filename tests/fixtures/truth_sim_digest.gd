## Replaces StubSim (Pass 2, deleted here) as the determinism corpus's
## simulation target — real TruthSim itself, not a toy stand-in, now that
## it exists and (Pass 7+) has real collision/AI/Ground behavior worth a
## determinism guard. StubSim's own class doc always said as much: "Delete
## this file once TruthSim lands and point the corpus tests at that
## instead" — deferred at Pass 3 on the reasoning that a movement-only
## TruthSim with no walls had no more interesting divergence surface than
## StubSim already proved against (docs/dev_log.md's Pass 3 entry); real
## walls, real collision, and the Ground verb all exist now, so this
## finally does it (docs/review_and_forward_plan.md's F9).
##
## Lives under tests/fixtures/, not src/, for the same reason StubSim did:
## this is test/CI infrastructure, not part of the shipped game. The
## graybox room here is its own copy, not imported from
## tests/fixtures/graybox_room.gd or scenes/main.gd — a test fixture
## depending on the playable scene would be backwards, and
## graybox_room.gd's own class doc already calls itself disposable.
class_name TruthSimDigest
extends RefCounted

const CELL_SIZE_MM: int = 500
const ROOM_WIDTH_CELLS: int = 12
const ROOM_HEIGHT_CELLS: int = 8
const PLAYER_RADIUS_MM: int = 250
const PLAYER_START: Vector2i = Vector2i(3000, 2000)


static func _make_sim() -> TruthSim:
	var sim := TruthSim.new(CELL_SIZE_MM, PLAYER_START, PLAYER_RADIUS_MM)
	for x: int in range(-1, ROOM_WIDTH_CELLS + 1):
		sim.grid.set_cell_blocked(Vector2i(x, -1), true)
		sim.grid.set_cell_blocked(Vector2i(x, ROOM_HEIGHT_CELLS), true)
	for y: int in range(-1, ROOM_HEIGHT_CELLS + 1):
		sim.grid.set_cell_blocked(Vector2i(-1, y), true)
		sim.grid.set_cell_blocked(Vector2i(ROOM_WIDTH_CELLS, y), true)
	return sim


## Runs every frame of `replay` through a fresh TruthSim and returns a
## SHA-256 hex digest of the final state. The one property that matters,
## unchanged from StubSim: two calls given equal ReplayLogs must always
## return equal digests — that equality *is* what "deterministic replay"
## means for the mechanism this exercises (tech_guidelines.md §3, §9).
## Built from an explicit, hand-formatted string rather than
## JSON.stringify() on a Dictionary containing Vector2i values (unverified
## whether that round-trips predictably — an explicit format is exactly as
## easy to get right and carries no such doubt, the same "don't assume an
## untested Godot behavior" discipline this codebase has used throughout).
static func run_and_digest(replay: ReplayLog) -> String:
	var sim: TruthSim = _make_sim()
	for frame: InputFrame in replay.frames:
		sim.step(frame)
	var snapshot: Dictionary = sim.capture_percept_snapshot()

	var actor_parts: Array[String] = []
	for actor: Dictionary in snapshot["actors"] as Array:
		var pos: Vector2i = actor["position"]
		actor_parts.append(
			(
				"id=%d,pos=(%d,%d),hp=%d,alive=%s"
				% [actor["id"], pos.x, pos.y, actor["hit_points"], actor["is_alive"]]
			)
		)

	var state_text: String = (
		"frames=%d;seed=%d;content=%s;tick=%d;ground_uses=%d;actors=[%s]"
		% [
			replay.frames.size(),
			replay.run_seed,
			replay.content_version,
			snapshot["tick"],
			sim.ground_use_count(),
			";".join(PackedStringArray(actor_parts))
		]
	)
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(state_text.to_utf8_buffer())
	return ctx.finish().hex_encode()
