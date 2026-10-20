# Lernnotizen: Start bis zum Hauptmenü

Zu jeder `[A]`-Task eine Notiz: welche Godot-Konzepte vorkommen und warum es so gebaut ist
(Verfassung, Grundsatz II). Geschrieben vom Godot-Agent, von Claude nach jeder Phase eingetragen.

## Phase 2: Grundlagen

### T009 Projekteinstellungen (`src/project.godot`)

- `project.godot` speichert nur Werte, die vom Standard abweichen. `stretch/aspect = "keep"` ist
  Standard und steht deshalb nicht drin.
- Stretch-Modus `viewport`: Godot zeichnet alles in 640 × 360 und vergrößert erst das fertige
  Bild. `integer` lässt dabei nur ganze Faktoren zu, der Rest wird schwarz.
- Die Snap-Optionen runden Positionen und Eckpunkte auf ganze Pixel. Sonst landen Glyphen und
  Texturen auf halben Pixeln und werden ungleichmäßig.
- Folge für das ganze Projekt: Auch die Zeitleisten-Demo läuft jetzt in 640 × 360 mit dem neuen
  Theme und wirkt grob. Das ist gewollt, die Demo löst später 10-01 ab.

### T010 Farben als Konstanten (`src/ui/ui_palette.gd`)

- `class_name` macht `UiPalette` im ganzen Projekt bekannt. `const` hängt an der Klasse, nicht
  an einem Objekt: `UiPalette.TUSCHE` geht ohne Autoload und ohne `new()`.
- Eine `.tres`-Datei kann keine GDScript-Konstanten lesen. Im Theme stehen deshalb die
  Zahlenwerte, eine Probe hat jede Theme-Farbe gegen die Palette geprüft.

### T011 Import der Schriften (`src/assets/fonts/*.import`)

- Die `.ttf` ist die Quelle, das Ergebnis liegt im Cache `.godot/imported/`. Wie importiert wird,
  steht in der `.import` unter `[params]`. Deshalb wird die `.import` committet und `.godot/`
  nicht.
- Antialiasing aus: jedes Pixel Tinte oder leer. Hinting aus: Die Schrift ist schon aufs
  Pixelraster gezeichnet und soll nicht verformt werden. Subpixel aus: Jede Glyphe beginnt auf
  einem ganzen Pixel.

### T012 Theme (`src/ui/computerladen_theme.tres`)

- Eine Theme-Variante wie `MenuRow` (Basis `Button`) ist ein benannter Satz Theme-Werte. Ein
  Node wählt sie über `theme_type_variation`, alles Übrige erbt er vom Basistyp.
- `FontVariation` legt Einstellungen über eine Schriftdatei, ohne sie zu kopieren:
  `variation_opentype = {2003265652: 500}` setzt die Achse `wght` (der Schlüssel ist der
  OpenType-Tag als Zahl), `spacing_glyph` die Laufweite. Doto ohne Variation stünde auf Gewicht
  900 und wäre zu fett.
- Ein einziges `StyleBoxEmpty` gilt für alle sechs Button-Zustände; wer es ändert, ändert alle.
- `line_spacing` rechnet Godot nur zwischen zwei Zeilen. Beim umbrechenden Hinweis liegen die
  Zeilen mit `-1` 10 Pixel auseinander wie beim Textstil `klein`.
- „Mittig“ kann kein Theme setzen. Das ist eine Eigenschaft des Labels und steht an der
  Kopfzeile in `main_menu.tscn`.

### T014 Resource als Datenklasse (`src/scenes/title/menu_entry.gd`)

- `MenuEntry extends Resource` mit `@export`-Feldern: Godot zeigt die Felder im Inspector und
  speichert sie in einer Szene, ab T024 als Unter-Resource im Titelbildschirm. Tests bauen
  Einträge mit `MenuEntry.new()`.
- `StringName` (`&"quit"`) vergleicht schneller als `String` und passt zu festen Kennungen.

### T015 Fokus-System und `_draw()` (`src/scenes/title/main_menu.gd`)

- Godots Fokus ist schon eine Auswahl, in der genau ein Control gewählt ist. Tab und
  Pfeiltasten verschieben ihn, `ui_accept` (Enter, Leertaste) drückt den fokussierten Button. Das
  Menü hört nur auf `focus_entered`.
- Ein gesperrter Button behält den Fokus, sendet aber nie `pressed`. „Nicht verfügbar“ lässt
  sich also wählen, aber nicht auslösen, ohne eigenen Code.
- `call_deferred`: In `_ready()` hängen die Buttons erst im Baum, der VBoxContainer ordnet sie
  später im selben Frame an. Die Startauswahl läuft danach, damit `row_rect` stimmt.
- `_draw()` läuft nicht jedes Bild. Godot merkt sich die Zeichenbefehle und malt erst nach
  `queue_redraw()` oder einer Größenänderung neu.
- Was ein Node selbst malt, liegt unter seinen Kindern. Das Menü malt Papier und Gelb, die
  durchsichtigen Buttons schreiben nur den Text darauf. Innerhalb von `_draw()` bestimmt die
  Reihenfolge die Ebene: erst der Schatten, dann das Papier.

### T016 Eigener Hinweis (`src/scenes/title/menu_hint.gd`)

- Ein `PanelContainer` nimmt die Größe seines Kindes plus `content_margin` an.
- Die Falle ist das umbrechende Label: Seine Höhe hängt von seiner aktuellen Breite ab. Erst die
  Breite setzen, dann den Text, sonst ist der Hinweis beim ersten Zeigen viel zu hoch.
- `reset_size()` schrumpft auf die Mindestgröße. Erst danach wird `global_position` gesetzt,
  weil die Lage von der Breite abhängt. `grow_horizontal = Begin`: Wächst der Hinweis, dann nach
  links, und die rechte Kante bleibt an der Zeile.
- Der pixelschatten ist ein L aus zwei Streifen, denn `_draw()` malt nach der Stylebox; ein
  volles Rechteck würde das Feld überdecken.

### T017 Tests (`src/test/test_main_menu.gd`)

- GUT kann auch in `before_each` warten (`await wait_process_frames(1)`); ein Frame reicht für
  `call_deferred` und das Anordnen.
- Im Code erzeugte Nodes haben keinen Owner, deshalb `find_children(..., false)`.
- `watch_signals` mit `get_signal_parameters` prüft nicht nur, dass gemeldet wurde, sondern auch,
  was.

### Korrekturen aus dem Review (T012, T016)

- `content_margin` zählt von der Außenkante bis zum Inhalt, die Kontur eingeschlossen. CSS-`padding`
  beginnt erst innerhalb der Kontur. Aus „Kontur 1, Innenabstand 4“ im Style-Guide wird in Godot
  deshalb `content_margin = 5`; der Kasten des Hinweises ist damit höchstens 140 breit, sein Text
  130.
- Eine Laufweite gehört zur Schrift, nicht zur Größe. Der Untertitel braucht deshalb eine eigene
  `FontVariation` (Pixelify 400 mit `spacing_glyph = 1`); beide Varianten verweisen auf dieselbe
  `.ttf`.

### Korrekturen nach der Sichtprobe (T012, T016)

Die erste Sichtprobe (T013) hat gezeigt: Bei 12 Pixeln kleben die Wörter, Pixelify Sans und Doto
sind bei 8 nicht lesbar. Vier Notizen oben sind damit überholt: das Gewicht 500 (jetzt 400) und
`line_spacing = -1` bei T012, bei den Korrekturen aus dem Review die Breiten 140 und 130 (jetzt 160
und 150) und die eigene `FontVariation` des Untertitels (er steht jetzt in `drucker`).

- `spacing_space` gibt nur dem Leerzeichen ganze Pixel dazu, die Buchstaben bleiben, wie sie sind.
  Das Leerzeichen von Pixelify ist bei 10 und 12 nur 2 Pixel breit. Im Menü wird es mit
  `spacing_space = 2` 4 breit, in Text und Hinweis mit 1 3 breit.
- Der Wert gehört zur `FontVariation`, nicht zur Theme-Variante. Standardschrift und `HintLabel`
  teilen sich `FontVariation_text`, eine Stelle ändert also beide.
- In Godot 4.7.2 kommt `spacing_space` nicht zur Laufweite dazu, es ersetzt sie beim Leerzeichen.
  Bei 0 bekommt das Leerzeichen `spacing_glyph` wie jeder Buchstabe, die letzte Glyphe eines Textes
  bekommt gar keine Laufweite. In CSS bekommt das Leerzeichen beides. Für dieselbe Wirkung ist
  `spacing_space` deshalb die Summe aus Laufweite und Wortabstand, etwa 1 + 1 = 2.
- Grundschnitt 400: Pixelify ist eine variable Schrift, Achse `wght` von 400 bis 700, Standard 400.
  Bei 400 gelten die Konturen, wie sie gezeichnet sind. Jedes andere Gewicht wird gerechnet, und
  jede Kante verschiebt sich um Bruchteile eines Pixels. Ohne Kantenglättung wird jede Kante für
  sich gerundet, gleich gemeinte Striche werden mal 1, mal 2 Pixel breit.
- Kein festes Pixelraster: Mit `subpixel_positioning` aus rundet Godot jeden Vorschub auf ganze
  Pixel und trägt den Rest weiter. Ein „i“ ist bei 12 deshalb mal 2, mal 3 Pixel breit. Das liegt
  an der Schrift; der Wortabstand hilft nur bei den Leerzeichen.
- `line_spacing` kommt zur Zeilenhöhe dazu. Pixelify ist bei 10 Pixeln 13 hoch (Ascent 10,
  Descent 3), mit 1 liegen die Zeilen 14 auseinander. Zwei Zeilen sind 27 hoch, der Kasten mit je
  5 Rand 37.
- Der Untertitel steht in `drucker`, denn Pixelify verformt bei 10 Pixeln Großbuchstaben und
  Ziffern. Eine `FontVariation` enthält nur, was zur Schrift gehört: Datei, Gewicht, Laufweite.
  Größe, Farbe und Schatten trägt jede Theme-Variante selbst. Deshalb zeigen `MenuHeader`,
  `Subtitle` und `VersionLine` auf dieselbe `FontVariation_drucker`, und eine Änderung an `drucker`
  gilt für alle drei, wie bei einem Textstil im Style-Guide.
- Eine `[sub_resource]`, auf die nichts mehr zeigt, legt Godot beim Laden trotzdem an. Erst beim
  Speichern aus dem Editor fiele sie weg; in einer von Hand geschriebenen Datei bleibt sie liegen.
  `FontVariation_subtitle` ist deshalb gelöscht.
- Doto hat einen festen Vorschub von 6 Pixeln, mit Laufweite 7; die letzte Glyphe bekommt keine
  Laufweite. Der Untertitel ist also 32 × 7 + 6 = 230 breit. Bei Pixelify lässt sich die Breite so
  nicht abzählen, weil jeder Vorschub einzeln gerundet wird.

## Phase 3: App bis zum Titelbildschirm (US1)

### T024 Titelbildschirm (`src/scenes/title/title_screen.tscn`, `title_screen.gd`)

- Szene aus Szenen: `MainMenu` und `MenuHint` sind Instanzen. An einer Instanz steht nur, was
  abweicht, hier Lage und `entries`.
- Die vier `MenuEntry` sind Unter-Resources der Titelszene, denn die Daten gehören zum
  Titelbildschirm, nicht zum Menü. `available = false` steht nicht in der Datei: Godot speichert
  nur, was vom Standardwert im Skript abweicht.
- Die Zeile `[connection signal="selection_changed" … method="_on_main_menu_selection_changed"]`
  schreibt auch der Editor, wenn man im Node-Dock unter „Signale“ verbindet. Verbindungen aus der
  Szene stehen, bevor `_ready()` läuft; deshalb erreicht die zeitversetzte Startauswahl des Menüs
  schon den Hinweis. Menü und Hinweis kennen einander nicht, der Titelbildschirm vermittelt.
- Freie Lage oder Container: Kinder eines einfachen `Control` stehen über ihre Offsets
  (`layout_mode = 0`), im `VBoxContainer` ordnet der Container (`layout_mode = 2`), Offsets wirken
  dort nicht.
- ×2 ohne `scale`: Der Hintergrund ist fest 640 × 360 und streckt die 320 × 180, das Logo bekommt
  `custom_minimum_size` 282 × 54. Mit `scale` rechneten Container weiter mit der kleinen Größe.
- Der Einzug von 4 für den Untertitel ist eine `StyleBoxEmpty` mit `content_margin_left = 4` als
  Override: Ein Label zeichnet seinen Text innerhalb seiner Stylebox, das wirkt wie Padding.
- Die Versionszeile hängt unten links (`anchors_preset = 2`) und wächst nach oben
  (`grow_vertical = 0`); ihre Unterkante bleibt bei 354, wie hoch die Schrift auch ist. Den Text
  setzt `_ready()` aus `ProjectSettings`, im Editor ist die Zeile deshalb leer.

### T025 Tests (`src/test/test_title_screen.gd`)

- Eine statische Funktion ruft man an der Klasse auf: `TitleScreen.version_text("0.1")`. Dafür
  braucht es keine Instanz, keinen Baum und kein Warten auf Frames.

### T026 GameWindow (`src/core/game_window.gd`, `project.godot`)

- Autoload: `GameWindow="*res://core/game_window.gd"` legt den Node beim Start unter `/root` an.
  Das Skript hat kein `class_name`, sonst verdeckte der Klassenname den Autoload.
- `_unhandled_input` kommt zuletzt: Erst nimmt die Oberfläche, was sie braucht (Fokus, Enter),
  dann das globale Kürzel. Die Taste steht als Aktion in `[input]` und lässt sich unter
  Projekteinstellungen → Eingabezuordnung ändern; eine physische Taste liegt auf jeder Belegung
  an derselben Stelle.
- `Window.min_size` rechnet in Bildschirmpixeln, 640 × 360 sind auf Retina 320 × 180 Punkte.
- `size_changed` meldet die Größe des Viewports, nicht die des Fensters. Bei Stretch `viewport`
  bleibt der Viewport 640 × 360, das Signal kommt also nie. Den Moduswechsel erkennt deshalb
  `_process()` durch Vergleich mit dem vorigen Bild.
- Zwei Wege, zwei Zeitpunkte: Beim grünen Knopf meldet Godot das Fenster erst nach dem Übergang,
  nach dem Kürzel sofort, während die Animation noch läuft. `maxi(jetzt, umgeschaltet + 1000)`
  deckt beides ab. `Time.get_ticks_msec()` hängt nicht an Bildrate oder `time_scale`.
- `Vector2i / Vector2i` teilt beide Achsen ganzzahlig; `@warning_ignore("integer_division")` sagt
  Godot, dass das Abschneiden gewollt ist. Headless zeigt Godot solche Warnungen nur mit `-d`.

### T027 Tests (`src/test/test_game_window.gd`)

- `best_factor` ist eine reine Funktion: Alles kommt über Parameter, nichts wird abgefragt. Sie
  läuft deshalb ohne Fenster. Der Test lädt das Skript per `preload`, weil der Autoload keinen
  `class_name` hat.

### T028 Projekteinstellungen

- `window/size/mode = 3` gilt ab dem Start, auch für F5 im Editor.
- `config/icon` lädt Godot zur Laufzeit direkt als Bild, an der Importierung vorbei, für Fenster
  und Dock. In der exportierten Mac-App gewinnt das Symbol im Bundle, also das Liquid-Glass-Symbol.

### Schriftwechsel auf Ark Pixel (Nachtrag zu T011 und T012)

- Die Importwerte stehen in der `.import` unter `[params]`. Godot 4.7 schlägt für Schriften
  Kantenglättung, Hinting und Subpixel vor; für Pixelschriften kommen alle drei auf 0.
- Ark Pixel ist statisch, jede Größe eine eigene Datei. Eine `FontVariation` hätte nichts
  abzuwandeln, deshalb zeigt das Theme direkt auf die Datei. `drucker` bleibt eine
  `FontVariation`, weil Doto Gewicht und Laufweite braucht.
- Eine Pixelschrift nur in ihrer Entwurfsgröße: Dann liegt jeder gezeichnete Pixel auf einem
  Bildschirmpixel. WOFF2 ist nur gepacktes OpenType und ergibt dieselbe `FontFile`.
- Godots Standard-Theme gibt Labels `line_spacing` 3. Die 0 muss deshalb ausdrücklich im Theme
  stehen; Ark 10 ist 11 + 3 = 14 hoch, die Zeilen liegen 14 auseinander.

### Nachtrag zu T016 (`menu_hint.gd`)

- `instantiate()` setzt die Werte aus den Szenendateien, `_ready()` läuft erst danach. Was
  `_ready()` setzt, gewinnt also gegen jede `.tscn`. `layout_mode = 0` an einer Instanz setzt
  Anker und Wuchsrichtung beim Laden zurück; deshalb setzt der Hinweis seine Wuchsrichtung jetzt
  selbst.

### T029 Export-Preset (`src/export_presets.cfg`)

- Die Datei gehört zum Projekt und wird versioniert. `[runnable_presets]` legt das ausführbare
  Preset je Plattform fest, `[preset.0]` das Allgemeine (`export_path` relativ zu `src/`, Filter),
  `[preset.0.options]` alle Optionen der Plattform, auch die mit Standardwert.
- Geheimes schreibt Godot nie hierher: Optionen mit `PROPERTY_USAGE_SECRET` (Zertifikat, Passwort,
  Beglaubigungs-Zugänge, Skript-Schlüssel) landen in `.godot/export_credentials.cfg`, das nicht
  versioniert wird. Deshalb darf `export_presets.cfg` ins Repo.
- Godot schreibt die Datei nur beim Speichern aus dem Export-Dialog. Der Agent hat sie in einer
  Wegwerf-Kopie per kleinem `EditorExportPlugin` von Godot selbst schreiben lassen, statt das
  Format zu raten.
- Ad-hoc-Signatur: signiert, aber ohne Apple-Zertifikat. Auf dem eigenen Mac startet die App, für
  die Weitergabe braucht es Developer ID und Beglaubigung (11-03). Universal heißt: eine
  ausführbare Datei mit x86_64 und arm64, prüfbar mit `lipo -info`.
- Zwei Symbole: Aus `application/liquid_glass_icon` macht `actool` aus Xcode `Assets.car`
  (`CFBundleIconName`), aus `application/icon` baut Godot `icon.icns` als Ersatz für ältere
  Systeme. Die `.gdignore` im `.icon` hält den Ordner aus dem Import, `actool` liest ihn trotzdem.
- `import_etc2_astc` lässt den Importer VRAM-komprimierte Texturen auch als ETC2/ASTC erzeugen;
  Apple-Silicon braucht sie, deshalb verlangt der Export für `arm64` und `universal` die
  Einstellung. Unsere Texturen sind verlustfrei, an ihren `.import` ändert sich nichts.
- `exclude_filter` ist eine kommagetrennte Liste von Mustern; `*` deckt auch `/` ab. Mit den
  Quelldateien fallen ihre abgeleiteten Dateien weg (`.gdc`, `.scn`, `.import`).

### T032 Beenden (`title_screen.gd`, `title_screen.tscn`), vorgezogen aus Phase 4

- Signal statt Aufruf: `MainMenu` meldet nur `entry_activated(id)` und weiß nicht, was „quit“
  bedeutet. Was geschieht, entscheidet `TitleScreen._on_main_menu_entry_activated`. Deshalb kann
  ein Test das Menü auslösen, ohne dass etwas endet.
- `get_tree().quit()` setzt nur eine Marke; das Spiel endet am Ende des laufenden Bilds, mit
  Exit-Code 0.
- Für Klick, Enter und Leertaste braucht es keinen Code: Ein `Button` sendet `pressed` bei einem
  Linksklick und, wenn er den Fokus hat, bei der Aktion `ui_accept`. Ausgelöst wird beim
  Loslassen, also einmal je Tastendruck; ein gesperrter Button sendet nie.
- Cmd+Q und der rote Knopf laufen über die Schließen-Anfrage: Jeder Node bekommt
  `NOTIFICATION_WM_CLOSE_REQUEST`, dann beendet der SceneTree, weil `auto_accept_quit` an ist.

### T033 Tests (`test_main_menu.gd`)

- `watch_signals` hängt GUT an alle Signale; `assert_signal_emit_count(…, 1)` prüft „genau
  einmal“, `assert_signal_emitted_with_parameters` den Inhalt.
- Erst der Gegentest auf einem nicht verfügbaren Eintrag zeigt, dass `activate_selected()` die
  Verfügbarkeit prüft; ein Menü, das immer meldet, bestünde den ersten Test allein.
- `watch_signals` steht nach `select()`, damit nur zählt, was der Act-Schritt auslöst.

## Phase 5: Menü mit Maus und Tastatur (US3)

### T036 Maus und Fokus (`main_menu.gd`)

- `button.mouse_entered.connect(button.grab_focus)` verbindet das Signal direkt mit einer Methode,
  ohne eigene Funktion. Ein Gegenstück für `mouse_exited` gibt es bewusst nicht, sonst ginge die
  Auswahl verloren, sobald die Maus das Menü verlässt.
- Kopfzeile und Lochränder brauchen keinen Code: Die Kopfzeile ist ein Label ohne Fokus, die
  Lochränder gehören zum Menü selbst. Ein Klick auf ein Control ohne Fokus nimmt niemandem den
  Fokus weg.
- Pfeil hoch und runter (`ui_up`, `ui_down`) folgen `focus_neighbor_top` und
  `focus_neighbor_bottom`, Tab und Shift+Tab (`ui_focus_next`, `ui_focus_prev`) folgen
  `focus_next` und `focus_previous`. Ist nichts gesetzt, sucht Godot selbst; am Ende bliebe der
  Fokus stehen oder spränge zu einem anderen Element. `_link_ends()` verbindet deshalb nur die
  beiden Enden. Im Code gebaute Buttons heißen `@Button@5` und ähnlich, der Pfad kommt deshalb aus
  `get_path_to()`.
- Rechtsklick: Erst kommt das Signal `gui_input`, dann `_gui_input`, dann die eigene Verarbeitung
  des Buttons. `accept_event()` beendet diese Kette. Bei `.bind(index)` kommen erst die Argumente
  des Signals, dann die gebundenen.

### T037 Mauszeiger

- `mouse_default_cursor_shape` hat jedes Control; steht die Maus darüber, zeigt das System diesen
  Zeiger ohne weiteren Code. Die Hand gilt nur über dem Button, auf den Lochrändern bleibt der Pfeil.

### T038 Tests (`test_main_menu.gd`)

- `viewport.push_input(ereignis)` ist derselbe Eingang wie für echte Tastendrücke. So prüfen die
  Tests auch, dass Tab wirklich `ui_focus_next` ist, nicht nur `select()`.
- GUTs Oberfläche liegt im Haupt-Viewport und schluckt Mausklicks; ein eigener `SubViewport` hat
  eigene Eingabe und eigenen Fokus. Ein fremder Button auf der Bühne beweist, dass die Enden
  wirklich verbunden sind: Ohne `_link_ends()` sprang Pfeil hoch zu ihm.
- Gegenproben in einer Wegwerf-Kopie: Jede entfernte Zeile (Rechtsklick, Enden, Tab-Nachbarn,
  Mauszeiger) ließ genau den zugehörigen Test fallen.

## Phase 6: Noch nicht verfügbare Einträge (US4)

### T040 Darstellung „nicht verfügbar“ (`computerladen_theme.tres`, `main_menu.gd`)

- Ein Button hat sechs Schriftfarben, je eine für Normal, Fokus, Überfahren, Gedrückt, Überfahren
  und gedrückt, Gesperrt. Welche gilt, entscheidet `get_draw_mode()`, und „gesperrt“ geht vor
  allen anderen Zuständen. Eine einzige Theme-Zeile (`font_disabled_color`) reicht deshalb für
  „in Ruhe wie ausgewählt“.
- Eine `.tres` kann `UiPalette` nicht lesen; der Farbwert steht als Zahl darin. Die Schreibweise
  liefert Godot selbst: `var_to_str(UiPalette.GEHAEUSE_DUNKEL)`.
- Den Pfeil malt das Menü selbst, das Theme erreicht ihn nicht. `_draw()` wählt seine Farbe nach
  `entry.available`; es läuft bei jeder Auswahländerung neu, weil `queue_redraw()` kommt.

### T041 Tests (`test_main_menu.gd`)

- Der Gegentest aus T033 deckt jetzt alle drei gesperrten Einträge ab, statt gedoppelt zu werden.
- Die gedämpfte Schrift prüft der Test über öffentliche Schnittstellen: `get_draw_mode()` zeigt
  `DRAW_DISABLED`, `get_theme_color(&"font_disabled_color")` liefert `gehaeuse-dunkel`, genau wie
  der Button sie beim Zeichnen nimmt. Der Vergleich mit `UiPalette` sichert, dass Theme und Pfeil
  dieselbe Farbe behalten.
- Den Pfeil prüft kein Test: Headless gehen die Zeichenbefehle an einen Renderer ohne Bild, und
  kein GDScript-API liest sie zurück. Ein Spy auf eine interne Funktion prüfte die Umsetzung statt
  des Ergebnisses. Den Pfeil prüft Klaus mit dem Auge (T042).
