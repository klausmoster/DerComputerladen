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

## Phase 5

### T027 Das Gehäuse genau ×2

- `Case` ist ein `TextureRect` mit `stretch_mode = STRETCH_KEEP`, so groß wie das Bild (216 × 132)
  und mit `scale = Vector2(2, 2)`. Jedes Bildpixel wird so 2 × 2 Oberflächenpixel, und der Faktor
  steht ausdrücklich in der Szene. Ein Ziehen auf eine feste Größe hätte bei einem Bild mit einer
  anderen Größe still verzerrt.
- `size` bleibt die Bildgröße. Die Fläche, die das Gehäuse bedeckt, rechnet
  `get_transform() * Rect2(Vector2.ZERO, size)` aus; der Test vergleicht sie mit der Größe des
  Communicators.
- Der Platzhalter aus Phase 2 entfällt von selbst, weil `_draw()` ihn nur malt, wenn `Case` kein
  Bild hat.

### T028 Der Titel auf dem Communicator

- Die Seiten hängen in `title_screen.tscn` unter der Instanz (`parent="Communicator"`), die
  Signalverbindungen nennen `from="Communicator/MainMenu"`, und `@onready` holt sie über
  `$Communicator/…`. Die Namen der Seiten sind dieselben wie vorher; Handler und Tests bleiben
  wiedererkennbar.
- `_show_only()` ruft nur noch `Communicator.show_page()`. Die Regel „erst verbergen, dann zeigen“
  steht damit an einer Stelle.
- Der pixelschatten des Logos ist ein Kind `Shadow` des Logos, 2 nach rechts unten, mit
  `show_behind_parent`: Es wird vor seinem Elternteil gemalt, liegt also darunter. Weil `Logo`
  kein Container ist, stört das Kind das Layout des `VBoxContainer` nicht.
- Seine Textur macht `TitleScreen.silhouette()` mit `Image`: `get_image()`, `convert()`,
  `set_pixel()`, `ImageTexture.create_from_image()`. Jedes deckende Pixel wird genau `tusche`. Ein
  Shader könnte das auch, aber eine Farbe als Uniform läuft je nach Farbraum durch eine Umrechnung,
  und ein Test kann die Pixel nicht nachlesen.
- Untertitel und Versionszeile bekommen den Schatten aus dem Theme: `font_shadow_color`,
  `shadow_offset_x/y` 2 und `shadow_outline_size` 0 ergeben einen harten Versatz ohne Unschärfe.

### T029 Erscheinen, Wache und Hinausfahren

- Eine eigene Wache statt der Sichtbarkeit: `add_page()` verbirgt alle Seiten schon in
  `Communicator._ready()`. Bis das zeitversetzte `_build_sheets()` das Hauptmenü zeigt, ist
  `_main_menu.visible` false. Ein Esc in dieser Lücke liefe sonst in `_go_back()`.
  `_ready_for_input` wird erst true, wenn Einträge und Auswahl stehen.
- Die Handler, die etwas auslösen, und `_unhandled_input()` fragen zuerst `_accepts_input()`. Die
  Handler der Auswahl fragen nicht: Die erste Auswahl kommt aus `_build_sheets()`, noch vor der
  Wache, und ihr Hinweis soll stehen.
- Den Szenenwechsel macht erst ein Signal: `_leave()` setzt `_leaving` und ruft `slide_out()`;
  `slide_finished(false)` ruft `_change_scene()`. Das Spiel läuft da schon, und schließt der
  Spieler in diesen 200 ms das Fenster, speichert die Session wie bisher. Mit `animate = false`
  kommt das Signal sofort, noch im selben Aufruf; die bisherigen Tests merken deshalb keinen
  Unterschied.
- Zwei Sperren beim Verlassen: Der Communicator sperrt Fokus und Maus für seine Seiten, `_leaving`
  sperrt alle Handler des Titels. So legt weder ein zweites Enter noch „Maus bewegen, dann Enter“
  ein zweites Spiel an (B2). Weil kein Handler mehr läuft, ruft auch niemand `select()` an einer
  gesperrten Seite; das gäbe die Warnung „can't grab focus“.
- Lagen relativ zum bewegten Knoten: `_remember_row()` merkt sich die gewählte Zeile relativ zum
  Communicator, `_current_row()` rechnet sie in die jetzige Lage zurück. Eine Meldung nach einer
  Wahl während der Fahrt steht so neben der Zeile, wo sie jetzt ist (C3).
- Der Hinweis fährt mit dem Gerät hinaus. `_leave()` zeigt den Hinweis der gewählten Zeile noch
  einmal, denn das Auslösen hat eine Meldung schon beendet. Als Kind des Communicators fährt er
  dann ohne eigenen Code mit.

### T030 Die Fahrt im Titel testen

- Die bisherigen Tests setzen `animate = false` am Communicator. Er steht dann sofort in der
  Endlage, und ein begonnenes Spiel wechselt sofort die Szene; die Tests bleiben, wie sie waren.
- Die Fahrt-Tests schalten mit `set_process(false)` die Engine ab und takten mit `_fahre()` selbst,
  wie in `test_communicator.gd`. Gesetzt wird das direkt nach dem Einhängen, denn die Fahrt
  herein beginnt erst zeitversetzt in `_build_sheets()`.
- Eingaben vor den Einträgen schickt `_druecke()` ohne ein Bild zu warten. So kommen sie, bevor
  `_build_sheets()` am Ende des Bilds läuft.
- SC-004 misst mit der echten Schrift: `get_combined_minimum_size()` jeder Zeile gegen die Breite
  von `Rows` und `Font.get_string_size()` jeder Spalte gegen die Breite ihres Labels.
- SC-006 prüft Rechtecke mit `Rect2.intersects()`, jedes mit seinen 2 Pixeln Schatten, für jede
  Zeile jeder Seite, als Hinweis und als Meldung.

### T031a Die Versionszeile oben rechts

- Beim Fahren glitt der Hinweis kurz über die Versionszeile unten links. SC-006 verlangt „in keiner
  Lage“, der Test prüfte aber nur die Endlage. Die Zeile steht jetzt oben rechts im freien Himmel
  (Klaus; Style-Guide, Baustein Communicator).
- Verankert mit `anchor_left` und `anchor_right` 1, `offset_right` −16, `grow_horizontal` BEGIN
  und `horizontal_alignment` RIGHT. Die rechte Kante bleibt bei x 624, und ein längerer Text wächst
  nach links, ohne dass jemand die Lage nachrechnen muss.
- Der neue Test prüft SC-006 über die ganze Fahrt: `_fahre()` ruft nach jedem Bild ein
  `Callable`, hier eine Lambda mit `bind()`, die Gehäuse, Hinweis und Meldung gegen die freien
  Flächen prüft. So zählt jede Zwischenlage, nicht nur die Endlage.

### T031c Die Anzeige 320 × 160

- Klaus hat das Gerät kleiner gemacht, damit etwas von der Tastatur zu sehen ist. Im Code ändern
  sich nur Zahlen an den Stellen, die dafür da sind: `Communicator.DISPLAY_SIZE` (320 × 160), die
  Vorgabe von `display_rect` (38, 24), die Größen in `communicator.tscn` (Gehäuse 396 × 264, `Case`
  198 × 132 mit `scale` 2) und die Endlage im Titel (242, 96). Seiten, Hinweis und Rollmarken
  rechnen ihre Lage aus `display_rect` und der Kante des Gehäuses und ziehen von selbst mit.
- Die Liste zeigt auf der Anzeige höchstens fünf Spielstände, auf Papier weiter sechs. Ausgedrückt
  ist das mit zwei Konstanten, `VISIBLE_ROWS` (Papier) und `LCD_VISIBLE_ROWS` (Anzeige), und einer
  Funktion `visible_rows()`, die nach `look` wählt.
  - Nach `look` und nicht nach der Größe der Seite: Die Größe gibt der Communicator erst, nachdem
    die Liste ihre Zeilen gebaut hat, und im Style-Guide steht die Zahl als Regel, nicht als
    Rechnung.
  - Zwei Konstanten statt einer gerechneten Zahl: Jede steht für eine Regel des Style-Guides und
    lässt sich dort nachschlagen.
  - Die Liste baut genau `visible_rows()` Zeilen; ein Wechsel von `look` baut ohnehin neu. Eine
    sechste Zeile, die auf der Anzeige immer verborgen bliebe, wäre ein Knoten ohne Aufgabe.
- Wechselt `look`, kann die gewählte Zeile kurz außerhalb des kleineren Fensters liegen, bevor
  `select()` sie hineinrollt. `_update_row_colors()` färbt dann noch keine Zeile, statt auf einen
  Button zuzugreifen, den es nicht gibt.
- In den Tests stehen die Maße als Konstanten oben in jeder Datei. Wo ein Test „die unterste Zeile
  des Fensters“ meint, fragt er `visible_rows() - 1` statt einer festen Nummer; so behält er seine
  Aussage bei jeder Fenstergröße.

### T031e Das Gehäuse G-03

- Ein neues Gehäuse heißt hier: neue Zahlen an genau den Stellen, die zum Gehäuse gehören. Das
  sind die Vorgabe von `display_rect` (36, 28) in `communicator.gd`, die Größen in
  `communicator.tscn` (Communicator 392 × 268, `Case` 196 × 134, `Display` von 36/28 bis 356/188)
  und die Endlage im Titel und in der Probeszene (244, 92). Die Datei bleibt
  `organizer_1991.png`. Weil Godot das Bild über seine `.uid` und seinen Pfad findet, braucht keine
  Szene einen neuen Verweis.
- `Case` behält STRETCH_KEEP und `scale` 2. Seine Größe in der Szene muss trotzdem zum Bild passen:
  Mit KEEP zeichnet Godot die Textur in Originalgröße, und das Rechteck des Knotens bestimmt nur,
  was als „Gehäuse“ zählt. `test_gehaeuse_ist_g03_genau_doppelt` prüft deshalb Bild, Knoten und
  Communicator gegeneinander.
- Hinweis und Meldung brauchten keine Änderung. `_beside_case()` liest die linke Kante des Gehäuses
  zur Laufzeit aus `_case.get_global_rect()`, nicht aus einer Zahl, und die rechte Kante des
  Hinweises liegt damit von selbst bei 244 − 4 = 240.
- Die Anzeige im Titel bleibt bei x 280 bis 600 und y 120 bis 280: 244 + 36 und 92 + 28. Der Titel
  verschiebt also nur das Gehäuse um die Anzeige herum. Die Tests der Seiten, die an `ANZEIGE`
  hängen, laufen ohne Änderung weiter.
- Im Titeltest steht die Oberkante jetzt als Konstante `GEHAEUSE_OBEN` neben `GEHAEUSE_LINKS`, statt
  an fünf Stellen als Zahl. Beim nächsten Gehäuse ändert sich dann nur eine Zeile.
- Der Abstand zum Logo hat jetzt einen eigenen Test,
  `test_zwischen_logoblock_und_gehaeuse_bleibt_mindestens_raster_8_frei`. Er misst an den echten
  Rechtecken: `get_global_rect()` des `LogoBlock` (endet bei y 83) und von `Case` (beginnt bei 92),
  also 9. Gemessen wird am Kasten ohne Schatten, so wie der Style-Guide den freien Bereich festlegt.
  Das reicht, weil der Schatten des Untertitels im Kasten liegt: Die Grundlinie liegt bei 80, der
  Text hat keine Unterlängen, der Schatten endet bei 82. `get_global_rect()` rechnet die `scale`
  von `Case` mit ein; das Rechteck ist also das auf der Oberfläche, 392 × 268.

## Phase 7

### T041 „Beenden“ ohne Fahrt testen

- `get_tree().quit()` ist nicht testbar: Es beendet den ganzen Testlauf. Deshalb hat der Titel jetzt
  `quit_callback: Callable`, nach demselben Muster wie `scene_callback` im Titel und
  `quit_callback` in `GameSession` und in der Werkstatt. Ein `Callable` ist eine Funktion als Wert;
  ungültig (der Vorgabewert) heißt „das Echte tun“. `_quit()` entscheidet das an einer Stelle, so
  wie `_change_scene()` für den Szenenwechsel.
- Eine eigene Eigenschaft statt `GameSession.quit_callback`: Jener gehört zum Schließen des Fensters
  mit Speichern. Der Titel würde sonst in einen fremden Node greifen, um zu entscheiden, wie er
  selbst beendet.
- Der Helfer `_baue_titel_ohne_warten()` setzt `quit_callback` für jeden Test. So kann kein Test, der
  „Beenden“ zufällig trifft, den Lauf abbrechen.
- Die zwei Tests fahren im Takt des Tests (`faehrt = true`). Mit `animate = false` käme eine Fahrt
  hinaus sofort zu Ende und wäre kaum zu sehen. So bemerken `is_in()`, `accepts_input()`, die Lage
  und ein mitgeschriebenes `slide_finished` jede Fahrt. Gegenprobe: Mit `slide_out()` vor dem
  Beenden schlagen beide Tests fehl.
