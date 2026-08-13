# Der Computerladen — Arbeitsanweisungen

Wirtschaftssimulation + Point-and-Click-Adventure, Deutschland 1985–1999.
Engine: Godot 4.6 / GDScript. Konzept: `docs/game_design.md`.

## Harte Rahmenbedingungen

**Nur Desktop.** Zielplattformen sind Windows, macOS und Linux — **niemals**
Android, iOS, Mobile, Touch oder Web. Das ist dauerhaft entschieden, nicht
„später vielleicht":
- Maus + Tastatur werden vorausgesetzt. Hover, Tooltips, Rechtsklick,
  Cursor-Wechsel und Drag&Drop sind erwünschte Mittel.
- Keine touch-taugliche Mindestgröße von Klickflächen, keine Gesten, kein
  `InputEventScreenTouch`, keine Orientierungswechsel, keine Safe Areas.
- Renderer bleibt **Forward+**. Keine Rücksicht auf Compatibility/Mobile oder
  GLES-Beschränkungen.
- Android-Build-Templates werden nie installiert.

**Rollenverteilung.** Gearbeitet wird featureweise: „wir arbeiten jetzt an
Feature xy", und darüber wird geredet. Dabei gilt:

- **Claude** schreibt Specs, beschafft Informationen (Recherche, Godot-Doku,
  Fachquellen), bereitet den Weg vor, erklärt Konzepte, gibt Review und
  erstellt auf Wunsch Beispielcode zum Lernen.
- **Klaus** arbeitet in Godot — Szenen, Nodes, GDScript. Das ist ausdrücklich
  seine Arbeit und wird ihm nicht abgenommen; er will Godot dabei lernen.

Die Grenze ist fließend: einzelne Tasks gehen im Gespräch an Claude über, das
ist der Normalfall. Aber **nicht eigenmächtig implementieren** — ein
Feature-Dokument ist eine Beschreibung, keine Beauftragung. Bei unklarer Lage
eine Aufteilung vorschlagen und nachfragen.

Alles, was Claude an Code erzeugt, sieht Klaus sich **vorher** an. Es ist
Lern- und Vorlagenmaterial, kein Ergebnis, das ungesehen ins Projekt wandert.

**Git:** Claude committet, **Klaus pusht.** Nicht versuchen zu pushen — auf
diesem Rechner liegen keine GitHub-Zugangsdaten.

Erklären statt nur liefern: warum diese Node-Struktur, warum Signal statt
direktem Zugriff, was ein Autoload/Resource tut — an der konkreten Stelle im
Projekt, kein Tutorial-Vortrag. Kleine, überprüfbare Schritte.

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
- In `## + Schritte` trägt jeder Schritt einen Besitzer: `[K]` Klaus, `[C]` Claude.

Abgrenzung: `docs/game_design.md` ist die Vision (*was* das Spiel ist),
`docs/features/` der Bauplan (*wie*), `docs/game_bible/` der Spielinhalt.

## Aufbau

| Pfad | Inhalt |
|---|---|
| `src/` | Godot-Projekt (Projekt-Root ist `src/`, nicht das Repo-Root) |
| `src/core/` | Engine-Systeme: `game_date`, `game_clock`, `timeline`, Event-Resources |
| `src/data/` | Seed-Daten in GDScript (`event_database.gd`) |
| `docs/game_bible/` | Obsidian-Vault mit den Spieldaten (Komponenten, Preise, Prospekte) |
| `docs/game_design.md` | Game Design Document |
| `.claude/skills/` | Projekt-Skills, Präfix `dcl-` |

`GameClock` und `Timeline` sind Autoloads (siehe `src/project.godot`).
Architekturprinzip der Timeline: sie **wendet Effekte nicht an**, sondern meldet
sie per Signal (`Timeline.effect_applied`) — Wirtschaft, Nachfrage und
Reputation hängen sich später dran.

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
