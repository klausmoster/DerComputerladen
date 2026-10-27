# Implementation Plan: Communicator als Steuerelement

**Branch**: `feature/005-communicator` | **Date**: 2026-10-27 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/005-communicator/spec.md`

## Summary

Der Titel wird über den Communicator bedient, ein Taschengerät, das von unten ins Bild fährt. Im
Titel ist es fest der Organizer von 1991, rechts unten auf einem neuen Titelbild T-02. Alle vier
Blätter aus Feature 004 stehen als Seiten auf seiner Anzeige: Hauptmenü, Gradwahl, Spielstände und
Rückfrage. Die gewählte Zeile ist invertiert wie auf einem echten LCD, der Hinweis steht als Zettel
links neben dem Gerät. Beginnt ein Spiel, fährt das Gerät erst hinaus. Gebaut wird der Communicator
als eigener Baustein, den spätere Bildschirme mit eigenen Seiten benutzen.

Technischer Ansatz (Details in [research.md](research.md), Verträge unter [contracts/](contracts/)):
- **Farbe `lcd`** als 16. Farbe nur der Oberfläche; die Hauptpalette bleibt eingefroren (R1, R2).
- **Baustein `Communicator`** unter `src/ui/communicator/`: Gehäuse als Bild, Anzeige in `lcd`,
  Seiten als Kinder, Hinweis als Kind, das mitfährt (R4, R7).
- **Fahrt** mit Tween auf ganzen Pixeln, Zeitschritt auf 1/30 s gedeckelt, herein bedienbar,
  hinaus gesperrt (R6, R8).
- **Seiten:** `MainMenu` und `SaveList` bekommen den Schalter `look` mit `PAPER` und `LCD`; auf
  `LCD` ohne Papier, mit invertierter Auswahl (R3, R5).
- **Titel:** vier Seiten im Communicator, T-02, Hinausfahren vor dem Spielstart (R8, R9).
- **Grafik:** G-02 (Organizer mit LCD 2 : 1) und T-02 aus Leonardo; bis dahin ein Platzhalter (R10,
  R11).
- **Style-Guide zuerst:** Baustein Communicator, `lcd`, Menü und Liste auf der Anzeige (R12).
- **Code des Spikes** gezielt übernommen, nicht gemergt (R14).

## Technical Context

**Language/Version**: GDScript, typisiert, Godot 4.7.2 (Forward+)

**Primary Dependencies**: keine neuen. Godot-Bordmittel: `Tween` mit `custom_step()`,
`Control._draw()`, `TextureRect`, `ColorRect`, Theme-Varianten. Tests mit GUT 9.7.1. Für die Grafik
`tools/raster/` (Python 3, Standardbibliothek) und Leonardo.ai durch Klaus.

**Storage**: keine. Spielstände bleiben wie in Feature 004.

**Testing**: GUT 9.7.1 headless; die Fahrt Bild für Bild über `_process()` mit festen Zeitschritten.
Oberfläche zusätzlich mit Bildschirmfotos aus dem echten Fenster und von Hand nach
[quickstart.md](quickstart.md).

**Target Platform**: Desktop: Windows, macOS, Linux; geprüft auf macOS (Apple Silicon).

**Project Type**: Desktop-Spiel (Godot-Projekt unter `src/`)

**Performance Goals**: Fahrt 200 ms, Endlage spätestens 250 ms nach dem ersten Bild auch bei 30
Bildern je Sekunde (SC-002); Titel bedienbar nach höchstens 3 s wie in Feature 001.

**Constraints**:
- Jede Lage auf ganzen Oberflächenpixeln, nie über die Endlage (SC-003).
- Wege, Texte, Vorwahl und Esc des Titels unverändert (FR-013, SC-007).
- Logo, Untertitel und Versionszeile frei (SC-006).
- Der Communicator kennt den Titel nicht (FR-007, SC-005).
- Nur Desktop mit Maus und Tastatur; alles auf dem Oberflächenraster 640 × 360.

**Scale/Scope**: ein neuer Baustein mit Szene und Skript; geändert `UiPalette`, Theme, `MenuPaper`,
`MainMenu`, `SaveList`, `TitleScreen` und ihre Szenen. Eine neue Testdatei, fünf geänderte
(`test_main_menu.gd`, `test_save_list.gd`, `test_title_screen.gd`, `test_ui_palette.gd`,
`test_bilder.gd`). Zwei neue Bilder. Im Style-Guide ein neuer Baustein, ein Token und sechs
Ergänzungen (R12).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Grundsatz | Prüfung | Vor Phase 0 | Nach Phase 1 |
|---|---|---|---|
| I. Nur Desktop | Maus und Tastatur wie bisher: Überfahren wählt, Rechtsklick zeigt den Hinweis, Pfeile, Tab, Enter, Esc, Mausrad. Keine Touch-Eingaben, Forward+ bleibt | erfüllt | erfüllt |
| II. Klaus entscheidet, der Agent baut, Claude plant und prüft | Der Plan enthält nur Signaturen. Umgesetzt wird phasenweise auf Klaus' Auftrag, `/speckit-implement` nie; Lernnotizen zu jeder Task. Klaus erzeugt die Bilder (`[K]`), Claude schreibt Prompts, rastert und schreibt den Style-Guide (`[C]`). Claudes Festlegungen stehen gekennzeichnet in research.md und `docs/offene-punkte.md` | erfüllt | erfüllt |
| III. Erst spezifizieren | Spec mit 8 Klärungen, eigener Branch, System 10 genannt; 14 Entscheidungen mit verworfenen Alternativen in research.md | erfüllt | erfüllt |
| IV. Ein Look: der Style-Guide | Baustein Communicator, `lcd` und die Anpassungen an Menü, Liste, Hinweis und README kommen in Phase 1 in den Style-Guide, bevor gebaut wird (R12). Die Zahlen in R2 und R9 sind Vorschläge und Messungen; Verträge und Tasks verweisen danach nur auf den Style-Guide. G-02 und T-02 nach dem Leonardo-Workflow mit Eintrag im Prompt-Log (R10) | erfüllt, mit Vorarbeit | erfüllt, mit Vorarbeit |
| V. Daten sauber halten | keine Spieldaten berührt; game_bible und Katalog unberührt | erfüllt | erfüllt |
| Technische Rahmenbedingungen | Godot 4.7, GUT 9.7.1, Projekt in `src/`. Keine Autoloads dazu; Zeitleiste und Spielablauf unverändert | erfüllt | erfüllt |
| Arbeitsweise | Dokumente deutsch. `.uid` und `.import` der neuen Skripte und Bilder werden committet; `export_presets.cfg` bleibt unberührt | erfüllt | erfüllt |

Ergebnis: bestanden, vor und nach dem Entwurf. Zu Grundsatz IV ist Vorarbeit nötig: Phase 1.

## Project Structure

### Documentation (this feature)

```text
specs/005-communicator/
├── spec.md                      # Spezifikation, geklärt
├── plan.md                      # dieser Plan
├── research.md                  # Phase 0: Entscheidungen R1–R14
├── data-model.md                # Phase 1: Teile, Lage, Wege, Seiten auf der Anzeige
├── quickstart.md                # Phase 1: Prüfanleitung
├── contracts/
│   ├── communicator.md          # Baustein Communicator, look an Menü und Liste, lcd, Theme
│   └── titelbildschirm.md       # Titel mit Communicator, T-02, Hinausfahren
├── checklists/
│   └── requirements.md          # Qualitätsprüfung der Spec
├── tasks.md                     # Aufgaben je Phase (/speckit-tasks)
└── lernnotizen.md               # entsteht bei der Umsetzung
```

### Source Code (repository root)

```text
src/
├── assets/images/
│   ├── organizer_1991.png       # neu: Gehäuse G-02
│   └── title_t02.png            # neu: Titelbild T-02
├── ui/
│   ├── ui_palette.gd            # geändert: lcd
│   ├── computerladen_theme.tres # geändert: LcdRow, LcdHeader
│   └── communicator/            # neu: communicator.tscn, communicator.gd
├── scenes/title/                # geändert: menu_paper, main_menu, save_list, title_screen
└── test/                        # test_communicator.gd neu, fünf geändert
docs/art/leonardo/               # Originale G-02, T-02; prompt-log.md
```

**Structure Decision**: Der Communicator ist ein Baustein für mehrere Bildschirme und liegt deshalb
in `src/ui/` neben `knopf.gd`, nicht im Titel. Menü, Liste, Papier und Hinweis bleiben in
`scenes/title/`; sie umzuziehen gehört zu dem Feature, das sie als Erstes außerhalb des Titels
braucht.

## Complexity Tracking

Keine Einträge, die Prüfung der Verfassung zeigt keine Verstöße.

## Vorarbeiten vor dem Bauen

1. **Style-Guide** (R12), Phase 1: Claude schreibt Baustein, Token und Ergänzungen, Klaus gibt sie
   frei, auch den Wert von `lcd` (R2).
2. **Prompts G-02 und T-02** (R10): Claude schreibt sie in Phase 1 mit, Klaus erzeugt die Bilder,
   wann es ihm passt; gebraucht werden sie erst in Phase 5 (R11).

## Umsetzungsphasen (Vorschlag für die Tasks)

Jede Phase endet mit grünen Tests, Lernnotizen und Klaus' Abnahme; erst dann folgt die nächste.
Jede Phase mit Sichtbarem oder Texten hat vor der Abnahme die [C]-Aufgabe „Phasenprüfung“ mit
`/dcl-phasenpruefung`.

| Phase | Inhalt | Story |
|---|---|---|
| 1 | Style-Guide nach R12 mit dem Wert von `lcd`; Prompts G-02 und T-02 in die Prompt-Bibliothek. Kein Code | Vorarbeit |
| 2 | Grafik, erst G-02, dann T-02 (CHK005): Klaus erzeugt G-02 `[K]`; Claude rastert, räumt auf und misst die Anzeige im Gehäuse nach `[C]`; danach Prompt T-02 mit der freien Fläche, Klaus erzeugt T-02 `[K]`, Claude rastert; beide ins Prompt-Log; Klaus gibt frei. Darf parallel zu Phase 3 und 4 laufen, weil sie keine Datei teilt | Vorarbeit |
| 3 | Kern Communicator: `UiPalette.LCD`, `test_bilder.gd`, `Communicator` mit Platzhalter-Gehäuse, Fahrt, Seiten, Hinweis, gesperrter Eingabe; Probeszene; `test_communicator.gd` (SC-002, SC-003, SC-005) | US3 |
| 4 | Seiten auf der Anzeige: `look` an `MainMenu` und `SaveList`, `MenuPaper.draw_lcd_selection()`, Theme `LcdRow`, `LcdHeader`; Tests mit `LCD` neben den bisherigen | US1, US2 (Teil) |
| 5 | Titel: G-02 ins Gehäuse, T-02, vier Seiten im Communicator, Hinweis über ihn, Erscheinen, Hinausfahren vor dem Spielstart; `test_title_screen.gd` (SC-001, SC-004, SC-006, SC-007). Braucht Phase 2, 3 und 4 | US1, US2 |
| 6 | Abschluss: `docs/features/Features.md`; `CLAUDE.md` (Tabelle „Aufbau“: `src/ui/communicator/`) nur mit Klaus' OK; Ideensammlung und Recherche mit Verweis auf 005; Lückensuche mit `/speckit-converge`; Spielbeschreibung prüfen (`titel-und-hauptmenue.md`, `darstellung.md`, `bilder.md`, `glossar.md` mit Communicator, Gehäuse, Anzeige und Seite, `architektur.md` mit `src/ui/communicator/`; CHK006) und Klaus vorlegen; Gesamtabnahme | – |

Phase 3 und 4 sind voneinander unabhängig im Code, laufen aber nacheinander, weil Klaus jede Phase
einzeln freigibt (Grundsatz II). Phase 2 ist Klaus' und Claudes Grafikarbeit und blockiert nur
Phase 5.

## Änderungen nach der Checkliste

Aus [checklists/review.md](checklists/review.md), 26 Punkte, von Klaus am 2026-10-27 alle
freigegeben. Eingearbeitet in Spec (Clarifications „Review 2026-10-27“), research.md (R3, R10, R12,
R13), Datenmodell, beide Verträge, Quickstart und hier in Phase 2 und 6.

## Prüfer je Phase

Jede Phase mit Sichtbarem oder Texten endet mit der [C]-Aufgabe „Phasenprüfung“ durch
`/dcl-phasenpruefung` vor Klaus' Abnahme (`docs/ki_workflow/ki_pruefung.md`).

| Phase | Ändert | Prüfer | Maßstab für die Prüfer |
|---|---|---|---|
| 1 Style-Guide | den Maßstab selbst | keine; Klaus nimmt ab | – |
| 2 Grafik | zwei Bilder | Stil | `README.md` (Szenen und Figuren, Farben), Leonardo-Workflow, Stilanker C2; die gerasterten Bilder ×4 |
| 3 Kern Communicator | die Probeszene | Stil | Baustein Communicator, `tokens.json`; Bildschirmfoto der Probeszene |
| 4 Seiten auf der Anzeige | Menü und Liste auf `lcd` | Stil | Bausteine Menü, Liste, Communicator, `tokens.json`; Bildschirmfotos |
| 5 Titel | den ganzen Titel | Stil, Text | wie 4, dazu Hinweis, Meldung, README (Bildaufbau, Bewegung, Logo); `Sprache.md` nur, falls sich doch ein Text ändert; Bildschirmfotos aus titelbildschirm.md |
| 6 Abschluss | Doku | bei der Lückensuche Stil einmal über das ganze Feature | wie 5 |

Neue Texte entstehen in diesem Feature nicht (Spec, Annahmen); der Text-Prüfer läuft deshalb nur in
Phase 5 als Gegenprobe, dass sich kein Text verschoben oder gekürzt hat.
