## The compiled form of a `.dlg` scene (foundation_blueprints.md §4.1),
## loaded from the JSON `tools/dlgc.py` emits. Compiled output is a build
## artifact (tech_guidelines.md §5.1: "never hand-edited, never
## committed") — this class only ever loads a Dictionary already in that
## shape, whether that Dictionary came from a real compile step or (in
## tests, mirroring Pass 8/9's "synthetic snapshot" discipline) a
## hand-built fixture matching the same format.
class_name DialogueGraph
extends RefCounted

const END_NODE: String = "END"

var start_node: String
var nodes: Dictionary


func _init(data: Dictionary) -> void:
	start_node = data["start_node"]
	nodes = data["nodes"]


func node(node_id: String) -> Dictionary:
	assert(nodes.has(node_id), "DialogueGraph: unknown node '%s'" % node_id)
	return nodes[node_id]


func has_node(node_id: String) -> bool:
	return nodes.has(node_id)
