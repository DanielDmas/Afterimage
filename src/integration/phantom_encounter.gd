## A single scripted PhantomEntity sighting, wired into the same live,
## freely-walked scene as DriftEncounter (scenes/main.gd) — the second of
## the demo's two distinct distortion moments, chosen deliberately for how
## differently it reads from a text mishearing: a person-shaped figure the
## player can *see*, standing where nothing real is, obeying Charter rule
## 1 (a phantom never damages or blocks) exactly because it's percept-only.
## Kept as pure logic (no Node/scene-tree dependency), mirroring
## DriftEncounter's own shape exactly — same state machine, same
## Charter-rule-5 guarantee that REVEALED is reached either way (grounded
## or timed out), same "scenes/main.gd only asks it what should be true
## right now" contract.
class_name PhantomEncounter
extends RefCounted

enum State { WAITING, ACTIVE, REVEALED }

const ENTITY_KIND: String = "figure"
const DRAMATIC_INTENT: String = "dread"

const TRIGGER_POINT_MM: Vector2i = Vector2i(1800, 1200)
const TRIGGER_RADIUS_MM: int = 1000
const PHANTOM_POSITION_MM: Vector2i = Vector2i(1800, 1200)
const PHANTOM_FACING_DIR: Vector2i = Vector2i(1, 1)
const DISPLAY_DURATION_TICKS: int = 180  # 6s at the fixed 30Hz tick rate

var state: State = State.WAITING
var op: PhantomEntity
var start_tick: int = -1
var was_grounded: bool = false


## Call once per tick with the player's current position. A no-op once
## triggered (or already revealed) — the encounter fires exactly once.
func maybe_trigger(player_position_mm: Vector2i, current_tick: int) -> void:
	if state != State.WAITING:
		return
	var d: Vector2i = player_position_mm - TRIGGER_POINT_MM
	var dist_sq: int = d.x * d.x + d.y * d.y
	if dist_sq > TRIGGER_RADIUS_MM * TRIGGER_RADIUS_MM:
		return
	state = State.ACTIVE
	start_tick = current_tick
	op = PhantomEntity.new(PHANTOM_POSITION_MM, ENTITY_KIND, PHANTOM_FACING_DIR, DRAMATIC_INTENT)


## Call once per tick while active with this tick's Ground-completion
## signal (TruthSim.capture_percept_snapshot()'s own "ground_just_completed").
## A no-op outside the ACTIVE state.
func advance(current_tick: int, ground_just_completed: bool) -> void:
	if state != State.ACTIVE:
		return
	if ground_just_completed:
		was_grounded = true
		state = State.REVEALED
		return
	if current_tick - start_tick >= DISPLAY_DURATION_TICKS:
		state = State.REVEALED


func is_waiting() -> bool:
	return state == State.WAITING


func is_active() -> bool:
	return state == State.ACTIVE


func is_revealed() -> bool:
	return state == State.REVEALED
