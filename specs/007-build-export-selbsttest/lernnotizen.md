# Lernnotizen: Build & Export mit Selbsttest

Zu jeder umgesetzten Task die Godot-Konzepte und warum es so gebaut ist, an den Stellen im
Projekt. Bei `[A]`-Tasks schreibt der Agent die Notizen, Claude trägt sie je Phase hier ein; baut
Klaus eine Task selbst, schreibt Claude die Notiz beim Review. Abnahmen und Phasenprüfungen bauen
nichts und haben deshalb keine Notiz.

## Phase 1

### T001 Lauf und Ablauf: Klassen ohne Node

- **Kein Node, wie `TimelineRun`.** `SelbsttestLauf` und `SelbsttestAblauf` erben von
  `RefCounted`. Sie hängen nicht im Szenenbaum, haben kein `_process()` und warten auf nichts.
  Der Lauf hält nur fest, was geplant ist und was herauskam; der Läufer in Phase 2 wird ein Node,
  weil er auf Bilder warten (`await`) und das Schließen des Fensters hören muss. Dieselbe Teilung
  wie beim Fahrplan: `TimelineRun` rechnet, das Autoload `Timeline` hängt ihn an die Uhr. Deshalb
  prüft `test_selbsttest_lauf.gd` alle Regeln ohne Fenster in Millisekunden.
- **Innere Klasse `SelbsttestLauf.Schritt`.** Ein Schritt gehört nur zum Lauf, deshalb steht er
  als `class Schritt:` in derselben Datei statt in einer eigenen. Von außen heißt er
  `SelbsttestLauf.Schritt`, und typisierte Listen wie `Array[Schritt]` gehen damit. Innerhalb
  der inneren Klasse steht der Status als `SelbsttestLauf.Status`, mit dem Namen der äußeren
  Klasse; so ist eindeutig, welches `Status` gemeint ist.
- **`enum Status` mit `OFFEN`.** Der Vertrag kennt drei Ergebnisse. Bis ein Schritt eines hat, ist
  er `OFFEN`; im Protokoll gibt es das nicht. Wie ein Status im Protokoll heißt, steht in
  `STATUS_TEXT`, nicht in `Status.keys()`. Die Namen im Code dürfen sich ändern, die Wörter im
  Protokoll nicht, denn Claude liest sie zeilenweise.
- **Alles einplanen, dann melden.** Der Läufer gibt dem Lauf mit `plane()` zu Beginn alle Abläufe
  mit allen Schritten. So steht `gesamt()` für „Schritt 12 von 40“ fest, und auch ein Schritt,
  der nie läuft, hat seine Beschreibung für die Liste der Zusammenfassung.
- **Die Regeln stehen im Lauf, nicht im Läufer.** `melde_fehler()` setzt den Rest des Ablaufs auf
  „Fehler in Schritt …“ und ruft `_sperre_abhaengige()`. Die sucht mit `_ursache()` rekursiv über
  `baut_auf` den Ablauf, in dem der Fehler steckt; die Liste `gesehen` verhindert eine Endlosschleife,
  falls zwei Abläufe versehentlich aufeinander aufbauen. Der Läufer fragt dann nur noch
  `ablauf_offen()` und überspringt, was nicht laufen soll.
- **Eine Basisklasse zum Überschreiben.** `SelbsttestAblauf.schritte()` gibt in der Basisklasse
  eine leere Liste; jeder Ablauf ab Phase 2 erbt (`extends SelbsttestAblauf`) und überschreibt
  sie, wie `ErfundenerAblauf` im Test. Ein Schritt ist ein Dictionary mit `Callable`s für
  Eingaben und Prüfung: Ein `Callable` ist eine Funktion als Wert, die man speichern und später
  mit `.call()` oder `await …call()` ausführen kann. `neuer_schritt()` baut das Dictionary immer
  mit denselben Schlüsseln.

### T002 Ein Formatierer für zwei Ausgaben

- **Eine Funktion, drei Texte.** `SelbsttestProtokoll._text()` schreibt Protokoll, Text für
  „Kopieren“ und Text bei nicht beschreibbarem Ordner; die öffentlichen Funktionen `protokoll()`,
  `kopieren()` und `kopieren_nicht_beschreibbar()` rufen sie nur mit einer anderen `_Art`. Weil
  es keine zweite Stelle gibt, die Schlüssel schreibt, können Datei und kopierter Text nicht
  auseinanderlaufen (FR-014a). Der Test
  `test_kopieren_unterscheidet_sich_nur_in_den_schritten_ok_und_dem_ordner` hält das fest.
- **`static func`.** Alle Funktionen sind statisch: Man ruft `SelbsttestProtokoll.protokoll(lauf)`,
  ohne ein Objekt anzulegen. Das passt, weil der Formatierer keinen eigenen Zustand hat.
- **Typen bis zum Schluss, Text erst am Rand.** In den Systemdaten steht `Vector2i(3024, 1964)`
  und `2.0`, nicht schon fertiger Text. Erst `wert()` macht daraus mit `match typeof(inhalt)`
  „3024x1964“ und „2.0“, aus `null` und `""` wird „unbekannt“, aus jedem Zeilenumbruch „⏎“. So
  gibt es eine Stelle für die Maschinenform. Godots `str(2.0)` ist „2.0“; `snappedf()` rundet
  Kommazahlen vorher auf zwei Stellen, sonst stünde bei 59,94 Hz „59.94000244140625“ da.
- **Zeilenende `\n` überall.** Die Zeilen sammelt eine `PackedStringArray`, `"\n".join()` setzt
  sie zusammen. Godot schreibt mit `FileAccess.store_string()` genau diese Bytes, als UTF-8 ohne
  BOM, auch unter Windows; ein `\r\n` entsteht nirgends.
- **Texte in einer eigenen Klasse.** `SelbsttestTexte` hat nur Konstanten und statische
  Funktionen, wie `TitleTexts` im Titel. Die Zahl „von 1 Schritt“, „von 2 Schritten“ steckt in
  `_von_schritten()`, damit der Dativ nur einmal richtig sein muss.
- **Byte für Byte vergleichen.** Der Test macht aus dem Text mit `to_utf8_buffer()` Bytes und
  vergleicht sie mit `FileAccess.get_file_as_bytes()` der Erwartung. Steht etwas anders da, sucht
  `_vergleiche()` die erste abweichende Zeile und nennt sie, statt nur „ungleich“ zu melden.

### T003 Systemdaten und ein Thread

- **Woher die Werte kommen.** `OS` kennt Betriebssystem, Prozessor und Sprache,
  `RenderingServer` Grafikkarte, Renderer und Schnittstelle, `DisplayServer` Bildschirm, Fenster
  und Tastatur. Headless gibt es keinen Bildschirm (`window_get_current_screen()` ist −1) und
  keine Grafikkarte; dann bleibt der Wert `null` und steht als „unbekannt“ im Protokoll. Der
  Test prüft deshalb nur, dass jeder Schlüssel da ist.
- **Ein `Thread` für langsame Aufrufe.** `OS.get_video_adapter_driver_info()` kann unter Windows
  und Linux Sekunden dauern (R20). `erhebe()` startet sie mit `Thread.start(_lies_treiber)` in
  einem eigenen Thread; das Spiel läuft unterdessen weiter. `hole_treiber()` wartet mit
  `wait_to_finish()` und bekommt dabei den Rückgabewert der Funktion. Jeder gestartete Thread muss
  so abgeholt werden, sonst warnt Godot; deshalb holt `_notification(NOTIFICATION_PREDELETE)` ihn
  zur Not ab, bevor das Objekt verschwindet.
- **Austauschbar für Tests.** Wie liest, steht in der Variable `treiber_leser`, einem `Callable`,
  und ob gelesen wird, in `mit_treiber`. Der Test setzt beide und prüft so den Weg durch den
  Thread auch auf dem Mac. Dasselbe Muster wie `GameSession.now` und `GameSession.rng`.

### T004 Logger, Threads und Zip

- **`Logger`.** Seit Godot 4.5 gibt es die Klasse `Logger`. Eine Unterklasse, angemeldet mit
  `OS.add_logger()`, bekommt jede Ausgabe zusätzlich zu Godots eigener: `_log_message()` für
  `print()` und `printerr()`, `_log_error()` für Fehler und Warnungen, auch aus `push_error()` und
  `push_warning()`. Beide sind virtuelle Methoden, also solche, die Godot aufruft und wir
  überschreiben, wie `_ready()`.
- **Aus fremden Threads.** Godot ruft den Logger in dem Thread, der gerade etwas ausgibt. Gibt der
  Thread aus T003 eine Warnung aus, während der Läufer einen Schritt wechselt, greifen zwei Threads
  zugleich auf `_zeilen` zu. Deshalb steht jeder Zugriff zwischen `_mutex.lock()` und
  `_mutex.unlock()`: Ein `Mutex` lässt immer nur einen Thread hinein, der andere wartet.
  `test_mehrere_threads_zugleich` schreibt aus drei Threads 600 Zeilen und prüft, dass keine
  verloren geht oder zerrissen ist.
- **Selbst still.** Der Logger ruft nie `print()`. Das liefe wieder in `_log_message()` und so
  fort, ohne Ende.
- **Wo es wirklich geschah.** Bei `push_warning()` nennt Godot als Ort seine eigene C++-Datei
  (`core/variant/variant_utility.cpp`). Die Stelle im Skript steht im ersten `ScriptBacktrace`,
  Bild 0; das nimmt `_log_error()`, wenn es eines gibt.
- **GUT zählt Fehler mit.** GUT meldet sich selbst als Logger an und lässt einen Test scheitern,
  in dem Godot einen unerwarteten Fehler ausgibt. `test_nicht_beschreibbar_mit_pfad` erwartet den
  Fehler von `make_dir_recursive_absolute()` deshalb ausdrücklich mit `assert_engine_error()`.
- **`user://` und echte Pfade.** `user://` ist der Datenordner der App, unter macOS in
  `~/Library/Application Support/Godot/app_userdata/<Name>/`. `ProjectSettings.globalize_path()`
  macht daraus den Pfad, den Finder und Klaus kennen; den zeigt die Zusammenfassung.
- **`ZIPPacker`.** `open()` legt das Zip an, dann je Datei `start_file()`, `write_file()` mit den
  Bytes und `close_file()`, am Ende `close()`. Es ist immer nur eine Datei im Zip offen. Die Pfade
  im Zip beginnen ohne den Ordner des Laufs (`protokoll.txt`, `fotos/titel.01_start.png`); der Test
  liest das Zip mit `ZIPReader` zurück.
- **Umstellbarer Basisordner.** `SelbsttestAblage.new(lauf_id, basis)` nimmt einen eigenen
  Basisordner, wie `GameSession.folder`. Die Tests schreiben nach `user://test_selbsttest_ablage/`
  und räumen ihn in `after_each()` weg.

### T005 Statische Stellschraube statt Abhängigkeit

- **`static var`.** `SaveGame.time_zone_bias` gehört zum Skript, nicht zu einem Spielstand. Es gibt
  sie genau einmal im Programm, und sie gilt, bis jemand sie ändert. Der Selbsttest setzt sie in
  Phase 2 beim Start einmal auf 60 (UTC+1); danach zeigt die Liste „zuletzt gespielt“ auf jedem
  Rechner dieselbe Uhrzeit, und die Fotos bleiben gleich (R7).
- **Die Richtung der Abhängigkeit.** Das Spiel weiß nichts vom Selbsttest: `save_game.gd` nennt
  keine Klasse aus `tools/selbsttest/` und fragt nicht nach dem Feature-Tag. Der Selbsttest kennt
  das Spiel und dreht an der Schraube. So lässt der normale Export `tools/` weg, ohne dass im Spiel
  ein Verweis ins Leere zeigt (SC-005). Verworfen: `SaveGame` fragt
  `OS.has_feature("selbsttest")`, weil dann das Spiel den Selbsttest kennen müsste; ein Parameter
  durch Liste und Titel, weil er viele Stellen im Spiel ändern würde.
- **Vorgabe ändert nichts.** Ohne Selbsttest steht sie auf `SYSTEM_BIAS`, der Marke für „wie der
  Rechner“. `_local_time()` nimmt einen ausdrücklich übergebenen Versatz zuerst, dann die
  Stellschraube, dann den Rechner; alle bisherigen Aufrufe laufen wie vorher.
- **Tests räumen auf.** Weil sie für das ganze Programm gilt, setzt jeder Test sie danach zurück,
  und `after_each()` in `test_save_game.gd` tut es zur Sicherheit noch einmal. Sonst hinge ein
  späterer Test von der Reihenfolge ab.

### Auslegungen in T001 bis T005

- **Vier Schlüssel der Systemdaten liegen im Lauf.** `selbsttest.version`, `lauf.start`,
  `lauf.feste_zeit` und `lauf.zeitraffer` misst kein System; sie stehen in `SelbsttestLauf`.
  `SelbsttestSystem.LAUF_SCHLUESSEL` nennt sie, und der Test prüft, dass System und Lauf zusammen
  genau die 24 Schlüssel der Tabelle haben.
- **Grund über mehrere Stufen.** Baut `loeschen` auf `laden` und `laden` auf `neues_spiel`, und
  scheitert `neues_spiel`, dann nennen beide „Fehler in Ablauf neues_spiel“, den Ablauf mit dem
  Fehler.
- **Abbruch.** Der Schritt, in dem das Fenster geschlossen wurde, und alle danach heißen „Fenster
  geschlossen“; was schon lief, bleibt.
- **Meldung bei nicht beschreibbarem Ordner.** Sie steht als letzte Zeile nach `# System`, mit
  einer Leerzeile davor; ohne `ergebnis:`, weil nichts lief.
- **`printerr()` zählt als Meldung**, `print()` nicht.
- **Treiber mit Name.** `system.gpu_driver` ist „Name Version“, etwa „nvidia 550.54.14“: Unter
  Linux sagt der Name, ob der Treiber des Herstellers läuft.
- **`godot.version` immer mit drei Zahlen**, auch bei einer Version x.y.0.
