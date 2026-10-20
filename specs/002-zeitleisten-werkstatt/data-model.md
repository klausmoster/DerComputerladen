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
```

Der Katalog ist die Beschreibung, was passieren kann; er ändert sich während eines Spiels nie
(Spec, Key Entities). Ein `TimelineRun` arbeitet auf einer eigenen Kopie.

**Zeit:** Alle Tage sind Tagesindizes wie in `GameDate`: 01.01.1985 = 0, 31.12.1999 = 5477
(15 Jahre, davon 3 Schaltjahre). Ein Monat hat die Nummer 0 (Januar 1985) bis 179 (Dezember
1999). In der Datei stehen Datumsangaben lesbar, umgerechnet wird beim Lesen.

## EventCategory

| Feld | Typ | Bedeutung |
|---|---|---|
| `id` | String | Kennung, `[a-z0-9_]+`, eindeutig |
| `name` | String | Anzeigename, deutsch |
| `color` | StringName | Token aus `UiPalette`, etwa `&"petrol"` |

Bei der Übernahme: `hardware`, `software`, `tech`, `wirtschaft`, `lokal`, `konkurrenz`, `kunde`,
`reklamation`, `lieferung` (aus dem bisherigen Enum) und neu `kalender`.

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

`YEARLY` ist in der Werkstatt „fix, jährlich“; Spec und Fahrplan sprechen von „fix“ und
„jährlich“.

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
| `PRESET` | `count_weights` | PackedFloat32Array | Gewicht je Anzahl ab `count_min`, Summe 100 |
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

„Eingetreten“ heißt: Ein Termin dieses Ereignisses hat bis zum Vortag begonnen (Zustand `RUNNING`
oder `OCCURRED`).

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
| `roll`, `threshold` | float | bei `ROLLED`: Würfelwert und wirksame Schwelle; sonst −1 |
| `modifier_ids` | PackedStringArray | bei `ROLLED`: Modifikatoren, die beim Wurf galten |
| `note` | String | Grund bei Entfall, Absage, Verschiebung oder Einplanung |

**Zustände:**

```text
            Beginn, ohne Dauer
 PLANNED ─────────────────────────────► OCCURRED
    │  │                                   ▲
    │  │ Beginn, mit Dauer                 │ Ende
    │  └──────────────────► RUNNING ───────┘
    │
    ├── Bedingung nicht erfüllt, läuft noch, Kette gestoppt ──► SKIPPED
    └── Eingriff „absagen“ ──────────────────────────────────► CANCELLED
```

Verschieben ändert nur `day` und `end_day` eines `PLANNED`-Termins und setzt `note`. Termine
werden nie gelöscht; der Fahrplan ist zugleich die Geschichte des Spiels (01-03).

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
| `rule` | String | Kennung der Regel, `V01` bis `V22` |
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
| V17 | Bedingung an einem fixen oder jährlichen Ereignis | Fehler |
| V18 | Kreis aus Folgeereignissen mit 100 % und Verzögerung 0 | Fehler |
| V19 | Wirkung `DURING` beginnt wegen ihrer Verzögerung erst nach dem Ende ihres Ereignisses | Fehler |
| V20 | Wirkung auf Preis, Nachfrage, Ruf oder Kundenstrom mit Stärke 0 | Warnung |
| V21 | Kategorie: Kennung doppelt oder leer, Farbe kein Token der Palette | Fehler |
| V22 | Strukturfehler beim Lesen: Datei kein gültiges JSON (mit Zeile), `format` nicht 1, Pflichtfeld fehlt, falscher Typ, unbekannter Schlüssel oder Wert für `kind` oder `scope` | Fehler |

Ein Ereignis ohne Wirkung ist erlaubt (reine Meldung).

## EventStatistic (Statistik je Ereignis)

| Feld | Typ | Bedeutung |
|---|---|---|
| `event_id`, `title` | String | das Ereignis |
| `games` | int | Zahl der gerechneten Spiele |
| `total` | int | Beginne über alle Spiele |
| `minimum`, `maximum` | int | kleinste und größte Anzahl in einem Spiel |
| `games_without` | int | Spiele, in denen es nie begann |
| `games_at_max` | int | Spiele, in denen es die Höchstzahl erreichte; bei gesetzten Ereignissen die höchste Anzahl |
| `per_year` | PackedInt32Array | 15 Werte, Beginne je Jahr 1985 bis 1999 über alle Spiele |

Mittelwert = `total / games`; Anteile = `games_without / games` und `games_at_max / games`.
Gezählt werden Beginne (Zustand `RUNNING` oder `OCCURRED`), nicht entfallene oder abgesagte
Termine.
