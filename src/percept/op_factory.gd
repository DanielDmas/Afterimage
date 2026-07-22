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
## All eleven op classes (docs/forward_dev_plan.md Phase A: Pass 9's
## original four plus HUDGlitch/ObjectSwap/FamiliarFace/EntityMask/
## GeometrySwap/TimeGap/MemoryEdit) now have a real `_init()` and a
## build_* branch here. `build()` still asserts clearly for any unknown
## op_class string rather than returning null silently, matching
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
		"HUDGlitch":
			return _build_hud_glitch(entry.params)
		"ObjectSwap":
			return _build_object_swap(entry.params)
		"FamiliarFace":
			return _build_familiar_face(entry.params)
		"EntityMask":
			return _build_entity_mask(entry.params)
		"GeometrySwap":
			return _build_geometry_swap(entry.params)
		"TimeGap":
			return _build_time_gap(entry.params)
		"MemoryEdit":
			return _build_memory_edit(entry.params)
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


static func _build_hud_glitch(params: Dictionary) -> HUDGlitch:
	return HUDGlitch.new(
		String(params["target_element_id"]),
		String(params["glitched_value"]),
		String(params.get("dramatic_intent", "doubt"))
	)


static func _build_object_swap(params: Dictionary) -> ObjectSwap:
	return ObjectSwap.new(
		int(params["target_prop_id"]),
		String(params["swapped_kind"]),
		String(params.get("dramatic_intent", "paranoia"))
	)


static func _build_familiar_face(params: Dictionary) -> FamiliarFace:
	return FamiliarFace.new(
		int(params["target_actor_id"]),
		String(params["familiar_face_id"]),
		String(params.get("dramatic_intent", "grief"))
	)


static func _build_entity_mask(params: Dictionary) -> EntityMask:
	return EntityMask.new(
		int(params["target_actor_id"]), String(params.get("dramatic_intent", "dread"))
	)


static func _build_geometry_swap(params: Dictionary) -> GeometrySwap:
	return GeometrySwap.new(
		String(params["target_cell_id"]),
		String(params["swapped_kind"]),
		String(params.get("dramatic_intent", "doubt"))
	)


static func _build_time_gap(params: Dictionary) -> TimeGap:
	return TimeGap.new(
		int(params["duration_ticks"]), String(params.get("dramatic_intent", "dread"))
	)


static func _build_memory_edit(params: Dictionary) -> MemoryEdit:
	return MemoryEdit.new(
		String(params["target_entry_id"]),
		String(params["edited_text"]),
		String(params.get("dramatic_intent", "grief"))
	)


## JSON has no vector type — positions/directions are authored as plain
## {"x": int, "y": int} objects. Godot's JSON.parse_string() parses every
## JSON number as float (the same documented gotcha MissionLoader's own
## int() casts already guard against), so the int() casts here are
## load-bearing, not decorative.
static func _vector2i_from(raw: Dictionary) -> Vector2i:
	return Vector2i(int(raw["x"]), int(raw["y"]))
