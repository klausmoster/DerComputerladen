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

## Phase 4

### T017 `MenuPaper` und `MainMenu` zur Laufzeit

- `MenuPaper` erbt von `RefCounted`, wird aber nie mit `new()` angelegt; es gibt nur Konstanten und
  `static func`. Malen darf ein Control nur in seinem eigenen `_draw()`. Deshalb gibt
  `MainMenu._draw()` sich selbst als `canvas` mit, und `MenuPaper` ruft `canvas.draw_rect(...)`
  auf. So malen Menü und Liste dasselbe Papier, ohne voneinander zu erben.
- `@export` mit Setter (`header_text`, `paper_width`): Der Setter läuft auch, wenn Godot die Szene
  lädt, bevor `$Rows/Header` existiert. Deshalb fragt er erst `is_node_ready()`, und `_ready()` holt
  den Wert nach.
- `set_entries()` meldet die gewählte Zeile sofort; `_row_rect()` rechnet sie deshalb aus der Lage
  des Menüs, denn der `VBoxContainer` ordnet neue Buttons erst im nächsten Bild an.
- Das Hauptmenü ist vor und nach dem Umbau fotografiert und Pixel für Pixel verglichen: gleich.

### T018 Knopf und Meldung

- Ein Button malt zuerst seinen StyleBox und den Text, danach ruft Godot das `_draw()` des
  Skripts. Fläche und Kontur kommen deshalb aus `StyleBoxFlat` (Theme-Variante `Knopf`); `_draw()`
  malt nur, was eine `StyleBoxFlat` nicht kann: die Lichtkante oben links, die Schattenkante unten
  rechts und die Fokuslinie außerhalb des Knopfs. Ein Control darf über seinen Rand hinaus malen.
- Dass der Text beim Drücken einen Pixel tiefer rückt, macht nur das Theme: Der StyleBox `pressed`
  hat oben 3 statt 2 Innenabstand und unten 1 statt 2.
- `has_focus(true)` ist falsch, wenn der Fokus von einem Mausklick kommt; die Fokuslinie erscheint
  also wie `:focus-visible` nur bei Tastatur oder `grab_focus()`.
- Die Meldung ist kein eigener Knoten: `MenuHint` wechselt nur `theme_type_variation` zwischen
  `HintPanel` und `WarningPanel`.

### T019 `TitleTexts`: Texte an einer Stelle, gemessen statt geschätzt

- Die Vorlagen nutzen benannte Platzhalter mit `String.format()`, etwa
  `"{name} löschen".format({"name": …})`; das liest sich für Text-Prüfer besser als `%s`.
- Der Test holt die Texte über `get_script_constant_map()` aus den Skripten. Ein neuer `HINT_*`
  wird ohne Änderung am Test mitgeprüft.
- Gemessen wird mit dem echten `menu_hint.tscn` und `Label.get_line_count()`, also mit derselben
  Schrift, Breite und Umbruchregel wie im Spiel. Nur so fiel auf, dass die Rückfrage mit „Spiel
  9999“ drei Zeilen braucht; die Rechnung im Plan mit Wortbreiten hatte zwei ergeben.

### T020 Titelbildschirm mit Blättern

- **Zwei Instanzen einer Szene:** `MainMenu` und `DifficultySheet` sind dieselbe `main_menu.tscn`;
  nur `header_text` und die Einträge unterscheiden sich. Ein Blatt ist also Daten statt Code.
  Gewechselt wird über `visible`.
- **Erst verbergen, dann zeigen:** Ein Control, das unsichtbar wird, gibt den Fokus ab, auch den
  eines Buttons darin. So hat das verborgene Blatt nie Tastenfokus; danach ruft `_show_only()`
  `select()` auf dem sichtbaren Blatt.
- **Ein Handler für zwei Signale:** Beide `selection_changed` sind mit `_on_sheet_selection_changed`
  verbunden. Der Hinweis gehört dem Titel, nicht einem Blatt.
- **Esc in `_unhandled_input()`:** Die Taste kommt dort an, wenn kein Bedienelement sie genommen
  hat. Nur der Titel weiß, welche Ebene darüber liegt; `set_input_as_handled()` hält sie danach von
  anderen fern.
- **`call_deferred` hält den Wert der Bestellung fest:** `MainMenu._ready()` bestellt
  `select.call_deferred(0)`. Ein `set_entries()` im `_ready()` des Titels würde danach
  überschrieben; deshalb baut der Titel seine Blätter mit `_build_sheets.call_deferred()`.
  Zeitversetzte Aufrufe laufen in der Reihenfolge ihrer Bestellung.
- **`session` und `scene_callback`** sind Einhängepunkte für Tests, wie `GameSession.clock` und
  `quit_callback`: null bzw. ungültig heißt das Autoload bzw. `change_scene_to_file()`.

### T021 Spielbildschirm

- Die Szene ist `Control` → `ColorRect`, `Button` mit Skript `knopf.gd`, `MenuHint`. `knopf.gd`
  ist ein Skript auf einem eingebauten `Button`; ein eigener Knopftyp ist nicht nötig.
- `pressed` ist in der `.tscn` verbunden, `save_failed` im Code, denn die Session steht erst zur
  Laufzeit fest. Wird der Bildschirm freigegeben, löst Godot die Verbindung zum Autoload selbst.
- **Signal plus Zustand:** Scheitert das Speichern schon beim Fortsetzen, kommt `save_failed`,
  bevor der Bildschirm existiert. Deshalb liest `_ready()` zusätzlich `last_error`; ein Signal
  allein geht verloren, wenn noch niemand zuhört.
- Ein ausgeschalteter Knopf zeigt den Pfeil: Für `disabled` gibt es kein Signal, aber Godot malt
  den Knopf nach jedem Umschalten neu, deshalb setzt `_draw()` den Mauszeiger.

### T022 Bildschirmfotos

- Ein Skript, das mit `-s` startet, wird übersetzt, bevor Godot die Namen der Autoloads kennt.
  `preload("res://core/game_session.gd")` scheitert dort an „Identifier not found: GameClock“; die
  Kopie des Fotoskripts lädt die Skripte deshalb erst zur Laufzeit mit `load()`.
- Headless rendert Godot nicht; fotografiert wird mit Fenster, das Bild kommt aus
  `root.get_texture().get_image()` im Raster 640 × 360, die dreifache Fassung mit Nearest.

## Phase 5

### T025 `SaveList`: ein Fenster aus festen Zeilen

- **Feste Zeilen statt `ScrollContainer`:** `_build_rows()` legt einmal 6 + 2 Buttons an. Beim
  Rollen ändert sich nur `_first_visible`, und `_refresh_rows()` schreibt neue Inhalte in dieselben
  Buttons. So rollt die Liste nie um halbe Zeilen und braucht keinen Rollbalken; das Zebra malt
  `MenuPaper.draw_paper()` nach der Lage auf dem Papier.
- **Navigation selbst in der Hand:** Am Rand des Fensters soll der Fokus auf demselben Button
  bleiben und nur der Inhalt rollen. `_on_row_gui_input()` fängt `ui_up`, `ui_down`,
  `ui_focus_next` und `ui_focus_prev` ab und beendet sie mit `accept_event()`; `gui_input` kommt,
  bevor der Viewport den Fokus verschiebt. `exact_match = true`, sonst zählte Shift+Tab als Tab.
- **Melden ohne Fokuswechsel:** Zeigt derselbe Button nach dem Rollen einen anderen Spielstand,
  gibt es kein neues `focus_entered`; `select()` sendet `selection_changed` deshalb selbst.
- **Labels im Button:** Ein Button ist kein Container, seine Kinder stehen an ihrer `position`.
  `mouse_filter = IGNORE`, damit Klicks beim Button ankommen; Schrift und Farbe holen sie aus der
  Theme-Variante `MenuRow`.
- **Gedämpft ist nicht gesperrt:** `disabled` heißt nur „löst nichts aus“; gedämpft wird über die
  Farbe. So kann eine beschädigte Zeile im Löschmodus gedämpft bleiben und trotzdem löschen.
- **Kürzen macht Godot:** `text_overrun_behavior = OVERRUN_TRIM_ELLIPSIS` mit `ellipsis_char` „…“.
- **Mausrad:** Buttons halten Mausereignisse auf, deshalb behandelt `_on_row_gui_input()` das Rad
  über den Zeilen; über der Kopfzeile kommt es in `SaveList._gui_input()` an.

### T026 bis T028 Liste, Löschmodus und Rückfrage im Titelbildschirm

- **Ein Blatt mehr, kein neuer Mechanismus:** Die Rückfrage ist die dritte Instanz von
  `main_menu.tscn`, nur mit `header_text` „LÖSCHEN?“ und zwei Einträgen. `_show_only()` nimmt jetzt
  `Control` statt `MainMenu`, damit auch die `SaveList` dazugehört; mehr braucht es dafür nicht.
- **Die Liste meldet, der Titel entscheidet:** `SaveList` sendet `resume_requested`,
  `delete_requested` und `back_requested` und tut selbst nichts. Fortsetzen geht über die Session,
  Löschen über ihren `SaveStore`. So bleibt die Liste ohne Wissen über Dateien und Szenen, und ihre
  Tests brauchen keinen Ordner.
- **Esc an einer Stelle:** `_unhandled_input()` fragt der Reihe nach, welche Ebene oben liegt:
  Rückfrage, Liste (im Löschmodus nur den Modus beenden), Gradwahl. Die Reihenfolge der `if`-Zweige
  ist die Reihenfolge der Ebenen von oben nach unten.
- **Erst sichtbar, dann die Einträge:** Bei der Rückfrage ruft der Titel `set_entries()` nach
  `_show_only()`. Dann nimmt „Abbrechen“ sofort den Fokus, und `selection_changed` bringt seinen
  Hinweis mit. Bei der Liste ist es umgekehrt: `show_slots()` merkt sich die Zeile, solange sie
  unsichtbar ist, und `select()` nach dem Zeigen bringt Fokus und Hinweis.
- **Neu lesen, wo sich etwas geändert haben kann:** „Spiel laden“ und ein bestätigtes Löschen
  lesen den Ordner neu, „Abbrechen“ nicht, denn da ist nichts passiert. Die Liste merkt sich die
  gelesenen `SaveSlot` in `_list_slots`; Fortsetzen und Löschen nehmen genau diesen Stand.
- **Nach Nummer suchen, nicht nach Objekt:** Nach dem Neulesen sind die `SaveSlot` neue Objekte.
  `_index_of_number()` findet einen Spielstand deshalb über `number` wieder, etwa für die Meldung,
  wenn Löschen scheitert.
- **Meldung nach dem Hinweis:** `select()` zeigt den Hinweis der gewählten Zeile; die Meldung kommt
  danach und ersetzt ihn an derselben Stelle. Andersherum würde der Hinweis die Meldung sofort
  überdecken.

### Reparatur nach der Phasenprüfung (T029)

- **Die Meldung gehört zum Spielstand, nicht zur Stelle.** `MenuHint` kennt nur Stellen:
  `show_text()` lässt eine Meldung stehen, solange dieselbe `row_rect` kommt. In Menüs mit festen
  Zeilen ist das richtig, etwa wenn die Maus noch einmal über die Zeile fährt. Die Liste rollt aber:
  Nach dem Rollen zeigt derselbe Button einen anderen Spielstand an derselben Stelle. Gelöst ist das
  im Titelbildschirm, denn nur er hat das Löschen ausgeführt und weiß, zu welchem Spielstand die
  Meldung gehört. Er merkt sich `_warning_number`. In `_on_save_list_selection_changed()` vergleicht
  er die Nummer mit `selected_slot()`: Ist es derselbe Spielstand, wandert die Meldung mit
  `show_warning()` an die neue Stelle. Sonst blendet `_hide_hint()` sie aus, und der Hinweis kommt.
  Beides geschieht im selben Bild, also ohne Flackern. `MenuHint` und sein Vertrag bleiben, wie sie
  sind; ein Schlüssel in `show_warning()` hätte dem Hinweis Wissen über Spielstände gegeben.
- **Ein Helfer, der beides vergisst:** `_hide_hint()` blendet aus und vergisst die Nummer. Sonst käme
  die Meldung zurück, sobald derselbe Spielstand wieder gewählt wird, etwa nach Esc und erneutem
  Öffnen der Liste.
- **Gedämpft hängt an derselben Bedingung wie `disabled`:** In `_fill_row()` steuert jetzt
  `triggers := _delete_mode or resumable` Farbe, `disabled` und Mauszeiger zugleich, `_is_dimmed()`
  den Pfeil nach derselben Regel. So kann eine Zeile nicht gesperrt aussehen und doch auslösen.
- **Eine Vorlage statt zwei:** Die Rückfrage hat einen Platzhalter `{angaben}`, gefüllt mit „Schwer,
  14.03.1986“ oder dem Zustand. Zwei Satzformen für dasselbe laufen sonst mit der Zeit auseinander.
