# 10 · Feature 008: Godot and game architecture (2026-10-28 to 2026-10-29)

The project now has written architecture rules and a third reviewer that checks code against them.
A guide with 20 rules says how "Der Computerladen" is built in Godot; a read-only agent checks plans
and code against it; a test measures what can be measured on every run. The existing code was
reviewed against the guide and fixed without changing behaviour. Checklist 19 points, analysis 18
recommendations, seven phases, the last one from a gap search after the build.

**Tokens and cost:** 2026-10-28 to 2026-10-29 on `feature/008-architektur`: 1.2 M output, 2,556 input, 5.3 M cache write, 284.4 M cache read; 499 responses from Claude, 702 from sub-agents; about $112 at API list price.

### 2026-10-28 · One architecture guide with numbered rules `[Architecture]`

- **Decision:** All architecture rules live in one file, `docs/architektur-leitfaden.md`, as rules
  AR-01 to AR-20. Each rule has eight parts: statement, reason, example from the code,
  counter-example, source, layer, how it is checked, and status. Five of them are the Godot
  principles: a core without nodes, signal up and call down, few autoloads, data as resources,
  scenes built from scenes. I decided all 20 in one review of the draft.
- **Alternatives:** Rules spread over the constitution, the game description and the agent's
  instructions; asking me rule by rule.
- **Why:** A reviewer needs one yardstick with fixed numbers, so a finding can say "AR-02" and
  everyone knows what is meant. Asking only where there were real alternatives kept the review short.
- **Evidence:** `e26f84e`, `specs/008-architektur/research.md` (R1, R2, R12).

### 2026-10-28 · The event catalog stays JSON, as a documented exception `[Architecture]`

- **Decision:** The guide says game data should be Godot resources. The event catalog stays a JSON
  file, written by the Werkstatt, and is listed as a justified exception to AR-04. Every exception
  carries a comment `# Ausnahme AR-NN: …` at its place and a line in the guide's table.
- **Alternatives:** Converting the catalog to `.tres` resources.
- **Why:** The Werkstatt reads and writes the file, the constitution expects it as a file, and Git
  shows every change readably. An exception with a reason is better than a rule nobody keeps.
- **Evidence:** `e26f84e`, `docs/architektur-leitfaden.md` (table "Ausnahmen").

### 2026-10-28 · A third reviewer for architecture, tested with planted mistakes `[Workflow]`

- **Decision:** Next to the style and text reviewers there is now an architecture reviewer
  (`.claude/agents/architektur-pruefer.md`). It only reads and reports each finding with place,
  rule and evidence. Before I trusted it, Claude planted five violations in eight sample files; it
  found all five with the right rule and flagged none of the allowed places. Constitution 2.3.0
  makes the review part of every phase that changes code, and of every plan at the checklist.
- **Alternatives:** Claude checking architecture alone; reviewing only at the end of a feature.
- **Why:** The style and text reviewers had found things Claude missed. The planted mistakes showed
  the new one does the same before it got real work.
- **Evidence:** `dbf7efc`, `specs/008-architektur/fehlerprobe/`, `docs/ki_workflow/ki_pruefung.md`
  ("Nachmessen").

### 2026-10-28 · Reviewing the whole existing code once `[Architecture]`

- **Decision:** The reviewer read all 76 scripts, scenes and resources of the game and the Werkstatt
  in three runs: core, game and interface, tools. Claude checked every finding against the code.
  I decided all of them as recommended: 13 fixes in this feature, one exception, and two larger
  clean-ups as features of their own, 11-09 (shared code in `core/` and `ui/`) and 11-10 (decouple
  the Werkstatt).
- **Alternatives:** Only checking new code from now on; fixing everything in this feature.
- **Why:** New code would copy old patterns otherwise. Large refactors in one go would mix too much
  into one feature.
- **Evidence:** `55fcd84`, `specs/008-architektur/bestandsbericht.md`,
  `docs/features/Feature_Ideas.md` (11-09, 11-10).

### 2026-10-28 · A test that measures the rules on every run `[Architecture]`

- **Decision:** `src/test/test_architektur.gd` checks what can be measured: cores without nodes,
  autoloads or global randomness (AR-01, AR-08), exactly the four autoloads (AR-03), no path up the
  scene tree (AR-02), the game never referencing the tools (AR-14). Known places to fix wait in a
  list `BIS_BEHEBUNG`; a second test fails when an entry no longer matches anything. After the
  merge of 007 the test was sharpened: `../` only counts in node paths, not in file paths.
- **Alternatives:** Leaving everything to the reviewer.
- **Why:** What a test measures, the reviewer can skip, and nobody has to remember it. The list of
  pending fixes had to be empty at the end, and it is.
- **Evidence:** `dd636d7`, `dc8ada1`, `specs/008-architektur/contracts/architektur-tests.md`.

### 2026-10-28 · Rules for tools, decided on the code of Feature 007 `[Architecture]`

- **Decision:** After 007 was merged, the reviewer checked its self-test code. Its findings led to
  rules for tools: a tool may have its own text class; only one place, the driver, may operate the
  game through the names of inner nodes; an object that touches the scene tree is a "helper of the
  shell", not a core, and says so in its header; scripts outside `src/` name their Godot source in a
  comment.
- **Alternatives:** Treating tools exactly like game code; leaving tools unregulated.
- **Why:** The self-test has to reach into the game in ways game code must not. Writing down where
  that is allowed keeps it in one place.
- **Evidence:** `4fe1b9c`, `docs/architektur-leitfaden.md` (section "Werkzeuge", "Geschichte").

### 2026-10-29 · Fixes without changing behaviour, measured before and after `[Workflow]`

- **Decision:** Before the fixes, Claude recorded the test count, the start check, the schedules for
  seeds 1, 4711 and 99999 in every difficulty, and two save games made by a script. I also made a save
  of my own in the real game. After each part of the fixes everything had to be identical: schedules
  byte for byte, both saves loading the same, the self-test on the Mac 45 of 45 with every photo
  unchanged. The fixes themselves replace groups of flags with explicit states (`enum`), add seams
  that tests can set, and keep each value in one place.
- **Alternatives:** Trusting the unit tests alone.
- **Why:** A refactor must not change the game. The schedules and saves show that the timeline and
  the save format are untouched; the self-test shows the title screen behaves the same.
- **Evidence:** `7ad50c1`, `e6321f6`, `dd93a09`, `bdb697e`, `97f0238`;
  `specs/008-architektur/lernnotizen.md` ("Phase 5").

### 2026-10-29 · The guide grows with each review `[Architecture]`

- **Decision:** Every review that found a gap in the guide ended with a decision from me, and the
  rule got a sentence more: what counts as a collection of flags, who a "read only" comment binds,
  that private copies of the same helper count as a value in two places, that a tool name in a
  comment is not a reference. The old wording of each rule stays in the section "Geschichte".
- **Alternatives:** Fixing the code and leaving the guide as it was.
- **Why:** The reviewer reported fewer gaps the more of them were in the guide: five to nine per run
  in the first review, none in the last.
- **Evidence:** `4fe1b9c`, `bdb697e`, `docs/architektur-leitfaden.md` ("Geschichte").

### 2026-10-29 · A local Godot reference instead of an online service `[Tools]`

- **Decision:** `tools/godot_referenz/erzeuge.sh` writes the class reference of the installed Godot
  4.7.2 into `godot_referenz/klassen/`, one XML file per class. It is generated, not committed. The
  Godot agent, the reviewer and Claude look up class names, methods and signals there instead of
  answering from memory. For now it holds signatures only; the descriptions need a download from
  the Godot source and wait for my permission.
- **Alternatives:** A service like Context7; committing the files; downloading the descriptions
  right away.
- **Why:** The reference matches the exact version in use and works offline. Wrong method names
  from older Godot versions are the most common mistake, and the signatures already prevent them.
- **Evidence:** `5c9f142`, `1ea6c81`, `specs/008-architektur/lernnotizen.md` ("T039a").

### 2026-10-29 · A gap search that also checks the workflow documents `[Workflow]`

- **Decision:** After the build, a gap search compared spec, plan and tasks with the repository. It
  found no gap in the code but eleven in documents, templates and the review skill. The most
  important: the task template had no phase review for the phase where cores usually appear. They
  became a phase of their own, which I released.
- **Alternatives:** Ending the feature after the acceptance of the fixes.
- **Why:** The next feature is written from these templates. A missing line there would mean the new
  reviewer is simply not asked.
- **Evidence:** `7ea84f8`, `specs/008-architektur/tasks.md` ("Phase 7: Convergence").
