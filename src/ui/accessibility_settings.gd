## ux_charter.md §4's Quality-of-Life Inventory ("committed, not
## aspirational") as real settings state — the toggles/steps a future
## options screen (Pass 20+/post-slice) will bind widgets to. Several
## inventory items (colorblind-safe double coding, photosensitivity-safe
## rendering, screen-reader output, subtitle plates) need actual art/UI
## presentation this pass doesn't build (no Godot scene exists to render
## into) — what's real here is the settings *state* and, where a real
## mechanism already exists to gate, the actual gating logic.
class_name AccessibilitySettings
extends RefCounted

## §4.16/master_plan §4.6: Ground's own GroundState takes a plain
## "requested this tick" bool, deliberately agnostic to whether it came
## from a continuous hold or a hold-to-toggle scheme — this is that
## accessibility preference, real and settable, even though no input-
## sampling layer exists yet to read it (Pass 6's "InputFrame arrives
## already resolved" contract means whatever eventually samples raw input
## is the thing that reads this setting, not GroundState itself).
enum GroundInputMode { HOLD, TOGGLE }

## "UI scale (4 steps)" — ux_charter §4.
const UI_SCALE_FACTORS: Array[float] = [1.0, 1.15, 1.3, 1.5]
## Subtitle size, stepped the same way ("subtitle size... options").
const SUBTITLE_SIZE_FACTORS: Array[float] = [1.0, 1.25, 1.5, 1.75]

var ui_scale_step: int = 0
var subtitle_size_step: int = 0
var colorblind_safe_mode: bool = false
var photosensitivity_safe_mode: bool = false
var clarity_mode_enabled: bool = false
var screen_reader_enabled: bool = false
var ground_input_mode: GroundInputMode = GroundInputMode.HOLD
var mind_dashboard_shows_numbers: bool = false  ## "numbers togglable in options" — §4.11


func set_ui_scale_step(step: int) -> void:
	assert(
		step >= 0 and step < UI_SCALE_FACTORS.size(),
		(
			"AccessibilitySettings: ui_scale_step %d out of range [0, %d)"
			% [step, UI_SCALE_FACTORS.size()]
		)
	)
	ui_scale_step = step


func ui_scale_factor() -> float:
	return UI_SCALE_FACTORS[ui_scale_step]


func set_subtitle_size_step(step: int) -> void:
	assert(
		step >= 0 and step < SUBTITLE_SIZE_FACTORS.size(),
		(
			"AccessibilitySettings: subtitle_size_step %d out of range [0, %d)"
			% [step, SUBTITLE_SIZE_FACTORS.size()]
		)
	)
	subtitle_size_step = step


func subtitle_size_factor() -> float:
	return SUBTITLE_SIZE_FACTORS[subtitle_size_step]


## Clarity Mode's actual on/off gate (master_plan §4.16, Charter rule 6) —
## `ClarityMode.active_flags()` itself (Pass 10) is unconditional reporting
## over whatever ops are active; its own docstring named this settings
## class as where the toggle belongs. When disabled, a caller shouldn't
## even query it — returning an empty list here, not just "flags nobody
## reads," keeps that contract enforced in one place.
func clarity_flags_for(active_ops: Array) -> Array:
	if not clarity_mode_enabled:
		return []
	return ClarityMode.active_flags(active_ops)
