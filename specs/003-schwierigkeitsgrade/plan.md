# Implementation Plan: Schwierigkeitsgrade der Zeitleiste

**Branch**: `feature/003-schwierigkeitsgrade` | **Date**: 2026-10-21 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/003-schwierigkeitsgrade/spec.md`

## Summary

Ein Spiel startet mit einem der Grade Leicht, Mittel oder Schwer. Es bleibt ein Katalog. Leicht
und Schwer haben je ein Profil aus Start-Modifikatoren, die beim Spielstart Chancen von
Ereignissen über Wahrscheinlichkeit verschieben, mit dem Mechanismus der Modifikatoren aus
Feature 002. Mittel ist der Katalog allein. Seed und Grad sind unabhängig: Derselbe Seed mit
demselben Grad ergibt dasselbe Spiel, zwei Grade mit demselben Seed unterscheiden sich nur dort,
wo ein Profil eine Schwelle verschiebt. In der Werkstatt pflegt Klaus die Profile in einem eigenen
Reiter, wählt im Simulator einen Grad und vergleicht in der Statistik alle drei.

Technischer Ansatz (Details in [research.md](research.md), Verträge unter [contracts/](contracts/)):
- **Grad als Aufzählung:** `Difficulty.Level { LEICHT, MITTEL, SCHWER }`, Vorgabe Mittel, mit den
  Namen für Datei und Text an einer Stelle (R1).
- **Profile in der Katalogdatei:** ein Abschnitt `"profiles"` mit `"leicht"` und `"schwer"`, je
  eine Liste von Start-Modifikatoren in derselben Form wie Modifikatoren in Proben. Ein geänderter
  Wert ändert genau eine Zeile. Die Formatnummer bleibt 1, Dateien aus Feature 002 laden weiter
  (R2, R3).
- **Strenge Prüfung:** Ein Profil für Mittel oder einen unbekannten Grad ist ein Strukturfehler
  V22. Start-Modifikatoren prüfen die neuen Regeln V25 bis V30. Fehlerhafte nimmt
  `without_faulty()` aus, ohne das Ereignis zu treffen, auf das sie zeigen (R4, R8).
- **Zwei Listen im Lauf:** `TimelineRun` setzt die Start-Modifikatoren in `_init()` in eine eigene
  Liste, bevor zum ersten Mal gewürfelt wird. Eingriffe bleiben in `modifiers`. So unterscheiden
  sich beide durch ihre Herkunft, nicht durch ihre Kennung: Start-Modifikatoren lassen sich nicht
  entfernen, landen nie in Proben, und Eingriffe wirken in jedem Grad gleich (R5, R6).
- **Werkstatt:** Reiter „Schwierigkeitsgrade“ mit Tabelle und Feldern, Chance je Grad im Formular
  nur zum Lesen, Grad und umschaltbarer Vergleich im Simulator, Proben mit Grad, Statistik mit
  einem Grad oder allen drei, Seed für Seed (R10 bis R15).
- **Textausgabe** mit `--grad`; die Kopfzeile nennt den Grad (R16).
- **Feste Größe:** Mit Mittel sind Fahrplan und Protokoll Zeichen für Zeichen wie in Feature 002,
  belegt an einer eingefrorenen Grundlinie, bevor sich der Lauf ändert (R17).

## Technical Context

**Language/Version**: GDScript, typisiert, Godot 4.7.2 (Forward+)

**Primary Dependencies**: keine neuen. Godot-Bordmittel wie in Feature 002: `JSON`,
`FileAccess`, `UndoRedo`, `Tree`, `OptionButton`, `HSplitContainer`. Tests mit GUT 9.7.1.

**Storage**: der Ereigniskatalog `src/data/event_catalog.json` mit dem neuen Abschnitt
`"profiles"`, gepflegt mit der Werkstatt (Verfassung, Grundsatz V, Ausnahme Ereigniskatalog).
Proben unter `src/tools/werkstatt/proben/` mit dem neuen Schlüssel `"difficulty"`. Keine
Spielstände; wenn sie mit 11-01 kommen, speichern sie den Grad mit (Spec, Annahmen).

**Testing**: GUT 9.7.1 headless mit Test-Katalogen unter `src/test/fixtures/` und einer
eingefrorenen Grundlinie für Mittel. Reiter, Formular, Simulator und Statistik prüft Klaus von Hand
nach [quickstart.md](quickstart.md).

**Target Platform**: entwickelt und geprüft auf macOS (Apple Silicon); das Spiel ist für Windows,
macOS und Linux gedacht. Die Werkstatt läuft nur in der Entwicklungsumgebung und wird nicht
exportiert. Die neuen Kernklassen `Difficulty` und `DifficultyProfile` gehören zum Spiel.

**Project Type**: Desktop-Spiel (Godot-Projekt unter `src/`) mit Entwicklungswerkzeug

**Performance Goals**: Vergleich aller drei Grade über je 1.000 Spiele mit dem vorhandenen Katalog
in höchstens 90 s (SC-004). Gemessen in Feature 002: 1.000 Spiele in 7,9 s headless, für drei
Grade also rund 24 s. Prüfung und Änderung samt Prüfung mit 500 Ereignissen bleiben unter 100 ms
(SC-011 von Feature 002).

**Constraints**:
- Wiederholbar: Katalog, Seed und Grad ergeben denselben Fahrplan (FR-008, SC-001).
- Ein Grad verschiebt nur Schwellen; Würfel und ihre Zwecke bleiben (FR-009, R5 von Feature 002).
- Die Zeitleiste meldet nur, sie wendet keine Wirkung an (Verfassung).
- Mittel ist bytegleich zu Feature 002; die Startprobe bleibt still.
- Kanonisches JSON, eine Zeile je geändertem Wert (FR-005, SC-006).
- Nur Desktop mit Maus und Tastatur.

**Scale/Scope**: drei Grade, zwei Profile, heute sechs Ereignisse über Wahrscheinlichkeit im
Katalog. Zwei neue Kernklassen und sieben geänderte, ein geändertes Autoload. In der Werkstatt ein
neues Panel und sieben geänderte Dateien, darunter die Textausgabe. Fünf neue Testdateien und
zwölf geänderte, dazu rund 17 neue Fixtures, davon sechs für die Grundlinie. Drei vorhandene
Fixtures bekommen den Abschnitt `profiles` (R17).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Grundsatz | Prüfung | Vor Phase 0 | Nach Phase 1 |
|---|---|---|---|
| I. Nur Desktop | Neue Bedienung nur in der Werkstatt, mit Maus und Tastatur: Auswahlfelder, Häkchen, Tabelle, Felder mit Enter und Hinweis beim Überfahren. Keine Touch-Eingaben, Forward+ bleibt | erfüllt | erfüllt |
| II. Klaus entscheidet, der Agent baut, Claude plant und prüft | Der Plan enthält nur Signaturen, keine Rümpfe. Die Aufteilung `[K]`/`[A]`/`[C]` folgt in den Tasks; umgesetzt wird phasenweise auf Klaus' Auftrag mit Lernnotizen in `lernnotizen.md`. Klaus' Entscheidung im Plan (R9) steht mit Datum da. `/speckit-implement` wird nicht verwendet | erfüllt | erfüllt |
| III. Erst spezifizieren | Spec mit sieben Klärungen, eigener Branch, System 01 in der Spec genannt. Godot-Details erst hier, 18 Entscheidungen mit Alternativen in research.md. Die Präzisierung von FR-017 hat Klaus entschieden | erfüllt | erfüllt |
| IV. Ein Look: der Style-Guide | Das Spiel bekommt keine neue Oberfläche. Die Werkstatt nutzt nur Bausteine aus dem Abschnitt „Werkzeuge“: Tabelle mit Zebra, Auswahlfeld, Häkchen, Feld mit Fehlerkontur, gedämpfter Text, Fehlerhinweis. Ein neuer Baustein käme zuerst in den Style-Guide (R11, R15) | erfüllt | erfüllt |
| V. Daten sauber halten | Die Profile stehen in der Katalogdatei, wie Klaus in der Klärung entschieden hat, und werden mit der Werkstatt gepflegt. Die Ausnahme Ereigniskatalog deckt das, denn sie gilt der Datei und ihrer Pflege in der Werkstatt. game_bible unberührt | erfüllt | erfüllt, mit Hinweis unten |
| Technische Rahmenbedingungen | Godot 4.7 und GUT 9.7.1, Projekt in `src/`. `GameClock` und `Timeline` bleiben Autoloads. Die Timeline meldet weiter nur; ein Grad wirkt nur über Chancen in der Timeline, also steht alles, was ein Ereignis auslösen kann, weiter dort | erfüllt | erfüllt |
| Arbeitsweise | Dokumente deutsch. `.uid` der neuen Skripte wird committet. `export_presets.cfg` bleibt unberührt; `tools/*` ist schon ausgeschlossen | erfüllt | erfüllt |

Ergebnis: bestanden, vor und nach dem Entwurf, ohne Verstöße, die begründet werden müssten.

Hinweis zu Grundsatz V: Die Ausnahme spricht von „den Ereignissen der Zeitleiste“. Die Profile sind
keine Ereignisse, stehen aber in derselben Datei und werden genauso gepflegt. Claude hält das für
gedeckt. Klarer würde es mit einer Klarstellung als PATCH 2.1.2: „die Ereignisse und die Profile
der Schwierigkeitsgrade“. Das blockiert nichts und ist Klaus' Entscheidung (siehe „Offene
Entscheidungen“).

## Project Structure

### Documentation (this feature)

```text
specs/003-schwierigkeitsgrade/
├── spec.md                      # Spezifikation, geklärt, im Plan präzisiert (FR-017)
├── plan.md                      # dieser Plan
├── research.md                  # Phase 0: Entscheidungen R1–R18
├── data-model.md                # Phase 1: Klassen, Felder, Prüfregeln V25–V30
├── quickstart.md                # Phase 1: Prüfanleitung
├── contracts/
│   ├── ereigniskatalog.md       # Abschnitt „profiles“ in der Katalogdatei
│   ├── zeitleiste.md            # Kern, Autoload, Textausgabe, Tests
│   └── werkstatt.md             # Reiter, CatalogEditor, Formular, Simulator, Proben, Statistik
├── checklists/
│   └── requirements.md          # Qualitätsprüfung der Spec
├── tasks.md                     # entsteht mit /speckit-tasks
└── lernnotizen.md               # entsteht bei der Umsetzung, eine Notiz je [A]-Task
```

### Source Code (repository root)

```text
src/                                     # Godot-Projekt
├── core/
│   ├── timeline.gd                      # geändert: start_game() mit Grad, get_difficulty()
│   └── timeline/
│       ├── difficulty.gd                # neu
│       ├── difficulty_profile.gd        # neu
│       ├── chance_modifier.gd           # geändert: from_dict(), to_dict()
│       ├── event_catalog.gd             # geändert: profiles
│       ├── catalog_validator.gd         # geändert: V25–V30
│       ├── timeline_run.gd              # geändert: Grad, Start-Modifikatoren
│       ├── timeline_message.gd          # geändert: START_MODIFIER
│       ├── schedule_text.gd             # geändert: Kopfzeile
│       └── timeline_statistics.gd       # geändert: mehrere Grade
├── data/event_catalog.json              # bekommt den Abschnitt, wenn Klaus speichert
├── tools/werkstatt/
│   ├── difficulty_panel.tscn / .gd      # neu: Reiter „Schwierigkeitsgrade“
│   ├── werkstatt.tscn / .gd             # geändert
│   ├── catalog_editor.gd                # geändert
│   ├── event_form.gd                    # geändert
│   ├── simulator_panel.tscn / .gd       # geändert
│   ├── statistics_panel.tscn / .gd      # geändert
│   ├── what_if_probe.gd                 # geändert
│   └── fahrplan_ausgabe.gd              # geändert: --grad
└── test/                                # neue und geänderte Tests, fixtures/
```

**Structure Decision**: Die Aufteilung aus Feature 002 bleibt. Die Grade gehören zum Kern unter
`src/core/timeline/`, weil das Spiel sie braucht; alles für die Pflege liegt in der Werkstatt unter
`src/tools/werkstatt/` und wird nicht exportiert. Einzelheiten stehen in den Verträgen.

## Complexity Tracking

Keine Einträge, die Prüfung der Verfassung zeigt keine Verstöße.

## Vorarbeiten vor dem Bauen

1. **Grundlinie einfrieren** (R17), als erste Aufgabe, solange der Lauf noch der aus Feature 002
   ist. Fahrplan und Protokoll der eingefrorenen Übernahme für die Seeds 1, 4711 und 99999 kommen
   als Fixtures nach `src/test/fixtures/`. An ihnen misst ein Test, dass Mittel Zeichen für Zeichen
   bleibt, wie es war.
2. **Style-Guide:** keine Vorarbeit nötig. Alle Bausteine gibt es schon (Grundsatz IV, R11).

## Umsetzungsphasen (Vorschlag für die Tasks)

Jede Phase endet mit grünen Tests, Lernnotizen und Klaus' Abnahme; erst dann folgt die nächste.

| Phase | Inhalt | Story |
|---|---|---|
| 1 | Grundlage: Grundlinie einfrieren; `Difficulty`, `DifficultyProfile`, `ChanceModifier.from_dict()`/`to_dict()`; Profile im `EventCatalog` (Lesen, Schreiben, `to_dict()`, Kopie, `without_faulty()`); V22 für den Abschnitt und V25 bis V30 mit kaputten Fixtures. Dazu, was sonst Tests aus Feature 002 bräche: `catalog_minimal.json`, `catalog_500.json` und `catalog_alle_arten.json` bekommen den Abschnitt, die Rundreise der Übernahme ihre neue Erwartung, die Sicherungskopie baut aus `to_dict()`. Zur Abnahme speichert Klaus den echten Katalog einmal in der Werkstatt (R3) | blockiert alles |
| 2 | Spielstart mit Grad: `TimelineRun` (Grad, Start-Modifikatoren, `chance_info()`, Begründung, Protokoll, `remove_modifier()`), `TimelineMessage`, Autoload (`start_game()`, `get_difficulty()`, Meldungen), Kopfzeile und Textausgabe mit `--grad`; SC-001, SC-002, Mittel gegen Grundlinie | US1 (P1) |
| 3 | Profile in der Werkstatt in zwei Teilen. Teil 1, Kern: `CatalogEditor` mit Start-Modifikatoren, jede Änderung ersetzt das ganze Profil (R10), Verweise beim Löschen und Umbenennen, `content_key()`; SC-006. Teil 2, Oberfläche: `DifficultyPanel`, vierter Reiter, Prüfmeldung führt zum Feld, Löschdialog, „Je Grad“ im Formular. Zur Abnahme legt Klaus die Profile im echten Katalog an (SC-005, R18) | US2 (P1) |
| 4 | Simulator: `WhatIfProbe` mit Grad; Auswahl des Grads, Neubau beim Wechsel, Vergleich umschaltbar mit Text, Markierungen, Protokoll, Modifikatoren, Liste der Proben | US3 (P2) |
| 5 | Statistik: `TimelineStatistics` mit mehreren Graden Seed für Seed; Auswahl und Vergleichstabelle; SC-003, SC-004 | US4 (P2) |
| 6 | Abschluss: CLAUDE.md (Tabelle „Aufbau“, Beschreibung der Timeline mit Grad), `docs/features/Features.md`, `Feature_Ideas.md` (11-05 und 01-05 mit `start_game()` samt Grad), Lückensuche mit `/speckit-converge`, Quickstart vollständig, Gesamtabnahme | – |

Die Phasen laufen in dieser Reihenfolge. Phase 4 und 5 brauchen den Lauf aus Phase 2; Phase 3
kommt davor, damit Klaus die Profile anlegen kann, mit denen er danach Simulator und Statistik
prüft.

## Was Klaus dabei lernt

Kandidaten für Lernnotizen und für `[K]`-Aufgaben, die Klaus sich aussucht:
- Eine Aufzählung als Typ und warum sie zur Laufzeit trotzdem eine Zahl ist: `Difficulty.Level`
  und `is_valid()` (Phase 1).
- Ein freiwilliger Abschnitt in einem Dateiformat, ohne die Formatnummer zu erhöhen (Phase 1).
- Ein Parameter mit Vorgabe, damit alte Aufrufe gültig bleiben: `TimelineRun.new(catalog, seed)`
  ist weiter Mittel (Phase 2).
- Herkunft statt Namensregel: zwei Listen im Lauf statt einer Vorsilbe in der Kennung (Phase 2).
- `UndoRedo` mit Einträgen in verschachtelten Listen (Phase 3).
- Ein Panel aus Tabelle und Feldern nebeneinander, mit `HSplitContainer` (Phase 3).
- **Gut als `[K]`-Aufgabe:** die Zeile „Je Grad“ im Formular. Sie ist klein und klar umrissen:
  eine Zeile in ein vorhandenes Formular einfügen und eine fertige Hilfe aus dem Kern aufrufen
  (`DifficultyProfile.chance_periods()`, Phase 3).
- **Ebenfalls geeignet:** das Häkchen „mit Mittel vergleichen“ im Simulator, ein Signal und ein
  neuer Vergleichslauf (Phase 4).
- Ein `Tree` mit vielen Spalten und Hinweisen je Spalte (Phase 5).

## Was sich an Feature 002 ändert

| Teil | Bisher | Danach | Wer es merkt |
|---|---|---|---|
| Kopfzeile der Textausgabe | „# Seed 4711, bis 31.12.1999“ | „# Seed 4711, Grad Mittel, bis 31.12.1999“ | `test_schedule_text.gd` (drei Stellen), wer Ausgaben vergleicht |
| Rundreise alter Kataloge | bytegleich | Komma hinter `"format": 1`, dazu vier Zeilen `"profiles"` | `test_event_catalog.gd` an der Übernahme; das erste Speichern des echten Katalogs, deshalb speichert Klaus ihn in Phase 1 einmal |
| Fixtures, mit denen Tests Text vergleichen | ohne Abschnitt | `catalog_minimal.json` und `catalog_500.json` mit leerem, `catalog_alle_arten.json` mit gefülltem Abschnitt | `test_catalog_editor.gd`, `test_werkstatt_scene.gd`, `test_large_catalog.gd`, `test_event_catalog.gd` |
| `EventCatalog.KEYS`, `to_json()` | drei Schlüssel | vier, über `to_dict()` | die Sicherungskopie, die ihr Dictionary bisher selbst baute; sie nutzt `to_dict()` schon ab Phase 1 |
| Ergebnistext der Statistik | „Ergebnis über 200 Spiele, Seeds 1 bis 200, ohne Eingriffe; …“ | mit Grad: „…, Seeds 1 bis 200, Mittel, ohne Eingriffe; …“ | `test_statistics_panel.gd` |
| Proben | Seed, Stand, Eingriffe | dazu `"difficulty"`, immer geschrieben | `test_what_if_probe.gd` vergleicht die ganze Datei; ältere Proben gelten als Mittel |
| Teiler der Werkstatt | sechs | dazu der im neuen Reiter | `test_werkstatt_settings.gd` |
| `chance_info()` | vier Schlüssel | dazu `"start_modifiers"`; `"sum"` rechnet sie mit | der Simulator; für Mittel ändert sich nichts |
| `TimelineMessage.Kind` | sieben Arten | dazu `START_MODIFIER` am Ende | `Timeline._send()`, kein Signal |
| `TimelineRun.new()` | Katalog, Seed | dazu der Grad, Vorgabe Mittel | niemand, alte Aufrufe bleiben gültig |
| `TimelineStatistics.new()` | Katalog, Anzahl, erster Seed | dazu die Grade | das Statistik-Panel |
| `CatalogValidator.validate()` | Kategorien zuletzt | danach die Profile | Reihenfolge in der Prüfung |
| `delete_event()`, `rename_event()` | Folgen und Bedingungen | dazu Start-Modifikatoren, über ganze Profile | Löschdialog, Klaus |

Gleich bleiben der Stand im Simulator („Stand: … · Seed 4711“) und die Texte der Markierungen beim
Vergleich mit demselben Grad; ihre Tests aus Feature 002 bleiben unverändert (R13).

## Änderungen an der Spec nach dem Plan

Beim Planen fiel ein Widerspruch auf: FR-017 verlangte, Verweise aus Profilen auch vor dem
Umbenennen eines Ereignisses zu nennen, „wie die übrigen Verweise“. Folgen und Bedingungen zieht
die Werkstatt seit Feature 002 aber still nach. Klaus hat am 2026-10-21 entschieden: still
nachziehen, genannt wird nur beim Löschen (R9). Präzisiert sind FR-017 und der Edge Case
„Kaputter Verweis“, die Frage steht unter „Clarifications“, „Plan 2026-10-21“.

## Offene Entscheidungen für Klaus

Beides blockiert nichts:
- **Startwerte der Profile** (R18): Claudes Vorschlag ist eine Tabelle für die sechs Ereignisse
  über Wahrscheinlichkeit. Klaus legt die Profile zur Abnahme von Phase 3 in der Werkstatt an und
  stellt sie mit der Statistik nach.
- **Verfassung, Grundsatz V:** Die Ausnahme Ereigniskatalog könnte die Profile ausdrücklich nennen,
  als PATCH 2.1.2. Claude hält den heutigen Wortlaut für ausreichend.
