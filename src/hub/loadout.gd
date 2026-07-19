## master_plan.md §4.7/§4.11: the equipped-for-tonight kit and its
## cover-consistency check — "night-phase kit vs. cover-consistency
## check." A loadout is cover-consistent only if every equipped item is;
## one inconsistent item (a silenced weapon under a day coat) is enough
## to flag the whole kit, matching how a single tell condition catches a
## lie (§5's `lies[{claim, tell}]`) rather than averaging risk away.
class_name Loadout
extends RefCounted

var equipped: Array[LoadoutItem] = []


func equip(item: LoadoutItem) -> void:
	if not equipped.has(item):
		equipped.append(item)


func unequip(item: LoadoutItem) -> void:
	equipped.erase(item)


func is_equipped(item: LoadoutItem) -> bool:
	return equipped.has(item)


func is_cover_consistent() -> bool:
	for item: LoadoutItem in equipped:
		if not item.cover_consistent:
			return false
	return true


func inconsistent_items() -> Array[LoadoutItem]:
	var result: Array[LoadoutItem] = []
	for item: LoadoutItem in equipped:
		if not item.cover_consistent:
			result.append(item)
	return result
