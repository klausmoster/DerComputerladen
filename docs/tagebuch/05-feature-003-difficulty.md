# 05 · Feature 003: Difficulty levels (2026-10-21 to 2026-10-26)

Three difficulty levels on top of the schedule. In parallel I set up reviewer agents and moved the
workflow documents into a folder of their own. Review 38 points, analysis 41 findings.

### 2026-10-21 · Levels shift chances, nothing else `[Game content]`

- **Decision:** Easy and Hard shift only the chances of probability events, through profiles of
  start modifiers. Medium is the catalog alone, without a profile. Counts and effect strengths may
  follow in a later feature.
- **Evidence:** `80834bf`, `specs/003-schwierigkeitsgrade/spec.md`.

### 2026-10-21 · Profiles live in the catalog `[Architecture]`

- **Decision:** The profiles are a section of the event catalog and are edited in a Werkstatt tab
  of their own. Seed and level are independent of each other.
- **Alternatives:** One seed per level.
- **Why:** With one seed per level, comparing levels would only show noise.
- **Evidence:** `specs/003-schwierigkeitsgrade/spec.md` (Clarifications),
  `specs/003-schwierigkeitsgrade/research.md` (R7).

### 2026-10-21 · One Claude session per feature `[Workflow]`

- **Decision:** Every feature gets its own Claude session, at first from the plan onwards.
- **Why:** One session had carried feature 001, the start of 002 and the spec of 003, and lost
  details each time it was summarised.
- **Evidence:** `72b743a`, `docs/ki_workflow/ki_dev.md` (item 7).

### 2026-10-22 · The shipped catalog has filled profiles `[Game content]`

- **Decision:** The catalog that ships with the game must contain filled profiles, checked by a
  test. Claude proposed the starting values.
- **Alternatives:** Filled profiles without a test; filling them later during balancing.
- **Evidence:** `92ef1ce`, `specs/003-schwierigkeitsgrade/research.md` (R18).

### 2026-10-22 · Reviewer agents, kept simple `[Workflow]` `[Tools]`

- **Decision:** I asked for dedicated reviewers. Two agents, `stil-pruefer` and `text-pruefer`,
  check a phase against the style guide; the skill `dcl-phasenpruefung` runs them, and Claude
  checks every finding. Anything measurable is checked by tests instead (`test_bilder.gd`,
  `test_texte.gd`). Start simple, specialise by standard rather than by role, check at fixed points.
- **Alternatives:** A hook that runs on every agent stop; postponed until the agent twice delivers
  red tests without saying so.
- **Why:** Anthropic's "Building effective agents" advises starting simple; multi-agent systems
  cost about fifteen times the tokens. A trial run on feature 001 found three style errors the
  review had missed.
- **Evidence:** `20fd50c`, `00c4976`, `de74df3`, `ba19ae3`, `2290d6c`, `cbcc245`,
  `docs/ki_workflow/ki_pruefung.md`.

### 2026-10-22 · A tone of voice for the texts `[Game content]`

- **Decision:** Dry and ironic like "Das Amt", no jokes in the controls, period detail in moderation.
  The game says "du" to the player; customers, the bank and the authorities say "Sie" to the
  shopkeeper. This became the section "Sprache" in the style guide.
- **Evidence:** `b3d066a`, `docs/offene-punkte.md`.

### 2026-10-22 · A folder for the AI workflow `[Workflow]`

- **Decision:** `docs/ki_workflow/` holds the blueprint (`ki_dev.md`), the checks
  (`ki_pruefung.md`) and an entry page, with diagrams.
- **Evidence:** `5a5664d`, `7f371df`, `81ce4bf`.

### 2026-10-22 · Choosing the level belongs to "New game" `[Game content]`

- **Decision:** Players choose the level when they start a new game, which became feature 004.
- **Alternatives:** A later settings feature; a backlog number of its own.
- **Evidence:** `specs/003-schwierigkeitsgrade/research.md` (R19).

### 2026-10-26 · Fix every quickstart failure before acceptance `[Workflow]`

- **Decision:** The quickstart found three failures, two of them from feature 002. I had all three
  fixed in an extra phase before accepting the feature.
- **Evidence:** `ed6eff7`, `b8d801c`, `specs/003-schwierigkeitsgrade/tasks.md` (Phase 8).
