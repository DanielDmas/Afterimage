# AFTERIMAGES: VRANOV — Development Log
**Document type:** Engineering progress log, one entry per pass. Companion to `roadmap.md` (the checkable backlog) — this file is the narrative "what happened and why," roadmap.md is the "what's left."

Engineering is being delivered in **20 planned passes**. Each pass is a substantial, self-contained chunk of work: implement, test, lint/format-verify, update this log and the roadmap, commit. The plan below is the current best estimate of how the 20 passes divide the work — later passes may adjust it (noted here when they do) as real constraints surface.

---

## The 20-pass plan (living document)

| Pass | Focus |
|---|---|
| **1** | Repo/project scaffold, custom test harness, CI. Deterministic core: `FixedMath`, `Xoshiro128StarStar` PRNG, `EventBus`, `Predicate`/`WorldQuery`. |
| 2 | `GameStateStore` + `SaveSystem` + schema versioning/migrations; fixed-tick sim harness + `InputFrame` recording/replay; determinism corpus v0 + CI job. |
| 3 | TruthSim actor model (integer-mm positions, entity IDs), grid collision, swept casts. |
| 4 | Line-of-sight (occlusion grid) + sound propagation (room/portal graph). |
| 5 | Utility AI skeleton + Sentry/Professional archetypes; WitnessSystem v1. |
| 6 | Combat verbs v1 (move/sprint/crouch/lean/aim/fire/reload/takedown/throw/Focus); InputMap actions. |
| 7 | Graybox test level wiring TruthSim+AI+combat; paranoid/credulous bot harness v0. |
| 8 | PerceptRenderer boundary (read-only truth views, op decorator pipeline) + static truth/percept separation lint. |
| 9 | First DistortionOp classes (`SubtitleDrift`, `AudioSwap`, `PhantomAudio`, `PhantomEntity`). |
| 10 | Ground verb; Clarity Mode stub. |
| 11 | MindModel (four variables, master_plan §4.4 constants, worked-example fixtures). |
| 12 | DistortionDirector (budget/deck/caps/cooling/seeding); fairness auditor v1. |
| 13 | Content pipeline: JSON schemas, content validator CLI, mission package loader + a stub mission fixture. |
| 14 | Replay Theater v0 (data model: dual-pane reconstruction, checkpoint snapshots). |
| 15 | Dialogue DSL parser/compiler + runtime graph + DialogueRunner + interrupt memory. |
| 16 | NPC mind schema + SuspicionGraph + GossipSim. |
| 17 | Claims/Provenance + DebriefLedger; liar-bot smoke test. |
| 18 | Hub skeleton: calendar/sleep economy, mind dashboard bindings, loadout data model. |
| 19 | UI shell (Theme resource, placeholder screens) + accessibility scaffolding. |
| 20 | Integration: playable prologue stub (Ground tutorial + one scripted `SubtitleDrift` + mini-Theater + trivial debrief) on placeholder art; full-suite green; log/roadmap finalized with what's left for post-Pass-20 (real art/audio/content authoring, M5-M7). |

This maps onto `roadmap.md`'s M0–M4 milestones; passes 18-20 begin reaching into M5/M6 territory (hub, UI, integration) at a skeleton/placeholder level. **No real art, music, or voice work happens in these passes** — every pass is engine/tooling/data code plus, where useful, programmer-art placeholders (colored rectangles, primitive shapes) purely so a system can be seen running. Actual asset production per `art_direction.md` and `master_plan.md` §6 is out of this 20-pass engineering arc.

---

## Pass 1 — Foundations: scaffold, deterministic core, test harness, CI

**Delivered:**
- **Project scaffold**: `project.godot` (title *Afterimages: Vranov*, 640×360 logical resolution integer-scaled per tech_guidelines D6, `warnings/treat_warnings_as_errors` on per D2), `docs/ENGINE_VERSION` pinning 4.3.0-stable, `.gitignore`/`.gitattributes` (LFS policy per tech D14), the `/src`, `/tests`, `/content`, `/tools` directory layout from tech_guidelines §5.8.
- **Deterministic core** (`src/core/`):
  - `fixed_math.gd` — Q16.16 fixed-point scalar arithmetic for MindModel/Director math (tech §3.2). Explicitly *not* for world positions (those stay plain integer mm per tech D4) — documented in the class header so a future pass doesn't reach for it in the wrong place.
  - `prng.gd` — `Xoshiro128StarStar`, seeded via four splitmix64 draws from one 64-bit seed (tech D5). One named stream per system is the intended usage pattern once TruthSim/Director/Gossip streams exist (Pass 2+).
  - `event_bus.gd` — typed pub/sub, registration-order dispatch, non-reentrant (queued) re-publish, snapshot-iterated so a handler unsubscribing itself mid-dispatch is safe (foundation_blueprints §1.2).
  - `world_query.gd` + `predicate.gd` — the Predicate language (foundation_blueprints §2): 18 leaf operators + `all`/`any`/`not` combinators, a duck-typed `WorldQuery` read interface, and a pure static `validate()` that content tooling will run in CI later (Pass 13).
- **Test harness** (`tests/framework/`, `tests/run_tests.gd`): a small custom xUnit-style harness (`AfterimageTestCase`, `AfterimageTestRunner`) — **not GUT**. See the decision note below.
- **67 unit tests** across 5 files (`test_fixed_math.gd` 15, `test_prng.gd` 10, `test_event_bus.gd` 11, `test_predicate_evaluate.gd` 20, `test_predicate_validate.gd` 11), plus a reusable `MockWorldQuery` test double in `tests/framework/`.
- **CI** (`.github/workflows/ci.yml`): a `test` job that downloads Godot 4.3-stable headless and runs the suite, and a `lint` job running `gdlint`/`gdformat --check`.
- **Title change**: the game is now titled **Afterimages: Vranov** (README, master_plan.md header + §12 risk resolved, tech_guidelines.md amendment log). The in-fiction mechanic keeps its original name, "the Afterimage."

**Decision — custom test harness instead of GUT (tech_guidelines.md §12 amendment):** `tech_guidelines.md` D13 locked in GUT. GUT has to be fetched from GitHub — as a git submodule or via the editor's AssetLib — and this authoring sandbox has no network path to GitHub (confirmed: `git`/`curl` to `github.com` return a policy-level 403 from the egress proxy, and `git submodule add` needs to resolve a real commit hash from the remote, which isn't possible offline). Rather than block Pass 1 on that or hand-copy a third-party project's source from memory, I built a small in-house harness whose assertion surface (`assert_eq`, `assert_true`, `assert_almost_eq`, …) deliberately mirrors GUT's naming, so adopting real GUT later — once someone with GitHub access pins a commit via submodule — is an addition, not a rewrite of any test file. Recorded as a proper amendment in `tech_guidelines.md` §12, not a silent deviation.

**Verification approach and its honest limits:** this sandboxed environment has no Godot binary and no working Docker daemon, so nothing in this pass has been executed inside the actual Godot runtime by me directly. Given that constraint, verification leaned on everything that *was* available:
1. **The PRNG is the highest-risk piece** (hand-porting 64-bit-unsigned bit-twiddling algorithms into a 64-bit-*signed* scripting language). Rather than trust the port by inspection, I wrote an executable Python reference implementation of splitmix64 + xoshiro128**, ran it to generate concrete output vectors for five seeds, then wrote a *second* Python model that mimics GDScript's exact arithmetic assumptions (signed 64-bit wraparound, arithmetic right-shift, explicit unsigned-shift correction via precomputed masks) and confirmed it reproduces the canonical vectors bit-for-bit before porting that exact logic to GDScript. The five seeds' first-12-draws are pinned directly into `test_prng.gd` as `VECTORS`. The one assumption that couldn't be verified without a real Godot process is that GDScript's `int` actually performs silent two's-complement wraparound on overflow and that `>>` is arithmetic — both are documented Godot 4 behaviors, and the test is written so that if either assumption is wrong, CI's real headless Godot run will fail loudly on `test_reference_vectors_match_across_seeds` rather than silently producing subtly-wrong randomness.
2. **`gdtoolkit` (gdlint/gdformat) was installed and actually run locally** (`pypi.org` is reachable through this session's egress policy even though `github.com` isn't) — every source and test file was run through `gdformat --check` and `gdlint` and is 100% clean, which catches real syntax errors, not just style: gdformat has to fully parse a file's GDScript grammar to reformat it, so a clean run is meaningful evidence the code is at least syntactically well-formed.
3. **GDScript closure semantics were treated as a known trap, not assumed**: GDScript lambdas capture outer local variables *by value*, not by reference, so a naive `var count := 0; bus.subscribe(..., func(e): count += 1)` pattern would silently produce a false test failure (the outer `count` never changes) that has nothing to do with whether `EventBus` itself is correct. Every `EventBus` test that needs a mutable counter across calls uses a small helper class with a bound `Callable(instance, "method")` instead, sidestepping the issue entirely.
4. **What's *not* verified yet**: actual execution inside Godot. The first real Godot run happens in CI on push (GitHub Actions runners have full internet access regardless of this sandbox's restrictions), and I will check that run's logs via the GitHub API/MCP tools immediately after pushing and fix forward in a follow-up commit within this same pass if anything surfaces — this is called out explicitly rather than assumed clean.

**Deferred to Pass 2** (see `roadmap.md` M0): `GameStateStore`, `SaveSystem` + schema/migration harness, the fixed-tick simulation harness, `InputFrame` recording/replay, and the determinism corpus + its CI job. M0's actual exit criterion ("inputs recorded in a stub scene replay tick-perfect") is **not yet reached** — Pass 1 built the deterministic primitives that harness will be built on top of, not the harness itself.

**Files added:** `project.godot`, `.gitignore`, `.gitattributes`, `docs/ENGINE_VERSION`, `.github/workflows/ci.yml`, `src/core/{fixed_math,prng,event_bus,world_query,predicate}.gd`, `tests/framework/{test_case,test_runner,mock_world_query}.gd`, `tests/run_tests.gd`, `tests/unit/{test_fixed_math,test_prng,test_event_bus,test_predicate_evaluate,test_predicate_validate}.gd`.

**Files changed:** `README.md` (title, status, test-running instructions), `docs/master_plan.md` (title, §12 risk resolved), `docs/tech_guidelines.md` (§12 amendment log: test harness decision, title decision), `docs/roadmap.md` (M0 checkboxes updated).

**Post-push CI verification (the loop this whole approach depends on):** first real CI run ([run 29654915740](https://github.com/DanielDmas/Afterimage/actions/runs/29654915740)) came back **lint: pass, test: fail** — checked via the GitHub Actions API, not assumed. The good news first: `gdlint`/`gdformat --check` passing for real on GitHub's infrastructure confirms the local `gdtoolkit` run in this pass was meaningful, not just theater. The failure was real and unrelated to any of the PRNG/overflow risk called out above — it was simpler and more fundamental:

```
SCRIPT ERROR: Parse Error: Could not find type "AfterimageTestRunner" in the current scope.
  at: GDScript::reload (res://tests/run_tests.gd:11)
```

**Root cause:** `.godot/` (Godot's project-scan cache, which is where global `class_name` → script-path resolution gets recorded) is correctly gitignored — it's a local editor artifact, not something to commit. But that means on a genuinely fresh checkout, Godot hasn't scanned the project yet, so none of this pass's `class_name` globals (`AfterimageTestRunner`, `FixedMath`, `Xoshiro128StarStar`, etc.) are resolvable the moment `--script res://tests/run_tests.gd` tries to parse a reference to one. Opening a project in the editor UI triggers this scan invisibly and automatically; running a script directly via `--headless --script` does not.

**Fix:** added an explicit one-time import pass — `godot --headless --path . --editor --quit` — before running the test script, in both `.github/workflows/ci.yml` and the README's local instructions. This forces the same project scan the editor would do on first open, without needing a display. Its own exit code is treated as non-authoritative (`|| true`) since a benign warning can make that pass itself report nonzero; the test-running step right after it is what actually gates the build, and it now starts from a warm class-name cache. This is exactly the verification loop described as the plan for this pass: something unverifiable locally (real Godot script-loading behavior on a cold checkout) surfaced through real CI, got diagnosed from the actual error text rather than guessed at, and was fixed forward in the same pass rather than discovered later.

**Confirmed green** ([run 29655073102](https://github.com/DanielDmas/Afterimage/actions/runs/29655073102), commit `a788729`): both jobs `success`. Pulled the actual test-step log text rather than trusting the exit code alone —
```
Afterimage test run — 5 suite(s), 67 test(s), 6849 assertion(s)
...
ALL PASSED (67/67)
```
— and `gdlint`/`gdformat --check` both clean on GitHub's own infrastructure, matching the local run byte-for-byte. **Pass 1 is closed.** One cosmetic, non-blocking note from the same log for the record: Godot prints `WARNING: ObjectDB instances leaked at exit` / `ERROR: 3 resources still in use at exit` after the test report but before process exit — harmless in a one-shot CLI runner that terminates immediately after (the OS reclaims everything), and it does not affect the exit code (`quit(0 if report.all_passed() else 1)` still returned 0). Worth a look with `--verbose` if a future pass wants zero engine noise in the log, but not worth chasing now.

