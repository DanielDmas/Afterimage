## master_plan.md §4.7: the Argus social graph's suspicion side — owns one
## SuspicionLedger per NPC and the named threshold bands ("at 25 (wary)
## they test Radek... at 50 (active) counter-surveillance events enter the
## deck... at 75 (convinced) the cover-blown fork triggers"). The NPC
## roster itself (personality/knows/hides/lies/gossip_edges) is stored
## alongside so GossipSim has one place to read both from.
class_name SuspicionGraph
extends RefCounted

enum Level { CALM, WARY, ACTIVE, CONVINCED }

const THRESHOLD_WARY: int = 25
const THRESHOLD_ACTIVE: int = 50
const THRESHOLD_CONVINCED: int = 75

var _npcs: Dictionary = {}  ## npc_id -> NPC
var _ledgers: Dictionary = {}  ## npc_id -> SuspicionLedger


func add_npc(npc: NPC) -> void:
	_npcs[npc.id] = npc
	_ledgers[npc.id] = SuspicionLedger.new()


func has_npc(npc_id: String) -> bool:
	return _npcs.has(npc_id)


func npc(npc_id: String) -> NPC:
	return _npcs[npc_id]


func ledger(npc_id: String) -> SuspicionLedger:
	return _ledgers[npc_id]


func add_entry(npc_id: String, entry_type: String, weight: int, day_added: int) -> void:
	ledger(npc_id).add_entry(entry_type, weight, day_added)


func total_for(npc_id: String, current_day: int) -> int:
	return ledger(npc_id).total(current_day)


static func level_for_total(total: int) -> Level:
	if total >= THRESHOLD_CONVINCED:
		return Level.CONVINCED
	if total >= THRESHOLD_ACTIVE:
		return Level.ACTIVE
	if total >= THRESHOLD_WARY:
		return Level.WARY
	return Level.CALM


func level_for(npc_id: String, current_day: int) -> Level:
	return level_for_total(total_for(npc_id, current_day))
