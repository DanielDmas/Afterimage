# AFTERIMAGE
*A psychological action thriller about a mind you cannot trust — including yours.*

Top-down 2D action thriller (Godot 4). You are an undercover officer inside a criminal intelligence firm in Vranov, 2004. The engine simulates the **true** world on one layer and renders only what your character **believes** on another — and after every mission, a replay theater shows you both, side by side.

**Status:** pre-production. Planning complete and ratified; no code yet. Development follows the milestone plan below — nothing is decided on the go.

## The document set

| Document | What it governs |
|---|---|
| [`docs/master_plan.md`](docs/master_plan.md) | The master development plan: design pillars, story bible, all systems (distortions, mind model, combat, debrief), architecture, milestones M0–M7, testing, risks |
| [`docs/tech_guidelines.md`](docs/tech_guidelines.md) | **Locked technology decisions** — engine pinning, determinism contract, data formats, audio/input/UI tech, CI, performance budgets. Change-controlled |
| [`docs/foundation_blueprints.md`](docs/foundation_blueprints.md) | Full specification of the foundation layer: EventBus, GameStateStore, predicate language, dialogue DSL, NPC minds, claims/provenance, validators & bots |
| [`docs/art_direction.md`](docs/art_direction.md) | The beauty bible: *sodium light and carbon paper* — palette, lighting, pixel-art specs, distortion VFX grammar, typography, motion |
| [`docs/ux_charter.md`](docs/ux_charter.md) | Player-experience standards: onboarding contract, respect-for-time rules, quality-of-life inventory, testable enjoyability metrics |
| [`docs/story_bible.md`](docs/story_bible.md) | **Spoiler-complete** narrative canon: fixed timeline (1993–2004), character voice sheets, gazetteer, ground-truth outlines for prologue + slice missions |
| [`docs/roadmap.md`](docs/roadmap.md) | The development backlog: milestone work items with acceptance criteria, and the definition-of-ready-to-code checklist |

Reading order for a newcomer: this README → `master_plan.md` §0–§3 → `ux_charter.md` → the rest as needed. (`story_bible.md` spoils the entire game — read deliberately.)

## Ground rules (from the plans, binding)
1. **Determinism is law** — the truth simulation replays tick-perfect, always (it's the save format, the bug report, and the Afterimage Theater).
2. **Fairness is auditable** — the distortion system obeys a hard charter, enforced by tooling, and every lie is disclosed after the run.
3. **Missions must be fun sober** — with distortions off, or they're rejected.
4. **Content is data** — no mission logic in engine code.
5. **Cruel game, kind product** — all friction is authored; none is accidental.

## Next steps (master_plan §14)
1. Ratify the document set (done — this commit).
2. Write prologue + mission 1–3 ground-truth docs and the story-bible timeline.
3. Repo scaffold + M0 walking skeleton (EventBus, state store, predicate evaluator, fixed-tick harness, determinism CI). *First line of code is a test.*
4. Graybox the combat room (M1 prep).
