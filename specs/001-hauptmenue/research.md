# Recherche: Start bis zum Hauptmenü

Grundlage: [spec.md](spec.md), [Verfassung](../../.specify/memory/constitution.md), Style-Guide.
Godot-Stand: 4.7.2. Namen, Typen und Standardwerte stammen aus der Klassenreferenz, die das
installierte Godot mit `--doctool` ausgibt; Beschreibungen aus der Doku 4.7
(docs.godotengine.org/en/4.7). Ein Verhalten wurde mit einer Probe in Godot 4.7.2 geprüft (R9).

## R1 Bildschirm und Skalierung

- **Entscheidung:** Basisgröße 640 × 360 (`display/window/size/viewport_width`/`_height`),
  `display/window/stretch/mode = "viewport"`, `stretch/aspect = "keep"`,
  `stretch/scale_mode = "integer"`, `display/window/dpi/allow_hidpi = true` (Standard). Im
  macOS-Export `display/high_res = true`. Texturfilter Nearest
  (`rendering/textures/canvas_textures/default_texture_filter = 0`),
  `rendering/2d/snap/snap_2d_transforms_to_pixel` und `snap_2d_vertices_to_pixel` an.
- **Begründung:** Die Godot-Doku („Multiple resolutions“) empfiehlt für Pixel-Art genau diese
  Kombination; bei `integer` füllt Godot den Rest mit schwarzen Rändern. Der Style-Guide schreibt
  dasselbe vor. Ohne `high_res` rendert macOS in Punkten und vergrößert unscharf.
- **Alternativen:** `canvas_items` (rechnet in Fensterauflösung, nicht pixelgenau),
  `fractional` (krumme Faktoren) – beide verstoßen gegen den Style-Guide.

## R2 Vollbild und Fenster unter macOS

- **Entscheidung:** Start in `MODE_FULLSCREEN` (`display/window/size/mode = 3`). Der grüne
  Fensterknopf wirkt von selbst. Für Ctrl+Cmd+F gibt es die Eingabe-Aktion `toggle_fullscreen`,
  die zwischen `MODE_FULLSCREEN` und `MODE_WINDOWED` umschaltet. Ein Autoload `GameWindow`
  bemerkt den Wechsel ins Fenster und setzt dann die Fenstergröße auf den größten ganzzahligen
  Faktor der Basisgröße, der samt Titelleiste in den nutzbaren Bereich des Bildschirms passt, auf
  dem das Fenster gerade liegt (`DisplayServer.window_get_current_screen()`), und zentriert das
  Fenster. Gestartet wird auf dem Hauptbildschirm (`display/window/size/initial_screen`, Standard). Die Mindestgröße setzt er mit `get_window().min_size`.
- **Begründung:** `MODE_FULLSCREEN` nutzt unter macOS einen eigenen Schreibtisch, genau wie der
  grüne Knopf; beide Wege verhalten sich also gleich. Ob macOS Ctrl+Cmd+F schon selbst über das
  Fenstermenü abfängt, ließ sich weder aus der Doku noch aus dem Quelltext sicher klären. Die
  eigene Aktion ist trotzdem unschädlich: Fängt macOS das Kürzel ab, kommt es bei Godot nicht an.
  Geprüft wird das im Quickstart.
- **Offen zu prüfen:** Die Doku warnt, dass ein um 1 Pixel verkleinertes Vollbild den
  Skalierungsfaktor senken kann, und rät dann zu `MODE_EXCLUSIVE_FULLSCREEN`. Tritt das unter
  macOS auf (SC-004), wird auf exklusives Vollbild gewechselt.
- **Alternativen:** `MODE_EXCLUSIVE_FULLSCREEN` von Anfang an (verhält sich anders als der grüne
  Knopf); eine feste Fenstergröße über `window_width_override` (passt nicht auf jeden Bildschirm).

## R3 Startgrund statt Godot-Logo

- **Entscheidung:** `application/boot_splash/show_image = false`,
  `application/boot_splash/bg_color` und `rendering/environment/defaults/default_clear_color` in
  `anzeige-grund` (#0d1716). Der Style-Guide bekommt dafür einen Eintrag „Startgrund“.
- **Begründung:** FR-003 verbietet ein fremdes Logo. `anzeige-grund` ist die dunkelste Farbe des
  Guides und liegt nah an den schwarzen Rändern der Skalierung.
- **Ränder:** Die Ränder der ganzzahligen Skalierung zeichnet Godot schwarz. Der Unterschied zu
  `anzeige-grund` ist kaum sichtbar und bleibt so (Review, CHK019).
- **Alternativen:** `nacht` (passt zum Abendhimmel, setzt sich aber sichtbar von den schwarzen
  Rändern ab); ein eigenes Startbild mit Logo (lohnt bei unter 3 Sekunden Ladezeit nicht).

## R4 macOS-Export

- **Entscheidung:**
  - Export-Vorlagen 4.7.2 über „Editor → Export-Vorlagen verwalten“ installieren (1,3 GB).
  - Preset „macOS“ mit `binary_format/architecture = universal` (die offiziellen Vorlagen
    enthalten nur Universal-Binaries), Codesign „Built-in (ad-hoc only)“, Notarisierung aus,
    `display/high_res = true`.
  - `application/bundle_identifier` legt Klaus fest, im Reverse-DNS-Format einer eigenen
    Domain (`de.<domain>.dercomputerladen`).
  - Exportpfad `../build/macos/Der Computerladen.app`, `build/` kommt in die `.gitignore`.
  - Kommandozeile: `--export-release "macOS" "../build/macos/Der Computerladen.app"`; der Pfad
    gilt relativ zum Projektordner `src/`, nicht zum Aufrufort.
- **Begründung:** Ad-hoc-Signatur ist laut Doku der Weg ohne Developer-ID. Auf dem eigenen Mac
  entsteht keine Quarantäne-Markierung, also keine Gatekeeper-Warnung (SC-002). Vertrauliche
  Optionen speichert Godot in `.godot/export_credentials.cfg`, das nicht versioniert ist;
  `export_presets.cfg` ist laut Doku versionierbar und wird trotzdem vor dem Commit angesehen
  (Verfassung, Arbeitsweise).
- **Alternativen:** Signieren mit Developer-ID und Beglaubigen sowie Ausgabe als `.zip` oder
  `.dmg`, beides erst für die Weitergabe mit 11-03.

## R5 App-Symbol

- **Entscheidung:**
  - Der Monitor aus dem Ladenschild wird aufs Bildraster gebracht und ganzzahlig auf eine Fläche
    von 1024 × 1024 nach Apples Symbolraster für macOS vergrößert. Das Ergebnis geht als PNG in
    `application/icon` des Exports und in `application/config/icon`.
  - Dazu kommt ein Liquid-Glass-Symbol aus Icon Composer in `application/liquid_glass_icon`.
    Das braucht Xcode 26 oder neuer; vorhanden sind macOS 27.0.1 und Xcode 27.1.
  - Grundfläche `nacht` (Review, Entscheidung von Klaus); `kassenrot` bedeutet im Style-Guide
    Geld und Gefahr. Der Style-Guide bekommt dazu einen Abschnitt App-Symbol.
- **Begründung:** Godot 4.7 unterstützt Liquid-Glass-Symbole beim Export unter macOS. Ältere
  Symbolformate stellt macOS seit Version 26 teils in einem grauen Rahmen dar.
- **Alternativen:** neues Leonardo-Motiv oder Godot-Symbol (Klärung, Frage 5: Monitor gewählt).

## R6 Rasterfassung von Titelbild und Logo

- **Befund:** Die gemalten Pixel in T-01 und im Logo sind unterschiedlich groß. Gemessen wurden
  Lauflängen gleicher Farbe von häufig 2 bis 12 Pixeln, beim Titelbild kommen JPEG-Artefakte
  dazu. Nearest Neighbor nach Schritt 2 der Nachbearbeitung im Style-Guide würde zufällige Pixel
  herausgreifen.
- **Entscheidung:**
  - Verkleinern per Flächenmittel auf die Endgröße, dann auf die Hauptpalette rechnen (ohne
    Dithering), dann von Hand aufräumen.
  - T-01: erst auf 1920 × 1080 beschneiden (je 4 Pixel oben und unten), dann auf 320 × 180
    Bildpixel.
  - Logo: Faktor 6 auf etwa 142 × 27 Bildpixel, angezeigt ×2 wie die Szene, also auf dem
    Bildraster. Bricht die Schrift dabei auf, Ausweichlösung Faktor 3 aufs Oberflächenraster.
  - Werkzeuge: `sips` (macOS) zum Dekodieren, Python-Skripte nur mit Standardbibliothek in
    `tools/raster/`. Den groben Feinschliff (Einzelpixel, Farbreste) macht Klaus in Pixelorama
    (frei) oder Aseprite; der volle Feinschliff nach Schritt 4 kommt später (Review).
  - Abnahme: FR-019 und SC-007 der Spec. Dass die Rasterfassung in dieses Feature gehört, hat
    Klaus im Review bestätigt.
  - Schritt 2 der Nachbearbeitung im Style-Guide wird entsprechend ergänzt.
- **Alternativen:** Nearest Neighbor (s. o.); Bilder neu erzeugen (kostet Tokens, löst das
  Rasterproblem nicht); ImageMagick oder Pillow (nicht installiert, neue Abhängigkeit).

## R7 Hauptpalette

- **Befund:** Der Style-Guide beschreibt die Hauptpalette, als Datei gibt es sie noch nicht.
- **Entscheidung:**
  - Jetzt erzeugen und einfrieren: 240 Farben per Median-Cut aus Stilanker C2, T-01 und C-01,
    dazu die 15 Oberflächenfarben und eine Transparenzfarbe.
  - Ablage als `docs/art/hauptpalette.gpl` (lesbar für Pixelorama, Aseprite und GIMP) und als
    Farbtafel `docs/art/hauptpalette.png`.
  - Ab dann wird jede Szene darauf gerechnet.
  - Der Style-Guide nennt als Quelle „den Stilanker und die ersten freigegebenen Szenen“. Das
    Cover ist keine Szene, aber im selben Stil freigegeben; der Wortlaut wird zu „Bilder“
    erweitert (CHK020).
- **Alternativen:** eine Palette je Bild (bricht die Stimmigkeit); Palette erst mit 10-02 (dann
  müsste T-01 später neu gerechnet werden).

## R8 Schriften

- **Entscheidung:**
  - Pixelify Sans und Doto von Google Fonts (SIL OFL 1.1), mit Lizenzdatei nach
    `src/assets/fonts/`. Die Dateinamen werden ohne eckige Klammern abgelegt.
  - Import-Einstellungen: `antialiasing` None, `hinting` None, `subpixel_positioning` Disabled,
    `generate_mipmaps` aus, `multichannel_signed_distance_field` aus.
  - Das Gewicht wird per `FontVariation.variation_opentype` gesetzt. Saira braucht der Titel
    nicht.
  - Vor dem Festzurren des Themes gibt es eine Sichtprobe bei 8, 10 und 12 Pixeln.
- **Begründung:** Im Stretch-Modus `viewport` wird Text in 640 × 360 gerastert und ganzzahlig
  vergrößert; Kantenglättung bliebe als graue Pixel sichtbar.
- **Alternativen:** eigene Bitmap-Schrift (genauer, aber erst zu bauen).

## R9 Menü: Auswahl, Fokus, nicht verfügbare Einträge

- **Befund (Probe mit Godot 4.7.2):** Ein `Button` mit `disabled = true` behält
  `focus_mode = FOCUS_ALL`, nimmt `grab_focus()` an, und die Suche nach dem Fokus-Nachbarn
  (`find_valid_focus_neighbor`) schließt ihn ein. Auslösen lässt er sich nicht.
- **Entscheidung:**
  - Ein `Button` je Eintrag; „nicht verfügbar“ heißt `disabled = true`.
  - Fährt die Maus über einen Eintrag, ruft er `grab_focus()` auf. So teilen Maus und Tastatur
    eine Auswahl (FR-011).
  - Der Umlauf oben und unten läuft über `focus_neighbor_top`/`focus_neighbor_bottom`.
  - Papier, hervorgehobene Zeile (`signalgelb`) und Pfeil zeichnet das Menü in `_draw()`; die
    Buttons selbst sind durchsichtig. Eine zusätzliche Fokuslinie gibt es im Menü nicht (FR-011).
  - Ein `Button` reagiert standardmäßig nur auf die linke Maustaste. Den Rechtsklick fängt das
    Menü über `gui_input` ab: Zeile fokussieren, nichts auslösen (FR-009).
  - Leertaste und Tab brauchen keinen eigenen Code: Godots Aktion `ui_accept` umfasst Enter und
    Leertaste, `ui_focus_next`/`ui_focus_prev` sind Tab und Shift+Tab. Die Probe zeigt, dass die
    Tab-Reihenfolge vom letzten zum ersten Eintrag umläuft.
  - Mauszeiger über `mouse_default_cursor_shape`: `CURSOR_POINTING_HAND` bei verfügbaren,
    `CURSOR_ARROW` bei nicht verfügbaren Einträgen (FR-018).
- **Alternativen:** eigene Auswahl-Logik neben dem Fokus-System (mehr Code und weniger
  Godot-Lernstoff); getrennte Stile für Überfahren und Fokus (zwei Hervorhebungen zugleich,
  verstößt gegen FR-011).

## R10 Eigener Hinweis statt eingebautem Tooltip

- **Befund:** Godots eingebaute Tooltips erscheinen nur beim Überfahren mit der Maus, und zwar
  nach `gui/timers/tooltip_delay_sec` (0,5 s). Eine Auswahl per Tastatur zeigt keinen.
- **Entscheidung:** eine eigene Hinweis-Komponente links neben der gewählten Zeile, gesteuert über
  das Auswahl-Signal des Menüs, für Maus und Tastatur gleich. Sie erscheint ohne Verzögerung und
  bleibt stehen, bis eine andere Zeile gewählt wird (FR-017). Ihr Aussehen kommt in den
  Style-Guide.
- **Alternativen:** eingebauter Tooltip (keine Tastatur); eine Hinweiszeile unten auf dem Papier
  (einfacher, aber nicht so, wie der Style-Guide Tooltips beschreibt).

## R11 Beenden

- **Entscheidung:** „Beenden“ ruft `get_tree().quit()` auf. Für Cmd+Q und das Schließen des
  Fensters ist kein eigener Code vorgesehen; Godot nimmt die Schließen-Anfrage standardmäßig an.
- **Offen zu prüfen:** Ob das App-Menü des Exports Cmd+Q schon mitbringt, ließ sich im
  Quelltext nicht eindeutig finden. Fehlt es im Quickstart, kommt in diesem Feature ein Eintrag
  „Der Computerladen beenden“ mit Cmd+Q über `NativeMenu` dazu.

## R12 Version und Hauptszene

- **Entscheidung:** `application/config/version = "0.1"`, Versionszeile „V0.1 · PROTOTYP“.
  `application/run/main_scene` zeigt auf den Titelbildschirm. Die Zeitleisten-Demo bleibt im
  Editor startbar.

## R13 Statisches Titelbild ohne SubViewport

- **Entscheidung:** Ein `TextureRect` zeigt die 320 × 180 große Textur genau ×2 auf 640 × 360.
  Den SubViewport, den der Style-Guide für Szenen vorsieht, braucht erst eine bewegte Szene
  (10-02).

## R14 Tests

- **Entscheidung:**
  - GUT 9.7.1 prüft die Menülogik (Reihenfolge, Verfügbarkeit, Startauswahl, Umlauf, Auslösen),
    den Fensterfaktor als reine Funktion und den Versionstext.
  - Darstellung, Vollbild, Symbol und Export werden nach dem Quickstart von Hand geprüft, weil
    der Headless-Modus kein Fenster und kein Bild hat.
  - Startprobe: `--headless --path src --quit-after 60` startet die Hauptszene ohne Fehler.

## R15 Anrede

- **Entscheidung:** Alle Texte im Spiel duzen den Spieler (Review, Entscheidung von Klaus). Das gilt
  über dieses Feature hinaus und kommt in den Style-Guide.
- **Alternativen:** „Sie“, wie in vielen Wirtschaftssimulationen der 90er.
