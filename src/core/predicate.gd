## The Predicate language: one small declarative condition language, one
## evaluator, used everywhere — dialogue guards/unlocks, mission event
## triggers, suspicion countermeasures, debrief consequence rules, ending
## gates, and the content validators (foundation_blueprints.md §2).
##
## A predicate is plain data (a Dictionary), never code, so it can live in
## JSON content files and be authored by writers, not programmers:
##   {"op": "trustAtLeast", "args": {"npc": "npc.doubek", "n": 40}}
##   {"op": "all", "args": {"predicates": [pred_a, pred_b]}}
##
## Adding an operator is a spec change to this file + this file's tests,
## never an inline hack elsewhere (foundation_blueprints.md §2 discipline).
class_name PredicateEvaluator
extends RefCounted

const COMBINATORS: Array[String] = ["all", "any", "not"]

## op name -> Array[{"name": String, "type": int}] where type is a
## typeof()-compatible constant. Used by both evaluate() (to fail loudly on
## malformed content instead of guessing) and validate() (static content
## linting, no WorldQuery needed).
const OPERATOR_SPECS: Dictionary = {
	"hasClaim": [{"name": "id", "type": TYPE_STRING}],
	"claimAsserted": [{"name": "id", "type": TYPE_STRING}],  # optional "mode": TYPE_STRING
	"trustAtLeast": [{"name": "npc", "type": TYPE_STRING}, {"name": "n", "type": TYPE_INT}],
	"suspicionAtLeast": [{"name": "target", "type": TYPE_STRING}, {"name": "n", "type": TYPE_INT}],
	"mindBand": [{"name": "variable", "type": TYPE_STRING}, {"name": "band", "type": TYPE_STRING}],
	"dayAfter": [{"name": "day", "type": TYPE_INT}],
	"dayBefore": [{"name": "day", "type": TYPE_INT}],
	"missionDone": [{"name": "id", "type": TYPE_STRING}],
	"flag": [{"name": "name", "type": TYPE_STRING}],
	"flagValue": [{"name": "name", "type": TYPE_STRING}, {"name": "value", "type": -1}],  # any type
	"killsAtLeast": [{"name": "context", "type": TYPE_STRING}, {"name": "n", "type": TYPE_INT}],
	"witnessed": [{"name": "eventTag", "type": TYPE_STRING}],
	"grounded": [{"name": "ref", "type": TYPE_STRING}],
	"coverBlownTo": [],  # optional "faction": TYPE_STRING
	"endingGate": [{"name": "family", "type": TYPE_STRING}],
	"itemHeld": [{"name": "id", "type": TYPE_STRING}],
	"relationshipAtLeast":
	[{"name": "npc", "type": TYPE_STRING}, {"name": "tier", "type": TYPE_INT}],
}

const VALID_MIND_VARIABLES: Array[String] = ["stress", "fatigue", "moral_injury", "identity_strain"]
const VALID_MIND_BANDS: Array[String] = ["quiet", "murmur", "loud", "crisis"]


## Evaluates a predicate tree against a WorldQuery. Malformed predicates
## (unknown op, missing required arg) fail loudly via assert rather than
## silently evaluating to false — content should never reach runtime
## unvalidated (see validate() below, which the content validator runs
## ahead of time, in CI, on every predicate in every file).
static func evaluate(predicate: Dictionary, query: WorldQuery) -> bool:
	assert(predicate.has("op"), "Predicate missing 'op' key: %s" % [predicate])
	var op: String = predicate["op"]
	var args: Dictionary = predicate.get("args", {})

	match op:
		"all":
			var preds: Array = args.get("predicates", [])
			for p: Dictionary in preds:
				if not evaluate(p, query):
					return false
			return true
		"any":
			var preds: Array = args.get("predicates", [])
			for p: Dictionary in preds:
				if evaluate(p, query):
					return true
			return false
		"not":
			var inner: Dictionary = args.get("predicate", {})
			return not evaluate(inner, query)
		"hasClaim":
			return query.has_claim(args["id"])
		"claimAsserted":
			return query.claim_asserted(args["id"], args.get("mode", ""))
		"trustAtLeast":
			return query.trust(args["npc"]) >= int(args["n"])
		"suspicionAtLeast":
			return query.suspicion(args["target"]) >= int(args["n"])
		"mindBand":
			return query.mind_band(args["variable"]) == args["band"]
		"dayAfter":
			return query.current_day() > int(args["day"])
		"dayBefore":
			return query.current_day() < int(args["day"])
		"missionDone":
			return query.mission_done(args["id"])
		"flag":
			return query.flag(args["name"])
		"flagValue":
			return query.flag_value(args["name"]) == args["value"]
		"killsAtLeast":
			return query.kills(args["context"]) >= int(args["n"])
		"witnessed":
			return query.witnessed(args["eventTag"])
		"grounded":
			return query.grounded(args["ref"])
		"coverBlownTo":
			return query.cover_blown_to(args.get("faction", ""))
		"endingGate":
			return query.ending_gate_reached(args["family"])
		"itemHeld":
			return query.item_held(args["id"])
		"relationshipAtLeast":
			return query.relationship_tier(args["npc"]) >= int(args["tier"])
		_:
			assert(false, "Unknown predicate operator: %s" % op)
			return false


## Pure static structural validation — no WorldQuery required. Returns an
## array of human-readable error strings; empty means the predicate tree is
## well-formed. This is what the content validator (tools/) runs over every
## predicate in every content file in CI (foundation_blueprints.md §7).
static func validate(predicate: Variant, path: String = "$") -> Array[String]:
	var errors: Array[String] = []
	if typeof(predicate) != TYPE_DICTIONARY:
		errors.append(
			"%s: predicate must be a Dictionary, got %s" % [path, type_string(typeof(predicate))]
		)
		return errors

	var pred: Dictionary = predicate
	if not pred.has("op"):
		errors.append("%s: missing required 'op' key" % path)
		return errors
	if typeof(pred["op"]) != TYPE_STRING:
		errors.append("%s: 'op' must be a String" % path)
		return errors

	var op: String = pred["op"]
	var args: Dictionary = pred.get("args", {})

	if op in COMBINATORS:
		errors.append_array(_validate_combinator(op, args, path))
		return errors

	if not OPERATOR_SPECS.has(op):
		errors.append("%s: unknown operator '%s'" % [path, op])
		return errors

	var specs: Array = OPERATOR_SPECS[op]
	for spec: Dictionary in specs:
		var arg_name: String = spec["name"]
		var expected_type: int = spec["type"]
		if not args.has(arg_name):
			errors.append("%s: operator '%s' missing required arg '%s'" % [path, op, arg_name])
			continue
		if expected_type != -1 and typeof(args[arg_name]) != expected_type:
			errors.append(
				(
					"%s: operator '%s' arg '%s' expected %s, got %s"
					% [
						path,
						op,
						arg_name,
						type_string(expected_type),
						type_string(typeof(args[arg_name]))
					]
				)
			)

	if op == "mindBand":
		if args.get("variable") is String and not VALID_MIND_VARIABLES.has(args["variable"]):
			errors.append(
				(
					"%s: mindBand 'variable' must be one of %s, got '%s'"
					% [path, VALID_MIND_VARIABLES, args.get("variable")]
				)
			)
		if args.get("band") is String and not VALID_MIND_BANDS.has(args["band"]):
			errors.append(
				(
					"%s: mindBand 'band' must be one of %s, got '%s'"
					% [path, VALID_MIND_BANDS, args.get("band")]
				)
			)

	return errors


static func _validate_combinator(op: String, args: Dictionary, path: String) -> Array[String]:
	var errors: Array[String] = []
	match op:
		"all", "any":
			if not args.has("predicates"):
				errors.append("%s: '%s' missing required arg 'predicates'" % [path, op])
			elif typeof(args["predicates"]) != TYPE_ARRAY:
				errors.append("%s: '%s' arg 'predicates' must be an Array" % [path, op])
			else:
				var preds: Array = args["predicates"]
				if preds.is_empty():
					errors.append(
						(
							"%s: '%s' has an empty 'predicates' list (always %s)"
							% [path, op, "true" if op == "all" else "false"]
						)
					)
				for i: int in preds.size():
					errors.append_array(validate(preds[i], "%s.%s[%d]" % [path, op, i]))
		"not":
			if not args.has("predicate"):
				errors.append("%s: 'not' missing required arg 'predicate'" % path)
			else:
				errors.append_array(validate(args["predicate"], "%s.not" % path))
	return errors
