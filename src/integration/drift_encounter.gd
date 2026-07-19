## A single scripted SubtitleDrift moment, wired into a live, freely-walked
## scene rather than PrologueStub's fixed scripted sequence (Pass 20) — the
## "thesis demo" the post-arc review called for: Ground verb + one real
## distortion + a disclosure, playable by a stranger in under two minutes.
## Kept as pure logic (no Node/scene-tree dependency) so it gets real unit
## test coverage from the existing harness, exactly like every other
## engineering-arc class — `scenes/main.gd` only asks it "what should be
## true right now" and renders the answer.
##
## State machine: WAITING (player hasn't reached the trigger point) ->
## ACTIVE (the drifted subtitle is live) -> REVEALED (either the player
## grounded it, or its display window simply ran out). Charter rule 5
## ("everything is disclosable... no secret permanent gaslighting") means
## REVEALED is reached either way — grounding just gets there sooner and
## self-corrects the subtitle in the moment, per §4.6's actual point of the
## verb, rather than being the only path to disclosure at all.
class_name DriftEncounter
extends RefCounted

enum State { WAITING, ACTIVE, REVEALED }

## §2.6/PrologueStub's own Cold Open beat, reused deliberately rather than
## invented fresh — the same real, already-content-reviewed narrative case,
## now experienced live instead of as a fixed cutscene.
const TRUE_TEXT: String = "Footsteps. Someone was there."
const DRIFTED_TEXT: String = "Just the radiator, ticking."
const DRAMATIC_INTENT: String = "doubt"

const TRIGGER_POINT_MM: Vector2i = Vector2i(5000, 3000)
const TRIGGER_RADIUS_MM: int = 800
const DISPLAY_DURATION_TICKS: int = 150  # 5s at the fixed 30Hz tick rate

var state: State = State.WAITING
var op: SubtitleDrift
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
	op = SubtitleDrift.new(DRIFTED_TEXT, DRAMATIC_INTENT)


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


## The synthetic "subtitle" truth fact SubtitleDrift.apply()/
## resolve_grounded() operate on (§4.2's op contract) — dialogue has no
## real truth-layer representation yet (SubtitleDrift's own class doc),
## so this is hand-built the same way PrologueStub's is.
func subtitle_truth_fact() -> Dictionary:
	return {"speaker_id": "unknown", "true_text": TRUE_TEXT}
