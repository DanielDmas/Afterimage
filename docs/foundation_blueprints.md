# AFTERIMAGE — Foundation Blueprints
**Document type:** Specification of the foundation layer (M0 + M4 systems). Companion to `master_plan.md` (§5.4, §5.7, §9) and `tech_guidelines.md`.
**Provenance:** these designs originate from the shelved *Quiet Ledger* plan (design reference only — that game will not be built, and its planning document has been removed from the repo). Everything below is **Afterimage's own spec**, restated standalone and adapted to this game. This file is the single source for the "inheritance ledger" systems; nothing here depends on any external document.

---

## 1. EventBus & GameStateStore (the spine)

### 1.1 GameStateStore
- **Single serializable source of truth** for all campaign/hub/meta state (mission-in-progress truth state lives in TruthSim and is reconstructed from replay logs — tech §3.1).
- All reads go through typed accessors; **all mutations are Events** (§1.2). No system holds private mutable campaign state.
- Serialization: full store → save format (tech §5.3). The store knows its `schema_version` and owns the migration ladder.
- Grants for free, by construction: autosave anywhere, a debug time-travel log, deterministic campaign replays for bug reports, and playtest analytics (the event stream *is* the instrumentation, ux_charter §6).

### 1.2 EventBus
- Typed publish/subscribe. Every event: `{tick|day, type, payload, source}`. Events are **facts, past tense** (`ClaimFiled`, `SuspicionEntryAdded`, `SleepBlockCompleted`) — never commands.
- Ordering: synchronous dispatch in registration order within a tick; subscribers may emit follow-up events, which queue (no reentrant dispatch). Deterministic by construction (tech §3.5).
- The append-only event log is the analytics stream, the debrief's claim-drafting source (master_plan §4.10), and the campaign save's audit trail.

## 2. The Predicate Language (one condition language, used everywhere)
A small declarative condition language evaluated against world state. **One evaluator, unit-tested once, used by:** dialogue guards and unlocks, mission event triggers, suspicion countermeasure (alibi) checks, debrief consequence rules, ending gates, and the validators.

- **Operator set (~18):** `hasClaim(id)`, `claimAsserted(id, mode?)`, `trustAtLeast(npc, n)`, `suspicionAtLeast(npc|faction, n)`, `mindBand(variable, band)`, `dayAfter(d)` / `dayBefore(d)`, `missionDone(id)`, `flag(name)` / `flagValue(name, v)`, `killsAtLeast(context, n)`, `witnessed(eventTag)`, `grounded(opClass|opId)`, `coverBlownTo(faction?)`, `endingGate(family)`, `itemHeld(id)`, `relationshipAtLeast(npc, tier)`, plus boolean combinators `all/any/not`.
- **Form:** data, not code — JSON tree in content files; the `.dlg` DSL writes them inline in a compact text form and the compiler emits the JSON.
- **Discipline:** adding an operator is a spec change to this file + evaluator tests, never an inline hack. The validator statically checks every predicate in content for unknown operators, unreachable conditions, and type errors.

## 3. Claims, Provenance & the Debrief Ledger
The epistemic backbone (adapted from the Quiet Ledger deduction design into the debrief system, master_plan §4.10).

- `Claim {id, subject, predicate, object, qualifiers{}, provenance[]}` — an atomic assertable fact. Subjects/objects are content IDs (tech §5.2).
- **Provenance chain** is first-class: every claim knows how Eliška came to hold it — `perceived` (from the percept event log; may be distortion-tainted, and the taint is *knowable to the engine, not to her*), `grounded` (verified via the Ground verb — armored), `evidence` (photograph, document — photographs record truth, master_plan §4.9), `told` (an NPC said it — carries the teller).
- **DebriefLedger:** per mission, the claim candidates drafted from salient log events, the honesty mode chosen per claim, the hidden engine-computed truth-delta, and consequences applied. Append-only across the campaign; the Theater's honesty report reads it directly (master_plan §4.12).
- Conflict handling: mechanical conflicts (same subject+predicate, incompatible object; timeline impossibility) are auto-detected to power Doubek's cross-checks and NPC interrupt-memory catches; semantic conflicts are authored pairs in mission packages.

## 4. The Dialogue DSL & Runner

### 4.1 DSL (authoring format)
Plain text, one file per NPC per scene-context, compiled to graph JSON (tech §5.1). Design goals: a writer never touches engine code; diffs read like a screenplay. Features:
- Node labels and choice blocks; **stance tags** per player line (`[procedural]`, `[warm]`, `[pressing]` — recolored by Radek's register at identity strain, master_plan §4.8).
- Inline **guard predicates** (§2) on lines and choices; **claim-grants** (`+claim.id`) and **claim-listeners** (`?claim.pattern → node`) so scenes react to what the player knows and asserts.
- **Radek/Eliška register marks** on choices (drives the strain-based pre-selection and input-hold behavior, master_plan §4.4.4).
- Localization keys auto-derived from file+node; `SubtitleDrift` pairs declared adjacent to their true line with a `drift_intent` note (tech §5.4).
- Compiler (`/tools/dlgc`) emits graph JSON + a visualization export (Graphviz) for review.

### 4.2 Runner
Interprets compiled graphs; owns **interrupt memory** — a transcript of NPC and *player-as-Radek* statements stored as claims with `told` provenance, so contradictions are detectable both ways: the player can catch NPC lies, and NPCs catch Radek's inconsistencies as suspicion entries (master_plan §4.7). Evidence/assertion presentation opens the claim archive mid-scene; graphs declare listeners for load-bearing assertions and a graceful generic response layer handles the rest.

## 5. NPC Mind Schema
`NPC {id, portraitSet, personality{pride, fear, greed, loyaltyTargets[]}, knows[claimId], hides[{claimId, unlock:Predicate}], lies[{claim, tell:Predicate}], gossipEdges[{npcId, delayDays, distortion}], trust:int, suspicion:ledger, relationship:tier, state:enum}`
- **KNOWS** may include false beliefs genuinely held. **HIDES** unlock via trust/leverage/assertion/world-state. **LIES** carry authored *tell conditions* — the evidence combination that catches them in-scene, changing NPC state by personality.
- The personality vector is small and authored (not ML); it drives leverage response, being-caught reactions, and gossip distortion flavor.
- **GossipSim:** end-of-day breadth-first propagation of investigation-relevant knowledge along gossip edges with per-edge delay and distortion; deterministic per seed stream (tech §3.3); writes consequences as scheduled mission events. In Afterimage its primary cargo is **suspicion** (master_plan §4.7).

## 6. Save Versioning Discipline
- `schema_version` in every save; forward-only chained migrations, each with a fixture test (tech §5.3). Save-breaking changes are a milestone-boundary event with an amendment note, never a surprise.
- The replay log format is versioned separately (`replay_version`) and pinned to engine+content versions — a replay declares what it needs to re-simulate truthfully; the Theater refuses gracefully rather than replaying wrong.

## 7. Validator & Bot Blueprints (tooling)
- **Content validator** (CLI, CI): every referenced ID resolves; every HIDES unlock reachable; every load-bearing claim acquirable on every branch family; predicate static checks (§2); calendar lint (mission windows vs. hub blocks); conflict-pair symmetry.
- **Fairness auditor** (CLI, CI): decks/levels/ops vs. the Fairness Charter — mask restrictions, density/tier caps, Clarity and photosensitivity substitutions present, loc drift pairs intact, substance-dominance lint (master_plan §10).
- **Headless bots:** random-walk soak (crashes, dead ends, predicate typos) plus the three authored personalities — paranoid (grounds always), credulous (never), liar (fabricates every claim) — all must finish every mission; run nightly (tech §9).

---
*This file is ratified alongside `tech_guidelines.md`. Together with `master_plan.md` §4–5 it is the complete pre-code specification of the foundation layer: M0 builds §1–2 and §6, M4 builds §3–5, tooling lands with its system.*
