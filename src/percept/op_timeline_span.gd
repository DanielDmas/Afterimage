## One row of the Afterimage Theater's op timeline (master_plan.md §4.12:
## "every DistortionOp as an annotated span (class, cause variable,
## resolution: grounded / believed / acted-upon)"). Plain data, matching
## DeckEntry's own "content is data, not code" shape — a real deriving
## mechanism (turning a live DistortionDirector's purchase log plus its
## lifecycle events into these spans automatically) doesn't exist yet;
## these are constructed directly for now, the same "state now, consumer
## later" pattern DeckEntry itself started under in Pass 12.
class_name OpTimelineSpan
extends RefCounted

enum Resolution { GROUNDED, BELIEVED, ACTED_UPON, UNDISCLOSED }

var op_class: String
var tier: int
var cause_variable: String
var tick_start: int
var tick_end: int
var resolution: Resolution


func _init(
	p_op_class: String,
	p_tier: int,
	p_cause_variable: String,
	p_tick_start: int,
	p_tick_end: int,
	p_resolution: Resolution = Resolution.UNDISCLOSED
) -> void:
	op_class = p_op_class
	tier = p_tier
	cause_variable = p_cause_variable
	tick_start = p_tick_start
	tick_end = p_tick_end
	resolution = p_resolution


func is_active_at(tick: int) -> bool:
	return tick >= tick_start and tick <= tick_end
