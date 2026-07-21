## Turns a DeckEntry's `op_class` string + `params` Dictionary into a real,
## live DistortionOp instance — the bridge master_plan.md §10's "fairness
## auditor runs on every content commit" promise, and DistortionDirector's
## own purchase records, both needed and never had before
## (docs/review_and_forward_plan.md's F1, the review's own top finding).
##
## DistortionDirector deliberately never references a concrete op class by
## name (its own class doc: "takes plain data... rather than referencing
## MindModel or any src/sim/ class directly... equally plain data" —
## extended in practice to the op taxonomy too, since its purchase records
## are `{tick, op_class, tier, cost}` Strings/ints, never live instances).
## That was the right call for the Director, but it meant nothing, until
## now, ever turned a purchased `op_class` string back into something
## `FairnessAuditor.validate()` or `PerceptRenderer.render()` could
## actually use — the auditor could only ever validate hand-built op
## instances or test doubles, never a real mission's real deck.
##
## Only the four op classes with a real `_init()` today (Pass 9:
## SubtitleDrift/AudioSwap/PhantomAudio/PhantomEntity) have a build_*
## branch — the other six §4.2 taxonomy classes have no constructor to
## call yet (roadmap.md's own "remaining ops" M5 item). `build()` asserts
## clearly for those rather than returning null silently, matching
## MissionLoader's own established stance: "asserts on malformed input
## rather than handling it gracefully... a contract violation, not a
## runtime case to design around."
class_name OpFactory
extends RefCounted

## master_plan.md §4.7 territory in spirit, but concretely just a fact
## about this codebase's own actor-ID assignment (src/sim/actor_registry.gd:
## `_next_id` starts at 1, and TruthSim._init() always spawns the player
## before anything else ever calls spawn_ai()) — the player's actor ID is
## therefore always exactly 1, in every mission, deterministically. Content
## authoring a `target_source_id` for AudioSwap has nothing else stable to
## reference (AI actor IDs are assigned at spawn time, not authored), so
## this is the one symbolic content-authoring convention OpFactory commits
## to and documents here, rather than leaving mission authors to guess.
const PLAYER_SOURCE_ID: int = 1


static func build(entry: DeckEntry) -> DistortionOp:
	match entry.op_class:
		"SubtitleDrift":
			return _build_subtitle_drift(entry.params)
		"AudioSwap":
			return _build_audio_swap(entry.params)
		"PhantomAudio":
			return _build_phantom_audio(entry.params)
		"PhantomEntity":
			return _build_phantom_entity(entry.params)
	assert(
		false,
		(
			"OpFactory: no constructor for op_class '%s' yet (roadmap.md's 'remaining ops' item)"
			% entry.op_class
		)
	)
	return null


static func _build_subtitle_drift(params: Dictionary) -> SubtitleDrift:
	return SubtitleDrift.new(
		String(params["drifted_text"]), String(params.get("dramatic_intent", "doubt"))
	)


static func _build_audio_swap(params: Dictionary) -> AudioSwap:
	return AudioSwap.new(
		int(params["target_source_id"]),
		String(params["swapped_tag"]),
		String(params.get("dramatic_intent", "doubt"))
	)


static func _build_phantom_audio(params: Dictionary) -> PhantomAudio:
	return PhantomAudio.new(
		_vector2i_from(params["phantom_position"]),
		String(params["phantom_tag"]),
		String(params.get("dramatic_intent", "dread"))
	)


static func _build_phantom_entity(params: Dictionary) -> PhantomEntity:
	var facing: Vector2i = (
		_vector2i_from(params["phantom_facing_dir"])
		if params.has("phantom_facing_dir")
		else Vector2i(1, 0)
	)
	return PhantomEntity.new(
		_vector2i_from(params["phantom_position"]),
		String(params["entity_kind"]),
		facing,
		String(params.get("dramatic_intent", "paranoia"))
	)


## JSON has no vector type — positions/directions are authored as plain
## {"x": int, "y": int} objects. Godot's JSON.parse_string() parses every
## JSON number as float (the same documented gotcha MissionLoader's own
## int() casts already guard against), so the int() casts here are
## load-bearing, not decorative.
static func _vector2i_from(raw: Dictionary) -> Vector2i:
	return Vector2i(int(raw["x"]), int(raw["y"]))
