# AFTERIMAGE — Player Experience Charter
**Document type:** UX + enjoyability standards. Companion to `master_plan.md` (§3, §4.15–4.17, §7) and `art_direction.md` (§6–7).
**Purpose:** the game may be psychologically merciless; the *product* is never allowed to be. This charter defines what "user friendly and enjoyable" means, testably, in advance. The game distrusts its protagonist — never its player.

---

## 1. Experience Pillars

**X1 — Cruel game, kind product.** All friction is authored, diegetic, and meaningful (suspicion, fatigue, doubt). Zero friction is accidental (menus, loads, retries, unskippables). If a playtester is frustrated, we ask: did the *game* do that on purpose, or did the *product* do it by neglect? The second is always a bug.

**X2 — Respect for time.**
- A complete, satisfying session = **one operation cycle, 30–45 min**, with a clean save point at each cycle boundary. The game is honest about session length: the hub shows what a mission window will roughly cost before you commit.
- Save anywhere in hub; mission progress checkpointed at encounter boundaries; quit mid-mission resumes at checkpoint, always.
- **Death → retry ≤ 3 s.** Failure costs psyche and story, never ceremony or lost time (master_plan §3.2).
- All dialogue: skip-line on input; previously-seen scenes fast-forwardable on replay; **no unskippable sequence longer than 10 seconds exists anywhere in the game**, including the logo cards.

**X3 — Clarity before cleverness.** The player may doubt what they saw; they must never doubt *what the game wants from them or how to operate it*. Controls, objectives-as-expectations, and systems are taught once, well, diegetically — and are always re-consultable (Sova's worksheets double as the manual). Distortion never touches the controls tutorial layer, input prompts, or menus (Charter rule 3; tech D11).

**X4 — Every input lands.** ≤ 100 ms acknowledgment of any player action, in the physical UI sound-and-motion language (art_direction §7). Nothing the player does is ever swallowed silently — including invalid actions, which get a soft diegetic "no" (a pencil tap, a locked-drawer sound).

**X5 — The player chooses their pressure.** Two independent sliders (combat / psychological, master_plan §4.15), changeable any time, penalty-free, achievement-neutral. Clarity Mode and all content toggles are honorable ways to play, presented without stigma — the settings screen copy is written as carefully as the dialogue.

---

## 2. First Hour Contract (onboarding, specified)
The first hour decides everything. Targets, measured in playtests (§6):

1. **Minute 0–2:** cold boot → content-and-comfort setup (content toggles, subtitle size, brightness/audio calibration, control scheme detect) → main menu. One screen each, plain language, resumable later. Defaults are sensible; a player who holds "continue" through it all gets a good experience.
2. **Minute 2–10:** playing. The Cold Open starts in a controllable scene within 60 seconds of "New Game." **Time-to-first-meaningful-choice < 10 min.**
3. **Minute 10–30:** Ground taught and used; the game shows its trick once and proves it (mini-Theater, master_plan §4.17). The epistemic contract lands *before* the first real mission.
4. **Minute 30–60:** first full cycle (day → night → debrief) completed; first honest debrief filed; hub understood.
5. Exit criterion for the prologue in playtests: a new player can state, unprompted, (a) what Ground does, (b) that the game will lie and later prove it, (c) what the debrief is for. Three sentences, 90%+ of testers.

## 3. Moment-to-Moment Usability Standards
- **Menus:** any common action ≤ 2 layers deep; pause → quit-to-desktop ≤ 2 inputs with save confirmation only when there is genuinely unsaved progress. Settings changes apply live, no restart, no "apply" button where avoidable.
- **The hub never wastes steps:** all five hub screens one input apart (tab ring); the "next" action (advance to mission / sleep) is always visible and never buried.
- **Objectives-as-expectations:** the mission brief states what Argus/Doubek *expects* in plain human sentences (no quest-log verbiage); a re-readable brief is one button away in-mission. No breadcrumb trails, no objective markers in-world (design), but never mystery about *what was asked* (product).
- **Diegetic aids that keep beauty and usability aligned:** the daytime-memory minimap (master_plan §4.14), noise rings, suspicion pips — all information is in-world, shape-and-color double-coded, legible at 100% zoom on a Steam Deck screen (the readability reference device, tech §11.2).
- **Interruption-proof:** controller disconnect / focus loss / lid close = instant pause, zero state loss, resume where you were, in every mode including the Theater.
- **Error states:** a corrupted save is quarantined, not overwritten; the newest healthy autosave loads with a plain-language note. The game never destroys player progress to protect itself.

## 4. Quality-of-Life Inventory (committed, not aspirational)
Shipping in the slice: save-anywhere (hub) · 3 rotating autosaves + debrief save · ≤3 s retry · skip/fast-forward seen content · full remapping (M/K + pad) + hold/toggle alternates · both sliders live-adjustable · Clarity Mode · granular content toggles + substance-autopilot · colorblind-safe double coding · UI scale (4 steps) + subtitle size/plate options · screen-reader on all paperwork/menu screens · photosensitivity-safe mode · rumble slider · brightness/audio calibration · glyph set override · streamer mode (Theater spoiler hold-back) · language-independent iconography on all systemic tells.

Post-slice (full game): mission replay/select from campaign map · per-mission Theater exports gallery · input presets for one-handed play (evaluated with consultant at M6 — the verb set is small enough to make this real).

## 5. Enjoyability — What "Fun" Means Here, Testably
The game's pleasures, named, so we can tune toward them and test for them:
1. **Competence under pressure** (night): a clean infiltration or a survived collapse must *feel* authored by the player. Metric: post-mission self-report "that went wrong because of *my* read, not the game's" ≥ 80% agreement even on failed runs. (The Fairness Charter is what makes this score reachable.)
2. **Social performance** (day): playing Radek well should feel like being *good at something slightly wrong* — charm with a cost. Metric: players voluntarily replay day scenes to try other stances.
3. **Earned doubt** (the signature): the delicious specific unease of "…was that real?" — which only works if it's *rare*. Distortion frequency errs low; the director's budget is tuned so the median Act-1 mission has **1–3 percept events**, not a haunted house. Metric: playtesters report distortion moments as *memorable incidents*, recounted individually, not as ambient noise.
4. **The reveal** (Theater): the "THAT'S what happened?" laugh-gasp. Metric: unprompted Theater re-watching; export usage.
5. **Being known** (hub): Sova, Doubek, Tereza remembering — warmth as the counterweight that makes the paranoia legible. Metric: players name a hub character when asked what they liked.

Anti-fun tripwires (auto-investigate if seen in any playtest): grounding-spam (player grounds >8×/mission → doubt has collapsed into ritual; retune costs or density) · debrief box-ticking (claims filed without reading → consequence feedback too weak) · phase dread (players avoiding day *or* night phases → the loop's contract is broken, not the player).

## 6. UX Testing Protocol
- Every playtest round (master_plan §10) includes: first-hour protocol with think-aloud (targets in §2), session-exit questionnaire covering the five pleasures (§5), and telemetry from the event log: retry latencies, menu depth heatmap, Ground usage histograms, skip usage, slider changes, quit points.
- **The quit-point review is sacred:** every mid-session quit gets a written hypothesis (natural stop? confusion? frustration?) checked against the log.
- Accessibility passes are scheduled QA (M6, M7), run with the toggles *on* — Clarity Mode, photosensitive-safe, screen reader, toggle-inputs are play-tested as first-class ways to experience the game, not smoke-tested as switches.
- One standing rule for all UX findings: **we fix the product before we blame the player.**
