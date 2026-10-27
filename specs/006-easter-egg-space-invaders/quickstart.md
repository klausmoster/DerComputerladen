# Quickstart: Easter Egg 01 prüfen

So lässt sich nachweisen, dass das Feature fertig ist. Was gebaut wird, steht in den Verträgen unter
[contracts/](contracts/); hier steht nur, wie man es prüft. Alle Befehle laufen vom Repo-Root aus.
Der Quickstart von Feature 005 gilt weiter für den Titel ohne Easter Egg.

## Voraussetzungen

- Godot 4.7.2 unter `/Applications/Godot.app/Contents/MacOS/Godot`, GUT 9.7.1 im Projekt.
- Python 3 für die Töne. Nur ein Testlauf zur selben Zeit: Alle Sitzungen teilen sich `user://`.
- Ton am Rechner an, für die Prüfung von Hand.

## Automatisch

```bash
python3 -I tools/ton/make_sounds.py
```

Erwartet: zehn Dateien unter `src/assets/sounds/`; danach zeigt `git status` keine Änderung an ihnen
(bytegleich).

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://addons/gut/gut_cmdln.gd
```

Erwartet: alle Tests grün, zweimal mit derselben Zahl. Darunter `test_ton.gd`,
`test_invaders_game.gd`, `test_invaders_sprites.gd`, `test_invaders_page.gd`, `test_key_sequence.gd`
und die erweiterten `test_communicator.gd` und `test_title_screen.gd`.

Startprobe, erwartet: Exit 0 und keine Ausgabe:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless -d --path src --quit-after 60
```

## Töne anhören (Phase 2)

```bash
for f in src/assets/sounds/*.wav; do echo "$f"; afplay "$f"; done
```

Erwartet: kurze Piepser wie ein Taschengerät, kein Knacken am Ende, nichts lauter als nötig.

## Das Spiel allein (Phase 4)

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path src res://test/fixtures/invaders_probe.tscn
```

1. Das Spiel läuft auf der Anzeige: dunkle Pixel auf `lcd`, auf dem Bildraster, nichts verwischt.
2. Pfeile fahren, Leertaste schießt; Schuss, Treffer, Marschtakt und Kanone klingen.
3. Der Block wird schneller, je weniger übrig sind. Gezielt gewinnt man in höchstens 3 Minuten;
   ohne zu schießen landet der Block frühestens nach 1 Minute (SC-002).
4. In ein anderes Fenster klicken: Spiel und Ton halten an; zurück: es geht weiter.
5. Am Ende die Ergebnisanzeige; eine gehaltene Leertaste überspringt sie nicht; danach eine Taste.
6. Esc beendet sofort; kein Ton klingt nach.
7. Im Spiel wirken Vollbild und Fenster-Schließen wie immer.
8. Texte: „ALLE ERWISCHT.“, „KANONE KAPUTT.“, „DIE SIND GELANDET.“, darunter die Punkte und
   „Weiter mit Taste oder Klick.“

## Im Titel (Phase 5)

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path src
```

1. Über den drei grauen Knöpfen rechts unter der Anzeige bleibt der Pfeil; nichts verrät sie.
2. Jeder Knopf drückt sich beim Drücken ein und klickt, auch in falscher Reihenfolge.
3. 1-2-3 startet das Spiel, auf jeder Seite (Hauptmenü, Gradwahl, Spielstände, Rückfrage). 2-1-3
   startet nicht. 1-1-2-3 startet.
4. Im Spiel lösen Pfeile, Leertaste und Enter im Menü dahinter nichts aus.
5. Nach Sieg, Niederlage und Esc steht dieselbe Seite da, mit derselben Auswahl und ihrem Hinweis.
6. Danach ein Spiel beginnen: Alles läuft wie vor dem Easter Egg; kein Spielstand ist neu.
7. Bildschirmfotos aus dem echten Fenster in 1920 × 925: Knopf eingedrückt, Spiel läuft, Ergebnisanzeige.
