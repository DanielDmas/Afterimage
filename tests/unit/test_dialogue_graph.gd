extends AfterimageTestCase

const SIMPLE_GRAPH: Dictionary = {
	"dlg_version": 1,
	"start_node": "a",
	"nodes":
	{
		"a": {"lines": [], "choices": [], "claim_grants": [], "goto": "b"},
		"b": {"lines": [], "choices": [], "claim_grants": [], "goto": "END"},
	},
}


func test_constructor_reads_start_node_and_nodes() -> void:
	var graph := DialogueGraph.new(SIMPLE_GRAPH)
	assert_eq(graph.start_node, "a")
	assert_eq(graph.nodes.size(), 2)


func test_node_returns_the_requested_node_dictionary() -> void:
	var graph := DialogueGraph.new(SIMPLE_GRAPH)
	assert_eq(graph.node("a")["goto"], "b")
	assert_eq(graph.node("b")["goto"], "END")


func test_has_node_reflects_presence() -> void:
	var graph := DialogueGraph.new(SIMPLE_GRAPH)
	assert_true(graph.has_node("a"))
	assert_false(graph.has_node("nonexistent"))
