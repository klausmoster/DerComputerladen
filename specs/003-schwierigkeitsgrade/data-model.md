# Datenmodell: Schwierigkeitsgrade der Zeitleiste

Abgeleitet aus [spec.md](spec.md), Entscheidungen in [research.md](research.md). Das Datenmodell
ergänzt das von [Feature 002](../002-zeitleisten-werkstatt/data-model.md). Was dort steht und
hier nicht vorkommt, gilt unverändert. Das Dateiformat steht in
[contracts/ereigniskatalog.md](contracts/ereigniskatalog.md), Klassen und Signaturen in
[contracts/zeitleiste.md](contracts/zeitleiste.md) und
[contracts/werkstatt.md](contracts/werkstatt.md).

## Überblick

```text
EventCatalog ──┬── EventCategory (1..n)
               ├── TimelineEvent (0..n)
               └── DifficultyProfile (genau 2: Leicht, Schwer)          neu
                     └── ChanceModifier als Start-Modifikator (0..n)   neu im Katalog
                           └──► Kennung eines TimelineEvent über Wahrscheinlichkeit

TimelineRun (ein Spiel) ──┬── Seed
                          ├── Difficulty.Level (Grad, fest für das ganze Spiel)   neu
                          ├── ChanceModifier (start_modifiers, aus dem Profil)    neu
                          ├── ChanceModifier (modifiers, aus Eingriffen)
                          ├── ScheduleEntry (Fahrplan)
                          └── TimelineMessage (Protokoll)

WhatIfProbe (Werkstatt) ──── Seed, Grad und Eingriffsprotokoll
TimelineStatistics ───────── Seeds, Liste der Grade, Eingriffe
```

Ein Lauf ist jetzt ein Spiel aus Katalog, Seed und Grad (Spec, Key Entities). „Mittel“ ist der
Katalog ohne Start-Modifikatoren und hat kein Profil (FR-004).

## Difficulty (Schwierigkeitsgrad)

Eine Klasse ohne Instanzen; sie hält die Aufzählung und die Namen (R1).

| Wert | `key()`, in Dateien und Argumenten | `label()`, in Texten | Profil |
|---|---|---|---|
| `Level.LEICHT` | `"leicht"` | „Leicht“ | ja |
| `Level.MITTEL` | `"mittel"` | „Mittel“ | nein, Katalog allein |
| `Level.SCHWER` | `"schwer"` | „Schwer“ | ja |

- `DEFAULT` ist `Level.MITTEL`: Ohne Angabe gilt Mittel, beim Spielstart (FR-006), in einer Probe
  ohne Grad (FR-019) und in der Textausgabe.
- `WITH_PROFILE` ist `[LEICHT, SCHWER]`, die Reihenfolge der Profile im Katalog.
- `from_key()` gibt für einen unbekannten Namen −1. Groß- und Kleinschreibung zählt: `"Schwer"` ist
  unbekannt.
- `is_valid()` prüft eine Zahl, denn eine Aufzählung ist zur Laufzeit eine ganze Zahl.

## DifficultyProfile (Profil)

| Feld | Typ | Bedeutung |
|---|---|---|
| `level` | `Difficulty.Level` | `LEICHT` oder `SCHWER` |
| `modifiers` | Array[ChanceModifier] | die Start-Modifikatoren in der Reihenfolge der Datei; neue kommen ans Ende, ein Duplikat direkt hinter sein Original (R2) |

Ein leeres Profil verhält sich wie „Mittel“ (Edge Case „Leeres Profil“). Mehrere
Start-Modifikatoren auf dasselbe Ereignis addieren sich, auch mit überlappenden Zeiträumen (Edge
Case).

**Stelle eines Start-Modifikators:** Im Profil hat er seine Stelle i, ab 0. In Prüfmeldungen heißt
sie wie in der Datei, `profiles.<key>[<i>].<schlüssel>`, etwa `profiles.schwer[2].reason`. Im Text
heißt sie „Profil „Schwer“, Start-Modifikator „reklamationswelle““, ohne Kennung „Profil
„Schwer“, Start-Modifikator Nr. 3 ohne Kennung“, gezählt ab 1.

## Start-Modifikator

Ein Start-Modifikator ist ein `ChanceModifier` (Feature 002) in einem Profil. Er hat dieselben
Felder (FR-002):

| Feld | Typ | Bedeutung |
|---|---|---|
| `id` | String | Kennung, `[a-z0-9_]+`, im Profil eindeutig (V30) |
| `event_id` | String | Kennung eines Ereignisses über Wahrscheinlichkeit (V25, V26) |
| `value` | float | Prozentpunkte als Anteil, +0.05 = +5 Prozentpunkte; positiv, negativ oder 0 |
| `reason` | String | lesbarer Grund, nicht leer (V29), etwa „Anspruchsvolle Kunden“ |
| `from_day` | int | erster Tag, an dem er gilt, im Spielzeitraum (V28) |
| `to_day` | int | letzter Tag, Pflicht, nicht vor `from_day` (V27); „unbegrenzt“ = 5477 |

**Vorgaben:** Dieselben Werte bekommt ein neuer Start-Modifikator in der Werkstatt, und sie gelten
für ein Feld, das beim Lesen fehlt (dann mit V22):
- `from_day` = 0 und `to_day` = 5477, also das ganze Spiel 01.01.1985 bis 31.12.1999 (FR-002);
- `value` = 0.0, `reason` = „“;
- in der Werkstatt: `event_id` = das gewählte Ereignis, wenn es über Wahrscheinlichkeit kommt,
  sonst das erste solche nach Kennung; `id` = dessen Kennung, im Profil eindeutig gemacht, etwa
  `reklamationswelle_2` (R11);
- beim Lesen: `event_id` und `id` leer, das ergibt zusätzlich V25 bzw. V30.

**In der Datei:** Tage stehen als `"JJJJ-MM-TT"`, der Wert als Anteil auf vier Nachkommastellen,
wie bei einem Modifikator in einer Probe (R2). Im Speicher sind es Tagesindizes.

**Wann er wirkt:** Gewürfelt wird am Monatsersten, mit der Chance dieses Tags (R8 von Feature
002). Ein Start-Modifikator, der am 15.03.1990 beginnt, wirkt deshalb ab der Würfelrunde am
01.04.1990. Einer, der am 31.12.1994 endet, wirkt noch in der Würfelrunde am 01.12.1994. Die
Werkstatt nennt die Tage, wie sie im Profil stehen.

## EventCatalog

Neu:

| Feld | Typ | Bedeutung |
|---|---|---|
| `profiles` | Array[DifficultyProfile] | immer zwei: `[0]` Leicht, `[1]` Schwer, auch leer; ein neuer Katalog hat zwei leere |

`get_profile(level)` gibt das Profil eines Grads zurück, für Mittel `null`. Der Katalog ändert sich
während eines Spiels nie; das gilt auch für seine Profile.

## TimelineRun (Lauf)

Neu:

| Feld | Typ | Bedeutung |
|---|---|---|
| `difficulty` | `Difficulty.Level` | Grad des Spiels, gesetzt in `_init()`, danach fest (Edge Case „Kein Wechsel im Spiel“) |
| `start_modifiers` | Array[ChanceModifier] | die Start-Modifikatoren des Profils, die der Lauf gesetzt hat, als eigene Kopien in der Reihenfolge des Profils; danach unveränderlich |
| `start_refusals` | PackedStringArray | je Start-Modifikator, den der Lauf nicht setzen konnte, ein Satz mit Grad, Kennung und Grund; meist leer (R6) |

**Anlegen** (`_init(catalog, seed, difficulty)`):
1. Katalog kopieren, fixe, jährliche und gesetzte Termine anlegen, Würfel der Ereignisse über
   Wahrscheinlichkeit anlegen, alles wie in Feature 002.
2. Ist der Grad unbekannt, gilt Mittel, mit einem Satz in `start_refusals`. Ablehnen müssen ihn
   vorher die Aufrufer (FR-011).
3. Die Start-Modifikatoren des Profils prüfen wie `add_modifier()` und setzen (R6). Je gesetztem
   Start-Modifikator kommt eine Meldung `START_MODIFIER` am Tag −1 ins Protokoll.

Danach würfelt `begin()` zum ersten Mal (FR-007). Die Würfel und ihre Zwecke bleiben, wie sie sind.

**Wirksame Chance** am Tag d, mit den Modifikatoren aus beiden Listen (FR-007, FR-025 von Feature
002):

```text
clamp(monthly_chance
      + Σ value der Start-Modifikatoren mit from_day ≤ d ≤ to_day
      + Σ value der Eingriffs-Modifikatoren mit from_day ≤ d ≤ to_day, 0, 1)
```

Beispiel aus US1, Szenario 7: 3 % + 5 − 6 = 2 %.

**Getrennte Listen** (R5): `modifiers` hält nur Modifikatoren aus Eingriffen. Kennungen sind je
Liste eindeutig; `remove_modifier()` und die Prüfung auf doppelte Kennungen in `add_modifier()`
sehen nur `modifiers`. Start-Modifikatoren stehen nie im Eingriffsprotokoll `interventions`.

**Begründung gewürfelter Termine:** `modifier_notes` nennt zuerst die geltenden
Start-Modifikatoren als „<Grad>: <grund> <wert>“, etwa „Schwer: Anspruchsvolle Kunden +5“, dann
die Eingriffe wie bisher.

## TimelineMessage

Neue Art am Ende der Aufzählung, die übrigen behalten ihre Nummern:

| Art | Spalte „Art“ | Tag | Text |
|---|---|---|---|
| `START_MODIFIER` | „Grad“ | −1, also 31.12.1984 | „Reklamationswelle: Start-Modifikator „Anspruchsvolle Kunden“ (Schwer) +5 Prozentpunkte vom 01.01.1985 bis 31.12.1999“ |

Sie steht nur im Protokoll, nie in der Rückgabe von `begin()` oder `advance_to()`, und wird kein
Signal (R6).

## Prüfmeldungen zu Profilen

`CatalogIssue` bleibt, wie es ist. Für Profile gilt:
- `event_id` ist leer, auch wenn der Start-Modifikator auf ein Ereignis zeigt. Sonst nähme
  `without_faulty()` dieses Ereignis aus dem Spiel (R8).
- `field` nennt die Stelle wie in der Datei: `profiles.schwer[2].event_id`, bei Strukturfehlern im
  Abschnitt selbst `profiles` oder `profiles.mittel`.
- `message` beginnt mit dem Ort, etwa „Profil „Schwer“, Start-Modifikator „reklamationswelle“,
  Feld „to_day“: …“.

## Prüfregeln

Die Tabelle aus Feature 002 (V01 bis V24) wird fortgesetzt. Alle neuen Regeln sind Fehler:

| Regel | Prüft | Feld |
|---|---|---|
| V25 | Start-Modifikator verweist auf ein unbekanntes Ereignis, auch ein leeres | `event_id` |
| V26 | Start-Modifikator auf ein Ereignis, das nicht über Wahrscheinlichkeit kommt: fix, jährlich, beim Start gesetzt oder nur als Folge | `event_id` |
| V27 | Ende vor dem Beginn | `to_day` |
| V28 | Beginn oder Ende außerhalb 01.01.1985 bis 31.12.1999 | `from_day` bzw. `to_day` |
| V29 | Grund leer oder nur Leerzeichen | `reason` |
| V30 | Kennung leer, mit anderen Zeichen als a–z, 0–9 und _, oder im Profil doppelt; eine Dublette wird bei jedem Start-Modifikator mit dieser Kennung gemeldet | `id` |

V22 deckt beim Lesen zusätzlich ab:
- `profiles` ist kein Objekt, ein Profil keine Liste, ein Eintrag kein Objekt;
- ein Schlüssel fehlt, hat den falschen Typ oder ist unbekannt, etwa `"value": "0,05"` oder
  `"from_day": "1990-02-30"`;
- ein Profil für `"mittel"` oder für einen Grad, den es nicht gibt (R4).

Reihenfolge der Meldungen in `validate()`: Ereignisse nach Kennung, dann Kategorien, dann die
Profile, Leicht vor Schwer, je Profil nach Stelle und je Start-Modifikator nach Regel.

## Fehlerhafte Start-Modifikatoren ausnehmen

`EventCatalog.without_faulty(issues)` nimmt wie bisher Ereignisse mit Fehlern aus. Dazu lässt es
in den Profilen der Kopie zwei Arten von Start-Modifikatoren weg (R8):
1. die, zu deren Stelle eine Meldung der Stufe `ERROR` gehört, deren Feld also mit
   `profiles.<key>[<i>].` beginnt;
2. die, deren Ereignis in der Kopie kein Ereignis über Wahrscheinlichkeit ist, etwa weil es selbst
   ausgenommen wurde.

Spiel, Simulator, Statistik und Textausgabe rechnen deshalb nur mit Start-Modifikatoren, die die
Prüfung bestehen. Die Zeitleiste meldet jeden weggelassenen mit Grad, Kennung und Grund über
`push_error()` (FR-013).

## Chance je Zeitabschnitt

Für das Formular eines Ereignisses über Wahrscheinlichkeit (FR-015, R12):
`DifficultyProfile.chance_periods()` gibt die wirksame Chance über das ganze Spiel als Abschnitte
zurück, je `{"from_day": int, "to_day": int, "chance": float}`:
- Grenzen liegen bei 0, bei jedem `from_day` und `to_day + 1` der Start-Modifikatoren auf das
  Ereignis und bei 5478, begrenzt auf den Spielzeitraum.
- Je Abschnitt gilt die Grundchance plus die Summe der dort geltenden Werte, begrenzt auf 0 bis 1.
- Gleiche Nachbarn werden zusammengelegt.
- Start-Modifikatoren mit einem Fehler zählen nicht, wie im Spiel.
- Für Mittel gibt es einen Abschnitt mit der Grundchance.

`describe_periods()` macht daraus den Text: „8 %“ bei einem Abschnitt, sonst „3 % bis
31.12.1994, 6 % ab 01.01.1995“, in der Mitte „5 % vom 01.01.1990 bis 31.12.1994“. Prozent mit
deutschem Komma und höchstens zwei Nachkommastellen, etwa „2,5 %“.

## WhatIfProbe

Neu:

| Feld | Typ | Bedeutung |
|---|---|---|
| `difficulty` | `Difficulty.Level` | Grad des Durchlaufs; in der Datei `"difficulty": "schwer"`, immer geschrieben; fehlt er, gilt Mittel; ein unbekannter Wert macht die Probe unlesbar (R14) |

`build_run(catalog)` legt den Lauf mit Seed und Grad an; danach wie in Feature 002. Das
Eingriffsprotokoll enthält nie Start-Modifikatoren.

## TimelineStatistics

Neu:

| Feld | Typ | Bedeutung |
|---|---|---|
| `difficulties` | Array[int] | die Grade, die die Statistik rechnet, je ein Wert aus `Difficulty.Level`; Vorgabe nur Mittel, beim Vergleich Leicht, Mittel, Schwer |

Zählen (R15):
- Ein Spiel ist ein Seed. Die Statistik spielt ihn in jedem Grad der Liste, mit denselben
  Eingriffen.
- `games_done` zählt Seeds, die in allen Graden fertig sind. Erst dann gehen ihre Zahlen in die
  `EventStatistic` der Grade ein.
- Ein Abbruch verwirft den angefangenen Seed in allen Graden. Jeder Grad hat also immer gleich
  viele Spiele mit denselben Seeds (FR-020).
- `accepted` und `refused` stammen aus dem ersten Seed im ersten Grad. Sie sind in jedem Grad
  gleich (R5).
