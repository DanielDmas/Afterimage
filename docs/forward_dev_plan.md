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

### Phase A — Complete the DistortionOp taxonomy (highest leverage-per-risk, pure in-sandbox)
Build the 7 missing ops as `DistortionOp` subclasses, each the same shape as the existing 4 (`apply()`/`resolve_grounded()` over a percept-snapshot Dictionary, fairness tags hardcoded in `_init()`), each with a `params` contract wired into `OpFactory.build()` and a dedicated test.
- **`EntityMask`** and **`GeometrySwap`** are the priority two: they're the only classes `FairnessAuditor` rules 2 and 4 exist to guard, and today those rules have *no real class to catch* (only `_FakeOp` doubles). Building them makes two Charter rules real.
- **`HUDGlitch`, `ObjectSwap`, `FamiliarFace`, `TimeGap`, `MemoryEdit`** per master_plan §4.2's table (each has a defined distortion + Ground response). `TimeGap`/`MemoryEdit` operate on the percept snapshot's temporal/history fields; define those fields explicitly (the same way `subtitle`/`sound_events`/`actors` were added to the snapshot as ops needed them).
- **Augmentation while here:** extend `OpFactory` and `mission.schema.json`'s `params` for each; add each to `content/missions/m00_stub` or a new richer fixture so `test_mission_content_fairness.gd` audits all 11 op classes, not 4.
- **Acceptance:** all 11 ops instantiate from `mission.json` via `OpFactory`; `FairnessAuditor` rules 1–8 each have a real op that both passes (correct tags) and a fixture that fails (missing tag); every op has an `apply`/`resolve_grounded` round-trip test.
- **Files:** new `src/percept/{entity_mask,geometry_swap,hud_glitch,object_swap,familiar_face,time_gap,memory_edit}.gd`; extend `src/percept/op_factory.gd`, `tools/schemas/mission.schema.json`; new tests.

### Phase B — The runtime distortion spine (wire the pipeline into the playable surface)
Replace the hardcoded `DriftEncounter` path with the real one. Introduce a small `RefCounted` **`MissionRuntime`** (in `src/integration/`) that owns: a `MissionPackage` (from `MissionLoader`), a `DistortionDirector` seeded per §4.3, the `MindModel` values it reads for budget, and the set of currently-active op instances (built via `OpFactory` from purchase records). Each tick it: grants/spends budget against the Director, instantiates purchased ops, and hands the active op list to `PerceptRenderer.render()` on the truth snapshot. `scenes/main.gd` becomes a thin renderer of whatever `MissionRuntime` says is active.
- **Augmentation:** the Mind Model finally gets a *real consumer* driving its inputs — combat/near-discovery events raise acute stress, which raises the Director's budget, which buys more distortion. This is the first time the §4.4↔§4.3 feedback loop runs live. Wire `TruthSim`'s existing `EventBus` facts (`WeaponFired`, `ActorDowned`, `GroundCompleted`) into `MindModel` gain calls via a small bridge (mirrors `GroundObservationBridge`'s pattern exactly).
- **Acceptance:** a headless test drives a scripted `ReplayLog` through `MissionRuntime` and asserts (a) the Director's purchase log is seed-reproducible, (b) rising acute stress raises budget, (c) Ground resolves the *live* purchased ops (not a hardcoded one), (d) the whole run is deterministic (add a corpus fixture). Then the web scene renders it.
- **Files:** new `src/integration/mission_runtime.gd`, a `src/sim/`→`MindModel` event bridge; rework `scenes/main.gd`; new tests + corpus fixture.

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
