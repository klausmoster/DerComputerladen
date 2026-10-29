# 11 · Feature 009: Compatibility instead of Forward+ (2026-10-28 to 2026-10-29)

The game now draws with Godot's Compatibility renderer on all three systems, using OpenGL instead of
Vulkan, Direct3D 12 or Metal. The trigger was the finding from Feature 007: on my MacBook Pro 2015
with Windows in Boot Camp, Forward+ did not start and showed no message. Now the game starts there
with a double click, and the self-test gives the same 43 photos as the Mac on four machines: Mac,
Boot Camp, Linux and Windows in Parallels. The reference images did not change. Checklist 18 points,
analysis 6 findings, six phases, the last one from the gap search.

**Tokens and cost:** 2026-10-28 to 2026-10-29 on `feature/009-renderer-compatibility` and the
preparing branch `claude/009-renderer-compatibility-10f148`: 0.3 M output, 888 input, 1.2 M cache
write, 117.5 M cache read; 283 responses from Claude, 110 from sub-agents; about $37 at API list
price.

### 2026-10-28 · Compatibility on all three systems `[Architecture]`

- **Decision:** The game uses the Compatibility renderer on Windows, macOS and Linux. Everything
  only Forward+ can do (HDR, anti-aliasing of the whole image in 2D, compute) is not used. Drivers
  and fallbacks stay on Godot's defaults: OpenGL 3.3, on Windows ANGLE over Direct3D 11 when OpenGL
  is not good enough, on Linux/X11 OpenGL ES.
- **Alternatives:** Keeping Forward+; Compatibility only on Windows; a start option or an
  `override.cfg` the player has to know about.
- **Why:** Forward+ fails silently exactly where the target group plays, on older notebooks and on
  Macs with Windows. A pixel art game with a fixed palette at 640 × 360 needs nothing Forward+ adds;
  HDR or soft edges would even harm the picture. One renderer means one thing to test.
- **Evidence:** `d5771a8`, `docs/entscheidungen/renderer.md`; `c867405`, `src/project.godot`;
  the runs in `specs/009-renderer-compatibility/belege/`.

### 2026-10-28 · A feature of its own, not an addendum to 007 `[Workflow]`

- **Decision:** The switch got its own number with spec, plan and phases. Feature 007 was closed
  with Forward+.
- **Alternatives:** Claude recommended adding it to Feature 007, where the requirement and the open
  Windows run were.
- **Why:** The switch changes CLAUDE.md, the constitution and the style guide. That deserves its own
  spec and its own decisions, not a side note in the export feature.
- **Evidence:** `docs/entscheidungen/renderer.md` ("Entscheidung"); `d5771a8`.

### 2026-10-28 · Apple's OpenGL on the Mac, ANGLE only if needed `[Architecture]`

- **Decision:** On macOS the game uses Godot's default, Apple's OpenGL. ANGLE over Metal would only
  come if the Mac run showed differences; it did not.
- **Alternatives:** ANGLE over Metal from the start.
- **Why:** The default is the shorter way. A test start showed that Apple's OpenGL runs over Metal on
  Apple Silicon anyway ("OpenGL 4.1 Metal"), and that Godot's ANGLE on the Mac also runs over Metal,
  not over OpenGL as Godot's documentation says.
- **Evidence:** `1c0dba4`, `specs/009-renderer-compatibility/research.md` (R2);
  `specs/009-renderer-compatibility/belege/macos_2026-10-29_11-48-48/`.

### 2026-10-29 · First the rule, then the setting `[Workflow]`

- **Decision:** I decided the new wording first. Claude changed CLAUDE.md, the constitution (version
  3.0.0, a major step because principle I was redefined) and a sentence in the style guide. Only
  then did the agent switch the setting. The old rule stays visible with its date.
- **Alternatives:** Switching the setting first and fixing the rules at the end.
- **Why:** Otherwise one commit would have broken the constitution that applied at that moment, and
  every later plan would have been checked against an outdated rule.
- **Evidence:** `cf37246`, `.specify/memory/constitution.md`, `CLAUDE.md`; style guide version 66,
  "Raster und Auflösung".

### 2026-10-29 · The photos do not show the window, so we look at it `[Workflow]`

- **Decision:** Besides the self-test photos, every system gets a look at the real window: the dark
  start screen without Godot's logo, an odd window size with whole-number scaling and black borders.
  On the Mac Claude takes screenshots, for which I allowed screen recording; on Windows and Linux I
  look myself with a short checklist.
- **Alternatives:** Relying on the photos alone.
- **Why:** The reviewers noticed that the self-test photographs only the 640 × 360 image, not what
  the renderer paints around it. A changed renderer is exactly what could change that.
- **Evidence:** `6eeb110`, `specs/009-renderer-compatibility/checklists/review.md` (CHK016, CHK017);
  `9e18b02`, `specs/009-renderer-compatibility/tasks.md` (T021).

### 2026-10-29 · A blueprint to take the workflow to other projects `[Workflow]`

- **Decision:** The way I work with Claude becomes a blueprint of its own: one file without any
  reference to this game, with roles instead of names, modules to switch on or off, skeletons for
  `CLAUDE.md`, constitution, templates, agents and skill, the token script, and the steps to set up a
  new project. What only applies here moves into a project profile. For a new project I copy one file
  and say "set up the project from the blueprint". It also explains why we never run
  `/speckit-implement`: it builds all phases in one go, in the session itself, so the acceptance of
  each phase and the split between building and reviewing would be gone.
- **Alternatives:** keeping the workflow documents as they were, mixed with game details and
  presented as a template; a separate repository for the blueprint.
- **Why:** Memory in the repository, Spec Kit, the folders and the order of steps would fit any
  project, but until now they were tangled with Godot commands and anecdotes from single features.
- **Evidence:** `8da13ae`, `133c2ad`, [blaupause.md](../ki_workflow/blaupause.md),
  [projekt.md](../ki_workflow/projekt.md).

### 2026-10-29 · The blueprint tested on an empty project `[Workflow]`

- **Decision:** A fresh agent that knew nothing of this project set up an invented one, a web app for
  a club's membership fees, using only the blueprint, and reported every gap. The first run found 22,
  among them a step that could not be done and an example that contradicted the blueprint itself.
  After a revision the second run got through to a working setup and found 21 smaller gaps. Both went
  into version 0.3; a third run I left out. Two findings hold for this project too: our task template
  still calls tests optional and says "commit after each task", and Spec Kit updates never reach our
  own templates. They are open points.
- **Alternatives:** reviewing the blueprint by reading it myself.
- **Why:** Whoever writes a blueprint knows too much to see what it leaves out. Only someone without
  that knowledge can show whether one file is enough.
- **Evidence:** `133c2ad`, [blaupause.md](../ki_workflow/blaupause.md) ("Änderungen"),
  [offene-punkte.md](../offene-punkte.md).

### 2026-10-29 · Tests and owners hold even against Spec Kit `[Workflow]`

- **Decision:** Our task template no longer calls tests optional, puts the owner `[K]`, `[A]` or
  `[C]` right after the task number, commits once per accepted phase instead of after each task, and
  drops "deploy/demo" and parallel teams. Constitution 3.1.0 makes tests mandatory for everything
  measurable and fixes the owner format, both explicitly also where a Spec Kit skill says otherwise.
  After every Spec Kit update Claude now compares its new templates with the originals our copies
  came from, recorded with checksums in the project profile.
- **Alternatives:** leaving it to Claude to correct each generated task list by hand, as until now.
- **Why:** The blueprint tests showed that our own template still carried Spec Kit's defaults, which
  contradict how we work, and that a template of our own replaces Spec Kit's completely, so its
  improvements would never reach us.
- **Evidence:** `8eedd1e`, [tasks-template.md](../../.specify/templates/overrides/tasks-template.md),
  [constitution.md](../../.specify/memory/constitution.md).
