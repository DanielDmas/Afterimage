## Pass 20's integration capstone: a playable prologue stub tying together
## almost every prior pass's system into one coherent, scripted scenario —
## master_plan.md §2.6's "Cold Open" ("Dr. Sova teaches Ground
## diegetically... ends with the game showing its own trick once: one
## scripted misheard line, immediately disclosed in a mini-Theater").
##
## Deliberately not a real Godot scene (Pass 19's own reasoning still
## applies: no editor exists in this sandbox to author/verify a `.tscn`
## against) — this is the same "orchestration as a tested RefCounted
## class" shape every other integration in this codebase already uses
## (`ReplayTheater`, `DebriefLedger`), just wiring more systems together
## at once: `TruthSim` (Pass 3-10) for the Ground tutorial,
## `DialogueRunner`+`InterruptMemory` (Pass 15) replaying the real
## compiled prologue scene, `SubtitleDrift`+`PerceptRenderer` (Pass 8/9)
## for the one scripted distortion, `ReplayTheater`+`OpTimelineSpan`
## (Pass 14) for the mini-Theater reconstruction, and
## `ClaimDrafter`+`DebriefLedger` (Pass 17) for the trivial debrief.
##
## Lives outside `src/percept/` (so it may name `TruthSim` directly,
## unlike `ReplayTheater`) and outside `src/dialogue/`/`src/debrief/`
## (it's the one place that legitimately depends on all of them at once).
class_name PrologueStub
extends RefCounted

## Transcribed verbatim from `python3 tools/dlgc.py content/dialogue/prologue_sova.dlg`'s
## real compiled output (Pass 15 already verified this exact Dictionary
## against the live compiler) — the compiled JSON itself is never
## committed (tech_guidelines §5.1), so this is the same "hand-built
## fixture matching the compiler's real output format" this codebase has
## used since Pass 15's own tests.
const PROLOGUE_GRAPH: Dictionary = {
	"dlg_version": 1,
	"start_node": "node_briefing",
	"nodes":
	{
		"node_briefing":
		{
			"lines":
			[
				{
					"speaker": "npc.sova",
					"stance": null,
					"text": "Before we start, a simple exercise.",
					"drift": null,
				}
			],
			"choices": [],
			"claim_grants": [{"id": "claim.sova_taught_ground"}],
			"goto": "node_choice",
		},
		"node_choice":
		{
			"lines":
			[
				{
					"speaker": "npc.sova",
					"stance": null,
					"text": "Tell me — what did you hear just now, down the hall?",
					"drift": null,
				}
			],
			"choices":
			[
				{
					"text": "The heating pipes, ticking.",
					"stance": "procedural",
					"target": "node_pipes",
					"guard": null,
				},
				{
					"text": "Footsteps. Someone was there.",
					"stance": "pressing",
					"target": "node_footsteps",
					"guard": null,
				},
			],
			"claim_grants": [],
			"goto": null,
		},
		"node_footsteps":
		{
			"lines":
			[
				{
					"speaker": "player",
					"stance": null,
					"text": "Footsteps. Someone was there.",
					"drift": {"text": "Just the radiator, ticking.", "intent": "doubt"},
				},
				{
					"speaker": "npc.sova",
					"stance": null,
					"text": "There was no one in that hall.",
					"drift": null,
				},
			],
			"choices": [],
			"claim_grants":
			[
				{
					"id": "claim.player_heard",
					"subject": "player",
					"predicate": "heard_sound",
					"object": "footsteps",
				}
			],
			"goto": "node_close",
		},
		"node_close":
		{
			"lines":
			[
				{
					"speaker": "npc.sova",
					"stance": null,
					"text": "Ground when you doubt.",
					"drift": null,
				}
			],
			"choices": [],
			"claim_grants": [],
			"goto": "END",
		},
	},
}

## The ground truth for the footsteps branch's misheard line —
## master_plan §2.6: "There was no one in that hall." Whatever the
## debrief stage compares the perceived claim against.
const GROUND_TRUTH_HEARD_SOUND: String = "silence"

var truth_sim: TruthSim
var dialogue: DialogueRunner
var interrupt_memory: InterruptMemory
var replay: ReplayLog
var debrief: DebriefLedger

var _drift_tick: int = -1
var _drift_op: SubtitleDrift


func _init() -> void:
	truth_sim = TruthSim.new(500, Vector2i(0, 0), 300)
	interrupt_memory = InterruptMemory.new()
	dialogue = DialogueRunner.new(DialogueGraph.new(PROLOGUE_GRAPH), interrupt_memory)
	replay = ReplayLog.new(1, "prologue-stub")
	debrief = DebriefLedger.new()


static func _scenario_factory() -> Callable:
	return func() -> TruthSim: return TruthSim.new(500, Vector2i(0, 0), 300)


func _step(inputs: Dictionary) -> void:
	var frame := InputFrame.new(replay.frame_count() + 1, inputs)
	replay.record(frame)
	truth_sim.step(frame)


## Stage 1 — the Ground tutorial (§2.6, §4.6): holds Ground for exactly
## GroundState.DURATION_TICKS, producing a real GroundCompleted resolution
## through TruthSim's own Ground verb (Pass 10), not a stand-in.
func run_ground_tutorial() -> void:
	dialogue.advance()  # node_briefing -> node_choice (bare claim grant applied on entry)
	for _i: int in range(GroundState.DURATION_TICKS):
		_step({"ground": true})


## Stage 2 — one scripted SubtitleDrift (§2.6's "one scripted misheard
## line"): advances dialogue down the footsteps branch (its own claim
## grant lands in `interrupt_memory` automatically, Pass 15), then renders
## that exact tick's percept view through a real `SubtitleDrift` +
## `PerceptRenderer` (Pass 8/9) — the drift never touched by hand-waving,
## the same classes every other pass's tests already exercise.
func play_scripted_misheard_line() -> Dictionary:
	dialogue.choose(1, WorldQuery.new())  # node_choice -> node_footsteps
	var drift_line: Dictionary = dialogue.current_lines()[0]
	var drift_data: Dictionary = drift_line["drift"]

	_drift_tick = replay.frame_count() + 1
	_step({})  # a plain tick to advance TruthSim/replay in lockstep with dialogue

	_drift_op = SubtitleDrift.new(drift_data["text"], drift_data["intent"])
	var truth_snapshot: Dictionary = truth_sim.capture_percept_snapshot()
	truth_snapshot["subtitle"] = {
		"speaker_id": drift_line["speaker"], "true_text": drift_line["text"]
	}
	var percept_snapshot: Dictionary = PerceptRenderer.render(truth_snapshot, [_drift_op])

	dialogue.advance()  # node_footsteps -> node_close
	dialogue.advance()  # node_close -> END

	return {"truth": truth_snapshot, "percept": percept_snapshot}


## Stage 3 — the mini-Theater (§4.12): reconstructs both views for the
## exact scripted tick, via the same `ReplayTheater`/`OpTimelineSpan`
## machinery Pass 14 built and tested standalone.
func build_mini_theater() -> ReplayTheater:
	var span := OpTimelineSpan.new(
		_drift_op.op_class, _drift_op.tier, "acute_stress", _drift_tick, _drift_tick
	)
	var spans: Array[OpTimelineSpan] = [span]
	return ReplayTheater.new(_scenario_factory(), replay, spans)


## Stage 4 — the trivial debrief (§4.10): drafts a claim from what
## interrupt memory actually recorded the player asserting ("heard
## footsteps"), and submits it As-Seen against the real ground truth
## ("There was no one in that hall") — the quiet knife, played out for
## real: the player's own claim, honestly submitted, still comes back
## false, because that's what they believed.
func draft_and_submit_debrief() -> Dictionary:
	var heard_statement: Dictionary = interrupt_memory.statements()[0]
	var event: Dictionary = {
		"id": "claim.prologue.heard_sound",
		"subject": heard_statement["subject"],
		"predicate": heard_statement["predicate"],
		"object": heard_statement["object"],
	}
	var claims: Array[Claim] = ClaimDrafter.draft_from_perceived_events([event])
	debrief.add_candidate(claims[0])
	return debrief.submit_claim(
		claims[0].id, DebriefLedger.HonestyMode.AS_SEEN, GROUND_TRUTH_HEARD_SOUND
	)


## Runs every stage in order — the whole playable stub, start to end.
func run_full_stub() -> Dictionary:
	run_ground_tutorial()
	var dual_view: Dictionary = play_scripted_misheard_line()
	var theater: ReplayTheater = build_mini_theater()
	var debrief_record: Dictionary = draft_and_submit_debrief()
	return {
		"dual_view": dual_view,
		"theater": theater,
		"debrief_record": debrief_record,
		"ground_use_count": truth_sim.ground_use_count(),
	}
