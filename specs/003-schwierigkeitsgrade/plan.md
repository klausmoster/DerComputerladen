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
  V22. Start-Modifikatoren prüfen die neuen Regeln V25 bis V30; V31 warnt bei einem Beginn oder
  Ende mitten im Monat. Fehlerhafte nimmt `without_faulty()` aus, ohne das Ereignis zu treffen,
  auf das sie zeigen (R4, R8).
- **Zwei Listen im Lauf:** `TimelineRun` setzt die Start-Modifikatoren in `_init()` in eine eigene
  Liste, bevor zum ersten Mal gewürfelt wird. Eingriffe bleiben in `modifiers`. So unterscheiden
  sich beide durch ihre Herkunft, nicht durch ihre Kennung: Start-Modifikatoren lassen sich nicht
  entfernen, landen nie in Proben, und Eingriffe wirken in jedem Grad gleich (R5, R6).
- **Werkstatt:** Reiter „Schwierigkeitsgrade“ mit Tabelle und Feldern, Chance je Grad im Formular
  nur zum Lesen, Grad und umschaltbarer Vergleich im Simulator, Proben mit Grad, Statistik mit
  einem Grad oder allen drei, Seed für Seed (R10 bis R15).
- **Textausgabe** mit `--grad`; die Kopfzeile nennt den Grad (R16).
- **Feste Größe:** Mit Mittel sind Fahrplan und Protokoll Zeichen für Zeichen wie in Feature 002,
  ohne die Kopfzeile der Textausgabe. Belegt ist das an einer eingefrorenen Grundlinie, bevor sich
  der Lauf ändert (R17, SC-007).
- **Review:** Die Checkliste [review.md](checklists/review.md) mit 38 Punkten ist eingearbeitet.
  Fünf davon hat Klaus entschieden (siehe „Änderungen an der Spec nach dem Plan“).
- **Analyse:** Die 41 Befunde von `/speckit-analyze` sind eingearbeitet. Klaus hat alle nach
  Empfehlung freigegeben; zwei sind auf anderem Weg mit demselben Ziel gelöst (siehe „Änderungen
  nach der Analyse“).

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
(SC-011 von Feature 002). Die Prüfung der Profile fällt darunter: `test_large_catalog.gd` misst
sie mit 20 Start-Modifikatoren je Profil, die er `catalog_500.json` im Speicher hinzufügt
(Analyse, G9).

**Constraints**:
- Wiederholbar: Katalog, Seed und Grad ergeben denselben Fahrplan (FR-008, SC-001).
- Ein Grad verschiebt nur Schwellen; Würfel und ihre Zwecke bleiben (FR-009, R5 von Feature 002).
- Die Zeitleiste meldet nur, sie wendet keine Wirkung an (Verfassung).
- Mit Mittel bleiben Fahrplan und Protokoll Zeichen für Zeichen wie in Feature 002, ohne die
  Kopfzeile der Textausgabe (SC-007). Die Startprobe mit `-d` bleibt still.
- Kanonisches JSON, eine Zeile je geändertem Wert (FR-005, SC-006).
- Nur Desktop mit Maus und Tastatur.

**Scale/Scope**: drei Grade, zwei Profile, heute sechs Ereignisse über Wahrscheinlichkeit im
Katalog. Zwei neue Kernklassen und sieben geänderte, ein geändertes Autoload. In der Werkstatt ein
neues Panel und acht geänderte Dateien, darunter die Textausgabe. Fünf neue Testdateien und 15
geänderte, dazu rund 18 neue Fixtures, davon sechs für die Grundlinie. Drei vorhandene Fixtures
bekommen den Abschnitt `profiles` (R17).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Grundsatz | Prüfung | Vor Phase 0 | Nach Phase 1 |
|---|---|---|---|
| I. Nur Desktop | Neue Bedienung nur in der Werkstatt, mit Maus und Tastatur: Auswahlfelder, Häkchen, Tabelle, Felder mit Enter und Hinweis beim Überfahren. Keine Touch-Eingaben, Forward+ bleibt | erfüllt | erfüllt |
| II. Klaus entscheidet, der Agent baut, Claude plant und prüft | Der Plan enthält nur Signaturen, keine Rümpfe. Die Aufteilung `[K]`/`[A]`/`[C]` folgt in den Tasks; umgesetzt wird phasenweise auf Klaus' Auftrag, mit einer Lernnotiz in `lernnotizen.md` zu jeder umgesetzten Task, auch zu denen, die Klaus selbst baut (Analyse, K2). Klaus' Entscheidung im Plan (R9) steht mit Datum da. `/speckit-implement` wird nicht verwendet | erfüllt | erfüllt |
| III. Erst spezifizieren | Spec mit sieben Klärungen, eigener Branch, System 01 in der Spec genannt. Godot-Details erst hier, 19 Entscheidungen mit Alternativen in research.md. Die Präzisierung von FR-017 hat Klaus entschieden. Review mit 38 Punkten eingearbeitet, fünf davon von Klaus entschieden. Analyse mit 41 Befunden eingearbeitet; der kritische fand fehlende Alternativen zu R17 und CHK008 (K1), sie stehen jetzt da | erfüllt | erfüllt |
| IV. Ein Look: der Style-Guide | Das Spiel bekommt keine neue Oberfläche. Die Werkstatt nutzt nur Bausteine aus dem Abschnitt „Werkzeuge“: Tabelle mit Zebra, Auswahlfeld, Häkchen, Feld mit Fehlerkontur, gedämpfter Text, Fehlerhinweis. Braucht der Agent doch einen neuen Baustein, hält er an und fragt; der Baustein käme zuerst in den Style-Guide (R11, R15) | erfüllt | erfüllt |
| V. Daten sauber halten | Die Profile stehen in der Katalogdatei, wie Klaus in der Klärung entschieden hat, und werden mit der Werkstatt gepflegt. Die Ausnahme Ereigniskatalog deckt das, denn sie gilt der Datei und ihrer Pflege in der Werkstatt; so hat Klaus es am 2026-10-22 bestätigt (CHK022). game_bible unberührt | erfüllt | erfüllt |
| Technische Rahmenbedingungen | Godot 4.7 und GUT 9.7.1, Projekt in `src/`. `GameClock` und `Timeline` bleiben Autoloads. Die Timeline meldet weiter nur; ein Grad wirkt nur über Chancen in der Timeline, also steht alles, was ein Ereignis auslösen kann, weiter dort | erfüllt | erfüllt |
| Arbeitsweise | Dokumente deutsch. `.uid` der neuen Skripte wird committet. `export_presets.cfg` bleibt unberührt; `tools/*` ist schon ausgeschlossen | erfüllt | erfüllt |

Ergebnis: bestanden, vor und nach dem Entwurf, nach dem Review und nach der Analyse, ohne
Verstöße, die begründet werden müssten. Die Analyse fand zwei Lücken: fehlende Alternativen zu
Grundsatz III (K1) und keine Lernnotiz für Tasks, die Klaus selbst baut, zu Grundsatz II (K2).
Beide sind behoben.

Zu Grundsatz V: Die Ausnahme spricht von „den Ereignissen der Zeitleiste“. Die Profile sind keine
Ereignisse, stehen aber in derselben Datei und werden genauso gepflegt. Klaus hat am 2026-10-22
entschieden, den Wortlaut so zu lassen; die Verfassung bleibt bei 2.1.1 (CHK022).

## Project Structure

### Documentation (this feature)

```text
specs/003-schwierigkeitsgrade/
├── spec.md                      # Spezifikation, geklärt, im Plan und im Review präzisiert
├── plan.md                      # dieser Plan
├── research.md                  # Phase 0: Entscheidungen R1–R19
├── data-model.md                # Phase 1: Klassen, Felder, Prüfregeln V25–V31
├── quickstart.md                # Phase 1: Prüfanleitung
├── contracts/
│   ├── ereigniskatalog.md       # Abschnitt „profiles“ in der Katalogdatei
│   ├── zeitleiste.md            # Kern, Autoload, Textausgabe, Tests
│   └── werkstatt.md             # Reiter, CatalogEditor, Formular, Simulator, Proben, Statistik
├── checklists/
│   ├── requirements.md          # Qualitätsprüfung der Spec
│   └── review.md                # Review der Anforderungen, 38 Punkte, von Klaus entschieden
├── tasks.md                     # Aufgaben je Phase (/speckit-tasks), T001 bis T035
└── lernnotizen.md               # entsteht bei der Umsetzung, eine Notiz je umgesetzter Task
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
│       ├── catalog_validator.gd         # geändert: V25–V31
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
│   ├── issues_panel.gd                  # geändert: „Profil Schwer“ in der Prüfung
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
   bleibt, wie es war, ohne die Kopfzeile der Textausgabe (SC-007).
2. **Style-Guide:** keine Vorarbeit nötig. Alle Bausteine gibt es schon (Grundsatz IV, R11).

## Umsetzungsphasen (Vorschlag für die Tasks)

Jede Phase endet mit grünen Tests, Lernnotizen und Klaus' Abnahme; erst dann folgt die nächste.
Eine Lernnotiz gibt es zu jeder umgesetzten Task; baut Klaus eine selbst, schreibt Claude die
Notiz beim Review (Analyse, K2). Hat eine Phase Kern und Oberfläche, prüft Claude den Kern, bevor
die Oberfläche beginnt (Analyse, I9).

| Phase | Inhalt | Story |
|---|---|---|
| 1 | Grundlage: Grundlinie einfrieren; `Difficulty`, `DifficultyProfile`, `ChanceModifier.from_dict()`/`to_dict()`; Profile im `EventCatalog` (Lesen, Schreiben, `to_dict()`, Kopie, `without_faulty()`, `skipped_start_modifiers()`); V22 für den Abschnitt und V25 bis V31 mit kaputten Fixtures. Dazu, was sonst Tests aus Feature 002 bräche: `catalog_minimal.json`, `catalog_500.json` und `catalog_alle_arten.json` bekommen den Abschnitt, die Rundreise der Übernahme ihre neue Erwartung, die Sicherungskopie baut aus `to_dict()`. Zur Abnahme schließt Klaus jede ältere Werkstatt und speichert den echten Katalog einmal in der neuen (R3, CHK037) | blockiert alles |
| 2 | Spielstart mit Grad: `TimelineRun` (Grad, Start-Modifikatoren, `chance_info()`, Begründung, Protokoll, `remove_modifier()`), `TimelineMessage` mit „Grad“ als achter Art, Autoload (`start_game()`, `get_difficulty()`, Meldungen), Kopfzeile und Textausgabe mit `--grad`; SC-001, SC-002, Mittel gegen Grundlinie | US1 (P1) |
| 3 | Profile in der Werkstatt in zwei Teilen. Teil 1, Kern: `CatalogEditor` mit Start-Modifikatoren, jede Änderung ersetzt das ganze Profil (R10), Verweise beim Löschen und Umbenennen, `content_key()`, Lesemeldungen eines geänderten Profils verwerfen; SC-006. Dann prüft Claude. Teil 2, Oberfläche: `DifficultyPanel`, vierter Reiter, Prüfmeldung führt zum Feld, „Profil Schwer“ in der Prüfung, Löschdialog, „Je Grad“ im Formular. Zur Abnahme prüft Klaus erst nach Quickstart 4.1 auf einer Kopie mit leeren Profilen, darin SC-005. Dann legt er die Profile im echten Katalog an (R18), und der Test, dass Leicht und Schwer nicht leer sind, kommt dazu (CHK008; Analyse, I1) | US2 (P1) |
| 4 | Simulator in zwei Teilen. Kern: `WhatIfProbe` mit Grad; dann prüft Claude. Oberfläche: Auswahl des Grads, Neubau beim Wechsel, Vergleich umschaltbar mit Text, Markierungen, Protokoll, Modifikatoren, Liste der Proben, weggelassene Start-Modifikatoren im Hinweis | US3 (P2) |
| 5 | Statistik in zwei Teilen. Kern: `TimelineStatistics` mit mehreren Graden Seed für Seed, SC-003; dann prüft Claude. Oberfläche: Auswahl und Vergleichstabelle, SC-004 | US4 (P2) |
| 6 | Abschluss: CLAUDE.md (Tabelle „Aufbau“, Beschreibung der Timeline mit Grad), `docs/features/Features.md`, `Feature_Ideas.md` (01-05 als „Neues Spiel: Startdatum, Seed und Grad“ mit `start_game(seed, difficulty)`, R19; 11-05 mit dem Hinweis auf Feature 003; 11-01: Spielstände speichern den Grad), die offene Frage „Schwierigkeitsgrade?“ im GDD nur mit Klaus' OK (CHK038), Lückensuche mit `/speckit-converge`, Quickstart vollständig nach der Phase für Lücken, Gesamtabnahme | – |

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
  eine Zeile in ein vorhandenes Formular einfügen und fertige Hilfen aus dem Kern aufrufen
  (`DifficultyProfile.chance_periods()` und `describe_periods()`, Phase 3).
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
| Liste der Proben beim Laden | vier Spalten | dazu „Grad“ | `test_simulator.gd` erwartet fünf Spalten (Analyse, B2) |
| Teiler und Mindestgröße der Werkstatt | sechs gespeicherte Teiler, acht geprüfte Bereiche | sieben und elf, mit dem neuen Reiter | `test_werkstatt_settings.gd` (Analyse, B3) |
| `chance_info()` | vier Schlüssel | dazu `"start_modifiers"`; `"sum"` rechnet sie mit | der Simulator; für Mittel ändert sich nichts |
| `TimelineMessage.Kind` | sieben Arten | dazu `START_MODIFIER` am Ende | `Timeline._send()`, kein Signal; `test_timeline_run.gd`, dessen Test der Zeilen je Art „Grad“ als achte Art bekommt (Analyse, B1) |
| `TimelineRun.new()` | Katalog, Seed | dazu der Grad, Vorgabe Mittel | niemand, alte Aufrufe bleiben gültig |
| `TimelineStatistics.new()` | Katalog, Anzahl, erster Seed | dazu die Grade | das Statistik-Panel |
| `CatalogValidator.validate()` | Kategorien zuletzt | danach die Profile | Reihenfolge in der Prüfung |
| Test jeder Prüfregel (`FAELLE`) | jede Meldung mit „Ereignis „“ | bei Feldern `profiles…` „Profil „“, mit dem vollen Feld im Text | `test_catalog_validator.gd`, mit einem Zweig für Profile (Analyse, B4) |
| `test_large_catalog.gd` | 500 Ereignisse | dazu im Speicher 20 Start-Modifikatoren je Profil | die Messung der Prüfung (Analyse, G9) |
| `delete_event()`, `rename_event()` | Folgen und Bedingungen | dazu Start-Modifikatoren, über ganze Profile | Löschdialog, Klaus |
| Spalte „Ereignis“ der Prüfung | „–“ bei Meldungen ohne Ereignis | „Profil Leicht“, „Profil Schwer“ oder „Profile“, nach dem zweiten Pfadteil des Felds | `issues_panel.gd`, `test_werkstatt_scene.gd` (Analyse, U4) |
| `test_shipped_catalog.gd` | keine Fehler, Kalender | dazu ab Phase 3: Leicht und Schwer nicht leer | Klaus, der die Profile anlegt |

Gleich bleiben der Stand im Simulator („Stand: … · Seed 4711“) und die Texte der Markierungen beim
Vergleich mit demselben Grad; ihre Tests aus Feature 002 bleiben unverändert (R13).

## Änderungen an der Spec nach dem Plan

Beim Planen fiel ein Widerspruch auf: FR-017 verlangte, Verweise aus Profilen auch vor dem
Umbenennen eines Ereignisses zu nennen, „wie die übrigen Verweise“. Folgen und Bedingungen zieht
die Werkstatt seit Feature 002 aber still nach. Klaus hat am 2026-10-21 entschieden: still
nachziehen, genannt wird nur beim Löschen (R9). Präzisiert sind FR-017 und der Edge Case
„Kaputter Verweis“, die Frage steht unter „Clarifications“, „Plan 2026-10-21“.

Im Review der Checkliste [review.md](checklists/review.md) am 2026-10-22 hat Klaus fünf Fragen
entschieden, alle nach Empfehlung:
- gefüllte Profile zur Gesamtabnahme, mit Test (CHK008);
- die Warnung V31 für einen Beginn oder ein Ende mitten im Monat (CHK013);
- die Auswahl des Grads gehört zu 01-05 (CHK021, R19);
- Grundsatz V bleibt, wie er ist (CHK022);
- `catalog_500.json` und `catalog_minimal.json` bekommen den leeren Abschnitt (CHK036).

Die beiden ersten stehen unter „Clarifications“, „Review 2026-10-22“. Die übrigen 33 Punkte waren
Vorschläge von Claude, die Klaus freigegeben hat. An der Spec haben sie Folgendes geändert:
- **Präzisiert:**
  - FR-002 erlaubt den Wert 0;
  - FR-007 sagt, wann ein Start-Modifikator in der Würfelrunde wirkt;
  - FR-009 definiert, was abhängt;
  - FR-011 sagt, welche Grade es gibt;
  - FR-015 beschreibt Kennung, „Neu“ und „Löschen“ und dass Fehlerhaftes in der Anzeige nicht
    zählt;
  - FR-018 beschreibt den Wechsel des Grads, „so, wie er war“;
  - FR-021 nennt den Grad auch bei Mittel.
- **Ergänzt:**
  - FR-005 verweist auf das erste Speichern einer älteren Datei;
  - FR-013 behandelt ausgenommene Ereignisse sowie Simulator, Statistik und Textausgabe;
  - FR-014 verlangt nicht leere Profile;
  - FR-016 regelt Rückgängig, Sicherungskopie und den Grad in der Prüfung;
  - FR-019 regelt eine Probe mit unbekanntem Grad;
  - FR-020 regelt die Werte im Vergleich, den Abbruch, den Grad im Ergebnis und „Katalog
    geändert“;
  - US1, Szenario 6 nennt den Grad.
- **Neue Edge Cases:** „Ereignis dupliziert“, „Art geändert“ und „Beginn mitten im Monat“; „Ältere
  Katalogdatei“ ist erweitert.
- **Messbar gemacht:** SC-002 mit dem Vergleich zweier Läufe, SC-003 mit „ohne weitere Grenzen“,
  SC-004 mit Messbedingungen, SC-006 an einer Datei mit Abschnitt. SC-007 ist neu: Mittel bleibt
  Zeichen für Zeichen wie vor dem Feature.
- **Annahmen:** 01-05 umfasst Startdatum, Seed und Grad; die Profile sind zur Gesamtabnahme
  gefüllt.

Alles Übrige betraf research.md, Datenmodell, Verträge, Quickstart und diesen Plan.

## Änderungen nach der Analyse

Die Analyse mit `/speckit-analyze` am 2026-10-22 fand 41 Befunde: einen kritischen, sieben hohe,
zehn mittlere und 23 niedrige. Klaus hat am selben Tag alle nach Empfehlung freigegeben. Die
meisten Kürzel stehen auch an den Stellen, die sie geändert haben, etwa „(Analyse, G1)“.
- **Kritisch:** Zu R17 und zu CHK008 fehlten die verworfenen Alternativen (K1, Grundsatz III).
  Jetzt nennen sie R17, R18, die Klärung „Review 2026-10-22“ in der Spec und CHK008 in der
  Checkliste.
- **Hoch:**
  - Vier Tests aus Feature 002 wären sonst gebrochen (B1 bis B4); die Tasks nennen ihre neuen
    Erwartungen. Meldungen zu Profilen nennen dafür das volle Feld im Text, wie Meldungen zu
    Kategorien.
  - `DifficultyProfile.to_dict()` liefert `content_key()` den Text eines Profils (U1).
  - `EventCatalog.skipped_start_modifiers()` liefert die weggelassenen Start-Modifikatoren mit Ort
    und Fehlergrund. Timeline, Textausgabe, Simulator und Statistik nennen sie daraus, auch die,
    deren Ereignis ausgenommen ist (G1).
  - Klaus prüft nach Quickstart 4.1 auf einer Kopie mit leeren Profilen, bevor er die echten
    anlegt (I1).
- **An der Spec:** „Fehlergrund“ in FR-013 und US1, Szenario 6 (A1); SC-007 nimmt die Kopfzeile
  der Textausgabe aus (A2); „Neu“ nimmt das erste Ereignis nach Kennung (A4); Edge Cases und eine
  Annahme verweisen auf ihre Anforderung, statt sie zu wiederholen (D1).
- **Tasks:** 35 statt 32. Neu sind die Prüfung auf einer Kopie vor den echten Profilen (T019) und
  Claudes Prüfung zwischen Kern und Oberfläche in Phase 4 und 5 (T024, T029; I9). Die
  Markierungen `[P]` stimmen (I7), und Lernnotizen gibt es zu jeder umgesetzten Task (K2).
- **Übrige:** Datenmodell, Verträge, research.md und Quickstart sind genauer geworden:
  - Felder, Orte und Texte der Meldungen (B4, U4, U5, U7, U8);
  - verworfene Lesemeldungen eines geänderten Profils (U2) und `as Difficulty.Level` mit der
    Startprobe (U3);
  - die Hülle der Abhängigen bei SC-002 und FR-003 (G2, I6);
  - Tests für Randfälle und neue Fixtures (G3 bis G7, G9, U6, I8);
  - Bildschirmfotos und Platz (G10), einheitliche Namen (I2), Texte (I3 bis I5, A3);
  - kleine Vorgaben im Panel (U10), die Grundlinie (U9) und die Formatierung im Kern (U11);
  - die neue Zeile mit der Textausgabe in Quickstart 4.1 (G8).
- **Anders gelöst als im Bericht vorgeschlagen, mit demselben Ziel:**
  - U1: Statt `JSON.stringify(to_list())` als Sonderfall bekommt `DifficultyProfile` ein
    `to_dict()`. `_text_of()` ruft es wie bei Ereignissen und Kategorien und braucht keinen
    eigenen Zweig.
  - G10: Die FilterBar bricht nicht um. Sie wird nicht breiter als bisher, und `%CompareLabel`
    kürzt seinen Text mit „…“ und zeigt ihn beim Überfahren ganz. So bleibt die Leiste einzeilig,
    und die Tabelle darunter behält ihre Höhe. Bis Phase 4: Seit 2026-10-23 ist die Leiste ein
    `HFlowContainer` und bricht in 1280 × 720 in zwei Zeilen um; Kürzen allein reichte nicht
    (`docs/offene-punkte.md`, „Feature 003, Phase 4, Oberfläche“).

  Diese zwei und die Einzelheiten, die der Bericht offen ließ, etwa die Texte zu A3 und die Regeln
  zu V31 (U7), stehen als Claudes Entscheidungen in `docs/offene-punkte.md`.
- **Prüfung der Einarbeitung:** Ein Prüfer hat die eingearbeiteten Dokumente gegen Bericht,
  Verträge und Code gelesen und 17 Stellen gefunden, die noch nicht stimmten. Darunter waren
  Cmd+Z in den Feldern des Reiters, der Ablauf in Quickstart 4.1, die Kopien für die Prüfung von
  Hand und doppelte Meldungen der Textausgabe, die jetzt `by_event` vermeidet. Alle sind behoben.
  Bei U2 hatte Claude die Lesemeldungen zuerst mit ihren Stellen wandern lassen. Das hätte auch
  Text, Verlauf und Speichern berührt; deshalb gilt jetzt die Empfehlung, sie zu verwerfen.

## Offene Entscheidungen für Klaus

Eine, die nichts blockiert:
- **Startwerte der Profile** (R18): Claudes Vorschlag ist eine Tabelle für die sechs Ereignisse
  über Wahrscheinlichkeit. Klaus legt die Profile in Phase 3 in der Werkstatt an, nachdem er auf
  einer Kopie mit leeren Profilen geprüft hat (T019, T020), und stellt sie mit der Statistik
  nach. Zur Gesamtabnahme müssen beide gefüllt sein (CHK008).

Entschieden ist seit dem 2026-10-22 die Frage zu Grundsatz V der Verfassung: Er bleibt, wie er
ist (CHK022).
