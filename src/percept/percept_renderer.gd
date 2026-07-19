## Composes a truth snapshot with active DistortionOps into the percept
## view actually shown to the player (master_plan.md §4.1: "percept =
## truth + active DistortionOps," §5.2's PerceptRenderer). This is the
## one non-negotiable architectural boundary in the whole project: "all
## gameplay consequences are computed from truth events only," and the
## enforcement here isn't a naming convention — `render()`'s input is
## already a plain-value snapshot Dictionary (see
## TruthSim.capture_percept_snapshot()'s class doc), so there is no
## Actor/TruthSim reference anywhere in this file for an op to mutate
## even if one tried. `tools/percept_truth_boundary_lint.py` (run in CI)
## statically confirms nothing under `src/percept/` ever references a
## `src/sim/` class by name at all, as a second, independent guarantee on
## top of the type-shape one.
class_name PerceptRenderer
extends RefCounted


## Applies every op in `active_ops`, in order, to `truth_snapshot`.
## Deep-copies the input first so ops can never be seen to have mutated
## the caller's original snapshot out from under it — each op receives
## (and must return) its own independent Dictionary.
static func render(truth_snapshot: Dictionary, active_ops: Array) -> Dictionary:
	var percept: Dictionary = truth_snapshot.duplicate(true)
	for op: PerceptOp in active_ops:
		percept = op.apply(percept)
	return percept
