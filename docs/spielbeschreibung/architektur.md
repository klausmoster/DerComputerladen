# Architektur

- **Worum es geht:** wie das Godot-Projekt aufgebaut ist, welche Teile es gibt und wer wen kennt.
- **Laden, wenn:** eine Arbeit mehrere Systeme berührt, neue Dateien, Autoloads oder Systeme
  dazukommen, oder ein System an ein anderes angebunden wird.
- **Code:** `src/project.godot`, `src/core/`, `src/scenes/`, `src/ui/`, `src/tools/`
- **Herkunft:** Pläne von `specs/001-hauptmenue/` bis `specs/005-communicator/`,
  Verfassung `.specify/memory/constitution.md`
- **Stand:** Feature 005, 2026-10-27

## Das Spiel in einem Absatz

„Der Computerladen“ ist eine Wirtschaftssimulation mit Point-and-Click-Adventure: Der Spieler
betreibt von 1985 bis 1999 einen Computerladen in Deutschland. Die Vision steht in
`docs/game_design.md`. Gebaut sind bisher der Start bis zum Hauptmenü (Feature 001), die
Zeitleiste mit ihrer Werkstatt (002), die Schwierigkeitsgrade der Zeitleiste (003), das
Beginnen, Speichern und Fortsetzen von Spielen (004) und der Communicator, ein Taschengerät als
Steuerelement, auf dem heute das Menü des Titels läuft (005). Der Spielbildschirm ist noch leer: Die Uhr
steht, Wirtschaft und Laden gibt es noch nicht.

## Ordner

| Pfad | Inhalt |
|---|---|
| `src/` | Godot-Projekt; Projekt-Root ist `src/`, nicht das Repo-Root |
| `src/core/` | Systeme mit Autoloads: `game_date`, `game_clock`, `timeline`, `game_window`, `game_session` |
| `src/core/save/` | Spielstände ohne Node: `SaveGame`, `SaveSlot`, `SaveStore` |
| `src/core/timeline/` | Kern der Zeitleiste ohne Node: Datenklassen, Katalog, Prüfung, Lauf, Vergleich, Statistik, Grade |
| `src/data/` | Spieldaten: `event_catalog.json` |
| `src/scenes/` | Szenen des Spiels: `title/` (Titelbildschirm und seine Seiten), `game/` (Spielbildschirm) |
| `src/ui/` | für alle Szenen: Theme, Farben, Baustein Knopf, Baustein Communicator (`communicator/`) |
| `src/assets/` | Schriften, gerasterte Bilder, App-Symbol |
| `src/tools/werkstatt/` | Zeitleisten-Werkstatt; nicht im Export |
| `src/test/` | GUT-Tests und `fixtures/` |
| `tools/raster/` | Python-Werkzeuge für Bilder, außerhalb von Godot |
| `docs/` | Vision (`game_design.md`), Spielinhalt (`game_bible/`), Bauplan (`features/`), diese Beschreibung, Arbeitsweise (`ki_workflow/`) |
| `specs/NNN-*/` | Spec Kit je Feature: Spec, Plan, Datenmodell, Verträge, Recherche, Aufgaben, Lernnotizen |

## Wer wen kennt

```mermaid
flowchart TB
    subgraph spiel["Spiel"]
        TS["TitleScreen<br/>scenes/title"]
        GS["GameScreen<br/>scenes/game"]
    end
    subgraph autoloads["Autoloads"]
        GC["GameClock"]
        TL["Timeline"]
        GW["GameWindow"]
        SE["GameSession"]
    end
    subgraph save["Spielstände ohne Node, core/save"]
        ST["SaveStore, SaveSlot,<br/>SaveGame"]
    end
    subgraph kern["Kern ohne Node, core/timeline"]
        RUN["TimelineRun"]
        CAT["EventCatalog,<br/>CatalogValidator"]
        DIF["Difficulty,<br/>DifficultyProfile"]
    end
    subgraph werkzeuge["Werkzeuge, nicht im Export"]
        WS["Werkstatt"]
        TA["Textausgabe"]
    end
    DATA[("data/event_catalog.json")]
    SAVES[("user://spielstaende/")]
    UI["ui: Theme, UiPalette"]
    CO["Communicator<br/>ui/communicator"]
    TS -->|"Seiten, Fahrt, Hinweis"| CO
    CO --> UI
    TS -->|"start_new, resume"| SE
    GS -->|"leave"| SE
    TS -->|"Liste, Löschen"| ST
    SE -->|"set_date"| GC
    SE -->|"start_game, resume_game,<br/>stop_game"| TL
    SE --> ST
    ST --> SAVES
    ST --> CAT
    GC -->|"day_passed"| TL
    TL --> RUN
    TL --> CAT
    RUN --> CAT
    RUN --> DIF
    CAT --> DATA
    WS --> RUN
    WS --> CAT
    WS -->|"liest und schreibt"| DATA
    TA --> RUN
    TS --> UI
    WS --> UI
    TL -.->|"Signale, später"| ABN["Abnehmer:<br/>Wirtschaft, Nachfrage, Ruf"]
```

Autoloads in `project.godot`, in dieser Reihenfolge: `GameClock`, `Timeline`, `GameWindow`,
`GameSession`.
Hauptszene ist `res://scenes/title/title_screen.tscn`.

## Grundsätze

- **Kern ohne Node, Hülle als Autoload.** Logik steckt in `RefCounted`-Klassen, die weder
  Szenenbaum noch Uhr brauchen. So laufen sie gleich im Spiel, in Werkzeugen und in Tests. Das
  Autoload verbindet nur und macht Signale daraus.
- **Melden statt anwenden.** Die Zeitleiste meldet Ereignisse und Wirkungen; was daraus folgt,
  entscheidet das System, das zuhört. Systeme sind über Signale entkoppelt, nicht über direkte
  Aufrufe.
- **Wiederholbar.** Katalog, Seed, Grad und Eingriffe legen ein Spiel vollständig fest. Spielstände
  bauen darauf, statt den ganzen Zustand zu speichern (siehe [spielstaende.md](spielstaende.md)).
- **Daten statt Code.** Ereignisse und Profile stehen in der Katalogdatei und werden in der
  Werkstatt gepflegt; Menüeinträge sind `MenuEntry`-Resources; Texte des Titels stehen an einer
  Stelle (`TitleTexts`); Farben heißen über Tokens.
- **Ein Look.** Der Style-Guide ist die einzige Quelle für Farben, Raster, Schriften und Sprache.
  Texte duzen den Spieler.
- **Nur Desktop.** Maus und Tastatur, Forward+.

## Code-Stil

GDScript typisiert. `class_name` für Klassen, die andere benutzen; Autoloads ohne `class_name`.
Doku-Kommentare mit `##` auf Deutsch, mit Verweisen auf FR-, R- und T-Nummern der Specs.
Zeichenketten der Oberfläche auf Deutsch, Bezeichner auf Englisch. Der Start mit `-d` muss still
sein, deshalb stehen nötige `@warning_ignore` mit Grund im Code.

## Was als Nächstes andockt

Feature-Ideen, die auf diesem Stand aufsetzen, stehen in `docs/features/Feature_Ideas.md`: etwa
die Produktdatenbank (System 02) und die Wirtschaft (03) als erster Abnehmer der Zeitleiste. Was
ein neues System im Spiel hält, muss in den Spielstand (siehe [spielstaende.md](spielstaende.md)),
und es muss beim Fortsetzen aus Seed, Grad und Eingriffen wieder entstehen oder eigene Daten
mitspeichern.
