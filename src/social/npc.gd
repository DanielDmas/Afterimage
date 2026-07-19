## An Argus NPC's mind (foundation_blueprints.md §5): `NPC {id, portraitSet,
## personality{pride, fear, greed, loyaltyTargets[]}, knows[claimId],
## hides[{claimId, unlock:Predicate}], lies[{claim, tell:Predicate}],
## gossipEdges[{npcId, delayDays, distortion}], trust:int, suspicion:ledger,
## relationship:tier, state:enum}`.
##
## `suspicion` is deliberately NOT a field here: it lives in SuspicionGraph,
## keyed by npc id, since suspicion is inherently relational (who's
## noticing what about Radek) rather than an NPC's own private property —
## matching how GroundState/FocusState live on TruthSim rather than on
## Actor. `portraitSet` (art_direction-facing) has no consumer before real
## UI (Pass 19) and isn't modeled here — plain data with nothing to render
## yet, the same "no consumer" deferral used throughout.
##
## KNOWS may include false beliefs genuinely held (plain claim ID strings —
## whether a known claim is objectively true is a Claims/Provenance
## question, Pass 17's job, not this class's). HIDES/LIES entries carry
## Predicate trees (src/core/predicate.gd, reused as-is) as their
## unlock/tell conditions — evaluated by whatever system checks them
## (suspicion countermeasures, dialogue), not by NPC itself.
class_name NPC
extends RefCounted

enum State { NEUTRAL, WARY, HOSTILE, ALLY }

var id: String
var personality: Dictionary  ## {pride: int, fear: int, greed: int} 0-10 each
var loyalty_targets: Array[String]
var knows: Array[String]
var hides: Array[Dictionary]  ## [{claim_id: String, unlock: Dictionary (predicate)}]
var lies: Array[Dictionary]  ## [{claim_id: String, tell: Dictionary (predicate)}]
var gossip_edges: Array[Dictionary]  ## [{npc_id: String, delay_days: int, distortion: bool}]
var trust: int
var relationship_tier: int
var state: State


func _init(
	p_id: String,
	p_personality: Dictionary = {},
	p_loyalty_targets: Array[String] = [],
	p_knows: Array[String] = [],
	p_hides: Array[Dictionary] = [],
	p_lies: Array[Dictionary] = [],
	p_gossip_edges: Array[Dictionary] = [],
	p_trust: int = 0,
	p_relationship_tier: int = 0,
	p_state: State = State.NEUTRAL
) -> void:
	id = p_id
	personality = p_personality
	loyalty_targets = p_loyalty_targets
	knows = p_knows
	hides = p_hides
	lies = p_lies
	gossip_edges = p_gossip_edges
	trust = p_trust
	relationship_tier = p_relationship_tier
	state = p_state


func knows_claim(claim_id: String) -> bool:
	return knows.has(claim_id)
