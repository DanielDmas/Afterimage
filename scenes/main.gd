## The first playable slice, developed in three stages. Stage 1 (see
## docs/dev_log.md's "First playable scene" entry) proved a real graybox
## room driven by the actual TruthSim would run in a browser at all.
## Stage 2 ("the thesis demo" — docs/review_and_forward_plan.md P2/P3)
## closed the gaps that review found: the percept/truth seam is respected
## (rendering reads TruthSim.capture_percept_snapshot() through
## PerceptRenderer, never raw truth), the Ground verb is wired end to
## end, every InputFrame is recorded into a real ReplayLog, and the
## disclosure at the end is backed by a genuine ReplayTheater
## re-simulation. Stage 3 (this revision, "make it actually playable" —
## the user's own framing: "play it from the position of a curious and
## smart player... make it fun and enjoyable... engaging") is a player-
## experience pass over that same real mechanism, not a new one: a second,
## visually distinct distortion (a PhantomEntity sighting, alongside the
## original SubtitleDrift) so the demo shows two different kinds of lie
## instead of one; a player-chosen objective (a marked exit) instead of an
## invisible proximity timer deciding when the session ends; an onboarding
## hint (nothing told the player Ground existed before this); visual
## feedback while holding Ground (a vignette that ramps with the real
## hold duration, GroundState.DURATION_TICKS); and a restart loop, since a
## demo that dead-ends at the reveal panel forever is not "nicely
## playable" — the reveal is a beat, not the end of the process. None of
## this is a new mechanism: it is the same TruthSim/PerceptRenderer/
## DriftEncounter/ReplayTheater machinery Stage 2 already proved, staged
## and paced like something a stranger would actually enjoy running
## through.
##
## Every Godot API here was checked against the real 4.3 class docs before
## use (docs.godotengine.org, reachable from this sandbox even though the
## engine binary/export templates are not) — see the dev_log entry for
## the specific facts verified this way. Stage 3 additionally verified
## Node.create_tween()/Tween.tween_property()'s exact signatures (the
## phantom's "shimmers and dissolves" fade) before use, since no earlier
## pass in this codebase had used Tween at all.
extends Node2D

const CELL_SIZE_MM: int = 500
const ROOM_WIDTH_CELLS: int = 12
const ROOM_HEIGHT_CELLS: int = 8
const PLAYER_RADIUS_MM: int = 250
const PLAYER_START: Vector2i = Vector2i(3000, 2000)

const EXIT_POSITION_MM: Vector2i = Vector2i(5600, 3600)
const EXIT_RADIUS_MM: int = 400

const GROUND_VIGNETTE_MAX_ALPHA: float = 0.35
const PHANTOM_DISSOLVE_SECONDS: float = 1.0  # master_plan.md §4.2: "~1 s"

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

## ThemePalette's own art_direction.md §5 anchors, hand-converted from
## their hex source to float RGB rather than called via
## ThemePalette.color() — GDScript const initializers can't call static
## methods (see acute_stress_state.gd's own note on this, "consts can't
## call statics"). Recomputed directly from ThemePalette's hex strings
## (verified against them, not eyeballed).
const _WALL_COLOR: Color = Color(0.478, 0.545, 0.435)  # municipal_green (§5)
const _PLAYER_COLOR: Color = Color(0.91, 0.58, 0.251)  # sodium_orange (§5)
const _BG_COLOR: Color = Color(0.102, 0.118, 0.165)  # night_base (§5)
const _PANEL_BG_COLOR: Color = Color(0.102, 0.118, 0.165, 0.92)  # night_base (§5), translucent
const _PANEL_TEXT_COLOR: Color = Color(0.867, 0.91, 0.863)  # fluorescent_white (§5)
const _PHANTOM_COLOR: Color = Color(0.494, 0.176, 0.149)  # blood (§5) — the one op you can see
const _EXIT_COLOR: Color = Color(0.247, 0.722, 0.686)  # club_teal (§5) — the only inviting color

var _sim: TruthSim
var _event_bus: EventBus
var _replay: ReplayLog
var _drift: DriftEncounter
var _phantom: PhantomEncounter

var _tick_accumulator: float = 0.0
var _ground_completions: int = 0
var _ground_hold_ticks: int = 0
var _session_ended: bool = false

var _world_root: Node2D
var _player_sprite: Sprite2D
var _phantom_sprite: Sprite2D
var _ground_vignette: ColorRect
var _tick_label: Label
var _ground_label: Label
var _hint_label: Label
var _objective_label: Label
var _clarity_label: Label
var _subtitle_label: Label
var _reveal_panel: Control


func _ready() -> void:
	RenderingServer.set_default_clear_color(_BG_COLOR)
	_bind_input_keys()

	_world_root = Node2D.new()
	add_child(_world_root)
	_build_hud()
	_start_new_session()


## The InputMap actions Pass 6 declared (move_*, sprint, ...) were
## deliberately left with empty key bindings — that pass's own dev_log
## explains why: hand-authoring an InputEventKey resource literal in
## project.godot's text format risked a wrong keycode with no editor to
## catch it. Binding keys here in code sidesteps that risk entirely.
## "ground" and "restart" are added the same way — neither had a
## project.godot entry before the pass that first needed it. Called once
## from _ready(), never on restart: InputMap actions are process-global,
## not session state.
func _bind_input_keys() -> void:
	_bind_action_key("move_up", [KEY_UP, KEY_W])
	_bind_action_key("move_down", [KEY_DOWN, KEY_S])
	_bind_action_key("move_left", [KEY_LEFT, KEY_A])
	_bind_action_key("move_right", [KEY_RIGHT, KEY_D])
	_bind_action_key("sprint", [KEY_SHIFT])
	_bind_action_key("ground", [KEY_SPACE])
	_bind_action_key("restart", [KEY_ENTER])


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


## The screen-space overlay: HUD labels and the Ground vignette, built
## exactly once and never rebuilt on restart (unlike the room itself,
## none of this is session state). Added to `self` (not `_world_root`),
## and in this exact order, so draw order — CanvasItem children draw in
## tree order regardless of Node2D vs Control, already proven by Stage
## 2's labels sitting correctly on top of the room's Sprite2D walls —
## keeps the vignette above the world but every label above the
## vignette, so HUD text never loses contrast under it.
func _build_hud() -> void:
	_ground_vignette = ColorRect.new()
	_ground_vignette.position = Vector2.ZERO
	_ground_vignette.size = VIEWPORT_SIZE_PX
	_ground_vignette.color = Color(
		_PANEL_TEXT_COLOR.r, _PANEL_TEXT_COLOR.g, _PANEL_TEXT_COLOR.b, 0.0
	)
	add_child(_ground_vignette)

	_tick_label = Label.new()
	_tick_label.position = Vector2(4, 4)
	add_child(_tick_label)

	_ground_label = Label.new()
	_ground_label.position = Vector2(4, 20)
	add_child(_ground_label)

	_hint_label = Label.new()
	_hint_label.position = Vector2(4, 36)
	_hint_label.text = "WASD/Arrows move  ·  Shift sprint  ·  hold SPACE to Ground"
	add_child(_hint_label)

	_objective_label = Label.new()
	_objective_label.position = Vector2(4, 52)
	_objective_label.text = "Objective: reach the teal door, bottom-right"
	add_child(_objective_label)

	_clarity_label = Label.new()
	_clarity_label.position = Vector2(4, 68)
	add_child(_clarity_label)

	_subtitle_label = Label.new()
	_subtitle_label.position = Vector2(0, 335)
	_subtitle_label.size = Vector2(VIEWPORT_SIZE_PX.x, 24)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_subtitle_label)


## Resets every piece of session state and rebuilds the room fresh — the
## restart loop this stage added, since freezing forever at the reveal
## panel (Stage 2's behavior) is a dead end, not "nicely playable." Called
## once from _ready() and again every time the player presses Enter after
## reaching the reveal panel.
func _start_new_session() -> void:
	for child: Node in _world_root.get_children():
		child.queue_free()
	if _reveal_panel != null:
		_reveal_panel.queue_free()
		_reveal_panel = null

	_event_bus = EventBus.new()
	_event_bus.subscribe("GroundCompleted", _on_ground_completed)
	_sim = _make_sim(_event_bus)
	_replay = ReplayLog.new(0, "afterimage-web-demo")
	_drift = DriftEncounter.new()
	_phantom = PhantomEncounter.new()

	_tick_accumulator = 0.0
	_ground_completions = 0
	_ground_hold_ticks = 0
	_session_ended = false
	_phantom_sprite = null
	_ground_vignette.color = Color(
		_PANEL_TEXT_COLOR.r, _PANEL_TEXT_COLOR.g, _PANEL_TEXT_COLOR.b, 0.0
	)

	_build_world_visuals()
	_update_visuals()


## Every wall cell, the player, and the exit marker are Sprite2D nodes
## (world-space, CanvasItem, same coordinate model as _world_root)
## scaled from one shared 8x8 solid-color base texture per color, never
## per-node — programmer-art placeholders, real content deferred, the
## same discipline art_direction.md's document set has assumed throughout
## this engineering arc.
func _build_world_visuals() -> void:
	var wall_texture: ImageTexture = _solid_texture(_WALL_COLOR)
	for cell: Vector2i in _sim.grid.blocked_cells():
		var aabb: Dictionary = _sim.grid.cell_aabb(cell)
		var wall := Sprite2D.new()
		wall.texture = wall_texture
		wall.position = _mm_to_px((aabb["min"] + aabb["max"]) / 2)
		var size_px: Vector2 = _mm_to_px_extent(aabb["max"] - aabb["min"])
		wall.scale = size_px / _BASE_TEXTURE_SIZE_PX
		_world_root.add_child(wall)

	var exit_sprite := Sprite2D.new()
	exit_sprite.texture = _solid_texture(_EXIT_COLOR)
	exit_sprite.position = _mm_to_px(EXIT_POSITION_MM)
	var exit_size_px: Vector2 = _mm_to_px_extent(Vector2i(EXIT_RADIUS_MM, EXIT_RADIUS_MM))
	exit_sprite.scale = exit_size_px / _BASE_TEXTURE_SIZE_PX
	_world_root.add_child(exit_sprite)

	_player_sprite = Sprite2D.new()
	_player_sprite.texture = _solid_texture(_PLAYER_COLOR)
	var player_size_px: Vector2 = _mm_to_px_extent(
		Vector2i(PLAYER_RADIUS_MM * 2, PLAYER_RADIUS_MM * 2)
	)
	_player_sprite.scale = player_size_px / _BASE_TEXTURE_SIZE_PX
	_world_root.add_child(_player_sprite)


## The fixed-tick accumulator pattern tech_guidelines.md §3.1 requires:
## TruthSim.step() advances in whole 1/30s ticks regardless of the
## engine's actual frame rate, so movement replays identically at 30fps or
## 300fps. Input is sampled fresh for every elapsed tick this frame (never
## once per rendered frame), matching the determinism contract exactly.
## Stops ticking once the player reaches the exit (the reveal is a beat to
## read, not something to keep walking through) until Enter restarts.
func _physics_process(delta: float) -> void:
	if _session_ended:
		if Input.is_action_just_pressed("restart"):
			_start_new_session()
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
	var ground_just_completed: bool = bool(snapshot.get("ground_just_completed", false))

	_drift.maybe_trigger(_sim.player_position(), _sim.clock.current_tick)
	_drift.advance(_sim.clock.current_tick, ground_just_completed)

	_phantom.maybe_trigger(_sim.player_position(), _sim.clock.current_tick)
	_phantom.advance(_sim.clock.current_tick, ground_just_completed)

	_ground_hold_ticks = _ground_hold_ticks + 1 if grounding else 0

	if not _session_ended and _reached_exit(_sim.player_position()):
		_session_ended = true
		_show_reveal_panel()


static func _reached_exit(position_mm: Vector2i) -> bool:
	var d: Vector2i = position_mm - EXIT_POSITION_MM
	var dist_sq: int = d.x * d.x + d.y * d.y
	return dist_sq <= EXIT_RADIUS_MM * EXIT_RADIUS_MM


func _on_ground_completed(_event: Dictionary) -> void:
	_ground_completions += 1


func _update_visuals() -> void:
	var truth_snapshot: Dictionary = _sim.capture_percept_snapshot()
	var active_ops: Array = []
	if _drift.is_active():
		truth_snapshot["subtitle"] = _drift.subtitle_truth_fact()
		active_ops.append(_drift.op)
	if _phantom.is_active():
		active_ops.append(_phantom.op)
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

	# Charter rule 6 (§4.5): "Clarity Mode can flag distortions in real time
	# with a subtle vignette... fully honorable way to play." ClarityMode
	# itself has existed since Pass 10 with no consumer until now — this is
	# the plainest possible one (a text line, not a vignette), always on
	# rather than a real settings toggle (Pass 19's accessibility UI never
	# got built), but it is the real mechanism, not a placeholder string.
	_clarity_label.text = (
		"" if ClarityMode.active_flags(active_ops).is_empty() else "reality feels off right now"
	)

	_update_phantom_sprite(percept)
	_update_ground_vignette()


## Renders the phantom actor PhantomEntity.apply() adds to the percept
## snapshot (never the truth snapshot — Pass 8's boundary) as an extra
## Sprite2D, and fades it out (§4.2's "shimmers and dissolves over ~1 s")
## the moment it stops being in the percept — whether that's because it
## was grounded or because its own display window simply ran out;
## PerceptEncounter's own Charter-rule-5 guarantee means both paths are
## real disclosure, not just one of them.
func _update_phantom_sprite(percept: Dictionary) -> void:
	var phantom_actor: Dictionary = {}
	for actor: Dictionary in percept.get("actors", []) as Array:
		if bool(actor.get("is_phantom", false)):
			phantom_actor = actor
			break

	if phantom_actor.is_empty():
		if _phantom_sprite != null:
			_dissolve_phantom_sprite()
		return

	if _phantom_sprite == null:
		_phantom_sprite = Sprite2D.new()
		_phantom_sprite.texture = _solid_texture(_PHANTOM_COLOR)
		var size_px: Vector2 = _mm_to_px_extent(
			Vector2i(PLAYER_RADIUS_MM * 2, PLAYER_RADIUS_MM * 2)
		)
		_phantom_sprite.scale = size_px / _BASE_TEXTURE_SIZE_PX
		_world_root.add_child(_phantom_sprite)
	_phantom_sprite.position = _mm_to_px(phantom_actor["position"] as Vector2i)


func _dissolve_phantom_sprite() -> void:
	var sprite: Sprite2D = _phantom_sprite
	_phantom_sprite = null
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, PHANTOM_DISSOLVE_SECONDS)
	tween.tween_callback(sprite.queue_free)


## Ramps with the real Ground hold duration (GroundState.DURATION_TICKS),
## not an independent cosmetic timer — the vignette reaches full
## intensity on exactly the tick Ground actually completes, so the
## feedback is honest about what the mechanic is doing, not decorative
## guesswork layered on top of it.
##
## Reassigns the whole `color` property rather than writing
## `_ground_vignette.color.a = ...` directly: verified against the real
## GDScript docs before use — a property getter (`node.color`) returns a
## copy of a built-in value type like Color, so mutating `.a` on that
## copy and never reassigning it back through the setter is silently
## lost, not an error.
func _update_ground_vignette() -> void:
	var progress: float = clampf(
		float(_ground_hold_ticks) / float(GroundState.DURATION_TICKS), 0.0, 1.0
	)
	_ground_vignette.color = Color(
		_PANEL_TEXT_COLOR.r,
		_PANEL_TEXT_COLOR.g,
		_PANEL_TEXT_COLOR.b,
		progress * GROUND_VIGNETTE_MAX_ALPHA
	)


## The disclosure: builds a real ReplayTheater re-simulation of the whole
## recorded session (proving the tick-perfect reconstruction mechanism
## against a genuinely freely-played session, re-checked at the exact
## tick the player chose to end it) and shows what was actually true
## against what the drift/phantom encounters rendered, Charter rule 5
## ("everything is disclosable") made concrete for both distortions this
## demo carries — including the honest case where the player rushed past
## one, or both, without ever triggering them at all.
func _show_reveal_panel() -> void:
	if _reveal_panel != null:
		return

	var final_tick: int = _sim.clock.current_tick
	var theater := ReplayTheater.new(_scenario_factory(), _replay)
	var reconstructed: Dictionary = theater.truth_view_at(final_tick)
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

	var lines: PackedStringArray = PackedStringArray(["THE AFTERIMAGE", ""])
	lines.append_array(_drift_reveal_lines())
	lines.append("")
	lines.append_array(_phantom_reveal_lines())
	lines.append("")
	lines.append(
		(
			"Reconstructed from the replay: tick %d, you were at (%d, %d)"
			% [final_tick, reconstructed_player["position"].x, reconstructed_player["position"].y]
		)
	)
	lines.append("")
	lines.append("Press ENTER to walk it again.")

	var text_label := Label.new()
	text_label.position = Vector2(24, 56)
	text_label.size = Vector2(VIEWPORT_SIZE_PX.x - 48, 260)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.add_theme_color_override("font_color", _PANEL_TEXT_COLOR)
	text_label.text = "\n".join(lines)
	_reveal_panel.add_child(text_label)


func _drift_reveal_lines() -> PackedStringArray:
	if _drift.op == null:
		return PackedStringArray(["You reached the door without hearing anything unusual."])
	return PackedStringArray(
		[
			'You heard: "%s"' % DriftEncounter.DRIFTED_TEXT,
			'Truth:     "%s"' % DriftEncounter.TRUE_TEXT,
			(
				"Grounded in the moment: %s"
				% ("yes" if _drift.was_grounded else "no — disclosed anyway")
			),
		]
	)


func _phantom_reveal_lines() -> PackedStringArray:
	if _phantom.op == null:
		return PackedStringArray(
			["You reached the door without seeing anything that wasn't there."]
		)
	return PackedStringArray(
		[
			"You saw a figure standing nearby.",
			"Truth:     nobody was there.",
			(
				"Grounded in the moment: %s"
				% ("yes" if _phantom.was_grounded else "no — disclosed anyway")
			),
		]
	)


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
