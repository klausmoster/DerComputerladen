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

## Phase 4

### T029 Werkzeug im Spielfenster

- **Dieselbe App, ein anderes Fenster.** Der Selbsttest läuft im Spielraster 640 × 360 mit Stretch
  `viewport`; die Zusammenfassung ist ein Werkzeug und braucht scharfen Text in normaler Größe.
  `SelbsttestErgebnis._richte_fenster_ein()` stellt deshalb wie die Werkstatt
  `content_scale_mode = DISABLED` und `content_scale_factor = DisplayServer.screen_get_scale()`:
  Godot zeichnet in voller Auflösung, und ein Punkt Text ist auf dem Retina-Bildschirm zwei Pixel.
  Das ist nur eine Einstellung am `Window`; Szenenbaum und Autoloads bleiben, wie sie sind.
- **`GameWindow` anhalten statt umbauen.** Das Autoload prüft jedes Bild in `_process()`, ob das
  Fenster aus dem Vollbild kommt, und gäbe ihm dann die ganzzahlige Spielgröße. `set_process(false)`
  und `set_process_input(false)` (bis Phase 5 `set_process_unhandled_input`) schalten nur diesen
  einen Knoten still, ohne dass
  `GameWindow` vom Selbsttest wissen muss. Die Seite holt es über `/root/GameWindow`, wie die
  Werkstatt.
- **Kein Maximieren (Klaus, 2026-10-28).** Anders als die Werkstatt behält das Fenster Größe und Lage
  aus dem Lauf, auf diesem Mac 1600 × 932 Punkte samt Titelleiste. Die Seite füllt die Fläche, die
  da ist. Gemessen: in der Probe vor und nach dem Wechsel 3200 × 1800 Pixel an derselben Stelle, in
  der echten App von außen über 25 s gleich bis auf den Ablauf `fenster`.
- **Felder vor dem Einzug setzen: `change_scene_to_node()`.** Der Läufer baut die Seite mit
  `SelbsttestErgebnis.erstelle()`, setzt Lauf und Pfade und gibt den fertigen Knoten an
  `get_tree().change_scene_to_node()` (seit Godot 4.5). So stehen alle Werte, bevor `_ready()` läuft;
  mit `change_scene_to_file()` gäbe es keinen Weg dorthin außer über ein Autoload. `erstelle()` lädt
  die Szene mit `load()`, nicht `preload()`: Die Szene nennt das Skript, ein `preload` im Skript
  wäre ein Kreis.
- **Der Filter muss vorher aus sein.** `SelbsttestEingabe.einschalten()` ersetzt den Empfang des
  Fensters; Godot gibt den alten nicht heraus. `ausschalten()` lässt deshalb den eigenen Empfang
  stehen, der danach alles durchreicht. Der Läufer ruft es in `_schreibe()`, also vor dem Wechsel.
  Belegt in der Probe mit `--filter`: Ein Klick mit gewöhnlichem Gerät über
  `Input.parse_input_event()`, dem Eingang auch der Ereignisse von macOS, kommt bei eingeschaltetem
  Filter nicht an „Kopieren“, danach schon.
- **Schließen beendet einfach.** Nach `_schreibe()` ist `_laeuft` falsch, der Läufer überhört
  `NOTIFICATION_WM_CLOSE_REQUEST`, und `GameSession.quit_callback` ist wieder der alte. Ohne
  laufendes Spiel steht `auto_accept_quit` auf true; Godot beendet dann ohne eigenen Code.

### T029 Theme-Kopie

- **Eine Datei, die erbt, gibt es nicht.** Godot kann ein Theme nicht von einem anderen ableiten.
  `selbsttest_theme.tres` ist deshalb eine Kopie von `werkstatt_theme.tres` mit fünf neuen Varianten
  (`theme_type_variation`): `EntryPanel` und `AlternateEntryPanel` für die Einträge in `papier` und
  `endlos-gruen`, `ErrorMarkLabel` und `NotRunMarkLabel` für die Felder „!“ und „–“,
  `SmallMutedLabel` für die Systemzeile. So stehen auch diese Farben im Theme statt im Code.
- **Damit die Kopie nicht still veraltet,** vergleicht `test_selbsttest_ergebnis.gd` sie Eintrag für
  Eintrag mit dem Theme der Werkstatt. Unterressourcen wie Styleboxen tragen einen Pfad
  `datei.tres::id`; der Test vergleicht sie nach ihren gespeicherten Eigenschaften, Dateien wie
  Symbole nach dem Pfad. `ResourceLoader.CACHE_MODE_IGNORE` lädt frisch aus der Datei, ohne die
  Schrift, die eine offene Seite schon gesetzt hat.
- **Die Schrift kommt per Code.** Open Sans SemiBold ist Godots eingebaute Schrift
  (`ThemeDB.fallback_font`) und hat keine Datei, die eine `.tres` nennen könnte. Die Werkstatt
  dupliziert ihr Theme vorher, weil es geteilt ist; die Kopie gehört nur dieser Seite, die Seite
  setzt `default_font` direkt.
- **Ein Pfad, der nur nach Trennern umbricht.** `umbrechbar()` setzt hinter jedes `/` und `\` ein
  Leerzeichen ohne Breite (`\u200B`), an dem der Umbruch erlaubt ist, und macht die Leerzeichen im
  Pfad fest (`\u00A0`). Ohne das brach der Pfad bei „Büro hinten“ um; mit `AUTOWRAP_WORD_SMART`
  bricht er nach „Woche 44/“ und wird nie gekürzt. Zu sehen ist der Pfad unverändert.

### T029 Zwischenablage

- **`DisplayServer.clipboard_set()`** legt den Text ab, den `SelbsttestProtokoll.kopieren()` baut,
  dieselbe Funktion wie für `protokoll.txt`. Die Seite hält sie als Callable
  (`zwischenablage`); Tests geben eine eigene Funktion und prüfen den Text, ohne Klaus'
  Zwischenablage anzufassen.
- **Warum Linux anders ist.** Unter macOS und Windows übernimmt das System den Inhalt. Unter X11
  gehört er dem Programm, das ihn anbietet: Wer einfügt, fragt die App, und ist sie beendet, ist der
  Inhalt weg, solange kein Clipboard-Manager ihn übernimmt (R11). Deshalb heißt die Bestätigung
  dort „Kopiert. Erst einfügen, dann beenden.“
- **Bestätigung bis zum nächsten Klick.** `_input()` sieht jeden Klick, bevor ein Knopf ihn
  bekommt, und blendet „Kopiert.“ aus. Ein Knopf löst erst beim Loslassen aus; ein Klick auf
  „Kopieren“ zeigt die Bestätigung deshalb gleich wieder. Das Mausrad zählt nicht als Klick.

### T029 Dateimanager

- **`OS.shell_show_in_file_manager()`** zeigt das Zip im Finder bzw. Explorer und markiert es;
  unter Linux öffnet es den Ordner (R11). Gibt es kein Zip, weil das Packen scheiterte, zeigt die
  Seite den Ordner des Laufs. Auch das ist ein Callable (`dateimanager`), damit kein Test ein
  Fenster öffnet.
- **Ordner nicht beschreibbar.** Die Startszene erhebt dann nur die Systemdaten und wechselt
  gleich zur Seite mit `beschreibbar = false`: Meldung an Stelle von Summe, Liste und Pfad,
  „Ordner zeigen“ gesperrt. Ein gesperrter Knopf behält in Godot seinen `focus_mode`; die Seite
  setzt ihn auf `FOCUS_NONE`, sonst landete Tab auf einem Knopf, der nichts tut.

### Auslegungen in T029

- **Abstände.** Die Zeilen der Tabelle im Vertrag gelten als Bereiche, also 16 zwischen
  Überschrift, Systemzeile, Summe, Bereichstitel, Pfad und Fußzeile. Bereichstitel und Liste stehen
  in einem eigenen `VBoxContainer` „Bereich“ mit 8 dazwischen (Style-Guide „Werkzeuge“, Version 60).
  Die Einträge liegen ohne Lücke untereinander, damit der Grund `endlos-gruen` als Streifen wirkt;
  je 4 Innenabstand oben und unten ergeben 8 zwischen zwei Einträgen. Die Fußzeile ist ein
  `HBoxContainer` mit 16: links die Knopfreihe mit 8 zwischen den Knöpfen, damit die Fokuslinie
  (4 über den Knopf hinaus) den Nachbarn nicht berührt, rechts die Bestätigung.
- **Zeilenabstand 0.** Godots Vorgabe für `Label/constants/line_spacing` ist 3; umbrochene Zeilen in
  einem Label stünden so 3 Pixel weiter auseinander als getrennte Labels. Die Kopie setzt den Wert
  für alle Labels der Seite auf 0, eine Zeile `werkzeug-text` ist damit 20 Pixel hoch. Das ist der
  einzige Eintrag, den die Kopie in einem Typ der Werkstatt ändert; der Test kennt ihn.
- **Gesperrter Knopf mit eigenem Tooltip.** „Ordner zeigen“ sagt im gesperrten Zustand „Kein Zip:
  Im Ordner lässt sich nicht schreiben.“
- **Pfad und Knopfreihe stehen unten.** Die Liste nimmt den freien Platz und rollt, wenn er nicht
  reicht; ohne Liste hält eine leere Fläche die Knopfreihe unten.
- **Das Feld** ist quadratisch und so hoch wie eine Zeile `werkzeug-text`, damit „!“ und „–“ neben
  der ersten Zeile stehen. Die Zeichen stehen als `ZEICHEN_FEHLER` und `ZEICHEN_NICHT_GELAUFEN` in
  `SelbsttestTexte`.

## Phase 5

### T035: `tools/selbsttest/vergleich.py`

- **Vergleich ohne Toleranz.** Der Selbsttest fotografiert mit festem Seed, fester Zeit und ohne
  Mauszeiger, und `titel` gleicht `titel_echtzeit` Byte für Byte (Phase 2). Auf demselben Rechner
  muss deshalb jedes Pixel gleich sein; eine Toleranz würde genau die kleinen Fehler verdecken, die
  ein anderer Grafiktreiber macht, etwa eine Kante, die einen Pixel versetzt ist. Was nach Zeit
  rechnet, wie das versteckte Spiel, markiert das Protokoll als „nicht vergleichbar“; dort prüft
  der Vergleich nur die Größe.
- **Warum außerhalb von Godot.** Claude soll Läufe von Windows und Linux auswerten, ohne Godot und
  ohne Fenster. Ein Python-Skript mit Standardbibliothek läuft überall, wo Python ist, und teilt
  den PNG-Leser mit der Rasterfassung (`tools/raster/pngio.py`). Der schnelle Weg vergleicht erst
  die rohen Zeilen; nur wenn sie verschieden sind, rechnet er Pixel für Pixel.
- **`python3 -I`.** Der Schalter isoliert Python: Es lädt keine Module aus dem Ordner des Skripts
  oder dem aktuellen Ordner und liest keine Umgebungsvariablen wie `PYTHONPATH`. Ein Zip von einem
  fremden Rechner könnte sonst eine Datei `json.py` mitbringen, die beim `import json` liefe. Das
  Skript holt `pngio` deshalb ausdrücklich über seinen eigenen Pfad.
- **Pfade aus dem Zip hinaus.** Ein Eintrag wie `../ausbruch.txt` würde beim Entpacken neben den
  Ordner geschrieben („Zip Slip“). `entpacke()` prüft alle Einträge, bevor es eine Datei schreibt,
  und lehnt das ganze Zip ab; ebenso symbolische Links. Exit 2 heißt: dem Eingang nicht trauen.

## Phase 6

### T042: ICO aus `tools/raster/make_icon.py`

- **Was eine ICO ist.** Ein kleiner Kopf (Typ 1, Zahl der Bilder), dann je Bild ein Eintrag von 16
  Bytes mit Breite, Höhe, Farbtiefe, Länge und Lage der Daten, dahinter die Bilder selbst. Seit
  Windows Vista darf jedes Bild ein ganzes PNG sein. Breite und Höhe 256 passen nicht in ein Byte
  und stehen deshalb als 0 im Eintrag. `write_ico()` baut das mit `struct.pack`, `pngio` liefert die
  PNG über die neue Funktion `encode_png_rgba()` als Bytes.
- **Warum jede Größe eigens.** Windows wählt je nach Ansicht 16, 32, 48 oder 256. Rechnet Godot oder
  Windows die Größen aus einem großen Bild herunter, mischen sich benachbarte Pixel, und der Monitor
  wird zu Brei. Mit ganzzahligem Zoom aus den Bildpixeln bleibt jede Kante scharf. Nur in 16 passt
  der Monitor nicht; dort nimmt das Skript jedes zweite Bildpixel (Klaus' Wahl).
- **Das 1024er Symbol bleibt Byte für Byte gleich.** Die ICO entsteht aus demselben Monitor, aber auf
  ihn zugeschnitten (18 × 16 statt 19 × 16 mit leerer Spalte), damit er in jeder Größe mittig steht.

### T043: Renderer, Vollbild-Kürzel und Presets für Windows und Linux

- **Renderer-Ausweichen.** Forward+ zeichnet über Godots `RenderingDevice`: unter macOS mit Metal,
  unter Windows mit Direct3D 12 (`rendering_device/driver.windows="d3d12"` in `project.godot`) oder
  Vulkan, unter Linux mit Vulkan. Scheitert der Treiber, darf Godot innerhalb von Forward+ wechseln:
  `fallback_to_vulkan` und `fallback_to_d3d12` stehen auf ihrer Vorgabe true und deshalb gar nicht in
  der Datei. `fallback_to_opengl3` ist jetzt false. Mit true schaltete Godot still auf den Renderer
  Compatibility mit OpenGL 3.3 um: andere Shader, andere Bilder, genau die Rücksicht, die Grundsatz I
  ausschließt. Mit false zeigt Godot „Unable to initialize video driver“ und endet. Das ist ehrlicher
  als ein Spiel, das anders aussieht als getestet. `test_projekt_einstellungen.gd` prüft alle drei
  Werte; „nicht eingetragen“ sieht der Test nur an der Datei selbst, weil `ProjectSettings` für eine
  fehlende Einstellung die Vorgabe liefert.
- **Eine Aktion, mehrere Tasten.** Eine Eingabe-Aktion ist eine Liste von Ereignissen. Trifft ein
  Ereignis eines davon, gilt die Aktion. `toggle_fullscreen` hat jetzt drei: Ctrl+Cmd+F, F11 und
  Alt+Enter. In `project.godot` steht jedes als `Object(InputEventKey, …)`. `physical_keycode` meint
  die Lage der Taste, gleich welches Tastaturlayout; `device: -1` heißt jedes Gerät. Die Zeilen hat
  Godot selbst geschrieben (`ProjectSettings.save()` an einer Kopie), damit der Editor sie beim
  nächsten Speichern nicht umformt.
- **`exact_match`.** Ohne den Schalter vergleicht Godot großzügig: Die Zusatztasten der Aktion müssen
  gedrückt sein, weitere stören nicht. Beim Loslassen prüft Godot sie gar nicht. Deshalb ist
  Alt+Enter für Godot auch `ui_accept`, und das Loslassen von Enter allein trifft
  `toggle_fullscreen`. Das zweite hat ein vorhandener Test der Invaders-Seite gefunden:
  `InvadersPage._on_key()` ließ das Loslassen von Enter zum Bildschirm durch. `is_action(…, true)`
  und `is_action_pressed(…, false, true)` verlangen genau die Zusatztasten der Aktion. Das reicht;
  einen eigenen Vergleich der Zusatztasten braucht es nicht.
- **`_input()` statt `_unhandled_input()`.** Ein Viewport reicht jedes Ereignis in fester
  Reihenfolge weiter: zuerst `_input()` aller Knoten, dann die Oberfläche (`_gui_input()` des
  Controls mit Fokus), zuletzt `_unhandled_input()`. `set_input_as_handled()` beendet den Weg.
  `GameWindow._input()` nimmt das Kürzel also, bevor ein Menü es als Enter deuten kann. Markiert
  werden auch Loslassen und Wiederholung, geschaltet wird nur beim ersten Drücken. In Godot 4.7.2 fragt
  ein `Button` `ui_accept` selbst genau ab und hätte bei Alt+Enter ohnehin nicht ausgelöst; ein
  Control, das großzügig fragt, schon. Die Folge an anderer Stelle: Werkstatt und Zusammenfassung
  des Selbsttests halten `GameWindow` jetzt mit `set_process_input(false)` an. Das alte
  `set_process_unhandled_input(false)` hätte das Kürzel dort nicht mehr abgeschaltet.
- **Ein Spion im Test.** Headless meldet das Fenster immer „minimiert“, das Vollbild lässt sich so
  nicht beobachten. `test_game_window.gd` hängt deshalb eine Unterklasse von `game_window.gd` in einen
  eigenen Viewport, die `toggle_fullscreen()` nur zählt. Ihr `_ready()` ersetzt das geerbte; Godot 4
  ruft das `_ready()` der Elternklasse nicht von selbst. Das Signal `gui_input` der gewählten
  Menüzeile zeigt, ob die Oberfläche das Kürzel überhaupt sieht. Erst diese Prüfung fiel durch, als
  das Kürzel probeweise wieder in `_unhandled_input()` stand.
- **Presets für Windows und Linux.** `binary_format/embed_pck = true` hängt das Paket mit allen
  Szenen und Skripten an die ausführbare Datei an. Weitergegeben wird dann eine Datei statt zwei, die
  zusammenbleiben müssten. `application/modify_resources = true` lässt Godot Symbol und
  Versionsangaben selbst in die `.exe` schreiben, ohne `rcedit`. Datei- und Produktversion bleiben
  leer; dann nimmt Godot `application/config/version` und macht für Windows vier Zahlen daraus,
  „0.1“ wird „0.1.0.0“. Eine `.ico` nimmt Godot, wie sie ist. Fehlt darin eine der Größen 16 bis 256,
  warnt es „Icon size … is missing“. Eine PNG rechnete es selbst herunter, mit Weichzeichnen.
- **Keine Geheimnisse in der Datei.** Optionen mit dem Merkmal `PROPERTY_USAGE_SECRET` schreibt Godot
  nicht nach `export_presets.cfg`, sondern nach `.godot/export_credentials.cfg`, das nicht
  versioniert wird; für Windows sind das `codesign/identity_type`, `codesign/identity` und
  `codesign/password`. Die übrigen Optionen stehen in der Reihenfolge und mit den Vorgaben, die
  Godot 4.7.2 selbst anlegt. Ermittelt ist das mit `EditorExportPlatform.create_preset()` in einem
  Editor-Plugin eines Probeprojekts; die ausgeblendeten erweiterten Optionen kamen aus der Quelle von
  4.7.2. Die Spiel-Presets sind wie `macOS` „runnable“, wie der Editor es beim ersten Preset einer
  Plattform setzt; der Abschnitt `[runnable_presets]` nennt die Plattform, also `"Windows Desktop"`.

### T044: `tools/build/baue_alles.sh`

- **Ein Befehl, alle Systeme.** Godot exportiert headless mit `--export-release "<Preset>" <Ziel>`;
  das Skript ruft das sechsmal und hält je Preset die Ausgabe in `build/logs/` fest. Es zählt nicht
  auf den Exit-Code allein, sondern prüft auch, dass die Datei da ist, und behandelt die Warnung
  „Icon size … is missing“ als Fehler.
- **Prüfung auf Testcode (SC-005).** Im Paket stehen die Pfade der Dateien im Klartext. Steht
  `selbsttest_laeufer` im Spiel, ist Testcode mitgekommen; steht er im Selbsttest nicht, wäre die
  Prüfung ohne Aussage. `LC_ALL=C grep -a -c` liest die Binärdatei als Text.
- **Packen.** `ditto -c -k` packt eine `.app` so, wie der Finder es täte, mit Rechten und Signatur;
  ein gewöhnliches `zip` kann Teile davon verlieren. Für Windows und Linux packt `zip -r -X`, das die
  Unix-Rechte mitnimmt; so bleibt die Linux-Datei nach dem Entpacken ausführbar. Ein Zip je System
  enthält Spiel und Selbsttest, unter Windows samt den Dateien für Direct3D 12 daneben.

## Phase 8

### T060: Skalierung aus den dpi

- **Zwei Fragen an den Bildschirm.** `DisplayServer.screen_get_scale()` fragt das System nach seinem
  Skalierungsfaktor. Das können in Godot 4.7 nur macOS (2.0 auf Retina) und Wayland; unter Windows
  und X11 kommt immer 1.0 zurück. `screen_get_dpi()` gibt es auf allen Desktops, aber es misst etwas
  anderes: Unter Windows meldet Godot die dpi, die Windows aus der eingestellten Skalierung macht
  (125 % sind 120 dpi), unter X11 rechnet es aus Auflösung und Größe des Bildschirms in Millimetern,
  also die echte Dichte. Unter macOS sind die dpi ungenau, sobald die Skalierung krumm ist; deshalb
  bleibt es dort beim Faktor des Systems.
- **Eine Funktion für beide Stellen.** `SelbsttestSystem.skalierung(server, scale, dpi)` ist statisch
  und liest nichts selbst; so prüft der Test jeden Fall ohne Fenster. `bildschirm_skalierung()` holt
  die drei Werte vom `DisplayServer` und gibt sie hinein. Protokoll (`system.bildschirm_skalierung`)
  und Zusammenfassung (`content_scale_factor`) nehmen dieselbe Funktion; damit kann das Protokoll
  nicht einen anderen Faktor nennen als den, mit dem die Seite gezeichnet ist.
- **Warum `DisplayServer.get_name()` und nicht `OS.get_name()`.** Ob der Faktor fehlt, hängt am
  Display-Server, nicht am System: Linux hat zwei, X11 und Wayland, und nur einer kennt den Faktor.
  `OS.get_name()` sagt in beiden Fällen „Linux“. Unter Windows heißen beide gleich.
- **Runden.** `snappedf(dpi / 96.0, 0.25)` rundet auf das nächste Vielfache von 0,25, wie die Stufen
  in den Anzeigeeinstellungen von Windows; `maxf(…, 1.0)` hält einen kleinen oder unbekannten
  Bildschirm bei 1. Die Werkstatt rechnet weiter mit `screen_get_scale()`.

### T061: Variante `FormScroll`

- **Eine Variante bringt alles mit.** `theme_type_variation = &"FormScroll"` gibt der Liste nicht nur
  `scrollbar_h_separation = 4`, den Abstand zwischen Inhalt und Rollbalken, sondern auch das `panel`
  der Variante, eine leere StyleBox mit 4 Innenabstand ringsum. Der Inhalt rückt also 4 nach innen,
  wie das Formular der Werkstatt. Die Variante stand schon in der Kopie des Themes; die Szene nennt
  sie nur.

### T059: Symbol des Fensters unter Windows

- **Zwei Symbole.** `application/icon` im Export-Preset schreibt das Symbol in die `.exe`; das zeigt
  der Explorer. `application/config/windows_native_icon` in `project.godot` setzt Godot beim Start
  über `DisplayServer.set_native_icon()` für das laufende Fenster: Titelleiste, Taskleiste, Alt+Tab.
  Ohne die Einstellung nähme Godot dort die PNG aus `config/icon` und rechnete sie herunter. Die Zeile
  hat wieder Godot geschrieben (`ProjectSettings.save()` an einer Kopie); sie steht gleich hinter
  `config/icon`.
