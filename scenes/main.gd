## The first playable slice, developed in two stages. Stage 1 (see
## docs/dev_log.md's "First playable scene" entry) proved a real graybox
## room driven by the actual TruthSim would run in a browser at all.
## Stage 2 (this revision, "the thesis demo" — docs/review_and_forward_plan.md
## P2/P3) closes the gaps that review found: the percept/truth seam is
## respected (rendering reads TruthSim.capture_percept_snapshot() through
## PerceptRenderer, never raw truth, so distortions have somewhere to
## attach), the Ground verb is wired end to end, one real scripted
## SubtitleDrift (DriftEncounter, src/integration/) fires on proximity and
## self-corrects on Ground, every InputFrame is recorded into a real
## ReplayLog, the EventBus is actually passed to TruthSim and subscribed
## to, and the disclosure at the end is backed by a genuine ReplayTheater
## re-simulation of the whole recorded session — not a cosmetic mockup.
##
## Every Godot API here was checked against the real 4.3 class docs before
## use (docs.godotengine.org, reachable from this sandbox even though the
## engine binary/export templates are not) — see the dev_log entry for the
## specific facts verified this way (renderer requirement, self-contained
## export template path, etc.) and Stage 2's own entry for this revision's
## additions (String.join()'s real PackedStringArray-only signature —
## Pass 19 avoided it for lack of verification, not because it's wrong;
## Control/ColorRect/InputMap.add_action() APIs).
extends Node2D

const CELL_SIZE_MM: int = 500
const ROOM_WIDTH_CELLS: int = 12
const ROOM_HEIGHT_CELLS: int = 8
const PLAYER_RADIUS_MM: int = 250
const PLAYER_START: Vector2i = Vector2i(3000, 2000)

## World mm -> screen px. Chosen so the room's full rendered extent,
## including its perimeter walls (7000x5000mm), fits inside the 640x360
## logical viewport (project.godot's window/stretch/mode="viewport") with
## visible margin for HUD text: 7000*0.06=420px, 5000*0.06=300px.
const PX_PER_MM: float = 0.06
const TICK_SECONDS: float = 1.0 / 30.0
const _BASE_TEXTURE_SIZE_PX: int = 8

## Centers the room's rendered extent in the 640x360 viewport (see
## PX_PER_MM's own comment for the arithmetic this satisfies).
const WORLD_OFFSET_PX: Vector2 = Vector2(140, 60)

const VIEWPORT_SIZE_PX: Vector2 = Vector2(640, 360)

## These four are ThemePalette's own art_direction.md §5 anchors, hand-
## converted from their hex source to float RGB rather than called via
## ThemePalette.color() — GDScript const initializers can't call static
## methods (see acute_stress_state.gd's own note on this, "consts can't
## call statics"), and this file's own established pattern is to hardcode
## the already-const-safe Color(r,g,b) form rather than risk an unverified
## const-folding edge case for a cosmetic value. Recomputed directly from
## ThemePalette's hex strings (verified against them, not eyeballed).
const _WALL_COLOR: Color = Color(0.478, 0.545, 0.435)  # municipal_green (§5)
const _PLAYER_COLOR: Color = Color(0.91, 0.58, 0.251)  # sodium_orange (§5)
const _BG_COLOR: Color = Color(0.102, 0.118, 0.165)  # night_base (§5)
const _PANEL_BG_COLOR: Color = Color(0.102, 0.118, 0.165, 0.92)  # night_base (§5), translucent
const _PANEL_TEXT_COLOR: Color = Color(0.867, 0.91, 0.863)  # fluorescent_white (§5)

var _sim: TruthSim
var _event_bus: EventBus
var _replay: ReplayLog
var _drift := DriftEncounter.new()

var _tick_accumulator: float = 0.0
var _ground_completions: int = 0

var _player_sprite: Sprite2D
var _tick_label: Label
var _subtitle_label: Label
var _ground_label: Label
var _reveal_panel: Control


func _ready() -> void:
	RenderingServer.set_default_clear_color(_BG_COLOR)
	_bind_input_keys()

	_event_bus = EventBus.new()
	_event_bus.subscribe("GroundCompleted", _on_ground_completed)
	_sim = _make_sim(_event_bus)
	_replay = ReplayLog.new(0, "afterimage-web-demo")

	_build_visuals()


## The InputMap actions Pass 6 declared (move_*, sprint, ...) were
## deliberately left with empty key bindings — that pass's own dev_log
## explains why: hand-authoring an InputEventKey resource literal in
## project.godot's text format risked a wrong keycode with no editor to
## catch it. Binding keys here in code sidesteps that risk entirely:
## GDScript's named KEY_* constants resolve at compile time, so there is
## no numeric literal to get wrong. "ground" has no project.godot entry at
## all yet (Pass 10 built the verb before Pass 6's InputMap existed for
## it) — added here too, the same way, rather than leaving it as a raw
## physical-key check with no remappable action behind it.
func _bind_input_keys() -> void:
	_bind_action_key("move_up", [KEY_UP, KEY_W])
	_bind_action_key("move_down", [KEY_DOWN, KEY_S])
	_bind_action_key("move_left", [KEY_LEFT, KEY_A])
	_bind_action_key("move_right", [KEY_RIGHT, KEY_D])
	_bind_action_key("sprint", [KEY_SHIFT])
	_bind_action_key("ground", [KEY_SPACE])


static func _bind_action_key(action: String, keycodes: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for keycode: int in keycodes:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action, event)


## Shared by both the live session and the Afterimage reveal's
## re-simulation (build_theater()'s scenario_factory) — the exact same
## room every time, so re-simulating from a recorded ReplayLog reproduces
## the live session tick-for-tick, per tech_guidelines.md §3.1's
## determinism contract.
static func _make_sim(event_bus: EventBus = null) -> TruthSim:
	var sim := TruthSim.new(CELL_SIZE_MM, PLAYER_START, PLAYER_RADIUS_MM, event_bus)
	_wall_perimeter(sim.grid)
	return sim


## A perimeter-walled room, matching tests/fixtures/graybox_room.gd's
## layout exactly (interior world coords roughly
## [0, ROOM_WIDTH_CELLS*CELL_SIZE_MM) x [0, ROOM_HEIGHT_CELLS*CELL_SIZE_MM)).
static func _wall_perimeter(grid: CollisionGrid) -> void:
	for x: int in range(-1, ROOM_WIDTH_CELLS + 1):
		grid.set_cell_blocked(Vector2i(x, -1), true)
		grid.set_cell_blocked(Vector2i(x, ROOM_HEIGHT_CELLS), true)
	for y: int in range(-1, ROOM_HEIGHT_CELLS + 1):
		grid.set_cell_blocked(Vector2i(-1, y), true)
		grid.set_cell_blocked(Vector2i(ROOM_WIDTH_CELLS, y), true)


static func _solid_texture(color: Color) -> ImageTexture:
	var image: Image = Image.create_empty(
		_BASE_TEXTURE_SIZE_PX, _BASE_TEXTURE_SIZE_PX, false, Image.FORMAT_RGBA8
	)
	image.fill(color)
	return ImageTexture.create_from_image(image)


## Every wall cell and the player are Sprite2D nodes (world-space,
## CanvasItem, same coordinate model as this scene's own Node2D root)
## scaled from one shared 8x8 solid-color base texture per color, never
## per-node — programmer-art placeholders, real content deferred, the
## same discipline art_direction.md's document set has assumed throughout
## this engineering arc. HUD text/panels below use Control nodes (Label,
## ColorRect) instead, since screen-space UI is exactly what Control is
## for — the two node families are used for what each is actually good
## at, not mixed within either role.
func _build_visuals() -> void:
	var wall_texture: ImageTexture = _solid_texture(_WALL_COLOR)
	for cell: Vector2i in _sim.grid.blocked_cells():
		var aabb: Dictionary = _sim.grid.cell_aabb(cell)
		var wall := Sprite2D.new()
		wall.texture = wall_texture
		wall.position = _mm_to_px((aabb["min"] + aabb["max"]) / 2)
		var size_px: Vector2 = _mm_to_px_extent(aabb["max"] - aabb["min"])
		wall.scale = size_px / _BASE_TEXTURE_SIZE_PX
		add_child(wall)

	_player_sprite = Sprite2D.new()
	_player_sprite.texture = _solid_texture(_PLAYER_COLOR)
	var player_size_px: Vector2 = _mm_to_px_extent(
		Vector2i(PLAYER_RADIUS_MM * 2, PLAYER_RADIUS_MM * 2)
	)
	_player_sprite.scale = player_size_px / _BASE_TEXTURE_SIZE_PX
	add_child(_player_sprite)

	_tick_label = Label.new()
	_tick_label.position = Vector2(4, 4)
	add_child(_tick_label)

	_ground_label = Label.new()
	_ground_label.position = Vector2(4, 20)
	add_child(_ground_label)

	_subtitle_label = Label.new()
	_subtitle_label.position = Vector2(0, 335)
	_subtitle_label.size = Vector2(VIEWPORT_SIZE_PX.x, 24)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_subtitle_label)

	_update_visuals()


## The fixed-tick accumulator pattern tech_guidelines.md §3.1 requires:
## TruthSim.step() advances in whole 1/30s ticks regardless of the
## engine's actual frame rate, so movement replays identically at 30fps or
## 300fps. Input is sampled fresh for every elapsed tick this frame (never
## once per rendered frame), matching the determinism contract exactly.
## Stops ticking once the drift encounter is revealed — this is a bounded
## demo, not an open-ended session, and freezing on the reveal keeps its
## disclosure panel the clear final beat rather than something the player
## wanders away from mid-read.
func _physics_process(delta: float) -> void:
	if _drift.is_revealed():
		return
	_tick_accumulator += delta
	while _tick_accumulator >= TICK_SECONDS:
		_tick_accumulator -= TICK_SECONDS
		_step_sim()
	_update_visuals()


func _step_sim() -> void:
	var dir := Vector2i(
		(
			(1 if Input.is_action_pressed("move_right") else 0)
			- (1 if Input.is_action_pressed("move_left") else 0)
		),
		(
			(1 if Input.is_action_pressed("move_down") else 0)
			- (1 if Input.is_action_pressed("move_up") else 0)
		)
	)
	var sprinting: bool = Input.is_action_pressed("sprint")
	var grounding: bool = Input.is_action_pressed("ground")
	var mode: MovementProfile.Mode = (
		MovementProfile.Mode.SPRINT if sprinting else MovementProfile.Mode.WALK
	)
	var delta_mm: Vector2i = MovementProfile.resolve_delta(dir, mode)
	var frame := InputFrame.new(
		_replay.frame_count() + 1,
		{"move_x": delta_mm.x, "move_y": delta_mm.y, "sprinting": sprinting, "ground": grounding}
	)
	_replay.record(frame)
	_sim.step(frame)

	var snapshot: Dictionary = _sim.capture_percept_snapshot()
	_drift.maybe_trigger(_sim.player_position(), _sim.clock.current_tick)
	_drift.advance(_sim.clock.current_tick, bool(snapshot.get("ground_just_completed", false)))
	if _drift.is_revealed():
		_show_reveal_panel()


func _on_ground_completed(_event: Dictionary) -> void:
	_ground_completions += 1


func _update_visuals() -> void:
	var truth_snapshot: Dictionary = _sim.capture_percept_snapshot()
	var active_ops: Array = []
	if _drift.is_active():
		truth_snapshot["subtitle"] = _drift.subtitle_truth_fact()
		active_ops = [_drift.op]
	var percept: Dictionary = PerceptRenderer.render(truth_snapshot, active_ops)

	var pos_mm: Vector2i = _sim.player_position()
	_player_sprite.position = _mm_to_px(pos_mm)
	_tick_label.text = "tick %d   pos (%d, %d) mm" % [_sim.clock.current_tick, pos_mm.x, pos_mm.y]
	_ground_label.text = (
		"[Space] hold to Ground — resolved %d" % _ground_completions
		if not _sim.is_grounding()
		else "GROUNDING..."
	)

	if percept.has("subtitle"):
		_subtitle_label.text = '"%s"' % percept["subtitle"]["rendered_text"]
	else:
		_subtitle_label.text = ""


## The disclosure: builds a real ReplayTheater re-simulation of the whole
## recorded session (proving the tick-perfect reconstruction mechanism
## against a genuinely long, freely-played session for the first time —
## every prior use was a short fixed scenario) and shows what was
## actually true against what the subtitle rendered, Charter rule 5
## ("everything is disclosable") made concrete.
func _show_reveal_panel() -> void:
	if _reveal_panel != null:
		return

	var span := OpTimelineSpan.new(
		_drift.op.op_class,
		_drift.op.tier,
		"acute_stress",
		_drift.start_tick,
		_drift.start_tick + DriftEncounter.DISPLAY_DURATION_TICKS
	)
	var spans: Array[OpTimelineSpan] = [span]
	var theater := ReplayTheater.new(_scenario_factory(), _replay, spans)
	var reconstructed: Dictionary = theater.truth_view_at(_drift.start_tick)
	var reconstructed_player: Dictionary = _find_actor(reconstructed["actors"], _sim.player_id)

	_reveal_panel = Control.new()
	_reveal_panel.position = Vector2.ZERO
	_reveal_panel.size = VIEWPORT_SIZE_PX
	add_child(_reveal_panel)

	var backdrop := ColorRect.new()
	backdrop.position = Vector2.ZERO
	backdrop.size = VIEWPORT_SIZE_PX
	backdrop.color = _PANEL_BG_COLOR
	_reveal_panel.add_child(backdrop)

	var lines: PackedStringArray = PackedStringArray(
		[
			"THE AFTERIMAGE",
			"",
			'You heard: "%s"' % DriftEncounter.DRIFTED_TEXT,
			'Truth:     "%s"' % DriftEncounter.TRUE_TEXT,
			"",
			(
				"Grounded in the moment: %s"
				% ("yes" if _drift.was_grounded else "no — disclosed anyway")
			),
			(
				"Reconstructed from the replay: tick %d, you were at (%d, %d)"
				% [
					_drift.start_tick,
					reconstructed_player["position"].x,
					reconstructed_player["position"].y
				]
			),
		]
	)
	var text_label := Label.new()
	text_label.position = Vector2(24, 100)
	text_label.size = Vector2(VIEWPORT_SIZE_PX.x - 48, 160)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.add_theme_color_override("font_color", _PANEL_TEXT_COLOR)
	text_label.text = "\n".join(lines)
	_reveal_panel.add_child(text_label)


static func _find_actor(actors: Array, id: int) -> Dictionary:
	for actor: Dictionary in actors:
		if actor["id"] == id:
			return actor
	return {}


static func _scenario_factory() -> Callable:
	return func() -> TruthSim: return _make_sim()


static func _mm_to_px(v: Vector2i) -> Vector2:
	return Vector2(v.x, v.y) * PX_PER_MM + WORLD_OFFSET_PX


## For sizes/extents (no world-position offset should apply).
static func _mm_to_px_extent(v: Vector2i) -> Vector2:
	return Vector2(v.x, v.y) * PX_PER_MM
