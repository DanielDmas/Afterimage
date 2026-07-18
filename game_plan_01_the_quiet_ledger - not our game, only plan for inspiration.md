# GAME PLAN 01 — "THE QUIET LEDGER"
### A systemic deduction noir for adults
**Document type:** Full design + technical architecture plan (pre-production)
**Target:** A game we can realistically build together, incrementally, in a chat-based workflow
**No code in this document — design and architecture only**

---

## 0. Executive Summary

*The Quiet Ledger* is a single-player, text-and-2D detective game in which the player investigates the collapse of a mid-sized private bank in a fictional Central European city in 1993 — the messy, morally gray privatization era. There is no combat. The core verb is **inference**: the player gathers evidence, interrogates people whose memories and motives conflict, and assembles claims into a formal **deduction board**. The game never tells the player whether they are right; it only reacts to what they *assert*, and the story branches on assertions, not on truth. Multiple internally consistent "solutions" exist; only one matches the underlying simulated ground truth, and the game is honest enough that a careful player can find it.

Why this game first:

1. **It is buildable by two collaborators in text.** The heavy lifting is data modeling, systems design, and writing — all things that work well in an iterative chat workflow. Art requirements are deliberately minimal (portraits, documents, a city map).
2. **It is genuinely adult** — not in the sense of gore or sex, but in theme: complicity, institutional rot, the difference between legal and moral guilt, and the unreliability of testimony. The player is asked to *think*, and the game respects them enough not to grade their homework.
3. **It scales.** We can ship a one-case vertical slice, then grow to a full campaign, because the architecture below separates *engine* from *case content* from day one.

Reference points (for flavor, not imitation): *Return of the Obra Dinn* (assertion-based deduction), *Disco Elysium* (adult tone, dialogue depth), *Her Story* (player-driven epistemology), *Papers, Please* (bureaucratic texture as gameplay).

---

## 1. High Concept & Design Pillars

### 1.1 Logline
A forensic auditor arrives in the city of Vranov to unwind the collapse of Banka Meridian. Everyone lies a little. The books lie more. You will file one report, name names, and live with it.

### 1.2 Design Pillars (every feature must serve at least one)

**P1 — The game never grades your reasoning, only your assertions.**
There is no "wrong answer" popup. The player writes a final report; the epilogue simulates its consequences. Truth is discoverable but never confirmed mid-game. This is the single most important pillar and the source of the game's adult character.

**P2 — Evidence is physical, testimonies are human.**
Documents are consistent, dated, cross-referenceable artifacts. People are not: NPCs have knowledge models, motives to lie, and imperfect memory. The tension between paper and people is the whole game.

**P3 — Time is a resource, not a timer.**
The investigation spans a fixed number of in-game days. Every interrogation, stakeout, or archive dive costs time slots. The player cannot do everything in one playthrough — prioritization *is* the difficulty curve. No real-time pressure, ever.

**P4 — Systemic under the hood, authored on the surface.**
The case is hand-written, but NPC knowledge, gossip propagation, and reactions to player assertions run on simulation. Authored quality, systemic reactivity.

**P5 — Minimal art, maximal atmosphere.**
Static illustrated scenes, character portraits with a small set of expressions, scanned-looking documents, a stylized city map. Sound and writing carry the mood. This keeps the project shippable by a tiny team.

### 1.3 Audience & Rating
Adults 25+, players of narrative and deduction games, readers of le Carré and Havel-era reportage. Content: strong language, alcohol, references to suicide and coercion, sexual references (non-explicit), systemic corruption. Roughly PEGI 16 / ESRB M for themes. No graphic violence on screen.

### 1.4 Platform & Scope Targets
- **Primary:** Desktop (Windows/Linux/macOS).
- **Vertical slice:** 1 case, ~3–4 hours, 12 NPCs, ~90 documents, 1 district map. Estimated 4–6 months of part-time collaborative work.
- **Full game:** 3 interconnected cases, ~15–20 hours, shared cast, cumulative reputation.

---

## 2. Setting, Tone, and Narrative Design

### 2.1 The World
Vranov, 1993. A fictional post-communist city of ~200,000. Privatization vouchers, sudden fortunes, old secret-police files that half the town wants burned and the other half wants weaponized. Western consultants who understand nothing, local operators who understand everything. The city has four playable districts in the slice: **Old Town** (the bank, ministries, café society), **Zálesí** (industrial, the failing engineering works the bank financed), **Riverside** (new money, night clubs, the private security firm), and **The Archive Quarter** (courts, land registry, newspaper morgue).

### 2.2 The Case (Vertical Slice): "Meridian"
Ground truth, spoiler-level summary for our internal design use:

- Banka Meridian collapsed after issuing enormous unsecured loans to **Zálesí Strojírny**, an engineering works being asset-stripped by its own management in concert with the bank's deputy director, **Pavel Rys**.
- The nominal villain the public expects — bank director **Antonín Karas** — is guilty of negligence and vanity but not the fraud; he signed what Rys put in front of him.
- The whistle came from a junior accountant, **Ivana Šebestová**, who died three weeks before the game begins. Official ruling: suicide. Ground truth: it *was* suicide — but induced by targeted blackmail from the security firm **Argus** hired by Rys, using her StB-era family file. This is deliberately not a murder; the game refuses the comforting genre convention. The moral crime is real, the legal crime is nearly unprosecutable, and the player must decide what their report can honestly claim.
- A parallel red herring: a genuinely violent loan-shark subplot in Riverside that *looks* connected and can consume the player's limited days if they chase it. It has its own small, satisfying resolution, so the time isn't "wasted," but it will not crack Meridian.

Three broad "consistent solutions" exist: (A) the tabloid solution (Karas did it all), (B) the cynical solution (systemic failure, no individual culpability provable), (C) the true solution (Rys + Argus + management of the Strojírny, with Karas as negligent enabler). The final report system (§4.6) lets the player assert any of them — or partial mixtures — and the epilogue honestly simulates outcomes, including the ugly one where naming the truth achieves less than the tabloid lie would have.

### 2.3 The Player Character
**Marta Holanová**, 41, forensic auditor contracted by the National Property Fund. Defined enough to have a voice (dry, exact, tired), open enough for player expression through dialogue stance choices (see §4.4). She has one personal hook the player can engage or ignore: her own father's name appears in a peripheral StB file the investigation touches. Engaging it costs time and opens one extra ending flavor; ignoring it is fully valid. No romance mechanics; adult does not mean dating sim.

### 2.4 Tone Rules for All Writing
- Nobody monologues their guilt. Confessions are partial, self-serving, and rare.
- Bureaucratic texture is loving, not parodic — forms, stamps, ledger conventions are rendered accurately enough that learning to read them is a player skill.
- Humor exists (gallows, deadpan) but never winks at the camera.
- Every NPC believes their own story. The writing brief for each character includes "the version of events in which they are the reasonable one."

---

## 3. Core Gameplay Loops

### 3.1 Macro Loop (one in-game day)
1. **Plan** — morning at the hotel: review the deduction board, choose how to spend the day's 3 time slots (4 on some days; events can steal slots).
2. **Act** — visit locations; each visit runs one or more scenes: interrogation, document search, observation, or event.
3. **Digest** — evening: new evidence auto-files into the case archive; the player optionally works the deduction board; the gossip simulation ticks (NPCs talk to each other about what the player did today).
4. **Consequence** — some assertions and actions trigger next-day events: a lawyer shows up, a source dries up, a document gets shredded.

The slice covers **10 in-game days** plus a final report day. That is 30–34 slots against ~55 slot-worth of available content — the scarcity is tuned so a first playthrough sees roughly 60% of the material.

### 3.2 Micro Loop (a scene)
Enter scene → read/observe → choose interactions (dialogue nodes, examine hotspots, request documents) → collect **claims** (atomic facts, see §4.1) → exit. Scenes are short (3–8 minutes) and always yield *something*, even if it's only a contradiction.

### 3.3 The Deduction Loop (the real game)
Claims accumulate. The player links them on the board into **hypotheses** ("Rys authorized loan #114 knowing collateral was fictitious"). Hypotheses can be **asserted** in the world — put to an NPC's face, cited to a magistrate, leaked to a journalist. Assertion is the risk mechanic: it can unlock confessions and warrants, or burn sources and trigger cover-ups. The loop: *gather → connect → assert → world reacts → gather*.

### 3.4 Failure and Friction
No fail states before the report. Friction comes from: time scarcity, sources closing, documents being destroyed reactively, NPC trust dropping, and the player's own wrong hypotheses sending them down coherent-but-false paths. The game is lost only in the epilogue's mirror.

---

## 4. Systems Design (Detailed)

### 4.1 Claims — the atomic unit of knowledge
Everything the player "knows" is a **claim**: a structured triple-plus — *(subject, predicate, object, qualifiers)* — e.g., `(Rys, signed, LoanDoc#114, {date: 1992-11-03, source: document_scan_114})`. Design rules:

- Every claim has a **provenance chain**: which document, which testimony, which observation. Provenance is first-class UI — the player can always ask "why do I believe this?"
- Claims can **conflict**. Conflicts are auto-detected on simple axes (same subject+predicate, incompatible objects; timeline impossibilities) and surfaced as board notifications. Semantic conflicts are hand-authored as conflict pairs in case data.
- Claims have **confidence** only in the player's head. The system never scores truth. (Pillar P1.)
- Authoring target for the slice: **~350 claims**, of which ~120 are "load-bearing" for at least one solution path.

### 4.2 Evidence & Documents
Documents are images + structured metadata + extractable claims. Types: ledgers, loan contracts, land registry extracts, StB file fragments, newspaper clippings, letters, phone logs, autopsy report. Design specifics:

- **Cross-referencing is a skill.** A ledger line means nothing until the player has the chart-of-accounts document; a signature means nothing until they've seen a verified specimen. We teach this gently in Day 1–2 via a tutorialized mini-case (a petty expense fraud inside the audit team's own paperwork).
- Some documents exist in **multiple versions** (the original and the doctored copy). Detecting doctoring requires having both, or having a claim that contradicts the copy.
- Documents can be **destroyed by the simulation** if the player's assertions warn the conspirators. The archive keeps a "you saw this once" ghost entry with degraded, memory-level claims — a hard but fair punishment.

### 4.3 NPC Knowledge & Lie Model
Each NPC record contains:
- **KNOWS**: set of claims they truly hold (subset of ground truth + false beliefs they genuinely hold).
- **HIDES**: claims they will not volunteer, each with an unlock condition (trust threshold, leverage item, correct assertion presented to them, or a world-state trigger).
- **LIES**: authored false claims they will assert, each with a **tell condition** — the specific evidence combination that lets the player catch the lie in-scene, which changes the NPC's state (rattled/hostile/cooperative depending on their profile).
- **PERSONALITY VECTOR** (small, authored, not ML): pride, fear, greed, loyalty targets. Drives which leverage works and how they respond to being caught.
- **GOSSIP EDGES**: who they talk to, with what delay and distortion. When the player asserts hypothesis H to NPC X, the propagation system decides which conspirators learn of it by which day — this is what makes the world feel alive and dangerous without any scripting per-playthrough.

Slice cast: **12 interactive NPCs** (each ~2,500–4,000 words of dialogue) + ~10 non-interactive flavor characters.

### 4.4 Dialogue System
Node-graph dialogue with these extensions beyond the standard:
- **Stance modifiers**: many player lines come in up to three stances — *procedural* (by the book), *empathetic*, *pressing*. Stance history shifts NPC trust and Marta's characterization; it is our replacement for a morality meter.
- **Evidence presentation**: any scene can open the case archive to present a document or assert a hypothesis; the dialogue graph declares which claim-patterns it listens for, so authored responses exist for the load-bearing assertions and a graceful generic layer ("Holanová slides the page across…") handles the rest.
- **Interrupt memory**: NPCs remember exact prior statements; contradicting themselves is detectable and the player can call it.
- Authoring format: a plain-text DSL we design together (see §6.3), compiled to graph data — critical for writing speed in our workflow.

### 4.5 Time, Map, and Events
- The city map is the day-planning screen. Locations show known open hours, travel is abstracted (adjacent districts cost nothing; cross-city costs part of a slot — a light pressure, not a puzzle).
- **Event deck**: authored events with trigger conditions (day range + world-state predicates) inject urgency: a source calls in panic, an office announces it's closing for inventory, a body of documents goes to the shredder in 48h. Events are the pacing tool that shapes an otherwise open structure.

### 4.6 The Final Report & Epilogue Simulator
On Day 11 the player composes the report from a structured builder: for each of ~8 report questions (Who caused the collapse? Was the death connected? Was there criminal intent? …) they attach asserted hypotheses and cite provenance. Then the epilogue engine runs:

- Each named party's outcome is computed from: strength of cited provenance (documents outweigh testimony; testimony from burned sources counts less), the party's connections (some are protected), and world-state (did the shredding happen? is the journalist alive to corroborate?).
- Epilogue is delivered as a sequence of newspaper clippings, letters, and one final scene, over "six months later." It is written to be honest: correct-but-unprovable assertions produce acquittals; the tabloid solution produces a satisfying conviction of the wrong man and a quiet, devastating final letter. **We author ~40 epilogue fragments** that compose combinatorially.

### 4.7 Difficulty & Accessibility of Thought
- Optional **"Second Auditor" mode**: a toggleable assistant (diegetic: Marta's junior colleague) who will point out *that* a contradiction exists in the board, never *what it means*. Default off. This is our accessibility ramp without violating P1.
- Full text-size/contrast options; the entire game is playable without color-only information; dyslexia-friendly font option for documents (with the "scanned" styling preserved as toggleable).

---

## 5. Technical Architecture

### 5.1 Engine Choice & Rationale
**Recommendation: Godot 4.x with GDScript (option to move hot systems to C#).**
Reasons: free and open-source, excellent 2D/UI tooling, scene system maps cleanly onto our screens, text rendering and theming are strong, exports to all desktop targets, and its plain-text scene/resource formats play well with a chat-based collaboration (we can review diffs as text). Alternative considered: TypeScript + web (max shareability, weaker packaging/perf for large text search); Unity (heavier, licensing noise, no benefit for a 2D text game). We are not writing an engine.

### 5.2 Top-Level Architecture: strict engine/content split

```
+---------------------------------------------------------------+
|                        PRESENTATION                           |
|  Screens: Map/Planner · Scene View · Dialogue UI ·            |
|  Document Viewer · Deduction Board · Archive · Report Builder |
+------------------------------△--------------------------------+
                               │ (UI events / view models)
+------------------------------▽--------------------------------+
|                       APPLICATION CORE                        |
|  GameStateStore (single source of truth, serializable)        |
|  EventBus (typed pub/sub; every mutation is an Event)         |
|  Systems: TimeSystem · SceneDirector · DialogueRunner ·       |
|  ClaimLedger · ConflictDetector · NPCMind · GossipSim ·       |
|  EventDeck · AssertionResolver · EpilogueEngine · SaveSystem  |
+------------------------------△--------------------------------+
                               │ (loads, validates)
+------------------------------▽--------------------------------+
|                        CONTENT LAYER                          |
|  Case packages (pure data): claims.json · npcs/*.mind ·       |
|  dialogue/*.dlg (DSL) · documents/* + meta · events.json ·    |
|  epilogue/*.frag · localization tables                        |
+---------------------------------------------------------------+
```

Key rules:
- **All game logic reads/writes only through GameStateStore**, and every mutation is an event on the EventBus. This gives us: trivial autosave, a debug time-travel log, deterministic replays for bug reports, and easy analytics during playtesting.
- **Content is data, never code.** A "case" is a self-contained package the engine loads. This is what makes Case 2 and 3 cheap later, and lets us divide labor cleanly (one of us can write case data while the other builds systems).

### 5.3 Data Model (core entities)
- `Claim {id, subject, predicate, object, qualifiers{}, provenance[], conflictPairs[]}`
- `Document {id, images[], pages[], extractableClaims[], versionOf?, destroyedFlag, metadata{date, issuer, docType}}`
- `NPC {id, portraitSet, personality{}, knows[claimId], hides[{claimId, unlock:Predicate}], lies[{claim, tell:Predicate}], gossipEdges[{npcId, delayDays, distortion}], trust:int, state:enum}`
- `DialogueGraph {nodes[], edges[], listeners[{claimPattern, targetNode}], stanceVariants{}}`
- `WorldEvent {id, window:{dayMin,dayMax}, trigger:Predicate, effects[Mutation], scene?}`
- `Hypothesis {id, memberClaims[], playerLabel, assertedTo[{npcId, day}]}`
- `EpilogueFragment {id, guard:Predicate, weight, text, slot}`
- `Predicate`: a small declarative condition language over world state (we define ~15 operators: hasClaim, trustAtLeast, dayAfter, docDestroyed, assertedTo, flag, and boolean combinators). One shared predicate evaluator used by dialogue unlocks, event triggers, epilogue guards — **one system, tested once, used everywhere.**

### 5.4 Subsystem Notes
- **ClaimLedger**: append-only; "forgetting" never happens, but provenance can degrade (document destroyed → provenance downgraded to memory). Indexes by subject/predicate for the board UI and ConflictDetector.
- **ConflictDetector**: runs on ledger append; mechanical checks (timeline, exclusivity) + authored conflict pairs. Emits `ConflictFound` events the UI turns into board notifications.
- **GossipSim**: end-of-day tick; breadth-first propagation of "what NPCs learned about the investigation" along gossip edges with per-edge delay/distortion; writes consequences as scheduled WorldEvents (e.g., `ShredderEvent` if any conspirator's alarm ≥ threshold). Deterministic given a seed — reproducibility matters more than variety here.
- **DialogueRunner**: interprets compiled DSL graphs; exposes listener matching for evidence presentation; owns interrupt-memory (transcript of NPC statements as claims with provenance = testimony).
- **AssertionResolver**: the "physics" of putting a hypothesis to someone: matches against authored responses, falls back to generic reaction computed from personality + whether the hypothesis touches their HIDES/LIES sets, mutates trust/state, notifies GossipSim.
- **EpilogueEngine**: evaluates report against outcome tables; selects and orders fragments; pure function of final state — trivially testable with saved states.
- **SaveSystem**: serialize GameStateStore + RNG seeds; save anywhere; 3 rotating autosaves at day boundaries. Save format versioned from day one.

### 5.5 Performance, Persistence, Tooling
- Performance is a non-issue by design (text + static 2D); the only care point is document image memory — lazy-load pages, cap texture sizes.
- **Internal tools we will build (small but essential):**
  1. *Case Validator* — CLI: checks every claim referenced by dialogue/events/epilogue exists; every HIDES unlock is reachable; conflict pairs are symmetric; every load-bearing claim has ≥1 acquisition path; time-budget lint (total available slots vs. content).
  2. *Dialogue DSL compiler* with graph visualization export.
  3. *Playthrough simulator* — headless bot that random-walks days and asserts random hypotheses; catches crashes, dead ends, and predicate typos long before humans do.
- Version control: Git, content as text (JSON/DSL), images via LFS.

---

## 6. Content Production Plan

### 6.1 Asset Budget (vertical slice)
| Asset | Count | Notes |
|---|---|---|
| NPC portraits | 12 × 4 expressions | consistent illustrated style; can be commissioned or AI-assisted then hand-corrected — we decide together |
| Location scenes | 14 static | painterly, muted palette |
| Documents | ~90 | template-generated layouts + hand-dressed details; period-accurate typography |
| City map | 1 (4 districts) | stylized, diegetic (a real 1990s tourist map look) |
| Music | 6 tracks | sparse piano/tape-hiss ambient; loopable |
| SFX/ambience | ~40 | offices, street, rain, paper |
| Words (dialogue+docs+epilogue) | ~110–130k | the real budget line |

### 6.2 Writing Pipeline
Character bible → per-NPC knowledge sheet (KNOWS/HIDES/LIES with unlock logic) → dialogue in DSL → validator pass → in-engine read-through. We write the **ground-truth document first** (already sketched in §2.2, to be expanded to ~5,000 words with a full timeline), because every lie must be authored against a known truth.

### 6.3 The Dialogue DSL (design intent)
Plain text, one file per NPC per scene-context; features: node labels, choice blocks with stance tags, guard predicates inline, claim-grant and claim-listener annotations, localization keys auto-derived. Designed so that a writer never touches engine code and so diffs read like a screenplay.

### 6.4 Localization
English first; Czech as the authenticity-check second language (names, documents, and idioms will be vetted for it regardless). All strings externalized from day one — retrofitting localization is the classic avoidable disaster.

---

## 7. UX / UI Design

- **Map/Planner screen**: the "morning ritual." Shows day number, remaining slots, location cards with known leads pinned. Calm, deliberate.
- **Scene view**: static illustration, hotspots, character present → dialogue panel slides in. No pixel hunting: hotspots are listed textually on demand.
- **Document viewer**: zoomable pages, side panel of extracted claims, "compare" mode for two documents side by side (essential for the doctored-copies mechanic).
- **Deduction board**: the signature screen. Corkboard metaphor but *structured*: claims as cards, typed links (supports / contradicts / same-event), hypothesis containers. Search and filter by person/date/predicate — with 350 claims, findability is a hard requirement, not a nice-to-have.
- **Archive**: chronological + faceted browsing of everything; provenance always one click away.
- **Report builder**: solemn, form-like, irreversible on submit (with a clear warning and a dedicated save).
- Overall visual language: paper, ink, rubber stamps, muted teal/ochre; UI sounds are physical (paper, drawer, stamp). Dark mode as "night shift" variant.

---

## 8. Audio Direction
Diegetic-leaning: typewriters, trams, radiators, distant trains. Music is restrained and mostly absent during interrogations (silence is the tension instrument), swelling only at day boundaries and the epilogue. One motif for Šebestová that the player will only consciously notice on a second playthrough.

---

## 9. Production Plan & Milestones

**M0 — Foundations (weeks 1–3):** GameStateStore, EventBus, Predicate evaluator + tests, save/load, empty screens navigable. *Exit criterion: a "walking skeleton" — start a day, spend slots on stub scenes, sleep, save, reload.*

**M1 — Talk & Read (weeks 4–8):** Dialogue DSL + compiler + runner; document viewer; ClaimLedger + provenance UI. Content: the Day 1–2 tutorial mini-case complete. *Exit: the mini-case is playable start to finish.*

**M2 — Think (weeks 9–13):** Deduction board, ConflictDetector, AssertionResolver, evidence presentation in dialogue. *Exit: player can catch one authored lie via evidence and see the NPC react.*

**M3 — Live World (weeks 14–18):** NPCMind full model, GossipSim, EventDeck, time pressure tuning; Case Validator + playthrough simulator. *Exit: asserting to the wrong person on Day 4 demonstrably causes the Day 6 shredding event.*

**M4 — Judgment (weeks 19–22):** Report builder + EpilogueEngine + first 15 epilogue fragments. *Exit: three hand-played runs produce three meaningfully different, coherent epilogues.*

**M5 — Content Complete (weeks 23–30):** all 12 NPCs, ~90 documents, all events, all epilogue fragments; two full internal playtests with note-taking.

**M6 — Polish & Slice Release (weeks 31–36):** art/audio pass, accessibility pass, difficulty tuning from playtests, trailer-able build.

(Weeks assume part-time; the ordering matters more than the calendar.)

---

## 10. Testing & Quality Strategy
- Unit tests for Predicate evaluator, ClaimLedger, ConflictDetector, EpilogueEngine (all pure or near-pure — architecture chosen partly for testability).
- Deterministic replay from event logs = every bug report is reproducible.
- Headless simulator soak runs nightly on content changes.
- Human playtests focus on the two designer-nightmares of this genre: (a) players feeling lost (mitigate via Second Auditor mode, event pacing), (b) players solving it by accident/meta rather than reasoning (mitigate via multiple consistent solutions and no truth-grading).

## 11. Risks & Mitigations
| Risk | Severity | Mitigation |
|---|---|---|
| Writing volume balloons | High | DSL + validator to keep throughput high; strict claim budget; cut NPCs before cutting depth |
| Deduction board UX fails (illegible at 350 claims) | High | prototype the board in M2 with real data, not lorem ipsum; search/filter first-class |
| "No grading" frustrates players | Medium | Second Auditor mode; tutorial mini-case teaches the epistemic contract explicitly |
| GossipSim produces unfair-feeling punishments | Medium | determinism + always foreshadow consequences (a warning scene precedes every destruction event) |
| Scope creep into Cases 2–3 mid-slice | Medium | this document; content-package boundary makes "later" cheap, so nothing tempts us to do it now |
| Sensitive themes (suicide, StB files) handled clumsily | High | content warnings, no depiction of the act, the theme treated with the gravity of the epilogue's design; external sensitivity read before release |

## 12. What We Build First (our immediate next steps)
1. Agree on engine (my recommendation: Godot 4) and repo layout.
2. I draft the Predicate mini-language spec and the Claim/Document/NPC JSON schemas for your review.
3. In parallel, we expand the ground-truth document of the Meridian case to a full dated timeline.
4. M0 walking skeleton.

---

*End of Plan 01. Sequel plan documents (Case 2 "The Land Registry," Case 3 "The Foundation") will be outlined only after the slice's systems prove themselves — but the architecture above already reserves their seats.*
