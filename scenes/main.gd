## The first genuinely playable slice: a real graybox room driven by the
## actual TruthSim (src/sim/, Pass 3-7) with live rendering wired directly
## to its tick-perfect simulation — nothing here is a stand-in. Movement +
## collision is the safest, most heavily-tested slice to expose first
## (CollisionGrid/SweptCollision/TruthSim already carry 150+ passing unit
## tests); combat, AI, the Mind Model, and distortions are deliberately
## not wired into this first playable scene — the same "prove the one
## thing that matters, don't overreach" discipline this codebase has used
## pass over pass. The room layout mirrors tests/fixtures/graybox_room.gd
## (Pass 7's own graybox room) rather than importing it directly — a
## runtime scene depending on the test tree would be backwards, so the
## handful of lines are duplicated here instead.
##
## This is the project's first Node-derived script and first .tscn scene.
## Every prior pass avoided the scene tree entirely (Pass 19's dev_log
## entry: no local Godot editor exists in this authoring sandbox to
## visually verify one against). That constraint hasn't changed — this
## still can't be visually verified here — but every Godot API used below
## was checked against the real Godot 4.3 class docs (docs.godotengine.org,
## reachable from this sandbox even though the engine binary and export
## templates are not) before being used, the same "verify externally
## before porting/using" discipline this project has applied to arithmetic
## since Pass 1. What can't be verified locally gets verified for real via
## the exported web build instead — the same "fix forward from a real
## environment this sandbox lacks" pattern every truly-untestable piece of
## this codebase has followed, just substituting "a browser" for "CI."
extends Node2D

const CELL_SIZE_MM: int = 500
const ROOM_WIDTH_CELLS: int = 12
const ROOM_HEIGHT_CELLS: int = 8
const PLAYER_RADIUS_MM: int = 250
const PLAYER_START: Vector2i = Vector2i(3000, 2000)

const PX_PER_MM: float = 0.08  # a 6000x4000mm room -> 480x320px, fits the 640x360 viewport
const TICK_SECONDS: float = 1.0 / 30.0
const _BASE_TEXTURE_SIZE_PX: int = 8

const _WALL_COLOR: Color = Color(0.15, 0.13, 0.11)  # art_direction §5: carbon paper
const _PLAYER_COLOR: Color = Color(0.98, 0.55, 0.14)  # art_direction §5: sodium orange
const _BG_COLOR: Color = Color(0.05, 0.05, 0.06)

var _sim: TruthSim
var _tick_accumulator: float = 0.0
var _player_sprite: Sprite2D
var _tick_label: Label


func _ready() -> void:
	RenderingServer.set_default_clear_color(_BG_COLOR)
	_bind_movement_keys()
	_sim = TruthSim.new(CELL_SIZE_MM, PLAYER_START, PLAYER_RADIUS_MM)
	_build_room_walls()
	_build_visuals()


## The InputMap actions this project declares (project.godot's [input]
## section, Pass 6) were deliberately left with empty key bindings — that
## pass's own dev_log explains why: hand-authoring an InputEventKey
## resource literal in project.godot's text format risked a wrong keycode
## with no editor to catch it. Binding keys here in code sidesteps that
## risk entirely: GDScript's named KEY_* constants (verified against the
## real @GlobalScope docs above) resolve at compile time, so there is no
## numeric literal to get wrong.
func _bind_movement_keys() -> void:
	_bind_key("move_up", [KEY_UP, KEY_W])
	_bind_key("move_down", [KEY_DOWN, KEY_S])
	_bind_key("move_left", [KEY_LEFT, KEY_A])
	_bind_key("move_right", [KEY_RIGHT, KEY_D])
	_bind_key("sprint", [KEY_SHIFT])


static func _bind_key(action: String, keycodes: Array) -> void:
	for keycode: int in keycodes:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action, event)


## A perimeter-walled room, matching tests/fixtures/graybox_room.gd's
## layout exactly (interior world coords roughly
## [0, ROOM_WIDTH_CELLS*CELL_SIZE_MM) x [0, ROOM_HEIGHT_CELLS*CELL_SIZE_MM)).
func _build_room_walls() -> void:
	for x: int in range(-1, ROOM_WIDTH_CELLS + 1):
		_sim.grid.set_cell_blocked(Vector2i(x, -1), true)
		_sim.grid.set_cell_blocked(Vector2i(x, ROOM_HEIGHT_CELLS), true)
	for y: int in range(-1, ROOM_HEIGHT_CELLS + 1):
		_sim.grid.set_cell_blocked(Vector2i(-1, y), true)
		_sim.grid.set_cell_blocked(Vector2i(ROOM_WIDTH_CELLS, y), true)


static func _solid_texture(color: Color) -> ImageTexture:
	var image: Image = Image.create_empty(
		_BASE_TEXTURE_SIZE_PX, _BASE_TEXTURE_SIZE_PX, false, Image.FORMAT_RGBA8
	)
	image.fill(color)
	return ImageTexture.create_from_image(image)


## Every wall cell and the player are Sprite2D nodes scaled from one
## shared 8x8 solid-color base texture per color (never per-node), the
## same "programmer-art placeholder, real content deferred" approach
## art_direction.md's own document set has assumed throughout this
## engineering arc — Sprite2D (a CanvasItem, like this scene's own
## Node2D root) is used rather than a Control-based ColorRect specifically
## to avoid mixing Control's anchor-based layout system into a Node2D
## world-space tree, keeping every position/scale calculation in one
## consistent coordinate model.
func _build_visuals() -> void:
	var wall_texture: ImageTexture = _solid_texture(_WALL_COLOR)
	for cell: Vector2i in _sim.grid.blocked_cells():
		var aabb: Dictionary = _sim.grid.cell_aabb(cell)
		var wall := Sprite2D.new()
		wall.texture = wall_texture
		wall.position = _mm_to_px((aabb["min"] + aabb["max"]) / 2)
		var size_px: Vector2 = _mm_to_px(aabb["max"] - aabb["min"])
		wall.scale = size_px / _BASE_TEXTURE_SIZE_PX
		add_child(wall)

	_player_sprite = Sprite2D.new()
	_player_sprite.texture = _solid_texture(_PLAYER_COLOR)
	var player_size_px: Vector2 = _mm_to_px(Vector2i(PLAYER_RADIUS_MM * 2, PLAYER_RADIUS_MM * 2))
	_player_sprite.scale = player_size_px / _BASE_TEXTURE_SIZE_PX
	add_child(_player_sprite)

	_tick_label = Label.new()
	_tick_label.position = Vector2(4, 4)
	add_child(_tick_label)

	_update_visuals()


## The fixed-tick accumulator pattern tech_guidelines.md §3.1 requires:
## TruthSim.step() advances in whole 1/30s ticks regardless of the
## engine's actual frame rate, so movement replays identically at 30fps or
## 300fps. Input is sampled fresh for every elapsed tick this frame (never
## once per rendered frame), matching the determinism contract exactly.
func _physics_process(delta: float) -> void:
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
	var mode: MovementProfile.Mode = (
		MovementProfile.Mode.SPRINT if sprinting else MovementProfile.Mode.WALK
	)
	var delta_mm: Vector2i = MovementProfile.resolve_delta(dir, mode)
	var frame := InputFrame.new(
		_sim.clock.current_tick + 1,
		{"move_x": delta_mm.x, "move_y": delta_mm.y, "sprinting": sprinting}
	)
	_sim.step(frame)


func _update_visuals() -> void:
	var pos_mm: Vector2i = _sim.player_position()
	_player_sprite.position = _mm_to_px(pos_mm)
	_tick_label.text = (
		"tick %d   pos (%d, %d) mm — WASD/arrows to move, Shift to sprint"
		% [_sim.clock.current_tick, pos_mm.x, pos_mm.y]
	)


static func _mm_to_px(v: Vector2i) -> Vector2:
	return Vector2(v.x, v.y) * PX_PER_MM
