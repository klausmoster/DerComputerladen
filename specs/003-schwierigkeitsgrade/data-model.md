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

**Wenn sich das Ereignis ändert:**
- Löschen: Die Start-Modifikatoren darauf werden mit entfernt (FR-017).
- Umbenennen: Sie ziehen still mit (FR-017).
- Duplizieren: Die Kopie bekommt keine Start-Modifikatoren (Edge Case „Ereignis dupliziert“).
- Art ändern: Sie bleiben stehen, und V26 meldet sie (Edge Case „Art geändert“).

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
002). Ein Start-Modifikator wirkt in den Würfelrunden, deren Tag in seinem Zeitraum liegt (FR-007):
- Beginnt er am 15.03.1990, wirkt er ab der Würfelrunde am 01.04.1990.
- Endet er am 15.06.1994, wirkt er noch in der Würfelrunde am 01.06.1994.
- Einer, der am 31.12.1994 endet, wirkt zuletzt in der Würfelrunde am 01.12.1994.

Die Werkstatt nennt die Tage, wie sie im Profil stehen. Ist der Beginn kein Monatserster oder das
Ende kein Monatsletzter, warnt V31 und nennt die Würfelrunde (Klaus, 2026-10-22).

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
| `start_refusals` | PackedStringArray | je Start-Modifikator, den der Lauf nicht setzen konnte, ein Satz mit dem Ort aus `place()` und dem Grund; meist leer (R6) |

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
- `field` nennt die Stelle wie in der Datei:
  - an einem Feld: `profiles.schwer[2].event_id`;
  - an einem Eintrag, der kein Objekt ist: `profiles.schwer[2]`;
  - am Abschnitt: `profiles`; an einem Grad, den es nicht gibt, oder an Mittel:
    `profiles.<schlüssel>`, etwa `profiles.extrem` oder `profiles.mittel`.

  Wer Felder auswertet, vergleicht ganze Pfadteile: `profiles.schwerr` gehört nicht zu Schwer.
- `message` beginnt mit dem Ort und nennt das volle Feld, wie bei Kategorien: „Profil „Schwer“,
  Start-Modifikator „reklamationswelle“, Feld „profiles.schwer[2].to_day“: …“ (Analyse, B4).
- Lesemeldungen V22 zu einem Profil verwirft die Werkstatt, sobald eine Änderung dieses Profil
  ersetzt, denn danach können sich die Stellen verschieben. Rückgängig bringt sie nicht zurück
  (R10; Analyse, U2).

## Prüfregeln

Die Tabelle aus Feature 002 (V01 bis V24) wird fortgesetzt:

| Regel | Prüft | Feld | Stufe |
|---|---|---|---|
| V25 | Start-Modifikator verweist auf ein unbekanntes Ereignis, auch ein leeres | `event_id` | Fehler |
| V26 | Start-Modifikator auf ein Ereignis, das nicht über Wahrscheinlichkeit kommt: fix, jährlich, beim Start gesetzt oder nur als Folge | `event_id` | Fehler |
| V27 | Ende vor dem Beginn | `to_day` | Fehler |
| V28 | Beginn oder Ende außerhalb 01.01.1985 bis 31.12.1999 | `from_day` bzw. `to_day` | Fehler |
| V29 | Grund leer oder nur Leerzeichen | `reason` | Fehler |
| V30 | Kennung leer, mit anderen Zeichen als a–z, 0–9 und _, oder im Profil doppelt; eine Dublette wird bei jedem Start-Modifikator mit dieser Kennung gemeldet | `id` | Fehler |
| V31 | Beginn kein Monatserster oder Ende kein Monatsletzter; die Meldung nennt die erste bzw. letzte Würfelrunde, in der er wirkt. Beide mitten im Monat ergeben zwei Warnungen. Liegt im Zeitraum kein Monatserster, gibt es nur eine, an `from_day`: Er wirkt nie. Gilt V27 oder V28, prüft V31 nicht (Klaus, 2026-10-22; Analyse, U7) | `from_day` bzw. `to_day` | Warnung |

V31 kommt zu den Warnregeln V13, V20 und V23. Eine Warnung nimmt nichts aus: Ein Start-Modifikator
mit V31 gilt im Spiel, in den Würfelrunden seines Zeitraums.

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
1. die, zu deren Stelle eine Meldung der Stufe `ERROR` gehört, deren Feld also
   `profiles.<key>[<i>]` ist oder mit `profiles.<key>[<i>].` beginnt;
2. die, deren Ereignis in der Kopie kein Ereignis über Wahrscheinlichkeit ist, etwa weil es selbst
   ausgenommen wurde.

Spiel, Simulator, Statistik und Textausgabe rechnen deshalb nur mit Start-Modifikatoren, die die
Prüfung bestehen. Welche weggefallen sind, liefert `EventCatalog.skipped_start_modifiers(issues)`,
je mit Grad, Stelle, Ort aus `place()` und Fehlergrund, nach derselben Regel wie oben (Analyse,
G1). `by_event` kennzeichnet die, die ohne eigene Meldung nur wegen ihres Ereignisses wegfallen.
Zeitleiste und Textausgabe nennen jeden genau einmal: mit seiner eigenen Meldung oder, mit
`by_event`, aus dieser Liste (FR-013). Simulator und Statistik nennen alle im Hinweis auf
Ausgenommenes.

## Abhängige Ereignisse

Für FR-009 und SC-002: Abhängig von einer Menge veränderter Ereignisse ist jedes Ereignis, das von
einem davon aus erreichbar ist, auch über mehrere Stufen:
- über ein Folgeereignis, von der Quelle zur Folge;
- über eine Bedingung, vom Ereignis in der Bedingung zum Ereignis, das die Bedingung hat.

Verändert ist ein Ereignis, wenn ein geltender Start-Modifikator des Grads darauf zeigt. Bei zwei
Graden zählen die Start-Modifikatoren beider Profile. Alle übrigen Ereignisse haben in beiden
Graden dieselben Termine. Ein Test bildet die Hülle aus dem Katalog und prüft jede Markierung von
`ScheduleDiff` und jeden weggefallenen Termin in `removed` dagegen (Analyse, G2).

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
deutschem Komma und höchstens zwei Nachkommastellen, etwa „2,5 %“. Die Zahl der Abschnitte hat
keine Grenze; im Formular bricht die Zeile eines Grads um.

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
