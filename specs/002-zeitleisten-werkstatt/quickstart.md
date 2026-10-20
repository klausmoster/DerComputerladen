# Quickstart: Zeitleisten-Werkstatt prüfen

So lässt sich nachweisen, dass das Feature fertig ist. Was gebaut wird, steht in den Verträgen
[zeitleiste.md](contracts/zeitleiste.md), [werkstatt.md](contracts/werkstatt.md) und
[ereigniskatalog.md](contracts/ereigniskatalog.md); hier steht nur, wie man es prüft. Alle Befehle
laufen vom Repo-Root aus, Godot liegt unter `/Applications/Godot.app/Contents/MacOS/Godot`.

Jede Phase nimmt Klaus mit den Abschnitten ab, die es bis dahin gibt; die Tabelle „Abnahme je
Phase“ am Ende ordnet sie den Abnahme-Tasks zu.

## Voraussetzungen

- Godot 4.7.2, GUT 9.7.1 (im Projekt).
- Der Katalog `src/data/event_catalog.json` ist übernommen, die Test-Kataloge liegen unter
  `src/test/fixtures/`.
- Für den Export: Export-Vorlagen 4.7.2 und das Preset „macOS“ aus Feature 001.

## 1. Automatische Tests

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://addons/gut/gut_cmdln.gd
```

Erwartet: alle Tests grün. Sobald die jeweilige Phase fertig ist, sind damit belegt:
- FR-048: Der echte Katalog hat keine Fehler (ab Phase 2).
- SC-006: Jede Fehlerregel schlägt bei ihrer kaputten Fixture an, jede Warnregel warnt (Phase 2).
- SC-002: 10 Läufe mit gleichem Seed ergeben 10 gleiche Textausgaben (Phase 3).
- SC-005: Die historischen Ereignisse kommen wie im Schnappschuss, geprüft an der eingefrorenen
  Übernahme (Phase 3).
- SC-009: Das Weihnachtsgeschäft liegt in allen 15 Jahren richtig (Phase 5).
- SC-003: Ein Modifikator ändert keinen fremden Termin (Phase 8).
- SC-008: 50 % pro Monat ergeben im Mittel 85,5 bis 94,5 (Phase 9).

Dass der Fahrplan unter Windows und Linux gleich ausfällt (FR-014), weist erst 11-03 Build &
Export nach.

## 2. Startprobe ohne Fenster

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src --quit-after 60
/Applications/Godot.app/Contents/MacOS/Godot --headless -d --path src --quit-after 60
```

Erwartet: Exit-Code 0, keine Ausgabe, auch keine Warnung. Die Zeitleiste lädt den Katalog still.

## 3. Textausgabe (ab Phase 3)

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://tools/werkstatt/fahrplan_ausgabe.gd -- --seed 4711 > /tmp/fahrplan_a.txt
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://tools/werkstatt/fahrplan_ausgabe.gd -- --seed 4711 > /tmp/fahrplan_b.txt
diff /tmp/fahrplan_a.txt /tmp/fahrplan_b.txt
```

| Prüfung | Erwartet | Bezug |
|---|---|---|
| `diff` der beiden Läufe | keine Ausgabe | US1, Szenario 2; SC-002 |
| Zeile „Intel Pentium erscheint“ | am 22.03.1993, darunter am 05.04.1993 „Nachfrage · ram · +20%“ | US1, Szenarien 1 und 5 |
| `--seed 1` und `--seed 2` mit `--katalog res://test/fixtures/catalog_us1_preset.json` | verschiedene gesetzte Termine, je Seed bei Wiederholung gleich | US1, Szenario 4 |
| `--bis 1990-12-31` | Kopfzeile „bis 31.12.1990“, kein Termin danach | FR-046 |
| `--katalog res://test/fixtures/catalog_v04_titel_leer.json`, danach `echo $?` | Meldung auf stderr, Ausgabe ohne das fehlerhafte Ereignis, Exit-Code 1 | FR-046, R18 |
| `--katalog res://test/fixtures/catalog_v22_kaputt.json` | nur die Meldung mit Zeile auf stderr, Exit-Code 1 | FR-046, R18 |

## 4. Werkstatt von Hand

Im Editor `src/tools/werkstatt/werkstatt.tscn` öffnen und F6 drücken.

### 4.1 Grundgerüst (ab Phase 4)

| Prüfung | Erwartet | Bezug |
|---|---|---|
| Start | maximiertes Fenster in voller Auflösung, gut lesbare Schrift, Farben des Computerladens | FR-029 |
| Suche „pentium“, Filter Art und Kategorie | Liste schrumpft passend | FR-030 |
| „Neu …“, Titel „Neubaugebiet am Stadtrand“, Art „beim Start gesetzt“ | Dialog schlägt `neubaugebiet_am_stadtrand` vor; danach zeigt das Formular Zeitfenster, Anzahl mit Wahrscheinlichkeit je Anzahl und Mindestabstand | US2, Szenario 1; FR-032 |
| Fixes Datum 12.05.2001 eingeben | Meldung am Feld Datum, Prüfung zählt einen Fehler mehr | US2, Szenario 3 |
| Diese Meldung in der Prüfung anklicken | Ereignis gewählt, Fokus im Feld Datum | FR-033 |
| „3,5“ und „3.5“ als Chance, „1.3.1993“ als Datum, dann „abc“ | alle drei angenommen und mit Komma angezeigt; „abc“ abgelehnt, alter Wert und Hinweis | FR-031 |
| Ein Feld mit Enter bestätigen, dann sofort Cmd+Z | Fokus ist aus dem Feld, Cmd+Z nimmt die Änderung im Katalog zurück | FR-034, R15 |
| Art von „über Wahrscheinlichkeit“ auf „beim Start gesetzt“, dann Cmd+Z | Zeitfenster, Mindestabstand und Dauer bleiben; Chance und Höchstzahl fallen weg, Anzahl und Gewichte bekommen Vorgaben; Cmd+Z bringt Chance und Höchstzahl zurück | FR-031 |
| Bei einem gesetzten Ereignis „Anzahl bis“ von 1 auf 3 stellen, dann Cmd+Z | Gewichte neu verteilt, alle gleich; ein Cmd+Z nimmt Anzahl und Gewichte zusammen zurück | FR-004, FR-031 |
| Kategorie anlegen, umbenennen, eine belegte Kategorie löschen | neue Kategorie hat eine freie der erlaubten Farben, Umbenennen ändert nur den Namen, Löschen gesperrt | FR-031 |
| Ein Ereignis mit Verweis löschen, dann Cmd+Z | Rückfrage nennt den Verweis; Ereignis und Verweis sind weg; Cmd+Z holt beide zurück | US2, Szenario 4; FR-036 |
| Kennung ändern, speichern | Verweise zeigen auf die neue Kennung | US2, Szenario 6 |
| Ein Feld ändern, speichern, `git diff src/data/event_catalog.json` | genau eine geänderte Zeile | US2, Szenario 2; FR-035 |
| Drei Felder ändern, dreimal Cmd+Z, dann Shift+Cmd+Z | Schritt für Schritt zurück und wieder vor | US2, Szenario 7 |
| Mit einem Fehler im Katalog speichern | Rückfrage „Der Katalog hat 1 Fehler. Trotzdem speichern?“; „Abbrechen“ speichert nicht | FR-034 |
| Etwas ändern, dann „Verwerfen“ | Rückfrage; danach der Stand der Datei, nichts mehr rückgängig zu machen | FR-034 |
| Mit ungespeicherten Änderungen schließen, einmal per Fensterknopf, einmal per Cmd+Q | Rückfrage „Speichern / Verwerfen / Abbrechen“ | FR-034, R15 |
| Katalogdatei in einem Texteditor ändern, dann in der Werkstatt speichern | Warnung vor fremder Änderung | Edge Case |
| Einen unbekannten Schlüssel in die Datei schreiben, Werkstatt neu starten, ein anderes Feld ändern | V22 nennt den Schlüssel und bleibt nach der Änderung stehen; Speichern fragt wegen des Fehlers nach | ereigniskatalog.md, Regel 5 |
| Komma in der Datei löschen, Werkstatt neu starten | Meldung mit Zeile und Grund, Datei unverändert | Edge Case, R4 |
| Katalogdatei vorübergehend umbenennen, Werkstatt starten | Angebot, einen leeren Katalog anzulegen; geschrieben wird erst beim Speichern | Edge Case |
| Ungespeicherte Änderung, 2 Minuten warten, Werkstatt im Terminal mit `kill` beenden, neu starten | Angebot, die Sicherungskopie zu übernehmen, mit beiden Zeiten; danach ist die Änderung da | FR-050 |
| Bei liegender Sicherungskopie die Werkstatt mit `-- --katalog res://test/fixtures/catalog_minimal.json` starten | keine Übernahme angeboten, ein Hinweis nennt den Pfad der Kopie | R23 |

### 4.2 Kalender und Dauer (ab Phase 5)

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://tools/werkstatt/fahrplan_ausgabe.gd -- --seed 4711 | grep -E "weihnachtsgeschaeft|winter|cebit"
```

| Prüfung | Erwartet | Bezug |
|---|---|---|
| Zeilen `weihnachtsgeschaeft` | 15 Termine „01.11.JJJJ  bis 31.12.JJJJ“; 1999 mit „läuft“ und „(Ende nach Spielende)“ | US3; SC-009 |
| Zeilen `winter` | der erste ab 01.01.1985 mit „(lief schon vor Spielbeginn)“, der letzte bis 29.02.2000 mit „(Ende nach Spielende)“ | US3, Szenario 2; R9 |
| Zeilen `cebit` | erst ab 1986 | FR-023; R9 |
| Weihnachtsgeschäft im Formular | jährlich, 01.11. bis Monatsende Dezember, Wirkung „gilt nur während“ | US3, FR-007 |

### 4.3 Zeitstrahl (ab Phase 6)

| Prüfung | Erwartet | Bezug |
|---|---|---|
| Pentium auf dem Zeitstrahl auf den 15.04.1993 ziehen, dann Cmd+Z | Datum tagesgenau am Mauszeiger, übernommen; Cmd+Z stellt den 22.03.1993 wieder her | US4, Szenarien 1 und 7 |
| Ende eines Zeitfensters ziehen, bis Anzahl und Abstand nicht mehr passen | Fehler steht schon beim Ziehen am Mauszeiger; nach dem Loslassen meldet die Prüfung V10 | US4, Szenario 2 |
| Maus über einem Ereignis ruhen lassen | Hinweis mit Titel, Art, Datum oder Fenster, Chance | US4, Szenario 3 |
| Rechtsklick auf ein Ereignis | Menü Bearbeiten, Duplizieren, Löschen | US4, Szenario 4 |
| Doppelklick in der Zeile Hardware, März 1996 | neues fixes Ereignis an diesem Tag, gewählt, Fokus im Titel | US4, Szenario 5 |
| Mit Cmd+Mausrad hineinzoomen | bis zu einem Monat mit Tagesstrichen | US4, Szenario 6 |
| Weihnachtsgeschäft ziehen | geht nicht, Hinweis „nur im Formular änderbar“ | FR-039 |
| Zwei Ereignisse derselben Kategorie auf denselben Tag legen | gestapelt untereinander, Titel nur bei Platz | FR-037 |
| Titel und Farben ansehen | Titel in Textfarbe neben der Marke, Kategorien gut unterscheidbar | FR-029, R14 |

### 4.4 Simulator (ab Phase 7)

| Prüfung | Erwartet | Bezug |
|---|---|---|
| Buchstaben ins Seed-Feld tippen | werden nicht angenommen | FR-040 |
| Seed 4711, „Fahrplan erzeugen“ | alle feststehenden Termine, Zustand „geplant“ | US5, Szenario 1 |
| „+1 Tag“, „+1 Monat“, „+1 Jahr“, dann „Bis …“ 31.12.1990 | Datum springt entsprechend, das Protokoll wächst, Zustände wechseln auf „eingetreten“ oder „läuft“ | FR-041 |
| „Bis zum Ende“ mit dem übernommenen Katalog | in unter 1 Sekunde fertig, Protokoll in zeitlicher Reihenfolge | US5, Szenario 2; SC-004 |
| Während eines Laufs ein Ereignis im Katalog ändern | Hinweis „Katalog geändert, neu starten“, der Lauf bleibt, wie er ist | FR-042 |
| Ein Ereignis absichtlich fehlerhaft machen, „Fahrplan erzeugen“ | Ereignis ausgenommen, Hinweis nennt es | FR-042 |
| Einen gewürfelten Termin auswählen | Würfelwert, Grundchance, Modifikatoren, Schwelle | US5, Szenario 3; SC-007 |
| Chance eines Ereignisses ändern, nicht speichern, mit demselben Seed „Fahrplan erzeugen“ und „Bis zum Ende“ | geänderte Chance gilt, andere Termine bleiben | US5, Szenario 4 |

Dass der Simulator die Spieluhr nicht anfasst (US5, Szenario 5), prüft `test_werkstatt_scene.gd`.

### 4.5 Was wäre, wenn (ab Phase 8)

| Prüfung | Erwartet | Bezug |
|---|---|---|
| Modifikator „Ware vom windigen Händler: +5 Prozentpunkte vom 01.01.1990 bis 31.12.1993“ auf Reklamationswelle | Begründungen 1990–1993 nennen 8 %, sonst 3 % | US6, Szenario 1 |
| „Neu starten mit Eingriffen“, Filter „nur Unterschiede“ | markiert sind nur Termine der Reklamationswelle und von ihr abhängige; weggefallene stehen durchgestrichen; „verschoben“ steht nur bei verschobenen Terminen | US6, Szenario 2; FR-043 |
| Modifikatoren +4 und −6, dann +4 entfernen | „−3 % → 0 %“ angezeigt | US6, Szenario 3 |
| „Konkurrent eröffnet“ auf „beim Start gesetzt“ stellen (nicht speichern), Simulator neu starten, vor dessen Termin den Termin mit Grund absagen | Termin „abgesagt“ mit Grund, tritt nicht ein; danach Cmd+Z bis zum alten Stand | US6, Szenario 4 |
| „Windows 95“ absagen oder verschieben | abgelehnt, mit Grund | US6, Szenario 5 |
| Einen gewürfelten Termin absagen, dann „Neu starten mit Eingriffen“ | der Termin ist wieder abgesagt, nichts als „nicht anwendbar“ genannt | FR-043, R22 |
| Probe mit Modifikator und Absage als „Windiger Händler ab 1990“ speichern, Werkstatt schließen, wieder öffnen, Probe laden | Seed, Modifikator und Absage wieder gesetzt, Fahrplan wie vorher; Datei unter `src/tools/werkstatt/proben/` | US6, Szenario 7; FR-051 |
| Das abgesagte Ereignis im Katalog auf eine andere Art stellen, Probe erneut laden | Absage als nicht anwendbar genannt, Modifikator gesetzt | US6, Szenario 8 |
| „Probe löschen“ | Probe fehlt in der Liste, die Datei ist weg | FR-051 |

Die genauen Werte aus US6, Szenario 4 (01.06.1992, Absage am 01.01.1992) und den Ablauf eines
Modifikators (Szenario 6) prüft `test_interventions.gd` mit einem Test-Katalog; von Hand reicht
der Ablauf.

### 4.6 Statistik (ab Phase 9)

| Prüfung | Erwartet | Bezug |
|---|---|---|
| Statistik über 1.000 Spiele vom Start bis 100 %, einmal abbrechen | höchstens 30 Sekunden; abgebrochen mit Zahl der fertigen Spiele | US7, Szenario 1; SC-004 |
| Zeile „Neubaugebiet“ und eine Zeile eines fixen Ereignisses | Mittelwert, kleinste und größte Anzahl, „ohne“, „Obergrenze“ (rund 85 %), Verteilung auf die Jahre; beim fixen Ereignis „–“ bei der Obergrenze | US7, Szenario 2; FR-044 |
| Im Simulator +5 Prozentpunkte auf die Reklamationswelle, dann Statistik mit Häkchen „Mit Modifikatoren und Einplanungen aus dem Simulator“ und ohne | mit Häkchen höherer Mittelwert der Reklamationswelle, ohne wie vorher | US7, Szenario 4; FR-045 |

### 4.7 Abnahme der Werkstatt (Phase 10)

| Prüfung | Erwartet | Bezug |
|---|---|---|
| Fünf Ereignisse anlegen: fix, jährlich mit Dauer, beim Start gesetzt, über Wahrscheinlichkeit und eines „nur als Folge“; speichern; im Simulator den Fahrplan für Seed 4711 erzeugen. Uhr vom ersten „Neu“, bis der Fahrplan erzeugt ist | ohne Datei von Hand, zusammen höchstens 10 Minuten; im Fahrplan stehen das fixe, das jährliche und das gesetzte Ereignis | SC-001 |
| Abnahme | Klaus pflegt Ereignisse ohne Code und bestätigt das Eintakten | SC-010 |

## 5. Großer Katalog (Phase 10, SC-011)

`src/test/fixtures/catalog_500.json` enthält 500 erzeugte Ereignisse, je zur Hälfte fix und über
Wahrscheinlichkeit. `test_large_catalog.gd` misst die Prüfung, eine Änderung samt neuer Prüfung
und ein ganzes Spiel; von Hand bleibt:

```bash
time /Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://tools/werkstatt/fahrplan_ausgabe.gd -- --seed 1 --katalog res://test/fixtures/catalog_500.json > /dev/null
/Applications/Godot.app/Contents/MacOS/Godot --path src res://tools/werkstatt/werkstatt.tscn -- --katalog res://test/fixtures/catalog_500.json
```

| Prüfung | Erwartet | Bezug |
|---|---|---|
| `time` der Textausgabe | unter 2 Sekunden samt Programmstart | SC-011 |
| In der Werkstatt ein Feld ändern und ein Ereignis ziehen | keine spürbare Verzögerung, das Ziehen ruckelt nicht | SC-011 |
| Statistik über 1.000 Spiele | unter 5 Minuten, Werkstatt bleibt bedienbar | SC-011 |

## 6. Export

| Prüfung | Erwartet | Bezug |
|---|---|---|
| `src/export_presets.cfg` ansehen (Phase 1 und nach dem Probe-Export in Phase 3) | `exclude_filter` enthält `tools/*`, keine Zugangsdaten | FR-028, Verfassung |
| macOS-App exportieren und im Terminal starten (Phase 3) | keine Meldung zum Ereigniskatalog: Er liegt im Paket und wird gelesen | R4 |

## Abnahme je Phase

| Phase | Abnahme | Abschnitte |
|---|---|---|
| 1 | T006 | Schnappschuss und Katalogdatei ansehen; 6, erste Zeile |
| 2 | T019 | 1, 2 |
| 3 | T030 | 1, 2, 3, 6 |
| 4 | T040 | 1, 4.1 |
| 5 | T046 | 1, 4.2 |
| 6 | T051 | 1, 4.3 |
| 7 | T055 | 1, 4.4 |
| 8 | T063 | 1, 4.5 |
| 9 | T067 | 1, 4.6 |
| 10 | T069, T072 | 5; danach 1 bis 6 vollständig samt 4.7 |
