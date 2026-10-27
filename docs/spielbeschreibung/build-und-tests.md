# Build und Tests

- **Worum es geht:** wie das Spiel gestartet, exportiert und getestet wird.
- **Laden, wenn:** exportiert wird, Tests geschrieben oder laufen gelassen werden, oder neue
  Dateien zum Export oder Repo dazukommen.
- **Code:** `src/export_presets.cfg`, `src/.gutconfig.json`, `src/test/`, `src/addons/gut/`
- **Herkunft:** `specs/001-hauptmenue/` (Export, GUT), `specs/002-zeitleisten-werkstatt/`
  (Fixtures, Grundlinien), Regeln in `docs/ki_workflow/ki_dev.md`, „Tests“
- **Stand:** Feature 003, 2026-10-27

## Starten

Godot 4.7.2 liegt unter `/Applications/Godot.app/Contents/MacOS/Godot`. Projekt-Root ist `src/`,
also immer `--path src`, vom Repo-Root aus:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path src
```

Die Werkstatt startet mit `res://tools/werkstatt/werkstatt.tscn` dahinter (siehe
[werkstatt.md](werkstatt.md)). **Startprobe:** headless mit `-d` muss mit Exit 0 und ohne
Ausgabe enden; ein fehlerfreier Katalog erzeugt keine Ausgabe.

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
  die Import-Einstellungen. Fehlen sie, brechen Szenen-Referenzen nach einem Clone.

## Tests

GUT 9.7.1, alle Tests unter `src/test/`, Dateien `test_*.gd`. Headless:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src -s res://addons/gut/gut_cmdln.gd
```

Regeln:
- **Deterministisch:** feste Seeds, etwa 1, 4711 und 99999.
- **Nie in echte Daten:** Tests lesen eigene Kataloge aus `src/test/fixtures/` und schreiben nur
  in eigene Ordner unter `user://`. Dafür lassen sich Pfade umstellen, etwa
  `Timeline.catalog_path`, `CatalogEditor.backup_folder`, `Werkstatt.settings_path`; die Uhr der
  Zeitleiste über `Timeline.clock`.
- **Ausgaben als Ganzes vergleichen:** Bytevergleich gegen gespeicherte Erwartungen.
- **Zahlen aus der Spec messen:** Tests prüfen ein ganzes Spiel unter 1 s, mit 500 Ereignissen
  ein Spiel unter 2 s und Prüfung samt Änderung unter 100 ms. Die Statistik über 1.000 Spiele
  (Ziel unter 30 s) prüft kein Test.

**Fixtures:** je Prüfregel ein Katalog (`catalog_v01_…` bis `catalog_v31_…`), je User Story
Kataloge (`catalog_us…`), `catalog_500.json` für die Größe, `event_catalog_uebernahme.json`
als eingefrorene Kopie der Übernahme mit Fahrplänen und Protokollen für die Seeds 1, 4711 und
99999. Diese Grundlinien belegen, dass Mittel seit Feature 003 Zeichen für Zeichen gleich
geblieben ist.

**Tests am echten Bestand:**
- `test_shipped_catalog.gd`: Der echte Katalog hat keinen Fehler, die Kalender-Ereignisse sind
  da, Leicht und Schwer haben je mindestens einen Start-Modifikator. Einzelne Werte prüft er
  bewusst nicht, denn Klaus ändert sie in der Werkstatt.
- `test_bilder.gd`: Jedes Bild in `res://assets/images/` nutzt nur Farben der Hauptpalette, ohne
  Halbtransparenz.
- `test_texte.gd`: Texte in Szenen und Skripten unter `scenes/`, `tools/werkstatt/` und `core/`
  duzen.

Was Tests nicht sehen, prüft Klaus von Hand nach dem `quickstart.md` des Features: Look,
Fensterverhalten, Zeitstrahl, Formulare.
