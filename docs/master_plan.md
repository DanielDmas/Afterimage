# GAME PLAN 02 — "AFTERIMAGE"
### A psychological action thriller about a mind you cannot trust — including yours
**Document type:** Full design + technical architecture + production plan (pre-production, expanded edition)
**Document status:** v2.0 — expanded to a standalone master development plan. Supersedes v1.
**Relationship to Plan 01 (*The Quiet Ledger*):** Design reference and shared-universe bible **only**. That game will not be built, and its planning document has been removed from the repo — every design it contributed is restated standalone in `foundation_blueprints.md`. All systems are planned, specced, and scheduled **inside this project** (§5.7, §9). *Afterimage* plays, and is built, completely standalone.
**No code in this document — design, architecture, and production planning only.**

**Document map (the complete pre-production set — nothing is decided on the go):**
| File | Contents |
|---|---|
| `docs/master_plan.md` (this file) | Design, systems, narrative, architecture, production plan |
| `docs/tech_guidelines.md` | **Locked technology decisions** (engine, determinism contract, formats, budgets, CI) with change control |
| `docs/foundation_blueprints.md` | Full spec of the foundation layer (EventBus, state store, predicate language, dialogue DSL, NPC minds, claims, tooling) |
| `docs/art_direction.md` | Visual identity, beauty standards, VFX grammar, typography, motion |
| `docs/ux_charter.md` | Player-experience pillars, onboarding contract, QoL inventory, enjoyability metrics |
| `docs/story_bible.md` | Fixed narrative canon: timeline, voice sheets, gazetteer, slice mission ground-truth outlines (spoiler-complete) |
| `docs/roadmap.md` | Milestone backlog with acceptance criteria; the day-to-day tracking document |

---

## 0. Executive Summary

*Afterimage* is a single-player, top-down 2D psychological action thriller. You are an undercover officer embedded in **Argus** — a private security firm that by **2004** has metastasized into Vranov's dominant organized-crime/private-intelligence hybrid. Days are social infiltration under a cover identity; nights are fast, readable, consequence-heavy tactical action.

The hook — the thing that catches attention — is architectural, not cosmetic:

> **The engine simulates the true world on one layer and renders only what your character *believes* on another.** Stress, sleep deprivation, and moral injury inject deterministic, rule-bound distortions between the two: a hostile who was never there, a line of dialogue you misheard (the subtitle text itself changes), a corridor that isn't where you remember it, thirty seconds you cannot account for. You are given one costly verb to fight back: **reality-testing**. And after every mission, you must tell your handler what happened — while the game silently holds the recording.
>
> When a run ends, you unlock the **Afterimage**: a replay of the ground truth, side by side with what you saw. That comparison — *"wait, THAT'S what actually happened?"* — is the shareable, streamable, word-of-mouth moment the whole design is built around.

This is not "hallucinations as spooky VFX." The distortion system is a fair, learnable, counterable game mechanic with strict rules (§4.5), and the psychological model underneath (acute stress, fatigue, moral injury, identity strain) is a real simulation the player can manage — or mortgage.

**Why standalone, and why now:** an earlier plan (Plan 01, *The Quiet Ledger*) designed the deterministic, event-sourced, content-separated foundation and a dialogue/claims stack that *Afterimage* needs. That game is shelved; its **designs** survive as blueprints. Event-sourced ground truth is the *precondition* for honest unreliable perception and for the replay theater — so we build that foundation first, here, as this project's M0 (§9). We are not importing code that doesn't exist; we are building to a spec we already trust.

Reference points (flavor, not imitation): *Hotline Miami* (top-down readability, weight of violence), *Metal Gear* (infiltration texture), *Hellblade* (psychological seriousness), *Disco Elysium* (interiority), *Her Story / Obra Dinn* (epistemic play — our house obsession), *Alan Wake / Silent Hill 2* (mind-as-level-design, but we do it systemically, not scripted).

---

## 1. High Concept & Design Pillars

### 1.1 Logline
Eleven years after the Meridian bank scandal, an undercover officer burrows into the security firm that got away with it. The deeper the cover goes, the less the officer can trust the only witness they have left: themselves.

### 1.2 Design Pillars

**P1 — Two worlds, one truth.** Ground truth is simulated completely and deterministically. The player sees a filtered rendering. Every distortion is logged, bounded by fairness rules, and ultimately *disclosable* (the Afterimage replay). The game gaslights you and then, uniquely, lets you prove it. Honesty-after-the-fact is what separates psychological tension from cheap trolling.

**P2 — Action with weight, never friction with cheapness.** Combat is short, brutal, readable, and avoidable more often than players expect. Distortions may create dread, doubt, and terrible decisions — they may never create unfair deaths (hard rules in §4.5). The player's aim is never lied to; only the world is.

**P3 — The mind is a resource system you manage, not a meter that judges you.** Stress, fatigue, moral injury, and identity strain are simulation variables with gameplay-visible consequences and gameplay-usable countermeasures (sleep, grounding, confession, abstinence or use of substances — each with costs). No morality score. Consequences, not judgment.

**P4 — The cover identity is a second character sheet.** "Radek Mráz," the cover, has his own reputation, skills, relationships, and expectations. Feeding the cover starves the self and vice versa. The endgame question is not "will you be discovered?" but "which of you will be left?"

**P5 — Systemic under the hood, authored on the surface.** Missions, characters, and the conspiracy are authored; perception, stress, gossip/suspicion inside Argus, and debrief consequences run on simulation.

**P6 — Buildable by us.** Top-down 2D with modern lighting, small handcrafted levels, systemic depth over asset volume. Every expensive-sounding feature above is cheap *because* of the event-sourced core — which is why the event-sourced core is milestone zero, not an aspiration.

### 1.3 Audience & Rating
Adults. Themes: dissociation, paranoia, moral injury, insomnia, substance use, violence with consequences, undercover ethics. Violence is depicted top-down and stylized but treated as serious; no torture interactivity, no glamorized substance mechanics (using stabilizes short-term and damages long-term — modeled honestly, §4.4.5). PEGI 18 / ESRB M. Explicit content-warning screen with granular toggles (§4.16). We will commission a sensitivity read on the psychological depiction: the character is *a person under extreme strain*, not a walking diagnosis; we deliberately avoid naming real disorders in-fiction.

### 1.4 Platform & Scope Targets
- **Desktop first** (Windows/Linux/macOS), controller + M/K parity from day one (twin-stick friendly). Steam as primary storefront; itch.io for the demo.
- **Vertical slice:** prologue + 3 missions + safehouse hub, ~2.5 hours, the full perception stack working. Estimated **10–12 months part-time, fully standalone** — this now *includes* building the event-sourced foundation layer that v1 of this plan assumed would already exist (§9 for the honest breakdown).
- **Full game:** 12 missions + hub life, 8–12 hours, 3 ending families with internal variation.

### 1.5 What "advanced" means for this project (design maturity commitments)
These are the disciplines we hold ourselves to for the whole production, stated once here and referenced throughout:
1. **Determinism is law.** Any feature that cannot survive tick-perfect re-simulation is redesigned or cut (§5.3, §10).
2. **Fairness is auditable, not aspirational.** The Fairness Charter (§4.5) is enforced by a static auditor tool in CI, not by memory (§10).
3. **Missions must be fun sober.** A mission that isn't good with distortions off is rejected (§6.2).
4. **Content is data.** No mission logic in engine code; everything authored flows through validated content packages (§5.2, §5.8).
5. **Accessibility and psychological safety are features with owners and milestones**, not a pre-ship checklist (§4.16, §9).
6. **Nothing is decided on the go.** Technology choices are locked in `tech_guidelines.md` under change control; beauty is specified in `art_direction.md`; player-friendliness is specified, with pass/fail targets, in `ux_charter.md`. When a question comes up mid-build, the answer is looked up — or the governing document is formally amended at a milestone boundary.

---

## 2. Setting, Narrative & Story Bible

### 2.1 The World, Eleven Years Later
Vranov, 2004. EU accession is months away; everyone respectable is laundering their history. **Argus**, once a thuggish blackmail shop, is now three businesses in a trenchcoat: legitimate corporate security, an illegal private-intelligence archive built on stolen StB files and two decades of wiretaps, and a quiet enforcement arm. Its founder, **Zdeněk Hora**, is dying and hasn't told anyone; his two lieutenants are already fighting over the inheritance. Into this succession war the police insert one officer.

### 2.2 Backstory canon (fixed — the Meridian affair)
*The Quiet Ledger* will not ship as a game, so its events are now **fixed authored canon**, written into this project's story bible with no save-import mechanic (the v1 "import flag" feature is cut):

- In 1993, Banka Meridian collapsed after unsecured loans to an asset-stripped engineering works. The fraud's architect was deputy director **Pavel Rys**, working with the works' management and with **Argus**, then a small "security" outfit that handled the ugly parts — including the blackmail, using an StB-era family file, that drove whistleblower **Ivana Šebestová** to suicide.
- **The official history is the tabloid version.** Director **Antonín Karas** — guilty of negligence, innocent of the fraud — was convicted and became the face of the scandal. Rys emigrated quietly. Argus was never charged; the audit that touched them was buried.
- This is precisely why the logline works: Argus is "the firm that got away with it," and the police unit running Eliška knows a piece of the true history that was never provable. A handful of in-game documents, and one returning Argus veteran (§2.4), carry this canon; new players need none of it explained.

### 2.3 The Player Character(s)
**Eliška Vranná**, 34, undercover officer. Cover: **"Radek Mráz"** — the game makes you *play as Radek* for long stretches: his walk-cycle swagger, his dialogue options, his reputation sheet. The interface itself takes sides: at high identity strain, the pause-menu character sheet sometimes shows Radek's stats where Eliška's should be — one of the strictly bounded UI distortions (§4.2). Her handler, **Kapitán Doubek**, and a mandated police psychologist, **Dr. Sova**, anchor the debrief loop. Whether Dr. Sova's sessions are a safe space or feed Doubek's file on her is a live question the player probes.

### 2.4 Cast Roster
**Police side (hub):**
- **Kapitán Doubek** — handler. Old-school, protective in a way that is also controlling; his trust is the resource tap (§4.10). Believes the operation is about the archive. It's also about his own career.
- **Dr. Sova** — police psychologist, mandated check-ins. The only character who talks to *Eliška* rather than to the operation. Sessions reduce moral injury (§4.4.3) but everything said may or may not reach Doubek — the game seeds evidence both ways and never fully resolves it until Act 3.
- **Tereza Vranná** — Eliška's sister, civilian, believes Eliška works a desk job in Brno. Optional phone calls are an identity anchor (−strain, §4.4.4) and a vulnerability (Argus counter-surveillance can find her).

**Argus:**
- **Zdeněk Hora** — founder, early sixties, dying (pancreatic; undisclosed). Charismatic in the exhausted way of a man who has stopped lying to himself. Takes a liking to Radek — which is to say, to Eliška's performance — and is the game's chief engine of moral injury: he is *likeable*.
- **Kamila Rohanová** — lieutenant, runs the archive and intelligence business. Precise, funny, genuinely believes information is a safer currency than violence. The "clean hands" successor — whose cleanliness is subsidized by the other lieutenant's dirty ones.
- **Stanislav "Standa" Vrba** — lieutenant, runs enforcement and the protection book. Loyal to Hora like a son; treats Radek as a project and a protégé. The succession war is Rohanová's paper against Vrba's muscle, and both court Radek.
- **Josef Sedlák** — old guard, the returning face from 1993: the man who worked the Šebestová file. Now semi-retired, keeps the archive's oldest secrets, and is the only person who might recognize patterns in "Radek" that others miss. Canon anchor (§2.2) and Act 2's quiet menace.
- **Supporting bench (interactive):** a driver, a forger, a club manager, a young recruit who idolizes Radek (the game's cruelest mirror), an off-the-books cop on Argus's payroll — the leak plotline's red herring pool (§2.6, missions 9–11).

### 2.5 Story Shape (spoiler-level, internal)
Three acts across 12 missions. Act 1: earn trust, small jobs, the perception system introduces itself gently. Act 2: the succession war weaponizes Eliška; she discovers Argus's archive contains *her own* recruitment file — someone inside the police feeds Argus. Stress systems and leak paranoia now resonate: is the surveillance she keeps noticing real? (Sometimes yes. Deterministically.) Act 3: Hora's death detonates the succession; Eliška's final debrief — the game's climax — decides which faction, and which version of *her*, survives.

### 2.6 Mission Beat Sheet (12 missions + prologue)
Each entry: fantasy · phase emphasis · what the mission teaches or turns. Full per-mission ground-truth docs are authored per the §6.2 pipeline; this is the spine.

**Prologue — "Cold Open."** Pre-insertion. Dr. Sova teaches Ground diegetically; a controlled tail-and-report training exercise ends with the game *showing its own trick once*: one scripted misheard line, immediately disclosed in a mini-Theater. Establishes the epistemic contract before the player can distrust us for the wrong reasons. (§4.20.)

**Act 1 — Getting In**
1. **"Induction."** Night: ride-along debt collection at the Zálesí works' ruins; Radek must be *useful*. Teaches night-phase core verbs, noise, nonlethal options. First debrief (trivially honest — trust the form before you fear it).
2. **"The Listening Room."** Day: case a rival operator's club as Radek; night: plant Argus's bugs in it. Teaches day/night duality — your own daytime memory is the night's minimap. First deck: SubtitleDrift + AudioSwap only.
3. **"Smoke Test."** Argus stages a leak to test the new man. Social gauntlet; a beating Radek is expected to deliver (nonlethal branch showcase; the player chooses how convincing to be). First moral-injury spike by design. Slice climax.
4. **"Paper Weight."** Steal notarial documents from a law office Argus half-owns. Suspicion mechanics open up fully; first `PhantomEntity` appears — in a sightline pocket authored for it.

**Act 2 — The House Learns Your Name**
5. **"The Archive."** First entry to the archive floor. Eliška finds a file with her own recruitment date. The leak thread opens; from here, some surveillance she notices is *real* (deterministically, and disclosed as such in the Theater).
6. **"Vrba's Wedding."** All-day social mission, no night phase: the wedding of Vrba's daughter. Alcohol mechanics, gossip web at full density, Hora's first private conversation with Radek. The mission with zero shots fired and the highest stakes so far.
7. **"Counterweight."** Police counter-op: extract evidence from a police depot *before* Argus's own bought cop gets it — Eliška racing her own side's leak. Three-way night phase; the first mission where blown cover forks into the tragic branch-family instead of failure.
8. **"White Night."** Two jobs in one night, no sleep window between; fatigue showcase (`TimeGap`, `MemoryEdit` debut). Authored so a stimulant is *available and tempting* — and honestly costed (§4.4.5).
9. **"The Leak."** Eliška hunts the mole with Argus's own methods. Debrief claims become weapons: naming a suspect to Doubek has consequences whether or not she's right — and by now her confidence in her own observations is the game's live wire.

**Act 3 — Succession**
10. **"Succession."** Hora dies mid-mission (authored; his last conversation differs by relationship state). The safehouse is compromised; hub moves. Rohanová and Vrba both summon Radek the same night.
11. **"Inventory."** The archive war. Each faction tasks Radek with securing it; Doubek orders it seized; burning it is discoverable. Point of no return — the player's plan here selects the reachable ending families.
12. **"Afterimage."** The finale is the final debrief *as a playable mission*, intercut with the night it describes. The player assembles their account from claims whose truth they can no longer fully access — and the ending resolves from what they assert, what they verified, and who they've become (§2.7).

### 2.7 Ending Matrix
Three ending families, selected by tracked state — no hidden morality score, only consequences of legible systems:

| Family | Primary gate | Internal variation driven by |
|---|---|---|
| **Extraction** — Eliška leaves with the truth, whatever it's worth | Cover intact-enough at M12 + archive evidence delivered to Doubek | Discrepancy ledger (was her testimony honest? verified?), Doubek trust, whether the mole was correctly named — outcomes range from a conviction that holds to a report that dies in a drawer (the Meridian rhyme) |
| **Inheritance** — Radek wins | Identity strain in crisis band (§4.4.4) at M12 + Radek-aligned choices in M10–11 | Which lieutenant Radek rose under; whether Eliška's police self is exposed posthumously or simply… never mentioned again |
| **Erasure** — the archive burns | Player destroys the archive in M11/12 | Motive state the systems can read: burned *including* her own file (self-erasure) vs. burned after extracting the truth (arson as testimony); Tereza thread modulates the epilogue |

Blown cover is not a fourth family: it forks missions 7+ into harder, tragic variants *within* these families (one Extraction variant requires it).

### 2.8 Tone Rules
- Distortions are written with restraint; the scariest ones are mundane (a repeated breakfast scene; a colleague greeting you about a conversation you don't remember having).
- Argus people are professionals, funny, and frighteningly reasonable. The horror is that undercover work *works* by liking them.
- No jump-scare economy. Dread over startle, always.
- Nobody monologues their guilt; every NPC's writing brief includes "the version of events in which they are the reasonable one" (a Plan 01 discipline we keep).

---

## 3. Core Gameplay Loops

### 3.1 Macro Loop (one operation cycle, ~30–45 min)
1. **Safehouse (hub):** sleep (or fail to), manage the mind (§4.4), study the Argus org board (suspicion/relationship map), talk to Doubek, optional session with Dr. Sova, choose loadout *and* cover-consistent equipment (Radek carrying police-issue anything is a suspicion event). Full hub spec: §4.11.
2. **Day phase — Infiltration:** social stealth inside Argus offices/venues. Dialogue under cover (dialogue DSL with stances and claim-listeners, §4.8), light objectives: plant, photograph, eavesdrop, maintain alibis. Suspicion, not health, is the resource.
3. **Night phase — Operation:** the action core. Top-down real-time tactical action in handcrafted levels: Argus jobs (which Eliška must perform *well enough* to keep cover — the game's nastiest lever) or police counter-ops. 8–15 minutes, high intensity. Full spec: §4.9.
4. **Debrief:** report to Doubek. The debrief screen is built from **claims**: the player asserts what happened; the engine compares against ground truth silently. Consequences propagate (trust, resources, plot). Then the psychological tick: stress converts to fatigue, moral injury settles in, distortion budget for the next cycle is computed. Full spec: §4.10.

### 3.2 Micro Loop (combat/action)
Deliberate twin-stick tactical action, closer to a violent immersive sim than a bullet-hell: lean/peek, sound as a first-class system (noise rings visible when focused), lethal vs. nonlethal branches on every tool, short time-dilated **Focus** (a stress *loan* — slows time now, raises acute stress after), environmental play (lights, locks, phones). Enemy count is low (3–9 per encounter); lethality is high both ways; checkpoints are generous. Deaths restart encounters, not missions — the punishment lives in the psyche model and the story, not in lost time.

### 3.3 The Reality-Testing Loop (signature verb)
At any moment the player can **Ground** (hold a button: Eliška's breathing exercise, taught diegetically in the prologue). Grounding runs a reality test on what's in view: phantoms shimmer and dissolve; misremembered geometry snaps true; false subtitles visibly correct themselves. Costs: it is loud silence — in combat you are stationary and vulnerable; in social scenes, visibly "off" (suspicion tick if observed); and each Ground raises *fatigue* slightly. Skilled play is not grounding constantly; it is developing *judgment about when your judgment is bad* — the game's thesis as a mechanic. Full spec: §4.6.

### 3.4 The Debrief Loop (signature consequence)
Debrief claims come in three honesty modes the player chooses per claim: report what you saw (may be innocently false), report what you *verified*, or knowingly lie. Doubek's trust, resource flow, and late-game plot branches ride on the discrepancy ledger — which the player can finally read, mission by mission, in the post-game Afterimage theater. Full spec: §4.10.

---

## 4. Systems Design (Detailed)

### 4.1 The Two-Layer World
- **Truth layer:** full deterministic simulation at a fixed tick — every entity, sound, line of dialogue, and shot, event-sourced (append-only log). This is the only layer that decides outcomes: damage, deaths, alarms, witnesses, evidence.
- **Percept layer:** what is rendered. Computed each frame as *truth + active DistortionOps*. Distortions are data (typed operations, §4.2), never hand-hacked into levels.
- Every DistortionOp is logged with cause (which mind variable purchased it), duration, and resolution (grounded? believed? acted upon?). This log powers fairness auditing (§10) and the Afterimage theater (§4.12).

### 4.2 The DistortionOp Taxonomy (full spec)
Ten op classes in four tiers. Every class ships with: parameter schema, fairness tags, a **Clarity Mode substitution** (§4.16), an **accessibility twin** (audio ops get visual alternatives and vice versa), a defined **Ground response**, and **Theater disclosure** behavior. The fairness auditor (§10) statically verifies every deck against this table.

| Class | Tier | Cost (§4.3) | What it does | Ground response |
|---|---|---|---|---|
| `SubtitleDrift` | 1 | 5 | Rendered subtitle differs from the truth-layer line by a plausible mishearing; audio may stay true (the reader's poison) or drift with it | Subtitle visibly self-corrects, strike-through animation |
| `AudioSwap` | 1 | 8 | A true sound replaced by a near-neighbor (phone ring → alarm; name → other name) | True sound replays clean once |
| `PhantomAudio` | 1 | 8 | A sound with no truth-layer source: footsteps behind you, your name from another room | Fades under the breath rhythm |
| `HUDGlitch` | 2 | 10 | Bounded set only: map annotations, objective phrasing, clock time, journal margin notes. **Never** health, ammo, stamina, input prompts | Affected element flickers true |
| `ObjectSwap` | 2 | 12 | A prop rendered as a different prop of similar silhouette (a dropped phone as a weapon — the classic tragic misread, used with extreme authorial care) | Snaps true with a lens-pull |
| `FamiliarFace` | 2 | 15 | A stranger rendered with a face from Eliška's ledger of the dead or the betrayed; moral-injury's signature purchase | Face resolves to the real stranger |
| `PhantomEntity` | 3 | 25 | A full entity (person, car, dog) with no truth-layer counterpart; obeys Charter rule 1 absolutely | Shimmers and dissolves over ~1 s |
| `EntityMask` | 3 | 25 | A real entity not rendered. Restricted per Charter rule 2 to non-threats: witnesses, evidence, the body that "wasn't there" | Unmasked entity fades in |
| `GeometrySwap` | 3 | 20 | Between visits only, never mid-sight (Charter rule 4): a door where the wall was, a corridor shorter than memory | Layout snaps true; minimap annotates the correction |
| `TimeGap` | 4 | 30 | Controlled jump-cut in safe zones only: 10–90 s of truth-layer time the percept layer skips. The truth sim runs it fully; the Theater shows what happened | Cannot be grounded during (it already happened); journal marks the gap |
| `MemoryEdit` | 4 | 30 | Journal/board text differs from what the player actually saw — the cruelest one; always disclosable, never load-bearing for progression | Grounding near the journal restores the true entry, both versions kept visible |

**Authoring guidelines:** tier-1 ops carry Act 1; tier-3+ require deck authorization per mission and per-mission caps; `ObjectSwap` and `FamiliarFace` may never be placed where the Charter's misidentification nightmare becomes *forced* rather than possible; every op instance in a deck names its intended dramatic function (dread / doubt / grief / paranoia) so playtests can measure intent against effect.

### 4.3 The Distortion Director
An AI-director-style budgeter. Deterministic given seed + state — the same run replays identically: our debugging superpower and the honesty guarantee behind the Afterimage.

- **Budget accrual.** Each scene, the director receives points: `B = base(sceneType) × (0.4 + Σ wᵥ · v/100)` where `v` ranges over the four mind variables and weights `wᵥ` come from the mission deck (so a moral-injury mission buys `FamiliarFace`, a fatigue mission buys `TimeGap`). Base values: social scene ≈ 20, infiltration ≈ 30, combat ≈ 25, hub ≈ 10.
- **Purchasing.** The director spends budget on ops from the mission's **weighted deck** (authored per mission/act), subject to: global density cap (max 3 concurrent ops; ≥20 s spacing between tier-3+ ops), per-encounter caps from the deck, Charter constraints (auto-enforced — an illegal purchase is a build failure, not a runtime clamp), and variable-affinity (each op class lists which variables may purchase it).
- **Cooling.** On player death, encounter budget ×0.6; second death in the same encounter ×0.3 (Charter rule 7). On Ground resolving an op, refund 0 — but the op class's weight in this scene decays (the mind that gets caught repeating a trick changes tricks).
- **Seeding.** One RNG stream per system (§5.3); the director's stream is seeded from (run seed, mission id, scene id) so re-simulation reproduces every purchase tick-perfectly.

### 4.4 The Mind Model (four variables, all diegetic, all 0–100)
Bands used throughout: **Quiet** 0–24, **Murmur** 25–49, **Loud** 50–74, **Crisis** 75–100. All constants below are tuning baselines for M3 playtests, stated so we argue about numbers, not adjectives.

**4.4.1 Acute stress (fast).** Gains: entering combat +8; gunfire within earshot +2; near-discovery event +10; witnessing a kill +6; acting on a believed phantom +5; Focus use +6 (the loan, billed after the slowdown ends). Decay: −0.4/s in safe zones, −0.1/s in mission with no hostiles alerted; completing a Ground −8; hub rest returns it to a floor of `max(fatigue, moralInjury) × 0.3`. Effects by band: Murmur unlocks tier-1 purchases; Loud adds tier-2 and tightens the noise-ring rendering (diegetic tell); Crisis adds screen-edge breathing VFX and biases the director toward combat-adjacent ops.

**4.4.2 Fatigue (daily).** Gains: skipped sleep block +12; each hour awake past 18 +2; each Ground +1.5; White-Night-class double missions add a scripted +10. Decay: **only sleep** — full block −40, partial block −15; nothing else touches it (design commitment: no coffee-as-cure). Effects: Murmur raises Ground cost to +2.5 fatigue; Loud unlocks `TimeGap`; Crisis unlocks `MemoryEdit` and adds input-latency *rendering* (percept-side sluggishness VFX — actual input handling is never delayed, Charter rule 3).

**4.4.3 Moral injury (slow, sticky).** Gains, context-weighted: kill in open combat +4; kill of an unaware victim +6; executing a downed enemy +9; a civilian +15; betraying an Argus NPC with relationship ≥ friendly +8; a knowing lie in debrief +3 (+5 if it conceals a death). Decay: near-zero passively (−0.1/day). Active decay only through confession-shaped mechanics: a Dr. Sova session −4 to −8 (scaled by how much the player actually discloses in the session's choice structure — and disclosure may feed Doubek's file, §2.4); telling Doubek a hard truth −6 (with its own trust/plot costs). Effects: purchases the *personal* ops (`FamiliarFace`, victim-adjacent `PhantomAudio`, `MemoryEdit` of the order of events at a shooting).

**4.4.4 Identity strain.** Gains: +1/day in cover; +2 per skill check passed *as Radek*; +4 per Radek-method act (intimidation, ugly jobs done convincingly); +2 spending Argus money on personal comfort. Decay: −3 per Eliška-anchor act (a Tereza call §2.4, a private ritual in the hub, a truthful Sova session), each with risk or time cost. Effects: Murmur recolors some dialogue UI toward Radek's register; Loud pre-selects Radek options in dialogue (Eliška options require an input *hold* — never removed, made effortful); Crisis enables the character-sheet swap distortion and gates the Inheritance ending family (§2.7).

**4.4.5 Substances & tools (honest tradeoffs, authored).** Stimulants: suppress all fatigue *effects* tonight; afterwards fatigue floor +10 for 3 days and acute-stress gains ×1.25. Alcohol at Argus socials: −1 suspicion per drink consumed in-scene, +2 identity strain, and one random tier-1 op authorized for the scene. Sedatives (hub): guarantee a full sleep block during high-stress nights, +moral-injury decay blocked that night (you skip the processing, not just the insomnia). **No mechanic ever makes sustained use optimal; the model punishes dependency curves by design, not by accident** — the fairness auditor lints decks and missions for configurations where repeated use dominates.

### 4.5 Fairness Charter (hard rules — the mechanic lives or dies here)
1. Phantoms never deal damage and never block movement or bullets. The danger of a phantom is *what you do about it*: shooting one fires real bullets into the real world (noise, witnesses, or — the nightmare the game is honest about — a real person you misidentified; missions are authored so this is possible but never forced).
2. `EntityMask` is never applied to entities that can damage the player while masked; it is used for witnesses, evidence, and dread, not for cheap ambushes.
3. Player inputs, aim, and hit registration are never distorted. The hands are true; only the eyes and memory lie.
4. Geometry never changes while observed; no distortion may contradict information the player is currently, actively verifying.
5. Everything is disclosable: every op appears in the post-run Afterimage. No secret permanent gaslighting.
6. **Clarity Mode** (accessibility, §4.16) can flag distortions in real time with a subtle vignette — the psychological pressure drops, the story stays intact. Fully honorable way to play; no content gated behind suffering.
7. Distortion density is capped per encounter and cooled after deaths — dying twice to a situation demonstrably reduces director budget there.
8. **The Theater never lies and the debrief never forges.** Truth-view replay is raw re-simulation; the engine never fabricates a claim the player didn't make, and never alters a claim after submission.

### 4.6 The Ground Verb (full spec)
- **Input:** hold (rebindable; hold-to-toggle alternative, §4.16). **Duration:** 2.5 s baseline; 3.5 s in fatigue Loud+.
- **Effect radius:** everything currently in view/earshot; resolves *all* active ops in scope simultaneously (no partial grounding — the player learns the world is either being tested or it isn't).
- **Costs:** stationary and defenseless for the duration (combat); a visible "off" moment — if observed by an Argus NPC in a social scene, a suspicion entry (weight 2, "Radek does that breathing thing," §4.7); +1.5 fatigue per use (+2.5 at fatigue Murmur+).
- **On empty:** grounding when nothing is distorted still costs — and still *tells you something true* (the world held). This is deliberate: negative results are information, and the cost keeps them from being free.
- **Edge cases:** cannot interrupt `TimeGap` (already elapsed); during dialogue, grounding pauses the exchange one beat and NPCs react by personality (Rohanová notices everything; Vrba finds it funny once); grounding in the Theater is a scrubber feature, not a verb.

### 4.7 Suspicion, Cover, and the Argus Social Graph
Argus NPCs run a full mind-model (KNOWS/HIDES/LIES sets + personality vector + gossip edges — the Plan 01 NPC design, built here, §5.7), extended with a **suspicion ledger**: observations that don't fit Radek. 
- **Entries:** typed observations with weight 1–10 (seen Grounding: 2; police-pattern behavior at a scene: 4; inconsistency between two things Radek said: 3–6 via the interrupt-memory system; carrying cover-inconsistent equipment: 5; surviving something implausible: 6). Entries decay −1/week if unreinforced.
- **Propagation:** along authored gossip edges with per-edge delay (1–3 days) and distortion (weight ±1, details blur). End-of-day tick, deterministic given seed. The player watches the *effects* on the org board (§4.11), never raw numbers.
- **Thresholds per NPC:** at 25 (wary) they test Radek — trick questions with claim-listeners armed; at 50 (active) counter-surveillance events enter the mission event deck; at 75 (convinced) the cover-blown fork triggers **for the faction that NPC belongs to** — blown to Vrba plays differently than blown to Rohanová.
- **Countermeasures:** alibi actions (spend hub time constructing verifiable cover stories — retroactive Predicate guards against specific entry types), scapegoats (mission opportunities to redirect suspicion — with moral-injury pricing), and the nastiest one: doing ugly jobs *convincingly* (large suspicion relief, large strain/injury cost).
- Blown cover is not instant game over: it forks missions into a harder, tragic branch-family — and one Extraction variant requires it (§2.7).

### 4.8 Day Phase — Social Stealth (full spec)
- **Verbs:** converse (stance-tagged dialogue), eavesdrop (positioning + noise system reused from night phase), observe (build org-board knowledge), plant/lift (pickpocket-class interactions with observation cones), photograph, small talk (harmless — but maintains presence in a space; loitering *without* it is an observation).
- **Dialogue:** node graphs authored in the plain-text DSL (§5.7), with **stance modifiers** (procedural / warm / pressing — Radek's register recolors them at strain, §4.4.4), **claim-listeners** (scenes declare which player-known claims they react to), and **interrupt memory** (NPCs remember Radek's exact prior statements; contradictions become suspicion entries — the Plan 01 lie-catching system pointed at the player).
- **Objectives** are predicate-guarded, never quest-markered: the mission doc states what Argus (or Doubek) expects; the world evaluates what actually happened.
- **Failure texture:** the day phase has no fail state, only suspicion, burned opportunities, and worse night-phase starting conditions (a guard who was warned, a door that got locked).

### 4.9 Night Phase — Combat & Infiltration (full spec)
**Player verbs:** move, sprint (noise), crouch, lean/peek, aim, fire, reload, holster, melee takedown (lethal), chokehold (nonlethal, slow, interruptible), throw (distraction objects), interact (locks, lights, phones, bodies), **Focus** (0.4× time for 3 s; +6 acute stress billed after), **Ground** (§4.6).

**Weapons & tools (2004 Vranov flavor, lethal/nonlethal pairing on every loadout slot):**
- Sidearms: CZ 75 (loud, reliable), suppressed .32 (quiet, weak); Argus-issue Škorpion vz. 61 (Radek-appropriate; using police-issue anything is a suspicion entry, §4.7).
- Long: worn double-barrel (enforcement jobs only — carrying it *is* a statement).
- Nonlethal: telescopic baton, incapacitant spray, improvised (bottle, fire extinguisher).
- Tools: lockpicks, radio scanner (hear police/Argus nets — truth-layer audio, therefore distortable), instant camera (evidence — photographs record *truth*, a quiet late-game revelation the player can discover and exploit), cut phone lines, breaker panels.

**Enemy archetypes (6):**
1. **Sentry** — static/patrol, teaches vision and noise. 2. **Professional** — Argus-trained: flanks, checks corners, calls contacts in on the net. 3. **Heavy** — armored, shotgun, slow; the "you cannot fight everything" lesson. 4. **Runner** — breaks for a phone/exit to report; the game's cruelest temptation (shooting a fleeing unarmed man is heavily moral-injury priced). 5. **Technician** — cameras and lights; disabling their infrastructure is the systemic route. 6. **Civilian/Witness** — no threat, maximum consequence; the WitnessSystem's protagonist.

**AI design bar:** legible over clever — utility-scored behaviors over small state (patrol/investigate/engage/flee/report) with truth-layer senses (vision cones, sound propagation, last-known-position memory). The player must be able to model AI perfectly, because the game's uncertainty budget is spent *entirely* on the player's own perception. Two uncertain systems stacked would be noise, not dread.

**Damage model:** player takes 2–4 hits (by difficulty); enemies take 1–3 by weapon/armor; no regen mid-encounter, patch-up between encounters. **Checkpoints:** at encounter boundaries, generous; death restarts the encounter with director cooling applied (§4.3).

**Encounter grammar (authoring rules):** every encounter provides ≥1 nonviolent route, ≥1 noise-manipulation opportunity, ≥1 authored phantom-plausible pocket (sightline geometry where a tier-3 op is credible), and explicit witness stakes. Encounters are placed 3–9 enemies, 60–180 s expected engagement.

**Combat-feel tuning checklist (M1 exit gate):** stop-distance and acceleration feel (top-down "weight"); muzzle-flash/noise-ring readability at design zoom; hit feedback (hitstop 40–70 ms, sprite flash, sound layers); takedown animation interruptibility; controller stick-aim assist curves vs. M/K parity; camera lookahead when leaning; screen-shake budget (low — readability is P2); death-and-restart under 3 s.

### 4.10 The Debrief System (full spec)
- **Claim generation:** at mission end, the engine drafts the claim list from the event log's salient events — objectives touched, shots fired, kills and their contexts, alarms, witnesses, conversations held — **as perceived**: a believed phantom the player acted on generates a claim candidate ("a second guard was present"), because Eliška believes it. This is the system's quiet knife.
- **Honesty modes, chosen per claim:** **As-seen** (assert the percept — may be innocently false); **Verified-only** (only claims that were grounded or are evidence-backed — fewer, but armored: a verified claim can never later be contradicted, and Doubek's trust in verified claims compounds); **Fabricate** (knowingly assert what the percept didn't show — protect Radek's actions, hide a kill, cover a blackout; +moral injury, §4.4.3, and creates a discoverable liability: if contrary evidence exists in the world — Argus's own archive, a photograph, a witness — a future event can surface it).
- **Truth-delta:** engine-computed per claim, hidden until the Theater. Consequences run on the delta *and* the mode: an honest error costs less trust than a fabrication when discovered, and the discovery machinery is diegetic (Doubek cross-checks what he can).
- **Consequence channels:** Doubek trust (gates resources and late-game options), resource budget for the next cycle (§4.13), plot flags (mission variants, the leak thread, ending gates), and the psychological tick (lies price into moral injury immediately — the liar knows).
- **UI:** a form. Our house aesthetic — paperwork as dramaturgy. Claims as typed lines, mode as a stamp choice, submission irreversible with a dedicated autosave (Charter rule 8).

### 4.11 The Safehouse Hub (full spec)
- **Calendar & sleep economy:** hub time advances in blocks (evening/night/morning); sleep consumes blocks (§4.4.2) and competes with: org-board work, alibi construction (§4.7), Sova sessions, Tereza calls, equipment prep. Mission windows are authored per mission — the pressure is scheduling, never a real-time timer.
- **Org board:** corkboard-language relationship/suspicion map of Argus (the house visual language). Shows structure, known gossip edges, and *effects* of suspicion (who's been testing Radek), never raw numbers. Fed by day-phase observation; at fatigue Crisis it is `MemoryEdit`-eligible (and always disclosable).
- **Mind dashboard:** framed as Dr. Sova's worksheets — the four variables rendered diegetically (sleep diary, session notes), bands not numbers by default (numbers togglable in options; no shame in playing with the hood open).
- **Loadout:** night-phase kit vs. cover-consistency check (§4.7); Radek's wardrobe and props for day scenes.
- **Dr. Sova sessions:** short dialogue scenes with real choice structure (what to disclose); moral-injury decay scaled by disclosure (§4.4.3); the is-this-confidential thread woven through Acts 2–3.

### 4.12 The Afterimage Theater (full spec)
- **When:** unlocked per mission after its debrief; full campaign timeline post-game.
- **View:** synchronized dual-pane replay — truth view and percept view — with a scrubber, tick-accurate, driven by re-simulation (§5.3). Op timeline below the scrubber: every DistortionOp as an annotated span (class, cause variable, resolution: grounded / believed / acted-upon).
- **Honesty report:** per-mission table of debrief claims vs. truth-delta vs. mode chosen — the discrepancy ledger made legible. The campaign view graphs the four mind variables across all missions against the claims record: the shape of a cover story, drawn by the player's own hands.
- **Sharing:** one-click image export of a run's discrepancy summary and of any single dual-view moment (spoiler-safe crop rules: exports never include future-mission content). This is the organic-marketing engine (§11.4).
- **Spectator/streamer note:** a toggle to suppress Theater auto-unlock until stream end, so streamers can experience missions blind and do Theater reveals as a segment.

### 4.13 Economy & Progression
- **Two currencies, deliberately incompatible:** Doubek's **operational budget** (police resources: clean gear, surveillance support, alibi paperwork — scales with trust and with *verified* claims) and **Radek's pay** (Argus money: cover-consistent gear, social spending, bribes — spending it on Eliška's comfort prices identity strain, §4.4.4).
- **Progression is access, not stats:** no XP. Across 12 missions the player accrues tools, standing (Argus rank unlocks mission variants and spaces), org-board knowledge, and *system mastery* — the mind model and director are learnable, and learning them is the power curve. The only "build" is the psyche the player has chosen to spend.
- **Difficulty of the economy:** tuned so that a player who never lies is resource-poor but armored, a player who lies fluently is rich and fragile — both viable through the slice, divergent by Act 3 (ending gates, §2.7).

### 4.14 Missions & Level Design
Handcrafted compact levels (a nightclub back-house, a server archive, a river warehouse, a police evidence depot) designed twice: once as truth, once annotated with **distortion affordances** (mirror surfaces, PA speakers, sightline pockets where phantoms are plausible). Day/night variants of several spaces — you case it as Radek by day, hit it by night; your own daytime memory becomes the minimap, and fatigue corrupts *the memory*, not the space. 3 missions + prologue in the slice (§2.6: Cold Open, Induction, The Listening Room, Smoke Test), 12 in the full game, plus the hub.

### 4.15 Difficulty
Combat difficulty and psychological intensity are **separate sliders**. A player can want brutal gunfights with mild distortion, or trivial combat inside a deeply unreliable world. Combat slider: damage/ammo/AI aggression. Psych slider: director budget multiplier and tier caps (never below the authored story minimum — some ops are narrative). Defaults tuned in playtest; both sliders diegetically framed; changeable mid-campaign without penalty or achievement gating.

### 4.16 Content & Accessibility Safeguards
- **Granular content toggles** at first launch and any time after: photosensitivity-safe (no flicker-class VFX — the deck substitutes automatically; auditor-enforced), subtitle-drift off (audio ops get visual alternatives), self-harm-adjacent imagery off (none is interactive regardless), substance-mechanics autopilot (choices made by a stated policy, scenes retained).
- **Clarity Mode** (Charter rule 6): real-time distortion flagging via subtle vignette. First-class, tested, no content loss.
- **Standard accessibility:** colorblind-safe noise/suspicion indicators (shape+color double-coding), full remapping, hold-to-toggle alternatives for Ground and chokehold, UI scale, screen-reader support for all menu/paperwork screens (our forms are the game — they must read aloud), subtitle size/background options, no required rapid inputs.
- **Sensitivity review** (external consultant) on the psychological depiction and the suicide-adjacent backstory content before slice release (§9 M7, §10).

### 4.17 Journal, Photography & Evidence
- **The journal** is Eliška's own record, auto-written from **percept** events at cycle boundaries (mission summary, org-board notes, personal marginalia authored per mind-state band). Because it is percept-side it is `MemoryEdit`/`HUDGlitch`-eligible — and every edit is disclosable (Charter rule 5, §4.5): grounded journal pages show both versions, struck through and retyped (art_direction §4). The journal is the player's memory made object, which is exactly why the game can touch it.
- **The instant camera** is the one **truth instrument** the player can carry: photographs are taken from the truth layer (a phantom photographed produces an empty frame — a discovery the game never explains in words; the film teaches it). Film is scarce (3–5 exposures per mission, resupply via Doubek's budget), so photographing is a *belief bet*: you spend truth-paper on what you doubt most. Photos attach to debrief claims as `evidence` provenance (armored, §4.10) and pin org-board entries.
- **Evidence items** (documents lifted, tapes, ledger pages) carry claims with `evidence` provenance (blueprints §3). Evidence is heavy in cover terms: carrying it through a day phase is a suspicion risk (§4.7); the dead-drop ritual (hub calendar action) converts held evidence into filed evidence.

### 4.18 Mission Outcomes & the No-Fail Contract
Missions end in **outcome states, never game-over**: **Clean** (undetected, objectives met) · **Loud** (alarms/witnesses — the world reprices, §4.7) · **Burned** (objective lost or evidence destroyed — the campaign routes around it; every load-bearing plot flag has an alternate acquisition path, validator-enforced) · **Aborted** — the player may walk away at authored exfil points in every night mission; aborting an *Argus* job has cover consequences, aborting a *police* op has trust consequences, and both are always survivable. Death is the only repeated state (encounter restart, §3.2). The campaign cannot dead-end: the validator proves every mission completable from every reachable world state (§10). Failure in *Afterimage* is always a fork, never a wall.

### 4.19 Endings Delivery & the Epilogue Engine
- The three families (§2.7) resolve through an **epilogue engine**: authored fragments — news clippings, case-file pages, letters, one final playable scene per family — selected and ordered by predicate guards (blueprints §2) over final campaign state. Data: `EpilogueFragment {id, guard:Predicate, slot, weight, textKey}`; ~40 fragments at full scope, composing combinatorially so endings feel *computed from your campaign*, not picked from three.
- Delivery order: final mission → debrief (the climax, §2.6) → epilogue sequence → **the full-campaign Afterimage unlock**: the complete honesty report, every mission's dual replay, and the four mind variables graphed across the whole game — the last image is the player reading their own file. Then, and only then, credits.
- The epilogue is honest the way the debrief taught them to fear: correct-but-unverified assertions can die in a drawer; the tabloid lie can convict; the paperwork aesthetic carries it (a verdict is a form, too).
- **Save-reload stance (ruled now, not on the go):** reloading a pre-debrief save to re-file claims is *allowed* — kind product (ux_charter X1), single-player freedom, and re-simulation makes it cheap. We spend zero design energy punishing it; the Theater simply records the account that was *submitted*. The design defends itself honestly instead: the player who scums the debrief is optimizing away the game's point, and the mind model (lies still price into moral injury on the timeline that counts) makes sincerity the interesting path, not the enforced one.

### 4.20 Onboarding & The Prologue
The prologue ("Cold Open," §2.6) carries the entire epistemic contract:
1. Ground taught diegetically by Dr. Sova, practiced in a zero-stakes scene.
2. The phase split taught separately — one pure day scene, one pure night scene — before any mission mixes them (visual grammar per phase is strict and distinct).
3. **The game shows its trick once:** a scripted, safe misheard line, immediately disclosed in a mini-Theater. The player learns *the game will lie and then prove it lied* in the first thirty minutes — trust is established before it is spent.
4. The first debrief is trivially honest (nothing worth hiding) so the form is familiar before it is frightening.
Tutorialization after the prologue is diegetic only (Doubek briefs, Sova worksheets); no toast-tips in mission.

---

## 5. Technical Architecture

### 5.1 Engine
**Godot 4.x** (GDScript first; hot paths — truth-sim tick, director — in C# or GDExtension only if profiling demands; we do not assume it will). Rationale: free and open-source, its 2D lighting/normal-map pipeline and shader stack cover 100% of our visual needs, plain-text scene/resource formats diff cleanly in our review workflow, exports to all desktop targets. **Version pinning policy:** the engine version is pinned per milestone; upgrades happen only at milestone boundaries, gated on the determinism suite passing green on the new version (§10).

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
|  SuspicionGraph + GossipSim                                      |
|  DialogueRunner + Claims/DebriefLedger                           |
|  Predicate evaluator (one condition language, used everywhere)   |
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
- Fixed-tick truth simulation (target 30 Hz sim under 60+ Hz render, interpolated), integer/fixed-point where float drift threatens determinism, single seeded RNG stream per system (sim, director, gossip, AI — never shared, so adding a system never perturbs another's sequence).
- The event log (inputs + seeds + authored triggers) *is* the save file for mission-in-progress and *is* the Afterimage source. Replays are re-simulations, not video — tiny on disk, perfectly accurate, and they double as bug reports (a crash + its log = reproducible case).
- The Afterimage Theater renders the same replay twice — truth view and percept view — synchronized, with a scrubber and op-annotations. Checkpoint snapshots every N seconds of log keep scrubbing fast (§5.6).

### 5.4 Data Model (core entities)
- `DistortionOp {id, class, params, cause:{variable, threshold}, window:{start,end|condition}, fairnessTags[], dramaticIntent, resolution?}`
- `MindState {acuteStress, fatigue, moralInjury, identityStrain, modifiers[]}`
- `DebriefClaim {id, assertion, honestyMode, truthDelta (engine-computed, hidden), consequencesApplied[]}`
- `SuspicionEntry {npcId, observation, weight, decay, sharedWith[]}`
- `MissionPackage {truthLevel, affordanceLayer, deck, npcRoster, debriefSpec, endingHooks}`
- `DistortionDeck {missionId, weights{opClass→weight}, variableAffinity{}, caps{concurrent, perEncounter, tierCeiling}, budgetWeights{wS,wF,wM,wI}}`
- `EpilogueFragment {id, guard:Predicate, slot, weight, textKey}` (§4.19)
- Foundation entities built to Plan 01's designs (§5.7): `Claim {subject, predicate, object, qualifiers, provenance[]}`, `Predicate` (small declarative condition language, ~15 operators, one evaluator used by dialogue unlocks, event triggers, ending gates — one system, tested once, used everywhere), `NPC` mind schema (KNOWS/HIDES/LIES + personality vector + gossip edges), `DialogueGraph` (+ stance variants + claim-listeners), versioned save format from day one.

### 5.5 Enemy & Civilian AI
Utility-scored behaviors over small state (patrol/investigate/engage/flee/report) with truth-layer senses (vision cones, sound propagation, memory of last-known). Design bar: legible over clever (§4.9). AI reads *only* truth — enemies never react to phantoms, which is both a fairness guarantee and, discovered by observant players, a Ground-free reality test the design deliberately leaves on the table (watching a guard *not* react to what you see is free information, paid for in dread).

### 5.6 Performance Notes
Top-down 2D with lighting: comfortably within budget. Watchpoints: percept-layer double bookkeeping (design ops as render-side decorators, not entity clones), replay re-sim speed for theater scrubbing (checkpoint snapshots every N seconds of log), audio voice count during distortion-heavy scenes, document/portrait texture memory in hub screens (lazy-load).

### 5.7 Inheritance Ledger (what the Plan 01 *document* paid forward)
Plan 01's game is shelved; its useful designs have been extracted, restated standalone, and adapted for this game in **`foundation_blueprints.md`** — the single source for these specs (the Plan 01 document itself is gone from the repo). **Everything below is built inside Afterimage, on Afterimage's calendar (§9) — no external dependency of any kind exists.**
- **Built to Plan 01's spec, as designed there:** EventBus (typed pub/sub; every mutation is an event), GameStateStore (single serializable source of truth), Predicate language + evaluator (+ its test discipline), versioned save format, dialogue DSL + compiler + runner (stances, guards, claim-grants/listeners, localization keys auto-derived), claims/provenance concept, NPC mind schema, gossip propagation.
- **Adapted:** gossip → suspicion ledger (§4.7); claims → debrief honesty modes (§4.10); Plan 01's Case Validator concept → our fairness auditor + deck/mission validator (§10); its headless playthrough simulator → our bot rigs (§10).
- **Genuinely new to Afterimage:** TruthSim/percept split, DistortionOps + Director, MindModel, real-time combat + AI, WitnessSystem, replay Theater.
The honest accounting: roughly **40% of Afterimage's core is pre-designed** — a specification dividend, not a code dividend. The calendar in §9 prices that correctly.

### 5.8 Project & Repo Structure (proposed)
```
/project.godot            # Godot 4.x, version pinned per milestone
/src/
  core/                   # EventBus, GameStateStore, SaveSystem, Predicate
  sim/                    # TruthSim: actors, AI, sound, witnesses
  mind/                   # MindModel
  director/               # DistortionDirector + op implementations
  percept/                # PerceptRenderer, op decorators, HUD
  social/                 # SuspicionGraph, GossipSim
  dialogue/               # DSL runtime, DialogueRunner
  debrief/                # claims, ledger, consequences
  theater/                # replay + dual view
  ui/                     # hub screens, menus
/content/
  missions/m00_prologue … m12/   # one package per mission (§5.4)
  decks/                  # distortion decks
  dialogue/               # .dlg DSL sources
  minds/                  # NPC mind files
  loc/                    # localization tables (externalized from day one)
/tools/                   # validators, fairness auditor, DSL compiler, bots
/tests/                   # unit + determinism corpus (recorded runs)
/docs/                    # the document set (see map in header), story bible,
                          # mission ground-truth docs, ENGINE_VERSION, pipelines/
```
Conventions: content is data (JSON/DSL/text), reviewed as diffs; images via LFS; GDScript style guide + static typing enforced by CI lint; every system lands with its unit tests or its determinism-corpus entry (definition of done, §10).

---

## 6. Content Production Plan

### 6.1 Asset Budget (vertical slice)
| Asset | Count | Notes |
|---|---|---|
| Character sprites | ~14 actors × animation sets | top-down, readable silhouettes; normal-mapped for lighting |
| Levels | prologue + 3 missions + hub (≈7 spaces) | handcrafted tilesets ×3 environments |
| Portraits | 10 × 3–4 expressions | consistent illustrated style |
| Distortion VFX/shader set | ~15 ops' worth | the art-direction crown jewels; budgeted early (M2) |
| Music | 7 tracks + adaptive stems | see §8 |
| SFX/ambience | ~120 | doubled inventory: many need a "true" and a "distorted" variant |
| Words | ~60–80k (slice) | dialogue + debriefs + journals (which can lie) |

### 6.2 Authoring Pipeline
Ground-truth mission doc first (timeline, every NPC's real knowledge — every lie must be authored against a known truth), then level graybox → truth playtest *with distortions off* (the mission must be good sober) → affordance annotation → deck authoring → distortion playtests. Rule: **a mission that isn't fun with zero distortions is rejected**, because distortions multiply quality, they don't create it. Validator + fairness auditor run on every content commit (§10).

### 6.3 Localization
English first; **Czech as the authenticity-check second language** (names, documents, idioms vetted regardless of whether we ship the locale). All strings externalized from day one. One genuinely novel loc problem is ours alone: **`SubtitleDrift` pairs must be translated as pairs** — the true line and the drifted line, preserving a *plausible mishearing* in each target language. The loc kit therefore carries a "drift intent" note per pair (what kind of mishearing: phonetic, expectation-driven, name-swap), and the fairness auditor checks that no drift pair is orphaned by translation.

---

## 7. UX / UI Design
- Diegetic-leaning HUD: minimal; noise rings, suspicion pips over heads (day phase), Focus/Ground shown as breath UI. The HUD is on the *percept* side and thus distortable — within the bounded `HUDGlitch` set only (never health/ammo/inputs, §4.2).
- Hub screens: org/suspicion board (corkboard language), mind dashboard as Dr. Sova's worksheets, debrief as a form — paperwork as dramaturgy, our house aesthetic.
- Afterimage Theater: split view, op timeline, per-mission honesty report, shareable exports (§4.12).
- Screen inventory (slice): main menu · content/safety setup · hub (5 sub-screens: board, mind, loadout, phone, sleep) · day scene · night HUD · dialogue panel · debrief form · Theater · pause/settings · mission select (post-completion replay only — the campaign itself is linear-with-forks).
- Visual language: 2004 post-communist municipal — laminate, fluorescents, carbon-copy forms; muted palette that the percept layer can *slightly* wrong-foot (white balance as a tell at high stress — subtle, auditor-capped).

## 8. Audio Direction
Audio is half the psychology. Truth-layer sounds are dry and diegetic; distortion audio is *almost* identical — the design goal is 95% trust. Adaptive score: a cold synth-and-cimbalom palette (2004 Vranov: post-Soviet melancholia meets Eurodance leaking through club walls) that thins as stress rises rather than swelling — silence as symptom. Binaural detail work for headphone players; every audio distortion has a visual accessibility twin (§4.16). Implementation notes: audio events are truth-layer events with percept-side decoration (same architecture as visuals — one pipeline, not two); voice-count budget tested in the distortion-heaviest authored scene (White Night, §2.6).

---

## 9. Production Plan & Milestones (standalone)
No external dependencies: the foundation layer formerly assumed from Plan 01 is now **M0 of this project**. Calendar in part-time weeks; the ordering matters more than the dates. Total to slice: **~48 weeks part-time (≈10–12 months)**.

**M0 — Foundations (w1–6):** EventBus, GameStateStore, versioned SaveSystem, Predicate evaluator + tests, fixed-tick loop harness with input recording, **determinism CI from the first week** (§10). *Exit: a walking skeleton — inputs recorded in a stub scene replay tick-perfect on every platform target.*

**M1 — Truth Skeleton (w7–12):** TruthSim actors + physics-lite, sound propagation, first enemy archetype AI (Sentry, Professional), combat feel prototype in one graybox room; the §4.9 tuning checklist is this milestone's rubric. *Exit: a fight can be recorded and replayed tick-perfect, and the fight is already fun.*

**M2 — The Split (w13–17):** PerceptRenderer boundary; first 4 op classes (`SubtitleDrift`, `AudioSwap`, `PhantomAudio`, `PhantomEntity`); Ground verb; Clarity Mode stub; distortion VFX art direction locked. *Exit: a phantom fools a playtester once, and the replay proves it.*

**M3 — The Mind (w18–22):** MindModel with §4.4 math, DistortionDirector with deck loading, fairness auditor v1 enforcing the Charter statically, hub sleep/calendar loop. *Exit: two testers with different playstyles get measurably different distortion profiles from the same mission.*

**M4 — The Cover (w23–29):** dialogue DSL + compiler + runner (built to spec, §5.7), NPC minds + suspicion graph + gossip tick, day-phase social stealth verbs, debrief v1 with honesty modes. *Exit: a full day/night/debrief cycle plays end-to-end.*

**M5 — Mission One for Real (w30–35):** "Induction" at full quality (art, audio, deck), Afterimage Theater v1, remaining op classes + enemy archetypes. *Exit: the theater moment lands in playtests ("that's what happened?!").*

**M6 — Slice Complete (w36–43):** prologue + "The Listening Room" + "Smoke Test," hub cast dialogue, ending-hooks stubbed, difficulty/psych sliders, first full accessibility pass, localization pipeline proven on one scene pair.

**M7 — Polish & Slice Release (w44–48):** tuning from external playtests, sensitivity review implemented, content-safety toggles final, trailer built around one real, unstaged Afterimage comparison.

**Post-slice (full game):** missions 4–12 in three content batches (one per act), systems frozen except tuning; see §13.

---

## 10. Testing & Quality Strategy
- **Determinism CI (from M0, non-negotiable):** nightly re-simulation of a growing corpus of recorded runs; any divergence fails the build. Every headline feature depends on this wall standing.
- **Fairness auditor:** static analysis of decks, missions, and op placements against the Charter (§4.5) — no `EntityMask` on damage-capable actors, density/tier caps respected, every op class has Clarity/photosensitivity/accessibility substitutions, no orphaned drift pairs (§6.3), no dependency-dominant substance configurations (§4.4.5). Runs on every content commit.
- **Content validator:** every claim referenced by dialogue/debrief/endings exists; every HIDES unlock reachable; every load-bearing plot flag settable on every branch family; calendar lint (mission windows vs. hub blocks).
- **Headless bots:** soak combat for crashes; **"paranoid bot"** grounds constantly and **"credulous bot"** never does — both must finish every mission (proves distortions are never mandatory-lethal knowledge); a **"liar bot"** fabricates every claim to smoke-test the consequence graph.
- **Human playtests instrumented via the event log:** we can literally watch where players believed a phantom, measure each op instance's dramatic intent (§4.2) against observed reaction, and tune decks with data. Slice playtests: 2 internal rounds (M5, M6), 1 external round (M7).
- **Psychological-content review** with the external consultant before slice release; their notes are tracked issues, not suggestions.
- **Definition of done (every system):** unit tests or determinism-corpus entry, auditor/validator coverage if content-facing, accessibility pass if player-facing, and a one-page doc in `/docs`.

## 11. Team, Budget & Marketing

### 11.1 Team shape (assumed)
Two-person part-time core: **systems designer/programmer** and **writer/designer** (roles overlap; the pipeline in §6.2 splits cleanly along the engine/content boundary). Contracted: 2D artist (sprites, portraits, tilesets — engaged from M2 for VFX direction, M5 for production), composer/sound designer (M5–M7), sensitivity consultant (M6–M7), external playtesters (M7). Everything in this plan is scoped to this shape; if the team grows, missions 4–12 parallelize, the slice plan does not change.

### 11.2 Budget posture
Part-time labor is the real cost and is sweat-funded. Cash outlay concentrates in: contracted art (the largest line), audio, consultant fees, and store/tax/legal boilerplate. The slice is deliberately *demo-able* (prologue + mission 1 as a public demo) to support funding applications or a publisher conversation after M7 — but the plan does not depend on external money to reach M7.

### 11.3 Legal & licensing posture (settled now)
Engine MIT (Godot), fonts OFL only (art_direction §6), no proprietary middleware anywhere by design (tech D10), all authored assets original with contractor agreements assigning IP; tool licenses (Aseprite etc.) are paid per seat. Music is commissioned work-for-hire — no licensed period tracks (the 2004 Eurodance "leaking through club walls" is pastiche we own). Store/tax/company boilerplate is a scheduled M7 task, not an afterthought. **Working-title note:** see the title-collision risk in §12 — a naming decision is due at M5, before any public-facing material ships.

### 11.4 Marketing beats (built from systems, not promises)
- **The trailer is one real Afterimage comparison**, unstaged, captured from a playtest run (M7 exit).
- **Shareable honesty reports** (§4.12) as organic word-of-mouth: players posting their own discrepancy summaries is the community loop.
- **Streamer mode** (§4.12) makes the Theater reveal a content segment.
- Store-page framing: lead with the two-layer premise and the fairness promise together — "the game lies to you and then proves it" is the whole pitch, and it is true.

## 12. Risks & Mitigations
| Risk | Severity | Mitigation |
|---|---|---|
| Distortions read as cheap or gimmicky | High | Fairness Charter as law, enforced by tooling; missions must work sober (§6.2); disclosure via Theater converts trickery into trust |
| Determinism breaks under engine updates/float drift | High | fixed-point in sim core, determinism CI from M0 week one, engine version pinning per milestone with gated upgrades (§5.1) |
| Combat feel mediocre (we're systems people, not action veterans) | High | M1 dedicates a full milestone to feel before any psychology, with an explicit tuning rubric (§4.9); external playtesters early; scope combat depth down before cutting readability |
| Psychological themes handled exploitatively | High | sensitivity consultant with tracked issues, granular toggles, no diagnosis-naming, moral injury modeled with respect (confession mechanics, not "insanity meter") |
| **Standalone foundation work blows the calendar** (the cost Plan 01 was meant to absorb) | High | M0 is deliberately small and boring — six weeks of well-specified, pre-designed plumbing (§5.7); its exit criterion is binary; any slip here reprices the whole plan *early*, which is the point of doing it first |
| Two-person team single-point-of-failure / burnout | Medium | milestone exits are demo-able states (safe pause points); content/engine split means either half can idle without blocking the other; scope valve is mission count, never system honesty |
| Two-layer rendering doubles content cost | Medium | ops as decorators/shaders, not duplicated assets; distorted-variant budget capped in §6.1 |
| Debrief/claims complexity balloons the consequence graph | Medium | consequence channels fixed at four (§4.10); liar-bot smoke tests; plot flags budgeted per mission in the ground-truth doc |
| Player confusion between the two phases' rulesets | Low | strict visual grammar per phase; prologue teaches them separately before mixing (§4.20) |
| **Title collision:** "Afterimage" is already a released 2023 metroidvania — discoverability and trademark risk | Medium | *Afterimage* stays the working title/codename; a naming decision (keep with a strong subtitle — e.g. *Afterimage: Vranov* — or retitle; candidates riffing on the fiction: *Ground Truth*, *The Debrief*, *Percept*) is a scheduled M5 deliverable with a trademark/storefront search, before any public asset ships (§11.3) |

## 13. Post-Slice Roadmap (full game)
- **Act batches:** missions 4–6, 7–9, 10–12 authored in three passes with a playtest between each; systems frozen at M7 except tuning constants and new op *instances* (no new op classes after the slice without a design review — the taxonomy is the contract).
- **Cut lines, pre-agreed:** if the full game must shrink, missions merge within acts (12→9 floor); ending families never cut; hub cast trims before mission count does.
- **Ports/localization:** Czech locale decision after slice reception; console ports evaluated only post-1.0 (the determinism core makes porting tractable but it is not free).
- **Plan 03 note:** the closing thought of v1 stands — a third design should someday ask what happens when the truth is known by everyone and matters to no one. A fight for another document.

## 14. What We Build First (immediate next steps, in order)
1. ~~Ratify the document set~~ — **done**: this plan, `tech_guidelines.md`, `foundation_blueprints.md`, `art_direction.md`, `ux_charter.md`.
2. ~~Story-bible timeline + prologue/slice mission ground-truth outlines~~ — **done**: `story_bible.md` (full ground-truth docs deepen from those outlines during each mission's authoring pass, §6.2).
3. **Repo scaffold per §5.8** and the M0 walking skeleton: EventBus, GameStateStore, Predicate evaluator, fixed-tick harness, determinism CI. First line of code is a test. Work items: `roadmap.md` M0.
4. **Graybox the combat room** (M1 prep): one space, Sentry + Professional, the §4.9 checklist printed and taped to the monitor.
Development now tracks against **`roadmap.md`** — the milestone backlog with acceptance criteria and the definition-of-ready-to-code checklist.

---

*End of Plan 02, expanded edition. The arc the two documents describe survives the shelving of the first game:* The Quiet Ledger *asked whether you can find the truth in a lying world, and its answer — its architecture — is now the foundation under this game.* Afterimage *asks whether you can report the truth with a lying mind. Build the truth layer first. Everything else is perception.*


