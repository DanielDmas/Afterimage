extends AfterimageTestCase

const SIMPLE_GRAPH: Dictionary = {
	"dlg_version": 1,
	"start_node": "a",
	"nodes":
	{
		"a":
		{
			"lines": [{"speaker": "npc.sova", "stance": null, "text": "Hello.", "drift": null}],
			"choices": [],
			"claim_grants": [{"id": "claim.bare"}],
			"goto": "b",
		},
		"b":
		{
			"lines": [{"speaker": "npc.sova", "stance": null, "text": "Pick one.", "drift": null}],
			"choices":
			[
				{"text": "Yes", "stance": "warm", "target": "c", "guard": null},
				{
					"text": "Locked",
					"stance": "pressing",
					"target": "d",
					"guard": {"op": "flag", "args": {"name": "unlock_d"}},
				},
			],
			"claim_grants": [],
			"goto": null,
		},
		"c":
		{
			"lines": [{"speaker": "player", "stance": null, "text": "Yes.", "drift": null}],
			"choices": [],
			"claim_grants":
			[{"id": "claim.c_reached", "subject": "player", "predicate": "chose", "object": "c"}],
			"goto": "END",
		},
		"d":
		{
			"lines": [{"speaker": "player", "stance": null, "text": "Locked path.", "drift": null}],
			"choices": [],
			"claim_grants": [],
			"goto": "END",
		},
	},
}

## Transcribed verbatim from `python3 tools/dlgc.py content/dialogue/prologue_sova.dlg`'s
## real output, hand-verified locally before this file was written — proves
## the runtime actually interprets what the real compiler emits, without
## needing to invoke Python from a GDScript test.
const PROLOGUE_SOVA_GRAPH: Dictionary = {
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
					"text":
					"Before we start, a simple exercise. Hold still, hold quiet, and tell me what's true.",
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
		"node_pipes":
		{
			"lines":
			[
				{
					"speaker": "player",
					"stance": null,
					"text": "The heating pipes, ticking.",
					"drift": null,
				},
				{
					"speaker": "npc.sova",
					"stance": null,
					"text": "Correct. Ground told you the truth before I even had to.",
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
					"object": "heating_pipes",
				}
			],
			"goto": "node_close",
		},
		"node_footsteps":
		{
			"lines":
			[
				{
					"speaker": "player",
					"stance": null,
					"text": "Footsteps. Someone was there.",
					"drift": {"text": "Footsteps. Someone was there.", "intent": "doubt"},
				},
				{
					"speaker": "npc.sova",
					"stance": null,
					"text":
					"There was no one in that hall. That's the lesson — not everything you hear is real.",
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
					"text": "Ground when you doubt. It costs you time, never dignity.",
					"drift": null,
				}
			],
			"choices": [],
			"claim_grants":
			[
				{
					"id": "claim.sova_closing_lesson",
					"subject": "npc.sova",
					"predicate": "lesson_theme",
					"object": "ground_costs_time_not_dignity",
				}
			],
			"goto": "END",
		},
	},
}


func test_starts_at_the_graphs_start_node_and_applies_its_claim_grants() -> void:
	var runner := DialogueRunner.new(DialogueGraph.new(SIMPLE_GRAPH))
	assert_eq(runner.current_node_id(), "a")
	assert_false(runner.is_ended())
	assert_eq(runner.interrupt_memory.statements().size(), 0)  # bare grant, not structured


func test_advance_follows_goto_on_a_no_choice_node() -> void:
	var runner := DialogueRunner.new(DialogueGraph.new(SIMPLE_GRAPH))
	runner.advance()
	assert_eq(runner.current_node_id(), "b")


func test_available_choices_filters_by_guard() -> void:
	var runner := DialogueRunner.new(DialogueGraph.new(SIMPLE_GRAPH))
	runner.advance()  # a -> b

	var locked_query := MockWorldQuery.new()
	assert_eq(runner.available_choices(locked_query).size(), 1)
	assert_eq(runner.available_choices(locked_query)[0]["text"], "Yes")

	var unlocked_query := MockWorldQuery.new()
	unlocked_query.flags["unlock_d"] = true
	assert_eq(runner.available_choices(unlocked_query).size(), 2)


func test_choose_advances_to_the_chosen_targets_node_and_applies_its_grants() -> void:
	var runner := DialogueRunner.new(DialogueGraph.new(SIMPLE_GRAPH))
	runner.advance()  # a -> b
	var query := MockWorldQuery.new()
	runner.choose(0, query)  # "Yes" -> c
	assert_eq(runner.current_node_id(), "c")
	assert_eq(runner.interrupt_memory.statements().size(), 1)
	assert_eq(runner.interrupt_memory.statements()[0]["object"], "c")


func test_reaching_end_node_sets_is_ended() -> void:
	var runner := DialogueRunner.new(DialogueGraph.new(SIMPLE_GRAPH))
	runner.advance()  # a -> b
	runner.choose(0, MockWorldQuery.new())  # -> c
	runner.advance()  # c -> END
	assert_true(runner.is_ended())


## The real, compiled prologue scene, played through both branches —
## satisfying the roadmap AC's "compiled prologue Sova scene plays."
func test_prologue_sova_plays_through_the_pipes_branch() -> void:
	var runner := DialogueRunner.new(DialogueGraph.new(PROLOGUE_SOVA_GRAPH))
	assert_eq(runner.current_lines()[0]["speaker"], "npc.sova")
	runner.advance()  # briefing -> choice
	assert_eq(runner.current_node_id(), "node_choice")

	var query := MockWorldQuery.new()
	runner.choose(0, query)  # "The heating pipes, ticking." -> node_pipes
	assert_eq(runner.current_node_id(), "node_pipes")

	runner.advance()  # -> node_close
	assert_eq(runner.current_node_id(), "node_close")
	runner.advance()  # -> END
	assert_true(runner.is_ended())

	var statements: Array = runner.interrupt_memory.statements()
	assert_eq(statements.size(), 2)
	assert_eq(statements[0]["object"], "heating_pipes")
	assert_eq(statements[1]["subject"], "npc.sova")


func test_prologue_sova_plays_through_the_footsteps_branch_with_a_drift_annotation() -> void:
	var runner := DialogueRunner.new(DialogueGraph.new(PROLOGUE_SOVA_GRAPH))
	runner.advance()  # briefing -> choice
	runner.choose(1, MockWorldQuery.new())  # "Footsteps..." -> node_footsteps
	assert_eq(runner.current_node_id(), "node_footsteps")

	var drift: Variant = runner.current_lines()[0]["drift"]
	assert_eq(drift["intent"], "doubt")

	runner.advance()  # -> node_close
	runner.advance()  # -> END
	assert_true(runner.is_ended())
	assert_eq(runner.interrupt_memory.statements()[0]["object"], "footsteps")


## Neither branch of the real scene contradicts itself (both grant
## claim.player_heard with different objects, but only one branch ever
## runs per playthrough) — a contradiction only arises across separately
## authored statements, which test_interrupt_memory.gd covers directly.
func test_prologue_sova_single_playthrough_has_no_contradiction() -> void:
	var runner := DialogueRunner.new(DialogueGraph.new(PROLOGUE_SOVA_GRAPH))
	runner.advance()
	runner.choose(0, MockWorldQuery.new())
	runner.advance()
	runner.advance()
	assert_false(runner.interrupt_memory.has_contradiction())
