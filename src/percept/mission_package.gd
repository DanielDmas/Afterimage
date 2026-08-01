## The in-memory, loaded form of a mission package (tech_guidelines.md
## D7/§5.1's JSON content package), ready to drive DistortionDirector and
## FairnessAuditor directly — plain data, matching DeckEntry's own "content
## is data, not code" shape. Built by MissionLoader, never constructed by
## hand outside tests.
class_name MissionPackage
extends RefCounted

var id: String
var scene_type: DistortionDirector.SceneType
var mission_weights_fx: Dictionary
var encounter_cap: int
var deck: Array[DeckEntry]


func _init(
	p_id: String,
	p_scene_type: DistortionDirector.SceneType,
	p_mission_weights_fx: Dictionary,
	p_encounter_cap: int,
	p_deck: Array[DeckEntry]
) -> void:
	id = p_id
	scene_type = p_scene_type
	mission_weights_fx = p_mission_weights_fx
	encounter_cap = p_encounter_cap
	deck = p_deck
