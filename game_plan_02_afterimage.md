# GAME PLAN 02 — "AFTERIMAGE"
### A psychological action thriller about a mind you cannot trust — including yours
**Document type:** Full design + technical architecture plan (pre-production)
**Relationship to Plan 01:** Same shared universe, same engine foundations, deliberately reused tech (§5.7). Plays completely standalone.
**No code in this document — design and architecture only**

---

## 0. Executive Summary

*Afterimage* is a single-player, top-down psychological action thriller. You are an undercover officer embedded in **Argus** — the private security firm from *The Quiet Ledger*, which by **2004** has metastasized into Vranov's dominant organized-crime/private-intelligence hybrid. Days are social infiltration under a cover identity; nights are fast, readable, consequence-heavy tactical action.

The hook — the thing that catches attention — is architectural, not cosmetic:

> **The engine simulates the true world on one layer and renders only what your character *believes* on another.** Stress, sleep deprivation, and moral injury inject deterministic, rule-bound distortions between the two: a hostile who was never there, a line of dialogue you misheard (the subtitle text itself changes), a corridor that isn't where you remember it, thirty seconds you cannot account for. You are given one costly verb to fight back: **reality-testing**. And after every mission, you must tell your handler what happened — while the game silently holds the recording.
>
> When a run ends, you unlock the **Afterimage**: a replay of the ground truth, side by side with what you saw. That comparison — *"wait, THAT'S what actually happened?"* — is the shareable, streamable, word-of-mouth moment the whole design is built around.

This is not "hallucinations as spooky VFX." The distortion system is a fair, learnable, counterable game mechanic with strict rules (§4.4), and the psychological model underneath (acute stress, fatigue, moral injury, identity strain) is a real simulation the player can manage — or mortgage.

Why this game second: Plan 01 builds our deterministic, event-sourced, content-separated foundation and a dialogue/claims stack. *Afterimage* is exactly the game that architecture secretly wants to become — event-sourced ground truth is the *precondition* for honest unreliable perception and for the replay theater. We are not starting over; we are cashing in.

Reference points (flavor, not imitation): *Hotline Miami* (top-down readability, weight of violence), *Metal Gear* (infiltration texture), *Hellblade* (psychological seriousness), *Disco Elysium* (interiority), *Her Story / Obra Dinn* (epistemic play — our house obsession), *Alan Wake / Silent Hill 2* (mind-as-level-design, but we do it systemically, not scripted).

---

## 1. High Concept & Design Pillars

### 1.1 Logline
Eleven years after the Meridian bank scandal, an undercover officer burrows into the security firm that got away with it. The deeper the cover goes, the less the officer can trust the only witness they have left: themselves.

### 1.2 Design Pillars

**P1 — Two worlds, one truth.** Ground truth is simulated completely and deterministically. The player sees a filtered rendering. Every distortion is logged, bounded by fairness rules, and ultimately *disclosable* (the Afterimage replay). The game gaslights you and then, uniquely, lets you prove it. Honesty-after-the-fact is what separates psychological tension from cheap trolling.

**P2 — Action with weight, never friction with cheapness.** Combat is short, brutal, readable, and avoidable more often than players expect. Distortions may create dread, doubt, and terrible decisions — they may never create unfair deaths (hard rules in §4.4). The player's aim is never lied to; only the world is.

**P3 — The mind is a resource system you manage, not a meter that judges you.** Stress, fatigue, moral injury, and identity strain are simulation variables with gameplay-visible consequences and gameplay-usable countermeasures (sleep, grounding, confession, abstinence or use of substances — each with costs). No morality score. Consequences, not judgment. (Direct descendant of Plan 01's P1.)

**P4 — The cover identity is a second character sheet.** "Radek Mráz," the cover, has his own reputation, skills, relationships, and expectations. Feeding the cover starves the self and vice versa. The endgame question is not "will you be discovered?" but "which of you will be left?"

**P5 — Systemic under the hood, authored on the surface** (inherited from Plan 01). Missions, characters, and the conspiracy are authored; perception, stress, gossip/suspicion inside Argus, and debrief consequences run on simulation.

**P6 — Buildable by us.** Top-down 2D with modern lighting, small handcrafted levels, systemic depth over asset volume. Every expensive-sounding feature above is cheap *because* of the event-sourced core.

### 1.3 Audience & Rating
Adults. Themes: dissociation, paranoia, moral injury, insomnia, substance use, violence with consequences, undercover ethics. Violence is depicted top-down and stylized but treated as serious; no torture interactivity, no glamorized substance mechanics (using stabilizes short-term and damages long-term — modeled honestly, §4.3). PEGI 18 / ESRB M. Explicit content-warning screen with granular toggles (§4.8). We will commission a sensitivity read on the psychological depiction: the character is *a person under extreme strain*, not a walking diagnosis; we deliberately avoid naming real disorders in-fiction.

### 1.4 Platform & Scope Targets
- **Desktop first** (Windows/Linux/macOS), controller + M/K parity from day one (twin-stick friendly).
- **Vertical slice:** prologue + 3 missions + safehouse hub, ~2.5 hours, the full perception stack working. Estimated 6–8 months part-time, *assuming Plan 01's M0–M1 foundations exist*.
- **Full game:** 12 missions + hub life, 8–12 hours, 3 ending families with internal variation.

---

## 2. Setting, Tone, and Narrative Design

### 2.1 The World, Eleven Years Later
Vranov, 2004. EU accession is months away; everyone respectable is laundering their history. **Argus**, once a thuggish blackmail shop (players of *The Quiet Ledger* met them; new players need nothing), is now three businesses in a trenchcoat: legitimate corporate security, an illegal private-intelligence archive built on stolen StB files and two decades of wiretaps, and a quiet enforcement arm. Its founder, **Zdeněk Hora**, is dying and hasn't told anyone; his two lieutenants are already fighting over the inheritance. Into this succession war the police insert one officer.

Continuity is reward, not homework: a handful of documents, one returning minor character, and — for players who filed certain reports in Game 1 — a few lines acknowledging which "history" of the Meridian affair became official. (Technically trivial: an optional import flag; default canon otherwise.)

### 2.2 The Player Character(s)
**Eliška Vranná**, 34, undercover officer. Cover: **"Radek Mráz"** — the game makes you *play as Radek* for long stretches: his walk-cycle swagger, his dialogue options, his reputation sheet. The interface itself takes sides: at high identity strain, the pause-menu character sheet sometimes shows Radek's stats where Eliška's should be — one of the strictly-bounded UI distortions (§4.4). Eliška's handler, **Kapitán Doubek**, and a mandated police psychologist, **Dr. Sova**, anchor the debrief loop. Whether Dr. Sova's sessions are a safe space or feed Doubek's file on her is a live question the player probes.

### 2.3 Story Shape (spoiler-level, for our internal use)
Three acts across 12 missions. Act 1: earn trust, small jobs, the perception system introduces itself gently (a misheard sentence, a car that wasn't there). Act 2: the succession war weaponizes Eliška; she discovers Argus's archive contains *her own* recruitment file — someone inside the police feeds Argus. Stress systems and the leak paranoia now resonate: is the surveillance she keeps noticing real? (Sometimes yes. Deterministically.) Act 3: Hora's death detonates the succession; Eliška's report — her final debrief, the game's climax — decides which faction, and which version of *her*, survives. The endgame is a direct heir of Plan 01's report mechanic: **what you claim happened is a weapon**, and by now the player knows their own testimony is partly corrupt. Three ending families: *Extraction* (leave with the truth, whatever it's worth), *Inheritance* (Radek wins), *Erasure* (burn the archive — including what's true in it).

### 2.4 Tone Rules
- Distortions are written with restraint; the scariest ones are mundane (a repeated breakfast scene; a colleague greeting you about a conversation you don't remember having).
- Argus people are professionals, funny, and frighteningly reasonable. The horror is that undercover work *works* by liking them.
- No jump-scare economy. Dread over startle, always.

---

## 3. Core Gameplay Loops

### 3.1 Macro Loop (one operation cycle, ~30–45 min)
1. **Safehouse (hub):** sleep (or fail to), manage the mind (§4.3), study the Argus org board (suspicion/relationship map), talk to Doubek, optional session with Dr. Sova, choose loadout *and* cover-consistent equipment (Radek carrying police-issue anything is a suspicion event).
2. **Day phase — Infiltration:** social stealth inside Argus offices/venues. Dialogue under cover (reusing and extending Plan 01's dialogue DSL, stances, and claim-listeners), light objectives: plant, photograph, eavesdrop, maintain alibis. Suspicion, not health, is the resource.
3. **Night phase — Operation:** the action core. Top-down real-time tactical action in handcrafted levels: Argus jobs (which Eliška must perform *well enough* to keep cover — the game's nastiest lever) or police counter-ops. 8–15 minutes, high intensity.
4. **Debrief:** report to Doubek. The debrief screen is built from **claims** (Plan 01 tech, reused verbatim as a concept): the player asserts what happened. The engine compares against ground truth silently. Consequences propagate (trust, resources, plot). Then the psychological tick: stress converts to fatigue, moral injury settles in, distortion budget for the next cycle is computed.

### 3.2 Micro Loop (combat/action)
Deliberate twin-stick tactical action, closer to a violent immersive sim than a bullet-hell: lean/peek, sound as a first-class system (noise rings visible when focused), lethal vs. nonlethal branches on every tool, short time-dilated **Focus** (a stress *loan* — slows time now, raises acute stress after), environmental play (lights, locks, phones). Enemy count is low (3–9 per encounter); lethality is high both ways; checkpoints are generous. Deaths restart encounters, not missions — the punishment lives in the psyche model and the story, not in lost time.

### 3.3 The Reality-Testing Loop (signature verb)
At any moment the player can **Ground** (hold a button: Eliška's breathing exercise, taught diegetically by Dr. Sova in the prologue). Grounding for ~2.5 seconds runs a reality test on what's in view: phantoms shimmer and dissolve; misremembered geometry snaps true; false subtitles visibly correct themselves. Costs: it is loud silence — in combat you are stationary and vulnerable; in social scenes, visibly "off" (suspicion tick if observed); and each Ground raises *fatigue* slightly (you can white-knuckle a night, and you will pay tomorrow). Skilled play is not grounding constantly; it is developing *judgment about when your judgment is bad* — the game's thesis as a mechanic.

### 3.4 The Debrief Loop (signature consequence)
Debrief claims come in three honesty modes the player chooses per claim: report what you saw (may be innocently false), report what you *verified* (only grounded/ evidence-backed claims — fewer, but armored), or knowingly lie (protect Radek's actions, hide a kill, cover a blackout). Doubek's trust, resource flow, and late-game plot branches ride on the discrepancy ledger — which the player can finally read, mission by mission, in the post-game Afterimage theater.

---

## 4. Systems Design (Detailed)

### 4.1 The Two-Layer World
- **Truth layer:** full deterministic simulation at a fixed tick — every entity, sound, line of dialogue, and shot, event-sourced (append-only log). This is the only layer that decides outcomes: damage, deaths, alarms, witnesses, evidence.
- **Percept layer:** what is rendered. Computed each frame as *truth + active DistortionOps*. Distortions are data (typed operations), never hand-hacked into levels: `PhantomEntity`, `EntityMask` (real thing not shown — used with extreme care, §4.4), `AudioSwap`, `SubtitleDrift`, `GeometrySwap` (between visits only, never mid-sight), `TimeGap` (controlled jump-cut in safe zones), `HUDGlitch` (bounded set), `MemoryEdit` (journal/board text differs from what player actually saw — the cruelest one, always disclosable later).
- Every DistortionOp is logged with cause (which stress variable purchased it), duration, and resolution (grounded? believed? acted upon?). This log powers fairness auditing (§10) and the Afterimage theater.

### 4.2 The Distortion Director
An AI-director-style budgeter. Inputs: the four mind variables (§4.3), scene type, recent distortion history, and authored mission caps. It buys DistortionOps from a weighted deck authored per mission/act (so early game misheards, late game full phantoms), subject to global fairness rules (§4.4). Deterministic given seed + state — the same run replays identically, which is both our debugging superpower and the honesty guarantee behind the Afterimage.

### 4.3 The Mind Model (four variables, all diegetic)
- **Acute stress** (fast): spikes in combat, on kills witnessed, on near-discovery; buys short-lived distortions; decays with safety, Grounding, hub rest.
- **Fatigue** (daily): sleep debt; raises Ground cost and unlocks `TimeGap`/`MemoryEdit` classes; the only cure is actually sleeping, which consumes calendar and can conflict with mission windows.
- **Moral injury** (slow, sticky): grows from what Eliška *does* — kills (weighted by context: unaware victims, nonlethal-then-executed, civilians vastly more), betrayals of Argus people she has genuinely befriended, lies in debrief she knows are lies. Decays only through the confession-shaped mechanics (Dr. Sova sessions, telling Doubek hard truths) — each of which has its own risks. Moral injury biases *which* distortions the director buys: it purchases the personal ones (the repeated victim, the misremembered order of events at a shooting).
- **Identity strain**: rises with time-in-cover, with skill checks passed *as Radek*, with using Radek's methods; the source of UI-identity distortions and, at thresholds, of dialogue where Radek options are pre-selected and Eliška options need an input *hold* to choose. Never removes agency; makes the self cost effort. This is the pillar-P4 endgame currency.
- **Substances & tools:** authored, honest tradeoffs (e.g., stimulants: erase fatigue effects tonight, +fatigue floor and +acute-stress gain for days; alcohol at Argus socials: −suspicion, +strain). No mechanic ever makes sustained use optimal; the model quietly punishes dependency curves. This is a design commitment, not a tuning accident.

### 4.4 Fairness Charter (hard rules — the mechanic lives or dies here)
1. Phantoms never deal damage and never block movement or bullets. The danger of a phantom is *what you do about it*: shooting one fires real bullets into the real world (noise, witnesses, or — the nightmare the game is honest about — a real person you misidentified; missions are authored so this is possible but never forced).
2. `EntityMask` (hiding something real) is never applied to entities that can damage the player while masked; it is used for witnesses, evidence, and dread (the body that "wasn't there"), not for cheap ambushes.
3. Player inputs, aim, and hit registration are never distorted. The hands are true; only the eyes and memory lie.
4. Geometry never changes while observed; no distortion may contradict information the player is currently, actively verifying.
5. Everything is disclosable: every op appears in the post-run Afterimage. No secret permanent gaslighting.
6. **Clarity Mode** (accessibility, §4.8) can flag distortions in real time with a subtle vignette — the psychological pressure drops, the story stays intact. Fully honorable way to play; no content gated behind suffering.
7. Distortion density is capped per encounter and cooled after deaths — dying twice to a situation demonstrably reduces director budget there.

### 4.5 Suspicion, Cover, and the Argus Social Graph
Argus NPCs run the Plan 01 mind-model (KNOWS/HIDES/LIES + personality + gossip edges), extended with a **suspicion ledger**: observations that don't fit Radek (seen Grounding, police-pattern behavior, inconsistencies between what Radek said in two conversations — the interrupt-memory system from Plan 01 pointed at the *player* this time). Suspicion propagates along gossip edges with delay/distortion; countermeasures exist (alibis, scapegoats, doing ugly jobs *convincingly*). Blown cover is not instant game over: it forks missions into a harder, tragic branch-family — and one ending family requires it.

### 4.6 Missions & Level Design
Handcrafted compact levels (a nightclub back-house, a server archive, a river warehouse, a police evidence depot) designed twice: once as truth, once annotated with distortion affordances (mirror surfaces, PA speakers, sightline pockets where phantoms are plausible). Day/night variants of several spaces (you case it as Radek by day, hit it by night — your own daytime memory becomes the minimap, and fatigue corrupts *the memory*, not the space). 3 missions in the slice, 12 in the full game, plus the hub.

### 4.7 Difficulty
Combat difficulty and psychological intensity are **separate sliders**. A player can want brutal gunfights with mild distortion, or trivial combat inside a deeply unreliable world. Defaults tuned in playtest; both sliders diegetically framed.

### 4.8 Content & Accessibility Safeguards
Granular toggles: photosensitivity-safe (no flicker-class ops — the deck simply substitutes), subtitle-drift off (audio-only distortions get visual alternatives), self-harm-adjacent imagery off (none is interactive regardless), Clarity Mode (§4.4.6). Colorblind-safe noise/suspicion indicators; full remapping; hold-to-toggle alternatives for Ground.

---

## 5. Technical Architecture

### 5.1 Engine
**Godot 4.x**, same as Plan 01 — now with a real rationale upgrade: its 2D lighting/normal-map pipeline and shader stack cover 100% of our visual needs, and our shared foundations (below) already target it. Hot paths (truth-sim tick, director) in C# or GDExtension if profiling demands; we do not assume it will.

### 5.2 Top-Level Architecture

```
+------------------------------------------------------------------+
|                         PRESENTATION                             |
|  PerceptRenderer (truth ⊕ DistortionOps) · HUD (distortable,     |
|  bounded) · Dialogue UI · Hub screens · Debrief UI ·             |
|  Afterimage Theater (dual-view replay)                           |
+-------------------------------△----------------------------------+
                                │ percept state (read-only views)
+-------------------------------▽----------------------------------+
|                        APPLICATION CORE                          |
|  TruthSim (fixed-tick, deterministic, event-sourced)             |
|   ├─ ActorSystem (player+AI bodies, physics-lite)                |
|   ├─ AISystem (utility-based enemy/civilian brains)              |
|   ├─ SoundPropagation (truth-layer, feeds AI and percept)        |
|   └─ WitnessSystem (who truly saw what — feeds suspicion+story)  |
|  MindModel (4 variables + substance modifiers)                   |
|  DistortionDirector (budgets, buys, retires DistortionOps)       |
|  SuspicionGraph + GossipSim (Plan 01 system, extended)           |
|  DialogueRunner + Claims/DebriefLedger (Plan 01, reused)         |
|  Predicate evaluator (Plan 01, verbatim)                         |
|  EventBus · GameStateStore · SaveSystem · ReplayStore            |
+-------------------------------△----------------------------------+
                                │ loads, validates
+-------------------------------▽----------------------------------+
|                         CONTENT LAYER                            |
|  Mission packages: levels (truth + distortion-affordance layer)  |
|  · distortion decks · NPC minds · dialogue DSL · debrief specs   |
|  · ending tables · localization                                  |
+------------------------------------------------------------------+
```

Non-negotiable invariant, enforced by architecture: **PerceptRenderer has read-only access to TruthSim; DistortionOps live in a separate stream; nothing in the percept path can mutate truth.** All gameplay consequences are computed from truth events only. This single boundary is what makes P1 real instead of aspirational.

### 5.3 Determinism & Replay (the load-bearing wall)
- Fixed-tick truth simulation (target 30 Hz sim under 60+ Hz render, interpolated), integer/fixed-point where float drift threatens determinism, single seeded RNG stream per system.
- The event log (inputs + seeds + authored triggers) *is* the save file for mission-in-progress and *is* the Afterimage source. Replays are re-simulations, not video — tiny on disk, perfectly accurate, and they double as bug reports (a crash + its log = reproducible case, inherited practice from Plan 01).
- The Afterimage Theater renders the same replay twice — truth view and percept view — synchronized, with a scrubber and op-annotations. Built almost for free from the above; marketed as a headline feature.

### 5.4 Data Model (core additions over Plan 01)
- `DistortionOp {id, class, params, cause:{variable, threshold}, window:{start,end|condition}, fairnessTags[], resolution?}`
- `MindState {acuteStress, fatigue, moralInjury, identityStrain, modifiers[]}`
- `DebriefClaim {id, assertion, honestyMode, truthDelta (engine-computed, hidden), consequencesApplied[]}`
- `SuspicionEntry {npcId, observation, weight, decay, sharedWith[]}`
- `MissionPackage {truthLevel, affordanceLayer, deck, npcRoster, debriefSpec, endingHooks}`
- Reused verbatim from Plan 01: `Claim`, `Predicate`, `NPC` mind schema, `DialogueGraph`, save versioning discipline.

### 5.5 Enemy & Civilian AI
Utility-scored behaviors over small state (patrol/investigate/engage/flee/report) with truth-layer senses (vision cones, sound propagation, memory of last-known). Design bar: legible over clever — the player must be able to model AI perfectly, because the game's uncertainty budget is spent *entirely* on the player's own perception. Two uncertain systems stacked would be noise, not dread.

### 5.6 Performance Notes
Top-down 2D with lighting: comfortably within budget. Watchpoints: percept-layer double bookkeeping (design ops as render-side decorators, not entity clones), replay re-sim speed for theater scrubbing (checkpoint snapshots every N seconds of log), audio voice count during distortion-heavy scenes.

### 5.7 Reuse Ledger (what Plan 01 pays forward)
Reused as-is: EventBus, GameStateStore, Predicate language + evaluator + tests, save versioning, dialogue DSL/compiler/runner, claims/provenance concept, NPC mind schema, gossip propagation, Case Validator skeleton, headless playthrough simulator. Extended: gossip → suspicion; claims → debrief modes; validator → fairness auditor (§10). New: TruthSim/percept split, DistortionDirector, MindModel, combat AI, replay theater. Roughly **40% of Afterimage's core exists the day Plan 01's M3 is done** — this is the series strategy working as intended.

---

## 6. Content Production Plan

### 6.1 Asset Budget (vertical slice)
| Asset | Count | Notes |
|---|---|---|
| Character sprites | ~14 actors × animation sets | top-down, readable silhouettes; normal-mapped for lighting |
| Levels | 3 missions + hub (≈6 spaces) | handcrafted tilesets ×3 environments |
| Portraits | 10 × 3–4 expressions | style continuity with Plan 01 |
| Distortion VFX/shader set | ~15 ops' worth | the art-direction crown jewels; budgeted early |
| Music | 7 tracks + adaptive stems | see §8 |
| SFX/ambience | ~120 | doubled inventory: many need a "true" and a "distorted" variant |
| Words | ~60–80k (slice) | dialogue + debriefs + journals (which can lie) |

### 6.2 Authoring Pipeline
Ground-truth mission doc first (timeline, every NPC's real knowledge — Plan 01 discipline), then level graybox → truth playtest *with distortions off* (the mission must be good sober) → affordance annotation → deck authoring → distortion playtests. Rule: **a mission that isn't fun with zero distortions is rejected**, because distortions multiply quality, they don't create it.

---

## 7. UX / UI Design
- Diegetic-leaning HUD: minimal; noise rings, suspicion pips over heads (day phase), Focus/Ground shown as breath UI. The HUD is on the *percept* side and thus distortable — within the bounded `HUDGlitch` set only (never health/ammo lies; typically: map annotations, objective text phrasing, clock).
- Hub screens: org/suspicion board (corkboard language inherited from Plan 01 — returning players will feel the rhyme), mind dashboard framed as Dr. Sova's worksheets, debrief as a form (our house aesthetic: paperwork as dramaturgy).
- Afterimage Theater: split view, op timeline, per-mission "honesty report" comparing debrief claims to truth. Shareable image export of a run's discrepancy summary (organic marketing).

## 8. Audio Direction
Audio is half the psychology. Truth-layer sounds are dry and diegetic; distortion audio is *almost* identical — the design goal is 95% trust. Adaptive score: a cold synth-and-cimbalom palette (2004 Vranov: post-Soviet melancholia meets Eurodance leaking through club walls) that thins as stress rises rather than swelling — silence as symptom, a Plan 01 principle pushed further. Binaural detail work for headphone players; every audio distortion has a visual accessibility twin.

## 9. Production Plan & Milestones
Assumes Plan 01 foundations (its M0–M3) are built; calendar in part-time weeks.

**M0 — Truth Skeleton (w1–4):** fixed-tick TruthSim + event log + re-sim replay; one graybox room; combat feel prototype (move/aim/shoot/noise/AI investigate). *Exit: a fight can be recorded and replayed tick-perfect.*
**M1 — The Split (w5–9):** PerceptRenderer boundary; first 4 DistortionOp classes; Ground verb; Clarity Mode stub. *Exit: a phantom fools a playtester once, and the replay proves it.*
**M2 — The Mind (w10–14):** MindModel + DistortionDirector + fairness rule enforcement + fatigue/sleep hub loop. *Exit: two testers with different playstyles get measurably different distortion profiles from the same mission.*
**M3 — The Cover (w15–19):** dialogue/suspicion integration (Plan 01 stack drop-in), day-phase social stealth, debrief v1 with honesty modes. *Exit: a full day/night/debrief cycle plays end-to-end.*
**M4 — Mission One for Real (w20–25):** full-quality mission (art, audio, deck), Afterimage Theater v1. *Exit: the theater moment lands in playtests ("that's what happened?!").*
**M5 — Slice Complete (w26–34):** prologue + missions 2–3, hub cast, ending-hooks stubbed, difficulty/psych sliders, accessibility pass.
**M6 — Polish & Slice Release (w35–40):** tuning from external playtests, sensitivity review implemented, trailer built around one real, unstaged Afterimage comparison.

## 10. Testing & Quality Strategy
- Determinism CI: nightly re-simulation of a library of recorded runs; any divergence fails the build. (Non-negotiable — every headline feature depends on it.)
- **Fairness auditor:** extends Plan 01's validator — statically checks decks and levels against the Fairness Charter (e.g., no `EntityMask` on damage-capable actors; density caps; every op class has a Clarity/accessibility substitution).
- Headless bots: soak combat for crashes; "paranoid bot" grounds constantly and "credulous bot" never does — both must be able to finish every mission (proves distortions are never mandatory-lethal knowledge).
- Human playtests instrumented via the event log: we can literally watch where players believed a phantom, and tune the deck with data.
- Psychological-content review pass with an external consultant before slice release.

## 11. Risks & Mitigations
| Risk | Severity | Mitigation |
|---|---|---|
| Distortions read as cheap or gimmicky | High | Fairness Charter as law; missions must work sober (§6.2); disclosure via Theater converts trickery into trust |
| Determinism breaks under engine updates/float drift | High | fixed-point in sim core, determinism CI from M0, engine version pinning per milestone |
| Combat feel mediocre (we're systems people, not action veterans) | High | M0 dedicates a full milestone to feel before any psychology; external playtesters early; scope combat depth down before cutting readability |
| Psychological themes handled exploitatively | High | sensitivity consultant, granular toggles, no diagnosis-naming, moral injury modeled with respect (confession mechanics, not "insanity meter") |
| Two-layer rendering doubles content cost | Medium | ops as decorators/shaders, not duplicated assets; distorted-variant budget capped in §6.1 |
| Series coupling: Plan 01 slips → this slips | Medium | M0–M1 here depend only on Plan 01's M0 (state store/bus/predicates), which is weeks, not months; combat prototype can start against stubs |
| Player confusion between the two phases' rulesets | Low | strict visual grammar per phase; tutorialized prologue splits them before mixing |

## 12. What We Build First (immediate next steps)
1. Ratify the Fairness Charter (§4.4) — it constrains everything downstream, so we argue about it *now*.
2. I draft the DistortionOp taxonomy + MindModel math (curves, decay constants) as a spec for your review.
3. Combat-feel prototype plan: one room, one enemy archetype, tuning checklist.
4. Decide the Plan 01 import question (does Game 1's report canonically exist in this timeline, and does a save import change lines) — cheap either way, but it affects the story bible.

---

*End of Plan 02. The two plans now form a deliberate arc: Game 1 asks whether you can find the truth in a lying world; Game 2 asks whether you can report the truth with a lying mind. Plan 03, when we get there, should probably ask what happens when the truth is known by everyone and matters to no one — but that's a fight for another document.*
