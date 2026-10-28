# Recherche: Build & Export mit Selbsttest

Entscheidungen aus `/speckit-plan` zu [spec.md](spec.md), jede mit Grund und verworfenen
Alternativen (Verfassung, Grundsatz III). Die Verträge unter [contracts/](contracts/) setzen sie um,
das Datenmodell steht in [data-model.md](data-model.md).

„Claude, 2026-10-28“ heißt: eigene Festlegung, eingetragen in `docs/offene-punkte.md`, Abschnitt
„Feature 007, Plan“; Klaus kann sie bei der Checkliste oder jeder Abnahme ändern.

**Belege:** Ein Recherche-Agent hat am 2026-10-28 die Quellen von Godot am Tag `4.7.2-stable`, das
Klassenhandbuch des installierten 4.7.2 (`--doctool`) gelesen und die Kernfragen in einem
Wegwerf-Projekt mit echtem Fenster und macOS-Export ausprobiert. Wo unten „belegt“ steht, gibt es
Quelle oder Versuch; „Vermutung“ ist offen und wird in der genannten Phase geprüft.

## R1 Eigener Läufer statt GUT

**Entscheidung:** Der Selbsttest bekommt einen eigenen kleinen Läufer: Abläufe als Skripte mit
`await`, je Schritt Eingaben, Warten auf einen Zustand, Foto, Ergebnis (Claude, 2026-10-28).
GUT bleibt das Werkzeug für die Tests ohne Fenster und bleibt aus jedem Export draußen.

**Grund:** GUT ist rund 3,2 MB groß, hat Editor-Teile (`gut_plugin.gd`, `get_editor_interface.gd`)
und müsste Tests vor dem Export einsammeln (belegt). Die Abläufe brauchen nichts davon: Sie laufen
nacheinander durch ein echtes Fenster, warten auf Bilder und schreiben ein eigenes Protokoll. Ein
Läufer mit Ablauf, Schritt und Ergebnis ist klein und genau auf das Protokoll aus FR-014
zugeschnitten.

**Verworfen:** GUT im Export, wegen Größe, Editor-Teilen und eigener Ausgabe, die nicht dem
Protokoll entspricht.

## R2 Ort des Codes: `src/tools/selbsttest/`

**Entscheidung:** Läufer, Abläufe, Startszene und Zusammenfassung liegen unter
`src/tools/selbsttest/`. Das Preset „macOS“ schließt `tools/*` schon heute aus, also auch den
Selbsttest (FR-002). Das Preset „Selbsttest macOS“ schließt nur `addons/gut/*` und `test/*` aus; die
Werkstatt kommt so mit in die Selbsttest-App, wird dort aber nie geladen (Claude, 2026-10-28).
Vergleichswerkzeug und Referenzbilder liegen außerhalb von Godot unter `tools/selbsttest/`.

**Grund:** Eine Regel für alle Werkzeuge statt einer zweiten; die Zusammenfassung nutzt das Theme der
Werkstatt `tools/werkstatt/werkstatt_theme.tres` (R12), das so ohnehin im Paket ist. Referenzbilder
in `src/` würde Godot importieren und `.import`-Dateien anlegen.

**Verworfen:** eigener Ordner `src/selbsttest/` mit eigenem Ausschluss, wie der Agent vorschlug;
geht auch, braucht aber eine zweite Regel im normalen Preset und die Werkstatt-Datei als Ausnahme.

## R3 Eigene App über den Feature-Tag `selbsttest`

**Entscheidung:** Das Preset „Selbsttest macOS“ trägt den eigenen Feature-Tag `selbsttest`. In
`project.godot` stehen dazu Overrides:

- `application/config/name.selbsttest = "Der Computerladen Selbsttest"`: eigener Name der App und
  damit eigener Datenordner `app_userdata/Der Computerladen Selbsttest` (belegt im Versuch). Echte
  Spielstände liegen in einem anderen Ordner und sind für den Selbsttest unsichtbar (FR-008).
- `application/run/main_scene.selbsttest = "res://tools/selbsttest/selbsttest_start.tscn"`: die
  Startszene des Selbsttests (belegt: Overrides wirken früh genug, auch für Name und Ordner).
- Eine eigene Bundle-ID im Preset, `de.klausmoster.dercomputerladen.selbsttest`, damit macOS beide
  Apps auseinanderhält.

Im Skript liest der Selbsttest Einstellungen mit `ProjectSettings.get_setting_with_override()`;
`get_setting()` liefert den Grundwert (belegt).

**Grund:** Ein Name, ein Ordner, eine Startszene, ohne dass das Spiel etwas vom Selbsttest weiß. Die
Overrides stehen zwar auch im normalen Export in `project.binary`, wirken dort aber nicht (belegt).

**Verworfen:** ein Autoload für den Selbsttest, weil er im normalen Export auf eine fehlende Datei
zeigte; ein Startparameter, weil ein Doppelklick keinen mitgibt.

## R4 Eingaben einspeisen, echte fernhalten

**Entscheidung:**
- Jede Eingabe des Selbsttests ist ein `InputEvent` mit der Kennung `device = 4711` und geht durch
  `Input.parse_input_event()`, also denselben Weg wie echte Eingaben (FR-004).
- Der Selbsttest ersetzt mit `DisplayServer.window_set_input_event_callback()` den Empfang des
  Fensters: Ereignisse mit `device = 4711` reicht er mit `get_tree().root.push_input()` weiter, alle
  anderen verwirft er (FR-010). Im Versuch kam ein echter Klick nicht durch, ein markierter schon
  (belegt).
- `Input.use_accumulated_input = false`, weil Godot sonst Mausbewegungen ohne Blick auf die Kennung
  zusammenfasst (belegt).
- Mauspositionen rechnet der Selbsttest vom Raster 640 × 360 in Fensterpixel um, mit
  `get_tree().root.get_final_transform()` (belegt, Faktor 2 bei 1280 × 720).
- Drücken und Loslassen gehen in zwei aufeinanderfolgenden Bildern raus, eine gehaltene Taste wird
  je Bild erneuert.

**Grund:** Hover, `mouse_entered`, Zeigerwechsel und Klicks entstehen so wie bei echter Maus, ohne
`warp_mouse` und ohne Fensterfokus (belegt). Ein früher Knoten mit `_input()` reicht nicht: Godot
rechnet das Hover vor `_input()` aus, und Autoloads werden als letzte gefragt (belegt).

**Nachtrag Phase 2:** Beim Weiterreichen an das Fenster bekommt ein eigenes Ereignis das Gerät, das
Godot 4.7 echten Ereignissen gibt: `InputEvent.DEVICE_ID_KEYBOARD` (16) für Tasten,
`DEVICE_ID_MOUSE` (32) für die Maus. Die Aktionen `ui_accept`, `ui_cancel`, `ui_focus_*` gelten nur
für Gerät 16; mit 4711 löste Enter nichts aus (belegt mit Probe und Test). 4711 ist damit nur das
Kennzeichen bis zum Filter. Weitergereicht wird an das Fenster selbst (`push_input()`), das ist
die Wurzel des Baums.

**Restrisiken, geprüft in Phase 2:**
- Echte Tasten ändern trotzdem den Zustand von `Input`, etwa `is_key_pressed()`. Das Spiel fragt
  diesen Zustand nirgends ab (geprüft am 2026-10-28: kein `Input.is_…`, `Input.get_…` oder
  `window_input` unter `scenes/`, `core/`, `ui/`); das versteckte Spiel liest Ereignisse.
- Verlässt der echte Zeiger das Fenster, löscht Godot das Hover. Deshalb schickt jeder Schritt mit
  Mausziel vor dem Klick eine Bewegung auf das Ziel.
- Verliert das Fenster den Fokus, gibt Godot gedrückte Tasten frei. Der Fokusverlust steht im
  Protokoll (FR-013), der Schritt kann dann scheitern; das ist gewollt sichtbar.
- Das Signal `Window.window_input` feuert für die Ereignisse des Selbsttests nicht. Das Spiel nutzt
  es nicht.
- Den ursprünglichen Empfang des Fensters gibt Godot nicht heraus; „ausschalten“ heißt deshalb:
  alles durchreichen. Ob Godot den Empfang bei Größen- oder Moduswechseln neu setzt, prüft Claude in
  Phase 3 (Ablauf `fenster`) und Phase 4 (Maximieren) (Analyse, U3).
- Beim Schließen beendet `GameSession` das Programm selbst, solange ein Spiel läuft. Der Läufer
  setzt deshalb einen eigenen `quit_callback`, der erst Protokoll, Ausgabe und Zip schreibt und dann
  beendet (Analyse, U2).

**Verworfen:** Knoten mit `_input()` und `set_input_as_handled()`; echte Eingaben nur erkennen und
melden statt fernhalten, weil Spec FR-010 das Fernhalten verlangt.

## R5 Ziele über ihre Bedeutung: der Fahrer

**Entscheidung:** Zwischen Abläufen und Spiel steht ein **Fahrer** (`SelbsttestFahrer`), der den Titel
kennt: Er findet Seiten, Einträge nach Kennung (`new_game`, `continue`, `back`, …), Zeilen der Liste
nach Spielstand, Gehäusetasten nach Index und den Knopf „Zum Hauptmenü“, und liest den Zustand
(sichtbare Seite, gewählte Zeile, Hinweis, Szene, Fahrt des Communicators). Abläufe sprechen nur mit
dem Fahrer. Wortlaute holt er aus `TitleTexts` (Claude, 2026-10-28).

**Grund:** Ändert sich die Oberfläche, ändert sich eine Stelle, der Fahrer, nicht jeder Ablauf; das
ist der Kern der Aufgabe „[A] Selbsttest-Abläufe anpassen“ in späteren Features. Fehlt ein Ziel,
nennt die Meldung, was gesucht war (FR-005). Ein Knopf, der ein paar Pixel rückt, stört nicht, weil
die Lage zur Laufzeit gelesen wird.

**Verworfen:** Koordinaten in den Abläufen; Suche nach sichtbarem Text, weil die Liste Zeilen in
Spalten malt und Texte sich ändern.

## R6 Warten auf Zustände, Höchstzeit

**Entscheidung:** Nach den Eingaben prüft der Schritt jedes Bild, ob der erwartete Zustand da ist,
bis zur Höchstzeit von 5000 ms (Claude, 2026-10-28). Danach wartet er auf
`RenderingServer.frame_post_draw` und fotografiert. Feste Wartezeiten gibt es nicht. Der Lauf nimmt
für den Communicator die echte Fahrt (`animate` bleibt an), denn sie gehört zum geprüften Spiel; im
Zeitraffer läuft sie schneller (R24). Die Höchstzeit gilt in echter Zeit.

**Grund:** Wartet ein Schritt auf eine feste Zeit, ist er auf langsamen Rechnern zu kurz und auf
schnellen verschwendet. 5 s sind ein Vielfaches der längsten Fahrt, auch in Echtzeit.

## R7 Gleiche Fotos: feste Uhrzeit, Zeitzone, Seed

**Entscheidung:**
- `GameSession.now` gibt im Selbsttest eine feste Zeit zurück, `2026-10-26 20:40 UTC`, und
  `GameSession.rng` hat einen festen Seed (4711).
- Die Hinweise der Liste zeigen Zeiten in der Zeitzone des Rechners
  (`SaveGame.time_text()` mit `SYSTEM_BIAS`). Damit Fotos auf jedem Rechner gleich sind, bekommt
  `SaveGame` eine statische Stellschraube für den Versatz, die nur der Selbsttest setzt, auf UTC+1.
  Ohne sie gilt wie bisher die Zeitzone des Rechners. Das ist die einzige Änderung am Spiel für den
  Teil 1 (Claude, 2026-10-28).
- Die Spieluhr steht im Spielbildschirm still (heute so, `GameClock.paused` bleibt true); das
  Spieldatum bleibt 01.01.1985.
- Das versteckte Spiel rechnet nach vergangener Zeit. Fotos der Schritte `easter_egg.03_start` und
  `easter_egg.04_spielen` sind deshalb „nicht vergleichbar“; geprüft wird dort der Zustand.

**Grund:** Ohne diese drei Dinge ändert sich bei jedem Lauf oder auf jedem Rechner ein Hinweis, und
der Vergleich wäre wertlos. Auf dem Mac waren Fotos in drei Fenstergrößen und über zwei Prozesse
bytegleich (belegt).

**Vermutung, geprüft in Teil 2:** Andere Grafikkarten können Kanten oder Schrift anders malen. Dann
zeigt der Vergleich genau das; ob es stört, entscheidet Klaus am Befund.

## R8 Fotos

`get_viewport().get_texture().get_image()` nach `await RenderingServer.frame_post_draw` liefert bei
Stretch `viewport` immer 640 × 360, unabhängig von der Fenstergröße; der Mauszeiger ist nicht im Bild
(belegt). Gespeichert wird PNG mit `Image.save_png()`.

## R9 Protokoll als eine Textdatei mit festen Schlüsseln

**Entscheidung:** Ein `protokoll.txt` mit Zeilen `schlüssel: wert` und Blöcken je Schritt
([contracts/protokoll.md](contracts/protokoll.md)). Derselbe Formatierer schreibt Datei und Text für
„Kopieren“ (FR-014a) (Claude, 2026-10-28).

**Grund:** Klaus liest es ohne Werkzeug, Claude wertet es zeilenweise aus, und es passt in den Chat.

**Verworfen:** Text und JSON nebeneinander, weil zwei Dateien auseinanderlaufen können; nur JSON,
weil Klaus es schlecht liest.

## R10 Ausgabe mitschneiden mit `Logger`

**Entscheidung:** Ein eigener `Logger`, angemeldet mit `OS.add_logger()`, nimmt jede Zeile von Godot
und Spiel (`_log_message`, `_log_error`), versieht sie mit der Kennung des laufenden Schritts und
schreibt sie nach `ausgabe.txt`; Fehler und Warnungen hängt er dem Schritt als `meldung:` an. Die
Methoden kommen aus fremden Threads, deshalb mit `Mutex`, und sie geben selbst nichts aus (belegt).

**Verworfen:** Godots Datei `user://logs/godot.log` nachträglich lesen, weil sie keine Schritte
kennt.

## R11 Ablage, Zip, Ordner zeigen, Zwischenablage

- Ordner: `user://selbsttest/<lauf-id>/`, daneben `<lauf-id>_<system>.zip` mit `ZIPPacker`
  (eine Datei zur Zeit offen; belegt).
- „Ordner zeigen“: `OS.shell_show_in_file_manager()` auf das Zip; Windows und macOS markieren es,
  Linux öffnet den Ordner (belegt).
- „Kopieren“: `DisplayServer.clipboard_set()`. Unter Linux mit X11 ist der Inhalt nach dem Beenden
  weg, wenn kein Clipboard-Manager läuft (belegt); der Quickstart sagt: erst einfügen, dann beenden.
- Ist der Ordner nicht beschreibbar, zeigt die Zusammenfassung die Meldung mit Pfad (Spec, Edge
  Cases).

## R12 Zusammenfassung im Look der Werkzeuge

**Entscheidung:** Nach dem letzten Ablauf wechselt der Selbsttest in eine eigene Szene
`selbsttest_ergebnis.tscn`. Wie die Werkstatt schaltet sie die Skalierung des Spiels ab, nimmt den
Skalierungsfaktor des Bildschirms und das Theme `werkstatt_theme.tres` (Spec, Clarify). Was der
Abschnitt „Werkzeuge“ im Style-Guide für eine solche Seite noch nicht regelt, kommt vorher dort
hinein (Grundsatz IV), als `[C]`-Aufgabe in Phase 4: Zeichen für Fehler und „nicht gelaufen“, keine
Farbe für „in Ordnung“, gesperrte Knöpfe, mehrzeilige Listen, Bestätigung, Tooltip und Handzeiger
für alle Werkzeuge, Umbruch, Geltung der Wortliste, Formen im Protokoll (Review CHK019, CHK020,
CHK024 bis CHK027, CHK030, CHK039). Wie die Werkstatt maximiert die Seite das Fenster, hält
`GameWindow` an und setzt die eingebaute Schrift auf einer Kopie des Themes (Review CHK016,
CHK017).

## R13 Renderer: kein Ausweichen auf OpenGL

**Entscheidung (Klaus, 2026-10-28, Spec):** `rendering/rendering_device/fallback_to_opengl3 = false`
in `project.godot`. `fallback_to_vulkan` und `fallback_to_d3d12` bleiben true: Unter Windows darf
Godot zwischen Direct3D 12 und Vulkan wechseln, beides ist Forward+ (belegt: getrennt schaltbar).
Fehlt beides, zeigt Godot das Fenster „Unable to initialize video driver“ mit dem Text „Your video
card drivers seem not to support …“ und endet (belegt für Windows, X11, Wayland). Ein GUT-Test prüft
die drei Einstellungen.

Der Agent hatte empfohlen, die Standardwerte zu lassen und den Renderer nur zu protokollieren; das
widerspricht Klaus' Entscheidung und Grundsatz I und wurde nicht übernommen.

## R14 Exporte für Windows und Linux

- **Vorlagen fehlen:** Auf Klaus' Mac liegen unter
  `~/Library/Application Support/Godot/export_templates/4.7.2.stable/` nur `macos.zip` und
  `version.txt` (belegt). Für Windows und Linux müssen die vollständigen Export-Templates 4.7.2
  installiert werden. Das ist ein Download und eine `[K]`-Aufgabe; Claude fragt vorher mit
  Dateiname, Quelle und Größe (FR-024).
- **Kein `rcedit`, kein wine:** Godot 4.7 schreibt Symbol und Versionsangaben selbst in die `.exe`
  (`application/modify_resources`, Standard true; belegt). Die Idee aus dem Backlog, `rcedit`
  herunterzuladen, entfällt.
- **Symbol:** `application/icon` nimmt auch PNG und rechnet selbst auf 16 bis 256 Pixel herunter
  (belegt). Für Pixelgrafik verwischt das. Deshalb erzeugt `tools/raster/make_icon.py` eine
  `app_icon.ico` mit 16, 32, 48, 64, 128 und 256 Pixeln, die kleinen Größen pixelgenau aus dem
  gerasterten Logo (Claude, 2026-10-28, `[C]`). Fehlt eine Größe, warnt Godot.
- **Ein Paket je System:** `binary_format/embed_pck = true` für Windows und Linux, damit eine Datei
  reicht (belegt bis etwa 3,9 GB).
- **Direct3D 12:** Das Projekt setzt `driver.windows = "d3d12"`; der Export legt die Agility-DLLs bei,
  wenn sie in den Vorlagen sind (belegt; Vorhandensein prüfen nach der Installation).
- **Linux:** Ob das Ausführrecht beim Weitergeben als Zip vom Mac erhalten bleibt, ist offen
  (Vermutung); der Quickstart nennt `chmod +x` als Rückfall.
- **Selbsttest-Presets:** je System ein zweites Preset mit Tag `selbsttest`, Ausschluss nur
  `addons/gut/*, test/*`.

## R15 Vollbild unter Windows und Linux

**Entscheidung:** Die Aktion `toggle_fullscreen` bekommt zu Ctrl+Cmd+F die Tasten F11 und Alt+Enter
(Spec, Clarify). Alle drei gelten auf jedem System; unter macOS fängt das System F11 meist selbst ab,
unter Windows tut Ctrl+Win+F nichts im Spiel Störendes (Claude, 2026-10-28).

**Änderung nach der Analyse (I2, Klaus, 2026-10-28):** Godot lässt Alt+Enter auch als `ui_accept`
gelten, weil eine Aktion ohne Zusatztaste auch ein Ereignis mit Alt trifft. Der gewählte Menüeintrag
löste dann aus, und `GameWindow._unhandled_input()` sähe das Ereignis nie. `GameWindow` fängt das
Kürzel deshalb in `_input()` ab, vor der Oberfläche, mit genauem Vergleich der Zusatztasten, und
markiert es als behandelt. Enter allein löst weiter aus. Das ist die zweite Änderung am Spielcode
(Phase 6).

**Verworfen:** Belegung je System über Overrides der Eingabe (`input/….windows`); nicht belegt, ob
Godot Overrides für Eingabe-Aktionen anwendet, und mehr zu prüfen.

## R16 Ablauf „Fenster“

Der Selbsttest stellt die Fenstergröße über `get_window().size` ein (Größe ziehen ist Sache des
Systems) und prüft Zahlen: Startgröße gleich `640 × 360 × GameWindow.best_factor()` für den
Bildschirm, Lage mittig im nutzbaren Bereich (± 1 Pixel), bei krummer Größe ganzzahliger Faktor
und mittiges Bild laut `get_tree().root.get_final_transform()`. Vollbild nicht (Spec, Clarify).

## R17 Vergleichswerkzeug in Python

`tools/selbsttest/vergleich.py`, Python 3 mit Standardbibliothek, PNG über `tools/raster/pngio.py`;
Aufruf mit `python3 -I`, weil Zips von fremden Rechnern kommen; Pfade im Zip, die hinausführen,
werden abgelehnt ([contracts/vergleich.md](contracts/vergleich.md)) (Claude, 2026-10-28, `[C]`).

**Verworfen:** Vergleich in Godot, weil Claude ihn ohne Godot und ohne Fenster laufen lassen soll.

## R18 Referenzbilder

`tools/selbsttest/referenz/macos/<kennung>.png`, versioniert; erneuert nur nach Klaus' Abnahme
(FR-020) mit `--referenz-erneuern`. Die alten bleiben in der Versionsgeschichte.

## R19 Belege

`specs/007-build-export-selbsttest/belege/<system>_<lauf-id>/` mit Protokoll, Vergleichsbericht und
nur den abweichenden Fotos samt Markierung (Spec, Clarify, FR-020a). Eingang `build/selbsttest/`,
schon durch `/build/` in `.gitignore` ausgenommen.

## R20 Systemdaten

Gemessen auf Klaus' Mac (belegt): `OS.get_name()` macOS, `OS.get_version()` 27.0.1,
`OS.get_processor_name()` Apple M1, `RenderingServer.get_video_adapter_name()` „Apple M1
(Apple7)“, Hersteller Apple, `get_current_rendering_driver_name()` metal,
`get_video_adapter_api_version()` 4.0, `get_current_rendering_method()` forward_plus,
`DisplayServer.screen_get_size()` 3840 × 2160, `screen_get_scale()` 2.0, `screen_get_dpi()` 265,
`screen_get_refresh_rate()` 60, `OS.get_locale()` de_DE, `keyboard_get_layout_name()` Deutsch.
`OS.get_video_adapter_driver_info()` gibt es nur unter Windows und Linux und kann dort Sekunden
dauern; der Selbsttest ruft sie in einem Thread auf, solange der erste Ablauf läuft.

## R21 Version und Bauzeit des Selbsttests

`selbsttest.version` ist eine Zahl im Läufer, die steigt, wenn sich Abläufe ändern.
`selbsttest.gebaut` ist die Änderungszeit des Pakets: unter macOS die `.pck` in
`Contents/Resources/`, unter Windows und Linux die ausführbare Datei mit eingebettetem Paket; sonst
`unbekannt` (Claude, 2026-10-28). Godot kennt ohne Export-Plugin keine Bauzeit.

## R22 Fortschritt im Fenstertitel

`get_window().title = "Selbsttest · Schritt 12 von 40: Neues Spiel"` vor jedem Schritt (Spec, FR-003). Nicht
im Spielbild, damit die Fotos nur das Spiel zeigen.

## R23 Prüfen, was sich prüfen lässt

- GUT, ohne Fenster: Protokoll Byte für Byte gegen Erwartungen; Ergebnis und Summe des Läufers mit
  erfundenen Schritten; Systemdaten haben jeden Schlüssel; Stellschraube der Zeitzone in `SaveGame`;
  die Einstellungen aus R13 und R15; der Fahrer findet jedes Ziel im echten Titel und meldet ein
  fehlendes mit Namen.
- Im echten Fenster: die Selbsttest-App selbst, gebaut und per `open` gestartet, mit der
  Fehlerprobe aus SC-004, je ein Fehler in einer Kopie: Titel (falsch vorgewählte Zeile), Gradwahl
  (fehlende Seite), Liste (ohne Spielstand), Rückfrage (falsche Vorwahl), Easter Egg (Gehäusetasten
  vertauscht), Fenster (falscher Startfaktor) (Analyse, I7).
- `export.md` nennt die Prüfung, dass das normale Paket keine Datei des Selbsttests enthält (SC-005).

## R24 Zeitraffer über `Engine.time_scale`

**Entscheidung:** Der Läufer setzt vor jedem Ablauf `Engine.time_scale = 8` und für
`titel_echtzeit` auf 1 (Spec FR-003a, Klaus, 2026-10-28; Faktor Claude, 2026-10-28). Godot skaliert
damit `delta` in `_process()` und `_physics_process()`, Tweens und Timer; Fahrt des Communicators,
Spieluhr und das versteckte Spiel laufen so schneller, ohne dass das Spiel davon weiß. Höchstzeiten
und Dauern misst der Läufer mit `Time.get_ticks_msec()`, das nicht skaliert ist. Gehaltene Tasten
(„Pfeil rechts halten“) zählen in echter Zeit.

**Grund:** Eine Stellschraube für alles, ohne Code im Spiel. Fotos entstehen nur, wenn alles steht
(R6), deshalb bleiben sie gleich. Faktor 8 hält jede Fahrt über mehrere Bilder, sodass Zwischenlagen
noch durchlaufen werden; ein höherer Faktor würde Bewegungen in ein, zwei Bildern abschließen und
mehr verdecken.

**Grenze (Analyse, I1):** Der Communicator stellt seine Fahrt selbst weiter und begrenzt den Schritt
je Bild auf 1/30 s (`Communicator.MAX_STEP`), das versteckte Spiel auf vier Schritte je Bild. Im
Zeitraffer fährt der Communicator deshalb bei 60 Bildern je Sekunde nur etwa doppelt so schnell. Die
Grenzen bleiben, sie halten die Bewegung glatt; SC-001 verlangt nur, dass der Zeitraffer schneller
ist.

**Vermutung, geprüft in Phase 2:** `GameWindow` rechnet mit `Time.get_ticks_msec()`, ist also nicht
betroffen; der Ablauf `fenster` läuft dennoch mit Faktor 1, weil er Fenster des Systems abwartet.

**Verworfen:** eigene Tempo-Schalter je System im Spiel (`Communicator.animate`,
`GameClock.days_per_second`), weil jedes künftige Feature einen weiteren bräuchte.

## R25 Selbsttest zur Endabnahme

**Entscheidung (Klaus, 2026-10-28):** Der Selbsttest läuft zur Gesamtabnahme eines Features, nicht
nach jeder Phase. Vor der Gesamtabnahme steht die Aufgabe „[A] Selbsttest-Abläufe anpassen“, danach
baut Claude alles mit einem Befehl (R26), lässt den Selbsttest auf dem Mac laufen und nennt das
Ergebnis in der Bitte um Gesamtabnahme; Klaus startet ihn auf Windows und Linux, wenn das Feature
dort etwas ändert oder es lange keinen Lauf gab. Wann genau, schlägt Claude mit der Regel in
Phase 7 vor. In 007 selbst läuft er in den Phasen, die ihn bauen.

## R26 Ein Befehl baut alles: `tools/build/baue_alles.sh`

**Entscheidung:** Ein Shell-Skript `[C]` baut headless alle sechs Presets nach `build/`, prüft das
Spiel jedes Systems auf Testcode (export.md, SC-005) und packt je System ein Zip zum Weitergeben:
`build/abnahme/<version>_<system>.zip` mit Spiel und Selbsttest. Unter macOS packt es mit `ditto`,
damit Signatur und Rechte der `.app` erhalten bleiben; die Linux-Datei bekommt im Zip ihr Ausführrecht.
Endet mit Exit 0 nur, wenn alles gebaut und geprüft ist; sonst nennt es System und Grund (Spec
FR-026a) (Claude, 2026-10-28).

**Grund:** Shell, weil es nur Godot, `grep`, `zip` und `ditto` aufruft; Python bliebe für den
Vergleich. Liegt unter `tools/build/`, nicht in `src/`, weil es kein Teil des Spiels ist.

**Verworfen:** ein Python-Skript, weil es nur Befehle aneinanderreiht; ein Export-Plugin im Editor,
weil es den Editor bräuchte.

## R27 Rahmen für Szenarien

**Entscheidung:** Ein Szenario ist ein Ablauf (`SelbsttestSzenario`, abgeleitet von
`SelbsttestAblauf`) mit drei Zusätzen: Startbedingung (Grad, Seed), einer Liste von Entscheidungen,
die über den Fahrer an der Oberfläche getroffen werden, und Prüfpunkten mit Spieldatum, an denen der
Läufer die Spieluhr im Zeitraffer bis zu diesem Tag laufen lässt, den Zustand prüft und fotografiert
(Spec FR-011a; Claude, 2026-10-28). Die Spieluhr läuft dabei über die Bedienung des Spielbildschirms,
sobald es sie gibt. Bis dahin gibt es kein Szenario; der Rahmen hat einen GUT-Test mit einem
erfundenen Szenario ohne Fenster.

**Grund:** So kann das erste Feature mit Bedienung im Spielbildschirm ein Szenario anlegen, ohne den
Läufer zu ändern. Ein Probeszenario jetzt hätte die Spieluhr an der Oberfläche vorbei starten
müssen (Spec, Abgleich).

## Auslegungen aus Phase 1

Vom Agent bei T001 bis T006 ausgelegt, von Claude geprüft und angenommen (2026-10-28):
- `SelbsttestAblauf.schritte()` nimmt den Fahrer vorerst als `RefCounted`; T013 stellt auf
  `SelbsttestFahrer` um. `zeitraffer` ist ein Feld des Ablaufs (Vorgabe 8). Schritte entstehen über
  `neuer_schritt()`, damit jedes Dictionary dieselben Schlüssel hat.
- `selbsttest.version`, `lauf.start`, `lauf.feste_zeit` und `lauf.zeitraffer` hält der Lauf, nicht
  `SelbsttestSystem`; ein Test prüft, dass beide zusammen genau die 24 Schlüssel der Tabelle haben.
- Der Grund bei abhängigen Abläufen nennt die Ursache über mehrere Stufen („Fehler in Ablauf
  neues_spiel“ auch bei `loeschen`). Beim Abbruch heißen der laufende und alle offenen Schritte
  „Fenster geschlossen“, `lauf.abbruch` nennt den laufenden.
- Der Kopiertext bei nicht beschreibbarem Ordner hat kein `ergebnis:`, die `meldung:` steht nach
  `# System`; `# Schritte` steht auch ohne Schritte da.
- Das Zip hat keinen Oberordner; `vergleich.py` (T035) entpackt nach `build/selbsttest/<name>/`.
- Meldungen haben die Form `WARNING: Text · at: funktion (datei:zeile)` mit dem Ort aus dem
  Skript; `printerr()` zählt als Meldung, `print()` nicht; Meldungen vor dem ersten und nach dem
  letzten Schritt stehen nur in `ausgabe.txt`. Der Läufer sagt dem Logger den Schritt
  (`setze_schritt()`), weil der Logger aus fremden Threads gerufen wird. `ausgabe.txt` entsteht am
  Ende aus dem Speicher.
- `system.gpu_driver` als „Name Version“, `godot.version` mit drei Zahlen, Kommazahlen auf 0,01,
  ganze Bildwiederholraten ohne Nachkommastellen; headless meldet die Tastatur „Not supported“, so
  bleibt es stehen.
- Zwei Testdateien mehr als im Vertrag: `test_selbsttest_logger.gd`, `test_selbsttest_ablage.gd`.
- **Aus der Phasenprüfung (Text-Prüfer, 2026-10-28), von Claude entschieden:** Das Ziel in „Ziel
  nicht gefunden: …“ steht in der Form der Spalte „Erwartet“, etwa `HAUPTMENÜ, „Neues Spiel“`, die
  Kennung nur, wo es keinen Wortlaut gibt (L2). Maschinenform nur für Messwerte, Texte der Abläufe
  deutsch mit „ד (L1). Ein durch einen Fehler im Läufer offener Schritt hat `gefunden: unbekannt`
  (L3). „Kein Protokoll“ steht ohne `[selbsttest]` (L4). L1 kommt mit T027 in den Style-Guide.
- **Entscheidung Claude für Phase 2:** Der Text für `eingaben:` kommt als eigener Schlüssel
  `eingaben_text` in das Schritt-Dictionary (`neuer_schritt()`), nicht aus einem Mitschreiben der
  Eingabe; so steht im Protokoll, was der Ablauf meint, etwa „Maus über „Neues Spiel“, Enter“.

## Auslegungen aus Phase 2

Vom Agent bei T011 bis T015 ausgelegt, von Claude geprüft und angenommen (2026-10-28):
- Die Beschreibungen von `titel.02` und `titel.03` stehen nicht im Vertrag; die Tabelle in
  ablaeufe.md hat keine Spalte dafür. Sie lauten „„Weiterspielen“ wählen, ohne Spielstand nicht
  verfügbar“ und „„Beenden“ wählen, ohne auszulösen“, Wortlaut der Einträge aus `TitleTexts`.
  Fest war nur `titel.01`, „Start, der Communicator fährt herein“ (CHK030).
- Die Vorbereitung endet, sobald der neue Titel im Baum steht, nicht erst, wenn das Menü steht. Die
  Fahrt herein gehört so zu Schritt 01, und SC-001 bleibt messbar. Hat der erste Schritt eines
  Ablaufs Eingaben, wartet der Läufer vorher, bis der Communicator steht. Auch der erste Ablauf
  lädt den Titel neu, damit beide Abläufe gleich beginnen.
- Findet der Fahrer ein Ziel nicht, gibt `eingaben` den Text „Ziel nicht gefunden: …“ zurück, und
  der Schritt scheitert sofort, ohne die Höchstzeit abzuwarten.
- `neuer_schritt()` nimmt `eingaben_text` als dritten Parameter; die Tests aus Phase 1 sind
  angepasst, die Fixtures unverändert.
- Kennungen des Fahrers ohne Vorbild im Spiel: `slot_<nummer>` für Zeilen der Liste, `leave` für
  den Knopf „Zum Hauptmenü“.
- Der Fahrer gibt jedem neuen Titel einen `quit_callback`, der nur mitzählt. So lässt sich „nicht
  ausgelöst“ prüfen, ohne dass die App mitten im Lauf zugeht.
- Meldungen während der Vorbereitung zählen zum ersten Schritt des Ablaufs.
- Ist der Ordner nicht beschreibbar, gibt die Startszene bis Phase 4 die Meldung mit `printerr()`
  aus und beendet mit Code 1.
- Prüfbefehl in export.md: `LC_ALL=C grep -a -c` statt `grep -c`, sonst keine Ausgabe.
- **Neues Restrisiko für Phase 3:** `Control.set_default_cursor_shape()` schickt Godot eine eigene
  Mausbewegung an der echten Zeigerposition, am Filter vorbei (`control.cpp` 4.7.2). Das passiert,
  wenn sich die Zeigerform eines Controls unter dem echten Zeiger ändert. `SaveList._refresh_rows()`
  tut das; der echte Zeiger könnte so in der Liste eine Zeile wählen. Im Titel tritt es nicht auf.
  Phase 3 prüft es mit dem Ablauf `laden`.
- **Beobachtung Claude bei T016:** Schließen etwa 0,4 s nach dem Start, bevor der Läufer läuft,
  wurde nicht beachtet; der Lauf lief durch. Zwischen 0,6 und 0,75 s brach er wie verlangt ab.
  Vermutlich kommt die Anfrage, bevor Godot sie annehmen kann; es betrifft nicht den Lauf selbst.

## Für Klaus zum Aufräumen

Die Versuche des Agents haben unter `~/Library/Application Support/Godot/app_userdata/` die Ordner
`Probe` und `Probe Selbsttest` angelegt; sie gehören zu keinem Projekt und können weg.
