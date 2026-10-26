# Quickstart: Neues Spiel starten prüfen

So lässt sich nachweisen, dass das Feature fertig ist. Was gebaut wird, steht in den Verträgen
[spielstand.md](contracts/spielstand.md), [spielablauf.md](contracts/spielablauf.md) und
[titelbildschirm.md](contracts/titelbildschirm.md); hier steht nur, wie man es prüft. Alle Befehle
laufen vom Repo-Root aus.

Jede Phase nimmt Klaus mit den Abschnitten ab, die es bis dahin gibt; die Tabelle am Ende ordnet sie
zu. Die Quickstarts von Feature 001 bis 003 gelten weiter, mit zwei Ausnahmen: Das Hauptmenü hat
fünf Einträge, und im Hintergrund startet kein Spiel mehr von selbst.

## Voraussetzungen

- Godot 4.7.2 unter `/Applications/Godot.app/Contents/MacOS/Godot`, GUT 9.7.1 im Projekt.
- Nur ein Testlauf zur selben Zeit: Alle Sitzungen teilen sich `user://` (`ki_pruefung.md`,
  „Tests“).
- Die echten Spielstände liegen unter macOS hier:

  ```text
  ~/Library/Application Support/Godot/app_userdata/Der Computerladen/spielstaende/
  ```

  Für die Prüfungen „ohne Spielstände“ legt Klaus den Ordner beiseite und holt ihn danach zurück,
  statt ihn zu löschen:

  ```bash
  mv ~/Library/Application\ Support/Godot/app_userdata/Der\ Computerladen/spielstaende ~/Library/Application\ Support/Godot/app_userdata/Der\ Computerladen/spielstaende_beiseite
  ```

FR-012 (Spielstände überstehen Updates) ist in diesem Feature nur durch den Ort belegt: Der Ordner
liegt unter `user://`, außerhalb der App. Ein echter Test kommt mit dem ersten Export (Checkliste,
CHK026).

## 1. Automatische Tests

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://addons/gut/gut_cmdln.gd
```

Erwartet: alle Tests grün, bei zwei Läufen mit derselben Zahl von Prüfungen. Sobald die jeweilige
Phase fertig ist, sind damit belegt:
- SC-003 (Phase 2 und 3): Seeds 1, 4711, 99999 in allen drei Graden, am 14.03.1986 gespeichert und
  fortgesetzt, melden bis zum 31.12.1999 dasselbe wie ohne Pause, auch mit Eingriffen.
- SC-004 (Phase 2 und 3): beschädigt, zu neu, unbekannter Grad, Seed außerhalb, Speichern scheitert
  und jeder Abbruch beim Speichern: kein Absturz, kein verlorener Spielstand.
- SC-005 (Phase 3): Datum im Spielstand nach dem Verlassen am 01.01.1985, 15.02.1985, 14.03.1986
  und 31.12.1999.
- SC-002 (Phase 2, 3 und 5): 20 Spielstände mit je 500 Ereignissen in höchstens 1 s gelesen und
  gezeigt; ein Spielstand vom 31.12.1999 in höchstens 1 s fortgesetzt.
- SC-001 und SC-002 (Phase 4 und 5): die Zahl der Eingaben.
- FR-003 (Phase 3): Ohne begonnenes Spiel läuft keins, und es entsteht keine Datei.

## 2. Startprobe ohne Fenster

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src --quit-after 60
```

Erwartet: Exit-Code 0 und keine Ausgabe, auch mit `-d`. Danach gibt es im Ordner der Spielstände
keine neue Datei (FR-003).

## 3. Spiel von Hand (ab Phase 4)

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path src
```

### 3.1 Ohne Spielstände (Ordner beiseitegelegt)

1. Der Titelbildschirm sieht aus wie in Feature 001, das Menü hat fünf Einträge: Weiterspielen,
   Neues Spiel, Spiel laden, Einstellungen, Beenden. „Neues Spiel“ ist gewählt; „Weiterspielen“
   und „Spiel laden“ sind gedämpft, ihr Hinweis nennt den Grund (US3, Szenario 2; SC-006).
2. Enter: Die Gradwahl erscheint an der Stelle des Menüs, „Mittel“ gewählt, daneben sein Satz.
   Pfeil hoch und runter: Der Satz wechselt mit dem Grad (US1, Szenario 1).
3. Esc: zurück im Hauptmenü, „Neues Spiel“ gewählt; der Ordner ist noch leer (US1, Szenario 3).
4. Enter, Pfeil hoch auf „Leicht“, Enter: Der Spielbildschirm erscheint, dunkel, in der Mitte „Zum
   Hauptmenü“ mit dem Hinweis „Speichert Spiel 1 …“. Im Ordner liegt `spiel_1.json` mit
   `"difficulty": "leicht"` und `"day": "1985-01-01"` (US1, Szenario 2).
5. Esc tut nichts. Enter: Hauptmenü mit „Weiterspielen“ gewählt (US2, Szenario 1).
6. Zählen: vom Hauptmenü bis zum Spielbildschirm eines neuen Spiels mit Mittel höchstens 3 Tasten
   (SC-001).

### 3.2 Mehrere Spielstände (ab Phase 5)

1. Zwei weitere Spiele beginnen, eins mit Schwer, eins mit Mittel, jedes über den Knopf verlassen.
2. „Spiel laden“: Drei Zeilen mit Name, Grad, Spieldatum und „zuletzt gespielt“, das jüngste oben;
   der Hinweis nennt „zuletzt gespielt“ ausgeschrieben (US3, Szenario 5).
3. Das älteste wählen: Es erscheint; zurück im Hauptmenü setzt „Weiterspielen“ es fort, und in der
   Liste steht es oben (US3, Szenario 3).
4. App mit Cmd+Q beenden, neu starten, Enter: Der Spielbildschirm mit dem zuletzt gespielten Spiel,
   der Hinweis nennt es (US3, Szenario 1; US2, Szenario 2; SC-002).
5. Mit der Maus: „Spiel laden“, eine Zeile: 2 Klicks bis zum Spielbildschirm (SC-002).

### 3.3 Löschen (ab Phase 5)

1. In der Liste „Löschen …“: Die Kopfzeile lautet WELCHES LÖSCHEN?, jeder Hinweis sagt, dass die
   Zeile gelöscht wird.
2. Esc: Der Modus endet, Enter auf einer Zeile setzt wieder fort (US4, Szenario 2).
3. „Löschen …“, „Spiel 1“: Die Rückfrage LÖSCHEN? mit „Abbrechen“ gewählt, der Hinweis nennt Name,
   Grad und Spieldatum (US4, Szenario 1). Esc: Spiel 1 ist noch da (US4, Szenario 4).
4. Noch einmal, „Spiel 1 löschen“: Es fehlt in der Liste und im Ordner; die anderen sind unverändert
   (US4, Szenario 3; FR-018).
5. Alle übrigen löschen: Nach dem letzten erscheint das Hauptmenü mit „Neues Spiel“ gewählt
   (US4, Szenario 5).

### 3.4 Nicht fortsetzbare Spielstände (ab Phase 5)

Eine Datei `notizen.txt` und zwei Fixtures in den Ordner legen, als `spiel_8.json` und
`spiel_9.json`:

```bash
cp src/test/fixtures/spielstaende/spiel_kein_json.json ~/Library/Application\ Support/Godot/app_userdata/Der\ Computerladen/spielstaende/spiel_8.json
```

```bash
cp src/test/fixtures/spielstaende/spiel_format_2.json ~/Library/Application\ Support/Godot/app_userdata/Der\ Computerladen/spielstaende/spiel_9.json
```

1. Die Liste zeigt „Spiel 9 … neuere Version“ und „Spiel 8 … beschädigt“ gedämpft unten; `notizen.txt`
   erscheint nicht. Enter auf ihnen tut nichts, ihr Hinweis nennt den Grund (Edge Cases).
2. Beide lassen sich über „Löschen …“ löschen; `notizen.txt` bleibt liegen.
3. Ein neues Spiel heißt danach „Spiel 10“, solange 8 oder 9 noch da sind (FR-009).

### 3.5 Eigener Katalog im Spielstand (ab Phase 5)

`spiel_N.json` eines neuen Spiels im Texteditor öffnen: Unter `"catalog"` steht der Katalog samt
`"profiles"` (FR-022). Dass ein Spiel nach einer Änderung am Katalog mit seiner Kopie weiterläuft,
belegt `test_save_resume_run.gd`; den echten Katalog ändert Klaus dafür nicht.

## 4. Aufräumen

Den beiseitegelegten Ordner zurückholen; vorher den Prüfordner wegräumen, wenn Klaus ihn nicht
behalten will:

```bash
mv ~/Library/Application\ Support/Godot/app_userdata/Der\ Computerladen/spielstaende ~/Library/Application\ Support/Godot/app_userdata/Der\ Computerladen/spielstaende_pruefung
```

```bash
mv ~/Library/Application\ Support/Godot/app_userdata/Der\ Computerladen/spielstaende_beiseite ~/Library/Application\ Support/Godot/app_userdata/Der\ Computerladen/spielstaende
```

## Abnahme je Phase

| Phase | Abschnitte |
|---|---|
| 1 Style-Guide | Abschnitte aus R17 im Style-Guide, von Klaus freigegeben; Sätze zu den Graden entschieden |
| 2 Kern Spielstand | 1 |
| 3 Spielablauf | 1, 2 |
| 4 Neues Spiel und Spielbildschirm | 1, 2, 3.1 |
| 5 Liste und Löschen | 1, 2, 3.2 bis 3.5 |
| 6 Abschluss | alles, nach der Lückensuche |
