# Build und Tests

- **Worum es geht:** wie das Spiel gestartet, exportiert und getestet wird.
- **Laden, wenn:** exportiert wird, Tests geschrieben oder laufen gelassen werden, oder neue
  Dateien zum Export oder Repo dazukommen.
- **Code:** `src/export_presets.cfg`, `src/.gutconfig.json`, `src/test/`, `src/addons/gut/`,
  `tools/ton/make_sounds.py`
- **Herkunft:** `specs/001-hauptmenue/` (Export, GUT), `specs/002-zeitleisten-werkstatt/`
  (Fixtures, Grundlinien), `specs/006-easter-egg-space-invaders/` (Töne, Probeszene), Regeln in
  `docs/ki_workflow/ki_dev.md`, „Tests“
- **Stand:** Feature 006, 2026-10-28

## Starten

Godot 4.7.2 liegt unter `/Applications/Godot.app/Contents/MacOS/Godot`. Projekt-Root ist `src/`,
also immer `--path src`, vom Repo-Root aus:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path src
```

Die Werkstatt startet mit `res://tools/werkstatt/werkstatt.tscn` dahinter (siehe
[werkstatt.md](werkstatt.md)). **Startprobe:** headless mit `-d` muss mit Exit 0 und ohne
Ausgabe enden; ein fehlerfreier Katalog erzeugt keine Ausgabe.

Probeszenen starten ebenso mit ihrem Pfad dahinter, etwa das versteckte Spiel allein:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path src res://test/fixtures/invaders_probe.tscn
```

**Töne** erzeugt `tools/ton/make_sounds.py` neu, vom Repo-Root mit `python3 -I`; ein Lauf schreibt
dieselben Bytes, `git status` zeigt danach keine Änderung. Mit `--pruefsummen` schreibt es auch die
Prüfsummen neu (siehe [ton.md](ton.md)).

## Export

Bisher gibt es nur das Preset „macOS“:

| Option | Wert |
|---|---|
| Ziel | `build/macos/Der Computerladen.app` (nicht versioniert) |
| Architektur | universal |
| Signierung | ad hoc, ohne Beglaubigung |
| Bundle-ID | `de.klausmoster.dercomputerladen` |
| Version | aus `application/config/version` in `project.godot` |
| Symbole | `app_icon.png` und Liquid-Glass `app_icon.icon` |
| Ausgeschlossen | `addons/gut/*`, `test/*`, `tools/*`: GUT, Tests und die Werkstatt |

`export_presets.cfg` vor jedem Commit ansehen: Je nach Godot-Version landen dort Zugangsdaten.
Windows und Linux, Developer-ID und Beglaubigung kommen mit Feature-Idee 11-03.

## Versionierung

- `.godot/` bleibt draußen, ebenso `build/`.
- `*.uid` und `*.import` werden committet: `.uid` hält die stabile ID einer Resource, `.import`
  die Import-Einstellungen. Fehlen sie, brechen Szenen-Referenzen nach einem Clone. Bei den Tönen
  hält die `.import` den Import als PCM ohne Trimmen, Normalisieren und Schleife.

## Tests

GUT 9.7.1, alle Tests unter `src/test/`, Dateien `test_*.gd`. Headless:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://addons/gut/gut_cmdln.gd
```

Regeln:
- **Deterministisch:** feste Seeds, etwa 1, 4711 und 99999.
- **Nie in echte Daten:** Tests lesen eigene Kataloge aus `src/test/fixtures/` und schreiben nur
  in eigene Ordner unter `user://`. Dafür lassen sich Pfade umstellen, etwa
  `Timeline.catalog_path`, `CatalogEditor.backup_folder`, `Werkstatt.settings_path`,
  `GameSession.folder`; die Uhr der Zeitleiste über `Timeline.clock`. `GameSession` nimmt dazu
  eigene Uhr, Zeitleiste, Uhrzeit (`now`), Würfel (`rng`) und `quit_callback`. Titel- und
  Spielbildschirm nehmen eine eigene `session` und prüfen Szenenwechsel über `scene_callback`.
  Kein Test schreibt in `user://spielstaende/`.
- **Ausgaben als Ganzes vergleichen:** Bytevergleich gegen gespeicherte Erwartungen.
- **Zahlen aus der Spec messen:** Tests prüfen ein ganzes Spiel unter 1 s, mit 500 Ereignissen
  ein Spiel unter 2 s, Prüfung samt Änderung unter 100 ms und 20 Spielstände mit 500 Ereignissen
  in höchstens 1 s gelesen. Die Statistik über 1.000 Spiele
  (Ziel unter 30 s) prüft kein Test.

**Fixtures:** je Prüfregel ein Katalog (`catalog_v01_…` bis `catalog_v31_…`), je User Story
Kataloge (`catalog_us…`), `catalog_500.json` für die Größe, `event_catalog_uebernahme.json`
als eingefrorene Kopie der Übernahme mit Fahrplänen und Protokollen für die Seeds 1, 4711 und
99999. Diese Grundlinien belegen, dass Mittel seit Feature 003 Zeichen für Zeichen gleich
geblieben ist. Unter `fixtures/spielstaende/` liegt je Fehlerfall ein kleiner Spielstand, etwa
`spiel_kein_json.json`, `spiel_format_2.json`, `spiel_grad_extrem.json`, dazu
`spiel_gueltig.json`; Tests kopieren sie unter einem Namen `spiel_<N>.json` in ihren Ordner.
`communicator_probe.tscn` ist eine Probeszene mit einem Communicator und einem Menü außerhalb des
Titels; sie zeigt, dass der Baustein ohne Titel läuft. Seit Feature 006 hat ihr Gehäuse die drei
Gehäusetasten, und ein gezählter Druck zeigt eine Meldung mit der Nummer der Taste.
`invaders_probe.tscn` zeigt das versteckte Spiel auf einem Communicator ohne Titel, ohne
Gehäusetasten und ohne `GameSession`; nach jedem Ende beginnt eine neue Partie.
`ton_pruefsummen.txt` hält je Ton eine MD5-Prüfsumme, geschrieben von
`make_sounds.py --pruefsummen`.

**Tests aus Feature 006:**
- `test_ton.gd`: die zehn Töne, Format, Import, erste und letzte Probe, Längen, Prüfsummen, Kanäle
  (siehe [ton.md](ton.md)). Liest die Rohdateien und schreibt nichts.
- `test_invaders_game.gd`: der Kern Schritt für Schritt mit festem Seed, auch die Grenzen aus SC-002
  (gezielt gewonnen in höchstens 10 800 Schritten, ohne Schuss gelandet frühestens nach 3 600).
- `test_invaders_sprites.gd`: Muster, Größen, nur `#` und `.`.
- `test_invaders_page.gd`: die Seite mit `autoplay = false`, `advance()` und erfundenen Tasten.
- `test_key_sequence.gd`: die Folge, dazu 20 zufällige falsche Folgen mit festem Seed.
- erweitert: `test_communicator.gd` (Gehäusetasten mit erfundenen Mausereignissen),
  `test_title_screen.gd` (Easter Egg, Zeiten aus SC-001 und SC-006, kein Spielstand),
  `test_title_texts.gd` (Zeilen der Ergebnisanzeige passen auf die Anzeige).

Headless laufen Töne über Godots Dummy-Treiber; Tests prüfen, welcher Player auf welchem Kanal
anläuft, nicht, was zu hören ist.

**Tests am echten Bestand:**
- `test_shipped_catalog.gd`: Der echte Katalog hat keinen Fehler, die Kalender-Ereignisse sind
  da, Leicht und Schwer haben je mindestens einen Start-Modifikator. Einzelne Werte prüft er
  bewusst nicht, denn Klaus ändert sie in der Werkstatt.
- `test_bilder.gd`: Jedes Bild in `res://assets/images/` nutzt nur Farben der Hauptpalette, ohne
  Halbtransparenz; `lcd` steht nicht darin.
- `test_texte.gd`: Texte in Szenen und Skripten unter `scenes/`, `tools/werkstatt/` und `core/`
  duzen. Seit Feature 006 findet er die Anrede auch in Versalien („SIE“, „IHNEN“).
- `test_ton.gd`: Die Töne im Projekt sind bytegleich mit dem, was `make_sounds.py` erzeugt.

Was Tests nicht sehen, prüft Klaus von Hand nach dem `quickstart.md` des Features: Look,
Fensterverhalten, Zeitstrahl, Formulare, Klang der Töne.
