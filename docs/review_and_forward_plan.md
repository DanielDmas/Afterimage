# Code Review, Blank Spots & Forward Plan
**Date:** 2026-07-19 (post-arc, after the first playable Web build)
**Scope:** full-repo review — 70 source files, 79 test files, tools, CI, content, and the new `scenes/` + export pipeline. Review only; no code was changed in this pass.
**Method:** every claim below was verified against the actual code (grep/read), not recalled from memory. Where a finding contradicts something a doc promises, both sides are cited.

---

## 1. What is genuinely solid (baseline, for calibration)

- **529 tests, CI green**, on real headless Godot — logic-level correctness of the deterministic core, TruthSim, percept ops, Mind Model, Director, social graph, debrief, hub, and substance model is well covered and has survived an independent re-derivation audit (dev_log "Post-arc: bug audit").
- **The percept/truth boundary holds** structurally and by static lint (24 forbidden names, 0 violations).
- **The Web export pipeline works end to end** on real CI (run 29689158562) — renderer choice, template install, preset, artifact upload all confirmed, not assumed.
- The codebase's discipline (verify-externally-then-port, sorted iteration, tick-counted time, "state now, consumer later") is applied consistently enough that most findings below are *unwired seams*, not defects.

---

## 2. Findings — ranked, each independently verified

**Status update (post-arc "thesis demo" pass, see dev_log.md):** P1 (F2, F7, icon half of F13) and P2 (F3) are closed. P3's acceptance bar — Ground verb wired, one scripted drift, dual-view reveal, playable by a stranger in under two minutes — is met; the AI addition mentioned alongside it was left for later, as this doc's own P3 description allowed. F4 and F6 (originally scoped to P1) ended up delivered as part of P3 instead, since the reveal panel made `ReplayLog` recording load-bearing rather than optional. The palette half of F12 is also closed. F1, F5, F8, F9, F10, F11 (remaining), and F12 (settings persistence) remain open — see each finding below for current status.

### F1 — The Fairness Auditor cannot audit the content pipeline's actual decks (architectural seam, highest priority) — **CLOSED**
**Post-arc update:** closed via `src/percept/op_factory.gd` (`OpFactory.build()`) exactly as this finding's own fix direction proposed, plus `DeckEntry.params`/`MissionLoader` passthrough and a `"params"` schema field (loosely typed — real validation is `OpFactory.build()`'s job). `tests/unit/test_mission_content_fairness.gd` is the "runs on every content commit" proof: it loads the real `content/missions/m00_stub/mission.json` through the real `MissionLoader`, builds every entry through `OpFactory`, and runs `FairnessAuditor.validate()` against the result, asserting zero violations. Building this surfaced two real, previously-undetected bugs it was specifically designed to catch: `PhantomAudio` never declared the Charter rule-1 tag it structurally always satisfies, and `PhantomEntity` never declared the (universal) rule-3 tag — both from Pass 9, invisible until real op classes (not hand-built test fixtures) ran through the real auditor for the first time. Both fixed, both now have dedicated regression tests. See dev_log.md's own entry for full detail.

<details><summary>Original finding (kept for record)</summary>
`FairnessAuditor.validate()` requires entries exposing `fairness_tags`, `dramatic_intent`, and passing `entry is DistortionOp` (rule 6). But the deck the Director consumes — and the only deck shape the content pipeline produces (`mission.json` → `MissionLoader` → `DeckEntry`) — has **none of those fields** (`DeckEntry`: `op_class/tier/cost/variable_affinity` only). Verified: zero occurrences of `fairness_tags`/`dramatic_intent` anywhere in the deck-loading path; the auditor's own tests validate only hand-built op instances and `_FakeOp` doubles.

**Consequence:** master_plan §10's promise — "fairness auditor… runs on every content commit" — is currently *unsatisfiable* against real content. There is also **no factory anywhere** that turns a purchased `DeckEntry.op_class` string into a live `DistortionOp` instance, which is the same missing bridge from the other side: the Director produces purchase records nothing can execute.

**Fix direction (design, not code yet):** one `OpFactory` (op_class string → configured `DistortionOp`), used both (a) at runtime to instantiate purchases, and (b) by a new CI step that loads every `mission.json`, instantiates its full deck through the factory, and runs `FairnessAuditor.validate()` on the result. That makes the §10 promise real with one mechanism, and gives real ops their charter tags exactly once (in the op classes, where they already live).
</details>

### F2 — CI never lints `scenes/` (tooling gap, trivial to close) — **CLOSED**
`ci.yml`'s lint job runs `gdlint src/ tests/` and `gdformat --check src/ tests/`. The new `scenes/` directory is invisible to it. It was linted locally before commit, but nothing prevents future drift. One-word fix per line in `ci.yml`.

### F3 — The playable scene renders *truth* directly; the percept seam is bypassed — **CLOSED**
`scenes/main.gd::_update_visuals()` reads `_sim.player_position()` — truth-layer state — straight into pixels. Acceptable for a movement-only slice, but the entire premise of this game is that the render layer consumes `capture_percept_snapshot()` → `PerceptRenderer.render()` output, never truth. The moment the first distortion is wired in, this must flip — and it's cheaper to flip *now*, while the scene is 180 lines, than after HUD/combat/AI rendering accretes on the wrong side of the seam. Note: `tools/percept_truth_boundary_lint.py` only scans `src/percept/` (verified), so nothing mechanical stops `scenes/` from reading truth forever. Consider extending the lint with a rule for `scenes/`: rendering code may hold a `TruthSim` (it must, to step it) but should consume snapshots for display.

### F4 — The playable scene doesn't record a `ReplayLog` (determinism contract unexercised where it matters most) — **CLOSED**
tech_guidelines §3.1: the recorded frame stream + seed *is* the save and the Theater's source. `main.gd` builds `InputFrame`s and steps the sim correctly, but discards them — no `ReplayLog.record()`. Every browser session is therefore unreproducible, and the one place real human input finally exists feeds nothing into the replay/Theater machinery that 14+ passes built. Recording is ~3 lines; a "download replay JSON" debug button in the web build would additionally turn any player-encountered bug into a deterministic repro — the exact payoff the architecture was designed for.

### F5 — Event economy is publish-only: `GroundObserved` and `SuspicionEntryAdded` have zero subscribers
Verified by grep: both are published (TruthSim, GossipSim) and consumed nowhere. The designed pipeline — Ground observed → suspicion entry → gossip propagation → org board — exists as disconnected segments. Each deferral was individually reasonable ("state now, consumer later"); collectively they mean the social-consequence loop has never run end to end, even in a test. **Suggested next step:** one integration test in the PrologueStub style that wires TruthSim's EventBus → a SuspicionGraph subscriber → GossipSim and proves one Ground-observed event lands as a decaying ledger entry.

### F6 — `main.gd` doesn't pass an `EventBus` to `TruthSim` — **CLOSED**
Related to F5 but distinct: the playable scene constructs `TruthSim.new(...)` without the optional `event_bus`, so even the events that *are* published go nowhere in the real build. Free to fix whenever the scene grows a consumer.

### F7 — Export workflow dies on merge (branch filter) + Pages still off — **branch filter CLOSED, Pages toggle still open**
`export-web.yml` triggers only on `push` to `claude/afterimage-game-plan-uib3rh`. Merged to any other branch, the playable build silently stops updating. Also, the `deploy-pages` job still 404s until the repo owner enables **Settings → Pages → Source: GitHub Actions** (one-time manual toggle; the workflow artifact remains the fallback). Forward fix: trigger on the default branch too, keep `workflow_dispatch`.

### F8 — Dialogue content cannot reach the runtime
`tools/dlgc.py` (Python) compiles `.dlg` → graph JSON, but compiled output is deliberately never committed, and there is no GDScript loader that parses `.dlg` or reads compiled JSON at runtime. Today the *only* way dialogue enters the game is hand-transcription into a `const Dictionary` (PrologueStub). That's fine for one scene; it does not scale to "hub cast dialogue to slice depth" (roadmap M6). Two honest options to decide between: (a) commit compiled JSON as build artifacts of a CI step (revisit the tech_guidelines §5.1 "never commit compiled output" rule with an amendment), or (b) a small GDScript JSON-graph loader + CI step that compiles `.dlg` → JSON into the export only. Either is small; the *decision* is the missing piece.

### F9 — Determinism corpus still points at StubSim (deferred since Pass 3)
`tests/corpus/` still exercises the disposable Pass 2 `StubSim`. The original deferral reason ("TruthSim too boring to hash") expired around Pass 7 — TruthSim now has AI, combat, noise, Ground. Re-pointing the corpus at a real graybox encounter (record once via bot, hash re-simulation) would make the determinism CI actually guard the sim that ships. Also unblocks the roadmap's "100% green corpus 14 consecutive nights" release gate, which is meaningless against StubSim.

### F10 — No hub "day loop" orchestrator
`HubCalendar.advance_day()`, `SubstanceModel.advance_day()`, `MoralInjuryState.decay_passive_daily()`, and `SuspicionLedger`'s day-based decay are all correct in isolation but caller-sequenced — four separate calls with an implicit required order that only test code currently knows. A thin `HubDayLoop` (sequence-calls-only, like HubCalendar itself) would make "one day passes" a single authoritative operation before save/load integration multiplies the callers.

### F11 — Input & platform gaps in the playable build
- Only 5 of the 14 declared InputMap actions are key-bound; **Ground — the signature verb — is unbound and unplayable.**
- No touch controls: the web build is dead on phones/tablets (canvas renders, nothing moves).
- No gamepad events bound (deadzones declared since Pass 6, no joypad bindings).
- Crouch exists in the sim and has no key.
- Diagonal movement is 1.41× speed (documented Pass 6 deferral — but now *playtestable*, so the deferral's own stated trigger has fired).

### F12 — Settings exist, persistence doesn't
`AccessibilitySettings` (UI scale, subtitle size, Clarity toggle, Ground hold/toggle) is real tested state that nothing saves, loads, or applies. `SaveSystem` (Pass 2) is sitting right there. Also: the scene ignores `ThemePalette`/`MotionConstants` — it hardcodes its three colors (with comments referencing art_direction §5, but not the constants class built for exactly this). Minor duplication now; drift risk later.

### F13 — Smaller items (grouped)
- **Localization:** zero `tr()` calls anywhere; every string hardcoded. Cheapest to adopt before scene code multiplies (roadmap M6 item; the discipline should start now).
- **ReplayTheater memory:** full-tick snapshot cache is O(ticks × actors); fine for a prologue, unbounded for a 20-minute mission. Note for when missions get long — checkpoint interval + re-sim window is the known fix.
- **`config/icon` is empty** — web export succeeded, but browser tab/PWA iconography is missing; also `html/export_icon=true` with no icon is inert.
- **Test-exit noise:** the Pass 1 `ObjectDB instances leaked` warning still prints; harmless, still unchased (as decided then).
- **`scenes/main.gd` untestable as written:** pure helpers (`_mm_to_px`, wall-layout math) could be extracted to a `RefCounted` class the existing harness can cover; the Node shell stays thin and untested.
- **substance suspicion relief** (`apply_alcohol_drink()`'s returned −1) still has no consumer — expected; it's waiting on the same scene/NPC wiring as F5.
- **Fairness auditor "dependency-dominance" lint** (master_plan §10) still needs a content schema for substance availability before it can exist — tracked in roadmap; noting here for completeness.

---

## 3. Enhancement possibilities (beyond gap-closing)

Ordered roughly by leverage-per-effort:

1. **"Thesis demo" slice — the single highest-value next build.** Wire *one scripted SubtitleDrift + the Ground verb* into the playable scene, rendering through PerceptRenderer (F3), with a dual-view reveal at the end (mini-Theater, even as plain text). Every mechanism already exists and is tested (PrologueStub proves the composition). This turns "a box moves in a box" into *the actual game's pitch, playable in a browser* — the thing you'd show anyone to explain the project in 60 seconds.
2. **One AI in the room.** `spawn_ai()` + a second sprite + the existing engage-and-fire loop gives the web build stakes (get seen → get shot) with near-zero new mechanism. Combine with sprint noise (already simulated!) for a real stealth toy.
3. **Replay download/upload in the web build** (F4): deterministic bug reports from any player, and the foundation for shareable "watch my run" links — master_plan's own marketing beat (§11, shareable honesty reports) starts here.
4. **Deck→Op factory + auditor-on-content CI step** (F1): closes the architecture's biggest broken promise and unblocks the runtime distortion loop in one move.
5. **Corpus re-point** (F9): record 3 bot-driven graybox encounters as the new corpus; nightly determinism guard becomes real.
6. **Touch controls** (F11): a simple virtual joystick makes the itch.io/Pages link playable on phones — biggest audience multiplier for zero sim work.
7. **Camera2D + a second room:** trivial scene work that starts exercising SoundGraph's room/portal propagation (built Pass 4, still unwired to TruthSim's open-air hearing check).
8. **itch.io publishing** as an alternative/additional host (the artifact zip is already itch-shaped; butler CLI in CI is a 10-line job) — gives a stable public URL without the Pages toggle dependency.
9. **Longer-horizon:** WebGPU will eventually let Forward+ back onto the web (Godot tracks this; the `gl_compatibility` decision is revisitable then, recorded as such); PWA/offline mode is one preset flag away once an icon exists; a "streamer mode" flag (roadmap M5) is cheap once the Theater UI exists.

---

## 4. Forward plan (proposed order, no code yet)

**P1 — Trust repairs (small, do first):**
F2 (lint scenes/ in CI) · F7 (workflow branch trigger) · F6 (pass EventBus) · F4 (record ReplayLog) · icon (F13). Each is minutes, each closes a silent-drift hole.

**P2 — The seam flip:** F3 — scene consumes percept snapshots; extend boundary lint to scenes/. Do before any new rendering lands.

**P3 — The thesis demo:** enhancement #1 (+#2 if appetite): Ground verb bound, one scripted drift, dual-view reveal, one AI. Acceptance: a stranger in a browser experiences "the game lied to me and then showed me the truth" in under two minutes.

**P4 — Content really flows:** F1 (OpFactory + auditor CI on mission.json) · F8 (dialogue runtime decision + loader) · F9 (corpus re-point). Acceptance: a mission.json's deck audits in CI, purchases instantiate, a .dlg scene plays in-runtime, corpus hashes TruthSim.

**P5 — Loops close:** F5 (suspicion pipeline integration test) · F10 (HubDayLoop) · F12 (settings persistence + palette adoption) · F11 (input completeness, touch) · localization discipline start (`tr()`).

Everything beyond P5 is the roadmap's existing M5–M7 territory (real art/audio/content/playtesting) and stays there.

---

*Cross-references: `docs/dev_log.md` (this review is logged as a post-arc entry), `docs/roadmap.md` (M-item statuses unchanged by this review — findings here are seams between checked items, which is exactly why a fresh-eyes pass was worth it).*
