## Per-archetype perception configuration (master_plan.md §4.9). Pass 5
## scope deliberately limits the Sentry/Professional difference to
## perception parameters and whether REPORT is used — tactical behaviors
## named in the design (Professional "flanks, checks corners") need
## pathfinding and combat that don't exist yet (later passes); building
## bespoke behavior trees for them now, with nothing to actually execute
## the tactics, would be scope creep with no way to verify it does
## anything real.
class_name AiArchetype
extends RefCounted

var vision_range_mm: int
var vision_cos_sq_half_angle_fx: int
var uses_report: bool


func _init(p_vision_range_mm: int, p_half_angle_degrees: float, p_uses_report: bool) -> void:
	vision_range_mm = p_vision_range_mm
	vision_cos_sq_half_angle_fx = VisionCone.cos_sq_half_angle_fx_from_degrees(p_half_angle_degrees)
	uses_report = p_uses_report


## "Sentry — static/patrol, teaches vision and noise" (master_plan §4.9):
## a shorter, narrower cone; no radio, so spotting the player never
## triggers REPORT.
static func sentry() -> AiArchetype:
	return AiArchetype.new(6000, 50.0, false)


## "Professional — Argus-trained... calls contacts in on the net"
## (master_plan §4.9): longer, wider cone, and spotting the player is
## always reported.
static func professional() -> AiArchetype:
	return AiArchetype.new(8000, 60.0, true)
