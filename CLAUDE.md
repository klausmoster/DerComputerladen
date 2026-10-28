# Der Computerladen — Arbeitsanweisungen

Wirtschaftssimulation + Point-and-Click-Adventure, Deutschland 1985–1999.
Engine: Godot 4.7 / GDScript. Konzept: `docs/game_design.md`.

## Harte Rahmenbedingungen

**Nur Desktop.** Zielplattformen sind Windows, macOS und Linux — **niemals**
Android, iOS, Mobile, Touch oder Web. Das ist dauerhaft entschieden, nicht
„später vielleicht":
- Maus + Tastatur werden vorausgesetzt. Hover, Tooltips, Rechtsklick,
  Cursor-Wechsel und Drag&Drop sind erwünschte Mittel.
- Keine touch-taugliche Mindestgröße von Klickflächen, keine Touch-Gesten, kein
  `InputEventScreenTouch`, keine Orientierungswechsel, keine Safe Areas. Wischen
  und Kneifen auf dem Trackpad sind Desktop-Eingabe und erlaubt.
- Renderer bleibt **Forward+**. Keine Rücksicht auf Compatibility/Mobile oder
  GLES-Beschränkungen.
- Android-Build-Templates werden nie installiert.

**Rollenverteilung.** Gearbeitet wird featureweise: „wir arbeiten jetzt an
Feature xy", und darüber wird geredet. Es gibt drei Rollen:

- **Klaus** entscheidet und nimmt ab. Er gibt jede Umsetzung frei und baut
  selbst, was er in Godot lernen will, dazu alles, was nur im Godot-Editor, in
  Grafikprogrammen oder mit seiner Entscheidung geht. Solche Aufgaben tragen
  `[K]`.
- **Der Godot-Agent** (`.claude/agents/godot-entwickler.md`) setzt
  `[A]`-Aufgaben um — Szenen, Nodes, GDScript, Tests. Für Arbeit in Godot ist
  er der Standard.
- **Claude** schreibt Specs und Pläne, beschafft Informationen (Recherche,
  Godot-Doku, Fachquellen), verteilt die Aufgaben, übernimmt `[C]`-Aufgaben
  (Werkzeuge außerhalb von Godot, Style-Guide, Doku), beauftragt den Agent und
  prüft sein Ergebnis.

**Nicht eigenmächtig umsetzen** — ein Feature-Dokument oder eine Taskliste ist
eine Beschreibung, keine Beauftragung. Umgesetzt wird nur, was Klaus freigibt,
und zwar phasenweise, nie das ganze Feature in einem Zug. Bei unklarer Lage
eine Aufteilung vorschlagen und nachfragen.

Alles, was der Agent oder Claude an Code erzeugt, sieht Klaus sich **vorher**
an: Claude prüft es zuerst, dann bekommt Klaus Diff und Erklärung, und erst
nach seinem OK wird committet.

**Git:** Claude committet, **Klaus pusht.** Der Godot-Agent committet nicht.
Nicht versuchen zu pushen — auf diesem Rechner liegen keine
GitHub-Zugangsdaten.

**Arbeitsweise:** Die Dokumente in `docs/ki_workflow/` beschreiben Abläufe,
Prüfungen und Erfahrungen und gelten für Claude in diesem Projekt. Es gibt kein
lokales Gedächtnis: Was dauerhaft gelten soll, kommt in eine Repo-Datei und
wird committet. Offene Punkte und Claudes eigene Entscheidungen stehen in
`docs/offene-punkte.md`.

Erklären statt nur liefern: Zu jeder umgesetzten Aufgabe gibt es eine
Lernnotiz — warum diese Node-Struktur, warum Signal statt direktem Zugriff, was
ein Autoload/Resource tut — an der konkreten Stelle im Projekt, kein
Tutorial-Vortrag. Gelernt wird über Lernnotizen, Review und die `[K]`-Aufgaben,
die Klaus sich aussucht. Kleine, überprüfbare Schritte.

Ausgenommen von alldem: die Daten in `docs/game_bible/` und die Skills dürfen
selbstständig befüllt werden.

## Featureweise arbeiten

Gearbeitet wird mit Spec Kit; es ersetzt `/dcl-feature` seit 2026-10-27 dauerhaft. Jedes Feature
hat eine feste Nummer `NNN`, einen Branch `feature/NNN-kurzname` und einen Ordner
`specs/NNN-kurzname/` mit Spec, Plan, Aufgaben und Lernnotizen. Der Ablauf steht in der Verfassung
(`.specify/memory/constitution.md`) und in `docs/ki_workflow/ki_dev.md`.

- `docs/features/Features.md` — Systemliste 01–11 und Index der Features
- `docs/features/Feature_Ideas.md` — unverbindlicher Backlog; die IDs `SS-NN` dort sind
  reserviert, nicht vergeben. Wird ein Eintrag gebaut, entsteht er mit `/speckit-specify`.
- `docs/features/archiv/` — Feature-Docs aus der Zeit vor Spec Kit
- In `tasks.md` trägt jeder Schritt einen Besitzer: `[K]` Klaus, `[A]` Godot-Agent, `[C]` Claude.

Abgrenzung: `docs/game_design.md` ist die Vision (*was* das Spiel ist), `specs/` der Bauplan
(*wie*), `docs/spielbeschreibung/` der Stand im Code und `docs/game_bible/` der Spielinhalt.

## Aufbau

Vor Arbeit an einem System die passende Datei aus `docs/spielbeschreibung/` laden; welche, sagt
deren `README.md`.

| Pfad | Inhalt |
|---|---|
| `src/` | Godot-Projekt (Projekt-Root ist `src/`, nicht das Repo-Root) |
| `src/core/` | Engine-Systeme: `game_date`, `game_clock`, `timeline` (Hülle der Zeitleiste), `game_window`, `game_session` (das laufende Spiel) |
| `src/core/timeline/` | Kern der Zeitleiste ohne Node: Datenklassen, Katalog, Prüfregeln, Fahrplan (`TimelineRun`), Vergleich, Statistik, Schwierigkeitsgrade (`Difficulty`, `DifficultyProfile`) |
| `src/core/save/` | Spielstände: `SaveGame` (Inhalt, Formatversion), `SaveSlot` (eine Datei und ihr Zustand), `SaveStore` (Ordner `user://spielstaende/`, sicheres Schreiben, Löschen) |
| `src/data/` | Ereigniskatalog `event_catalog.json`, gepflegt mit der Zeitleisten-Werkstatt |
| `src/ui/` | Theme des ganzen Spiels (`computerladen_theme.tres`), Farben (`ui_palette.gd`) und der Communicator (`communicator/`) |
| `src/scenes/title/` | Titelbildschirm mit seinen Seiten auf dem Communicator: Hauptmenü, Gradwahl, Liste der Spielstände, Rückfrage; Hinweis und Meldung; alle Texte in `title_texts.gd`; das versteckte Spiel unter `invaders/` |
| `src/scenes/game/` | Spielbildschirm, bisher leer bis auf „Zum Hauptmenü“ |
| `src/assets/` | Schriften (`fonts/`), gerasterte Bilder (`images/`), App-Symbol (`icon/`), Töne (`sounds/`) |
| `src/tools/werkstatt/` | Zeitleisten-Werkstatt (Editor, Zeitstrahl, Simulator, Statistik), Textausgabe `fahrplan_ausgabe.gd`, Proben unter `proben/`; vom Export ausgeschlossen |
| `tools/raster/` | Python-Werkzeuge der Rasterfassung: Palette, Rastern, Aufräumen, App-Symbol |
| `tools/ton/` | `make_sounds.py` erzeugt die Töne; die Kanäle stehen in `src/default_bus_layout.tres` |
| `tools/tagebuch/` | `token_bilanz.py`: Token und geschätzte Kosten je Branch aus den Protokollen von Claude Code |
| `docs/art/` | Hauptpalette, Leonardo-Originale, Ebenen des App-Symbols (`app_icon/`) |
| `docs/game_bible/` | Obsidian-Vault mit den Spieldaten (Komponenten, Preise, Prospekte) |
| `docs/game_design.md` | Game Design Document |
| `docs/spielbeschreibung/` | Stand im Code, nach Systemen; Index `README.md` |
| `docs/ki_workflow/` | Arbeitsweise mit KI: Abläufe, Prüfungen, Erfahrungen |
| `docs/offene-punkte.md` | offene Fragen, Lücken und Claudes eigene Entscheidungen |
| `docs/tagebuch/` | Entwicklungstagebuch: wichtige Entscheidungen seit Projektbeginn, je Merge fortgeschrieben |
| `.claude/skills/` | Projekt-Skills, Präfix `dcl-` (eigene) und `speckit-` (Spec Kit) |
| `.claude/agents/` | Projekt-Agents, z.B. `godot-entwickler` für `[A]`-Aufgaben |

`GameClock`, `Timeline`, `GameWindow` und `GameSession` sind Autoloads (siehe `src/project.godot`).
Die Zeitleiste folgt dem Fahrplan-Modell: Aus dem Katalog entsteht je Spiel, Seed
und Grad ein Fahrplan (`TimelineRun`, ein Kern ohne Node), den die Spieluhr
abspielt. Leicht und Schwer verschieben über Profile aus Start-Modifikatoren nur
Chancen; Mittel ist der Katalog allein.
Das Autoload `Timeline` ist die Hülle darum und meldet per Signal:
`event_fired`, `effect_applied`, `event_ended`, `effect_ended` und
`entry_skipped`. Die Zeitleiste startet kein Spiel von selbst. Das tut `GameSession`: Sie beginnt
ein neues Spiel oder setzt einen Spielstand fort, speichert beim Verlassen und beim Schließen des
Fensters und spielt beim Fortsetzen den Fahrplan bis zum gespeicherten Tag nach. Architekturprinzip: Die Timeline **wendet Effekte nicht an**,
sie meldet sie nur — Wirtschaft, Nachfrage und Reputation hängen sich später dran.
Ereignisse und die Profile der Grade pflegt Klaus in der Zeitleisten-Werkstatt
(`src/tools/werkstatt/werkstatt.tscn`), nicht im Code.

## game_bible — Datenkonventionen

- Strukturierte Daten **nur** ins YAML-Frontmatter; Skalare als
  `kategorie_feld` (z.B. `technik_cache_l1`).
- Preise als Range: je Eintrag `von`/`bis` als **Zahl in DM** (kein „DM",
  kein Tausenderpunkt).
- Freitext **nur** unter `##`-Überschriften, deren Titel mit `+` beginnt —
  diese Abschnitte sind vor Regenerierung geschützt.
- Bezug: deutscher Markt, 1990er, DM, Datumsformat `JJJJ-MM`.
- `Templates/TEMPLATE_*.md` ist die **alleinige** Autorität für Struktur und
  Feldnamen. Niemals eine vorhandene Datei als Strukturvorlage nehmen.
- Lesbare Tabellen erzeugt `regenerate_tables.py` aus dem Frontmatter — das ist
  ein **separater** Schritt, nicht Teil des `/dcl-komponente`-Skills.

## Versionierung (Godot-Fallen)

- `.godot/` bleibt draußen: Caches, importierte Assets, Editor-Zustand.
- `*.uid` und `*.import` **müssen** committet werden. Sie sehen wie Cache aus,
  sind aber Quelle: `.uid` hält die stabile Resource-ID (fehlt sie, brechen
  Szenen-Referenzen nach einem Clone), `.import` die Import-Einstellungen.
- `export_presets.cfg` (entsteht beim ersten Export) vor dem Committen
  ansehen — je nach Godot-Version landen dort Signierungs-Credentials im
  Klartext.
