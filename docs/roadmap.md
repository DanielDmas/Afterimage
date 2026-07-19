# AFTERIMAGE — Development Roadmap & Backlog
**Document type:** Milestone backlog with acceptance criteria. Companion to `master_plan.md` §9 (which owns the milestone narrative and calendar); this file turns it into checkable work.
**Usage:** items are checked off in commits as they land; an item is *done* only when its acceptance criterion passes in CI or in a recorded playtest. Scope changes to a milestone are amendments here, made at milestone boundaries. This file is the day-to-day truth of "where are we."

---

## Definition of Ready to Code (all true before M0 begins)
- [x] Master plan ratified (`master_plan.md` v2)
- [x] Technology decisions locked under change control (`tech_guidelines.md`)
- [x] Foundation layer specified (`foundation_blueprints.md`)
- [x] Art direction + UX charter ratified (`art_direction.md`, `ux_charter.md`)
- [x] Story canon fixed; slice mission ground-truth outlines written (`story_bible.md`)
- [x] Godot 4.3.x exact patch chosen and recorded in `/docs/ENGINE_VERSION` (Pass 1: 4.3.0-stable)
- [~] GitHub Actions runner plan confirmed — Linux reference CI landed Pass 1 (`.github/workflows/ci.yml`); Windows/macOS nightly runners still open

## M0 — Foundations (w1–6)
*Exit (master_plan §9): walking skeleton — inputs recorded in a stub scene replay tick-perfect on every platform target. **Not yet reached** — Passes 1–2 delivered every M0 checklist item below; the exit criterion itself needs TruthSim (Pass 3) to have something real to replay. See `dev_log.md` for verification caveats: this sandbox has no Godot binary, so everything below is verified by lint/format tooling + algorithmic cross-checks locally, and by CI's real headless Godot run on push (confirmed green both passes).*
- [x] Repo scaffold per master_plan §5.8; lint config (gdtoolkit), CI pipeline skeleton — **AC:** a PR with a style violation fails *(Pass 1; gdlint/gdformat --check both wired into CI and verified locally against every source file)*
- [x] Fixed-point helpers + PRNG (xoshiro128**, splitmix64 seeding) — **AC:** unit tests vs. reference vectors green *(Pass 1: `src/core/fixed_math.gd`, `src/core/prng.gd`; reference vectors cross-derived from an executable Python transliteration, not hand-guessed)*
- [x] EventBus (typed, queued dispatch) — **AC:** ordering/reentrancy unit tests *(Pass 1: `src/core/event_bus.gd`, 11 tests incl. reentrant-publish-is-queued and self-unsubscribe-mid-dispatch)*
- [x] GameStateStore + save serialization + `schema_version` + migration harness — **AC:** save→load→save byte-identical fixture test *(Pass 2: `src/core/game_state_store.gd`, `src/core/save_migrations.gd`, `src/core/save_system.gd`; a real exercised v1→v2 migration, gzip-compressed JSON via `PackedByteArray.compress()`, and an explicit byte-identical save/load/save fixture test)*
- [x] Predicate evaluator (18 operators, blueprints §2) — **AC:** full operator test matrix; unknown-operator rejection *(Pass 1: `src/core/predicate.gd` + `src/core/world_query.gd`, 31 tests across evaluate() and validate())*
- [x] Fixed-tick harness with `InputFrame` recording/replay — **AC:** determinism corpus v0 (3 stub runs) re-simulates hash-identical on Linux/Win/mac in CI *(Pass 2: `src/core/{fixed_tick_clock,input_frame,replay_log}.gd`; 3 fixtures in `tests/corpus/` replayed through a disposable `StubSim` placeholder — proves the record/replay/hash/compare mechanism catches both agreement and divergence in-process. Cross-platform Linux/Win/mac agreement still needs the multi-OS CI runners tracked below)*
- [~] Determinism CI job (PR subset + nightly full) — **AC:** an intentionally seeded divergence is caught by the job *(Pass 2: divergence-detection proven by unit test (`test_digest_is_sensitive_to_an_extra_frame`), running as part of the normal fast suite. Still open: a dedicated CI job, the PR-subset/nightly-full split, and Windows/macOS runners — deferred until the corpus is large enough for that split to matter, consistent with the Windows/macOS item already open from Pass 1)*

## M1 — Truth Skeleton (w7–12)
*Exit: a fight can be recorded and replayed tick-perfect, and the fight is already fun. The tick-perfect half is reached as of Pass 7 — every item below is wired together and deterministic. "Already fun" is not, and structurally can't be from engineering passes alone: it's a human-playtest verdict against a real rendered build, which needs real art/UI (post-Pass-20 scope) and real testers. All checkboxes below are complete for what this sandbox can deliver.*
- [x] TruthSim actor model (integer mm positions, entity IDs) + grid collision & swept casts (tech §3.4) — **AC:** collision unit suite; corpus runs with movement *(Pass 3: `src/sim/{actor,actor_registry,collision_grid,swept_collision,truth_sim}.gd`. Swept circle-vs-AABB verified against an executable Python reference using exact Fraction arithmetic before porting — same rigor as the Pass 1 PRNG. "Corpus runs with movement" satisfied narrowly: TruthSim has its own direct correctness tests rather than replacing the Pass 2 StubSim corpus, which still proves the record/replay/hash mechanism on its own terms — see dev_log.md for the reasoning)*
- [x] Line-of-sight + sound propagation (occlusion grid, room/portal BFS) — **AC:** deterministic sense tests; noise rings render from truth events *(Pass 4: `src/sim/{line_of_sight,sound_graph}.gd`. LOS reuses CollisionGrid's blocked-cell data via Bresenham's line algorithm — verified against a Python reference before porting. Sound propagation is a room/portal graph with subtractive integer attenuation, solved by iterative relaxation (Bellman-Ford-style) rather than a priority-queue Dijkstra, appropriately scoped to small room counts. Angular vision cones deliberately deferred to Pass 5 — no consumer exists yet, and building the cone math now risked premature complexity (see dev_log.md). "Noise rings render from truth events" is not yet built: that's percept-side UI (Pass 8+), this pass delivers the truth-layer propagation it would read from)*
- [x] Sentry + Professional AI (utility patrol/investigate/engage/flee/report) — **AC:** paranoid/credulous bot stubs finish the graybox room *(Pass 5: `src/sim/{vision_cone,ai_utility,ai_archetype,ai_agent}.gd`. Vision cones — deferred from Pass 4 — verified against a Python reference across nine clean-angle cases (30°/45°/60°, whose cos² values are exact rationals) before porting, with a numerically-derived overflow bound enforced by assert. All five master_plan §5.5 states implemented as pure utility-scoring functions; FLEE is wired but inert (threat_level defaults to 0) until Pass 6 gives it real combat data to score against. Sentry/Professional differ only in perception parameters and REPORT usage — tactical behaviors ("flanks, checks corners") need pathfinding/combat that don't exist yet, so building bespoke behavior trees for them now was out of scope. The literal AC (bots finishing the graybox room) awaits Pass 7's room; this pass delivers the AI decision-making the bots will drive, with its own direct correctness tests instead)*
- [x] Combat verbs v1 (move/sprint/crouch/lean/aim/fire/reload/takedown/throw/Focus) — **AC:** every §4.9 tuning-checklist line has a recorded pass *(Pass 6: `src/sim/{movement_profile,weapon,combat_resolver,focus_state,lean}.gd` + InputMap actions in `project.godot`. Every verb built standalone-and-tested, not yet wired into TruthSim.step() — that wiring is Pass 7's literal job ("graybox test level wiring TruthSim+AI+combat"), the same order Pass 4/5 shipped LOS/sound and vision/AI ahead of their consumers. Fire and takedown reuse Pass 4/5's LineOfSight/VisionCone primitives rather than new geometry; noise-hearing (sprint/gunfire/throw) uses a distance-only v1 model pending a real room to route through SoundGraph. The literal AC (a *recorded pass* per tuning-checklist line) needs actual playtesting against a real build, which doesn't exist before Pass 7's graybox room — not satisfiable yet, same class of deferral as Pass 5's bot-stub AC. Focus's state machine (activation/duration/cooldown) is built and tested; its "0.4× time" effect is deliberately not — TruthSim's tick rate never varies (determinism contract), so that's a presentation-layer trick with no renderer to attach to yet)*
- [x] Graybox room (Zálesí ruins fragment) — **AC:** 3 external testers rate the sober fight "fun" without prompting on distortions (they don't exist yet) *(Pass 7: `tests/fixtures/graybox_room.gd` (a code-defined perimeter-walled room, not a real Godot scene — no level-authoring pipeline exists before Pass 13) + `TruthSim`'s combat/AI wiring: player movement, aim/fire/reload/takedown/throw/focus, and every spawned AI's perception-and-fire-back all resolve for real now (`src/sim/truth_sim.gd`), with a bot harness v0 (`tests/fixtures/bot_inputs.gd`, `tests/unit/test_bot_harness.gd`) soak-testing an aggressive and a cautious bot through a full encounter, hand-traced and asserted exactly. The literal AC (3 external testers judging "fun") needs real human playtesters against a real, rendered build — categorically outside what an engineering pass in this sandbox can satisfy, the same class of deferral as Pass 5/6's bot-stub and tuning-checklist ACs. What's real: a fight that resolves deterministically, replays tick-perfect, and is driven by every system Pass 3-6 built standalone)*
- [x] WitnessSystem v1 (who truly saw what) — **AC:** witness log matches hand-computed scenario fixtures *(Pass 5: `src/sim/witness_system.gd`, reusing VisionCone + LineOfSight against a roster of candidates. Every fixture in `test_witness_system.gd` is hand-computed geometry, not a black-box comparison)*

## M2 — The Split (w13–17)
*Exit: a phantom fools a playtester once, and the replay proves it.*
- [ ] PerceptRenderer boundary (read-only truth views; op decorator pipeline) — **AC:** static check: no percept-path writes to truth (CI lint on module imports)
- [ ] Distortion shader library skeleton + photosensitivity caps (tech §4) — **AC:** caps unit-verified
- [ ] Ops: `SubtitleDrift`, `AudioSwap`, `PhantomAudio`, `PhantomEntity` — **AC:** each op's Ground response + Theater disclosure works in the graybox
- [ ] Ground verb (timings, costs, on-empty behavior, §4.6) — **AC:** input-hold + toggle variants; suspicion tick stub on observed Ground
- [ ] Clarity Mode stub (vignette flagging) — **AC:** all four ops flagged correctly in real time
- [ ] Replay Theater v0 (dual-pane, scrubber, op timeline; checkpoint snapshots) — **AC:** scrub-to-any-point ≤ 100 ms on Deck-class hardware
- [ ] Art direction lock: distortion VFX + Grounding reveal (art_direction §4) — **AC:** the reveal reads as "beautiful" in a 5-person blind AB vs. a plain fade

## M3 — The Mind (w18–22)
*Exit: two testers with different playstyles get measurably different distortion profiles from the same mission.*
- [ ] MindModel with §4.4 constants + band effects — **AC:** arithmetic unit tests; worked-example fixtures from the plan reproduce exactly
- [ ] DistortionDirector (budget accrual, deck loading, caps, cooling, seeding) — **AC:** same seed+state → identical purchase log, in corpus
- [ ] Fairness auditor v1 (static deck/level checks) — **AC:** each Charter rule has a fixture deck that fails it
- [ ] Hub v1: calendar/sleep loop, mind dashboard (worksheets) — **AC:** a full sleep-debt week produces the §4.4.2 fatigue trace
- [ ] Substance model (stimulant/alcohol/sedative tradeoffs) — **AC:** dependency-dominance lint passes on all authored configs

## M4 — The Cover (w23–29)
*Exit: a full day/night/debrief cycle plays end-to-end.*
- [ ] Dialogue DSL + compiler (`/tools/dlgc`) + runner + interrupt memory (blueprints §4) — **AC:** compiled prologue Sova scene plays; contradiction catch fires both directions
- [ ] NPC minds (KNOWS/HIDES/LIES + personality) + suspicion ledger + gossip tick — **AC:** scenario fixtures: a witnessed Ground reaches the right NPCs on the right days
- [ ] Day-phase verbs (converse/eavesdrop/observe/plant/lift/photograph/small talk) — **AC:** M2 "Listening Room" day half playable in graybox
- [ ] Debrief v1: claim drafting from event log, three honesty modes, truth-delta, consequence channels — **AC:** liar-bot smoke test; a believed-phantom claim drafts correctly
- [ ] Journal + camera/evidence systems (§4.17) — **AC:** photographed phantom yields empty frame; evidence provenance armors a claim
- [ ] Content validator v1 (IDs, reachability, calendar lint) — **AC:** seeded broken content fails CI

## M5 — Mission One for Real (w30–35)
*Exit: the theater moment lands in playtests ("that's what happened?!").*
- [ ] "Induction" full production (art, audio, deck, debrief spec) per its ground-truth doc (story_bible §4)
- [ ] Remaining ops (`HUDGlitch`, `ObjectSwap`, `FamiliarFace`, `EntityMask`, `GeometrySwap`, `TimeGap`, `MemoryEdit`) + remaining archetypes (Heavy, Runner, Technician, Civilian)
- [ ] Theater v1 (honesty report, export cards, streamer mode) — **AC:** export renders correctly at phone size (art_direction §8)
- [ ] Adaptive music v1 (stem buses, band-driven thinning) — **AC:** mix sheet loudness targets verified
- [ ] **Naming decision** (title-collision risk, master_plan §12) with trademark/storefront search — **AC:** decision recorded in §11.3 amendment
- [ ] Steam Deck profiling pass — **AC:** all tech §11.1 budgets green on Deck

## M6 — Slice Complete (w36–43)
- [ ] Prologue + "The Listening Room" + "Smoke Test" full production per ground-truth docs
- [ ] Hub cast dialogue (Doubek, Sova, Tereza arcs to slice depth); ending hooks stubbed
- [ ] Difficulty + psych sliders; first full accessibility pass (ux_charter §4 inventory audit — every committed item demonstrably present)
- [ ] Localization pipeline proven on one full scene incl. a drift pair round-trip
- [ ] Internal playtest #2 with full UX protocol (ux_charter §6) — **AC:** first-hour targets measured; anti-fun tripwires reviewed

## M7 — Polish & Slice Release (w44–48)
- [ ] External playtest round; tuning from telemetry; quit-point review complete
- [ ] Sensitivity review implemented (tracked issues closed); content toggles final
- [ ] Trailer from one real unstaged Afterimage comparison; store/demo packaging (prologue+M1 demo build)
- [ ] Slice release criteria: determinism corpus 100% green 14 consecutive nights; all bots finish all missions; ux_charter §2 targets met in the external round

---
*After M7: full-game content batches per master_plan §13. This file gains M8+ sections at that boundary, not before.*
