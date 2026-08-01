# CLAUDE.md — Repository Guide & Continuation Handbook

**Read this first.** It is written for an AI agent (Claude Code or otherwise) picking up
this repository cold, but it works for a human too. It covers what the repo *is*, how it's
laid out, the rules that govern changes, the traps that have actually bitten this project,
and exactly where to start.

**Companion files:**
- [`docs/GAME.md`](docs/GAME.md) — what the game is and how every system works.
- [`PROGRESS.md`](PROGRESS.md) — everything built so far, and how each piece was verified.
- [`docs/forward_dev_plan.md`](docs/forward_dev_plan.md) — **the live plan.** Start here for "what's next."

---

## 1. What this repository is

**Afterimages: Vranov** — a top-down 2D psychological action thriller in **Godot 4.3**,
GDScript, statically typed, warnings-as-errors.

The engine simulates the **true** world on one layer (`src/sim/`) and renders only what
the player-character **believes** on another (`src/percept/`). After a mission, a replay
theater discloses both. The thesis: *can you report the truth with a lying mind?*

**State:** planning complete and ratified; a 20-pass engineering arc complete; post-arc
phases A, B and Phase C's core logic delivered. **644 tests, CI green.** A real graybox
slice is playable in a browser. Real art, audio, and mission content do not exist yet.

---

## 2. Repository layout

```
Afterimage/
├── CLAUDE.md                    ← you are here
├── PROGRESS.md                  ← what's been built, and how it was verified
├── README.md                    ← public-facing overview + how to play
├── project.godot                ← engine config; encodes locked decisions D1/D6/D11
├── export_presets.cfg           ← Web export preset
│
├── docs/
│   ├── GAME.md                  ← the game explained (systems, story, loop)
│   ├── ENGINE_VERSION           ← 4.3.0-stable. Single source of truth
│   ├── master_plan.md           ← ~75 KB. All system specs (§4), architecture (§5)
│   ├── tech_guidelines.md       ← LOCKED decisions D1–D14 + amendment log
│   ├── foundation_blueprints.md ← foundation-layer specs
│   ├── story_bible.md           ← narrative canon (SPOILS THE ENTIRE GAME)
│   ├── art_direction.md         ← the visual bible
│   ├── ux_charter.md            ← player-experience standards
│   ├── roadmap.md               ← milestone backlog M0–M7 with acceptance criteria
│   ├── dev_log.md               ← ~246 KB. Per-pass narrative, incl. every wrong turn
│   ├── review_and_forward_plan.md ← the F1–F13 code-review findings
│   └── forward_dev_plan.md      ← ★ THE LIVE PLAN (Phases A–G)
│
├── src/                         ← 84 GDScript files, all RefCounted unless noted
│   ├── core/       FixedMath, PRNG, EventBus, Predicate/WorldQuery,
│   │               GameStateStore, SaveSystem, SaveMigrations,
│   │               InputFrame, ReplayLog, FixedTickClock
│   ├── sim/        ★ THE TRUTH LAYER. TruthSim + actors, collision, LOS,
│   │               sound, vision cones, utility AI, combat verbs, Ground,
│   │               the four Mind Model variables, substances, witnesses
│   ├── percept/    ★ THE LIE LAYER. PerceptRenderer, 11 DistortionOps,
│   │               DistortionDirector, FairnessAuditor, OpFactory,
│   │               MissionLoader/Package/DeckEntry, ClarityMode, ReplayTheater
│   ├── debrief/    Claim, ClaimDrafter, ClaimReducer, DebriefLedger,
│   │               DebriefConsequences
│   ├── dialogue/   DialogueGraph, DialogueRunner, InterruptMemory
│   ├── social/     NPC, SuspicionLedger, SuspicionGraph, GossipSim,
│   │               GroundObservationBridge
│   ├── hub/        HubCalendar, MindDashboard, Loadout, LoadoutItem
│   ├── ui/         ThemePalette, MotionConstants, AccessibilitySettings,
│   │               ScreenSpec, MindDashboardScreen, DebriefScreen
│   └── integration/ MissionRuntime, MindModelEventBridge, PrologueStub
│
├── scenes/
│   ├── main.tscn                ← the one real scene (thin; logic is in the .gd)
│   └── main.gd                  ← ★ the playable slice. ~800 lines, heavily commented
│
├── tests/                       ← 104 files, 644 tests
│   ├── run_tests.gd             ← entry point
│   ├── framework/               ← custom xUnit harness (NOT GUT — see §7)
│   ├── fixtures/                ← GrayboxRoom, BotInputs, TruthSimDigest,
│   │                              MissionRuntimeDigest, a deliberately-broken suite
│   ├── corpus/                  ← 3 recorded ReplayLog JSON fixtures
│   └── unit/                    ← one test file per source class
│
├── content/                     ← ★ CONTENT IS DATA. No logic here.
│   ├── missions/m00_stub/mission.json    (an 11-entry distortion deck)
│   └── dialogue/prologue_sova.dlg
│
├── tools/                       ← Python 3, dependency-free, all CI-invoked
│   ├── percept_truth_boundary_lint.py    ← ★ enforces the architecture invariant
│   ├── content_validator.py              ← mission JSON schema validation
│   ├── dlgc.py                           ← the dialogue DSL compiler
│   └── schemas/mission.schema.json
│
└── .github/workflows/
    ├── ci.yml                   ← tests + 5 lint/validation gates, every push
    └── export-web.yml           ← Web export; deploys to Pages on main only
```

---

## 3. The five ground rules (binding — from the ratified plans)

1. **Determinism is law.** The truth sim replays tick-perfect. It is the save format, the
   bug report, and the Afterimage Theater simultaneously. Never introduce a source of
   nondeterminism into `src/sim/` or `src/core/`.
2. **Fairness is auditable.** The Fairness Charter's 8 rules are enforced by
   `FairnessAuditor` against real committed content in CI.
3. **Missions must be fun sober.** A mission with distortions off must still be good.
4. **Content is data.** No mission logic in engine code. Missions are JSON in `content/`.
5. **Cruel game, kind product.** All friction is authored; none is accidental.

---

## 4. The architecture invariant (the one that's machine-enforced)

**Nothing under `src/percept/` may reference a `src/sim/` class by name.**

`tools/percept_truth_boundary_lint.py` derives the denylist from every `class_name`
declaration under `src/sim/` at scan time (so it stays correct as the sim grows), strips
comments to avoid false positives, and fails CI on any violation.

The seam is `TruthSim.capture_percept_snapshot()`, which returns a Dictionary of **plain
values only** — `int`, `bool`, `Vector2i` copied out of each actor — never a reference to
an `Actor` or to `TruthSim` itself. That's what makes "read-only" structurally true rather
than a naming convention: the percept layer holds nothing it *could* mutate.

**Practical consequence:** a class under `src/percept/` that genuinely needs a `TruthSim`
takes a `Callable` factory and duck-types the result (see `ReplayTheater`'s class doc for
the worked example).

---

## 5. Determinism contract (`tech_guidelines.md` §3)

- **30 Hz fixed tick.** Never read engine `delta` in sim code. `scenes/main.gd`
  accumulates real time and steps whole ticks.
- **Integer millimetres** for all world positions. Never floats.
- **Q16.16 fixed-point** (`FixedMath`) for Mind Model and Director math.
- **Sorted iteration** everywhere. Never rely on `Dictionary` iteration order.
- **One seeded `Xoshiro128StarStar` stream per system.** Same seed + same inputs = same
  result, always.
- **No transcendental functions in the per-tick hot path.** `cos()` appears exactly once,
  at content-authoring time, to convert an authored half-angle. Vision cones use squared
  dot products; there is no `atan2`/`sqrt` in sim code.
- `ReplayLog.run_seed` **is** the deterministic seed for a recorded run — it seeds
  `TruthSim` and doubles as `DistortionDirector`'s seed when driving `MissionRuntime`.

---

## 6. Development environment — what you actually have

| Available | Not available |
|---|---|
| GDScript source + Python tooling | **No Godot binary.** You cannot run the game or the tests locally |
| `gdlint` / `gdformat` (gdtoolkit 4.x) | No Godot editor — never hand-author `.tscn`/`.tres` blind |
| GitHub Actions CI (real headless Godot 4.3) | No real art/audio pipeline |
| **Chromium + Playwright** (`/opt/pw-browsers/`) | No target hardware (Steam Deck, phones) |
| `docs.godotengine.org` via WebFetch | Windows/macOS CI runners |
| GitHub MCP tools | `gh` CLI |

**CI is the only place code actually executes.** This shapes everything: verify APIs
against real docs before use, verify arithmetic with Python first, and treat every push as
the experiment.

### Verifying the live build in a real browser

The egress proxy blocks headless Chromium navigation, but **loopback bypasses it**:

```bash
# 1. Download the deployed build via curl (curl works through the proxy)
mkdir -p "$SCRATCH/site" && cd "$SCRATCH/site"
for f in index.html index.js index.wasm index.pck index.audio.worklet.js; do
  curl -sS -o "$f" "https://danieldmas.github.io/Afterimage/$f" &
done; wait

# 2. Serve it over 127.0.0.1 (needs no proxy)
python3 -m http.server 8099 --bind 127.0.0.1

# 3. Drive it with Playwright
#    executablePath: "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
#    args: ["--disable-quic", "--no-first-run", "--no-default-browser-check"]
#    Allow ~14s after goto() for wasm+pck fetch and engine boot.
#    Click the canvas first — it focuses input AND satisfies audio autoplay policy.
```

This rig has already found a real gameplay bug (the wall-slide wedge) and verified audio
(via an `AnalyserNode` RMS tap), the compass arrow (screenshots vs. hand-computed angles),
and the PNG export (a captured `download` event). **Use it. Don't assume a correct API
call means correct behavior.**

---

## 7. Testing

**A custom xUnit-style harness in `tests/framework/`, not GUT.** GUT needs a GitHub fetch
the original sandbox couldn't make; the assertion surface deliberately mirrors GUT's
naming so adopting it later is an addition, not a rewrite. Recorded as a proper amendment
in `tech_guidelines.md` §12.

**Assertions:** `assert_true`, `assert_false`, `assert_eq`, `assert_ne`,
`assert_almost_eq`, `assert_null`, `assert_not_null`, `assert_gt`, `assert_lt`,
`assert_gte`, `assert_lte`.

```gdscript
extends AfterimageTestCase

func test_thing_does_what_it_says() -> void:
    assert_eq(actual, expected, "message shown on failure")
```

**Running them** (only possible where a Godot binary exists):
```bash
godot --headless --path . --editor --quit                   # one-time: builds class cache
godot --headless --path . --script res://tests/run_tests.gd
```
The first line matters: `.godot/` is gitignored, so `class_name` globals aren't resolvable
on a fresh clone until something triggers a project scan.

**Testing principles this project holds:**
- **Never hand-compute a golden hash.** Determinism tests prove *self-consistency* —
  replay the same run twice, digests must match — plus sensitivity (different input ⇒
  different digest). A hand-reasoned expected value just bakes in your mistake.
- **Hash an explicit, hand-formatted state string.** Never `JSON.stringify()` a
  `Vector2i`-bearing Dictionary and hope the round-trip is stable.
- **Prove against real content where it's free.** Several tests load the actual committed
  `mission.json` — safe because they're self-consistency checks, not pinned values.
- A test that fails to *load* must fail the build, never silently vanish from the count.
  `tests/fixtures/broken_suite/` exists to regression-test exactly that.

---

## 8. The pre-commit ritual (run every one of these, every time)

```bash
gdlint src/ tests/ scenes/
gdformat --check src/ tests/ scenes/       # if it complains: gdformat <files> then re-lint
python3 tools/percept_truth_boundary_lint.py
python3 tools/content_validator.py
python3 tools/dlgc.py
```

**`gdformat` will reformat almost anything you write** (it aggressively wraps long
chained calls into parenthesized blocks). Run it, then run `gdlint` *again* — gdformat
occasionally produces a line that trips gdlint's 100-char limit, and the fix is to
restructure (e.g. move a trailing comment onto its own `##` line), not to fight the
formatter.

Then: commit → push → open a PR → **wait for real CI** → pull the actual
`ALL PASSED (N/N)` log text → merge.

---

## 9. Git and CI workflow

- **Work on the designated feature branch**, never commit directly to `main`.
- **Merge commits, never squash** — `dev_log.md` references commit SHAs, and squashing
  breaks them.
- **Never `git commit --amend`** on pushed work; never force-push published history.
- After each merge, `git fetch origin main && git reset --hard origin/main`.
- Use `mcp__github__*` tools for all GitHub operations (no `gh` CLI here).
- **A local stop-hook flags GitHub's own merge commits as "Unverified"** because they're
  authored by `GitHub <noreply@github.com>`. This is normal, expected GitHub behavior and
  **not a problem to fix by rewriting published history.**

**Verifying CI properly:**
```
mcp__github__pull_request_read  (method: "get_check_runs")   → status
mcp__github__get_job_logs       (return_content: true)       → the ACTUAL log text
```
Grep for `ALL PASSED (N/N)`. A green badge is not evidence; the log line is.
On failure, `[FAIL]` lines carry the assertion detail (`expected <44>, got <49>`) —
diagnose from that, never from a guess.

*Note: the `Deploy to GitHub Pages` job carries `if: github.ref == 'refs/heads/main'`
because GitHub protects that environment to the default branch. It correctly shows as
`skipped` on feature branches — that is not a failure.*

---

## 10. Coding conventions

- **Statically typed GDScript, warnings-as-errors.** Type every variable, parameter and
  return. `var x: int = ...` or `var x := ...`.
- **`RefCounted`, not `Node`,** for all sim/percept/logic classes. They must not depend on
  the scene tree.
- **`class_name` on everything** — it's how the codebase resolves cross-file references.
- **Explicit `as SubclassName` casts** when narrowing (e.g. `DistortionOp` → `SubtitleDrift`).
- **Events are facts, past tense**: `ClaimFiled`, not `FileClaim`.
- **Doc comments carry reasoning, not restatement.** The house style is to explain *why*
  a decision was made, what alternative was rejected, what spec section it implements, and
  what is deliberately deferred. Match the surrounding density — it's high.
- **Name deferrals explicitly.** "This is a v1 stand-in for X, deferred because Y" is
  correct. Silent omission is not.
- **`int()`-cast every number that came from JSON.**

---

## 11. Traps that have actually bitten this project

Each of these cost a real CI cycle. They're in `docs/dev_log.md` with full traces.

| Trap | Detail |
|---|---|
| **Sub-property assignment silently fails** | `node.color.a = 0.5` does nothing — the getter returns a *copy* of the built-in value type. Reassign the whole property |
| **Unqualified inner-enum params** | A static method typed with its own class's bare enum name doesn't unify with the qualified name a caller must write. Type the parameter `int` |
| **Engine enums vs. GDScript enums** | Engine-exposed C++ enums are `AudioStreamWAV.FORMAT_16_BITS` — **no** intermediate enum-type name. This codebase's own enums *do* need one: `MovementProfile.Mode.SPRINT` |
| **`get_instance_id()` isn't guaranteed positive** | Godot sets an internal flag bit that reads back negative in GDScript's signed int. Wrap in `absi()` before negating |
| **`RefCounted` subscriber lifetime** | An `EventBus` holding a `Callable` does *not* keep its object alive. A freed bridge silently stops receiving events. **Owners must hold the reference.** (A `var bridge := X.new(...)` that's never read again *is* safe in a test function — verified, not assumed) |
| **`JSON.stringify()` canonicalizes key order** | Whole-Dictionary `==` across a JSON round-trip is not order-stable. Assert specific values |
| **Fresh clones have no class cache** | `.godot/` is gitignored. Run the `--editor --quit` import pass first or `class_name` types won't resolve |
| **`Viewport.get_texture()` too early** | Can be black or stale. `await RenderingServer.frame_post_draw` first |
| **Web-only singletons** | `JavaScriptBridge` exists only in the Web export, but the script is *parsed* on Linux CI. Reach it via `Engine.has_singleton("JavaScriptBridge")` / `get_singleton()`, never as a static type reference |
| **Axis-coupled collision resolution** | One `earliest_t` across both axes zeroes the along-wall component of a diagonal move → the player wedges. Resolve axes independently |

---

## 12. How to continue the work

### The immediate options, in leverage order

**1. Finish Phase C — wire the debrief into the playable scene.**
This is the north star's last mile and the highest-value item. All the logic exists and is
tested; nothing renders it. Needs: a claim-submission UI (`DebriefScreen` already produces
the row data and the legal mode set per claim), then the Afterimage reveal showing
truth-delta side by side (`ReplayTheater` already reconstructs both panes).
*Gate 3 in the plan: "a stranger plays the whole loop in the browser, including the
quiet-knife debrief where honesty still comes back false. This is the demo that explains
the game."*

**2. Phase D — give the world texture.** `AiUtility` already scores PATROL/INVESTIGATE/
FLEE/REPORT and `AiAgent` remembers last-known position, but `TruthSim._resolve_ai_ticks()`
acts only on ENGAGE. Add an authored `PatrolRoute` value type and deterministic movement
toward waypoints, reusing `SweptCollision.move_with_collision()`. Also: wire
`WitnessSystem` into `TruthSim` (built, tested, never called during a run), and wire
`SoundGraph`'s room propagation (built in Pass 4, still waiting for its first consumer).

**3. Phase F — the camera.** *Photographing a phantom yields an empty frame*, because the
camera reads truth while the player sees percept. The game's entire thesis in one
interaction, fully unit-testable, no assets required to be correct.

**4. Phase E — dialogue runtime.** `dlgc.py --emit-json` + a `DialogueLoader`, deleting
`PrologueStub`'s hand transcription. Unblocks all authored dialogue.

**5. Phase G — persistence and platform.** `HubDayLoop`, settings persistence, touch input
(the biggest audience multiplier — phones render but can't move), `tr()` discipline.

### The working method that has worked here

1. **Read `docs/forward_dev_plan.md` first.** It's the live plan and it names what's
   blocked, not just what's next.
2. **Read the existing code around your change.** The doc comments carry the reasoning and
   usually name the deferral you're about to close.
3. **Verify every risky API against `docs.godotengine.org` before writing it.** WebFetch
   works. Do not write from memory.
4. **Verify tricky arithmetic in Python first** (exact `Fraction` where it matters), then
   port.
5. Write the code and its tests together. Match the surrounding comment density.
6. **Run the full pre-commit ritual** (§8).
7. Commit, push, PR, **wait for real CI, read the actual log text**, merge.
8. **If it's player-facing, play the deployed build** (§6) and measure something.
9. **Update `docs/dev_log.md`** — including the wrong turns, honestly. Update
   `docs/forward_dev_plan.md` to mark items delivered, with scope notes for anything
   partial.
10. **Never fold a deferral into "delivered."**

### What NOT to do

- Don't attempt real art, audio assets, shaders, `.tscn`/`.tres` authoring, hardware
  profiling, playtests, or the naming decision. These are named as blocked in the plan
  **on purpose**. Faking them is worse than leaving them.
- Don't break the percept/truth boundary to make something convenient.
- Don't introduce floats into world positions or engine `delta` into sim code.
- Don't put mission logic in engine code — it goes in `content/`.
- Don't hand-compute an expected hash.
- Don't claim something works because the API call looks right. Measure it.

---

## 13. Quick reference

```bash
# Full local verification (everything you can run here)
gdlint src/ tests/ scenes/ && gdformat --check src/ tests/ scenes/ \
  && python3 tools/percept_truth_boundary_lint.py \
  && python3 tools/content_validator.py \
  && python3 tools/dlgc.py

# Run the game / tests (needs a Godot binary — CI only)
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/run_tests.gd
godot --path .
```

| I need to… | Go to |
|---|---|
| Understand the game | `docs/GAME.md` |
| See what's been built | `PROGRESS.md`, then `docs/dev_log.md` for detail |
| Find the next task | `docs/forward_dev_plan.md` §4 (phases), §6 (gates) |
| Check a locked technical decision | `docs/tech_guidelines.md` |
| Find a system's full spec | `docs/master_plan.md` §4 |
| Check narrative canon | `docs/story_bible.md` (**spoilers**) |
| See the playable slice | `scenes/main.gd` |
| See the truth/percept seam | `TruthSim.capture_percept_snapshot()` → `PerceptRenderer.render()` |
| Add a distortion | A new `src/percept/*.gd` + a case in `op_factory.gd` + a deck entry in `content/` |
| Add a mission | `content/missions/<id>/mission.json` (validated by `tools/content_validator.py`) |
