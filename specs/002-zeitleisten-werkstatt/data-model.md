# Datenmodell: Zeitleisten-Werkstatt

Abgeleitet aus [spec.md](spec.md), Entscheidungen in [research.md](research.md). Das Dateiformat
steht in [contracts/ereigniskatalog.md](contracts/ereigniskatalog.md), Klassen und Signaturen in
[contracts/zeitleiste.md](contracts/zeitleiste.md).

## Überblick

```text
EventCatalog ──┬── EventCategory (1..n, Reihenfolge = Zeilen im Zeitstrahl)
               └── TimelineEvent (0..n, nach Kennung sortiert)
                     ├── EventEffect   (0..n)
                     ├── FollowUp      (0..n) ──► Kennung eines anderen TimelineEvent
                     └── EventCondition (0..n) ──► Kennung eines anderen TimelineEvent

TimelineRun (ein Spiel) ──┬── Seed
                          ├── ScheduleEntry (Fahrplan) ──► TimelineEvent
                          ├── ChanceModifier (Eingriffe) ──► Kennung eines TimelineEvent
                          └── TimelineMessage (Protokoll)

WhatIfProbe (Werkstatt) ──── Seed und Eingriffsprotokoll, gespeichert neben der Werkstatt
```

Der Katalog ist die Beschreibung, was passieren kann; er ändert sich während eines Spiels nie
(Spec, Key Entities). Ein `TimelineRun` arbeitet auf einer eigenen Kopie.

**Zeit:** Alle Tage sind Tagesindizes wie in `GameDate`: 01.01.1985 = 0, 31.12.1999 = 5477
(15 Jahre, davon 3 Schaltjahre). Tage vor 1985 haben negative Indizes, etwa 31.12.1984 = −1 und
01.12.1984 = −31; `GameDate` rechnet dafür auch rückwärts richtig. Gebraucht werden sie nur für
jährliche Vorkommen, die vor Spielbeginn beginnen. Ein Monat hat die Nummer 0 (Januar 1985) bis
179 (Dezember 1999). In der Datei stehen Datumsangaben lesbar, umgerechnet wird beim Lesen; ein
Datum außerhalb des Spielzeitraums erkennt die Prüfung am Index (V06).

## EventCategory

| Feld | Typ | Bedeutung |
|---|---|---|
| `id` | String | Kennung, `[a-z0-9_]+`, eindeutig; entsteht beim Anlegen aus dem Namen und bleibt fest |
| `name` | String | Anzeigename, deutsch; Umbenennen ändert nur ihn |
| `color` | StringName | Token aus `UiPalette`, etwa `&"petrol"`; nur Tokens, die der Style-Guide für Kategorien erlaubt; neue Kategorien bekommen das erste noch freie davon |

Bei der Übernahme: `hardware`, `software`, `tech`, `wirtschaft`, `lokal`, `konkurrenz`, `kunde`,
`reklamation`, `lieferung` (aus dem bisherigen Enum) und neu `kalender`. Gelöscht werden kann eine
Kategorie nur, wenn kein Ereignis mehr zu ihr gehört (FR-031).

## TimelineEvent

Gemeinsame Felder:

| Feld | Typ | Bedeutung |
|---|---|---|
| `id` | String | Kennung, `[a-z0-9_]+`, eindeutig, stabil (FR-002) |
| `title` | String | Titel, deutsch, nicht leer |
| `description` | String | Text, darf leer sein |
| `category` | String | Kennung einer `EventCategory` |
| `kind` | `Kind` | `FIXED`, `YEARLY`, `PRESET`, `CHANCE`, `FOLLOW_ONLY` |
| `effects` | Array[EventEffect] | Wirkungen, auch keine |
| `follow_ups` | Array[FollowUp] | Folgeereignisse, auch keine |
| `conditions` | Array[EventCondition] | nur bei `PRESET`, `CHANCE`, `FOLLOW_ONLY` (FR-006) |

`YEARLY` ist die Art „fix“ mit dem Häkchen „jährlich“. Die Spec kennt deshalb vier Arten, der
Code fünf Werte für `Kind`; angezeigt wird `YEARLY` überall als „fix, jährlich“.

Felder je Art (andere Felder sind leer und werden nicht gespeichert):

| Art | Feld | Typ | Bedeutung |
|---|---|---|---|
| `FIXED` | `date` | int | Tag des Ereignisses |
| `FIXED`, `PRESET`, `CHANCE`, `FOLLOW_ONLY` | `duration_days` | int ≥ 0 | 0 heißt Augenblick |
| `YEARLY` | `yearly_from`, `yearly_to` | int | Jahre, in denen es gilt, 1985 bis 1999 |
| `YEARLY` | `yearly_start` | Vector2i | (Monat, Tag) des Beginns |
| `YEARLY` | `yearly_end` | Vector2i | (Monat, Tag) des letzten Tags; Tag 0 heißt Monatsende; (0, 0) heißt ohne Dauer |
| `PRESET`, `CHANCE` | `window_from`, `window_to` | int | Zeitfenster, beide Tage einschließlich |
| `PRESET`, `CHANCE` | `min_gap_days` | int ≥ 0 | Mindestabstand zwischen zwei Beginnen |
| `PRESET` | `count_min` | int ≥ 0 | kleinste Anzahl |
| `PRESET` | `count_weights` | Array[float] | Gewicht je Anzahl ab `count_min` in Prozent, Summe 100; die einzige Prozentangabe in der Datei, geschrieben auf zwei Nachkommastellen |
| `CHANCE` | `monthly_chance` | float 0..1 | Grundchance pro Monat |
| `CHANCE` | `max_occurrences` | int ≥ 0 | 0 heißt unbegrenzt |

Beispiel `count_min = 0`, `count_weights = [30, 70]`: zu 30 % keinmal, zu 70 % einmal.

## EventEffect

| Feld | Typ | Bedeutung |
|---|---|---|
| `kind` | `Kind` | `PREIS`, `NACHFRAGE`, `REPUTATION`, `KUNDENSTROM`, `PRESSE`; `SPAWN` entfällt |
| `target` | String | Warengruppe wie `cpu_486` oder `*` für alles |
| `magnitude` | float | relativ, −0.30 = −30 %; bei `PRESSE` 0 |
| `delay_days` | int ≥ 0 | Verzögerung ab Beginn des Ereignisses |
| `scope` | `Scope` | `ONCE` (einmaliger Anstoß) oder `DURING` (gilt nur während des Ereignisses) |
| `note` | String | Notiz |

Vorgabe für `scope`: `DURING` bei Ereignissen mit Dauer, sonst `ONCE`. Bei Ereignissen ohne Dauer
wirkt `DURING` wie `ONCE` (FR-021).

## FollowUp

| Feld | Typ | Bedeutung |
|---|---|---|
| `target` | String | Kennung des Folgeereignisses, nicht `FIXED` oder `YEARLY` |
| `chance` | float 0..1 | Vorgabe 1.0 |
| `delay_min`, `delay_max` | int ≥ 0 | Verzögerung in Tagen; gleich heißt fest |

## EventCondition

| Feld | Typ | Bedeutung |
|---|---|---|
| `event` | String | Kennung eines anderen Ereignisses |
| `occurred` | bool | `true`: schon eingetreten; `false`: noch nicht eingetreten |

„Eingetreten“ heißt: Ein Termin dieses Ereignisses hat bis zum Vortag begonnen (Zustand `RUNNING`,
`OCCURRED` oder `ENDED`), auch wenn er noch läuft (FR-006).

## ScheduleEntry (Termin)

| Feld | Typ | Bedeutung |
|---|---|---|
| `serial` | int | laufende Nummer im Fahrplan, Kennung für Eingriffe |
| `event` | TimelineEvent | das Ereignis |
| `day` | int | Beginn |
| `end_day` | int | Tag, an dem das Ende gemeldet wird; = `day` ohne Dauer; > 5477 heißt nach Spielende |
| `origin` | `Origin` | `FIXED`, `YEARLY`, `PRESET`, `ROLLED`, `FOLLOW_UP`, `INTERVENTION` |
| `source_event_id` | String | bei `FOLLOW_UP` das auslösende Ereignis |
| `started_before_game` | bool | bei `YEARLY`: lief schon vor dem 01.01.1985 (R9) |
| `state` | `State` | siehe unten |
| `roll`, `threshold` | float | bei `ROLLED` und `FOLLOW_UP`: Würfelwert und Schwelle, die er unterschreiten musste; sonst −1 |
| `base_chance` | float | bei `ROLLED`: Grundchance aus dem Katalog; bei `FOLLOW_UP`: Wahrscheinlichkeit des Folgeereignisses |
| `modifier_notes` | PackedStringArray | bei `ROLLED`: die Modifikatoren, wie sie beim Wurf galten, je „<grund> <wert in Prozentpunkten>“, etwa „Ware vom windigen Händler +5“ |
| `moved_from_day` | int | ursprünglicher Tag, wenn ein Eingriff den Termin verschoben hat; sonst −1 |
| `note` | String | Grund bei Entfall, Absage, Verschiebung oder Einplanung |

**Zustände:**

```text
            Beginn, ohne Dauer
 PLANNED ─────────────────────────────► OCCURRED   („eingetreten“)
    │  │
    │  │ Beginn, mit Dauer                 Ende
    │  └──────────────────► RUNNING ─────────────► ENDED   („beendet“)
    │                      („läuft“)
    ├── Bedingung nicht erfüllt, läuft noch, Kette gestoppt ──► SKIPPED   („entfallen“)
    └── Eingriff „absagen“ ──────────────────────────────────► CANCELLED („abgesagt“)
```

Verschieben ändert nur `day` und `end_day` eines `PLANNED`-Termins, setzt `note` und beim ersten
Verschieben `moved_from_day`. Termine werden nie gelöscht; der Fahrplan ist zugleich die
Geschichte des Spiels (01-03).

**Fällige verzögerte Wirkungen** ergeben sich aus `event.effects`: Tag = `day + delay_days`. Der
Fahrplan zeigt sie beim Termin (FR-013).

## ChanceModifier

| Feld | Typ | Bedeutung |
|---|---|---|
| `id` | String | Kennung, eindeutig im Lauf |
| `event_id` | String | ein `CHANCE`-Ereignis |
| `value` | float | Prozentpunkte als Anteil, +0.05 = +5 Prozentpunkte |
| `reason` | String | lesbarer Grund, nicht leer |
| `from_day` | int | erster Tag, an dem er gilt; Vorgabe: der aktuelle Spieltag (vor Spielbeginn 0). Die Würfelrunde des aktuellen Tags ist dann schon vorbei, er wirkt also ab der nächsten |
| `to_day` | int | letzter Tag, Pflicht; „unbegrenzt“ = 5477 |

Wirksame Chance am Tag d = `clamp(monthly_chance + Σ value aller Modifikatoren mit
from_day ≤ d ≤ to_day, 0, 1)` (FR-025).

Abgelehnt wird ein Modifikator mit `to_day` < `from_day`, mit leerem Grund, mit einer schon
vergebenen Kennung oder für ein Ereignis, das nicht `CHANCE` ist. Ein `from_day` in der
Vergangenheit und der Wert 0 sind erlaubt (Edge Cases).

## TimelineMessage (Meldung)

| Feld | Typ | Bedeutung |
|---|---|---|
| `day` | int | Tag der Meldung |
| `kind` | `Kind` | `EVENT_STARTED`, `EVENT_ENDED`, `EFFECT_STARTED`, `EFFECT_ENDED`, `ENTRY_SKIPPED`, `CHAIN_STOPPED`, `INTERVENTION` |
| `event` | TimelineEvent | betroffenes Ereignis, falls vorhanden |
| `effect` | EventEffect | bei Wirkungsmeldungen |
| `entry` | ScheduleEntry | betroffener Termin, falls vorhanden |
| `text` | String | eine Zeile fürs Protokoll, deutsch |

## CatalogIssue (Prüfmeldung)

| Feld | Typ | Bedeutung |
|---|---|---|
| `severity` | `Severity` | `ERROR` oder `WARNING` |
| `rule` | String | Kennung der Regel, `V01` bis `V24` |
| `event_id` | String | betroffenes Ereignis oder leer |
| `field` | String | betroffenes Feld, etwa `date`, `effects[1].delay_days` |
| `message` | String | deutsch, nennt Ereignis und Feld |

## Prüfregeln

Die Regeln aus den Edge Cases der Spec, durchnummeriert für Tests (SC-006):

| Regel | Prüft | Stufe |
|---|---|---|
| V01 | Kennung leer | Fehler |
| V02 | Kennung doppelt | Fehler |
| V03 | Kennung enthält andere Zeichen als `a–z`, `0–9`, `_` | Fehler |
| V04 | Titel leer | Fehler |
| V05 | Kategorie unbekannt | Fehler |
| V06 | Datum oder Zeitfenster außerhalb 01.01.1985 bis 31.12.1999 | Fehler |
| V07 | Zeitfenster endet vor seinem Beginn | Fehler |
| V08 | Jährlich: Jahre außerhalb 1985 bis 1999 oder `yearly_from` > `yearly_to` | Fehler |
| V09 | Jährlich: Beginn oder Ende kein gültiger Tag im Jahr oder 29.02. | Fehler |
| V10 | Gesetzt: höchste Anzahl passt mit Mindestabstand nicht ins Zeitfenster | Fehler |
| V11 | Gesetzt: Gewichte negativ oder Summe nicht 100 (Toleranz 0,01) | Fehler |
| V12 | Grundchance oder Wahrscheinlichkeit eines Folgeereignisses außerhalb 0 bis 1 | Fehler |
| V13 | Grundchance 0 | Warnung |
| V14 | Dauer, Verzögerung, Mindestabstand oder Höchstzahl negativ; `delay_min` > `delay_max` | Fehler |
| V15 | Folgeereignis oder Bedingung verweist auf unbekannte Kennung | Fehler |
| V16 | Folgeereignis zeigt auf ein fixes oder jährliches Ereignis | Fehler |
| V17 | Bedingung an einem fixen oder jährlichen Ereignis; schon der Schlüssel `conditions` bei `fixed` oder `yearly` ergibt V17, nicht V22 | Fehler |
| V18 | Kreis aus Folgeereignissen mit 100 % und Verzögerung 0; gemeldet bei jedem Ereignis des Kreises | Fehler |
| V19 | Wirkung `DURING` mit `delay_days` ≥ Dauer: Sie begänne erst am Tag des Endes oder danach | Fehler |
| V20 | Wirkung auf Preis, Nachfrage, Ruf oder Kundenstrom mit Stärke 0 | Warnung |
| V21 | Kategorie: Kennung doppelt oder leer, Farbe nicht in `UiPalette.CATEGORY_TOKENS` | Fehler |
| V22 | Strukturfehler beim Lesen: Datei kein gültiges JSON (mit Zeile), `format` nicht 1, Pflichtfeld fehlt, falscher Typ, unbekannter Schlüssel oder Wert für `kind` oder `scope` | Fehler |
| V23 | Kreis aus Folgeereignissen mit 100 % und Verzögerung, der bis Spielende weiterläuft | Warnung |
| V24 | Gesetzt: Mindestabstand kürzer als die Dauer, gesetzte Termine würden sich überlappen | Fehler |

Ein Ereignis ohne Wirkung ist erlaubt (reine Meldung). Meldungen ohne Ereignis (V21 nennt die
Kategorie in `field`, V22 bei einem Parse-Fehler die Zeile) haben ein leeres `event_id`.

**Fehlerhafte Ereignisse ausnehmen:** Spiel, Simulator, Statistik und Textausgabe rechnen mit
`EventCatalog.without_faulty(issues)`, einer Kopie ohne die Ereignisse, zu denen eine Meldung der
Stufe `ERROR` gehört:
- Folgeereignisse, die auf ein ausgenommenes Ereignis zeigen, fallen mit weg.
- Bedingungen bleiben stehen: Ein ausgenommenes Ereignis tritt nie ein. „Schon eingetreten“ ist
  damit nie erfüllt, „noch nicht eingetreten“ immer.
- Fehler ohne Ereignis, etwa V21, nehmen nichts aus.

## EventStatistic (Statistik je Ereignis)

| Feld | Typ | Bedeutung |
|---|---|---|
| `event_id`, `title` | String | das Ereignis |
| `games` | int | Zahl der gerechneten Spiele |
| `total` | int | Beginne über alle Spiele |
| `minimum`, `maximum` | int | kleinste und größte Anzahl in einem Spiel |
| `games_without` | int | Spiele, in denen es nie begann |
| `games_at_max` | int | Spiele, in denen es seine Obergrenze erreichte: Höchstzahl bei `CHANCE`, höchste Anzahl bei `PRESET`; −1 bei Ereignissen ohne Obergrenze |
| `per_year` | PackedInt32Array | 15 Werte, Beginne je Jahr 1985 bis 1999 über alle Spiele |

Mittelwert = `total / games`; Anteile = `games_without / games` und `games_at_max / games`.
Gezählt werden Beginne (Zustand `RUNNING`, `OCCURRED` oder `ENDED`), nicht entfallene oder
abgesagte Termine.

## WhatIfProbe (Was-wäre-wenn-Probe)

Eine gespeicherte Probe aus dem Simulator (FR-051), eine JSON-Datei je Probe unter
`src/tools/werkstatt/proben/<kennung>.json`, geschrieben nach denselben Regeln wie der Katalog.

| Feld | Typ | Bedeutung |
|---|---|---|
| `id` | String | Kennung = Dateiname, aus dem Namen erzeugt wie bei Ereignissen |
| `name` | String | Anzeigename, etwa „Windiger Händler ab 1990“ |
| `seed` | int | Seed des Durchlaufs |
| `until_day` | int | Tag, bis zu dem der Lauf beim Speichern abgespielt war |
| `interventions` | Array | das Eingriffsprotokoll des Laufs, siehe unten |

**Eingriffsprotokoll:** `TimelineRun.interventions` hält jeden Eingriff in der Reihenfolge, in der
er geschah, als Dictionary:
- `kind`: `"add_modifier"`, `"remove_modifier"`, `"cancel"`, `"move"` oder `"schedule"`;
- `at_day`: der Wert von `today`, als der Eingriff geschah, also −1 vor Spielbeginn;
- je nach Art `event_id`, `day`, `new_day`, `reason` und bei Modifikatoren `modifier` mit den
  Feldern von `ChanceModifier`.

Absagen und Verschiebungen merken sich Ereignis und Tag des Termins statt der laufenden Nummer,
denn die Nummer kann sich ändern, wenn sich der Katalog ändert.

**Neu abspielen:** `WhatIfProbe.build_run(catalog)` legt einen Lauf mit `seed` an und geht das
Protokoll der Reihe nach durch:
1. den Lauf bis `at_day` abspielen, bei −1 gar nicht;
2. dort den Eingriff mit `TimelineRun.apply_intervention()` anwenden; Absagen und Verschiebungen
   finden ihren Termin über `find_planned(event_id, day)`.

Danach spielt sie bis `until_day` weiter. So entsteht derselbe Fahrplan wie beim Speichern, auch
für gewürfelte und Folge-Termine. Ein Eingriff, dessen Ereignis oder Termin fehlt, ist nicht
anwendbar und wird genannt. Genauso startet der Simulator neu mit Eingriffen. In die Statistik
gehen nur `add_modifier`, `remove_modifier` und `schedule` ein, jeweils an ihrem `at_day` wie
beim Neu abspielen (FR-045).
