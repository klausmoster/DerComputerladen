# Lernnotizen: Easter Egg 01: Space Invaders

Zu jeder umgesetzten Task die Godot-Konzepte und warum es so gebaut ist, an den Stellen im
Projekt. Bei `[A]`-Tasks schreibt der Agent die Notizen, Claude trägt sie je Phase hier ein; baut
Klaus eine Task selbst, schreibt Claude die Notiz beim Review. Abnahmen und Phasenprüfungen bauen
nichts und haben deshalb keine Notiz.

## Phase 2

### T004 Tonskript: eine Rechteckwelle als Zahlen

Kein Godot, aber die Grundlage für alles, was in Phase 2 bis 5 klingt (`tools/ton/make_sounds.py`).

- Ein **digitaler Ton** ist eine Liste von Zahlen, 22 050 je Sekunde (die Abtastrate). Jede Zahl
  sagt, wie weit die Lautsprechermembran in diesem Augenblick ausgelenkt ist, als 16-Bit-Wert von
  −32 768 bis 32 767. `wave` aus der Standardbibliothek schreibt die Liste mit dem Kopf, den ein
  WAV braucht.
- Eine **Rechteckwelle** springt nur zwischen zwei Werten, +Pegel und −Pegel. Wie oft sie springt,
  ist die Tonhöhe: Bei 98 Hz (`marsch_1.wav`) wechselt sie 98-mal je Sekunde hin und her, also alle
  rund 112 Proben. Das Skript führt eine **Phase** von 0 bis 1 mit; je Probe wächst sie um
  Frequenz ÷ Abtastrate, und in der ersten Hälfte ist der Wert oben, in der zweiten unten. So kann
  sich die Frequenz Probe für Probe ändern, ohne zu springen, etwa beim Schuss von 1200 auf 600 Hz.
  So klangen PC-Lautsprecher und Taschengeräte, die nur „an“ und „aus“ kannten.
- **Rauschen** sind Zufallszahlen. Damit es bei jedem Lauf dasselbe Rauschen ist, hat jede Datei
  einen festen Seed (`random.Random(1)` für den Klick). Ein Seed ist der Startwert des
  Zufallsgenerators: gleicher Seed, gleiche Folge, wie beim Fahrplan der Zeitleiste. Daraus folgt
  „bytegleich“, und deshalb kann `test_ton.gd` die Dateien über Prüfsummen mit dem Skript
  vergleichen.
- **Hüllkurve:** Treffer und Kanone werden leiser, indem jede Probe mit einem Faktor malgenommen
  wird, der exponentiell von 1 gegen 0 fällt. Am Ende jedes Tons fallen die letzten 5 ms linear auf
  genau 0. Ein Ton, der mitten in einer Auslenkung abbricht, knackt im Lautsprecher.
- **Kein stiller Anfang:** Die Phase beginnt bei 0, die erste Probe ist also schon +Pegel. Damit
  klingt der Ton im selben Augenblick, in dem Godot ihn startet (SC-007).
- **−6 dBFS:** Der Spitzenpegel ist die Hälfte des Vollausschlags (10^(−6/20) ≈ 0,5). Das lässt
  Luft, wenn mehrere Töne gleichzeitig im Bus `Effekte` zusammenkommen, damit die Summe nicht
  übersteuert.

### T005 Tonkanäle und Import: `default_bus_layout.tres` und die `.import` der WAV

- Ein **Bus** (im Style-Guide „Tonkanal“) ist eine Mischstufe im `AudioServer`: Jeder
  `AudioStreamPlayer` spielt in genau einen Bus (`bus = &"Effekte"`), der Bus mischt alles, was in
  ihn spielt, regelt den Pegel (`volume_db`), kann Effekte tragen und gibt das Ergebnis an sein
  Ziel weiter (`send`). Am Ende steht immer `Master`, Bus 0, der an den Ausgang geht.
- Die Töne bekommen einen eigenen Bus `Effekte` (−10 dB, Ziel `Master`), statt direkt in `Master`
  zu spielen. So gibt es genau eine Stelle für „Effekte lauter oder leiser“
  (`AudioServer.set_bus_volume_db()`), und kein Player trägt einen eigenen Pegel. Kommt später
  Musik, bekommt sie einen Bus neben `Effekte`; ein „Einstellungen“ regelt dann beide getrennt und
  `Master` als Gesamtlautstärke (R14). Effekte auf den Bussen gibt es keine: Hall wäre gegen den
  Style-Guide.
- `src/default_bus_layout.tres` ist eine Resource vom Typ `AudioBusLayout`, als Text geschrieben.
  Jeder Bus ist ein Satz Zeilen `bus/<nummer>/…`; `bus/1/send = &"Master"` ist das Ziel. `Master`
  steht ausdrücklich mit 0 dB darin, obwohl das der Vorgabewert ist: Wer die Datei liest, sieht
  beide Kanäle.
- Warum Godot die Datei **von selbst** lädt: Die Projekteinstellung `audio/buses/default_bus_layout`
  hat den Vorgabewert `"res://default_bus_layout.tres"` (Klassenreferenz `ProjectSettings`). Beim
  Start lädt der `AudioServer` die Datei unter diesem Pfad, falls es sie gibt. Deshalb bleibt
  `project.godot` unverändert; eine Einstellung stünde dort nur, wenn wir einen anderen Pfad
  wollten. Der Editor legt dieselbe Datei an, sobald man im Fenster „Audio“ unten einen Bus
  hinzufügt. Die Fehlerprobe zeigt es: Ohne die Datei kennt der `AudioServer` nur `Master`, und
  `test_kanaele_master_und_effekte` schlägt fehl.
- Die Datei hat keine `uid://` im Kopf, weil sie als Text entstand; der Editor trägt eine ein,
  sobald er sie einmal speichert. Für Godot reicht der Pfad, und der ist durch die Einstellung
  ohnehin fest.
- Eine **`.import`** neben jeder WAV hält fest, wie Godot die Rohdatei in eine eigene Ressource
  umwandelt (`AudioStreamWAV`, abgelegt unter `.godot/imported/`, nicht im Repo). Unter `[params]`
  stehen die Import-Einstellungen, unter `[remap]` die `uid` der Datei. Deshalb wird `.import`
  committet: Ohne sie importiert ein frischer Clone mit den Vorgaben, und Verweise per `uid`
  brechen.
- Godots Vorgaben für WAV passen hier zweimal nicht, beide habe ich in den zehn `.import` geändert:
  `compress/mode=2` („Quite OK Audio“, verlustbehaftet) wird `0` („PCM (Uncompressed)“), und
  `edit/loop_mode=0` („Detect from WAV“, folgt den Schleifenmarken in der Datei) wird `1`
  („Disabled“). `edit/trim` und `edit/normalize` sind schon `false`.
- Warum **PCM**: Die Proben sollen so klingen, wie das Skript sie schreibt. QOA und IMA ADPCM
  verändern sie leicht und müssen beim Abspielen dekodiert werden; Trimmen schnitte leise Stellen unter −50 dB
  an Anfang und Ende ab, also einen Teil des Ausblendens, und die Länge stimmte nicht mehr;
  Normalisieren den Spitzenpegel von −6 dBFS auf 0 dB
  heben. Bei zusammen unter 100 KB kostet PCM nichts. „Schleife aus“ statt „aus der Datei“ macht
  die Absicht ausdrücklich, statt sich darauf zu verlassen, dass die WAV keine Marken hat.
- Geändert wurde die `.import` als Text, danach lief `--import` noch einmal. Godot merkt an den
  geänderten `[params]`, dass die Ressource neu entstehen muss. Im Editor ginge dasselbe im Dock
  „Import“ mit „Reimport“.

### T006 Tests: Rohdatei, Import und Kanäle getrennt prüfen

- `test_ton.gd` liest Proben, Länge und Prüfsumme aus der **Rohdatei**
  (`FileAccess.get_file_as_bytes()`, `FileAccess.get_md5()`), nicht aus der importierten Ressource
  (wie `test_bilder.gd` bei den PNG). Was der Import daraus macht, prüft ein eigener Test an der
  geladenen `AudioStreamWAV` (`format == FORMAT_16_BITS`, `loop_mode == LOOP_DISABLED`, `stereo`,
  `mix_rate`) und an der `.import` selbst, gelesen mit `ConfigFile`, denn sie ist eine INI-Datei.
  Beides zusammen sagt: Die Datei ist richtig, und Godot spielt sie unverändert.
- `_lies_wav()` geht die RIFF-Blöcke der Reihe nach durch, statt feste 44 Byte Kopf anzunehmen. Eine
  WAV darf weitere Blöcke haben; so findet der Test `fmt ` und `data` auch dann.
  `PackedByteArray.decode_s16()` liest eine vorzeichenbehaftete 16-Bit-Probe, Little Endian wie in
  WAV üblich.
- Die Kanäle prüft der Test am laufenden `AudioServer` (`bus_count`, `get_bus_send()`,
  `get_bus_volume_db()`), nicht an der `.tres`. Er prüft damit, was Godot beim Start tatsächlich
  geladen hat, also auch, dass die Datei ohne Projekteinstellung greift.
- Ein Test prüft, dass im Ordner genau die zehn WAV liegen. Ein elfter Ton ohne Eintrag im
  Style-Guide fällt so auf, statt ungeprüft mitzulaufen.
- Headless läuft der Dummy-Tontreiber; zu hören ist nichts (R15). Ob die Töne gut klingen und sofort
  einsetzen, prüft Klaus mit `afplay`.

## Phase 3

### T010 Muster als Daten: `InvadersSprites`

- Die acht Pixelmuster stehen in `src/scenes/title/invaders/invaders_sprites.gd` als Konstante
  `PATTERNS`: je Muster eine Liste von Bildern, jedes Bild eine Liste von Strings, `#` gesetzt,
  `.` leer. Das ist dieselbe Schreibweise wie im Style-Guide; der Review vergleicht Zeile für Zeile,
  und ein Abgleich per Skript fand keine Abweichung.
- Die Klasse hat nur `const` und `static func`. Niemand legt eine Instanz an; man ruft
  `InvadersSprites.pixels(&"alien_a", 1)` direkt über den `class_name` auf. `extends RefCounted`
  steht nur da, weil jedes Skript von irgendetwas erben muss.
- Die Schlüssel sind `StringName` (`&"alien_a"`), nicht `String`. Ein `StringName` gibt es im
  Speicher nur einmal, ein Vergleich ist deshalb ein Zeigervergleich. Godot nimmt sie überall dort,
  wo Namen gemeint sind, etwa bei Aktionen, Signalen und Animationen.
- `pixels()` wandelt die Strings in eine Liste von `Vector2i` um. Die Seite malt daraus in Phase 4
  je Pixel ein Rechteck. `size_of()` liest die Größe aus dem ersten Bild, so dass keine zweite
  Zahlentabelle neben den Mustern auseinanderlaufen kann. Ein Bild über die Zahl der Bilder hinaus
  zählt im Kreis (`posmod`). Deshalb darf die Seite allen Teilen `march_frame` mitgeben, auch der
  Kanone mit nur einem Bild.
- Warum keine PNG: Ein Muster als Text lässt sich im Diff lesen und im Test prüfen („8 × 6, nur
  `#` und `.`“). Ein Spritesheet müsste man öffnen und Pixel zählen (research.md, R8).

### T011 Der Kern ohne Node: `InvadersGame`

- **Kein Node, wie `TimelineRun`.** `InvadersGame` erbt von `RefCounted`, nicht von `Node`. Es
  hängt nicht im Szenenbaum, bekommt kein `_process()` und kennt weder Eingabe noch Bildschirm.
  Godot räumt ein `RefCounted` selbst weg, sobald niemand mehr darauf verweist; `queue_free()`
  braucht es nicht. Die Seite in Phase 4 hält eine Partie und ruft `step()` auf, die Tests tun
  dasselbe ohne Szene. Das ist die Aufteilung des Fahrplans: `TimelineRun` rechnet, das Autoload
  `Timeline` hängt ihn an die Uhr.
- **Fester Schritt statt `delta`.** Ein Spiel mit `position += speed * delta` läuft auf jedem
  Rechner etwas anders: Bei 59 oder 144 Bildern je Sekunde entstehen andere Zwischenlagen, und auf
  einem Raster aus ganzen Bildpixeln wird gerundet. Hier ist ein Aufruf von `step()` immer 1/60 s
  (`STEP`), und alles zählt in ganzen Schritten: die Kanone 1 Pixel je Schritt, die Bombe 1 Pixel je
  zwei, der Takt alle 30 bis 3 Schritte, die Pause 60. Wie viele Schritte zu einem Bild gehören,
  rechnet in Phase 4 die Seite mit einem Zeitspeicher aus (höchstens 4 je Bild).
- **Eigener Zufall mit Seed.** Die Partie hat einen eigenen `RandomNumberGenerator` (`_rng`) mit
  dem Seed aus `_init()`. Die globalen Funktionen `randf()` und `randi()` teilen sich einen Zustand
  mit dem ganzen Spiel; jeder andere Aufruf irgendwo verschöbe die Bomben. Mit eigenem Generator
  ergibt gleicher Seed bei gleichen Eingaben dieselbe Partie, und die Tests können Bombentreffer
  gezielt herbeiführen. Gewürfelt wird in jedem Takt, auch wenn schon 3 Bomben fallen. Sonst hinge
  die Folge der Würfe davon ab, wie viele Bomben gerade im Feld sind.
- **`seed` als Parametername.** Der Vertrag nennt ihn `seed`; das ist auch eine globale Funktion.
  `@warning_ignore("shadowed_global_identifier")` vor der Funktion schaltet die Warnung nur dort ab,
  wie bei `TimelineRun.seed`. Sonst wäre der Start mit `-d` nicht still.
- **Ereignisse statt Signale.** `step()` gibt eine Liste wie
  `[{ "event": Event.MARCH, "note": 2 }]` zurück. Signale bräuchten Verbindungen und wären in Tests
  umständlicher. So sieht der Aufrufer genau, was in diesem Schritt geschah, und die Seite macht
  daraus Töne. Der Kern spielt selbst keinen Ton und malt nichts. `drawables()` sagt nur, welches
  Muster wo liegt.
- **Werte an einer Stelle.** Alle Maße, Tempi, Zeiten und Punkte stehen oben als `const` unter
  „Werte aus dem Style-Guide, Spiel auf der Anzeige“. Abgeleitete Werte rechnet Godot aus den
  anderen, etwa `RIGHT_EDGE := FIELD.x - 1 - INSET` (157). Ändert Klaus in Phase 4 einen Wert im
  Style-Guide, gibt es im Code genau eine Stelle dafür.
- **Treffer sind Rechtecke.** `Rect2i(pos, size).intersects()` ist wahr, wenn sich zwei Rechtecke
  auf mindestens einem Pixel überschneiden; ein Berühren an der Kante reicht nicht. Das passt zu
  „gezählt einschließlich“: `Rect2i(Vector2i(75, 73), Vector2i(9, 5))` belegt x 75 bis 83 und y 73
  bis 77. Auf einem so kleinen Raster reicht das, Physik-Nodes wären zu viel (R6).
- **Halbieren mit `floori(x / 2.0)`.** Eine Ganzzahl-Division wie `9 / 2` warnt in Godot
  (`integer_division`), weil sie oft ein Versehen ist. Wie in `menu_paper.gd` steht deshalb da, was
  gemeint ist: abrunden.

### T012 Tests: Schritt für Schritt, mit festem Seed

- Jeder Test legt seine Partie selbst an und ruft `step()` in einer Schleife auf. Ein `await` gibt
  es nicht, also auch kein Warten auf Bilder. 27 Tests mit gut 17 000 Prüfungen laufen in rund
  4 Sekunden.
- Der Test sieht die Partie wie die Seite: Er liest `drawables()`, die öffentlichen Felder und die
  Ereignisse. In Felder mit Unterstrich greift er nicht. Eine Umbenennung im Inneren bricht ihn
  deshalb nicht, ein falsch gemaltes Teil aber schon.
- Für längere Partien gibt es einen **Testspieler** (`_spieler_schritt`): Er weicht jeder Bombe
  über der Kanone aus und fährt beim Zielen unter den waagrecht nächsten lebenden Außerirdischen.
  Ohne Ausweichen gingen die meisten Partien durch Treffer verloren; in einer Probe ohne Ausweichen
  verloren vier von fünf Seeds.
- **Landung „frühestens nach 1 Minute“.** Ohne Schuss und ohne Bewegung trafen in der Probe bei
  allen fünf Seeds drei Bomben die stehende Kanone, bevor der Block unten war. Gewählt habe ich: Der
  Testspieler weicht aus, schießt nicht, und es zählen nur Partien, die mit `LANDED` enden. Das
  misst dasselbe wie „ohne Bewegung“, denn der Weg des Blocks hängt nicht an der Kanone. Das prüft
  `test_der_block_haengt_nicht_an_der_kanone`: Bis zum ersten Treffer liegt der Block bei stehender
  und bei ausweichender Kanone Schritt für Schritt gleich. Ein Treffer hält den Block nur 60
  Schritte an. Er macht die Landung also später, nie früher, und die Untergrenze bleibt gültig. Ohne
  Treffer landet der Block immer nach 9 420 Schritten (157 s). Ein fester Seed, bei dem auch die
  stehende Kanone überlebt, wäre zerbrechlich: Ändert Klaus in Phase 4 ein Tempo, fiele der Test
  wegen des Seeds um und nicht wegen der Regel.
- **Obergrenze der Bomben, nachgebessert nach der Fehlerprobe (T014).** Ein Test, der nur
  „nie mehr als 3“ prüft, bleibt auch mit einer falschen Grenze grün, wenn der Fall „drei fallen,
  und der Wurf gelingt“ nie vorkommt. Mit `>` statt `>=` in `_maybe_drop_bomb()` blieb er das
  zunächst. Jetzt spielen 50 Seeds mit dem zielenden Testspieler: Der Block wird schnell, und die
  Bomben stauen sich. Eine Testhilfe zählt dabei, wie oft der Fall eintrat: `Beobachter`, eine
  innere Klasse im Test (`class Beobachter extends InvadersGame`), überschreibt
  `_maybe_drop_bomb()`, zählt und ruft dann mit `super()` das Original. Den Wurf sieht sie an einer
  Kopie des Generators voraus (`probe.seed = _rng.seed`, `probe.state = _rng.state`). Der Kern
  würfelt also unverändert weiter, und eine öffentliche API braucht er dafür nicht. Gemessen:
  4 149 solche Fälle über die 50 Seeds. Der Test verlangt mindestens einen, und mit der Mutation
  schlägt er bei Seed 1 ab Schritt 592 fehl.
- **Gleiche Partie:** Zwei Läufe mit gleichem Seed und festen Eingaben werden mit `var_to_str()`
  zu Text und Zeichen für Zeichen verglichen; ein anderer Seed ergibt eine andere Folge.

### Auslegungen in T011

Wo Vertrag, Datenmodell und Style-Guide nichts festlegen, gilt:

- **Reihenfolge in einem Schritt:** Explosionen altern; die Kanone fährt; der Schuss fliegt, ein
  neuer Druck schießt, Treffer; die Bomben fallen, Treffer an der Kanone; der Takt. Endet die
  Partie oder trifft eine Bombe, endet der Schritt dort. Ein Takt im selben Schritt wie der letzte
  Treffer findet also nicht mehr statt.
- **Der Schuss** startet mit seiner Unterkante direkt über der Spitze, an x `cannon_x + 4` (der
  mittleren Spalte) und y 69 bis 72. Im Schritt des Drucks prüft der Kern schon, ob er trifft;
  fliegen tut er ab dem nächsten Schritt. Er verschwindet, sobald er in die Kopfzeile (y 0 bis 7)
  flöge. Ein neuer Druck schießt auch im selben Schritt, in dem der alte oben verschwindet.
- **Ein Schuss, zwei Außerirdische:** Überschneidet er mehrere, zählt der unterste. Bei 1 Pixel
  Breite und 4 Pixel Höhe gegen 3 Pixel Abstand kommt das nicht vor, die Regel macht es trotzdem
  eindeutig.
- **Die Bombe** startet mit ihrer Oberkante direkt unter der Unterkante des Werfers, waagrecht
  mittig (`x + 3`, 2 breit in 8). Sie fällt ab dem zweiten Schritt nach dem Abwurf. Sie trifft die
  Kanone, sobald sich ihr Rechteck mit dem Rechteck der Kanone (9 × 5) überschneidet, auch an den
  leeren Ecken des Musters. Sie verschwindet, bevor sie unter y 77 ragen würde.
- **Abstand der Takte nach einem Treffer:** Stirbt ein Außerirdischer, gilt der kürzere Abstand
  schon für den laufenden Takt (`_march_timer` wird auf den neuen Abstand gekürzt, nie verlängert).
- **Takt am Rand:** Geprüft wird im Takt selbst. Steht die Außenkante der Lebenden in Fahrtrichtung
  schon am Innenrand (x 157 rechts, x 2 links), rückt dieser Takt tiefer statt zur Seite. Weil der
  Block bei x 34 beginnt und um 2 rückt, trifft er die Ränder genau.
- **Explosion an der Kanone:** Sie steht die ganze Pause von 60 Schritten an der Stelle der Kanone,
  nicht nur 15 Schritte, und auch nach dem letzten Treffer (`LOST`/`HIT`). Lage `cannon_x` und y 72:
  waagrecht fällt der halbe Pixel (9 gegen 8) nach links, senkrecht endet sie auf Zeile 77, damit
  sie nicht aus dem Innenrand ragt.
- **In der Pause** altern die Explosionen der Außerirdischen weiter; sonst steht alles, Eingaben
  zählen nicht. Im 60. Schritt kehrt die Kanone nach x 75 zurück, ohne Ereignis, und der Schritt
  danach spielt wieder normal.

## Phase 4

### T016 Texte: Breiten messen statt schätzen

- Die fünf Wortlaute stehen in `TitleTexts` als `INVADERS_*`, mit `%04d` und `%d` als Vorlage.
  `%` auf einem String ist in GDScript Formatieren wie `printf`: `"PUNKTE %04d" % 380` ergibt
  `PUNKTE 0380`.
- `test_title_texts.gd` misst mit derselben Schrift, die das Spiel nimmt: `Theme.get_font()` und
  `get_font_size()` für die Varianten `LcdHeader` (drucker) und `LcdRow` (menue), dann
  `Font.get_string_size()`. Die Grenzen kommen aus den Konstanten von `Communicator`,
  `InvadersGame` und `InvadersPage`, nicht als Zahl im Test; ändert sich ein Maß, misst der Test
  gegen das neue.
- `test_texte.gd` sucht die Anrede jetzt auch in Versalien. `SIE` ist kein Fehler des regulären
  Ausdrucks, sondern eine eigene Schreibweise; deshalb stehen die Versalien als eigene Wörter in
  `ANREDE`. Neue Treffer gab es im Projekt keine, `ERLAUBT` bleibt, wie es war.

### T017 Die Seite: `InvadersPage`

- **Fokus ist der Weg der Tasten.** Eine Taste geht in Godot zuerst an `_input()` aller Nodes,
  dann an das eine Control mit dem Tastaturfokus (`_gui_input()`), dann an `_unhandled_input()`.
  Deshalb nimmt `start()` den Fokus mit `grab_focus()`; dafür braucht die Seite `focus_mode = 2`
  (ALL) in der Szene. Die verborgenen Seiten des Menüs bekommen nichts, weil ein verborgenes Control
  keinen Fokus hat. So erreicht kein Pfeil das Menü des Titels (FR-017).
- **`accept_event()` hält eine Taste auf.** Danach sieht kein `_unhandled_input()` sie mehr, auch
  der Titel nicht. Die Seite verbraucht jede Taste ohne Cmd, Strg und Alt, auch unbekannte. Mit
  diesen Tasten kehrt `_on_key()` vorher zurück, ohne `accept_event()`: Cmd+Q und Strg+Cmd+F
  (`toggle_fullscreen`) kommen dann bei `GameWindow._unhandled_input()` und beim Betriebssystem an
  wie immer. Den Fall „Aktion `toggle_fullscreen` umbelegt“ fängt `key.is_action()` ab, mit
  `InputMap.has_action()` davor, weil `is_action()` bei einer unbekannten Aktion einen Fehler
  meldet.
- **Gehalten statt abgefragt.** Statt `Input.is_key_pressed()` merkt sich die Seite selbst, ob ein
  Pfeil unten ist (`_left_held`), und setzt bei jedem neuen Druck auf die Leertaste
  `_fire_pressed`. `echo` ist die Wiederholung, die das System schickt, solange eine Taste unten
  bleibt; sie zählt nie. So lässt sich die Seite mit erfundenen `InputEventKey` testen.
- **Fokus zurückholen, aber verzögert.** `focus_exited` ruft `_reclaim_focus.call_deferred()`. Der
  Aufruf läuft am Ende des Bilds und prüft erst dann, ob die Seite noch läuft, zu sehen ist und
  Fokus nehmen darf (`get_focus_mode_with_override()`; der Communicator sperrt beim Hinausfahren
  mit `focus_behavior_recursive`). Sofort zurückgeholt, würde der Fokus einem Bildschirm
  weggenommen, der die Seite gerade verbirgt (Analyse, C5).
- **Kein Fokusrahmen, ohne Code.** Den Rahmen malen Button, LineEdit und Co. aus ihrem Theme-Stil
  `focus`. Ein schlichtes `Control` hat keinen und malt nur, was `_draw()` malt.
- **Malen in `_draw()` auf dem Bildraster.** `_draw()` läuft nur, wenn `queue_redraw()` es
  verlangt, hier nach jedem Takt mit mindestens einem Schritt. Jedes gesetzte Pixel eines Musters
  wird ein `draw_rect()` von 2 × 2 an `(pos + pixel) * PIXEL`. Weil `pos` ganze Bildpixel sind und
  die Anzeige bei geraden Koordinaten liegt, liegt alles auf dem Bildraster; die Fotos zeigen kein
  Pixel daneben und keine dritte Farbe. Text malt `draw_string()` mit der Schrift aus dem Theme
  (`get_theme_font(&"font", &"LcdHeader")`). Die Lage ist die Grundlinie, nicht die Oberkante:
  „oben bündig bei y 1“ heißt deshalb Grundlinie bei 2 + Oberlänge, wie ein Label es täte.
- **Fester Schritt mit Zeitspeicher.** `_process(delta)` gibt die Zeit an `advance()`. Dort sammelt
  `_time_left` sie, und jede volle 1/60 s ist ein Schritt des Kerns. Ein Bild mit 1/120 s ergibt
  keinen Schritt, das nächste einen; 1/30 s ergibt zwei. Mehr als 4 Schritte je Aufruf gibt es
  nicht, der Rest verfällt: Nach einem Hänger springt das Spiel nicht (R6, SC-003). Tests rufen
  `advance()` selbst und schalten `autoplay` ab, dann zählt keine echte Zeit.
- **Benachrichtigungen statt Signal.** `_notification(what)` bekommt, was die Engine allen Nodes
  meldet. `NOTIFICATION_APPLICATION_FOCUS_OUT` und `…_FOCUS_IN` kommen, wenn das Fenster den Fokus
  verliert oder bekommt; der Szenenbaum reicht sie an jeden Node weiter. Ohne Fokus steht der Takt,
  die Pfeile gelten als losgelassen (ihr Loslassen käme nie an), und `stream_paused` hält jeden Ton
  an der Stelle an. Mit Fokus wird der Zeitspeicher geleert, damit nichts nachgeholt wird.
  `NOTIFICATION_VISIBILITY_CHANGED` kommt, wenn die Seite oder ein Elternteil verborgen wird; dann
  ruht die Partie bis zum nächsten `start()`.

- **Benachrichtigungen vor `_ready()`.** Nachgebessert nach Claudes Prüfung in T022: Im echten
  Fenster kam beim Start `NOTIFICATION_APPLICATION_FOCUS_IN`, bevor `_ready()` lief. Die
  `@onready`-Variablen der Player waren da noch null, und `_pause_sounds()` brach mit einem
  SCRIPT ERROR ab. Headless fiel das nicht auf: Ohne Fenster gibt es keinen Fokus des Fensters, und
  Godot schickt diese Benachrichtigungen nie; die Tests schickten sie bis dahin nur an eine fertige
  Seite. Jetzt gibt `_players()` vor `_ready()` (`is_node_ready()`) eine leere Liste,
  `_window_focused` wird trotzdem gesetzt, und `_ready()` hält die Player an, wenn das Fenster
  schon keinen Fokus hatte. `test_fokus_des_fensters_vor_ready_ohne_fehler` schickt beide
  Benachrichtigungen vor dem Einhängen; ohne die Wache meldet GUT den Fehler als „Unexpected
  Errors“. Merksatz: `_notification()` kann vor `_ready()` laufen, `@onready` gilt erst danach.

### T018 Töne: ein Player je Ton, einer für den Marsch

- Jeder `AudioStreamPlayer` spielt einen Ton zugleich; `play()` auf einem, der noch klingt, beginnt
  von vorn. Deshalb hat jeder Ton seinen Player, damit Schuss und Treffer sich nicht abschneiden,
  und die vier Marschtöne teilen sich `MarchSound`: Ein neuer Takt setzt `stream` und ruft
  `play()`, das schneidet den vorigen ab (CHK015). Alle sechs haben `bus = &"Effekte"` in der Szene.
- Godot hält mit `stream_paused` nur an, was gerade spielt; ein angehaltener Player meldet
  `playing` false, bis er weiterläuft. Ein stiller Player bleibt bei `stream_paused` false.
- `finished` und Verbergen rufen `stop()` auf allen Playern. Das Motiv für Sieg oder Niederlage
  klingt in der Ergebnisanzeige aus, weil dort noch niemand `stop()` ruft (FR-044).

### T019 Probeszene

- `invaders_probe.tscn` hängt die Seite wie ein Bildschirm direkt unter die Instanz des
  Communicators; dessen `_ready()` stellt sie auf die Anzeige. Die Probe zeigt sie mit
  `show_page()` und ruft erst danach `start()`, denn ein verborgenes Control kann keinen Fokus
  nehmen (Analyse, C1). Nach `finished` beginnt gleich die nächste Partie.

### T020 Tests: erfundene Eingaben über den Viewport

- Die Seite steht in einem eigenen `SubViewport`. `push_input()` gibt ein `InputEventKey` dort
  hinein wie eine echte Taste: über den Fokus an `_gui_input()` der Seite. Ein `Lauscher`, eine
  innere Klasse mit `_unhandled_input()`, steht für den Titel und schreibt mit, was durchkommt. So
  prüft der Test genau den Weg aus T017: Pfeile, Leertaste, Shift und unbekannte Tasten kommen nicht
  an, Cmd+Q, Strg+Cmd+F, Alt+Pfeil und die Aktion `toggle_fullscreen` schon.
- Für Sieg und Niederlage spielt der Test echte Partien mit Seed 1: einmal steht die Kanone, bis drei
  Bomben sie treffen, einmal zielt ein Testspieler wie in `test_invaders_game.gd`, aber über
  Tasten. Rund 3 000 Schritte laufen in Sekundenbruchteilen, weil nichts auf Bilder wartet.
- Headless spielt Godot ohne Ausgabe, `playing` wird trotzdem true (R15). Geprüft wird, welcher
  Player anläuft, nicht der Klang.

### Auslegungen in T017 bis T020

- **Kopfzeile senkrecht:** „Punkte oben bündig bei y 1“ habe ich wie ein Label gelesen: Die Zeile
  der Schrift beginnt bei Oberflächenpixel 2, die Grundlinie liegt bei 2 + Oberlänge (10). Die
  Versalien stehen dann in den Zeilen 5 bis 11, die Leben in 4 bis 11. Das entspricht der Vorschau
  im Style-Guide (`top: 2px`, `line-height: 12px`).
- **Ergebnisanzeige senkrecht:** je Zeile mittig wie ein Label, `floor((20 − Schrifthöhe) / 2)` über
  der Oberlänge; waagrecht `floor((320 − Breite) / 2)`.
- **Die Sperre zählt in Schritten** (30), nicht in Sekunden. So gilt für sie derselbe Deckel von 4
  Schritten je Bild wie für das Spiel, und ohne Fokus steht sie mit allem anderen.
- **Ein Schuss je Druck:** Hat ein Bild mehrere Schritte, schießt der Druck nur im ersten.
- **Esc und Loslassen nach dem Ende:** Nach `finished` nimmt die Seite nichts mehr an. Das
  Loslassen der Taste, die das Ende ausgelöst hat, geht deshalb durch; als Druck zählt es nirgends.
- **Verborgen heißt Ende ohne Meldung:** Die Seite ruht dann bis zum nächsten `start()`, auch wenn
  sie wieder gezeigt wird, und meldet kein `finished`.
- **Zwei Hilfen über den Vertrag hinaus,** beide statisch und ohne Zustand: `result_lines()` (die
  drei Zeilen der Ergebnisanzeige) und `life_pos()` (Lage eines Lebens). Sie machen Malen und
  Messen in den Tests gleich.

## Phase 5

### T025 Gehäusetasten: Klickflächen über einem Bild

- **Unsichtbare Controls über einem Bild.** Das Gehäuse ist ein `TextureRect`, und ein Bild weiß
  nicht, wo darin Tasten sind. Deshalb legt `_build_case_keys()` je Rechteck aus `case_keys` ein
  leeres `Control` (`CaseKey`) genau über die Taste: Lage und Größe in Bildpixeln mal `Case.scale`
  (×2). Es malt nichts, fängt aber mit `mouse_filter = STOP` die Maus. Alles darum herum
  (Communicator, `Case`, `Keys`) steht auf IGNORE und lässt die Maus durch; deshalb tut ein Klick
  daneben weiter nichts. Die Klickflächen hängen unter `Keys`, einem eigenen Control ohne Skript
  über `Case` und unter den Seiten.
- **Kein `Button`.** Ein Button nimmt Fokus und löst mit Enter und Leertaste aus, und sein Theme
  bringt eine Hover-Farbe mit (R4). `CaseKey` setzt in `_init()` `focus_mode = FOCUS_NONE` und den
  Pfeil als Zeiger; das ist alles, was es an Bedienung braucht.
- **Warum beim Loslassen gezählt wird.** Godot gibt einem Control, auf dem die Maustaste
  heruntergeht, den **Mausfokus**: Das Loslassen kommt dort an, gleich wo die Maus inzwischen
  steht, und `event.position` ist dann lokal zu dieser Taste, notfalls außerhalb. `_gui_input()`
  prüft mit `Rect2(Vector2.ZERO, size).has_point()`, ob die Maus noch drauf ist, und meldet nur
  dann `pressed`. So nimmt der Spieler einen Druck zurück, indem er wegzieht, wie bei jedem Knopf.
  Der Klick kommt dagegen beim Drücken, weil eine echte Taste beim Drücken klickt.
- **`accept_event()` nur für links.** Rechte und mittlere Maustaste lässt `_gui_input()` liegen.
  Dass sie trotzdem nicht zum Bild darunter durchgehen, macht `mouse_filter = STOP` selbst (siehe
  „Offen“ im Bericht).
- **Die Sperre aus Feature 005 gilt von selbst.** `mouse_behavior_recursive = DISABLED` wirkt auf
  den ganzen Teilbaum, also auch auf `Keys/CaseKey*`, die erst zur Laufzeit entstehen. Nur eine
  Taste, die gerade unten ist, bekäme ihr Loslassen nicht mehr; dafür ruft `_set_locked(true)`
  `cancel()`, und die Taste geht hoch, ohne zu zählen.
- **Malen mit dem Signal `draw`.** `Keys` hat kein Skript. `_ready()` verbindet
  `_keys.draw` mit `_draw_case_keys()`, und darin malt der Communicator mit `_keys.draw_rect()` und
  `_keys.draw_texture_rect_region()` *auf* `Keys`. Das geht, weil `draw` genau dann kommt, wenn
  `Keys` malen darf. Im `_draw()` des Communicators selbst ginge es nicht: Ein Node malt sich vor
  seinen Kindern, das Gehäuse `Case` läge also darüber.
- **Ausschnitt aus einer Textur.** `draw_texture_rect_region(textur, ziel, quelle)` malt das
  Rechteck `quelle` (in Pixeln der Textur) gestreckt auf `ziel`. Für eine eingedrückte Taste ist
  `quelle` die Taste ohne ihre unterste Zeile und `ziel` dasselbe eine Bildpixelzeile tiefer, ×2.
  Mit `texture_filter = NEAREST` auf `Keys` bleibt jedes Pixel ein 2 × 2-Block wie im Gehäuse. Die
  frei werdende oberste Zeile füllt `draw_rect()` in der Farbe des Pixels links neben der Taste;
  die liest `Texture2D.get_image().get_pixel()` aus dem Gehäusebild. Kein neues Bild, keine neue
  Farbe. `_pressed_layers()` liefert die Rechtecke und die Farbe als Daten, damit der Test sie ohne
  Bild prüfen kann, wie `_placeholder_layers()` aus Feature 005.
- **Im nächsten Bild.** `down_changed` ruft `_keys.queue_redraw()`. Godot malt nicht sofort, sondern
  merkt sich das und ruft `draw` einmal am Ende des Bilds, auch wenn mehrere Tasten sich ändern.
- **Setter an einem `@export`.** `case_keys` hat einen Setter wie `display_rect`: Vor `_ready()`
  setzt die Szene den Wert nur (die Kinder gibt es noch nicht), danach baut der Setter die
  Klickflächen neu. `is_node_ready()` unterscheidet die beiden Fälle.
- **Warum der Communicator die Folge nicht kennt.** Er meldet nur `case_key_pressed(index)`. Was
  links, Mitte, rechts bedeutet, weiß der Titel (Teil 2, `KeySequence`). Ein anderer Bildschirm mit
  demselben Gerät kann die Tasten für etwas anderes nutzen oder sie gar nicht freigeben; die
  Vorgabe `[]` heißt: ein Gehäuse ohne drückbare Tasten (R1; Analyse, I2).

- **Fokus des Fensters weg (Nachtrag nach der Phasenprüfung).** Verliert das Fenster den Fokus,
  ruft Godot an jedem Node `_notification(NOTIFICATION_APPLICATION_FOCUS_OUT)` auf; `CaseKey`
  ruft dann `cancel()`. Vorher kann aber schon etwas anderes kommen: Der Viewport gibt beim
  Fensterfokus den Mausfokus ab und schickt dem Control, das ihn hatte, selbst ein Loslassen,
  vorbei an `push_input()`, mit `device` −2 (`DEVICE_ID_INTERNAL` im Quelltext von Godot, in
  GDScript nicht als Konstante da). Steht die Maus dabei über der Taste, sähe das aus wie ein
  echter Druck. `_gui_input()` erkennt es am Gerät und lässt die Taste ohne `pressed` hoch. Ein
  echtes Loslassen danach findet die Taste oben und tut nichts.
- **`queue_free()` beim Neubau, nicht `free()`.** Ein Bildschirm könnte `case_keys` in seiner
  Antwort auf `case_key_pressed` ändern, also während die Taste noch ihr Signal sendet. `free()`
  löschte sie mitten in ihrem eigenen Aufruf. `queue_free()` löscht am Ende des Bilds; bis dahin
  hängt sie schon nicht mehr unter `Keys` (`remove_child()`) und zählt nicht mehr mit. GUT meldet
  solche Nodes als „Orphans“, wenn der Test vor dem Ende des Bilds aufhört; deshalb wartet
  `test_case_keys_zur_laufzeit_neu_gebaut` nach jedem Neubau ein Bild.

### T026 Probe und Tests

- Die Tests drücken mit erfundenen `InputEventMouseButton` über `push_input()` in einem eigenen
  `SubViewport`, wie die Klicks aus Feature 005. Ein Druck und ein Loslassen sind zwei Ereignisse;
  dazwischen prüft der Test `is_case_key_down()`.
- Headless entsteht kein Bild, `draw` kommt aber trotzdem. Der Test
  `test_eingedrueckt_im_naechsten_bild_gemalt` hängt sich an `Keys.draw` und sieht, dass nach einem Bild mit der Taste unten gemalt
  wurde. Wie es aussieht, zeigen die Bildschirmfotos.
- Die Probeszene setzt `case_keys` in der `.tscn` als `Array[Rect2i]([...])`, so wie es der Titel
  in Teil 2 tun wird, und zeigt einen gezählten Druck als Meldung „Gehäusetaste 2 gedrückt.“.

### Auslegungen

- `test_teile_in_der_richtigen_reihenfolge` aus Feature 005 erwartet jetzt auch `Keys` und
  `KeyClick` vor den Seiten; das verlangt der Szenenaufbau im Vertrag.
- Eingedrückt nach dem Style-Guide: Der Ausschnitt ist die Taste **ohne ihre unterste Zeile**
  (Zeilen 114 bis 120), gemalt auf 115 bis 121. Zeile 114 bekommt die Spaltfarbe. Der Vertrag sagt
  an einer Stelle „ohne ihre oberste Zeile“; so wörtlich reichte der Ausschnitt eine Zeile unter
  die Taste.
- Die Spaltfarbe ist das Pixel links neben der obersten Zeile der Taste, je Taste eigens gelesen
  (bei G-03 drei leicht verschiedene dunkle Töne aus dem Bild).

### T029 Eine Folge ohne Node: `KeySequence`

- **`RefCounted` statt Node.** Die Folge hat keine Lage, malt nichts, braucht keinen Takt und kein
  Signal; sie ist nur ein Zähler mit einer Regel. Ein Node müsste in den Baum, ein `RefCounted`
  nicht: Der Titel legt sie mit `KeySequence.new(EASTER_EGG_KEYS)` als gewöhnliche Variable an, und
  Godot gibt sie frei, sobald niemand mehr darauf verweist, hier mit dem Titel. Wie `InvadersGame`
  in Phase 3 lässt sie sich deshalb ohne Szene testen: `test_key_sequence.gd` ruft nur `press()`.
- **`press()` gibt die Antwort zurück, statt ein Signal zu senden.** Wer drückt, will sofort wissen,
  ob die Folge voll ist; ein Rückgabewert ist dafür der kürzeste Weg. Ein Signal lohnt sich erst,
  wenn mehrere unabhängig zuhören.
- **Die Regel bei einem falschen Druck** (FR-003): zurück auf 0, außer der Druck ist der Anfang der
  Folge, dann auf 1. Deshalb startet 1-1-2-3, 1-2-2-3 aber nicht.
- **`expected.duplicate()`** im Konstruktor: Arrays sind in GDScript Verweise. Ohne Kopie änderte
  ein Aufrufer, der sein Array später ändert, auch die Folge.

### T030 Der Titel: Folge, Start und Rückweg

- **Warum der Titel die Folge kennt und der Communicator nicht.** Der Communicator meldet nur
  `case_key_pressed(index)`: Eine Taste ist gedrückt. Ob sie zählt, hängt davon ab, was auf dem
  Bildschirm gerade los ist (`_accepts_input()`, Spiel schon auf der Anzeige), und was die Folge
  auslöst, ist eine Seite des Titels. Beides weiß nur der Titel. So bleibt der Communicator ein
  Baustein, den die Probeszene ganz anders nutzt (sie zeigt nur eine Meldung).
- **Die Seite steht in der Szene, nicht zur Laufzeit erzeugt.** `Invaders` ist eine Instanz von
  `invaders_page.tscn` unter dem Communicator wie die vier Blätter. `Communicator._ready()` stellt
  sie auf die Anzeige und verbirgt sie, `show_page()` zeigt sie. Dass sie existiert, kostet nichts:
  Verborgen taktet sie nicht (Phase 4).
- **Signale im Code verbunden.** Die vier Blätter sind in der `.tscn` verbunden, `case_key_pressed`
  und `finished` in `_ready()`, wie der Vertrag es sagt. Beides ist gleichwertig; im Code steht es
  neben dem Kommentar, warum.
- **Reihenfolge beim Start: erst merken, dann zeigen, dann starten.** `gui_get_focus_owner()` liefert
  das Control mit dem Tastaturfokus, hier eine Zeile des Blatts. Das muss *vor* `show_page()`
  gemerkt werden: Ein Control, das unsichtbar wird, gibt seinen Fokus ab. Und `start()` kommt erst
  nach `show_page()`, weil `grab_focus()` auf einem unsichtbaren Control nichts tut (Analyse, C1).
  Die Gehäusetasten haben `focus_mode = NONE`; der Klick auf die dritte Taste lässt den Fokus also
  auf der Zeile, und genau die kommt zurück.
- **Fokus zurückgeben.** Bei `finished` zeigt der Titel die gemerkte Seite und ruft `grab_focus()`
  auf das gemerkte Control. Ist es zu der Zeit noch nicht sichtbar, kommt der Aufruf mit
  `call_deferred()` am Ende des Bilds. Nach `show_page()` ist es aber schon sichtbar, denn
  `show()` wirkt sofort.
- **Warum der Hinweis eigens zurückkommt.** Bekommt eine Zeile des Menüs den Fokus, meldet das Menü
  `selection_changed`, und der Hinweis erscheint von selbst. Die Liste meldet nur, wenn sich die
  Zeile *ändert*; nach dem Spiel ist es dieselbe. Deshalb ruft `_on_invaders_finished()` am Ende
  `show_hint(_selected_hint, _current_row())`. Die Gegenprobe ohne diese Zeile: Nach dem Spiel aus
  der Liste fehlt der Hinweis.
- **Eine Meldung kommt als Hinweis zurück.** `_hide_hint()` beim Start vergisst auch, zu welchem
  Spielstand „Löschen ging nicht“ gehört (`_warning_number = -1`). `_selected_hint` ist immer der
  Hinweis der Zeile, auch wenn daneben gerade die Meldung stand; also kommt der Hinweis zurück.
- **Die Esc-Wache.** Esc geht zuerst an das Control mit dem Fokus, die Spielseite, und die
  verbraucht es mit `accept_event()`. Nur ohne Fokus, etwa in dem Bild, bevor die Seite ihn sich
  zurückholt, käme Esc bis `_unhandled_input()` des Titels und führte dort eine Ebene zurück. Darum
  markiert der Titel es als behandelt, solange `Invaders` sichtbar ist, und tut nichts.
- **Das Loslassen der Taste, die das Spiel beendet**, kommt bei der Zeile an, die gerade den Fokus
  zurückbekommen hat. Ein `Button` löst mit Enter nur aus, wenn er auch das Drücken bekommen hat;
  der Test mit Enter in der Ergebnisanzeige zeigt, dass danach nichts beginnt.

### T031 Tests

- Die Gehäusetasten bekommen ihre Klicks dort, wo sie gerade stehen
  (`Keys/CaseKey<n>.get_global_rect()`), auch während der Fahrt hinaus. Der Druck ist ein
  `InputEventMouseButton` gedrückt und losgelassen über `push_input()` wie in Feature 005.
- `_zustand_des_titels()` fasst Seite, Auswahl, Fokus und Hinweis (Text, Art, Lage) in ein
  Dictionary, Fokus als Pfad: Ein Unterschied steht dann lesbar im Protokoll, nicht als
  Objektnummer.
- Gemessen wird mit `Time.get_ticks_usec()`: SC-001 vom dritten Druck, bis die Seite den Fokus hat;
  SC-006 von `finished`, bis Spiel weg, Wache offen und der Fokus wieder auf der gemerkten Zeile
  ist. Beides geschieht im selben Aufruf, die Werte liegen bei einem Zehntel einer Millisekunde.
- Das Schließen des Fensters schickt der Test wie `test_werkstatt_scene.gd` als
  `NOTIFICATION_WM_CLOSE_REQUEST` an Session und Titel mit allen Knoten. Der Titel behandelt es
  nicht selbst; die Session speichert nur, wenn ein Spiel läuft, und das Easter Egg ist keins.

### Auslegungen in T029 bis T031

- **Fallback ohne Fokus.** Hatte beim Start kein Control den Fokus (im Titel bisher nicht gesehen),
  wählt die gemerkte Seite mit `select(selected_index())` ihre Zeile neu, damit die Tastatur nicht
  ins Leere geht. Der Vertrag nennt nur „Fokus zurück auf das gemerkte Control“.
- **Reset der Folge** beim Start (zusätzlich zu dem in `press()`) und bei `finished`. Ein neuer
  Titel hat eine neue Folge; ein eigener Reset in `_build_sheets()` ist deshalb nicht nötig.
- **SC-006 nur über Esc und die Niederlage gemessen.** Sieg und Niederlage nehmen denselben Weg
  über `finished`; eine Partie bis zum Sieg zu spielen, prüft schon `test_invaders_page.gd`.
- **Probeszene:** Die Meldung „Ausgelöst: …“ rechnet jetzt wie die der Gehäusetasten relativ zum
  Communicator (`_current_row()`); vorher lag sie unter dem Bildrand, wenn die Zeile gewählt war,
  während das Gerät noch draußen stand. Neuer Test
  `test_probeseite_meldung_eines_eintrags_steht_im_bild`; ohne die Reparatur scheitert er.
