## The determinism-corpus target for the *full* pipeline (docs/forward_dev_plan.md
## Phase B's one item left open after MissionRuntime shipped: "a determinism-
## corpus fixture for a full MissionRuntime-driven run"). TruthSimDigest
## (this same directory) already proves the truth layer alone re-simulates
## hash-identical; this proves the same guarantee holds once
## MissionRuntime/DistortionDirector/MindModelEventBridge are wired in on
## top of it — the exact pipeline `scenes/main.gd` runs live.
##
## Reuses the real, already-committed `content/missions/m00_stub/mission.json`
## (via MissionLoader) rather than a synthetic deck, the same "prove it
## against real content" choice `test_mission_runtime.gd`'s own real-content
## test already made — and it costs nothing here: this is a self-consistency
## check (replay the same recorded run twice, the digest must match), not a
## pinned expected value, so it is not fragile against future content edits.
##
## The graybox room here is its own copy, not imported from scenes/main.gd
## or tests/fixtures/graybox_room.gd — TruthSimDigest's own class doc already
## explains why a test fixture depending on the playable scene would be
## backwards. `BUDGET_REGRANT_INTERVAL_TICKS` mirrors scenes/main.gd's own
## policy choice (§4.3 describes one lump sum per scene; a longer session
## re-grants on its own schedule) as an independent constant for the same
## reason, not an import.
class_name MissionRuntimeDigest
extends RefCounted

const CELL_SIZE_MM: int = 500
const ROOM_WIDTH_CELLS: int = 12
const ROOM_HEIGHT_CELLS: int = 8
const PLAYER_RADIUS_MM: int = 250
const PLAYER_START: Vector2i = Vector2i(3000, 2000)

const BUDGET_REGRANT_INTERVAL_TICKS: int = 300  # 10s at the fixed 30Hz tick rate

const MISSION_PACKAGE_PATH: String = "res://content/missions/m00_stub/mission.json"


static func _make_sim(event_bus: EventBus) -> TruthSim:
	var sim := TruthSim.new(CELL_SIZE_MM, PLAYER_START, PLAYER_RADIUS_MM, event_bus)
	for x: int in range(-1, ROOM_WIDTH_CELLS + 1):
		sim.grid.set_cell_blocked(Vector2i(x, -1), true)
		sim.grid.set_cell_blocked(Vector2i(x, ROOM_HEIGHT_CELLS), true)
	for y: int in range(-1, ROOM_HEIGHT_CELLS + 1):
		sim.grid.set_cell_blocked(Vector2i(-1, y), true)
		sim.grid.set_cell_blocked(Vector2i(ROOM_WIDTH_CELLS, y), true)
	return sim


## Runs every frame of `replay` through a fresh TruthSim + MissionRuntime and
## returns a SHA-256 hex digest of the final combined state — truth-layer
## (same fields TruthSimDigest hashes) plus the Director's entire purchase
## log plus whichever ops are still active at the end. `replay.run_seed`
## seeds the Director directly (MissionRuntime.new()'s own `seed` param) —
## the same value already carries the "this IS the deterministic seed for
## this recorded run" contract ReplayLog's own class doc states, extended
## here from the truth layer to the percept layer's purchase decisions.
## Built from an explicit, hand-formatted string, the same "don't assume
## JSON.stringify() round-trips a Vector2i-bearing Dictionary predictably"
## discipline TruthSimDigest already established.
static func run_and_digest(replay: ReplayLog) -> String:
	var event_bus := EventBus.new()
	var sim: TruthSim = _make_sim(event_bus)
	var mind := MindModel.new()
	var bridge := MindModelEventBridge.new(mind, event_bus)
	var package: MissionPackage = MissionLoader.load_from_file(MISSION_PACKAGE_PATH)
	var runtime := MissionRuntime.new(package, replay.run_seed, mind)

	var next_grant_tick: int = BUDGET_REGRANT_INTERVAL_TICKS
	for frame: InputFrame in replay.frames:
		sim.step(frame)
		var snapshot: Dictionary = sim.capture_percept_snapshot()
		var ground_just_completed: bool = bool(snapshot.get("ground_just_completed", false))
		var current_tick: int = sim.clock.current_tick
		if current_tick >= next_grant_tick:
			runtime.grant_scene_budget()
			next_grant_tick = current_tick + BUDGET_REGRANT_INTERVAL_TICKS
		runtime.step(current_tick, ground_just_completed)

	var final_snapshot: Dictionary = sim.capture_percept_snapshot()

	var actor_parts: Array[String] = []
	for actor: Dictionary in final_snapshot["actors"] as Array:
		var pos: Vector2i = actor["position"]
		actor_parts.append(
			(
				"id=%d,pos=(%d,%d),hp=%d,alive=%s"
				% [actor["id"], pos.x, pos.y, actor["hit_points"], actor["is_alive"]]
			)
		)

	var purchase_parts: Array[String] = []
	for record: Dictionary in runtime.director.purchase_log():
		purchase_parts.append(
			(
				"tick=%d,op_class=%s,tier=%d,cost=%d,deck_index=%d"
				% [
					record["tick"],
					record["op_class"],
					record["tier"],
					record["cost"],
					record["deck_index"]
				]
			)
		)

	var active_op_parts: Array[String] = []
	for op: DistortionOp in runtime.active_ops:
		active_op_parts.append(op.op_class)

	var state_text: String = (
		"frames=%d;seed=%d;content=%s;tick=%d;ground_uses=%d;actors=[%s];purchases=[%s];active_ops=[%s]"
		% [
			replay.frames.size(),
			replay.run_seed,
			replay.content_version,
			final_snapshot["tick"],
			sim.ground_use_count(),
			";".join(PackedStringArray(actor_parts)),
			";".join(PackedStringArray(purchase_parts)),
			",".join(PackedStringArray(active_op_parts)),
		]
	)
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(state_text.to_utf8_buffer())
	return ctx.finish().hex_encode()
