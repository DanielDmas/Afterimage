## Loads a mission package JSON file (tech_guidelines.md D7/§5.1) into a
## MissionPackage. Assumes the file has already passed
## tools/content_validator.py in CI — mission content is a system boundary
## in principle, but by the time it reaches this loader it has already
## been schema-validated at commit time, so this class asserts on
## malformed input rather than handling it gracefully (the same stance
## FixedMath.div() takes on division by zero: a contract violation, not a
## runtime case to design around).
class_name MissionLoader
extends RefCounted

const SCENE_TYPE_NAMES: Dictionary = {
	"social": DistortionDirector.SceneType.SOCIAL,
	"infiltration": DistortionDirector.SceneType.INFILTRATION,
	"combat": DistortionDirector.SceneType.COMBAT,
	"hub": DistortionDirector.SceneType.HUB,
}


static func load_from_file(path: String) -> MissionPackage:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	assert(file != null, "MissionLoader: could not open mission file: %s" % path)
	var text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	assert(typeof(parsed) == TYPE_DICTIONARY, "MissionLoader: not a JSON object: %s" % path)
	return from_dict(parsed as Dictionary)


static func from_dict(data: Dictionary) -> MissionPackage:
	var id: String = data["id"]
	var scene_type_name: String = data["scene_type"]
	assert(
		SCENE_TYPE_NAMES.has(scene_type_name),
		"MissionLoader: unknown scene_type '%s'" % scene_type_name
	)
	var scene_type: DistortionDirector.SceneType = SCENE_TYPE_NAMES[scene_type_name]

	var mission_weights_fx: Dictionary = {}
	var raw_weights: Dictionary = data.get("mission_weights", {})
	for variable_name: String in raw_weights.keys():
		mission_weights_fx[variable_name] = FixedMath.from_float(raw_weights[variable_name])

	# Godot's JSON.parse_string() parses every JSON number as float (JSON
	# itself has no separate int type) - int() casts below are load-bearing,
	# not decorative, wherever a schema-integer field becomes a GDScript int.
	var encounter_cap: int = int(data["encounter_cap"])

	var deck: Array[DeckEntry] = []
	for raw_entry: Dictionary in data["deck"] as Array:
		var variable_affinity: Array[String] = []
		for variable_name: String in raw_entry["variable_affinity"] as Array:
			variable_affinity.append(variable_name)
		(
			deck
			. append(
				(
					DeckEntry
					. new(
						raw_entry["op_class"],
						int(raw_entry["tier"]),
						int(raw_entry["cost"]),
						variable_affinity,
						# passed through untyped and unvalidated - OpFactory.build() is
						# the one place that knows what shape a given op_class's
						# params actually need, and asserts clearly if they don't
						# match; MissionLoader stays as op-class-agnostic as DeckEntry
						# itself always has been.
						raw_entry.get("params", {})
					)
				)
			)
		)

	return MissionPackage.new(id, scene_type, mission_weights_fx, encounter_cap, deck)
