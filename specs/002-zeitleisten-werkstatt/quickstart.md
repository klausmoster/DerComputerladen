# Quickstart: Zeitleisten-Werkstatt prüfen

So lässt sich nachweisen, dass das Feature fertig ist. Was gebaut wird, steht in den Verträgen
[zeitleiste.md](contracts/zeitleiste.md), [werkstatt.md](contracts/werkstatt.md) und
[ereigniskatalog.md](contracts/ereigniskatalog.md); hier steht nur, wie man es prüft. Alle Befehle
laufen vom Repo-Root aus, Godot liegt unter `/Applications/Godot.app/Contents/MacOS/Godot`.

## Voraussetzungen

- Godot 4.7.2, GUT 9.7.1 (im Projekt).
- Der Katalog `src/data/event_catalog.json` ist übernommen, die Test-Kataloge liegen unter
  `src/test/fixtures/`.
- Für den Export: Export-Vorlagen 4.7.2 und das Preset „macOS“ aus Feature 001.

## 1. Automatische Tests

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://addons/gut/gut_cmdln.gd
```

Erwartet: alle Tests grün. Damit sind belegt:
- SC-003: Ein Modifikator ändert keinen fremden Termin.
- SC-005: Die historischen Ereignisse kommen wie im Schnappschuss.
- SC-006: Jede Prüfregel schlägt bei ihrer kaputten Fixture an.
- SC-008: 50 % pro Monat ergeben im Mittel 85,5 bis 94,5.
- SC-009: Das Weihnachtsgeschäft liegt in allen 15 Jahren richtig.
- FR-048: Der echte Katalog ist fehlerfrei.

## 2. Startprobe ohne Fenster

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src --quit-after 60
/Applications/Godot.app/Contents/MacOS/Godot --headless -d --path src --quit-after 60
```

Erwartet: Exit-Code 0, keine Ausgabe, auch keine Warnung. Die Zeitleiste lädt den Katalog still.

## 3. Textausgabe

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://tools/werkstatt/fahrplan_ausgabe.gd -- --seed 4711 > /tmp/fahrplan_a.txt
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://tools/werkstatt/fahrplan_ausgabe.gd -- --seed 4711 > /tmp/fahrplan_b.txt
diff /tmp/fahrplan_a.txt /tmp/fahrplan_b.txt
```

| Prüfung | Erwartet | Bezug |
|---|---|---|
| `diff` der beiden Läufe | keine Ausgabe | US1, Szenario 2; SC-002 |
| Zeile „Intel Pentium erscheint“ | am 22.03.1993, darunter am 05.04.1993 „Nachfrage · ram · +20%“ | US1, Szenarien 1 und 5 |
| Weihnachtsgeschäft | 15 Termine, Beginn 01.11., Ende 01.01. des Folgejahrs, 1999 „endet nach Spielende“ | US3; SC-009 |
| `--seed 1` und `--seed 2` mit `--katalog res://test/fixtures/catalog_us1_preset.json` | verschiedene gesetzte Termine, je Seed bei Wiederholung gleich | US1, Szenario 4 |
| `--katalog` auf eine kaputte Fixture | Meldung auf stderr, Exit-Code 1 | FR-049 |

## 4. Werkstatt von Hand

Im Editor `src/tools/werkstatt/werkstatt.tscn` öffnen und F6 drücken. Die Stoppuhr läuft bei
SC-001 und SC-004 mit.

| Prüfung | Erwartet | Bezug |
|---|---|---|
| Start | maximiertes Fenster in voller Auflösung, gut lesbare Schrift, Farben des Computerladens | FR-029 |
| Suche „pentium“, Filter Art und Kategorie | Liste schrumpft passend | FR-030 |
| Neues Ereignis „Neubaugebiet am Stadtrand“, Art „beim Start gesetzt“ | Felder Zeitfenster, Anzahl mit Wahrscheinlichkeit je Anzahl, Mindestabstand; Kennung `neubaugebiet_am_stadtrand` | US2, Szenario 1 |
| Je ein Ereignis jeder Art anlegen, dann im Simulator ansehen; Uhr vom ersten „Neu“, bis das vierte im Simulator steht | gelingt ohne Datei von Hand, zusammen höchstens 10 Minuten | SC-001 |
| Fixes Datum 12.05.2001 eingeben | Meldung am Feld Datum, Prüfung zählt einen Fehler mehr | US2, Szenario 3 |
| „3,5“ und „3.5“ als Chance, „1.3.1993“ als Datum, dann „abc“ | alle drei angenommen und mit Komma angezeigt; „abc“ abgelehnt, alter Wert und Hinweis | FR-031 |
| Art von „über Wahrscheinlichkeit“ auf „fix“ und zurück, dann Cmd+Z | Zeitfenster und Dauer bleiben, die Chance kommt erst mit Cmd+Z zurück | FR-031 |
| Kategorie anlegen, umbenennen, eine belegte Kategorie löschen | neue Kategorie hat eine freie Farbe, Umbenennen ändert nur den Namen, Löschen gesperrt | FR-031 |
| Ein Ereignis mit Verweis löschen, dann Cmd+Z | Rückfrage nennt den Verweis; Ereignis und Verweis sind weg; Cmd+Z holt beide zurück | US2, Szenario 4; FR-036 |
| Kennung ändern, speichern | Verweise zeigen auf die neue Kennung | US2, Szenario 6 |
| Ein Feld ändern, speichern, `git diff src/data/event_catalog.json` | genau eine geänderte Zeile | US2, Szenario 2; FR-035 |
| Drei Felder ändern, dreimal Cmd+Z, dann Shift+Cmd+Z | Schritt für Schritt zurück und wieder vor | US2, Szenario 7 |
| Mit ungespeicherten Änderungen schließen, einmal per Fensterknopf, einmal per Cmd+Q | Rückfrage „Speichern / Verwerfen / Abbrechen“ | FR-034, R15 |
| Katalogdatei in einem Texteditor ändern, dann in der Werkstatt speichern | Warnung vor fremder Änderung | Edge Case |
| Komma in der Datei löschen, Werkstatt neu starten | Meldung mit Zeile und Grund, Datei unverändert | Edge Case, R4 |
| Katalogdatei vorübergehend umbenennen, Werkstatt starten | Angebot, einen leeren Katalog anzulegen; geschrieben wird erst beim Speichern | Edge Case |
| Ungespeicherte Änderung, 2 Minuten warten, Werkstatt im Terminal mit `kill` beenden, neu starten | Angebot, die Sicherungskopie zu übernehmen, mit beiden Zeiten; danach ist die Änderung da | FR-050 |
| Pentium auf dem Zeitstrahl auf den 15.04.1993 ziehen, dann Cmd+Z | Datum tagesgenau am Mauszeiger, übernommen; Cmd+Z stellt den 22.03.1993 wieder her | US4, Szenarien 1 und 7 |
| Ende eines Zeitfensters ziehen, bis Anzahl und Abstand nicht mehr passen | Fenster ändert sich, Prüfung meldet sofort V10 | US4, Szenario 2 |
| Maus über einem Ereignis ruhen lassen | Hinweis mit Titel, Art, Datum oder Fenster, Chance | US4, Szenario 3 |
| Rechtsklick auf ein Ereignis | Menü Bearbeiten, Duplizieren, Löschen | US4, Szenario 4 |
| Doppelklick in der Zeile Hardware, März 1996 | neues fixes Ereignis an diesem Tag | US4, Szenario 5 |
| Mit Cmd+Mausrad hineinzoomen | bis zu einem Monat mit Tagesstrichen | US4, Szenario 6 |
| Weihnachtsgeschäft ziehen | geht nicht, Hinweis „nur im Formular änderbar“ | FR-039 |
| Zwei Ereignisse derselben Kategorie auf denselben Tag legen | gestapelt untereinander, Titel nur bei Platz | FR-037 |
| Simulator: Seed 4711, „Fahrplan erzeugen“ | alle feststehenden Termine, Zustand „geplant“ | US5, Szenario 1 |
| „Bis zum Ende“ mit dem übernommenen Katalog | in unter 1 Sekunde fertig, Protokoll in zeitlicher Reihenfolge | US5, Szenario 2; SC-004 |
| Während eines Laufs ein Ereignis im Katalog ändern | Hinweis „Katalog geändert, neu starten“, der Lauf bleibt, wie er ist | FR-042 |
| Ein Ereignis absichtlich fehlerhaft machen, Simulator neu starten | Ereignis ausgenommen, Hinweis nennt es | FR-042 |
| Einen gewürfelten Termin auswählen | Würfelwert, Grundchance, Modifikatoren, Schwelle | US5, Szenario 3; SC-007 |
| Chance eines Ereignisses ändern, nicht speichern, neu starten | geänderte Chance gilt, andere Termine bleiben | US5, Szenario 4 |
| Modifikator „Ware vom windigen Händler: +5 Prozentpunkte vom 01.01.1990 bis 31.12.1993“ auf Reklamationswelle | Begründungen 1990–1993 nennen 8 %, sonst 3 % | US6, Szenario 1 |
| „Neu starten mit Eingriffen“, Filter „nur Unterschiede“ | markiert sind nur Termine der Reklamationswelle und von ihr abhängige; weggefallene stehen durchgestrichen | US6, Szenario 2; FR-043 |
| Modifikatoren +4 und −6, dann +4 entfernen | „−3 % → 0 %“ angezeigt | US6, Szenario 3 |
| „Konkurrent eröffnet“ auf „beim Start gesetzt“ stellen (nicht speichern), Simulator neu starten, vor dessen Termin den Termin mit Grund absagen | Termin „abgesagt“ mit Grund, tritt nicht ein; danach Cmd+Z bis zum alten Stand | US6, Szenario 4 |
| „Windows 95“ absagen oder verschieben | abgelehnt, mit Grund | US6, Szenario 5 |
| Probe mit Modifikator und Absage als „Windiger Händler ab 1990“ speichern, Werkstatt schließen, wieder öffnen, Probe laden | Seed, Modifikator und Absage wieder gesetzt, Fahrplan wie vorher; Datei unter `src/tools/werkstatt/proben/` | US6, Szenario 7; FR-051 |
| Das abgesagte Ereignis im Katalog auf eine andere Art stellen, Probe erneut laden | Absage als nicht anwendbar genannt, Modifikator gesetzt | US6, Szenario 8 |
| Statistik über 1.000 Spiele vom Start bis 100 %, einmal abbrechen | höchstens 30 Sekunden; abgebrochen mit Zahl der fertigen Spiele | US7, Szenario 1; SC-004 |
| Statistik, Zeile „Neubaugebiet“ und eine Zeile eines fixen Ereignisses | Mittelwert, kleinste und größte Anzahl, „ohne“, „Obergrenze“ (rund 85 %), Verteilung auf die Jahre; beim fixen Ereignis „–“ bei der Obergrenze | US7, Szenario 2; FR-044 |
| Abnahme | Klaus pflegt Ereignisse ohne Code und bestätigt das Eintakten | SC-010 |

Die genauen Werte aus US6, Szenario 4 (01.06.1992, Absage am 01.01.1992) prüft
`test_interventions.gd` mit einem Test-Katalog; von Hand reicht der Ablauf.

## 5. Großer Katalog (SC-011)

`src/test/fixtures/catalog_500.json` enthält 500 erzeugte Ereignisse, je zur Hälfte fix und über
Wahrscheinlichkeit. `test_large_catalog.gd` prüft Prüfung und Spiel automatisch; von Hand bleibt:

```bash
time /Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://tools/werkstatt/fahrplan_ausgabe.gd -- --seed 1 --katalog res://test/fixtures/catalog_500.json > /dev/null
/Applications/Godot.app/Contents/MacOS/Godot --path src res://tools/werkstatt/werkstatt.tscn -- --katalog res://test/fixtures/catalog_500.json
```

| Prüfung | Erwartet | Bezug |
|---|---|---|
| `time` der Textausgabe | unter 2 Sekunden samt Programmstart | SC-011 |
| In der Werkstatt ein Feld ändern und ein Ereignis ziehen | keine spürbare Verzögerung | SC-011 |
| Statistik über 1.000 Spiele | unter 5 Minuten, Werkstatt bleibt bedienbar | SC-011 |

## 6. Export

| Prüfung | Erwartet | Bezug |
|---|---|---|
| `src/export_presets.cfg` ansehen | `exclude_filter` enthält `tools/*`, keine Zugangsdaten | FR-028, Verfassung |
| macOS-App exportieren und im Terminal starten | keine Meldung zum Ereigniskatalog: Er liegt im Paket und wird gelesen | R4 |
