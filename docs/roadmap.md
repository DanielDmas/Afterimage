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
- [ ] Godot 4.3.x exact patch chosen and recorded in `/docs/ENGINE_VERSION` (first act of M0)
- [ ] GitHub Actions runner plan confirmed (Linux reference + Win/mac nightly, tech §9)

## M0 — Foundations (w1–6)
*Exit (master_plan §9): walking skeleton — inputs recorded in a stub scene replay tick-perfect on every platform target.*
- [ ] Repo scaffold per master_plan §5.8; lint config (gdscript-toolkit), CI pipeline skeleton — **AC:** a PR with a style violation fails
- [ ] Fixed-point helpers + PRNG (xoshiro128**, splitmix64 seeding) — **AC:** unit tests vs. reference vectors green
- [ ] EventBus (typed, queued dispatch) — **AC:** ordering/reentrancy unit tests
- [ ] GameStateStore + save serialization + `schema_version` + migration harness — **AC:** save→load→save byte-identical fixture test
- [ ] Predicate evaluator (18 operators, blueprints §2) — **AC:** full operator test matrix; unknown-operator rejection
- [ ] Fixed-tick harness with `InputFrame` recording/replay — **AC:** determinism corpus v0 (3 stub runs) re-simulates hash-identical on Linux/Win/mac in CI
- [ ] Determinism CI job (PR subset + nightly full) — **AC:** an intentionally seeded divergence is caught by the job

## M1 — Truth Skeleton (w7–12)
*Exit: a fight can be recorded and replayed tick-perfect, and the fight is already fun.*
- [ ] TruthSim actor model (integer mm positions, entity IDs) + grid collision & swept casts (tech §3.4) — **AC:** collision unit suite; corpus runs with movement
- [ ] Line-of-sight + sound propagation (occlusion grid, room/portal BFS) — **AC:** deterministic sense tests; noise rings render from truth events
- [ ] Sentry + Professional AI (utility patrol/investigate/engage/flee/report) — **AC:** paranoid/credulous bot stubs finish the graybox room
- [ ] Combat verbs v1 (move/sprint/crouch/lean/aim/fire/reload/takedown/throw/Focus) — **AC:** every §4.9 tuning-checklist line has a recorded pass
- [ ] Graybox room (Zálesí ruins fragment) — **AC:** 3 external testers rate the sober fight "fun" without prompting on distortions (they don't exist yet)
- [ ] WitnessSystem v1 (who truly saw what) — **AC:** witness log matches hand-computed scenario fixtures

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
