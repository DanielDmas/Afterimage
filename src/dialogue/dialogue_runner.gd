## foundation_blueprints.md §4.2: "Interprets compiled graphs; owns
## interrupt memory." Walks a DialogueGraph node by node, evaluating guard
## predicates (src/core/predicate.gd's PredicateEvaluator, reused as-is —
## "one evaluator, unit-tested once, used by... dialogue guards and
## unlocks") against a caller-supplied WorldQuery, and records every
## structured claim grant into InterruptMemory as it's reached.
##
## v0 scope: guards apply to choices only, not individual lines — this
## scene's content never needed per-line guards, and adding them without a
## concrete AC-driving need would be exactly the premature-scope pattern
## this log has avoided since Pass 4. Register-mark-driven pre-selection/
## input-hold behavior (master_plan §4.4.4, §4.8) needs a real UI (Pass 19)
## to attach to and isn't implemented here — stance tags are parsed and
## carried through as data (DialogueGraph's choices/lines already have
## them), ready for that future consumer.
class_name DialogueRunner
extends RefCounted

var graph: DialogueGraph
var interrupt_memory: InterruptMemory

var _current_node_id: String
var _is_ended: bool = false


func _init(p_graph: DialogueGraph, p_interrupt_memory: InterruptMemory = null) -> void:
	graph = p_graph
	interrupt_memory = p_interrupt_memory if p_interrupt_memory != null else InterruptMemory.new()
	_current_node_id = graph.start_node
	_apply_claim_grants_for_current_node()


func is_ended() -> bool:
	return _is_ended


func current_node_id() -> String:
	return _current_node_id


func current_lines() -> Array:
	return graph.node(_current_node_id)["lines"]


## Filters this node's choices by guard, evaluated against `query` — the
## same duck-typed WorldQuery every other Predicate consumer uses.
func available_choices(query: WorldQuery) -> Array:
	var result: Array = []
	for choice: Dictionary in graph.node(_current_node_id)["choices"]:
		var guard: Variant = choice.get("guard")
		if guard == null or PredicateEvaluator.evaluate(guard, query):
			result.append(choice)
	return result


func choose(choice_index: int, query: WorldQuery) -> void:
	var choices: Array = available_choices(query)
	assert(
		choice_index >= 0 and choice_index < choices.size(),
		"DialogueRunner: choice index %d out of range [0, %d)" % [choice_index, choices.size()]
	)
	_advance_to(choices[choice_index]["target"])


## For a node with no choices: follows its `goto` (or ends the scene if
## `goto` is "END").
func advance() -> void:
	var node: Dictionary = graph.node(_current_node_id)
	assert(
		(node["choices"] as Array).is_empty(),
		"DialogueRunner: advance() called on a node with choices; use choose() instead"
	)
	_advance_to(node["goto"])


func _advance_to(target: String) -> void:
	if target == DialogueGraph.END_NODE:
		_is_ended = true
		return
	_current_node_id = target
	_apply_claim_grants_for_current_node()


## Attributes a structured claim grant's `told` provenance to the last
## line spoken in the node granting it — a v0 heuristic (the DSL has no
## explicit per-grant speaker syntax yet), documented rather than assumed
## obvious.
func _apply_claim_grants_for_current_node() -> void:
	var node: Dictionary = graph.node(_current_node_id)
	var source: String = _last_speaker_in_current_node()
	for grant: Dictionary in node["claim_grants"] as Array:
		if grant.has("subject"):
			interrupt_memory.record_statement(
				grant["subject"], grant["predicate"], grant["object"], source
			)


func _last_speaker_in_current_node() -> String:
	var lines: Array = graph.node(_current_node_id)["lines"]
	if lines.is_empty():
		return ""
	return (lines[-1] as Dictionary)["speaker"]
