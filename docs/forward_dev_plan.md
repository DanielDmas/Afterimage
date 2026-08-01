# Afterimage — Forward Development Plan (v2)
**Author role:** acting creative/technical director.
**Supersedes:** the forward-plan section (§4) of `docs/review_and_forward_plan.md`, whose P1–P4 and F5 are now delivered (F1, F2, F3, F4, F5, F6, F9 closed; icon done). This document is the living forward plan from here.
**Constraint that shapes everything below:** this sandbox has GDScript + a headless CI runner + Python tooling, and **no** Godot editor, no real art/audio pipeline, and no target hardware. So the plan is organized around what is *actually buildable and verifiable here* (mechanism code, data classes, tooling, CI, tests) versus what is genuinely blocked on a human, an editor session, real assets, or hardware. Blocked items are named, not hidden.

---

## 1. Context — why this plan, and where we actually are

The 20-pass engineering arc built every mechanism M0–M4 needs, and post-arc work has been closing the *seams between* those mechanisms: the content pipeline now audits real missions (`OpFactory` + `test_mission_content_fairness.gd`), the determinism corpus now hashes the real `TruthSim`, the social-consequence loop now runs end to end (`GroundObservationBridge`), and a genuinely playable web build exists (`scenes/main.gd`, exported by `.github/workflows/export-web.yml`). **554 tests, CI green.**

But there is a gap between "every mechanism exists and is unit-tested" and "the game's actual thesis is playable end to end." The clearest evidence: the playable scene (`scenes/main.gd`) drives its one distortion through a **hardcoded** `DriftEncounter`, not through the real `mission.json → DistortionDirector → OpFactory → PerceptRenderer` pipeline that now exists and is tested in isolation. The pipeline and the playable surface have never been connected. Closing that — turning the tech demo into a real, if tiny, *mission you play, distort under, ground through, and debrief on* — is the north star of this plan.

The game's thesis is **"can you report the truth with a lying mind?"** Everything below is ordered by how directly it serves making that thesis *playable and legible*, weighted against what this sandbox can actually verify.

---

## 2. The current map — green / stubbed / blocked

**Green and load-bearing** (built, tested, wired to at least one real consumer):
`FixedMath`, `Xoshiro128StarStar`, `EventBus`, `Predicate`/`WorldQuery`, `GameStateStore`/`SaveSystem`+migrations, fixed-tick harness, determinism corpus (now on real `TruthSim`), the whole `TruthSim` (collision, LOS, sound-open-air, vision cones, utility AI, combat verbs, Ground, Focus, witnesses), the percept/truth boundary + 4 `DistortionOp`s + `PerceptRenderer`, `MindModel` (4 vars) + `SubstanceModel`, `DistortionDirector` + `FairnessAuditor` + `OpFactory` + `MissionLoader`, `ReplayTheater` v0, the dialogue DSL (`dlgc.py`) + `DialogueRunner` + `InterruptMemory`, the Argus social graph + `GroundObservationBridge`, Claims/Provenance + `DebriefLedger`, the hub skeleton, the UI shell data layer, `PrologueStub` + `DriftEncounter` + the playable web scene.

**Built but stubbed / unwired at a seam** (the real next-work surface):
- **Runtime distortion loop is not wired into the playable scene** — `scenes/main.gd` uses a hardcoded `DriftEncounter`, not the Director/OpFactory pipeline.
- **Debrief has no real event-log reducer** — `ClaimDrafter.draft_from_perceived_events()` takes *already-reduced* events; nothing turns a real `TruthSim` run's `EventBus` history into salient claim candidates.
- **Debrief consequence channels are inert** — `DebriefLedger` computes truth-delta and bills moral injury, but Doubek-trust / resource-budget / plot-flags have no store to write to.
- **AI states beyond ENGAGE do nothing** — `AiUtility` scores PATROL/INVESTIGATE/FLEE/REPORT, but `TruthSim._resolve_ai_ticks()` only acts on ENGAGE; no waypoint movement, no radio.
- **`FLEE` `threat_level` still inert** (no health/threat feed), **`WitnessSystem` not wired into `TruthSim`**, **`SoundGraph` room propagation replaced by an open-air stand-in** (`CombatResolver.is_noise_heard_at`).
- **Dialogue can't reach the runtime** (F8) — compiled `.dlg` is never committed and has no GDScript loader; hand-transcription (`PrologueStub.PROLOGUE_GRAPH`) is the only path.
- **7 of 11 `DistortionOp` taxonomy classes are missing** (`HUDGlitch`, `ObjectSwap`, `FamiliarFace`, `EntityMask`, `GeometrySwap`, `TimeGap`, `MemoryEdit`) and 4 AI archetypes (Heavy, Runner, Technician, Civilian).
- **Journal / camera / evidence system** (§4.17) unbuilt — including the thesis-perfect "photograph a phantom → empty frame."
- **Settings don't persist** (F12), **no `HubDayLoop`** (F10), **input/platform gaps** (F11: touch, gamepad, crouch key, diagonal normalization), **zero `tr()`** (F13).

**Genuinely blocked here** (needs a human, an editor, real assets, or hardware — do NOT attempt in-sandbox):
- Real art/audio/VFX/shaders; a real Godot `Theme`/`.tres`/hand-authored `.tscn`; the distortion shader library + photosensitivity caps; the Grounding-reveal "is it beautiful" AB test.
- Steam Deck profiling; the naming/trademark decision; human playtests; the sensitivity review; the trailer.
- The GitHub Pages toggle (F7 — one settings click by the repo owner); Windows/macOS CI runners.

---

## 3. North star — the playable loop (the thing every phase serves)

**A stranger opens the browser build and, in ~3–4 minutes, plays a complete miniature of the whole game:** a short scripted setup → a small space with one guard and a real director-driven distortion or two → the Ground verb resolving *real purchased ops* (not a hardcoded one) → a debrief screen where they choose As-Seen / Verified-Only / Fabricate per claim → the Afterimage reveal showing truth-delta, with the Mind Model visibly having reacted. Everything in that sentence has its mechanism built already; almost none of it is *wired together at runtime.* That wiring is the plan.

Acceptance for the north star: `scenes/main.gd` (or a sibling `scenes/mission.gd`) runs a real `mission.json` through `DistortionDirector`→`OpFactory`, renders percept through `PerceptRenderer`, ends in a real `DebriefLedger` submission, and the whole session is recorded to a `ReplayLog` a `ReplayTheater` reconstructs for the reveal — all exported to web and green in CI.

---

## 4. Phases (each phase = in-sandbox buildable, unit-testable, CI-verifiable)

Phases are ordered by leverage toward the north star. Within each, work is small, testable, and follows the codebase's established discipline (verify-externally-then-port for any arithmetic; sorted iteration; `RefCounted`-only logic classes; keep the Node/scene shell thin).

### Phase A — Complete the DistortionOp taxonomy (highest leverage-per-risk, pure in-sandbox) — **DELIVERED**
*Post-arc update: all 7 remaining ops (`HUDGlitch`, `ObjectSwap`, `FamiliarFace`, `EntityMask`, `GeometrySwap`, `TimeGap`, `MemoryEdit`) are real `DistortionOp` subclasses in `src/percept/`, wired into `OpFactory.build()`, present in `content/missions/m00_stub/mission.json`'s real deck, and audited clean by `FairnessAuditor` end to end. `EntityMask`/`GeometrySwap` — the priority two named below — each gained a real-op "passes" test in `test_fairness_auditor.gd` alongside their pre-existing `_FakeOp` failing fixtures, closing out both rules 2 and 4 for real. 49 new tests (603 total). See `docs/dev_log.md`'s "Phase A" entry for the full account, including the honest scope calls this phase made (e.g. `GeometrySwap`'s "never mid-sight" structural half stays deferred — it needs a fog-of-war/visibility truth concept that doesn't exist yet — and is named as an open gap, not silently assumed solved).*

Build the 7 missing ops as `DistortionOp` subclasses, each the same shape as the existing 4 (`apply()`/`resolve_grounded()` over a percept-snapshot Dictionary, fairness tags hardcoded in `_init()`), each with a `params` contract wired into `OpFactory.build()` and a dedicated test.
- **`EntityMask`** and **`GeometrySwap`** are the priority two: they're the only classes `FairnessAuditor` rules 2 and 4 exist to guard, and today those rules have *no real class to catch* (only `_FakeOp` doubles). Building them makes two Charter rules real.
- **`HUDGlitch`, `ObjectSwap`, `FamiliarFace`, `TimeGap`, `MemoryEdit`** per master_plan §4.2's table (each has a defined distortion + Ground response). `TimeGap`/`MemoryEdit` operate on the percept snapshot's temporal/history fields; define those fields explicitly (the same way `subtitle`/`sound_events`/`actors` were added to the snapshot as ops needed them).
- **Augmentation while here:** extend `OpFactory` and `mission.schema.json`'s `params` for each; add each to `content/missions/m00_stub` or a new richer fixture so `test_mission_content_fairness.gd` audits all 11 op classes, not 4.
- **Acceptance:** all 11 ops instantiate from `mission.json` via `OpFactory`; `FairnessAuditor` rules 1–8 each have a real op that both passes (correct tags) and a fixture that fails (missing tag); every op has an `apply`/`resolve_grounded` round-trip test.
- **Files:** new `src/percept/{entity_mask,geometry_swap,hud_glitch,object_swap,familiar_face,time_gap,memory_edit}.gd`; extend `src/percept/op_factory.gd`, `tools/schemas/mission.schema.json`; new tests.

### Interlude — making the playable demo actually playable — **DELIVERED**
The user's own framing, mid-arc: *"play it from the position of a curious and smart player... make it nicely playable... fun and enjoyable... engaging. What you cannot build now, add to the plan."* This wasn't a new mechanism — it's a player-experience pass over Stage 2's already-real `TruthSim`/`PerceptRenderer`/`DriftEncounter`/`ReplayTheater` machinery, because a mechanically-correct demo that a stranger wouldn't enjoy running through isn't done. Delivered directly in `scenes/main.gd` and a new `src/integration/phantom_encounter.gd`:
- **A second, visually distinct distortion.** `PhantomEncounter` (mirrors `DriftEncounter`'s state machine exactly) scripts one `PhantomEntity` sighting — a figure the player can *see* standing where nothing real is, rendered as its own sprite and faded out over ~1s via a real `Tween` when it resolves (grounded or timed out), verified against the real `Node.create_tween()`/`Tween.tween_property()` docs before use since no earlier pass had touched `Tween` at all. One text-mishearing distortion reads as a demo; two differently-*felt* distortions read as a mechanic.
- **Player-chosen pacing.** The session used to end the instant an invisible proximity check decided it should. Now there's a marked exit (a teal door sprite) the player walks to when *they're* ready — both encounters run independently in the meantime, each auto-resolving on its own timeout if never grounded, matching Charter rule 5 either way.
- **Onboarding.** Nothing told a first-time player Ground existed before this pass. A persistent hint line now states the controls; an objective line says where the door is.
- **Ground made to feel like something.** A `ColorRect` vignette ramps with the *real* `GroundState.DURATION_TICKS` hold progress (not an independent cosmetic timer) — feedback that's honest about the mechanic, not decorative guesswork bolted on top.
- **A Clarity Mode consumer, finally.** `ClarityMode.active_flags()` (Pass 10) had zero callers anywhere in the codebase until this pass — the HUD now shows a plain text line whenever a distortion is active, the plainest possible instance of Charter rule 6's "flag it in real time, fully honorable way to play." Not yet toggleable (that needs Pass 19's real settings UI) — an honest partial step, not a fake one.
- **A restart loop.** The reveal panel used to freeze the session forever. `_start_new_session()` now resets every piece of state and rebuilds the room; Enter restarts from the reveal screen. A demo that dead-ends at its own climax was never "nicely playable."
- **Branching disclosure.** The reveal panel's text is generated per-encounter (`_drift_reveal_lines()`/`_phantom_reveal_lines()`), honestly covering the case where the player rushed past one or both encounters without ever triggering them, not just the "you saw it" case.

**What this deliberately still doesn't do — the near-term playability backlog, in priority order:**
1. ~~**Real content-driven encounters.**~~ **Delivered by Phase B** (below): `DriftEncounter`/`PhantomEncounter` are deleted; the scene now runs the real `MissionRuntime`/`OpFactory` pipeline against the real `m00_stub` mission content.
2. ~~**A directional objective indicator.**~~ **Delivered.** A small compass-style `Polygon2D` arrow, anchored in the HUD's top-right corner (clear of the room and every text label), drawn in the exit door's own `club_teal` color and re-rotated every `_update_visuals()` tick via `Vector2.angle()` (verified against the real docs: exactly `atan2(y, x)`) on the vector from the player's current position to `EXIT_POSITION_MM`. Reads faster than the "bottom-right" text line mid-exploration, and keeps working correctly regardless of where the player wanders.
3. ~~**Procedural audio.**~~ **Delivered.** Built with `AudioStreamWAV` + `PackedByteArray.encode_s16()` rather than the `AudioStreamGenerator` this entry originally named: a precomputed, exactly-looping buffer is the simpler and more deterministic fit for two fixed cues (no per-frame push-buffer bookkeeping needed), and `AudioStreamWAV.LOOP_FORWARD` gives a genuinely click-free loop for free once the buffer's own duration holds a whole number of cycles of every oscillator in it — verified against the real 4.3 docs before use (`AudioStreamWAV.format`/`loop_mode` are engine-exposed constants, `PackedByteArray.encode_s16()`'s documented little-endian layout). Two cues: a rising two-note chime (`_on_ground_completed()`, one-shot) and a low tremolo hum that tracks the Clarity Mode line 1:1, started/stopped only on the rising/falling edge (`scenes/main.gd`'s `_build_audio()`/`_update_visuals()`).
4. **More than one room.** The whole demo is a single rectangle. A real level (multiple rooms, sightlines, a reason to route around something) needs either hand-authored geometry data or Phase D's room-layout work — either way, real content, not a scene-script change.
5. **Camera follow/zoom.** Fixed full-room view works because the room is small; stops working the moment level 4 above happens.
6. ~~**Shareable reveal export.**~~ **Delivered.** master_plan.md's own marketing beat ("shareable honesty reports"): pressing E on the reveal panel captures the whole viewport as a PNG (`Viewport.get_texture().get_image().save_png_to_buffer()`) and triggers a real browser download via `JavaScriptBridge.download_buffer()` — reached through `Engine.has_singleton()`/`get_singleton()` rather than a static type reference, since that singleton only exists in the Web export and this script also gets *parsed* by the headless-Godot unit-test CI job on plain Linux.
Items 4–5 are additive polish, not correctness gaps; nothing above blocks Phase B starting next.

### Phase B — The runtime distortion spine (wire the pipeline into the playable surface) — **FULLY DELIVERED**
*Post-arc update: `MissionRuntime` and `MindModelEventBridge` landed first; `scenes/main.gd` has since been rewired to actually use them. `DriftEncounter`/`PhantomEncounter` (the hand-scripted pair) are deleted, not archived — the scene now loads the real, already-committed `content/missions/m00_stub/mission.json` via `MissionLoader` and lets `MissionRuntime` purchase from its real 11-op deck. The one item this section used to track as still open — a determinism-corpus fixture for a full `MissionRuntime`-driven run — is delivered too (`MissionRuntimeDigest`); every acceptance criterion below is closed.*

`MissionRuntime` owns: a `MissionPackage` (from `MissionLoader`), a `DistortionDirector` seeded per §4.3, the `MindModel` it reads for budget, and `active_ops: Array[DistortionOp]` (built via `OpFactory.build(package.deck[record["deck_index"]])` from purchase records — `DistortionDirector.purchase_one()`/`authorize_free_tier()` were extended to return `deck_index` in their record, the one piece of information `OpFactory` needs that op-class/tier/cost alone can't disambiguate once a deck ever authors two same-shaped entries with different params). `step(current_tick, ground_just_completed)` is the whole contract: a normal tick attempts one purchase (a no-op most ticks); a Ground-completion tick resolves and clears every active op instead (`notify_ground_resolved`/`notify_op_deactivated`, §4.3's "refund 0, weight decays"). Budget is granted once at construction and additionally re-granted by `scenes/main.gd` on its own schedule (`grant_scene_budget()`, every `BUDGET_REGRANT_INTERVAL_TICKS`) — a scene-authoring choice for a longer, open-ended session than §4.3's single-cut-point "scene" describes, named explicitly as the caller's own policy in `MissionRuntime`'s own class doc, not a change to the Director's contract.
- **Augmentation (delivered):** `MindModelEventBridge` wires `TruthSim`'s real `EventBus` facts (`WeaponFired` → `acute_stress.gain_gunfire_in_earshot()`, `ActorDowned` → `acute_stress.gain_witnessing_kill()`, `GroundCompleted` → `acute_stress.relieve_ground_completed()`) into `MindModel` for the first time since Pass 11 shipped it with zero consumers. Deliberately coarse and says so in its own class doc: every event anywhere fires the gain, unconditionally — real earshot-radius gating needs Phase D's `SoundGraph` wiring, and moral injury is deliberately *not* wired from `ActorDowned` here, since §4.4.3's gains are context-weighted (open combat vs. an unaware victim vs. a civilian) and `ActorDowned`'s payload carries none of that context yet; wiring a flat number would be a worse gap than leaving it unwired. In the playable demo's own graybox room this bridge never actually fires (no combat exists there) — wired for architectural completeness and whenever a real combat scene reaches this same scaffolding, not a placeholder.
- **`scenes/main.gd` rewired (delivered):** `DriftEncounter`/`PhantomEncounter` deleted; the scene loads `content/missions/m00_stub/mission.json` once via `MissionLoader`, and each session builds a fresh `MissionRuntime` (random seed — deliberately: truth-layer determinism, proven by `ReplayTheater`, doesn't depend on which distortions a session happened to draw, so a fresh seed each restart is replay value, not a determinism violation) that purchases from the real 11-op deck. The player-experience work Stage 3 built (the marked exit, the Ground vignette, the Clarity Mode line, the restart loop) survived the swap intact; `_update_phantom_sprite()` was already generic over "any phantom actor in the percept," needing zero changes. The reveal panel now discloses `MissionRuntime`'s actual purchase log — real flavor text for the four op classes this graybox room can render something for (`SubtitleDrift`, `AudioSwap`, `PhantomAudio`, `PhantomEntity`), and an honest generic fallback line for the other seven, which operate on percept-snapshot keys (hud_elements, props, geometry_cells, journal_entries) this demo's `TruthSim` never populates — Charter rule 5 doesn't have an exception for "the demo can't show this one yet."
- **Acceptance, all delivered:** (a) same-seed-same-mind-state purchase logs are identical (`test_mission_runtime.gd`); (b) rising acute stress raises granted budget, measured directly against `DistortionDirector.compute_budget()` as the oracle; (c) a Ground-completion tick clears every active op and notifies the Director, both in the unit tests and live in the rewired scene; (d) a real-content test loads `content/missions/m00_stub/mission.json` through the actual `MissionLoader`/`MissionRuntime`/`OpFactory` chain and confirms a real, `FairnessAuditor.KNOWN_OP_CLASSES`-recognized op comes out the other end — the same content the live scene now runs; (e) `MissionRuntimeDigest` (`tests/fixtures/`) re-simulates a full `MissionRuntime`-driven run — reusing the same three `tests/corpus/*.json` fixtures `test_determinism_corpus.gd` already exercises — and proves it re-simulates hash-identical given the same `run_seed` (reused directly as the Director's own seed), the same self-consistency discipline `TruthSimDigest` established, no hand-computed golden value.
- **Files:** `src/integration/mission_runtime.gd`, `src/integration/mind_model_event_bridge.gd`, `tests/fixtures/mission_runtime_digest.gd` (new); `scenes/main.gd` (rewired); `src/integration/drift_encounter.gd`, `src/integration/phantom_encounter.gd` and their tests (deleted); new tests.

### Phase C — The debrief loop (the thesis made playable)
Two missing bridges plus a screen-as-data:
1. **Event-log reducer** — a `RefCounted` `ClaimReducer` (in `src/debrief/`) that turns a `TruthSim` run's `EventBus` history (or a `ReplayTheater` percept view) into the `{id, subject, predicate, object}` "perceived event" shape `ClaimDrafter.draft_from_perceived_events()` already consumes. This is the "quiet knife" made real: a believed-phantom `PhantomEntity` the player shot must reduce to the same claim shape as a real guard, so the drafted claim looks identical. Test that directly.
2. **Consequence channels** — give `DebriefLedger.submit_claim()` a real place to write Doubek-trust / resource-budget / plot-flags: `GameStateStore` (Pass 2, already the "single serializable source of truth"). Define the key-paths, bill the deltas, test the trust/resource math against a worked example.
3. **Debrief-screen-as-data** — extend the `ScreenSpec` pattern (`src/ui/`) with a `DebriefScreen` data class (claim rows + honesty-mode stamp choices + a `screen_reader_text()`), so the web scene can render the form without a hand-authored `.tscn`. The Afterimage reveal reuses `ReplayTheater` for the truth-delta side-by-side.
- **Acceptance:** an integration test plays a tiny run (via `MissionRuntime`), reduces its events to claims, submits a mix of As-Seen/Verified-Only/Fabricate, and asserts truth-deltas, moral-injury billing, and `GameStateStore` consequence writes — including the quiet-knife case where an honest As-Seen claim about a phantom comes back false. The web scene shows the debrief + reveal.
- **Files:** new `src/debrief/claim_reducer.gd`, `src/ui/debrief_screen.gd`; extend `src/debrief/debrief_ledger.gd` (consequence writes), `scenes/main.gd`; new tests.

### Phase D — Enrich the truth sim so a mission has real texture (in-sandbox mechanism work)
The AI can currently only stand still and shoot on sight. A real mission needs patrol and investigation.
- **AI movement for non-ENGAGE states** — `AiAgent` already scores PATROL/INVESTIGATE/FLEE/REPORT and remembers last-known position; `TruthSim._resolve_ai_ticks()` just ignores them. Add authored **waypoint patrol data** (a small `PatrolRoute` value type, content-authored per mission), and deterministic grid movement toward the current waypoint / last-known position, reusing `SweptCollision.move_with_collision()`. FLEE and REPORT need `threat_level`/backup wiring — scope REPORT to "publish a `BackupCalled` fact" first (consumers later), the established pattern.
- **Wire `WitnessSystem` into `TruthSim`** — "who truly saw what" is the truth-layer fact the debrief's truth-delta and suspicion propagation should read from; today it's built and tested standalone but never called during a run. Publish witness facts on the `EventBus`; the `ClaimReducer` (Phase C) and `GroundObservationBridge` (done) consume them.
- **Wire `SoundGraph` room propagation** — replace `CombatResolver.is_noise_heard_at`'s open-air stand-in with real room/portal attenuation once a mission carries an authored room graph (a `RoomLayout` value type alongside the `CollisionGrid`). This is the moment `SoundGraph` (built Pass 4) finally has a consumer.
- **Acceptance:** a bot-driven soak test (extend `test_bot_harness.gd`) runs a full patrol-investigate-engage encounter deterministically; witness facts and room-attenuated hearing are asserted; a corpus fixture pins it.
- **Files:** new `src/sim/{patrol_route,room_layout}.gd`; extend `src/sim/truth_sim.gd`, `src/sim/ai_agent.gd`; wire `src/sim/witness_system.gd`, `src/sim/sound_graph.gd`; new tests + corpus fixtures.

### Phase E — The dialogue runtime decision (F8, unblocks all authored dialogue)
Make the decision the review flagged and build the small thing behind it. **Recommendation:** option (b) — a GDScript JSON-graph loader + a CI step that compiles every `content/dialogue/*.dlg` → JSON *into the export only* (never committed, honoring tech_guidelines §5.1). Add a `DialogueLoader` (`src/dialogue/`) that reads compiled JSON into the `DialogueGraph` shape `DialogueRunner` already consumes. `PrologueStub`'s hand-transcribed `const` graph becomes the loader's first real customer, deleting the transcription. This unblocks day-phase `converse`, the hub cast, and the whole M4/M6 authored-dialogue backlog.
- **Acceptance:** `dlgc.py` gains a `--emit-json <dir>` mode (CI-invoked); `DialogueLoader` round-trips `prologue_sova.dlg` → the exact graph `PrologueStub` hand-built (assert equality against the old `const` as a golden); the CI export step compiles all `.dlg` files and fails on any that don't.
- **Files:** extend `tools/dlgc.py`, `.github/workflows/export-web.yml`; new `src/dialogue/dialogue_loader.gd`; rework `src/integration/prologue_stub.gd`; new test.

### Phase F — The journal / camera / evidence system (§4.17 — thesis-perfect, in-sandbox)
Pure data/logic, no assets needed to be *correct* (art comes later). The showcase mechanic: **photographing a phantom yields an empty frame** — because the camera reads *truth*, not percept, so a `PhantomEntity` the player believes in simply isn't in the photo. This is the game's thesis in one interaction, and it's fully testable. Evidence provenance then "armors" a claim (a photographed real event makes an As-Seen claim un-contradictable, feeding Phase C's consequence machinery and the `GROUNDED`/`EVIDENCE` provenance types `Claim` already models but nothing yet attaches).
- **Acceptance:** a test photographs a scene containing one real actor and one `PhantomEntity`; the resulting evidence contains the real actor only; a claim backed by that evidence gets `EVIDENCE` provenance and survives a Verified-Only submission that an unbacked claim can't.
- **Files:** new `src/sim/camera.gd` (or `src/debrief/evidence.gd`), extend `src/debrief/claim.gd` provenance attachment; new tests.

### Phase G — Persistence, platform, polish (F10, F11, F12, F13 — close the trust gaps)
- **`HubDayLoop`** (F10): one `RefCounted` that sequences `HubCalendar.advance_day` + `SubstanceModel.advance_day` + `MoralInjuryState.decay_passive_daily` + suspicion decay in the one correct order, so "a day passes" is a single authoritative call before save/load multiplies the callers.
- **Settings persistence** (F12): wire `AccessibilitySettings` through `GameStateStore`/`SaveSystem` (both exist); adopt `ThemePalette`/`MotionConstants` in `scenes/main.gd` instead of the hardcoded colors (already partially done — finish it).
- **Input & platform** (F11): bind the remaining InputMap actions (crouch, the combat verbs) in code; add a simple on-screen virtual joystick + Ground button for touch (the single biggest audience multiplier for the web build — phones currently render but can't move); normalize diagonal speed now that it's playtestable.
- **Localization discipline** (F13): route user-facing strings through `tr()` starting now, before scene/UI code multiplies. Extract `scenes/main.gd`'s pure helpers (`_mm_to_px`, wall-layout) into a tested `RefCounted`.
- **`ReplayTheater` memory** (F13): add the checkpoint-interval + re-sim-window scheme its own docstring already describes, before missions get long enough for the full-tick cache to hurt.
- **itch.io publishing** (enhancement #8): a `butler`-push CI job gives a stable public URL without depending on the Pages toggle (F7, which only the owner can flip).

---

## 5. Cross-cutting improvements & augmentations (the "notice everything" sweep)

Smaller items worth doing opportunistically, grouped by kind:

**Correctness / robustness hardening:**
- `FairnessAuditor` could optionally run *at Director purchase time* as a defensive assert (belt-and-suspenders, matching the codebase's existing pattern), so an illegal runtime purchase fails loudly rather than rendering.
- The `RefCounted`-lifetime trap that bit `GroundObservationBridge` (a subscriber freed while `EventBus` holds its `Callable`) is a **class of bug**, not a one-off. Consider an `EventBus` option to hold strong references to subscribers, or a documented "subscribers must be owned" contract with a test that would catch a freed subscriber — so the next bridge-style class doesn't relearn it via CI.
- The determinism corpus should grow beyond 3 fixtures as each phase adds real behavior (patrol, distortion, debrief), and eventually earn the PR-subset/nightly-full split the roadmap tracks.

**Content-pipeline maturation (roadmap "Content validator v1"):**
- Now that `OpFactory` builds real ops from `mission.json`, extend `tools/content_validator.py` toward v1: cross-file ID resolution (once dialogue/missions reference each other), reachability (once dialogue graphs and mission objectives exist), and the "seeded broken content fails CI" regression fixture the AC names.
- The substance dependency-dominance lint (§10) becomes buildable once missions can *offer* substances — add a substance-availability schema field, then a lint that rejects configs where repeated use dominates.

**Design-legibility augmentations (make the systems visible):**
- A `MindDashboard` render in the web scene (the data class exists) — show the four bands reacting live during a mission. Makes the invisible Mind Model legible, which is a real UX-charter goal ("no shame in playing with the hood open").
- A live Clarity-Mode toggle in the web build (the gate exists, `ClarityMode.active_flags()`), so a player can *see* the distortion flagged in real time — the accessibility promise, demonstrable.
- The Afterimage Theater's op-timeline as a simple scrubber in the web build (the `ReplayTheater`/`OpTimelineSpan` data model exists) — the marketing beat (§11 shareable honesty reports) starts as an in-browser scrubber before it's an export card.

**Documentation / process:**
- Keep `docs/review_and_forward_plan.md` and this file as the two living planning docs; mark findings closed as they land, and *record wrong-then-right debugging traces honestly* (as the `GroundObservationBridge` `RefCounted` trace now does) — that history is the most useful part for the next contributor.
- A short `CONTRIBUTING`-style note capturing the hard-won sandbox rules (verify Godot APIs against docs before use; never hand-author `.tscn`/`.tres` blind; keep subscribers owned; `int()`-cast every JSON number) would save the next pass rediscovering them.

---

## 6. Recommended sequence & acceptance gates

The phases are already in leverage order, but the **critical path to the north star** is **A → B → C** (taxonomy → runtime spine → debrief loop): those three, plus a minimal slice of D (one patrolling guard), make the full "play → distort → ground → debrift → reveal" loop playable in the browser. E, F, G are high-value but parallelizable around that spine.

- **Gate 1 (after A):** all 11 DistortionOps audit from real content; Charter rules 2 & 4 have real classes.
- **Gate 2 (after B):** the web build's distortion is director-driven and stress-reactive, deterministic, corpus-pinned.
- **Gate 3 (after C + minimal D):** a stranger plays the whole loop in the browser, including the quiet-knife debrief where honesty still comes back false. *This is the demo that explains the game.*
- **Gate 4 (E/F/G as they land):** authored dialogue reaches the runtime; the camera proves the thesis in one interaction; settings persist; phones can play.

Every gate is verified the way this codebase always verifies: local `gdformat`/`gdlint`/boundary/content/dialogue checks, then real CI with the actual `ALL PASSED (N/N)` log pulled and read, then a green web export.

---

## 7. What this plan deliberately does NOT do

It does not schedule real art, audio, shaders, `.tscn`/`Theme` authoring, Steam Deck profiling, the naming decision, playtests, or the sensitivity review — every one needs a human, a real editor session, real assets, or hardware this sandbox lacks. Those stay in the roadmap's M5–M7 as they are, honestly blocked, not faked. The line this plan holds: **build and prove every mechanism and every wire between mechanisms that GDScript + CI can verify; stop exactly where a screenshot, a speaker, a playtester, or an editor becomes the only way to know it's right.**

---

*Cross-references: `docs/review_and_forward_plan.md` (F-findings, most now closed), `docs/roadmap.md` (M0–M7 milestones), `docs/dev_log.md` (per-pass + post-arc history), `docs/master_plan.md` (§4 system specs this plan wires together), `docs/story_bible.md` (§4 the mission ground-truth the north-star loop dramatizes).*
