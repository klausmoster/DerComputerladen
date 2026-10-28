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

## Phase 2

### T011 Feature-Tag, Overrides und ein zweites Preset

- **Feature-Tag.** Das Preset „Selbsttest macOS“ in `src/export_presets.cfg` trägt
  `custom_features="selbsttest"`. Godot schreibt diesen Tag in die gebaute App; dort ist
  `OS.has_feature("selbsttest")` wahr, im Editor und im Spiel nicht. Alles andere übernimmt das
  Preset von „macOS“; nur Name, Bundle-ID, Ziel und Ausschluss weichen ab. „macOS“ selbst blieb Byte
  für Byte gleich.
- **Override mit Punkt.** In `src/project.godot` stehen `config/name.selbsttest` und
  `run/main_scene.selbsttest`. Ein Schlüssel `einstellung.tag` ersetzt `einstellung`, wenn der Tag
  gesetzt ist. Die Selbsttest-App heißt deshalb „Der Computerladen Selbsttest“, hat damit ihren
  eigenen Datenordner (`app_userdata/Der Computerladen Selbsttest/`) und startet in
  `tools/selbsttest/selbsttest_start.tscn`. Das Spiel enthält beide Zeilen auch, aber ohne Tag wirken
  sie nicht. Es braucht also keinen Autoload und keine Zeile Code im Spiel.
- **`get_setting()` gegen `get_setting_with_override()`.** `ProjectSettings.get_setting(
  "application/config/name")` gibt auch in der Selbsttest-App „Der Computerladen“, den Grundwert.
  Erst `get_setting_with_override()` beachtet den Tag. Godot selbst liest Name und Hauptszene mit
  Override; der Code des Selbsttests braucht in Phase 2 keine überschriebene Einstellung. Wer später
  eine liest, nimmt `get_setting_with_override()`.
- **Ausschluss.** Das Preset „macOS“ schließt `tools/*` aus, der Selbsttest nur `addons/gut/*` und
  `test/*`. Geprüft am Paket: Im Spiel steht `selbsttest_laeufer` 0-mal, im Selbsttest 4-mal.

### T012 Der Weg eines Ereignisses und warum der Filter am Fenster sitzt

- **Der Weg.** Das Betriebssystem meldet eine Taste. Der DisplayServer macht daraus ein `InputEvent`
  und gibt es an `Input.parse_input_event()`; `Input` merkt sich den Zustand der Tasten und reicht
  das Ereignis an den Empfang des Fensters weiter. Erst der gibt es mit `Window.push_input()` in den
  Baum: Hover ausrechnen, dann `_input()`, dann die Oberfläche (`gui_input`, Fokus, Buttons), dann
  `_unhandled_input()`.
- **Warum am Fenster.** `SelbsttestEingabe.einschalten()` ersetzt mit
  `DisplayServer.window_set_input_event_callback()` genau diesen Empfang. Echte Ereignisse kommen
  dort an und gehen nicht weiter. Die eigenen kommen über denselben Weg wie echte, nämlich durch
  `Input.parse_input_event()`, und tragen `device = 4711`, also lässt der Filter sie durch. Ein
  Knoten mit `_input()` käme zu spät, denn Godot rechnet das Hover vor `_input()` aus.
- **Godot 4.7 hat Geräte für Tastatur und Maus.** Echte Tasten tragen `device = 16`
  (`InputEvent.DEVICE_ID_KEYBOARD`), die Maus `32` (`DEVICE_ID_MOUSE`). Die Aktionen `ui_accept`,
  `ui_cancel`, `ui_focus_next` usw. gelten nur für Gerät 16. Eine Taste mit 4711 löste also kein
  Enter aus. `fuer_das_spiel()` gibt deshalb jedem eigenen Ereignis beim Weiterreichen eine Kopie
  mit dem echten Gerät. 4711 ist nur das Kennzeichen auf dem Weg bis zum Filter.
- **Eine Lambda hält ihr Objekt fest.** Der Empfang ist `func(event): _empfange(event)`. Eine Lambda
  in einem `RefCounted` hält einen Verweis auf `self`; solange Godot den Empfang aufbewahrt, bleibt
  die Eingabe am Leben. Ein gewöhnliches Callable wie `_empfange` merkt sich nur die Kennung des
  Objekts. Wäre das Objekt weg, käme keine Eingabe mehr an, auch keine echte.
- **Zwei Bilder für einen Klick.** Drücken und Loslassen gehen in zwei Bildern hinaus
  (`await viewport.get_tree().process_frame`). Vor jedem Klick kommt eine Bewegung aufs Ziel, damit
  Hover und `mouse_entered` entstehen wie bei einer echten Hand. `Input.use_accumulated_input =
  false`, weil Godot sonst Mausbewegungen eines Bilds zusammenfasst.

### T013 Der Fahrer: Ziele über ihre Bedeutung

- **Lesen, was da ist.** `SelbsttestFahrer` findet Einträge über `MainMenu.entries` und die Buttons
  in `Rows`, Zeilen der Liste über das Label `Name`, Gehäusetasten unter `Communicator/Keys`, den
  Knopf über `LeaveButton`. Er nutzt nur öffentliche Methoden und die Knotennamen der Szenen. Am
  Spiel änderte sich nichts. Rückt ein Knopf, stimmt das Rechteck trotzdem, denn es wird zur
  Laufzeit gelesen (`get_global_rect()`, im Raster 640 × 360).
- **Steht der Communicator?** `is_in()` ist schon während der Fahrt herein wahr. Der Fahrer hört
  deshalb auf `SceneTree.node_added`: Jeder neue Communicator wird gemerkt, bevor sein `_ready()`
  läuft, und `slide_finished` sagt, wann er angekommen ist. So verpasst der Fahrer keine Fahrt, auch
  nicht beim frischen Titel.
- **Beenden abfangen.** Derselbe Weg gibt jedem neuen `TitleScreen` einen `quit_callback`, der nur
  mitzählt. Löste „Beenden“ aus, stünde das im Schritt, statt dass die App mitten im Lauf zugeht.
- **Callables mit `bind()`.** In `ablauf_titel.gd` sind die Prüfungen Methoden, und
  `_pruefe_start.bind(fahrer)` macht daraus ein Callable mit dem Fahrer als Argument. Ein solches
  Callable merkt sich das Objekt nur über dessen Kennung. Den Ablauf muss also jemand halten: in der
  App die Liste des Läufers, im Test eine Variable.

### T014 Läufer, Zeitraffer und `await` auf Bilder

- **Ein Node an der Wurzel.** Die Startszene hängt den Läufer mit
  `get_tree().root.add_child.call_deferred()` an die Wurzel. `change_scene_to_file()` tauscht nur
  die laufende Szene aus; alles, was direkt an der Wurzel hängt, wie die Autoloads, bleibt. So
  überlebt der Läufer jeden Wechsel zwischen Titel und Spielbildschirm.
- **`Engine.time_scale`.** Der Läufer setzt vor jedem Ablauf `Engine.time_scale = 8` bzw. `1`. Godot
  multipliziert damit das `delta` in `_process()`, Tweens und Timer, das Spiel merkt nichts davon.
  Der Communicator begrenzt seinen Schritt je Bild (`MAX_STEP`); im Lauf fuhr er im Zeitraffer in
  rund 100 ms herein, in Echtzeit in 210 ms. `Time.get_ticks_msec()` ist nicht skaliert. Daran messen
  Höchstzeit und `dauer_ms`, also in echter Zeit.
- **Warten ohne feste Zeit.** `_fuehre_aus()` prüft jedes Bild (`await get_tree().process_frame`),
  bis die Prüfung `""` gibt oder 5000 ms echter Zeit vorbei sind. Eine feste Wartezeit wäre auf
  langsamen Rechnern zu kurz und auf schnellen verschenkt.
- **`await` auf das fertige Bild.** Das Foto entsteht nach `await RenderingServer.frame_post_draw`:
  Das Signal kommt, wenn Godot das Bild fertig gemalt hat. Erst dann zeigt
  `get_viewport().get_texture().get_image()` sicher den Zustand, der eben geprüft wurde. Mit Stretch
  „viewport“ ist es immer 640 × 360, gleich wie groß das Fenster ist, und ohne Mauszeiger.
- **Eine Kette von `await`.** `starte()` kehrt beim ersten Warten zurück; der Lauf läuft als
  Koroutine weiter, Bild für Bild, während das Spiel normal läuft. Wird das Fenster geschlossen,
  schreibt `_brich_ab()` sofort Protokoll, Ausgabe und Zip, denn danach gibt es kein nächstes Bild.
  Die angehaltene Kette sieht beim Weiterlaufen `_abgebrochen` und hört auf. Läuft ein Spiel,
  kommt das Schließen erst bei `GameSession` an. Sie speichert und ruft dann `quit_callback`, den
  der Läufer auf `_brich_ab` gesetzt hat.
- **Austauschbar für Tests.** Frischer Titel, Foto und Beenden sind Callables (`vorbereitung`,
  `fotograf`, `beenden`), wie `quit_callback` in `GameSession`. So prüft
  `test_selbsttest_laeufer.gd` Warten, Fehler, Abbruch und Schreiben ohne Fenster.

### Auslegungen in T011 bis T014

- **Frischer Titel bis „steht im Baum“.** Die Vorbereitung endet, sobald der neue Titel da ist. Die
  Fahrt herein gehört zu Schritt 01 („Start, der Communicator fährt herein“); sonst zeigte
  `dauer_ms` keinen Unterschied zwischen `titel` und `titel_echtzeit` (SC-001). Hat der erste Schritt
  eines Ablaufs Eingaben, wartet der Läufer vorher, bis der Communicator steht.
- **`eingaben` darf einen Text zurückgeben.** Findet der Fahrer ein Ziel nicht, gibt die Eingabe
  „Ziel nicht gefunden: …“ zurück, und der Schritt scheitert sofort, ohne auf die Höchstzeit zu
  warten.
- **Ordner nicht beschreibbar.** Bis zur Zusammenfassung in Phase 4 gibt die Startszene die Meldung
  mit `printerr()` aus und beendet die App mit Code 1.

## Phase 3

### T019 Abhängige Abläufe und Eingaben als Methoden des Fahrers

- **`baut_auf` statt frischem Titel.** `laden` hat `baut_auf = "neues_spiel"`, `loeschen` hat
  `baut_auf = "laden"`. Für solche Abläufe lädt der Läufer keinen frischen Titel; sie beginnen dort,
  wo der Vorgänger aufhörte, im Hauptmenü auf „Weiterspielen“ mit Spiel 1 im Ordner. Dessen letzter
  Schritt hat genau diesen Zustand geprüft. Scheitert `neues_spiel`, gelten beide als nicht gelaufen
  („Fehler in Ablauf neues_spiel“); das regelt `SelbsttestLauf`, nicht der Ablauf.
- **`bind()` auf Methoden des Fahrers.** `fahrer.taste.bind(KEY_ENTER)` oder
  `fahrer.klick_auf_zeile.bind(1, …)` sind fertige Eingaben, ohne eigene Methode im Ablauf. Ein
  solches Callable merkt sich nur die Kennung des Fahrers; das geht, weil der Läufer Fahrer und
  Abläufe hält. Eine Methode mit `await` wird beim Aufruf zur Koroutine, deshalb ruft
  `_nacheinander()` in `selbsttest_ablauf.gd` jede Eingabe mit `await` auf und hört beim ersten
  Text auf, etwa „Ziel nicht gefunden: …“.
- **Der Befund in der Form der Erwartung.** Wo die Erwartung mehr sagt als der Fahrer liest,
  setzt die Prüfung des Schritts den Befund in derselben Folge zusammen, etwa
  „Communicator nicht hinausgefahren; Spielbildschirm steht, …“ in `neues_spiel.04`. So stehen
  `erwartet:` und `gefunden:` im Protokoll Wort für Wort untereinander.
- **`mouse_entered` gegen `gui_input`.** Das Hauptmenü wählt eine Zeile über `mouse_entered`, die
  Liste über jede Mausbewegung in `gui_input`. Ändert ein Control unter dem ruhenden echten Zeiger
  seine Zeigerform (`mouse_default_cursor_shape`), schickt Godot eine eigene Bewegung am Filter
  vorbei. Eine Probe zeigte: Sie löst `mouse_entered` aus, aber kein `gui_input`. Die Liste wählt
  dadurch nichts; das Menü setzt die Zeigerform nur an Buttons, die noch nicht im Baum hängen.
  Drei Läufe mit dem echten Zeiger auf „Zurück“, Spiel 1 und „Löschen …“ waren in Ordnung. Setzt
  ein späteres Feature die Zeigerform an einem Menü-Button im Baum, kann der echte Zeiger dort eine
  Zeile wählen.

### T021 Vorbereitung statt Eingabe, Fenster und `get_final_transform()`

- **Vorbereitung.** `bedienung.06` braucht sieben Spielstände. Die legt der Fahrer mit
  `lege_spielstaende_an()` über `SaveStore` an, wie `GameSession.start_new()` es täte, mit fester
  Zeit und festem Seed; danach lädt `lade_titel_neu()` den Titel, damit „Spiel laden“ verfügbar
  ist. Das geht nicht über Eingaben, deshalb steht im Protokoll
  `eingaben: Vorbereitung: 7 Spielstände; …`. `dauer_ms` und die Höchstzeit zählen erst ab der
  ersten Eingabe, dem Klick.
- **Aufräumen nach dem Ablauf.** `SelbsttestAblauf.aufraeumen()` ruft der Läufer nach jedem Ablauf,
  auch wenn ein Schritt scheiterte. `bedienung` löscht dort genau die Spielstände, die der Fahrer
  angelegt hat, `fenster` stellt Größe und Lage zurück, falls ein Schritt dazwischen scheiterte.
- **Szenenwechsel als Callable.** `lade_titel_neu()` wechselt über `fahrer.szenenwechsel`, ungültig
  heißt `change_scene_to_file()`. So läuft dieselbe Vorbereitung im Test in einem eigenen Viewport,
  wie `scene_callback` im Titel.
- **`get_final_transform()`.** Mit Stretch „viewport“ rendert Godot das Raster 640 × 360 und setzt
  es vergrößert ins Fenster. `get_tree().root.get_final_transform()` sagt, wie: Skalierung ist der
  Faktor, `origin` der Versatz, also der Rand links und oben. `SelbsttestFahrer.fenster_text()`
  rechnet daraus „Bild Faktor 2, mittig, Rand ringsum, ganze Pixel“. Die Fenstergröße stellt der
  Fahrer mit `get_window().size` ein, nicht über Eingaben; Größe ziehen ist Sache des Systems.
- **Bildschirmpixel und Punkte.** Godot rechnet Fenster in Pixeln, macOS auf einem Retina-Bildschirm
  in Punkten zu 2 Pixeln. Aus 1317 × 741 machte macOS deshalb 1316 × 740. `fenster.03` nimmt jetzt
  1318 × 742: krumm, aber gerade, und damit auf jedem System genau so zu setzen.
- **Warum `move_to_center()` nicht reichte (Änderung am Spiel).** `Window.move_to_center()` mittet die
  Fläche des Fensters ohne Titelleiste auf dem ganzen Bildschirm, Menüleiste und Dock eingeschlossen.
  Am Mac stand das Fenster so 63 Pixel unter der Mitte des freien Platzes; das fand `fenster.01`.
  `GameWindow._fit_to_screen()` rechnet die Lage jetzt selbst: `centered_position()` stellt den
  Rahmen (`window_get_size_with_decorations()`) mittig in `screen_get_usable_rect()` und gibt die
  Lage der Fläche zurück, also um den Versatz zwischen Rahmen und Fläche verschoben
  (`window_get_position_with_decorations()`), unter macOS die Titelleiste. Die Funktion ist
  statisch wie `best_factor()`, so prüft `test_game_window.gd` sie ohne Fenster. Der Selbsttest
  misst unabhängig davon am Rahmen (`SelbsttestFahrer.versatz_zur_mitte()`), damit er nicht nur
  nachrechnet, was das Spiel ohnehin tut.
- **Fester globaler Würfel.** Das versteckte Spiel nimmt seinen Seed aus `randi()`. Die Startszene
  ruft deshalb `seed(4711)`. Im Zeitraffer macht das Spiel je Bild genau 4 Schritte (die Grenze in
  `InvadersPage.advance()`), so fallen die Bomben in jedem Lauf gleich. Die Fotos von
  `easter_egg.03` und `.04` bleiben trotzdem nicht vergleichbar: Wie viele Bilder das Halten der
  Pfeiltaste dauert, hängt von der Bildrate ab.

### T022 Rahmen für Szenarien

- **Ein Szenario ist ein Ablauf.** `SelbsttestSzenario` erbt von `SelbsttestAblauf` und baut in
  `schritte()` aus Grad, Seed, `entscheidungen()` und `pruefpunkte()` gewöhnliche Schritte: erst
  „00_start“, dann nach Spieldatum, am selben Tag erst Entscheidungen, dann Prüfpunkte. Der Läufer
  spielt sie wie jeden anderen Ablauf; er braucht dafür keine Zeile mehr.
- **`sort_custom()` ist nicht stabil.** Godot garantiert bei gleichem Schlüssel keine Reihenfolge.
  Jeder Termin bekommt deshalb seine Stelle in der Liste mit, und `_frueher()` vergleicht zuletzt
  danach.
- **Die Uhr fragt der Fahrer.** `uhr_bis()` gibt heute
  „Die Uhr lässt sich im Spielbildschirm noch nicht bedienen“ zurück. Das ist ein Text für
  `gefunden:`, also scheitert der Schritt sofort, und der Rest gilt als nicht gelaufen. Das erste
  Feature mit Bedienung der Uhr baut sie dort ein; Szenarien und Läufer bleiben, wie sie sind.
- **Start als Vorbereitung.** Die Oberfläche kann keinen Seed wählen; `starte_spiel()` beginnt das
  Spiel deshalb über `GameSession.start_new(grad, seed)` und wechselt zum Spielbildschirm.

### Auslegungen in T019 bis T022

- **Erwartungen in der Form des Befunds**, wo der Vertrag nur beschreibt; Claude hat die Tabellen
  von `neues_spiel`, `laden` und `loeschen` danach angeglichen. Für Teil 2 siehe den Bericht zu
  T021: `easter_egg`, `bedienung` und `fenster` warten auf dieselbe Angleichung.
- **`bedienung.01` mit viermal Pfeil**, sonst läuft die Auswahl ohne Spielstand nicht um.
- **`fenster.01` misst das Fenster samt Titelleiste** gegen die Mitte des nutzbaren Bereichs, auf
  1 Pixel genau (Klaus). Zuerst scheiterte der Schritt, weil `GameWindow` auf dem ganzen Bildschirm
  mittete; Klaus hat entschieden, das Spiel zu richten.
- **`fenster.01` wartet auch, bis der Communicator steht.** Der Schritt hat keine Eingabe, also wartet
  der Läufer nicht von sich aus; ohne das zeigten die Fotos von 01 bis 04 die Fahrt herein, in jedem
  Lauf an anderer Stelle.
