# AFTERIMAGE — Technology Guidelines & Locked Decisions
**Document type:** Technical decision record + engineering guidelines. Companion to `master_plan.md` (§5).
**Purpose:** Every technology choice the project needs is made **here, in advance, in writing**. During development we consult this document; we do not decide on the go.
**Change control:** A locked decision changes only via a written amendment to this file (what changed, why, what it invalidates), and only at a milestone boundary with the determinism suite green. Mid-milestone, this document is read-only.

---

## 1. Locked Decisions (summary table)

| # | Area | Decision | Detail |
|---|---|---|---|
| D1 | Engine | **Godot 4.3.x**, exact patch pinned in `project.godot` + `/docs/ENGINE_VERSION` | §2.1 |
| D2 | Language | **GDScript, static typing mandatory**, warnings-as-errors; C#/GDExtension only through the profiling gate | §2.2 |
| D3 | Simulation | **30 Hz fixed tick; custom deterministic core; no engine physics in TruthSim** | §3 |
| D4 | Numbers | Integer world units (millimeters, millidegrees); shared fixed-point helpers for fractional math; float allowed only presentation-side | §3.2 |
| D5 | RNG | xoshiro128** implementation of our own; one named, seeded stream per system | §3.3 |
| D6 | Rendering | Logical resolution **640×360**, integer-scaled; hi-bit pixel art; Godot CanvasItem lighting + normal maps; all distortion visuals in one shader library | §4 |
| D7 | Content | JSON content packages validated against schemas in `/tools/schemas`; dialogue in `.dlg` DSL; no gameplay data in Godot scene files | §5 |
| D8 | Saves | JSON + gzip, `schema_version` field, forward-only migration ladder with tests | §5.3 |
| D9 | Localization | All strings externalized day one; CSV → Godot `Translation`; drift pairs stored as linked pairs | §5.4 |
| D10 | Audio | Godot audio buses only — **no middleware** (no FMOD/Wwise); adaptive music via stem buses; loudness −16 LUFS integrated, −1 dBTP | §6 |
| D11 | Input | Godot `InputMap` actions only (never raw keycodes in logic); radial deadzone 0.24; full remapping | §7 |
| D12 | UI | Single project `Theme` resource; two typefaces (OFL-licensed), defined in `art_direction.md` §6; UI motion standards | §8 |
| D13 | Testing/CI | GUT for unit tests; determinism corpus re-sim nightly + on PR; GitHub Actions; Linux headless is the reference truth | §9 |
| D14 | Version control | Git, trunk-based with short-lived branches; LFS for `.png/.ogg/.wav`; milestone tags; content freeze tags | §10 |
| D15 | Performance | Sim tick ≤ 4 ms, render ≤ 8 ms on min-spec; RAM ≤ 2 GB; install ≤ 2 GB | §11 |
| D16 | Platforms | Win/Linux/macOS; **Steam Deck is the min-spec reference device** from M5 | §11.2 |

---

## 2. Engine & Language

### 2.1 Engine pinning
- Godot **4.3.x**; the exact patch release is recorded in `/docs/ENGINE_VERSION` and installed from the official build only.
- Upgrades: evaluated **only at milestone boundaries**. Procedure: branch → install candidate → run full determinism corpus + unit suite + one manual mission pass → if green, amend this file and retag; if not, stay pinned. Skipping minor versions is fine; we chase stability, not features.
- No third-party engine forks. Editor plugins allowed only if build-time (import/tooling), never runtime-load-bearing.

### 2.2 Language policy
- **GDScript everywhere**, `static_typing` enforced, untyped declarations are CI lint errors. Warnings are errors.
- **The profiling gate for C#/GDExtension:** a system may be ported only when profiling on the min-spec reference device (§11.2) shows it exceeding its budget (§11.1) across three representative scenes, and a GDScript optimization pass has already failed. The port replaces one module behind its existing interface; it never introduces a second style of architecture.
- Sim-core GDScript is **engine-agnostic by construction**: TruthSim classes extend `RefCounted`/`Object`, never `Node`; they receive time and input as arguments and never read the scene tree, `Input`, or wall clocks. This is what makes headless testing and determinism possible, and it is not negotiable.

---

## 3. Determinism Contract (the load-bearing wall, engineering edition)

### 3.1 Tick & loop
- TruthSim advances at **exactly 30 Hz** in whole ticks; render at display rate with interpolation. The sim never reads `delta` — it receives tick counts.
- Input is sampled per tick into a serializable `InputFrame`; the recorded stream of `InputFrame`s + seeds + content version **is** the replay and the mission save.
- Percept layer, UI, VFX, and audio may be as nondeterministic as they like — nothing downstream of them touches truth.

### 3.2 Numbers
- World positions: **integer millimeters**. Angles: **integer millidegrees**. Timers: integer ticks. Durations authored in seconds are converted to ticks at load, once.
- Fractional math inside the sim (utility scores, budget accrual, decay curves) uses a small shared fixed-point helper set (32-bit, 16.16) — one implementation, unit-tested, used everywhere; no ad-hoc float math in sim code, ever.
- Floats are legal presentation-side only (rendering, tweens, audio). Any value that crosses from percept to truth (there should be none) is a design error.

### 3.3 Randomness
- One PRNG implementation of our own (**xoshiro128**\*\*, ~40 lines, unit-tested against reference vectors). Godot's built-in RNG is never used in sim code.
- Named streams, one per system: `sim`, `ai`, `director`, `gossip`, `ambience` (presentation-only). Stream seeds derive from `(runSeed, streamName, missionId)` via splitmix64. Adding a system never perturbs another stream's sequence.

### 3.4 No engine physics in TruthSim
Godot's physics is not deterministic across platforms and versions; therefore **TruthSim owns its own collision**: grid-based navigation + swept-AABB/circle casts over integer coordinates, and its own line-of-sight (Bresenham/DDA over the occlusion grid) and sound-propagation (BFS over a room/portal graph with integer attenuation). Scope is small by design — top-down, no stacked physics, no ragdolls (deaths are authored sprite animations). Engine physics may be used presentation-side for cosmetic debris only.

### 3.5 Iteration discipline
- Any iteration over collections in sim code uses **deterministic order** (arrays, or sorted keys); dictionary iteration order is never relied upon.
- Entity IDs are sequential integers assigned by the sim, never object instance IDs.

---

## 4. Rendering & Visual Tech
(Aesthetic intent lives in `art_direction.md`; this section is the machinery.)

- **Logical resolution 640×360**, integer scaling to display (2× = 720p, 3× = 1080p, 6× = 4K), letterboxed at odd ratios; UI text renders at native display resolution on a separate layer (crisp type over chunky world — a deliberate signature, see `art_direction.md` §6).
- Godot 2D renderer, **CanvasItem lighting**: normal-mapped sprites, one global ambient per scene + authored practical lights (lamps, signs, headlights); SDF-based 2D shadows for occluders.
- **The distortion shader library:** all percept-side op visuals (dissolve-on-Ground, subtitle correction, geometry snap, Clarity vignette) live in one documented shader include set with named uniforms. Op decorators compose these; no one-off shaders scattered in scenes. Photosensitivity budget (flash frequency/amplitude caps) is encoded as constants here and checked by the fairness auditor.
- Camera: smoothed follow with lookahead, all easing presentation-side; screenshake budget capped (`art_direction.md` §4), zero rotational shake.
- VSync on by default; frame pacing over raw framerate.

---

## 5. Content, Data & Persistence

### 5.1 Content is data
- Mission packages, decks, NPC minds, debrief specs, ending tables: **JSON**, one directory per mission (`/content/missions/mNN_name/`), validated in CI against JSON Schemas kept in `/tools/schemas` (schemas are versioned; a schema change requires a migration note).
- Dialogue: plain-text **`.dlg` DSL** (spec: `foundation_blueprints.md` §4), compiled to graph JSON by `/tools/dlgc`; compiled output is a build artifact, never hand-edited, never committed.
- Godot `.tscn` scenes carry **presentation only** (sprites, lights, colliders for cosmetics). Truth-layer level data (occlusion grid, portals, patrols, affordance annotations) is exported to the mission package by an editor tool; the sim never parses scenes.

### 5.2 IDs & references
- All content cross-references are string IDs (`npc.vrba`, `claim.m03.beating_witnessed`), namespaced `domain.mission.local`. The validator resolves every reference; dangling IDs fail CI. No positional/index references between files.

### 5.3 Saves
- Hub/meta save: JSON (gzip), human-diffable when decompressed; contains `schema_version`, campaign state, mind state, ledgers. Mission-in-progress save: the replay log itself (§3.1).
- **Migration ladder:** version N loads version N−1 saves via chained migrations, each with a fixture test. We never break saves inside a released branch; slice-era saves may be broken before release exactly once, announced.
- Three rotating autosave slots at cycle boundaries + one debrief-submission save (master_plan §4.10); manual save anywhere in hub.

### 5.4 Localization
- Source strings live in content files as keys; English text in `/content/loc/en.csv`, loaded through Godot `Translation`. No literal user-facing strings in code or scenes (CI greps for it).
- `SubtitleDrift` pairs are a first-class loc structure: `{key_true, key_drift, drift_intent}` — exported together, translated together, auditor-checked for orphans (master_plan §6.3).

---

## 6. Audio Tech
- **No middleware.** Godot buses: `Master → {Music, SFX, Ambience, Voice, Percept}`. The `Percept` bus carries distortion-owned audio so Clarity Mode and accessibility mixes are a bus-level operation, not per-sound bookkeeping.
- Adaptive score: stem-based — parallel loops on synchronized playback, mixed by bus automation from `MindState` bands; beat-grid data per track so transitions land musically. (Thinning-with-stress model: `master_plan` §8.)
- Formats: `.ogg` (music/ambience, 128–160 kbps), `.wav` 48 kHz (short SFX). Loudness: **−16 LUFS integrated**, true peak −1 dB; per-bus headroom documented in the mix sheet.
- Truth sounds and their distorted twins are authored as **pairs sharing a base take** (95%-identical goal, `master_plan` §8); the pair link is metadata, so the Theater can A/B them and the auditor can find unpaired twins.
- Voice count budget: 32 simultaneous; priority classes (dialogue > gameplay tells > ambience) with defined stealing rules.

---

## 7. Input
- All gameplay input flows through Godot `InputMap` **actions** (`move_up`, `ground`, `focus`, …); code never reads keycodes/buttons directly. Full remapping UI over the same action table.
- Controller: radial deadzone 0.24, response curves defined once in an input config resource; twin-stick aim with optional light magnetism (strength a settable constant, off at max difficulty).
- Hold-vs-toggle: every hold verb (Ground, chokehold) has a toggle alternative driven by one accessibility flag (master_plan §4.16).
- Rumble: sparse, meaning-bearing only (heartbeat at stress Crisis, Ground completion); global slider incl. off.
- Reference glyph sets: Xbox, PlayStation, generic; auto-detected, manually overridable.

---

## 8. UI Tech
- One project-wide `Theme` resource; per-screen styling by theme *variations*, never inline overrides (CI lint).
- Screens are Godot `Control` scenes with a thin view-model layer: UI reads read-only state snapshots off the EventBus; UI never mutates game state directly (same boundary discipline as percept/truth).
- UI text at native resolution (§4); dynamic font sizing for the four supported UI scales; all paperwork screens expose a screen-reader traversal order (master_plan §4.16).
- Motion standards (durations/easings) are constants in the theme, defined in `art_direction.md` §7 — one source, no per-screen invention.

---

## 9. Testing & CI
- **Framework:** GUT (Godot Unit Test). Unit coverage mandatory for: predicate evaluator, fixed-point helpers, PRNG, MindModel arithmetic, director budgeting, suspicion propagation, claim truth-delta, save migrations.
- **Determinism corpus:** recorded runs (input logs + expected end-state hashes + per-100-tick checkpoint hashes) in `/tests/corpus`. CI re-simulates the corpus **on every PR** (fast subset) and **nightly** (full, on Linux + Windows + macOS runners); any hash divergence fails. Linux headless output is the reference truth.
- **Content CI:** schema validation, ID resolution, fairness auditor, loc-pair audit, calendar lint — on every commit touching `/content`.
- **Bots:** paranoid/credulous/liar bots (master_plan §10) run nightly against all shipped missions.
- **Pipeline:** GitHub Actions; jobs: lint (gdscript-toolkit) → unit → content validation → determinism subset → export smoke (all three platforms, headless). Nightly adds full corpus + bot soak. A red main branch blocks all merges; no exceptions culture.

---

## 10. Version Control & Workflow
- Git; **trunk-based**: short-lived feature branches → PR → green CI → merge. No long-lived divergence.
- LFS: `*.png`, `*.ogg`, `*.wav`, `*.ttf`. Everything else is text and reviewed as diffs (this is why content is JSON/DSL).
- Tags: `mN-exit` at each milestone; `content-freeze/*` before playtest builds. Builds are reproducible from tag + pinned engine.
- Commit discipline: one logical change per commit; content commits name the mission touched.

---

## 11. Performance, Platforms & Budgets

### 11.1 Frame budgets (min-spec device, worst authored scene)
| Slice | Budget |
|---|---|
| TruthSim tick (30 Hz) | ≤ 4 ms |
| Render frame (60 Hz) | ≤ 8 ms |
| Percept op overhead | ≤ 1.5 ms of the render budget |
| Theater re-sim scrub | ≤ 100 ms to any point (checkpoint snapshots every 10 s of log) |
| RAM | ≤ 2 GB working set |
| Install size | ≤ 2 GB |
| Load: cold boot → menu ≤ 10 s; hub → mission ≤ 5 s; death → retry **≤ 3 s** | |

### 11.2 Platforms
- Windows 10+, Ubuntu-class Linux, macOS 12+ (arm64 + x86_64).
- **Steam Deck is the minimum-spec reference device** and the profiling target from M5 (it also standardizes the controller story). Anything hitting budget on Deck is fine everywhere we ship.
- Desktop GPU floor: anything Vulkan-capable from ~2016 (GTX 900-class/iGPU); Godot's GL compatibility renderer is our documented fallback if Vulkan drivers misbehave, tested quarterly.

---

## 12. Amendment Log
| Date | Decision | Change | Reason |
|---|---|---|---|
| — | — | Initial ratified version | — |
| Pass 1 | D13 testing framework | Ships as a small custom GDScript test harness (`tests/framework/`, `AfterimageTestCase`/`AfterimageTestRunner`) instead of GUT for now | GUT must be fetched from GitHub (submodule or AssetLib); the authoring environment for this pass has no network path to GitHub, so a submodule reference can't even be pinned (recording it requires resolving a commit hash from the remote). The custom harness's assertion API deliberately mirrors GUT's naming, so swapping in real GUT later — once someone with GitHub access pins a commit — is an addition, not a rewrite of any test file. Revisit at the next milestone boundary that touches testing infra |
| Pass 1 | Title | Game titled **Afterimages: Vranov** (master_plan.md header + §12), resolving the title-collision risk ahead of its scheduled M5 slot. Formal trademark/storefront search remains an M5 task | The collision (an unrelated, already-released same-named game) was flagged as a design-only risk in master_plan v2.0; naming it now, before any code/content references a title string, avoids a rename pass later |
