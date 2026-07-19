## Base class for a percept-layer decorator (master_plan.md §4.1: "the
## percept layer is computed each frame as truth + active DistortionOps").
## An op takes a percept snapshot Dictionary (already a plain-value copy —
## see PerceptRenderer's class doc) and returns a transformed one; it
## never sees a TruthSim/Actor reference to write back to, because none
## ever crosses into `src/percept/` in the first place.
##
## Pass 8 scope is deliberately just this pipeline shape: the identity
## base class and PerceptRenderer's compose-in-order machinery. The real
## op classes (`SubtitleDrift`, `AudioSwap`, `PhantomAudio`,
## `PhantomEntity`, master_plan §4.2) are Pass 9's job, once there's a
## real percept-side renderer consuming this snapshot to give them a
## reason to exist — the same "build the pipe, not the water" order
## every prior pass has used for its own standalone-before-wired pieces.
class_name PerceptOp
extends RefCounted


## Identity by default; every real op overrides this.
func apply(snapshot: Dictionary) -> Dictionary:
	return snapshot
