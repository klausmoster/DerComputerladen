# Lernnotizen: Neues Spiel starten

Zu jeder umgesetzten Task die Godot-Konzepte und warum es so gebaut ist, an den Stellen im
Projekt. Bei `[A]`-Tasks schreibt der Agent die Notizen, Claude trägt sie je Phase hier ein; baut
Klaus eine Task selbst, schreibt Claude die Notiz beim Review. Abnahmen und Phasenprüfungen bauen
nichts und haben deshalb keine Notiz.

## Phase 1

### T001 Style-Guide zuerst

- Was man im Spiel sieht, steht zuerst im Style-Guide und wird dann gebaut (Verfassung,
  Grundsatz IV). So gibt es für Stil- und Text-Prüfer einen Maßstab, gegen den sie prüfen.
- Die Maße stammen aus Messungen mit den echten Schriften des Spiels in Godot (`Font`,
  `get_string_size()`), nicht aus Schätzungen: „Spiel 9999“ ist in Ark Pixel 12 genau 57 breit.
  Deshalb ist die Spalte 64 breit.

## Phase 2

### T003 `InterventionFile`: eine Klasse nur aus statischen Funktionen

- `class_name InterventionFile` macht den Namen im ganzen Projekt bekannt. `static func` heißt:
  aufrufen ohne Objekt, etwa `InterventionFile.to_file(record)` in `WhatIfProbe.write_file()`.
- Die Klasse hat keinen Zustand, deshalb gibt es kein `new()`. `extends RefCounted` steht nur da,
  weil jedes Skript eine Basis braucht.
- Godot kennt einen neuen `class_name` erst nach `--import`; dabei entsteht auch die `.uid`.
- Die Datei liegt unter `core/timeline/` und nicht neben der Probe in `tools/`. `tools/` wird nicht
  exportiert (`exclude_filter`), der Spielstand im fertigen Spiel braucht die Regel aber auch. So
  steht sie an einer Stelle (R5).
- Die Werte kommen aus JSON und sind deshalb `Variant`; erst `typeof()` sagt, was drinsteckt. JSON
  kennt nur float, daher prüft `is_whole_number()`, ob etwa 2556.0 eine ganze Zahl ist.
- `to_file()` und `from_file()` bauen ein neues Dictionary und rufen sich für den Modifikator darin
  selbst auf (Rekursion). Das Original bleibt unberührt, denn Dictionaries werden in GDScript als
  Verweis übergeben.

### T004 `TimelineRun.replay()`: Daten zurückgeben statt selbst entscheiden

- `replay()` ist eine Methode des Laufs. Der Lauf ist ein `RefCounted` ohne Node, deshalb läuft er
  ohne Szenenbaum in Werkstatt, Spiel und Test gleich.
- Abgelehnte Einträge gibt die Methode als typisiertes `Array[Dictionary]` zurück, statt sie
  selbst zu melden. Was daraus wird, entscheidet der Aufrufer: Die Probe macht in `build_run()`
  Sätze für `not_applicable` daraus, das Spiel später eine `push_warning()`. Dasselbe Prinzip wie
  bei der Timeline: Der Kern meldet, die Hülle entscheidet.
- `"record"` ist derselbe Eintrag, keine Kopie. Weil Dictionaries Verweise sind, sieht `_label()`
  in der Probe genau den Eintrag aus ihrem eigenen Protokoll; der Test prüft das mit
  `assert_same`.
- Der Test hält die alte Schleife aus `build_run()` als Helfer `_bisher_nachgespielt()` fest und
  vergleicht Fahrplan, Protokoll und Ablehnungen mit `replay()`. So ist belegt, dass der Umzug
  nichts geändert hat.

### T005 `EventCatalog.from_data()`: Parsen und Auswerten trennen

- `from_json()` macht jetzt nur noch eins: Text mit `JSON.new().parse()` parsen. Alles danach
  erledigt `from_data()`.
- So kann der Spielstand seinen Abschnitt `"catalog"`, der mit der ganzen Datei schon geparst
  ist, ohne Umweg über Text lesen. Weil es nur einen Weg für das Auswerten gibt, bleiben die
  Meldungen zwangsläufig gleich.
- Der Parameter ist `Variant`, denn im Spielstand kann dort auch eine Zahl stehen. Nach der
  Prüfung mit `typeof()` nimmt `var section: Dictionary = data` ihn typisiert; ab da prüft der
  Editor die Aufrufe wie `read_int(section, …)`.
- `issues: Array[CatalogIssue]` ist ein Ausgabeparameter. Arrays sind Verweise, deshalb sieht der
  Aufrufer jede Meldung, die `from_data()` anhängt.

### T006 `SaveGame`: Daten ohne Node, Text als Vertrag

- `class_name SaveGame extends RefCounted`: Wie der Lauf ist der Spielstand kein Node. Er läuft so
  im Spiel, in Tests und später in `GameSession` gleich, ohne Szenenbaum, und Godot gibt ihn frei,
  sobald niemand mehr auf ihn zeigt.
- `to_json()` nutzt `JSON.stringify(data, "\t", true)`. Das `true` sortiert die Schlüssel jedes
  Dictionarys, auch im Katalog und in den Eingriffen. So ergibt gleicher Inhalt immer denselben
  Text, und `SaveStore` kann nach dem Schreiben Zeichen für Zeichen vergleichen.
- `from_data()` bekommt gelesenes JSON. Jeder Wert ist erst einmal ein `Variant`, und jede Zahl
  kommt als `float` (4711 als 4711.0). Deshalb prüft es mit `typeof()` und
  `InterventionFile.is_whole_number()`, bevor etwas in ein typisiertes Feld wie `var seed: int`
  kommt.
- `problems` und `details` sind Ausgabeparameter: Arrays werden als Verweis übergeben. Getrennt
  sind sie, weil der Satz für den Spieler nie einen Wert aus der Datei enthalten darf; der kann
  beliebig lang sein und steht deshalb nur in `details` für das Protokoll.
- `const SYSTEM_BIAS := -100000` als Vorgabe von `bias_minutes`: Ein Standardwert muss eine
  Konstante sein, die Zeitzone des Rechners kennt man aber erst zur Laufzeit. Der Platzhalter wird
  in `_local_time()` durch `Time.get_time_zone_from_system().bias` ersetzt; Tests geben den
  Versatz fest vor.
- `_upgrade()` ist die vorbereitete Stelle für Format 2. Mit Format 1 tut es nichts.

### T007 `SaveSlot`: ein Ergebnis statt einer Ausnahme

- GDScript kennt kein `try`/`catch`. `SaveSlot.read()` gibt deshalb immer ein Objekt zurück und
  legt das Ergebnis in `state` und `reason`. So kann die Liste auch einen kaputten Spielstand
  zeigen.
- `enum State { OK, DAMAGED, TOO_NEW }`: zur Laufzeit eine ganze Zahl, im Code lesbar.
- `FileAccess.file_exists()` steht vor `get_file_as_string()`: Fehlt die Datei, meldete Godot
  sonst einen Fehler der Engine.
- `JSON.new().parse()` statt `JSON.parse_string()`: Nur so kommt man an `get_error_line()` und
  `get_error_message()` für das Protokoll.
- `push_warning()` gehört ins Protokoll, nicht zum Spieler. GUT fängt Warnungen ab;
  `assert_push_warning("…")` prüft sie.

### T008 `SaveStore`: sicher speichern ohne Datenbank

- Dateizugriff läuft über `FileAccess` und die statischen Funktionen von `DirAccess`
  (`rename_absolute`, `remove_absolute`, `get_files_at`, `dir_exists_absolute`). Sie verstehen
  `user://` direkt, den Benutzerordner der App, der ein Update übersteht.
- Die fünf Schritte über `.neu` und `.alt` ersetzen, was Godot nicht hat: `fsync` und ein
  Umbenennen, das ein vorhandenes Ziel sicher ersetzt. Nach jedem Abbruch liegt ein lesbarer
  Stand da; welcher gilt, entscheidet `_slot_of()` nach R3.
- Die Dateinamen prüft ein `RegEx` mit `^spiel_([1-9][0-9]{0,8})\.json(\.neu|\.alt)?$`. Fremde
  Dateien wie `notizen.txt` oder `spiel_02.json` fallen so heraus und werden nie gelöscht.
- `_store_text()` ist eine eigene Methode, damit ein Test mit
  `class SaveStoreMitDefekt extends SaveStore` einen kaputten Datenträger nachstellen kann. So
  lässt sich Schritt 2 nachweisen, ohne Testcode in die Klasse zu legen.
- `last_error` nennt Datei und Schritt für das Protokoll. Den Satz für den Spieler wählt später
  `GameSession`; der Kern meldet, die Hülle entscheidet.

### T009 `test_save_resume_run.gd`: ein Spiel bleibt dasselbe Spiel

- Der Test braucht keine Autoloads. `TimelineRun` ist ein `RefCounted`, also legt er die Läufe
  selbst an und vergleicht ein Spiel ohne Pause mit einem, das über Datei, `SaveSlot.read()` und
  `replay()` weiterläuft.
- Die Eingriffe sind `[Tag, Callable]`: Eine Lambda oder eine Methode liefert den Eintrag, und
  Absagen suchen sich den nächsten passenden Termin im jeweiligen Lauf. So passt der Test für jeden
  Seed, ohne Termine festzuschreiben.
- Verglichen werden ganze Ausgaben: Protokollzeilen ab dem 15.03.1986, der ganze Fahrplan und das
  Eingriffsprotokoll. Stichproben würden Abweichungen übersehen.

## Phase 3

### T012 `GameClock.set_date()`: springen statt vorspulen

- Die Uhr ist ein Autoload, an dessen Signal `day_passed` die Zeitleiste hängt. Spulte das
  Fortsetzen die Uhr Tag für Tag vor, liefe jeder Tag einmal durch das Signal, und die Zeitleiste
  meldete die Vergangenheit noch einmal: Die Miete von 1985 wäre zweimal bezahlt. `set_date()` setzt
  deshalb nur `date`, `_day_index` und `_ended` und sendet nichts.
- Das Datum wird kopiert, weil `GameDate` ein `RefCounted` ist, also ein Verweis. Ohne Kopie würde
  die Uhr mitwandern, wenn der Aufrufer sein Objekt später ändert.
- `_accumulator` geht auf 0, sonst käme bei laufender Uhr der angefangene Tag aus `_process()`
  schon im nächsten Bild.

### T013 Kein Selbststart, `resume_game()`

- Bisher stand in `_ready()` `start_game.call_deferred()`: Am Ende des ersten Bilds begann immer
  ein Spiel. Jetzt liest `_ready()` nur den Katalog und verbindet sich mit der Uhr;
  `_on_day_passed()` kehrt bei `run == null` sofort zurück. Ein Spiel beginnt erst über
  `GameSession` (T014).
- `resume_game()` ist still, weil `TimelineRun.replay()` die Meldungen der nachgespielten Tage nur
  ins Protokoll des Laufs schreibt. Signale entstehen nur in `_send()`, und das wird hier nicht
  aufgerufen: Der Kern weiß nichts von Signalen, die Hülle entscheidet, was gesendet wird.
- `run` wird erst am Ende gesetzt. Ein abgelehnter Aufruf lässt das laufende Spiel deshalb
  unberührt, und kein halb aufgebauter Lauf bekommt Uhrtage.
- Die Kopie des Katalogs geht durch dieselbe statische Funktion `_checked_catalog()` wie der
  Katalog des Spiels. So fällt beim Fortsetzen genau das weg, was beim Start wegfiele, mit
  denselben Meldungen.
- In `test_title_screen.gd` kommt das echte Autoload über `get_node(^"/root/Timeline")`: In einem
  Skript, das GUT mit `-s` startet, kennt GDScript die Namen der Autoloads nicht.

### T014 Autoload `GameSession`

- **Autoload statt Szene:** Das Spiel wechselt zwischen Titel und Spielbildschirm. Ein Autoload
  hängt dauerhaft unter `/root` und übersteht den Szenenwechsel; deshalb hält `GameSession` das
  laufende Spiel (`current`), und die Szenen fragen es nur. Es steht in `project.godot` nach
  `GameClock` und `Timeline`, weil Godot Autoloads in dieser Reihenfolge in den Baum hängt.
- **Austauschbare Abhängigkeiten:** `clock` und `timeline` sind Felder; null heißt die Autoloads,
  aufgelöst in `_clock()` und `_timeline()`. So baut jeder Test seine eigene Uhr und Zeitleiste,
  wie bei `Timeline.clock`. Dasselbe gilt für `now` (ein `Callable` statt der Systemuhr) und `rng`
  (ein eigener `RandomNumberGenerator` mit festem Seed im Test).
- **Typen ohne `class_name`:** `game_clock.gd` und `timeline.gd` haben keinen Klassennamen.
  `const CLOCK_SCRIPT := preload(...)` macht das Skript selbst zum Typ, und `as CLOCK_SCRIPT`
  liefert typisierten Zugriff auf `set_date()` und `run`.
- **Erst schreiben, dann starten:** `Timeline.start_game()` sendet sofort die Signale des
  01.01.1985. Käme es vor dem Schreiben und das Schreiben scheiterte, hätten Abnehmer schon auf
  ein Spiel reagiert, das es nicht gibt.
- **Schließen abfangen:** Fensterknopf und Cmd+Q kommen bei jedem Knoten als
  `NOTIFICATION_WM_CLOSE_REQUEST` an. Godot beendet die App danach nur von selbst, wenn
  `get_tree().auto_accept_quit` an ist; `_update_quit_guard()` schaltet es aus, solange ein Spiel
  läuft. Ohne Spiel fasst der Knoten es nie an, so behält die Werkstatt ihre eigene Einstellung.
- **Signal und Feld:** `save_failed` meldet einen Fehler an den, der gerade zuhört; `last_error`
  hält denselben Satz für den, der erst danach erscheint, etwa den Spielbildschirm nach dem
  Fortsetzen.
