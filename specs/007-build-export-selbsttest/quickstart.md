# Quickstart: Build & Export mit Selbsttest prüfen

So lässt sich nachweisen, dass das Feature fertig ist. Was gebaut wird, steht in den Verträgen unter
[contracts/](contracts/); hier steht nur, wie man es baut, startet und prüft. Alle Befehle laufen vom
Repo-Root aus. Die Namen der Presets und Pfade stehen in [contracts/export.md](contracts/export.md).

## Voraussetzungen

- Godot 4.7.2 unter `/Applications/Godot.app/Contents/MacOS/Godot` mit den Export-Templates 4.7.2.
- Python 3 für den Vergleich.
- Für Teil 2 ein Windows-Rechner (x86_64) und ein Linux-Rechner (x86_64), beide mit einer
  Grafikkarte, die Direct3D 12 oder Vulkan kann. Eine virtuelle Maschine ohne Vulkan zeigt nur Godots
  Fehlermeldung (Spec, FR-017).

## Automatisch

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://addons/gut/gut_cmdln.gd
```

Erwartet: alle Tests grün, zweimal mit derselben Zahl; darunter die neuen Tests zum Selbsttest
(Protokoll, Ziele, Systemdaten, Einstellungen des Projekts).

Startprobe, erwartet: Exit 0 und außer der Versionszeile keine Ausgabe:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -d --quit-after 60
```

## Selbsttest auf dem Mac (Teil 1)

Bauen:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src --export-release "Selbsttest macOS" "../build/macos/Der Computerladen Selbsttest.app"
```

Starten, per Doppelklick im Finder oder:

```bash
open "build/macos/Der Computerladen Selbsttest.app"
```

1. Ein Fenster geht auf, der Titel erscheint, und die App spielt alle Abläufe im Zeitraffer durch,
   zum Schluss den Titel noch einmal in normalem Tempo. Der Fenstertitel
   zählt mit, etwa „Selbsttest · Schritt 12 von 37: Neues Spiel“. Maus und Tastatur muss man nicht
   anfassen; tut man es doch, ändert das nichts. Ein Lauf dauert auf dem Mac rund 7 s.
2. Am Ende steht die Zusammenfassung im Look der Werkzeuge, im selben Fenster wie der Lauf: Summe,
   fehlerhafte Schritte, Pfad, dazu
   „Kopieren“, „Ordner zeigen“ und „Beenden“. Erwartet: alle Schritte in Ordnung (SC-003); im
   Protokoll braucht `titel` weniger Zeit als `titel_echtzeit` (SC-001).
3. „Ordner zeigen“ zeigt das Zip des Laufs im Finder, markiert; daneben der Ordner des Laufs mit
   `protokoll.txt`, `ausgabe.txt`, `fotos/` (SC-007).
4. „Kopieren“ und in einen Texteditor einfügen: Kopf, Systemdaten, Summe, keine Schritte mit `OK`.
5. Ein zweiter Lauf: neuer Ordner, alter bleibt. Vergleich der beiden Läufe:

   ```bash
   python3 -I tools/selbsttest/vergleich.py "<Ordner des zweiten Laufs>" --gegen "<Ordner des ersten Laufs>"
   ```

   Erwartet: alles `gleich` oder `nicht vergleichbar` (SC-002, SC-008).
   Gegen die Referenzbilder vom Mac, ohne `--gegen`, dasselbe.
6. Echte Spielstände: vorher und nachher `ls -l` auf den Ordner des Spiels; unverändert (SC-006).
7. Während eines Laufs in ein anderes Fenster klicken: Das Protokoll vermerkt den Fokusverlust beim
   Schritt.
8. Während eines Laufs das Fenster schließen: Die App endet, das Protokoll vermerkt den Abbruch.

## Spiel ohne Testcode

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src --export-release "macOS" "../build/macos/Der Computerladen.app"
```

Erwartet: Die App startet zum Titel wie bisher, nichts läuft von selbst. Die Prüfung, dass keine
Datei des Selbsttests im Paket steckt, steht in [contracts/export.md](contracts/export.md) (SC-005).

## Windows und Linux (Teil 2)

Bauen auf dem Mac, alles mit einem Befehl:

```bash
tools/build/baue_alles.sh
```

Erwartet: je Preset „gebaut“, je System „geprüft“ und „gepackt“, Exit 0. Unter `build/abnahme/`
liegt je System ein Zip mit Spiel und Selbsttest: `0.1_windows.zip`, `0.1_linux.zip`, `0.1_macos.zip`.
Mit `--nur macos` baut das Skript nur ein System. Dann auf dem anderen Rechner:

1. Das Zip des Systems kopieren und entpacken, `Der Computerladen Selbsttest` per Doppelklick
   starten.
   - **Windows:** SmartScreen warnt beim ersten Start einer unbekannten App: „Weitere Informationen“,
     dann „Trotzdem ausführen“.
   - **Linux:** Das Zip behält das Ausführrecht. Fehlt es doch, etwa nach dem Entpacken mit einem
     anderen Programm: `chmod +x "Der Computerladen Selbsttest.x86_64"`.
   - **macOS:** Beim ersten Start einer unbekannten App fragt macOS nach; im Finder mit Rechtsklick
     „Öffnen“ wählen, oder unter Systemeinstellungen → Datenschutz & Sicherheit „Trotzdem öffnen“.
2. Am Ende „Kopieren“ und den Text in den Chat einfügen; das Zip über „Ordner zeigen“ holen und auf
   dem Mac nach `build/selbsttest/` legen.
3. Claude vergleicht und legt die Belege ab:

   ```bash
   python3 -I tools/selbsttest/vergleich.py build/selbsttest/<lauf>_windows.zip --beleg
   ```

4. Von Hand, kurzer Blick: Symbol der .exe im Explorer, im Fenster und in der Taskleiste; im Spiel
   (nicht im Selbsttest) Vollbild mit F11 und mit Alt+Enter hin und zurück; danach steht das Fenster
   wieder in seiner Größe. Alt+Enter löst dabei im Menü nichts aus.
5. Fehlt Vulkan oder Direct3D 12, erscheint Godots eigene Meldung „Unable to initialize video
   driver“, und die App beendet sich (FR-017). Auf OpenGL weicht das Spiel bewusst nicht aus (R13).
   Startet Direct3D 12 nur halb, etwa auf Stufe 11_0 mit alten Treibern, kommt keine Meldung: Das
   Fenster schließt sich still oder hängt. So war es auf einem MacBook Pro 2015 mit Boot Camp und AMD
   Radeon R9 M370X. Klären lässt es sich mit einem Start aus der PowerShell:

   ```powershell
   & ".\Der Computerladen Selbsttest.exe" --rendering-driver vulkan
   ```

   Für eine Probe ohne Forward+ lässt sich OpenGL einmalig erzwingen; das prüft alles außer der
   Darstellung mit Forward+ und gilt nicht als Abnahme des Renderers:

   ```powershell
   & ".\Der Computerladen Selbsttest.exe" --rendering-method gl_compatibility --rendering-driver opengl3
   ```

Auf dem Mac von Hand: im Spiel Vollbild mit Ctrl+Cmd+F hin und zurück, ebenso mit Option+Enter. F11
fängt macOS meist selbst ab.

## Aufräumen

- `build/` ist nicht versioniert und kann jederzeit weg.
- Die Läufe liegen im Datenordner der Selbsttest-App; sie stören nichts und lassen sich löschen.
