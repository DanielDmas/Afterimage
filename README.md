# AFTERIMAGES: VRANOV
*A psychological action thriller about a mind you cannot trust — including yours.*

Top-down 2D action thriller (Godot 4.3). You are an undercover officer inside a criminal intelligence firm in Vranov, 2004. The engine simulates the **true** world on one layer and renders only what your character **believes** on another — and after every mission, a replay theater shows you both, side by side.

**Title note:** the game is titled *Afterimages: Vranov* (the plural + place-name resolves the working title's collision with an unrelated, already-released 2023 metroidvania called *Afterimage*, flagged as a risk in `master_plan.md` §12). The in-fiction replay mechanic keeps its original singular name, **the Afterimage** — see `master_plan.md` §4.12/§4.19.

**Status:** in development. Planning is complete and ratified (docs below); engineering is underway — see `docs/dev_log.md` for pass-by-pass progress and `docs/roadmap.md` for the milestone backlog. Nothing is decided on the go: every system is built to the locked specs in the document set.

## Running the tests
This is a Godot 4.3.x project (`docs/ENGINE_VERSION` pins the exact build). On a **fresh clone**, run an import pass once first — `.godot/` (the class-name cache Godot builds by scanning the project) is gitignored, so `class_name` types like `AfterimageTestRunner` aren't resolvable until something triggers that scan:
```
godot --headless --path . --editor --quit   # one-time: builds the class cache
godot --headless --path . --script res://tests/run_tests.gd
```
(Opening the project in the editor UI at least once does the same thing — the explicit command above is just the headless/CI equivalent.) Exit code 0 from the second command = all tests passed. CI (`.github/workflows/ci.yml`) runs both steps on every push, plus `gdlint`/`gdformat --check` for style. See `docs/tech_guidelines.md` §9 and §12 for why this project uses a small custom GDScript test harness (`tests/framework/`) instead of GUT for now.

## The document set

| Document | What it governs |
|---|---|
| [`docs/master_plan.md`](docs/master_plan.md) | The master development plan: design pillars, story bible, all systems (distortions, mind model, combat, debrief), architecture, milestones M0–M7, testing, risks |
| [`docs/tech_guidelines.md`](docs/tech_guidelines.md) | **Locked technology decisions** — engine pinning, determinism contract, data formats, audio/input/UI tech, CI, performance budgets. Change-controlled |
| [`docs/foundation_blueprints.md`](docs/foundation_blueprints.md) | Full specification of the foundation layer: EventBus, GameStateStore, predicate language, dialogue DSL, NPC minds, claims/provenance, validators & bots |
| [`docs/art_direction.md`](docs/art_direction.md) | The beauty bible: *sodium light and carbon paper* — palette, lighting, pixel-art specs, distortion VFX grammar, typography, motion |
| [`docs/ux_charter.md`](docs/ux_charter.md) | Player-experience standards: onboarding contract, respect-for-time rules, quality-of-life inventory, testable enjoyability metrics |
| [`docs/story_bible.md`](docs/story_bible.md) | **Spoiler-complete** narrative canon: fixed timeline (1993–2004), character voice sheets, gazetteer, ground-truth outlines for prologue + slice missions |
| [`docs/roadmap.md`](docs/roadmap.md) | The development backlog: milestone work items with acceptance criteria, and the definition-of-ready-to-code checklist |
| [`docs/dev_log.md`](docs/dev_log.md) | Pass-by-pass engineering log: what was built, how it was verified, what's deferred |

Reading order for a newcomer: this README → `master_plan.md` §0–§3 → `ux_charter.md` → the rest as needed. (`story_bible.md` spoils the entire game — read deliberately.)

## Ground rules (from the plans, binding)
1. **Determinism is law** — the truth simulation replays tick-perfect, always (it's the save format, the bug report, and the Afterimage Theater).
2. **Fairness is auditable** — the distortion system obeys a hard charter, enforced by tooling, and every lie is disclosed after the run.
3. **Missions must be fun sober** — with distortions off, or they're rejected.
4. **Content is data** — no mission logic in engine code.
5. **Cruel game, kind product** — all friction is authored; none is accidental.

## Current progress
Passes 1–19 of a planned 20-pass engineering effort are complete: the repo scaffold, the deterministic core (`FixedMath`, `Xoshiro128StarStar` PRNG, `EventBus`, the `Predicate` language + `WorldQuery`), `GameStateStore`/`SaveSystem` with a real schema migration, the fixed-tick harness (`InputFrame`/`ReplayLog`/`FixedTickClock`), a determinism-corpus mechanism, `TruthSim` — entity-ID'd actors, a sparse collision grid, swept circle-vs-AABB collision, Bresenham line-of-sight, room/portal sound propagation, angular vision cones, utility-scored Sentry/Professional AI, a WitnessSystem, combat verbs v1 (movement modes, a weapon/ammo state machine, fire/takedown/throw resolution, a Focus resource gate, a lean/peek offset, InputMap actions), Pass 7's wiring (AI actors that perceive and fight back for real, a code-defined graybox room, a bot harness soak-testing a full deterministic encounter), Pass 8's percept/truth split (a read-only snapshot export from `TruthSim`, a `PerceptOp`/`PerceptRenderer` decorator pipeline, a CI-enforced static lint proving nothing under `src/percept/` can reference a truth-layer class by name), Pass 9's first four `DistortionOp` classes (`SubtitleDrift`, `AudioSwap`, `PhantomAudio`, `PhantomEntity`), Pass 10's Ground verb and Clarity Mode stub, Pass 11's four-variable Mind Model (`AcuteStressState`, `FatigueState`, `MoralInjuryState`, `IdentityStrainState` composed by `MindModel`), Pass 12's `DistortionDirector` and `FairnessAuditor` v1 (all 8 Fairness Charter rules, each with its own failing fixture), Pass 13's content pipeline (a versioned JSON Schema, a dependency-free `tools/content_validator.py`, and a `MissionLoader`/`MissionPackage` that loads real mission JSON straight into `DistortionDirector`), Pass 14's Replay Theater v0 data model (`ReplayTheater`/`OpTimelineSpan`), Pass 15's Dialogue DSL pipeline (`tools/dlgc.py` compiler, a real compiled prologue Sova scene, and a new `src/dialogue/` runtime with symmetric interrupt-memory contradiction detection), Pass 16's Argus social graph data spine (`NPC`/`SuspicionLedger`/`SuspicionGraph`/`GossipSim` in a new `src/social/`), Pass 17's Claims/Provenance and DebriefLedger (a new `src/debrief/` directory, a liar-bot smoke test), Pass 18's Safehouse Hub skeleton (`HubCalendar`/`MindDashboard`/`Loadout` in a new `src/hub/`), and — as of Pass 19 — the UI shell's data layer in a new `src/ui/` directory: `ThemePalette`/`MotionConstants` (art_direction's color/motion spec as named constants), real `AccessibilitySettings` state (including Clarity Mode's actual on/off gate), and a `ScreenSpec`/`MindDashboardScreen` "placeholder screen as data" abstraction — deliberately not a hand-authored Godot `.tscn`/`.tres` file, since this sandbox has no editor to verify one against (all verified against Python references, hand-traced tick-by-tick, or a deliberately-reintroduced violation before porting/committing). 506 tests, all passing lint/format. Full detail in [`docs/dev_log.md`](docs/dev_log.md); the live backlog is [`docs/roadmap.md`](docs/roadmap.md).
