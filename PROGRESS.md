# AFTERIMAGES: VRANOV — Progress Record

**Everything built so far, in order, with how each piece was verified.**

This is the executive summary. The exhaustive narrative — including every wrong turn,
every CI failure and its root cause — lives in [`docs/dev_log.md`](docs/dev_log.md)
(~246 KB, one entry per pass). This file is the map to it.

- **What the game *is*:** [`docs/GAME.md`](docs/GAME.md)
- **How to continue the work:** [`CLAUDE.md`](CLAUDE.md)
- **What's next:** [`docs/forward_dev_plan.md`](docs/forward_dev_plan.md)

---

## Status at a glance

| Metric | Value |
|---|---|
| **Tests** | **644**, all green in CI |
| **Source files** | 84 GDScript files under `src/` |
| **Test files** | 104 under `tests/` |
| **Commits** | 107 |
| **Engine** | Godot 4.3.0-stable (pinned in `docs/ENGINE_VERSION`) |
| **CI gates** | unit tests · `gdlint` · `gdformat --check` · percept/truth boundary lint · content schema validation · dialogue DSL compile · Web export build |
| **Live build** | <https://danieldmas.github.io/Afterimage/> (auto-deploys on merge to `main`) |
| **Planning docs** | Complete and ratified |
| **Engineering arc** | 20/20 passes complete |
| **Forward plan** | Phases A, B complete · Interlude complete · Phase C core logic complete · Phases D–G open |

---

## Phase 0 — Pre-production (complete, ratified)

Before a single line of engine code, the entire design was written down and locked:

| Document | Governs |
|---|---|
| `docs/master_plan.md` (~75 KB) | Design pillars, story, all system specs (§4), architecture (§5), milestones M0–M7, testing, risks |
| `docs/tech_guidelines.md` | **Locked** technology decisions D1–D14. Change-controlled with an amendment log |
| `docs/foundation_blueprints.md` | Foundation-layer specs: EventBus, GameStateStore, predicate language, dialogue DSL, NPC minds, claims/provenance, validators, bots |
| `docs/story_bible.md` | Spoiler-complete narrative canon: 1993–2004 timeline, character voice sheets, gazetteer, ground-truth mission outlines |
| `docs/art_direction.md` | *Sodium light and carbon paper* — palette, lighting, pixel specs, distortion VFX grammar, typography, motion |
| `docs/ux_charter.md` | Onboarding contract, respect-for-time rules, QoL inventory, testable enjoyability metrics |
| `docs/roadmap.md` | Milestone backlog M0–M7 with acceptance criteria |

**A structural decision made here shaped everything after it:** an earlier design
(*The Quiet Ledger*) was shelved as a game, but its *designs* survive as blueprints. This
project builds to those specs standalone — no code was imported, because none existed.

---

## Phase 1 — The 20-pass engineering arc (complete)

Each pass: implement → test → lint/format-verify → update the log → commit → **verify
against real CI logs** → close.

| Pass | Delivered | Notable |
|---|---|---|
| **1** | Scaffold, deterministic core (`FixedMath`, `Xoshiro128StarStar`, `EventBus`, `Predicate`/`WorldQuery`), custom test harness, CI | 67 tests. PRNG ported via an executable Python reference first — signed-64-bit wraparound verified bit-for-bit before writing GDScript |
| **2** | `GameStateStore`, `SaveSystem` + schema migrations, fixed-tick harness (`InputFrame`/`ReplayLog`/`FixedTickClock`), determinism corpus v0 | 111 tests. gzip framing verified against RFC 1952 directly, not assumed |
| **3** | TruthSim actor model, sparse collision grid, swept circle-vs-AABB | 150 tests. Every collision case worked out in exact-`Fraction` Python first |
| **4** | Line-of-sight (Bresenham), sound propagation (room/portal graph) | 176 tests |
| **5** | Vision cones, utility AI, Sentry/Professional archetypes, `WitnessSystem` v1 | 218 tests. Cone math uses squared dot products — no `atan2`/`sqrt` in sim code |
| **6** | Combat verbs v1, InputMap actions | 269 tests. **Found a real Godot limitation**: a static method's own unqualified inner-enum name doesn't unify with the qualified name a caller must write |
| **7** | Graybox room wiring TruthSim + AI + combat, bot harness v0 | 289 tests. First real fight — AI perceives and shoots back |
| **8** | Percept/truth boundary, read-only snapshots, op decorator pipeline, **CI boundary lint** | 297 tests. The architecture invariant became enforced, not just documented |
| **9** | First four `DistortionOp` classes | 323 tests. CI caught that `get_instance_id()` isn't guaranteed positive in GDScript's signed int |
| **10** | The Ground verb, Clarity Mode stub | — |
| **11** | Four-variable Mind Model | Caught a real bug: per-tick and batched acute-stress decay disagreed |
| **12** | `DistortionDirector`, `FairnessAuditor` v1 | All 8 Charter rules, each with its own failing fixture |
| **13** | Content pipeline: JSON Schema, `content_validator.py`, `MissionLoader`/`MissionPackage` | Real mission JSON loads straight into the Director |
| **14** | Replay Theater v0 data model | Dual-pane reconstruction, checkpoint snapshots |
| **15** | Dialogue DSL (`tools/dlgc.py`) + `DialogueRunner` + `InterruptMemory` | Symmetric contradiction detection |
| **16** | Argus social graph: `NPC`, `SuspicionLedger`, `SuspicionGraph`, `GossipSim` | — |
| **17** | Claims/Provenance + `DebriefLedger`, liar-bot smoke test | — |
| **18** | Hub skeleton: `HubCalendar`, `MindDashboard`, `Loadout` | — |
| **19** | UI shell data layer: `ThemePalette`, `MotionConstants`, `AccessibilitySettings`, `ScreenSpec` | Deliberately **not** hand-authored `.tscn`/`.tres` — no editor to verify against |
| **20** | Integration capstone: `PrologueStub` plays a full scenario end to end | A debrief submission comes back **false even though the player told the truth as they believed it** — the thesis, executable |

---

## Phase 2 — Post-arc: closing the seams

Every mechanism existed and was unit-tested, but the *seams between* them weren't wired.

### Bug audit + substance model
An independent audit pass, plus `src/sim/substance_model.gd` (§4.4.5's honest
long-term-cost curves).

### First playable scene + Web export
`scenes/main.gd` and `.github/workflows/export-web.yml` — a real browser build.

### Code review → `docs/review_and_forward_plan.md`
Findings **F1–F13**: the blank spots between individually-green systems. Most now closed.

| Finding | Resolution |
|---|---|
| **F1** — real content never built real ops | `OpFactory` — and running the fairness auditor against committed content **immediately caught two real, previously-invisible Charter-tag bugs** |
| **F9** — determinism corpus still on a Pass 2 stub | Re-pointed onto the real `TruthSim` |
| **F5** — Ground observation never reached the social graph | `GroundObservationBridge`. Its debugging surfaced a **class of bug**: a `RefCounted` subscriber freed while `EventBus` still held its `Callable`. Traced honestly in the dev log |
| F7 | GitHub Pages toggle — owner-only, since done |
| F8 | Dialogue runtime loader — still open (Phase E) |
| F10–F13 | Hub day loop, input/platform, settings persistence, localization — open (Phase G) |

---

## Phase 3 — `docs/forward_dev_plan.md` (v2): the playable-loop north star

**North star:** *a stranger opens the browser build and, in ~3–4 minutes, plays a
complete miniature of the whole game.*

### Phase A — Complete the DistortionOp taxonomy ✅
The remaining seven ops: `HUDGlitch`, `ObjectSwap`, `FamiliarFace`, `EntityMask`,
`GeometrySwap`, `TimeGap`, `MemoryEdit`. Charter rules 2 and 4 became **structurally
enforceable** instead of merely declared. The stub mission's deck grew from 4 to 11 real
entries. *(603 tests)*

### Interlude — making the demo actually playable ✅
A player-experience pass: a second visually distinct distortion, a marked exit the player
walks to when *they're* ready, onboarding text, a Ground vignette ramped by the **real**
`GroundState.DURATION_TICKS` (not a cosmetic timer), the first-ever `ClarityMode` consumer,
a restart loop, branching disclosure text. *(609 tests)*

### Phase B — The runtime distortion spine ✅
`MissionRuntime` + `MindModelEventBridge`. `DriftEncounter`/`PhantomEncounter` — the
hand-scripted pair — **deleted**, not archived. The scene now loads real
`mission.json` via `MissionLoader` and lets a seeded `DistortionDirector` purchase from
the real 11-op deck. Closed with `MissionRuntimeDigest`, a full-pipeline determinism
corpus proving the whole stack re-simulates hash-identical from one seed. *(615 tests)*

### Release to `main`
The entire project merged via PR #1.

### The wall-slide bug — found by *playing* the deployed build
The clearest lesson of the project. After deploying, the live build was played in a real
headless browser — and the player **wedged permanently against a wall**, stuck at an
identical position across 500+ ticks.

**Root cause:** `SweptCollision.move_with_collision()` computed one `earliest_t` across
both axes and scaled the whole delta by it — so a diagonal push into a wall zeroed the
*along-wall* component too. Fixed by resolving axes independently, plus an exclusive
parallel-slab tangency boundary (needed because after axis-separated resolution an actor
sits exactly *on* the expanded face, which the old inclusive test would treat as still
blocking).

**No amount of code review or unit testing had caught it.** Two regression tests were
added, and the fix was confirmed by re-playing the redeployed build.

### The Interlude backlog — all sandbox-buildable items ✅

| Item | Delivered | Live-verified how |
|---|---|---|
| **Procedural audio** | Ground chime + distortion hum, synthesized at runtime as real `AudioStreamWAV` buffers, zero asset files. Click-free loop by construction (both oscillators complete whole cycles across the buffer) | An `AnalyserNode` tapped the real Web Audio output; RMS energy over time matched the sim's tick math — hum steady while a distortion was active, a transient spike at *exactly* 2.5s into a Ground hold (75 ticks @ 30Hz), then exact silence once ops cleared |
| **Directional objective indicator** | A `Polygon2D` compass arrow in the exit's own colour, rotated via `Vector2.angle()` | Screenshots at three player positions matched hand-computed `atan2` angles, including a clean flip to horizontal when the player crossed below the exit's Y |
| **Shareable reveal export** | Press `E` on the reveal panel → viewport captured as PNG → real browser download via `JavaScriptBridge.download_buffer()`, reached through `Engine.has_singleton()` so the Web-only class is never a static reference the Linux CI job must parse | Playwright's `page.waitForEvent("download")` captured a genuine download; the saved file is a valid 640×360 PNG showing the real reveal content |

*Still open in that backlog: more than one room, and camera follow/zoom (which depends on
it). Both are real content-authoring work, not scene-script passes.*

### Phase C — The debrief loop (core logic ✅, scene integration open)

| Piece | What it does |
|---|---|
| `ClaimReducer` | Reduces a percept view into claim candidates (one per actor, rising edge only) and real `ActorDowned` facts into claims. **A believed-`PhantomEntity` sighting reduces identically to a real actor's** — the quiet knife, mechanized |
| `DebriefConsequences` | Pure `bill(mode, truth_delta)` worked-example math. The spec pins the *shape* (an honest error costs less than a fabrication) but not numbers — so these are defined here and documented as chosen, not derived |
| `DebriefScreen` | Data-class debrief UI following `MindDashboardScreen`'s precedent; offers only the honesty modes legal for each claim's provenance |
| `GameStateStore` | Gained `campaign.doubek_trust` and `campaign.resource_budget` |
| `DebriefLedger` | Optional `game_state` parameter (mirrors the existing `moral_injury` one) writing trust/resources plus a discoverable fabrication plot flag |
| Integration test | Runs a real `TruthSim` + `MissionRuntime`, reduces sightings, drafts real claims, submits a mix of modes — proving the phantom claim comes back `truth_delta = 1` and the real one `0`, from the same reduction code, in the same run |

*CI caught one bug here — in the **test's own arithmetic**, not the production code: the
expected-trust formula assumed both claims were FABRICATE when the test submits one
AS_SEEN. `DebriefConsequences`' own dedicated tests were green on the same run.*

**Scoped honestly, not silently narrowed:** this covers claim *sightings*, not the plan's
original "a phantom the player **shot**" wording — reducing `WeaponFired` into
believed-target data needs `CombatResolver`'s targeting geometry redone against percept
data, a separate and larger piece. And `scenes/main.gd` has no interactive debrief UI yet.
Both tracked as explicit open items in `docs/forward_dev_plan.md`.

---

## What remains

### Open phases (`docs/forward_dev_plan.md`)

- **Phase C, remainder** — wire the debrief + reveal into the web scene.
- **Phase D** — enrich the truth sim: AI patrol/investigate movement (waypoint data),
  wire `WitnessSystem` into `TruthSim`, wire `SoundGraph` room propagation.
- **Phase E** — the dialogue runtime decision: `dlgc.py --emit-json` + a `DialogueLoader`,
  deleting `PrologueStub`'s hand transcription.
- **Phase F** — journal/camera/evidence. *The showcase mechanic: photographing a phantom
  yields an empty frame, because the camera reads truth, not percept.* Fully testable.
- **Phase G** — `HubDayLoop`, settings persistence, touch input, localization discipline,
  `ReplayTheater` memory scheme, itch.io publishing.

### Genuinely blocked (needs a human, an editor, assets, or hardware — do **not** fake)

Real art / audio / VFX / shaders · a hand-authored Godot `Theme` / `.tres` / `.tscn` ·
the distortion shader library and photosensitivity caps · Steam Deck profiling ·
the naming/trademark decision · human playtests · the sensitivity review · the trailer ·
Windows/macOS CI runners.

---

## The verification discipline (why the record is trustworthy)

Every claim in this file was verified before being written down. The rules the project
holds itself to:

1. **Verify every risky API against the real docs before use** — not from memory.
   Real examples: `AudioStreamWAV` construction, `PackedByteArray.encode_s16`,
   `Vector2.angle()`, `JavaScriptBridge.download_buffer`, `Engine.has_singleton`,
   `Tween`, and the engine-enum-vs-GDScript-enum access distinction.
2. **Verify arithmetic with an independent tool first.** The PRNG, the swept-collision
   cases, the Bresenham octants and the vision-cone angles were all worked out in Python
   (exact `Fraction` where relevant) *before* being ported to GDScript.
3. **Never hand-compute a "golden" hash.** Determinism tests prove *self-consistency*
   (replay the same run twice, get the same digest) — never a value someone reasoned out,
   which would just bake a mistake in as the expected answer.
4. **CI is authoritative.** No local Godot binary exists in the sandbox. Every pass pulls
   the **actual `ALL PASSED (N/N)` log text** — never trusting the badge.
5. **Play the deployed artifact.** The wall-slide bug proved this isn't optional. Audio,
   the compass arrow, and the PNG export were each confirmed by driving a real headless
   browser against the real live build, with measurements (RMS traces, hand-computed
   angles, captured download events) — not by assuming a correct API call means correct
   behavior.
6. **Document wrong-then-right honestly.** Every CI failure's real root cause is in
   `docs/dev_log.md`, including the several that turned out to be mistakes in a *test*
   rather than in production code. That history is the most useful part for whoever
   comes next.
7. **Say what isn't done.** Deferrals are named in the plan documents, never folded into
   "delivered."
