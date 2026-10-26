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

**Arbeitsweise:** `docs/ki_dev.md` beschreibt Abläufe, Prüfungen und
Erfahrungen und gilt für Claude in diesem Projekt. Es gibt kein lokales
Gedächtnis: Was dauerhaft gelten soll, kommt in eine Repo-Datei und wird
committet. Offene Punkte und Claudes eigene Entscheidungen stehen in
`docs/offene-punkte.md`.

Erklären statt nur liefern: Zu jeder umgesetzten Aufgabe gibt es eine
Lernnotiz — warum diese Node-Struktur, warum Signal statt direktem Zugriff, was
ein Autoload/Resource tut — an der konkreten Stelle im Projekt, kein
Tutorial-Vortrag. Gelernt wird über Lernnotizen, Review und die `[K]`-Aufgaben,
die Klaus sich aussucht. Kleine, überprüfbare Schritte.

Ausgenommen von alldem: die Daten in `docs/game_bible/`, die Feature-Docs und
die Skills dürfen selbstständig befüllt werden.

## Featureweise arbeiten

Feature-Dokumente liegen in `docs/features/`, ein Dokument pro Feature, angelegt
und weitergeschoben mit `/dcl-feature`. `TEMPLATE_FEATURE.md` ist die Autorität
für Struktur und Felder.

- `Features.md` — Systemliste 01–11 und Index der vorhandenen Feature-Docs
- `Feature_Ideas.md` — unverbindlicher Backlog; IDs dort sind reserviert, nicht
  vergeben
- IDs sind `SS-NN` (System, laufende Nummer) und stabil — Wikilinks, Branches
  (`feature/02-01-bible-importer`) und Commits verweisen darauf
- Drei Phasen: `spec` (was und woran erkennbar fertig) → `plan` (technischer
  Vertrag, Schritte) → `tasks` (Umsetzung, Entscheidungen, Lernnotizen).
  Das Dokument wächst mit, es wird nicht auf einmal geschrieben.
- In `## + Schritte` (bei Spec Kit in `tasks.md`) trägt jeder Schritt einen
  Besitzer: `[K]` Klaus, `[A]` Godot-Agent, `[C]` Claude.

Abgrenzung: `docs/game_design.md` ist die Vision (*was* das Spiel ist),
`docs/features/` der Bauplan (*wie*), `docs/game_bible/` der Spielinhalt.

## Aufbau

| Pfad | Inhalt |
|---|---|
| `src/` | Godot-Projekt (Projekt-Root ist `src/`, nicht das Repo-Root) |
| `src/core/` | Engine-Systeme: `game_date`, `game_clock`, `timeline` (Hülle der Zeitleiste), `game_window` |
| `src/core/timeline/` | Kern der Zeitleiste ohne Node: Datenklassen, Katalog, Prüfregeln, Fahrplan (`TimelineRun`), Vergleich, Statistik, Schwierigkeitsgrade (`Difficulty`, `DifficultyProfile`) |
| `src/data/` | Ereigniskatalog `event_catalog.json`, gepflegt mit der Zeitleisten-Werkstatt |
| `src/ui/` | Theme des ganzen Spiels (`computerladen_theme.tres`) und Farben (`ui_palette.gd`) |
| `src/scenes/title/` | Titelbildschirm, Hauptmenü, Hinweis |
| `src/assets/` | Schriften (`fonts/`), gerasterte Bilder (`images/`), App-Symbol (`icon/`) |
| `src/tools/werkstatt/` | Zeitleisten-Werkstatt (Editor, Zeitstrahl, Simulator, Statistik), Textausgabe `fahrplan_ausgabe.gd`, Proben unter `proben/`; vom Export ausgeschlossen |
| `tools/raster/` | Python-Werkzeuge der Rasterfassung: Palette, Rastern, Aufräumen, App-Symbol |
| `docs/art/` | Hauptpalette, Leonardo-Originale, Ebenen des App-Symbols (`app_icon/`) |
| `docs/game_bible/` | Obsidian-Vault mit den Spieldaten (Komponenten, Preise, Prospekte) |
| `docs/game_design.md` | Game Design Document |
| `docs/ki_dev.md` | Arbeitsweise mit KI: Abläufe, Prüfungen, Erfahrungen |
| `docs/offene-punkte.md` | offene Fragen, Lücken und Claudes eigene Entscheidungen |
| `.claude/skills/` | Projekt-Skills, Präfix `dcl-` (eigene) und `speckit-` (Spec Kit) |
| `.claude/agents/` | Projekt-Agents, z.B. `godot-entwickler` für `[A]`-Aufgaben |

`GameClock`, `Timeline` und `GameWindow` sind Autoloads (siehe `src/project.godot`).
Die Zeitleiste folgt dem Fahrplan-Modell: Aus dem Katalog entsteht je Spiel, Seed
und Grad ein Fahrplan (`TimelineRun`, ein Kern ohne Node), den die Spieluhr
abspielt. Leicht und Schwer verschieben über Profile aus Start-Modifikatoren nur
Chancen; Mittel ist der Katalog allein.
Das Autoload `Timeline` ist die Hülle darum und meldet per Signal:
`event_fired`, `effect_applied`, `event_ended`, `effect_ended` und
`entry_skipped`. Architekturprinzip: Die Timeline **wendet Effekte nicht an**,
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
