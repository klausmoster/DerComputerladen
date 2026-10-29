# Quickstart: Renderer Compatibility prüfen

So lässt sich nachweisen, dass das Feature fertig ist. Was eingestellt wird, steht in
[contracts/renderer.md](contracts/renderer.md). Wie Bauen, Starten und Vergleichen des Selbsttests
im Einzelnen gehen, steht im Quickstart von Feature 007
([`specs/007-build-export-selbsttest/quickstart.md`](../007-build-export-selbsttest/quickstart.md));
hier steht nur, was für den Renderer dazukommt. Alle Befehle laufen vom Repo-Root aus.

## Voraussetzungen

- Godot 4.7.2 unter `/Applications/Godot.app/Contents/MacOS/Godot` mit allen Export-Vorlagen 4.7.2.
- In einem neuen Arbeitsordner einmal importieren, sonst fehlen Schriften und Bilder:

  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path src --import
  ```

- Für die Läufe: der Linux-Rechner (AMD R7 200) und der Boot-Camp-Rechner aus Feature 007.
- Öffnet Klaus das Projekt im Godot-Editor, läuft danach auch der Editor mit Compatibility. Das ist
  gewollt; der Editor startet dazu einmal neu.

## Automatisch

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://addons/gut/gut_cmdln.gd
```

Erwartet: alle Tests grün, zweimal mit derselben Zahl (SC-006); darunter die neuen Tests zum Renderer
in `test_projekt_einstellungen.gd`.

## Probestart auf dem Mac

Das Spiel mit Fenster, ohne Startoption. Es schließt sich nach 60 Bildern selbst:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path src --quit-after 60
```

Erwartet in der zweiten Zeile: „OpenGL API 4.1 Metal … - Compatibility - Using Device: Apple …“.
Steht dort „Forward+“ oder „Metal 3“ ohne „Compatibility“, greift die Einstellung nicht.

ANGLE über Metal zum Vergleich, nur einmalig per Startoption (R2):

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path src --rendering-driver opengl3_angle --quit-after 60
```

Erwartet: „OpenGL ES 3.0 (ANGLE …) - Compatibility - … ANGLE Metal Renderer …“.

## Selbsttest auf dem Mac

```bash
tools/build/baue_alles.sh
```

Dann `build/macos/Der Computerladen Selbsttest.app` per Doppelklick starten und vergleichen, wie im
Quickstart von 007 beschrieben:

```bash
python3 -I tools/selbsttest/vergleich.py "<Ordner des Laufs>" --beleg
```

Erwartet:
- alle Schritte in Ordnung;
- im Protokoll `system.renderer: gl_compatibility` und `system.grafik_api: OpenGL` (SC-004);
- alle Fotos `gleich` gegenüber `tools/selbsttest/referenz/macos/` (SC-002). Weicht eins ab, legt
  Claude es Klaus mit Bild vor; ersetzt wird nichts ohne seine Abnahme (FR-008).

Danach das echte Fenster (SC-007), mit Bildschirmfotos durch Claude:
- Beim Start des Spiels: Vor dem Titel ist nur der dunkle Startgrund zu sehen, kein Logo von Godot.
- Das Fenster auf eine krumme Größe ziehen, etwa 1500 × 900: Das Bild bleibt ganzzahlig vergrößert,
  die Pixel bleiben hart, der Rest ist schwarz.
- Die Werkstatt im echten Fenster bei 1920 × 925:

  ```bash
  /Applications/Godot.app/Contents/MacOS/Godot --path src res://tools/werkstatt/werkstatt.tscn
  ```

  Erwartet: Sie startet maximiert, die Schrift ist geglättet und so scharf wie vor dem Wechsel.
- Die Dauer des Laufs steht im Protokoll; mehr als doppelt so lang wie im Beleg aus 007 geht an
  Klaus.

## Prüfliste fürs echte Fenster (Windows und Linux, Klaus)

1. Beim Start: nur der dunkle Startgrund, kein Logo von Godot.
2. Fenster auf eine krumme Größe ziehen: Bild ganzzahlig vergrößert, Pixel hart, Rest schwarz.
3. Titel, Hauptmenü und Communicator sehen aus wie auf dem Mac.

## Windows auf dem Boot-Camp-Rechner

1. `build/abnahme/0.1_windows.zip` kopieren und entpacken.
2. **Das Spiel** `Der Computerladen.exe` per Doppelklick starten: Der Titel erscheint, ohne
   Startoption und ohne zusätzliche Datei (SC-001). Ins Hauptmenü und zurück, dann beenden.
3. **Der Selbsttest** `Der Computerladen Selbsttest.exe` per Doppelklick: alle Schritte in Ordnung;
   im Protokoll `gl_compatibility` und OpenGL oder ANGLE. Das Zip zurück auf den Mac nach
   `build/selbsttest/`, dann:

   ```bash
   python3 -I tools/selbsttest/vergleich.py build/selbsttest/<lauf-id>_windows.zip --beleg
   ```

4. **ANGLE über Direct3D 11** einmal erzwingen, aus der PowerShell im entpackten Ordner (FR-006):

   ```powershell
   & ".\Der Computerladen Selbsttest.exe" --rendering-driver opengl3_angle
   ```

   Erwartet: Der Lauf geht durch, im Protokoll steht `system.grafik_api: ANGLE`. Kommt stattdessen
   OpenGL, hat Godot ANGLE nicht gefunden und ist zurückgefallen; dann entscheidet Klaus über
   `export_angle = 1` (contracts/renderer.md).

5. Die Prüfliste fürs echte Fenster oben.

**Kann:** Dasselbe unter Windows in Parallels (Klärung vom 2026-10-29). Ein Lauf dort ist willkommen,
keine Bedingung.

## Linux

`build/abnahme/0.1_linux.zip` auf den Linux-Rechner, Selbsttest per Doppelklick starten, Zip zurück
und vergleichen wie unter Windows. Erwartet: alle Schritte in Ordnung, `gl_compatibility` und OpenGL,
alle Fotos gleich (SC-003, SC-004). Dazu die Prüfliste fürs echte Fenster.

## Regeln und Doku

Erwartet: Jede Fundstelle von „Forward+“ ist Geschichte mit Datum oder steht in einer älteren Spec
(SC-005):

```bash
grep -rn "Forward+" CLAUDE.md .specify/memory/constitution.md docs/spielbeschreibung docs/ki_workflow
```

Dazu von Hand: Der Style-Guide hat den Satz zu HDR, Kantenglättung und Glühen (FR-009a); in Feature
007 tragen FR-017 und R13 den Vermerk „bis 2026-10-29“ (FR-010).

## Wenn ein Rechner gar nicht startet

Fehlen OpenGL 3.3 und unter Windows auch Direct3D 11, beendet sich Godot; ob mit eigener Meldung,
klärt research.md, R8. Das Spiel schreibt dann nichts. Eine eigene Meldung des Spiels gehört nicht zu diesem Feature.

## Aufräumen

- `build/` ist nicht versioniert und kann jederzeit weg.
