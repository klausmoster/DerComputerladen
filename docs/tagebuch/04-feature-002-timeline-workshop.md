# 04 · Feature 002: Timeline and Werkstatt (2026-10-20 to 2026-10-21)

The prototype's event engine was replaced by a schedule that can be computed in advance, and I got
a workshop tool to maintain the events. The planning steps found a lot: the review 36 points, the
analysis 40 findings, before a line of code was written.

### 2026-10-20 · The schedule model `[Architecture]`

- **Decision:** Catalog, then a schedule per game, then playback, then signals. Each game has one
  seed, each event its own die. Changes are interventions on top of the schedule, never overwrites.
  The core runs without a game.
- **Alternatives:** Extending the old engine.
- **Why:** The old engine had no plan you could look ahead into.
- **Evidence:** `2a90ce7`, `specs/002-zeitleisten-werkstatt/spec.md`.

### 2026-10-20 · A core without a node, an autoload as its shell `[Architecture]`

- **Decision:** The core (`TimelineRun`) is a plain class without a node. The autoload `Timeline`
  only turns its reports into five signals. The timeline still applies no effects.
- **Alternatives:** Logic inside the autoload; the core as a node.
- **Why:** The same code runs in the game, in the tests and in the Werkstatt, without a running
  clock.
- **Evidence:** `1f9084f`, `specs/002-zeitleisten-werkstatt/research.md` (R1, R12).

### 2026-10-20 · The Werkstatt is a scene, the catalog is JSON `[Tools]`

- **Decision:** I maintain the events in a workshop scene inside the project, editor and simulator
  in one. The catalog is a single JSON file with sorted keys, English keys and German texts.
- **Alternatives:** An editor plugin, the inspector, Obsidian with an export; one file per event.
- **Why:** Every changed field changes exactly one line in the diff.
- **Evidence:** `2a90ce7`, `specs/002-zeitleisten-werkstatt/research.md` (R3, R13).

### 2026-10-20 · The event catalog leaves the Game Bible (constitution 2.1.0) `[Architecture]` `[Game content]`

- **Decision:** The event catalog is an exception to the rule that game data lives in the Game
  Bible. It sits in the game project and is maintained with the Werkstatt.
- **Why:** The Werkstatt must read and write it, and events need exact days, not just months.
- **Evidence:** `3f389ff`, `.specify/memory/constitution.md` (principle V).

### 2026-10-20 · Reproducible randomness `[Architecture]`

- **Decision:** Every event and purpose gets its own random generator, seeded from the game seed,
  the purpose and the event ID. The same Godot version is enough guarantee for the same results.
- **Alternatives:** A shared random generator; Godot's `hash()`, which is not stable.
- **Why:** Every outcome depends only on seed, event and time.
- **Evidence:** `specs/002-zeitleisten-werkstatt/research.md` (R5).

### 2026-10-20 · The Werkstatt gets its own, plainer style `[Graphics]`

- **Decision:** The Werkstatt uses full resolution and a normal font (Open Sans SemiBold) in the
  shop's colours, with seven category colours. The style guide got a section "Werkzeuge" for it.
- **Alternatives:** A plain tool without any style.
- **Evidence:** `96d0bec`, `specs/002-zeitleisten-werkstatt/spec.md`.

### 2026-10-20 · The game starts in a window `[Architecture]`

- **Decision:** Feature 001 had the game start in full screen. I changed that during the acceptance
  of the Werkstatt.
- **Why:** On macOS, starting in full screen forced the Werkstatt into full screen too.
- **Evidence:** `specs/001-hauptmenue/spec.md` (Clarifications), `specs/001-hauptmenue/research.md`
  (R2).

### 2026-10-21 · Statistics in small time slices, no threads `[Architecture]`

- **Decision:** Statistics over many games run in slices of 15 ms per frame on the main thread.
- **Alternatives:** Threads or the worker thread pool.
- **Why:** Threads are a minefield for a learner.
- **Evidence:** `cbf6ff8`, `specs/002-zeitleisten-werkstatt/research.md` (R17).

### 2026-10-21 · Trackpad gestures are desktop input (constitution 2.1.1) `[Architecture]`

- **Decision:** No touch, but panning and pinching on the trackpad are allowed, for the timeline
  view in the Werkstatt.
- **Evidence:** `0460ee1`, `.specify/memory/constitution.md`.

### 2026-10-21 · The gap search becomes a rule `[Workflow]`

- **Decision:** No final acceptance without a gap search first.
- **Why:** In this feature the gap search found 14 gaps, two of them contradicting the spec,
  although all tests were green.
- **Evidence:** `4b3fc58`, `docs/ki_workflow/ki_dev.md` (item 6).

### 2026-10-21 · No local memory, open points in the repo `[Workflow]`

- **Decision:** Claude keeps no local memory. Whatever should last goes into a file in the repo, and
  Claude's own decisions are marked as such in `docs/offene-punkte.md`.
- **Why:** Decisions must not be made silently.
- **Evidence:** `a967a54`, `docs/ki_workflow/README.md`, `docs/offene-punkte.md`.

### 2026-10-21 · A blueprint for working with AI `[Workflow]`

- **Decision:** `docs/ki_dev.md` collects the rules that have proved themselves, each with its
  reason, as a template for later projects.
- **Evidence:** `cbf6ff8`, `docs/ki_workflow/ki_dev.md`.

### 2026-10-21 · Questions to me always as a choice `[Workflow]`

- **Decision:** Claude asks me one question at a time, with options and the recommendation first.
- **Evidence:** `9d59841`, `docs/ki_workflow/ki_dev.md`.
