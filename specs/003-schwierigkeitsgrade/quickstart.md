# Quickstart: Schwierigkeitsgrade prüfen

So lässt sich nachweisen, dass das Feature fertig ist. Was gebaut wird, steht in den Verträgen
[zeitleiste.md](contracts/zeitleiste.md), [werkstatt.md](contracts/werkstatt.md) und
[ereigniskatalog.md](contracts/ereigniskatalog.md); hier steht nur, wie man es prüft. Alle Befehle
laufen vom Repo-Root aus, Godot liegt unter `/Applications/Godot.app/Contents/MacOS/Godot`.

Jede Phase nimmt Klaus mit den Abschnitten ab, die es bis dahin gibt. Die Tabelle „Abnahme je
Phase“ am Ende ordnet sie zu. Der Quickstart von Feature 002 gilt weiter und muss nach diesem
Feature unverändert bestehen. Zwei Ausnahmen gibt es: Die Kopfzeile der Textausgabe und der
Ergebnistext der Statistik nennen jetzt den Grad. Die Prüfung „eine Änderung, eine Zeile“ am
echten Katalog gilt wieder, sobald Klaus ihn zur Abnahme von Phase 1 einmal gespeichert hat.

## Voraussetzungen

- Godot 4.7.2, GUT 9.7.1 (im Projekt).
- Die Test-Kataloge und die eingefrorene Grundlinie liegen unter `src/test/fixtures/`.
- Für die Prüfung von Hand arbeitet Klaus auf Kopien, nicht auf dem echten Katalog und nie auf
  einer Fixture:

  ```bash
  cp src/data/event_catalog.json /tmp/katalog_probe.json
  ```

  - Für 4.1 braucht die Kopie leere Profile. Vor T020 ist das jede frische Kopie. Danach, etwa in
    Phase 6, öffnet Klaus die frische Kopie in der Werkstatt, löscht im Reiter
    „Schwierigkeitsgrade“ alle Start-Modifikatoren von Leicht und Schwer und speichert.
  - Für 4.2 und 4.3 entsteht die Kopie neu, mit den Profilen des echten Katalogs, also ab T020.

  Für die Fälle mit festen Zahlen gibt es eine zweite Kopie:

  ```bash
  cp src/test/fixtures/catalog_us1_grade.json /tmp/grade_probe.json
  ```

## 1. Automatische Tests

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://addons/gut/gut_cmdln.gd
```

Erwartet: alle Tests grün, bei zwei Läufen mit derselben Zahl von Prüfungen. Sobald die jeweilige
Phase fertig ist, sind damit belegt:
- FR-012 und FR-014: Jede Fehlerregel V25 bis V30 schlägt bei ihrer kaputten Fixture an, V31
  warnt. Der echte Katalog hat auch in seinen Profilen keinen Fehler (ab Phase 1). Ab Phase 3 sind
  Leicht und Schwer im echten Katalog nicht leer (CHK008).
- SC-007: Mittel ergibt für die Seeds 1, 4711 und 99999 Fahrplan und Protokoll wie die
  eingefrorene Grundlinie, Zeichen für Zeichen, den Fahrplan ohne Kopfzeile (ab Phase 2).
- SC-001: 100 Wiederholungen von Seed und Grad ergeben 100 gleiche Fahrpläne (Phase 2).
- SC-002: In 100 Seeds unterscheiden sich Mittel und Schwer nur bei den veränderten Ereignissen
  und ihren Abhängigen (Phase 2).
- SC-006: Ein geänderter Wert ändert genau eine Zeile der Datei (Phase 3).
- SC-003: Über 1.000 Spiele liegt der Mittelwert bei Mittel zwischen 4,9 und 5,9 und bei Schwer
  zwischen 13,4 und 15,4 (Phase 5).

## 2. Startprobe ohne Fenster

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src --quit-after 60
```

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless -d --path src --quit-after 60
```

Erwartet: Exit-Code 0 und außer der Kopfzeile der Engine keine Ausgabe, auch keine Warnung. Das
Spiel startet mit Mittel. Das gilt auch, nachdem Klaus die Profile im echten Katalog angelegt hat.

## 3. Textausgabe mit Grad (ab Phase 2)

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --no-header --path src -s res://tools/werkstatt/fahrplan_ausgabe.gd -- --seed 4711 --grad schwer --katalog res://test/fixtures/catalog_us1_grade.json > /tmp/schwer_a.txt
```

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --no-header --path src -s res://tools/werkstatt/fahrplan_ausgabe.gd -- --seed 4711 --grad schwer --katalog res://test/fixtures/catalog_us1_grade.json > /tmp/schwer_b.txt
```

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --no-header --path src -s res://tools/werkstatt/fahrplan_ausgabe.gd -- --seed 4711 --grad mittel --katalog res://test/fixtures/catalog_us1_grade.json > /tmp/mittel.txt
```

```bash
diff /tmp/schwer_a.txt /tmp/schwer_b.txt
```

```bash
diff /tmp/mittel.txt /tmp/schwer_a.txt
```

| Prüfung | Erwartet | Bezug |
|---|---|---|
| `diff` der beiden Läufe mit Schwer | keine Ausgabe; erste Zeile „# Seed 4711, Grad Schwer, bis 31.12.1999“ | US1, Szenario 3; SC-001; FR-021 |
| `diff` Mittel gegen Schwer | anders sind höchstens die Kopfzeile und Zeilen der Reklamationswelle, ihrer Folge und des Ereignisses mit Bedingung darauf; mit Seed 4711 bleibt das Ereignis mit Bedingung gleich, weil die erste Reklamationswelle in beiden Graden am 22.07.1985 kommt; Lieferengpass und das fixe Ereignis gleich | US1, Szenario 4; FR-009 |
| Ohne `--grad` | wie `--grad mittel`, Zeichen für Zeichen | FR-006 |
| Mittel mit `--katalog res://test/fixtures/event_catalog_uebernahme.json`, ab der zweiten Zeile gegen `src/test/fixtures/fahrplan_uebernahme_seed_4711.txt` | `diff` ohne Ausgabe | feste Größe |
| `--grad schwer --protokoll` mit `catalog_us1_grade.json` | die erste Zeile ist „31.12.1984  Grad  Reklamationswelle: Start-Modifikator „…“ (Schwer) +5 Prozentpunkte vom 01.01.1985 bis 31.12.1999“ | FR-010; US3, Szenario 2 |
| `--grad schwer --katalog res://test/fixtures/catalog_us1_profil_kaputt.json`, danach `echo $?` | auf stderr beide weggelassenen Start-Modifikatoren mit Grad, Kennung und Fehlergrund: der auf das unbekannte Ereignis und der, dessen Ereignis selbst fehlerhaft ist; die Ausgabe läuft mit dem dritten; Exit-Code 1 | US1, Szenario 6; FR-013 |
| `--grad extrem`, danach `echo $?` | Meldung und Aufrufhilfe mit `--grad` auf stderr, Exit-Code 1 | FR-011 |

## 4. Werkstatt von Hand

Gestartet wird auf der Kopie aus den Voraussetzungen:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path src res://tools/werkstatt/werkstatt.tscn -- --katalog /tmp/katalog_probe.json
```

Geprüft wird im maximierten Fenster bei Klaus' Größe, derzeit 1920 × 925 logisch.

### 4.1 Reiter „Schwierigkeitsgrade“ (ab Phase 3)

Die Kopie `/tmp/katalog_probe.json` hat leere Profile; in Phase 3 entsteht sie vor T020 (siehe
Voraussetzungen). Sonst stimmen die Zahlen der Anzeige „Je Grad“ unten nicht. Die Zeilen bauen
aufeinander auf. Was eine Zeile zurücknehmen muss, damit die nächsten stimmen, steht in ihr. Cmd+Z
erreicht den Verlauf des Katalogs erst, wenn kein Feld den Fokus hat, etwa nach Enter.

| Prüfung | Erwartet | Bezug |
|---|---|---|
| Reiter | „Schwierigkeitsgrade“ steht rechts neben „Statistik“; Prüfung, Simulator und Statistik sind, wo sie waren | FR-015 |
| Grad „Mittel“ | Notiz „Mittel ist der Katalog ohne Start-Modifikatoren …“, keine Tabelle | FR-004, FR-015 |
| Reklamationswelle in der Liste wählen, Grad „Leicht“, „Neu“ | neue Zeile auf die Reklamationswelle, 01.01.1985 bis 31.12.1999, Fokus in „Wert“; die Prüfung zeigt V29, bis ein Grund dasteht | FR-002, R11 |
| Wert „-2“, Grund „Nachsichtige Kunden“, Cmd+S, Werkstatt schließen und wieder öffnen | der Start-Modifikator steht in „Leicht“, mit „-2“ | US2, Szenario 1 |
| Im Formular die Art der Reklamationswelle auf „fix, jährlich“ stellen, dann Cmd+Z | Fehler V26 an „Ereignis“ des Start-Modifikators und in der Prüfung, das Ereignis steht als „Reklamationswelle (fix, jährlich)“ in der Auswahl; nach Cmd+Z ist der Fehler weg | US2, Szenario 2 |
| Ende vor Beginn; Grund leeren | Fehler V27 bzw. V29, die Meldung nennt Grad und Start-Modifikator; in der Prüfung steht in der Spalte „Ereignis“ „Profil Leicht“ | US2, Szenario 3; FR-016 |
| Eine dieser Meldungen in der Prüfung anklicken; danach Enter und Cmd+Z, bis Ende und Grund wieder stimmen | Reiter „Schwierigkeitsgrade“, richtiger Grad, Zeile gewählt, Fokus im Feld; zum Schluss keine Fehler mehr | FR-016 |
| Beginn 15.03.1990 mit Enter, Cmd+S; danach Cmd+Z, bis der Beginn wieder 01.01.1985 ist | Warnung V31 am Feld „Beginn“: „… wirkt ab der Würfelrunde am 01.04.1990“; Speichern geht ohne Rückfrage zu Fehlern | FR-012 |
| „Duplizieren“, „Löschen“, Cmd+Z; danach noch einmal Cmd+Z | Kopie direkt dahinter mit `_2`; Löschen ohne Rückfrage; Cmd+Z holt ihn zurück; die Toolbar zeigt „ungespeichert“; zum Schluss ist die Kopie wieder weg | FR-015, FR-016 |
| Die Reklamationswelle in der Liste duplizieren; danach Cmd+Z | die Kopie hat in keinem Profil einen Start-Modifikator; die der Reklamationswelle bleiben | Edge Case „Ereignis dupliziert“ |
| Cmd+S, dann im Terminal: `/Applications/Godot.app/Contents/MacOS/Godot --headless --no-header --path src -s res://tools/werkstatt/fahrplan_ausgabe.gd -- --grad leicht --katalog /tmp/katalog_probe.json --protokoll` | oben steht „31.12.1984  Grad  Reklamationswelle: Start-Modifikator „Nachsichtige Kunden“ (Leicht) -2 Prozentpunkte …“ | US2, Independent Test |
| In „Schwer“ einen Start-Modifikator auf „Konkurrent eröffnet“ mit dem Grund „Probe“, dann das Ereignis in der Liste löschen | der Dialog nennt „In den Profilen verweisen darauf: Schwer: Probe …“, denn der Katalog hat keine Folgen und Bedingungen; nach dem Löschen ist auch der Start-Modifikator weg; Cmd+Z holt beides zurück | US2, Szenario 4; FR-017 |
| Die Kennung von „Konkurrent eröffnet“ ändern | der Start-Modifikator zeigt danach auf die neue Kennung, ohne Rückfrage | FR-017, R9 |
| Dazu in „Schwer“ „+5“ auf die Reklamationswelle, mit einem Grund; Formular der Reklamationswelle | „Je Grad“: Leicht 1 %, Mittel 3 %, Schwer 8 %, nur zum Lesen | US2, Szenario 6 |
| In „Schwer“ „+3“ auf „Konkurrent eröffnet“ vom 01.01.1995 bis 31.12.1999, mit einem Grund; Formular von „Konkurrent eröffnet“ | „Schwer 3 % bis 31.12.1994, 6 % ab 01.01.1995“; der Start-Modifikator „Probe“ mit 0 ändert nichts | US2, Szenario 7 |
| Speichern, im Terminal `cp /tmp/katalog_probe.json /tmp/katalog_vorher.json`; dann nur einen Wert eines Start-Modifikators ändern, Cmd+S, und `diff /tmp/katalog_vorher.json /tmp/katalog_probe.json` | genau eine Zeile alt und eine neu | US2, Szenario 5; SC-006 |
| Schließen mit ungespeicherter Änderung am Profil | Rückfrage „Speichern“, „Verwerfen“, „Abbrechen“ | FR-016 |
| Platz | Tabelle und Felder nebeneinander, die Felder ohne Rollen sichtbar, mindestens vier Zeilen der Tabelle zu sehen | R11 |
| Zum Schluss eine neue Kopie mit leeren Profilen wie in den Voraussetzungen, die Werkstatt darauf; mit der Uhr in einem Profil drei Start-Modifikatoren anlegen, je mit Wert und Grund | unter 5 Minuten, ohne eine Datei zu öffnen | SC-005 |

### 4.2 Simulator mit Grad (ab Phase 4)

Die Kopie `/tmp/katalog_probe.json` entsteht neu und hat die Profile des echten Katalogs (siehe
Voraussetzungen); 4.3 nutzt dieselbe.

| Prüfung | Erwartet | Bezug |
|---|---|---|
| Seed 4711, Grad Mittel, „Fahrplan erzeugen“, „Bis …“ 01.01.1990, dann Grad „Schwer“ | „Stand: 01.01.1990 · Seed 4711“, die Auswahl zeigt „Schwer“; Termine der Ereignisse, die das Profil verändert, können anders liegen, alle übrigen bleiben | US3, Szenario 1; FR-018 |
| Protokoll ansehen | oben die Zeilen „Grad“ mit Grund, unterscheidbar von „Eingriff“ | US3, Szenario 2; FR-010 |
| Liste der Modifikatoren | zuerst die Start-Modifikatoren, mit „Schwer: …“ vor dem Grund und ohne eigene Farbe; „Entfernen“ ist für sie gesperrt, mit Hinweis | FR-010 |
| Häkchen „mit Mittel vergleichen“, ohne Eingriffe, „Bis zum Ende“ | „Vergleich: Mittel ohne Eingriffe“; markiert sind nur Termine der veränderten Ereignisse | US3, Szenario 5 |
| Mit der Kopie `/tmp/grade_probe.json` (Werkstatt mit `-- --katalog /tmp/grade_probe.json`): Eingriff „Lieferengpass -4 Prozentpunkte ab 01.01.1990“ (Minus von der Tastatur), Häkchen aus | „Vergleich: Schwer ohne Eingriffe“; markiert ist nur, was der Eingriff ändert | US3, Szenario 6 |
| Grad Mittel, Häkchen an und aus | keine Markierung ändert sich | Edge Case „Vergleich bei Mittel“ |
| „Neu starten ohne Eingriffe“, dann Grad wechseln | der neue Lauf ist wieder ohne Eingriffe; „Neu starten mit Eingriffen“ hat sie noch | R13 |
| Probe „Schwer mit Engpass“ speichern, Grad auf Mittel stellen, Probe laden | Seed, Grad Schwer und Eingriffe wieder gesetzt; die Liste der Proben zeigt die Spalte „Grad“ | US3, Szenario 3; FR-019 |
| In der Datei der Probe unter `src/tools/werkstatt/proben/` die Zeile `"difficulty"` löschen, dann laden | gilt als Mittel | US3, Szenario 4 |
| Ein Profil ändern, während ein Lauf steht | „Katalog geändert, neu starten“ | FR-018; FR-042 von Feature 002 |
| In „Schwer“ den Grund eines Start-Modifikators leeren, Lauf mit Schwer neu starten | der Hinweis „Ausgenommen, weil fehlerhaft“ nennt „Profil „Schwer“, Start-Modifikator „…““; Cmd+Z holt den Grund zurück | FR-013 |
| Danach den Grad wechseln | der neue Lauf nimmt den geänderten Katalog, der Hinweis „Katalog geändert“ ist weg | FR-018 |
| Mit Schwer einen gewürfelten Termin absagen, dann auf Mittel wechseln | gibt es den Termin bei Mittel nicht, nennt der Hinweis die Absage als nicht anwendbar | FR-018 |

### 4.3 Statistik mit Graden (ab Phase 5)

| Prüfung | Erwartet | Bezug |
|---|---|---|
| Die Kopie aus 4.2 mit den Profilen des echten Katalogs, ohne Eingriffe, Grad „Alle drei vergleichen“, 1.000 Spiele, „Starten“ | Fortschritt „… von 1.000 Spielen je Grad“; vom Starten bis 100 % höchstens 90 Sekunden, die Statistik nennt die Zeit | US4, Szenario 1; SC-004 |
| Tabelle | je Ereignis Ø, Spanne und „ohne“ für Leicht, Mittel und Schwer nebeneinander; alle Spalten ohne Rollen sichtbar; der Bereich der Verteilung auf die Jahre bleibt stehen und zeigt statt der Verteilung einen Text | FR-020, R15 |
| Noch einmal starten | dieselben Werte | US4, Szenario 2 |
| Fixe und jährliche Ereignisse, etwa das Weihnachtsgeschäft | in allen drei Graden dieselben Werte | US4, Szenario 3 |
| Einmal abbrechen | alle drei Grade mit derselben Zahl fertiger Spiele | FR-020 |
| Mit `/tmp/grade_probe.json` und dem Eingriff aus 4.2: Vergleich mit dem Häkchen „Mit Modifikatoren und Einplanungen aus dem Simulator“ | der Lieferengpass hat in allen drei Graden dieselben Werte; „mit 1 Eingriff“ | US4, Szenario 4 |
| Grad „Schwer“ allein | Tabelle wie bisher, der Text nennt „Schwer“ | FR-020 |
| Während einer Rechnung ein Profil ändern | „Katalog geändert, neu starten“, die Rechnung bleibt beim alten Stand | FR-020 |
| Einen Start-Modifikator fehlerhaft machen, etwa ohne Grund, und rechnen | der Hinweis auf Ausgenommenes nennt ihn | FR-013 |

## 5. Aufräumen

- Proben, die nur der Prüfung dienten, löschen: „Probe löschen“ im Simulator oder die Datei
  unter `src/tools/werkstatt/proben/`.
- Die Kopien unter `/tmp/` dürfen bleiben.
- Hat Klaus doch auf dem echten Katalog geprüft und will die Änderungen nicht behalten:

  ```bash
  git restore src/data/event_catalog.json
  ```

## Abnahme je Phase

| Phase | Abschnitte |
|---|---|
| 1 Grundlage | 1, 2; danach schließt Klaus jede ältere Werkstatt, öffnet den echten Katalog in der neuen und speichert einmal, damit er den leeren Abschnitt hat (research.md, R3; CHK037) |
| 2 Spielstart mit Grad (US1) | 1, 2, 3 |
| 3 Profile in der Werkstatt (US2) | zuerst 4.1 auf einer Kopie, die entsteht, solange die Profile im echten Katalog noch leer sind; dann legt Klaus die Profile an (research.md, R18), der Test, dass beide nicht leer sind, kommt dazu (CHK008), und zum Schluss 1 und 2 |
| 4 Simulator (US3) | 1, 4.2 |
| 5 Statistik (US4) | 1, 4.3 |
| 6 Abschluss | alles, 4.1 auf einer Kopie mit geleerten Profilen (Voraussetzungen), dazu der Quickstart von Feature 002 |
