# Implementation Plan: Zeitleisten-Werkstatt

**Branch**: `feature/002-zeitleisten-werkstatt` | **Date**: 2026-10-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-zeitleisten-werkstatt/spec.md`

## Summary

Die Zeitleiste wird nach dem Fahrplan-Modell umgebaut: Aus einem Ereigniskatalog und einem Seed
entsteht je Spiel ein Fahrplan, den das Spiel mit der Spieluhr abspult und dessen Termine die
Zeitleiste meldet, ohne Wirkungen anzuwenden. Gepflegt wird der Katalog in der
Zeitleisten-Werkstatt, die zugleich Simulator und Statistik ist. Eine Textausgabe zeigt den
Fahrplan ohne Fenster.

Technischer Ansatz (Details in [research.md](research.md), Verträge unter [contracts/](contracts/)):
- **Kern ohne Node:** `TimelineRun` (RefCounted) legt den Fahrplan an, spielt Tage ab und gibt
  Meldungen zurück. Das Autoload `Timeline` hängt ihn an `GameClock` und macht Signale daraus. Die
  bisherigen Signale `event_fired` und `effect_applied` bleiben, neu kommen Enden und Entfälle
  dazu.
- **Katalog als JSON:** `src/data/event_catalog.json`, kanonisch geschrieben: sortiert, Tabs,
  ganze Zahlen als `int`. So ändert eine Feldänderung genau eine Zeile. Die 25 Ereignisse aus
  `EventDatabase` werden per Skript übernommen, dazu kommen Kalender-Ereignisse.
- **Würfel je Ereignis:** Jedes Ereignis hat für jeden Zweck einen eigenen `RandomNumberGenerator`
  mit Startwert aus SHA-256 über Seed, Zweck und Kennung. Je Monat gibt es feste zwei Würfe,
  deshalb ändern Eingriffe nur Schwellen, nie fremde Würfe.
- **Werkstatt als Szene:** `src/tools/werkstatt/`, Start mit F6, volle Auflösung, eigenes Theme in
  den Farben des Computerladens. Sie hat Liste, Formular, Prüfung und einen Zeitstrahl mit
  Ziehen, Zoom und Tooltips. Alle Änderungen laufen über `CatalogEditor` mit `UndoRedo`.
- **Simulator und Statistik** arbeiten auf einer Kopie des aktuellen, auch ungespeicherten
  Katalogs. Die Statistik rechnet in Häppchen nach Zeitbudget und lässt sich abbrechen.
- **Was wäre, wenn:** Eingriffe im Simulator lassen sich als Probe speichern und laden. Jede Probe
  hält das Eingriffsprotokoll mit dem Tag jedes Eingriffs und spielt es beim Laden nach. Der
  Fahrplan markiert, was die Eingriffe gegenüber demselben Seed ohne Eingriffe ändern
  (`ScheduleDiff`). Eine Sicherungskopie unter `user://` schützt vor Abstürzen (Review, R22 bis
  R24).
- **Kalender:** Weihnachtsgeschäft, Jahreszeiten und CeBIT sind jährliche Ereignisse mit Dauer.
  `GameClock.season_changed` entfällt.

## Technical Context

**Language/Version**: GDScript, typisiert, Godot 4.7.2 (Forward+)

**Primary Dependencies**: keine neuen. Godot-Bordmittel: `RandomNumberGenerator`
(`rand_weighted`), `JSON`, `FileAccess`, `UndoRedo`, `String.sha256_buffer()`, `PopupMenu`,
eigenes Zeichnen. Tests mit GUT 9.7.1.

**Storage**: Ereigniskatalog als JSON-Datei `src/data/event_catalog.json`, gepflegt mit der
Werkstatt; außer ihr schreibt ihn nur einmal die Übernahme (Verfassung 2.1.0, Grundsatz V). Keine
Spielstände; das Modell ist so angelegt, dass Seed, Fahrplan und Eingriffe genügen (11-01).

**Testing**: GUT 9.7.1 headless mit Test-Katalogen unter `src/test/fixtures/`, einem
Schnappschuss der alten Daten und einer eingefrorenen Kopie der Übernahme. Rauchtest für die
Werkstatt-Szene; Zeitstrahl, Formulare, Fenster und Look von Hand nach
[quickstart.md](quickstart.md).

**Target Platform**: Entwickelt und geprüft auf macOS (Entwicklungsrechner, Apple Silicon); das
Spiel ist für Windows, macOS und Linux gedacht (Nachweis mit 11-03). Die Werkstatt läuft nur in
der Entwicklungsumgebung und wird nicht exportiert.

**Project Type**: Desktop-Spiel (Godot-Projekt unter `src/`) mit Entwicklungswerkzeug

**Performance Goals**: ein ganzes Spiel 1985–1999 unter 1 s, Statistik über 1.000 Spiele unter
30 s (SC-004, mit dem übernommenen Katalog). Mit 500 Ereignissen: ein Spiel unter 2 s, Statistik
unter 5 Minuten; Prüfung und Ziehen unter 100 ms (SC-011).

**Constraints**:
- Wiederholbar: gleicher Katalog, Seed und gleiche Eingriffe ergeben dasselbe Protokoll, egal in
  welchen Schritten die Uhr läuft (FR-014, FR-015).
- Die Zeitleiste meldet nur, sie wendet nichts an (Verfassung).
- Kanonisches JSON; beim Spielstart keine Ausgabe; die Werkstatt ist nicht im Export.
- Nur Desktop mit Maus und Tastatur.

**Scale/Scope**: 25 übernommene und 6 neue Kalender-Ereignisse, ausgelegt bis 500 (R21). Dazu
17 Klassen im Kern, ein umgebautes Autoload, zwei geänderte Kernklassen (`GameClock`, `GameDate`),
die Werkstatt mit rund elf Szenen und Skripten und 17 Testdateien, davon zwei bestehende, die sich
ändern.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Grundsatz | Prüfung | Vor Phase 0 | Nach Phase 1 |
|---|---|---|---|
| I. Nur Desktop | Die Werkstatt setzt Maus und Tastatur voraus: Hover, Tooltips, Rechtsklick, Ziehen. Kürzel Cmd bzw. Ctrl über `command_or_control_autoremap`, keine Touch-Eingaben, Forward+ bleibt | erfüllt | erfüllt |
| II. Klaus entscheidet, der Agent baut, Claude plant und prüft | Der Plan enthält nur Signaturen, keine Rümpfe. Die Aufteilung `[K]`/`[A]`/`[C]` folgt in den Tasks, umgesetzt wird phasenweise auf Klaus' Auftrag mit Lernnotizen; `/speckit-implement` wird nicht verwendet | erfüllt | erfüllt |
| III. Erst spezifizieren | Spec mit 5 Fragen geklärt und im Review nachgeschärft, eigener Branch, Godot-Details erst hier, Entscheidungen mit Alternativen in research.md (R1–R24) | erfüllt | erfüllt |
| IV. Ein Look: der Style-Guide | Die Werkstatt nutzt Farben der Hauptpalette. Wie, regelt ein neuer Abschnitt „Werkzeuge“ im Style-Guide, der vor dem Bau der Werkstatt entsteht (siehe „Vorarbeiten“). Das Spiel selbst bekommt keine neue Oberfläche | erfüllt mit Vorarbeit | erfüllt mit Vorarbeit |
| V. Daten sauber halten | Katalog als Datei im Spielprojekt, gepflegt mit der Werkstatt (Ausnahme Ereigniskatalog, Verfassung 2.1.0); game_bible unberührt | erfüllt | erfüllt |
| Technische Rahmenbedingungen | Godot 4.7 und GUT 9.7.1, Projekt in `src/`. `GameClock` und `Timeline` bleiben Autoloads, die Timeline meldet weiter nur per Signal. Kalender-Ereignisse ziehen in die Timeline, damit alles, was ein Ereignis auslösen kann, dort steht | erfüllt | erfüllt |
| Arbeitsweise | Dokumente deutsch; `.uid` verschobener und neuer Skripte werden committet; `export_presets.cfg` wird nach dem Ergänzen von `tools/*` vor dem Commit angesehen | erfüllt | erfüllt |

Ergebnis: bestanden, ohne Verstöße, die begründet werden müssten. Grundsatz IV gilt nur dann als
erfüllt, wenn der Abschnitt „Werkzeuge“ im Style-Guide steht, bevor die Werkstatt gebaut wird.

## Project Structure

### Documentation (this feature)

```text
specs/002-zeitleisten-werkstatt/
├── spec.md                      # Spezifikation, geklärt
├── plan.md                      # dieser Plan
├── research.md                  # Phase 0: Entscheidungen R1–R24
├── data-model.md                # Phase 1: Klassen, Felder, Zustände, Prüfregeln V01–V24
├── quickstart.md                # Phase 1: Prüfanleitung
├── contracts/
│   ├── ereigniskatalog.md       # Dateiformat des Katalogs
│   ├── zeitleiste.md            # Kern, Autoload, Textausgabe, Tests
│   └── werkstatt.md             # Werkstatt: Szenen, CatalogEditor, Bedienung
├── checklists/
│   ├── requirements.md          # Qualitätsprüfung der Spec
│   └── review.md                # Review der Anforderungen, von Klaus entschieden
├── tasks.md                     # Aufgaben je Phase (/speckit-tasks), nach der Analyse überarbeitet
└── lernnotizen.md               # entsteht bei der Umsetzung, eine Notiz je [A]-Task
```

### Source Code (repository root)

```text
src/                                 # Godot-Projekt
├── core/
│   ├── game_clock.gd                # geändert: season_changed entfällt
│   ├── game_date.gd                 # geändert: ISO-Datum, Altlasten entfallen
│   ├── timeline.gd                  # umgebaut: Hülle um TimelineRun
│   └── timeline/                    # neu: der Kern, 17 Klassen
├── data/
│   └── event_catalog.json           # neu; event_database.gd entfällt
├── scenes/                          # timeline_demo entfällt
├── tools/werkstatt/                 # neu: Werkstatt, Textausgabe, proben/; nicht im Export
├── ui/ui_palette.gd                 # geändert: by_token()
├── export_presets.cfg               # geändert: tools/* ausgeschlossen
└── test/                            # neue und geänderte Tests, fixtures/
```

**Structure Decision**: Die vorhandene Aufteilung bleibt. Der Kern bekommt einen Unterordner
`src/core/timeline/`, weil er aus 17 kleinen Klassen besteht. Werkzeuge, die Godot-Code brauchen,
liegen unter `src/tools/` und werden wie `test/` vom Export ausgeschlossen. Werkzeuge außerhalb
von Godot (Python) bleiben unter `tools/` im Repo-Root. Einzelheiten stehen in den Verträgen.

## Complexity Tracking

Keine Einträge, die Prüfung der Verfassung zeigt keine Verstöße.

## Vorarbeiten vor dem Bauen

1. **Style-Guide, Abschnitt „Werkzeuge“** (Grundsatz IV), vor dem Bau der Werkstatt. Der
   Abschnitt legt fest:
   - Werkzeuge laufen in voller Auflösung, nicht im 640 × 360-Raster;
   - eine Schrift ohne Pixelraster, vorgeschlagen Godots eingebaute Schrift (R14);
   - Farbrollen aus der Hauptpalette: Grund, Fläche, Text, gedämpfter Text, Auswahl, Fehler,
     Warnung, Ziehen;
   - die Farben, die Kategorien tragen dürfen, mit mindestens 3 : 1 Kontrast zum Grund des
     Zeitstrahls und ohne die Grundfarbe, dazu die Startfarben der zehn Kategorien (R14);
   - Text mit mindestens 4,5 : 1 Kontrast zu seinem Grund (FR-029); Titel im Zeitstrahl stehen in
     Textfarbe auf dem Grund, nicht auf der Kategorienfarbe.

   Claude entwirft ihn, Klaus gibt ihn frei.
2. **Schnappschuss der alten Daten** (R19), bevor der alte Code fällt. Er hält die 19 historischen
   Ereignisse so fest, wie die alte Engine sie liefert, als Prüfmaßstab für SC-005.

## Umsetzungsphasen (Vorschlag für die Tasks)

Jede Phase endet mit grünen Tests, Lernnotizen und Klaus' Abnahme; erst dann folgt die nächste.

| Phase | Inhalt | Story |
|---|---|---|
| 1 | Setup: Style-Guide „Werkzeuge“, Schnappschuss der alten Daten, Übernahme in `event_catalog.json`, Export-Filter `tools/*` | – |
| 2 | Grundlage: `GameDate` (Tage vor 1985, ISO-Datum), `UiPalette`, Datenklassen. `TimelineEvent` und `EventEffect` umbauen und im selben Schritt alte Engine, `EventDatabase`, Demo und alte Tests entfernen. `EventCatalog`, Katalog normalisieren und einfrieren, Prüfregeln, `ScheduleEntry`, stille Hülle des Autoloads | blockiert alles |
| 3 | Fahrplan abspulen: Würfel, Modifikatoren, Meldungen, `TimelineRun` (fix, gesetzt, Würfelrunde, Folgeereignisse, Bedingungen, Stichtage), Autoload, Textausgabe, Prüfung der Übernahme, Probe-Export (R4) | US1 (P1) |
| 4 | Werkstatt, Grundgerüst: Theme, `CatalogEditor` mit Rückgängig und Verwerfen, Fenster, Liste, Formular, Kategorien, Prüfung, Verdrahtung, Speichern, Schließen, Sicherungskopie | US2 (P1) |
| 5 | Kalender und Dauer: Dauer, jährliche Ereignisse, `ONCE`/`DURING`, Kalender-Ereignisse im Katalog, `season_changed` und `GameDate`-Altlasten entfernen | US3 (P2) |
| 6 | Zeitstrahl: Zeichnen, Zoom, Ziehen mit Vorschau, Tooltips, Rechtsklick, Doppelklick | US4 (P2) |
| 7 | Simulator: Seed, Schalter, Fahrplan, Protokoll, Begründung | US5 (P2) |
| 8 | Was wäre, wenn: Eingriffe und Eingriffsprotokoll im Kern, Vergleich mit `ScheduleDiff`, Proben mit Neu abspielen, Eingriffe im Simulator | US6 (P2) |
| 9 | Statistik nach Zeitbudget, Ergebnis-Tabelle, Verteilung | US7 (P3) |
| 10 | Abschluss: großer Katalog (SC-011), CLAUDE.md (Tabelle „Aufbau“, Beschreibung der Timeline), Features.md, Lückensuche mit `/speckit-converge`, Quickstart vollständig, Abnahme | – |

Die Phasen laufen in dieser Reihenfolge. Phase 5 braucht die Werkstatt aus Phase 4, denn Klaus legt
die Kalender-Ereignisse dort an.

## Was Klaus dabei lernt

Kandidaten für Lernnotizen und für `[K]`-Aufgaben, die Klaus sich aussucht:
- Datenklassen auf `RefCounted` mit `static func from_dict()` als Fabrik (Phase 2).
- JSON lesen mit Fehlerzeile und kanonisch schreiben, `int` und `float` in JSON (Phase 2).
- Ein Kern ohne Node, eine Hülle mit Signalen, `call_deferred()` (Phase 3).
- `RandomNumberGenerator` je Ereignis, `seed` und `state`, SHA-256 zum Mischen (Phase 3).
- SceneTree-Skript mit `-s` und eigenen Argumenten (Phase 3).
- `UndoRedo` zur Laufzeit, ungespeicherte Änderungen über `get_version()` (Phase 4).
- Theme für einen Teilbaum, Fenster zur Laufzeit umstellen (Phase 4).
- Eigenes Control mit `_draw()`, `_gui_input()`, `_get_tooltip()` und `PopupMenu` (Phase 6). Gut
  geeignet als `[K]`-Aufgabe, weil Klaus genau das später für Spielansichten braucht.
- Arbeit in Häppchen nach Zeitbudget mit `Time.get_ticks_usec()` und
  `await get_tree().process_frame` (Phase 9).

## Was wegfällt und wer es nutzte

| Teil | Bisherige Nutzer | Danach |
|---|---|---|
| `Timeline.fast_forward_to()` | niemand; gedacht für Idee 01-05 | 01-05 baut später auf `TimelineRun.advance_to()` auf (Vermerk in Feature_Ideas) |
| `GameClock.season_changed` | `timeline_demo`, ein Test | Kalender-Ereignisse (FR-023, FR-024) |
| `GameDate.season()`, `is_holiday_season()` | `GameClock.advance_day()` (für `season_changed`), `timeline_demo`, Tests | entfallen samt Tests und ihrem Aufruf in der Uhr |
| `timeline_demo.tscn/.gd` | Startbefehle in den Abnahmen von 01-01 und 01-02 | die Werkstatt; die beiden Feature-Docs bleiben als Historie, der Quickstart von 002 nimmt die Hauptszene |
| `EventDatabase`, `test_event_database.gd`, `test_timeline_event.gd` | alte Engine | Katalog, Schnappschuss, neue Tests |
| `EventEffect.Kind.SPAWN` | kein Ereignis | Folgeereignisse als eigener Teil |

## Änderungen an der Spec nach Plan und Review

Beim Planen fielen zwei Unschärfen auf:
- **Statistik mit Eingriffen:** Absagen und Verschiebungen lassen sich nicht auf andere Seeds
  übertragen, denn sie betreffen einen Termin, den es nur im Fahrplan eines bestimmten Seeds
  gibt. FR-045 und US7, Szenario 4 sagen jetzt, dass die Statistik Modifikatoren und
  Einplanungen mitnimmt (R11).
- **Tag eines Eingriffs:** Der aktuelle Spieltag ist schon abgespielt. Verschieben und Einplanen
  gehen deshalb erst ab dem folgenden Tag; FR-026 sagt jetzt „nach dem aktuellen Spieltag“ statt
  „zwischen dem aktuellen Spieltag und …“.

Im Review der Checkliste [review.md](checklists/review.md) hat Klaus vier Fragen entschieden:
Proben speichern, Sicherungskopie, Unterschiede markieren, Seeds je Godot-Version. User Story 6
heißt seitdem „Was wäre, wenn: Spieleraktionen ausprobieren“. Die übrigen Punkte sind als
Vorschläge eingearbeitet: Spec (FR-004 bis FR-051, Edge Cases, SC-001, SC-003, SC-004, SC-011),
Datenmodell (Zustand „beendet“, V23, V24, WhatIfProbe), Verträge, research.md (R22 bis R24) und
Quickstart.

Die Analyse mit `/speckit-analyze` fand 40 Befunde, alle von Klaus zur Einarbeitung freigegeben.
An der Spec haben sich dadurch geändert:
- **Präzisiert:** Mindestabstand ab dem letzten Termin, der weder entfallen noch abgesagt ist
  (FR-005). Begründungen nennen jeden Wurf, auch bei Folgeereignissen, mit den Modifikatoren, wie
  sie beim Wurf galten (FR-012). Die Kettenbremse zählt je Kette und warnt im Spiel (FR-018). Das
  Seed-Feld nimmt nur Ziffern an (FR-040).
- **Messbar gemacht:** SC-001 hat fünf Ereignisse und als Endpunkt den erzeugten Fahrplan.
  SC-005 prüft an einer eingefrorenen Kopie der Übernahme. SC-006 unterscheidet Fehler- und
  Warnregeln. SC-011 misst auch Änderung samt Prüfung. US7, Szenario 6 erlaubt 25 % bis 35 %.
- **Klargestellt:** Kategorienfarben kommen aus den Farben, die der Style-Guide dafür erlaubt
  (FR-031). Ein Verschieben auf den aktuellen Spieltag oder davor ist nicht möglich (Edge Cases).

Alles Übrige betraf Plan, Verträge, Datenmodell, Recherche, Quickstart und Tasks.

## Offene Entscheidungen für Klaus

- **Startwerte der Kalender-Ereignisse** (R19): Weihnachtsgeschäft „Kundenstrom alles +30 %“
  während, CeBIT vom 15. bis 21. März mit einer Pressemeldung, Jahreszeiten ohne Wirkung. Das
  blockiert nichts, Klaus ändert die Werte jederzeit in der Werkstatt.
- **Schrift und Farbrollen der Werkstatt** werden mit dem Style-Guide-Abschnitt in Phase 1
  entschieden.
