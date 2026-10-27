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
