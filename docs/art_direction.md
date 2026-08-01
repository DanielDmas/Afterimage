# AFTERIMAGE — Art Direction Bible
**Document type:** Visual identity + beauty standards. Companion to `master_plan.md` (§7–8) and `tech_guidelines.md` (§4, §8).
**Purpose:** so that "beautiful" is a specification, not a hope. Every visual decision an artist or programmer faces during production should be answerable from this document.

---

## 1. Vision Statement — *Sodium Light and Carbon Paper*

Vranov, 2004, is two cities. By day it is **carbon paper**: municipal laminate, fluorescent offices, ochre folders, the smell of toner — a world of surfaces that record things. By night it is **sodium light**: orange streetlamps on wet asphalt, club neon leaking under doors, headlights sweeping a warehouse wall — a world of surfaces that hide things.

The game's beauty lives in the tension between those two palettes and in one rule above all others:

> **The world must be beautiful enough to trust.** The player's relationship with our image is the game's core mechanic — they must *want* to believe their eyes. We are not making "glitchy horror art." We are making a warm, precise, humane-looking world, so that when it lies, the lie lands.

Three beauty priorities, in order, that resolve every conflict:
1. **Readability** — the player parses any frame in one glance (P2 in the master plan).
2. **Atmosphere** — the frame carries mood: time of day, temperature, era.
3. **Spectacle** — flourish is welcome only after 1 and 2 are paid.

## 2. World Rendering — Hi-Bit Pixel Art

- **Format:** hi-bit pixel art at 640×360 logical resolution (tech D6): pixel-crunchy sprites, but with modern lighting, normal maps, unrestricted palette, and smooth sub-pixel camera motion. The reference feel is contemporary hi-bit (crisp, lit, deliberate), not retro-console pastiche.
- **Grid & proportions:** 16 px world grid; characters ~26–30 px tall (2-head proportions with strong silhouettes); door/prop scale honest to the grid. Top-down at a slight southern tilt (front faces visible — faces matter in this game).
- **Silhouette law:** every character class readable by silhouette alone at 100% zoom in darkness — tested as flat black shapes before any detailing is approved. Enemy archetypes (master_plan §4.9) each own one silhouette signature (the Heavy's coat, the Runner's lean, the Technician's slung gear).
- **Animation principles:** sprite animation at 10–12 fps with strong key poses (snap and weight over smoothness); engine-side motion (camera, tweens, shadows, light) fully smooth. Contrast between chunky sprite and silky light *is* the look. Walk cycles are characterization — Radek's swagger vs. Eliška's economy is an animation deliverable, not a metaphor (master_plan §2.3).
- **Violence rendering:** brief, heavy, unglamorous. Muzzle flash lights the room for 2 frames (a lighting event, not a sprite event); bodies fall and *stay*, rendered with the same care as furniture — the point of a body is that it persists.

## 3. Light — the Real Protagonist

- **One ambient + practicals.** Every scene has a single authored ambient level and light *sources with diegetic owners*: lamps, monitors, signage, headlights, a cigarette. No unmotivated light. Turning lights off is gameplay (master_plan §4.9), so light must always read as a *thing in the world*.
- **Day grammar (carbon paper):** high ambient, low contrast, warm paper whites and institutional greens; shadows soft and short. Beauty by texture: grain of paper, moiré of a monitor, dust in a sunbeam by the archive window.
- **Night grammar (sodium light):** low ambient, high contrast; three canonical night colors — **sodium orange** (street), **fluorescent green-white** (interiors that never sleep), **signage teal/red** (club bleed). Wet-surface speculars via normal maps. Darkness is never flat black: it is deep blue-brown with visible film grain, so the eye keeps searching it.
- **Distortion neutrality rule:** distorted content receives **no color/lighting tell whatsoever** (that is Clarity Mode's job, and only its job). A phantom is lit exactly as the room lights it. Our shaders must make lies *indistinguishable*, and the reveal shaders make truth *arrive* gorgeously — the beauty budget of the whole VFX stack is spent on the moment of Grounding, not on the lie.

## 4. The Grounding Reveal & Distortion VFX (the crown jewels)

The Ground verb is the game's signature image; it must be the most beautiful thing we ship.
- **Breath choreography:** the 2.5 s hold is scored to Eliška's breath (audio + a soft radial UI that inhales/exhales). The world *stills* slightly — ambience ducks, camera drift stops.
- **The reveal:** phantoms don't "pop" — they **exhale out of existence**: a one-second dissolve like breath fading from glass, particles falling with gravity (the lie had weight, and it leaves). Geometry corrections **slide** true with an architectural shear, not a cut. False subtitles are struck through by an invisible hand and retyped — typewriter sounds, carbon-paper aesthetic (§6).
- **On-empty grounding** (nothing was false): the whole frame takes a single quiet breath — a 2% saturation bloom and settle. The world holding is also an image; verification deserves beauty too.
- **Screenshake budget:** ≤ 3 px, ≤ 150 ms, translational only, reserved for truth-layer impacts (shotgun, breach). Distortions never shake the screen — lies are quiet.
- **Photosensitivity:** all flicker-class effects live inside the shader library's capped constants (tech §4); the photosensitivity-safe toggle substitutes dissolves for any strobing texture with zero content loss.

## 5. Color Script

- **Campaign arc:** Act 1 leans day/carbon (the job is still paperwork); Act 2 tilts to night/sodium as the cover deepens; Act 3 is almost all night, with day scenes rendered *too* bright — overexposed, like insomnia. This is a authored per-mission ambient script, not a filter.
- **Mind-state grading (bounded):** at stress/fatigue Crisis bands, the percept layer may shift white balance ±5% and lift grain — subtle, auditor-capped (master_plan §7), and always *plausible as the world* (a fluorescent hum, a colder morning). Never a "sanity filter."
- **Palette anchors (hex, for consistency across artists):** carbon paper `#E8E0CE`, folder ochre `#C9A96A`, municipal green `#7A8B6F`, sodium orange `#E89440`, night base `#1A1E2A`, fluorescent white `#DDE8DC`, club teal `#3FB8AF`, blood (used sparingly, matte) `#7E2D26`, Eliška blue-grey `#8C9BAB`, Radek leather brown `#6B4A38`. The full ramps are derived from these ten and live with the tileset sources.

## 6. Typography & Paperwork (the UI's soul)

- **Two typefaces, both OFL-licensed:** a humanist grotesque for UI/subtitles (candidates: *Inter* or *IBM Plex Sans*; pick once at M2, record in the theme) and a typewriter face for all diegetic paperwork (candidates: *Special Elite* or an OFL equivalent with full Czech diacritics — diacritics coverage decides). UI text renders at native resolution over the pixel-art world (tech §4): crisp type on chunky world is our signature frame.
- **Paperwork as dramaturgy, rendered lovingly:** the debrief form, Sova's worksheets, and the org board are *objects*: paper texture with tooth, typewriter impressions with ink-bleed, carbon-copy duplicates (the *player's* copy is the smudged one — Doubek keeps the original; let the UI say that), rubber stamps that land with weight and a hair of rotation, a coffee ring that appears on the form of the mission where Doubek stopped sleeping. Detail is characterization.
- **Subtitles:** high-legibility grotesque, background plate optional, speaker-colored underlines (colorblind-safe, shape-coded too). `SubtitleDrift` corrections use the strikethrough-retype animation (§4) — the correction must be *satisfying to watch*, because we will be watching it a hundred times.

## 7. Motion & Interface Feel

- **Motion standards (theme constants, tech §8):** micro-interactions 120 ms, panel transitions 180 ms, scene transitions 300 ms; easing `cubic-out` for arrivals, `cubic-in-out` for moves; nothing bounces (this is not a bouncy world). Every animation is interruptible by input — the UI never makes the player wait for a flourish.
- **Every input acknowledged** within 100 ms by something physical: a key-click of the typewriter, a paper slide, a stamp thunk, a breath. The UI sound palette is 100% physical/diegetic (paper, wood, brass, breath) — no synth bleeps anywhere in menus.
- **Screen inventory grammar:** each screen owns one physical metaphor and never mixes: hub board = corkboard, mind = worksheet, debrief = form, loadout = table surface (top-down flat-lay of the actual kit — beautiful and informative), Theater = two projected film frames with a mechanical scrubber that *clacks*.
- **Loading:** hub→mission masked by a diegetic beat (the drive there: streetlights strobing across a windshield, 3–5 s, skippable when load completes early). Death→retry ≤ 3 s, near-instant cut to the encounter's start breath — failure never gets ceremony.

## 8. The Afterimage Theater — the Beauty Deliverable

The Theater is the trailer, the poster, and the thesis; art-direct it like a title sequence:
- Dual panes framed as **two strips of the same film**, sprocket holes and all; the truth strip is cooler and cleaner, the percept strip carries the mission's grade — *labeled by frame, not by look* until an op is selected.
- Selecting an op draws a thin red thread between the two panes at that moment (corkboard language migrating into the cinema — the house style closing its loop).
- The honesty report is typeset as a **carbon-copy triplicate**; the shareable export (master_plan §4.12) is auto-composed on the triplicate with the mission title stamped — designed to look great at phone-screen size, because that is where it will be seen.

## 9. Marketing & Identity Consistency
- Logo: the word AFTERIMAGE set in the grotesque, with one letter's ghost offset a few pixels — the entire premise in one typographic gesture; renders in 1-bit for stamps and favicons.
- Key art motif: one figure, two shadows disagreeing.
- Store/trailer assets are captured in-engine at 3× integer scale, never mocked up — the game must be its own key art (P6: what we show is what runs).

## 10. Art Production Standards
- Sources: Aseprite (`.aseprite` files versioned alongside exported `.png` in LFS); tilesets and character sheets follow the naming/layout conventions in `/docs/pipelines/` (created at M2 with the first asset batch).
- Normal maps generated per-asset via a documented Laigter/tool preset, then hand-corrected where light matters (faces, weapons, door frames).
- Every asset ships with its palette-compliance check (the ten anchors, §5) and a dark-scene readability screenshot in the PR.
- Review ritual: art PRs include one in-engine screenshot at 100% zoom in the darkest authored scene the asset appears in. If it reads there, it ships.
