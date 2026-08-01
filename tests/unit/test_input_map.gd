extends AfterimageTestCase

## project.godot's [input] section can't be checked by gdlint/gdformat (it's
## not GDScript) and there is no local Godot editor in this environment to
## hand-verify a resource literal against — so this test is the actual
## verification that the Pass 6 InputMap section parsed and every combat-
## verb action (master_plan.md §4.9) registered, run for real inside
## Godot by CI. See project.godot's D11 note for why no default key/button
## is bound yet.

const EXPECTED_ACTIONS: Array = [
	"move_up",
	"move_down",
	"move_left",
	"move_right",
	"sprint",
	"crouch",
	"lean_left",
	"lean_right",
	"aim",
	"fire",
	"reload",
	"takedown",
	"throw",
	"focus",
]


func test_every_combat_verb_action_is_registered() -> void:
	for action: String in EXPECTED_ACTIONS:
		assert_true(InputMap.has_action(action), "missing InputMap action: %s" % action)
