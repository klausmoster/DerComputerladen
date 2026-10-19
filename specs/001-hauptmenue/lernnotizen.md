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
