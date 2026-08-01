## A "placeholder screen" as data, not a Godot scene: a title plus a
## sequence of labeled rows. This is the pass's honest answer to "no
## Godot editor or renderer exists in this sandbox to verify a hand-
## authored .tscn/.tres file" — the same discipline that has kept this
## codebase from touching untestable Godot behavior since Pass 6/9's
## real gotchas. A future UI pass (with an actual editor session to
## verify against) builds real Control-node scenes that bind to a
## ScreenSpec's data; this class is the binding contract, not the
## rendering.
##
## `screen_reader_text()` is a real, generatable string — ux_charter §4's
## "screen-reader on all paperwork/menu screens" committed item — built
## from this spec's own data rather than scene-tree traversal, since no
## scene tree exists yet to traverse.
class_name ScreenSpec
extends RefCounted

var title: String
var rows: Array[Dictionary]  ## [{"label": String, "value": String}]


func _init(p_title: String, p_rows: Array[Dictionary] = []) -> void:
	title = p_title
	rows = p_rows


func add_row(label: String, value: String) -> void:
	rows.append({"label": label, "value": value})


func screen_reader_text() -> String:
	var text: String = title
	for row: Dictionary in rows:
		text += "\n%s: %s" % [row["label"], row["value"]]
	return text
