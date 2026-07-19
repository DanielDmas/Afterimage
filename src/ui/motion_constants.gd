## art_direction.md §7's motion standards ("theme constants, tech §8"):
## timings and easing names for a future UI's tween/animation calls.
## Plain named constants, not wired to any actual Tween/animation yet —
## no UI exists to animate before this pass, and no scene-tree-dependent
## code belongs in these sim/logic-adjacent classes anyway
## (tech_guidelines §2.2).
class_name MotionConstants
extends RefCounted

const MICRO_INTERACTION_MS: int = 120
const PANEL_TRANSITION_MS: int = 180
const SCENE_TRANSITION_MS: int = 300

## Godot Tween.TransitionType/EaseType names these correspond to
## (TRANS_CUBIC + EASE_OUT / EASE_IN_OUT) — named as strings here rather
## than referencing Tween's enums directly, since this class has no Tween
## to attach to yet; a future UI pass maps these names to the real enum
## values once it does.
const EASING_ARRIVALS: String = "cubic_out"
const EASING_MOVES: String = "cubic_in_out"

## "Every animation is interruptible by input — the UI never makes the
## player wait for a flourish" and "every input acknowledged within
## 100 ms by something physical" — both behavioral contracts a future UI
## must honor, not something this data class can enforce by itself.
const INPUT_ACKNOWLEDGEMENT_MAX_MS: int = 100
