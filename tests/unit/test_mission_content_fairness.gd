extends AfterimageTestCase

## Proves docs/review_and_forward_plan.md's F1 is actually closed: a real
## op_class string + real content-authored params round-trips through
## OpFactory into a live, correctly-tagged DistortionOp — and, the
## load-bearing case, content/missions/m00_stub/mission.json's *real*
## committed deck, loaded through the same MissionLoader the runtime
## uses, builds cleanly and passes FairnessAuditor.validate() with zero
## violations. This is master_plan.md §10's "fairness auditor runs on
## every content commit" promise, made real: a broken mission.json —
## wrong param shape, an op class with no constructor yet — now fails
## this exact test in CI, not silently at whatever point a player
## actually reached that content.


func test_op_factory_builds_subtitle_drift_from_params() -> void:
	var entry := DeckEntry.new(
		"SubtitleDrift", 1, 5, [], {"drifted_text": "wrong", "dramatic_intent": "grief"}
	)
	var op: DistortionOp = OpFactory.build(entry)
	assert_true(op is SubtitleDrift)
	assert_eq((op as SubtitleDrift).drifted_text, "wrong")
	assert_eq(op.dramatic_intent, "grief")
	assert_eq(op.op_class, "SubtitleDrift")


func test_op_factory_subtitle_drift_defaults_dramatic_intent() -> void:
	var entry := DeckEntry.new("SubtitleDrift", 1, 5, [], {"drifted_text": "wrong"})
	var op: DistortionOp = OpFactory.build(entry)
	assert_eq(op.dramatic_intent, "doubt")


func test_op_factory_builds_audio_swap_from_params() -> void:
	var entry := DeckEntry.new(
		"AudioSwap", 1, 8, [], {"target_source_id": 1, "swapped_tag": "static"}
	)
	var op: DistortionOp = OpFactory.build(entry)
	assert_true(op is AudioSwap)
	assert_eq((op as AudioSwap).target_source_id, 1)
	assert_eq((op as AudioSwap).swapped_tag, "static")


func test_op_factory_builds_phantom_audio_from_params() -> void:
	var entry := DeckEntry.new(
		"PhantomAudio",
		1,
		8,
		[],
		{"phantom_position": {"x": 100, "y": 200}, "phantom_tag": "whisper"}
	)
	var op: DistortionOp = OpFactory.build(entry)
	assert_true(op is PhantomAudio)
	assert_eq((op as PhantomAudio).phantom_position, Vector2i(100, 200))
	assert_eq((op as PhantomAudio).phantom_tag, "whisper")


func test_op_factory_builds_phantom_entity_with_default_facing() -> void:
	var entry := DeckEntry.new(
		"PhantomEntity",
		3,
		25,
		[],
		{"phantom_position": {"x": 300, "y": 400}, "entity_kind": "figure"}
	)
	var op: DistortionOp = OpFactory.build(entry)
	assert_true(op is PhantomEntity)
	assert_eq((op as PhantomEntity).phantom_position, Vector2i(300, 400))
	assert_eq((op as PhantomEntity).entity_kind, "figure")
	assert_eq((op as PhantomEntity).phantom_facing_dir, Vector2i(1, 0))


func test_op_factory_builds_phantom_entity_with_explicit_facing() -> void:
	var entry := (
		DeckEntry
		. new(
			"PhantomEntity",
			3,
			25,
			[],
			{
				"phantom_position": {"x": 0, "y": 0},
				"entity_kind": "figure",
				"phantom_facing_dir": {"x": -1, "y": 0},
			}
		)
	)
	var op: DistortionOp = OpFactory.build(entry)
	assert_eq((op as PhantomEntity).phantom_facing_dir, Vector2i(-1, 0))


func test_op_factory_builds_hud_glitch_from_params() -> void:
	var entry := DeckEntry.new(
		"HUDGlitch", 2, 10, [], {"target_element_id": "clock", "glitched_value": "23:41"}
	)
	var op: DistortionOp = OpFactory.build(entry)
	assert_true(op is HUDGlitch)
	assert_eq((op as HUDGlitch).target_element_id, "clock")
	assert_eq((op as HUDGlitch).glitched_value, "23:41")


func test_op_factory_builds_object_swap_from_params() -> void:
	var entry := DeckEntry.new(
		"ObjectSwap", 2, 12, [], {"target_prop_id": 7, "swapped_kind": "pistol"}
	)
	var op: DistortionOp = OpFactory.build(entry)
	assert_true(op is ObjectSwap)
	assert_eq((op as ObjectSwap).target_prop_id, 7)
	assert_eq((op as ObjectSwap).swapped_kind, "pistol")


func test_op_factory_builds_familiar_face_from_params() -> void:
	var entry := DeckEntry.new(
		"FamiliarFace",
		2,
		15,
		[],
		{"target_actor_id": 2, "familiar_face_id": "eliska_ledger:jana_martinu"}
	)
	var op: DistortionOp = OpFactory.build(entry)
	assert_true(op is FamiliarFace)
	assert_eq((op as FamiliarFace).target_actor_id, 2)
	assert_eq((op as FamiliarFace).familiar_face_id, "eliska_ledger:jana_martinu")


func test_op_factory_builds_entity_mask_from_params() -> void:
	var entry := DeckEntry.new("EntityMask", 3, 25, [], {"target_actor_id": 3})
	var op: DistortionOp = OpFactory.build(entry)
	assert_true(op is EntityMask)
	assert_eq((op as EntityMask).target_actor_id, 3)
	assert_eq(op.dramatic_intent, "dread")


func test_op_factory_builds_geometry_swap_from_params() -> void:
	var entry := DeckEntry.new(
		"GeometrySwap", 3, 20, [], {"target_cell_id": "corridor_3", "swapped_kind": "door"}
	)
	var op: DistortionOp = OpFactory.build(entry)
	assert_true(op is GeometrySwap)
	assert_eq((op as GeometrySwap).target_cell_id, "corridor_3")
	assert_eq((op as GeometrySwap).swapped_kind, "door")


func test_op_factory_builds_time_gap_from_params() -> void:
	var entry := DeckEntry.new("TimeGap", 4, 30, [], {"duration_ticks": 900})
	var op: DistortionOp = OpFactory.build(entry)
	assert_true(op is TimeGap)
	assert_eq((op as TimeGap).duration_ticks, 900)
	assert_eq(op.dramatic_intent, "dread")


func test_op_factory_builds_memory_edit_from_params() -> void:
	var entry := DeckEntry.new(
		"MemoryEdit", 4, 30, [], {"target_entry_id": "night_3", "edited_text": "wrong"}
	)
	var op: DistortionOp = OpFactory.build(entry)
	assert_true(op is MemoryEdit)
	assert_eq((op as MemoryEdit).target_entry_id, "night_3")
	assert_eq((op as MemoryEdit).edited_text, "wrong")


## Every real op_class OpFactory can build already sets its own
## fairness_tags correctly inside its own _init() (Pass 9/12) — proving
## this here closes the loop: content authoring params never touches
## Charter compliance at all, structurally, not just by convention.
func test_built_ops_carry_their_own_hardcoded_fairness_tags() -> void:
	var entry := DeckEntry.new("SubtitleDrift", 1, 5, [], {"drifted_text": "x"})
	var op: DistortionOp = OpFactory.build(entry)
	assert_true("charter_rule_5_always_disclosable" in op.fairness_tags)


## The actual, load-bearing proof. All eleven §4.2 taxonomy classes now
## have a real op_class entry in the committed mission (docs/forward_dev_plan.md
## Phase A), so this one test exercises every OpFactory build_* branch
## against real content, not just the four Pass 9 shipped with.
func test_real_stub_mission_deck_builds_and_passes_the_fairness_auditor() -> void:
	var package: MissionPackage = MissionLoader.load_from_file(
		"res://content/missions/m00_stub/mission.json"
	)
	assert_eq(package.deck.size(), 11)

	var built_ops: Array[DistortionOp] = []
	for entry: DeckEntry in package.deck:
		built_ops.append(OpFactory.build(entry))

	var violations: Array[String] = FairnessAuditor.validate(built_ops, package.encounter_cap)
	assert_eq(violations, [], "expected zero fairness violations, got: %s" % [violations])


## AudioSwap's target_source_id content-authoring convention
## (OpFactory.PLAYER_SOURCE_ID) — the real mission's own AudioSwap entry
## targets the player, and OpFactory resolves that to the same actor ID
## TruthSim always assigns the player (src/sim/actor_registry.gd: IDs
## start at 1, the player is always spawned first).
func test_real_stub_mission_audio_swap_targets_the_documented_player_source_id() -> void:
	var package: MissionPackage = MissionLoader.load_from_file(
		"res://content/missions/m00_stub/mission.json"
	)
	var audio_swap_entry: DeckEntry
	for entry: DeckEntry in package.deck:
		if entry.op_class == "AudioSwap":
			audio_swap_entry = entry
	assert_not_null(audio_swap_entry)

	var op: AudioSwap = OpFactory.build(audio_swap_entry) as AudioSwap
	assert_eq(op.target_source_id, OpFactory.PLAYER_SOURCE_ID)
