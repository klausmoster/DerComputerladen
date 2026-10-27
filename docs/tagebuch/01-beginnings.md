# 01 · Beginnings (2026-05-26 to 2026-10-18)

## Why this game

I was born in 1982. In my town, Speyer, there was a Vobis computer shop, and it regularly put out
the "Vobis Denkzettel" as an advertising leaflet. I loved reading those leaflets back then and
dreamt of certain computers.

My idea was: if I kept all of these leaflets, I could one day make a historically accurate game.
Maybe a computer shop that sells used computers, or new ones too.

Now it is 2026 and I want to take the idea up again, with AI. Before, the questions simply had no
answer for me: which programming language, where do the graphics come from, and so on. With AI I
can build it. I no longer have the leaflets, but luckily there are many PDFs with scans.

The repository started almost empty. Most of what happened before October was preparation: a data
vault for the game content, a first engine prototype, and the first rules for working with
Claude.

### 2026-05-26 · A repository for the game `[Workflow]`

- **Decision:** I created the repository with nothing but a README.
- **Evidence:** `b2bb190`.

### 2026-06-16 · Game content lives in an Obsidian vault `[Tools]` `[Game content]`

- **Decision:** All hardware and market data goes into `docs/game_bible/`, an Obsidian vault.
  Structured data sits in the YAML frontmatter, and the templates in `Templates/` define the
  structure. A script builds readable tables from the frontmatter; an AI fills in the data. The
  first Claude skill, `dcl-komponente`, does exactly that.
- **Evidence:** `28b7e1b`, `docs/game_bible/`.

### 2026-06-16 to 2026-08-13 · Pause

No commits. I had other things to do. The first Godot prototype was built outside version
control; when exactly is not recorded.

### 2026-08-13 · Put the prototype under version control `[Architecture]`

- **Decision:** I versioned the existing Godot prototype: game date, game clock and timeline,
  an event database with 18 fixed and 6 variable events, and a demo scene, then on Godot 4.6.
- **Evidence:** `36694db`.

### 2026-08-13 · Desktop only, for good `[Architecture]`

- **Decision:** The game runs on Windows, macOS and Linux. Never mobile, touch or web. The
  renderer stays Forward+, and Android templates are never installed.
- **Why:** Recorded later in the constitution: the decision is final, and keeping other platforms
  in mind costs design freedom.
- **Evidence:** `36694db`, `CLAUDE.md`, `.specify/memory/constitution.md`.

### 2026-08-13 · `.uid` and `.import` are source, not cache `[Tools]`

- **Decision:** `.godot/` stays out of Git; `*.uid` and `*.import` files are committed.
  `export_presets.cfg` is checked before every commit.
- **Why:** Without the `.uid` files, scene references break after a clone. Export presets can
  hold signing credentials in plain text.
- **Evidence:** `36694db`, `CLAUDE.md`.

### 2026-08-13 · I build, Claude specifies and reviews `[Workflow]`

- **Decision:** The day started with "Godot code is written together". By the evening I had
  changed it: Claude specifies, researches and reviews; building in Godot is my job. A feature
  document is a description, not an order.
- **Why:** I wanted to learn Godot.
- **Evidence:** `36694db`, `cb8403f`.

### 2026-08-13 · My own feature workflow `/dcl-feature` `[Workflow]`

- **Decision:** One document per feature in `docs/features/`, IDs `SS-NN` (system and number),
  phases spec, plan and tasks, owners `[K]` and `[C]`. The template is the authority, the skill
  stays thin, as in the Game Bible. Systems 01 to 11 in `Features.md`, a backlog in
  `Feature_Ideas.md`.
- **Evidence:** `cb8403f`.

### 2026-08-13 · How a sale works stays open `[Game content]`

- **Decision:** Selling to a customer could be a dialogue like in "Das Amt" or an input screen like
  in "Pizza Connection". I left it open; it depends on the game speed and the amount of text.
- **Evidence:** `ce54998`, `docs/features/Feature_Ideas.md`.

### 2026-08-13 · The timeline reports effects, it does not apply them `[Architecture]`

- **Decision:** The engine uses an absolute day index instead of year/month/day arithmetic, the
  clock is an autoload with an accumulator instead of a timer node, and the timeline only sends
  signals. Economy, demand and reputation hook in later.
- **Why:** The timeline can be finished before anything that consumes it exists.
- **Evidence:** `48f5b95`, `docs/features/archiv/01-01-spieluhr.md`,
  `docs/features/archiv/01-02-ereignis-engine.md`.

### 2026-08-13 · Seasons and modifiers become timeline events `[Architecture]`

- **Decision:** Seasons and the Christmas trade will be generated as timeline events. Chances are
  a fixed base value plus named modifiers, each with an end date.
- **Why:** Everything that can trigger an event is in one place.
- **Evidence:** `b012753`.

### 2026-08-13 · Tests with GUT from day one `[Tools]`

- **Decision:** Unit tests with GUT 9.6.1, headless from the command line. Tests build their own
  clocks and events instead of using the autoloads. 50 tests, all green.
- **Why:** No shared state, no accidental real events.
- **Evidence:** `c72ac9b`, `e50923a`.

### 2026-08-13 · Claude commits, I push `[Workflow]`

- **Decision:** Claude writes the commits; pushing is my job.
- **Why:** There are no GitHub credentials on this machine.
- **Evidence:** `e50923a`, `CLAUDE.md`.

### 2026-08-13 to 2026-10-19 · Pause

No commits. Other things came first and the project was on hold, but I thought about how I
wanted to work with AI.
