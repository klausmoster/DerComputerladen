# Build und Tests

- **Worum es geht:** wie das Spiel gestartet, exportiert und getestet wird.
- **Laden, wenn:** exportiert wird, Tests geschrieben oder laufen gelassen werden, oder neue
  Dateien zum Export oder Repo dazukommen.
- **Code:** `src/export_presets.cfg`, `tools/build/baue_alles.sh`, `src/.gutconfig.json`,
  `src/test/`, `src/addons/gut/`, `tools/ton/make_sounds.py`, `tools/godot_referenz/erzeuge.sh`
- **Herkunft:** `specs/001-hauptmenue/` (Export, GUT), `specs/002-zeitleisten-werkstatt/`
  (Fixtures, Grundlinien), `specs/006-easter-egg-space-invaders/` (Töne, Probeszene),
  `specs/007-build-export-selbsttest/` (`contracts/export.md`, `research.md` R14, R26),
  `specs/008-architektur/` (`contracts/architektur-tests.md`, `research.md` R6; T039a), Regeln in
  `docs/ki_workflow/ki_dev.md`, „Tests“
- **Stand:** Feature 008, 2026-10-29

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

Sechs Presets, je System eins für das Spiel und eins für den Selbsttest. Ziele unter `build/`, nicht
versioniert:

| Preset | System | Feature-Tag | Ausgeschlossen | Ziel |
|---|---|---|---|---|
| `macOS` | macOS universal | – | `addons/gut/*`, `test/*`, `tools/*` | `macos/Der Computerladen.app` |
| `Selbsttest macOS` | macOS universal | `selbsttest` | `addons/gut/*`, `test/*` | `macos/Der Computerladen Selbsttest.app` |
| `Windows` | Windows x86_64 | – | `addons/gut/*`, `test/*`, `tools/*` | `windows/Der Computerladen.exe` |
| `Selbsttest Windows` | Windows x86_64 | `selbsttest` | `addons/gut/*`, `test/*` | `windows/Der Computerladen Selbsttest.exe` |
| `Linux` | Linux x86_64 | – | `addons/gut/*`, `test/*`, `tools/*` | `linux/Der Computerladen.x86_64` |
| `Selbsttest Linux` | Linux x86_64 | `selbsttest` | `addons/gut/*`, `test/*` | `linux/Der Computerladen Selbsttest.x86_64` |

Das Spiel schließt GUT, Tests und alle Werkzeuge aus; die Selbsttest-Presets nehmen `tools/*` mit,
also auch die Werkstatt. Was der Feature-Tag bewirkt, steht in [selbsttest.md](selbsttest.md).

- **macOS:** ad hoc signiert, ohne Beglaubigung; Bundle-ID `de.klausmoster.dercomputerladen`, der
  Selbsttest `….selbsttest`; Symbole `app_icon.png` und Liquid-Glass `app_icon.icon`.
- **Windows:** ohne Signatur. `application/modify_resources = true`: Godot schreibt Symbol und
  Versionsangaben selbst in die `.exe`, ohne `rcedit`. Symbol ist die ICO
  `res://assets/icon/app_icon.ico` (`application/icon`), Firmen- und Produktname „Der
  Computerladen“. Direct3D 12 ist als Treiber gesetzt (`rendering_device/driver.windows`).
- **Windows und Linux:** `binary_format/embed_pck = true`, das Paket steckt in der ausführbaren
  Datei; eine Datei reicht.
- **Version** aus `application/config/version` in `project.godot`, heute 0.1.
- **Export-Templates 4.7.2** müssen vollständig installiert sein, nicht nur die für macOS.

`export_presets.cfg` vor jedem Commit ansehen: Je nach Godot-Version landen dort Zugangsdaten.
Developer-ID und Beglaubigung für macOS und eine Signatur für Windows bleiben offen.

Einzeln bauen, vom Repo-Root, headless:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path src --export-release "macOS" "../build/macos/Der Computerladen.app"
```

Für die anderen Presets mit Name und Ziel aus der Tabelle.

**Alles mit einem Befehl:** `tools/build/baue_alles.sh`, mit `--nur macos`, `windows` oder `linux`
nur ein System. Godot kommt aus `$GODOT` oder `/Applications`. Je System leert es `build/<system>/`,
baut beide Presets (Ausgabe von Godot nach `build/logs/`), prüft auf Testcode und packt
`build/abnahme/<version>_<system>.zip` mit Spiel und Selbsttest; unter macOS mit `ditto`, damit
Signatur und Rechte der `.app` bleiben, sonst mit `zip`, das das Ausführrecht unter Linux behält.
Ausgabe je Schritt „gebaut“, „geprüft“, „gepackt“ oder der Fehler mit System und Grund. Als Fehler
zählt auch die Warnung „Icon size …“ von Godot. Exit 0 nur, wenn alles gebaut und geprüft ist.

**Prüfung auf Testcode:** Im Paket stehen die Pfade der Dateien im Klartext. Gesucht wird nach
`selbsttest_laeufer`, der nur im Selbsttest steckt:

```bash
LC_ALL=C grep -a -c "selbsttest_laeufer" "build/macos/Der Computerladen.app/Contents/Resources/Der Computerladen.pck"
```

Erwartet: 0 im Spiel, mehr als 0 im Selbsttest; unter Windows und Linux an der ausführbaren Datei.
Ohne `LC_ALL=C` und `-a` gibt `grep` bei Binärdateien nichts aus. Nach `tools/selbsttest` allein zu
suchen reicht nicht: Der Override `main_scene.selbsttest` steht auch im Spiel in `project.binary`,
wirkt dort aber nicht.

## Versionierung

- `.godot/` bleibt draußen, ebenso `build/`.
- `*.uid` und `*.import` werden committet: `.uid` hält die stabile ID einer Resource, `.import`
  die Import-Einstellungen. Fehlen sie, brechen Szenen-Referenzen nach einem Clone. Bei den Tönen
  hält die `.import` den Import als PCM ohne Trimmen, Normalisieren und Schleife.

## Godot-Referenz

`tools/godot_referenz/erzeuge.sh`, vom Repo-Root, schreibt die Klassenreferenz der installierten
Godot mit `--doctool` nach `godot_referenz/klassen/<Klasse>.xml`, etwa `Node.xml` oder
`RegEx.xml`, und die Versionen nach `godot_referenz/version.txt`. Ohne Schalter haben die Dateien
nur Signaturen: Erbfolge, Methoden mit Parametern, Eigenschaften, Signale, Konstanten und Enums.
Mit `--texte` holt das Skript die Beschreibungen aus dem Quellcode von Godot, Tag
`<Version>-stable`, und `--doctool` mischt sie hinein; mit `--handbuch` kommt das Handbuch aus
`godot-docs`, Zweig `4.7`, als `.rst` nach `godot_referenz/handbuch/`, ohne `classes/`. Beide
laden als Teil-Klon ohne Geschichte in den Cache `~/.cache/der-computerladen/`, je Rechner und
Version einmal; ein neuer Worktree kopiert nur. Üblich ist `tools/godot_referenz/erzeuge.sh --texte --handbuch`.
Passt die Godot nicht zur Version in `src/project.godot`, bricht das Skript ab (Exit 2). Der Ordner
steht in `.gitignore` und ist nicht im Repo; in jedem Worktree läuft das Skript einmal. Bei
API-Fragen sehen Claude, der Godot-Agent und der Architektur-Prüfer dort nach statt aus dem
Gedächtnis.

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
  `GameSession.folder`; Uhr und Würfel der Zeitleiste über `Timeline.clock` und `Timeline.rng`.
  `GameSession` nimmt dazu eigene Uhr, Zeitleiste, Uhrzeit (`now`), Würfel (`rng`) und
  `quit_callback`. Titel- und Spielbildschirm nehmen eine eigene `session` und prüfen
  Szenenwechsel über `scene_callback`. Werkstatt und Zusammenfassung des Selbsttests nehmen ein
  eigenes `game_window`, der Simulator einen eigenen Würfel `SimulatorPanel.rng` (Nähte, siehe
  [architektur.md](architektur.md)). Kein Test schreibt in `user://spielstaende/`.
- **Selbsttest (Feature 007):** `test_selbsttest_*.gd` prüfen Lauf, Protokoll, Fahrer, Eingabe,
  Läufer, Abläufe und Zusammenfassung ohne Fenster; `test_projekt_einstellungen.gd` Renderer,
  Vollbildtasten, Overrides und Symbol. Die Probeszene `test/fixtures/selbsttest_ergebnis_probe.tscn`
  zeigt die Zusammenfassung mit erfundenen Läufen. Den Lauf im echten Fenster beschreibt
  [selbsttest.md](selbsttest.md).
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

**Architektur-Test (Feature 008):** `test_architektur.gd` misst die Regeln des Leitfadens, die sich
am Quelltext messen lassen; den Rest prüft der Architektur-Prüfer. Er liest Skripte und Szenen als
Text und trennt Code, Zeichenketten und Kommentare; Kommentare zählen nie. `addons/` und `test/`
durchsucht er nicht.
- **AR-01, AR-08** (`test_kerne_ohne_node`): Jedes Skript in `core/timeline/`, `core/save/` und
  in der Liste `KERNE` erbt von `RefCounted` oder `Resource`, nennt kein Autoload, ruft weder
  `get_tree()` noch `Engine.get_main_loop()` und keinen globalen Zufall (`randi()`, `randf()`,
  `randi_range()`, `randf_range()`, `randfn()`, `randomize()`, `shuffle()`, `pick_random()`).
- **AR-03** (`test_genau_diese_autoloads`): In `project.godot` stehen genau die Autoloads aus
  `AUTOLOADS`, in dieser Reihenfolge.
- **AR-02** (`test_kein_weg_nach_oben`): Kein Skript nennt `/root/` oder einen Knotenpfad mit
  `../`, keine Szene `../` oder `/root/`. Ein Knotenpfad ist eine Zeichenkette nach `^`, `$`,
  `NodePath(`, `get_node(`, `get_node_or_null(` oder `has_node(`; ein Dateipfad wie
  `"../Resources"` zählt nicht.
- **AR-14** (`test_spiel_kennt_werkzeuge_nicht`): Außerhalb von `tools/` verweist nichts auf
  `res://tools/`.

Die Listen am Kopf: `KERNE` (Kerne außerhalb der beiden Kernordner), `AUTOLOADS`,
`ERLAUBT_NACH_OBEN` (begründete Ausnahmen; heute nur `werkstatt.gd` mit `/root/GameWindow`),
`BIS_BEHEBUNG` (Abweichungen bis zur Behebung, seit Phase 5 von 008 leer) und `VORGEMERKT`
(Abweichungen, die ein eigenes Feature behebt; leer). `test_listen_ohne_leichen` meldet veraltete
Einträge: einen Pfad, den es nicht mehr gibt, oder mehr Einträge als Wege nach oben in der Datei.
`test_ausnahmen_wie_im_leitfaden` prüft, dass jede erlaubte Stelle in der Tabelle „Ausnahmen“ des
Leitfadens steht. Die Prüffunktionen nehmen einen Text; Fehlerproben an erfundenen Texten zeigen,
dass jede den Verstoß findet und die erlaubte Stelle daneben nicht.

**Tests aus Feature 008:** neu `test_architektur.gd` und `test_field_helpers.gd` (gemeinsame Hilfen
der Werkstatt); erweitert für die Umbauten, etwa `test_game_clock.gd` (Tage je Bild, Ende),
`test_title_screen.gd` (Phasen, Ebene und sichtbare Seite, Texte aus `TitleTexts`),
`test_timeline.gd` und `test_werkstatt_scene.gd` (Würfel über `rng`),
`test_selbsttest_laeufer.gd` (Stillstand nach dem Schließen).

Was Tests nicht sehen, prüft Klaus von Hand nach dem `quickstart.md` des Features: Look,
Fensterverhalten, Zeitstrahl, Formulare, Klang der Töne.
