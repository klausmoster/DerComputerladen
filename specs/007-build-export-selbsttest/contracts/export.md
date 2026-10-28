# Vertrag: Presets, Projekteinstellungen, App-Symbol

Spec FR-001, FR-002, FR-017, FR-021 bis FR-025, SC-005. Entscheidungen in
[research.md](../research.md) R2, R3, R13 bis R15.

## Presets in `src/export_presets.cfg`

| Preset | System | Feature-Tag | Ausschluss | Ziel (unter `build/`, nicht versioniert) |
|---|---|---|---|---|
| `macOS` | macOS universal | – | `addons/gut/*, test/*, tools/*` (wie heute) | `macos/Der Computerladen.app` |
| `Selbsttest macOS` | macOS universal | `selbsttest` | `addons/gut/*, test/*` | `macos/Der Computerladen Selbsttest.app` |
| `Windows` | Windows x86_64 | – | `addons/gut/*, test/*, tools/*` | `windows/Der Computerladen.exe` |
| `Selbsttest Windows` | Windows x86_64 | `selbsttest` | `addons/gut/*, test/*` | `windows/Der Computerladen Selbsttest.exe` |
| `Linux` | Linux x86_64 | – | `addons/gut/*, test/*, tools/*` | `linux/Der Computerladen.x86_64` |
| `Selbsttest Linux` | Linux x86_64 | `selbsttest` | `addons/gut/*, test/*` | `linux/Der Computerladen Selbsttest.x86_64` |

- macOS: Selbsttest mit eigener Bundle-ID `de.klausmoster.dercomputerladen.selbsttest`, sonst wie
  das Preset `macOS` (ad hoc signiert, ohne Beglaubigung).
- Windows: `application/icon = res://assets/icon/app_icon.ico`, `application/modify_resources = true`,
  Produkt- und Dateiversion aus `application/config/version`, Firmen- und Produktname
  „Der Computerladen“, `binary_format/embed_pck = true`, ohne Signatur.
- Linux: `binary_format/embed_pck = true`.
- Keine Zugangsdaten in der Datei (FR-025); Claude sieht sie vor jedem Commit an.
- Teil 1 legt nur `Selbsttest macOS` an; die vier für Windows und Linux kommen in Teil 2.

## Projekteinstellungen in `src/project.godot`

| Einstellung | Wert | Teil |
|---|---|---|
| `application/config/name.selbsttest` | `"Der Computerladen Selbsttest"` | 1 |
| `application/run/main_scene.selbsttest` | `"res://tools/selbsttest/selbsttest_start.tscn"` | 1 |
| `rendering/rendering_device/fallback_to_opengl3` | `false` | 2 |
| `rendering/rendering_device/fallback_to_vulkan`, `fallback_to_d3d12` | `true` (Vorgabe, nicht eingetragen) | 2 |
| `input/toggle_fullscreen` | Ctrl+Cmd+F wie bisher, dazu F11 und Alt+Enter | 2 |

`test_projekt_einstellungen.gd` prüft diese Werte. Die Werkstatt lädt ihre Einstellungen weiter
selbst; ihr Fenster ist vom Vollbild-Kürzel nicht betroffen, weil sie `GameWindow` abschaltet.

## App-Symbol für Windows

`tools/raster/make_icon.py` schreibt zusätzlich `src/assets/icon/app_icon.ico` mit den Größen 16, 32,
48, 64, 128 und 256, als PNG-Einträge in der ICO, die kleinen pixelgenau aus dem gerasterten Logo
(`[C]`). Godot importiert die `.ico` nicht als Textur; geprüft wird, dass der Export nicht warnt
„Icon size … is missing“.

## Bauen

Vom Repo-Root, headless:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src --export-release "Selbsttest macOS" "../build/macos/Der Computerladen Selbsttest.app"
```

Für die anderen Presets entsprechend mit Name und Ziel aus der Tabelle. Voraussetzung für Windows und
Linux: die vollständigen Export-Templates 4.7.2 (R14).

## Ein Befehl für alles (FR-026a, R26)

```bash
tools/build/baue_alles.sh
```

Baut alle sechs Presets nach `build/macos/`, `build/windows/`, `build/linux/`, prüft das Spiel jedes
Systems auf Testcode (unten), und packt je System `build/abnahme/<version>_<system>.zip` mit Spiel und
Selbsttest; unter macOS mit `ditto`, die Linux-Dateien mit Ausführrecht. Ausgabe je Preset eine Zeile
„gebaut“ oder der Fehler; Exit 0 nur, wenn alles gebaut und geprüft ist. Mit `--nur macos` baut es nur
ein System, etwa für die Phasen von 007 vor Teil 2.

## Prüfung: kein Testcode im Spiel (SC-005)

Im Paket stehen die Pfade der enthaltenen Dateien im Klartext. Gesucht wird nach dem Läufer, der nur
im Selbsttest steckt:

```bash
grep -c "selbsttest_laeufer" "build/macos/Der Computerladen.app/Contents/Resources/Der Computerladen.pck"
```

Erwartet: `0` für das Spiel, mehr als `0` für den Selbsttest. Unter Windows und Linux dasselbe an der
ausführbaren Datei mit eingebettetem Paket. Nach `tools/selbsttest` allein zu suchen reicht nicht: Der
Override `main_scene.selbsttest` steht als Wert auch im Spiel in `project.binary`; das ist erwartet und
harmlos (R3). Die Aufgabe, die die Prüfung baut, belegt sie an beiden Paketen.
