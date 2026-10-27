# Lernnotizen: Communicator als Steuerelement

Zu jeder umgesetzten Task die Godot-Konzepte und warum es so gebaut ist, an den Stellen im
Projekt. Bei `[A]`-Tasks schreibt der Agent die Notizen, Claude trägt sie je Phase hier ein; baut
Klaus eine Task selbst, schreibt Claude die Notiz beim Review. Abnahmen und Phasenprüfungen bauen
nichts und haben deshalb keine Notiz.

## Phase 2

### T004 `UiPalette.LCD`: eine Farbe nur für die Oberfläche

- `const LCD := Color("b8c4a8")` hängt an der Klasse wie die 15 anderen Farben. `UiPalette` wird
  nie instanziiert; `UiPalette.LCD` geht überall, ohne Autoload und ohne `new()`.
- `lcd` steht in `TOKENS`, aber nicht in der Hauptpalette `docs/art/hauptpalette.gpl`: Sie gibt es
  nur in der Oberfläche, nie in einem Bild, und die Palette bleibt eingefroren (R1).
- Ausnahmen gehören in den Test, nicht nur in einen Kommentar: `test_bilder.gd` nennt `lcd` in
  `NUR_OBERFLAECHE`, und `test_lcd_steht_nicht_in_der_hauptpalette` sichert, dass es so bleibt.
  Zusammen mit dem Test „jedes Bild nur in Farben der Hauptpalette“ heißt das: `lcd` kommt in
  keinem Bild vor.
- Die Kontraste rechnet `test_ui_palette.gd` nach WCAG aus den Konstanten nach
  (`srgb_to_linear()`, `get_luminance()`). Der Test vergleicht zweierlei: Jedes Paar liegt über
  seiner Regel, und der Wert stimmt auf ±0,005 mit dem Style-Guide überein. Ändert jemand den Wert
  von `lcd`, fällt beides auf.

### T005 Aufbau und Seiten: Seiten als Kinder einer Instanz

- `communicator.tscn` hat drei eigene Kinder: `Case` (Gehäuse), `Display` (Anzeige) und `Hint`
  (eine Instanz von `menu_hint.tscn`). Ein Bildschirm hängt seine Seiten in der eigenen Szene direkt
  unter die Instanz, wie die Probe `MainMenu` unter `Communicator`. Die Pfade des Bildschirms wie
  `$Communicator/MainMenu` bleiben so gültig.
- Godot ruft `_ready()` eines Knotens erst, wenn alle Kinder bereit sind. In
  `Communicator._ready()` sind die Seiten aus der Szene also schon da; `add_page()` stellt sie auf
  `display_rect` und verbirgt sie.
- Die Reihenfolge im Baum ist die Malreihenfolge: Die Seiten stehen nach `Display` und liegen
  deshalb darüber, ohne umgehängt zu werden.
- Eine eigene Liste der Seiten gibt es nicht; `_page_list()` liest die Kinder. Eine Liste hätte
  verwaiste Einträge, sobald eine Seite frei wird oder der Communicator den Baum verlässt.
- Erst verbergen, dann zeigen (`add_page()`, `show_page()`): Eine verborgene Seite gibt ihren
  Fokus ab, und ein unsichtbares Menü nimmt keinen. So geht keine Taste an eine Seite, die man
  nicht sieht.
- Lage und Farbe der Anzeige sind `@export`-Eigenschaften mit Settern, keine Konstanten: Sie
  gehören zum Gehäuse, ein späteres Gehäuse setzt eigene (C11). Fest ist nur
  `DISPLAY_SIZE`, die Größe ist für jedes Gehäuse gleich. Der Setter prüft `is_node_ready()`, denn
  vor `_ready()` gibt es `$Display` noch nicht.
- Das Gehäuse ist reine Grafik: `mouse_filter = IGNORE` an Communicator, `Case`, `Display` und
  `Hint`. Ein Klick geht durch sie hindurch an das, was darunter liegt; der Test prüft genau das.
- Der Platzhalter bis G-02 kommt aus `Communicator._draw()`. Was der Elternknoten malt, liegt
  unter seinen Kindern. Sobald `Case` eine Textur hat, malt `_draw()` nichts mehr. Die Kontur sind
  vier Streifen, denn `draw_rect(…, false)` legt die Linie mittig auf die Kante, halb auf zwei
  Pixel. Gemalt wird aus einer Liste von Rechtecken (`_placeholder_layers()`) wie beim Knopf;
  headless entsteht kein Bild, die Liste kann ein Test lesen.

### T006 Fahrt: ein angehaltener Tween im eigenen Takt

- Der Tween schreibt nicht in `position.y`, sondern in die Eigenschaft `slide_y`. Deren Setter
  rundet auf ganze Oberflächenpixel; der Tween weiß davon nichts, und keine Lage liegt zwischen
  zwei Pixeln.
- `create_tween()` bindet den Tween an den Communicator; `pause()` hält ihn sofort an. Den Takt
  gibt `_process()` mit `custom_step()` vor, gedeckelt: im ersten Bild einer Fahrt auf 1/60 s,
  danach auf 1/30 s. Im langen ersten Bild nach dem Laden springt das Gerät so nicht gleich halb
  herein: Mit `EASE_OUT` legt es dann höchstens 23 % des Wegs zurück, ohne zweiten Deckel wären es
  42 %.
- Das Ende meldet das Signal `finished` des Tweens, nicht der Rückgabewert von `custom_step()`.
  Eine Probe hat gezeigt, dass der erst ein Bild nach dem Ende `false` wird; der Spike meldete
  deshalb ein Bild zu spät. Bei 30 Bildern je Sekunde wären das 267 statt höchstens 250 ms gewesen.
- `TRANS_CUBIC` federt nicht über das Ziel hinaus, anders als `TRANS_BACK` und `TRANS_ELASTIC`.
  Herein `EASE_OUT` (schnell los, sanft an), hinaus `EASE_IN` (sanft los, schnell weg).
- Eine Umkehr ruft `kill()` und startet einen neuen Tween aus der jetzigen Lage. `kill()` sendet
  kein `finished`, deshalb gibt es genau eine Meldung je Fahrt.
- Tests ohne `await`: `set_process(false)` hält die Engine davon ab, `_process()` mit echter Zeit
  aufzurufen. Der Test ruft es selbst mit festen Schritten und liest nach jedem Bild die Lage. So
  laufen 60 und 30 Bilder je Sekunde und ein erstes Bild von 0,5 s in Millisekunden durch.
- Eine Endlage auf ungeraden Lagen meldet `_ready()` mit `push_warning()`; GUT prüft das mit
  `assert_push_warning()`. Gerade muss sie sein, weil ein Bildpixel 2 × 2 Oberflächenpixel groß ist.

### T007 Eingabe sperren und der Hinweis als Kind

- Godot 4.7 hat an `Control` zwei Eigenschaften, die für den ganzen Teilbaum gelten:
  `focus_behavior_recursive` und `mouse_behavior_recursive`. `_set_locked()` setzt beide ab
  `slide_out()` auf `DISABLED`. Damit greift die Sperre auch für Zeilen, die ein Menü erst zur
  Laufzeit baut, ohne eine einzige Zeile anzufassen.
  - `FOCUS_BEHAVIOR_DISABLED` nimmt der Seite den Fokus sofort weg, und `grab_focus()` scheitert
    danach mit einer Warnung der Engine. Ohne Fokus gehen Enter und Leertaste an keine Zeile.
  - `MOUSE_BEHAVIOR_DISABLED` lässt jede Zeile wirken wie `MOUSE_FILTER_IGNORE`: kein
    `mouse_entered` (darüber wählt `MainMenu`), kein `gui_input` (darüber wählt `SaveList` bei
    jeder Bewegung), kein Klick.
  - Frei heißt `INHERITED`, nicht `ENABLED`: So gilt weiter, was ein Bildschirm darüber einstellt.
  - Verworfen: eine deckende Sperrfläche über den Seiten. Sie hielte die Maus ab, aber nicht die
    Tastatur, und den Fokus müsste man trotzdem selbst wegnehmen.
- Eine Zeile, die unter dem ruhenden Zeiger durchfährt, wird nicht gewählt, ohne eigenen Code:
  Godot meldet `mouse_entered` nur bei einer Bewegung der Maus, nicht wenn ein Control unter den
  Zeiger fährt. Belegt mit einer Probe mit Gegenprobe und im Test, der nach jedem Schritt ein
  echtes Bild abwartet. Ein kleines Rucken der Maus wählt danach die Zeile.
- Der Hinweis ist ein Kind des Communicators und fährt deshalb mit, ohne Code (R7). Im Spike
  verschob der Titelbildschirm ihn bei jeder Bewegung um die Differenz.
- `MenuHint` stellt seine rechte Kante `GAP` vor das Rechteck, das er bekommt. Der Communicator
  reicht ihm deshalb ein umgerechnetes Rechteck (`_beside_case()`): oben die Zeile, links die
  Kante des Gehäuses. `MenuHint` brauchte keine neue Funktion. Gleiche Zeilen ergeben gleiche
  Rechtecke, also gilt die Regel „eine Meldung bleibt neben derselben Zeile“ weiter.

### T008 Probeszene: der Baustein ohne den Titel

- `src/test/fixtures/communicator_probe.tscn` zeigt, was ein späterer Bildschirm tut: einen
  Communicator in der Szene, darunter ein `MainMenu`. Die Probe hört selbst auf `selection_changed`
  und `entry_activated` und reicht den Hinweis über `show_hint()` weiter. Der Communicator kennt die
  Signale seiner Seiten nicht (FR-007).
- Reihenfolge beim Erscheinen: `place_hidden()`, dann Einträge und Auswahl, dann `slide_in()`
  (C5). `place_hidden()` sperrt nicht, sonst könnte das Menü vor der Fahrt keinen Fokus nehmen.
- Nach einer Fahrt hinaus hat keine Seite den Fokus. Wer den Communicator wieder hereinholt, wählt
  die Zeile neu (`_on_slide_finished()` in der Probe).
- Die Farbe des Hintergrunds setzt das Skript aus `UiPalette.NACHT`, nicht die Szene als Zahl.
- Der Test lädt die Probe in einen eigenen `SubViewport` und bedient sie über `push_input()`: Pfeil
  runter, Enter, gemeldet wird der zweite Eintrag. Dass weder Titelbildschirm noch `TitleTexts`
  beteiligt sind, prüft ein zweiter Test an den Quelltexten der Probe.
- `src/test/` ist vom Export ausgeschlossen; die Probe kommt also nie ins fertige Spiel.

## Phase 3

### T013 `LcdRow` und `LcdHeader`: was das Theme kann und was nicht

- Eine Theme-Variante (`theme_type_variation`) ist ein eigener Typname im Theme mit einer Basis,
  etwa `LcdRow` mit Basis `Button`. Ein Button mit dieser Variante nimmt Farben, Schrift und
  Stile von dort und, was dort fehlt, von `Button`.
- Alle Schriftfarben von `LcdRow` sind `tusche`, auch `font_hover_color`; nur
  `font_disabled_color` ist `gehaeuse-dunkel`. `lcd` steht bewusst nicht im Theme: Das Theme kennt
  die Zustände eines Buttons (normal, Fokus, Hover, gedrückt, gesperrt), aber nicht „gewählt“.
  Unter der Maus nimmt ein Button `font_hover_color`, ob er den Fokus hat oder nicht. Wäre die
  `lcd`, stünde eine nicht gewählte Zeile unter der Maus hell auf hellem Grund; wäre sie `tusche`,
  stünde die gewählte unter der Maus schwarz auf dem schwarzen Balken (R15; Analyse, B1).
- `LcdRow` hat einen eigenen leeren Stil mit Innenabstand 12, obwohl `MenuRow` denselben Wert hat.
  So zieht eine spätere Änderung an der Anzeige das Papier nicht mit. Die 12 sind
  `MenuPaper.LCD_TEXT_INSET − LCD_ROW_INSET`, also Text bei x 16; `test_lcd_theme.gd` prüft das.
- Eine `.tres` kann keine Konstante aus `UiPalette` nennen, die Farben stehen dort als Zahlen.
  `test_lcd_theme.gd` vergleicht sie mit `UiPalette`, wie `test_werkstatt_theme.gd` es für die
  Werkstatt tut.

### T014 `MainMenu.look`: ein Schalter statt zweier Klassen

- `enum Look { PAPER, LCD }` und `@export var look`: Papier und Anzeige unterscheiden sich nur im
  Malen, in den Varianten und in den Abständen. Bedienung, Fokus, Umlauf an den Enden und Signale
  sind derselbe Code, und die Tests der Bedienung laufen auf beiden Fassungen. Zwei Klassen hießen
  doppelte Bedienung und doppelte Tests (R5).
- `look` gilt beim Bau der Zeilen, denn jede Zeile bekommt ihre Variante in `_make_row()`. Der
  Setter baut sie deshalb neu, wenn das Menü schon bereit ist (`is_node_ready()`), und wählt
  danach dieselbe Zeile wieder.
- Die helle Schrift der gewählten Zeile setzt `_update_row_colors()` per
  `add_theme_color_override()` und nimmt sie allen anderen mit `remove_theme_color_override()`
  wieder. Ein Override an einem Control geht vor das Theme. Es läuft beim Wählen
  (`_on_row_focus_entered()`), beim Wählen im Verborgenen und nach dem Bau der Zeilen.
- `font_disabled_color` bekommt keinen Override. Ein gesperrter Button ist immer im Zustand
  `DRAW_DISABLED` und nimmt diese Farbe, auch mit Fokus. Eine gewählte, nicht verfügbare Zeile
  bleibt so gedämpft, ohne eigenen Code.
- Auf der Anzeige setzt das Menü keine Größe, auch keine Mindestgröße: Die Seite gehört dem
  Communicator. Eine Mindestgröße lässt ein Control nie kleiner werden; bliebe die vom Papier
  stehen, könnte sie die Anzeige überstimmen.
- Die Maße beider Fassungen stehen in `MenuPaper` (`LCD_ROW_INSET`, `LCD_ARROW_X`,
  `LCD_TEXT_INSET`). `_apply_look()` stellt danach die Offsets von `Rows` und die Variante der
  Kopfzeile.
- Headless entsteht kein Bild. `MenuPaper.lcd_selection_layers()` und `arrow_layers()` liefern die
  Rechtecke, die gemalt würden, `_draws_paper()` sagt, ob Papier gemalt wird. Der Papierpfeil malt
  aus derselben Liste; das Bild auf Papier bleibt Pixel für Pixel gleich.
- Welche Farbe eine Zeile wirklich zeigt, rechnet der Test so nach, wie der Button sie wählt:
  `get_draw_mode()` und `has_focus()` ergeben den Namen der Farbe, `get_theme_color()` den Wert mit
  Override.

### T015 `SaveList.look`: dieselben Regeln, Spalten aus dem Button

- Derselbe Schalter wie im Menü. `SaveList` baut ihre Zeilen nur einmal; beim späteren Setzen von
  `look` nimmt `_clear_rows()` sie mit `remove_child()` sofort heraus und gibt sie mit
  `queue_free()` am Ende des Bilds frei. Ein Test, der gleich danach endet, wartet deshalb ein
  Bild, sonst zählt GUT die alten Zeilen als verwaiste Knoten.
- Die Spalten sind Labels im Button. `_fill_row()` nimmt ihre Farbe schon immer vom Button
  (`get_theme_color(&"font_color")`). Weil `select()` erst `_update_row_colors()` und dann
  `_refresh_rows()` aufruft, bekommen die Spalten der gewählten Zeile den Override `lcd` gleich mit.
  Gedämpfte Zeilen nehmen `font_disabled_color` und bleiben `gehaeuse-dunkel`.
- Die Spalten beginnen ab dem Text wie auf Papier (0, 64, 108, 172) und sind genauso breit. Was auf
  Papier passt, passt so auch auf der Anzeige; die breitere Anzeige lässt rechts nur mehr Luft.
- Die Rollmarke steht auf der Anzeige 8 vom Rand (`MenuPaper.LCD_SCROLL_MARK_INSET`). In der
  gewählten Zeile ist sie `lcd`, sonst `tusche`; sonst verschwände sie im Balken (CHK001).
  `_scroll_mark_layers()` liefert die Rechtecke für `_draw()` und für die Tests.
