## One piece of equipment in the Safehouse Hub's loadout screen
## (master_plan.md §4.11: "night-phase kit vs. cover-consistency check
## (§4.7); Radek's wardrobe and props for day scenes"). Plain data,
## matching DeckEntry/NPC's own "content is data, not code" shape.
class_name LoadoutItem
extends RefCounted

enum Category { WEAPON, TOOL, PROP }

var id: String
var display_name: String
var category: Category
var cover_consistent: bool


func _init(
	p_id: String, p_display_name: String, p_category: Category, p_cover_consistent: bool
) -> void:
	id = p_id
	display_name = p_display_name
	category = p_category
	cover_consistent = p_cover_consistent
