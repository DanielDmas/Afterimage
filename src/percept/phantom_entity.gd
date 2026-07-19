## master_plan.md §4.2: "A full entity (person, car, dog) with no
## truth-layer counterpart; obeys Charter rule 1 absolutely." Ground
## response: "Shimmers and dissolves over ~1 s."
##
## Charter rule 1 (§4.5): "Phantoms never deal damage and never block
## movement or bullets." That guarantee is structural here, not just
## asserted: this op only ever appends to a percept-side snapshot
## Dictionary that TruthSim never reads back (Pass 8's boundary,
## enforced in CI by tools/percept_truth_boundary_lint.py) — there is no
## code path by which a phantom entity's presence in this list could
## affect collision, damage, or any other truth outcome, because nothing
## under src/sim/ ever sees this data at all.
##
## Tagged with `-absi(get_instance_id())` as the phantom's `id`, so it can
## never collide with a real actor id (which ActorRegistry always assigns
## starting at 1) and resolve_grounded() can remove exactly the entity
## this op instance added. The `absi()` wrap matters: Godot 4 sets an
## internal flag bit on a RefCounted object's instance id that can read
## back as already-negative in GDScript's signed 64-bit `int` — a bare
## `-get_instance_id()` could double-negate back to positive for some
## instances, which a CI run caught (a real Godot behavior no local
## editor could have surfaced first). `absi()` first forces the sign
## unconditionally, regardless of which way Godot's own convention goes.
class_name PhantomEntity
extends DistortionOp

const TIER: int = 3
const COST: int = 25

var phantom_position: Vector2i
var phantom_facing_dir: Vector2i
var entity_kind: String


func _init(
	p_phantom_position: Vector2i,
	p_entity_kind: String,
	p_phantom_facing_dir: Vector2i = Vector2i(1, 0),
	p_dramatic_intent: String = "paranoia"
) -> void:
	op_class = "PhantomEntity"
	tier = TIER
	cost = COST
	dramatic_intent = p_dramatic_intent
	fairness_tags = [
		"charter_rule_1_never_damages_never_blocks", "charter_rule_5_always_disclosable"
	]
	phantom_position = p_phantom_position
	phantom_facing_dir = p_phantom_facing_dir
	entity_kind = p_entity_kind


func apply(snapshot: Dictionary) -> Dictionary:
	var out: Dictionary = snapshot.duplicate(true)
	var actors: Array = (out.get("actors", []) as Array).duplicate(true)
	(
		actors
		. append(
			{
				"id": -absi(get_instance_id()),
				"position": phantom_position,
				"facing_dir": phantom_facing_dir,
				"entity_kind": entity_kind,
				"is_alive": true,
				"is_phantom": true,
			}
		)
	)
	out["actors"] = actors
	return out


func resolve_grounded(snapshot: Dictionary) -> Dictionary:
	var out: Dictionary = snapshot.duplicate(true)
	var actors: Array = []
	for a: Dictionary in out.get("actors", []) as Array:
		var is_mine: bool = a.get("is_phantom", false) and a.get("id") == -absi(get_instance_id())
		if not is_mine:
			actors.append(a)
	out["actors"] = actors
	return out
