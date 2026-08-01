# AFTERIMAGES: VRANOV — Game Documentation

*A psychological action thriller about a mind you cannot trust — including yours.*

This document describes **the game**: what it is, how it plays, what every system does,
and how the pieces fit together. It is the single-file orientation for anyone — human or
agent — who needs to understand the product rather than the codebase.

- For **what has been built and when**, see [`PROGRESS.md`](../PROGRESS.md).
- For **how to work on the repository**, see [`CLAUDE.md`](../CLAUDE.md).
- For the **authoritative, change-controlled specs** this summarizes, see
  `docs/master_plan.md` (systems), `docs/story_bible.md` (narrative canon, spoiler-complete),
  `docs/tech_guidelines.md` (locked technology decisions), `docs/art_direction.md`,
  `docs/ux_charter.md`, `docs/foundation_blueprints.md`.

**This file summarizes. Where it disagrees with the specs above, the specs win.**

---

## 1. The elevator pitch

Top-down 2D action thriller, Godot 4.3, single-player. Vranov, Czech Republic, 2004.

Eleven years after the Meridian bank scandal, an undercover police officer burrows into
the private security firm that got away with it. The deeper her cover goes, the less she
can trust the only witness she has left: **herself**.

**The thesis, in one question: *can you report the truth with a lying mind?***

The engine simulates the **true** world on one layer and renders only what the character
**believes** on another. After every mission, a replay theater shows you both, side by
side, and tells you exactly which of your memories were lies the game told you.

---

## 2. The core conceit — truth vs. percept

This is the architectural spine, and it is non-negotiable (`master_plan.md` §5.2):

```
   ┌─────────────────────────────────────────────────────────────┐
   │  TruthSim  (src/sim/)                                       │
   │  The world as it actually is. Deterministic, 30Hz fixed      │
   │  tick, integer millimetres, seeded PRNG. Never lies.         │
   └───────────────────────┬─────────────────────────────────────┘
                           │ capture_percept_snapshot()
                           │ (plain values only — never object refs)
                           ▼
   ┌─────────────────────────────────────────────────────────────┐
   │  PerceptRenderer  (src/percept/)                            │
   │  Applies a stack of active DistortionOps to the snapshot.    │
   │  This is what the player is shown. It may lie.              │
   └─────────────────────────────────────────────────────────────┘
```

**The boundary is enforced in CI**, not by convention:
`tools/percept_truth_boundary_lint.py` fails the build if anything under `src/percept/`
so much as *names* a `src/sim/` class. Nothing in the percept path can reach back and
mutate truth, because it holds no reference to truth at all — only a copied Dictionary
of plain values.

**Why this matters as design, not just architecture:** because truth is always simulated
faithfully, the game can always *prove* what really happened. The lie is a rendering
decision, and rendering decisions are reversible, replayable, and disclosable.

---

## 3. The five ground rules (binding on all work)

1. **Determinism is law.** The truth simulation replays tick-perfect, always. It is the
   save format, the bug report, and the Afterimage Theater — all three at once.
2. **Fairness is auditable.** The distortion system obeys a hard charter, enforced by
   tooling, and every lie is disclosed after the run.
3. **Missions must be fun sober.** With distortions switched off, a mission must still be
   a good mission, or it is rejected.
4. **Content is data.** No mission logic in engine code. Missions are JSON.
5. **Cruel game, kind product.** All friction is authored; none is accidental.

---

## 4. The player-facing loop

### 4.1 The macro loop (design target)

```
  SAFEHOUSE (hub)  →  DAY PHASE  →  NIGHT PHASE  →  DEBRIEF  →  AFTERIMAGE
     sleep, mind        case it       hit it        report it      see the truth
     dashboard,         as Radek      as Radek                     side by side
     Dr. Sova,          (social       (action/
     loadout            stealth)      stealth)
        ▲                                                              │
        └──────────────────────────────────────────────────────────────┘
              consequences: Doubek trust, resources, plot flags,
              and the psychological tick (stress → fatigue → moral injury)
```

### 4.2 The micro loop (the thing that makes the game *this* game)

```
  play  →  something feels wrong  →  GROUND (hold Space)  →  it resolves
                    │                                              │
                    └── or don't, and carry the belief ────────────┘
                                        │
                                        ▼
                                    DEBRIEF: assert what you saw
                                        │
                                        ▼
                                 AFTERIMAGE: find out
```

---

## 5. The systems

### 5.1 TruthSim — the deterministic world (`src/sim/`)

The authoritative simulation. Everything in it is reproducible from a seed plus a
recorded input stream.

| Piece | File | What it does |
|---|---|---|
| Tick orchestrator | `truth_sim.gd` | One `step(InputFrame)` per tick; owns everything below |
| Actors + registry | `actor.gd`, `actor_registry.gd` | Integer-mm positions, sequential entity IDs (never Godot instance IDs — those aren't reproducible) |
| Collision grid | `collision_grid.gd` | Sparse blocked/free cells; floor-division corrected for negative coords |
| Swept collision | `swept_collision.gd` | Circle-vs-AABB via Minkowski-sum slab method; axis-separated resolution so you slide along walls instead of wedging |
| Line of sight | `line_of_sight.gd` | Bresenham over the same grid that blocks movement — one geometry, not two |
| Sound propagation | `sound_graph.gd` | Room/portal attenuation graph (built, awaiting an authored room layout to consume it) |
| Vision cones | `vision_cone.gd` | Angular FOV via squared dot products — no `atan2`/`sqrt` in sim code |
| Utility AI | `ai_utility.gd`, `ai_agent.gd`, `ai_archetype.gd` | Scores PATROL / INVESTIGATE / ENGAGE / FLEE / REPORT; Sentry and Professional archetypes |
| Witnesses | `witness_system.gd` | "Who *truly* saw what" — the truth-layer fact the debrief and suspicion systems read |
| Combat verbs | `weapon.gd`, `combat_resolver.gd`, `movement_profile.gd`, `focus_state.gd`, `lean.gd` | Ammo/reload as tick counts (never wall-clock), fire/takedown/throw resolution, the Focus resource gate, lean/peek offsets |
| The Ground verb | `ground_state.gd` | Hold to run a reality test; 75 ticks (2.5s at 30Hz) |
| Mind Model | `mind_model.gd` + `acute_stress_state.gd`, `fatigue_state.gd`, `moral_injury_state.gd`, `identity_strain_state.gd` | Four psychological variables, Q16.16 fixed-point |
| Substances | `substance_model.gd` | §4.4.5's honest long-term-cost curves |

**The determinism contract** (`tech_guidelines.md` §3):
30Hz fixed tick · integer millimetres for all world positions (never floats) ·
Q16.16 fixed-point for Mind Model / Director math · sorted iteration everywhere ·
one seeded `Xoshiro128StarStar` stream per system · no engine `delta` in sim code.

### 5.2 The distortion system (`src/percept/`)

**The eleven `DistortionOp` classes** — the full taxonomy from `master_plan.md` §4.2.
Each is a decorator over the percept snapshot with a `tier`, a `cost`, a
`dramatic_intent`, `fairness_tags`, and a `resolve_grounded()` behaviour:

| Op | Tier | What the player experiences | On Ground |
|---|---|---|---|
| `SubtitleDrift` | 1 | A line of dialogue says something it didn't | Reverts to the true line |
| `AudioSwap` | 1 | A real sound is relabelled as a different one | Reverts to the true tag |
| `PhantomAudio` | 1 | A sound with no source at all | Vanishes |
| `HUDGlitch` | 1 | A HUD element reads wrong | Corrects |
| `ObjectSwap` | 2 | A prop is not the prop it appears to be | Reverts |
| `FamiliarFace` | 2 | A stranger wears a face you know | Reverts |
| `EntityMask` | 2 | An entity appears as something else | Reverts (**never masks a damage-capable entity** — Charter rule 2, structurally enforced) |
| `GeometrySwap` | 3 | A doorway/wall is somewhere it isn't | Reverts (**never changes while observed** — rule 4) |
| `PhantomEntity` | 3 | A person who is not there | Shimmers and dissolves over ~1s |
| `TimeGap` | 3 | A jump-cut — you lost time | **Re-applies** rather than reveals: a gap you already lived through |
| `MemoryEdit` | 3 | A journal entry says what you didn't write | Shows **both** the true and edited text |

**The Fairness Charter** (`master_plan.md` §4.5), enforced by `fairness_auditor.gd` and
run against real committed content in CI:

1. Phantoms never deal damage and never block movement or bullets.
2. Never mask a damage-capable entity as harmless.
3. **Player inputs are never distorted.** What you press is what you did.
4. Nothing changes while directly observed.
5. Everything is always disclosable in the Afterimage.
6. Clarity Mode can flag *that* you're being lied to in real time — a fully honourable
   way to play (it never flags *what* the lie is).
7. Hard density cap per encounter.
8. Authorized-vs-purchased ops are never conflated in disclosure.

Charter rules 1, 2 and 4 are **structural**, not merely declared: a phantom literally
cannot affect truth because nothing under `src/sim/` ever reads the percept dictionary.

**The Distortion Director** (`distortion_director.gd`, `master_plan.md` §4.3):
accrues a budget sized by the Mind Model's current state and the mission's authored
variable weights, then spends it on ops drawn from the mission's weighted deck —
respecting affordability, a tier-3+ spacing cooldown (600 ticks), a hard concurrency cap,
and per-op-class weight decay after a Ground resolution. Fully seeded: same seed + same
mind state = same purchase sequence, always.

**Supporting pieces:** `op_factory.gd` (turns authored JSON deck entries into live op
instances), `mission_loader.gd`/`mission_package.gd`/`deck_entry.gd` (content loading),
`clarity_mode.gd` (rule 6's real-time flag), `replay_theater.gd` + `op_timeline_span.gd`
(the Afterimage's dual-pane reconstruction).

### 5.3 The Mind Model (`master_plan.md` §4.4)

Four variables, each with authored gain/decay constants and threshold bands:

- **Acute stress** — fast. Gunfire in earshot, witnessing a kill, near-discovery.
  Relieved by Grounding.
- **Fatigue** — slow. Sleep debt, long missions.
- **Moral injury** — slow and sticky. Context-weighted: a kill in open combat costs +4;
  an unaware victim +6; executing a downed enemy +9; a civilian +15; a knowing lie in
  debrief +3, or +5 if that lie conceals a death. Decays at −0.1/day passively — real
  decay comes only through confession-shaped mechanics (a Dr. Sova session, telling
  Doubek a hard truth).
- **Identity strain** — how much Radek is eating Eliška.

The Director reads all four to size its budget. At high identity strain the *interface
itself* takes sides — the pause-menu character sheet sometimes shows Radek's stats where
Eliška's should be.

### 5.4 The debrief loop (`src/debrief/`, `master_plan.md` §4.10)

**The quiet knife.** At mission end the engine drafts claim candidates from what was
*perceived* — never from truth. A believed phantom produces a claim candidate
**indistinguishable in shape** from a real sighting, because drafting never looks at
truth. That's the point.

```
  run  →  ClaimReducer  →  ClaimDrafter  →  DebriefLedger  →  consequences
          (percept →       (events →        (choose a mode,   (trust, resources,
           events)          Claims)          hidden truth-     plot flags, moral
                                             delta computed)    injury)
```

**Three honesty modes, chosen per claim:**

| Mode | Meaning | Cost / benefit |
|---|---|---|
| **As-seen** | Assert the percept. May be innocently false. | +2 trust if true, −1 if false |
| **Verified-only** | Only claims that were Grounded or evidence-backed. Fewer, but **armored** — can never later be contradicted. | +3 trust, +5 resources |
| **Fabricate** | Knowingly assert what the percept didn't show. | −3 trust, +moral injury, and a discoverable liability flag |

The trust/resource numbers are this codebase's own defined constants
(`debrief_consequences.gd`) — `master_plan.md` pins the *shape* of the math ("an honest
error costs less trust than a fabrication") and §4.13 pins that Doubek's operational
budget scales with verified claims, but neither pins actual numbers. They are tuning
values, not derived truths.

**Consequence channels** (fixed at four by design, to stop the graph ballooning):
Doubek trust · resource budget for the next cycle · plot flags · the psychological tick.

### 5.5 The Afterimage (the replay theater, `master_plan.md` §4.12)

The disclosure screen, and the game's whole trust argument in one UI:

- **Dual-pane replay**: truth view and percept view, synchronized, tick-accurate, driven
  by genuine re-simulation from the recorded `ReplayLog` — not a recording of pixels.
- **Op timeline**: every DistortionOp as an annotated span (class, cause variable,
  resolution: grounded / believed / acted-upon).
- **Honesty report**: claims vs. truth-delta vs. mode chosen — the discrepancy ledger
  made legible.
- **Sharing**: one-click image export of a run's summary. This is the organic-marketing
  engine (§11.4).

### 5.6 Social simulation (`src/social/`)

`NPC` minds, a `SuspicionLedger` per character, a `SuspicionGraph` of who suspects whom,
and `GossipSim` propagating it. `GroundObservationBridge` closes a real loop: Grounding
where an NPC can *see* you is itself a suspicious act, and that observation propagates.

### 5.7 Dialogue (`src/dialogue/`, `tools/dlgc.py`)

A custom `.dlg` DSL compiled by `tools/dlgc.py`, a `DialogueGraph` runtime, a
`DialogueRunner`, and `InterruptMemory` — which does symmetric contradiction detection, so
an NPC remembers what you said and notices when you contradict it.

### 5.8 Hub and UI data layers (`src/hub/`, `src/ui/`)

`HubCalendar` (day/sleep economy), `MindDashboard` (Dr. Sova's worksheets),
`Loadout`. UI is deliberately **data classes, not `.tscn` files** —
`ThemePalette`, `MotionConstants`, `AccessibilitySettings`, `ScreenSpec`,
`MindDashboardScreen`, `DebriefScreen` — because no Godot editor exists in the
development sandbox to verify hand-authored scene files against.

---

## 6. Story and setting

**Setting:** Vranov, Czech Republic, 2004 — post-Soviet melancholia meets Eurodance
leaking through club walls. Sodium light and carbon paper.

**Protagonist:** Eliška Vranná, 34, undercover officer. Cover identity: **"Radek Mráz."**
The game makes you *play as Radek* for long stretches — his walk-cycle swagger, his
dialogue options, his reputation sheet.

**Key characters:**
- **Kapitán Doubek** — her handler. Old-school, protective in a way that is also
  controlling. His trust is the resource tap. Believes the operation is about the
  archive; it's also about his own career.
- **Dr. Sova** — mandated police psychologist. The only character who talks to *Eliška*
  rather than to the operation. Sessions reduce moral injury — but whether everything
  said reaches Doubek is a live question the game seeds both ways and never fully
  resolves until Act 3.

**Structure:** three acts, twelve missions plus a prologue.
- **Act 1** — earn trust, small jobs; the perception system introduces itself gently.
- **Act 2** — the succession war weaponizes Eliška; she discovers the Argus archive
  contains *her own recruitment file*. Someone inside the police feeds Argus. Now the
  leak paranoia and the stress systems resonate: is the surveillance she keeps noticing
  real? (Sometimes yes. Deterministically.)
- **Act 3** — Hora's death detonates the succession; Eliška's final debrief is the
  climax, and decides which faction — and which version of her — survives.

**Endings** are selected by tracked variables, not a menu choice: **Extraction**,
**Inheritance**, **Erasure**, each with internal variants keyed to the discrepancy
ledger, Doubek's trust, and whether the mole was correctly named.

**The onboarding contract** (`master_plan.md` §4.20): the prologue **shows the game's
trick once** — a scripted, safe misheard line, immediately disclosed in a mini-Theater.
The player learns *the game will lie and then prove it lied* within the first thirty
minutes. Trust is established before it is spent.

---

## 7. What is actually playable right now

**Live:** <https://danieldmas.github.io/Afterimage/> (rebuilt on every merge to `main`).

**Locally** (needs Godot 4.3.x):
```bash
godot --headless --path . --editor --quit   # one-time on a fresh clone: builds the class cache
godot --path .                              # or open in the editor and press F5
```

**Controls:** `WASD`/arrows move · `Shift` sprint · **hold `Space` to Ground** ·
`Enter` to replay after the reveal · `E` on the reveal panel to save a shareable PNG.

**What you get:** a single graybox room, simulated by the real `TruthSim`. A real
`MissionRuntime` loads `content/missions/m00_stub/mission.json` and a real
`DistortionDirector` spends a real budget on ops from its real 11-entry deck. The HUD
shows *"reality feels off right now"* whenever something is active (Clarity Mode,
Charter rule 6) with an audible low hum as its twin. Holding Space runs the Ground verb —
a vignette ramps with the genuine hold progress and every active op resolves at once, with
a two-note chime. A teal door bottom-right ends the run; a compass arrow points at it.
Reaching it opens the Afterimage, which discloses every op the Director bought, backed by
a genuine `ReplayTheater` re-simulation of your own recorded session.

**Honest caveats:**
- It is a graybox — colored rectangles, no art, one room.
- Only `SubtitleDrift` and `PhantomEntity` can reach your senses visually here.
  `AudioSwap`/`PhantomAudio` are really purchased but there's no diegetic audio system yet.
  The other seven operate on truth-layer concepts this room doesn't have (HUD elements,
  props, geometry, journal entries).
- **Every one of them is still disclosed by name in the Afterimage anyway.** Charter rule
  5 has no exception for "the demo can't render this one yet."
- There is no combat, no debrief UI, and no hub in the playable slice. The mechanisms for
  all three exist and are tested; they are not yet wired to the surface.

**The thesis is playable. The game is not built.**

---

## 8. Art, audio, and UX direction (summary)

- **Art** (`art_direction.md`): *sodium light and carbon paper*. Pixel art, a tight
  period-accurate palette, distortion VFX with their own visual grammar.
- **Audio** (`master_plan.md` §4.16): audio is half the psychology. Truth-layer sounds are
  dry and diegetic; distortion audio is *almost* identical — the design goal is 95% trust.
  A cold synth-and-cimbalom palette that **thins as stress rises rather than swelling** —
  silence as symptom. Every audio distortion has a visual accessibility twin.
- **UX** (`ux_charter.md`): no shame in playing with the hood open. Clarity Mode is a
  first-class way to play, not an easy mode. Screen-reader text on all paperwork screens.
  Combat difficulty and psychological intensity are **separate sliders**, both changeable
  mid-campaign without penalty or achievement gating.
- **Failure is a fork, never a wall.** Missions end in outcome states — Clean, Loud,
  Burned, Aborted — never game-over. The campaign cannot dead-end; the validator proves
  every mission completable from every reachable world state.

---

## 9. Where to read further

| Question | Document |
|---|---|
| What has been built, when, and how it was verified? | [`PROGRESS.md`](../PROGRESS.md), `docs/dev_log.md` |
| How do I work on this repo? What are the rules? | [`CLAUDE.md`](../CLAUDE.md) |
| What's the next work? | `docs/forward_dev_plan.md` (Phases C–G), `docs/roadmap.md` |
| Full system specs | `docs/master_plan.md` |
| Locked technology decisions | `docs/tech_guidelines.md` |
| Narrative canon (**spoils the entire game**) | `docs/story_bible.md` |
| Foundation-layer specs | `docs/foundation_blueprints.md` |
| Visual bible | `docs/art_direction.md` |
| Player-experience standards | `docs/ux_charter.md` |
