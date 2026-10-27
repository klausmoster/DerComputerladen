# Glossar

- **Worum es geht:** die Begriffe des Spiels und der Doku und wie sie im Code heißen.
- **Laden, wenn:** ein Begriff unklar ist oder Spec, Doku und Code gegeneinander übersetzt
  werden.
- **Stand:** Feature 003, 2026-10-27

Doku und Oberfläche sind deutsch, der Code englisch. Werte in Dateien sind deutsch, wo sie
Spielinhalt sind (`"preis"`, `"leicht"`), sonst englisch (`"fixed"`, `"once"`).

| Begriff | Im Code | Bedeutung | Mehr in |
|---|---|---|---|
| Abnehmer | — | System, das sich an Signale der Zeitleiste hängt, später etwa Wirtschaft | [zeitleiste.md](zeitleiste.md) |
| Art (eines Ereignisses) | `TimelineEvent.Kind` | fix, fix jährlich, beim Start gesetzt, über Wahrscheinlichkeit, nur als Folge | [zeitleiste.md](zeitleiste.md) |
| Ausnehmen | `without_faulty()` | Fehlerhaftes aus einer Kopie des Katalogs entfernen, bevor gerechnet wird | [ereigniskatalog.md](ereigniskatalog.md) |
| Bedingung | `EventCondition` | „X ist schon / noch nicht eingetreten“ als Voraussetzung eines Termins | [zeitleiste.md](zeitleiste.md) |
| Bildraster | — | 320 × 180, Raster der Szenen und Bilder | [darstellung.md](darstellung.md) |
| Chance, Grundchance | `monthly_chance` | Wahrscheinlichkeit pro Monat aus dem Katalog | [zeitleiste.md](zeitleiste.md) |
| Chance, wirksame | `chance_info()["effective"]` | Grundchance plus Modifikatoren, begrenzt auf 0–1 | [zeitleiste.md](zeitleiste.md) |
| Eingriff | `add_modifier()`, `cancel_entry()`, `move_entry()`, `schedule_event()` | Änderung am laufenden Spiel von außen, mit Grund | [zeitleiste.md](zeitleiste.md) |
| Eingriffsprotokoll | `TimelineRun.interventions` | alle angenommenen Eingriffe mit Tag, zum Nachspielen | [zeitleiste.md](zeitleiste.md) |
| Ereignis | `TimelineEvent` | was passieren kann, Eintrag im Katalog | [zeitleiste.md](zeitleiste.md) |
| Ereigniskatalog, Katalog | `EventCatalog`, `event_catalog.json` | alle Ereignisse, Kategorien und Profile | [ereigniskatalog.md](ereigniskatalog.md) |
| Fahrplan | `TimelineRun.entries` | alle Termine eines Spiels, zugleich seine Geschichte | [zeitleiste.md](zeitleiste.md) |
| Folgeereignis | `FollowUp` | Ereignis, das mit einer Wahrscheinlichkeit nach einem anderen kommt | [zeitleiste.md](zeitleiste.md) |
| Grad, Schwierigkeitsgrad | `Difficulty.Level` | Leicht, Mittel, Schwer | [schwierigkeitsgrade.md](schwierigkeitsgrade.md) |
| Herkunft | `ScheduleEntry.Origin` | warum ein Termin im Fahrplan steht | [zeitleiste.md](zeitleiste.md) |
| Kategorie | `EventCategory` | Gruppe von Ereignissen mit Farbe, eine Zeile im Zeitstrahl | [ereigniskatalog.md](ereigniskatalog.md) |
| Kettenbremse | `TimelineRun.MAX_CHAIN` | höchstens 16 Glieder einer Folgekette am selben Tag, der Auslöser mitgezählt | [zeitleiste.md](zeitleiste.md) |
| Lauf | `TimelineRun` | ein Spiel der Zeitleiste aus Katalog, Seed und Grad | [zeitleiste.md](zeitleiste.md) |
| Meldung | `TimelineMessage` | was an einem Tag geschah; wird im Spiel zum Signal | [zeitleiste.md](zeitleiste.md) |
| Modifikator | `ChanceModifier` | verschiebt die Chance eines Ereignisses in einem Zeitraum um Prozentpunkte | [zeitleiste.md](zeitleiste.md) |
| Oberflächenraster | — | 640 × 360, Raster der Bedienung | [darstellung.md](darstellung.md) |
| Probe | `WhatIfProbe` | gespeicherte Was-wäre-wenn-Rechnung des Simulators: Seed, Grad, Eingriffe | [werkstatt.md](werkstatt.md) |
| Profil | `DifficultyProfile` | Liste der Start-Modifikatoren eines Grads | [schwierigkeitsgrade.md](schwierigkeitsgrade.md) |
| Prüfmeldung | `CatalogIssue` | Fehler oder Warnung zu einer Regel V01–V31 | [ereigniskatalog.md](ereigniskatalog.md) |
| Protokoll | `TimelineRun.protocol` | alle Meldungen eines Laufs | [zeitleiste.md](zeitleiste.md) |
| Seed | `TimelineRun.seed` | Zahl 0–2.147.483.647, aus der alle Zufallsentscheidungen eines Spiels folgen | [zeitleiste.md](zeitleiste.md) |
| Spieluhr | `GameClock` | treibt die Spielzeit voran | [spielzeit.md](spielzeit.md) |
| Start-Modifikator | `ChanceModifier` im Profil, `TimelineRun.start_modifiers` | Modifikator, den ein Grad beim Spielstart setzt | [schwierigkeitsgrade.md](schwierigkeitsgrade.md) |
| Stichtag | — | Tag, an dem der Lauf etwas zu tun hat; dazwischen springt er | [zeitleiste.md](zeitleiste.md) |
| Style-Guide | Artifact, `UiPalette` | verbindliche Quelle für Look und Sprache | [darstellung.md](darstellung.md) |
| Tagesindex | `int`, `GameDate.to_day_index()` | Tage seit 01.01.1985 (= 0), bis 5477 | [spielzeit.md](spielzeit.md) |
| Termin | `ScheduleEntry` | ein Vorkommen eines Ereignisses im Fahrplan | [zeitleiste.md](zeitleiste.md) |
| Textausgabe | `fahrplan_ausgabe.gd`, `ScheduleText` | Fahrplan oder Protokoll auf der Konsole | [werkstatt.md](werkstatt.md) |
| Token | `StringName` wie `&"petrol"` | Name einer Farbe aus dem Style-Guide | [darstellung.md](darstellung.md) |
| Unterschiede | `ScheduleDiff` | Vergleich zweier Läufe | [werkstatt.md](werkstatt.md) |
| Werkstatt | `Werkstatt`, `src/tools/werkstatt/` | Entwicklungswerkzeug für Katalog, Simulator, Statistik | [werkstatt.md](werkstatt.md) |
| Wirkung | `EventEffect` | was ein Ereignis meldet: Preis, Nachfrage, Ruf, Kundenstrom, Presse | [zeitleiste.md](zeitleiste.md) |
| Würfel | `EventDice` | eigener Zufallsgenerator je Zweck und Ereignis | [zeitleiste.md](zeitleiste.md) |
| Würfelrunde | `_roll_month()` | am Monatsersten würfeln alle Ereignisse über Wahrscheinlichkeit | [zeitleiste.md](zeitleiste.md) |
| Zeitstrahl | `TimelineView` | grafische Ansicht des Katalogs in der Werkstatt | [werkstatt.md](werkstatt.md) |
| Zustand | `ScheduleEntry.State` | geplant, läuft, eingetreten, beendet, entfallen, abgesagt | [zeitleiste.md](zeitleiste.md) |
