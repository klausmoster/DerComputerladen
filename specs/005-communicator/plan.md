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
`MainMenu`, `SaveList`, `TitleScreen` und ihre Szenen. Zwei neue Testdateien
(`test_communicator.gd`, `test_lcd_theme.gd`), fünf geänderte (`test_main_menu.gd`,
`test_save_list.gd`, `test_title_screen.gd`, `test_ui_palette.gd`, `test_bilder.gd`), dazu
`test_menu_hint.gd`, falls `MenuHint` eine Funktion bekommt (Analyse, C15). Eine Probeszene unter
`src/test/fixtures/`. Zwei neue Bilder. Im Style-Guide sechs Punkte, darunter ein neuer Baustein und
ein Token (R12; Analyse, C16).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Grundsatz | Prüfung | Vor Phase 0 | Nach Phase 1 |
|---|---|---|---|
| I. Nur Desktop | Maus und Tastatur wie bisher: Überfahren wählt, Rechtsklick zeigt den Hinweis, Pfeile, Tab, Enter, Esc, Mausrad. Keine Touch-Eingaben, Forward+ bleibt | erfüllt | erfüllt |
| II. Klaus entscheidet, der Agent baut, Claude plant und prüft | Der Plan enthält nur Signaturen. Umgesetzt wird phasenweise auf Klaus' Auftrag, eine Phase nach der anderen, auch die Grafik (Analyse, A1), `/speckit-implement` nie; Lernnotizen zu jeder Task. Klaus erzeugt die Bilder (`[K]`), Claude schreibt Prompts, rastert und schreibt den Style-Guide (`[C]`). Claudes Festlegungen stehen gekennzeichnet in research.md und `docs/offene-punkte.md` | erfüllt | erfüllt |
| III. Erst spezifizieren | Spec mit 8 Klärungen, Review und Analyse, eigener Branch, System 10 genannt; 15 Entscheidungen mit verworfenen Alternativen und Entscheider in research.md | erfüllt | erfüllt |
| IV. Ein Look: der Style-Guide | Baustein Communicator, `lcd` und die Anpassungen an Menü, Liste, Hinweis und README kommen in Phase 1 in den Style-Guide, bevor gebaut wird (R12). Die Zahlen in R2 und R9 sind Vorschläge und Messungen; Verträge und Tasks verweisen danach nur auf den Style-Guide. G-02 und T-02 nach dem Leonardo-Workflow mit Eintrag im Prompt-Log (R10) | erfüllt, mit Vorarbeit | erfüllt, mit Vorarbeit |
| V. Daten sauber halten | keine Spieldaten berührt; game_bible und Katalog unberührt | erfüllt | erfüllt |
| Technische Rahmenbedingungen | Godot 4.7, GUT 9.7.1, Projekt in `src/`. Keine Autoloads dazu; Zeitleiste und Spielablauf unverändert | erfüllt | erfüllt |
| Arbeitsweise | Dokumente deutsch. `.uid` und `.import` der neuen Skripte und Bilder werden committet; `export_presets.cfg` bleibt unberührt | erfüllt | erfüllt |

Ergebnis: bestanden, vor und nach dem Entwurf. Zu Grundsatz IV ist Vorarbeit nötig: Phase 1. Die
Analyse fand zwei Verstöße, die Grafik neben dem Code (A1) und Datei und Werte in der Spec (A2);
beide sind behoben.

## Project Structure

### Documentation (this feature)

```text
specs/005-communicator/
├── spec.md                      # Spezifikation, geklärt
├── plan.md                      # dieser Plan
├── research.md                  # Phase 0: Entscheidungen R1–R15
├── data-model.md                # Phase 1: Teile, Lage, Wege, Seiten auf der Anzeige
├── quickstart.md                # Phase 1: Prüfanleitung
├── contracts/
│   ├── communicator.md          # Baustein Communicator, look an Menü und Liste, lcd, Theme
│   └── titelbildschirm.md       # Titel mit Communicator, T-02, Hinausfahren
├── checklists/
│   ├── requirements.md          # Qualitätsprüfung der Spec
│   └── review.md                # Review der Anforderungen, 26 Punkte, von Klaus freigegeben
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
├── test/                        # test_communicator.gd, test_lcd_theme.gd neu, fünf geändert
│   └── fixtures/                # communicator_probe.tscn
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
2. **Prompt G-02** (R10): Claude schreibt ihn in Phase 1; Klaus erzeugt das Bild, wann es ihm passt.
   Der Prompt für T-02 entsteht erst in Phase 4 nach dem Nachmessen von G-02 (CHK005; Analyse, C8).
   Gebraucht werden beide erst in Phase 5 (R11).

## Umsetzungsphasen (Vorschlag für die Tasks)

Jede Phase endet mit grünen Tests, Lernnotizen und Klaus' Abnahme; erst dann folgt die nächste.
Jede Phase mit Sichtbarem oder Texten hat vor der Abnahme die [C]-Aufgabe „Phasenprüfung“ mit
`/dcl-phasenpruefung`.

| Phase | Inhalt | Story |
|---|---|---|
| 1 | Style-Guide nach R12 mit dem Wert von `lcd`; Prompt G-02 in die Prompt-Bibliothek. Kein Code | Vorarbeit |
| 2 | Baustein Communicator in drei Teilen (Analyse, C10): `UiPalette.LCD` mit `test_bilder.gd`; Aufbau und Seiten; Fahrt; Eingabe und Hinweis; Probeszene; `test_communicator.gd` (SC-002, SC-003, SC-005). Gehäuse als Platzhalter (R11) | US3 |
| 3 | Seiten auf der Anzeige: `look` an `MainMenu` und `SaveList`, `MenuPaper.draw_lcd_selection()`, Theme `LcdRow`, `LcdHeader`, helle Schrift der gewählten Zeile aus dem Code (R15); Tests mit `LCD` neben den bisherigen | US1, US2 (Teil) |
| 4 | Grafik, erst G-02, dann T-02 (CHK005): Klaus erzeugt G-02 `[K]`; Claude rastert, räumt auf und misst die Anzeige im Gehäuse nach `[C]`; danach Prompt T-02 mit der freien Fläche, Klaus erzeugt T-02 `[K]`, Claude rastert; beide ins Prompt-Log; Klaus gibt Bilder und eine Änderung am Style-Guide aus dem Nachmessen frei (C21) | Vorarbeit |
| 5 | Titel: G-02 ins Gehäuse, T-02, vier Seiten im Communicator, Hinweis über ihn, Erscheinen, Hinausfahren vor dem Spielstart mit gesperrter Eingabe (R8); `test_title_screen.gd` (SC-001, SC-004, SC-006, SC-007) | US1, US2 |
| 6 | Abschluss: `docs/features/Features.md`; `CLAUDE.md` (Tabelle „Aufbau“: `src/ui/communicator/`) nur mit Klaus' OK; Ideensammlung und Recherche mit Verweis auf 005; Kommentar in `tools/raster/make_palette.py` und `tools/raster/README.md` (C14); Lückensuche mit `/speckit-converge`; Spielbeschreibung prüfen (`titel-und-hauptmenue.md`, `darstellung.md`, `bilder.md`, `glossar.md` mit Communicator, Gehäuse, Anzeige und Seite, `architektur.md` mit `src/ui/communicator/`; CHK006) und Klaus vorlegen; Gesamtabnahme | – |

Die Phasen laufen streng nacheinander (Grundsatz II). Phase 3 hängt an Phase 2, weil sie die
Probeszene aus Phase 2 auf `LCD` umstellt (Analyse, C19). Bis zur Analyse war die Grafik Phase 2 und
sollte neben dem Code laufen; das widersprach Grundsatz II (A1). Klaus darf G-02 trotzdem schon nach
Phase 1 in Leonardo erzeugen: Das ist keine Umsetzung, und abgenommen wird es erst in Phase 4.

## Änderungen nach der Checkliste

Aus [checklists/review.md](checklists/review.md), 26 Punkte, von Klaus am 2026-10-27 alle
freigegeben. Eingearbeitet in Spec (Clarifications „Review 2026-10-27“), research.md (R3, R10, R12,
R13), Datenmodell, beide Verträge, Quickstart und hier in den Phasen der Grafik (seit der Analyse
Phase 4) und 6.

## Änderungen nach der Analyse

Aus `/speckit-analyze` am 2026-10-27 mit 26 Befunden, gelesen von einem unabhängigen Prüfer;
Claude hat die kritischen und hohen Befunde im Code nachgeprüft. Klaus hat alle Empfehlungen
freigegeben. Die wichtigsten:
- **A1** (kritisch): Grafik als Phase 4 statt neben dem Code; alle Phasen nacheinander.
- **A2** (kritisch): Die Spec nennt keine Datei und keine Werte des Style-Guides mehr.
- **B1** (hoch): Unter der Maus nimmt ein Button `font_hover_color`, auch ohne Fokus; die helle
  Schrift der gewählten Zeile kommt deshalb aus dem Code (R15).
- **B2** (hoch): Die Eingabesperre beim Hinausfahren hatte ein Loch über `mouse_entered` und
  Mausbewegung; jetzt rekursive Sperre oder Sperrfläche und ein Flag `_leaving` (R8).
- **C1** bis **C26**: SC-002 ab dem Beginn der Fahrt, erster Schritt auf 1/60 s gedeckelt (R6),
  Zeile relativ zum Communicator, eigene Wache vor den Einträgen, Reihenfolge Einträge vor Fahrt,
  Breiten und Abstände auf `LCD` aus einer Quelle, Lage und Farbe der Anzeige je Gehäuse, Baustein
  in drei Tasks, korrigierte Kontrastzahl in R3, Entscheider in research.md, Doku in Phase 6.

Eingearbeitet in Spec (Clarifications „Analyse 2026-10-27“), research.md (R3 bis R8, R10 bis R14,
neu R15), Datenmodell, Verträge, Quickstart, hier und in tasks.md (neu T001 bis T038).

## Prüfer je Phase

Jede Phase mit Sichtbarem oder Texten endet mit der [C]-Aufgabe „Phasenprüfung“ durch
`/dcl-phasenpruefung` vor Klaus' Abnahme (`docs/ki_workflow/ki_pruefung.md`).

| Phase | Ändert | Prüfer | Maßstab für die Prüfer |
|---|---|---|---|
| 1 Style-Guide | den Maßstab selbst | keine; Klaus nimmt ab | – |
| 2 Baustein Communicator | die Probeszene | Stil | Baustein Communicator, `tokens.json`; Bildschirmfoto der Probeszene |
| 3 Seiten auf der Anzeige | Menü und Liste auf `lcd` | Stil | Bausteine Menü, Liste, Communicator, `tokens.json`; Bildschirmfotos |
| 4 Grafik | zwei Bilder | Stil | `README.md` (Szenen und Figuren, Farben), Leonardo-Workflow, Stilanker C2; die gerasterten Bilder ×4 |
| 5 Titel | den ganzen Titel | Stil, Text | wie 3, dazu Hinweis, Meldung, README (Bildaufbau, Bewegung, Logo); `Sprache.md` nur, falls sich doch ein Text ändert; Bildschirmfotos aus titelbildschirm.md |
| 6 Abschluss | Doku | bei der Lückensuche Stil einmal über das ganze Feature | wie 5 |

Neue Texte entstehen in diesem Feature nicht (Spec, Annahmen); der Text-Prüfer läuft deshalb nur in
Phase 5 als Gegenprobe, dass sich kein Text verschoben oder gekürzt hat.
